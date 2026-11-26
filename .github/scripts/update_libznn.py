#!/usr/bin/env python3
"""Fetch, verify, and stage embedded libznn binaries from zenon-network/go-zenon."""

from __future__ import annotations

import argparse
import contextlib
import dataclasses
import datetime
import hashlib
import http.client
import json
import os
import pathlib
import re
import secrets
import shutil
import socket
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from typing import Any, Iterator, Mapping, Sequence

DEFAULT_UPSTREAM_REPO = "zenon-network/go-zenon"
CHECKSUMS_ASSET_NAME = "SHA256CHECKSUMS.txt"
MANIFEST_RELPATH = "lib/embedded_node/blobs/libznn.manifest.json"
MANIFEST_SCHEMA_VERSION = 1
MANIFEST_FILE_MODE = 0o644
ALLOWED_TARGET_BRANCHES = frozenset({"develop", "master"})

TAG_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+-]*$")
REPO_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
SHA256_HEX_PATTERN = re.compile(r"^[0-9a-f]{64}$")
GIT_COMMIT_SHA_PATTERN = re.compile(r"^[0-9a-fA-F]{40}$")
SEMVER_TAG_PATTERN = re.compile(
    r"^[vV]?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?"
    r"(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$"
)
CHECKSUM_LINE_PATTERN = re.compile(r"^([0-9a-fA-F]{64})[ \t]+\*?(.+)$")
GITHUB_DIGEST_PATTERN = re.compile(r"^sha256:([0-9a-fA-F]{64})$")
OUTPUT_KEY_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")
MAX_TAG_DEREF_DEPTH = 5
# Allow normal upstream release CI upload lag (e.g. znn_builder + makefat) before warning.
ASSET_UPDATE_GRACE_SECONDS = 3600

# Cap archive downloads and extracted native binaries (current binaries are ~19-38 MiB).
MAX_ARCHIVE_BYTES = 256 * 1024 * 1024
MAX_EXTRACTED_BYTES = 256 * 1024 * 1024
MAX_CHECKSUMS_BYTES = 1 * 1024 * 1024
MAX_METADATA_BYTES = 2 * 1024 * 1024
HTTP_TIMEOUT_SECONDS = 60
HTTP_MAX_ATTEMPTS = 3
CHUNK_SIZE = 64 * 1024

ELF_MAGICS = (b"\x7fELF",)
MACHO_MAGICS = (
    b"\xca\xfe\xba\xbe",  # Universal Fat Mach-O (big-endian)
    b"\xbe\xba\xfe\xca",  # Universal Fat Mach-O (little-endian)
    b"\xca\xfe\xba\xbf",  # Universal Fat64 Mach-O (big-endian)
    b"\xbf\xba\xfe\xca",  # Universal Fat64 Mach-O (little-endian)
    b"\xcf\xfa\xed\xfe",  # 64-bit Mach-O (little-endian)
    b"\xfe\xed\xfa\xcf",  # 64-bit Mach-O (big-endian)
)
PE_MAGICS = (b"MZ",)


class UpdaterError(RuntimeError):
    """Raised when fetching, verifying, or extracting libznn assets fails."""


@dataclasses.dataclass(frozen=True)
class BinarySpec:
    platform: str
    asset_name: str
    archive_format: str  # "tar.gz" or "zip"
    member_name: str
    blob_relpath: str
    file_mode: int
    valid_magics: tuple[bytes, ...]


BINARY_SPECS: tuple[BinarySpec, ...] = (
    BinarySpec(
        platform="Linux (amd64)",
        asset_name="libznn-linux-amd64.tar.gz",
        archive_format="tar.gz",
        member_name="libznn-linux-amd64.so",
        blob_relpath="lib/embedded_node/blobs/libznn.so",
        file_mode=0o755,
        valid_magics=ELF_MAGICS,
    ),
    BinarySpec(
        platform="macOS (universal)",
        asset_name="libznn-darwin-universal.tar.gz",
        archive_format="tar.gz",
        member_name="libznn-darwin-universal.dylib",
        blob_relpath="lib/embedded_node/blobs/libznn.dylib",
        file_mode=0o644,
        valid_magics=MACHO_MAGICS,
    ),
    BinarySpec(
        platform="Windows (amd64)",
        asset_name="libznn-windows-amd64.zip",
        archive_format="zip",
        member_name="libznn-windows-amd64.dll",
        blob_relpath="lib/embedded_node/blobs/libznn.dll",
        file_mode=0o755,
        valid_magics=PE_MAGICS,
    ),
)


@dataclasses.dataclass(frozen=True)
class ChecksumVerification:
    actual_sha256: str
    checksums_file_sha256: str | None
    github_digest_sha256: str | None
    source_description: str


@dataclasses.dataclass(frozen=True)
class VerifiedBinary:
    spec: BinarySpec
    download_url: str
    archive_verification: ChecksumVerification
    extracted_sha256: str
    previous_sha256: str | None
    asset_updated_at: str | None = None

    @property
    def changed(self) -> bool:
        return self.previous_sha256 != self.extracted_sha256


@dataclasses.dataclass(frozen=True)
class _StagedBinary:
    verified: VerifiedBinary
    extracted_path: pathlib.Path


@dataclasses.dataclass(frozen=True)
class ReleaseInfo:
    upstream_repo: str
    tag_name: str
    release_name: str
    html_url: str
    published_at: str
    prerelease: bool
    checksums_url: str | None
    checksums_sha256: str | None
    target_commitish: str | None = None
    tag_commit: str | None = None
    immutable: bool | None = None
    checksums_updated_at: str | None = None


@dataclasses.dataclass(frozen=True)
class ProvenanceAlerts:
    late_updated_assets: tuple[tuple[str, str], ...] = ()
    same_tag_rebuild: bool = False
    same_tag_rebuild_reasons: tuple[str, ...] = ()
    is_downgrade: bool = False
    previous_tag: str | None = None
    commitish_mismatch: bool = False


class _SafeRedirectHandler(urllib.request.HTTPRedirectHandler):
    """Enforce HTTPS on redirects and never forward Authorization across hosts."""

    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: Any,
        code: int,
        msg: str,
        headers: Any,
        newurl: str,
    ) -> urllib.request.Request | None:
        parsed_new = urllib.parse.urlsplit(newurl)
        if parsed_new.scheme != "https":
            raise UpdaterError(
                f"Refusing non-HTTPS redirect to {parsed_new.scheme!r} URL: {newurl}"
            )
        new_req = super().redirect_request(req, fp, code, msg, headers, newurl)
        if new_req is None:
            return None
        old_host = urllib.parse.urlsplit(req.full_url).netloc.lower()
        new_host = parsed_new.netloc.lower()
        if old_host != new_host:
            new_req.remove_header("Authorization")
            if hasattr(new_req, "unredirected_hdrs"):
                new_req.unredirected_hdrs.pop("Authorization", None)
        return new_req


def _build_opener() -> urllib.request.OpenerDirector:
    return urllib.request.build_opener(_SafeRedirectHandler())


def validate_upstream_repo(repo: str) -> str:
    cleaned = repo.strip()
    if not REPO_PATTERN.fullmatch(cleaned) or ".." in cleaned:
        raise UpdaterError(f"Invalid upstream repository identifier: {repo!r}")
    return cleaned


def validate_tag(tag: str) -> str:
    if "\n" in tag or "\r" in tag:
        raise UpdaterError(f"Invalid release tag format (newline not allowed): {tag!r}")
    cleaned = tag.strip()
    if not cleaned:
        return ""
    if not TAG_PATTERN.fullmatch(cleaned) or ".." in cleaned:
        raise UpdaterError(f"Invalid release tag format: {tag!r}")
    return cleaned


def validate_target_branch(branch: str) -> str:
    cleaned = branch.strip()
    if cleaned not in ALLOWED_TARGET_BRANCHES:
        allowed = ", ".join(sorted(ALLOWED_TARGET_BRANCHES))
        raise UpdaterError(
            f"Unsupported target branch {branch!r}; allowed values: {allowed}"
        )
    return cleaned


def validate_git_commit_sha(value: Any, label: str = "git commit SHA") -> str:
    if not isinstance(value, str):
        raise UpdaterError(f"Invalid {label}: expected string, got {type(value).__name__}")
    cleaned = value.strip()
    if not GIT_COMMIT_SHA_PATTERN.fullmatch(cleaned):
        raise UpdaterError(f"Invalid {label}: {value!r}")
    return cleaned.lower()


def _sanitize_inline_text(value: Any, *, default: str | None = None) -> str | None:
    if value is None:
        return default
    cleaned = re.sub(r"[\r\n`]+", " ", str(value)).strip()
    return cleaned if cleaned else default


def parse_iso8601_utc(value: str | None) -> datetime.datetime | None:
    if not value or not isinstance(value, str):
        return None
    cleaned = value.strip()
    if not cleaned:
        return None
    if cleaned.endswith(("Z", "z")):
        cleaned = cleaned[:-1] + "+00:00"
    try:
        dt = datetime.datetime.fromisoformat(cleaned)
    except ValueError:
        return None
    if dt.tzinfo is None or dt.utcoffset() is None:
        return None
    return dt.astimezone(datetime.timezone.utc)


def parse_semver_tag(tag: str) -> tuple[int, int, int, tuple[str, ...]] | None:
    """Parse a SemVer 2.0.0 tag (optional leading v/V) into (major, minor, patch, prerelease)."""
    match = SEMVER_TAG_PATTERN.fullmatch(tag.strip())
    if not match:
        return None
    major, minor, patch = int(match.group(1)), int(match.group(2)), int(match.group(3))
    prerelease = tuple(match.group(4).split(".")) if match.group(4) else ()
    # Per SemVer 2.0.0 §9, numeric prerelease identifiers MUST NOT include leading zeroes.
    for ident in prerelease:
        if ident.isdigit() and len(ident) > 1 and ident.startswith("0"):
            return None
    return major, minor, patch, prerelease


def compare_release_tags(tag_a: str, tag_b: str) -> int | None:
    """Compare two SemVer tags. Returns -1 if a < b, 0 if equal, 1 if a > b, None if incomparable."""
    parsed_a = parse_semver_tag(tag_a)
    parsed_b = parse_semver_tag(tag_b)
    if parsed_a is None or parsed_b is None:
        return None

    core_a, pre_a = parsed_a[:3], parsed_a[3]
    core_b, pre_b = parsed_b[:3], parsed_b[3]
    if core_a != core_b:
        return -1 if core_a < core_b else 1

    if not pre_a and not pre_b:
        return 0
    if not pre_a:
        return 1
    if not pre_b:
        return -1

    for ident_a, ident_b in zip(pre_a, pre_b):
        if ident_a == ident_b:
            continue
        a_num = ident_a.isdigit()
        b_num = ident_b.isdigit()
        if a_num and b_num:
            return -1 if int(ident_a) < int(ident_b) else 1
        if a_num != b_num:
            return -1 if a_num else 1
        return -1 if ident_a < ident_b else 1

    if len(pre_a) != len(pre_b):
        return -1 if len(pre_a) < len(pre_b) else 1
    return 0


