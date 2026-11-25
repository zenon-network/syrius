#!/usr/bin/env python3
"""Close stale automated libznn update PRs when the target branch is already up to date."""

from __future__ import annotations

import argparse
import dataclasses
import os
import pathlib
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Sequence

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import update_libznn as updater


@dataclasses.dataclass(frozen=True)
class ClosedPullRequest:
    number: int
    html_url: str


@dataclasses.dataclass(frozen=True)
class StalePrCleanupResult:
    closed_prs: tuple[ClosedPullRequest, ...]
    branch_deleted: str  # "not_needed", "deleted", or "already_deleted"


def expected_pr_branch_for_target(target_branch: str) -> str:
    validated = updater.validate_target_branch(target_branch)
    return f"chore/update-libznn-{validated}"


def validate_pr_branch(pr_branch: str, target_branch: str) -> str:
    expected = expected_pr_branch_for_target(target_branch)
    cleaned = pr_branch.strip()
    if cleaned != expected:
        raise updater.UpdaterError(
            f"Refusing to operate on unexpected PR branch {pr_branch!r}; expected {expected!r}"
        )
    return cleaned


def _list_stale_open_prs(
    *,
    repo: str,
    target_branch: str,
    pr_branch: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> list[dict[str, Any]]:
    owner = repo.split("/", 1)[0]
    query = urllib.parse.urlencode(
        {
            "state": "open",
            "head": f"{owner}:{pr_branch}",
            "base": target_branch,
            "per_page": "100",
        }
    )
    url = f"https://api.github.com/repos/{repo}/pulls?{query}"
    payload = updater._github_api_request_json(
        url,
        github_token=github_token,
        opener=opener,
        api_label="GitHub Pull Requests API",
    )
    if not isinstance(payload, list):
        raise updater.UpdaterError("Unexpected GitHub Pull Requests API payload type")

    matching: list[dict[str, Any]] = []
    for item in payload:
        if not isinstance(item, dict):
            continue
        if item.get("state") != "open":
            continue
        head = item.get("head")
        base = item.get("base")
        if not isinstance(head, dict) or not isinstance(base, dict):
            continue
        head_repo = head.get("repo")
        if not isinstance(head_repo, dict):
            continue
        head_full_name = str(head_repo.get("full_name") or "").lower()
        if head_full_name != repo.lower():
            continue
        if head.get("ref") != pr_branch or base.get("ref") != target_branch:
            continue
        if type(item.get("number")) is not int or item["number"] <= 0:
            continue
        matching.append(item)
    return matching


def _build_close_comment(
    *,
    target_branch: str,
    release_tag: str,
    workflow_run_url: str | None = None,
) -> str:
    run_suffix = f" ([workflow run]({workflow_run_url}))" if workflow_run_url else ""
    return (
        f"Closing this automated pull request because `{target_branch}` is already up to date "
        f"with `go-zenon` `{release_tag}`{run_suffix}."
    )


def _delete_stale_branch(
    *,
    repo: str,
    pr_branch: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> str:
    encoded_branch = urllib.parse.quote(pr_branch, safe="/")
    url = f"https://api.github.com/repos/{repo}/git/refs/heads/{encoded_branch}"
    try:
        updater._github_api_request_json(
            url,
            method="DELETE",
            github_token=github_token,
            opener=opener,
            api_label="GitHub Git Ref API",
            allow_empty_response=True,
        )
        return "deleted"
    except updater.UpdaterError as exc:
        cause = exc.__cause__
        if isinstance(cause, urllib.error.HTTPError) and cause.code in {404, 422}:
            return "already_deleted"
        raise


def close_stale_libznn_prs(
    *,
    repo: str,
    target_branch: str,
    pr_branch: str,
    release_tag: str,
    github_token: str,
    workflow_run_url: str | None = None,
    github_output: pathlib.Path | None = None,
    step_summary: pathlib.Path | None = None,
    opener: urllib.request.OpenerDirector | None = None,
) -> StalePrCleanupResult:
    validated_repo = updater.validate_upstream_repo(repo)
    validated_target = updater.validate_target_branch(target_branch)
    validated_branch = validate_pr_branch(pr_branch, validated_target)
    validated_tag = updater.validate_tag(release_tag)
    if not validated_tag:
        raise updater.UpdaterError("A non-empty --release-tag is required")
    if not github_token or not github_token.strip():
        raise updater.UpdaterError("GitHub token is required to inspect/close stale pull requests")

    updater.validate_output_file_paths(
        (
            ("--github-output", github_output),
            ("--step-summary", step_summary),
        )
    )

    open_prs = _list_stale_open_prs(
        repo=validated_repo,
        target_branch=validated_target,
        pr_branch=validated_branch,
        github_token=github_token,
        opener=opener,
    )

    if not open_prs:
        result = StalePrCleanupResult(closed_prs=(), branch_deleted="not_needed")
    else:
        closed: list[ClosedPullRequest] = []
        comment_body = _build_close_comment(
            target_branch=validated_target,
            release_tag=validated_tag,
            workflow_run_url=workflow_run_url,
        )
        for pr in open_prs:
            pr_number = int(pr["number"])
            pr_url = str(pr.get("html_url") or f"https://github.com/{validated_repo}/pull/{pr_number}")
            comment_url = f"https://api.github.com/repos/{validated_repo}/issues/{pr_number}/comments"
            updater._github_api_request_json(
                comment_url,
                method="POST",
                body={"body": comment_body},
                github_token=github_token,
                opener=opener,
                api_label="GitHub Issue Comments API",
            )
            close_url = f"https://api.github.com/repos/{validated_repo}/pulls/{pr_number}"
            updater._github_api_request_json(
                close_url,
                method="PATCH",
                body={"state": "closed"},
                github_token=github_token,
                opener=opener,
                api_label="GitHub Pull Requests API",
            )
            closed.append(ClosedPullRequest(number=pr_number, html_url=pr_url))

        branch_status = _delete_stale_branch(
            repo=validated_repo,
            pr_branch=validated_branch,
            github_token=github_token,
            opener=opener,
        )
        result = StalePrCleanupResult(
            closed_prs=tuple(closed),
            branch_deleted=branch_status,
        )

    if github_output is not None:
        try:
            github_output.parent.mkdir(parents=True, exist_ok=True)
            updater.write_github_outputs(
                github_output,
                {
                    "closed_count": str(len(result.closed_prs)),
                    "closed_pr_urls": ",".join(item.html_url for item in result.closed_prs),
                    "branch_deleted": result.branch_deleted,
                },
            )
        except OSError as exc:
            raise updater.UpdaterError(f"Failed writing GITHUB_OUTPUT {github_output}: {exc}") from exc

    if step_summary is not None:
        summary_lines = ["", "### Stale pull request cleanup"]
        if result.closed_prs:
            for item in result.closed_prs:
                summary_lines.append(
                    f"- Closed stale PR #{item.number} ({item.html_url}) because `{validated_target}` "
                    f"is already up to date with `{validated_tag}`."
                )
            summary_lines.append(
                f"- Branch `{validated_branch}` deletion status: `{result.branch_deleted}`."
            )
        else:
            summary_lines.append(
                f"- No stale automated pull request was open for `{validated_branch}` -> `{validated_target}`."
            )
        try:
            step_summary.parent.mkdir(parents=True, exist_ok=True)
            with step_summary.open("a", encoding="utf-8") as handle:
                handle.write("\n".join(summary_lines) + "\n")
        except OSError as exc:
            print(
                f"WARNING: failed to append step summary {step_summary}: {exc}",
                file=sys.stderr,
            )

    return result


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Close stale automated libznn update PRs when the target branch is up to date."
    )
    parser.add_argument(
        "--repo",
        required=True,
        help="GitHub repository in owner/name format (e.g. zenon-network/syrius).",
    )
    parser.add_argument(
        "--target-branch",
        required=True,
        help="Target branch (develop or master).",
    )
    parser.add_argument(
        "--pr-branch",
        required=True,
        help="Automated PR head branch (must match chore/update-libznn-<target-branch>).",
    )
    parser.add_argument(
        "--release-tag",
        required=True,
        help="Resolved go-zenon release tag that the target branch already matches.",
    )
    parser.add_argument(
        "--github-output",
        type=pathlib.Path,
        default=None,
        help="Optional path to GitHub Actions GITHUB_OUTPUT file.",
    )
    parser.add_argument(
        "--step-summary",
        type=pathlib.Path,
        default=None,
        help="Optional path to GitHub Actions GITHUB_STEP_SUMMARY file.",
    )
    args = parser.parse_args(argv)

    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
    try:
        result = close_stale_libznn_prs(
            repo=args.repo,
            target_branch=args.target_branch,
            pr_branch=args.pr_branch,
            release_tag=args.release_tag,
            github_token=token,
            workflow_run_url=updater._workflow_run_url_from_env(),
            github_output=args.github_output,
            step_summary=args.step_summary,
        )
    except updater.UpdaterError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if result.closed_prs:
        for item in result.closed_prs:
            print(f"Closed stale automated PR #{item.number}: {item.html_url}")
        print(f"Branch {args.pr_branch} cleanup status: {result.branch_deleted}")
    else:
        print(
            f"No stale automated pull request open for {args.pr_branch} -> {args.target_branch}."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
