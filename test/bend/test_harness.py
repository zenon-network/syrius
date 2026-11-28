"""Unit tests for the Syrius Bend verification harness (test/bend/run.py)."""

from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import run  # noqa: E402
import specs  # noqa: E402


class ProofBannerTests(unittest.TestCase):
    def test_proof_passed_requires_zero_exit_and_clean_banner(self) -> None:
        self.assertTrue(run.proof_passed(0, "ALL PROOFS CHECK\n"))
        # Bend exit-0 gotcha: must reject when SOME PROOFS FAIL appears!
        self.assertFalse(run.proof_passed(0, "SOME PROOFS FAIL\n"))
        self.assertFalse(
            run.proof_passed(0, "ALL PROOFS CHECK\nSOME PROOFS FAIL\n")
        )
        self.assertFalse(run.proof_passed(1, "ALL PROOFS CHECK\n"))
        self.assertFalse(run.proof_passed(0, ""))


class StaticAuditTests(unittest.TestCase):
    def test_clean_source_and_local_imports(self) -> None:
        src = (
            "import Base\n"
            "import ./model.bend as M\n"
            'def hint() -> String:\n  "is ? safe inside strings?"\n'
            "# comment with @unsafe and ?TODO ignored\n"
        )
        imports = run.audit_bend_source(src, "sample.bend")
        self.assertEqual(imports, ["./model.bend"])

    def test_rejects_unsafe_annotation(self) -> None:
        with self.assertRaisesRegex(ValueError, "@unsafe"):
            run.audit_bend_source("@unsafe\ndef loop(n: Nat) -> Nat: loop(n)\n", "bad.bend")

    def test_rejects_unsafe_sugar(self) -> None:
        with self.assertRaisesRegex(ValueError, "def\\?"):
            run.audit_bend_source("def loop?(n: Nat) -> Nat: loop(n)\n", "bad.bend")

    def test_rejects_todo_and_holes(self) -> None:
        for snippet in ("def p():\n  ?TODO\n", "def p():\n  ?goal\n", "def p():\n  ?\n"):
            with self.subTest(snippet=snippet):
                with self.assertRaisesRegex(ValueError, "unfinished"):
                    run.audit_bend_source(snippet, "hole.bend")

    def test_rejects_foreign_and_nonlocal_imports(self) -> None:
        with self.assertRaisesRegex(ValueError, "foreign"):
            run.audit_bend_source('def fx() -> IO(Unit):\n  import "./fx.c"\n', "fx.bend")
        with self.assertRaisesRegex(ValueError, "nonlocal"):
            run.audit_bend_source("import 0xdeadbeef/main.bend as P\n", "pkg.bend")


class InventoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "test/bend/common").mkdir(parents=True)
        (self.root / "test/bend/dom_a").mkdir(parents=True)
        (self.root / "test/bend_conformance").mkdir(parents=True)

        (self.root / "test/bend/common/nat.bend").write_text(
            "import Base\nlaw zero_eq:\n  {0n == 0n : Nat}\ndef zero_eq():\n  {==}\n"
        )
        (self.root / "test/bend/dom_a/model.bend").write_text(
            "import Base\ndef ok() -> Bool:\n  True{}\n"
        )
        (self.root / "test/bend/dom_a/LAWS.bend").write_text(
            "import Base\nimport ./model.bend as M\nlaw ok_true:\n  {M.ok() == True{} : Bool}\n"
        )
        (self.root / "test/bend/dom_a/PROOF.bend").write_text(
            "import Base\nimport ./LAWS.bend as Laws\ndef Laws.ok_true():\n  {==}\n"
        )
        (self.root / "LAWS.bend").write_text(
            "import Base\nimport ./test/bend/dom_a/model.bend as A\nlaw root_ok:\n  {A.ok() == True{} : Bool}\n"
        )
        (self.root / "PROOF.bend").write_text(
            "import Base\nimport ./LAWS.bend as Laws\nimport ./test/bend/dom_a/PROOF.bend as DomA\ndef Laws.root_ok():\n  {==}\n"
        )
        (self.root / "test/bend_conformance/dom_a_test.dart").write_text(
            "void main() {}\n"
        )
        self.manifest = {
            "schema": 1,
            "areas": [
                {
                    "area": "dom_a",
                    "domain": "dom_a",
                    "contract": "ok is always true",
                    "laws": ["dom_a.ok_true", "root.root_ok"],
                    "evidence": [
                        {
                            "file": "test/bend_conformance/dom_a_test.dart",
                            "kind": "conformance",
                        }
                    ],
                }
            ],
        }
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))

    def test_valid_inventory(self) -> None:
        res = run.check_inventory(self.root, domains=("dom_a",))
        self.assertEqual(res["total_laws"], 2)
        self.assertEqual(res["conformance_files"], ["test/bend_conformance/dom_a_test.dart"])

    def test_missing_proof_fails(self) -> None:
        (self.root / "test/bend/dom_a/PROOF.bend").write_text(
            "import Base\nimport ./LAWS.bend as Laws\n"
        )
        with self.assertRaisesRegex(ValueError, "mismatch"):
            run.check_inventory(self.root, domains=("dom_a",))

    def test_orphaned_bend_file_fails(self) -> None:
        (self.root / "test/bend/dom_a/unused.bend").write_text("import Base\n")
        with self.assertRaisesRegex(ValueError, "outside the proof graph"):
            run.check_inventory(self.root, domains=("dom_a",))

    def test_unlinked_law_fails(self) -> None:
        self.manifest["areas"][0]["laws"] = ["dom_a.ok_true"]
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        with self.assertRaisesRegex(ValueError, "not linked"):
            run.check_inventory(self.root, domains=("dom_a",))

    def test_missing_evidence_file_fails(self) -> None:
        (self.root / "test/bend_conformance/dom_a_test.dart").unlink()
        with self.assertRaisesRegex(ValueError, "missing Dart evidence"):
            run.check_inventory(self.root, domains=("dom_a",))

    def test_scoped_inventory_audits_selected_domains_without_root_manifest(self) -> None:
        (self.root / "LAWS.bend").unlink()
        (self.root / "PROOF.bend").unlink()
        (self.root / "test/bend/coverage.json").unlink()
        (self.root / "test/bend_conformance/dom_a_conformance_test.dart").write_text(
            "void main() {}\n"
        )
        res = run.check_scoped_inventory(self.root, domains=("dom_a",))
        self.assertEqual(res["total_laws"], 1)
        self.assertEqual(
            res["conformance_files"],
            ["test/bend_conformance/dom_a_conformance_test.dart"],
        )
        # Full inventory must still reject missing manifest / root PROOF.bend.
        with self.assertRaisesRegex(ValueError, "missing coverage inventory"):
            run.check_inventory(self.root, domains=("dom_a",))

    def test_oracle_ops_and_model_only_validation_passes(self) -> None:
        self.manifest["areas"][0]["oracle_ops"] = ["op_ok"]
        self.manifest["areas"][0]["model_only_laws"] = {
            "dom_a.ok_true": "model-only invariant",
        }
        self.manifest["areas"][0]["normative_target_laws"] = {
            "dom_a.ok_true": "normative target subset",
        }
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        res = run.check_inventory(
            self.root,
            domains=("dom_a",),
            expected_oracle_ops={"dom_a": {"op_ok"}},
        )
        self.assertEqual(res["oracle_ops_by_domain"], {"dom_a": ["op_ok"]})
        self.assertEqual(res["model_only_laws"], {"dom_a": ["dom_a.ok_true"]})
        self.assertEqual(res["normative_target_laws"], {"dom_a": ["dom_a.ok_true"]})

        # List form for model_only_laws and normative_target_laws is also accepted.
        self.manifest["areas"][0]["model_only_laws"] = ["dom_a.ok_true"]
        self.manifest["areas"][0]["normative_target_laws"] = ["dom_a.ok_true"]
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        res2 = run.check_inventory(
            self.root,
            domains=("dom_a",),
            expected_oracle_ops={"dom_a": {"op_ok"}},
        )
        self.assertEqual(res2["normative_target_laws"], {"dom_a": ["dom_a.ok_true"]})

    def test_oracle_ops_mismatch_or_missing_fails(self) -> None:
        # Missing oracle_ops when specs.py emits ops for this domain.
        with self.assertRaisesRegex(ValueError, "missing required oracle_ops"):
            run.check_inventory(
                self.root,
                domains=("dom_a",),
                expected_oracle_ops={"dom_a": {"op_ok"}},
            )

        # Extra/missing ops relative to specs.py.
        self.manifest["areas"][0]["oracle_ops"] = ["op_other"]
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        with self.assertRaisesRegex(ValueError, "oracle_ops mismatch"):
            run.check_inventory(
                self.root,
                domains=("dom_a",),
                expected_oracle_ops={"dom_a": {"op_ok"}},
            )

        # Duplicate ops.
        self.manifest["areas"][0]["oracle_ops"] = ["op_ok", "op_ok"]
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        with self.assertRaisesRegex(ValueError, "duplicate entries in oracle_ops"):
            run.check_inventory(
                self.root,
                domains=("dom_a",),
                expected_oracle_ops={"dom_a": {"op_ok"}},
            )

    def test_model_only_unknown_law_fails(self) -> None:
        self.manifest["areas"][0]["oracle_ops"] = ["op_ok"]
        self.manifest["areas"][0]["model_only_laws"] = ["dom_a.does_not_exist"]
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        with self.assertRaisesRegex(ValueError, "model_only_laws references undeclared"):
            run.check_inventory(
                self.root,
                domains=("dom_a",),
                expected_oracle_ops={"dom_a": {"op_ok"}},
            )

    def test_normative_target_must_be_subset_of_model_only(self) -> None:
        self.manifest["areas"][0]["oracle_ops"] = ["op_ok"]
        self.manifest["areas"][0]["model_only_laws"] = {}
        self.manifest["areas"][0]["normative_target_laws"] = {
            "dom_a.ok_true": "cannot be normative without being model-only",
        }
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        with self.assertRaisesRegex(
            ValueError, "normative_target_laws must be a subset of model_only_laws"
        ):
            run.check_inventory(
                self.root,
                domains=("dom_a",),
                expected_oracle_ops={"dom_a": {"op_ok"}},
            )

        # Unknown law in normative_target_laws also fails.
        self.manifest["areas"][0]["normative_target_laws"] = ["dom_a.nonexistent"]
        (self.root / "test/bend/coverage.json").write_text(json.dumps(self.manifest))
        with self.assertRaisesRegex(
            ValueError, "normative_target_laws references undeclared"
        ):
            run.check_inventory(
                self.root,
                domains=("dom_a",),
                expected_oracle_ops={"dom_a": {"op_ok"}},
            )

    def test_repo_coverage_inventory_passes_with_live_oracle_ops(self) -> None:
        res = run.check_inventory(
            run.ROOT, expected_oracle_ops=run.oracle_ops_by_domain()
        )
        self.assertEqual(res["total_laws"], 398)
        self.assertEqual(
            sum(len(ops) for ops in res["oracle_ops_by_domain"].values()), 107
        )


