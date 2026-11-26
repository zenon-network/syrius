#!/usr/bin/env python3
"""Close stale automated libznn update PRs when the target branch is already up to date."""

from __future__ import annotations

import argparse
import base64
import dataclasses
import json
import os
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Mapping, Sequence

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import update_libznn as updater

DOWNGRADE_TITLE_FLAG_PATTERN = re.compile(
    r"\(\s*(?:[^()]*,\s*)?downgrade(?:\s*,[^()]*)?\s*\)\s*$",
    re.IGNORECASE,
)
PRERELEASE_TITLE_FLAG_PATTERN = re.compile(
    r"\(\s*(?:[^()]*,\s*)?prerelease(?:\s*,[^()]*)?\s*\)\s*$",
    re.IGNORECASE,
)
BLOB_RELPATHS = frozenset(spec.blob_relpath for spec in updater.BINARY_SPECS)
BLOBS_DIR_RELPATH = "lib/embedded_node/blobs"
MAX_PR_FILES_PER_PAGE = 100
MAX_COMPARE_FILES = 300


@dataclasses.dataclass(frozen=True)
class ClosedPullRequest:
    number: int
    html_url: str
    reason: str
    comment_warning: str | None = None


@dataclasses.dataclass(frozen=True)
class PreservedPullRequest:
    number: int
    html_url: str
    reason: str


@dataclasses.dataclass(frozen=True)
class StalePrCleanupResult:
    closed_prs: tuple[ClosedPullRequest, ...]
    preserved_prs: tuple[PreservedPullRequest, ...]
    branch_deleted: str  # "not_needed", "deleted", or "already_deleted"


@dataclasses.dataclass(frozen=True)
class PrUpdateGuardResult:
    safe_to_update: bool
    blocking_prs: tuple[PreservedPullRequest, ...]
    updatable_prs: tuple[PreservedPullRequest, ...]
    expected_head_state: str = ""  # "present", "absent", or "" when not safe_to_update
    expected_head_oid: str = ""  # 40-char lowercase commit SHA when present, else ""
    blocking_reason: str | None = None
    inspected_pr_numbers: tuple[int, ...] = ()


def expected_pr_branch_for_target(target_branch: str) -> str:
    return updater.default_pr_branch_for_target(target_branch)


def validate_pr_branch(pr_branch: str, target_branch: str) -> str:
    expected = expected_pr_branch_for_target(target_branch)
    cleaned = pr_branch.strip()
    if cleaned != expected:
        raise updater.UpdaterError(
            f"Refusing to operate on unexpected PR branch {pr_branch!r}; expected {expected!r}"
        )
    return cleaned


def is_forced_downgrade_pr(pr: Mapping[str, Any]) -> bool:
    title = str(pr.get("title") or "")
    body = str(pr.get("body") or "")
    if DOWNGRADE_TITLE_FLAG_PATTERN.search(title):
        return True
    if "**Forced downgrade:**" in body:
        return True
    return False


def is_prerelease_pr(pr: Mapping[str, Any]) -> bool:
    title = str(pr.get("title") or "")
    body = str(pr.get("body") or "")
    if PRERELEASE_TITLE_FLAG_PATTERN.search(title):
        return True
    if "is marked as a **pre-release**" in body or "- **Release type:** `pre-release`" in body:
        return True
    return False


def is_explicit_tag_pr(pr: Mapping[str, Any]) -> bool:
    body = str(pr.get("body") or "")
    return "- **Selection mode:** explicit tag" in body


def protected_pr_marker_reason(
    pr: Mapping[str, Any],
    *,
    protect_prerelease_and_explicit: bool = True,
) -> str | None:
    """Return a human-readable protection reason if PR carries a protected title/body marker."""
    if is_forced_downgrade_pr(pr):
        return "PR is marked as an intentional forced downgrade"
    if protect_prerelease_and_explicit:
        if is_prerelease_pr(pr):
            return "PR is marked as a pre-release update"
        if is_explicit_tag_pr(pr):
            return "PR is marked as an explicit-tag dispatch"
    return None


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


def _prepare_git_remote_env(
    *,
    repo_root: pathlib.Path,
    remote: str,
    github_token: str,
) -> tuple[dict[str, str], tuple[str, ...]]:
    base_env, base_secrets = _build_git_env()
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
    return _build_git_env(remote_url=remote_url, github_token=github_token)


