#!/usr/bin/env python3
"""Unit tests for .github/scripts/close_stale_libznn_pr.py."""

from __future__ import annotations

import io
import json
import os
import pathlib
import sys
import tempfile
import unittest
import urllib.error
import urllib.request
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import close_stale_libznn_pr as stale_pr
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


class CloseStaleLibznnPrTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_no_open_pr_performs_no_writes_and_records_zero_closed(self) -> None:
        list_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-develop&base=develop&per_page=100"
        )
        opener = _RecordingOpener({("GET", list_url): b"[]"})
        gh_out = self.root / "gh.out"
        summary = self.root / "summary.md"

        result = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            github_output=gh_out,
            step_summary=summary,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertEqual(result.closed_prs, ())
        self.assertEqual(result.branch_deleted, "not_needed")
        self.assertEqual(len(opener.requests), 1)
        self.assertEqual(opener.requests[0][0], "GET")
        self.assertIn("closed_count=0\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("branch_deleted=not_needed\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("No stale automated pull request was open", summary.read_text(encoding="utf-8"))

    def test_closes_matching_stale_pr_ignores_fork_and_deletes_branch(self) -> None:
        list_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-develop&base=develop&per_page=100"
        )
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/201/comments"
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/201"
        delete_ref_url = (
            "https://api.github.com/repos/zenon-network/syrius/git/refs/heads/"
            "chore/update-libznn-develop"
        )
        prs_payload = [
            {
                "number": 200,
                "state": "open",
                "html_url": "https://github.com/zenon-network/syrius/pull/200",
                "head": {
                    "ref": "chore/update-libznn-develop",
                    "repo": {"full_name": "external-fork/syrius"},
                },
                "base": {"ref": "develop"},
            },
            {
                "number": 201,
                "state": "open",
                "html_url": "https://github.com/zenon-network/syrius/pull/201",
                "head": {
                    "ref": "chore/update-libznn-develop",
                    "repo": {"full_name": "zenon-network/syrius"},
                },
                "base": {"ref": "develop"},
            },
        ]
        opener = _RecordingOpener(
            {
                ("GET", list_url): json.dumps(prs_payload).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("PATCH", close_url): json.dumps({"number": 201, "state": "closed"}).encode("utf-8"),
                ("DELETE", delete_ref_url): b"",
            }
        )
        gh_out = self.root / "gh.out"
        summary = self.root / "summary.md"

        result = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            workflow_run_url="https://github.com/zenon-network/syrius/actions/runs/999",
            github_output=gh_out,
            step_summary=summary,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertEqual(len(result.closed_prs), 1)
        self.assertEqual(result.closed_prs[0].number, 201)
        self.assertEqual(result.branch_deleted, "deleted")

        # Verify request sequence: GET -> POST comment -> PATCH close -> DELETE branch
        self.assertEqual([r[0] for r in opener.requests], ["GET", "POST", "PATCH", "DELETE"])
        self.assertIn("v0.0.10-alphanet", opener.requests[1][2]["body"])
        self.assertIn("actions/runs/999", opener.requests[1][2]["body"])
        self.assertEqual(opener.requests[2][2], {"state": "closed"})

        gh_out_text = gh_out.read_text(encoding="utf-8")
        self.assertIn("closed_count=1\n", gh_out_text)
        self.assertIn(
            "closed_pr_urls=https://github.com/zenon-network/syrius/pull/201\n",
            gh_out_text,
        )
        self.assertIn("branch_deleted=deleted\n", gh_out_text)
        self.assertIn("Closed stale PR #201", summary.read_text(encoding="utf-8"))

    def test_tolerates_already_deleted_branch_on_404_or_422(self) -> None:
        list_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-master&base=master&per_page=100"
        )
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/205/comments"
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/205"
        delete_ref_url = (
            "https://api.github.com/repos/zenon-network/syrius/git/refs/heads/"
            "chore/update-libznn-master"
        )
        pr_item = [
            {
                "number": 205,
                "state": "open",
                "html_url": "https://github.com/zenon-network/syrius/pull/205",
                "head": {
                    "ref": "chore/update-libznn-master",
                    "repo": {"full_name": "zenon-network/syrius"},
                },
                "base": {"ref": "master"},
            }
        ]
        for code in (404, 422):
            with self.subTest(code=code):
                opener = _RecordingOpener(
                    {
                        ("GET", list_url): json.dumps(pr_item).encode("utf-8"),
                        ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                        ("PATCH", close_url): json.dumps({"number": 205, "state": "closed"}).encode(
                            "utf-8"
                        ),
                        ("DELETE", delete_ref_url): urllib.error.HTTPError(
                            delete_ref_url, code, "Not Found", {}, None  # type: ignore[arg-type]
                        ),
                    }
                )
                result = stale_pr.close_stale_libznn_prs(
                    repo="zenon-network/syrius",
                    target_branch="master",
                    pr_branch="chore/update-libznn-master",
                    release_tag="v0.0.10-alphanet",
                    github_token="ghs_test",
                    opener=opener,  # type: ignore[arg-type]
                )
                self.assertEqual(result.branch_deleted, "already_deleted")

    def test_rejects_unexpected_branch_missing_token_and_colliding_outputs(self) -> None:
        with self.assertRaisesRegex(updater.UpdaterError, "unexpected PR branch"):
            stale_pr.close_stale_libznn_prs(
                repo="zenon-network/syrius",
                target_branch="develop",
                pr_branch="feature/something-else",
                release_tag="v0.0.10-alphanet",
                github_token="ghs_test",
            )

        with self.assertRaisesRegex(updater.UpdaterError, "GitHub token is required"):
            stale_pr.close_stale_libznn_prs(
                repo="zenon-network/syrius",
                target_branch="develop",
                pr_branch="chore/update-libznn-develop",
                release_tag="v0.0.10-alphanet",
                github_token="",
            )

        shared = self.root / "same.out"
        with self.assertRaisesRegex(updater.UpdaterError, "must not refer to the same file"):
            stale_pr.close_stale_libznn_prs(
                repo="zenon-network/syrius",
                target_branch="develop",
                pr_branch="chore/update-libznn-develop",
                release_tag="v0.0.10-alphanet",
                github_token="ghs_test",
                github_output=shared,
                step_summary=shared,
            )

    def test_main_cli_returns_nonzero_when_token_missing(self) -> None:
        orig_gh = os.environ.pop("GH_TOKEN", None)
        orig_github = os.environ.pop("GITHUB_TOKEN", None)
        stderr_buf = io.StringIO()
        old_stderr = sys.stderr
        try:
            sys.stderr = stderr_buf
            rc = stale_pr.main(
                [
                    "--repo",
                    "zenon-network/syrius",
                    "--target-branch",
                    "develop",
                    "--pr-branch",
                    "chore/update-libznn-develop",
                    "--release-tag",
                    "v0.0.10-alphanet",
                ]
            )
        finally:
            sys.stderr = old_stderr
            if orig_gh is not None:
                os.environ["GH_TOKEN"] = orig_gh
            if orig_github is not None:
                os.environ["GITHUB_TOKEN"] = orig_github

        self.assertEqual(rc, 1)
        self.assertIn("GitHub token is required", stderr_buf.getvalue())


if __name__ == "__main__":
    unittest.main()
