#!/usr/bin/env python3
"""Commit staged libznn updates, push atomically with --force-with-lease, and open/update the PR."""

from __future__ import annotations

import argparse
import base64
import dataclasses
import os
import pathlib
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from typing import Any, Mapping, Sequence

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import close_stale_libznn_pr as stale_pr
import update_libznn as updater

DEFAULT_COMMITTER_NAME = "github-actions[bot]"
DEFAULT_COMMITTER_EMAIL = "41898282+github-actions[bot]@users.noreply.github.com"
ALLOWED_STAGE_PATHS: tuple[str, ...] = tuple(
    spec.blob_relpath for spec in updater.BINARY_SPECS
) + (updater.MANIFEST_RELPATH,)
TAG_SUFFIX_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
VALID_HEAD_STATES = frozenset({"present", "absent"})
LEASE_CHECK_REF = "refs/remotes/__libznn_lease_check__"


@dataclasses.dataclass(frozen=True)
class PublishPrResult:
    operation: str  # "created", "updated", or "unchanged"
    pr_url: str
    pr_number: int | None
    pr_branch: str
    pushed_commit_sha: str


def validate_publish_pr_branch(pr_branch: str, target_branch: str) -> str:
    """Validate that pr_branch is either the rolling branch or a tag-scoped branch for target_branch."""
    validated_target = updater.validate_target_branch(target_branch)
    default_branch = updater.default_pr_branch_for_target(validated_target)
    cleaned = pr_branch.strip()
    if cleaned == default_branch:
        return cleaned
    prefix = f"{default_branch}-"
    if not cleaned.startswith(prefix):
        raise updater.UpdaterError(
            f"Refusing to publish to unexpected PR branch {pr_branch!r}; "
            f"expected {default_branch!r} or {prefix}<tag-slug>"
        )
    suffix = cleaned[len(prefix) :]
    if (
        not TAG_SUFFIX_PATTERN.fullmatch(suffix)
        or ".." in suffix
        or suffix.endswith(".")
        or suffix.lower().endswith(".lock")
    ):
        raise updater.UpdaterError(f"Invalid tag-scoped PR branch name: {pr_branch!r}")
    return cleaned


def _validate_pr_title(title: str) -> str:
    if "\n" in title or "\r" in title:
        raise updater.UpdaterError("PR title must be a single line")
    cleaned = title.strip()
    if not cleaned:
        raise updater.UpdaterError("A non-empty --pr-title is required")
    return cleaned


def _scrub_secrets(text: str, secrets_to_mask: Sequence[str]) -> str:
    redacted = text
    for secret in secrets_to_mask:
        if secret:
            redacted = redacted.replace(secret, "***")
    return redacted


def _build_git_env(
    *,
    remote_url: str | None = None,
    github_token: str | None = None,
    author_name: str | None = None,
    author_email: str | None = None,
) -> tuple[dict[str, str], tuple[str, ...]]:
    env = dict(os.environ)
    env["GIT_TERMINAL_PROMPT"] = "0"
    secrets_to_mask: list[str] = []

    if author_name and author_email:
        env["GIT_AUTHOR_NAME"] = author_name
        env["GIT_AUTHOR_EMAIL"] = author_email
        env["GIT_COMMITTER_NAME"] = author_name
        env["GIT_COMMITTER_EMAIL"] = author_email

    if remote_url and github_token:
        parsed = urllib.parse.urlsplit(remote_url)
        if parsed.scheme == "https" and parsed.netloc.lower() == "github.com":
            basic_b64 = base64.b64encode(
                f"x-access-token:{github_token}".encode("utf-8")
            ).decode("ascii")
            secrets_to_mask.extend([github_token, basic_b64])
            try:
                existing_count = int(env.get("GIT_CONFIG_COUNT", "0"))
            except ValueError:
                existing_count = 0
            env[f"GIT_CONFIG_KEY_{existing_count}"] = "http.https://github.com/.extraheader"
            env[f"GIT_CONFIG_VALUE_{existing_count}"] = f"AUTHORIZATION: basic {basic_b64}"
            env["GIT_CONFIG_COUNT"] = str(existing_count + 1)
        else:
            secrets_to_mask.append(github_token)

    return env, tuple(secrets_to_mask)