def find_late_updated_assets(
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
    *,
    grace_seconds: int = ASSET_UPDATE_GRACE_SECONDS,
) -> list[tuple[str, str]]:
    """Return [(asset_name, updated_at)] for consumed assets updated past the post-publish grace window."""
    published_dt = parse_iso8601_utc(release.published_at)
    if published_dt is None:
        return []
    cutoff_dt = published_dt + datetime.timedelta(seconds=grace_seconds)
    late: list[tuple[str, str]] = []
    if release.checksums_url and release.checksums_updated_at:
        csum_dt = parse_iso8601_utc(release.checksums_updated_at)
        if csum_dt is not None and csum_dt > cutoff_dt:
            late.append((CHECKSUMS_ASSET_NAME, release.checksums_updated_at))
    for item in verified_binaries:
        if not item.asset_updated_at:
            continue
        asset_dt = parse_iso8601_utc(item.asset_updated_at)
        if asset_dt is not None and asset_dt > cutoff_dt:
            late.append((item.spec.asset_name, item.asset_updated_at))
    return late


def _timestamp_changed(prev_ts: str | None, new_ts: str | None) -> bool:
    if not prev_ts or not new_ts:
        return False
    prev_dt = parse_iso8601_utc(prev_ts)
    new_dt = parse_iso8601_utc(new_ts)
    if prev_dt is not None and new_dt is not None:
        return new_dt != prev_dt
    return prev_ts != new_ts


def _format_late_delta(published_at: str, updated_at: str) -> str:
    published_dt = parse_iso8601_utc(published_at)
    updated_dt = parse_iso8601_utc(updated_at)
    if published_dt is None or updated_dt is None or updated_dt <= published_dt:
        return ""
    seconds = int((updated_dt - published_dt).total_seconds())
    if seconds < 60:
        return f" (+{seconds}s)"
    minutes, rem_s = divmod(seconds, 60)
    if minutes < 60:
        return f" (+{minutes}m{rem_s:02d}s)"
    hours, rem_m = divmod(minutes, 60)
    if hours < 24:
        return f" (+{hours}h{rem_m:02d}m)"
    days, rem_h = divmod(hours, 24)
    return f" (+{days}d{rem_h:02d}h)"


def build_provenance_manifest(
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
) -> dict[str, Any]:
    checksums_entry: dict[str, Any] | None = None
    if release.checksums_url and release.checksums_sha256:
        checksums_entry = {
            "name": CHECKSUMS_ASSET_NAME,
            "download_url": release.checksums_url,
            "sha256": release.checksums_sha256,
            "updated_at": release.checksums_updated_at,
        }
    blobs_map: dict[str, dict[str, Any]] = {}
    for item in verified_binaries:
        blobs_map[item.spec.blob_relpath] = {
            "platform": item.spec.platform,
            "asset_name": item.spec.asset_name,
            "download_url": item.download_url,
            "asset_updated_at": item.asset_updated_at,
            "archive_sha256": item.archive_verification.actual_sha256,
            "extracted_sha256": item.extracted_sha256,
        }
    return {
        "schema_version": MANIFEST_SCHEMA_VERSION,
        "upstream_repo": release.upstream_repo,
        "release": {
            "tag": release.tag_name,
            "name": release.release_name,
            "html_url": release.html_url,
            "published_at": release.published_at,
            "prerelease": release.prerelease,
            "immutable": release.immutable,
            "target_commitish": release.target_commitish,
            "tag_commit": release.tag_commit,
            "checksums_asset": checksums_entry,
        },
        "blobs": blobs_map,
    }


def serialize_provenance_manifest(manifest: Mapping[str, Any]) -> str:
    return json.dumps(manifest, indent=2) + "\n"


def validate_provenance_manifest(
    data: Any,
    *,
    source: str = MANIFEST_RELPATH,
) -> dict[str, Any]:
    if not isinstance(data, dict):
        raise UpdaterError(f"Provenance manifest {source} must be a JSON object")
    schema_version = data.get("schema_version")
    if type(schema_version) is not int or schema_version != MANIFEST_SCHEMA_VERSION:
        raise UpdaterError(
            f"Unsupported provenance manifest schema_version in {source}: {schema_version!r}"
        )
    raw_repo = data.get("upstream_repo")
    if not isinstance(raw_repo, str):
        raise UpdaterError(f"Provenance manifest {source} is missing valid upstream_repo")
    upstream_repo = validate_upstream_repo(raw_repo)

    release = data.get("release")
    if not isinstance(release, dict):
        raise UpdaterError(f"Provenance manifest {source} is missing release object")
    raw_tag = release.get("tag")
    if not isinstance(raw_tag, str) or not validate_tag(raw_tag):
        raise UpdaterError(f"Provenance manifest {source} has invalid release.tag: {raw_tag!r}")
    if not isinstance(release.get("name"), str) or not release["name"].strip():
        raise UpdaterError(f"Provenance manifest {source} is missing release.name")
    raw_html_url = release.get("html_url")
    if not isinstance(raw_html_url, str):
        raise UpdaterError(f"Provenance manifest {source} is missing release.html_url")
    validate_release_html_url(raw_html_url, upstream_repo)
    raw_published_at = release.get("published_at")
    if not isinstance(raw_published_at, str) or not raw_published_at.strip():
        raise UpdaterError(f"Provenance manifest {source} is missing release.published_at")
    if type(release.get("prerelease")) is not bool:
        raise UpdaterError(f"Provenance manifest {source} release.prerelease must be a boolean")
    immutable = release.get("immutable")
    if immutable is not None and type(immutable) is not bool:
        raise UpdaterError(f"Provenance manifest {source} release.immutable must be boolean or null")
    target_commitish = release.get("target_commitish")
    if target_commitish is not None and (
        not isinstance(target_commitish, str) or not target_commitish.strip()
    ):
        raise UpdaterError(
            f"Provenance manifest {source} release.target_commitish must be non-empty string or null"
        )
    tag_commit = release.get("tag_commit")
    if tag_commit is not None:
        validate_git_commit_sha(tag_commit, label=f"{source} release.tag_commit")

    checksums_asset = release.get("checksums_asset")
    if checksums_asset is not None:
        if not isinstance(checksums_asset, dict):
            raise UpdaterError(f"Provenance manifest {source} release.checksums_asset must be object or null")
        if checksums_asset.get("name") != CHECKSUMS_ASSET_NAME:
            raise UpdaterError(
                f"Provenance manifest {source} release.checksums_asset.name must be {CHECKSUMS_ASSET_NAME!r}"
            )
        raw_csum_url = checksums_asset.get("download_url")
        if not isinstance(raw_csum_url, str):
            raise UpdaterError(f"Provenance manifest {source} release.checksums_asset.download_url missing")
        validate_release_download_url(raw_csum_url, upstream_repo)
        raw_csum_sha = checksums_asset.get("sha256")
        if not isinstance(raw_csum_sha, str) or not SHA256_HEX_PATTERN.fullmatch(raw_csum_sha):
            raise UpdaterError(f"Provenance manifest {source} release.checksums_asset.sha256 invalid")
        csum_updated_at = checksums_asset.get("updated_at")
        if csum_updated_at is not None and (
            not isinstance(csum_updated_at, str) or not csum_updated_at.strip()
        ):
            raise UpdaterError(
                f"Provenance manifest {source} release.checksums_asset.updated_at must be string or null"
            )

    blobs = data.get("blobs")
    if not isinstance(blobs, dict):
        raise UpdaterError(f"Provenance manifest {source} is missing blobs mapping")
    expected_keys = {spec.blob_relpath for spec in BINARY_SPECS}
    actual_keys = set(blobs.keys())
    if actual_keys != expected_keys:
        missing = sorted(expected_keys - actual_keys)
        extra = sorted(actual_keys - expected_keys)
        raise UpdaterError(
            f"Provenance manifest {source} blobs keys mismatch (missing={missing}, extra={extra})"
        )
    for spec in BINARY_SPECS:
        entry = blobs[spec.blob_relpath]
        if not isinstance(entry, dict):
            raise UpdaterError(f"Provenance manifest {source} entry for {spec.blob_relpath} must be an object")
        if not isinstance(entry.get("platform"), str) or not entry["platform"].strip():
            raise UpdaterError(f"Provenance manifest {source} {spec.blob_relpath}.platform missing")
        if entry.get("asset_name") != spec.asset_name:
            raise UpdaterError(
                f"Provenance manifest {source} {spec.blob_relpath}.asset_name expected {spec.asset_name!r}, "
                f"got {entry.get('asset_name')!r}"
            )
        raw_dl_url = entry.get("download_url")
        if not isinstance(raw_dl_url, str):
            raise UpdaterError(f"Provenance manifest {source} {spec.blob_relpath}.download_url missing")
        validate_release_download_url(raw_dl_url, upstream_repo)
        asset_updated_at = entry.get("asset_updated_at")
        if asset_updated_at is not None and (
            not isinstance(asset_updated_at, str) or not asset_updated_at.strip()
        ):
            raise UpdaterError(
                f"Provenance manifest {source} {spec.blob_relpath}.asset_updated_at must be string or null"
            )
        for field_name in ("archive_sha256", "extracted_sha256"):
            raw_hash = entry.get(field_name)
            if not isinstance(raw_hash, str) or not SHA256_HEX_PATTERN.fullmatch(raw_hash):
                raise UpdaterError(
                    f"Provenance manifest {source} {spec.blob_relpath}.{field_name} invalid: {raw_hash!r}"
                )
    return data


def load_provenance_manifest(repo_root: pathlib.Path) -> dict[str, Any] | None:
    manifest_path = repo_root / MANIFEST_RELPATH
    if manifest_path.is_symlink():
        raise UpdaterError(f"Provenance manifest path must not be a symlink: {manifest_path}")
    if not manifest_path.exists():
        return None
    if manifest_path.is_dir():
        raise UpdaterError(f"Provenance manifest path is a directory: {manifest_path}")
    try:
        raw = manifest_path.read_text(encoding="utf-8")
        parsed = json.loads(raw)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise UpdaterError(f"Failed to read provenance manifest {manifest_path}: {exc}") from exc
    return validate_provenance_manifest(parsed, source=str(manifest_path))


