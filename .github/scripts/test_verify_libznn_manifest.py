#!/usr/bin/env python3
"""Unit tests for .github/scripts/verify_libznn_manifest.py."""

from __future__ import annotations

import hashlib
import io
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import update_libznn as updater
import verify_libznn_manifest as verifier


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _make_manifest(
    *,
    linux_bytes: bytes,
    darwin_bytes: bytes,
    windows_bytes: bytes,
    tag: str = "v0.0.10-alphanet",
) -> dict[str, object]:
    base_dl = f"https://github.com/zenon-network/go-zenon/releases/download/{tag}"
    return {
        "schema_version": 1,
        "upstream_repo": "zenon-network/go-zenon",
        "release": {
            "tag": tag,
            "name": tag,
            "html_url": f"https://github.com/zenon-network/go-zenon/releases/tag/{tag}",
            "published_at": "2026-11-17T00:49:47Z",
            "prerelease": False,
            "immutable": False,
            "target_commitish": "e" * 40,
            "tag_commit": "e" * 40,
            "checksums_asset": {
                "name": "SHA256CHECKSUMS.txt",
                "download_url": f"{base_dl}/SHA256CHECKSUMS.txt",
                "sha256": "a" * 64,
                "updated_at": "2026-11-17T00:49:58Z",
            },
        },
        "blobs": {
            "lib/embedded_node/blobs/libznn.so": {
                "platform": "Linux (amd64)",
                "asset_name": "libznn-linux-amd64.tar.gz",
                "download_url": f"{base_dl}/libznn-linux-amd64.tar.gz",
                "asset_updated_at": "2026-11-17T00:49:55Z",
                "archive_sha256": "1" * 64,
                "extracted_sha256": _sha256_bytes(linux_bytes),
            },
            "lib/embedded_node/blobs/libznn.dylib": {
                "platform": "macOS (universal)",
                "asset_name": "libznn-darwin-universal.tar.gz",
                "download_url": f"{base_dl}/libznn-darwin-universal.tar.gz",
                "asset_updated_at": "2026-11-17T00:50:17Z",
                "archive_sha256": "2" * 64,
                "extracted_sha256": _sha256_bytes(darwin_bytes),
            },
            "lib/embedded_node/blobs/libznn.dll": {
                "platform": "Windows (amd64)",
                "asset_name": "libznn-windows-amd64.zip",
                "download_url": f"{base_dl}/libznn-windows-amd64.zip",
                "asset_updated_at": "2026-11-17T00:49:53Z",
                "archive_sha256": "3" * 64,
                "extracted_sha256": _sha256_bytes(windows_bytes),
            },
        },
    }


class VerifyLibznnManifestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.repo_root = pathlib.Path(self.tmpdir.name) / "repo"
        self.blobs_dir = self.repo_root / "lib" / "embedded_node" / "blobs"
        self.blobs_dir.mkdir(parents=True)
        self.linux_bytes = b"\x7fELF-linux-blob"
        self.darwin_bytes = b"\xca\xfe\xba\xbe-darwin-blob"
        self.windows_bytes = b"MZ-windows-blob"
        (self.blobs_dir / "libznn.so").write_bytes(self.linux_bytes)
        (self.blobs_dir / "libznn.dylib").write_bytes(self.darwin_bytes)
        (self.blobs_dir / "libznn.dll").write_bytes(self.windows_bytes)
        self.manifest_path = self.repo_root / updater.MANIFEST_RELPATH
        self._write_manifest()

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _write_manifest(
        self,
        *,
        linux_bytes: bytes | None = None,
        darwin_bytes: bytes | None = None,
        windows_bytes: bytes | None = None,
        tag: str = "v0.0.10-alphanet",
    ) -> None:
        manifest = _make_manifest(
            linux_bytes=linux_bytes if linux_bytes is not None else self.linux_bytes,
            darwin_bytes=darwin_bytes if darwin_bytes is not None else self.darwin_bytes,
            windows_bytes=windows_bytes if windows_bytes is not None else self.windows_bytes,
            tag=tag,
        )
        self.manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    def test_valid_manifest_and_blobs_pass(self) -> None:
        manifest = verifier.verify_manifest_and_blobs(self.repo_root)
        self.assertEqual(manifest["schema_version"], 1)

    def test_rejects_missing_or_corrupted_manifest(self) -> None:
        self.manifest_path.unlink()
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "Missing required provenance manifest"):
            verifier.verify_manifest_and_blobs(self.repo_root)

        self.manifest_path.write_text("{not valid json", encoding="utf-8")
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "Failed to read provenance manifest"):
            verifier.verify_manifest_and_blobs(self.repo_root)

        self.manifest_path.write_text(json.dumps({"schema_version": 99}), encoding="utf-8")
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "schema_version"):
            verifier.verify_manifest_and_blobs(self.repo_root)

    def test_rejects_blob_hash_mismatch_missing_blob_symlink_and_unexpected_file(self) -> None:
        # Modified blob without updating manifest
        (self.blobs_dir / "libznn.so").write_bytes(b"\x7fELF-tampered")
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "SHA-256 mismatch"):
            verifier.verify_manifest_and_blobs(self.repo_root)
        (self.blobs_dir / "libznn.so").write_bytes(self.linux_bytes)

        # Unexpected stray file in blobs directory
        stray = self.blobs_dir / "libznn.extra"
        stray.write_bytes(b"stray")
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "Unexpected file"):
            verifier.verify_manifest_and_blobs(self.repo_root)
        stray.unlink()

        # .DS_Store is tolerated locally
        ds_store = self.blobs_dir / ".DS_Store"
        ds_store.write_bytes(b"ds")
        verifier.verify_manifest_and_blobs(self.repo_root)
        ds_store.unlink()

        # Symlink blob rejected
        target = self.repo_root / "outside.so"
        target.write_bytes(self.linux_bytes)
        (self.blobs_dir / "libznn.so").unlink()
        (self.blobs_dir / "libznn.so").symlink_to(target)
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "must not be a symlink"):
            verifier.verify_manifest_and_blobs(self.repo_root)

    def test_pr_diff_check_requires_manifest_update_when_blobs_change(self) -> None:
        # No blob changes -> passes
        verifier.verify_pr_diff_updates_manifest(["README.md", ".github/workflows/pr-validation.yml"])

        # Only manifest changed -> passes
        verifier.verify_pr_diff_updates_manifest([updater.MANIFEST_RELPATH])

        # Blob + manifest changed -> passes
        verifier.verify_pr_diff_updates_manifest(
            ["lib/embedded_node/blobs/libznn.so", updater.MANIFEST_RELPATH]
        )

        # Blob changed without manifest -> fails
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "without updating"):
            verifier.verify_pr_diff_updates_manifest(["lib/embedded_node/blobs/libznn.so"])

        # Option-like git refs are rejected before invoking git diff
        with self.assertRaisesRegex(verifier.ManifestVerificationError, "Invalid git ref"):
            verifier.get_changed_blob_paths(self.repo_root, base_ref="--output=/tmp/x")

    def test_git_diff_integration_with_base_ref(self) -> None:
        def run_git(*args: str) -> str:
            proc = subprocess.run(
                ["git", "-C", str(self.repo_root), *args],
                check=True,
                capture_output=True,
                text=True,
            )
            return proc.stdout.strip()

        run_git("init")
        run_git("config", "user.email", "ci@example.com")
        run_git("config", "user.name", "CI Test")
        run_git("add", ".")
        run_git("commit", "-m", "initial blobs and manifest")
        base_sha = run_git("rev-parse", "HEAD")

        # Change only blob permissions/content without updating manifest -> fails via git diff
        (self.blobs_dir / "libznn.dll").write_bytes(b"MZ-windows-v2")
        run_git("add", "lib/embedded_node/blobs/libznn.dll")
        run_git("commit", "-m", "update dll without manifest")

        stderr_buf = io.StringIO()
        old_stderr = sys.stderr
        try:
            sys.stderr = stderr_buf
            rc = verifier.main(
                ["--repo-root", str(self.repo_root), "--base-ref", base_sha, "--head-ref", "HEAD"]
            )
        finally:
            sys.stderr = old_stderr
        self.assertEqual(rc, 1)
        self.assertIn("without updating", stderr_buf.getvalue())

        # Now update manifest to match the new dll -> passes cleanly
        self.windows_bytes = b"MZ-windows-v2"
        self._write_manifest(windows_bytes=self.windows_bytes, tag="v0.0.11-alphanet")
        run_git("add", updater.MANIFEST_RELPATH)
        run_git("commit", "-m", "update manifest")

        stdout_buf = io.StringIO()
        old_stdout = sys.stdout
        try:
            sys.stdout = stdout_buf
            rc = verifier.main(
                ["--repo-root", str(self.repo_root), "--base-ref", base_sha, "--head-ref", "HEAD"]
            )
        finally:
            sys.stdout = old_stdout
        self.assertEqual(rc, 0)
        self.assertIn("Verified lib/embedded_node/blobs/libznn.manifest.json", stdout_buf.getvalue())


if __name__ == "__main__":
    unittest.main()
