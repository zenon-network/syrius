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

    def test_tag_scoped_branch_publishes_without_guard_and_preserves_pushed_ref_on_post_failure(
        self,
    ) -> None:
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

        # 2. POST /pulls fails with HTTP 403 and no open PR -> leave newly pushed branch intact
        #    (no rollback/delete) and report failure, pushed SHA, and retry instructions.
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11-rc.1")
        summary_403 = self.root / "tag_403.md"
        opener_fail = _RecordingOpener(
            {
                ("GET", list_tag_head_only_url): b"[]",
                ("POST", self.create_pr_url): urllib.error.HTTPError(
                    self.create_pr_url, 403, "Forbidden", {}, None  # type: ignore[arg-type]
                ),
            }
        )
        with self.assertRaises(updater.UpdaterError) as ctx_403:
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=tag_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
                pr_body="rc body\n",
                commit_message="commit rc.1",
                github_token="ghs_test",
                step_summary=summary_403,
                opener=opener_fail,  # type: ignore[arg-type]
            )
        pushed_403_sha = self._bare_ref_sha(tag_branch)
        self.assertIsNotNone(pushed_403_sha)
        assert pushed_403_sha is not None
        self.assertIn("HTTP 403", str(ctx_403.exception))
        self.assertIn(pushed_403_sha, str(ctx_403.exception))
        self.assertIn("re-run the workflow to retry", str(ctx_403.exception))
        # Must have performed pre-push GET, POST, and post-failure GET lookup.
        self.assertEqual([r[0] for r in opener_fail.requests], ["GET", "POST", "GET"])
        summary_403_text = summary_403.read_text(encoding="utf-8")
        self.assertIn("HTTP 403", summary_403_text)
        self.assertIn(pushed_403_sha, summary_403_text)
        self.assertIn("re-run the workflow to retry", summary_403_text)

        # 3. Retry succeeds cleanly over the intact branch and creates the PR.
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

        # 4. POST /pulls fails with HTTP 422 after overwriting an existing branch (present -> B)
        #    with no open PR -> leave B intact (never roll back to A, avoiding PR-head race).
        prev_sha = res.pushed_commit_sha
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11-rc.2")
        summary_422 = self.root / "tag_422.md"
        opener_422 = _RecordingOpener(
            {
                ("GET", list_tag_head_only_url): b"[]",
                ("POST", self.create_pr_url): urllib.error.HTTPError(
                    self.create_pr_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                ),
            }
        )
        with self.assertRaises(updater.UpdaterError) as ctx_422:
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=tag_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.11-rc.2 (prerelease)",
                pr_body="rc2 body\n",
                commit_message="commit rc.2",
                github_token="ghs_test",
                step_summary=summary_422,
                opener=opener_422,  # type: ignore[arg-type]
            )
        pushed_422_sha = self._bare_ref_sha(tag_branch)
        self.assertIsNotNone(pushed_422_sha)
        assert pushed_422_sha is not None
        self.assertNotEqual(pushed_422_sha, prev_sha)
        self.assertEqual([r[0] for r in opener_422.requests], ["GET", "POST", "GET"])
        self.assertIn("HTTP 422", str(ctx_422.exception))
        self.assertIn(pushed_422_sha, str(ctx_422.exception))
        self.assertIn("not rolling back", str(ctx_422.exception))
        self.assertIn(pushed_422_sha, summary_422.read_text(encoding="utf-8"))

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

    def test_rejects_staged_rename_into_manifest_and_handles_special_filenames(self) -> None:
        # Remove manifest on develop and add an unrelated file whose content matches a manifest,
        # so default git rename detection would classify `git mv` as a pure rename.
        _git(["checkout", "develop"], self.seed_repo)
        manifest_seed = self.seed_repo / updater.MANIFEST_RELPATH
        manifest_content = manifest_seed.read_text(encoding="utf-8")
        manifest_seed.unlink()
        (self.seed_repo / "unrelated.json").write_text(manifest_content, encoding="utf-8")
        _git(["add", "-A"], self.seed_repo)
        _git(["commit", "--no-gpg-sign", "-m", "drop manifest and add unrelated file"], self.seed_repo)
        _git(["push", "origin", "develop"], self.seed_repo)

        self._reclone_work_repo()
        _git(["mv", "unrelated.json", updater.MANIFEST_RELPATH], self.work_repo)

        with self.assertRaisesRegex(updater.UpdaterError, r"unexpected staged files.*unrelated\.json"):
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

        # Also verify filenames with embedded newlines are parsed safely via -z.
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.10")
        weird_name = "bad\nname.txt"
        (self.work_repo / weird_name).write_text("oops\n", encoding="utf-8")
        _git(["add", "--", weird_name], self.work_repo)
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

    def test_aborts_before_push_if_existing_guarded_pr_gains_protection_marker(self) -> None:
        old_sha = self._push_concurrent_commit(self.rolling_branch, note="guarded-old")
        protected_cases = [
            (
                "forced-downgrade-body",
                "chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                "> **Forced downgrade:** intentional\n",
                "forced downgrade",
            ),
            (
                "prerelease-title",
                "chore: update embedded libznn to go-zenon v0.0.10-rc.1 (prerelease)",
                "body\n",
                "pre-release",
            ),
            (
                "explicit-tag-body",
                "chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                "- **Selection mode:** explicit tag (`v0.0.10-alphanet`)\n",
                "explicit-tag",
            ),
        ]
        for label, title, body, expected_reason in protected_cases:
            with self.subTest(case=label):
                self._reclone_work_repo()
                self._write_blobs(self.work_repo, version="v0.0.11")
                summary = self.root / f"marker_{label}.md"
                pr_rec = _pr_obj(
                    number=420,
                    title=title,
                    body=body,
                    head_ref=self.rolling_branch,
                    head_sha=old_sha,
                )
                opener = _RecordingOpener(
                    {
                        ("GET", self.list_rolling_head_only_url): json.dumps([pr_rec]).encode(
                            "utf-8"
                        )
                    }
                )
                with self.assertRaisesRegex(
                    updater.UpdaterError, f"protection marker.*{expected_reason}"
                ):
                    publish_pr.publish_libznn_pr(
                        repo="zenon-network/syrius",
                        repo_root=self.work_repo,
                        target_branch="develop",
                        pr_branch=self.rolling_branch,
                        pr_title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
                        pr_body="new body\n",
                        commit_message="commit v0.0.11",
                        github_token="ghs_test",
                        require_expected_head=True,
                        expected_head_state="present",
                        expected_head_oid=old_sha,
                        expected_pr_numbers="420",
                        step_summary=summary,
                        opener=opener,  # type: ignore[arg-type]
                    )
                self.assertEqual(self._bare_ref_sha(self.rolling_branch), old_sha)
                self.assertIn("protection marker", summary.read_text(encoding="utf-8"))

        # Unguarded tag-scoped PRs legitimately carry prerelease/explicit-tag markers and still update.
        tag_branch = "chore/update-libznn-develop-v0.0.11-rc.1"
        tag_sha = self._push_concurrent_commit(tag_branch, note="tag-old")
        list_tag_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-develop-v0.0.11-rc.1&per_page=100"
        )
        patch_tag_url = "https://api.github.com/repos/zenon-network/syrius/pulls/421"
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.11-rc.1")
        tag_pr = _pr_obj(
            number=421,
            title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
            body="- **Selection mode:** explicit tag (`v0.0.11-rc.1`)\n",
            head_ref=tag_branch,
            head_sha=tag_sha,
        )
        opener_tag = _RecordingOpener(
            {
                ("GET", list_tag_url): json.dumps([tag_pr]).encode("utf-8"),
                ("PATCH", patch_tag_url): json.dumps(
                    {
                        "number": 421,
                        "html_url": "https://github.com/zenon-network/syrius/pull/421",
                    }
                ).encode("utf-8"),
            }
        )
        updated_tag = publish_pr.publish_libznn_pr(
            repo="zenon-network/syrius",
            repo_root=self.work_repo,
            target_branch="develop",
            pr_branch=tag_branch,
            pr_title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
            pr_body="- **Selection mode:** explicit tag (`v0.0.11-rc.1`)\nUpdated\n",
            commit_message="commit rc.1 refresh",
            github_token="ghs_test",
            opener=opener_tag,  # type: ignore[arg-type]
        )
        self.assertEqual(updated_tag.operation, "updated")
        self.assertNotEqual(self._bare_ref_sha(tag_branch), tag_sha)

    def test_ambiguous_post_failure_reconciles_existing_pr_or_preserves_ref(self) -> None:
        # Helper opener supporting sequential GET /pulls responses.
        class _SequentialListOpener(_RecordingOpener):
            def __init__(self, handlers: dict[tuple[str, str], Any], list_seq: list[Any]) -> None:
                super().__init__(handlers)
                self._list_seq = list(list_seq)

            def open(self, req: urllib.request.Request, timeout: int = 60) -> _FakeResponse:
                if req.get_method() == "GET" and req.full_url == list_url:
                    self.requests.append(("GET", req.full_url, None))
                    outcome = self._list_seq.pop(0)
                    if callable(outcome):
                        outcome = outcome()
                    if isinstance(outcome, Exception):
                        raise outcome
                    return _FakeResponse(outcome)
                return super().open(req, timeout=timeout)

        list_url = self.list_rolling_head_only_url
        orig_sleep = updater.time.sleep
        updater.time.sleep = lambda _s: None  # type: ignore[assignment]
        try:
            # 1. Ambiguous POST timeout, but GitHub actually created PR #450 at the pushed SHA -> reconcile!
            prev_sha = self._push_concurrent_commit(self.rolling_branch, note="orphan-prev")
            self._reclone_work_repo()
            self._write_blobs(self.work_repo, version="v0.0.11")
            gh_out = self.root / "reconcile.out"

            def _return_created_pr() -> bytes:
                pushed_now = self._bare_ref_sha(self.rolling_branch)
                assert pushed_now is not None
                return json.dumps(
                    [
                        _pr_obj(
                            number=450,
                            title="chore: update embedded libznn to go-zenon v0.0.11-alphanet",
                            body="body\n",
                            head_ref=self.rolling_branch,
                            head_sha=pushed_now,
                        )
                    ]
                ).encode("utf-8")

            opener_reconcile = _SequentialListOpener(
                {("POST", self.create_pr_url): TimeoutError("read timed out")},
                list_seq=[b"[]", _return_created_pr],
            )
            stderr_buf = io.StringIO()
            old_stderr = sys.stderr
            try:
                sys.stderr = stderr_buf
                res = publish_pr.publish_libznn_pr(
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
                    expected_head_oid=prev_sha,
                    expected_pr_numbers="none",
                    github_output=gh_out,
                    opener=opener_reconcile,  # type: ignore[arg-type]
                )
            finally:
                sys.stderr = old_stderr
            self.assertEqual(res.operation, "created")
            self.assertEqual(res.pr_number, 450)
            self.assertEqual(self._bare_ref_sha(self.rolling_branch), res.pushed_commit_sha)
            self.assertNotEqual(res.pushed_commit_sha, prev_sha)
            self.assertIn("reconciling as created", stderr_buf.getvalue())
            self.assertIn("pull-request-number=450\n", gh_out.read_text(encoding="utf-8"))

            # 2. Ambiguous POST 502 AND follow-up GET /pulls also fails -> leave ref intact and report retry!
            prev_sha2 = self._bare_ref_sha(self.rolling_branch)
            assert prev_sha2 is not None
            self._reclone_work_repo()
            self._write_blobs(self.work_repo, version="v0.0.12")
            summary_unver = self.root / "unverifiable.md"
            opener_unver = _SequentialListOpener(
                {
                    ("POST", self.create_pr_url): urllib.error.HTTPError(
                        self.create_pr_url, 502, "Bad Gateway", {}, None  # type: ignore[arg-type]
                    )
                },
                list_seq=[
                    b"[]",
                    urllib.error.HTTPError(
                        list_url, 500, "Internal Server Error", {}, None  # type: ignore[arg-type]
                    ),
                    urllib.error.HTTPError(
                        list_url, 500, "Internal Server Error", {}, None  # type: ignore[arg-type]
                    ),
                    urllib.error.HTTPError(
                        list_url, 500, "Internal Server Error", {}, None  # type: ignore[arg-type]
                    ),
                ],
            )
            with self.assertRaisesRegex(
                updater.UpdaterError, "Leaving remote branch .* intact .* retry"
            ):
                publish_pr.publish_libznn_pr(
                    repo="zenon-network/syrius",
                    repo_root=self.work_repo,
                    target_branch="develop",
                    pr_branch=self.rolling_branch,
                    pr_title="chore: update embedded libznn to go-zenon v0.0.12-alphanet",
                    pr_body="body\n",
                    commit_message="commit v0.0.12",
                    github_token="ghs_test",
                    require_expected_head=True,
                    expected_head_state="present",
                    expected_head_oid=prev_sha2,
                    expected_pr_numbers="none",
                    step_summary=summary_unver,
                    opener=opener_unver,  # type: ignore[arg-type]
                )
            # Remote ref MUST stay at the newly pushed commit (not rolled back to prev_sha2)!
            self.assertNotEqual(self._bare_ref_sha(self.rolling_branch), prev_sha2)
            self.assertIn("re-run the workflow to retry", summary_unver.read_text(encoding="utf-8"))

            # 3. Ambiguous POST timeout + follow-up GET confirms NO PR exists -> leaves pushed B
            #    intact (no rollback) and reports timeout, pushed SHA, and retry instructions.
            prev_sha3 = self._bare_ref_sha(self.rolling_branch)
            assert prev_sha3 is not None
            self._reclone_work_repo()
            self._write_blobs(self.work_repo, version="v0.0.13")
            summary_no_pr = self.root / "ambiguous_no_pr.md"
            opener_no_pr = _SequentialListOpener(
                {("POST", self.create_pr_url): TimeoutError("timed out")},
                list_seq=[b"[]", b"[]"],
            )
            with self.assertRaises(updater.UpdaterError) as ctx_no_pr:
                publish_pr.publish_libznn_pr(
                    repo="zenon-network/syrius",
                    repo_root=self.work_repo,
                    target_branch="develop",
                    pr_branch=self.rolling_branch,
                    pr_title="chore: update embedded libznn to go-zenon v0.0.13-alphanet",
                    pr_body="body\n",
                    commit_message="commit v0.0.13",
                    github_token="ghs_test",
                    require_expected_head=True,
                    expected_head_state="present",
                    expected_head_oid=prev_sha3,
                    expected_pr_numbers="none",
                    step_summary=summary_no_pr,
                    opener=opener_no_pr,  # type: ignore[arg-type]
                )
            pushed_no_pr_sha = self._bare_ref_sha(self.rolling_branch)
            self.assertIsNotNone(pushed_no_pr_sha)
            assert pushed_no_pr_sha is not None
            self.assertNotEqual(pushed_no_pr_sha, prev_sha3)
            self.assertIn("timed out", str(ctx_no_pr.exception))
            self.assertIn(pushed_no_pr_sha, str(ctx_no_pr.exception))
            self.assertIn("not rolling back", str(ctx_no_pr.exception))
            self.assertIn("re-run the workflow to retry", summary_no_pr.read_text(encoding="utf-8"))
        finally:
            updater.time.sleep = orig_sleep

    def test_definite_post_rejection_reconciles_or_preserves_branch_for_concurrent_prs(
        self,
    ) -> None:
        list_url = self.list_rolling_head_only_url

        class _SequentialListOpener(_RecordingOpener):
            def __init__(self, handlers: dict[tuple[str, str], Any], list_seq: list[Any]) -> None:
                super().__init__(handlers)
                self._list_seq = list(list_seq)

            def open(self, req: urllib.request.Request, timeout: int = 60) -> _FakeResponse:
                if req.get_method() == "GET" and req.full_url == list_url:
                    self.requests.append(("GET", req.full_url, None))
                    outcome = self._list_seq.pop(0)
                    if callable(outcome):
                        outcome = outcome()
                    if isinstance(outcome, Exception):
                        raise outcome
                    return _FakeResponse(outcome)
                return super().open(req, timeout=timeout)

        # 1. HTTP 422 when the exact expected PR already exists at pushed commit B -> reconcile!
        sha_a = self._push_concurrent_commit(self.rolling_branch, note="older-orphan-a")
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.14")
        gh_out_422 = self.root / "reconcile_422.out"

        def _expected_pr_at_b() -> bytes:
            pushed_b = self._bare_ref_sha(self.rolling_branch)
            assert pushed_b is not None
            return json.dumps(
                [
                    _pr_obj(
                        number=460,
                        title="chore: update embedded libznn to go-zenon v0.0.14-alphanet",
                        body="v0.0.14 body\r\n",
                        head_ref=self.rolling_branch,
                        head_sha=pushed_b,
                    )
                ]
            ).encode("utf-8")

        opener_422_match = _SequentialListOpener(
            {
                ("POST", self.create_pr_url): urllib.error.HTTPError(
                    self.create_pr_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                )
            },
            list_seq=[b"[]", _expected_pr_at_b],
        )
        stderr_reconcile = io.StringIO()
        old_stderr = sys.stderr
        try:
            sys.stderr = stderr_reconcile
            res_match = publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.14-alphanet",
                pr_body="v0.0.14 body\n",
                commit_message="commit v0.0.14",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=sha_a,
                expected_pr_numbers="none",
                github_output=gh_out_422,
                opener=opener_422_match,  # type: ignore[arg-type]
            )
        finally:
            sys.stderr = old_stderr
        self.assertEqual(res_match.operation, "created")
        self.assertEqual(res_match.pr_number, 460)
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), res_match.pushed_commit_sha)
        self.assertNotEqual(res_match.pushed_commit_sha, sha_a)
        self.assertIn("reconciling as created", stderr_reconcile.getvalue())
        self.assertIn("pull-request-number=460\n", gh_out_422.read_text(encoding="utf-8"))

        # 2. HTTP 422 when a maintainer opened a DIFFERENT PR #461 at B right after push ->
        #    do NOT reconcile falsely and do NOT roll back B (preserving PR #461's head!),
        #    reporting HTTP 422, PR #461, pushed SHA, and retry instructions via CLI stderr + summary.
        prev_sha = res_match.pushed_commit_sha
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.15")
        body_file = self.root / "pr-461-body.md"
        body_file.write_text("v0.0.15 automated body\n", encoding="utf-8")
        summary_461 = self.root / "pr-461-summary.md"

        def _maintainer_pr_at_b() -> bytes:
            pushed_b = self._bare_ref_sha(self.rolling_branch)
            assert pushed_b is not None
            return json.dumps(
                [
                    _pr_obj(
                        number=461,
                        title="WIP: maintainer manual PR for libznn",
                        body="Opened manually after push.\n",
                        head_ref=self.rolling_branch,
                        head_sha=pushed_b,
                    )
                ]
            ).encode("utf-8")

        opener_422_diff = _SequentialListOpener(
            {
                ("POST", self.create_pr_url): urllib.error.HTTPError(
                    self.create_pr_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                )
            },
            list_seq=[b"[]", _maintainer_pr_at_b],
        )
        orig_build_opener = updater._build_opener
        orig_token = os.environ.get("GH_TOKEN")
        orig_commit = os.environ.get("COMMIT_MESSAGE")
        stderr_cli = io.StringIO()
        old_stderr = sys.stderr
        try:
            updater._build_opener = lambda: opener_422_diff  # type: ignore[assignment]
            os.environ["GH_TOKEN"] = "ghs_cli_422_test"
            os.environ["COMMIT_MESSAGE"] = "commit v0.0.15"
            sys.stderr = stderr_cli
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
                    "chore: update embedded libznn to go-zenon v0.0.15-alphanet",
                    "--pr-body-file",
                    str(body_file),
                    "--commit-message-env",
                    "COMMIT_MESSAGE",
                    "--require-expected-head",
                    "--expected-head-state",
                    "present",
                    "--expected-head-oid",
                    prev_sha,
                    "--expected-pr-numbers",
                    "none",
                    "--step-summary",
                    str(summary_461),
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            sys.stderr = old_stderr
            if orig_token is None:
                os.environ.pop("GH_TOKEN", None)
            else:
                os.environ["GH_TOKEN"] = orig_token
            if orig_commit is None:
                os.environ.pop("COMMIT_MESSAGE", None)
            else:
                os.environ["COMMIT_MESSAGE"] = orig_commit

        self.assertEqual(rc, 1)
        pushed_b_461 = self._bare_ref_sha(self.rolling_branch)
        self.assertIsNotNone(pushed_b_461)
        assert pushed_b_461 is not None
        # Remote ref MUST stay at pushed B (NOT rolled back to prev_sha)!
        self.assertNotEqual(pushed_b_461, prev_sha)
        stderr_text = stderr_cli.getvalue()
        summary_text = summary_461.read_text(encoding="utf-8")
        for output_text in (stderr_text, summary_text):
            self.assertIn("HTTP 422", output_text)
            self.assertIn("#461", output_text)
            self.assertIn(pushed_b_461, output_text)
            self.assertIn("not rolling back", output_text)
            self.assertIn("re-run the workflow to retry", output_text)

        # 3. HTTP 422 when an existing PR targets a different base (master) -> leave B intact
        #    and report PR number, base, pushed SHA, and retry instructions.
        prev_sha3 = pushed_b_461
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.16")
        summary_other_base = self.root / "pr-462-summary.md"

        def _other_base_pr() -> bytes:
            pushed_b = self._bare_ref_sha(self.rolling_branch)
            assert pushed_b is not None
            return json.dumps(
                [
                    _pr_obj(
                        number=462,
                        title="chore: update embedded libznn to go-zenon v0.0.16-alphanet",
                        body="body\n",
                        head_ref=self.rolling_branch,
                        head_sha=pushed_b,
                        base_ref="master",
                    )
                ]
            ).encode("utf-8")

        opener_other_base = _SequentialListOpener(
            {
                ("POST", self.create_pr_url): urllib.error.HTTPError(
                    self.create_pr_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                )
            },
            list_seq=[b"[]", _other_base_pr],
        )
        with self.assertRaises(updater.UpdaterError) as ctx_other:
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.16-alphanet",
                pr_body="body\n",
                commit_message="commit v0.0.16",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=prev_sha3,
                expected_pr_numbers="none",
                step_summary=summary_other_base,
                opener=opener_other_base,  # type: ignore[arg-type]
            )
        pushed_b_462 = self._bare_ref_sha(self.rolling_branch)
        self.assertIsNotNone(pushed_b_462)
        assert pushed_b_462 is not None
        self.assertNotEqual(pushed_b_462, prev_sha3)
        self.assertIn("#462", str(ctx_other.exception))
        self.assertIn("base=master", str(ctx_other.exception))
        self.assertIn(pushed_b_462, str(ctx_other.exception))
        self.assertIn("#462", summary_other_base.read_text(encoding="utf-8"))

        # 4. Concurrent push C during POST /pulls failure -> since no rollback push is ever
        #    issued, C remains completely untouched on the remote.
        prev_sha4 = pushed_b_462
        self._reclone_work_repo()
        self._write_blobs(self.work_repo, version="v0.0.17")
        pushed_c: list[str] = []

        class _ConcurrentCOnPostOpener(_RecordingOpener):
            def open(self, req: urllib.request.Request, timeout: int = 60) -> _FakeResponse:
                if req.get_method() == "POST" and req.full_url == create_url_ref:
                    self.requests.append(("POST", req.full_url, None))
                    pushed_c.append(push_c_fn())
                    raise urllib.error.HTTPError(
                        req.full_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                    )
                return super().open(req, timeout=timeout)

        create_url_ref = self.create_pr_url
        push_c_fn = lambda: self._push_concurrent_commit(self.rolling_branch, note="concurrent-c")
        opener_concurrent = _ConcurrentCOnPostOpener({("GET", list_url): b"[]"})
        with self.assertRaisesRegex(updater.UpdaterError, "HTTP 422.*not rolling back"):
            publish_pr.publish_libznn_pr(
                repo="zenon-network/syrius",
                repo_root=self.work_repo,
                target_branch="develop",
                pr_branch=self.rolling_branch,
                pr_title="chore: update embedded libznn to go-zenon v0.0.17-alphanet",
                pr_body="body\n",
                commit_message="commit v0.0.17",
                github_token="ghs_test",
                require_expected_head=True,
                expected_head_state="present",
                expected_head_oid=prev_sha4,
                expected_pr_numbers="none",
                opener=opener_concurrent,  # type: ignore[arg-type]
            )
        self.assertEqual(len(pushed_c), 1)
        self.assertEqual(self._bare_ref_sha(self.rolling_branch), pushed_c[0])


if __name__ == "__main__":
    unittest.main()