class OracleRenderingTests(unittest.TestCase):
    def test_render_oracle_uses_named_parallel_let_and_envelope_fields(self) -> None:
        cases = [
            specs.OracleCase("c0", "op_nat", {"x": 0}, "M.f(0n)", kind="nat"),
            specs.OracleCase("c1", "op_u32", {"x": 1}, "M.g(1)", kind="u32"),
            specs.OracleCase("c2", "op_bool", {"flag": True}, "M.h(True{})", kind="bool"),
            specs.OracleCase("c3", "op_str", {"s": "a"}, '"ok"', kind="string"),
            specs.OracleCase("c4", "op_raw", {}, "_fmt()", kind="raw_json"),
            specs.OracleCase("c5", "op_nat", {"x": 5}, "M.f(5n)", kind="nat"),
        ]
        src = run.render_oracle_source({"../../../test/bend/dom/model.bend": "M"}, cases)
        self.assertIn("c0 c1 c2 c3 = _chunk_0() _chunk_1() _chunk_2() _chunk_3()", src)
        self.assertIn("def _jbool(+b: Bool) -> String:", src)
        self.assertIn("def _chunk_0() -> String:", src)
        self.assertIn("def _chunk_3() -> String:", src)
        self.assertIn("Nat.show(M.f(0n))", src)
        self.assertIn("U32.show(M.g(1))", src)
        self.assertIn("_jbool(M.h(True{}))", src)
        self.assertIn('\\"expected\\":', src)
        self.assertNotIn("c0 c1 = (", src)

    def test_depth_and_seed_deterministically_vary_oracle_cases(self) -> None:
        by_domain = {s.domain: s for s in specs.ORACLE_SPECS}

        # Same (depth, seed) is 100% deterministic across all domains.
        for dom, spec in by_domain.items():
            c_a = spec.cases_fn(2, 1)
            c_b = spec.cases_fn(2, 1)
            self.assertEqual(c_a, c_b, f"{dom} cases must be deterministic")

        # Increasing depth strictly increases generated sequence/sample coverage.
        d1_total = sum(len(s.cases_fn(1, 1)) for s in specs.ORACLE_SPECS)
        d2_total = sum(len(s.cases_fn(2, 1)) for s in specs.ORACLE_SPECS)
        d3_total = sum(len(s.cases_fn(3, 1)) for s in specs.ORACLE_SPECS)
        self.assertLess(d1_total, d2_total)
        self.assertLess(d2_total, d3_total)

        # Varying seed at fixed depth deterministically varies sampled inputs.
        for dom in ("amounts", "wallet_lifecycle", "tx_pipeline", "node_sync", "plasma_staking"):
            s1 = [(c.op, c.args, c.expr) for c in by_domain[dom].cases_fn(2, 1)]
            s2 = [(c.op, c.args, c.expr) for c in by_domain[dom].cases_fn(2, 2)]
            self.assertNotEqual(s1, s2, f"{dom} must vary with seed")

    def test_oracle_ops_by_domain_covers_all_domains_and_is_depth_invariant(self) -> None:
        d1 = run.oracle_ops_by_domain(depth=1, seed=1)
        d3 = run.oracle_ops_by_domain(depth=3, seed=1)
        self.assertEqual(set(d1.keys()), set(run.DOMAINS))
        self.assertEqual(d1, d3)
        for dom, ops in d1.items():
            self.assertTrue(ops, f"{dom} must emit at least one oracle op")


