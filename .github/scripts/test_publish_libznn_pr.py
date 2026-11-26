#!/usr/bin/env python3
"""Unit tests for .github/scripts/publish_libznn_pr.py using real bare Git repositories."""

from __future__ import annotations

import base64
import io
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest
import urllib.error
import urllib.request
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import publish_libznn_pr as publish_pr
import update_libznn as updater


class _FakeResponse:
    def __init__(self, payload: bytes) -> None:
        self._stream = io.BytesIO(payload)

    def read(self, size: int = -1) -> bytes:
        return self._stream.read(size)

    def __enter__(self) -> _FakeResponse:
        return self

    def __exit__(self, *args: Any) -> None:
        self._stream.close()


class _RecordingOpener:
    def __init__(self, handlers: dict[tuple[str, str], Any]) -> None:
        self.handlers = handlers
        self.requests: list[tuple[str, str, Any]] = []

    def open(self, req: urllib.request.Request, timeout: int = 60) -> _FakeResponse:
        method = req.get_method()
        body = json.loads(req.data.decode("utf-8")) if req.data else None
        self.requests.append((method, req.full_url, body))
        key = (method, req.full_url)
        if key not in self.handlers:
            raise AssertionError(f"Unexpected request: {method} {req.full_url}")
        outcome = self.handlers[key]
        if isinstance(outcome, Exception):
            raise outcome
        return _FakeResponse(outcome)