def _list_candidate_open_prs(
    *,
    repo: str,
    pr_branch: str,
    github_token: str,
    base_branch: str | None = None,
    strict: bool = False,
    opener: urllib.request.OpenerDirector | None = None,
) -> list[dict[str, Any]]:
    owner = repo.split("/", 1)[0]
    params: dict[str, str] = {
        "state": "open",
        "head": f"{owner}:{pr_branch}",
    }
    if base_branch is not None:
        params["base"] = base_branch
    params["per_page"] = "100"
    query = urllib.parse.urlencode(params)
    url = f"https://api.github.com/repos/{repo}/pulls?{query}"
    payload = updater.github_api_request_json(
        url,
        github_token=github_token,
        opener=opener,
        api_label="GitHub Pull Requests API",
    )
    if not isinstance(payload, list):
        raise updater.UpdaterError("Unexpected GitHub Pull Requests API payload type")
    if len(payload) >= 100:
        raise updater.UpdaterError(
            f"GitHub Pull Requests API returned {len(payload)} open PRs for {pr_branch!r}; "
            "refusing potentially truncated inspection"
        )

    matching: list[dict[str, Any]] = []
    for item in payload:
        if not isinstance(item, dict):
            if strict:
                raise updater.UpdaterError("Malformed non-object entry in GitHub Pull Requests API response")
            continue
        head = item.get("head")
        base = item.get("base")
        if not isinstance(head, dict) or not isinstance(base, dict):
            if strict:
                raise updater.UpdaterError("Malformed PR entry missing head/base metadata")
            continue
        head_repo = head.get("repo")
        if head_repo is None:
            # Deleted fork repository; cannot belong to the same repository.
            continue
        if not isinstance(head_repo, dict):
            if strict:
                raise updater.UpdaterError("Malformed PR entry with non-object head.repo")
            continue
        head_full_name = str(head_repo.get("full_name") or "").lower()
        if head_full_name != repo.lower():
            continue
        if head.get("ref") != pr_branch:
            continue
        if item.get("state") != "open":
            if strict:
                raise updater.UpdaterError(
                    f"Unexpected non-open PR state {item.get('state')!r} in open PR listing"
                )
            continue
        base_ref = base.get("ref")
        if not isinstance(base_ref, str) or not base_ref.strip():
            if strict:
                raise updater.UpdaterError("Malformed PR entry missing base.ref")
            continue
        if base_branch is not None and base_ref != base_branch:
            continue
        if type(item.get("number")) is not int or item["number"] <= 0:
            if strict:
                raise updater.UpdaterError(f"Malformed PR number {item.get('number')!r}")
            continue
        matching.append(item)
    return matching


def _decode_changed_file_entries(
    raw_files: Any,
    *,
    max_entries: int,
) -> list[str] | None:
    """Decode GitHub PR/compare file entries, returning all affected paths or None if unverifiable.

    Includes both `filename` and `previous_filename` so renames out of or into
    unrelated paths cannot bypass the allowlist, and fails closed when a rename
    entry lacks a verifiable source path.
    """
    if not isinstance(raw_files, list) or len(raw_files) >= max_entries:
        return None
    paths: list[str] = []
    for entry in raw_files:
        if not isinstance(entry, dict):
            return None
        filename = entry.get("filename")
        if not isinstance(filename, str) or not filename:
            return None
        paths.append(filename)

        raw_status = entry.get("status")
        if raw_status is not None and not isinstance(raw_status, str):
            return None
        status_norm = raw_status.strip().lower() if isinstance(raw_status, str) else ""

        has_prev_key = "previous_filename" in entry and entry["previous_filename"] is not None
        prev_filename = entry.get("previous_filename")
        if has_prev_key:
            if not isinstance(prev_filename, str) or not prev_filename:
                return None
            paths.append(prev_filename)
        elif status_norm == "renamed":
            return None
    return paths


