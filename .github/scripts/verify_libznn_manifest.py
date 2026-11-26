#!/usr/bin/env python3
"""Validate lib/embedded_node/blobs/ against its committed provenance manifest."""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys
from typing import Sequence

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import update_libznn as updater

BLOBS_DIR_RELPATH = "lib/embedded_node/blobs"


class ManifestVerificationError(RuntimeError):
    """Raised when blob provenance manifest validation fails."""


def get_changed_blob_paths(
    repo_root: pathlib.Path,
    *,
    base_ref: str,
    head_ref: str = "HEAD",
) -> list[str]:
    """Return paths under lib/embedded_node/blobs/ changed between base_ref and head_ref."""
    for label, ref in (("base_ref", base_ref), ("head_ref", head_ref)):
        if not ref or ref.startswith("-"):
            raise ManifestVerificationError(f"Invalid git ref for {label}: {ref!r}")
    cmd = [
        "git",
        "-C",
        str(repo_root),
        "diff",
        "-z",
        "--name-only",
        "--no-renames",
        "--end-of-options",
        base_ref,
        head_ref,
        "--",
        BLOBS_DIR_RELPATH,
    ]
    try:
        proc = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
        )
    except OSError as exc:
        raise ManifestVerificationError(f"Failed invoking git diff: {exc}") from exc

    if proc.returncode != 0:
        stderr = proc.stderr.decode("utf-8", errors="replace").strip()
        raise ManifestVerificationError(
            f"git diff {base_ref}..{head_ref} failed (exit {proc.returncode}): {stderr}"
        )

    raw_entries = proc.stdout.decode("utf-8", errors="surrogateescape").split("\0")
    return [entry for entry in raw_entries if entry]


def verify_pr_diff_updates_manifest(changed_paths: Sequence[str]) -> None:
    """Fail if any file under lib/embedded_node/blobs/ changed without updating the manifest."""
    normalized = [path.strip("/") for path in changed_paths if path.strip("/")]
    prefix = f"{BLOBS_DIR_RELPATH}/"
    blob_area_changes = [
        path for path in normalized if path == BLOBS_DIR_RELPATH or path.startswith(prefix)
    ]
    if not blob_area_changes:
        return
    non_manifest_changes = [
        path for path in blob_area_changes if path != updater.MANIFEST_RELPATH
    ]
    if non_manifest_changes and updater.MANIFEST_RELPATH not in blob_area_changes:
        changed_list = ", ".join(sorted(non_manifest_changes))
        raise ManifestVerificationError(
            f"Files under {BLOBS_DIR_RELPATH}/ changed ({changed_list}) without updating "
            f"{updater.MANIFEST_RELPATH}. Update the provenance manifest alongside blob changes."
        )


def verify_blobs_directory_entries(repo_root: pathlib.Path) -> None:
    """Ensure lib/embedded_node/blobs/ contains only the expected binaries and manifest."""
    blobs_dir = repo_root / BLOBS_DIR_RELPATH
    if not blobs_dir.is_dir():
        raise ManifestVerificationError(f"Expected blobs directory is missing: {blobs_dir}")

    expected_names = {
        pathlib.PurePosixPath(spec.blob_relpath).name for spec in updater.BINARY_SPECS
    }
    expected_names.add(pathlib.PurePosixPath(updater.MANIFEST_RELPATH).name)

    unexpected: list[str] = []
    for entry in sorted(blobs_dir.iterdir(), key=lambda p: p.name):
        if entry.name == ".DS_Store":
            continue
        if entry.name not in expected_names:
            unexpected.append(f"{BLOBS_DIR_RELPATH}/{entry.name}")
    if unexpected:
        raise ManifestVerificationError(
            f"Unexpected file(s) in {BLOBS_DIR_RELPATH}/ not tracked by provenance manifest: "
            + ", ".join(unexpected)
        )


def verify_manifest_and_blobs(
    repo_root: pathlib.Path,
    *,
    base_ref: str | None = None,
    head_ref: str = "HEAD",
    changed_paths: Sequence[str] | None = None,
) -> dict[str, object]:
    """Validate manifest schema, on-disk blob SHA-256s, directory contents, and optional PR diff."""
    if changed_paths is not None:
        verify_pr_diff_updates_manifest(changed_paths)
    elif base_ref is not None:
        diff_paths = get_changed_blob_paths(repo_root, base_ref=base_ref, head_ref=head_ref)
        verify_pr_diff_updates_manifest(diff_paths)

    verify_blobs_directory_entries(repo_root)

    try:
        manifest = updater.load_provenance_manifest(repo_root)
    except updater.UpdaterError as exc:
        raise ManifestVerificationError(str(exc)) from exc

    if manifest is None:
        raise ManifestVerificationError(
            f"Missing required provenance manifest: {repo_root / updater.MANIFEST_RELPATH}"
        )

    blobs_section = manifest["blobs"]
    for spec in updater.BINARY_SPECS:
        blob_path = repo_root / spec.blob_relpath
        if blob_path.is_symlink():
            raise ManifestVerificationError(f"Embedded blob must not be a symlink: {blob_path}")
        if not blob_path.is_file():
            raise ManifestVerificationError(f"Missing embedded blob: {blob_path}")
        try:
            updater.verify_binary_magic(blob_path, spec.valid_magics, spec.blob_relpath)
            actual_sha256 = updater.sha256_file(blob_path)
        except (updater.UpdaterError, OSError) as exc:
            raise ManifestVerificationError(
                f"Failed verifying {spec.blob_relpath}: {exc}"
            ) from exc
        expected_sha256 = blobs_section[spec.blob_relpath]["extracted_sha256"]
        if actual_sha256 != expected_sha256:
            raise ManifestVerificationError(
                f"SHA-256 mismatch for {spec.blob_relpath}: "
                f"manifest records {expected_sha256}, but file on disk is {actual_sha256}. "
                f"Update {updater.MANIFEST_RELPATH} when updating embedded binaries."
            )

    return manifest


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Verify embedded libznn blobs against lib/embedded_node/blobs/libznn.manifest.json."
    )
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=pathlib.Path("."),
        help="Path to the syrius repository root.",
    )
    parser.add_argument(
        "--base-ref",
        default=None,
        help="Optional git base commit/ref to enforce manifest co-modification on blob changes.",
    )
    parser.add_argument(
        "--head-ref",
        default="HEAD",
        help="Git head commit/ref for diff comparison (default: HEAD).",
    )
    args = parser.parse_args(argv)

    try:
        manifest = verify_manifest_and_blobs(
            args.repo_root,
            base_ref=args.base_ref,
            head_ref=args.head_ref,
        )
    except ManifestVerificationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    release = manifest["release"]
    assert isinstance(release, dict)
    print(
        f"Verified {updater.MANIFEST_RELPATH} for go-zenon {release['tag']} "
        f"(commit: {release.get('tag_commit') or 'unknown'}) across {len(updater.BINARY_SPECS)} embedded blobs."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