def evaluate_manifest_transition(
    existing_manifest: Mapping[str, Any] | None,
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
    *,
    allow_downgrade: bool = False,
) -> ProvenanceAlerts:
    late_assets = tuple(find_late_updated_assets(release, verified_binaries))
    commitish_mismatch = bool(
        release.target_commitish
        and release.tag_commit
        and GIT_COMMIT_SHA_PATTERN.fullmatch(release.target_commitish)
        and release.target_commitish.lower() != release.tag_commit.lower()
    )

    if existing_manifest is None:
        return ProvenanceAlerts(
            late_updated_assets=late_assets,
            commitish_mismatch=commitish_mismatch,
        )

    prev_release = existing_manifest["release"]
    prev_tag = str(prev_release["tag"])
    prev_published_at = str(prev_release["published_at"])
    prev_tag_commit = prev_release.get("tag_commit")
    prev_blobs = existing_manifest["blobs"]

    tag_cmp = compare_release_tags(prev_tag, release.tag_name)
    is_downgrade = False
    if tag_cmp is not None:
        is_downgrade = tag_cmp > 0
    elif prev_tag != release.tag_name:
        prev_dt = parse_iso8601_utc(prev_published_at)
        new_dt = parse_iso8601_utc(release.published_at)
        if prev_dt is not None and new_dt is not None and new_dt < prev_dt:
            is_downgrade = True

    if is_downgrade and not allow_downgrade:
        raise UpdaterError(
            f"Refusing to downgrade embedded libznn from {prev_tag!r} to older release "
            f"{release.tag_name!r}; re-run with --allow-downgrade to force"
        )

    rebuild_reasons: list[str] = []
    if prev_tag == release.tag_name:
        if prev_tag_commit and release.tag_commit is None:
            raise UpdaterError(
                f"Refusing to overwrite recorded tag_commit ({prev_tag_commit}) for "
                f"{release.tag_name!r} with an unresolved tag commit; provide _resolved_tag_commit "
                "(via --fetch-metadata-only) or query the GitHub API directly"
            )
        if prev_tag_commit and release.tag_commit and prev_tag_commit.lower() != release.tag_commit.lower():
            rebuild_reasons.append(
                f"tag commit changed ({prev_tag_commit} -> {release.tag_commit})"
            )
        prev_csum = prev_release.get("checksums_asset")
        prev_csum_sha = prev_csum.get("sha256") if isinstance(prev_csum, dict) else None
        prev_csum_updated = prev_csum.get("updated_at") if isinstance(prev_csum, dict) else None
        if prev_csum_sha != release.checksums_sha256:
            rebuild_reasons.append(
                f"{CHECKSUMS_ASSET_NAME} SHA-256 changed "
                f"({prev_csum_sha or '<none>'} -> {release.checksums_sha256 or '<none>'})"
            )
        if _timestamp_changed(prev_csum_updated, release.checksums_updated_at):
            rebuild_reasons.append(
                f"{CHECKSUMS_ASSET_NAME} updated_at changed "
                f"({prev_csum_updated} -> {release.checksums_updated_at})"
            )
        for item in verified_binaries:
            prev_entry = prev_blobs[item.spec.blob_relpath]
            if prev_entry["archive_sha256"] != item.archive_verification.actual_sha256:
                rebuild_reasons.append(
                    f"{item.spec.asset_name} archive SHA-256 changed "
                    f"({prev_entry['archive_sha256']} -> {item.archive_verification.actual_sha256})"
                )
            if prev_entry["extracted_sha256"] != item.extracted_sha256:
                rebuild_reasons.append(
                    f"{item.spec.blob_relpath} extracted SHA-256 changed "
                    f"({prev_entry['extracted_sha256']} -> {item.extracted_sha256})"
                )
            elif item.changed:
                rebuild_reasons.append(
                    f"{item.spec.blob_relpath} on-disk binary differed from manifest/release "
                    f"({item.previous_sha256 or '<missing>'} -> {item.extracted_sha256})"
                )
            prev_asset_updated = prev_entry.get("asset_updated_at")
            if _timestamp_changed(prev_asset_updated, item.asset_updated_at):
                rebuild_reasons.append(
                    f"{item.spec.asset_name} updated_at changed "
                    f"({prev_asset_updated} -> {item.asset_updated_at})"
                )

    return ProvenanceAlerts(
        late_updated_assets=late_assets,
        same_tag_rebuild=bool(rebuild_reasons),
        same_tag_rebuild_reasons=tuple(rebuild_reasons),
        is_downgrade=is_downgrade,
        previous_tag=prev_tag,
        commitish_mismatch=commitish_mismatch,
    )


def _validate_github_url(url: str, expected_prefix: str, label: str) -> str:
    if any(ch.isspace() or ord(ch) < 32 or ch in "[]()<>`" for ch in url):
        raise UpdaterError(f"Invalid characters in {label}: {url!r}")
    parsed = urllib.parse.urlsplit(url)
    if (
        parsed.scheme != "https"
        or parsed.netloc.lower() != "github.com"
        or not parsed.path.startswith(expected_prefix)
    ):
        raise UpdaterError(
            f"Untrusted {label} {url!r}; expected https://github.com{expected_prefix}..."
        )
    return url


def validate_release_download_url(url: str, upstream_repo: str) -> str:
    return _validate_github_url(
        url,
        f"/{upstream_repo}/releases/download/",
        "asset download URL",
    )


def validate_release_html_url(url: str, upstream_repo: str) -> str:
    return _validate_github_url(
        url,
        f"/{upstream_repo}/releases/tag/",
        "release URL",
    )


def parse_github_asset_digest(digest: Any, asset_name: str) -> str | None:
    if digest is None or digest == "":
        return None
    if not isinstance(digest, str):
        raise UpdaterError(
            f"Unexpected non-string GitHub digest for {asset_name}: {digest!r}"
        )
    match = GITHUB_DIGEST_PATTERN.fullmatch(digest.strip())
    if not match:
        raise UpdaterError(
            f"Unsupported or malformed GitHub digest format for {asset_name}: {digest!r}"
        )
    return match.group(1).lower()


