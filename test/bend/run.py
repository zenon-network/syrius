#!/usr/bin/env python3
"""Syrius Bend formal verification, oracle, conformance, and mutation gate.

Uses Python 3 standard library only. Runs Bend checks inside the pinned
containerized toolchain (with optional host binary override for ``--check-only``
while always running ``--verdict`` in the Lean verdict container).
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent

if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import specs as bend_specs  # noqa: E402

DOMAINS: tuple[str, ...] = bend_specs.DOMAINS
DEFAULT_BEND_IMAGE = "syrius-bend:2.0.40"
DEFAULT_VERDICT_IMAGE = "syrius-bend:2.0.40-verdict"
ALLOWED_CHECKS = frozenset({
    "inventory",
    "proof",
    "verdict",
    "oracle",
    "conformance",
    "model-mutations",
    "dart-mutations",
    "harness-tests",
})


def proof_passed(returncode: int, output: str) -> bool:
    """Return True iff Bend accepted every proof without failure.

    Bend can occasionally exit 0 even when a proof fails, so callers must check
    both exit code and verdict banners.
    """
    return (
        returncode == 0
        and "ALL PROOFS CHECK" in output
        and "SOME PROOFS FAIL" not in output
    )


def replace_once(source: str, old: str, new: str) -> str:
    """Replace an exact single occurrence of ``old`` with ``new``."""
    count = source.count(old)
    if count != 1:
        raise ValueError(
            f"fault target must occur exactly once, found {count}: {old!r}"
        )
    return source.replace(old, new, 1)


def strip_comments_and_strings(source: str) -> str:
    """Strip Bend line comments and double/single-quoted string/char literals."""
    out: list[str] = []
    for raw_line in source.splitlines():
        line_chars: list[str] = []
        i = 0
        in_quote: str | None = None
        length = len(raw_line)
        while i < length:
            ch = raw_line[i]
            if in_quote is not None:
                if ch == "\\" and i + 1 < length:
                    i += 2
                    continue
                if ch == in_quote:
                    in_quote = None
                i += 1
                continue
            if ch == "#":
                break
            if ch in ('"', "'"):
                in_quote = ch
                line_chars.append(" ")
                i += 1
                continue
            line_chars.append(ch)
            i += 1
        out.append("".join(line_chars))
    return "\n".join(out)


def audit_bend_source(source: str, path_label: str) -> list[str]:
    """Audit Bend source for unsafe/unfinished/foreign constructs and return local imports."""
    comment_free = "\n".join(
        line.split("#", 1)[0] for line in source.splitlines()
    )
    if re.search(r"^\s*import\s+[\"']", comment_free, re.M):
        raise ValueError(f"foreign import forbidden in proof graph: {path_label}")

    cleaned = strip_comments_and_strings(source)
    if re.search(r"@unsafe\b", cleaned):
        raise ValueError(f"@unsafe forbidden in proof graph: {path_label}")
    if re.search(r"^\s*def\s+[A-Za-z_][\w.]*\?\s*\(", cleaned, re.M):
        raise ValueError(f"unsafe def? sugar forbidden in proof graph: {path_label}")
    if re.search(r"(?:^|[\s(\[{,:;])\?(?:[A-Za-z_]\w*)?(?=$|[\s)\]},;])", cleaned, re.M):
        raise ValueError(f"unfinished ? hole or ?TODO forbidden: {path_label}")

    imports: list[str] = []
    for target in re.findall(r"^\s*import\s+(\S+)", comment_free, re.M):
        if target == "Base":
            continue
        if not target.startswith(".") or not target.endswith(".bend"):
            raise ValueError(
                f"unreviewed nonlocal proof import {target!r} in {path_label}"
            )
        imports.append(target)
    return imports


def check_laws_match_proofs(
    laws_path: Path,
    proof_path: Path,
    *,
    label: str,
) -> list[str]:
    """Verify every ``law <name>:`` has an exact 1:1 ``def Laws.<name>(`` proof."""
    laws_src = "\n".join(
        line.split("#", 1)[0] for line in laws_path.read_text().splitlines()
    )
    proof_src = "\n".join(
        line.split("#", 1)[0] for line in proof_path.read_text().splitlines()
    )
    laws = re.findall(r"^law\s+(\w+):", laws_src, re.M)
    proofs = re.findall(r"^def\s+Laws\.(\w+)\(", proof_src, re.M)
    if not laws:
        raise ValueError(f"{label}: no laws declared in {laws_path}")
    if len(set(laws)) != len(laws):
        raise ValueError(f"{label}: duplicate law names in {laws_path}")
    if len(set(proofs)) != len(proofs):
        raise ValueError(f"{label}: duplicate proof definitions in {proof_path}")
    missing = sorted(set(laws) - set(proofs))
    extra = sorted(set(proofs) - set(laws))
    if missing or extra:
        raise ValueError(
            f"{label}: laws/proofs mismatch (missing={missing}, extra={extra})"
        )
    return laws


def discover_maintained_bend_files(root: Path) -> set[str]:
    """Return relative POSIX paths of maintained ``.bend`` files in the repo."""
    bend_files: set[str] = set()
    for name in ("LAWS.bend", "PROOF.bend"):
        candidate = root / name
        if candidate.is_file():
            bend_files.add(name)
    bend_dir = root / "test/bend"
    if bend_dir.is_dir():
        for path in bend_dir.rglob("*.bend"):
            rel = path.relative_to(root).as_posix()
            if "/.scratch/" in f"/{rel}" or rel.startswith("test/bend/.scratch/"):
                continue
            bend_files.add(rel)
    return bend_files


def oracle_ops_by_domain(
    specs_tuple: tuple[bend_specs.OracleSpec, ...] | None = None,
    *,
    depth: int = 1,
    seed: int = 1,
) -> dict[str, set[str]]:
    """Return the exact set of emitted oracle ``op`` names per domain from specs.py."""
    items = bend_specs.ORACLE_SPECS if specs_tuple is None else specs_tuple
    return {
        spec.domain: {case.op for case in spec.cases_fn(depth, seed)}
        for spec in items
    }


def _extract_law_names(
    raw: object,
    *,
    field: str,
    area_name: str,
) -> set[str]:
    """Extract unique non-empty law names from a list or dict field in coverage.json."""
    if raw is None:
        return set()
    if isinstance(raw, list):
        if not all(isinstance(item, str) and item.strip() for item in raw):
            raise ValueError(
                f"area {area_name!r} has invalid {field} (expected non-empty strings)"
            )
        if len(raw) != len(set(raw)):
            raise ValueError(f"area {area_name!r} has duplicate entries in {field}")
        return set(raw)
    if isinstance(raw, dict):
        if not all(
            isinstance(k, str)
            and k.strip()
            and isinstance(v, str)
            and v.strip()
            for k, v in raw.items()
        ):
            raise ValueError(
                f"area {area_name!r} has invalid {field} mapping "
                "(expected non-empty string keys and rationale values)"
            )
        return set(raw.keys())
    raise ValueError(
        f"area {area_name!r} has invalid {field} (expected list or object)"
    )


def validate_area_oracle_and_model_only(
    area: dict[str, object],
    *,
    area_laws: set[str],
    expected_oracle_ops: dict[str, set[str]] | None = None,
) -> tuple[set[str], set[str], set[str]]:
    """Validate per-area ``oracle_ops``, ``model_only_laws``, and ``normative_target_laws``."""
    area_name = str(area.get("area", "<unknown>"))
    domain = area.get("domain")

    declared_ops: set[str] | None = None
    if "oracle_ops" in area:
        raw_ops = area["oracle_ops"]
        if not isinstance(raw_ops, list) or not all(
            isinstance(op, str) and op.strip() for op in raw_ops
        ):
            raise ValueError(
                f"area {area_name!r} has invalid oracle_ops "
                "(expected list of non-empty strings)"
            )
        if len(raw_ops) != len(set(raw_ops)):
            raise ValueError(f"area {area_name!r} has duplicate entries in oracle_ops")
        declared_ops = set(raw_ops)

    if (
        isinstance(domain, str)
        and expected_oracle_ops is not None
        and domain in expected_oracle_ops
    ):
        expected = expected_oracle_ops[domain]
        if declared_ops is None:
            raise ValueError(
                f"area {area_name!r} (domain {domain!r}) missing required oracle_ops"
            )
        if declared_ops != expected:
            missing = sorted(expected - declared_ops)
            extra = sorted(declared_ops - expected)
            raise ValueError(
                f"area {area_name!r} oracle_ops mismatch with specs.py: "
                f"missing={missing}, extra={extra}"
            )

    model_only = _extract_law_names(
        area.get("model_only_laws"),
        field="model_only_laws",
        area_name=area_name,
    )
    unknown_model_only = sorted(model_only - area_laws)
    if unknown_model_only:
        raise ValueError(
            f"area {area_name!r} model_only_laws references undeclared law(s): "
            f"{unknown_model_only}"
        )

    normative = _extract_law_names(
        area.get("normative_target_laws"),
        field="normative_target_laws",
        area_name=area_name,
    )
    unknown_normative = sorted(normative - area_laws)
    if unknown_normative:
        raise ValueError(
            f"area {area_name!r} normative_target_laws references undeclared law(s): "
            f"{unknown_normative}"
        )
    not_in_model_only = sorted(normative - model_only)
    if not_in_model_only:
        raise ValueError(
            f"area {area_name!r} normative_target_laws must be a subset of "
            f"model_only_laws: {not_in_model_only}"
        )

    legacy_model_only = _extract_law_names(
        area.get("model_only_or_normative_laws"),
        field="model_only_or_normative_laws",
        area_name=area_name,
    )
    unknown_legacy = sorted(legacy_model_only - area_laws)
    if unknown_legacy:
        raise ValueError(
            f"area {area_name!r} model_only_or_normative_laws references "
            f"undeclared law(s): {unknown_legacy}"
        )

    return declared_ops or set(), model_only, normative


def check_inventory(
    root: Path = ROOT,
    *,
    domains: tuple[str, ...] = DOMAINS,
    expected_oracle_ops: dict[str, set[str]] | None = None,
) -> dict[str, object]:
    """Stage 1: Verify coverage manifest, proof import graph, and 1:1 law/proof parity."""
    coverage_path = root / "test/bend/coverage.json"
    if not coverage_path.is_file():
        raise ValueError(f"missing coverage inventory: {coverage_path}")
    manifest = json.loads(coverage_path.read_text())
    if manifest.get("schema") != 1 or not manifest.get("areas"):
        raise ValueError("invalid or empty test/bend/coverage.json")

    root_laws_path = root / "LAWS.bend"
    root_proof_path = root / "PROOF.bend"
    if not root_laws_path.is_file() or not root_proof_path.is_file():
        raise ValueError("root LAWS.bend and PROOF.bend must both exist")

    all_laws: dict[str, str] = {}
    root_laws = check_laws_match_proofs(
        root_laws_path, root_proof_path, label="root"
    )
    for law in root_laws:
        all_laws[f"root.{law}"] = "root"
        all_laws[law] = "root"

    entry_proofs: list[Path] = [root_proof_path]
    common_nat = root / "test/bend/common/nat.bend"
    if common_nat.is_file():
        entry_proofs.append(common_nat)

    domain_law_counts: dict[str, int] = {"root": len(root_laws)}
    qualified_laws: set[str] = {f"root.{law}" for law in root_laws}
    bare_laws: set[str] = set(root_laws)

    for domain in domains:
        ddir = root / "test/bend" / domain
        dlaws_path = ddir / "LAWS.bend"
        dproof_path = ddir / "PROOF.bend"
        if not dlaws_path.is_file() or not dproof_path.is_file():
            raise ValueError(
                f"domain {domain!r} missing LAWS.bend or PROOF.bend under {ddir}"
            )
        dlaws = check_laws_match_proofs(
            dlaws_path, dproof_path, label=f"domain:{domain}"
        )
        domain_law_counts[domain] = len(dlaws)
        for law in dlaws:
            qualified_laws.add(f"{domain}.{law}")
            bare_laws.add(law)
        entry_proofs.append(dproof_path)

    # Walk full transitive import graph and audit every reachable Bend file.
    reached: set[str] = set()
    pending: list[Path] = list(entry_proofs)
    resolved_root = root.resolve()
    while pending:
        current = pending.pop().resolve()
        if not current.is_file():
            raise ValueError(f"broken Bend import target: {current}")
        try:
            rel = current.relative_to(resolved_root).as_posix()
        except ValueError as exc:
            raise ValueError(f"Bend import escapes repository root: {current}") from exc
        if rel in reached:
            continue
        reached.add(rel)
        imports = audit_bend_source(current.read_text(), rel)
        for target in imports:
            pending.append(current.parent / target)

    maintained = discover_maintained_bend_files(root)
    orphaned = sorted(maintained - reached)
    if orphaned:
        raise ValueError(f"Bend modules outside the proof graph: {orphaned}")

    # Validate coverage areas, domain coverage, law links, oracle ops, and Dart evidence files.
    declared_domains: set[str] = set()
    oracle_checked_domains: set[str] = set()
    linked_laws: set[str] = set()
    conformance_files: list[str] = []
    oracle_ops_map: dict[str, list[str]] = {}
    model_only_by_area: dict[str, list[str]] = {}
    normative_by_area: dict[str, list[str]] = {}
    for area in manifest["areas"]:
        area_name = area.get("area")
        if not area_name or not area.get("contract") or not area.get("laws"):
            raise ValueError(f"incomplete area entry in coverage.json: {area_name!r}")
        if not area.get("evidence") and not area.get("checks"):
            raise ValueError(f"area {area_name!r} has no evidence or checks")
        unknown_checks = set(area.get("checks", [])) - ALLOWED_CHECKS
        if unknown_checks:
            raise ValueError(
                f"unknown checks in area {area_name!r}: {sorted(unknown_checks)}"
            )
        if area.get("domain"):
            declared_domains.add(area["domain"])
        for dom in area.get("domains", []):
            declared_domains.add(dom)
        raw_area_laws = area["laws"]
        if len(raw_area_laws) != len(set(raw_area_laws)):
            raise ValueError(f"area {area_name!r} has duplicate entries in laws")
        for law in raw_area_laws:
            if law not in qualified_laws and law not in bare_laws:
                raise ValueError(f"unknown law {law!r} referenced in area {area_name!r}")
            linked_laws.add(law)
        area_ops, area_model_only, area_normative = validate_area_oracle_and_model_only(
            area,
            area_laws=set(raw_area_laws),
            expected_oracle_ops=expected_oracle_ops,
        )
        if isinstance(area.get("domain"), str):
            dom_name = area["domain"]
            if area_ops:
                oracle_ops_map[dom_name] = sorted(area_ops)
            if expected_oracle_ops is not None and dom_name in expected_oracle_ops:
                oracle_checked_domains.add(dom_name)
        if area_model_only:
            model_only_by_area[area_name] = sorted(area_model_only)
        if area_normative:
            normative_by_area[area_name] = sorted(area_normative)
        for ev in area.get("evidence", []):
            ev_file = ev.get("file")
            if not ev_file or not (root / ev_file).is_file():
                raise ValueError(f"missing Dart evidence file in {area_name!r}: {ev}")
            if ev.get("kind") == "conformance" or ev_file.startswith(
                "test/bend_conformance/"
            ):
                conformance_files.append(ev_file)

    missing_domains = sorted(set(domains) - declared_domains)
    if missing_domains:
        raise ValueError(f"domains missing from coverage.json: {missing_domains}")

    if expected_oracle_ops is not None:
        missing_oracle_domains = sorted(
            (set(expected_oracle_ops) & set(domains)) - oracle_checked_domains
        )
        if missing_oracle_domains:
            raise ValueError(
                "domains with oracle specs missing dedicated domain area in "
                f"coverage.json: {missing_oracle_domains}"
            )

    # Every law declared across root + domains must be referenced in coverage.json.
    unlinked: list[str] = []
    for qlaw in sorted(qualified_laws):
        bare = qlaw.split(".", 1)[1]
        if qlaw not in linked_laws and bare not in linked_laws:
            unlinked.append(qlaw)
    if unlinked:
        raise ValueError(f"declared laws not linked in coverage.json: {unlinked}")

    return {
        "manifest": manifest,
        "bend_files": sorted(reached),
        "domain_law_counts": domain_law_counts,
        "total_laws": sum(domain_law_counts.values()),
        "conformance_files": sorted(set(conformance_files)),
        "oracle_ops_by_domain": oracle_ops_map,
        "model_only_laws": model_only_by_area,
        "normative_target_laws": normative_by_area,
    }


def parse_only_domains(only_args: list[str]) -> tuple[tuple[str, ...], bool]:
    """Parse repeatable/comma-separated ``--only`` domain selectors."""
    if not only_args:
        return DOMAINS, False
    requested: list[str] = []
    for entry in only_args:
        requested.extend(p.strip() for p in entry.split(",") if p.strip())
    unknown = sorted(set(requested) - set(DOMAINS))
    if unknown:
        raise ValueError(f"unknown --only domain(s): {unknown}")
    return tuple(dict.fromkeys(requested)), True


def check_scoped_inventory(
    root: Path = ROOT,
    *,
    domains: tuple[str, ...],
) -> dict[str, object]:
    """Scoped Stage 1 static audit for ``--only`` before root manifest lands."""
    if not domains:
        raise ValueError("check_scoped_inventory requires at least one domain")

    entry_proofs: list[Path] = []
    common_nat = root / "test/bend/common/nat.bend"
    if common_nat.is_file():
        entry_proofs.append(common_nat)

    domain_law_counts: dict[str, int] = {}
    conformance_files: list[str] = []
    scoped_files: set[str] = set()
    if common_nat.is_file():
        scoped_files.add("test/bend/common/nat.bend")

    for domain in domains:
        ddir = root / "test/bend" / domain
        dlaws_path = ddir / "LAWS.bend"
        dproof_path = ddir / "PROOF.bend"
        if not dlaws_path.is_file() or not dproof_path.is_file():
            raise ValueError(
                f"domain {domain!r} missing LAWS.bend or PROOF.bend under {ddir}"
            )
        dlaws = check_laws_match_proofs(
            dlaws_path, dproof_path, label=f"domain:{domain}"
        )
        domain_law_counts[domain] = len(dlaws)
        entry_proofs.append(dproof_path)

        for path in ddir.rglob("*.bend"):
            rel = path.relative_to(root).as_posix()
            if "/.scratch/" in f"/{rel}":
                continue
            scoped_files.add(rel)

        conf_rel = f"test/bend_conformance/{domain}_conformance_test.dart"
        if (root / conf_rel).is_file():
            conformance_files.append(conf_rel)

    reached: set[str] = set()
    pending: list[Path] = list(entry_proofs)
    resolved_root = root.resolve()
    while pending:
        current = pending.pop().resolve()
        if not current.is_file():
            raise ValueError(f"broken Bend import target: {current}")
        try:
            rel = current.relative_to(resolved_root).as_posix()
        except ValueError as exc:
            raise ValueError(f"Bend import escapes repository root: {current}") from exc
        if rel in reached:
            continue
        reached.add(rel)
        imports = audit_bend_source(current.read_text(), rel)
        for target in imports:
            pending.append(current.parent / target)

    orphaned = sorted(scoped_files - reached)
    if orphaned:
        raise ValueError(f"Bend modules outside scoped proof graph: {orphaned}")

    return {
        "manifest": None,
        "bend_files": sorted(reached),
        "domain_law_counts": domain_law_counts,
        "total_laws": sum(domain_law_counts.values()),
        "conformance_files": sorted(set(conformance_files)),
    }


def balanced_concat(parts: list[str]) -> str:
    """Combine Bend String expressions into a balanced binary ``++`` tree."""
    if not parts:
        return '""'
    if len(parts) == 1:
        return parts[0]
    mid = len(parts) // 2
    return f"({balanced_concat(parts[:mid])} ++ {balanced_concat(parts[mid:])})"


def _case_to_bend_pieces(case: bend_specs.OracleCase, is_first: bool) -> list[str]:
    prefix = ("" if is_first else ",") + json.dumps(
        {"id": case.id},
        separators=(",", ":"),
    )[:-1] + ',"expected":'
    if case.kind == "nat":
        val_expr = f"Nat.show({case.expr})"
    elif case.kind == "u32":
        val_expr = f"U32.show({case.expr})"
    elif case.kind == "bool":
        val_expr = f"_jbool({case.expr})"
    elif case.kind == "string":
        val_expr = f'("\\"" ++ ({case.expr}) ++ "\\"")'
    elif case.kind == "raw_json":
        val_expr = f"({case.expr})"
    else:
        raise ValueError(f"unsupported OracleCase kind: {case.kind!r}")
    return [json.dumps(prefix), val_expr, json.dumps("}")]


def render_oracle_source(
    imports: dict[str, str],
    cases: list[bend_specs.OracleCase],
    *,
    helpers: str = "",
) -> str:
    """Render a parallelized Bend oracle file evaluating ``cases`` into a JSON array.

    Uses up to 4 balanced sub-chunk defs combined with Bend parallel-let
    (named function calls on RHS as required by Bend 2.0.40) and balanced
    binary ``++`` trees inside each sub-chunk.
    """
    if not cases:
        raise ValueError("render_oracle_source requires at least one case")
    lines: list[str] = ["import Base"]
    for rel_path, alias in imports.items():
        lines.append(f"import {rel_path} as {alias}")
    lines.append("")
    lines.append("def _jbool(+b: Bool) -> String:")
    lines.append("  match b:")
    lines.append('    case False{}: "false"')
    lines.append('    case True{}: "true"')
    lines.append("")
    if helpers.strip():
        lines.append(helpers.strip())
        lines.append("")

    # Split into 1, 2, or 4 balanced sub-chunks for parallel-let evaluation.
    if len(cases) >= 4:
        num_buckets = 4
    elif len(cases) >= 2:
        num_buckets = 2
    else:
        num_buckets = 1

    buckets: list[list[tuple[int, bend_specs.OracleCase]]] = [
        [] for _ in range(num_buckets)
    ]
    for idx, case in enumerate(cases):
        bucket_idx = (idx * num_buckets) // len(cases)
        buckets[bucket_idx].append((idx, case))

    for b_idx, bucket in enumerate(buckets):
        pieces: list[str] = []
        for global_idx, case in bucket:
            pieces.extend(_case_to_bend_pieces(case, is_first=(global_idx == 0)))
        lines.append(f"def _chunk_{b_idx}() -> String:")
        lines.append(f"  {balanced_concat(pieces)}")
        lines.append("")

    lines.append("def main() -> String:")
    if num_buckets == 4:
        lines.append("  c0 c1 c2 c3 = _chunk_0() _chunk_1() _chunk_2() _chunk_3()")
        lines.append('  "[" ++ (c0 ++ (c1 ++ (c2 ++ (c3 ++ "]"))))')
    elif num_buckets == 2:
        lines.append("  c0 c1 = _chunk_0() _chunk_1()")
        lines.append('  "[" ++ (c0 ++ (c1 ++ "]"))')
    else:
        lines.append('  "[" ++ (_chunk_0() ++ "]")')
    lines.append("")
    return "\n".join(lines)


def parse_flutter_machine_events(
    ndjson_text: str,
    *,
    required_files: tuple[str, ...] = (),
    root: Path = ROOT,
) -> dict[str, object]:
    """Parse ``flutter test --machine`` NDJSON and fail on any skip/error/0-tests."""
    suites: dict[int, str] = {}
    started: dict[int, dict[str, object]] = {}
    passed: list[str] = []
    failed: list[str] = []
    skipped: list[str] = []
    errors: list[str] = []
    done_success: bool | None = None
    passed_suite_paths: set[str] = set()

    for raw_line in ndjson_text.splitlines():
        line = raw_line.strip()
        if not line.startswith("{"):
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(event, dict):
            continue
        etype = event.get("type")
        if etype == "suite":
            suite = event.get("suite") or {}
            sid = suite.get("id")
            spath = suite.get("path") or ""
            if isinstance(sid, int):
                suites[sid] = str(spath)
        elif etype == "testStart":
            test = event.get("test") or {}
            tid = test.get("id")
            if isinstance(tid, int):
                started[tid] = test
        elif etype == "error":
            errors.append(str(event.get("error", "unknown error")))
        elif etype == "testDone":
            tid = event.get("testID")
            hidden = bool(event.get("hidden", False))
            test_info = started.get(tid, {}) if isinstance(tid, int) else {}
            tname = str(test_info.get("name", f"test#{tid}"))
            if hidden or tname.startswith("loading "):
                continue
            suite_id = test_info.get("suiteID")
            suite_path = suites.get(suite_id, "") if isinstance(suite_id, int) else ""
            if event.get("skipped"):
                skipped.append(tname)
            elif event.get("result") == "success":
                passed.append(tname)
                if suite_path:
                    try:
                        rel = Path(suite_path).resolve().relative_to(root.resolve()).as_posix()
                    except ValueError:
                        rel = suite_path
                    passed_suite_paths.add(rel)
            else:
                failed.append(f"{tname} ({event.get('result')})")
        elif etype == "done":
            done_success = bool(event.get("success", False))

    if failed:
        raise RuntimeError(f"Dart conformance tests failed: {failed}")
    if errors:
        raise RuntimeError(f"Dart conformance errors: {errors[:5]}")
    if skipped:
        raise RuntimeError(f"Dart conformance tests must not skip: {skipped}")
    if not passed:
        raise RuntimeError("Dart conformance run executed 0 tests")
    if done_success is not True:
        raise RuntimeError(f"flutter test --machine did not report done.success=true ({done_success})")

    missing_files = [
        req for req in required_files if req not in passed_suite_paths
    ]
    if missing_files:
        raise RuntimeError(
            f"required conformance test files did not run and pass: {missing_files}"
        )
    return {
        "passed": len(passed),
        "suites": sorted(passed_suite_paths),
    }


def classify_model_fault(
    returncode: int,
    output: str,
    expected_law: str,
) -> str:
    """Classify a Bend model-mutant proof check result as caught/MISSED/ERROR."""
    if proof_passed(returncode, output):
        return "MISSED"
    if (
        returncode in (0, 1)
        and "SOME PROOFS FAIL" in output
        and "ALL PROOFS CHECK" not in output
        and f"Location: Laws.{expected_law}" in output
    ):
        return "caught"
    return "ERROR"


def classify_dart_fault(returncode: int, output: str) -> str:
    """Classify a Dart source-mutant test run as caught/MISSED/ERROR."""
    if returncode == 0:
        return "MISSED"
    fatal_markers = (
        "Failed to load",
        "Error: ",
        "Compilation failed",
        "Unable to spawn isolate",
        "TimeoutException",
        "test timed out",
        "No tests ran",
    )
    if any(marker in output for marker in fatal_markers):
        return "ERROR"
    if "BEND_MISMATCH" in output:
        return "caught"
    return "ERROR"


def stage_dart_mutant_workspace(
    root: Path,
    dest: Path,
    source_path: str,
    old: str,
    new: str,
) -> Path:
    """Create a lightweight isolated Dart workspace mutating only ``source_path``.

    Symlinks unchanged sibling directories (avoiding copying large native blobs)
    and copies ``.dart_tool/package_config.json`` + ``package_graph.json`` so
    ``flutter test --no-pub`` resolves ``package:zenon_syrius_wallet_flutter``
    against the mutated copy without touching the live working tree.
    """
    rel_src = Path(source_path)
    if rel_src.is_absolute() or rel_src.parts[0] != "lib":
        raise ValueError(f"Dart fault source_path must be under lib/: {source_path}")
    live_src = root / rel_src
    if not live_src.is_file():
        raise ValueError(f"missing Dart fault source file: {live_src}")

    mutated_text = replace_once(live_src.read_text(), old, new)

    dest.mkdir(parents=True, exist_ok=True)
    for cfg in ("pubspec.yaml", "pubspec.lock", "dart_test.yaml", "l10n.yaml"):
        src_cfg = root / cfg
        if src_cfg.is_file():
            shutil.copyfile(src_cfg, dest / cfg)

    dart_tool_dst = dest / ".dart_tool"
    dart_tool_dst.mkdir(parents=True, exist_ok=True)
    for meta in ("package_config.json", "package_graph.json"):
        src_meta = root / ".dart_tool" / meta
        if not src_meta.is_file():
            raise RuntimeError(
                f"missing {src_meta}; run `flutter pub get` before Stage 6"
            )
        shutil.copyfile(src_meta, dart_tool_dst / meta)
    for opt_meta in ("version",):
        src_opt = root / ".dart_tool" / opt_meta
        if src_opt.is_file():
            shutil.copyfile(src_opt, dart_tool_dst / opt_meta)

    for top_link in ("assets", "test", "drift_schemas"):
        src_dir = root / top_link
        if src_dir.exists():
            os.symlink(src_dir, dest / top_link)

    # Walk down lib/ along rel_src, symlinking all untouched siblings.
    cur_src_dir = root / "lib"
    cur_dst_dir = dest / "lib"
    cur_dst_dir.mkdir(parents=True, exist_ok=True)
    sub_parts = rel_src.parts[1:]
    for depth, part in enumerate(sub_parts):
        is_leaf = depth == len(sub_parts) - 1
        for sibling in cur_src_dir.iterdir():
            if sibling.name == part:
                continue
            os.symlink(sibling, cur_dst_dir / sibling.name)
        if is_leaf:
            target_file = cur_dst_dir / part
            target_file.write_text(mutated_text)
        else:
            cur_src_dir = cur_src_dir / part
            cur_dst_dir = cur_dst_dir / part
            cur_dst_dir.mkdir(parents=True, exist_ok=True)
    return dest


class Gate:
    """Orchestrates all 6 stages of the Syrius Bend verification gate."""

    def __init__(self, args: argparse.Namespace) -> None:
        self.root = ROOT
        self.verdict = not args.no_verdict and os.environ.get("VERDICT", "1") != "0"
        self.run_mutations = not args.no_mutations
        self.workers = args.workers
        self.depth = args.depth
        self.seed = args.seed
        self.domains, self.filtered = parse_only_domains(args.only)

        self.bend_bin = os.environ.get("BEND_BIN")
        self.bend_image = os.environ.get("BEND_IMAGE", DEFAULT_BEND_IMAGE)
        self.verdict_image = os.environ.get(
            "BEND_VERDICT_IMAGE", DEFAULT_VERDICT_IMAGE
        )

        scratch = self.root / ".bend-work"
        scratch.mkdir(exist_ok=True)
        scratch.chmod(0o755)
        self.work = Path(tempfile.mkdtemp(prefix="run-", dir=scratch))
        self.work.chmod(0o755)
        (self.work / "00-settings.log").write_text(
            f"DOMAINS={','.join(self.domains)}\n"
            f"VERDICT={int(self.verdict)}\n"
            f"MUTATIONS={int(self.run_mutations)}\n"
            f"DEPTH={self.depth}\n"
            f"SEED={self.seed}\n"
            f"WORKERS={self.workers}\n"
        )

    def ensure_docker_images(self) -> None:
        need_base = self.bend_bin is None
        need_verdict = self.verdict
        if not need_base and not need_verdict:
            return
        if not shutil.which("docker"):
            raise RuntimeError(
                "docker is required to run pinned Bend containers (and --verdict)"
            )
        if need_base or need_verdict:
            inspect = subprocess.run(
                ["docker", "image", "inspect", self.bend_image],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if inspect.returncode != 0:
                self._run_logged(
                    "build-bend-image",
                    [
                        "docker",
                        "build",
                        "-t",
                        self.bend_image,
                        "-f",
                        str(HERE / "Dockerfile"),
                        str(HERE),
                    ],
                    timeout=1200,
                )
        if need_verdict:
            inspect_v = subprocess.run(
                ["docker", "image", "inspect", self.verdict_image],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if inspect_v.returncode != 0:
                self._run_logged(
                    "build-verdict-image",
                    [
                        "docker",
                        "build",
                        "--build-arg",
                        f"BASE={self.bend_image}",
                        "-t",
                        self.verdict_image,
                        "-f",
                        str(HERE / "Dockerfile.verdict"),
                        str(HERE),
                    ],
                    timeout=1800,
                )

    def _run_logged(
        self,
        log_name: str,
        cmd: list[str],
        *,
        cwd: Path | None = None,
        env: dict[str, str] | None = None,
        timeout: int = 600,
        allow_fail: bool = False,
    ) -> tuple[int, str]:
        log_path = self.work / f"{log_name}.log"
        try:
            proc = subprocess.run(
                cmd,
                cwd=cwd or self.root,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                timeout=timeout,
            )
            output = proc.stdout
            rc = proc.returncode
        except subprocess.TimeoutExpired as exc:
            raw = exc.stdout or ""
            output = raw.decode(errors="replace") if isinstance(raw, bytes) else raw
            log_path.write_text(output + f"\n[TIMEOUT after {timeout}s]\n")
            if allow_fail:
                return 124, output + "\ntest timed out\n"
            raise RuntimeError(f"{log_name} timed out after {timeout}s ({log_path})") from exc

        log_path.write_text(output)
        if rc != 0 and not allow_fail:
            raise RuntimeError(
                f"{log_name} failed (exit {rc}, see {log_path}):\n{output[-6000:]}"
            )
        return rc, output

    def run_bend(
        self,
        log_name: str,
        rel_path: str,
        *,
        mode: str = "check",
        timeout: int = 300,
    ) -> tuple[int, str]:
        """Run Bend on ``rel_path`` (relative to repo root).

        ``mode`` is ``"check"`` (`--check-only`), ``"verdict"`` (`--verdict`),
        or ``"run"`` (evaluate ``main``).
        """
        extra_args: list[str] = []
        if mode == "check":
            extra_args = ["--check-only"]
        elif mode == "verdict":
            extra_args = ["--verdict"]
        elif mode != "run":
            raise ValueError(f"unknown Bend mode: {mode!r}")

        if mode != "verdict" and self.bend_bin:
            return self._run_logged(
                log_name,
                [self.bend_bin, rel_path, *extra_args],
                timeout=timeout,
                allow_fail=True,
            )

        image = self.verdict_image if mode == "verdict" else self.bend_image
        container_name = f"syrius-bend-{uuid.uuid4().hex[:12]}"
        cmd = [
            "docker",
            "run",
            "--rm",
            "--name",
            container_name,
            "--network",
            "none",
            "--read-only",
            "--cap-drop",
            "ALL",
            "--security-opt",
            "no-new-privileges",
            "--pids-limit",
            "256",
            "--memory",
            "2g",
            "--tmpfs",
            "/tmp:rw,nosuid,size=256m",
            "--mount",
            f"type=bind,source={self.root},target=/work,readonly",
            image,
            rel_path,
            *extra_args,
        ]
        try:
            return self._run_logged(
                log_name, cmd, timeout=timeout, allow_fail=True
            )
        finally:
            subprocess.run(
                ["docker", "rm", "-f", container_name],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=15,
            )

    def stage2_proofs(self) -> None:
        targets: list[tuple[str, str]] = [
            ("common-nat", "test/bend/common/nat.bend"),
        ]
        for domain in self.domains:
            targets.append((domain, f"test/bend/{domain}/PROOF.bend"))
        if not self.filtered:
            targets.append(("root", "PROOF.bend"))

        tasks: list[tuple[str, str, str]] = []
        for label, rel in targets:
            tasks.append((f"proof-{label}", rel, "check"))
            if self.verdict:
                tasks.append((f"verdict-{label}", rel, "verdict"))

        failures: list[str] = []
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=self.workers
        ) as pool:
            futures = {
                pool.submit(self.run_bend, log_name, rel, mode=mode): (
                    log_name,
                    rel,
                    mode,
                )
                for log_name, rel, mode in tasks
            }
            for fut in concurrent.futures.as_completed(futures):
                log_name, rel, mode = futures[fut]
                rc, out = fut.result()
                if not proof_passed(rc, out):
                    failures.append(
                        f"{rel} ({mode}) failed (exit {rc}):\n{out[-3000:]}"
                    )
        if failures:
            raise RuntimeError("Stage 2 proof failures:\n" + "\n---\n".join(failures))
        print(
            f"PASS Stage 2: {len(targets)} targets checked"
            + (" (+ Lean --verdict)" if self.verdict else " (verdict skipped)"),
            flush=True,
        )

    def stage3_oracle(self) -> tuple[Path | None, int]:
        selected_specs = [
            spec for spec in bend_specs.ORACLE_SPECS if spec.domain in self.domains
        ]
        if not selected_specs:
            print("SKIP Stage 3: no oracle specs configured yet", flush=True)
            return None, 0

        oracle_dir = self.work / "oracles"
        oracle_dir.mkdir(exist_ok=True)
        oracle_dir.chmod(0o755)

        jobs: list[tuple[str, str, Path, list[bend_specs.OracleCase]]] = []
        rel_prefix = os.path.relpath(self.root, oracle_dir).replace(os.sep, "/")

        for spec in selected_specs:
            cases = spec.cases_fn(self.depth, self.seed)
            if not cases:
                raise ValueError(f"oracle spec {spec.domain!r} produced 0 cases")
            seen_ids: set[str] = set()
            for case in cases:
                if case.id in seen_ids:
                    raise ValueError(
                        f"duplicate oracle case id {case.id!r} in domain {spec.domain!r}"
                    )
                seen_ids.add(case.id)
            resolved_imports = {
                f"{rel_prefix}/{path.lstrip('./')}": alias
                for path, alias in spec.imports.items()
            }
            for offset in range(0, len(cases), spec.chunk_size):
                chunk = cases[offset : offset + spec.chunk_size]
                source = render_oracle_source(
                    resolved_imports, chunk, helpers=spec.helpers
                )
                oracle_file = oracle_dir / f"oracle_{spec.domain}_{offset}.bend"
                oracle_file.write_text(source)
                oracle_file.chmod(0o644)
                jobs.append(
                    (spec.domain, f"oracle-{spec.domain}-{offset}", oracle_file, chunk)
                )

        results_by_idx: dict[int, list[dict[str, object]]] = {}

        def _eval_one(
            idx: int, name: str, path: Path, chunk: list[bend_specs.OracleCase]
        ) -> tuple[int, list[dict[str, object]]]:
            rel = path.relative_to(self.root).as_posix()
            rc, out = self.run_bend(name, rel, mode="run")
            if rc != 0 or "SOME PROOFS FAIL" in out:
                raise RuntimeError(f"Bend oracle {name} failed (exit {rc}):\n{out[-3000:]}")
            # Bend prints ALL PROOFS CHECK banner + quoted JSON string on the final line.
            lines = [ln.strip() for ln in out.splitlines() if ln.strip()]
            payload_line = lines[-1] if lines else ""
            raw_json = json.loads(payload_line)
            values = json.loads(raw_json) if isinstance(raw_json, str) else raw_json
            if not isinstance(values, list) or len(values) != len(chunk):
                raise ValueError(
                    f"Bend oracle {name} returned {len(values) if isinstance(values, list) else type(values)}, expected {len(chunk)}"
                )
            merged: list[dict[str, object]] = []
            for actual, expected_case in zip(values, chunk):
                if (
                    not isinstance(actual, dict)
                    or actual.get("id") != expected_case.id
                    or "expected" not in actual
                ):
                    raise ValueError(f"malformed oracle entry in {name}: {actual!r}")
                merged.append(
                    {
                        "id": expected_case.id,
                        "op": expected_case.op,
                        "args": expected_case.args,
                        "expected": actual["expected"],
                    }
                )
            return idx, merged

        with concurrent.futures.ThreadPoolExecutor(
            max_workers=self.workers
        ) as pool:
            futs = [
                pool.submit(_eval_one, idx, name, path, chunk)
                for idx, (_, name, path, chunk) in enumerate(jobs)
            ]
            for fut in concurrent.futures.as_completed(futs):
                idx, vals = fut.result()
                results_by_idx[idx] = vals

        domains_payload: dict[str, list[dict[str, object]]] = {
            spec.domain: [] for spec in selected_specs
        }
        total_vectors = 0
        for idx, (domain, _, _, _) in enumerate(jobs):
            vals = results_by_idx[idx]
            domains_payload[domain].extend(vals)
            total_vectors += len(vals)

        envelope = {
            "version": 1,
            "domains": domains_payload,
        }
        vectors_path = self.work / "vectors.json"
        vectors_path.write_text(json.dumps(envelope) + "\n")
        vectors_path.chmod(0o644)
        print(
            f"PASS Stage 3: {total_vectors} Bend oracle vectors generated across "
            f"{len(selected_specs)} domain(s) ({len(jobs)} parallel chunks)",
            flush=True,
        )
        return vectors_path, total_vectors

    def stage4_conformance(
        self,
        vectors_path: Path | None,
        required_files: list[str],
    ) -> None:
        conformance_dir = self.root / "test/bend_conformance"
        if not conformance_dir.is_dir() or not list(conformance_dir.glob("*_test.dart")):
            if required_files:
                raise RuntimeError(
                    f"coverage.json requires conformance tests {required_files}, but test/bend_conformance is empty"
                )
            print("SKIP Stage 4: no Dart conformance tests present yet", flush=True)
            return

        if not shutil.which("flutter"):
            raise RuntimeError("flutter is required for Stage 4 conformance tests")

        env = dict(os.environ)
        if vectors_path is not None:
            env["BEND_VECTORS"] = str(vectors_path.resolve())

        if self.filtered:
            scoped_files = [
                f"test/bend_conformance/{domain}_conformance_test.dart"
                for domain in self.domains
                if (
                    self.root / f"test/bend_conformance/{domain}_conformance_test.dart"
                ).is_file()
            ]
            target_args = scoped_files if scoped_files else required_files
            enforced_files = tuple(target_args)
            if not target_args:
                print(
                    f"SKIP Stage 4: no conformance tests present for {list(self.domains)}",
                    flush=True,
                )
                return
        else:
            target_args = ["test/bend_conformance"]
            enforced_files = tuple(required_files)

        cmd = [
            "flutter",
            "test",
            "--no-pub",
            "--tags",
            "bend",
            "--machine",
            *target_args,
        ]
        rc, out = self._run_logged(
            "conformance-dart", cmd, env=env, timeout=600, allow_fail=True
        )
        summary = parse_flutter_machine_events(
            out,
            required_files=enforced_files,
            root=self.root,
        )
        if rc != 0:
            raise RuntimeError(f"Stage 4 flutter test exited {rc}")
        print(
            f"PASS Stage 4: {summary['passed']} Dart<->Bend conformance tests passed across {len(summary['suites'])} suite(s)",
            flush=True,
        )

    def stage5_model_faults(self) -> None:
        faults = [f for f in bend_specs.MODEL_FAULTS if f.domain in self.domains]
        if not faults:
            print("SKIP Stage 5: no model faults configured yet", flush=True)
            return

        def _check_fault(fault: bend_specs.ModelFault) -> str:
            mut_root = self.work / f"mut-model-{fault.name}"
            mut_dom = mut_root / fault.domain
            mut_common = mut_root / "common"
            try:
                mut_root.mkdir(parents=True, exist_ok=True)
                mut_root.chmod(0o755)
                common_src = self.root / "test/bend/common"
                if common_src.is_dir():
                    shutil.copytree(common_src, mut_common)
                    mut_common.chmod(0o755)
                    for p in mut_common.rglob("*"):
                        p.chmod(0o755 if p.is_dir() else 0o644)
                shutil.copytree(self.root / "test/bend" / fault.domain, mut_dom)
                mut_dom.chmod(0o755)
                for p in mut_dom.rglob("*"):
                    p.chmod(0o755 if p.is_dir() else 0o644)

                target_file = mut_dom / fault.file
                target_file.write_text(
                    replace_once(target_file.read_text(), fault.old, fault.new)
                )
                target_file.chmod(0o644)

                rel_model = target_file.relative_to(self.root).as_posix()
                rc_m, out_m = self.run_bend(
                    f"mut-model-{fault.name}-typecheck", rel_model, mode="check"
                )
                if not proof_passed(rc_m, out_m):
                    raise RuntimeError(
                        f"model fault {fault.name!r} broke typecheck (malformed mutant):\n{out_m[-2000:]}"
                    )

                rel_proof = (mut_dom / "PROOF.bend").relative_to(self.root).as_posix()
                rc_p, out_p = self.run_bend(
                    f"mut-model-{fault.name}-proof", rel_proof, mode="check"
                )
                verdict = classify_model_fault(rc_p, out_p, fault.expected_law)
                if verdict != "caught":
                    raise RuntimeError(
                        f"model fault {fault.name!r} -> {verdict} (expected Location: Laws.{fault.expected_law}):\n{out_p[-2000:]}"
                    )
                return fault.name
            finally:
                shutil.rmtree(mut_root, ignore_errors=True)

        with concurrent.futures.ThreadPoolExecutor(
            max_workers=self.workers
        ) as pool:
            futs = [pool.submit(_check_fault, f) for f in faults]
            caught = [fut.result() for fut in concurrent.futures.as_completed(futs)]
        print(
            f"PASS Stage 5: {len(caught)}/{len(faults)} deliberate Bend model faults rejected",
            flush=True,
        )

    def stage6_dart_faults(self, vectors_path: Path | None) -> None:
        faults = [f for f in bend_specs.DART_FAULTS if f.domain in self.domains]
        if not faults:
            print("SKIP Stage 6: no Dart source faults configured yet", flush=True)
            return
        if not shutil.which("flutter"):
            raise RuntimeError("flutter is required for Stage 6 Dart mutations")

        env = dict(os.environ)
        if vectors_path is not None:
            env["BEND_VECTORS"] = str(vectors_path.resolve())

        def _check_dart_fault(fault: bend_specs.DartFault) -> str:
            mut_dir = self.work / f"mut-dart-{fault.name}"
            try:
                stage_dart_mutant_workspace(
                    self.root, mut_dir, fault.source_path, fault.old, fault.new
                )
                cmd = ["flutter", "test", "--no-pub", "--reporter", "expanded"]
                for tag in fault.extra_tags:
                    cmd.extend(["--tags", tag])
                if fault.test_name:
                    cmd.extend(["--name", fault.test_name])
                cmd.append(fault.test_file)
                rc, out = self._run_logged(
                    f"mut-dart-{fault.name}",
                    cmd,
                    cwd=mut_dir,
                    env=env,
                    timeout=300,
                    allow_fail=True,
                )
                verdict = classify_dart_fault(rc, out)
                if verdict != "caught":
                    raise RuntimeError(
                        f"Dart fault {fault.name!r} -> {verdict}:\n{out[-2500:]}"
                    )
                return fault.name
            finally:
                shutil.rmtree(mut_dir, ignore_errors=True)

        dart_workers = max(1, min(3, self.workers))
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=dart_workers
        ) as pool:
            futs = [pool.submit(_check_dart_fault, f) for f in faults]
            caught = [fut.result() for fut in concurrent.futures.as_completed(futs)]
        print(
            f"PASS Stage 6: {len(caught)}/{len(faults)} deliberate Dart source faults rejected",
            flush=True,
        )


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Syrius Bend formal verification, conformance, and mutation gate."
    )
    parser.add_argument(
        "--fast",
        action="store_true",
        help="Developer shortcut for --no-verdict --no-mutations.",
    )
    parser.add_argument(
        "--no-verdict",
        action="store_true",
        help="Skip Lean kernel --verdict checks (marks run as PARTIAL PASS).",
    )
    parser.add_argument(
        "--no-mutations",
        action="store_true",
        help="Skip Stage 5 model faults and Stage 6 Dart faults (PARTIAL PASS).",
    )
    parser.add_argument(
        "--only",
        action="append",
        default=[],
        help="Restrict checks to specific domain(s) (repeatable or comma-separated).",
    )
    parser.add_argument(
        "--inventory-only",
        action="store_true",
        help="Run Stage 1 static proof-graph and coverage inventory check only.",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=min(6, os.cpu_count() or 4),
        help="Maximum parallel worker threads.",
    )
    parser.add_argument(
        "--depth",
        type=int,
        default=int(os.environ.get("BEND_DEPTH", "3")),
        help="Exhaustive sequence depth bound (1..4).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=int(os.environ.get("BEND_SEED", "1")),
        help="Deterministic seed for sampled conformance histories.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)
    if args.fast:
        args.no_verdict = True
        args.no_mutations = True
    if not (1 <= args.depth <= 4):
        raise ValueError("--depth must be in 1..4")
    if args.seed < 1:
        raise ValueError("--seed must be >= 1")
    if args.workers < 1:
        raise ValueError("--workers must be >= 1")

    os.chdir(ROOT)
    selected_domains, filtered = parse_only_domains(args.only)
    has_full_manifest = (
        (ROOT / "test/bend/coverage.json").is_file()
        and (ROOT / "LAWS.bend").is_file()
        and (ROOT / "PROOF.bend").is_file()
    )
    if filtered and not has_full_manifest:
        inv = check_scoped_inventory(ROOT, domains=selected_domains)
        print(
            f"PASS Stage 1 (scoped --only): {inv['total_laws']} laws across "
            f"{len(inv['domain_law_counts'])} domain(s) "
            f"({len(inv['bend_files'])} audited .bend files)",
            flush=True,
        )
    else:
        inv = check_inventory(ROOT, expected_oracle_ops=oracle_ops_by_domain())
        print(
            f"PASS Stage 1: {inv['total_laws']} laws across {len(inv['domain_law_counts'])} suites "
            f"({len(inv['bend_files'])} audited .bend files)",
            flush=True,
        )
    if args.inventory_only:
        return 0

    gate = Gate(args)
    print(f"Logs: {gate.work.relative_to(ROOT)}", flush=True)
    gate.ensure_docker_images()
    gate.stage2_proofs()
    vectors_path, _ = gate.stage3_oracle()
    gate.stage4_conformance(vectors_path, list(inv["conformance_files"]))
    if gate.run_mutations:
        gate.stage5_model_faults()
        gate.stage6_dart_faults(vectors_path)

    partial = not gate.verdict or not gate.run_mutations or gate.filtered
    banner = "PARTIAL PASS" if partial else "PASS"
    print(f"{banner}: logs in {gate.work.relative_to(ROOT)}", flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, RuntimeError, OSError, subprocess.SubprocessError) as exc:
        print(f"BEND LAW GATE FAILED: {exc}", file=sys.stderr)
        sys.exit(1)
