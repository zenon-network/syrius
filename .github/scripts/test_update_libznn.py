#!/usr/bin/env python3
"""Unit tests for .github/scripts/update_libznn.py."""

from __future__ import annotations

import hashlib
import io
import json
import os
import pathlib
import stat
import sys
import tarfile
import tempfile
import unittest
import urllib.request
import zipfile
from typing import Any

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import update_libznn as updater


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _make_tar_gz(entries: list[tuple[str, bytes, int | None, str | None]]) -> bytes:
    """Create a .tar.gz in memory. Each entry is (name, data, type_override, linkname)."""
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tf:
        for name, data, type_override, linkname in entries:
            info = tarfile.TarInfo(name=name)
            if type_override is not None:
                info.type = type_override
                if linkname is not None:
                    info.linkname = linkname
                tf.addfile(info)
            else:
                info.size = len(data)
                tf.addfile(info, io.BytesIO(data))
    return buf.getvalue()


def _make_zip(entries: list[tuple[str, bytes, int | None]]) -> bytes:
    """Create a .zip in memory. Each entry is (name, data, external_attr)."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
        for name, data, external_attr in entries:
            info = zipfile.ZipInfo(name)
            if external_attr is not None:
                info.external_attr = external_attr
            zf.writestr(info, data)
    return buf.getvalue()


class _FakeResponse:
    def __init__(self, payload: bytes) -> None:
        self._stream = io.BytesIO(payload)

    def read(self, size: int = -1) -> bytes:
        return self._stream.read(size)

    def __enter__(self) -> _FakeResponse:
        return self

    def __exit__(self, *args: Any) -> None:
        self._stream.close()


class _FakeOpener:
    def __init__(self, responses: dict[str, bytes]) -> None:
        self.responses = responses
        self.requests: list[urllib.request.Request] = []

    def open(self, req: urllib.request.Request, timeout: int = 60) -> _FakeResponse:
        self.requests.append(req)
        if req.full_url not in self.responses:
            raise AssertionError(f"Unexpected URL requested: {req.full_url}")
        return _FakeResponse(self.responses[req.full_url])


class ValidationTests(unittest.TestCase):
    def test_validate_tag_accepts_valid_and_empty(self) -> None:
        self.assertEqual(updater.validate_tag(""), "")
        self.assertEqual(updater.validate_tag("  v0.0.10-alphanet  "), "v0.0.10-alphanet")
        self.assertEqual(updater.validate_tag("v1.2.3+build.1"), "v1.2.3+build.1")

    def test_validate_tag_rejects_traversal_and_metacharacters(self) -> None:
        for bad in (
            "../v1",
            "v1/v2",
            "v1..v2",
            "v1;rm -rf /",
            "v1\nv2",
            "v1\n",
            "v1 v2",
            "--dry-run",
            ".hidden",
        ):
            with self.subTest(bad=bad):
                with self.assertRaises(updater.UpdaterError):
                    updater.validate_tag(bad)

    def test_validate_target_branch(self) -> None:
        self.assertEqual(updater.validate_target_branch("develop"), "develop")
        self.assertEqual(updater.validate_target_branch("master"), "master")
        with self.assertRaises(updater.UpdaterError):
            updater.validate_target_branch("main")

    def test_validate_download_url_checks_host_and_prefix(self) -> None:
        valid = "https://github.com/zenon-network/go-zenon/releases/download/v0.0.10-alphanet/libznn-linux-amd64.tar.gz"
        self.assertEqual(
            updater.validate_release_download_url(valid, "zenon-network/go-zenon"),
            valid,
        )
        for bad in (
            "http://github.com/zenon-network/go-zenon/releases/download/v1/a.tar.gz",
            "https://evil.example/zenon-network/go-zenon/releases/download/v1/a.tar.gz",
            "https://github.com/other/repo/releases/download/v1/a.tar.gz",
        ):
            with self.subTest(bad=bad):
                with self.assertRaises(updater.UpdaterError):
                    updater.validate_release_download_url(bad, "zenon-network/go-zenon")

    def test_safe_redirect_handler_blocks_http_and_strips_auth_cross_host(self) -> None:
        handler = updater._SafeRedirectHandler()
        req = urllib.request.Request(
            "https://api.github.com/repos/zenon-network/go-zenon/releases/latest",
            headers={"Authorization": "Bearer super-secret"},
        )
        with self.assertRaises(updater.UpdaterError):
            handler.redirect_request(req, None, 302, "Found", {}, "http://example.com/file")

        redirected = handler.redirect_request(
            req,
            None,
            302,
            "Found",
            {},
            "https://objects.githubusercontent.com/some-blob",
        )
        self.assertIsNotNone(redirected)
        assert redirected is not None
        self.assertFalse(redirected.has_header("Authorization"))


class ChecksumTests(unittest.TestCase):
    def test_parse_checksums_file_formats(self) -> None:
        h1 = "a" * 64
        h2 = "B" * 64
        h3 = "c" * 64
        content = (
            f"{h1}  libznn-linux-amd64.tar.gz\r\n"
            f"{h2} *./libznn-windows-amd64.zip\n"
            "\n"
            f"{h3}\tlibznn-darwin-universal.tar.gz\n"
        )
        parsed = updater.parse_checksums_file(content)
        self.assertEqual(
            parsed,
            {
                "libznn-linux-amd64.tar.gz": h1,
                "libznn-windows-amd64.zip": h2.lower(),
                "libznn-darwin-universal.tar.gz": h3,
            },
        )

    def test_parse_checksums_file_rejects_malformed_or_conflicting(self) -> None:
        with self.assertRaises(updater.UpdaterError):
            updater.parse_checksums_file("not-a-hash  file.tar.gz\n")
        with self.assertRaises(updater.UpdaterError):
            updater.parse_checksums_file(f"{'a' * 64}  ../escape.tar.gz\n")
        with self.assertRaises(updater.UpdaterError):
            updater.parse_checksums_file(
                f"{'a' * 64}  same.tar.gz\n{'b' * 64}  same.tar.gz\n"
            )

    def test_verify_asset_checksum_dual_and_single_sources(self) -> None:
        h = "1" * 64
        both = updater.verify_asset_checksum(
            asset_name="libznn-linux-amd64.tar.gz",
            actual_sha256=h,
            checksums_map={"libznn-linux-amd64.tar.gz": h},
            github_digest_sha256=h,
        )
        self.assertIn("SHA256CHECKSUMS.txt", both.source_description)
        self.assertIn("GitHub release digest", both.source_description)

        gh_only = updater.verify_asset_checksum(
            asset_name="libznn-darwin-universal.tar.gz",
            actual_sha256=h,
            checksums_map={"libznn-linux-amd64.tar.gz": "2" * 64},
            github_digest_sha256=h,
        )
        self.assertIn("not listed in `SHA256CHECKSUMS.txt`", gh_only.source_description)

        file_only = updater.verify_asset_checksum(
            asset_name="libznn-linux-amd64.tar.gz",
            actual_sha256=h,
            checksums_map={"libznn-linux-amd64.tar.gz": h},
            github_digest_sha256=None,
        )
        self.assertEqual(file_only.source_description, "`SHA256CHECKSUMS.txt`")

    def test_verify_asset_checksum_fails_closed(self) -> None:
        h = "1" * 64
        wrong = "2" * 64
        # Missing from both sources
        with self.assertRaises(updater.UpdaterError):
            updater.verify_asset_checksum(
                asset_name="libznn-darwin-universal.tar.gz",
                actual_sha256=h,
                checksums_map={},
                github_digest_sha256=None,
            )
        # Mismatch against SHA256CHECKSUMS.txt when GitHub digest disagrees (conflict detected)
        with self.assertRaisesRegex(updater.UpdaterError, "Conflicting upstream checksums"):
            updater.verify_asset_checksum(
                asset_name="libznn-linux-amd64.tar.gz",
                actual_sha256=h,
                checksums_map={"libznn-linux-amd64.tar.gz": wrong},
                github_digest_sha256=h,
            )
        # Mismatch against SHA256CHECKSUMS.txt alone
        with self.assertRaisesRegex(updater.UpdaterError, "SHA256CHECKSUMS.txt"):
            updater.verify_asset_checksum(
                asset_name="libznn-linux-amd64.tar.gz",
                actual_sha256=h,
                checksums_map={"libznn-linux-amd64.tar.gz": wrong},
                github_digest_sha256=None,
            )
        # Mismatch against GitHub digest alone
        with self.assertRaisesRegex(updater.UpdaterError, "GitHub release digest"):
            updater.verify_asset_checksum(
                asset_name="libznn-linux-amd64.tar.gz",
                actual_sha256=h,
                checksums_map={},
                github_digest_sha256=wrong,
            )
        # Strict checksums-file requirement
        with self.assertRaises(updater.UpdaterError):
            updater.verify_asset_checksum(
                asset_name="libznn-darwin-universal.tar.gz",
                actual_sha256=h,
                checksums_map={},
                github_digest_sha256=h,
                require_in_checksums_file=True,
            )

    def test_parse_github_asset_digest_rejects_bad_algorithms(self) -> None:
        self.assertIsNone(updater.parse_github_asset_digest(None, "a.tar.gz"))
        self.assertEqual(
            updater.parse_github_asset_digest(f"sha256:{'A' * 64}", "a.tar.gz"),
            "a" * 64,
        )
        with self.assertRaises(updater.UpdaterError):
            updater.parse_github_asset_digest(f"md5:{'a' * 32}", "a.tar.gz")


class ExtractionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.tmp = pathlib.Path(self.tmpdir.name)
        self.linux_spec = updater.BINARY_SPECS[0]
        self.darwin_spec = updater.BINARY_SPECS[1]
        self.win_spec = updater.BINARY_SPECS[2]

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_extract_valid_tar_and_zip_including_dot_slash(self) -> None:
        elf_bytes = b"\x7fELF" + b"\x00" * 60
        tar_path = self.tmp / "linux.tar.gz"
        tar_path.write_bytes(_make_tar_gz([("./libznn-linux-amd64.so", elf_bytes, None, None)]))
        out_so = self.tmp / "out.so"
        digest = updater.extract_expected_binary(tar_path, self.linux_spec, out_so)
        self.assertEqual(digest, _sha256_bytes(elf_bytes))
        self.assertEqual(out_so.read_bytes(), elf_bytes)

        pe_bytes = b"MZ" + b"\x90" * 60
        zip_path = self.tmp / "win.zip"
        zip_path.write_bytes(_make_zip([("libznn-windows-amd64.dll", pe_bytes, None)]))
        out_dll = self.tmp / "out.dll"
        digest_win = updater.extract_expected_binary(zip_path, self.win_spec, out_dll)
        self.assertEqual(digest_win, _sha256_bytes(pe_bytes))
        self.assertEqual(out_dll.read_bytes(), pe_bytes)

    def test_rejects_tar_symlink_traversal_and_bad_magic(self) -> None:
        # Symlink member masquerading as expected binary
        sym_tar = self.tmp / "sym.tar.gz"
        sym_tar.write_bytes(
            _make_tar_gz([("libznn-linux-amd64.so", b"", tarfile.SYMTYPE, "/etc/passwd")])
        )
        with self.assertRaises(updater.UpdaterError):
            updater.extract_expected_binary(sym_tar, self.linux_spec, self.tmp / "s.so")

        # Path traversal member only (missing valid top-level member)
        trav_tar = self.tmp / "trav.tar.gz"
        trav_tar.write_bytes(
            _make_tar_gz([("../libznn-linux-amd64.so", b"\x7fELF1234", None, None)])
        )
        with self.assertRaises(updater.UpdaterError):
            updater.extract_expected_binary(trav_tar, self.linux_spec, self.tmp / "t.so")

        # Invalid binary magic (e.g. HTML error page)
        bad_magic = self.tmp / "html.tar.gz"
        bad_magic.write_bytes(
            _make_tar_gz([("libznn-linux-amd64.so", b"<html>not elf</html>", None, None)])
        )
        with self.assertRaises(updater.UpdaterError):
            updater.extract_expected_binary(bad_magic, self.linux_spec, self.tmp / "h.so")

    def test_rejects_zip_symlink_and_oversized_member(self) -> None:
        symlink_attr = (0o120777 << 16)
        sym_zip = self.tmp / "sym.zip"
        sym_zip.write_bytes(_make_zip([("libznn-windows-amd64.dll", b"MZtarget", symlink_attr)]))
        with self.assertRaises(updater.UpdaterError):
            updater.extract_expected_binary(sym_zip, self.win_spec, self.tmp / "z.dll")

        big_zip = self.tmp / "big.zip"
        big_zip.write_bytes(_make_zip([("libznn-windows-amd64.dll", b"MZ" + b"0" * 100, None)]))
        with self.assertRaises(updater.UpdaterError):
            updater.extract_expected_binary(
                big_zip,
                self.win_spec,
                self.tmp / "b.dll",
                max_extracted_bytes=32,
            )


class EndToEndUpdateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmpdir.name)
        self.repo_root = self.root / "repo"
        self.work_dir = self.root / "work"
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        blobs.mkdir(parents=True)
        self.old_linux = b"\x7fELF-old-linux"
        self.old_darwin = b"\xca\xfe\xba\xbe-old-darwin"
        self.old_windows = b"MZ-old-windows"
        (blobs / "libznn.so").write_bytes(self.old_linux)
        os.chmod(blobs / "libznn.so", 0o755)
        (blobs / "libznn.dylib").write_bytes(self.old_darwin)
        os.chmod(blobs / "libznn.dylib", 0o644)
        (blobs / "libznn.dll").write_bytes(self.old_windows)
        os.chmod(blobs / "libznn.dll", 0o755)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _build_mock_release(
        self,
        *,
        tag: str,
        linux_bin: bytes,
        darwin_bin: bytes,
        windows_bin: bytes,
        include_darwin_in_checksums: bool = False,
        corrupt_windows_digest: bool = False,
        prerelease: bool = False,
        immutable: bool | None = False,
        published_at: str = "2026-11-20T12:00:00Z",
        asset_updated_at: str = "2026-11-20T12:00:00Z",
        checksums_updated_at: str | None = None,
        target_commitish: str | None = None,
        tag_commit: str | None = None,
        annotated_tag_sha: str | None = None,
    ) -> tuple[_FakeOpener, dict[str, str]]:
        linux_arc = _make_tar_gz([("libznn-linux-amd64.so", linux_bin, None, None)])
        darwin_arc = _make_tar_gz([("libznn-darwin-universal.dylib", darwin_bin, None, None)])
        win_arc = _make_zip([("libznn-windows-amd64.dll", windows_bin, None)])

        linux_sha = _sha256_bytes(linux_arc)
        darwin_sha = _sha256_bytes(darwin_arc)
        win_sha = _sha256_bytes(win_arc)

        checksum_lines = [
            f"{linux_sha}  libznn-linux-amd64.tar.gz",
            f"{win_sha}  libznn-windows-amd64.zip",
        ]
        if include_darwin_in_checksums:
            checksum_lines.append(f"{darwin_sha}  libznn-darwin-universal.tar.gz")
        checksums_bytes = ("\n".join(checksum_lines) + "\n").encode("utf-8")
        checksums_sha = _sha256_bytes(checksums_bytes)

        resolved_tag_commit = tag_commit or "a" * 40
        resolved_target_commitish = (
            target_commitish if target_commitish is not None else resolved_tag_commit
        )
        csum_updated = checksums_updated_at if checksums_updated_at is not None else asset_updated_at

        base_dl = f"https://github.com/zenon-network/go-zenon/releases/download/{tag}"
        payload: dict[str, Any] = {
            "tag_name": tag,
            "name": tag,
            "draft": False,
            "prerelease": prerelease,
            "published_at": published_at,
            "target_commitish": resolved_target_commitish,
            "html_url": f"https://github.com/zenon-network/go-zenon/releases/tag/{tag}",
            "assets": [
                {
                    "name": "libznn-linux-amd64.tar.gz",
                    "browser_download_url": f"{base_dl}/libznn-linux-amd64.tar.gz",
                    "digest": f"sha256:{linux_sha}",
                    "updated_at": asset_updated_at,
                },
                {
                    "name": "libznn-darwin-universal.tar.gz",
                    "browser_download_url": f"{base_dl}/libznn-darwin-universal.tar.gz",
                    "digest": f"sha256:{darwin_sha}",
                    "updated_at": asset_updated_at,
                },
                {
                    "name": "libznn-windows-amd64.zip",
                    "browser_download_url": f"{base_dl}/libznn-windows-amd64.zip",
                    "digest": f"sha256:{'0' * 64 if corrupt_windows_digest else win_sha}",
                    "updated_at": asset_updated_at,
                },
                {
                    "name": "SHA256CHECKSUMS.txt",
                    "browser_download_url": f"{base_dl}/SHA256CHECKSUMS.txt",
                    "digest": f"sha256:{checksums_sha}",
                    "updated_at": csum_updated,
                },
            ],
        }
        if immutable is not None:
            payload["immutable"] = immutable

        responses: dict[str, bytes] = {
            f"https://api.github.com/repos/zenon-network/go-zenon/releases/tags/{tag}": json.dumps(
                payload
            ).encode("utf-8"),
            "https://api.github.com/repos/zenon-network/go-zenon/releases/latest": json.dumps(
                payload
            ).encode("utf-8"),
            f"{base_dl}/libznn-linux-amd64.tar.gz": linux_arc,
            f"{base_dl}/libznn-darwin-universal.tar.gz": darwin_arc,
            f"{base_dl}/libznn-windows-amd64.zip": win_arc,
            f"{base_dl}/SHA256CHECKSUMS.txt": checksums_bytes,
        }
        if annotated_tag_sha is not None:
            responses[
                f"https://api.github.com/repos/zenon-network/go-zenon/git/ref/tags/{tag}"
            ] = json.dumps(
                {
                    "ref": f"refs/tags/{tag}",
                    "object": {"sha": annotated_tag_sha, "type": "tag"},
                }
            ).encode("utf-8")
            responses[
                f"https://api.github.com/repos/zenon-network/go-zenon/git/tags/{annotated_tag_sha}"
            ] = json.dumps(
                {
                    "sha": annotated_tag_sha,
                    "object": {"sha": resolved_tag_commit, "type": "commit"},
                }
            ).encode("utf-8")
        else:
            responses[
                f"https://api.github.com/repos/zenon-network/go-zenon/git/ref/tags/{tag}"
            ] = json.dumps(
                {
                    "ref": f"refs/tags/{tag}",
                    "object": {"sha": resolved_tag_commit, "type": "commit"},
                }
            ).encode("utf-8")

        return _FakeOpener(responses), {
            "linux_arc": linux_sha,
            "darwin_arc": darwin_sha,
            "win_arc": win_sha,
            "checksums": checksums_sha,
            "tag_commit": resolved_tag_commit,
        }

    def test_updates_changed_blobs_preserves_modes_and_writes_provenance(self) -> None:
        new_linux = b"\x7fELF-new-linux-v11"
        new_darwin = b"\xca\xfe\xba\xbe-new-darwin-v11"
        new_windows = b"MZ-new-windows-v11"
        opener, hashes = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=new_linux,
            darwin_bin=new_darwin,
            windows_bin=new_windows,
        )

        pr_body_path = self.work_dir / "pr-body.md"
        gh_output = self.work_dir / "github_output.txt"
        summary_path = self.work_dir / "summary.md"

        release, verified, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="",
            target_branch="develop",
            pr_body_out=pr_body_path,
            github_output=gh_output,
            step_summary=summary_path,
            github_token="ghs_test_token",
            workflow_run_url="https://github.com/zenon-network/syrius/actions/runs/123",
            opener=opener,  # type: ignore[arg-type]
        )

        self.assertTrue(changed)
        self.assertEqual(release.tag_name, "v0.0.11-alphanet")
        self.assertEqual(len(verified), 3)
        self.assertFalse(hasattr(verified[0], "extracted_path"))

        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        self.assertEqual((blobs / "libznn.so").read_bytes(), new_linux)
        self.assertEqual((blobs / "libznn.dylib").read_bytes(), new_darwin)
        self.assertEqual((blobs / "libznn.dll").read_bytes(), new_windows)
        self.assertEqual(stat.S_IMODE((blobs / "libznn.so").stat().st_mode), 0o755)
        self.assertEqual(stat.S_IMODE((blobs / "libznn.dylib").stat().st_mode), 0o644)
        self.assertEqual(stat.S_IMODE((blobs / "libznn.dll").stat().st_mode), 0o755)

        # Ensure Authorization header was ONLY sent to api.github.com, never to download URLs.
        for req in opener.requests:
            if req.full_url.startswith("https://api.github.com/"):
                self.assertEqual(req.get_header("Authorization"), "Bearer ghs_test_token")
            else:
                self.assertIsNone(req.get_header("Authorization"))

        pr_body = pr_body_path.read_text(encoding="utf-8")
        self.assertIn("v0.0.11-alphanet", pr_body)
        self.assertIn(hashes["linux_arc"], pr_body)
        self.assertIn(hashes["darwin_arc"], pr_body)
        self.assertIn(hashes["win_arc"], pr_body)
        self.assertIn(_sha256_bytes(new_linux), pr_body)
        self.assertIn(_sha256_bytes(self.old_linux), pr_body)
        self.assertIn("Approve workflows to run", pr_body)
        self.assertNotIn("close and reopen", pr_body)

        gh_out_text = gh_output.read_text(encoding="utf-8")
        self.assertIn("changed=true\n", gh_out_text)
        self.assertIn("release_tag=v0.0.11-alphanet\n", gh_out_text)
        self.assertIn("commit_message<<EOF_", gh_out_text)
        base_dl = "https://github.com/zenon-network/go-zenon/releases/download/v0.0.11-alphanet"
        self.assertIn(f"{base_dl}/libznn-linux-amd64.tar.gz", gh_out_text)
        self.assertIn(f"{base_dl}/libznn-darwin-universal.tar.gz", gh_out_text)
        self.assertIn(f"{base_dl}/libznn-windows-amd64.zip", gh_out_text)
        self.assertIn(f"{base_dl}/SHA256CHECKSUMS.txt", gh_out_text)
        self.assertIn(hashes["checksums"], gh_out_text)

    def test_release_json_mode_skips_api_call_and_verifies_assets(self) -> None:
        new_linux = b"\x7fELF-json-mode"
        new_darwin = b"\xca\xfe\xba\xbe-json-mode"
        new_windows = b"MZ-json-mode"
        opener, _ = self._build_mock_release(
            tag="v0.0.12-alphanet",
            linux_bin=new_linux,
            darwin_bin=new_darwin,
            windows_bin=new_windows,
        )
        api_url = "https://api.github.com/repos/zenon-network/go-zenon/releases/tags/v0.0.12-alphanet"
        release_json_path = self.root / "release.json"
        release_json_path.write_bytes(opener.responses.pop(api_url))
        opener.responses.pop(
            "https://api.github.com/repos/zenon-network/go-zenon/releases/latest"
        )

        _, _, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.12-alphanet",
            release_json=release_json_path,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertTrue(changed)
        self.assertTrue(
            all(not req.full_url.startswith("https://api.github.com/") for req in opener.requests)
        )

    def test_rejects_draft_tag_mismatch_bad_html_url_missing_asset_and_bad_checksums_digest(
        self,
    ) -> None:
        opener_full, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-1",
            darwin_bin=b"\xca\xfe\xba\xbe-1",
            windows_bin=b"MZ-1",
        )
        base_payload = json.loads(
            opener_full.responses[
                "https://api.github.com/repos/zenon-network/go-zenon/releases/tags/v0.0.11-alphanet"
            ].decode("utf-8")
        )

        def run_with_payload(
            payload: dict[str, Any],
            *,
            tag: str = "v0.0.11-alphanet",
            extra_responses: dict[str, bytes] | None = None,
        ) -> None:
            meta_file = self.root / "bad_release.json"
            meta_file.write_text(json.dumps(payload), encoding="utf-8")
            opener = _FakeOpener(extra_responses or {})
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag=tag,
                release_json=meta_file,
                opener=opener,  # type: ignore[arg-type]
            )

        # 1. Draft release
        draft_payload = dict(base_payload, draft=True)
        with self.assertRaisesRegex(updater.UpdaterError, "draft"):
            run_with_payload(draft_payload)

        # 2. Resolved tag differs from requested tag
        with self.assertRaisesRegex(updater.UpdaterError, "does not match resolved"):
            run_with_payload(base_payload, tag="v0.0.99-alphanet")

        # 3. Untrusted html_url
        bad_url_payload = dict(
            base_payload,
            html_url="https://evil.example/zenon-network/go-zenon/releases/tag/v0.0.11-alphanet",
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Untrusted release URL"):
            run_with_payload(bad_url_payload)

        # 4. Missing required asset (reuses opener_full so archive/checksums match base_payload)
        missing_asset_payload = dict(
            base_payload,
            assets=[
                a for a in base_payload["assets"] if a["name"] != "libznn-windows-amd64.zip"
            ],
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Required asset"):
            run_with_payload(missing_asset_payload, extra_responses=opener_full.responses)

        # 5. SHA256CHECKSUMS.txt content does not match its GitHub digest
        bad_csum_assets = []
        for asset in base_payload["assets"]:
            if asset["name"] == "SHA256CHECKSUMS.txt":
                bad_csum_assets.append(dict(asset, digest=f"sha256:{'f' * 64}"))
            else:
                bad_csum_assets.append(asset)
        bad_csum_payload = dict(base_payload, assets=bad_csum_assets)
        with self.assertRaisesRegex(
            updater.UpdaterError, "SHA-256 mismatch for SHA256CHECKSUMS.txt"
        ):
            run_with_payload(bad_csum_payload, extra_responses=opener_full.responses)

    def test_download_retries_on_connection_reset_truncated_body_and_bounds_attempts(self) -> None:
        url = "https://github.com/zenon-network/go-zenon/releases/download/v0.0.11-alphanet/libznn-linux-amd64.tar.gz"

        class _FlakyStream:
            def __init__(
                self,
                *,
                fail_reset: bool = False,
                data: bytes = b"",
                headers: dict[str, str] | None = None,
            ) -> None:
                self._fail_reset = fail_reset
                self._stream = io.BytesIO(data)
                self.headers = headers or {}
                self.closed = False

            def read(self, size: int = -1) -> bytes:
                if self._fail_reset:
                    raise ConnectionResetError("connection reset by peer")
                return self._stream.read(size)

            def __enter__(self) -> _FlakyStream:
                return self

            def __exit__(self, *args: Any) -> None:
                self.closed = True
                self._stream.close()

        class _FlakyOpener:
            def __init__(self, responses: list[_FlakyStream]) -> None:
                self.calls = 0
                self._responses = responses

            def open(self, req: urllib.request.Request, timeout: int = 60) -> _FlakyStream:
                idx = min(self.calls, len(self._responses) - 1)
                self.calls += 1
                return self._responses[idx]

        dest = self.root / "flaky.tar.gz"
        payload = b"recovered-payload"
        flaky_ok = _FlakyOpener(
            [
                _FlakyStream(fail_reset=True),
                _FlakyStream(
                    data=payload[:5],
                    headers={"Content-Length": str(len(payload))},
                ),
                _FlakyStream(
                    data=payload,
                    headers={"Content-Length": str(len(payload))},
                ),
            ]
        )
        digest = updater.download_release_file(
            url,
            dest,
            upstream_repo="zenon-network/go-zenon",
            max_bytes=1024,
            opener=flaky_ok,  # type: ignore[arg-type]
            max_attempts=3,
            retry_backoff_seconds=0,
        )
        self.assertEqual(flaky_ok.calls, 3)
        self.assertEqual(digest, _sha256_bytes(payload))

        # Persistent truncated body fails cleanly after max_attempts and removes partial file.
        truncated_fail = _FlakyOpener(
            [
                _FlakyStream(
                    data=payload[:4],
                    headers={"Content-Length": str(len(payload))},
                ),
                _FlakyStream(
                    data=payload[:4],
                    headers={"Content-Length": str(len(payload))},
                ),
                _FlakyStream(
                    data=payload[:4],
                    headers={"Content-Length": str(len(payload))},
                ),
            ]
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Network error downloading"):
            updater.download_release_file(
                url,
                dest,
                upstream_repo="zenon-network/go-zenon",
                max_bytes=1024,
                opener=truncated_fail,  # type: ignore[arg-type]
                max_attempts=3,
                retry_backoff_seconds=0,
            )
        self.assertEqual(truncated_fail.calls, 3)
        self.assertFalse(dest.exists())

    def test_fetch_release_metadata_retries_body_read_failure_and_closes_response(self) -> None:
        good_json = json.dumps({"tag_name": "v0.0.11-alphanet"}).encode("utf-8")

        class _MetaStream:
            def __init__(self, fail_read: bool, data: bytes) -> None:
                self._fail_read = fail_read
                self._data = data
                self.closed = False

            def read(self, size: int = -1) -> bytes:
                if self._fail_read:
                    raise TimeoutError("timed out reading metadata body")
                return self._data[:size] if size >= 0 else self._data

            def __enter__(self) -> _MetaStream:
                return self

            def __exit__(self, *args: Any) -> None:
                self.closed = True

        first_stream = _MetaStream(fail_read=True, data=b"")
        second_stream = _MetaStream(fail_read=False, data=good_json)

        class _MetaOpener:
            def __init__(self) -> None:
                self.calls = 0

            def open(self, req: urllib.request.Request, timeout: int = 60) -> _MetaStream:
                self.calls += 1
                return first_stream if self.calls == 1 else second_stream

        opener = _MetaOpener()
        payload = updater.fetch_release_metadata(
            "zenon-network/go-zenon",
            "v0.0.11-alphanet",
            opener=opener,  # type: ignore[arg-type]
            max_attempts=3,
            retry_backoff_seconds=0,
        )
        self.assertEqual(opener.calls, 2)
        self.assertTrue(first_stream.closed)
        self.assertTrue(second_stream.closed)
        self.assertEqual(payload["tag_name"], "v0.0.11-alphanet")

    def test_main_fetch_metadata_only_errors_without_output_and_emits_warning_in_ci(self) -> None:
        stderr_buf = io.StringIO()
        old_stderr = sys.stderr
        try:
            sys.stderr = stderr_buf
            rc = updater.main(["--fetch-metadata-only"])
        finally:
            sys.stderr = old_stderr
        self.assertEqual(rc, 1)
        self.assertIn("--metadata-out is required", stderr_buf.getvalue())

        # Verify ::warning:: annotation on digest-only fallback uses accurate source description.
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-warn",
            darwin_bin=b"\xca\xfe\xba\xbe-warn",
            windows_bin=b"MZ-warn",
            include_darwin_in_checksums=False,
        )
        release_json = self.root / "warn_release.json"
        release_json.write_bytes(
            opener.responses[
                "https://api.github.com/repos/zenon-network/go-zenon/releases/tags/v0.0.11-alphanet"
            ]
        )
        orig_build_opener = updater._build_opener
        orig_gha = os.environ.get("GITHUB_ACTIONS")
        stdout_buf = io.StringIO()
        old_stdout = sys.stdout
        try:
            updater._build_opener = lambda: opener  # type: ignore[assignment]
            os.environ["GITHUB_ACTIONS"] = "true"
            sys.stdout = stdout_buf
            rc = updater.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--work-dir",
                    str(self.work_dir),
                    "--release-json",
                    str(release_json),
                    "--dry-run",
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            sys.stdout = old_stdout
            if orig_gha is None:
                os.environ.pop("GITHUB_ACTIONS", None)
            else:
                os.environ["GITHUB_ACTIONS"] = orig_gha
        self.assertEqual(rc, 0)
        self.assertIn(
            "::warning::Asset libznn-darwin-universal.tar.gz verified via "
            "GitHub release digest (not listed in SHA256CHECKSUMS.txt).",
            stdout_buf.getvalue(),
        )
        # Ensure per-run scratch directories were cleaned up inside work_dir.
        self.assertEqual(list(self.work_dir.glob("libznn-update-*")), [])

    def test_rollback_restores_existing_and_removes_new_blobs_on_mid_replace_failure(self) -> None:
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        # Remove libznn.dylib beforehand to verify newly created blobs are also removed on rollback.
        (blobs / "libznn.dylib").unlink()

        new_linux = b"\x7fELF-rollback-linux"
        new_darwin = b"\xca\xfe\xba\xbe-rollback-darwin"
        new_windows = b"MZ-rollback-windows"
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=new_linux,
            darwin_bin=new_darwin,
            windows_bin=new_windows,
        )

        orig_replace = os.replace
        forward_replaces: list[str] = []
        observed_dylib_before_failure: bytes | None = None

        def fail_on_third_replace(src: Any, dst: Any) -> None:
            nonlocal observed_dylib_before_failure
            dst_path = pathlib.Path(dst)
            if dst_path.name == "libznn.dll":
                observed_dylib_before_failure = (blobs / "libznn.dylib").read_bytes()
                raise PermissionError("simulated failure replacing third blob")
            if pathlib.Path(src).name.endswith(".tmp"):
                forward_replaces.append(dst_path.name)
            orig_replace(src, dst)

        try:
            os.replace = fail_on_third_replace  # type: ignore[assignment]
            with self.assertRaisesRegex(updater.UpdaterError, "Failed staging embedded binaries"):
                updater.run_update(
                    repo_root=self.repo_root,
                    work_dir=self.work_dir,
                    tag="v0.0.11-alphanet",
                    opener=opener,  # type: ignore[arg-type]
                )
        finally:
            os.replace = orig_replace

        # Both forward installs ran (including the newly created libznn.dylib) before rollback.
        self.assertEqual(forward_replaces, ["libznn.so", "libznn.dylib"])
        self.assertEqual(observed_dylib_before_failure, new_darwin)
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)
        self.assertFalse((blobs / "libznn.dylib").exists())
        self.assertEqual((blobs / "libznn.dll").read_bytes(), self.old_windows)
        self.assertEqual(list(blobs.glob(".*.tmp")), [])
        self.assertEqual(list(blobs.glob(".*.bak")), [])

    def test_rollback_handles_keyboard_interrupt_retains_unrestored_backup_and_rejects_blob_output_paths(
        self,
    ) -> None:
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        new_linux = b"\x7fELF-int-linux"
        new_darwin = b"\xca\xfe\xba\xbe-int-darwin"
        new_windows = b"MZ-int-windows"
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=new_linux,
            darwin_bin=new_darwin,
            windows_bin=new_windows,
        )

        # 1. Output path aliasing a repository blob is rejected even in dry-run mode.
        blob_symlink = self.root / "alias_to_so"
        blob_symlink.symlink_to(blobs / "libznn.so")
        with self.assertRaisesRegex(updater.UpdaterError, "must not refer to repository blob"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                pr_body_out=blob_symlink,
                dry_run=True,
                opener=opener,  # type: ignore[arg-type]
            )
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)

        # 2. KeyboardInterrupt mid-replacement rolls back already-installed blobs and re-raises.
        orig_replace = os.replace

        def interrupt_on_second_replace(src: Any, dst: Any) -> None:
            if pathlib.Path(dst).name == "libznn.dylib":
                raise KeyboardInterrupt("simulated Ctrl+C")
            orig_replace(src, dst)

        try:
            os.replace = interrupt_on_second_replace  # type: ignore[assignment]
            with self.assertRaises(KeyboardInterrupt):
                updater.run_update(
                    repo_root=self.repo_root,
                    work_dir=self.work_dir,
                    tag="v0.0.11-alphanet",
                    opener=opener,  # type: ignore[arg-type]
                )
        finally:
            os.replace = orig_replace
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)
        self.assertEqual(list(blobs.glob(".*.bak")), [])

        # 3. If restoring a backup fails during rollback, the backup file is retained for recovery.
        orig_write_outputs = updater.write_github_outputs

        def fail_write_outputs(path: pathlib.Path, outputs: Any) -> None:
            raise OSError("simulated output write error")

        def fail_restore_linux(src: Any, dst: Any) -> None:
            if pathlib.Path(src).name.endswith(".bak") and pathlib.Path(dst).name == "libznn.so":
                raise PermissionError("simulated restore failure")
            orig_replace(src, dst)

        stderr_buf = io.StringIO()
        old_stderr = sys.stderr
        try:
            updater.write_github_outputs = fail_write_outputs  # type: ignore[assignment]
            os.replace = fail_restore_linux  # type: ignore[assignment]
            sys.stderr = stderr_buf
            with self.assertRaisesRegex(updater.UpdaterError, "Failed writing updater output"):
                updater.run_update(
                    repo_root=self.repo_root,
                    work_dir=self.work_dir,
                    tag="v0.0.11-alphanet",
                    github_output=self.root / "gh_out.txt",
                    opener=opener,  # type: ignore[arg-type]
                )
        finally:
            updater.write_github_outputs = orig_write_outputs
            os.replace = orig_replace
            sys.stderr = old_stderr

        retained = list(blobs.glob(".libznn.so.*.bak"))
        self.assertEqual(len(retained), 1)
        self.assertEqual(retained[0].read_bytes(), self.old_linux)
        self.assertIn("retaining backup", stderr_buf.getvalue())
        # Restore manually for clean teardown.
        os.replace(retained[0], blobs / "libznn.so")
        self.assertEqual((blobs / "libznn.dylib").read_bytes(), self.old_darwin)
        self.assertEqual((blobs / "libznn.dll").read_bytes(), self.old_windows)

    def test_failed_output_write_does_not_hide_changes_on_retry(self) -> None:
        new_linux = b"\x7fELF-output-retry"
        new_darwin = b"\xca\xfe\xba\xbe-output-retry"
        new_windows = b"MZ-output-retry"
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=new_linux,
            darwin_bin=new_darwin,
            windows_bin=new_windows,
        )
        bad_output_dir = self.root / "output_is_a_dir"
        bad_output_dir.mkdir()

        # 1. Passing a directory as --github-output fails before replacing blobs.
        with self.assertRaisesRegex(updater.UpdaterError, "is a directory"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                github_output=bad_output_dir,
                opener=opener,  # type: ignore[arg-type]
            )
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)

        # 2. A post-replace output write error rolls back all replaced blobs.
        orig_write_outputs = updater.write_github_outputs

        def fail_write_outputs(path: pathlib.Path, outputs: Any) -> None:
            raise OSError("disk full writing GITHUB_OUTPUT")

        good_output = self.root / "github_output.txt"
        step_summary = self.root / "step_summary.md"
        step_summary.write_text("# Existing summary\n", encoding="utf-8")
        try:
            updater.write_github_outputs = fail_write_outputs  # type: ignore[assignment]
            with self.assertRaisesRegex(updater.UpdaterError, "Failed writing updater output"):
                updater.run_update(
                    repo_root=self.repo_root,
                    work_dir=self.work_dir,
                    tag="v0.0.11-alphanet",
                    github_output=good_output,
                    step_summary=step_summary,
                    opener=opener,  # type: ignore[arg-type]
                )
        finally:
            updater.write_github_outputs = orig_write_outputs

        # Step summary was not appended with a false success report on rollback.
        self.assertEqual(step_summary.read_text(encoding="utf-8"), "# Existing summary\n")
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)
        self.assertEqual((blobs / "libznn.dylib").read_bytes(), self.old_darwin)
        self.assertEqual((blobs / "libznn.dll").read_bytes(), self.old_windows)
        self.assertEqual(list(blobs.glob(".*.bak")), [])

        # 3. Retrying with valid output path still reports changed=true, stages blobs, and writes summary.
        _, _, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.11-alphanet",
            github_output=good_output,
            step_summary=step_summary,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertTrue(changed)
        self.assertIn("changed=true\n", good_output.read_text(encoding="utf-8"))
        self.assertIn("Updated embedded `libznn` binaries staged", step_summary.read_text(encoding="utf-8"))
        self.assertEqual((blobs / "libznn.so").read_bytes(), new_linux)

    def test_prerelease_requires_explicit_tag_and_surfaces_warning_in_outputs(self) -> None:
        new_linux = b"\x7fELF-prerelease"
        new_darwin = b"\xca\xfe\xba\xbe-prerelease"
        new_windows = b"MZ-prerelease"
        opener, _ = self._build_mock_release(
            tag="v0.0.11-rc1",
            linux_bin=new_linux,
            darwin_bin=new_darwin,
            windows_bin=new_windows,
            include_darwin_in_checksums=True,
            prerelease=True,
        )
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"

        # 1. Pre-release is refused when no explicit --tag was requested.
        with self.assertRaisesRegex(updater.UpdaterError, "pre-release"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="",
                opener=opener,  # type: ignore[arg-type]
            )
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)

        # 2. Explicitly requested pre-release tag succeeds and clearly flags PR title, body,
        # commit message, step summary, and GitHub Actions warning output.
        release_json = self.root / "prerelease.json"
        release_json.write_bytes(
            opener.responses[
                "https://api.github.com/repos/zenon-network/go-zenon/releases/tags/v0.0.11-rc1"
            ]
        )
        pr_body_path = self.root / "prerelease_pr_body.md"
        gh_output = self.root / "prerelease_gh_output.txt"
        step_summary = self.root / "prerelease_summary.md"

        orig_build_opener = updater._build_opener
        orig_gha = os.environ.get("GITHUB_ACTIONS")
        stdout_buf = io.StringIO()
        old_stdout = sys.stdout
        try:
            updater._build_opener = lambda: opener  # type: ignore[assignment]
            os.environ["GITHUB_ACTIONS"] = "true"
            sys.stdout = stdout_buf
            rc = updater.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--work-dir",
                    str(self.work_dir),
                    "--tag=v0.0.11-rc1",
                    "--release-json",
                    str(release_json),
                    "--pr-body-out",
                    str(pr_body_path),
                    "--github-output",
                    str(gh_output),
                    "--step-summary",
                    str(step_summary),
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            sys.stdout = old_stdout
            if orig_gha is None:
                os.environ.pop("GITHUB_ACTIONS", None)
            else:
                os.environ["GITHUB_ACTIONS"] = orig_gha

        self.assertEqual(rc, 0)
        self.assertIn(
            "::warning::Upstream release v0.0.11-rc1 is marked as a pre-release.",
            stdout_buf.getvalue(),
        )
        pr_body = pr_body_path.read_text(encoding="utf-8")
        self.assertIn("> [!WARNING]", pr_body)
        self.assertIn("marked as a **pre-release**", pr_body)
        self.assertIn("- **Release type:** `pre-release`", pr_body)

        gh_out_text = gh_output.read_text(encoding="utf-8")
        self.assertIn(
            "pr_title=chore: update embedded libznn to go-zenon v0.0.11-rc1 (prerelease)\n",
            gh_out_text,
        )
        self.assertIn("Release type: pre-release\n", gh_out_text)

        summary_text = step_summary.read_text(encoding="utf-8")
        self.assertIn("`v0.0.11-rc1` — pre-release", summary_text)
        self.assertIn("marked as a **pre-release**", summary_text)

    def test_unchanged_blobs_sets_changed_false(self) -> None:
        opener, _ = self._build_mock_release(
            tag="v0.0.10-alphanet",
            linux_bin=self.old_linux,
            darwin_bin=self.old_darwin,
            windows_bin=self.old_windows,
            include_darwin_in_checksums=True,
        )
        # First run seeds the missing provenance manifest even though binaries match.
        _, _, first_changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.10-alphanet",
            target_branch="master",
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertTrue(first_changed)
        self.assertTrue((self.repo_root / updater.MANIFEST_RELPATH).is_file())

        # Second run with matching blobs AND matching manifest reports no changes.
        gh_output = self.work_dir / "github_output.txt"
        _, _, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.10-alphanet",
            target_branch="master",
            github_output=gh_output,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertFalse(changed)
        gh_out_text = gh_output.read_text(encoding="utf-8")
        self.assertIn("changed=false\n", gh_out_text)
        self.assertIn("updates_detected=false\n", gh_out_text)

    def test_rejects_colliding_output_paths_and_manifest_alias(self) -> None:
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-collide",
            darwin_bin=b"\xca\xfe\xba\xbe-collide",
            windows_bin=b"MZ-collide",
        )
        shared_out = self.work_dir / "shared.out"
        with self.assertRaisesRegex(updater.UpdaterError, "must not refer to the same file"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                pr_body_out=shared_out,
                github_output=shared_out,
                opener=opener,  # type: ignore[arg-type]
            )
        # Fails fast before making any network requests.
        self.assertEqual(opener.requests, [])

        # Symlink alias between --pr-body-out and --step-summary is rejected.
        target_file = self.work_dir / "real_out.txt"
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_text("", encoding="utf-8")
        sym_file = self.work_dir / "sym_out.txt"
        sym_file.symlink_to(target_file)
        with self.assertRaisesRegex(updater.UpdaterError, "must not refer to the same file"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                pr_body_out=target_file,
                step_summary=sym_file,
                opener=opener,  # type: ignore[arg-type]
            )

        # Hardlink alias between --github-output and --step-summary is rejected.
        hard_file = self.work_dir / "hard_out.txt"
        os.link(target_file, hard_file)
        with self.assertRaisesRegex(updater.UpdaterError, "must not refer to the same file"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                github_output=target_file,
                step_summary=hard_file,
                opener=opener,  # type: ignore[arg-type]
            )

        # Output path aliasing libznn.manifest.json is rejected.
        manifest_path = self.repo_root / updater.MANIFEST_RELPATH
        with self.assertRaisesRegex(updater.UpdaterError, "repository provenance manifest"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                pr_body_out=manifest_path,
                opener=opener,  # type: ignore[arg-type]
            )

    def test_semver_comparison_and_tag_commit_dereferencing(self) -> None:
        self.assertEqual(updater.compare_release_tags("v0.0.9-alphanet", "v0.0.10-alphanet"), -1)
        self.assertEqual(updater.compare_release_tags("v0.0.10-alphanet", "v0.0.9-alphanet"), 1)
        self.assertEqual(updater.compare_release_tags("v0.0.10-alphanet", "v0.0.10"), -1)
        self.assertEqual(updater.compare_release_tags("v0.0.10-rc.2", "v0.0.10-rc.10"), -1)
        self.assertEqual(updater.compare_release_tags("v1.0.0+build.1", "v1.0.0+build.2"), 0)
        self.assertEqual(updater.compare_release_tags("v1.2.3-rc.0", "v1.2.3-rc.1"), -1)
        self.assertEqual(updater.compare_release_tags("v1.2.3-01a", "v1.2.3-01b"), -1)
        # Zero-padded numeric prerelease identifiers are invalid per SemVer 2.0.0 §9.
        self.assertIsNone(updater.parse_semver_tag("v1.2.3-rc.01"))
        self.assertIsNone(updater.compare_release_tags("v1.2.3-rc.01", "v1.2.3-rc.1"))
        self.assertIsNone(updater.compare_release_tags("v1.2.3-rc.1", "v1.2.3-rc.01"))
        self.assertIsNone(updater.compare_release_tags("nightly-2026", "v0.0.10-alphanet"))

        commit_sha = "1" * 40
        tag_obj_sha = "2" * 40
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-ann",
            darwin_bin=b"\xca\xfe\xba\xbe-ann",
            windows_bin=b"MZ-ann",
            tag_commit=commit_sha,
            annotated_tag_sha=tag_obj_sha,
        )
        resolved = updater.fetch_tag_commit(
            "zenon-network/go-zenon",
            "v0.0.11-alphanet",
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertEqual(resolved, commit_sha)

        # Prefix list response from git/ref/tags/<tag> is rejected cleanly.
        list_opener = _FakeOpener(
            {
                "https://api.github.com/repos/zenon-network/go-zenon/git/ref/tags/v0.0.11": json.dumps(
                    [{"ref": "refs/tags/v0.0.11-alphanet", "object": {"sha": commit_sha, "type": "commit"}}]
                ).encode("utf-8")
            }
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Unexpected GitHub Git Ref API response"):
            updater.fetch_tag_commit(
                "zenon-network/go-zenon",
                "v0.0.11",
                opener=list_opener,  # type: ignore[arg-type]
            )

        # Circular annotated tag object is rejected cleanly.
        cycle_opener = _FakeOpener(
            {
                "https://api.github.com/repos/zenon-network/go-zenon/git/ref/tags/v0.0.11": json.dumps(
                    {"ref": "refs/tags/v0.0.11", "object": {"sha": tag_obj_sha, "type": "tag"}}
                ).encode("utf-8"),
                f"https://api.github.com/repos/zenon-network/go-zenon/git/tags/{tag_obj_sha}": json.dumps(
                    {"sha": tag_obj_sha, "object": {"sha": tag_obj_sha, "type": "tag"}}
                ).encode("utf-8"),
            }
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Circular annotated tag"):
            updater.fetch_tag_commit(
                "zenon-network/go-zenon",
                "v0.0.11",
                opener=cycle_opener,  # type: ignore[arg-type]
            )

    def test_provenance_metadata_late_asset_warning_and_commitish_mismatch(self) -> None:
        tag_commit = "b" * 40
        other_commit = "c" * 40
        opener, hashes = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-prov",
            darwin_bin=b"\xca\xfe\xba\xbe-prov",
            windows_bin=b"MZ-prov",
            immutable=False,
            published_at="2026-11-20T12:00:00Z",
            asset_updated_at="2026-11-20T12:05:00Z",
            target_commitish=other_commit,
            tag_commit=tag_commit,
        )
        pr_body_path = self.work_dir / "prov-pr-body.md"
        gh_output = self.work_dir / "prov-gh-output.txt"
        summary_path = self.work_dir / "prov-summary.md"

        orig_build_opener = updater._build_opener
        orig_gha = os.environ.get("GITHUB_ACTIONS")
        stdout_buf = io.StringIO()
        old_stdout = sys.stdout
        try:
            updater._build_opener = lambda: opener  # type: ignore[assignment]
            os.environ["GITHUB_ACTIONS"] = "true"
            sys.stdout = stdout_buf
            rc = updater.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--work-dir",
                    str(self.work_dir),
                    "--tag=v0.0.11-alphanet",
                    "--pr-body-out",
                    str(pr_body_path),
                    "--github-output",
                    str(gh_output),
                    "--step-summary",
                    str(summary_path),
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            sys.stdout = old_stdout
            if orig_gha is None:
                os.environ.pop("GITHUB_ACTIONS", None)
            else:
                os.environ["GITHUB_ACTIONS"] = orig_gha

        self.assertEqual(rc, 0)
        pr_body = pr_body_path.read_text(encoding="utf-8")
        summary_text = summary_path.read_text(encoding="utf-8")
        gh_out_text = gh_output.read_text(encoding="utf-8")
        stdout_text = stdout_buf.getvalue()

        # Release commit, immutability, and asset updated_at appear in PR body & commit message.
        self.assertIn(tag_commit, pr_body)
        self.assertIn(other_commit, pr_body)
        self.assertIn("`false` (mutable release)", pr_body)
        self.assertIn("2026-11-20T12:05:00Z", pr_body)
        self.assertIn("updated_at` later than release", pr_body)
        self.assertIn(f"Tag commit: {tag_commit}", gh_out_text)
        self.assertIn("Release immutable: false", gh_out_text)
        self.assertIn("updated_at: 2026-11-20T12:05:00Z", gh_out_text)

        # Step summary & GitHub Actions annotations warn on late asset updates & commitish mismatch.
        self.assertIn("Assets updated after release `published_at`", summary_text)
        self.assertIn("::warning::Release asset libznn-linux-amd64.tar.gz was updated at 2026-11-20T12:05:00Z", stdout_text)
        self.assertIn("::warning::Release target_commitish", stdout_text)

        # Manifest written and valid.
        manifest = updater.load_provenance_manifest(self.repo_root)
        assert manifest is not None
        self.assertEqual(manifest["release"]["tag"], "v0.0.11-alphanet")
        self.assertEqual(manifest["release"]["tag_commit"], tag_commit)
        self.assertEqual(manifest["release"]["immutable"], False)
        self.assertEqual(
            manifest["blobs"]["lib/embedded_node/blobs/libznn.so"]["archive_sha256"],
            hashes["linux_arc"],
        )

    def test_detects_same_tag_rebuild_and_refuses_downgrade_unless_forced(self) -> None:
        # Step 1: Establish committed manifest at v0.0.10-alphanet.
        opener_v10, _ = self._build_mock_release(
            tag="v0.0.10-alphanet",
            linux_bin=self.old_linux,
            darwin_bin=self.old_darwin,
            windows_bin=self.old_windows,
            include_darwin_in_checksums=True,
            tag_commit="1" * 40,
        )
        updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.10-alphanet",
            opener=opener_v10,  # type: ignore[arg-type]
        )

        # Step 2: Downgrade to v0.0.9-alphanet is refused by default.
        opener_v9, _ = self._build_mock_release(
            tag="v0.0.9-alphanet",
            linux_bin=b"\x7fELF-v9",
            darwin_bin=b"\xca\xfe\xba\xbe-v9",
            windows_bin=b"MZ-v9",
            include_darwin_in_checksums=True,
            published_at="2026-11-10T12:00:00Z",
            asset_updated_at="2026-11-10T12:00:00Z",
            tag_commit="9" * 40,
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Refusing to downgrade"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.9-alphanet",
                opener=opener_v9,  # type: ignore[arg-type]
            )
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)

        # Step 3: Same-tag rebuild on v0.0.10-alphanet (different binaries) is detected and flagged.
        rebuilt_linux = b"\x7fELF-rebuilt-v10"
        opener_rebuild, _ = self._build_mock_release(
            tag="v0.0.10-alphanet",
            linux_bin=rebuilt_linux,
            darwin_bin=self.old_darwin,
            windows_bin=self.old_windows,
            include_darwin_in_checksums=True,
            tag_commit="2" * 40,
        )
        rebuild_pr_body = self.work_dir / "rebuild-pr-body.md"
        rebuild_gh_out = self.work_dir / "rebuild-gh-out.txt"
        rebuild_summary = self.work_dir / "rebuild-summary.md"
        _, _, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.10-alphanet",
            pr_body_out=rebuild_pr_body,
            github_output=rebuild_gh_out,
            step_summary=rebuild_summary,
            opener=opener_rebuild,  # type: ignore[arg-type]
        )
        self.assertTrue(changed)
        self.assertIn("same_tag_rebuild=true\n", rebuild_gh_out.read_text(encoding="utf-8"))
        self.assertIn("(same-tag rebuild)", rebuild_gh_out.read_text(encoding="utf-8"))
        self.assertIn("Same-tag rebuild detected", rebuild_pr_body.read_text(encoding="utf-8"))
        self.assertIn("Same-tag rebuild detected", rebuild_summary.read_text(encoding="utf-8"))
        self.assertEqual((blobs / "libznn.so").read_bytes(), rebuilt_linux)

        # Step 4: Forced downgrade with allow_downgrade=True succeeds and emits downgrade warnings.
        dg_pr_body = self.work_dir / "dg-pr-body.md"
        dg_gh_out = self.work_dir / "dg-gh-out.txt"
        dg_summary = self.work_dir / "dg-summary.md"
        _, _, dg_changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.9-alphanet",
            allow_downgrade=True,
            pr_body_out=dg_pr_body,
            github_output=dg_gh_out,
            step_summary=dg_summary,
            opener=opener_v9,  # type: ignore[arg-type]
        )
        self.assertTrue(dg_changed)
        self.assertIn("downgrade=true\n", dg_gh_out.read_text(encoding="utf-8"))
        self.assertIn("(downgrade)", dg_gh_out.read_text(encoding="utf-8"))
        self.assertIn("Forced downgrade", dg_pr_body.read_text(encoding="utf-8"))
        self.assertIn("Forced downgrade", dg_summary.read_text(encoding="utf-8"))
        self.assertEqual((blobs / "libznn.so").read_bytes(), b"\x7fELF-v9")

    def test_fetch_metadata_only_embeds_resolved_tag_commit_for_release_json_mode(self) -> None:
        tag_commit = "d" * 40
        opener, _ = self._build_mock_release(
            tag="v0.0.12-alphanet",
            linux_bin=b"\x7fELF-meta",
            darwin_bin=b"\xca\xfe\xba\xbe-meta",
            windows_bin=b"MZ-meta",
            target_commitish="master",
            tag_commit=tag_commit,
        )
        meta_out = self.work_dir / "fetched_release.json"
        orig_build_opener = updater._build_opener
        try:
            updater._build_opener = lambda: opener  # type: ignore[assignment]
            rc = updater.main(
                [
                    "--fetch-metadata-only",
                    "--tag=v0.0.12-alphanet",
                    "--metadata-out",
                    str(meta_out),
                ]
            )
        finally:
            updater._build_opener = orig_build_opener

        self.assertEqual(rc, 0)
        saved = json.loads(meta_out.read_text(encoding="utf-8"))
        self.assertEqual(saved["_resolved_tag_commit"], tag_commit)

        # Now run update in --release-json mode without any API URLs available in opener.
        dl_only_responses = {
            k: v for k, v in opener.responses.items() if not k.startswith("https://api.github.com/")
        }
        dl_opener = _FakeOpener(dl_only_responses)
        release, _, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.12-alphanet",
            release_json=meta_out,
            opener=dl_opener,  # type: ignore[arg-type]
        )
        self.assertTrue(changed)
        self.assertEqual(release.tag_commit, tag_commit)
        self.assertEqual(release.target_commitish, "master")
        self.assertTrue(
            all(not req.full_url.startswith("https://api.github.com/") for req in dl_opener.requests)
        )

    def test_rollback_restores_manifest_on_post_stage_failure(self) -> None:
        opener_v10, _ = self._build_mock_release(
            tag="v0.0.10-alphanet",
            linux_bin=self.old_linux,
            darwin_bin=self.old_darwin,
            windows_bin=self.old_windows,
            include_darwin_in_checksums=True,
            tag_commit="1" * 40,
        )
        updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.10-alphanet",
            opener=opener_v10,  # type: ignore[arg-type]
        )
        manifest_path = self.repo_root / updater.MANIFEST_RELPATH
        original_manifest_text = manifest_path.read_text(encoding="utf-8")

        opener_v11, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-v11-rb",
            darwin_bin=b"\xca\xfe\xba\xbe-v11-rb",
            windows_bin=b"MZ-v11-rb",
            tag_commit="2" * 40,
        )
        orig_write_outputs = updater.write_github_outputs

        def fail_outputs(path: pathlib.Path, outputs: Any) -> None:
            raise OSError("simulated disk full")

        try:
            updater.write_github_outputs = fail_outputs  # type: ignore[assignment]
            with self.assertRaisesRegex(updater.UpdaterError, "Failed writing updater output"):
                updater.run_update(
                    repo_root=self.repo_root,
                    work_dir=self.work_dir,
                    tag="v0.0.11-alphanet",
                    github_output=self.work_dir / "gh.out",
                    opener=opener_v11,  # type: ignore[arg-type]
                )
        finally:
            updater.write_github_outputs = orig_write_outputs

        self.assertEqual(manifest_path.read_text(encoding="utf-8"), original_manifest_text)
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)
        self.assertEqual(list(blobs.glob(".*.bak")), [])
        self.assertEqual(list(blobs.glob(".*.tmp")), [])

    def test_release_json_without_resolved_commit_does_not_copy_target_commitish_or_erase_recorded_commit(
        self,
    ) -> None:
        # 1. Raw --release-json (no _resolved_tag_commit) leaves tag_commit=None instead of copying target_commitish.
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-raw-json",
            darwin_bin=b"\xca\xfe\xba\xbe-raw-json",
            windows_bin=b"MZ-raw-json",
            target_commitish="e" * 40,
            tag_commit="f" * 40,
        )
        raw_release_path = self.root / "raw_release_no_commit.json"
        raw_release_path.write_bytes(
            opener.responses[
                "https://api.github.com/repos/zenon-network/go-zenon/releases/tags/v0.0.11-alphanet"
            ]
        )
        dl_only = _FakeOpener(
            {k: v for k, v in opener.responses.items() if not k.startswith("https://api.github.com/")}
        )
        release, _, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.11-alphanet",
            release_json=raw_release_path,
            dry_run=True,
            opener=dl_only,  # type: ignore[arg-type]
        )
        self.assertTrue(changed)
        self.assertIsNone(release.tag_commit)
        self.assertEqual(release.target_commitish, "e" * 40)

        # 2. If repo manifest already records tag_commit for v0.0.11-alphanet, unresolved --release-json is refused.
        updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.11-alphanet",
            opener=opener,  # type: ignore[arg-type]
        )
        with self.assertRaisesRegex(updater.UpdaterError, "Refusing to overwrite recorded tag_commit"):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                release_json=raw_release_path,
                opener=dl_only,  # type: ignore[arg-type]
            )

    def test_fetch_metadata_only_protects_manifest_and_blobs_when_repo_root_given(self) -> None:
        manifest_path = self.repo_root / updater.MANIFEST_RELPATH
        blob_path = self.repo_root / "lib" / "embedded_node" / "blobs" / "libznn.so"
        for protected in (manifest_path, blob_path):
            with self.subTest(protected=protected.name):
                stderr_buf = io.StringIO()
                old_stderr = sys.stderr
                try:
                    sys.stderr = stderr_buf
                    rc = updater.main(
                        [
                            "--fetch-metadata-only",
                            "--repo-root",
                            str(self.repo_root),
                            "--metadata-out",
                            str(protected),
                        ]
                    )
                finally:
                    sys.stderr = old_stderr
                self.assertEqual(rc, 1)
                self.assertIn("must not refer to repository", stderr_buf.getvalue())

    def test_local_cli_emits_provenance_warnings_to_stderr_outside_github_actions(self) -> None:
        # Seed manifest at v0.0.10-alphanet.
        opener_v10, _ = self._build_mock_release(
            tag="v0.0.10-alphanet",
            linux_bin=self.old_linux,
            darwin_bin=self.old_darwin,
            windows_bin=self.old_windows,
            include_darwin_in_checksums=True,
            tag_commit="1" * 40,
        )
        updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            tag="v0.0.10-alphanet",
            opener=opener_v10,  # type: ignore[arg-type]
        )

        # Trigger same-tag rebuild + late-updated asset in local CLI (GITHUB_ACTIONS unset).
        opener_local, _ = self._build_mock_release(
            tag="v0.0.10-alphanet",
            linux_bin=b"\x7fELF-local-rebuild",
            darwin_bin=self.old_darwin,
            windows_bin=self.old_windows,
            include_darwin_in_checksums=False,
            published_at="2026-11-20T12:00:00Z",
            asset_updated_at="2026-11-20T12:05:00Z",
            tag_commit="2" * 40,
        )
        orig_build_opener = updater._build_opener
        orig_gha = os.environ.pop("GITHUB_ACTIONS", None)
        stdout_buf = io.StringIO()
        stderr_buf = io.StringIO()
        old_stdout, old_stderr = sys.stdout, sys.stderr
        try:
            updater._build_opener = lambda: opener_local  # type: ignore[assignment]
            sys.stdout = stdout_buf
            sys.stderr = stderr_buf
            rc = updater.main(
                [
                    "--repo-root",
                    str(self.repo_root),
                    "--work-dir",
                    str(self.work_dir),
                    "--tag=v0.0.10-alphanet",
                    "--dry-run",
                ]
            )
        finally:
            updater._build_opener = orig_build_opener
            sys.stdout = old_stdout
            sys.stderr = old_stderr
            if orig_gha is not None:
                os.environ["GITHUB_ACTIONS"] = orig_gha

        self.assertEqual(rc, 0)
        stderr_text = stderr_buf.getvalue()
        self.assertIn("WARNING: Same-tag rebuild detected", stderr_text)
        self.assertIn("WARNING: Release asset libznn-linux-amd64.tar.gz was updated at", stderr_text)
        self.assertNotIn("::warning::", stdout_buf.getvalue())

    def test_failure_on_third_asset_leaves_all_blobs_untouched(self) -> None:
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-new",
            darwin_bin=b"\xca\xfe\xba\xbe-new",
            windows_bin=b"MZ-new",
            corrupt_windows_digest=True,
        )
        with self.assertRaises(updater.UpdaterError):
            updater.run_update(
                repo_root=self.repo_root,
                work_dir=self.work_dir,
                tag="v0.0.11-alphanet",
                opener=opener,  # type: ignore[arg-type]
            )
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)
        self.assertEqual((blobs / "libznn.dylib").read_bytes(), self.old_darwin)
        self.assertEqual((blobs / "libznn.dll").read_bytes(), self.old_windows)

    def test_dry_run_does_not_modify_blobs(self) -> None:
        opener, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-dry-run",
            darwin_bin=b"\xca\xfe\xba\xbe-dry-run",
            windows_bin=b"MZ-dry-run",
        )
        gh_output = self.work_dir / "github_output.txt"
        _, _, changed = updater.run_update(
            repo_root=self.repo_root,
            work_dir=self.work_dir,
            dry_run=True,
            github_output=gh_output,
            opener=opener,  # type: ignore[arg-type]
        )
        self.assertTrue(changed)
        self.assertIn("changed=false\n", gh_output.read_text(encoding="utf-8"))
        blobs = self.repo_root / "lib" / "embedded_node" / "blobs"
        self.assertEqual((blobs / "libznn.so").read_bytes(), self.old_linux)


if __name__ == "__main__":
    unittest.main()