def parse_checksums_file(content: str) -> dict[str, str]:
    """Parse standard sha256sum / shasum -a 256 text into {filename: sha256_hex}."""
    parsed: dict[str, str] = {}
    for line_no, raw_line in enumerate(content.splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        match = CHECKSUM_LINE_PATTERN.fullmatch(line)
        if not match:
            raise UpdaterError(
                f"Malformed line {line_no} in {CHECKSUMS_ASSET_NAME}: {raw_line!r}"
            )
        digest = match.group(1).lower()
        filename = match.group(2).strip()
        if filename.startswith("./"):
            filename = filename[2:]
        if not filename or "/" in filename or "\\" in filename or ".." in filename:
            raise UpdaterError(
                f"Invalid filename on line {line_no} in {CHECKSUMS_ASSET_NAME}: {filename!r}"
            )
        existing = parsed.get(filename)
        if existing is not None and existing != digest:
            raise UpdaterError(
                f"Conflicting checksum entries for {filename} in {CHECKSUMS_ASSET_NAME}"
            )
        parsed[filename] = digest
    return parsed


def verify_asset_checksum(
    *,
    asset_name: str,
    actual_sha256: str,
    checksums_map: Mapping[str, str] | None,
    github_digest_sha256: str | None,
    require_in_checksums_file: bool = False,
) -> ChecksumVerification:
    actual = actual_sha256.lower()
    if not SHA256_HEX_PATTERN.fullmatch(actual):
        raise UpdaterError(f"Invalid computed SHA-256 for {asset_name}: {actual_sha256!r}")

    file_expected = checksums_map.get(asset_name) if checksums_map is not None else None
    gh_expected = github_digest_sha256.lower() if github_digest_sha256 else None

    if file_expected is not None and gh_expected is not None and file_expected != gh_expected:
        raise UpdaterError(
            f"Conflicting upstream checksums for {asset_name}: "
            f"{CHECKSUMS_ASSET_NAME}={file_expected} vs GitHub digest={gh_expected}"
        )

    if file_expected is not None and file_expected != actual:
        raise UpdaterError(
            f"SHA-256 mismatch for {asset_name} against {CHECKSUMS_ASSET_NAME}: "
            f"expected {file_expected}, got {actual}"
        )

    if gh_expected is not None and gh_expected != actual:
        raise UpdaterError(
            f"SHA-256 mismatch for {asset_name} against GitHub release digest: "
            f"expected {gh_expected}, got {actual}"
        )

    if require_in_checksums_file and file_expected is None:
        raise UpdaterError(
            f"{asset_name} is missing from {CHECKSUMS_ASSET_NAME} "
            "and strict checksums-file verification was requested"
        )

    if file_expected is None and gh_expected is None:
        raise UpdaterError(
            f"No upstream SHA-256 provenance available for {asset_name} "
            f"(absent from {CHECKSUMS_ASSET_NAME} and no GitHub release digest); refusing unverified binary"
        )

    if file_expected is not None and gh_expected is not None:
        source_desc = f"`{CHECKSUMS_ASSET_NAME}` + GitHub release digest"
    elif file_expected is not None:
        source_desc = f"`{CHECKSUMS_ASSET_NAME}`"
    elif checksums_map is not None:
        source_desc = (
            f"GitHub release digest (not listed in `{CHECKSUMS_ASSET_NAME}`)"
        )
    else:
        source_desc = (
            f"GitHub release digest (`{CHECKSUMS_ASSET_NAME}` absent from release)"
        )

    return ChecksumVerification(
        actual_sha256=actual,
        checksums_file_sha256=file_expected,
        github_digest_sha256=gh_expected,
        source_description=source_desc,
    )


def sha256_file(path: pathlib.Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(CHUNK_SIZE)
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest()


def _normalize_archive_member_name(name: str) -> str | None:
    if not name or "\\" in name or name.startswith("/"):
        return None
    normalized = name
    while normalized.startswith("./"):
        normalized = normalized[2:]
    if not normalized or "/" in normalized or normalized in {".", ".."}:
        return None
    return normalized


def _copy_stream_bounded(
    src: Any,
    dest_path: pathlib.Path,
    *,
    max_bytes: int,
    label: str,
) -> tuple[str, int]:
    hasher = hashlib.sha256()
    total = 0
    with dest_path.open("wb") as out:
        while True:
            chunk = src.read(CHUNK_SIZE)
            if not chunk:
                break
            total += len(chunk)
            if total > max_bytes:
                raise UpdaterError(
                    f"{label} exceeded maximum allowed size of {max_bytes} bytes"
                )
            hasher.update(chunk)
            out.write(chunk)
    return hasher.hexdigest(), total


def verify_binary_magic(path: pathlib.Path, valid_magics: Sequence[bytes], label: str) -> None:
    max_len = max(len(m) for m in valid_magics)
    with path.open("rb") as handle:
        header = handle.read(max_len)
    if not any(header.startswith(magic) for magic in valid_magics):
        raise UpdaterError(
            f"Extracted {label} failed binary header sanity check (got {header[:8].hex()!r})"
        )


def extract_expected_binary(
    archive_path: pathlib.Path,
    spec: BinarySpec,
    dest_path: pathlib.Path,
    *,
    max_extracted_bytes: int = MAX_EXTRACTED_BYTES,
) -> str:
    """Safely extract the single expected regular-file member and return its SHA-256."""
    if spec.archive_format == "tar.gz":
        try:
            with tarfile.open(archive_path, mode="r:gz") as tf:
                matches: list[tarfile.TarInfo] = []
                for member in tf.getmembers():
                    normalized = _normalize_archive_member_name(member.name)
                    if normalized != spec.member_name:
                        continue
                    if not member.isfile():
                        raise UpdaterError(
                            f"Archive {spec.asset_name} member {member.name!r} is not a regular file"
                        )
                    if member.size <= 0 or member.size > max_extracted_bytes:
                        raise UpdaterError(
                            f"Archive {spec.asset_name} member {member.name!r} has invalid size {member.size}"
                        )
                    matches.append(member)

                if len(matches) != 1:
                    raise UpdaterError(
                        f"Expected exactly 1 {spec.member_name!r} member in {spec.asset_name}, found {len(matches)}"
                    )
                target_member = matches[0]
                stream = tf.extractfile(target_member)
                if stream is None:
                    raise UpdaterError(
                        f"Unable to read {target_member.name!r} from {spec.asset_name}"
                    )
                with stream:
                    digest, total = _copy_stream_bounded(
                        stream,
                        dest_path,
                        max_bytes=max_extracted_bytes,
                        label=f"{spec.asset_name}:{spec.member_name}",
                    )
                if total != target_member.size or total == 0:
                    raise UpdaterError(
                        f"Extracted size mismatch for {spec.member_name} in {spec.asset_name}: "
                        f"expected {target_member.size}, read {total}"
                    )
        except (tarfile.TarError, EOFError, OSError) as exc:
            raise UpdaterError(f"Failed to extract {spec.asset_name}: {exc}") from exc

    elif spec.archive_format == "zip":
        try:
            with zipfile.ZipFile(archive_path, mode="r") as zf:
                matches_zip: list[zipfile.ZipInfo] = []
                for info in zf.infolist():
                    if info.is_dir():
                        continue
                    normalized = _normalize_archive_member_name(info.filename)
                    if normalized != spec.member_name:
                        continue
                    # Reject POSIX symlinks encoded in ZipInfo.external_attr.
                    unix_mode = (info.external_attr >> 16) & 0o170000
                    if unix_mode == 0o120000:
                        raise UpdaterError(
                            f"Archive {spec.asset_name} member {info.filename!r} is a symlink"
                        )
                    if info.file_size <= 0 or info.file_size > max_extracted_bytes:
                        raise UpdaterError(
                            f"Archive {spec.asset_name} member {info.filename!r} has invalid size {info.file_size}"
                        )
                    matches_zip.append(info)

                if len(matches_zip) != 1:
                    raise UpdaterError(
                        f"Expected exactly 1 {spec.member_name!r} member in {spec.asset_name}, found {len(matches_zip)}"
                    )
                target_info = matches_zip[0]
                with zf.open(target_info, mode="r") as stream:
                    digest, total = _copy_stream_bounded(
                        stream,
                        dest_path,
                        max_bytes=max_extracted_bytes,
                        label=f"{spec.asset_name}:{spec.member_name}",
                    )
                if total != target_info.file_size or total == 0:
                    raise UpdaterError(
                        f"Extracted size mismatch for {spec.member_name} in {spec.asset_name}: "
                        f"expected {target_info.file_size}, read {total}"
                    )
        except UpdaterError:
            raise
        except (zipfile.BadZipFile, RuntimeError, EOFError, OSError) as exc:
            raise UpdaterError(f"Failed to extract {spec.asset_name}: {exc}") from exc
    else:
        raise UpdaterError(f"Unsupported archive format: {spec.archive_format!r}")

    verify_binary_magic(dest_path, spec.valid_magics, spec.member_name)
    return digest


def _declared_content_length(resp: Any) -> int | None:
    headers = getattr(resp, "headers", None)
    if headers is None or not hasattr(headers, "get"):
        return None
    content_encoding = headers.get("Content-Encoding")
    if content_encoding and str(content_encoding).strip().lower() != "identity":
        return None
    raw_len = headers.get("Content-Length")
    if raw_len is None:
        return None
    try:
        length = int(str(raw_len).strip())
    except ValueError:
        return None
    return length if length >= 0 else None


def github_api_request_json(
    url: str,
    *,
    method: str = "GET",
    body: Mapping[str, Any] | None = None,
    github_token: str | None = None,
    opener: urllib.request.OpenerDirector | None = None,
    max_attempts: int = HTTP_MAX_ATTEMPTS,
    retry_backoff_seconds: float | None = None,
    api_label: str = "GitHub API",
    allow_empty_response: bool = False,
) -> Any:
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "syrius-libznn-updater",
    }
    if github_token and urllib.parse.urlsplit(url).netloc.lower() == "api.github.com":
        headers["Authorization"] = f"Bearer {github_token}"
    data: bytes | None = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    active_opener = opener or _build_opener()
    raw: bytes | None = None
    last_exc: Exception | None = None
    retryable_methods = {"GET", "HEAD", "DELETE"}

    for attempt in range(1, max_attempts + 1):
        try:
            with active_opener.open(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
                declared_len = _declared_content_length(resp)
                if declared_len is not None and declared_len > MAX_METADATA_BYTES:
                    raise UpdaterError(
                        f"{api_label} response exceeded {MAX_METADATA_BYTES} bytes ({url})"
                    )
                raw = resp.read(MAX_METADATA_BYTES + 1)
                if len(raw) > MAX_METADATA_BYTES:
                    raise UpdaterError(
                        f"{api_label} response exceeded {MAX_METADATA_BYTES} bytes ({url})"
                    )
                if declared_len is not None and len(raw) < declared_len:
                    raise http.client.IncompleteRead(raw, declared_len - len(raw))
                if declared_len is not None and len(raw) > declared_len:
                    raise http.client.HTTPException(
                        f"Response length mismatch for {url}: declared {declared_len} bytes, got {len(raw)}"
                    )
            break
        except UpdaterError:
            raise
        except urllib.error.HTTPError as exc:
            last_exc = exc
            if (
                method not in retryable_methods
                or exc.code not in {429, 500, 502, 503, 504}
                or attempt == max_attempts
            ):
                raise UpdaterError(f"HTTP {exc.code} fetching {url}: {exc.reason}") from exc
        except (
            urllib.error.URLError,
            http.client.HTTPException,
            ConnectionError,
            TimeoutError,
            socket.timeout,
        ) as exc:
            last_exc = exc
            if method not in retryable_methods or attempt == max_attempts:
                raise UpdaterError(f"Network error fetching {url}: {exc}") from exc
        except OSError as exc:
            raise UpdaterError(f"Error reading {api_label} response ({url}): {exc}") from exc
        sleep_s = (
            retry_backoff_seconds
            if retry_backoff_seconds is not None
            else min(2 ** (attempt - 1), 4)
        )
        if sleep_s > 0:
            time.sleep(sleep_s)

    if raw is None:
        raise UpdaterError(f"Failed fetching {url}: {last_exc}")

    if allow_empty_response and not raw.strip():
        return None

    try:
        return json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise UpdaterError(f"Invalid JSON from {api_label} ({url}): {exc}") from exc


def fetch_release_metadata(
    upstream_repo: str,
    tag: str,
    *,
    github_token: str | None = None,
    opener: urllib.request.OpenerDirector | None = None,
    max_attempts: int = HTTP_MAX_ATTEMPTS,
    retry_backoff_seconds: float | None = None,
) -> dict[str, Any]:
    if tag:
        encoded_tag = urllib.parse.quote(tag, safe="")
        url = f"https://api.github.com/repos/{upstream_repo}/releases/tags/{encoded_tag}"
    else:
        url = f"https://api.github.com/repos/{upstream_repo}/releases/latest"

    payload = github_api_request_json(
        url,
        github_token=github_token,
        opener=opener,
        max_attempts=max_attempts,
        retry_backoff_seconds=retry_backoff_seconds,
        api_label="GitHub Releases API",
    )
    if not isinstance(payload, dict):
        raise UpdaterError("Unexpected GitHub Releases API payload type")
    return payload


def fetch_tag_commit(
    upstream_repo: str,
    tag: str,
    *,
    github_token: str | None = None,
    opener: urllib.request.OpenerDirector | None = None,
    max_attempts: int = HTTP_MAX_ATTEMPTS,
    retry_backoff_seconds: float | None = None,
) -> str:
    """Resolve the authoritative commit SHA for an upstream release tag via git/ref/tags/<tag>."""
    validated_tag = validate_tag(tag)
    if not validated_tag:
        raise UpdaterError("Cannot resolve tag commit for empty tag")
    encoded_tag = urllib.parse.quote(validated_tag, safe="")
    ref_url = f"https://api.github.com/repos/{upstream_repo}/git/ref/tags/{encoded_tag}"
    payload = github_api_request_json(
        ref_url,
        github_token=github_token,
        opener=opener,
        max_attempts=max_attempts,
        retry_backoff_seconds=retry_backoff_seconds,
        api_label="GitHub Git Ref API",
    )
    expected_ref = f"refs/tags/{validated_tag}"
    if not isinstance(payload, dict) or payload.get("ref") != expected_ref:
        raise UpdaterError(
            f"Unexpected GitHub Git Ref API response for {expected_ref!r} ({ref_url})"
        )
    obj = payload.get("object")
    if not isinstance(obj, dict):
        raise UpdaterError(f"Missing object metadata for tag ref {expected_ref!r}")
    obj_sha = validate_git_commit_sha(obj.get("sha"), label=f"tag {validated_tag!r} object SHA")
    obj_type = obj.get("type")

    seen_tag_shas: set[str] = set()
    depth = 0
    while obj_type == "tag":
        if obj_sha in seen_tag_shas:
            raise UpdaterError(f"Circular annotated tag object reference detected for {validated_tag!r}")
        if depth >= MAX_TAG_DEREF_DEPTH:
            raise UpdaterError(
                f"Annotated tag {validated_tag!r} exceeded maximum dereference depth ({MAX_TAG_DEREF_DEPTH})"
            )
        seen_tag_shas.add(obj_sha)
        depth += 1
        tag_obj_url = f"https://api.github.com/repos/{upstream_repo}/git/tags/{obj_sha}"
        tag_obj = github_api_request_json(
            tag_obj_url,
            github_token=github_token,
            opener=opener,
            max_attempts=max_attempts,
            retry_backoff_seconds=retry_backoff_seconds,
            api_label="GitHub Git Tag API",
        )
        if not isinstance(tag_obj, dict) or not isinstance(tag_obj.get("object"), dict):
            raise UpdaterError(f"Malformed annotated tag object {obj_sha} for {validated_tag!r}")
        inner_obj = tag_obj["object"]
        obj_sha = validate_git_commit_sha(
            inner_obj.get("sha"), label=f"annotated tag {validated_tag!r} target SHA"
        )
        obj_type = inner_obj.get("type")

    if obj_type != "commit":
        raise UpdaterError(
            f"Expected tag {validated_tag!r} to resolve to a commit, got {obj_type!r}"
        )
    return obj_sha


def load_release_metadata_file(path: pathlib.Path) -> dict[str, Any]:
    try:
        raw = path.read_text(encoding="utf-8")
        payload = json.loads(raw)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise UpdaterError(f"Failed to load release metadata JSON from {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise UpdaterError(f"Unexpected release metadata JSON payload type in {path}")
    return payload


def download_release_file(
    url: str,
    dest_path: pathlib.Path,
    *,
    upstream_repo: str,
    max_bytes: int,
    opener: urllib.request.OpenerDirector | None = None,
    max_attempts: int = HTTP_MAX_ATTEMPTS,
    retry_backoff_seconds: float | None = None,
) -> str:
    validate_release_download_url(url, upstream_repo)
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "syrius-libznn-updater"},
    )
    active_opener = opener or _build_opener()
    last_exc: Exception | None = None
    for attempt in range(1, max_attempts + 1):
        try:
            with active_opener.open(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
                declared_len = _declared_content_length(resp)
                if declared_len is not None and declared_len > max_bytes:
                    raise UpdaterError(
                        f"{url} declared Content-Length {declared_len} exceeds maximum allowed size of {max_bytes} bytes"
                    )
                digest, total = _copy_stream_bounded(
                    resp,
                    dest_path,
                    max_bytes=max_bytes,
                    label=url,
                )
            if declared_len is not None and total < declared_len:
                raise http.client.IncompleteRead(b"", declared_len - total)
            if declared_len is not None and total > declared_len:
                raise http.client.HTTPException(
                    f"Response length mismatch for {url}: declared {declared_len} bytes, got {total}"
                )
            if total == 0:
                raise UpdaterError(f"Downloaded file from {url} is empty")
            return digest
        except UpdaterError:
            dest_path.unlink(missing_ok=True)
            raise
        except urllib.error.HTTPError as exc:
            dest_path.unlink(missing_ok=True)
            last_exc = exc
            if exc.code not in {429, 500, 502, 503, 504} or attempt == max_attempts:
                raise UpdaterError(f"HTTP {exc.code} downloading {url}: {exc.reason}") from exc
        except (
            urllib.error.URLError,
            http.client.HTTPException,
            ConnectionError,
            TimeoutError,
            socket.timeout,
        ) as exc:
            dest_path.unlink(missing_ok=True)
            last_exc = exc
            if attempt == max_attempts:
                raise UpdaterError(f"Network error downloading {url}: {exc}") from exc
        except OSError as exc:
            dest_path.unlink(missing_ok=True)
            raise UpdaterError(f"I/O error downloading {url}: {exc}") from exc
        sleep_s = (
            retry_backoff_seconds
            if retry_backoff_seconds is not None
            else min(2 ** (attempt - 1), 4)
        )
        if sleep_s > 0:
            time.sleep(sleep_s)
    raise UpdaterError(f"Failed downloading {url}: {last_exc}")


def _safe_unlink(path: pathlib.Path, context: str) -> None:
    try:
        path.unlink(missing_ok=True)
    except OSError as exc:
        print(f"WARNING: failed to remove {context} {path}: {exc}", file=sys.stderr)


def _paths_alias(path_a: pathlib.Path, path_b: pathlib.Path) -> bool:
    try:
        if path_a.resolve(strict=False) == path_b.resolve(strict=False):
            return True
    except OSError:
        pass
    try:
        if path_a.exists() and path_b.exists() and os.path.samefile(path_a, path_b):
            return True
    except OSError:
        pass
    return False


def _validate_output_file_path(
    path: pathlib.Path | None,
    label: str,
    protected_entries: Sequence[tuple[pathlib.Path, str]] = (),
) -> None:
    if path is None:
        return
    if path.exists() and path.is_dir():
        raise UpdaterError(f"{label} path is a directory, not a file: {path}")
    for protected, protected_kind in protected_entries:
        if _paths_alias(path, protected):
            raise UpdaterError(
                f"{label} path {path} must not refer to {protected_kind} {protected}"
            )


def validate_output_file_paths(
    output_paths: Sequence[tuple[str, pathlib.Path | None]],
    *,
    protected_blobs: Sequence[pathlib.Path] = (),
    protected_manifest: pathlib.Path | None = None,
) -> None:
    """Validate individual output paths and reject pairwise collisions across CLI flags."""
    protected_entries: list[tuple[pathlib.Path, str]] = [
        (blob, "repository blob") for blob in protected_blobs
    ]
    if protected_manifest is not None:
        protected_entries.append((protected_manifest, "repository provenance manifest"))

    provided: list[tuple[str, pathlib.Path]] = []
    for label, path in output_paths:
        if path is None:
            continue
        _validate_output_file_path(path, label, protected_entries)
        provided.append((label, path))

    for idx, (label_a, path_a) in enumerate(provided):
        for label_b, path_b in provided[idx + 1 :]:
            if _paths_alias(path_a, path_b):
                raise UpdaterError(
                    f"Output paths for {label_a} ({path_a}) and {label_b} ({path_b}) "
                    "must not refer to the same file"
                )


def _create_backup(dest: pathlib.Path) -> pathlib.Path:
    for _ in range(16):
        backup = dest.parent / f".{dest.name}.{secrets.token_hex(8)}.bak"
        try:
            os.link(dest, backup)
            return backup
        except FileExistsError:
            continue
        except OSError:
            fd, tmp_bak = tempfile.mkstemp(
                prefix=f".{dest.name}.",
                suffix=".bak",
                dir=str(dest.parent),
            )
            os.close(fd)
            bak_path = pathlib.Path(tmp_bak)
            try:
                shutil.copy2(dest, bak_path)
                return bak_path
            except BaseException:
                _safe_unlink(bak_path, "temporary backup")
                raise
    raise UpdaterError(f"Failed to allocate unique backup path for {dest}")


@contextlib.contextmanager
def _staged_blob_transaction(
    repo_root: pathlib.Path,
    staged_binaries: Sequence[_StagedBinary],
    *,
    manifest_text: str | None = None,
    manifest_changed: bool = False,
) -> Iterator[list[pathlib.Path]]:
    """Stage changed blobs and manifest with rollback if any replacement or post-stage write fails."""
    prepared: list[tuple[pathlib.Path, pathlib.Path, pathlib.Path | None]] = []
    replaced: list[tuple[pathlib.Path, pathlib.Path | None]] = []
    try:
        for entry in staged_binaries:
            if not entry.verified.changed:
                continue
            dest = repo_root / entry.verified.spec.blob_relpath
            if dest.is_symlink():
                raise UpdaterError(f"Destination blob path must not be a symlink: {dest}")
            if dest.exists() and dest.is_dir():
                raise UpdaterError(f"Destination blob path is a directory: {dest}")
            dest.parent.mkdir(parents=True, exist_ok=True)
            fd, tmp_name = tempfile.mkstemp(
                prefix=f".{dest.name}.",
                suffix=".tmp",
                dir=str(dest.parent),
            )
            os.close(fd)
            tmp_path = pathlib.Path(tmp_name)
            prepared.append((tmp_path, dest, None))
            shutil.copyfile(entry.extracted_path, tmp_path)
            os.chmod(tmp_path, entry.verified.spec.file_mode)
            if dest.is_file():
                backup_path = _create_backup(dest)
                prepared[-1] = (tmp_path, dest, backup_path)

        if manifest_changed and manifest_text is not None:
            manifest_dest = repo_root / MANIFEST_RELPATH
            if manifest_dest.is_symlink():
                raise UpdaterError(
                    f"Destination provenance manifest path must not be a symlink: {manifest_dest}"
                )
            if manifest_dest.exists() and manifest_dest.is_dir():
                raise UpdaterError(
                    f"Destination provenance manifest path is a directory: {manifest_dest}"
                )
            manifest_dest.parent.mkdir(parents=True, exist_ok=True)
            fd, tmp_name = tempfile.mkstemp(
                prefix=f".{manifest_dest.name}.",
                suffix=".tmp",
                dir=str(manifest_dest.parent),
            )
            os.close(fd)
            tmp_path = pathlib.Path(tmp_name)
            prepared.append((tmp_path, manifest_dest, None))
            tmp_path.write_text(manifest_text, encoding="utf-8")
            os.chmod(tmp_path, MANIFEST_FILE_MODE)
            if manifest_dest.is_file():
                backup_path = _create_backup(manifest_dest)
                prepared[-1] = (tmp_path, manifest_dest, backup_path)

        updated_paths: list[pathlib.Path] = []
        for tmp_path, dest, backup_path in prepared:
            replaced.append((dest, backup_path))
            try:
                os.replace(tmp_path, dest)
            except BaseException:
                if tmp_path.exists():
                    replaced.pop()
                raise
            updated_paths.append(dest)

        yield updated_paths
    except BaseException as exc:
        retained_backups: set[pathlib.Path] = set()
        for dest, backup_path in reversed(replaced):
            try:
                if backup_path is not None:
                    os.replace(backup_path, dest)
                else:
                    dest.unlink(missing_ok=True)
            except OSError as restore_exc:
                if backup_path is not None:
                    retained_backups.add(backup_path)
                    print(
                        f"WARNING: failed to restore {dest} from backup {backup_path} during "
                        f"rollback: {restore_exc}; retaining backup {backup_path} for manual recovery",
                        file=sys.stderr,
                    )
                else:
                    print(
                        f"WARNING: failed to remove newly staged {dest} during rollback: {restore_exc}",
                        file=sys.stderr,
                    )
        for tmp_path, _, backup_path in prepared:
            _safe_unlink(tmp_path, "staging temp file")
            if backup_path is not None and backup_path not in retained_backups:
                _safe_unlink(backup_path, "rollback backup")
        if isinstance(exc, OSError):
            raise UpdaterError(f"Failed staging embedded binaries: {exc}") from exc
        raise
    else:
        for _, _, backup_path in prepared:
            if backup_path is not None:
                _safe_unlink(backup_path, "post-commit backup")


def _format_immutable_label(immutable: bool | None) -> str:
    if immutable is True:
        return "true"
    if immutable is False:
        return "false"
    return "unknown"


def build_pr_title(
    release: ReleaseInfo,
    *,
    alerts: ProvenanceAlerts | None = None,
) -> str:
    flags: list[str] = []
    if release.prerelease:
        flags.append("prerelease")
    if alerts is not None and alerts.same_tag_rebuild:
        flags.append("same-tag rebuild")
    if alerts is not None and alerts.is_downgrade:
        flags.append("downgrade")
    suffix = f" ({', '.join(flags)})" if flags else ""
    return f"chore: update embedded libznn to go-zenon {release.tag_name}{suffix}"


def build_commit_message(
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
    *,
    alerts: ProvenanceAlerts | None = None,
    manifest_changed: bool = False,
) -> str:
    active_alerts = alerts or ProvenanceAlerts()
    release_type = "pre-release" if release.prerelease else "release"
    immutable_label = _format_immutable_label(release.immutable)
    lines = [
        build_pr_title(release, alerts=active_alerts),
        "",
        f"Upstream release: {release.html_url}",
        f"Release type: {release_type}",
        f"Release immutable: {immutable_label}",
        f"Tag commit: {release.tag_commit or 'unknown'}",
    ]
    if release.target_commitish and release.target_commitish != release.tag_commit:
        lines.append(f"Target commitish: {release.target_commitish}")
    lines.append(f"Published: {release.published_at}")
    if release.checksums_url and release.checksums_sha256:
        csum_updated = f", updated_at: {release.checksums_updated_at}" if release.checksums_updated_at else ""
        lines.append(
            f"Checksums file: {release.checksums_url} "
            f"(sha256: {release.checksums_sha256}{csum_updated})"
        )
    else:
        lines.append(f"Checksums file: not present in release ({CHECKSUMS_ASSET_NAME})")

    warning_lines: list[str] = []
    if active_alerts.is_downgrade:
        warning_lines.append(
            f"- Forced downgrade from {active_alerts.previous_tag or 'unknown'} to {release.tag_name}"
        )
    if active_alerts.same_tag_rebuild:
        warning_lines.append(
            f"- Same-tag rebuild detected for {release.tag_name}: "
            + "; ".join(active_alerts.same_tag_rebuild_reasons)
        )
    if active_alerts.commitish_mismatch:
        warning_lines.append(
            f"- Release target_commitish ({release.target_commitish}) differs from resolved "
            f"tag commit ({release.tag_commit})"
        )
    for asset_name, updated_at in active_alerts.late_updated_assets:
        warning_lines.append(
            f"- Asset {asset_name} updated_at ({updated_at}) is later than release published_at ({release.published_at})"
        )
    if warning_lines:
        lines.extend(["", "Provenance warnings:"])
        lines.extend(warning_lines)

    lines.extend(["", "Verified upstream release archives (SHA-256):"])
    for item in verified_binaries:
        source_plain = item.archive_verification.source_description.replace("`", "")
        updated_part = f"; updated_at: {item.asset_updated_at}" if item.asset_updated_at else ""
        lines.append(
            f"- {item.spec.asset_name}: {item.archive_verification.actual_sha256} "
            f"({source_plain}{updated_part})"
        )
        lines.append(f"  URL: {item.download_url}")
    lines.extend(["", "Extracted embedded library binaries (SHA-256):"])
    for item in verified_binaries:
        prev = item.previous_sha256 or "<missing>"
        status = "updated" if item.changed else "unchanged"
        lines.append(
            f"- {item.spec.blob_relpath}: {item.extracted_sha256} ({status}; previous: {prev})"
        )
    manifest_status = "updated" if manifest_changed else "unchanged"
    lines.append(f"- {MANIFEST_RELPATH}: ({manifest_status})")
    return "\n".join(lines)


def build_pr_body(
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
    *,
    target_branch: str,
    workflow_run_url: str | None = None,
    alerts: ProvenanceAlerts | None = None,
    manifest_changed: bool = False,
) -> str:
    active_alerts = alerts or ProvenanceAlerts()
    release_type = "pre-release" if release.prerelease else "release"
    immutable_label = _format_immutable_label(release.immutable)
    immutable_suffix = " (mutable release)" if release.immutable is False else ""
    lines = [
        "## Summary",
        "",
        (
            f"Updates the embedded `libznn` binaries on `{target_branch}` to "
            f"[{release.upstream_repo} `{release.tag_name}`]({release.html_url}) "
            f"(published `{release.published_at}`)."
        ),
    ]
    if active_alerts.is_downgrade:
        lines.extend(
            [
                "",
                "> [!CAUTION]",
                (
                    f"> **Forced downgrade:** This update downgrades embedded `libznn` from "
                    f"`{active_alerts.previous_tag or 'unknown'}` to older release "
                    f"`{release.tag_name}` via `--allow-downgrade`. Confirm this downgrade is intentional."
                ),
            ]
        )
    if active_alerts.same_tag_rebuild:
        reasons_md = "; ".join(active_alerts.same_tag_rebuild_reasons)
        lines.extend(
            [
                "",
                "> [!CAUTION]",
                (
                    f"> **Same-tag rebuild detected:** Upstream release tag `{release.tag_name}` "
                    f"is unchanged from `{MANIFEST_RELPATH}`, but provenance hashes/metadata changed "
                    f"({reasons_md}). Inspect the upstream release carefully before merging."
                ),
            ]
        )
    if release.prerelease:
        lines.extend(
            [
                "",
                "> [!WARNING]",
                (
                    f"> Upstream release `{release.tag_name}` is marked as a **pre-release** "
                    f"on `{release.upstream_repo}`. Verify stability before merging."
                ),
            ]
        )
    if active_alerts.late_updated_assets:
        late_details = ", ".join(
            f"`{name}` (`{ts}`{_format_late_delta(release.published_at, ts)})"
            for name, ts in active_alerts.late_updated_assets
        )
        lines.extend(
            [
                "",
                "> [!WARNING]",
                (
                    f"> One or more upstream release assets have `updated_at` more than 1 hour "
                    f"after release `published_at` (`{release.published_at}`): {late_details}. "
                    "Verify these post-publication asset uploads were expected."
                ),
            ]
        )
    if active_alerts.commitish_mismatch:
        lines.extend(
            [
                "",
                "> [!WARNING]",
                (
                    f"> Upstream release `target_commitish` (`{release.target_commitish}`) differs "
                    f"from resolved `git/ref/tags/{release.tag_name}` commit (`{release.tag_commit}`)."
                ),
            ]
        )

    if release.tag_commit:
        commit_url = f"https://github.com/{release.upstream_repo}/commit/{release.tag_commit}"
        tag_commit_md = f"[`{release.tag_commit}`]({commit_url})"
    else:
        tag_commit_md = "`unknown`"

    lines.extend(
        [
            "",
            "## Upstream release provenance",
            "",
            f"- **Repository:** `{release.upstream_repo}`",
            f"- **Release tag:** [`{release.tag_name}`]({release.html_url})",
            f"- **Release type:** `{release_type}`",
            f"- **Release immutable:** `{immutable_label}`{immutable_suffix}",
            f"- **Tag commit:** {tag_commit_md}",
        ]
    )
    if release.target_commitish:
        lines.append(f"- **Target commitish:** `{release.target_commitish}`")
    lines.append(f"- **Published at:** `{release.published_at}`")
    if release.checksums_url and release.checksums_sha256:
        csum_updated_md = (
            f", updated `{release.checksums_updated_at}`" if release.checksums_updated_at else ""
        )
        lines.append(
            f"- **Upstream checksums file:** [`{CHECKSUMS_ASSET_NAME}`]({release.checksums_url}) "
            f"(`{release.checksums_sha256}`{csum_updated_md})"
        )
    else:
        lines.append(f"- **Upstream checksums file:** not present in release")
    manifest_state = "updated" if manifest_changed else "unchanged"
    lines.append(f"- **Provenance manifest:** `{MANIFEST_RELPATH}` ({manifest_state})")
    if workflow_run_url:
        lines.append(f"- **Workflow run:** {workflow_run_url}")

    lines.extend(
        [
            "",
            "### Verified release archives",
            "",
            "| Platform | Upstream asset | Archive SHA-256 | Updated at | Verification source |",
            "|---|---|---|---|---|",
        ]
    )
    for item in verified_binaries:
        updated_col = f"`{item.asset_updated_at}`" if item.asset_updated_at else "`unknown`"
        lines.append(
            f"| {item.spec.platform} "
            f"| [`{item.spec.asset_name}`]({item.download_url}) "
            f"| `{item.archive_verification.actual_sha256}` "
            f"| {updated_col} "
            f"| {item.archive_verification.source_description} |"
        )

    lines.extend(
        [
            "",
            "### Extracted embedded libraries",
            "",
            "| Blob path | Status | New SHA-256 | Previous SHA-256 |",
            "|---|---|---|---|",
        ]
    )
    for item in verified_binaries:
        status = "Updated" if item.changed else "Unchanged"
        prev = f"`{item.previous_sha256}`" if item.previous_sha256 else "`<missing>`"
        lines.append(
            f"| `{item.spec.blob_relpath}` | {status} | `{item.extracted_sha256}` | {prev} |"
        )

    lines.extend(
        [
            "",
            "## Verification checklist",
            "",
            "- [ ] CI desktop builds (`macOS`, `Windows`, `Linux`) pass",
            "- [ ] PR unit/widget tests and devnet BDD integration tests pass",
            "- [ ] Smoke-test embedded node startup/RPC/shutdown if FFI or runtime behavior changed",
            "",
            "> **Note:** Pull requests opened with the default `GITHUB_TOKEN` create "
            "`pull_request` CI runs that require approval. A maintainer with write access must "
            "select **Approve workflows to run** in the merge box. If no CI runs appear, check "
            "the workflow triggers and branch filters.",
        ]
    )
    return "\n".join(lines) + "\n"


def build_step_summary(
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
    *,
    target_branch: str,
    changed: bool,
    dry_run: bool,
    alerts: ProvenanceAlerts | None = None,
    manifest_changed: bool = False,
) -> str:
    active_alerts = alerts or ProvenanceAlerts()
    if changed and dry_run:
        status_line = (
            f"Updates detected for `{target_branch}` (dry run; no repository blobs were modified)."
        )
    elif changed:
        status_line = f"Updated embedded `libznn` binaries staged for `{target_branch}`."
    else:
        status_line = (
            f"All embedded `libznn` binaries on `{target_branch}` are already up to date with "
            f"`{release.tag_name}`."
        )

    heading_flags: list[str] = []
    if release.prerelease:
        heading_flags.append("pre-release")
    if active_alerts.same_tag_rebuild:
        heading_flags.append("same-tag rebuild")
    if active_alerts.is_downgrade:
        heading_flags.append("downgrade")
    heading_suffix = f" — {', '.join(heading_flags)}" if heading_flags else ""
    immutable_label = _format_immutable_label(release.immutable)
    lines = [
        f"## Embedded `libznn` update check (`{release.tag_name}`{heading_suffix})",
        "",
        status_line,
        "",
        f"- **Tag commit:** `{release.tag_commit or 'unknown'}`",
        f"- **Release immutable:** `{immutable_label}`",
        f"- **Published at:** `{release.published_at}`",
        f"- **Manifest (`{MANIFEST_RELPATH}`):** {'Updated' if manifest_changed else 'Unchanged'}",
    ]
    if active_alerts.is_downgrade:
        lines.extend(
            [
                "",
                (
                    f"> **Warning:** Forced downgrade from `{active_alerts.previous_tag or 'unknown'}` "
                    f"to `{release.tag_name}`."
                ),
            ]
        )
    if active_alerts.same_tag_rebuild:
        lines.extend(
            [
                "",
                (
                    f"> **Warning:** Same-tag rebuild detected for `{release.tag_name}` "
                    f"({'; '.join(active_alerts.same_tag_rebuild_reasons)})."
                ),
            ]
        )
    if release.prerelease:
        lines.extend(
            [
                "",
                f"> **Warning:** Upstream release `{release.tag_name}` is marked as a **pre-release**.",
            ]
        )
    if active_alerts.late_updated_assets:
        late_details = ", ".join(
            f"`{name}` (`{ts}`{_format_late_delta(release.published_at, ts)})"
            for name, ts in active_alerts.late_updated_assets
        )
        lines.extend(
            [
                "",
                (
                    f"> **Warning:** Assets updated after release `published_at` "
                    f"(`{release.published_at}`): {late_details}."
                ),
            ]
        )
    if active_alerts.commitish_mismatch:
        lines.extend(
            [
                "",
                (
                    f"> **Warning:** Release `target_commitish` (`{release.target_commitish}`) "
                    f"differs from tag commit (`{release.tag_commit}`)."
                ),
            ]
        )
    lines.extend(
        [
            "",
            "| Platform | Upstream asset | Archive SHA-256 | Updated at | Verification | Extracted SHA-256 | Status |",
            "|---|---|---|---|---|---|---|",
        ]
    )
    for item in verified_binaries:
        state = "Updated" if item.changed else "Unchanged"
        updated_col = f"`{item.asset_updated_at}`" if item.asset_updated_at else "`unknown`"
        lines.append(
            f"| {item.spec.platform} "
            f"| [`{item.spec.asset_name}`]({item.download_url}) "
            f"| `{item.archive_verification.actual_sha256}` "
            f"| {updated_col} "
            f"| {item.archive_verification.source_description} "
            f"| `{item.extracted_sha256}` "
            f"| {state} |"
        )
    return "\n".join(lines) + "\n"


def write_github_outputs(output_path: pathlib.Path, outputs: Mapping[str, str]) -> None:
    lines: list[str] = []
    for key, value in outputs.items():
        if not OUTPUT_KEY_PATTERN.fullmatch(key):
            raise UpdaterError(f"Invalid GITHUB_OUTPUT key: {key!r}")
        if "\n" in value or "\r" in value:
            delimiter = f"EOF_{secrets.token_hex(16)}"
            while delimiter in value:
                delimiter = f"EOF_{secrets.token_hex(16)}"
            lines.append(f"{key}<<{delimiter}")
            lines.append(value)
            lines.append(delimiter)
        else:
            lines.append(f"{key}={value}")
    with output_path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def _run_update_detailed(
    *,
    repo_root: pathlib.Path,
    work_dir: pathlib.Path,
    upstream_repo: str = DEFAULT_UPSTREAM_REPO,
    tag: str = "",
    release_json: pathlib.Path | None = None,
    target_branch: str = "develop",
    pr_body_out: pathlib.Path | None = None,
    github_output: pathlib.Path | None = None,
    step_summary: pathlib.Path | None = None,
    require_all_in_checksums_file: bool = False,
    allow_downgrade: bool = False,
    dry_run: bool = False,
    github_token: str | None = None,
    workflow_run_url: str | None = None,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[ReleaseInfo, list[VerifiedBinary], bool, ProvenanceAlerts]:
    upstream = validate_upstream_repo(upstream_repo)
    requested_tag = validate_tag(tag)
    branch = validate_target_branch(target_branch)

    protected_blobs = [repo_root / spec.blob_relpath for spec in BINARY_SPECS]
    protected_manifest = repo_root / MANIFEST_RELPATH
    validate_output_file_paths(
        (
            ("--pr-body-out", pr_body_out),
            ("--step-summary", step_summary),
            ("--github-output", github_output),
        ),
        protected_blobs=protected_blobs,
        protected_manifest=protected_manifest,
    )

    existing_manifest = load_provenance_manifest(repo_root)

    if release_json is not None:
        release_data = load_release_metadata_file(release_json)
    else:
        release_data = fetch_release_metadata(
            upstream,
            requested_tag,
            github_token=github_token,
            opener=opener,
        )

    if release_data.get("draft"):
        raise UpdaterError("Refusing to use a draft go-zenon release")

    resolved_tag = validate_tag(str(release_data.get("tag_name") or ""))
    if not resolved_tag:
        raise UpdaterError("Release metadata is missing tag_name")
    if requested_tag and resolved_tag != requested_tag:
        raise UpdaterError(
            f"Requested tag {requested_tag!r} does not match resolved release tag {resolved_tag!r}"
        )

    html_url = validate_release_html_url(str(release_data.get("html_url") or ""), upstream)
    release_name = _sanitize_inline_text(release_data.get("name"), default=resolved_tag) or resolved_tag
    published_at = _sanitize_inline_text(release_data.get("published_at"), default="unknown") or "unknown"
    prerelease = bool(release_data.get("prerelease", False))
    if prerelease and not requested_tag:
        raise UpdaterError(
            f"Refusing to use pre-release {resolved_tag!r} without an explicit --tag"
        )

    raw_immutable = release_data.get("immutable")
    immutable: bool | None = raw_immutable if type(raw_immutable) is bool else None
    target_commitish = _sanitize_inline_text(release_data.get("target_commitish"), default=None)

    tag_commit: str | None = None
    if release_json is not None:
        pre_resolved = release_data.get("_resolved_tag_commit")
        if pre_resolved is not None and pre_resolved != "":
            tag_commit = validate_git_commit_sha(pre_resolved, label="_resolved_tag_commit")
    else:
        tag_commit = fetch_tag_commit(
            upstream,
            resolved_tag,
            github_token=github_token,
            opener=opener,
        )

    raw_assets = release_data.get("assets")
    if not isinstance(raw_assets, list):
        raise UpdaterError("Release metadata is missing assets list")
    assets_by_name: dict[str, dict[str, Any]] = {}
    for entry in raw_assets:
        if isinstance(entry, dict) and isinstance(entry.get("name"), str):
            assets_by_name[entry["name"]] = entry

    work_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix="libznn-update-",
        dir=str(work_dir),
    ) as scratch_dir_name:
        run_scratch_dir = pathlib.Path(scratch_dir_name)
        downloads_dir = run_scratch_dir / "downloads"
        extracted_dir = run_scratch_dir / "extracted"
        downloads_dir.mkdir()
        extracted_dir.mkdir()

        checksums_map: dict[str, str] | None = None
        checksums_url: str | None = None
        checksums_sha256: str | None = None
        checksums_updated_at: str | None = None

        checksums_asset = assets_by_name.get(CHECKSUMS_ASSET_NAME)
        if checksums_asset is not None:
            checksums_url = validate_release_download_url(
                str(checksums_asset.get("browser_download_url") or ""),
                upstream,
            )
            checksums_updated_at = _sanitize_inline_text(
                checksums_asset.get("updated_at"), default=None
            )
            checksums_path = downloads_dir / CHECKSUMS_ASSET_NAME
            checksums_sha256 = download_release_file(
                checksums_url,
                checksums_path,
                upstream_repo=upstream,
                max_bytes=MAX_CHECKSUMS_BYTES,
                opener=opener,
            )
            checksums_gh_digest = parse_github_asset_digest(
                checksums_asset.get("digest"),
                CHECKSUMS_ASSET_NAME,
            )
            if checksums_gh_digest is not None and checksums_gh_digest != checksums_sha256:
                raise UpdaterError(
                    f"SHA-256 mismatch for {CHECKSUMS_ASSET_NAME} against GitHub release digest: "
                    f"expected {checksums_gh_digest}, got {checksums_sha256}"
                )
            try:
                checksums_text = checksums_path.read_text(encoding="utf-8")
            except UnicodeDecodeError as exc:
                raise UpdaterError(
                    f"Failed to decode {CHECKSUMS_ASSET_NAME} as UTF-8: {exc}"
                ) from exc
            checksums_map = parse_checksums_file(checksums_text)

        release_info = ReleaseInfo(
            upstream_repo=upstream,
            tag_name=resolved_tag,
            release_name=release_name,
            html_url=html_url,
            published_at=published_at,
            prerelease=prerelease,
            checksums_url=checksums_url,
            checksums_sha256=checksums_sha256,
            target_commitish=target_commitish,
            tag_commit=tag_commit,
            immutable=immutable,
            checksums_updated_at=checksums_updated_at,
        )

        verified_binaries: list[VerifiedBinary] = []
        staged_binaries: list[_StagedBinary] = []
        for spec in BINARY_SPECS:
            asset = assets_by_name.get(spec.asset_name)
            if asset is None:
                raise UpdaterError(
                    f"Required asset {spec.asset_name!r} not found in {upstream} release {resolved_tag}"
                )
            download_url = validate_release_download_url(
                str(asset.get("browser_download_url") or ""),
                upstream,
            )
            asset_updated_at = _sanitize_inline_text(asset.get("updated_at"), default=None)
            archive_path = downloads_dir / spec.asset_name
            actual_archive_sha256 = download_release_file(
                download_url,
                archive_path,
                upstream_repo=upstream,
                max_bytes=MAX_ARCHIVE_BYTES,
                opener=opener,
            )
            gh_digest = parse_github_asset_digest(asset.get("digest"), spec.asset_name)
            verification = verify_asset_checksum(
                asset_name=spec.asset_name,
                actual_sha256=actual_archive_sha256,
                checksums_map=checksums_map,
                github_digest_sha256=gh_digest,
                require_in_checksums_file=require_all_in_checksums_file,
            )

            extracted_path = extracted_dir / spec.member_name
            extracted_sha256 = extract_expected_binary(archive_path, spec, extracted_path)

            existing_blob = repo_root / spec.blob_relpath
            previous_sha256 = sha256_file(existing_blob) if existing_blob.is_file() else None

            verified = VerifiedBinary(
                spec=spec,
                download_url=download_url,
                archive_verification=verification,
                extracted_sha256=extracted_sha256,
                previous_sha256=previous_sha256,
                asset_updated_at=asset_updated_at,
            )
            verified_binaries.append(verified)
            staged_binaries.append(
                _StagedBinary(verified=verified, extracted_path=extracted_path)
            )

        alerts = evaluate_manifest_transition(
            existing_manifest,
            release_info,
            verified_binaries,
            allow_downgrade=allow_downgrade,
        )

        new_manifest = build_provenance_manifest(release_info, verified_binaries)
        new_manifest_text = serialize_provenance_manifest(new_manifest)
        existing_manifest_text = (
            protected_manifest.read_text(encoding="utf-8")
            if protected_manifest.is_file()
            else None
        )
        manifest_changed = existing_manifest_text != new_manifest_text
        blobs_changed = any(item.changed for item in verified_binaries)
        changed = blobs_changed or manifest_changed

        pr_title = build_pr_title(release_info, alerts=alerts)
        commit_message = build_commit_message(
            release_info,
            verified_binaries,
            alerts=alerts,
            manifest_changed=manifest_changed,
        )
        pr_body = build_pr_body(
            release_info,
            verified_binaries,
            target_branch=branch,
            workflow_run_url=workflow_run_url,
            alerts=alerts,
            manifest_changed=manifest_changed,
        )
        summary_md = build_step_summary(
            release_info,
            verified_binaries,
            target_branch=branch,
            changed=changed,
            dry_run=dry_run,
            alerts=alerts,
            manifest_changed=manifest_changed,
        )

        blobs_committed = changed and not dry_run
        stage_ctx: contextlib.AbstractContextManager[Any] = (
            _staged_blob_transaction(
                repo_root,
                staged_binaries,
                manifest_text=new_manifest_text,
                manifest_changed=manifest_changed,
            )
            if blobs_committed
            else contextlib.nullcontext()
        )
        with stage_ctx:
            try:
                if pr_body_out is not None:
                    pr_body_out.parent.mkdir(parents=True, exist_ok=True)
                    pr_body_out.write_text(pr_body, encoding="utf-8")

                if github_output is not None:
                    github_output.parent.mkdir(parents=True, exist_ok=True)
                    outputs = {
                        "changed": "true" if blobs_committed else "false",
                        "updates_detected": "true" if changed else "false",
                        "release_tag": release_info.tag_name,
                        "release_url": release_info.html_url,
                        "tag_commit": release_info.tag_commit or "",
                        "same_tag_rebuild": "true" if alerts.same_tag_rebuild else "false",
                        "downgrade": "true" if alerts.is_downgrade else "false",
                        "pr_title": pr_title,
                        "commit_message": commit_message,
                        "pr_body_path": str(pr_body_out) if pr_body_out is not None else "",
                    }
                    write_github_outputs(github_output, outputs)
            except OSError as exc:
                raise UpdaterError(f"Failed writing updater output file: {exc}") from exc

        if step_summary is not None:
            try:
                step_summary.parent.mkdir(parents=True, exist_ok=True)
                with step_summary.open("a", encoding="utf-8") as handle:
                    handle.write(summary_md)
            except OSError as exc:
                if blobs_committed:
                    print(
                        f"WARNING: failed to append step summary {step_summary}: {exc}",
                        file=sys.stderr,
                    )
                else:
                    raise UpdaterError(f"Failed writing step summary {step_summary}: {exc}") from exc

    return release_info, verified_binaries, changed, alerts


def run_update(
    *,
    repo_root: pathlib.Path,
    work_dir: pathlib.Path,
    upstream_repo: str = DEFAULT_UPSTREAM_REPO,
    tag: str = "",
    release_json: pathlib.Path | None = None,
    target_branch: str = "develop",
    pr_body_out: pathlib.Path | None = None,
    github_output: pathlib.Path | None = None,
    step_summary: pathlib.Path | None = None,
    require_all_in_checksums_file: bool = False,
    allow_downgrade: bool = False,
    dry_run: bool = False,
    github_token: str | None = None,
    workflow_run_url: str | None = None,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[ReleaseInfo, list[VerifiedBinary], bool]:
    release_info, verified_binaries, changed, _ = _run_update_detailed(
        repo_root=repo_root,
        work_dir=work_dir,
        upstream_repo=upstream_repo,
        tag=tag,
        release_json=release_json,
        target_branch=target_branch,
        pr_body_out=pr_body_out,
        github_output=github_output,
        step_summary=step_summary,
        require_all_in_checksums_file=require_all_in_checksums_file,
        allow_downgrade=allow_downgrade,
        dry_run=dry_run,
        github_token=github_token,
        workflow_run_url=workflow_run_url,
        opener=opener,
    )
    return release_info, verified_binaries, changed


def workflow_run_url_from_env() -> str | None:
    server = os.environ.get("GITHUB_SERVER_URL", "").strip()
    repo = os.environ.get("GITHUB_REPOSITORY", "").strip()
    run_id = os.environ.get("GITHUB_RUN_ID", "").strip()
    if server and repo and run_id:
        return f"{server}/{repo}/actions/runs/{run_id}"
    return None


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Fetch, verify, and stage embedded libznn binaries from go-zenon releases."
    )
    parser.add_argument(
        "--fetch-metadata-only",
        action="store_true",
        help="Only fetch GitHub release metadata JSON and write it to --metadata-out.",
    )
    parser.add_argument(
        "--metadata-out",
        type=pathlib.Path,
        default=None,
        help="Output path for --fetch-metadata-only.",
    )
    parser.add_argument(
        "--release-json",
        type=pathlib.Path,
        default=None,
        help="Use pre-fetched GitHub release metadata JSON instead of calling the API.",
    )
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=None,
        help="Path to the checked-out syrius repository.",
    )
    parser.add_argument(
        "--work-dir",
        type=pathlib.Path,
        default=None,
        help="Temporary working directory for downloads and extracted files.",
    )
    parser.add_argument(
        "--upstream-repo",
        default=DEFAULT_UPSTREAM_REPO,
        help=f"Upstream GitHub repository (default: {DEFAULT_UPSTREAM_REPO}).",
    )
    parser.add_argument(
        "--tag",
        default="",
        help="Specific go-zenon release tag; leave empty for latest release.",
    )
    parser.add_argument(
        "--target-branch",
        default="develop",
        help="Target branch for the update pull request (develop or master).",
    )
    parser.add_argument(
        "--pr-body-out",
        type=pathlib.Path,
        default=None,
        help="Path to write the generated pull request body Markdown.",
    )
    parser.add_argument(
        "--github-output",
        type=pathlib.Path,
        default=None,
        help="Path to GitHub Actions GITHUB_OUTPUT file.",
    )
    parser.add_argument(
        "--step-summary",
        type=pathlib.Path,
        default=None,
        help="Path to GitHub Actions GITHUB_STEP_SUMMARY file.",
    )
    parser.add_argument(
        "--require-all-in-checksums-file",
        action="store_true",
        help=f"Fail if any required asset is missing from {CHECKSUMS_ASSET_NAME}.",
    )
    parser.add_argument(
        "--allow-downgrade",
        action="store_true",
        help="Allow downgrading embedded libznn binaries to an older go-zenon release tag.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Verify release assets and compare hashes without modifying repository blobs.",
    )
    args = parser.parse_args(argv)

    if args.fetch_metadata_only:
        if args.metadata_out is None:
            print("ERROR: --metadata-out is required with --fetch-metadata-only", file=sys.stderr)
            return 1
        try:
            protected_blobs = (
                [args.repo_root / spec.blob_relpath for spec in BINARY_SPECS]
                if args.repo_root is not None
                else ()
            )
            protected_manifest = (
                args.repo_root / MANIFEST_RELPATH if args.repo_root is not None else None
            )
            validate_output_file_paths(
                (("--metadata-out", args.metadata_out),),
                protected_blobs=protected_blobs,
                protected_manifest=protected_manifest,
            )
            upstream = validate_upstream_repo(args.upstream_repo)
            requested_tag = validate_tag(args.tag)
            token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
            payload = fetch_release_metadata(
                upstream,
                requested_tag,
                github_token=token,
            )
            if not payload.get("draft"):
                resolved_tag = validate_tag(str(payload.get("tag_name") or ""))
                if resolved_tag:
                    payload["_resolved_tag_commit"] = fetch_tag_commit(
                        upstream,
                        resolved_tag,
                        github_token=token,
                    )
            args.metadata_out.parent.mkdir(parents=True, exist_ok=True)
            args.metadata_out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        except (UpdaterError, OSError) as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            return 1
        print(f"Wrote release metadata to {args.metadata_out}")
        return 0

    if args.repo_root is None or args.work_dir is None:
        print("ERROR: --repo-root and --work-dir are required", file=sys.stderr)
        return 1

    try:
        release_info, verified, changed, alerts = _run_update_detailed(
            repo_root=args.repo_root,
            work_dir=args.work_dir,
            upstream_repo=args.upstream_repo,
            tag=args.tag,
            release_json=args.release_json,
            target_branch=args.target_branch,
            pr_body_out=args.pr_body_out,
            github_output=args.github_output,
            step_summary=args.step_summary,
            require_all_in_checksums_file=args.require_all_in_checksums_file,
            allow_downgrade=args.allow_downgrade,
            dry_run=args.dry_run,
            github_token=os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN"),
            workflow_run_url=workflow_run_url_from_env(),
        )
    except UpdaterError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    in_github_actions = os.environ.get("GITHUB_ACTIONS") == "true"

    def _emit_warning(message: str) -> None:
        if in_github_actions:
            print(f"::warning::{message}")
        else:
            print(f"WARNING: {message}", file=sys.stderr)

    print(f"Verified go-zenon release {release_info.tag_name} ({release_info.html_url})")
    if release_info.prerelease:
        _emit_warning(
            f"Upstream release {release_info.tag_name} is marked as a pre-release."
        )
    if alerts.is_downgrade:
        _emit_warning(
            f"Forced downgrade of embedded libznn from "
            f"{alerts.previous_tag or 'unknown'} to {release_info.tag_name}."
        )
    if alerts.same_tag_rebuild:
        _emit_warning(
            f"Same-tag rebuild detected for {release_info.tag_name}: "
            f"{'; '.join(alerts.same_tag_rebuild_reasons)}."
        )
    if alerts.commitish_mismatch:
        _emit_warning(
            f"Release target_commitish ({release_info.target_commitish}) "
            f"differs from resolved tag commit ({release_info.tag_commit})."
        )
    for asset_name, updated_at in alerts.late_updated_assets:
        _emit_warning(
            f"Release asset {asset_name} was updated at {updated_at}, "
            f"after release published_at ({release_info.published_at})."
        )
    for item in verified:
        state = "UPDATED" if item.changed else "UNCHANGED"
        print(
            f"  - {item.spec.blob_relpath}: {state} "
            f"(extracted={item.extracted_sha256}, archive={item.archive_verification.actual_sha256})"
        )
        if item.archive_verification.checksums_file_sha256 is None:
            source_plain = item.archive_verification.source_description.replace("`", "")
            _emit_warning(f"Asset {item.spec.asset_name} verified via {source_plain}.")
    if changed and args.dry_run:
        print("Dry run enabled: repository blobs were not modified.")
    elif changed:
        print("Staged updated libznn binaries and provenance manifest in repository.")
    else:
        print("All embedded libznn binaries and provenance manifest are already up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
