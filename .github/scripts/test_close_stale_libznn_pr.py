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


def _pr_files_response(filenames: list[str]) -> bytes:
    return json.dumps([{"filename": name} for name in filenames]).encode("utf-8")


def _blobs_dir_contents_response(so_sha: str, dylib_sha: str, dll_sha: str) -> bytes:
    return json.dumps(
        [
            {"type": "file", "path": "lib/embedded_node/blobs/libznn.so", "sha": so_sha},
            {"type": "file", "path": "lib/embedded_node/blobs/libznn.dylib", "sha": dylib_sha},
            {"type": "file", "path": "lib/embedded_node/blobs/libznn.dll", "sha": dll_sha},
        ]
    ).encode("utf-8")


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
        self.list_develop_head_only_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-develop&per_page=100"
        )
        self.delete_develop_url = (
            "https://api.github.com/repos/zenon-network/syrius/git/refs/heads/"
            "chore/update-libznn-develop"
        )
        self.all_updater_files = [
            "lib/embedded_node/blobs/libznn.so",
            "lib/embedded_node/blobs/libznn.dylib",
            "lib/embedded_node/blobs/libznn.dll",
            updater.MANIFEST_RELPATH,
        ]
        self.blob_only_files = [
            "lib/embedded_node/blobs/libznn.so",
            "lib/embedded_node/blobs/libznn.dylib",
            "lib/embedded_node/blobs/libznn.dll",
        ]

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _files_url(self, pr_number: int) -> str:
        return f"https://api.github.com/repos/zenon-network/syrius/pulls/{pr_number}/files?per_page=100"

    def _manifest_contents_url(self, ref: str) -> str:
        return (
            "https://api.github.com/repos/zenon-network/syrius/contents/"
            f"lib/embedded_node/blobs/libznn.manifest.json?ref={ref}"
        )

    def _blobs_contents_url(self, ref: str) -> str:
        return (
            "https://api.github.com/repos/zenon-network/syrius/contents/"
            f"lib/embedded_node/blobs?ref={ref}"
        )

    def _ref_url(self, branch: str) -> str:
        return f"https://api.github.com/repos/zenon-network/syrius/git/ref/heads/{branch}"

    def _compare_url(self, base: str, head: str) -> str:
        return f"https://api.github.com/repos/zenon-network/syrius/compare/{base}...{head}"

    def _branch_ref_response(self, branch: str, sha: str, obj_type: str = "commit") -> bytes:
        return json.dumps(
            {
                "ref": f"refs/heads/{branch}",
                "object": {"type": obj_type, "sha": sha},
            }
        ).encode("utf-8")

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
                ("GET", self._files_url(201)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 201, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", self._ref_url("chore/update-libznn-develop")): self._branch_ref_response(
                    "chore/update-libznn-develop", head_sha
                ),
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
        self.assertIsNone(result.closed_prs[0].comment_warning)
        self.assertEqual(result.preserved_prs, ())
        self.assertEqual(result.branch_deleted, "deleted")

        # Sequence: GET pulls -> GET files -> GET manifest -> PATCH close -> POST comment
        # -> GET open PRs (head-only) -> GET ref -> DELETE branch
        self.assertEqual(
            [r[0] for r in opener.requests],
            ["GET", "GET", "GET", "PATCH", "POST", "GET", "GET", "DELETE"],
        )
        self.assertEqual(opener.requests[3][2], {"state": "closed"})
        self.assertIn("v0.0.10-alphanet", opener.requests[4][2]["body"])
        self.assertIn("actions/runs/999", opener.requests[4][2]["body"])

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
                ("GET", self._files_url(202)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.9-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 202, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 2}).encode("utf-8"),
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", self._ref_url("chore/update-libznn-develop")): self._branch_ref_response(
                    "chore/update-libznn-develop", head_sha
                ),
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

    def test_preserves_inherited_manifest_pr_when_blobs_differ_from_target_branch(self) -> None:
        # Legacy updater started from develop at v10 (inherited v10 manifest),
        # updated ONLY the blobs to v11-rc.1, and left manifest untouched.
        head_sha = "7" * 40
        prs_payload = [
            _pr_obj(
                number=207,
                title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
                head_sha=head_sha,
            )
        ]
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._files_url(207)): _pr_files_response(self.blob_only_files),
                ("GET", self._blobs_contents_url(head_sha)): _blobs_dir_contents_response(
                    "aaa", "bbb", "ccc"
                ),
                ("GET", self._blobs_contents_url("develop")): _blobs_dir_contents_response(
                    "111", "222", "333"
                ),
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
        self.assertEqual(result.closed_prs, ())
        self.assertEqual(len(result.preserved_prs), 1)
        self.assertEqual(result.branch_deleted, "not_needed")
        self.assertIn("without updating", result.preserved_prs[0].reason)

    def test_closes_blob_only_pr_when_all_three_blobs_already_match_target_branch(self) -> None:
        head_sha = "8" * 40
        prs_payload = [
            _pr_obj(
                number=208,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_sha,
            )
        ]
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/208"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/208/comments"
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._files_url(208)): _pr_files_response(self.blob_only_files),
                ("GET", self._blobs_contents_url(head_sha)): _blobs_dir_contents_response(
                    "111", "222", "333"
                ),
                ("GET", self._blobs_contents_url("develop")): _blobs_dir_contents_response(
                    "111", "222", "333"
                ),
                ("PATCH", close_url): json.dumps({"number": 208, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 8}).encode("utf-8"),
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", self._ref_url("chore/update-libznn-develop")): self._branch_ref_response(
                    "chore/update-libznn-develop", head_sha
                ),
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
        self.assertEqual(result.branch_deleted, "deleted")
        self.assertIn("already match `develop`", result.closed_prs[0].reason)

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
                ("GET", self._files_url(204)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
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
        self.assertEqual([r[0] for r in opener.requests], ["GET", "GET", "GET"])
        self.assertIn("not superseded by `v0.0.10-alphanet`", summary.read_text(encoding="utf-8"))

    def test_comment_failure_after_patch_still_records_close_and_deletes_branch(self) -> None:
        head_sha = "9" * 40
        prs_payload = [
            _pr_obj(
                number=209,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_sha,
            )
        ]
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/209"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/209/comments"
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._files_url(209)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 209, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): urllib.error.HTTPError(
                    comment_url, 403, "Forbidden", {}, None  # type: ignore[arg-type]
                ),
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", self._ref_url("chore/update-libznn-develop")): self._branch_ref_response(
                    "chore/update-libznn-develop", head_sha
                ),
                ("DELETE", self.delete_develop_url): b"",
            }
        )
        gh_out = self.root / "comment_fail.out"
        summary = self.root / "comment_fail_summary.md"
        stderr_buf = io.StringIO()
        old_stderr = sys.stderr
        try:
            sys.stderr = stderr_buf
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
        finally:
            sys.stderr = old_stderr

        self.assertEqual(len(result.closed_prs), 1)
        self.assertIsNotNone(result.closed_prs[0].comment_warning)
        self.assertEqual(result.branch_deleted, "deleted")
        self.assertEqual(
            [r[0] for r in opener.requests],
            ["GET", "GET", "GET", "PATCH", "POST", "GET", "GET", "DELETE"],
        )
        self.assertIn("closed_count=1\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("branch_deleted=deleted\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("closing comment failed", summary.read_text(encoding="utf-8"))
        self.assertIn("failed to post closing comment", stderr_buf.getvalue())

    def test_delete_branch_handles_404_and_confirms_absence_on_422(self) -> None:
        list_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-master&base=master&per_page=100"
        )
        list_master_head_only_url = (
            "https://api.github.com/repos/zenon-network/syrius/pulls?"
            "state=open&head=zenon-network%3Achore%2Fupdate-libznn-master&per_page=100"
        )
        head_sha = "6" * 40
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/205"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/205/comments"
        delete_ref_url = (
            "https://api.github.com/repos/zenon-network/syrius/git/refs/heads/"
            "chore/update-libznn-master"
        )
        get_ref_url = self._ref_url("chore/update-libznn-master")
        pr_item = [
            _pr_obj(
                number=205,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_ref="chore/update-libznn-master",
                head_sha=head_sha,
                base_ref="master",
            )
        ]

        # 1. DELETE 404 -> already_deleted directly.
        opener_404 = _RecordingOpener(
            {
                ("GET", list_url): json.dumps(pr_item).encode("utf-8"),
                ("GET", self._files_url(205)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 205, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("GET", list_master_head_only_url): b"[]",
                ("GET", get_ref_url): self._branch_ref_response(
                    "chore/update-libznn-master", head_sha
                ),
                ("DELETE", delete_ref_url): urllib.error.HTTPError(
                    delete_ref_url, 404, "Not Found", {}, None  # type: ignore[arg-type]
                ),
            }
        )
        res_404 = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="master",
            pr_branch="chore/update-libznn-master",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            opener=opener_404,  # type: ignore[arg-type]
        )
        self.assertEqual(res_404.branch_deleted, "already_deleted")

        # 2. DELETE 422 + GET ref 404 -> confirmed absent -> already_deleted.
        class _SequentialRefOpener(_RecordingOpener):
            def __init__(self, handlers: dict[tuple[str, str], Any], ref_seq: list[Any]) -> None:
                super().__init__(handlers)
                self._ref_seq = list(ref_seq)

            def open(self, req: urllib.request.Request, timeout: int = 60) -> _FakeResponse:
                if req.get_method() == "GET" and req.full_url == get_ref_url:
                    self.requests.append(("GET", req.full_url, None))
                    outcome = self._ref_seq.pop(0)
                    if isinstance(outcome, Exception):
                        raise outcome
                    return _FakeResponse(outcome)
                return super().open(req, timeout=timeout)

        opener_422_absent = _SequentialRefOpener(
            {
                ("GET", list_url): json.dumps(pr_item).encode("utf-8"),
                ("GET", self._files_url(205)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 205, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("GET", list_master_head_only_url): b"[]",
                ("DELETE", delete_ref_url): urllib.error.HTTPError(
                    delete_ref_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                ),
            },
            ref_seq=[
                self._branch_ref_response("chore/update-libznn-master", head_sha),
                urllib.error.HTTPError(
                    get_ref_url, 404, "Not Found", {}, None  # type: ignore[arg-type]
                ),
            ],
        )
        res_422_absent = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="master",
            pr_branch="chore/update-libznn-master",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            opener=opener_422_absent,  # type: ignore[arg-type]
        )
        self.assertEqual(res_422_absent.branch_deleted, "already_deleted")

        # 3. DELETE 422 + GET ref 200 (branch still exists) -> raises UpdaterError!
        opener_422_present = _RecordingOpener(
            {
                ("GET", list_url): json.dumps(pr_item).encode("utf-8"),
                ("GET", self._files_url(205)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 205, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("GET", list_master_head_only_url): b"[]",
                ("DELETE", delete_ref_url): urllib.error.HTTPError(
                    delete_ref_url, 422, "Unprocessable Entity", {}, None  # type: ignore[arg-type]
                ),
                ("GET", get_ref_url): self._branch_ref_response(
                    "chore/update-libznn-master", head_sha
                ),
            }
        )
        with self.assertRaisesRegex(updater.UpdaterError, "HTTP 422"):
            stale_pr.close_stale_libznn_prs(
                repo="zenon-network/syrius",
                target_branch="master",
                pr_branch="chore/update-libznn-master",
                release_tag="v0.0.10-alphanet",
                github_token="ghs_test",
                opener=opener_422_present,  # type: ignore[arg-type]
            )

    def test_stale_cleanup_skips_branch_delete_when_other_base_pr_exists_or_head_moved(
        self,
    ) -> None:
        head_sha = "5" * 40
        moved_sha = "6" * 40
        pr_develop = _pr_obj(
            number=220,
            title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
            head_sha=head_sha,
            base_ref="develop",
        )
        pr_master = _pr_obj(
            number=221,
            title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
            head_sha=head_sha,
            base_ref="master",
        )
        close_url = "https://api.github.com/repos/zenon-network/syrius/pulls/220"
        comment_url = "https://api.github.com/repos/zenon-network/syrius/issues/220/comments"

        # 1. Second open PR targeting master still references the same head branch -> skip DELETE!
        summary_other = self.root / "stale_other_pr.md"
        opener_other = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps([pr_develop]).encode("utf-8"),
                ("GET", self._files_url(220)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 220, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("GET", self.list_develop_head_only_url): json.dumps([pr_master]).encode("utf-8"),
            }
        )
        res_other = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            step_summary=summary_other,
            opener=opener_other,  # type: ignore[arg-type]
        )
        self.assertEqual(len(res_other.closed_prs), 1)
        self.assertEqual(res_other.branch_deleted, "not_needed")
        self.assertFalse(any(r[0] == "DELETE" for r in opener_other.requests))
        self.assertIn("other open PR(s) still reference it (#221)", summary_other.read_text(encoding="utf-8"))

        # 2. Remote ref moved to a newer commit after classification -> skip DELETE!
        summary_moved = self.root / "stale_moved.md"
        opener_moved = _RecordingOpener(
            {
                ("GET", self.list_develop_url): json.dumps([pr_develop]).encode("utf-8"),
                ("GET", self._files_url(220)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet"
                ),
                ("PATCH", close_url): json.dumps({"number": 220, "state": "closed"}).encode("utf-8"),
                ("POST", comment_url): json.dumps({"id": 1}).encode("utf-8"),
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", self._ref_url("chore/update-libznn-develop")): self._branch_ref_response(
                    "chore/update-libznn-develop", moved_sha
                ),
            }
        )
        res_moved = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            step_summary=summary_moved,
            opener=opener_moved,  # type: ignore[arg-type]
        )
        self.assertEqual(res_moved.branch_deleted, "not_needed")
        self.assertFalse(any(r[0] == "DELETE" for r in opener_moved.requests))
        self.assertIn("moved after stale-PR classification", summary_moved.read_text(encoding="utf-8"))

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

    def test_update_guard_allows_when_no_open_pr_or_only_fork_pr(self) -> None:
        prs_payload = [
            _pr_obj(
                number=300,
                title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
                head_repo="external-fork/syrius",
            )
        ]
        ref_url = self._ref_url("chore/update-libznn-develop")
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", ref_url): urllib.error.HTTPError(
                    ref_url, 404, "Not Found", {}, None  # type: ignore[arg-type]
                ),
            }
        )
        gh_out = self.root / "guard_ok.out"
        summary = self.root / "guard_ok.md"

        result = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            github_output=gh_out,
            step_summary=summary,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertTrue(result.safe_to_update)
        self.assertEqual(result.expected_head_state, "absent")
        self.assertEqual(result.expected_head_oid, "")
        self.assertEqual(result.blocking_prs, ())
        self.assertEqual([r[0] for r in opener.requests], ["GET", "GET"])
        out_text = gh_out.read_text(encoding="utf-8")
        self.assertIn("safe_to_update=true\n", out_text)
        self.assertIn("expected_head_state=absent\n", out_text)
        self.assertIn("expected_head_oid=\n", out_text)
        self.assertIn("blocking_pr_count=0\n", out_text)
        self.assertFalse(summary.exists())

    def test_update_guard_allows_superseding_older_or_same_stable_rolling_pr(self) -> None:
        head_sha = "a" * 40
        prs_payload = [
            _pr_obj(
                number=301,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_sha,
            )
        ]
        opener = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._files_url(301)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_sha)): _encoded_manifest_response(
                    "v0.0.10-alphanet", prerelease=False
                ),
                ("GET", self._ref_url("chore/update-libznn-develop")): self._branch_ref_response(
                    "chore/update-libznn-develop", head_sha
                ),
            }
        )
        for incoming_tag in ("v0.0.11-alphanet", "v0.0.10-alphanet"):
            with self.subTest(incoming_tag=incoming_tag):
                gh_out = self.root / f"guard_{incoming_tag}.out"
                result = stale_pr.check_pr_branch_safe_to_update(
                    repo="zenon-network/syrius",
                    target_branch="develop",
                    pr_branch="chore/update-libznn-develop",
                    release_tag=incoming_tag,
                    github_token="ghs_test",
                    github_output=gh_out,
                    opener=opener,  # type: ignore[arg-type]
                )
                self.assertTrue(result.safe_to_update)
                self.assertEqual(result.expected_head_state, "present")
                self.assertEqual(result.expected_head_oid, head_sha)
                self.assertEqual(len(result.updatable_prs), 1)
                self.assertEqual(result.blocking_prs, ())
                out_text = gh_out.read_text(encoding="utf-8")
                self.assertIn("expected_head_state=present\n", out_text)
                self.assertIn(f"expected_head_oid={head_sha}\n", out_text)
        self.assertTrue(all(r[0] == "GET" for r in opener.requests))

    def test_update_guard_blocks_prerelease_downgrade_explicit_newer_and_non_blob_prs(self) -> None:
        # 1. Forced downgrade PR (caught immediately from PR metadata, single GET).
        dg_prs = [
            _pr_obj(
                number=302,
                title="chore: update embedded libznn to go-zenon v0.0.9-alphanet (downgrade)",
                body="> **Forced downgrade:** intentional",
            )
        ]
        opener_dg = _RecordingOpener(
            {("GET", self.list_develop_head_only_url): json.dumps(dg_prs).encode("utf-8")}
        )
        gh_out = self.root / "guard_dg.out"
        summary = self.root / "guard_dg.md"
        res_dg = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            github_output=gh_out,
            step_summary=summary,
            opener=opener_dg,  # type: ignore[arg-type]
        )
        self.assertFalse(res_dg.safe_to_update)
        self.assertEqual(res_dg.expected_head_state, "")
        self.assertEqual(res_dg.expected_head_oid, "")
        self.assertEqual(res_dg.blocking_prs[0].number, 302)
        self.assertIn("forced downgrade", res_dg.blocking_prs[0].reason)
        self.assertIn("safe_to_update=false\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("expected_head_state=\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("expected_head_oid=\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("blocking_pr_count=1\n", gh_out.read_text(encoding="utf-8"))
        self.assertIn("Preserved open PR #302", summary.read_text(encoding="utf-8"))

        # 2. Pre-release PR marked via manifest (even if title was edited and SemVer < incoming).
        head_pre = "b" * 40
        pre_prs = [
            _pr_obj(
                number=303,
                title="custom title without flag",
                head_sha=head_pre,
            )
        ]
        opener_pre = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(pre_prs).encode("utf-8"),
                ("GET", self._files_url(303)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_pre)): _encoded_manifest_response(
                    "v0.0.10-rc.1", prerelease=True
                ),
            }
        )
        res_pre = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.10-alphanet",
            github_token="ghs_test",
            opener=opener_pre,  # type: ignore[arg-type]
        )
        self.assertFalse(res_pre.safe_to_update)
        self.assertIn("pre-release", res_pre.blocking_prs[0].reason)

        # 3. Explicit-tag PR marked in body (even for an older stable tag).
        explicit_prs = [
            _pr_obj(
                number=304,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                body="- **Selection mode:** explicit tag (`v0.0.10-alphanet`)",
            )
        ]
        opener_exp = _RecordingOpener(
            {("GET", self.list_develop_head_only_url): json.dumps(explicit_prs).encode("utf-8")}
        )
        res_exp = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_exp,  # type: ignore[arg-type]
        )
        self.assertFalse(res_exp.safe_to_update)
        self.assertIn("explicit-tag", res_exp.blocking_prs[0].reason)

        # 4. Open PR targeting a newer tag than the scheduled release.
        head_newer = "c" * 40
        newer_prs = [
            _pr_obj(
                number=305,
                title="chore: update embedded libznn to go-zenon v0.0.12-alphanet",
                head_sha=head_newer,
            )
        ]
        opener_newer = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(newer_prs).encode("utf-8"),
                ("GET", self._files_url(305)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(head_newer)): _encoded_manifest_response(
                    "v0.0.12-alphanet", prerelease=False
                ),
            }
        )
        res_newer = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_newer,  # type: ignore[arg-type]
        )
        self.assertFalse(res_newer.safe_to_update)
        self.assertIn("not superseded", res_newer.blocking_prs[0].reason)

        # 5. Open PR modifying files outside blobs/manifest (human commits on rolling branch).
        head_extra = "d" * 40
        extra_prs = [
            _pr_obj(
                number=306,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_extra,
            )
        ]
        opener_extra = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(extra_prs).encode("utf-8"),
                ("GET", self._files_url(306)): _pr_files_response(
                    [*self.all_updater_files, "lib/embedded_node/embedded_node.dart"]
                ),
            }
        )
        res_extra = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_extra,  # type: ignore[arg-type]
        )
        self.assertFalse(res_extra.safe_to_update)
        self.assertIn("outside embedded libznn blobs/manifest", res_extra.blocking_prs[0].reason)

        # 6. Legacy blob-only PR whose blobs differ from target branch.
        head_legacy = "e" * 40
        legacy_prs = [
            _pr_obj(
                number=307,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_legacy,
            )
        ]
        opener_legacy = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(legacy_prs).encode("utf-8"),
                ("GET", self._files_url(307)): _pr_files_response(self.blob_only_files),
                ("GET", self._blobs_contents_url(head_legacy)): _blobs_dir_contents_response(
                    "aaa", "bbb", "ccc"
                ),
                ("GET", self._blobs_contents_url("develop")): _blobs_dir_contents_response(
                    "111", "222", "333"
                ),
            }
        )
        res_legacy = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_legacy,  # type: ignore[arg-type]
        )
        self.assertFalse(res_legacy.safe_to_update)
        self.assertIn("without updating", res_legacy.blocking_prs[0].reason)

    def test_update_guard_blocks_retargeted_pr_on_other_base_while_stale_cleanup_respects_base(
        self,
    ) -> None:
        retargeted_protected = [
            _pr_obj(
                number=310,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                body="- **Selection mode:** explicit tag (`v0.0.10-alphanet`)",
                head_ref="chore/update-libznn-develop",
                base_ref="master",
            )
        ]
        opener_guard = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(
                    retargeted_protected
                ).encode("utf-8")
            }
        )
        res_guard = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_guard,  # type: ignore[arg-type]
        )
        self.assertFalse(res_guard.safe_to_update)
        self.assertEqual(len(res_guard.blocking_prs), 1)
        self.assertEqual(res_guard.blocking_prs[0].number, 310)
        self.assertIn("targets base branch `master` instead of `develop`", res_guard.blocking_prs[0].reason)
        self.assertNotIn("base=", opener_guard.requests[0][1])

        # Even a plain rolling PR retargeted to master must block overwriting from develop.
        retargeted_plain = [
            _pr_obj(
                number=311,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_ref="chore/update-libznn-develop",
                base_ref="master",
            )
        ]
        opener_plain = _RecordingOpener(
            {("GET", self.list_develop_head_only_url): json.dumps(retargeted_plain).encode("utf-8")}
        )
        res_plain = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_plain,  # type: ignore[arg-type]
        )
        self.assertFalse(res_plain.safe_to_update)
        self.assertEqual(res_plain.blocking_prs[0].number, 311)

        # Stale-PR cleanup MUST still restrict to base=develop (both API query and record filter).
        opener_stale = _RecordingOpener(
            {("GET", self.list_develop_url): json.dumps(retargeted_plain).encode("utf-8")}
        )
        res_stale = stale_pr.close_stale_libznn_prs(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_stale,  # type: ignore[arg-type]
        )
        self.assertEqual(res_stale.closed_prs, ())
        self.assertEqual(res_stale.preserved_prs, ())
        self.assertEqual(res_stale.branch_deleted, "not_needed")
        self.assertIn("base=develop", opener_stale.requests[0][1])

    def test_update_guard_fails_closed_on_head_drift_and_handles_orphan_branch(self) -> None:
        # 1. Head drift: PR inspected at SHA A, remote ref already moved to SHA B -> raises UpdaterError.
        sha_a = "1" * 40
        sha_b = "2" * 40
        prs_payload = [
            _pr_obj(
                number=320,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=sha_a,
            )
        ]
        opener_drift = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._files_url(320)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(sha_a)): _encoded_manifest_response(
                    "v0.0.10-alphanet", prerelease=False
                ),
                ("GET", self._ref_url("chore/update-libznn-develop")): self._branch_ref_response(
                    "chore/update-libznn-develop", sha_b
                ),
            }
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Head drift detected"):
            stale_pr.check_pr_branch_safe_to_update(
                repo="zenon-network/syrius",
                target_branch="develop",
                pr_branch="chore/update-libznn-develop",
                release_tag="v0.0.11-alphanet",
                github_token="ghs_test",
                opener=opener_drift,  # type: ignore[arg-type]
            )

        # 2. Remote branch disappears after listing open PR -> fails closed.
        ref_url = self._ref_url("chore/update-libznn-develop")
        opener_missing = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(prs_payload).encode("utf-8"),
                ("GET", self._files_url(320)): _pr_files_response(self.all_updater_files),
                ("GET", self._manifest_contents_url(sha_a)): _encoded_manifest_response(
                    "v0.0.10-alphanet", prerelease=False
                ),
                ("GET", ref_url): urllib.error.HTTPError(
                    ref_url, 404, "Not Found", {}, None  # type: ignore[arg-type]
                ),
            }
        )
        with self.assertRaisesRegex(updater.UpdaterError, "is absent after inspecting open PR"):
            stale_pr.check_pr_branch_safe_to_update(
                repo="zenon-network/syrius",
                target_branch="develop",
                pr_branch="chore/update-libznn-develop",
                release_tag="v0.0.11-alphanet",
                github_token="ghs_test",
                opener=opener_missing,  # type: ignore[arg-type]
            )

        # 3. Prefix-match list response without exact ref -> treated as absent and safe.
        prefix_list_payload = [
            {
                "ref": "refs/heads/chore/update-libznn-develop-v0.0.11-rc.1",
                "object": {"type": "commit", "sha": sha_a},
            }
        ]
        opener_prefix = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", ref_url): json.dumps(prefix_list_payload).encode("utf-8"),
            }
        )
        res_prefix = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_prefix,  # type: ignore[arg-type]
        )
        self.assertTrue(res_prefix.safe_to_update)
        self.assertEqual(res_prefix.expected_head_state, "absent")
        self.assertEqual(res_prefix.expected_head_oid, "")

        # 4. Orphan remote branch with NO open PR that is already merged (ahead_by == 0) -> safe with OID.
        opener_merged = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", ref_url): self._branch_ref_response("chore/update-libznn-develop", sha_a),
                ("GET", self._compare_url("develop", sha_a)): json.dumps(
                    {"status": "behind", "ahead_by": 0, "behind_by": 3}
                ).encode("utf-8"),
            }
        )
        res_merged = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_merged,  # type: ignore[arg-type]
        )
        self.assertTrue(res_merged.safe_to_update)
        self.assertEqual(res_merged.expected_head_state, "present")
        self.assertEqual(res_merged.expected_head_oid, sha_a)

        # 5. Squash/rebase-merged or closed leftover rolling branch (diverged/ahead, only libznn
        # files, non-prerelease manifest <= release_tag) -> allowed with OID lease!
        sha_squash = "3" * 40
        opener_squash = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", ref_url): self._branch_ref_response("chore/update-libznn-develop", sha_squash),
                ("GET", self._compare_url("develop", sha_squash)): json.dumps(
                    {
                        "status": "diverged",
                        "ahead_by": 1,
                        "behind_by": 4,
                        "commits": [
                            {
                                "commit": {
                                    "message": "chore: update embedded libznn to go-zenon v0.0.10-alphanet"
                                }
                            }
                        ],
                        "files": [{"filename": path} for path in self.all_updater_files],
                    }
                ).encode("utf-8"),
                ("GET", self._manifest_contents_url(sha_squash)): _encoded_manifest_response(
                    "v0.0.10-alphanet", prerelease=False
                ),
            }
        )
        gh_squash = self.root / "orphan_squash.out"
        res_squash = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            github_output=gh_squash,
            opener=opener_squash,  # type: ignore[arg-type]
        )
        self.assertTrue(res_squash.safe_to_update)
        self.assertEqual(res_squash.expected_head_state, "present")
        self.assertEqual(res_squash.expected_head_oid, sha_squash)
        self.assertEqual(res_squash.inspected_pr_numbers, ())
        self.assertIn("inspected_pr_numbers=none\n", gh_squash.read_text(encoding="utf-8"))

        # 6. Orphan branch with non-libznn file -> blocked, blocking_reason output, CLI emits ::error:: and exits 1!
        summary = self.root / "orphan_unmerged.md"
        gh_out = self.root / "orphan_unmerged.out"
        opener_unmerged = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", ref_url): self._branch_ref_response("chore/update-libznn-develop", sha_b),
                ("GET", self._compare_url("develop", sha_b)): json.dumps(
                    {
                        "status": "ahead",
                        "ahead_by": 2,
                        "behind_by": 0,
                        "files": [
                            {"filename": "lib/embedded_node/blobs/libznn.so"},
                            {"filename": "lib/embedded_node/embedded_node.dart"},
                        ],
                    }
                ).encode("utf-8"),
            }
        )
        res_unmerged = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            github_output=gh_out,
            step_summary=summary,
            opener=opener_unmerged,  # type: ignore[arg-type]
        )
        self.assertFalse(res_unmerged.safe_to_update)
        self.assertEqual(res_unmerged.expected_head_state, "")
        self.assertEqual(res_unmerged.expected_head_oid, "")
        self.assertIsNotNone(res_unmerged.blocking_reason)
        self.assertIn("outside embedded libznn blobs/manifest", res_unmerged.blocking_reason or "")
        out_unmerged = gh_out.read_text(encoding="utf-8")
        self.assertIn("safe_to_update=false\n", out_unmerged)
        self.assertIn("blocking_reason=", out_unmerged)
        self.assertIn("outside embedded libznn blobs/manifest", out_unmerged)
        self.assertIn("outside embedded libznn blobs/manifest", summary.read_text(encoding="utf-8"))

        # Verify CLI exits 1 with ::error:: for blocked orphan branch (never silently green).
        orig_build_opener = updater._build_opener
        orig_token = os.environ.get("GH_TOKEN")
        orig_gha = os.environ.get("GITHUB_ACTIONS")
        stdout_buf = io.StringIO()
        old_stdout = sys.stdout
        try:
            updater._build_opener = lambda: opener_unmerged  # type: ignore[assignment]
            os.environ["GH_TOKEN"] = "ghs_test"
            os.environ["GITHUB_ACTIONS"] = "true"
            sys.stdout = stdout_buf
            rc_orphan = stale_pr.main(
                [
                    "--check-update-safe",
                    "--repo",
                    "zenon-network/syrius",
                    "--target-branch",
                    "develop",
                    "--pr-branch",
                    "chore/update-libznn-develop",
                    "--release-tag",
                    "v0.0.11-alphanet",
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            sys.stdout = old_stdout
            if orig_token is None:
                os.environ.pop("GH_TOKEN", None)
            else:
                os.environ["GH_TOKEN"] = orig_token
            if orig_gha is None:
                os.environ.pop("GITHUB_ACTIONS", None)
            else:
                os.environ["GITHUB_ACTIONS"] = orig_gha
        self.assertEqual(rc_orphan, 1)
        self.assertIn("::error::Blocking rolling PR update", stdout_buf.getvalue())

        # 7. Orphan branch containing forced downgrade commit or prerelease manifest -> blocked!
        opener_dg_orphan = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): b"[]",
                ("GET", ref_url): self._branch_ref_response("chore/update-libznn-develop", sha_b),
                ("GET", self._compare_url("develop", sha_b)): json.dumps(
                    {
                        "status": "ahead",
                        "ahead_by": 1,
                        "commits": [
                            {
                                "commit": {
                                    "message": "chore: update embedded libznn to go-zenon v0.0.9 (downgrade)"
                                }
                            }
                        ],
                        "files": [{"filename": path} for path in self.all_updater_files],
                    }
                ).encode("utf-8"),
            }
        )
        res_dg_orphan = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_dg_orphan,  # type: ignore[arg-type]
        )
        self.assertFalse(res_dg_orphan.safe_to_update)
        self.assertIn("forced downgrade", res_dg_orphan.blocking_reason or "")

        # 8. Strict PR listing ignores deleted-fork (head.repo=None) PRs but fails closed on malformed entries.
        deleted_fork_pr = _pr_obj(number=330, title="deleted fork")
        deleted_fork_pr["head"]["repo"] = None
        opener_del_fork = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps([deleted_fork_pr]).encode("utf-8"),
                ("GET", ref_url): urllib.error.HTTPError(
                    ref_url, 404, "Not Found", {}, None  # type: ignore[arg-type]
                ),
            }
        )
        res_del_fork = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_del_fork,  # type: ignore[arg-type]
        )
        self.assertTrue(res_del_fork.safe_to_update)

        opener_malformed = _RecordingOpener(
            {("GET", self.list_develop_head_only_url): json.dumps(["not-a-dict"]).encode("utf-8")}
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Malformed non-object entry"):
            stale_pr.check_pr_branch_safe_to_update(
                repo="zenon-network/syrius",
                target_branch="develop",
                pr_branch="chore/update-libznn-develop",
                release_tag="v0.0.11-alphanet",
                github_token="ghs_test",
                opener=opener_malformed,  # type: ignore[arg-type]
            )

    def test_update_guard_rejects_tag_scoped_branch_and_cli_emits_warning_in_ci(self) -> None:
        with self.assertRaisesRegex(updater.UpdaterError, "unexpected PR branch"):
            stale_pr.check_pr_branch_safe_to_update(
                repo="zenon-network/syrius",
                target_branch="develop",
                pr_branch="chore/update-libznn-develop-v0.0.11-rc.1",
                release_tag="v0.0.11-alphanet",
                github_token="ghs_test",
            )

        pre_prs = [
            _pr_obj(
                number=308,
                title="chore: update embedded libznn to go-zenon v0.0.11-rc.1 (prerelease)",
            )
        ]
        opener = _RecordingOpener(
            {("GET", self.list_develop_head_only_url): json.dumps(pre_prs).encode("utf-8")}
        )
        gh_out = self.root / "cli_guard.out"
        orig_build_opener = updater._build_opener
        orig_token = os.environ.get("GH_TOKEN")
        orig_gha = os.environ.get("GITHUB_ACTIONS")
        stdout_buf = io.StringIO()
        old_stdout = sys.stdout
        try:
            updater._build_opener = lambda: opener  # type: ignore[assignment]
            os.environ["GH_TOKEN"] = "ghs_test"
            os.environ["GITHUB_ACTIONS"] = "true"
            sys.stdout = stdout_buf
            rc = stale_pr.main(
                [
                    "--check-update-safe",
                    "--repo",
                    "zenon-network/syrius",
                    "--target-branch",
                    "develop",
                    "--pr-branch",
                    "chore/update-libznn-develop",
                    "--release-tag",
                    "v0.0.10-alphanet",
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
            if orig_gha is None:
                os.environ.pop("GITHUB_ACTIONS", None)
            else:
                os.environ["GITHUB_ACTIONS"] = orig_gha

        self.assertEqual(rc, 0)
        self.assertIn("::warning::Skipping rolling PR update", stdout_buf.getvalue())
        self.assertIn("safe_to_update=false\n", gh_out.read_text(encoding="utf-8"))

    def test_update_guard_fails_closed_on_api_error_and_deleted_manifest(self) -> None:
        # 1. PR that deleted libznn.manifest.json reports accurate missing-manifest reason.
        head_deleted = "f" * 40
        deleted_prs = [
            _pr_obj(
                number=309,
                title="chore: update embedded libznn to go-zenon v0.0.10-alphanet",
                head_sha=head_deleted,
            )
        ]
        opener_deleted = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): json.dumps(deleted_prs).encode("utf-8"),
                ("GET", self._files_url(309)): _pr_files_response([updater.MANIFEST_RELPATH]),
                ("GET", self._manifest_contents_url(head_deleted)): urllib.error.HTTPError(
                    self._manifest_contents_url(head_deleted),
                    404,
                    "Not Found",
                    {},
                    None,  # type: ignore[arg-type]
                ),
            }
        )
        res_deleted = stale_pr.check_pr_branch_safe_to_update(
            repo="zenon-network/syrius",
            target_branch="develop",
            pr_branch="chore/update-libznn-develop",
            release_tag="v0.0.11-alphanet",
            github_token="ghs_test",
            opener=opener_deleted,  # type: ignore[arg-type]
        )
        self.assertFalse(res_deleted.safe_to_update)
        self.assertIn("missing `lib/embedded_node/blobs/libznn.manifest.json`", res_deleted.blocking_prs[0].reason)
        self.assertNotIn("modifies non-blob files", res_deleted.blocking_prs[0].reason)

        # 2. GitHub API HTTP 500 error in --check-update-safe CLI mode returns exit 1 (fail closed).
        opener_err = _RecordingOpener(
            {
                ("GET", self.list_develop_head_only_url): urllib.error.HTTPError(
                    self.list_develop_head_only_url,
                    500,
                    "Internal Server Error",
                    {},
                    None,  # type: ignore[arg-type]
                )
            }
        )
        orig_build_opener = updater._build_opener
        orig_sleep = updater.time.sleep
        orig_token = os.environ.get("GH_TOKEN")
        stderr_buf = io.StringIO()
        old_stderr = sys.stderr
        try:
            updater._build_opener = lambda: opener_err  # type: ignore[assignment]
            updater.time.sleep = lambda _s: None  # type: ignore[assignment]
            os.environ["GH_TOKEN"] = "ghs_test"
            sys.stderr = stderr_buf
            rc = stale_pr.main(
                [
                    "--check-update-safe",
                    "--repo",
                    "zenon-network/syrius",
                    "--target-branch",
                    "develop",
                    "--pr-branch",
                    "chore/update-libznn-develop",
                    "--release-tag",
                    "v0.0.11-alphanet",
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            updater.time.sleep = orig_sleep
            sys.stderr = old_stderr
            if orig_token is None:
                os.environ.pop("GH_TOKEN", None)
            else:
                os.environ["GH_TOKEN"] = orig_token

        self.assertEqual(rc, 1)
        self.assertIn("HTTP 500", stderr_buf.getvalue())


if __name__ == "__main__":
    unittest.main()
