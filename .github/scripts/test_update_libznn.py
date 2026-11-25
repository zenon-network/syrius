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

        base_dl = f"https://github.com/zenon-network/go-zenon/releases/download/{tag}"
        payload = {
            "tag_name": tag,
            "name": tag,
            "draft": False,
            "prerelease": False,
            "published_at": "2026-11-20T12:00:00Z",
            "html_url": f"https://github.com/zenon-network/go-zenon/releases/tag/{tag}",
            "assets": [
                {
                    "name": "libznn-linux-amd64.tar.gz",
                    "browser_download_url": f"{base_dl}/libznn-linux-amd64.tar.gz",
                    "digest": f"sha256:{linux_sha}",
                },
                {
                    "name": "libznn-darwin-universal.tar.gz",
                    "browser_download_url": f"{base_dl}/libznn-darwin-universal.tar.gz",
                    "digest": f"sha256:{darwin_sha}",
                },
                {
                    "name": "libznn-windows-amd64.zip",
                    "browser_download_url": f"{base_dl}/libznn-windows-amd64.zip",
                    "digest": f"sha256:{'0' * 64 if corrupt_windows_digest else win_sha}",
                },
                {
                    "name": "SHA256CHECKSUMS.txt",
                    "browser_download_url": f"{base_dl}/SHA256CHECKSUMS.txt",
                    "digest": f"sha256:{checksums_sha}",
                },
            ],
        }

        responses = {
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
        return _FakeOpener(responses), {
            "linux_arc": linux_sha,
            "darwin_arc": darwin_sha,
            "win_arc": win_sha,
            "checksums": checksums_sha,
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
        self.assertIn("GITHUB_TOKEN", pr_body)

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
        base_payload = json.loads(
            self._build_mock_release(
                tag="v0.0.11-alphanet",
                linux_bin=b"\x7fELF-1",
                darwin_bin=b"\xca\xfe\xba\xbe-1",
                windows_bin=b"MZ-1",
            )[0]
            .responses[
                "https://api.github.com/repos/zenon-network/go-zenon/releases/tags/v0.0.11-alphanet"
            ]
            .decode("utf-8")
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

        # 4. Missing required asset
        missing_asset_payload = dict(
            base_payload,
            assets=[
                a for a in base_payload["assets"] if a["name"] != "libznn-windows-amd64.zip"
            ],
        )
        opener_full, _ = self._build_mock_release(
            tag="v0.0.11-alphanet",
            linux_bin=b"\x7fELF-1",
            darwin_bin=b"\xca\xfe\xba\xbe-1",
            windows_bin=b"MZ-1",
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
        with self.assertRaisesRegex(updater.UpdaterError, "SHA256CHECKSUMS.txt"):
            run_with_payload(bad_csum_payload, extra_responses=opener_full.responses)

    def test_download_retries_on_connection_reset_and_bounds_attempts(self) -> None:
        url = "https://github.com/zenon-network/go-zenon/releases/download/v0.0.11-alphanet/libznn-linux-amd64.tar.gz"

        class _FlakyStream:
            def __init__(self, fail: bool, data: bytes) -> None:
                self._fail = fail
                self._stream = io.BytesIO(data)

            def read(self, size: int = -1) -> bytes:
                if self._fail:
                    raise ConnectionResetError("connection reset by peer")
                return self._stream.read(size)

            def __enter__(self) -> _FlakyStream:
                return self

            def __exit__(self, *args: Any) -> None:
                self._stream.close()

        class _FlakyOpener:
            def __init__(self, fail_times: int, data: bytes) -> None:
                self.calls = 0
                self.fail_times = fail_times
                self.data = data

            def open(self, req: urllib.request.Request, timeout: int = 60) -> _FlakyStream:
                self.calls += 1
                return _FlakyStream(self.calls <= self.fail_times, self.data)

        dest = self.root / "flaky.tar.gz"
        payload = b"recovered-payload"
        flaky_ok = _FlakyOpener(fail_times=2, data=payload)
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

        flaky_fail = _FlakyOpener(fail_times=5, data=payload)
        with self.assertRaisesRegex(updater.UpdaterError, "Network error downloading"):
            updater.download_release_file(
                url,
                dest,
                upstream_repo="zenon-network/go-zenon",
                max_bytes=1024,
                opener=flaky_fail,  # type: ignore[arg-type]
                max_attempts=3,
                retry_backoff_seconds=0,
            )
        self.assertEqual(flaky_fail.calls, 3)
        self.assertFalse(dest.exists())

    def test_unchanged_blobs_sets_changed_false(self) -> None:
        opener, _ = self._build_mock_release(
            tag="v0.0.10-alphanet",
            linux_bin=self.old_linux,
            darwin_bin=self.old_darwin,
            windows_bin=self.old_windows,
            include_darwin_in_checksums=True,
        )
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
        self.assertIn("changed=false\n", gh_output.read_text(encoding="utf-8"))

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