class FlutterMachineParserTests(unittest.TestCase):
    def _events(self, *objs: dict[str, object]) -> str:
        return "\n".join(json.dumps(o) for o in objs)

    def test_passes_clean_run(self) -> None:
        root = Path("/repo")
        ndjson = self._events(
            {"type": "suite", "suite": {"id": 1, "path": "/repo/test/bend_conformance/a_test.dart"}},
            {"type": "testStart", "test": {"id": 1, "suiteID": 1, "name": "loading /repo/test/bend_conformance/a_test.dart"}},
            {"type": "testDone", "testID": 1, "result": "success", "skipped": False, "hidden": True},
            {"type": "testStart", "test": {"id": 2, "suiteID": 1, "name": "checks law"}},
            {"type": "testDone", "testID": 2, "result": "success", "skipped": False, "hidden": False},
            {"type": "done", "success": True},
        )
        res = run.parse_flutter_machine_events(
            ndjson,
            required_files=("test/bend_conformance/a_test.dart",),
            root=root,
        )
        self.assertEqual(res["passed"], 1)

    def test_rejects_skipped_test(self) -> None:
        ndjson = self._events(
            {"type": "suite", "suite": {"id": 1, "path": "test/bend_conformance/a_test.dart"}},
            {"type": "testStart", "test": {"id": 2, "suiteID": 1, "name": "skipped law"}},
            {"type": "testDone", "testID": 2, "result": "success", "skipped": True, "hidden": False},
            {"type": "done", "success": True},
        )
        with self.assertRaisesRegex(RuntimeError, "must not skip"):
            run.parse_flutter_machine_events(ndjson)

    def test_rejects_zero_tests(self) -> None:
        ndjson = self._events({"type": "done", "success": True})
        with self.assertRaisesRegex(RuntimeError, "0 tests"):
            run.parse_flutter_machine_events(ndjson)

    def test_rejects_failed_test(self) -> None:
        ndjson = self._events(
            {"type": "suite", "suite": {"id": 1, "path": "test/bend_conformance/a_test.dart"}},
            {"type": "testStart", "test": {"id": 2, "suiteID": 1, "name": "broken law"}},
            {"type": "testDone", "testID": 2, "result": "failure", "skipped": False, "hidden": False},
            {"type": "done", "success": False},
        )
        with self.assertRaisesRegex(RuntimeError, "failed"):
            run.parse_flutter_machine_events(ndjson)