def _git(args: list[str], cwd: pathlib.Path) -> str:
    proc = subprocess.run(
        ["git", *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        check=True,
    )
    return proc.stdout.strip()


def _pr_obj(
    *,
    number: int,
    title: str,
    body: str,
    head_ref: str,
    head_sha: str,
    base_ref: str = "develop",
    head_repo: str = "zenon-network/syrius",
) -> dict[str, Any]:
    return {
        "number": number,
        "state": "open",
        "title": title,
        "body": body,
        "html_url": f"https://github.com/zenon-network/syrius/pull/{number}",
        "head": {
            "ref": head_ref,
            "sha": head_sha,
            "repo": {"full_name": head_repo},
        },
        "base": {
            "ref": base_ref,
            "sha": "0" * 40,
        },
    }


class PublishLibznnPrTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmpdir.name)
        self.bare_repo = self.root / "remote.git"
        self.seed_repo = self.root / "seed"
        self.work_repo = self.root / "target-repo"

        _git(["init", "--bare", "-b", "develop", str(self.bare_repo)], self.root)
        _git(["clone", str(self.bare_repo), str(self.seed_repo)], self.root)
        _git(["config", "user.name", "Maintainer"], self.seed_repo)
        _git(["config", "user.email", "maintainer@example.com"], self.seed_repo)

        self._write_blobs(self.seed_repo, version="v0.0.9")
        _git(["add", "."], self.seed_repo)
        _git(["commit", "--no-gpg-sign", "-m", "initial blobs v0.0.9"], self.seed_repo)
        _git(["push", "origin", "develop"], self.seed_repo)

        self._reclone_work_repo()

        self.rolling_branch = "chore/update-libznn-develop"
        self.list_rolling_head_only_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-develop&per_page=100"
        )
        self.create_pr_url = "https://api.github.com/repos/zenon-network/syrius/pulls"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _reclone_work_repo(self) -> None:
        if self.work_repo.exists():
            import shutil

            shutil.rmtree(self.work_repo)
        # Shallow clone matching actions/checkout defaults.
        _git(
            [
                "clone",
                "--depth=1",
                "--branch",
                "develop",
                f"file://{self.bare_repo}",
                str(self.work_repo),
            ],
            self.root,
        )

    def _write_blobs(self, repo_path: pathlib.Path, *, version: str) -> None:
        blobs_dir = repo_path / "lib" / "embedded_node" / "blobs"
        blobs_dir.mkdir(parents=True, exist_ok=True)
        (blobs_dir / "libznn.so").write_bytes(b"\x7fELF" + version.encode("utf-8"))
        (blobs_dir / "libznn.dylib").write_bytes(b"\xca\xfe\xba\xbe" + version.encode("utf-8"))
        (blobs_dir / "libznn.dll").write_bytes(b"MZ" + version.encode("utf-8"))
        (blobs_dir / "libznn.manifest.json").write_text(
            json.dumps({"version": version}, indent=2) + "\n",
            encoding="utf-8",
        )

    def _bare_ref_sha(self, branch: str) -> str | None:
        proc = subprocess.run(
            ["git", "rev-parse", "--verify", f"refs/heads/{branch}"],
            cwd=str(self.bare_repo),
            capture_output=True,
            text=True,
            check=False,
        )
        return proc.stdout.strip() if proc.returncode == 0 else None

    def _push_concurrent_commit(self, branch: str, *, note: str) -> str:
        _git(["fetch", "origin"], self.seed_repo)
        existing = self._bare_ref_sha(branch)
        if existing:
            _git(["checkout", "-B", branch, f"origin/{branch}"], self.seed_repo)
        else:
            _git(["checkout", "-B", branch, "origin/develop"], self.seed_repo)
        (self.seed_repo / "MAINTAINER_NOTE.md").write_text(f"{note}\n", encoding="utf-8")
        _git(["add", "MAINTAINER_NOTE.md"], self.seed_repo)
        _git(["commit", "--no-gpg-sign", "-m", f"maintainer commit: {note}"], self.seed_repo)
        sha = _git(["rev-parse", "HEAD"], self.seed_repo)
        _git(["push", "origin", f"HEAD:refs/heads/{branch}"], self.seed_repo)
        return sha

    def test_missing_ref_create_pushes_with_empty_lease_and_creates_pr(self) -> None:
        self._write_blobs(self.work_repo, version="v0.0.10")
        gh_out = self.root / "create.out"
        opener = _RecordingOpener(
            {
                ("GET", self.list_rolling_head_only_url): b"[]",
                ("POST", self.create_pr_url): json.dumps(
                    {
                        "number": 401,
                        "html_url": "https://github.com/zenon-network/syrius/pull/401",
                    }
                ).encode("utf-8"),
            }
        )

        result = publish_pr.publish_libznn_pr(
            repo="zenon-network/syrius",
            repo_root=self.work_repo,
            target_branch="develop",
            pr_branch=self.rolling_branch,
            pr_title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
            pr_body="Updated binaries to v0.0.10-alphanet.\n",
            commit_message="chore: update embedded libznn to go-zenon v0.0.10-alphanet\n\nDetails",
            github_token="ghs_test",
            require_expected_head=True,
            expected_head_state="absent",
            expected_head_oid="",
            expected_pr_numbers="none",
            github_output=gh_out,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertEqual(result.operation, "created")
        self.assertEqual(result.pr_number, 401)
        self.assertEqual(result.pr_url, "https://github.com/zenon-network/syrius/pull/401")
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), result.pushed_commit_sha)
        # Local develop ref was not mutated because we committed on detached HEAD.
        self.assertEqual(
            _git(["rev-parse", "refs/heads/develop"], self.work_repo),
            self._bare_ref_sha("develop"),
        )
        out_text = gh_out.read_text(encoding="utf-8")
        self.assertIn("pull-request-operation=created\n", out_text)
        self.assertIn("pull-request-number=401\n", out_text)
        self.assertIn(f"pull-request-branch={self.rolling_branch}\n", out_text)

    def test_missing_ref_aborts_atomically_if_branch_created_concurrently(self) -> None:
        # Maintainer creates the rolling branch AFTER pr_guard saw it absent.
        maintainer_sha = self._push_concurrent_commit(self.rolling_branch, note="wip")
        self._write_blobs(self.work_repo, version="v0.0.10")
        summary = self.root / "race_absent.md"
        opener = _RecordingOpener({("GET", self.list_rolling_head_only_url): b"[]"})

        with self.assertRaisesRegex(updater.UpdaterError, "Atomic push aborted"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                pr_body="body\n",
                commit_message="commit msg",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="absent",
                expected_head_oid="",
                expected_pr_numbers="none",
                step_summary=summary,
                opener=opener,  # type: ignore[arg-type]
            )
        # Maintainer commit MUST remain intact on the remote!
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), maintainer_sha)
        self.assertIn("Atomic push aborted", summary.read_text(encoding="utf-8"))

    def test_existing_ref_lease_match_updates_branch_and_patches_pr(self) -> None:
        # First create an older rolling PR branch on the bare remote.
        self._write_blobs(self.work_repo, version="v0.0.10")
        opener_first = _RecordingOpener(
            {
                ("GET", self.list_rolling_head_only_url): b"[]",
                ("POST", self.create_pr_url): json.dumps(
                    {
                        "number": 402,
                        "html_url": "https://github.com/zenon-network/syrius/pull/402",
                    }
                ).encode("utf-8"),
            }
        )
        first = publish_pr.publish_libznn_pr(
            repo="zenon-network/syrius",
            repo_root=self.work_repo,
            target_branch="develop",
            pr_branch=self.rolling_branch,
            pr_title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
            pr_body="v0.0.10 body\n",
            commit_message="commit v0.0.10",
            github_token="ghs_test",
            require_expected_head=True,
            expected_head_state="absent",
            expected_head_oid="",
            expected_pr_numbers="none",
            opener=opener_first,  # type: ignore[arg-type]
        )
        old_sha = first.pushed_commit_sha

        # Now supersede with v0.0.11 from a fresh shallow checkout using the approved old_sha lease.
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11")
        patch_url = "https://api.github.com/repos/zenon-network/syrius/pulls/402"
        existing_pr = _pr_obj(
            number=402,
            title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
            body="v0.0.10 body\n",
            head_ref=self.rolling_branch,
            head_sha=old_sha,
        )
        opener_second = _RecordingOpener(
            {
                ("GET", self.list_rolling_head_only_url): json.dumps([existing_pr]).encode("utf-8"),
                ("PATCH", patch_url): json.dumps(
                    {
                        "number": 402,
                        "html_url": "https://github.com/zenon-network/syrius/pull/402",
                    }
                ).encode("utf-8"),
            }
        )
        second = publish_pr.publish_libznn_pr(
            repo="zenon-network/syrius",
            repo_root=self.work_repo,
            target_branch="develop",
            pr_branch=self.rolling_branch,
            pr_title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
            pr_body="v0.0.11 body\n",
            commit_message="commit v0.0.11",
            github_token="ghs_test",
            require_expected_head=True,
            expected_head_state="present",
            expected_head_oid=old_sha,
            expected_pr_numbers="402",
            opener=opener_second,  # type: ignore[arg-type]
        )
        self.assertEqual(second.operation, "updated")
        self.assertNotEqual(second.pushed_commit_sha, old_sha)
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), second.pushed_commit_sha)
        self.assertEqual([r[0] for r in opener_second.requests], ["GET", "PATCH"])

    def test_existing_ref_lease_mismatch_aborts_and_preserves_maintainer_commit(self) -> None:
        # Seed remote rolling branch at old_sha, then simulate a concurrent maintainer commit.
        old_sha = self._push_concurrent_commit(self.rolling_branch, note="initial-pr")
        maintainer_sha = self._push_concurrent_commit(self.rolling_branch, note="maintainer-fix")
        self.assertNotEqual(old_sha, maintainer_sha)

        # Case 1: No open PR (post-merge leftover branch at old_sha) — direct git --force-with-lease rejects!
        self._write_blobs(self.work_repo, version="v0.0.11")
        summary = self.root / "lease_mismatch.md"
        opener_no_pr = _RecordingOpener({("GET", self.list_rolling_head_only_url): b"[]"})
        with self.assertRaisesRegex(updater.UpdaterError, "Atomic push aborted"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
                pr_body="body\n",
                commit_message="commit v0.0.11",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=old_sha,
                expected_pr_numbers="none",
                step_summary=summary,
                opener=opener_no_pr,  # type: ignore[arg-type]
            )
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), maintainer_sha)
        self.assertIn("Atomic push aborted", summary.read_text(encoding="utf-8"))

        # Case 2: Open PR listing still stale (old_sha), remote ref already at maintainer_sha -> fetch check aborts!
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11")
        stale_pr_entry = _pr_obj(
            number=403,
            title="old",
            body="old\n",
            head_ref=self.rolling_branch,
            head_sha=old_sha,
        )
        opener_stale_pr = _RecordingOpener(
            {("GET", self.list_rolling_head_only_url): json.dumps([stale_pr_entry]).encode("utf-8")}
        )
        with self.assertRaisesRegex(updater.UpdaterError, "moved from approved head"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
                pr_body="body\n",
                commit_message="commit v0.0.11",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=old_sha,
                expected_pr_numbers="403",
                opener=opener_stale_pr,  # type: ignore[arg-type]
            )
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), maintainer_sha)

        # Case 3: Open PR listing already reports maintainer_sha while expected_head_oid is old_sha -> pre-push abort!
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11")
        moved_pr_entry = _pr_obj(
            number=403,
            title="old",
            body="old\n",
            head_ref=self.rolling_branch,
            head_sha=maintainer_sha,
        )
        opener_moved_pr = _RecordingOpener(
            {("GET", self.list_rolling_head_only_url): json.dumps([moved_pr_entry]).encode("utf-8")}
        )
        with self.assertRaisesRegex(updater.UpdaterError, "moved from approved head"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
                pr_body="body\n",
                commit_message="commit v0.0.11",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=old_sha,
                expected_pr_numbers="403",
                opener=opener_moved_pr,  # type: ignore[arg-type]
            )
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), maintainer_sha)

        # Case 4: Uninspected PR opened on the exact same OID after pr_guard saw none -> aborts!
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11")
        unexpected_pr = _pr_obj(
            number=499,
            title="chore: downgrade (downgrade)",
            body="**Forced downgrade:** intentional\n",
            head_ref=self.rolling_branch,
            head_sha=maintainer_sha,
        )
        opener_uninspected = _RecordingOpener(
            {("GET", self.list_rolling_head_only_url): json.dumps([unexpected_pr]).encode("utf-8")}
        )
        with self.assertRaisesRegex(updater.UpdaterError, "open PR set on .* changed after pr_guard"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
                pr_body="body\n",
                commit_message="commit v0.0.11",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=maintainer_sha,
                expected_pr_numbers="none",
                opener=opener_uninspected,  # type: ignore[arg-type]
            )
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), maintainer_sha)

    def test_unchanged_remote_commit_skips_redundant_force_push(self) -> None:
        self._write_blobs(self.work_repo, version="v0.0.10")
        pr_title = "chore: update embedded libznn to go-zenon v0.0.10-alphanet"
        pr_body = "Same body\n"
        opener_first = _RecordingOpener(
            {
                ("GET", self.list_rolling_head_only_url): b"[]",
                ("POST", self.create_pr_url): json.dumps(
                    {
                        "number": 404,
                        "html_url": "https://github.com/zenon-network/syrius/pull/404",
                    }
                ).encode("utf-8"),
            }
        )
        first = publish_pr.publish_libznn_pr(
            repo="zenon-network/syrius",
            repo_root=self.work_repo,
            target_branch="develop",
            pr_branch=self.rolling_branch,
            pr_title=pr_title,
            pr_body=pr_body,
            commit_message="commit v0.0.10",
            github_token="ghs_test",
            require_expected_head=True,
            expected_head_state="absent",
            expected_head_oid="",
            expected_pr_numbers="none",
            opener=opener_first,  # type: ignore[arg-type]
        )
        first_sha = first.pushed_commit_sha

        # Re-run with identical staged blobs/manifest and identical PR metadata -> NO push, NO PATCH!
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.10")
        existing = _pr_obj(
            number=404,
            title=pr_title,
            body=pr_body,
            head_ref=self.rolling_branch,
            head_sha=first_sha,
        )
        opener_second = _RecordingOpener(
            {("GET", self.list_rolling_head_only_url): json.dumps([existing]).encode("utf-8")}
        )
        second = publish_pr.publish_libznn_pr(
            repo="zenon-network/syrius",
            repo_root=self.work_repo,
            target_branch="develop",
            pr_branch=self.rolling_branch,
            pr_title=pr_title,
            pr_body=pr_body,
            commit_message="commit v0.0.10 (re-run)",
            github_token="ghs_test",
            require_expected_head=True,
            expected_head_state="present",
            expected_head_oid=first_sha,
            expected_pr_numbers="404",
            opener=opener_second,  # type: ignore[arg-type]
        )
        self.assertEqual(second.operation, "unchanged")
        self.assertEqual(second.pushed_commit_sha, "")
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), first_sha)
        self.assertEqual([r[0] for r in opener_second.requests], ["GET"])

    def test_retargeted_pr_on_other_base_aborts_before_push(self) -> None:
        old_sha = self._push_concurrent_commit(self.rolling_branch, note="retargeted")
        self._write_blobs(self.work_repo, version="v0.0.11")
        retargeted = _pr_obj(
            number=405,
            title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
            body="body\n",
            head_ref=self.rolling_branch,
            head_sha=old_sha,
            base_ref="master",
        )
        opener = _RecordingOpener(
            {("GET", self.list_rolling_head_only_url): json.dumps([retargeted]).encode("utf-8")}
        )
        with self.assertRaisesRegex(updater.UpdaterError, "target a base branch other than 'develop'"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
                pr_body="body\n",
                commit_message="commit v0.0.11",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=old_sha,
                expected_pr_numbers="none",
                opener=opener,  # type: ignore[arg-type]
            )
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), old_sha)

    def test_tag_scoped_branch_publishes_without_guard_and_protects_retargeted_and_rollback(self) -> None:
        tag_branch = "chore/update-libznn-develop-v0.0.11-rc.1"
        list_tag_head_only_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-develop-v0.0.11-rc.1&per_page=100"
        )
        # 1. Tag-scoped PR retargeted to master aborts before push.
        retargeted_tag_pr = _pr_obj(
            number=407,
            title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
            body="rc body\n",
            head_ref=tag_branch,
            head_sha="a" * 40,
            base_ref="master",
        )
        self._write_blobs(self.work_repo, version="v0.0.11-rc.1")
        opener_retargeted = _RecordingOpener(
            {("GET", list_tag_head_only_url): json.dumps([retargeted_tag_pr]).encode("utf-8")}
        )
        with self.assertRaisesRegex(updater.UpdaterError, "target a base branch other than 'develop'"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=tag_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
                pr_body="rc body\n",
                commit_message="commit rc.1",
                github_token="ghs_test",
                opener=opener_retargeted,  # type: ignore[arg-type]
            )
        self.assertIsNone(self._bare_ref_sha(tag_branch))

        # 2. POST /pulls fails with HTTP 403 -> newly created remote branch is conditionally rolled back.
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11-rc.1")
        opener_fail = _RecordingOpener(
            {
                ("GET", list_tag_head_only_url): b"[]",
                ("POST", self.create_pr_url): urllib.error.HTTPError(
                    self.create_pr_url, 403, "Forbidden", {}, None  # type: ignore[arg-type]
                ),
            }
        )
        with self.assertRaisesRegex(updater.UpdaterError, "HTTP 403"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=tag_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
                pr_body="rc body\n",
                commit_message="commit rc.1",
                github_token="ghs_test",
                opener=opener_fail,  # type: ignore[arg-type]
            )
        self.assertIsNone(self._bare_ref_sha(tag_branch))

        # 3. Successful publish on tag-scoped branch creates branch and PR.
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11-rc.1")
        opener_ok = _RecordingOpener(
            {
                ("GET", list_tag_head_only_url): b"[]",
                ("POST", self.create_pr_url): json.dumps(
                    {
                        "number": 406,
                        "html_url": "https://github.com/zenon-network/syrius/pull/406",
                    }
                ).encode("utf-8"),
            }
        )
        res = publish_pr.publish_libznn_pr(
            repo="zenon-network/syrius",
            repo_root=self.work_repo,
            target_branch="develop",
            pr_branch=tag_branch,
            pr_title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
            pr_body="rc body\n",
            commit_message="commit rc.1",
            github_token="ghs_test",
            opener=opener_ok,  # type: ignore[arg-type]
        )
        self.assertEqual(res.operation, "created")
        self.assertEqual(self._bare_ref_sha(tag_branch), res.pushed_commit_sha)

        # 4. POST /pulls fails after overwriting an existing branch (present) -> guarded REST restore to old OID!
        prev_sha = res.pushed_commit_sha
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11-rc.2")
        get_ref_url = f"https://api.github.com/repos/zenon-network/syrius/git/ref/heads/{tag_branch}"
        patch_ref_url = f"https://api.github.com/repos/zenon-network/syrius/git/refs/heads/{tag_branch}"

        class _RestoreCheckOpener(_RecordingOpener):
            def open(self, req: urllib.request.Request, timeout: int = 60) -> _FakeResponse:
                if req.get_method() == "GET" and req.full_url == get_ref_url:
                    self.requests.append(("GET", req.full_url, None))
                    # Simulate GitHub returning the newly pushed SHA at rollback check time.
                    pushed_now = _git(["rev-parse", f"refs/heads/{tag_branch}"], bare_repo_ref)
                    return _FakeResponse(
                        json.dumps(
                            {
                                "ref": f"refs/heads/{tag_branch}",
                                "object": {"type": "commit", "sha": pushed_now},
                            }
                        ).encode("utf-8")
                    )
                return super().open(req, timeout=timeout)

        bare_repo_ref = self.bare_repo
        opener_restore = _RestoreCheckOpener(
            {
                ("GET", list_tag_head_only_url): b"[]",
                ("POST", self.create_pr_url): urllib.error.HTTPError(
                    self.create_pr_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                ),
                ("PATCH", patch_ref_url): json.dumps({"ref": f"refs/heads/{tag_branch}"}).encode(
                    "utf-8"
                ),
            }
        )
        with self.assertRaisesRegex(updater.UpdaterError, "HTTP 422"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=tag_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-rc.2 (prerelease)",
                pr_body="rc2 body\n",
                commit_message="commit rc.2",
                github_token="ghs_test",
                opener=opener_restore,  # type: ignore[arg-type]
            )
        patch_calls = [r for r in opener_restore.requests if r[0] == "PATCH" and r[1] == patch_ref_url]
        self.assertEqual(len(patch_calls), 1)
        self.assertEqual(patch_calls[0][2], {"sha": prev_sha, "force": True})

    def test_validation_and_secret_scrubbing(self) -> None:
        # Rolling branch ALWAYS refuses missing expected_head_state even if require_expected_head=False.
        self._write_blobs(self.work_repo, version="v0.0.10")
        with self.assertRaisesRegex(updater.UpdaterError, "without a valid --expected-head-state"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="title",
                pr_body="body\n",
                commit_message="msg",
                github_token="ghs_test",
            )

        # Auth header is injected ONLY for https://github.com/... remotes and scrubbed from text.
        secret = "ghs_super_secret_token_12345"
        env_gh, mask_gh = publish_pr._build_git_env(
            remote_url="https://github.com/zenon-network/syrius.git",
            github_token=secret,
        )
        self.assertEqual(env_gh["GIT_CONFIG_KEY_0"], "http.https://github.com/.extraheader")
        expected_b64 = base64.b64encode(f"x-access-token:{secret}".encode("utf-8")).decode("ascii")
        self.assertIn(expected_b64, env_gh["GIT_CONFIG_VALUE_0"])
        scrubbed = publish_pr._scrub_secrets(
            f"failed with {secret} and {expected_b64}", mask_gh
        )
        self.assertNotIn(secret, scrubbed)
        self.assertNotIn(expected_b64, scrubbed)

        env_other, _ = publish_pr._build_git_env(
            remote_url="https://evil.example.com/zenon-network/syrius.git",
            github_token=secret,
        )
        self.assertNotIn("GIT_CONFIG_KEY_0", env_other)

        # Rejects unexpected pre-staged files outside the 4 updater paths.
        (self.work_repo / "unexpected.txt").write_text("bad\n", encoding="utf-8")
        _git(["add", "unexpected.txt"], self.work_repo)
        with self.assertRaisesRegex(updater.UpdaterError, "unexpected staged files"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="title",
                pr_body="body\n",
                commit_message="msg",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="absent",
                expected_head_oid="",
                expected_pr_numbers="none",
            )

    def test_cli_main_reads_body_file_and_commit_message_env(self) -> None:
        self._write_blobs(self.work_repo, version="v0.0.10")
        body_file = self.root / "pr-body.md"
        body_file.write_text("PR body from file\n", encoding="utf-8")
        gh_out = self.root / "cli.out"
        opener = _RecordingOpener(
            {
                ("GET", self.list_rolling_head_only_url): b"[]",
                ("POST", self.create_pr_url): json.dumps(
                    {
                        "number": 410,
                        "html_url": "https://github.com/zenon-network/syrius/pull/410",
                    }
                ).encode("utf-8"),
            }
        )
        orig_build_opener = updater._build_opener
        orig_token = os.environ.get("GH_TOKEN")
        orig_commit = os.environ.get("COMMIT_MESSAGE")
        stdout_buf = io.StringIO()
        old_stdout = sys.stdout
        try:
            updater._build_opener = lambda: opener  # type: ignore[assignment]
            os.environ["GH_TOKEN"] = "ghs_cli_test"
            os.environ["COMMIT_MESSAGE"] = "chore: update embedded libznn\n\nBody line"
            sys.stdout = stdout_buf
            rc = publish_pr.main(
                [
                    "--repo",
                    "zenon-network/syrius",
                    "--repo-root",
                    str(self.work_repo),
                    "--target-branch",
                    "develop",
                    "--pr-branch",
                    self.rolling_branch,
                    "--pr-title",
                    "chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                    "--pr-body-file",
                    str(body_file),
                    "--commit-message-env",
                    "COMMIT_MESSAGE",
                    "--require-expected-head",
                    "--expected-head-state",
                    "absent",
                    "--expected-head-oid",
                    "",
                    "--expected-pr-numbers",
                    "none",
                    "--github-output",
                    str(gh_out),
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            sys.stdout = old_stdout
            if orig_token is None:
                os.environ.pop("GH_TOKEN", None)
            else:
                os.environ["GH_TOKEN"] = orig_token
            if orig_commit is None:
                os.environ.pop("COMMIT_MESSAGE", None)
            else:
                os.environ["COMMIT_MESSAGE"] = orig_commit

        self.assertEqual(rc, 0)
        self.assertIn("Pull request created:", stdout_buf.getvalue())
        self.assertIn("pull-request-number=410\n", gh_out.read_text(encoding="utf-8"))
        # Verify commit message in bare repo matches multiline env var.
        pushed_sha = self._bare_ref_sha(self.rolling_branch)
        self.assertIsNotNone(pushed_sha)
        msg = _git(["log", "-1", "--format=%B", pushed_sha or ""], self.bare_repo)
        self.assertIn("Body line", msg)


if __name__ == "__main__":
    unittest.main()