def _list_pr_changed_files(
    *,
    repo: str,
    pr_number: int,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> list[str] | None:
    """Return changed paths in the PR (including rename sources), or None if truncated/invalid."""
    url = (
        f"https://api.github.com/repos/{repo}/pulls/{pr_number}/files"
        f"?per_page={MAX_PR_FILES_PER_PAGE}"
    )
    payload = updater.github_api_request_json(
        url,
        github_token=github_token,
        opener=opener,
        api_label="GitHub Pull Request Files API",
    )
    return _decode_changed_file_entries(payload, max_entries=MAX_PR_FILES_PER_PAGE)


def _fetch_blob_git_shas(
    *,
    repo: str,
    ref: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> dict[str, str] | None:
    """Return {blob_relpath: git_blob_sha} for embedded blobs at ref, or None if unreadable."""
    encoded_dir = urllib.parse.quote(BLOBS_DIR_RELPATH, safe="/")
    query = urllib.parse.urlencode({"ref": ref})
    url = f"https://api.github.com/repos/{repo}/contents/{encoded_dir}?{query}"
    try:
        payload = updater.github_api_request_json(
            url,
            github_token=github_token,
            opener=opener,
            api_label="GitHub Contents API",
        )
    except updater.UpdaterError as exc:
        cause = exc.__cause__
        if isinstance(cause, urllib.error.HTTPError) and cause.code == 404:
            return None
        raise
    if not isinstance(payload, list):
        return None
    shas: dict[str, str] = {}
    for entry in payload:
        if not isinstance(entry, dict) or entry.get("type") != "file":
            continue
        path = entry.get("path")
        sha = entry.get("sha")
        if path in BLOB_RELPATHS and isinstance(sha, str) and sha:
            shas[path] = sha
    return shas if set(shas.keys()) == BLOB_RELPATHS else None


def _pr_blobs_match_target_branch(
    *,
    repo: str,
    head_ref: str,
    target_branch: str,
    changed_files: Sequence[str],
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> bool:
    """Return True only if PR touches only embedded blobs and all 3 blobs match target_branch."""
    if not changed_files:
        return True
    if not set(changed_files).issubset(BLOB_RELPATHS):
        return False
    head_shas = _fetch_blob_git_shas(
        repo=repo,
        ref=head_ref,
        github_token=github_token,
        opener=opener,
    )
    if head_shas is None:
        return False
    target_shas = _fetch_blob_git_shas(
        repo=repo,
        ref=target_branch,
        github_token=github_token,
        opener=opener,
    )
    if target_shas is None:
        return False
    return head_shas == target_shas


def _fetch_pr_manifest(
    *,
    repo: str,
    ref: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[str, dict[str, Any] | None]:
    """Return ('ok', manifest), ('missing', None), or ('invalid', None) for PR head manifest."""
    encoded_path = urllib.parse.quote(updater.MANIFEST_RELPATH, safe="/")
    query = urllib.parse.urlencode({"ref": ref})
    url = f"https://api.github.com/repos/{repo}/contents/{encoded_path}?{query}"
    try:
        payload = updater.github_api_request_json(
            url,
            github_token=github_token,
            opener=opener,
            api_label="GitHub Contents API",
        )
    except updater.UpdaterError as exc:
        cause = exc.__cause__
        if isinstance(cause, urllib.error.HTTPError) and cause.code == 404:
            return "missing", None
        raise

    if not isinstance(payload, dict) or payload.get("encoding") != "base64":
        return "invalid", None
    raw_content = payload.get("content")
    if not isinstance(raw_content, str):
        return "invalid", None
    try:
        decoded = base64.b64decode(raw_content, validate=False).decode("utf-8")
        parsed = json.loads(decoded)
        validated = updater.validate_provenance_manifest(
            parsed, source=f"{repo}@{ref}:{updater.MANIFEST_RELPATH}"
        )
    except (ValueError, UnicodeDecodeError, updater.UpdaterError):
        return "invalid", None
    return "ok", validated


def _classify_content_diff(
    *,
    repo: str,
    head_ref: str,
    target_branch: str,
    release_tag: str,
    changed_files: Sequence[str],
    github_token: str,
    protect_prerelease: bool,
    subject_label: str = "PR",
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[bool, str]:
    """Classify whether a set of changed files + head manifest represents a replaceable update."""
    if len(changed_files) == 0:
        return True, f"{subject_label} has no remaining diff against `{target_branch}`"

    changed_set = set(changed_files)
    allowed_paths = BLOB_RELPATHS | {updater.MANIFEST_RELPATH}
    if not changed_set.issubset(allowed_paths):
        return (
            False,
            f"{subject_label} modifies files outside embedded libznn blobs/manifest; "
            f"preserving {subject_label} for manual review",
        )
    touches_blobs = bool(changed_set & BLOB_RELPATHS)
    touches_manifest = updater.MANIFEST_RELPATH in changed_set

    # If blobs are modified without updating the manifest, any manifest at head is
    # inherited from the base branch and does not describe the blob changes.
    if touches_blobs and not touches_manifest:
        if _pr_blobs_match_target_branch(
            repo=repo,
            head_ref=head_ref,
            target_branch=target_branch,
            changed_files=changed_files,
            github_token=github_token,
            opener=opener,
        ):
            return (
                True,
                f"{subject_label} blob contents already match `{target_branch}` (no remaining binary diff)",
            )
        return (
            False,
            f"{subject_label} updates embedded blobs without updating `{updater.MANIFEST_RELPATH}` and "
            f"differs from `{target_branch}`; preserving {subject_label} for manual review",
        )

    manifest_status, pr_manifest = _fetch_pr_manifest(
        repo=repo,
        ref=head_ref,
        github_token=github_token,
        opener=opener,
    )
    if manifest_status == "ok" and pr_manifest is not None:
        if protect_prerelease and pr_manifest["release"].get("prerelease") is True:
            return False, f"{subject_label} provenance manifest targets a pre-release"
        pr_tag = str(pr_manifest["release"]["tag"])
        if pr_tag == release_tag:
            if protect_prerelease:
                return True, f"{subject_label} already targets `{pr_tag}`"
            return True, f"{subject_label} targets `{pr_tag}`, which `{target_branch}` already matches"
        tag_cmp = updater.compare_release_tags(pr_tag, release_tag)
        if tag_cmp is not None and tag_cmp < 0:
            if protect_prerelease:
                return (
                    True,
                    f"{subject_label} targets older release `{pr_tag}`, superseded by `{release_tag}`",
                )
            return (
                True,
                f"{subject_label} targets older release `{pr_tag}`, superseded by `{release_tag}` on `{target_branch}`",
            )
        return (
            False,
            f"{subject_label} targets `{pr_tag}`, which is not superseded by `{release_tag}`",
        )

    if manifest_status == "missing":
        return (
            False,
            f"{subject_label} head is missing `{updater.MANIFEST_RELPATH}` (deleted or absent); "
            f"preserving {subject_label} for manual review",
        )

    return (
        False,
        f"{subject_label} `{updater.MANIFEST_RELPATH}` could not be validated; "
        f"preserving {subject_label} for manual review",
    )


def _classify_rolling_pr(
    *,
    repo: str,
    pr: Mapping[str, Any],
    target_branch: str,
    release_tag: str,
    github_token: str,
    protect_prerelease_and_explicit: bool,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[bool, str]:
    """Evaluate whether an open rolling-branch PR can be closed/superseded.

    Fails safe (False) unless the PR is proven to be a replaceable automated
    libznn update for `release_tag` or an older superseded release.
    """
    base = pr.get("base")
    pr_base_ref = str(base.get("ref") or "") if isinstance(base, Mapping) else ""
    if pr_base_ref != target_branch:
        if pr_base_ref:
            return (
                False,
                f"PR targets base branch `{pr_base_ref}` instead of `{target_branch}`; "
                "preserving PR for manual review",
            )
        return (
            False,
            f"PR base branch could not be verified against `{target_branch}`; "
            "preserving PR for manual review",
        )

    marker_reason = protected_pr_marker_reason(
        pr,
        protect_prerelease_and_explicit=protect_prerelease_and_explicit,
    )
    if marker_reason is not None:
        return False, marker_reason

    pr_number = int(pr["number"])
    head = pr["head"]
    raw_head_sha = head.get("sha")
    if protect_prerelease_and_explicit:
        try:
            head_ref = updater.validate_git_commit_sha(
                raw_head_sha, label=f"PR #{pr_number} head SHA"
            )
        except updater.UpdaterError:
            return (
                False,
                "PR head commit SHA could not be verified; preserving PR for manual review",
            )
    else:
        head_ref = str(raw_head_sha or head.get("ref") or "")

    changed_files = _list_pr_changed_files(
        repo=repo,
        pr_number=pr_number,
        github_token=github_token,
        opener=opener,
    )
    if changed_files is None:
        return (
            False,
            "PR file list could not be verified or exceeded 100 files; preserving PR for manual review",
        )
    return _classify_content_diff(
        repo=repo,
        head_ref=head_ref,
        target_branch=target_branch,
        release_tag=release_tag,
        changed_files=changed_files,
        github_token=github_token,
        protect_prerelease=protect_prerelease_and_explicit,
        subject_label="PR",
        opener=opener,
    )


def _classify_pr_staleness(
    *,
    repo: str,
    pr: Mapping[str, Any],
    target_branch: str,
    release_tag: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[bool, str]:
    """Return (is_stale, reason). Fails safe (False) when staleness cannot be proven."""
    return _classify_rolling_pr(
        repo=repo,
        pr=pr,
        target_branch=target_branch,
        release_tag=release_tag,
        github_token=github_token,
        protect_prerelease_and_explicit=False,
        opener=opener,
    )


def _classify_pr_overwrite_safety(
    *,
    repo: str,
    pr: Mapping[str, Any],
    target_branch: str,
    release_tag: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[bool, str]:
    """Return (safe_to_overwrite, reason) for a rolling update PR branch. Fails safe (False)."""
    return _classify_rolling_pr(
        repo=repo,
        pr=pr,
        target_branch=target_branch,
        release_tag=release_tag,
        github_token=github_token,
        protect_prerelease_and_explicit=True,
        opener=opener,
    )


def _resolve_remote_branch_head(
    *,
    repo: str,
    pr_branch: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[str, str]:
    """Resolve remote refs/heads/<pr_branch> to ('present', sha) or ('absent', '')."""
    encoded_branch = urllib.parse.quote(pr_branch, safe="/")
    url = f"https://api.github.com/repos/{repo}/git/ref/heads/{encoded_branch}"
    try:
        payload = updater.github_api_request_json(
            url,
            github_token=github_token,
            opener=opener,
            api_label="GitHub Git Ref API",
        )
    except updater.UpdaterError as exc:
        cause = exc.__cause__
        if isinstance(cause, urllib.error.HTTPError) and cause.code == 404:
            return "absent", ""
        raise

    expected_ref = f"refs/heads/{pr_branch}"
    matched_entry: Mapping[str, Any] | None = None
    if isinstance(payload, dict):
        if payload.get("ref") != expected_ref:
            raise updater.UpdaterError(
                f"Unexpected GitHub Git Ref API response for {expected_ref!r} ({url})"
            )
        matched_entry = payload
    elif isinstance(payload, list):
        for entry in payload:
            if isinstance(entry, dict) and entry.get("ref") == expected_ref:
                matched_entry = entry
                break
        if matched_entry is None:
            return "absent", ""
    else:
        raise updater.UpdaterError(
            f"Unexpected GitHub Git Ref API payload type for {expected_ref!r} ({url})"
        )

    obj = matched_entry.get("object")
    if not isinstance(obj, dict):
        raise updater.UpdaterError(f"Missing object metadata for branch ref {expected_ref!r}")
    obj_type = obj.get("type")
    if obj_type != "commit":
        raise updater.UpdaterError(
            f"Expected branch ref {expected_ref!r} to resolve to a commit, got {obj_type!r}"
        )
    sha = updater.validate_git_commit_sha(
        obj.get("sha"), label=f"branch {pr_branch!r} head SHA"
    )
    return "present", sha


def _inspect_compare_commits_for_downgrade(payload: Mapping[str, Any]) -> tuple[str, str]:
    """Inspect compare commits for downgrade markers and verify list completeness.

    Returns:
      ("downgrade", reason)  if any visible commit carries a forced-downgrade marker
      ("incomplete", reason) if the commit list is missing, truncated, or malformed
      ("clean", "")          only when all `ahead_by` commits were inspected and clean
    """
    raw_commits = payload.get("commits")
    malformed_entry = False
    if isinstance(raw_commits, list):
        for entry in raw_commits:
            if not isinstance(entry, dict):
                malformed_entry = True
                continue
            commit_obj = entry.get("commit")
            if not isinstance(commit_obj, dict):
                malformed_entry = True
                continue
            raw_message = commit_obj.get("message")
            if not isinstance(raw_message, str):
                malformed_entry = True
                continue
            subject = raw_message.splitlines()[0] if raw_message else ""
            if DOWNGRADE_TITLE_FLAG_PATTERN.search(subject):
                return "downgrade", "commit subject carries downgrade flag"
            if "- Forced downgrade from " in raw_message or "**Forced downgrade:**" in raw_message:
                return "downgrade", "commit message carries forced-downgrade marker"

    ahead_by = payload.get("ahead_by")
    if type(ahead_by) is not int or ahead_by < 0:
        return "incomplete", f"missing or invalid ahead_by ({ahead_by!r})"
    if not isinstance(raw_commits, list):
        return "incomplete", "compare response omitted commits list"
    if malformed_entry:
        return "incomplete", "compare response contained malformed commit entry"
    if len(raw_commits) < ahead_by:
        return (
            "incomplete",
            f"compare response returned only {len(raw_commits)} of {ahead_by} ahead commit(s)",
        )
    if "total_commits" in payload and payload["total_commits"] is not None:
        total_commits = payload["total_commits"]
        if type(total_commits) is not int or total_commits < 0:
            return "incomplete", f"invalid total_commits ({total_commits!r})"
        if len(raw_commits) < total_commits:
            return (
                "incomplete",
                f"compare response returned only {len(raw_commits)} of {total_commits} total commit(s)",
            )
    return "clean", ""


def _classify_orphan_branch_head(
    *,
    repo: str,
    target_branch: str,
    head_sha: str,
    release_tag: str,
    github_token: str,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[bool, str]:
    """Classify an existing remote rolling branch that currently has no open PR.

    Handles both normal merge leftovers (ahead_by == 0) and squash/rebase-merged
    or closed automated rolling branches (by inspecting compare files and head
    provenance manifest). Fails safe (False) on any non-libznn, prerelease,
    downgrade, newer-tag, or unverifiable diff.
    """
    encoded_target = urllib.parse.quote(target_branch, safe="")
    url = f"https://api.github.com/repos/{repo}/compare/{encoded_target}...{head_sha}"
    try:
        payload = updater.github_api_request_json(
            url,
            github_token=github_token,
            opener=opener,
            api_label="GitHub Compare API",
        )
    except updater.UpdaterError as exc:
        cause = exc.__cause__
        if isinstance(cause, urllib.error.HTTPError) and cause.code == 404:
            return (
                False,
                f"Remote branch head `{head_sha[:12]}` could not be compared against "
                f"`{target_branch}`; preserving branch for manual review",
            )
        raise

    if not isinstance(payload, dict):
        raise updater.UpdaterError(
            f"Unexpected GitHub Compare API payload type for {target_branch}...{head_sha}"
        )
    status = payload.get("status")
    ahead_by = payload.get("ahead_by")
    if status in {"identical", "behind"} and type(ahead_by) is int and ahead_by == 0:
        return True, f"Remote branch head `{head_sha[:12]}` is already merged into `{target_branch}`"

    commit_status, commit_detail = _inspect_compare_commits_for_downgrade(payload)
    if commit_status == "downgrade":
        return (
            False,
            f"Remote branch `{head_sha[:12]}` contains an intentional forced downgrade commit; "
            "preserving branch for manual review",
        )
    if commit_status != "clean":
        return (
            False,
            f"Remote branch `{head_sha[:12]}` commit list could not be fully verified for downgrade "
            f"markers ({commit_detail}); preserving branch for manual review",
        )

    changed_files = _decode_changed_file_entries(
        payload.get("files"),
        max_entries=MAX_COMPARE_FILES,
    )
    if changed_files is None:
        ahead_desc = (
            f"ahead by {ahead_by} commit(s)"
            if type(ahead_by) is int
            else f"status={status!r}"
        )
        return (
            False,
            f"Remote branch exists at `{head_sha[:12]}` with no open PR ({ahead_desc} relative to "
            f"`{target_branch}`) and its changed file list could not be verified; preserving branch for manual review",
        )

    return _classify_content_diff(
        repo=repo,
        head_ref=head_sha,
        target_branch=target_branch,
        release_tag=release_tag,
        changed_files=changed_files,
        github_token=github_token,
        protect_prerelease=True,
        subject_label="Remote branch",
        opener=opener,
    )


def check_pr_branch_safe_to_update(
    *,
    repo: str,
    target_branch: str,
    pr_branch: str,
    release_tag: str,
    github_token: str,
    github_output: pathlib.Path | None = None,
    step_summary: pathlib.Path | None = None,
    opener: urllib.request.OpenerDirector | None = None,
) -> PrUpdateGuardResult:
    """Inspect open PRs on the rolling branch and report whether force-updating is safe."""
    validated_repo = updater.validate_upstream_repo(repo)
    validated_target = updater.validate_target_branch(target_branch)
    validated_branch = validate_pr_branch(pr_branch, validated_target)
    validated_tag = updater.validate_tag(release_tag)
    if not validated_tag:
        raise updater.UpdaterError("A non-empty --release-tag is required")
    if not github_token or not github_token.strip():
        raise updater.UpdaterError("GitHub token is required to inspect open pull requests")

    updater.validate_output_file_paths(
        (
            ("--github-output", github_output),
            ("--step-summary", step_summary),
        )
    )

    # Query without a base filter so PRs retargeted to another base (e.g. master)
    # on this head branch are still inspected and protected.
    open_prs = _list_candidate_open_prs(
        repo=validated_repo,
        pr_branch=validated_branch,
        base_branch=None,
        strict=True,
        github_token=github_token,
        opener=opener,
    )

    blocking: list[PreservedPullRequest] = []
    updatable: list[PreservedPullRequest] = []
    for pr in open_prs:
        pr_number = int(pr["number"])
        pr_url = str(pr.get("html_url") or f"https://github.com/{validated_repo}/pull/{pr_number}")
        safe, reason = _classify_pr_overwrite_safety(
            repo=validated_repo,
            pr=pr,
            target_branch=validated_target,
            release_tag=validated_tag,
            github_token=github_token,
            opener=opener,
        )
        entry = PreservedPullRequest(number=pr_number, html_url=pr_url, reason=reason)
        if safe:
            updatable.append(entry)
        else:
            blocking.append(entry)

    safe_to_update = False
    expected_head_state = ""
    expected_head_oid = ""
    blocking_reason: str | None = None
    inspected_pr_numbers: tuple[int, ...] = ()

    if not blocking:
        head_state, head_oid = _resolve_remote_branch_head(
            repo=validated_repo,
            pr_branch=validated_branch,
            github_token=github_token,
            opener=opener,
        )
        if open_prs:
            if head_state != "present":
                raise updater.UpdaterError(
                    f"Remote branch {validated_branch!r} is absent after inspecting open PR(s); "
                    "refusing to update without re-classification"
                )
            for pr in open_prs:
                pr_number = int(pr["number"])
                pr_head_sha = updater.validate_git_commit_sha(
                    pr["head"].get("sha"), label=f"PR #{pr_number} head SHA"
                )
                if pr_head_sha != head_oid:
                    raise updater.UpdaterError(
                        f"Head drift detected for {validated_branch!r}: PR #{pr_number} was "
                        f"inspected at {pr_head_sha}, but remote ref is at {head_oid}; "
                        "re-run to classify the new head"
                    )
            safe_to_update = True
            expected_head_state = "present"
            expected_head_oid = head_oid
            inspected_pr_numbers = tuple(sorted(item.number for item in updatable))
        elif head_state == "absent":
            safe_to_update = True
            expected_head_state = "absent"
            expected_head_oid = ""
            inspected_pr_numbers = ()
        else:
            orphan_safe, orphan_reason = _classify_orphan_branch_head(
                repo=validated_repo,
                target_branch=validated_target,
                head_sha=head_oid,
                release_tag=validated_tag,
                github_token=github_token,
                opener=opener,
            )
            if orphan_safe:
                safe_to_update = True
                expected_head_state = "present"
                expected_head_oid = head_oid
                inspected_pr_numbers = ()
            else:
                safe_to_update = False
                blocking_reason = orphan_reason

    result = PrUpdateGuardResult(
        safe_to_update=safe_to_update,
        blocking_prs=tuple(blocking),
        updatable_prs=tuple(updatable),
        expected_head_state=expected_head_state,
        expected_head_oid=expected_head_oid,
        blocking_reason=blocking_reason,
        inspected_pr_numbers=inspected_pr_numbers,
    )

    if result.safe_to_update:
        inspected_prs_output = (
            ",".join(str(num) for num in result.inspected_pr_numbers)
            if result.inspected_pr_numbers
            else "none"
        )
    else:
        inspected_prs_output = ""

    if github_output is not None:
        try:
            github_output.parent.mkdir(parents=True, exist_ok=True)
            updater.write_github_outputs(
                github_output,
                {
                    "safe_to_update": "true" if result.safe_to_update else "false",
                    "expected_head_state": result.expected_head_state,
                    "expected_head_oid": result.expected_head_oid,
                    "inspected_pr_numbers": inspected_prs_output,
                    "blocking_pr_count": str(len(result.blocking_prs)),
                    "blocking_pr_urls": ",".join(item.html_url for item in result.blocking_prs),
                    "blocking_reason": result.blocking_reason or "",
                },
            )
        except OSError as exc:
            raise updater.UpdaterError(f"Failed writing GITHUB_OUTPUT {github_output}: {exc}") from exc

    if step_summary is not None and not result.safe_to_update:
        summary_lines = [
            "",
            "### Pull request",
            (
                f"- Skipped updating rolling branch `{validated_branch}` -> `{validated_target}` "
                f"for `{validated_tag}` to avoid overwriting protected branch state:"
            ),
        ]
        for kept in result.blocking_prs:
            summary_lines.append(
                f"  - Preserved open PR #{kept.number} ({kept.html_url}): {kept.reason}."
            )
        if result.blocking_reason:
            summary_lines.append(f"  - {result.blocking_reason}.")
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


def _build_close_comment(
    *,
    target_branch: str,
    release_tag: str,
    reason: str,
    workflow_run_url: str | None = None,
) -> str:
    run_suffix = f" ([workflow run]({workflow_run_url}))" if workflow_run_url else ""
    return (
        f"Closing this automated pull request because `{target_branch}` is already up to date "
        f"with `go-zenon` `{release_tag}` ({reason}){run_suffix}."
    )


def _delete_stale_branch(
    *,
    pr_branch: str,
    expected_head_oid: str,
    repo_root: pathlib.Path,
    remote: str,
    github_token: str,
    git_env: Mapping[str, str] | None = None,
    git_secrets: Sequence[str] | None = None,
) -> tuple[str, str | None]:
    """Atomically delete `refs/heads/<pr_branch>` only if it still points to `expected_head_oid`."""
    validated_sha = updater.validate_git_commit_sha(
        expected_head_oid, label=f"expected stale branch {pr_branch!r} head SHA"
    )
    if git_env is None or git_secrets is None:
        git_env, git_secrets = _prepare_git_remote_env(
            repo_root=repo_root,
            remote=remote,
            github_token=github_token,
        )

    delete_proc = _run_git(
        [
            "push",
            f"--force-with-lease=refs/heads/{pr_branch}:{validated_sha}",
            remote,
            f":refs/heads/{pr_branch}",
        ],
        repo_root=repo_root,
        env=git_env,
        secrets_to_mask=git_secrets,
        check=False,
    )
    if delete_proc.returncode == 0:
        return "deleted", None

    detail = _scrub_secrets(
        (delete_proc.stderr or delete_proc.stdout or f"exit status {delete_proc.returncode}").strip(),
        git_secrets,
    )
    try:
        cur_state, cur_oid = _resolve_remote_head_via_ls_remote(
            repo_root=repo_root,
            remote=remote,
            pr_branch=pr_branch,
            env=git_env,
            secrets_to_mask=git_secrets,
        )
    except updater.UpdaterError as verify_exc:
        raise updater.UpdaterError(
            f"Failed to atomically delete stale branch {pr_branch!r} at {validated_sha}: {detail} "
            f"(and follow-up remote ref inspection failed: {verify_exc})"
        ) from verify_exc

    if cur_state == "absent":
        return "already_deleted", None
    if cur_oid != validated_sha:
        return (
            "not_needed",
            f"Skipped deleting `{pr_branch}` because remote head moved from "
            f"`{validated_sha[:12]}` to `{cur_oid[:12]}` before atomic delete",
        )
    raise updater.UpdaterError(
        f"Failed to atomically delete stale branch {pr_branch!r} at {validated_sha}: {detail}"
    )


def close_stale_libznn_prs(
    *,
    repo: str,
    target_branch: str,
    pr_branch: str,
    release_tag: str,
    github_token: str,
    repo_root: pathlib.Path | None = None,
    remote: str = "origin",
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

    if repo_root is None:
        raise updater.UpdaterError(
            "--repo-root is required when closing stale pull requests "
            f"(needed to atomically delete stale branch {validated_branch!r})"
        )

    git_env, git_secrets = _prepare_git_remote_env(
        repo_root=repo_root,
        remote=remote,
        github_token=github_token,
    )

    open_prs = _list_candidate_open_prs(
        repo=validated_repo,
        pr_branch=validated_branch,
        base_branch=validated_target,
        github_token=github_token,
        opener=opener,
    )

    closed: list[ClosedPullRequest] = []
    preserved: list[PreservedPullRequest] = []
    closed_head_shas: set[str] = set()

    for pr in open_prs:
        pr_number = int(pr["number"])
        pr_url = str(pr.get("html_url") or f"https://github.com/{validated_repo}/pull/{pr_number}")
        is_stale, reason = _classify_pr_staleness(
            repo=validated_repo,
            pr=pr,
            target_branch=validated_target,
            release_tag=validated_tag,
            github_token=github_token,
            opener=opener,
        )
        if not is_stale:
            preserved.append(PreservedPullRequest(number=pr_number, html_url=pr_url, reason=reason))
            continue

        raw_head_sha = (pr.get("head") or {}).get("sha")
        if isinstance(raw_head_sha, str) and updater.GIT_COMMIT_SHA_PATTERN.fullmatch(
            raw_head_sha.strip()
        ):
            closed_head_shas.add(raw_head_sha.strip().lower())

        # Close first so retries after a failed close never post duplicate comments.
        close_url = f"https://api.github.com/repos/{validated_repo}/pulls/{pr_number}"
        updater.github_api_request_json(
            close_url,
            method="PATCH",
            body={"state": "closed"},
            github_token=github_token,
            opener=opener,
            api_label="GitHub Pull Requests API",
        )
        # Record the close immediately and isolate comment failures so branch cleanup still runs.
        comment_warning: str | None = None
        comment_body = _build_close_comment(
            target_branch=validated_target,
            release_tag=validated_tag,
            reason=reason,
            workflow_run_url=workflow_run_url,
        )
        comment_url = f"https://api.github.com/repos/{validated_repo}/issues/{pr_number}/comments"
        try:
            updater.github_api_request_json(
                comment_url,
                method="POST",
                body={"body": comment_body},
                github_token=github_token,
                opener=opener,
                api_label="GitHub Issue Comments API",
            )
        except updater.UpdaterError as exc:
            comment_warning = str(exc)
            print(
                f"WARNING: closed stale PR #{pr_number} but failed to post closing comment: {exc}",
                file=sys.stderr,
            )
        closed.append(
            ClosedPullRequest(
                number=pr_number,
                html_url=pr_url,
                reason=reason,
                comment_warning=comment_warning,
            )
        )

    branch_skip_note: str | None = None
    if closed and not preserved:
        # Before deleting the head branch, verify no open PR remains on any base branch
        # (e.g. a second PR targeting master) and the remote ref still matches the head we inspected.
        remaining_open_prs = _list_candidate_open_prs(
            repo=validated_repo,
            pr_branch=validated_branch,
            base_branch=None,
            strict=True,
            github_token=github_token,
            opener=opener,
        )
        if remaining_open_prs:
            remaining_desc = ", ".join(f"#{int(item['number'])}" for item in remaining_open_prs)
            branch_status = "not_needed"
            branch_skip_note = (
                f"Skipped deleting `{validated_branch}` because other open PR(s) still reference it "
                f"({remaining_desc})"
            )
        else:
            head_state, head_oid = _resolve_remote_branch_head(
                repo=validated_repo,
                pr_branch=validated_branch,
                github_token=github_token,
                opener=opener,
            )
            if head_state == "absent":
                branch_status = "already_deleted"
            elif head_oid not in closed_head_shas:
                branch_status = "not_needed"
                branch_skip_note = (
                    f"Skipped deleting `{validated_branch}` because remote head `{head_oid[:12]}` "
                    "moved after stale-PR classification"
                )
            else:
                branch_status, branch_skip_note = _delete_stale_branch(
                    pr_branch=validated_branch,
                    expected_head_oid=head_oid,
                    repo_root=repo_root,
                    remote=remote,
                    github_token=github_token,
                    git_env=git_env,
                    git_secrets=git_secrets,
                )
    else:
        branch_status = "not_needed"

    result = StalePrCleanupResult(
        closed_prs=tuple(closed),
        preserved_prs=tuple(preserved),
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
                    "preserved_count": str(len(result.preserved_prs)),
                    "preserved_pr_urls": ",".join(item.html_url for item in result.preserved_prs),
                    "branch_deleted": result.branch_deleted,
                },
            )
        except OSError as exc:
            raise updater.UpdaterError(f"Failed writing GITHUB_OUTPUT {github_output}: {exc}") from exc

    if step_summary is not None:
        summary_lines = ["", "### Stale pull request cleanup"]
        if result.closed_prs:
            for item in result.closed_prs:
                note = (
                    f" (warning: closing comment failed: {item.comment_warning})"
                    if item.comment_warning
                    else ""
                )
                summary_lines.append(
                    f"- Closed stale PR #{item.number} ({item.html_url}): {item.reason}.{note}"
                )
            summary_lines.append(
                f"- Branch `{validated_branch}` deletion status: `{result.branch_deleted}`."
            )
            if branch_skip_note:
                summary_lines.append(f"- {branch_skip_note}.")
        if result.preserved_prs:
            for kept in result.preserved_prs:
                summary_lines.append(
                    f"- Preserved open PR #{kept.number} ({kept.html_url}): {kept.reason}."
                )
        if not result.closed_prs and not result.preserved_prs:
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
        "--check-update-safe",
        action="store_true",
        help="Read-only check: verify no protected open PR on --pr-branch would be overwritten.",
    )
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=None,
        help="Path to checked-out repository working tree (required for atomic branch cleanup).",
    )
    parser.add_argument(
        "--remote",
        default="origin",
        help="Git remote name used for atomic stale-branch deletion (default: origin).",
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
    if args.check_update_safe:
        try:
            guard_result = check_pr_branch_safe_to_update(
                repo=args.repo,
                target_branch=args.target_branch,
                pr_branch=args.pr_branch,
                release_tag=args.release_tag,
                github_token=token,
                github_output=args.github_output,
                step_summary=args.step_summary,
            )
        except updater.UpdaterError as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            return 1

        if guard_result.safe_to_update:
            head_desc = (
                f"expected head {guard_result.expected_head_oid}"
                if guard_result.expected_head_state == "present"
                else "remote branch absent"
            )
            print(
                f"Rolling PR branch {args.pr_branch} -> {args.target_branch} is safe to update "
                f"for {args.release_tag} ({head_desc})."
            )
            return 0

        in_github_actions = os.environ.get("GITHUB_ACTIONS") == "true"
        for kept in guard_result.blocking_prs:
            msg = (
                f"Skipping rolling PR update on {args.pr_branch} -> {args.target_branch} "
                f"for {args.release_tag} to preserve open PR #{kept.number} ({kept.html_url}): "
                f"{kept.reason}."
            )
            if in_github_actions:
                print(f"::warning::{msg}")
            else:
                print(f"WARNING: {msg}", file=sys.stderr)
        if guard_result.blocking_reason:
            msg = (
                f"Blocking rolling PR update on {args.pr_branch} -> {args.target_branch} "
                f"for {args.release_tag}: {guard_result.blocking_reason}."
            )
            if in_github_actions:
                print(f"::error::{msg}")
            else:
                print(f"ERROR: {msg}", file=sys.stderr)
            return 1
        return 0

    try:
        result = close_stale_libznn_prs(
            repo=args.repo,
            target_branch=args.target_branch,
            pr_branch=args.pr_branch,
            release_tag=args.release_tag,
            github_token=token,
            repo_root=args.repo_root,
            remote=args.remote,
            workflow_run_url=updater.workflow_run_url_from_env(),
            github_output=args.github_output,
            step_summary=args.step_summary,
        )
    except updater.UpdaterError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if result.closed_prs:
        for item in result.closed_prs:
            print(f"Closed stale automated PR #{item.number}: {item.html_url} ({item.reason})")
        print(f"Branch {args.pr_branch} cleanup status: {result.branch_deleted}")
    if result.preserved_prs:
        for kept in result.preserved_prs:
            print(f"Preserved open PR #{kept.number}: {kept.html_url} ({kept.reason})")
    if not result.closed_prs and not result.preserved_prs:
        print(
            f"No stale automated pull request open for {args.pr_branch} -> {args.target_branch}."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
