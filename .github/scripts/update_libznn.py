#!/usr/bin/env python3
"""Fetch, verify, and stage embedded libznn binaries from zenon-network/go-zenon."""

from __future__ import annotations

import argparse
import contextlib
import dataclasses
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
ALLOWED_TARGET_BRANCHES = frozenset({"develop", "master"})

TAG_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+-]*$")
REPO_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
SHA256_HEX_PATTERN = re.compile(r"^[0-9a-f]{64}$")
CHECKSUM_LINE_PATTERN = re.compile(r"^([0-9a-fA-F]{64})[ \t]+\*?(.+)$")
GITHUB_DIGEST_PATTERN = re.compile(r"^sha256:([0-9a-fA-F]{64})$")
OUTPUT_KEY_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")

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

    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "syrius-libznn-updater",
    }
    if github_token and urllib.parse.urlsplit(url).netloc.lower() == "api.github.com":
        headers["Authorization"] = f"Bearer {github_token}"

    req = urllib.request.Request(url, headers=headers)
    active_opener = opener or _build_opener()
    raw: bytes | None = None
    last_exc: Exception | None = None

    for attempt in range(1, max_attempts + 1):
        try:
            with active_opener.open(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
                declared_len = _declared_content_length(resp)
                if declared_len is not None and declared_len > MAX_METADATA_BYTES:
                    raise UpdaterError(
                        f"GitHub Releases API response exceeded {MAX_METADATA_BYTES} bytes ({url})"
                    )
                raw = resp.read(MAX_METADATA_BYTES + 1)
                if len(raw) > MAX_METADATA_BYTES:
                    raise UpdaterError(
                        f"GitHub Releases API response exceeded {MAX_METADATA_BYTES} bytes ({url})"
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
            if exc.code not in {429, 500, 502, 503, 504} or attempt == max_attempts:
                raise UpdaterError(f"HTTP {exc.code} fetching {url}: {exc.reason}") from exc
        except (
            urllib.error.URLError,
            http.client.HTTPException,
            ConnectionError,
            TimeoutError,
            socket.timeout,
        ) as exc:
            last_exc = exc
            if attempt == max_attempts:
                raise UpdaterError(f"Network error fetching {url}: {exc}") from exc
        except OSError as exc:
            raise UpdaterError(f"Error reading GitHub Releases API response ({url}): {exc}") from exc
        sleep_s = (
            retry_backoff_seconds
            if retry_backoff_seconds is not None
            else min(2 ** (attempt - 1), 4)
        )
        if sleep_s > 0:
            time.sleep(sleep_s)

    if raw is None:
        raise UpdaterError(f"Failed fetching {url}: {last_exc}")

    try:
        payload = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise UpdaterError(f"Invalid JSON from GitHub Releases API ({url}): {exc}") from exc

    if not isinstance(payload, dict):
        raise UpdaterError("Unexpected GitHub Releases API payload type")
    return payload


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
    protected_paths: Sequence[pathlib.Path] = (),
) -> None:
    if path is None:
        return
    if path.exists() and path.is_dir():
        raise UpdaterError(f"{label} path is a directory, not a file: {path}")
    for protected in protected_paths:
        if _paths_alias(path, protected):
            raise UpdaterError(
                f"{label} path {path} must not refer to repository blob {protected}"
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
) -> Iterator[list[pathlib.Path]]:
    """Stage changed blobs with rollback if any replacement or post-stage write fails."""
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


def build_commit_message(
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
) -> str:
    lines = [
        f"chore: update embedded libznn to go-zenon {release.tag_name}",
        "",
        f"Upstream release: {release.html_url}",
        f"Published: {release.published_at}",
    ]
    if release.checksums_url and release.checksums_sha256:
        lines.append(
            f"Checksums file: {release.checksums_url} (sha256: {release.checksums_sha256})"
        )
    else:
        lines.append(f"Checksums file: not present in release ({CHECKSUMS_ASSET_NAME})")
    lines.extend(["", "Verified upstream release archives (SHA-256):"])
    for item in verified_binaries:
        source_plain = item.archive_verification.source_description.replace("`", "")
        lines.append(
            f"- {item.spec.asset_name}: {item.archive_verification.actual_sha256} ({source_plain})"
        )
        lines.append(f"  URL: {item.download_url}")
    lines.extend(["", "Extracted embedded library binaries (SHA-256):"])
    for item in verified_binaries:
        prev = item.previous_sha256 or "<missing>"
        status = "updated" if item.changed else "unchanged"
        lines.append(
            f"- {item.spec.blob_relpath}: {item.extracted_sha256} ({status}; previous: {prev})"
        )
    return "\n".join(lines)


def build_pr_body(
    release: ReleaseInfo,
    verified_binaries: Sequence[VerifiedBinary],
    *,
    target_branch: str,
    workflow_run_url: str | None = None,
) -> str:
    lines = [
        "## Summary",
        "",
        (
            f"Updates the embedded `libznn` binaries on `{target_branch}` to "
            f"[{release.upstream_repo} `{release.tag_name}`]({release.html_url}) "
            f"(published `{release.published_at}`)."
        ),
        "",
        "## Upstream release provenance",
        "",
        f"- **Repository:** `{release.upstream_repo}`",
        f"- **Release tag:** [`{release.tag_name}`]({release.html_url})",
        f"- **Published at:** `{release.published_at}`",
    ]
    if release.checksums_url and release.checksums_sha256:
        lines.append(
            f"- **Upstream checksums file:** [`{CHECKSUMS_ASSET_NAME}`]({release.checksums_url}) "
            f"(`{release.checksums_sha256}`)"
        )
    else:
        lines.append(f"- **Upstream checksums file:** not present in release")
    if workflow_run_url:
        lines.append(f"- **Workflow run:** {workflow_run_url}")

    lines.extend(
        [
            "",
            "### Verified release archives",
            "",
            "| Platform | Upstream asset | Archive SHA-256 | Verification source |",
            "|---|---|---|---|",
        ]
    )
    for item in verified_binaries:
        lines.append(
            f"| {item.spec.platform} "
            f"| [`{item.spec.asset_name}`]({item.download_url}) "
            f"| `{item.archive_verification.actual_sha256}` "
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
) -> str:
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

    lines = [
        f"## Embedded `libznn` update check (`{release.tag_name}`)",
        "",
        status_line,
        "",
        "| Platform | Upstream asset | Archive SHA-256 | Verification | Extracted SHA-256 | Status |",
        "|---|---|---|---|---|---|",
    ]
    for item in verified_binaries:
        state = "Updated" if item.changed else "Unchanged"
        lines.append(
            f"| {item.spec.platform} "
            f"| [`{item.spec.asset_name}`]({item.download_url}) "
            f"| `{item.archive_verification.actual_sha256}` "
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
    dry_run: bool = False,
    github_token: str | None = None,
    workflow_run_url: str | None = None,
    opener: urllib.request.OpenerDirector | None = None,
) -> tuple[ReleaseInfo, list[VerifiedBinary], bool]:
    upstream = validate_upstream_repo(upstream_repo)
    requested_tag = validate_tag(tag)
    branch = validate_target_branch(target_branch)

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
    release_name = re.sub(r"[\r\n`]+", " ", str(release_data.get("name") or resolved_tag)).strip()
    published_at = re.sub(r"[\r\n`]+", " ", str(release_data.get("published_at") or "unknown")).strip()
    prerelease = bool(release_data.get("prerelease", False))

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

        checksums_asset = assets_by_name.get(CHECKSUMS_ASSET_NAME)
        if checksums_asset is not None:
            checksums_url = validate_release_download_url(
                str(checksums_asset.get("browser_download_url") or ""),
                upstream,
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
            )
            verified_binaries.append(verified)
            staged_binaries.append(
                _StagedBinary(verified=verified, extracted_path=extracted_path)
            )

        changed = any(item.changed for item in verified_binaries)
        pr_title = f"chore: update embedded libznn to go-zenon {release_info.tag_name}"
        commit_message = build_commit_message(release_info, verified_binaries)
        pr_body = build_pr_body(
            release_info,
            verified_binaries,
            target_branch=branch,
            workflow_run_url=workflow_run_url,
        )
        summary_md = build_step_summary(
            release_info,
            verified_binaries,
            target_branch=branch,
            changed=changed,
            dry_run=dry_run,
        )

        protected_blobs = [repo_root / spec.blob_relpath for spec in BINARY_SPECS]
        _validate_output_file_path(pr_body_out, "--pr-body-out", protected_blobs)
        _validate_output_file_path(step_summary, "--step-summary", protected_blobs)
        _validate_output_file_path(github_output, "--github-output", protected_blobs)

        blobs_committed = changed and not dry_run
        stage_ctx: contextlib.AbstractContextManager[Any] = (
            _staged_blob_transaction(repo_root, staged_binaries)
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
                        "release_tag": release_info.tag_name,
                        "release_url": release_info.html_url,
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

    return release_info, verified_binaries, changed


def _workflow_run_url_from_env() -> str | None:
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
            upstream = validate_upstream_repo(args.upstream_repo)
            requested_tag = validate_tag(args.tag)
            payload = fetch_release_metadata(
                upstream,
                requested_tag,
                github_token=os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN"),
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
        release_info, verified, changed = run_update(
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
            dry_run=args.dry_run,
            github_token=os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN"),
            workflow_run_url=_workflow_run_url_from_env(),
        )
    except UpdaterError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    in_github_actions = os.environ.get("GITHUB_ACTIONS") == "true"
    print(f"Verified go-zenon release {release_info.tag_name} ({release_info.html_url})")
    for item in verified:
        state = "UPDATED" if item.changed else "UNCHANGED"
        print(
            f"  - {item.spec.blob_relpath}: {state} "
            f"(extracted={item.extracted_sha256}, archive={item.archive_verification.actual_sha256})"
        )
        if in_github_actions and item.archive_verification.checksums_file_sha256 is None:
            source_plain = item.archive_verification.source_description.replace("`", "")
            print(f"::warning::Asset {item.spec.asset_name} verified via {source_plain}.")
    if changed and args.dry_run:
        print("Dry run enabled: repository blobs were not modified.")
    elif changed:
        print("Staged updated libznn binaries in repository.")
    else:
        print("All embedded libznn binaries are already up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