def _run_git(
    args: Sequence[str],
    *,
    repo_root: pathlib.Path,
    env: Mapping[str, str] | None = None,
    input_text: str | None = None,
    secrets_to_mask: Sequence[str] = (),
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    proc = subprocess.run(
        ["git", *args],
        cwd=str(repo_root),
        env=dict(env) if env is not None else None,
        input=input_text,
        capture_output=True,
        text=True,
        check=False,
    )
    if check and proc.returncode != 0:
        detail = _scrub_secrets(
            (proc.stderr or proc.stdout or f"exit status {proc.returncode}").strip(),
            secrets_to_mask,
        )
        safe_args = _scrub_secrets(" ".join(args), secrets_to_mask)
        raise updater.UpdaterError(f"git {safe_args} failed: {detail}")
    return proc


def _resolve_remote_head_via_ls_remote(
    *,
    repo_root: pathlib.Path,
    remote: str,
    pr_branch: str,
    env: Mapping[str, str],
    secrets_to_mask: Sequence[str],
) -> tuple[str, str]:
    target_ref = f"refs/heads/{pr_branch}"
    proc = _run_git(
        ["ls-remote", "--heads", remote, target_ref],
        repo_root=repo_root,
        env=env,
        secrets_to_mask=secrets_to_mask,
    )
    matched_shas: list[str] = []
    for line in proc.stdout.splitlines():
        parts = line.strip().split("\t")
        if len(parts) == 2 and parts[1] == target_ref:
            matched_shas.append(
                updater.validate_git_commit_sha(
                    parts[0], label=f"remote {target_ref} head SHA"
                )
            )
    if not matched_shas:
        return "absent", ""
    if len(matched_shas) > 1:
        raise updater.UpdaterError(f"Ambiguous ls-remote output for {target_ref}")
    return "present", matched_shas[0]


def _parse_commit_tree_and_parents(raw_commit: str) -> tuple[str | None, list[str]]:
    tree_sha: str | None = None
    parents: list[str] = []
    for line in raw_commit.splitlines():
        if not line:
            break
        if line.startswith("tree "):
            tree_sha = line[5:].strip().lower()
        elif line.startswith("parent "):
            parents.append(line[7:].strip().lower())
    return tree_sha, parents


def _remote_branch_matches_commit(
    *,
    repo_root: pathlib.Path,
    remote: str,
    pr_branch: str,
    expected_head_oid: str,
    expected_parent_sha: str,
    expected_tree_sha: str,
    env: Mapping[str, str],
    secrets_to_mask: Sequence[str],
) -> bool:
    """Return True if remote pr_branch is still at expected_head_oid with identical parent & tree.

    Raises UpdaterError if the fetched remote ref drifted away from expected_head_oid.
    """
    fetch_proc = _run_git(
        [
            "fetch",
            "--no-tags",
            "--depth=1",
            remote,
            f"+refs/heads/{pr_branch}:{LEASE_CHECK_REF}",
        ],
        repo_root=repo_root,
        env=env,
        secrets_to_mask=secrets_to_mask,
        check=False,
    )
    if fetch_proc.returncode != 0:
        return False

    try:
        rev_proc = _run_git(
            ["rev-parse", LEASE_CHECK_REF],
            repo_root=repo_root,
            env=env,
            secrets_to_mask=secrets_to_mask,
        )
        fetched_sha = updater.validate_git_commit_sha(
            rev_proc.stdout.strip(), label=f"fetched {pr_branch!r} head SHA"
        )
        if fetched_sha != expected_head_oid:
            raise updater.UpdaterError(
                f"Atomic push aborted: remote branch {pr_branch!r} moved from approved head "
                f"{expected_head_oid} to {fetched_sha}. Re-run the workflow so pr_guard can "
                "classify the new branch head."
            )
        cat_proc = _run_git(
            ["cat-file", "-p", LEASE_CHECK_REF],
            repo_root=repo_root,
            env=env,
            secrets_to_mask=secrets_to_mask,
        )
        remote_tree, remote_parents = _parse_commit_tree_and_parents(cat_proc.stdout)
        return (
            remote_tree == expected_tree_sha.lower()
            and remote_parents == [expected_parent_sha.lower()]
        )
    finally:
        _run_git(
            ["update-ref", "-d", LEASE_CHECK_REF],
            repo_root=repo_root,
            env=env,
            secrets_to_mask=secrets_to_mask,
            check=False,
        )


def _append_step_summary_note(step_summary: pathlib.Path | None, lines: Sequence[str]) -> None:
    if step_summary is None:
        return
    try:
        step_summary.parent.mkdir(parents=True, exist_ok=True)
        with step_summary.open("a", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")
    except OSError as exc:
        print(
            f"WARNING: failed to append step summary {step_summary}: {exc}",
            file=sys.stderr,
        )


def _parse_expected_pr_numbers(raw: str) -> frozenset[int]:
    cleaned = raw.strip()
    if cleaned == "none":
        return frozenset()
    if not cleaned:
        raise updater.UpdaterError(
            "Refusing to push guarded branch without --expected-pr-numbers ('none' or comma-separated PR numbers)"
        )
    numbers: set[int] = set()
    for part in cleaned.split(","):
        token = part.strip()
        if not token.isdigit() or int(token) <= 0:
            raise updater.UpdaterError(
                f"Invalid --expected-pr-numbers entry {part!r} in {raw!r}"
            )
        numbers.add(int(token))
    return frozenset(numbers)


def publish_libznn_pr(
    *,
    repo: str,
    repo_root: pathlib.Path,
    target_branch: str,
    pr_branch: str,
    pr_title: str,
    pr_body: str,
    commit_message: str,
    github_token: str,
    require_expected_head: bool = False,
    expected_head_state: str = "",
    expected_head_oid: str = "",
    expected_pr_numbers: str = "",
    remote: str = "origin",
    committer_name: str = DEFAULT_COMMITTER_NAME,
    committer_email: str = DEFAULT_COMMITTER_EMAIL,
    github_output: pathlib.Path | None = None,
    step_summary: pathlib.Path | None = None,
    opener: urllib.request.OpenerDirector | None = None,
) -> PublishPrResult:
    """Commit staged libznn blobs/manifest, push atomically, and create or update the PR."""
    validated_repo = updater.validate_upstream_repo(repo)
    validated_target = updater.validate_target_branch(target_branch)
    validated_branch = validate_publish_pr_branch(pr_branch, validated_target)
    validated_title = _validate_pr_title(pr_title)
    if not commit_message or not commit_message.strip():
        raise updater.UpdaterError("A non-empty commit message is required")
    if not github_token or not github_token.strip():
        raise updater.UpdaterError("GitHub token is required to publish pull request")

    protected_blobs = [repo_root / spec.blob_relpath for spec in updater.BINARY_SPECS]
    protected_manifest = repo_root / updater.MANIFEST_RELPATH
    updater.validate_output_file_paths(
        (
            ("--github-output", github_output),
            ("--step-summary", step_summary),
        ),
        protected_blobs=protected_blobs,
        protected_manifest=protected_manifest,
    )

    is_default_branch = validated_branch == updater.default_pr_branch_for_target(validated_target)
    must_require_lease = require_expected_head or is_default_branch

    cleaned_state = expected_head_state.strip()
    cleaned_oid = expected_head_oid.strip()
    expected_pr_set: frozenset[int] | None = None

    if must_require_lease:
        if cleaned_state not in VALID_HEAD_STATES:
            raise updater.UpdaterError(
                f"Refusing to push guarded branch {validated_branch!r} without a valid "
                f"--expected-head-state ('present' or 'absent'); got {expected_head_state!r}"
            )
        expected_pr_set = _parse_expected_pr_numbers(expected_pr_numbers)
    elif cleaned_state:
        if cleaned_state not in VALID_HEAD_STATES:
            raise updater.UpdaterError(
                f"Invalid --expected-head-state {expected_head_state!r}; expected 'present' or 'absent'"
            )
        if expected_pr_numbers.strip():
            expected_pr_set = _parse_expected_pr_numbers(expected_pr_numbers)
    elif cleaned_oid:
        raise updater.UpdaterError(
            "--expected-head-oid was provided without --expected-head-state"
        )
    elif expected_pr_numbers.strip():
        expected_pr_set = _parse_expected_pr_numbers(expected_pr_numbers)

    if cleaned_state == "present":
        cleaned_oid = updater.validate_git_commit_sha(
            cleaned_oid, label="--expected-head-oid"
        )
    elif cleaned_state == "absent" and cleaned_oid:
        raise updater.UpdaterError(
            f"--expected-head-oid must be empty when --expected-head-state is 'absent'; got {expected_head_oid!r}"
        )

    base_env, base_secrets = _build_git_env(
        author_name=committer_name,
        author_email=committer_email,
    )
    inside = _run_git(
        ["rev-parse", "--is-inside-work-tree"],
        repo_root=repo_root,
        env=base_env,
        secrets_to_mask=base_secrets,
    )
    if inside.stdout.strip() != "true":
        raise updater.UpdaterError(f"{repo_root} is not a Git working tree")

    remote_url = _run_git(
        ["remote", "get-url", remote],
        repo_root=repo_root,
        env=base_env,
        secrets_to_mask=base_secrets,
    ).stdout.strip()
    git_env, git_secrets = _build_git_env(
        remote_url=remote_url,
        github_token=github_token,
        author_name=committer_name,
        author_email=committer_email,
    )

    base_head_sha = updater.validate_git_commit_sha(
        _run_git(
            ["rev-parse", "HEAD"],
            repo_root=repo_root,
            env=git_env,
            secrets_to_mask=git_secrets,
        ).stdout.strip(),
        label="checked-out base HEAD SHA",
    )

    # Verify allowed paths are not symlinks and stage only the 4 updater-owned paths.
    paths_to_stage: list[str] = []
    for relpath in ALLOWED_STAGE_PATHS:
        full_path = repo_root / relpath
        if full_path.is_symlink():
            raise updater.UpdaterError(f"Refusing to stage symlink path: {full_path}")
        if full_path.exists():
            paths_to_stage.append(relpath)

    if paths_to_stage:
        _run_git(
            ["add", "--", *paths_to_stage],
            repo_root=repo_root,
            env=git_env,
            secrets_to_mask=git_secrets,
        )

    staged_files = [
        line.strip()
        for line in _run_git(
            ["diff", "--cached", "--name-only"],
            repo_root=repo_root,
            env=git_env,
            secrets_to_mask=git_secrets,
        ).stdout.splitlines()
        if line.strip()
    ]
    unexpected_staged = sorted(set(staged_files) - set(ALLOWED_STAGE_PATHS))
    if unexpected_staged:
        raise updater.UpdaterError(
            f"Refusing to commit unexpected staged files outside libznn blobs/manifest: {unexpected_staged}"
        )

    if not staged_files:
        noop_result = PublishPrResult(
            operation="unchanged",
            pr_url="",
            pr_number=None,
            pr_branch=validated_branch,
            pushed_commit_sha="",
        )
        _write_publish_outputs(github_output, noop_result)
        return noop_result

    # For tag-scoped branches without an explicit caller lease, snapshot remote ref once
    # so even tag-scoped pushes use an explicit --force-with-lease check.
    if not cleaned_state:
        cleaned_state, cleaned_oid = _resolve_remote_head_via_ls_remote(
            repo_root=repo_root,
            remote=remote,
            pr_branch=validated_branch,
            env=git_env,
            secrets_to_mask=git_secrets,
        )

    # Inspect ALL open PRs on this head branch (across all bases) before touching the remote branch.
    open_prs = stale_pr._list_candidate_open_prs(
        repo=validated_repo,
        pr_branch=validated_branch,
        base_branch=None,
        strict=True,
        github_token=github_token,
        opener=opener,
    )
    other_base_prs = [
        pr
        for pr in open_prs
        if str((pr.get("base") or {}).get("ref") or "") != validated_target
    ]
    if other_base_prs:
        numbers = ", ".join(f"#{int(pr['number'])}" for pr in other_base_prs)
        msg = (
            f"Atomic push aborted: open PR(s) {numbers} on {validated_branch!r} target a "
            f"base branch other than {validated_target!r}. Re-run the workflow to re-classify."
        )
        _append_step_summary_note(
            step_summary,
            ["", "### Pull request", f"- {msg}"],
        )
        raise updater.UpdaterError(msg)

    matching_prs = [
        pr
        for pr in open_prs
        if str((pr.get("base") or {}).get("ref") or "") == validated_target
    ]
    if len(matching_prs) > 1:
        raise updater.UpdaterError(
            f"Found multiple open PRs ({len(matching_prs)}) for {validated_branch!r} -> {validated_target!r}"
        )
    existing_pr = matching_prs[0] if matching_prs else None

    if expected_pr_set is not None:
        actual_pr_set = frozenset(int(pr["number"]) for pr in matching_prs)
        if actual_pr_set != expected_pr_set:
            expected_desc = (
                ", ".join(f"#{n}" for n in sorted(expected_pr_set))
                if expected_pr_set
                else "none"
            )
            actual_desc = (
                ", ".join(f"#{n}" for n in sorted(actual_pr_set))
                if actual_pr_set
                else "none"
            )
            msg = (
                f"Atomic push aborted: open PR set on {validated_branch!r} changed after pr_guard "
                f"(expected {expected_desc}, observed {actual_desc}). Re-run the workflow to re-classify."
            )
            _append_step_summary_note(
                step_summary,
                ["", "### Pull request", f"- {msg}"],
            )
            raise updater.UpdaterError(msg)

    if must_require_lease:
        if cleaned_state == "absent" and existing_pr is not None:
            pr_num = int(existing_pr["number"])
            msg = (
                f"Atomic push aborted: open PR #{pr_num} appeared on {validated_branch!r} after "
                "pr_guard verified the remote branch was absent. Re-run the workflow to classify it."
            )
            _append_step_summary_note(
                step_summary,
                ["", "### Pull request", f"- {msg}"],
            )
            raise updater.UpdaterError(msg)
        if cleaned_state == "present" and existing_pr is not None:
            pr_num = int(existing_pr["number"])
            pr_head_sha = updater.validate_git_commit_sha(
                existing_pr["head"].get("sha"), label=f"PR #{pr_num} head SHA"
            )
            if pr_head_sha != cleaned_oid:
                msg = (
                    f"Atomic push aborted: open PR #{pr_num} on {validated_branch!r} moved from "
                    f"approved head {cleaned_oid} to {pr_head_sha}. Re-run the workflow so "
                    "pr_guard can classify the new branch head."
                )
                _append_step_summary_note(
                    step_summary,
                    ["", "### Pull request", f"- {msg}"],
                )
                raise updater.UpdaterError(msg)

    # Detach HEAD before committing so local base branch refs are never mutated.
    _run_git(
        ["checkout", "--detach", "HEAD"],
        repo_root=repo_root,
        env=git_env,
        secrets_to_mask=git_secrets,
    )
    _run_git(
        ["commit", "--no-verify", "--no-gpg-sign", "-F", "-"],
        repo_root=repo_root,
        env=git_env,
        input_text=commit_message,
        secrets_to_mask=git_secrets,
    )
    new_commit_sha = updater.validate_git_commit_sha(
        _run_git(
            ["rev-parse", "HEAD"],
            repo_root=repo_root,
            env=git_env,
            secrets_to_mask=git_secrets,
        ).stdout.strip(),
        label="created commit SHA",
    )
    new_tree_sha = updater.validate_git_commit_sha(
        _run_git(
            ["rev-parse", "HEAD^{tree}"],
            repo_root=repo_root,
            env=git_env,
            secrets_to_mask=git_secrets,
        ).stdout.strip(),
        label="created commit tree SHA",
    )

    need_push = True
    if cleaned_state == "present" and existing_pr is not None:
        try:
            already_identical = _remote_branch_matches_commit(
                repo_root=repo_root,
                remote=remote,
                pr_branch=validated_branch,
                expected_head_oid=cleaned_oid,
                expected_parent_sha=base_head_sha,
                expected_tree_sha=new_tree_sha,
                env=git_env,
                secrets_to_mask=git_secrets,
            )
        except updater.UpdaterError as exc:
            _append_step_summary_note(
                step_summary,
                ["", "### Pull request", f"- {exc}"],
            )
            raise
        if already_identical:
            need_push = False

    pushed_commit_sha = ""
    if need_push:
        lease_expect = cleaned_oid if cleaned_state == "present" else ""
        lease_arg = f"--force-with-lease=refs/heads/{validated_branch}:{lease_expect}"
        push_proc = _run_git(
            [
                "push",
                lease_arg,
                remote,
                f"HEAD:refs/heads/{validated_branch}",
            ],
            repo_root=repo_root,
            env=git_env,
            secrets_to_mask=git_secrets,
            check=False,
        )
        if push_proc.returncode != 0:
            detail = _scrub_secrets(
                (push_proc.stderr or push_proc.stdout or f"exit status {push_proc.returncode}").strip(),
                git_secrets,
            )
            if cleaned_state == "absent":
                msg = (
                    f"Atomic push aborted: remote branch {validated_branch!r} could not be created "
                    "with an empty lease (branch may have been created concurrently after pr_guard "
                    f"inspected it). Re-run the workflow to classify the new branch head. "
                    f"Git error: {detail}"
                )
            else:
                msg = (
                    f"Atomic push aborted: remote branch {validated_branch!r} no longer matches "
                    f"approved head {cleaned_oid} (or push was rejected). Re-run the workflow so "
                    f"pr_guard can classify the new branch head. Git error: {detail}"
                )
            _append_step_summary_note(
                step_summary,
                ["", "### Pull request", f"- {msg}"],
            )
            raise updater.UpdaterError(msg)
        pushed_commit_sha = new_commit_sha

    if existing_pr is not None:
        pr_number = int(existing_pr["number"])
        pr_url = str(
            existing_pr.get("html_url")
            or f"https://github.com/{validated_repo}/pull/{pr_number}"
        )
        existing_title = str(existing_pr.get("title") or "")
        existing_body = str(existing_pr.get("body") or "")
        if existing_title != validated_title or existing_body != pr_body:
            update_url = f"https://api.github.com/repos/{validated_repo}/pulls/{pr_number}"
            updated_payload = updater.github_api_request_json(
                update_url,
                method="PATCH",
                body={"title": validated_title, "body": pr_body},
                github_token=github_token,
                opener=opener,
                api_label="GitHub Pull Requests API",
            )
            if isinstance(updated_payload, dict) and isinstance(
                updated_payload.get("html_url"), str
            ):
                pr_url = updated_payload["html_url"]
            operation = "updated"
        elif pushed_commit_sha:
            operation = "updated"
        else:
            operation = "unchanged"
    else:
        create_url = f"https://api.github.com/repos/{validated_repo}/pulls"
        try:
            created_payload = updater.github_api_request_json(
                create_url,
                method="POST",
                body={
                    "title": validated_title,
                    "head": validated_branch,
                    "base": validated_target,
                    "body": pr_body,
                },
                github_token=github_token,
                opener=opener,
                api_label="GitHub Pull Requests API",
            )
        except updater.UpdaterError:
            if cleaned_state == "absent" and pushed_commit_sha:
                rollback = _run_git(
                    [
                        "push",
                        f"--force-with-lease=refs/heads/{validated_branch}:{pushed_commit_sha}",
                        remote,
                        f":refs/heads/{validated_branch}",
                    ],
                    repo_root=repo_root,
                    env=git_env,
                    secrets_to_mask=git_secrets,
                    check=False,
                )
                if rollback.returncode != 0:
                    detail = _scrub_secrets(
                        (rollback.stderr or rollback.stdout or "").strip(),
                        git_secrets,
                    )
                    print(
                        f"WARNING: failed to roll back newly pushed branch {validated_branch!r}: {detail}",
                        file=sys.stderr,
                    )
            elif cleaned_state == "present" and cleaned_oid and pushed_commit_sha:
                try:
                    cur_state, cur_oid = stale_pr._resolve_remote_branch_head(
                        repo=validated_repo,
                        pr_branch=validated_branch,
                        github_token=github_token,
                        opener=opener,
                    )
                    if cur_state == "present" and cur_oid == pushed_commit_sha:
                        encoded_branch = urllib.parse.quote(validated_branch, safe="/")
                        ref_patch_url = (
                            f"https://api.github.com/repos/{validated_repo}/git/refs/heads/{encoded_branch}"
                        )
                        updater.github_api_request_json(
                            ref_patch_url,
                            method="PATCH",
                            body={"sha": cleaned_oid, "force": True},
                            github_token=github_token,
                            opener=opener,
                            api_label="GitHub Git Ref API",
                        )
                except updater.UpdaterError as rollback_exc:
                    print(
                        f"WARNING: failed to restore branch {validated_branch!r} to "
                        f"{cleaned_oid} after PR creation failure: {rollback_exc}",
                        file=sys.stderr,
                    )
            raise
        if (
            not isinstance(created_payload, dict)
            or type(created_payload.get("number")) is not int
            or created_payload["number"] <= 0
            or not isinstance(created_payload.get("html_url"), str)
            or not created_payload["html_url"].strip()
        ):
            raise updater.UpdaterError("Unexpected GitHub Pull Requests API response when creating PR")
        pr_number = int(created_payload["number"])
        pr_url = created_payload["html_url"]
        operation = "created"

    result = PublishPrResult(
        operation=operation,
        pr_url=pr_url,
        pr_number=pr_number,
        pr_branch=validated_branch,
        pushed_commit_sha=pushed_commit_sha,
    )
    _write_publish_outputs(github_output, result)
    return result


def _write_publish_outputs(
    github_output: pathlib.Path | None,
    result: PublishPrResult,
) -> None:
    if github_output is None:
        return
    try:
        github_output.parent.mkdir(parents=True, exist_ok=True)
        updater.write_github_outputs(
            github_output,
            {
                "pull-request-url": result.pr_url,
                "pull-request-number": str(result.pr_number) if result.pr_number is not None else "",
                "pull-request-branch": result.pr_branch,
                "pull-request-operation": result.operation,
                "pushed-commit-sha": result.pushed_commit_sha,
            },
        )
    except OSError as exc:
        raise updater.UpdaterError(f"Failed writing GITHUB_OUTPUT {github_output}: {exc}") from exc


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Commit staged libznn changes, push atomically with --force-with-lease, and open/update PR."
    )
    parser.add_argument(
        "--repo",
        required=True,
        help="GitHub repository in owner/name format (e.g. zenon-network/syrius).",
    )
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        required=True,
        help="Path to checked-out repository working tree.",
    )
    parser.add_argument(
        "--target-branch",
        required=True,
        help="PR base branch (develop or master).",
    )
    parser.add_argument(
        "--pr-branch",
        required=True,
        help="PR head branch (chore/update-libznn-<target> or tag-scoped variant).",
    )
    parser.add_argument(
        "--pr-title",
        required=True,
        help="Pull request title.",
    )
    parser.add_argument(
        "--pr-body-file",
        type=pathlib.Path,
        required=True,
        help="Path to file containing the pull request body Markdown.",
    )
    parser.add_argument(
        "--commit-message",
        default=None,
        help="Commit message string.",
    )
    parser.add_argument(
        "--commit-message-file",
        type=pathlib.Path,
        default=None,
        help="Path to file containing commit message.",
    )
    parser.add_argument(
        "--commit-message-env",
        default="COMMIT_MESSAGE",
        help="Environment variable holding commit message when --commit-message/--commit-message-file are omitted.",
    )
    parser.add_argument(
        "--require-expected-head",
        action="store_true",
        help="Require explicit --expected-head-state ('present' or 'absent') from pr_guard.",
    )
    parser.add_argument(
        "--expected-head-state",
        default="",
        help="Expected remote branch state from pr_guard ('present' or 'absent').",
    )
    parser.add_argument(
        "--expected-head-oid",
        default="",
        help="Expected remote branch 40-char commit SHA when --expected-head-state is 'present'.",
    )
    parser.add_argument(
        "--expected-pr-numbers",
        default="",
        help="Inspected open PR numbers from pr_guard ('none' or comma-separated PR numbers).",
    )
    parser.add_argument(
        "--remote",
        default="origin",
        help="Git remote name (default: origin).",
    )
    parser.add_argument(
        "--committer-name",
        default=DEFAULT_COMMITTER_NAME,
        help=f"Git author/committer name (default: {DEFAULT_COMMITTER_NAME}).",
    )
    parser.add_argument(
        "--committer-email",
        default=DEFAULT_COMMITTER_EMAIL,
        help=f"Git author/committer email (default: {DEFAULT_COMMITTER_EMAIL}).",
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
        try:
            pr_body = args.pr_body_file.read_text(encoding="utf-8")
        except OSError as exc:
            raise updater.UpdaterError(
                f"Failed reading PR body file {args.pr_body_file}: {exc}"
            ) from exc

        if args.commit_message is not None:
            commit_message = args.commit_message
        elif args.commit_message_file is not None:
            try:
                commit_message = args.commit_message_file.read_text(encoding="utf-8")
            except OSError as exc:
                raise updater.UpdaterError(
                    f"Failed reading commit message file {args.commit_message_file}: {exc}"
                ) from exc
        else:
            commit_message = os.environ.get(args.commit_message_env, "")

        result = publish_libznn_pr(
            repo=args.repo,
            repo_root=args.repo_root,
            target_branch=args.target_branch,
            pr_branch=args.pr_branch,
            pr_title=args.pr_title,
            pr_body=pr_body,
            commit_message=commit_message,
            github_token=token,
            require_expected_head=args.require_expected_head,
            expected_head_state=args.expected_head_state,
            expected_head_oid=args.expected_head_oid,
            expected_pr_numbers=args.expected_pr_numbers,
            remote=args.remote,
            committer_name=args.committer_name,
            committer_email=args.committer_email,
            github_output=args.github_output,
            step_summary=args.step_summary,
        )
    except updater.UpdaterError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if result.pr_url:
        print(
            f"Pull request {result.operation}: {result.pr_url} "
            f"(branch: {result.pr_branch})"
        )
    else:
        print(f"No pull request changes required for {result.pr_branch}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
