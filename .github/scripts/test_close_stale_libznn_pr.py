#!/usr/bin/env python3
"""Unit tests for .github/scripts/close_stale_libznn_pr.py."""

from __future__ import annotations

import base64
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


def _encoded_manifest_response(tag: str, *, prerelease: bool = False) -> bytes:
    base_dl = f"https://github.com/zenon-network/go-zenon/releases/download/{tag}"
    manifest = {
        "schema_version": 1,
        "upstream_repo": "zenon-network/go-zenon",
        "release": {
            "tag": tag,
            "name": tag,
            "html_url": f"https://github.com/zenon-network/go-zenon/releases/tag/{tag}",
            "published_at": "2026-11-20T12:00:00Z",
            "prerelease": prerelease,
            "immutable": False,
            "target_commitish": "a" * 40,
            "tag_commit": "a" * 40,
            "checksums_asset": None,
        },
        "blobs": {
            "lib/embedded_node/blobs/libznn.so": {
                "platform": "Linux (amd64)",
                "asset_name": "libznn-linux-amd64.tar.gz",
                "download_url": f"{base_dl}/libznn-linux-amd64.tar.gz",
                "asset_updated_at": "2026-11-20T12:00:00Z",
                "archive_sha256": "1" * 64,
                "extracted_sha256": "2" * 64,
            },
            "lib/embedded_node/blobs/libznn.dylib": {
                "platform": "macOS (universal)",
                "asset_name": "libznn-darwin-universal.tar.gz",
                "download_url": f"{base_dl}/libznn-darwin-universal.tar.gz",
                "asset_updated_at": "2026-11-20T12:00:00Z",
                "archive_sha256": "3" * 64,
                "extracted_sha256": "4" * 64,
            },
            "lib/embedded_node/blobs/libznn.dll": {
                "platform": "Windows (amd64)",
                "asset_name": "libznn-windows-amd64.zip",
                "download_url": f"{base_dl}/libznn-windows-amd64.zip",
                "asset_updated_at": "2026-11-20T12:00:00Z",
                "archive_sha256": "5" * 64,
                "extracted_sha256": "6" * 64,
            },
        },
    }
    encoded = base64.b64encode((json.dumps(manifest, indent=2) + "\n").encode("utf-8")).decode("ascii")
    return json.dumps({"encoding": "base64", "content": encoded}).encode("utf-8")


def _pr_obj(
    *,
    number: int,
    title: str,
    body: str = "",
    head_ref: str = "chore/update-libznn-develop",
    head_sha: str = "a" * 40,
    head_repo: str = "zenon-network/syrius",
    base_ref: str = "develop",
    base_sha: str = "b" * 40,
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
            "sha": base_sha,
        },
    }


class CloseStaleLibznnPrTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmpdir.name)
        self.list_develop_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-develop&base=develop&per_page=100"
        )
        self.delete_develop_url = (
            "https://api.github.com/repos/zenon-network/syrius/git/refs/heads/"
            "chore/update-libznn-develop"
        )

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _contents_url(self, ref: str) -> str:
        return (
            "https://api.github.com/repos/zenon-network/syrius/contents/"
            f"lib/embedded_node/blobs/libznn.manifest.json?ref={ref}"
        )

    def test_no_open_pr_performs_no_writes_and_records_zero_closed(self) -> None:
        opener = _RecordingOpener({("GET", self.list_develop_url): b"[]"})
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
        self.assertEqual(result.preserved_prs, ())
        self.assertEqual(result.branch_deleted, "not_needed")
        self.assertEqual(len(opener.requests), 1)
        self.assertEqual(opener.requests[0][0], "GET")
        self.assertIn("closed_count=0\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("preserved_count=0\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("branch_deleted=not_needed\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("No stale automated pull request was open", summary.read_text(encoding="utf-8"))

    def test_closes_same_or_older_stale_pr_ignores_fork_and_closes_before_commenting(self) -> None:
        head_sha = "1" * 40
        prs_payload = [
            _pr_obj(
                number=200,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_repo="external-fork/syrius",
            ),
            _pr_obj(
                number=201,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_sha,
            ),
        ]
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/201"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/201/comments"
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._contents_url(head_sha)): _encoded_manifest_response("v0.0.10-alphanet"),
                ("PATCH", close_url): json.dumps({"number": 201, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("DELETE", self.delete_develop_url): b"",
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
        self.assertEqual(result.preserved_prs, ())
        self.assertEqual(result.branch_deleted, "deleted")

        # Verify request sequence: GET pulls -> GET manifest -> PATCH close -> POST comment -> DELETE branch
        self.assertEqual([r[0] for r in opener.requests], ["GET", "GET", "PATCH", "POST", "DELETE"])
        self.assertEqual(opener.requests[2][2], {"state": "closed"})
        self.assertIn("v0.0.10-alphanet", opener.requests[3][2]["body"])
        self.assertIn("actions/runs/999", opener.requests[3][2]["body"])

        gh_out_text = gh_out.read_text(encoding="utf-8")
        self.assertIn("closed_count=1\n", gh_out_text)
        self.assertIn("closed_pr_urls=https://github.com/zenon-network/syrius/pull/201\n", gh_out_text)
        self.assertIn("branch_deleted=deleted\n", gh_out_text)
        self.assertIn("Closed stale PR #201", summary.read_text(encoding="utf-8"))

    def test_closes_superseded_older_non_downgrade_pr(self) -> None:
        head_sha = "2" * 40
        prs_payload = [
            _pr_obj(
                number=202,
                title="chore: update embedded libznn to go-zenon v0.0.9-alphanet",
                head_sha=head_sha,
            )
        ]
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/202"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/202/comments"
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._contents_url(head_sha)): _encoded_manifest_response("v0.0.9-alphanet"),
                ("PATCH", close_url): json.dumps({"number": 202, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 2}).encode("utf-8"),
                ("DELETE", self.delete_develop_url): b"",
            }
        )
        result = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertEqual(len(result.closed_prs), 1)
        self.assertIn("superseded by `v0.0.10-alphanet`", result.closed_prs[0].reason)
        self.assertEqual(result.branch_deleted, "deleted")

    def test_preserves_forced_downgrade_pr_and_does_not_delete_branch(self) -> None:
        prs_payload = [
            _pr_obj(
                number=203,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet (downgrade)",
                body="> [!CAUTION]\n> **Forced downgrade:** downgrading from v0.0.11 to v0.0.10-alphanet",
            )
        ]
        opener = _RecordingOpener(
            {("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8")}
        )
        gh_out = self.root / "dg.out"
        summary = self.root / "dg_summary.md"

        result = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            github_output=gh_out,
            step_summary=summary,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertEqual(result.closed_prs, ())
        self.assertEqual(len(result.preserved_prs), 1)
        self.assertEqual(result.preserved_prs[0].number, 203)
        self.assertEqual(result.branch_deleted, "not_needed")
        self.assertEqual([r[0] for r in opener.requests], ["GET"])
        self.assertIn("preserved_count=1\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("Preserved open PR #203", summary.read_text(encoding="utf-8"))

    def test_preserves_newer_prerelease_pr_and_does_not_delete_branch(self) -> None:
        head_sha = "3" * 40
        prs_payload = [
            _pr_obj(
                number=204,
                title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
                head_sha=head_sha,
            )
        ]
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.11-rc.1", prerelease=True
                ),
            }
        )
        summary = self.root / "pre_summary.md"

        result = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            step_summary=summary,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertEqual(result.closed_prs, ())
        self.assertEqual(len(result.preserved_prs), 1)
        self.assertEqual(result.branch_deleted, "not_needed")
        self.assertEqual([r[0] for r in opener.requests], ["GET", "GET"])
        self.assertIn("not superseded by `v0.0.10-alphanet`", summary.read_text(encoding="utf-8"))

    def test_legacy_pr_without_manifest_closes_only_when_diff_is_empty(self) -> None:
        base_sha = "4" * 40
        head_sha = "5" * 40
        compare_url = (
            f"https://api.github.com/repos/zenon-network/syrius/compare/{base_sha}...{head_sha}"
        )
        prs_payload = [
            _pr_obj(
                number=206,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_sha,
                base_sha=base_sha,
            )
        ]
        # 1. Legacy PR with non-empty diff is preserved (fail-safe).
        opener_keep = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._contents_url(head_sha)): urllib.error.HTTPError(
                    self._contents_url(head_sha), 404, "Not Found", {}, None  # type: ignore[arg-type]
                ),
                ("GET", compare_url): json.dumps(
                    {"status": "ahead", "files": [{"filename": "lib/embedded_node/blobs/libznn.so"}]}
                ).encode("utf-8"),
            }
        )
        keep_result = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            opener=opener_keep,  # type: ignore[arg-type]
        )
        self.assertEqual(keep_result.closed_prs, ())
        self.assertEqual(len(keep_result.preserved_prs), 1)

        # 2. Legacy PR with identical/empty diff is closed and its branch deleted.
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/206"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/206/comments"
        opener_close = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._contents_url(head_sha)): urllib.error.HTTPError(
                    self._contents_url(head_sha), 404, "Not Found", {}, None  # type: ignore[arg-type]
                ),
                ("GET", compare_url): json.dumps({"status": "identical", "files": []}).encode("utf-8"),
                ("PATCH", close_url): json.dumps({"number": 206, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 6}).encode("utf-8"),
                ("DELETE", self.delete_develop_url): b"",
            }
        )
        close_result = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            opener=opener_close,  # type: ignore[arg-type]
        )
        self.assertEqual(len(close_result.closed_prs), 1)
        self.assertEqual(close_result.branch_deleted, "deleted")

    def test_tolerates_already_deleted_branch_on_404_or_422(self) -> None:
        list_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-master&base=master&per_page=100"
        )
        head_sha = "6" * 40
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/205"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/205/comments"
        delete_ref_url = (
            "https://api.github.com/repos/zenon-network/syrius/git/refs/heads/"
            "chore/update-libznn-master"
        )
        pr_item = [
            _pr_obj(
                number=205,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_ref="chore/update-libznn-master",
                head_sha=head_sha,
                base_ref="master",
            )
        ]
        for code in (404, 422):
            with self.subTest(code=code):
                opener = _RecordingOpener(
                    {
                        ("GET", list_url): json.dumps(pr_item).encode("utf-8"),
                        ("GET", self._contents_url(head_sha)): _encoded_manifest_response(
                            "v0.0.10-alphanet"
                        ),
                        ("PATCH", close_url): json.dumps({"number": 205, "state": "closed"}).encode(
                            "utf-8"
                        ),
                        ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
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