class FaultClassificationAndStagingTests(unittest.TestCase):
    def test_classify_model_fault(self) -> None:
        self.assertEqual(
            run.classify_model_fault(
                1, "SOME PROOFS FAIL\nLocation: Laws.foo_bar\n", "foo_bar"
            ),
            "caught",
        )
        self.assertEqual(
            run.classify_model_fault(0, "ALL PROOFS CHECK\n", "foo_bar"),
            "MISSED",
        )
        self.assertEqual(
            run.classify_model_fault(
                1, "SOME PROOFS FAIL\nLocation: Laws.other_law\n", "foo_bar"
            ),
            "ERROR",
        )

    def test_classify_dart_fault(self) -> None:
        self.assertEqual(
            run.classify_dart_fault(1, "BEND_MISMATCH plasma args=[252000]\n"),
            "caught",
        )
        self.assertEqual(run.classify_dart_fault(0, "All tests passed!\n"), "MISSED")
        self.assertEqual(
            run.classify_dart_fault(1, "Error: Expected ';' after this.\n"),
            "ERROR",
        )
        self.assertEqual(
            run.classify_dart_fault(
                1, "BEND_MISMATCH x\nFailed to load test/foo_test.dart\n"
            ),
            "ERROR",
        )

    def test_stage_dart_mutant_isolates_live_tree_and_symlinks_siblings(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            dest = Path(tmp) / "mut"
            (root / ".dart_tool").mkdir(parents=True)
            (root / "lib/utils").mkdir(parents=True)
            (root / "lib/embedded_node/blobs").mkdir(parents=True)
            (root / "test").mkdir(parents=True)
            (root / "pubspec.yaml").write_text("name: sample\n")
            (root / ".dart_tool/package_config.json").write_text("{}\n")
            (root / ".dart_tool/package_graph.json").write_text("{}\n")
            (root / ".dart_tool/hooks_runner").mkdir(parents=True)
            live_file = root / "lib/utils/sample.dart"
            live_file.write_text("int f() => 1;\n")
            (root / "lib/utils/other.dart").write_text("int g() => 2;\n")

            run.stage_dart_mutant_workspace(
                root, dest, "lib/utils/sample.dart", "=> 1;", "=> 2;"
            )
            self.assertEqual(live_file.read_text(), "int f() => 1;\n")
            self.assertEqual((dest / "lib/utils/sample.dart").read_text(), "int f() => 2;\n")
            self.assertTrue((dest / "lib/embedded_node").is_symlink())
            self.assertTrue((dest / "lib/utils/other.dart").is_symlink())
            self.assertFalse((dest / ".dart_tool/hooks_runner").exists())


if __name__ == "__main__":
    unittest.main()
