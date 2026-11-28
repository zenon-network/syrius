"""Declarative Bend oracle, model-fault, and Dart-fault specifications.

Keeping specs declarative separates domain catalogs from the verification engine
in ``test/bend/run.py``. Every ``expected`` value in ``vectors.json`` is
computed by executing real Bend on ``test/bend/<domain>/model.bend`` — never by
Python or Dart.
"""

from __future__ import annotations

from dataclasses import dataclass, field
import itertools
import random
from typing import Callable, Literal

DOMAINS: tuple[str, ...] = (
    "amounts",
    "wallet_lifecycle",
    "tx_pipeline",
    "node_sync",
    "wallet_connect",
    "wc_crash_safety",
    "plasma_staking",
    "pillars_sentinels",
    "tokens_zts",
    "p2p_htlc",
    "accelerator",
)


@dataclass(frozen=True)
class OracleCase:
    """One differential comparison input evaluated by real Bend."""

    id: str
    op: str
    args: dict[str, object]
    expr: str
    kind: Literal["nat", "u32", "bool", "string", "raw_json"] = "nat"


@dataclass(frozen=True)
class DomainOracleSpec:
    """Oracle vector generator spec for one Bend domain."""

    domain: str
    imports: dict[str, str]
    cases_fn: Callable[[int, int], list[OracleCase]]
    helpers: str = ""
    chunk_size: int = 24


@dataclass(frozen=True)
class ModelFault:
    """Deliberate semantic fault in a Bend model that must break a named law."""

    name: str
    domain: str
    old: str
    new: str
    expected_law: str
    file: str = "model.bend"


@dataclass(frozen=True)
class DartFault:
    """Deliberate semantic fault in real Dart source under ``lib/``."""

    name: str
    domain: str
    source_path: str
    old: str
    new: str
    test_file: str
    test_name: str = ""
    extra_tags: tuple[str, ...] = field(default_factory=lambda: ("bend",))


def _b(value: bool) -> str:
    return "True{}" if value else "False{}"


def _bend_nat_list(values: list[int] | tuple[int, ...]) -> str:
    res = "Nil{}"
    for v in reversed(values):
        res = f"({v}n <> {res})"
    return res


def _bend_bool_list(values: list[bool] | tuple[bool, ...]) -> str:
    res = "Nil{}"
    for v in reversed(values):
        res = f"({_b(v)} <> {res})"
    return res


def _bend_maybe_nat(value: int | None) -> str:
    return "None{}" if value is None else f"Some{{{value}n}}"


def _bend_u32_list(values: list[int] | tuple[int, ...]) -> str:
    res = "Nil{}"
    for v in reversed(values):
        res = f"({v} <> {res})"
    return res


# ---------------------------------------------------------------------------
# Domain: amounts
# ---------------------------------------------------------------------------

_AMOUNTS_HELPERS = """\
def _fmt_min_max(+a: Nat, +b: Nat) -> String:
  ("{\\"min\\":" ++ Nat.show(M.big_min(a, b))) ++ ((",\\"max\\":" ++ Nat.show(M.big_max(a, b))) ++ "}")

def _fmt_amt_err(+e: M.AmountError) -> String:
  match e:
    case M.AmountOk{}: "{\\"ok\\":true,\\"error\\":\\"ok\\"}"
    case M.AmountErrBlank{}: "{\\"ok\\":false,\\"error\\":\\"blank\\"}"
    case M.AmountErrParse{}: "{\\"ok\\":false,\\"error\\":\\"parse\\"}"
    case M.AmountErrTooManyDecimals{}: "{\\"ok\\":false,\\"error\\":\\"too_many_decimals\\"}"
    case M.AmountErrMaxBelowMin{}: "{\\"ok\\":false,\\"error\\":\\"max_below_min\\"}"
    case M.AmountErrEmptyBalance{}: "{\\"ok\\":false,\\"error\\":\\"empty_balance\\"}"
    case M.AmountErrOutOfRange{}: "{\\"ok\\":false,\\"error\\":\\"out_of_range\\"}"

def _fmt_cmp(+c: Cmp) -> String:
  match c:
    case LT{}: "-1"
    case EQ{}: "0"
    case GT{}: "1"

def _fmt_tier_str(+t: M.PlasmaTier) -> String:
  match t:
    case M.PlasmaInsufficient{}: "\\"insufficient\\""
    case M.PlasmaLow{}: "\\"low\\""
    case M.PlasmaAverage{}: "\\"average\\""
    case M.PlasmaHigh{}: "\\"high\\""

def _fmt_color_str(+c: M.PlasmaColor) -> String:
  match c:
    case M.ColorZts{}: "\\"zts\\""
    case M.ColorOrange{}: "\\"orange\\""
    case M.ColorYellow{}: "\\"yellow\\""
    case M.ColorZnn{}: "\\"znn\\""

def _fmt_tip_str(+t: M.PlasmaTooltip) -> String:
  match t:
    case M.TipInsufficient{}: "\\"Insufficient Plasma\\""
    case M.TipLow{}: "\\"Low Plasma\\""
    case M.TipAverage{}: "\\"Average Plasma\\""
    case M.TipHigh{}: "\\"High Plasma\\""

def _fmt_plasma_tier(+p: U32) -> String:
  t = _fmt_tier_str(M.plasma_tier(p))
  c = _fmt_color_str(M.plasma_color(p))
  tip = _fmt_tip_str(M.plasma_tooltip(p))
  ("{\\"tier\\":" ++ t) ++ ((",\\"color\\":" ++ c) ++ ((",\\"tooltip\\":" ++ tip) ++ "}"))

def _fmt_pw_tier(+s: M.PasswordStrength) -> String:
  match s:
    case M.PwEmpty{}: "\\"empty\\""
    case M.PwWeak{}: "\\"weak\\""
    case M.PwMedium{}: "\\"medium\\""
    case M.PwStrong{}: "\\"strong\\""

def _fmt_pw_strength(+len: Nat, +hu: Bool, +hl: Bool, +hd: Bool, +hs: Bool) -> String:
  v = _jbool(M.password_is_valid(len, hu, hl, hd, hs))
  t = _fmt_pw_tier(M.password_strength(len, hu, hl, hd, hs))
  ("{\\"valid\\":" ++ v) ++ ((",\\"tier\\":" ++ t) ++ "}")

def _fmt_label_err(+e: M.LabelError) -> String:
  match e:
    case M.LabelOk{}: "ok"
    case M.LabelEmpty{}: "empty"
    case M.LabelTooLong{}: "too_long"
    case M.LabelDuplicate{}: "duplicate"
"""


def _amounts_cases(depth: int, seed: int) -> list[OracleCase]:
    eff_depth = max(1, depth)
    rng = random.Random(seed + 101)
    cases: list[OracleCase] = []

    for a, b in ((0, 0), (0, 5), (5, 0), (3, 7), (7, 3), (42, 42)):
        cases.append(
            OracleCase(
                id=f"minmax_{a}_{b}",
                op="big_min_max",
                args={"a": a, "b": b},
                expr=f"_fmt_min_max({a}n, {b}n)",
                kind="raw_json",
            )
        )
    for i in range(2 + eff_depth):
        a = rng.randint(0, 150)
        b = rng.randint(0, 150)
        cases.append(
            OracleCase(
                id=f"minmax_seed{seed}_d{eff_depth}_{i}",
                op="big_min_max",
                args={"a": a, "b": b},
                expr=f"_fmt_min_max({a}n, {b}n)",
                kind="raw_json",
            )
        )

    for label, w, f, fl, d in (
        ("zero_d0", 0, 0, 0, 0),
        ("whole_d2", 5, 0, 0, 2),
        ("pad_right", 1, 5, 1, 2),
        ("exact_d2", 1, 25, 2, 2),
        ("truncate_d2", 1, 125, 3, 2),
        ("leading_zero_frac", 0, 5, 2, 3),
        ("trunc_to_d0", 2, 75, 2, 0),
    ):
        cases.append(
            OracleCase(
                id=f"extract_{label}",
                op="extract_decimals",
                args={"whole": w, "frac": f, "frac_len": fl, "decimals": d},
                expr=f"M.extract_decimals({w}n, {f}n, {fl}n, {d}n)",
                kind="nat",
            )
        )

    for bu, d in ((0, 0), (0, 2), (42, 0), (125, 2), (5, 2), (1000, 3)):
        cases.append(
            OracleCase(
                id=f"roundtrip_{bu}_d{d}",
                op="roundtrip_decimals",
                args={"base_units": bu, "decimals": d},
                expr=f"M.roundtrip_decimals({bu}n, {d}n)",
                kind="nat",
            )
        )

    cv_inputs = (
        ("zero_max_can_eq_ok", 0, 0, 0, 0, True, False, False, True, 0),
        ("zero_max_can_eq_parse_err", 0, 0, 0, 0, True, False, False, False, 0),
        ("zero_max_empty_bal", 0, 0, 0, 0, False, False, False, True, 0),
        ("blank_allowed", 0, 50, 2, 10, True, True, True, True, 0),
        ("blank_rejected", 0, 50, 2, 10, True, False, True, True, 0),
        ("parse_multi_dot", 10, 50, 2, 10, True, False, False, False, 2),
        ("too_many_decimals", 100, 500, 2, 10, True, False, False, True, 3),
        ("max_below_min", 5, 5, 0, 10, True, False, False, True, 0),
        ("at_min_allowed", 10, 50, 0, 10, True, False, False, True, 0),
        ("at_min_strict_rejected", 10, 50, 0, 10, False, False, False, True, 0),
        ("at_max_ok", 50, 50, 0, 10, False, False, False, True, 0),
        ("above_max_rejected", 51, 50, 0, 10, True, False, False, True, 0),
    )
    for label, v, mx, dec, mn, ceq, cb, ib, pok, fd in cv_inputs:
        cases.append(
            OracleCase(
                id=f"cv_{label}",
                op="correct_value",
                args={
                    "val": v,
                    "max_val": mx,
                    "dec": dec,
                    "min_val": mn,
                    "can_eq_min": ceq,
                    "can_be_blank": cb,
                    "is_blank": ib,
                    "parse_ok": pok,
                    "frac_digits": fd,
                },
                expr=(
                    f"_fmt_amt_err(M.correct_value({v}n, {mx}n, {dec}n, {mn}n, "
                    f"{_b(ceq)}, {_b(cb)}, {_b(ib)}, {_b(pok)}, {fd}n))"
                ),
                kind="raw_json",
            )
        )

    def _asset_expr(kind: str, aid: int) -> str:
        if kind == "znn":
            return "M.Znn{}"
        if kind == "qsr":
            return "M.Qsr{}"
        return f"M.Zts{{{aid}n}}"

    asset_pairs = (
        ("znn", 0, "znn", 0),
        ("znn", 0, "qsr", 0),
        ("znn", 0, "zts", 1),
        ("qsr", 0, "znn", 0),
        ("qsr", 0, "qsr", 0),
        ("qsr", 0, "zts", 1),
        ("zts", 1, "znn", 0),
        ("zts", 1, "qsr", 0),
        ("zts", 1, "zts", 1),
        ("zts", 1, "zts", 2),
    )
    for ak, ai, bk, bi in asset_pairs:
        cases.append(
            OracleCase(
                id=f"asset_{ak}{ai}_vs_{bk}{bi}",
                op="asset_cmp",
                args={"a": ak, "a_id": ai, "b": bk, "b_id": bi},
                expr=f"_fmt_cmp(M.asset_cmp({_asset_expr(ak, ai)}, {_asset_expr(bk, bi)}))",
                kind="raw_json",
            )
        )

    for p in (0, 20999, 21000, 188999, 189000, 251999, 252000, 500000):
        cases.append(
            OracleCase(
                id=f"plasma_tier_{p}",
                op="plasma_tier",
                args={"plasma": p},
                expr=f"_fmt_plasma_tier({p})",
                kind="raw_json",
            )
        )

    pw_inputs = (
        ("empty", 0, False, False, False, False),
        ("short_7", 7, True, True, True, True),
        ("invalid_12_no_special", 12, True, True, True, False),
        ("invalid_16_no_upper", 16, False, True, True, True),
        ("valid_medium_8", 8, True, True, True, True),
        ("valid_medium_15", 15, True, True, True, True),
        ("valid_strong_16", 16, True, True, True, True),
        ("valid_strong_20", 20, True, True, True, True),
    )
    for label, ln, hu, hl, hd, hs in pw_inputs:
        cases.append(
            OracleCase(
                id=f"pw_{label}",
                op="password_strength",
                args={
                    "len": ln,
                    "has_upper": hu,
                    "has_lower": hl,
                    "has_digit": hd,
                    "has_special": hs,
                },
                expr=f"_fmt_pw_strength({ln}n, {_b(hu)}, {_b(hl)}, {_b(hd)}, {_b(hs)})",
                kind="raw_json",
            )
        )

    for label, a_codes, b_codes in (
        ("both_empty", [], []),
        ("equal_3", [1, 2, 3], [1, 2, 3]),
        ("diff_last", [1, 2, 3], [1, 2, 4]),
        ("prefix_len_diff", [1, 2], [1, 2, 3]),
        ("nonempty_vs_empty", [1, 2, 3], []),
    ):
        cases.append(
            OracleCase(
                id=f"pw_match_{label}",
                op="password_match",
                args={"a": a_codes, "b": b_codes},
                expr=f"M.password_match({_bend_nat_list(a_codes)}, {_bend_nat_list(b_codes)})",
                kind="bool",
            )
        )

    for cur, mb, dec in ((0, 100, 0), (50, 100, 2), (100, 100, 2), (150, 100, 2), (10, 0, 0)):
        cases.append(
            OracleCase(
                id=f"max_amt_c{cur}_m{mb}_d{dec}",
                op="resolve_max_amount",
                args={"cur": cur, "max_bal": mb, "decimals": dec},
                expr=f"M.resolve_max_amount({cur}n, {mb}n)",
                kind="nat",
            )
        )

    for ln, is_dup in ((0, False), (1, False), (80, False), (81, False), (10, True), (81, True)):
        cases.append(
            OracleCase(
                id=f"addr_label_l{ln}_d{int(is_dup)}",
                op="validate_address_label",
                args={"len": ln, "is_dup": is_dup},
                expr=f"_fmt_label_err(M.validate_address_label({ln}n, {_b(is_dup)}))",
                kind="string",
            )
        )

    for cnt, ph in ((0, False), (0, True), (1, False), (1, True), (2, False), (3, True)):
        cases.append(
            OracleCase(
                id=f"proto_args_c{cnt}_p{int(ph)}",
                op="validate_protocol_args",
                args={"arg_count": cnt, "has_placeholder": ph},
                expr=f"M.validate_protocol_args({cnt}n, {_b(ph)})",
                kind="bool",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: wallet_lifecycle
# ---------------------------------------------------------------------------

_WALLET_LIFECYCLE_HELPERS = """\
def _fmt_file_state(+s: M.FileState) -> String:
  match s:
    case M.FileIdle{}: "\\"idle\\""
    case M.FileSessionActive{}: "\\"session_active\\""
    case M.FileClosing{}: "\\"closing\\""
    case M.FileClosed{}: "\\"closed\\""

def _wf_fold(+evs: List<&2, M.FileEvent>, +s: M.FileState, +last_g: Bool) -> String:
  match evs:
    case Nil{}:
      ("{\\"state\\":" ++ _fmt_file_state(s)) ++ ((",\\"access_granted\\":" ++ _jbool(last_g)) ++ "}")
    case h <> t:
      +o = M.wallet_file_step(s, h)
      _wf_fold(t, M.file_outcome_state(o), M.file_outcome_granted(o))

def _fmt_wtype(+t: M.ResolvedWalletType) -> String:
  match t:
    case M.WalletKeyStore{}: "keystore"
    case M.WalletLedger{}: "ledger"
    case M.WalletUnsupported{}: "unsupported"

def _fmt_unlock_st(+st: M.UnlockStatus) -> String:
  match st:
    case M.UnlockInitial{}: "\\"initial\\""
    case M.UnlockSuccess{}: "\\"success\\""
    case M.UnlockFailure{}: "\\"failure\\""
    case M.UnlockAutoErase{}: "\\"auto_erase\\""

def _fmt_unlock(+failed: Nat, +limit: Nat, +ic: Bool, +att: M.UnlockAttemptResult) -> String:
  +u = M.unlock_step(M.UnlockState{M.UnlockInitial{}, failed, M.compute_remaining(limit, failed), ic, False{}}, limit, att)
  st = _fmt_unlock_st(M.unlock_status(u))
  fl = Nat.show(M.unlock_failed(u))
  rm = Nat.show(M.unlock_remaining(u))
  inc = _jbool(M.unlock_init_completed(u))
  lni = _jbool(M.unlock_last_needed_init(u))
  ("{\\"status\\":" ++ st) ++ ((",\\"failed\\":" ++ fl) ++ ((",\\"remaining\\":" ++ rm) ++ ((",\\"init_completed\\":" ++ inc) ++ ((",\\"last_needed_init\\":" ++ lni) ++ "}"))))

def _fmt_lock(+ls: M.LockScreenState) -> String:
  il = _jbool(M.lock_is_locked(ls))
  hh = _jbool(M.lock_has_handle(ls))
  ta = _jbool(M.lock_timer_active(ls))
  sq = Nat.show(M.lock_sequence(ls))
  ("{\\"is_locked\\":" ++ il) ++ ((",\\"has_handle\\":" ++ hh) ++ ((",\\"timer_active\\":" ++ ta) ++ ((",\\"sequence\\":" ++ sq) ++ "}")))

def _fmt_splash_dest(+d: M.SplashDest) -> String:
  match d:
    case M.DestAccessWallet{}: "access_wallet"
    case M.DestHome{}: "home"
    case M.DestNodeManagement{}: "node_management"
    case M.DestExitApp{}: "exit_app"
"""


def _wallet_lifecycle_cases(depth: int, seed: int) -> list[OracleCase]:
    eff_depth = max(1, depth)
    rng = random.Random(seed + 202)
    cases: list[OracleCase] = []

    fev_ctor = {
        "begin_access": "M.FileBeginAccess{}",
        "end_access": "M.FileEndAccess{}",
        "request_close": "M.FileRequestClose{}",
        "finish_close": "M.FileFinishClose{}",
    }
    fev_alphabet = tuple(fev_ctor.keys())
    wf_seqs: list[tuple[str, list[str]]] = [
        ("begin_once", ["begin_access"]),
        ("double_begin_blocked", ["begin_access", "begin_access"]),
        ("begin_end_idle", ["begin_access", "end_access"]),
        ("close_from_idle", ["request_close"]),
        ("closed_rejects_access", ["request_close", "begin_access"]),
        ("close_while_active_closing", ["begin_access", "request_close"]),
        ("closing_completes_on_end", ["begin_access", "request_close", "end_access"]),
        ("finish_close_permanent", ["begin_access", "request_close", "finish_close", "begin_access"]),
    ]
    # Exhaustive short event histories of length 1..min(eff_depth, 2)
    for seq_len in range(1, min(eff_depth, 2) + 1):
        for idx, seq in enumerate(itertools.product(fev_alphabet, repeat=seq_len)):
            wf_seqs.append((f"exh_l{seq_len}_{idx}", list(seq)))
    # Deterministic seeded histories of length max(2, eff_depth)
    hist_len = max(2, eff_depth)
    for i in range(2 + eff_depth):
        seq = [rng.choice(fev_alphabet) for _ in range(hist_len)]
        wf_seqs.append((f"seed{seed}_d{eff_depth}_{i}", seq))
    for label, evs in wf_seqs:
        bend_evs = "Nil{}"
        for e in reversed(evs):
            bend_evs = f"({fev_ctor[e]} <> {bend_evs})"
        cases.append(
            OracleCase(
                id=f"wf_{label}",
                op="wallet_file_lifecycle",
                args={"events": evs},
                expr=f"_wf_fold({bend_evs}, M.FileIdle{{}}, False{{}})",
                kind="raw_json",
            )
        )

    ks_inputs = (
        ("valid_min_bounds", 8, 16, 12, True, True, True, True, True, True),
        ("short_salt_7", 7, 16, 12, True, True, True, True, True, True),
        ("short_cipher_15", 8, 15, 12, True, True, True, True, True, True),
        ("short_nonce_11", 8, 16, 11, True, True, True, True, True, True),
        ("bad_salt_hex", 8, 16, 12, False, True, True, True, True, True),
        ("bad_cipher_hex", 8, 16, 12, True, False, True, True, True, True),
        ("bad_nonce_hex", 8, 16, 12, True, True, False, True, True, True),
        ("missing_cipher_name", 8, 16, 12, True, True, True, False, True, True),
        ("missing_kdf", 8, 16, 12, True, True, True, True, False, True),
        ("bad_meta_types", 8, 16, 12, True, True, True, True, True, False),
    )
    for label, sb, cb, nb, sh, ch, nh, hcn, hk, mt in ks_inputs:
        cases.append(
            OracleCase(
                id=f"keystore_{label}",
                op="validate_keystore_schema",
                args={
                    "salt_bytes": sb,
                    "cipher_bytes": cb,
                    "nonce_bytes": nb,
                    "salt_hex_ok": sh,
                    "cipher_hex_ok": ch,
                    "nonce_hex_ok": nh,
                    "has_cipher_name": hcn,
                    "has_kdf": hk,
                    "meta_types_ok": mt,
                },
                expr=(
                    f"M.validate_keystore_schema({sb}n, {cb}n, {nb}n, "
                    f"{_b(sh)}, {_b(ch)}, {_b(nh)}, {_b(hcn)}, {_b(hk)}, {_b(mt)})"
                ),
                kind="bool",
            )
        )

    for rt, oc, expr in (
        ("none", 0, "M.RawTypeNone{}"),
        ("keystore", 0, "M.RawTypeKeyStore{}"),
        ("ledger", 0, "M.RawTypeLedger{}"),
        ("other", 7, "M.RawTypeOther{7n}"),
    ):
        cases.append(
            OracleCase(
                id=f"wtype_{rt}",
                op="dispatch_wallet_type",
                args={"raw_type": rt, "other_code": oc},
                expr=f"_fmt_wtype(M.dispatch_wallet_type({expr}))",
                kind="string",
            )
        )

    for unl in (False, True):
        for hw in (False, True):
            cases.append(
                OracleCase(
                    id=f"backup_u{int(unl)}_hw{int(hw)}",
                    op="can_backup_wallet",
                    args={"is_unlocked": unl, "is_hardware": hw},
                    expr=f"M.can_backup_wallet({_b(unl)}, {_b(hw)})",
                    kind="bool",
                )
            )

    att_ctor = {
        "empty": "M.AttemptEmptyPassword{}",
        "ok": "M.AttemptOk{}",
        "incorrect_password": "M.AttemptIncorrectPassword{}",
        "ledger_error": "M.AttemptLedgerError{}",
        "io_error": "M.AttemptIoError{}",
    }
    unlock_inputs = (
        ("empty_noop", 1, 3, False, "empty"),
        ("ok_first_init", 2, 3, False, "ok"),
        ("ok_subsequent_init", 1, 3, True, "ok"),
        ("incorrect_below_limit", 1, 3, True, "incorrect_password"),
        ("incorrect_hits_limit_erase", 2, 3, True, "incorrect_password"),
        ("incorrect_limit_1_erase", 0, 1, False, "incorrect_password"),
        ("ledger_err_preserves", 1, 3, True, "ledger_error"),
        ("io_err_preserves", 2, 3, False, "io_error"),
    )
    for label, fl, lim, ic, att in unlock_inputs:
        cases.append(
            OracleCase(
                id=f"unlock_{label}",
                op="unlock_step",
                args={"failed": fl, "limit": lim, "init_completed": ic, "attempt": att},
                expr=f"_fmt_unlock({fl}n, {lim}n, {_b(ic)}, {att_ctor[att]})",
                kind="raw_json",
            )
        )

    lock_inputs = (
        ("locked_activity_suppressed", True, False, False, 2, "user_activity", False),
        ("unlocked_activity_resets", False, True, False, 2, "user_activity", False),
        ("manual_lock_clears", False, True, True, 1, "manual_lock", False),
        ("timer_suppressed_by_htlc", False, True, True, 1, "timer_fired", True),
        ("timer_locks_when_idle_swaps", False, True, True, 1, "timer_fired", False),
        ("timer_noop_when_inactive", False, True, False, 1, "timer_fired", False),
        ("unlocked_sets_handle", True, False, False, 3, "unlocked", False),
    )
    for label, il, hh, ta, sq, inp, htlc in lock_inputs:
        if inp == "user_activity":
            ev_e = "M.LockUserActivity{}"
        elif inp == "manual_lock":
            ev_e = "M.LockManualLock{}"
        elif inp == "timer_fired":
            ev_e = f"M.LockTimerFired{{{_b(htlc)}}}"
        else:
            ev_e = "M.LockUnlocked{}"
        cases.append(
            OracleCase(
                id=f"lock_{label}",
                op="lock_step",
                args={
                    "is_locked": il,
                    "has_handle": hh,
                    "timer_active": ta,
                    "seq": sq,
                    "input": inp,
                    "has_active_incoming_swaps": htlc,
                },
                expr=(
                    f"_fmt_lock(M.lock_step(M.LockScreenState{{"
                    f"{_b(il)}, {_b(hh)}, {_b(ta)}, {sq}n}}, {ev_e}))"
                ),
                kind="raw_json",
            )
        )

    flow_ctor = {
        "normal": "M.FlowNormal{}",
        "dev": "M.FlowDev{}",
        "delete_cache": "M.FlowDeleteCache{}",
        "reset_wallet": "M.FlowResetWallet{}",
    }
    for fl in ("normal", "dev", "delete_cache", "reset_wallet"):
        for hwp, hn in ((False, False), (True, False), (True, True)):
            cases.append(
                OracleCase(
                    id=f"splash_dest_{fl}_w{int(hwp)}_n{int(hn)}",
                    op="splash_destination",
                    args={"flow": fl, "has_wallet_path": hwp, "has_node": hn},
                    expr=(
                        f"_fmt_splash_dest(M.splash_destination("
                        f"{flow_ctor[fl]}, {_b(hwp)}, {_b(hn)}))"
                    ),
                    kind="string",
                )
            )

    for fl in ("normal", "dev", "delete_cache", "reset_wallet"):
        for fwc in (False, True):
            cases.append(
                OracleCase(
                    id=f"splash_retry_{fl}_c{int(fwc)}",
                    op="splash_can_retry",
                    args={"flow": fl, "fail_during_clear": fwc},
                    expr=f"M.splash_can_retry({flow_ctor[fl]}, {_b(fwc)})",
                    kind="bool",
                )
            )

    for ch in (False, True):
        for th in (False, True):
            for pv in (False, True):
                cases.append(
                    OracleCase(
                        id=f"hide_c{int(ch)}_t{int(th)}_p{int(pv)}",
                        op="hide_widget_step",
                        args={
                            "currently_hidden": ch,
                            "target_hidden": th,
                            "password_valid": pv,
                        },
                        expr=f"M.hide_widget_step({_b(ch)}, {_b(th)}, {_b(pv)})",
                        kind="bool",
                    )
                )

    return cases


# ---------------------------------------------------------------------------
# Domain: tx_pipeline
# ---------------------------------------------------------------------------

_TX_PIPELINE_SYNC_CTOR = {
    "unknown": "SyncUnknown",
    "syncing": "Syncing",
    "syncDone": "SyncDone",
    "notEnoughPeers": "NotEnoughPeers",
}

_TX_PIPELINE_HELPERS = """\
def _fmt_precond(+o: M.PrecondOutcome) -> String:
  match o:
    case M.PrecondOk{_, _}: "ok"
    case M.ErrNodeNotSynced{}: "err_node_not_synced"
    case M.ErrNoAddressSelected{}: "err_no_address_selected"
    case M.ErrAddressNotInWallet{}: "err_address_not_in_wallet"
    case M.ErrWalletNotUnlocked{}: "err_wallet_not_unlocked"

def _pow_add_em(+em: Nat, +did: Bool) -> Nat:
  match did:
    case True{}: 1n+em
    case False{}: em

def _fmt_pow_fold(+evs: List<&2, M.PowEvent>, +s: M.PowState, +em: Nat) -> String:
  match evs:
    case Nil{}:
      fg = _jbool(M.pow_is_generating(s))
      es = Nat.show(em)
      ("{\\"final_generating\\":" ++ fg) ++ ((",\\"emissions\\":" ++ es) ++ "}")
    case h <> t:
      +r = M.pow_step(s, h)
      _fmt_pow_fold(t, M.pow_res_state(r), _pow_add_em(em, M.pow_res_emitted(r)))

def _fmt_review(+rt: M.ReviewTiming) -> String:
  match rt:
    case M.NoReview{}: "none"
    case M.ReviewImmediate{}: "immediate"
    case M.ReviewDeferredUntilPowDone{}: "deferred"

def _comma_if(+first: Bool) -> String:
  match first:
    case True{}: ""
    case False{}: ","

def _fmt_nat_list_go(+xs: List<&2, Nat>, +first: Bool) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      (_comma_if(first) ++ Nat.show(h)) ++ _fmt_nat_list_go(t, False{})

def _fmt_nat_list(+xs: List<&2, Nat>) -> String:
  ("[" ++ _fmt_nat_list_go(xs, True{})) ++ "]"

def _ar_add_fold(+hs: List<&2, Nat>, +fs: List<&2, Bool>, +s: M.AutoReceiveState) -> M.AutoReceiveState:
  match hs fs:
    case h <> ht f <> ft:
      _ar_add_fold(ht, ft, M.auto_receive_add_hash(s, h, f))
    case _ _:
      s

def _fmt_ar_add(+hs: List<&2, Nat>, +fs: List<&2, Bool>) -> String:
  +s = _ar_add_fold(hs, fs, M.AutoReceiveState{Nil{}, False{}, 0n})
  +p = M.ar_pool(s)
  ("{\\"pool\\":" ++ _fmt_nat_list(p)) ++ ((",\\"pool_len\\":" ++ Nat.show(M.nat_list_len(p))) ++ "}")

def _fmt_ar_step(+pool: List<&2, Nat>, +enabled: Bool, +htlc: Bool, +out: M.ReceiveOutcome) -> String:
  +r = M.auto_receive_loop_step(M.AutoReceiveState{pool, False{}, 0n}, enabled, htlc, out)
  +ns = M.ar_res_state(r)
  +rp = M.ar_pool(ns)
  +en = Bool.and(M.ar_res_continue(r), Bool.not(M.nat_list_is_empty(rp)))
  ("{\\"remaining_pool\\":" ++ _fmt_nat_list(rp)) ++ ((",\\"notif_seq\\":" ++ Nat.show(M.ar_notif_seq(ns))) ++ ((",\\"entered_next\\":" ++ _jbool(en)) ++ "}"))

def _fmt_poll_dec(+d: M.PollStepDecision) -> String:
  match d:
    case M.PollDone{True{}}: "{\\"kind\\":\\"done_true\\",\\"sleep_ms\\":0}"
    case M.PollDone{False{}}: "{\\"kind\\":\\"done_false\\",\\"sleep_ms\\":0}"
    case M.PollSleep{ms}: ("{\\"kind\\":\\"sleep\\",\\"sleep_ms\\":" ++ Nat.show(ms)) ++ "}"

def _pick_addr(+same: Bool) -> Maybe<&2, Nat>:
  match same:
    case True{}: Some{1n}
    case False{}: Some{2n}

def _il_second_idx(+can_more: Bool, +first_len: Nat, +ps: Nat) -> String:
  match can_more:
    case True{}: Nat.show(M.il_page_index(first_len, ps))
    case False{}: "-1"

def _il_item_count(+s: M.InfiniteListModel) -> Nat:
  match s:
    case M.InfiniteListModel{_, cnt, _, _, _, _}: cnt

def _fmt_il_step(+ps: Nat, +first_len: Nat, +second_len: Nat, +same_addr: Bool) -> String:
  +s1 = M.il_begin_first_page(M.InfiniteListModel{M.ListInitial{}, 0n, False{}, 0n, None{}, ps}, Some{1n}, False{})
  +s2 = M.il_apply_first_page(s1, M.il_active_req_id(s1), first_len, True{})
  +ev_addr = _pick_addr(same_addr)
  +can_more = M.il_can_load_more(s2, ev_addr)
  +s3 = M.il_apply_more_page(s2, M.il_active_req_id(s2), first_len, ev_addr, second_len, True{})
  f_hrm = _jbool(M.il_has_reached_max(s2))
  spi = _il_second_idx(can_more, first_len, ps)
  fc = Nat.show(_il_item_count(s3))
  fin_hrm = _jbool(M.il_has_reached_max(s3))
  ("{\\"first_has_reached_max\\":" ++ f_hrm) ++ ((",\\"second_page_index\\":" ++ spi) ++ ((",\\"final_count\\":" ++ fc) ++ ((",\\"final_has_reached_max\\":" ++ fin_hrm) ++ "}")))
"""


def _tx_pipeline_cases(depth: int, seed: int) -> list[OracleCase]:
    eff_depth = max(1, depth)
    rng = random.Random(seed + 303)
    cases: list[OracleCase] = []

    sync_inputs = (
        ("done_zeros", "syncDone", 0, 0),
        ("syncing_diff_19_ok", "syncing", 81, 100),
        ("syncing_diff_20_rejected", "syncing", 80, 100),
        ("syncing_diff_21_rejected", "syncing", 79, 100),
        ("syncing_zero_cur", "syncing", 0, 10),
        ("syncing_zero_tgt", "syncing", 10, 0),
        ("unknown_equal_pos", "unknown", 50, 50),
        ("peers_behind", "notEnoughPeers", 10, 50),
    )
    for label, st, cur, tgt in sync_inputs:
        ctor = _TX_PIPELINE_SYNC_CTOR[st]
        cases.append(
            OracleCase(
                id=f"tx_sync_{label}",
                op="node_is_synced_for_tx",
                args={"state": st, "current_height": cur, "target_height": tgt},
                expr=f"M.node_is_synced_for_tx(M.{ctor}{{}}, {cur}n, {tgt}n)",
                kind="bool",
            )
        )

    precond_inputs = (
        ("unsynced_first", "syncing", 10, 50, False, False, False, False),
        ("no_addr_selected", "syncDone", 100, 100, False, False, True, True),
        ("addr_not_in_wallet", "syncDone", 100, 100, True, False, False, True),
        ("wallet_locked", "syncDone", 100, 100, True, False, True, False),
        ("explicit_ok", "syncDone", 100, 100, True, False, True, True),
        ("selected_fallback_ok", "syncDone", 100, 100, False, True, True, True),
    )
    for label, st, cur, tgt, has_exp, has_sel, in_wal, unlocked in precond_inputs:
        ctor = _TX_PIPELINE_SYNC_CTOR[st]
        exp_m = "Some{1n}" if has_exp else "None{}"
        sel_m = "Some{1n}" if has_sel else "None{}"
        wal_m = "Some{1n}" if unlocked else "None{}"
        cases.append(
            OracleCase(
                id=f"precond_{label}",
                op="check_create_preconditions",
                args={
                    "state": st,
                    "current_height": cur,
                    "target_height": tgt,
                    "has_explicit_addr": has_exp,
                    "has_selected_addr": has_sel,
                    "addr_in_wallet": in_wal,
                    "wallet_unlocked": unlocked,
                },
                expr=(
                    f"_fmt_precond(M.check_create_preconditions("
                    f"M.{ctor}{{}}, {cur}n, {tgt}n, {exp_m}, {sel_m}, "
                    f"{_b(in_wal)}, {wal_m}))"
                ),
                kind="string",
            )
        )

    pow_seqs: list[tuple[str, list[int]]] = [
        ("empty", []),
        ("done_underflow_clamp", [0, 0]),
        ("single_cycle", [1, 0]),
        ("nested_two", [1, 1, 0, 0]),
        ("nested_still_active", [1, 1, 0]),
        ("clamp_then_cycle", [0, 1, 1, 0, 0, 0]),
    ]
    # Exhaustive PoW ref-count event histories of length 1..min(eff_depth, 4)
    for seq_len in range(1, min(eff_depth, 4) + 1):
        for bits in itertools.product((0, 1), repeat=seq_len):
            tag = "".join(str(b) for b in bits)
            pow_seqs.append((f"exh_l{seq_len}_{tag}", list(bits)))
    # Deterministic seeded PoW histories of length max(3, eff_depth + 2)
    pow_len = max(3, eff_depth + 2)
    for i in range(2 + eff_depth):
        seq = [rng.randint(0, 1) for _ in range(pow_len)]
        pow_seqs.append((f"seed{seed}_d{eff_depth}_{i}", seq))
    for label, evs in pow_seqs:
        bend_evs = "Nil{}"
        for ev in reversed(evs):
            ctor = "M.PowGenerating{}" if ev == 1 else "M.PowDone{}"
            bend_evs = f"({ctor} <> {bend_evs})"
        cases.append(
            OracleCase(
                id=f"pow_seq_{label}",
                op="pow_sequence",
                args={"events": evs},
                expr=f"_fmt_pow_fold({bend_evs}, M.pow_init(), 0n)",
                kind="raw_json",
            )
        )

    for nr in (False, True):
        for np_ in (False, True):
            cases.append(
                OracleCase(
                    id=f"hw_review_r{int(nr)}_p{int(np_)}",
                    op="hw_review_timing",
                    args={"need_review": nr, "need_plasma": np_},
                    expr=f"_fmt_review(M.hw_review_timing({_b(nr)}, {_b(np_)}))",
                    kind="string",
                )
            )

    ar_add_inputs = (
        ("dedup_and_unsynced", [1, 2, 1, 3, 2], [1, 1, 1, 0, 1]),
        ("all_unsynced", [5, 6], [0, 0]),
        ("all_distinct_synced", [7, 8, 9], [1, 1, 1]),
    )
    for label, hs, fs in ar_add_inputs:
        cases.append(
            OracleCase(
                id=f"ar_add_{label}",
                op="auto_receive_add_hash",
                args={"hashes": hs, "synced_flags": fs},
                expr=(
                    f"_fmt_ar_add({_bend_nat_list(hs)}, "
                    f"{_bend_bool_list([f == 1 for f in fs])})"
                ),
                kind="raw_json",
            )
        )

    ar_out_ctor = {
        "ok": "ReceiveOk",
        "already_received": "ReceiveAlreadyReceived",
        "other_error": "ReceiveOtherError",
    }
    ar_step_inputs = (
        ("disabled_clears_pool", [1, 2], False, False, "ok"),
        ("htlc_preempts_keeps_pool", [1, 2], True, True, "ok"),
        ("ok_two_items_continues", [1, 2], True, False, "ok"),
        ("ok_single_item_finishes", [1], True, False, "ok"),
        ("already_received_pops", [1, 2], True, False, "already_received"),
        ("other_error_stops_keeps_head", [1, 2], True, False, "other_error"),
        ("empty_pool_noop", [], True, False, "ok"),
    )
    for label, pool, en, htlc, out in ar_step_inputs:
        cases.append(
            OracleCase(
                id=f"ar_step_{label}",
                op="auto_receive_step",
                args={
                    "initial_pool": pool,
                    "enabled": en,
                    "htlc_unlocking": htlc,
                    "outcome": out,
                },
                expr=(
                    f"_fmt_ar_step({_bend_nat_list(pool)}, {_b(en)}, "
                    f"{_b(htlc)}, M.{ar_out_ctor[out]}{{}})"
                ),
                kind="raw_json",
            )
        )

    poll_out_ctor = {
        "confirmed": "FetchConfirmed",
        "not_confirmed": "FetchNotConfirmed",
        "transient_error": "FetchTransientError",
    }
    poll_inputs = (
        ("cancelled_before", True, 100, "confirmed", False, 80, 20),
        ("zero_budget_before", False, 0, "confirmed", False, 0, 20),
        ("confirmed_done_true", False, 100, "confirmed", False, 80, 20),
        ("cancelled_after", False, 100, "not_confirmed", True, 80, 20),
        ("exact_boundary_no_sleep", False, 100, "not_confirmed", False, 50, 50),
        ("above_boundary_sleeps", False, 100, "not_confirmed", False, 51, 50),
        ("below_boundary_stops", False, 100, "not_confirmed", False, 49, 50),
        ("transient_err_sleeps", False, 100, "transient_error", False, 60, 20),
        ("transient_err_boundary_stops", False, 100, "transient_error", False, 20, 20),
    )
    for label, cb, rb, out, ca, ra, iv in poll_inputs:
        cases.append(
            OracleCase(
                id=f"poll_{label}",
                op="poll_step",
                args={
                    "cancelled_before": cb,
                    "rem_before_ms": rb,
                    "outcome": out,
                    "cancelled_after": ca,
                    "rem_after_ms": ra,
                    "poll_interval_ms": iv,
                },
                expr=(
                    f"_fmt_poll_dec(M.poll_step({_b(cb)}, {rb}n, "
                    f"M.{poll_out_ctor[out]}{{}}, {_b(ca)}, {ra}n, {iv}n))"
                ),
                kind="raw_json",
            )
        )

    il_inputs = (
        ("full_then_partial", 5, 5, 3, True),
        ("full_then_full", 5, 5, 5, True),
        ("partial_stops_more", 5, 3, 5, True),
        ("empty_stops_more", 5, 0, 5, True),
        ("different_addr_blocked", 5, 5, 5, False),
    )
    for label, ps, fl, sl, same in il_inputs:
        cases.append(
            OracleCase(
                id=f"il_{label}",
                op="infinite_list_page_and_max",
                args={
                    "page_size": ps,
                    "first_page_len": fl,
                    "second_page_len": sl,
                    "more_same_address": same,
                },
                expr=f"_fmt_il_step({ps}n, {fl}n, {sl}n, {_b(same)})",
                kind="raw_json",
            )
        )

    for bc, z, q in ((0, 0, 0), (0, 10, 0), (0, 0, 10), (1, 0, 0), (1, 5, 0), (1, 0, 5), (3, 2, 4)):
        cases.append(
            OracleCase(
                id=f"balance_bc{bc}_z{z}_q{q}",
                op="balance_is_populated",
                args={"block_count": bc, "znn": z, "qsr": q},
                expr=f"M.balance_is_populated({bc}n, {z}n, {q}n)",
                kind="bool",
            )
        )

    for bc, ps in ((0, 4), (1, 4), (4, 4), (5, 4), (8, 4), (9, 4), (0, 1024), (1, 1024), (1024, 1024), (1025, 1024)):
        cases.append(
            OracleCase(
                id=f"chain_stats_bc{bc}_ps{ps}",
                op="account_chain_stats_page_count",
                args={"block_count": bc, "page_size": ps},
                expr=f"M.ceil_div({bc}n, {ps}n)",
                kind="nat",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: node_sync
# ---------------------------------------------------------------------------

_NODE_SYNC_HELPERS = """\
def _fmt_sync_status(+st: M.SyncStateKind, +cur: Nat, +tgt: Nat) -> String:
  s = _jbool(M.sync_info_is_synced(st, cur, tgt))
  b = _jbool(M.sync_info_is_clearly_behind(cur, tgt))
  ("{\\"is_synced\\":" ++ s) ++ ((",\\"is_clearly_behind\\":" ++ b) ++ "}")

def _fmt_sync_state(+st: M.SyncStateKind) -> String:
  match st:
    case M.SyncUnknown{}: "unknown"
    case M.Syncing{}: "syncing"
    case M.SyncDone{}: "syncDone"
    case M.NotEnoughPeers{}: "notEnoughPeers"

def _fmt_node_id(+nid: Nat) -> String:
  match nid:
    case 1n: "\\"prev\\""
    case _: "\\"target\\""

def _nm_reconnect_failed(+pm: Maybe<&2, M.MismatchPrompt>) -> Bool:
  match pm:
    case None{}: False{}
    case Some{p}: M.prompt_reconnect_failed(p)

def _fmt_nm_state(+s: M.NodeMgmtState) -> String:
  sel = _fmt_node_id(M.nm_selected(s))
  cnf = _fmt_node_id(M.nm_confirmed(s))
  sav = _fmt_node_id(M.nm_saved(s))
  hm = _jbool(M.nm_has_pending_mismatch(s))
  dc = _jbool(M.nm_is_disconnected(s))
  rf = _jbool(_nm_reconnect_failed(M.nm_pending_mismatch(s)))
  nc = Nat.show(M.nm_nonce(s))
  ("{\\"selected\\":" ++ sel) ++ ((",\\"confirmed\\":" ++ cnf) ++ ((",\\"saved\\":" ++ sav) ++ ((",\\"has_mismatch\\":" ++ hm) ++ ((",\\"is_disconnected\\":" ++ dc) ++ ((",\\"reconnect_failed\\":" ++ rf) ++ ((",\\"nonce\\":" ++ nc) ++ "}"))))))

def _fmt_nm_act(
  +act: Nat, +s1: M.NodeMgmtState, +check_mm: Bool, +conn_ok: Bool,
  +proc_cid: Nat, +pre_ok: Bool, +rb_ok: Bool, +rest_cid: Nat, +not_ok: Bool
) -> String:
  match act:
    case 0n:
      _fmt_nm_state(s1)
    case 1n:
      _fmt_nm_state(M.nm_resolve_proceed(s1, check_mm, conn_ok, proc_cid, pre_ok, rb_ok, rest_cid, not_ok))
    case _:
      _fmt_nm_state(M.nm_resolve_cancel(s1, rb_ok, rest_cid))

def _fmt_nm_flow(
  +check_mm: Bool, +client_cid: Nat, +conn_ok: Bool, +live_cid: Nat,
  +pre_ok: Bool, +rb_ok: Bool, +rest_cid: Nat, +not_ok: Bool,
  +act: Nat, +proc_cid: Nat
) -> String:
  +s1 = M.nm_confirm_node(M.NodeMgmtState{False{}, 2n, 1n, 1n, client_cid, client_cid, False{}, None{}, 0n, True{}}, check_mm, conn_ok, live_cid, pre_ok, rb_ok, rest_cid, not_ok)
  _fmt_nm_act(act, s1, check_mm, conn_ok, proc_cid, pre_ok, rb_ok, rest_cid, not_ok)

def _fmt_edit_val(+v: M.EditNodeValidation) -> String:
  match v:
    case M.EditValid{}: "valid"
    case M.EditErrEmpty{}: "empty"
    case M.EditErrTooLong{}: "too_long"
    case M.EditErrDuplicate{}: "duplicate"
    case M.EditErrProtected{}: "protected"

def _fmt_maybe_nat_or_zero(+m: Maybe<&2, Nat>) -> String:
  match m:
    case None{}: "0"
    case Some{n}: Nat.show(n)

def _fmt_about(+o: M.AboutOutcome) -> String:
  match o:
    case M.AboutOutFailure{e}:
      ("{\\"is_failure\\":true,\\"has_momentum\\":false,\\"has_process\\":false,\\"has_os\\":false,\\"first_err_idx\\":" ++ Nat.show(e)) ++ "}"
    case M.AboutOutPopulated{hm, hp, ho, fe}:
      ("{\\"is_failure\\":false,\\"has_momentum\\":" ++ _jbool(hm)) ++ ((",\\"has_process\\":" ++ _jbool(hp)) ++ ((",\\"has_os\\":" ++ _jbool(ho)) ++ ((",\\"first_err_idx\\":" ++ _fmt_maybe_nat_or_zero(fe)) ++ "}")))

def _comma_if_ns(+first: Bool) -> String:
  match first:
    case True{}: ""
    case False{}: ","

def _fmt_notif_ts_go(+xs: List<&2, M.NotifEntry>, +first: Bool) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      (_comma_if_ns(first) ++ Nat.show(M.notif_ts(h))) ++ _fmt_notif_ts_go(t, False{})

def _notif_add_fold(+ts_list: List<&2, Nat>, +box: List<&2, M.NotifEntry>, +idx: Nat, +max_e: Nat) -> List<&2, M.NotifEntry>:
  match ts_list:
    case Nil{}: box
    case t <> rest:
      _notif_add_fold(rest, M.notif_repo_add(box, M.NotifEntry{idx, t}, max_e), 1n+idx, max_e)

def _fmt_notif_fifo(+ts_list: List<&2, Nat>, +max_e: Nat, +lim: Nat) -> String:
  +loaded = M.notif_repo_load(_notif_add_fold(ts_list, Nil{}, 0n, max_e), lim)
  ("{\\"loaded_timestamps\\":[" ++ _fmt_notif_ts_go(loaded, True{})) ++ (("],\\"loaded_len\\":" ++ Nat.show(M.notif_len(loaded))) ++ "}")

def _notif_dismiss_mode(+s1: M.NotifBannerState, +mode: Nat) -> M.NotifBannerState:
  match mode:
    case 0n: M.notif_bloc_dismiss(s1, None{})
    case 1n: M.notif_bloc_dismiss(s1, Some{M.banner_revision(s1)})
    case 2n: M.notif_bloc_dismiss(s1, Some{Nat.add(M.banner_revision(s1), 99n)})
    case _: s1

def _fmt_notif_bloc(+add_ok: Bool, +mode: Nat) -> String:
  +s1 = M.notif_bloc_add(M.NotifBannerState{None{}, 0n}, 1n, add_ok)
  +s2 = _notif_dismiss_mode(s1, mode)
  ha = _jbool(Maybe.is_some(&2, Nat, M.banner_active(s2)))
  rv = Nat.show(M.banner_revision(s2))
  ("{\\"has_active\\":" ++ ha) ++ ((",\\"revision\\":" ++ rv) ++ "}")
"""


def _node_sync_cases(depth: int, seed: int) -> list[OracleCase]:
    eff_depth = max(1, depth)
    rng = random.Random(seed + 404)
    cases: list[OracleCase] = []

    sync_inputs = (
        ("done_zeros", "syncDone", 0, 0),
        ("syncing_diff_0", "syncing", 100, 100),
        ("syncing_diff_2_synced", "syncing", 98, 100),
        ("syncing_diff_3_behind", "syncing", 97, 100),
        ("syncing_diff_4_behind", "syncing", 96, 100),
        ("syncing_zero_cur", "syncing", 0, 10),
        ("unknown_zero_tgt", "unknown", 10, 0),
        ("peers_diff_3", "notEnoughPeers", 97, 100),
    )
    for label, st, cur, tgt in sync_inputs:
        ctor = _TX_PIPELINE_SYNC_CTOR[st]
        cases.append(
            OracleCase(
                id=f"sync_status_{label}",
                op="sync_info_status",
                args={"state": st, "current_height": cur, "target_height": tgt},
                expr=f"_fmt_sync_status(M.{ctor}{{}}, {cur}n, {tgt}n)",
                kind="raw_json",
            )
        )

    hyst_inputs = (
        ("done_ignores_jitter_2", "syncDone", 100, 100, "syncing", 98, 100),
        ("done_transitions_behind_3", "syncDone", 100, 100, "syncing", 97, 100),
        ("behind_to_done", "syncing", 50, 100, "syncDone", 100, 100),
        ("unknown_ignores_jitter", "syncing", 99, 100, "notEnoughPeers", 98, 100),
        ("unknown_to_peers_behind", "notEnoughPeers", 50, 100, "syncing", 98, 100),
    )
    for label, s1, c1, t1, s2, c2, t2 in hyst_inputs:
        c1_ctor = _TX_PIPELINE_SYNC_CTOR[s1]
        c2_ctor = _TX_PIPELINE_SYNC_CTOR[s2]
        cases.append(
            OracleCase(
                id=f"sync_hyst_{label}",
                op="sync_cubit_hysteresis",
                args={
                    "state1": s1,
                    "cur1": c1,
                    "tgt1": t1,
                    "state2": s2,
                    "cur2": c2,
                    "tgt2": t2,
                },
                expr=(
                    f"_fmt_sync_state(M.sync_cubit_step("
                    f"M.sync_cubit_step(M.SyncUnknown{{}}, M.{c1_ctor}{{}}, {c1}n, {t1}n), "
                    f"M.{c2_ctor}{{}}, {c2}n, {t2}n))"
                ),
                kind="string",
            )
        )

    nm_flows = (
        # (label, check_mm, client_cid, conn_ok, live_cid, pre_ok, rb_ok, rest_cid, not_ok, action, proc_cid)
        ("clean_commit", True, 1, True, 1, True, True, 1, True, "confirm_only", 1),
        ("connect_fail_rollback", True, 1, False, 1, True, True, 1, True, "confirm_only", 1),
        ("precommit_fail_rollback_ok", True, 1, True, 1, False, True, 1, True, "confirm_only", 1),
        ("precommit_fail_rollback_fail", True, 1, True, 1, False, False, 1, True, "confirm_only", 1),
        ("notify_fail_stays_committed", True, 1, True, 1, True, True, 1, False, "confirm_only", 1),
        ("mismatch_prompts_no_save", True, 1, True, 2, True, True, 1, True, "confirm_only", 2),
        ("mismatch_proceed_same_cid", True, 1, True, 2, True, True, 1, True, "proceed", 2),
        ("mismatch_proceed_toctou_drift", True, 1, True, 2, True, True, 1, True, "proceed", 3),
        ("mismatch_cancel_ok", True, 1, True, 2, True, True, 1, True, "cancel", 2),
        ("mismatch_cancel_reconnect_fail", True, 1, True, 2, True, False, 1, True, "cancel", 2),
        ("check_disabled_commits_mismatch", False, 1, True, 2, True, True, 1, True, "confirm_only", 2),
    )
    act_code = {"confirm_only": 0, "proceed": 1, "cancel": 2}
    for label, cm, cc, cok, lc, pok, rok, rc, nok, act, pc in nm_flows:
        cases.append(
            OracleCase(
                id=f"nm_flow_{label}",
                op="node_mgmt_confirm_flow",
                args={
                    "check_mismatch": cm,
                    "client_chain_id": cc,
                    "connect_ok": cok,
                    "live_chain_id": lc,
                    "precommit_ok": pok,
                    "rollback_ok": rok,
                    "restored_chain_id": rc,
                    "notify_ok": nok,
                    "action": act,
                    "proceed_live_chain_id": pc,
                },
                expr=(
                    f"_fmt_nm_flow({_b(cm)}, {cc}n, {_b(cok)}, {lc}n, "
                    f"{_b(pok)}, {_b(rok)}, {rc}n, {_b(nok)}, {act_code[act]}n, {pc}n)"
                ),
                kind="raw_json",
            )
        )

    for new_len, is_dup in ((0, False), (1, False), (80, False), (81, False), (10, True), (81, True)):
        existing = "(9n <> Nil{})" if is_dup else "Nil{}"
        cases.append(
            OracleCase(
                id=f"edit_len{new_len}_dup{int(is_dup)}",
                op="node_mgmt_edit_validation",
                args={"new_len": new_len, "is_duplicate": is_dup},
                expr=(
                    f"_fmt_edit_val(M.validate_edit_node("
                    f"False{{}}, False{{}}, {new_len}n, 9n, {existing}))"
                ),
                kind="string",
            )
        )

    for r1 in (False, True):
        for r2 in (False, True):
            for r3 in (False, True):
                e1 = "M.RpcOk{1n}" if r1 else "M.RpcErr{1n}"
                e2 = "M.RpcOk{2n}" if r2 else "M.RpcErr{2n}"
                e3 = "M.RpcOk{3n}" if r3 else "M.RpcErr{3n}"
                cases.append(
                    OracleCase(
                        id=f"about_r{int(r1)}{int(r2)}{int(r3)}",
                        op="about_reduce",
                        args={"r1_ok": r1, "r2_ok": r2, "r3_ok": r3},
                        expr=f"_fmt_about(M.about_reduce({e1}, {e2}, {e3}))",
                        kind="raw_json",
                    )
                )

    fifo_inputs: list[tuple[str, list[int], int, int]] = [
        ("empty", [], 5, 10),
        ("sorted_desc", [10, 30, 20], 5, 10),
        ("evict_oldest_fifo", [10, 20, 30, 40, 50], 3, 10),
        ("limit_truncates", [10, 50, 20, 40, 30], 10, 2),
        ("ties_preserved", [20, 20, 10, 30], 3, 5),
    ]
    for i in range(2 + eff_depth):
        ts_len = rng.randint(3, 6)
        ts = [rng.randint(10, 90) for _ in range(ts_len)]
        max_e = rng.randint(1, 5)
        lim = rng.randint(1, 6)
        fifo_inputs.append((f"seed{seed}_d{eff_depth}_{i}", ts, max_e, lim))
    for label, ts, max_e, lim in fifo_inputs:
        cases.append(
            OracleCase(
                id=f"notif_fifo_{label}",
                op="notif_repo_fifo_load",
                args={"timestamps": ts, "max_entries": max_e, "limit": lim},
                expr=f"_fmt_notif_fifo({_bend_nat_list(ts)}, {max_e}n, {lim}n)",
                kind="raw_json",
            )
        )

    mode_code = {"none": 0, "matching": 1, "stale": 2, "skip": 3}
    for add_ok in (False, True):
        for mode, code in mode_code.items():
            cases.append(
                OracleCase(
                    id=f"notif_bloc_add{int(add_ok)}_{mode}",
                    op="notif_bloc_lifecycle",
                    args={"add_repo_ok": add_ok, "dismiss_mode": mode},
                    expr=f"_fmt_notif_bloc({_b(add_ok)}, {code}n)",
                    kind="raw_json",
                )
            )

    opt_inputs = (
        ("macos_perm_denied_blocks_enable", False, True, True, False, True),
        ("macos_perm_denied_preserves_true", True, True, True, False, True),
        ("macos_perm_granted_enables", False, True, True, True, True),
        ("macos_disable_ignores_perm", True, False, True, False, True),
        ("linux_enables_without_macos_perm", False, True, False, False, True),
        ("save_failure_rolls_back_enable", False, True, False, True, False),
        ("save_failure_rolls_back_disable", True, False, True, True, False),
    )
    for label, prev, des, mac, perm, ok in opt_inputs:
        cases.append(
            OracleCase(
                id=f"wallet_opt_{label}",
                op="wallet_opt_desktop_notifs",
                args={
                    "prev": prev,
                    "desired": des,
                    "is_macos": mac,
                    "os_perm_granted": perm,
                    "save_ok": ok,
                },
                expr=(
                    f"M.wallet_opt_toggle_desktop_notifs({_b(prev)}, "
                    f"{_b(des)}, {_b(mac)}, {_b(perm)}, {_b(ok)})"
                ),
                kind="bool",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: plasma_staking
# ---------------------------------------------------------------------------

_PLASMA_STAKING_HELPERS = """\
def _fmt_fusion(+s: M.FusionStatus) -> String:
  match s:
    case M.FusionRevocable{}:
      "{\\"revocable\\":true,\\"seconds\\":0}"
    case M.FusionLocked{secs}:
      ("{\\"revocable\\":false,\\"seconds\\":" ++ Nat.show(secs)) ++ "}"
"""


def _plasma_staking_cases(depth: int, seed: int) -> list[OracleCase]:
    eff_depth = max(1, depth)
    rng = random.Random(seed + 505)
    cases: list[OracleCase] = []

    for qsr in (0, 1, 5, 10, 40, 50, 90, 120, 200, 1000):
        cases.append(
            OracleCase(
                id=f"plasma_for_qsr_{qsr}",
                op="plasma_for_qsr_u32",
                args={"qsr": qsr},
                expr=f"M.plasma_for_qsr_u32({qsr})",
                kind="u32",
            )
        )

    op_ctors = (
        ("min_plasma", "OpMinPlasma"),
        ("delegate", "OpDelegate"),
        ("stake", "OpStake"),
        ("issue_token", "OpIssueToken"),
        ("pillar", "OpPillar"),
        ("sentinel", "OpSentinel"),
    )
    for op_name, ctor in op_ctors:
        cases.append(
            OracleCase(
                id=f"op_plasma_{op_name}",
                op="op_plasma_u32",
                args={"op": op_name},
                expr=f"M.op_plasma_u32(M.{ctor}{{}})",
                kind="u32",
            )
        )

    fuse_inputs: list[tuple[str, int, int, bool, bool]] = [
        ("zero_bal_min_qsr", 10, 0, True, True),
        ("zero_both", 0, 0, True, True),
        ("zero_qsr_pos_bal", 0, 50, True, True),
        ("below_min_9", 9, 50, True, True),
        ("bal_below_min", 10, 9, True, True),
        ("exact_min_eq_bal", 10, 10, True, True),
        ("exact_min_below_bal", 10, 50, True, True),
        ("exact_full_bal", 50, 50, True, True),
        ("above_bal", 51, 50, True, True),
        ("fractional_rejected", 10, 50, False, True),
        ("invalid_beneficiary", 10, 50, True, False),
        ("both_flags_invalid", 10, 50, False, False),
        ("typical_valid", 15, 100, True, True),
    ]
    for i in range(2 + eff_depth):
        qsr = rng.randint(0, 40)
        bal = rng.randint(0, 40)
        is_int = rng.choice((True, True, False))
        valid_ben = rng.choice((True, True, False))
        fuse_inputs.append((f"seed{seed}_d{eff_depth}_{i}", qsr, bal, is_int, valid_ben))
    for label, qsr, bal, is_int, valid_ben in fuse_inputs:
        cases.append(
            OracleCase(
                id=f"can_fuse_{label}",
                op="can_fuse_plasma",
                args={
                    "qsr": qsr,
                    "balance": bal,
                    "is_integer": is_int,
                    "valid_beneficiary": valid_ben,
                },
                expr=(
                    f"M.can_fuse_plasma({qsr}n, {bal}n, "
                    f"{_b(is_int)}, {_b(valid_ben)})"
                ),
                kind="bool",
            )
        )

    fusion_heights = (
        ("eq_zero", 0, 0),
        ("eq_ten", 10, 10),
        ("gt_by_one", 11, 10),
        ("gt_by_fifteen", 25, 10),
        ("lt_by_one", 0, 1),
        ("lt_by_five", 10, 15),
        ("lt_by_hundred", 10, 110),
        ("one_gt_zero", 1, 0),
    )
    for label, last_h, exp_h in fusion_heights:
        cases.append(
            OracleCase(
                id=f"fusion_status_{label}",
                op="fusion_status",
                args={"last_height": last_h, "exp_height": exp_h},
                expr=f"_fmt_fusion(M.fusion_status({last_h}n, {exp_h}n))",
                kind="raw_json",
            )
        )

    for months in (0, 1, 2, 6, 11, 12, 13, 24):
        cases.append(
            OracleCase(
                id=f"valid_stake_months_{months}",
                op="valid_stake_months",
                args={"months": months},
                expr=f"M.valid_stake_months({months}n)",
                kind="bool",
            )
        )

    for months in (1, 2, 3, 6, 12):
        cases.append(
            OracleCase(
                id=f"stake_duration_{months}m",
                op="stake_duration_u32",
                args={"months": months},
                expr=f"M.stake_duration_u32({months})",
                kind="u32",
            )
        )

    stake_inputs = (
        ("zero_bal", 1, 0, 1),
        ("zero_amt", 0, 10, 1),
        ("zero_both", 0, 0, 1),
        ("exact_min", 1, 1, 1),
        ("max_bal_12m", 10, 10, 12),
        ("above_bal", 11, 10, 6),
        ("months_0", 5, 10, 0),
        ("months_13", 5, 10, 13),
        ("valid_mid", 5, 10, 6),
    )
    for label, amt, bal, months in stake_inputs:
        cases.append(
            OracleCase(
                id=f"can_create_stake_{label}",
                op="can_create_stake",
                args={"amount": amt, "balance": bal, "months": months},
                expr=f"M.can_create_stake({amt}n, {bal}n, {months}n)",
                kind="bool",
            )
        )

    reward_inputs = (
        (0, 0),
        (0, 5),
        (0, 100),
        (1, 0),
        (1, 1),
        (50, 0),
        (25, 10),
    )
    for qsr, znn in reward_inputs:
        cases.append(
            OracleCase(
                id=f"collect_stake_qsr{qsr}_znn{znn}",
                op="can_collect_stake_rewards",
                args={"qsr": qsr, "znn": znn},
                expr=f"M.can_collect_stake_rewards({qsr}n, {znn}n)",
                kind="bool",
            )
        )

    par_inputs = (
        ("both_valid", 10, 20, True, True, 5, 10, 6),
        ("fuse_zero_bal", 10, 0, True, True, 5, 10, 6),
        ("fuse_fractional", 10, 20, False, True, 5, 10, 6),
        ("stake_months_13", 10, 20, True, True, 5, 10, 13),
        ("stake_over_bal", 10, 20, True, True, 15, 10, 6),
        ("both_invalid", 5, 2, False, False, 0, 0, 0),
    )
    for label, q, qb, ii, vb, z, zb, m in par_inputs:
        cases.append(
            OracleCase(
                id=f"parallel_check_{label}",
                op="parallel_plasma_staking_check",
                args={
                    "qsr": q,
                    "qsr_bal": qb,
                    "is_int": ii,
                    "valid_ben": vb,
                    "znn": z,
                    "znn_bal": zb,
                    "months": m,
                },
                expr=(
                    f"M.parallel_plasma_staking_check({q}n, {qb}n, "
                    f"{_b(ii)}, {_b(vb)}, {z}n, {zb}n, {m}n)"
                ),
                kind="bool",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: pillars_sentinels
# ---------------------------------------------------------------------------

_PILLARS_SENTINELS_HELPERS = """\
def _fmt_pillar_consts() -> String:
  p = U32.show(M.role_plasma_req_u32(M.RolePillar{}))
  z = U32.show(M.role_znn_collateral_u32(M.RolePillar{}))
  b = _jbool(M.role_qsr_burned(M.RolePillar{}))
  ("{\\"plasma_u32\\":" ++ p) ++ ((",\\"znn_u32\\":" ++ z) ++ ((",\\"qsr_burned\\":" ++ b) ++ "}"))

def _fmt_sentinel_consts() -> String:
  p = U32.show(M.role_plasma_req_u32(M.RoleSentinel{}))
  z = U32.show(M.role_znn_collateral_u32(M.RoleSentinel{}))
  q = U32.show(M.sentinel_qsr_cost_u32())
  b = _jbool(M.role_qsr_burned(M.RoleSentinel{}))
  ("{\\"plasma_u32\\":" ++ p) ++ ((",\\"znn_u32\\":" ++ z) ++ ((",\\"qsr_cost_u32\\":" ++ q) ++ ((",\\"qsr_burned\\":" ++ b) ++ "}")))

def _fmt_qsr_summary(+bal: Nat, +cost: Nat, +dep: Nat) -> String:
  r = Nat.show(M.qsr_remaining(cost, dep))
  m = Nat.show(M.max_qsr_deposit(bal, cost, dep))
  c = _jbool(M.qsr_covered(dep, cost))
  w = _jbool(M.can_withdraw_qsr(dep))
  cl = Nat.show(M.clamped_qsr_deposit(cost, dep))
  ("{\\"remaining\\":" ++ r) ++ ((",\\"max_deposit\\":" ++ m) ++ ((",\\"is_covered\\":" ++ c) ++ ((",\\"can_withdraw\\":" ++ w) ++ ((",\\"clamped_deposit\\":" ++ cl) ++ "}"))))

def _fmt_reward_pct(+pct: Nat) -> String:
  v = _jbool(M.valid_reward_pct(pct))
  o = Nat.show(M.owner_reward_pct(pct))
  ("{\\"valid\\":" ++ v) ++ ((",\\"owner_pct\\":" ++ o) ++ "}")
"""


def _pillars_sentinels_cases(depth: int, seed: int) -> list[OracleCase]:
    del depth, seed
    cases: list[OracleCase] = [
        OracleCase(
            id="role_constants_pillar",
            op="role_constants",
            args={"role": "pillar"},
            expr="_fmt_pillar_consts()",
            kind="raw_json",
        ),
        OracleCase(
            id="role_constants_sentinel",
            op="role_constants",
            args={"role": "sentinel"},
            expr="_fmt_sentinel_consts()",
            kind="raw_json",
        ),
    ]

    deposit_inputs = (
        ("all_zero", 0, 0, 0),
        ("no_bal_no_dep", 0, 50, 0),
        ("bal_lt_remaining", 20, 50, 0),
        ("bal_gt_remaining", 100, 50, 0),
        ("partial_dep_bal_gt_rem", 100, 50, 20),
        ("partial_dep_bal_lt_rem", 10, 50, 20),
        ("exact_covered", 50, 50, 50),
        ("over_deposited", 50, 50, 75),
        ("covered_zero_bal", 0, 50, 50),
        ("exact_bal_eq_rem", 30, 50, 20),
    )
    for label, bal, cost, dep in deposit_inputs:
        cases.append(
            OracleCase(
                id=f"qsr_summary_{label}",
                op="qsr_deposit_summary",
                args={"balance": bal, "cost": cost, "deposit": dep},
                expr=f"_fmt_qsr_summary({bal}n, {cost}n, {dep}n)",
                kind="raw_json",
            )
        )

    uptime_inputs = (
        (0, 0),
        (1, 0),
        (5, 0),
        (0, 1),
        (1, 1),
        (0, 10),
        (1, 10),
        (5, 10),
        (10, 10),
        (1, 4),
        (3, 4),
        (1, 5),
        (2, 5),
        (4, 5),
        (1, 2),
        (19, 20),
        # Non-exact half-away-from-zero rounding & produced > expected (#47)
        (1, 3),
        (2, 3),
        (1, 6),
        (5, 6),
        (1, 200),
        (12, 10),
    )
    for prod, exp in uptime_inputs:
        cases.append(
            OracleCase(
                id=f"uptime_{prod}_of_{exp}",
                op="safe_uptime_pct",
                args={"produced": prod, "expected": exp},
                expr=f"M.safe_uptime_pct({prod}n, {exp}n)",
                kind="nat",
            )
        )

    for addr_valid in (False, True):
        for in_wallet in (False, True):
            cases.append(
                OracleCase(
                    id=f"producer_valid{int(addr_valid)}_wallet{int(in_wallet)}",
                    op="valid_pillar_producer",
                    args={"addr_valid": addr_valid, "in_wallet": in_wallet},
                    expr=f"M.valid_pillar_producer({_b(addr_valid)}, {_b(in_wallet)})",
                    kind="bool",
                )
            )

    for pct in (0, 1, 25, 50, 99, 100, 101, 150):
        cases.append(
            OracleCase(
                id=f"reward_pct_{pct}",
                op="reward_pct",
                args={"pct": pct},
                expr=f"_fmt_reward_pct({pct}n)",
                kind="raw_json",
            )
        )

    for bal in (0, 1, 2, 10, 100):
        cases.append(
            OracleCase(
                id=f"can_delegate_znn_{bal}",
                op="can_delegate",
                args={"znn_bal": bal},
                expr=f"M.can_delegate({bal}n)",
                kind="bool",
            )
        )

    for role, ctor in (("pillar", "RolePillar"), ("sentinel", "RoleSentinel")):
        for znn, qsr in ((0, 0), (0, 1), (1, 0), (1, 1), (0, 50), (25, 0)):
            cases.append(
                OracleCase(
                    id=f"collect_{role}_z{znn}_q{qsr}",
                    op="can_collect_rewards",
                    args={"role": role, "znn": znn, "qsr": qsr},
                    expr=f"M.can_collect_rewards(M.{ctor}{{}}, {znn}n, {qsr}n)",
                    kind="bool",
                )
            )

    spawn_inputs = (
        ("exact_met", 50, 50, 20, 20, 15, 15),
        ("all_exceeded", 80, 50, 30, 20, 25, 15),
        ("plasma_short", 49, 50, 20, 20, 15, 15),
        ("deposit_short", 50, 50, 19, 20, 15, 15),
        ("znn_short", 50, 50, 20, 20, 14, 15),
        ("all_short", 0, 50, 0, 20, 0, 15),
        ("zero_reqs", 0, 0, 0, 0, 0, 0),
    )
    for label, p, pr, dep, qc, zb, zr in spawn_inputs:
        cases.append(
            OracleCase(
                id=f"spawn_readiness_{label}",
                op="parallel_spawn_readiness",
                args={
                    "plasma": p,
                    "plasma_req": pr,
                    "deposit": dep,
                    "qsr_cost": qc,
                    "znn_bal": zb,
                    "znn_req": zr,
                },
                expr=(
                    f"M.parallel_spawn_readiness({p}n, {pr}n, {dep}n, "
                    f"{qc}n, {zb}n, {zr}n)"
                ),
                kind="bool",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: tokens_zts
# ---------------------------------------------------------------------------

_TOKENS_ZTS_HELPERS = """\
def _fmt_issue_consts() -> String:
  p = U32.show(M.issue_plasma_req_u32())
  f = Nat.show(M.issue_znn_fee())
  ("{\\"plasma_u32\\":" ++ p) ++ ((",\\"znn_fee\\":" ++ f) ++ "}")

def _fmt_token_caps(+m: Bool, +b: Bool, +tot: Nat, +mx: Nat, +own: Bool, +wown: Bool) -> String:
  +c = M.token_caps(m, b, tot, mx, own, wown)
  ct = _jbool(M.caps_can_transfer(c))
  sm = _jbool(M.caps_show_mint(c))
  cm = _jbool(M.caps_can_mint(c))
  cb = _jbool(M.caps_can_burn(c))
  ob = _jbool(M.caps_show_own_badge(c))
  ("{\\"can_transfer\\":" ++ ct) ++ ((",\\"show_mint\\":" ++ sm) ++ ((",\\"can_mint\\":" ++ cm) ++ ((",\\"can_burn\\":" ++ cb) ++ ((",\\"show_own_badge\\":" ++ ob) ++ "}"))))

def _fmt_supply(+m: Bool, +tot: Nat, +mx: Nat, +cap: Nat, +dec: Nat) -> String:
  v = _jbool(M.valid_token_supply(m, tot, mx, cap, dec))
  em = Nat.show(M.effective_max_supply(m, tot, mx))
  ("{\\"valid\\":" ++ v) ++ ((",\\"effective_max\\":" ++ em) ++ "}")

def _fmt_fav_step(+init: M.FavStatus, +ev1: M.FavEvent, +ev2: M.FavEvent) -> String:
  +s2 = M.fav_step(M.fav_step(init, ev1), ev2)
  sa = _jbool(M.fav_shows_add_action(s2))
  sr = _jbool(M.fav_shows_remove_action(s2))
  ("{\\"shows_add\\":" ++ sa) ++ ((",\\"shows_remove\\":" ++ sr) ++ "}")
"""


def _tokens_zts_cases(depth: int, seed: int) -> list[OracleCase]:
    del depth, seed
    cases: list[OracleCase] = [
        OracleCase(
            id="issue_constants",
            op="issue_constants",
            args={},
            expr="_fmt_issue_consts()",
            kind="raw_json",
        )
    ]

    for m in (False, True):
        for b in (False, True):
            for own in (False, True):
                for regime, tot, mx in (("partial", 5, 10), ("full", 10, 10)):
                    wown = own
                    cases.append(
                        OracleCase(
                            id=f"caps_m{int(m)}_b{int(b)}_o{int(own)}_{regime}",
                            op="token_caps",
                            args={
                                "is_mintable": m,
                                "is_burnable": b,
                                "total": tot,
                                "max_sup": mx,
                                "is_sel_owner": own,
                                "is_wallet_owner": wown,
                            },
                            expr=(
                                f"_fmt_token_caps({_b(m)}, {_b(b)}, "
                                f"{tot}n, {mx}n, {_b(own)}, {_b(wown)})"
                            ),
                            kind="raw_json",
                        )
                    )
    for label, m, b, own, wown in (
        ("wallet_not_sel", True, False, False, True),
        ("wallet_not_sel_burnable", False, True, False, True),
        ("sel_without_wallet", True, True, True, False),
        ("over_max_supply", True, False, True, True),
    ):
        tot, mx = (12, 10) if label == "over_max_supply" else (5, 10)
        cases.append(
            OracleCase(
                id=f"caps_{label}",
                op="token_caps",
                args={
                    "is_mintable": m,
                    "is_burnable": b,
                    "total": tot,
                    "max_sup": mx,
                    "is_sel_owner": own,
                    "is_wallet_owner": wown,
                },
                expr=(
                    f"_fmt_token_caps({_b(m)}, {_b(b)}, "
                    f"{tot}n, {mx}n, {_b(own)}, {_b(wown)})"
                ),
                kind="raw_json",
            )
        )

    supply_inputs = (
        ("mint_zero_max", True, 0, 0, 100, 8),
        ("mint_zero_tot_min_max", True, 0, 1, 100, 8),
        ("mint_valid", True, 10, 100, 100, 8),
        ("mint_full_dec18", True, 100, 100, 100, 18),
        ("mint_tot_gt_max", True, 101, 100, 100, 8),
        ("mint_max_gt_cap", True, 50, 101, 100, 8),
        ("mint_dec19", True, 10, 50, 100, 19),
        ("mint_dec0", True, 10, 50, 100, 0),
        ("fixed_zero_tot", False, 0, 0, 100, 8),
        ("fixed_min_tot", False, 1, 0, 100, 8),
        ("fixed_ignores_max_in", False, 50, 99, 100, 8),
        ("fixed_at_cap_dec18", False, 100, 0, 100, 18),
        ("fixed_over_cap", False, 101, 0, 100, 8),
        ("fixed_dec19", False, 50, 0, 100, 19),
    )
    for label, m, tot, mx, cap, dec in supply_inputs:
        cases.append(
            OracleCase(
                id=f"supply_{label}",
                op="valid_token_supply",
                args={
                    "is_mintable": m,
                    "total": tot,
                    "max_in": mx,
                    "cap": cap,
                    "dec": dec,
                },
                expr=f"_fmt_supply({_b(m)}, {tot}n, {mx}n, {cap}n, {dec}n)",
                kind="raw_json",
            )
        )

    mint_inputs = (
        ("valid", 1, 5, 10, True, True),
        ("exact_rem", 5, 5, 10, True, True),
        ("over_rem", 6, 5, 10, True, True),
        ("zero_amt", 0, 5, 10, True, True),
        ("full_sup", 1, 10, 10, True, True),
        ("tot_gt_max", 1, 12, 10, True, True),
        ("not_mintable", 1, 5, 10, False, True),
        ("not_owner", 1, 5, 10, True, False),
    )
    for label, amt, tot, mx, m, own in mint_inputs:
        cases.append(
            OracleCase(
                id=f"can_mint_{label}",
                op="can_mint_amount",
                args={
                    "amt": amt,
                    "total": tot,
                    "max_sup": mx,
                    "is_mintable": m,
                    "is_sel_owner": own,
                },
                expr=(
                    f"M.can_mint_amount({amt}n, {tot}n, {mx}n, "
                    f"{_b(m)}, {_b(own)})"
                ),
                kind="bool",
            )
        )

    burn_inputs = (
        ("burnable_non_owner", 5, 10, 20, True, False),
        ("owner_non_burnable", 5, 10, 20, False, True),
        ("unauth", 5, 10, 20, False, False),
        ("zero_amt", 0, 10, 20, True, True),
        ("exact_bal", 10, 10, 20, True, True),
        ("over_bal", 11, 10, 20, True, True),
        ("over_total", 15, 20, 10, True, True),
        ("exact_total", 10, 20, 10, True, True),
    )
    for label, amt, bal, tot, b, own in burn_inputs:
        cases.append(
            OracleCase(
                id=f"can_burn_{label}",
                op="can_burn_amount",
                args={
                    "amt": amt,
                    "balance": bal,
                    "total": tot,
                    "is_burnable": b,
                    "is_sel_owner": own,
                },
                expr=(
                    f"M.can_burn_amount({amt}n, {bal}n, {tot}n, "
                    f"{_b(b)}, {_b(own)})"
                ),
                kind="bool",
            )
        )

    sym_ctor = {
        "znn": "SymZnn",
        "qsr": "SymQsr",
        "custom": "SymCustom",
    }
    meta_inputs = (
        ("min_valid", 1, 1, "custom", 1, 0),
        ("max_valid", 40, 10, "custom", 128, 18),
        ("empty_name", 0, 3, "custom", 10, 8),
        ("long_name", 41, 3, "custom", 10, 8),
        ("empty_sym", 5, 0, "custom", 10, 8),
        ("long_sym", 5, 11, "custom", 10, 8),
        ("reserved_znn", 5, 3, "znn", 10, 8),
        ("reserved_qsr", 5, 3, "qsr", 10, 8),
        ("empty_dom", 5, 3, "custom", 0, 8),
        ("long_dom", 5, 3, "custom", 129, 8),
        ("bad_dec", 5, 3, "custom", 10, 19),
    )
    for label, nl, sl, sk, dl, dec in meta_inputs:
        cases.append(
            OracleCase(
                id=f"metadata_{label}",
                op="valid_token_metadata",
                args={
                    "name_len": nl,
                    "sym_len": sl,
                    "sym_kind": sk,
                    "dom_len": dl,
                    "dec": dec,
                },
                expr=(
                    f"M.parallel_token_metadata_valid({nl}n, {sl}n, "
                    f"M.{sym_ctor[sk]}{{}}, {dl}n, {dec}n)"
                ),
                kind="bool",
            )
        )

    for is_znn in (False, True):
        for is_qsr in (False, True):
            for is_fav in (False, True):
                cases.append(
                    OracleCase(
                        id=f"trusted_z{int(is_znn)}_q{int(is_qsr)}_f{int(is_fav)}",
                        op="is_trusted_token",
                        args={
                            "is_znn": is_znn,
                            "is_qsr": is_qsr,
                            "is_favorite": is_fav,
                        },
                        expr=(
                            f"M.is_trusted_token({_b(is_znn)}, "
                            f"{_b(is_qsr)}, {_b(is_fav)})"
                        ),
                        kind="bool",
                    )
                )

    fav_inputs = (
        ("add_from_not_fav_ok", "not_favorite", "add", False, "FavNotFavorite", "FavAdd", "FavAddOk"),
        ("add_from_not_fav_err", "not_favorite", "add", True, "FavNotFavorite", "FavAdd", "FavAddErr"),
        ("rem_from_fav_ok", "favorite", "remove", False, "FavFavorite", "FavRemove", "FavRemoveOk"),
        ("rem_from_fav_err", "favorite", "remove", True, "FavFavorite", "FavRemove", "FavRemoveErr"),
        ("add_idempotent_fav_ok", "favorite", "add", False, "FavFavorite", "FavAdd", "FavAddOk"),
        ("add_from_fav_err", "favorite", "add", True, "FavFavorite", "FavAdd", "FavAddErr"),
        ("rem_idempotent_not_fav_ok", "not_favorite", "remove", False, "FavNotFavorite", "FavRemove", "FavRemoveOk"),
        ("rem_from_not_fav_err", "not_favorite", "remove", True, "FavNotFavorite", "FavRemove", "FavRemoveErr"),
    )
    for label, init_s, ev_s, fail_op, init_c, ev1_c, ev2_c in fav_inputs:
        cases.append(
            OracleCase(
                id=f"fav_{label}",
                op="fav_transition",
                args={"initial": init_s, "event": ev_s, "fail": fail_op},
                expr=f"_fmt_fav_step(M.{init_c}{{}}, M.{ev1_c}{{}}, M.{ev2_c}{{}})",
                kind="raw_json",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: p2p_htlc
# ---------------------------------------------------------------------------

_P2P_HTLC_HELPERS = """\
def _fmt_join_win(+exp_m: Nat, +now_m: Nat) -> String:
  sj = _jbool(M.can_safely_join_window(exp_m, now_m))
  rc = _jbool(M.can_reclaim(exp_m, now_m))
  ul = _jbool(M.can_unlock(exp_m, now_m))
  ("{\\"can_safely_join\\":" ++ sj) ++ ((",\\"can_reclaim\\":" ++ rc) ++ ((",\\"can_unlock\\":" ++ ul) ++ "}"))

def _fmt_htlc_role(+r: M.HtlcRole) -> String:
  match r:
    case M.InitialHtlc{}: "initial"
    case M.CounterHtlc{}: "counter"

def _fmt_funded_role(+dir: M.SwapDir, +has_counter: Bool) -> String:
  match dir has_counter:
    case M.Incoming{} False{}: "none"
    case d _: _fmt_htlc_role(M.funded_htlc_role(d))

def _wrap_err(+depth: Nat, +is_drift: Bool, +sec: Nat, +inner: M.SwapError) -> M.SwapError:
  match depth:
    case 0n: inner
    case 1n+p:
      match is_drift:
        case True{}: M.DriftWrap{_wrap_err(p, True{}, sec, inner), sec}
        case False{}: M.RollbackWrap{_wrap_err(p, False{}, sec, inner), sec}

def _fmt_sanitized(+s: M.SanitizedSummary) -> String:
  match s:
    case M.SummarySqlite{w, c}:
      ("{\\"kind\\":\\"sqlite\\",\\"wrapped\\":" ++ _jbool(w)) ++ ((",\\"code\\":" ++ Nat.show(c)) ++ "}")
    case M.SummaryRpc{c}:
      ("{\\"kind\\":\\"rpc\\",\\"wrapped\\":false,\\"code\\":" ++ Nat.show(c)) ++ "}"
    case M.SummaryTypeOnly{}:
      "{\\"kind\\":\\"type_only\\",\\"wrapped\\":false,\\"code\\":0}"

def _fmt_chg_pwd(+rekey_ok: Bool, +wp_ok: Bool) -> String:
  +res = M.change_password_txn(M.Storage{True{}, 1n, M.EncFile{1n}, M.NoFile{}, True{}}, 1n, 2n, rekey_ok, wp_ok)
  +st_out = M.chg_pwd_storage(res)
  suc = _jbool(M.chg_pwd_succeeded(res))
  com = _jbool(M.file_has_key(M.storage_primary(st_out), 2n))
  rb = _jbool(Bool.and(rekey_ok, M.file_has_key(M.storage_primary(st_out), 1n)))
  sr = _jbool(M.storage_sync_running(st_out))
  ("{\\"succeeded\\":" ++ suc) ++ ((",\\"committed\\":" ++ com) ++ ((",\\"rolled_back\\":" ++ rb) ++ ((",\\"sync_restarted\\":" ++ sr) ++ "}")))

def _fmt_reclaim(+o: M.ReclaimOutcome) -> String:
  ok = _jbool(M.reclaim_is_ok(o))
  dc = Nat.show(M.reclaim_derived_count(o))
  ("{\\"ok\\":" ++ ok) ++ ((",\\"derived_count\\":" ++ dc) ++ "}")

def _fmt_auto_unlock(+wo: Bool, +ns: Bool, +t1: Nat, +t2: Nat) -> String:
  +step1 = M.try_start_auto_unlock(M.AutoUnlock{False{}, None{}}, wo, ns, t1)
  +s1 = M.finish_auto_unlock(M.unlock_step_state(step1))
  +step2 = M.try_start_auto_unlock(s1, wo, ns, t2)
  f1 = _jbool(M.unlock_step_started(step1))
  f2 = _jbool(M.unlock_step_started(step2))
  ("{\\"first_started\\":" ++ f1) ++ ((",\\"second_started\\":" ++ f2) ++ "}")
"""


def _p2p_htlc_cases(depth: int, seed: int) -> list[OracleCase]:
    del depth, seed
    cases: list[OracleCase] = []

    win_inputs = (
        ("expired_past", 5, 10),
        ("expired_exact", 10, 10),
        ("in_buffer_5m", 15, 10),
        ("at_unlock_boundary_10m", 20, 10),
        ("unlock_ok_11m", 21, 10),
        ("join_below_419m", 429, 10),
        ("join_exact_420m", 430, 10),
        ("join_above_480m", 490, 10),
    )
    for label, exp_m, now_m in win_inputs:
        cases.append(
            OracleCase(
                id=f"join_win_{label}",
                op="join_window",
                args={"exp_min": exp_m, "now_min": now_m},
                expr=f"_fmt_join_win({exp_m}n, {now_m}n)",
                kind="raw_json",
            )
        )

    for direction, dctor in (("outgoing", "Outgoing"), ("incoming", "Incoming")):
        for has_counter in (False, True):
            cases.append(
                OracleCase(
                    id=f"funded_{direction}_c{int(has_counter)}",
                    op="funded_htlc_role",
                    args={"direction": direction, "has_counter": has_counter},
                    expr=f"_fmt_funded_role(M.{dctor}{{}}, {_b(has_counter)})",
                    kind="string",
                )
            )

    san_inputs = (
        ("sqlite_direct", "sqlite", 0, "drift", 19, 42),
        ("sqlite_drift_1", "sqlite", 1, "drift", 19, 43),
        ("sqlite_drift_4_max_ok", "sqlite", 4, "drift", 19, 44),
        ("sqlite_drift_5_capped", "sqlite", 5, "drift", 19, 45),
        ("sqlite_rollback_2", "sqlite", 2, "rollback", 5, 46),
        ("sqlite_rollback_5_capped", "sqlite", 5, "rollback", 5, 47),
        ("rpc_direct", "rpc", 0, "drift", 32000, 48),
        ("rpc_wrapped", "rpc", 1, "drift", 32000, 49),
        ("other_direct", "other", 0, "drift", 0, 50),
    )
    for label, kind, wdepth, wkind, code, stag in san_inputs:
        if kind == "sqlite":
            base_err = f"M.SqliteErr{{{code}n, {stag}n}}"
        elif kind == "rpc":
            base_err = f"M.RpcErr{{{code}n, {stag}n}}"
        else:
            base_err = f"M.OtherErr{{{stag}n}}"
        is_drift = wkind == "drift"
        # Use small code in Bend for rpc (or exact code if <= 200); note 32000n
        # is avoided by using code=25 for rpc so Peano Nat stays instant!
        bend_code = 25 if code > 200 else code
        actual_code = bend_code
        if kind == "sqlite":
            base_err = f"M.SqliteErr{{{bend_code}n, {stag}n}}"
        elif kind == "rpc":
            base_err = f"M.RpcErr{{{bend_code}n, {stag}n}}"
        cases.append(
            OracleCase(
                id=f"sanitize_{label}",
                op="sanitize_error",
                args={
                    "kind": kind,
                    "wrap_depth": wdepth,
                    "wrap_kind": wkind,
                    "code": actual_code,
                    "secret_tag": stag,
                },
                expr=(
                    f"_fmt_sanitized(M.sanitize_error("
                    f"_wrap_err({wdepth}n, {_b(is_drift)}, {stag}n, {base_err})))"
                ),
                kind="raw_json",
            )
        )

    for kl, bok in ((0, True), (31, True), (32, True), (32, False), (33, True)):
        cases.append(
            OracleCase(
                id=f"sqlcipher_len{kl}_b{int(bok)}",
                op="sqlcipher_key_valid",
                args={"key_len": kl, "bytes_ok": bok},
                expr=f"M.is_valid_sqlcipher_key({kl}n, {_b(bok)})",
                kind="bool",
            )
        )

    for rk in (False, True):
        for wp in (False, True):
            cases.append(
                OracleCase(
                    id=f"chg_pwd_rk{int(rk)}_wp{int(wp)}",
                    op="change_password_txn",
                    args={"rekey_ok": rk, "wallet_pwd_ok": wp},
                    expr=f"_fmt_chg_pwd({_b(rk)}, {_b(wp)})",
                    kind="raw_json",
                )
            )

    reclaim_inputs = (
        ("in_wallet_expired", True, True, False, 2, None, 10, 10),
        ("in_wallet_locked", True, True, False, 2, None, 20, 10),
        ("sw_lookahead_first", False, True, False, 2, 2, 10, 10),
        ("sw_lookahead_fourth", False, True, False, 2, 5, 10, 10),
        ("sw_lookahead_upper_50", False, True, False, 2, 51, 10, 10),
        ("sw_lookahead_out_51", False, True, False, 2, 52, 10, 10),
        ("sw_lookahead_still_locked", False, True, False, 2, 4, 20, 10),
        ("hw_missing_rejected", False, True, True, 2, 2, 10, 10),
        ("no_wallet_rejected", False, False, False, 2, 2, 10, 10),
        ("no_match_rejected", False, True, False, 2, None, 10, 10),
    )
    for label, iw, hw, is_hw, wlen, midx, exp_m, now_m in reclaim_inputs:
        cases.append(
            OracleCase(
                id=f"reclaim_{label}",
                op="reclaim_evaluate",
                args={
                    "in_wallet": iw,
                    "has_wallet": hw,
                    "is_hw": is_hw,
                    "wallet_len": wlen,
                    "match_idx": midx,
                    "exp_min": exp_m,
                    "now_min": now_m,
                },
                expr=(
                    f"_fmt_reclaim(M.evaluate_reclaim({_b(iw)}, {_b(hw)}, "
                    f"{_b(is_hw)}, {wlen}n, {_bend_maybe_nat(midx)}, "
                    f"{exp_m}n, {now_m}n))"
                ),
                kind="raw_json",
            )
        )

    for st_name, st_ctor in (
        ("pending", "Pending"),
        ("active", "Active"),
        ("completed", "Completed"),
        ("reclaimable", "Reclaimable"),
        ("unsuccessful", "Unsuccessful"),
        ("error", "Error"),
    ):
        cases.append(
            OracleCase(
                id=f"can_delete_{st_name}",
                op="can_delete_swap",
                args={"state": st_name},
                expr=f"M.can_delete_swap(M.{st_ctor}{{}})",
                kind="bool",
            )
        )

    arb_inputs = (
        ("wallet_closed", False, True, 10, 15),
        ("node_unsynced", True, False, 10, 15),
        ("cooldown_blocks_same_min", True, True, 10, 10),
        ("cooldown_blocks_1m", True, True, 10, 11),
        ("cooldown_expires_2m", True, True, 10, 12),
        ("cooldown_expires_5m", True, True, 10, 15),
    )
    for label, wo, ns, t1, t2 in arb_inputs:
        cases.append(
            OracleCase(
                id=f"auto_unlock_{label}",
                op="auto_unlock_arbiter",
                args={
                    "wallet_open": wo,
                    "node_synced": ns,
                    "first_min": t1,
                    "second_min": t2,
                },
                expr=f"_fmt_auto_unlock({_b(wo)}, {_b(ns)}, {t1}n, {t2}n)",
                kind="raw_json",
            )
        )

    par_swap_inputs = (
        ("all_ok_null_chain", 490, 10, 32, True, 1, None),
        ("all_ok_matching_chain", 430, 10, 32, True, 1, 1),
        ("window_too_short", 429, 10, 32, True, 1, 1),
        ("window_over_max_24h", 1451, 10, 32, True, 1, 1),
        ("bad_key_len", 490, 10, 31, True, 1, 1),
        ("bad_key_bytes", 490, 10, 32, False, 1, 1),
        ("chain_id_mismatch", 490, 10, 32, True, 1, 2),
    )
    for label, exp_m, now_m, kl, bok, ac, uc in par_swap_inputs:
        cases.append(
            OracleCase(
                id=f"parallel_swap_{label}",
                op="parallel_swap_safety_check",
                args={
                    "exp_min": exp_m,
                    "now_min": now_m,
                    "key_len": kl,
                    "bytes_ok": bok,
                    "active_chain": ac,
                    "updated_chain": uc,
                },
                expr=(
                    f"M.parallel_swap_safety_check("
                    f"True{{}}, False{{}}, False{{}}, {exp_m}n, {now_m}n, {now_m}n, "
                    f"True{{}}, False{{}}, {kl}n, {_b(bok)}, {ac}n, {_bend_maybe_nat(uc)})"
                ),
                kind="bool",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: accelerator
# ---------------------------------------------------------------------------

_ACCELERATOR_STATUS_CTOR = {
    "voting": "Voting",
    "active": "Active",
    "paid": "Paid",
    "closed": "Closed",
    "completed": "Completed",
}

_ACCELERATOR_HELPERS = """\
def _fmt_vote_method(+m: M.VoteMethod) -> String:
  match m:
    case M.ByName{}: "\\"by_name\\""
    case M.ByProdAddress{}: "\\"by_prod_address\\""

def _fmt_pillar_found(+res: Maybe<&2, M.PillarEntry>, +addr: Nat) -> String:
  match res:
    case None{}:
      "{\\"found_id\\":null,\\"vote_method\\":\\"none\\"}"
    case Some{M.Pillar{id, own, prod}}:
      vm = _fmt_vote_method(M.vote_method_for(M.Pillar{id, own, prod}, addr))
      ("{\\"found_id\\":" ++ Nat.show(id)) ++ ((",\\"vote_method\\":" ++ vm) ++ "}")

def _fmt_pillar_resolve(+pillars: List<&2, M.PillarEntry>, +addr: Nat) -> String:
  _fmt_pillar_found(M.pillar_for_address(pillars, addr), addr)

def _fmt_vote_summary(+yes: Nat, +no: Nat, +abs: Nat, +tp: Nat) -> String:
  qn = Nat.show(M.quorum_needed(tp))
  qr = _jbool(M.quorum_reached(M.vote_total(yes, no, abs), tp))
  hm = _jbool(M.has_majority(yes, no))
  ("{\\"quorum_needed\\":" ++ qn) ++ ((",\\"quorum_reached\\":" ++ qr) ++ ((",\\"has_majority\\":" ++ hm) ++ "}"))

def _fmt_don_retry_go(+flag: Bool, +a1: M.DonationAttempt, +f1: M.DonationForm, +retry_qsr_ok: Bool) -> String:
  match flag:
    case False{}:
      fsz = _jbool(M.attempt_sent_znn(a1))
      fsq = _jbool(M.attempt_sent_qsr(a1))
      fin = _jbool(M.don_status_is_submitted(M.form_status(f1)))
      ("{\\"first_sent_znn\\":" ++ fsz) ++ ((",\\"first_sent_qsr\\":" ++ fsq) ++ ((",\\"first_znn_submitted_flag\\":false,\\"retry_sent_znn\\":false,\\"retry_sent_qsr\\":false,\\"final_submitted\\":" ++ fin) ++ "}"))
    case True{}:
      +a2 = M.submit_donation_attempt(f1, True{}, retry_qsr_ok)
      fsz = _jbool(M.attempt_sent_znn(a1))
      fsq = _jbool(M.attempt_sent_qsr(a1))
      rsz = _jbool(M.attempt_sent_znn(a2))
      rsq = _jbool(M.attempt_sent_qsr(a2))
      fin = _jbool(M.don_status_is_submitted(M.form_status(M.attempt_form(a2))))
      ("{\\"first_sent_znn\\":" ++ fsz) ++ ((",\\"first_sent_qsr\\":" ++ fsq) ++ ((",\\"first_znn_submitted_flag\\":true,\\"retry_sent_znn\\":" ++ rsz) ++ ((",\\"retry_sent_qsr\\":" ++ rsq) ++ ((",\\"final_submitted\\":" ++ fin) ++ "}"))))

def _fmt_don_retry_res(+a1: M.DonationAttempt, +retry_qsr_ok: Bool) -> String:
  +f1 = M.attempt_form(a1)
  _fmt_don_retry_go(M.don_status_znn_submitted(M.form_status(f1)), a1, f1, retry_qsr_ok)

def _fmt_don_retry(+z: Nat, +q: Nat, +zok: Bool, +qok: Bool, +rqok: Bool) -> String:
  _fmt_don_retry_res(M.submit_donation_attempt(M.DonForm{z, q, M.DonInitial{}}, zok, qok), rqok)

def _tag_nv(+t: M.FilterTags) -> Bool:
  match t:
    case M.Tags{_, _, nv, _}: nv

def _tag_av(+t: M.FilterTags) -> Bool:
  match t:
    case M.Tags{_, _, _, av}: av

def _fmt_proj_filter(+hp: Bool, +tags: M.FilterTags, +pv: M.ProjectView) -> String:
  +eff = M.strip_pillar_tags(hp, tags)
  vis = _jbool(M.matches_project_list(hp, eff, pv))
  nvk = _jbool(_tag_nv(eff))
  avk = _jbool(_tag_av(eff))
  ("{\\"visible\\":" ++ vis) ++ ((",\\"needs_voting_kept\\":" ++ nvk) ++ ((",\\"already_voted_kept\\":" ++ avk) ++ "}"))

def _fmt_budget_phase(+obal: Nat, +zn: Nat, +qn: Nat, +pz: Nat, +pq: Nat, +phz: Nat, +phq: Nat) -> String:
  vp = _jbool(M.valid_project_budget(obal, zn, qn))
  rz = Nat.show(M.remaining_funds(zn, pz))
  rq = Nat.show(M.remaining_funds(qn, pq))
  vph = _jbool(M.valid_phase_funds(phz, phq, zn, pz, qn, pq))
  ("{\\"valid_project\\":" ++ vp) ++ ((",\\"remaining_znn\\":" ++ rz) ++ ((",\\"remaining_qsr\\":" ++ rq) ++ ((",\\"valid_phase\\":" ++ vph) ++ "}")))

def _fmt_phase_gate(+own: Bool, +pst: M.ProjectStatus, +lp: Maybe<&2, M.ProjectStatus>, +phst: M.ProjectStatus) -> String:
  cc = _jbool(M.can_create_phase(own, pst, lp))
  cu = _jbool(M.can_update_phase(own, phst))
  ("{\\"can_create\\":" ++ cc) ++ ((",\\"can_update\\":" ++ cu) ++ "}")
"""


def _accelerator_cases(depth: int, seed: int) -> list[OracleCase]:
    del depth, seed
    cases: list[OracleCase] = []

    pillar_inputs = (
        ("empty_list", [], 1),
        ("owner_match", [{"id": 1, "owner": 10, "producer": 20}], 10),
        ("producer_match", [{"id": 1, "owner": 10, "producer": 20}], 20),
        (
            "owner_beats_producer",
            [
                {"id": 1, "owner": 10, "producer": 20},
                {"id": 2, "owner": 20, "producer": 30},
            ],
            20,
        ),
        ("no_match", [{"id": 1, "owner": 10, "producer": 20}], 99),
    )
    for label, plist, addr in pillar_inputs:
        bend_pl = "Nil{}"
        for p in reversed(plist):
            bend_pl = f"(M.Pillar{{{p['id']}n, {p['owner']}n, {p['producer']}n}} <> {bend_pl})"
        cases.append(
            OracleCase(
                id=f"pillar_resolve_{label}",
                op="pillar_resolve",
                args={"pillars": plist, "addr": addr},
                expr=f"_fmt_pillar_resolve({bend_pl}, {addr}n)",
                kind="raw_json",
            )
        )

    vote_inputs = (
        ("quorum_33_of_100_short", 33, 0, 0, 100),
        ("quorum_34_of_100_reached", 34, 0, 0, 100),
        ("tie_no_majority", 2, 2, 0, 5),
        ("strict_majority", 3, 2, 0, 5),
        ("abstain_meets_quorum_no_maj", 0, 0, 4, 10),
        ("single_pillar_quorum", 1, 0, 0, 1),
        ("three_pillars_two_votes", 2, 0, 0, 3),
        ("three_pillars_one_vote_short", 1, 0, 0, 3),
    )
    for label, yes, no, abst, tp in vote_inputs:
        cases.append(
            OracleCase(
                id=f"vote_summary_{label}",
                op="vote_summary",
                args={"yes": yes, "no": no, "abstain": abst, "total_pillars": tp},
                expr=f"_fmt_vote_summary({yes}n, {no}n, {abst}n, {tp}n)",
                kind="raw_json",
            )
        )

    def _signed_expr(val: int) -> str:
        return f"M.NonNeg{{{val}n}}" if val >= 0 else f"M.Neg{{{-val - 1}n}}"

    don_valid_inputs = (
        ("neg_znn_pos_qsr", -1, 5, 10, 10),
        ("pos_znn_neg_qsr", 5, -1, 10, 10),
        ("both_zero", 0, 0, 10, 10),
        ("zero_balances", 0, 0, 0, 0),
        ("znn_only_ok", 1, 0, 10, 10),
        ("qsr_only_ok", 0, 1, 10, 10),
        ("both_pos_ok", 5, 5, 10, 10),
        ("znn_over_bal", 11, 0, 10, 10),
        ("qsr_over_bal", 0, 11, 10, 10),
    )
    for label, z, q, bz, bq in don_valid_inputs:
        cases.append(
            OracleCase(
                id=f"don_valid_{label}",
                op="donation_valid",
                args={"znn": z, "qsr": q, "bal_znn": bz, "bal_qsr": bq},
                expr=(
                    f"M.is_valid_donation({_signed_expr(z)}, {_signed_expr(q)}, "
                    f"{bz}n, {bq}n)"
                ),
                kind="bool",
            )
        )

    don_retry_inputs = (
        ("both_ok", 5, 10, True, True, True),
        ("znn_fails", 5, 10, False, True, True),
        ("partial_retry_qsr_ok", 5, 10, True, False, True),
        ("partial_retry_qsr_fail", 5, 10, True, False, False),
        ("znn_only_ok", 5, 0, True, True, True),
        ("qsr_only_ok", 0, 10, True, True, True),
        ("both_zero_fail", 0, 0, True, True, True),
    )
    for label, z, q, zok, qok, rqok in don_retry_inputs:
        cases.append(
            OracleCase(
                id=f"don_retry_{label}",
                op="donation_partial_retry",
                args={
                    "znn": z,
                    "qsr": q,
                    "znn_ok": zok,
                    "qsr_ok": qok,
                    "retry_qsr_ok": rqok,
                },
                expr=f"_fmt_don_retry({z}n, {q}n, {_b(zok)}, {_b(qok)}, {_b(rqok)})",
                kind="raw_json",
            )
        )

    filter_inputs = (
        ("non_pillar_active_visible", False, "active", False, False, False, False, False, False),
        ("non_pillar_voting_hidden", False, "voting", False, False, False, False, False, False),
        ("non_pillar_own_voting_visible", False, "voting", True, False, False, False, False, False),
        ("non_pillar_strips_voting_tags", False, "active", False, False, False, True, True, False),
        ("pillar_needs_voting_match", True, "voting", False, False, False, True, False, False),
        ("pillar_needs_voting_already_voted", True, "voting", False, False, False, True, False, True),
        ("pillar_already_voted_match", True, "voting", False, False, False, False, True, True),
        ("my_projects_filters_non_owner", True, "active", False, True, False, False, False, False),
        ("only_accepted_filters_voting", True, "voting", True, False, True, False, False, False),
    )
    for label, hp, st, own, mp, oa, nv, av, hv in filter_inputs:
        st_ctor = _ACCELERATOR_STATUS_CTOR[st]
        hnv = (st == "voting") and (not hv)
        hav = (st == "voting") and hv
        cases.append(
            OracleCase(
                id=f"proj_filter_{label}",
                op="project_list_filter",
                args={
                    "has_pillar": hp,
                    "status": st,
                    "is_owner": own,
                    "tag_my_projects": mp,
                    "tag_only_accepted": oa,
                    "tag_needs_voting": nv,
                    "tag_already_voted": av,
                    "has_voted": hv,
                },
                expr=(
                    f"_fmt_proj_filter({_b(hp)}, "
                    f"M.Tags{{{_b(mp)}, {_b(oa)}, {_b(nv)}, {_b(av)}}}, "
                    f"M.ProjView{{M.{st_ctor}{{}}, {_b(own)}, {_b(hnv)}, {_b(hav)}}})"
                ),
                kind="raw_json",
            )
        )

    budget_inputs = (
        ("exact_min_valid", 1, 10, 100, 0, 0, 10, 100),
        ("zero_fee_invalid", 0, 10, 100, 0, 0, 5, 50),
        ("below_znn_min", 1, 9, 100, 0, 0, 5, 50),
        ("below_qsr_min", 1, 10, 99, 0, 0, 5, 50),
        ("exact_remaining_valid", 1, 100, 500, 40, 200, 60, 300),
        ("phase_znn_over_rem", 1, 100, 500, 40, 200, 61, 300),
        ("phase_qsr_over_rem", 1, 100, 500, 40, 200, 60, 301),
        ("fully_paid_zero_phase", 1, 100, 500, 100, 500, 0, 0),
    )
    for label, ob, zn, qn, pz, pq, phz, phq in budget_inputs:
        cases.append(
            OracleCase(
                id=f"budget_{label}",
                op="project_budget_and_phase",
                args={
                    "owner_znn_bal": ob,
                    "znn_needed": zn,
                    "qsr_needed": qn,
                    "paid_znn": pz,
                    "paid_qsr": pq,
                    "phase_znn": phz,
                    "phase_qsr": phq,
                },
                expr=(
                    f"_fmt_budget_phase({ob}n, {zn}n, {qn}n, "
                    f"{pz}n, {pq}n, {phz}n, {phq}n)"
                ),
                kind="raw_json",
            )
        )

    gate_inputs = (
        ("owner_active_no_prev_voting", True, "active", "none", "voting"),
        ("owner_active_paid_prev_voting", True, "active", "paid", "voting"),
        ("owner_active_voting_prev_blocks_create", True, "active", "voting", "voting"),
        ("owner_voting_proj_blocks_create", True, "voting", "none", "voting"),
        ("non_owner_blocks_both", False, "active", "none", "voting"),
        ("owner_active_paid_active_phase_blocks_upd", True, "active", "paid", "active"),
    )
    for label, own, pst, lp, phst in gate_inputs:
        pst_c = f"M.{_ACCELERATOR_STATUS_CTOR[pst]}{{}}"
        lp_c = "None{}" if lp == "none" else f"Some{{M.{_ACCELERATOR_STATUS_CTOR[lp]}{{}}}}"
        phst_c = f"M.{_ACCELERATOR_STATUS_CTOR[phst]}{{}}"
        cases.append(
            OracleCase(
                id=f"phase_gate_{label}",
                op="phase_gate",
                args={
                    "is_owner": own,
                    "project_status": pst,
                    "last_phase_status": lp,
                    "phase_status": phst,
                },
                expr=f"_fmt_phase_gate({_b(own)}, {pst_c}, {lp_c}, {phst_c})",
                kind="raw_json",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: wallet_connect
# ---------------------------------------------------------------------------

_WC_HELPERS = """\
def _fmt_verify_sev(+s: M.VerifySeverity) -> String:
  match s:
    case M.SevVerified{}: "verified"
    case M.SevUnverified{}: "unverified"
    case M.SevInvalid{}: "invalid"
    case M.SevScam{}: "scam"

def _comma_if_wc(+first: Bool) -> String:
  match first:
    case True{}: ""
    case False{}: ","

def _fmt_chain_str(+c: M.ChainId) -> String:
  match c:
    case M.ChainMainnet{}: "\\"zenon:1\\""
    case M.ChainTestnet{}: "\\"zenon:3\\""
    case M.ChainUnsupported{id}: ("\\"zenon:" ++ Nat.show(id)) ++ "\\""

def _fmt_chains_go(+xs: List<&2, M.ChainId>, +first: Bool) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      (_comma_if_wc(first) ++ _fmt_chain_str(h)) ++ _fmt_chains_go(t, False{})

def _fmt_meth_str(+m: M.WcMethod) -> String:
  match m:
    case M.MethodZnnSign{}: "\\"znn_sign\\""
    case M.MethodZnnInfo{}: "\\"znn_info\\""
    case M.MethodZnnSend{}: "\\"znn_send\\""
    case M.MethodOther{}: "\\"other\\""

def _fmt_meths_go(+xs: List<&2, M.WcMethod>, +first: Bool) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      (_comma_if_wc(first) ++ _fmt_meth_str(h)) ++ _fmt_meths_go(t, False{})

def _fmt_ev_str(+e: M.WcEvent) -> String:
  match e:
    case M.EventChainIdChange{}: "\\"chainIdChange\\""
    case M.EventAddressChange{}: "\\"addressChange\\""
    case M.EventOther{}: "\\"other\\""

def _fmt_evs_go(+xs: List<&2, M.WcEvent>, +first: Bool) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      (_comma_if_wc(first) ++ _fmt_ev_str(h)) ++ _fmt_evs_go(t, False{})

def _fmt_approved_ns(+a: M.ApprovedNamespace) -> String:
  cs = _fmt_chains_go(M.approved_chains(a), True{})
  ms = _fmt_meths_go(M.approved_methods(a), True{})
  es = _fmt_evs_go(M.approved_events(a), True{})
  ("{\\"chains\\":[" ++ cs) ++ (("],\\"methods\\":[" ++ ms) ++ (("],\\"events\\":[" ++ es) ++ "]}"))

def _fmt_u32_list_go(+xs: List<&2, U32>, +first: Bool) -> String:
  match xs:
    case Nil{}: ""
    case h <> t:
      (_comma_if_wc(first) ++ U32.show(h)) ++ _fmt_u32_list_go(t, False{})

def _fmt_u32_list(+xs: List<&2, U32>) -> String:
  ("[" ++ _fmt_u32_list_go(xs, True{})) ++ "]"

def _fmt_val_outcome(+o: M.ValidationOutcome) -> U32:
  match o:
    case M.ValidOk{}: 0
    case M.ValidErr{c}: c

def _fmt_signer_res(+r: M.SignerResolution) -> String:
  match r:
    case M.SignerResolved{id}: Nat.show(id)
    case M.SignerRejectedUnsupportedAccounts{}: "-1"

def _fmt_reval_res(+r: M.RevalidationResult) -> U32:
  match r:
    case M.RevalOk{}: 0
    case M.RevalErr{c}: c
"""


def _wallet_connect_cases(depth: int, seed: int) -> list[OracleCase]:
    del depth, seed
    cases: list[OracleCase] = []

    src_ctor = {
        "direct": "DirectWc",
        "percent_once": "PercentEncodedOnce",
        "percent_twice": "PercentEncodedTwice",
        "query_param": "QueryUriParam",
        "regex_fallback": "RegexUriFallback",
        "non_wc": "NonWcInput",
    }
    uri_inputs = (
        ("direct_v2_ok", "direct", False, False, 2, True, True, True, False),
        ("percent_once_ok", "percent_once", False, True, 2, True, True, True, False),
        ("percent_twice_ok", "percent_twice", False, False, 2, True, True, True, False),
        ("query_param_ok", "query_param", False, False, 2, True, True, True, False),
        ("regex_fallback_ok", "regex_fallback", False, False, 2, True, True, True, False),
        ("non_wc_rejected", "non_wc", False, True, 2, True, True, True, False),
        ("v1_rejected", "direct", False, False, 1, True, True, True, False),
        ("missing_topic", "direct", False, False, 2, False, True, True, False),
        ("missing_relay", "direct", False, False, 2, True, False, True, False),
        ("missing_sym_key", "direct", False, False, 2, True, True, False, False),
        ("win_slash_on_windows_ok", "direct", True, False, 2, True, True, True, True),
        ("win_slash_on_unix_rejected", "direct", True, False, 2, True, True, True, False),
    )
    for label, src, hsq, how, ver, tne, rne, sne, isw in uri_inputs:
        cases.append(
            OracleCase(
                id=f"wc_uri_{label}",
                op="extract_wc_uri",
                args={
                    "source": src,
                    "has_windows_slash_query": hsq,
                    "has_outer_whitespace": how,
                    "version": ver,
                    "topic_non_empty": tne,
                    "relay_protocol_non_empty": rne,
                    "sym_key_non_empty": sne,
                    "is_windows": isw,
                },
                expr=(
                    f"M.is_wc_uri_extracted(M.extract_wc_uri(M.WcUriCandidate{{"
                    f"M.{src_ctor[src]}{{}}, {_b(hsq)}, {_b(how)}, {ver}n, "
                    f"{_b(tne)}, {_b(rne)}, {_b(sne)}}}, {_b(isw)}))"
                ),
                kind="bool",
            )
        )

    rk_inputs = (
        ("same_id_diff_fp", 1, 1, 10, 5, 1, 1, 20, 5),
        ("diff_id_same_fp", 1, 1, 10, 5, 1, 1, 10, 6),
        ("no_id_same_fp", 1, 1, 10, None, 1, 1, 10, None),
        ("no_id_diff_fp", 1, 1, 10, None, 1, 1, 20, None),
        ("id_vs_no_id", 1, 1, 10, 5, 1, 1, 10, None),
    )
    for label, m1, t1, f1, r1, m2, t2, f2, r2 in rk_inputs:
        cases.append(
            OracleCase(
                id=f"req_key_{label}",
                op="interactive_request_key_eq",
                args={
                    "method1": m1,
                    "topic1": t1,
                    "fp1": f1,
                    "request_id1": r1,
                    "method2": m2,
                    "topic2": t2,
                    "fp2": f2,
                    "request_id2": r2,
                },
                expr=(
                    f"M.request_key_eq("
                    f"M.interactive_request_key({m1}n, {t1}n, {f1}n, {_bend_maybe_nat(r1)}), "
                    f"M.interactive_request_key({m2}n, {t2}n, {f2}n, {_bend_maybe_nat(r2)}))"
                ),
                kind="bool",
            )
        )

    for label, kind, code, bend_err in (
        ("json_rpc", "json_rpc", 4001, "M.ErrJsonRpc{4001}"),
        ("reown_sign", "reown_sign", 5003, "M.ErrReownSign{5003}"),
        ("reown_core", "reown_core", 6000, "M.ErrReownCore{6000}"),
        ("unknown_5000", "unknown", 0, "M.ErrUnknown{}"),
    ):
        cases.append(
            OracleCase(
                id=f"err_code_{label}",
                op="wc_error_to_json_rpc_code",
                args={"kind": kind, "code": code},
                expr=f"M.wc_error_to_json_rpc_code({bend_err})",
                kind="u32",
            )
        )

    val_ctor = {
        "valid": "ValValid",
        "invalid": "ValInvalid",
        "unknown": "ValUnknown",
        "scam": "ValScam",
    }

    def _vctx_expr(present: bool, is_scam: bool, validation: str) -> str:
        if not present:
            return "M.NoVerifyContext{}"
        return f"M.HasVerifyContext{{{_b(is_scam)}, M.{val_ctor[validation]}{{}}}}"

    verify_inputs = (
        ("absent", False, False, "unknown"),
        ("valid_clean", True, False, "valid"),
        ("unknown_clean", True, False, "unknown"),
        ("invalid_clean", True, False, "invalid"),
        ("scam_validation", True, False, "scam"),
        ("scam_flag_overrides_valid", True, True, "valid"),
    )
    for label, pres, scam, val in verify_inputs:
        vexpr = _vctx_expr(pres, scam, val)
        cases.append(
            OracleCase(
                id=f"is_scam_{label}",
                op="is_verify_scam",
                args={"present": pres, "is_scam_flag": scam, "validation": val},
                expr=f"M.is_verify_scam({vexpr})",
                kind="bool",
            )
        )
        cases.append(
            OracleCase(
                id=f"describe_verify_{label}",
                op="describe_verify_context",
                args={"present": pres, "is_scam_flag": scam, "validation": val},
                expr=f"_fmt_verify_sev(M.describe_verify_context({vexpr}))",
                kind="string",
            )
        )

    scheme_ctor = {
        "http": "SchemeHttp",
        "https": "SchemeHttps",
        "javascript": "SchemeJavascript",
        "file": "SchemeFile",
        "data": "SchemeData",
        "other": "SchemeOther",
    }

    def _url_expr(malf: bool, sch: str, auth: bool, host: bool) -> str:
        if malf:
            return "M.UrlMissingOrMalformed{}"
        return f"M.UrlParsed{{M.{scheme_ctor[sch]}{{}}, {_b(auth)}, {_b(host)}}}"

    url_inputs = (
        ("https_ok", False, "https", True, True),
        ("http_ok", False, "http", True, True),
        ("javascript_blocked", False, "javascript", True, True),
        ("file_blocked", False, "file", True, True),
        ("data_blocked", False, "data", True, True),
        ("ftp_blocked", False, "other", True, True),
        ("malformed_blocked", True, "https", True, True),
        ("no_authority_blocked", False, "https", False, True),
        ("empty_host_blocked", False, "https", True, False),
    )
    for label, malf, sch, auth, host in url_inputs:
        cases.append(
            OracleCase(
                id=f"url_{label}",
                op="sanitize_http_url",
                args={
                    "malformed": malf,
                    "scheme": sch,
                    "has_authority": auth,
                    "host_non_empty": host,
                },
                expr=f"M.is_url_allowed(M.sanitize_http_url({_url_expr(malf, sch, auth, host)}))",
                kind="bool",
            )
        )

    for kind, tid, fid, raw_e in (
        ("null", 1, 9, "M.DisplayNull{}"),
        ("whitespace", 1, 9, "M.DisplayWhitespaceOnly{}"),
        ("literal_null", 1, 9, "M.DisplayLiteralNull{}"),
        ("text", 7, 9, "M.DisplayText{7n}"),
    ):
        cases.append(
            OracleCase(
                id=f"display_{kind}",
                op="display_value",
                args={"kind": kind, "text_id": tid, "fallback_id": fid},
                expr=f"M.display_value({raw_e}, {fid}n)",
                kind="nat",
            )
        )

    def _chain_expr_str(caip: str) -> str:
        if caip == "zenon:1":
            return "M.ChainMainnet{}"
        if caip == "zenon:3":
            return "M.ChainTestnet{}"
        return "M.ChainUnsupported{99n}"

    def _meth_expr_str(m: str) -> str:
        return {
            "znn_sign": "M.MethodZnnSign{}",
            "znn_info": "M.MethodZnnInfo{}",
            "znn_send": "M.MethodZnnSend{}",
        }.get(m, "M.MethodOther{}")

    def _ev_expr_str(e: str) -> str:
        return {
            "chainIdChange": "M.EventChainIdChange{}",
            "addressChange": "M.EventAddressChange{}",
        }.get(e, "M.EventOther{}")

    def _ns_list_expr(entries: list[dict[str, object]]) -> str:
        res = "Nil{}"
        for ent in reversed(entries):
            ns_c = "M.NsZenon{}" if ent["ns_key"] == "zenon" else "M.NsOther{}"
            cs_e = "Nil{}"
            for c in reversed(ent["chains"]):  # type: ignore[arg-type]
                cs_e = f"({_chain_expr_str(c)} <> {cs_e})"
            ms_e = "Nil{}"
            for m in reversed(ent["methods"]):  # type: ignore[arg-type]
                ms_e = f"({_meth_expr_str(m)} <> {ms_e})"
            es_e = "Nil{}"
            for e in reversed(ent["events"]):  # type: ignore[arg-type]
                es_e = f"({_ev_expr_str(e)} <> {es_e})"
            res = f"(M.NamespaceEntry{{{ns_c}, {cs_e}, {ms_e}, {es_e}}} <> {res})"
        return res

    req_ns_inputs: tuple[tuple[str, int, list[dict[str, object]]], ...] = (
        ("empty_mainnet_ok", 1, []),
        ("valid_mainnet", 1, [{"ns_key": "zenon", "chains": ["zenon:1"], "methods": ["znn_info", "znn_send"], "events": ["chainIdChange"]}]),
        ("valid_testnet", 3, [{"ns_key": "zenon", "chains": ["zenon:3"], "methods": ["znn_sign"], "events": ["addressChange"]}]),
        ("unsupported_active_chain", 99, [{"ns_key": "zenon", "chains": ["zenon:1"], "methods": ["znn_info"], "events": []}]),
        ("non_zenon_ns", 1, [{"ns_key": "eip155", "chains": ["eip155:1"], "methods": ["eth_sendTransaction"], "events": []}]),
        ("wrong_chain_for_mainnet", 1, [{"ns_key": "zenon", "chains": ["zenon:3"], "methods": ["znn_info"], "events": []}]),
        ("unsupported_method", 1, [{"ns_key": "zenon", "chains": ["zenon:1"], "methods": ["eth_sign"], "events": []}]),
        ("unsupported_event", 1, [{"ns_key": "zenon", "chains": ["zenon:1"], "methods": ["znn_info"], "events": ["accountsChanged"]}]),
    )
    for label, acid, entries in req_ns_inputs:
        cases.append(
            OracleCase(
                id=f"req_ns_{label}",
                op="unsupported_required_namespace_reason",
                args={"active_chain_id": acid, "entries": entries},
                expr=(
                    f"M.is_ns_accepted(M.unsupported_required_namespace_reason("
                    f"M.chain_from_nat({acid}n), {_ns_list_expr(entries)}))"
                ),
                kind="bool",
            )
        )

    app_ns_inputs: tuple[tuple[str, int, list[dict[str, object]], list[dict[str, object]]], ...] = (
        ("empty_grants_all", 1, [], []),
        ("req_subset_mainnet", 1, [{"ns_key": "zenon", "chains": ["zenon:1"], "methods": ["znn_info", "znn_send"], "events": ["addressChange"]}], []),
        (
            "opt_filters_non_zenon_and_bad_method",
            1,
            [{"ns_key": "zenon", "chains": ["zenon:1"], "methods": ["znn_info"], "events": ["chainIdChange"]}],
            [
                {"ns_key": "eip155", "chains": ["eip155:1"], "methods": ["eth_sign"], "events": []},
                {"ns_key": "zenon", "chains": ["zenon:1"], "methods": ["znn_sign", "bad_meth"], "events": ["addressChange", "bad_ev"]},
            ],
        ),
        ("testnet_req_only", 3, [{"ns_key": "zenon", "chains": ["zenon:3"], "methods": ["znn_sign"], "events": []}], []),
    )
    for label, acid, reqs, opts in app_ns_inputs:
        cases.append(
            OracleCase(
                id=f"app_ns_{label}",
                op="build_approved_namespaces",
                args={"active_chain_id": acid, "required": reqs, "optional": opts},
                expr=(
                    f"_fmt_approved_ns(M.build_approved_namespaces("
                    f"M.chain_from_nat({acid}n), {_ns_list_expr(reqs)}, {_ns_list_expr(opts)}))"
                ),
                kind="raw_json",
            )
        )

    for label, msg in (
        ("empty", ""),
        ("one_char", "a"),
        ("hello", "Hello"),
        ("ten_digits", "0123456789"),
        ("zenon", "Zenon!"),
    ):
        msg_bytes = list(msg.encode("utf-8"))
        cases.append(
            OracleCase(
                id=f"sign_payload_{label}",
                op="encode_signed_message_payload",
                args={"message": msg},
                expr=f"_fmt_u32_list(M.encode_signed_message_payload({_bend_u32_list(msg_bytes)}))",
                kind="raw_json",
            )
        )

    bt_ctor = {
        "user_send": "BlockUserSend",
        "user_receive": "BlockUserReceive",
        "contract_send": "BlockContractSend",
        "contract_receive": "BlockContractReceive",
    }
    sch_ctor = {"mainnet": "ChainMainnet", "testnet": "ChainTestnet"}

    def _blk_expr(bt: str, fhe: bool, bcid: int, sch: str) -> str:
        fh = "M.HashEmpty{}" if fhe else "M.HashNonEmpty{1n}"
        return f"M.SendAccountBlock{{M.{bt_ctor[bt]}{{}}, {fh}, {bcid}n, M.{sch_ctor[sch]}{{}}}}"

    blk_inputs = (
        ("valid_mainnet", "user_send", True, 1, "mainnet", 1),
        ("valid_testnet", "user_send", True, 3, "testnet", 3),
        ("reject_user_receive", "user_receive", True, 1, "mainnet", 1),
        ("reject_contract_send", "contract_send", True, 1, "mainnet", 1),
        ("reject_contract_receive", "contract_receive", True, 1, "mainnet", 1),
        ("reject_nonempty_from_hash", "user_send", False, 1, "mainnet", 1),
        ("reject_block_chain_mismatch", "user_send", True, 3, "mainnet", 1),
        ("reject_session_chain_mismatch", "user_send", True, 1, "testnet", 1),
    )
    for label, bt, fhe, bcid, sch, acid in blk_inputs:
        cases.append(
            OracleCase(
                id=f"send_blk_{label}",
                op="validate_send_account_block",
                args={
                    "block_type": bt,
                    "from_hash_empty": fhe,
                    "block_chain_id": bcid,
                    "session_chain": sch,
                    "active_chain_id": acid,
                },
                expr=f"_fmt_val_outcome(M.validate_send_account_block({_blk_expr(bt, fhe, bcid, sch)}, {acid}n))",
                kind="u32",
            )
        )

    def _req_addr_expr(rk: str, rid: int) -> str:
        if rk == "none":
            return "M.ReqAddrNone{}"
        if rk == "empty":
            return "M.ReqAddrEmpty{}"
        return f"M.ReqAddrValue{{{rid}n}}"

    signer_inputs = (
        ("none_uses_active", 0, "none", 0, [0, 1]),
        ("empty_uses_active", 1, "empty", 0, [0, 1]),
        ("owned_requested_ok", 0, "value", 1, [0, 1]),
        ("foreign_requested_rejected", 0, "value", 2, [0, 1]),
        ("empty_owned_rejected", 0, "value", 0, []),
    )
    for label, aid, rk, rid, owned in signer_inputs:
        cases.append(
            OracleCase(
                id=f"signer_{label}",
                op="resolve_signer_address",
                args={
                    "active_addr_id": aid,
                    "req_kind": rk,
                    "req_addr_id": rid,
                    "owned_ids": owned,
                },
                expr=(
                    f"_fmt_signer_res(M.resolve_signer_address("
                    f"{aid}n, {_req_addr_expr(rk, rid)}, {_bend_nat_list(owned)}))"
                ),
                kind="raw_json",
            )
        )

    imeth_ctor = {
        "znn_info": "InteractiveZnnInfo",
        "znn_sign": "InteractiveZnnSign",
        "znn_send": "InteractiveZnnSend",
    }
    reval_inputs = (
        ("locked_9000", "znn_send", True, True, True, True, "mainnet", "mainnet", 1),
        ("inactive_session_5001", "znn_send", False, False, True, True, "mainnet", "mainnet", 1),
        ("not_pending_5005", "znn_send", False, True, True, False, "mainnet", "mainnet", 1),
        ("no_req_id_skips_pending", "znn_send", False, True, False, False, "mainnet", "mainnet", 1),
        ("chain_drift_send_5003", "znn_send", False, True, True, True, "mainnet", "mainnet", 3),
        ("chain_drift_sign_5003", "znn_sign", False, True, True, True, "mainnet", "testnet", 1),
        ("chain_drift_info_ok", "znn_info", False, True, True, True, "mainnet", "mainnet", 3),
        ("all_valid_ok", "znn_send", False, True, True, True, "mainnet", "mainnet", 1),
    )
    for label, meth, lock, sact, hrid, pend, svc_c, sess_c, acid in reval_inputs:
        cases.append(
            OracleCase(
                id=f"reval_{label}",
                op="revalidate_interactive_request",
                args={
                    "method": meth,
                    "wallet_locked": lock,
                    "session_active": sact,
                    "has_request_id": hrid,
                    "request_still_pending": pend,
                    "service_chain": svc_c,
                    "session_chain": sess_c,
                    "active_chain_id": acid,
                },
                expr=(
                    f"_fmt_reval_res(M.revalidate_interactive_request("
                    f"M.{imeth_ctor[meth]}{{}}, M.RevalidationState{{"
                    f"{_b(lock)}, {_b(sact)}, {_b(hrid)}, {_b(pend)}, "
                    f"M.{sch_ctor[svc_c]}{{}}, M.{sch_ctor[sess_c]}{{}}, "
                    f"M.chain_from_nat({acid}n)}}))"
                ),
                kind="u32",
            )
        )

    preflight_inputs = (
        ("all_ok", True, False, "valid", False, "https", True, True, "user_send", True, 1, "mainnet", 1, 0, "value", 1, [0, 1], False, True, True, True, "mainnet"),
        ("scam_blocks", True, True, "valid", False, "https", True, True, "user_send", True, 1, "mainnet", 1, 0, "value", 1, [0, 1], False, True, True, True, "mainnet"),
        ("js_url_blocks", True, False, "valid", False, "javascript", True, True, "user_send", True, 1, "mainnet", 1, 0, "value", 1, [0, 1], False, True, True, True, "mainnet"),
        ("bad_block_blocks", True, False, "valid", False, "https", True, True, "user_receive", True, 1, "mainnet", 1, 0, "value", 1, [0, 1], False, True, True, True, "mainnet"),
        ("foreign_signer_blocks", True, False, "valid", False, "https", True, True, "user_send", True, 1, "mainnet", 1, 0, "value", 2, [0, 1], False, True, True, True, "mainnet"),
        ("locked_wallet_blocks", True, False, "valid", False, "https", True, True, "user_send", True, 1, "mainnet", 1, 0, "value", 1, [0, 1], True, True, True, True, "mainnet"),
        ("chain_drift_blocks", True, False, "valid", False, "https", True, True, "user_send", True, 1, "mainnet", 3, 0, "value", 1, [0, 1], False, True, True, True, "mainnet"),
    )
    for (
        label, cp, sf, val, um, us, ua, uh, bt, fhe, bcid, sch, acid,
        aid, rk, rid, owned, wl, sa, hrid, pend, svc_c
    ) in preflight_inputs:
        cases.append(
            OracleCase(
                id=f"preflight_{label}",
                op="parallel_send_preflight",
                args={
                    "ctx_present": cp,
                    "is_scam_flag": sf,
                    "validation": val,
                    "url_malformed": um,
                    "url_scheme": us,
                    "url_has_authority": ua,
                    "url_host_non_empty": uh,
                    "block_type": bt,
                    "from_hash_empty": fhe,
                    "block_chain_id": bcid,
                    "session_chain": sch,
                    "active_chain_id": acid,
                    "active_addr_id": aid,
                    "req_kind": rk,
                    "req_addr_id": rid,
                    "owned_ids": owned,
                    "wallet_locked": wl,
                    "session_active": sa,
                    "has_request_id": hrid,
                    "request_still_pending": pend,
                    "service_chain": svc_c,
                },
                expr=(
                    f"M.parallel_send_preflight("
                    f"{_vctx_expr(cp, sf, val)}, {_url_expr(um, us, ua, uh)}, "
                    f"{_blk_expr(bt, fhe, bcid, sch)}, {acid}n, "
                    f"{aid}n, {_req_addr_expr(rk, rid)}, {_bend_nat_list(owned)}, "
                    f"M.RevalidationState{{{_b(wl)}, {_b(sa)}, {_b(hrid)}, {_b(pend)}, "
                    f"M.{sch_ctor[svc_c]}{{}}, M.{sch_ctor[sch]}{{}}, M.chain_from_nat({acid}n)}})"
                ),
                kind="bool",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Domain: wc_crash_safety
# ---------------------------------------------------------------------------

_WC_CRASH_SAFETY_HELPERS = """\
def _fmt_store_mode(+m: M.StoreMode) -> String:
  match m:
    case M.ModeSecure{}: "secure"
    case M.ModeTransientFallback{}: "transient_fallback"
    case M.ModeAuthoritativeFallback{}: "authoritative_fallback"

def _fmt_isolation(+key: M.StoreKey, +owned: List<&2, Nat>) -> String:
  del = _jbool(M.can_delete_key(M.ModeAuthoritativeFallback{}, True{}, owned, key))
  +snap = M.delete_all_fallback_snapshot(M.FallbackStoreSnapshot{True{}, 2n, 1n})
  fp = _jbool(M.snap_flag_present(snap))
  fr = _jbool(Nat.is_gt(M.snap_foreign_count(snap), 0n))
  ("{\\"deleted\\":" ++ del) ++ ((",\\"flag_preserved\\":" ++ fp) ++ ((",\\"foreign_preserved\\":" ++ fr) ++ "}"))

def _fmt_maybe_nat_json(+m: Maybe<&2, Nat>) -> String:
  match m:
    case None{}: "null"
    case Some{n}: Nat.show(n)

def _fmt_reconcile_view(+v: Maybe<&2, M.EntryVal>) -> String:
  match v:
    case None{}: "{\\"present\\":false,\\"sub_a\\":null,\\"sub_b\\":null}"
    case Some{M.EntryVal{sa, sb}}:
      ("{\\"present\\":true,\\"sub_a\\":" ++ _fmt_maybe_nat_json(sa)) ++ ((",\\"sub_b\\":" ++ _fmt_maybe_nat_json(sb)) ++ "}")

def _fmt_mig_commit(+r: M.MigrationCommitResult) -> String:
  mp = _jbool(M.migration_marker_persisted(r))
  nm = _fmt_store_mode(M.migration_next_mode(r))
  ("{\\"marker_persisted\\":" ++ mp) ++ ((",\\"next_mode\\":\\"" ++ nm) ++ "\\"}")

def _fmt_cleanup_commit(+r: M.CleanupCommitResult) -> String:
  md = _jbool(M.cleanup_marker_deleted(r))
  cd = _jbool(M.cleanup_copies_deleted(r))
  ("{\\"marker_deleted\\":" ++ md) ++ ((",\\"copies_deleted\\":" ++ cd) ++ "}")

def _fmt_relay_unsub(+st: M.RelayTopicState) -> String:
  tm = _jbool(Nat.is_gt(M.relay_topic_map_id(st), 0n))
  pr = _jbool(Nat.is_gt(M.relay_preserved_id(st), 0n))
  un = _jbool(M.relay_unconfirmed(st))
  ("{\\"topic_map_kept\\":" ++ tm) ++ ((",\\"preserved_id_present\\":" ++ pr) ++ ((",\\"unconfirmed\\":" ++ un) ++ "}"))

def _reset_rem_sessions(+delete_ok: Bool) -> Nat:
  match delete_ok:
    case True{}: 0n
    case False{}: 1n

def _fmt_reset_durability(+mw_ok: Bool, +del_ok: Bool) -> String:
  match mw_ok:
    case False{}:
      pd = _jbool(M.sweep_performed_deletes(M.reset_sweep_step(False{})))
      ("{\\"performed_deletes\\":" ++ pd) ++ ",\\"marker_cleared\\":true}"
    case True{}:
      pd = _jbool(M.sweep_performed_deletes(M.reset_sweep_step(True{})))
      mc = _jbool(M.should_clear_reset_marker(_reset_rem_sessions(del_ok), 0n, 1n, 1n, False{}))
      ("{\\"performed_deletes\\":" ++ pd) ++ ((",\\"marker_cleared\\":" ++ mc) ++ "}")

def _act_is_retry(+a: M.RequestAction) -> Bool:
  match a:
    case M.ActionRetryCachedDelivery{_}: True{}
    case _: False{}

def _add_handler_call(+base: Nat, +exec: Bool) -> Nat:
  match exec:
    case True{}: 1n+base
    case False{}: base

def _fmt_idem_delivery(+first_ok: Bool, +sess_act: Bool) -> String:
  +a1 = M.decide_request_action(M.ReqFresh{}, True{}, False{})
  +c1 = _add_handler_call(0n, M.action_executes_handler(a1))
  +st1 = M.post_handler_delivery_step(42n, first_ok, False{})
  +a2 = M.decide_request_action(st1, sess_act, False{})
  +c2 = _add_handler_call(c1, M.action_executes_handler(a2))
  rc = _jbool(_act_is_retry(a2))
  ("{\\"handler_calls\\":" ++ Nat.show(c2)) ++ ((",\\"retried_cached_delivery\\":" ++ rc) ++ "}")
"""


def _wc_crash_safety_cases(depth: int, seed: int) -> list[OracleCase]:
    del depth, seed
    cases: list[OracleCase] = []

    boot_inputs = (
        ("none_os_ok", "none", False, False, False, False, True, True, True, False),
        ("none_os_read_fail", "none", False, False, False, False, False, True, True, False),
        ("authoritative_sticky", "authoritative", False, False, False, False, True, True, True, False),
        ("legacy_authoritative", "legacy", False, False, False, False, True, True, True, False),
        ("transient_read_fail", "transient", False, False, False, True, False, True, True, False),
        ("transient_empty_kc_stays_transient", "transient", False, False, False, True, True, True, True, False),
        ("transient_kc_reconcile_ok", "transient", False, False, False, True, True, True, True, True),
        ("transient_kc_reconcile_fail_auth", "transient", False, False, False, True, True, False, True, True),
        ("transient_kc_reconcile_fail_fb_fail", "transient", False, False, False, True, True, False, False, True),
        ("transient_cleared_all_reconciles", "transient", True, False, False, False, True, True, True, False),
    )
    for label, mk, ca, hd, hr, ht, orok, orwok, fwok, kc in boot_inputs:
        if mk == "none":
            mk_e = "M.MarkerNone{}"
        elif mk == "authoritative":
            mk_e = "M.MarkerAuthoritative{}"
        elif mk == "legacy":
            mk_e = "M.MarkerLegacy{}"
        else:
            mk_e = f"M.MarkerTransient{{{_b(ca)}, {_b(hd)}, {_b(hr)}, {_b(ht)}}}"
        cases.append(
            OracleCase(
                id=f"boot_{label}",
                op="store_boot_mode",
                args={
                    "marker": mk,
                    "cleared_all": ca,
                    "has_deleted": hd,
                    "has_replaced": hr,
                    "has_transient_keys": ht,
                    "os_read_ok": orok,
                    "os_reconcile_write_ok": orwok,
                    "fallback_write_ok": fwok,
                    "keychain_had_entries": kc,
                },
                expr=(
                    f"_fmt_store_mode(M.store_boot_mode("
                    f"{mk_e}, {_b(orok)}, {_b(orwok)}, {_b(fwok)}, {_b(kc)}))"
                ),
                kind="string",
            )
        )

    op_exprs = {
        "read": "M.StoreOpRead{}",
        "write": "M.StoreOpWrite{}",
        "delete": "M.StoreOpDelete{}",
        "delete_all": "M.StoreOpDeleteAll{}",
        "restart": "M.StoreOpRestart{False{}, False{}, False{}, False{}, True{}, False{}}",
    }
    for op_name in ("read", "write", "delete", "delete_all", "restart"):
        cases.append(
            OracleCase(
                id=f"sticky_{op_name}_os_ok",
                op="store_authoritative_sticky_step",
                args={"op": op_name, "os_ok": True},
                expr=(
                    f"_fmt_store_mode(M.store_step_mode("
                    f"M.ModeAuthoritativeFallback{{}}, {op_exprs[op_name]}, True{{}}, True{{}}))"
                ),
                kind="string",
            )
        )
    for op_name in ("write", "restart"):
        cases.append(
            OracleCase(
                id=f"sticky_{op_name}_os_fail",
                op="store_authoritative_sticky_step",
                args={"op": op_name, "os_ok": False},
                expr=(
                    f"_fmt_store_mode(M.store_step_mode("
                    f"M.ModeAuthoritativeFallback{{}}, {op_exprs[op_name]}, False{{}}, True{{}}))"
                ),
                kind="string",
            )
        )

    iso_inputs = (
        ("fallback_flag", True, "M.KeyFallbackFlag{}"),
        ("foreign", True, "M.KeyForeign{9n}"),
        ("owned_present", True, "M.KeyOwned{1n}"),
        ("owned_absent", False, "M.KeyOwned{1n}"),
    )
    for label, opres, kexpr in iso_inputs:
        kk = "owned" if label.startswith("owned") else label
        owned_l = "(1n <> Nil{})" if opres else "Nil{}"
        cases.append(
            OracleCase(
                id=f"iso_{label}",
                op="store_isolation_and_delete_all",
                args={"key_kind": kk, "owned_present": opres},
                expr=f"_fmt_isolation({kexpr}, {owned_l})",
                kind="raw_json",
            )
        )

    def _entry_opt(pres: bool, sa: int | None, sb: int | None) -> str:
        if not pres:
            return "None{}"
        return f"Some{{M.EntryVal{{{_bend_maybe_nat(sa)}, {_bend_maybe_nat(sb)}}}}}"

    rec_inputs = (
        ("cleared_all_wipes_os", True, False, False, True, 1, 2, False, None, None),
        ("cleared_all_keeps_tr", True, False, False, True, 1, 2, True, 7, None),
        ("deleted_tombstone", False, True, False, True, 1, 2, False, None, None),
        ("replaced_tr_wins", False, False, True, True, 1, 2, True, 8, None),
        ("absent_os_tr_wins", False, False, False, False, None, None, True, 4, 5),
        ("merge_missing_subkeys", False, False, False, True, 1, None, True, 9, 2),
    )
    for label, ca, idel, irep, opres, osa, osb, tpres, tsa, tsb in rec_inputs:
        cases.append(
            OracleCase(
                id=f"reconcile_{label}",
                op="store_reconcile_key_view",
                args={
                    "cleared_all": ca,
                    "in_deleted_keys": idel,
                    "in_replaced_keys": irep,
                    "os_present": opres,
                    "os_sub_a": osa,
                    "os_sub_b": osb,
                    "tr_present": tpres,
                    "tr_sub_a": tsa,
                    "tr_sub_b": tsb,
                },
                expr=(
                    f"_fmt_reconcile_view(M.reconcile_key_view("
                    f"{_b(ca)}, {_b(idel)}, {_b(irep)}, "
                    f"{_entry_opt(opres, osa, osb)}, {_entry_opt(tpres, tsa, tsb)}))"
                ),
                kind="raw_json",
            )
        )

    for eok in (False, True):
        for mok in (False, True):
            cases.append(
                OracleCase(
                    id=f"mig_e{int(eok)}_m{int(mok)}",
                    op="store_migration_commit_order",
                    args={"entries_write_ok": eok, "marker_write_ok": mok},
                    expr=f"_fmt_mig_commit(M.migrate_to_authoritative({_b(eok)}, {_b(mok)}))",
                    kind="raw_json",
                )
            )

    for mdok in (False, True):
        for cdok in (False, True):
            cases.append(
                OracleCase(
                    id=f"cleanup_m{int(mdok)}_c{int(cdok)}",
                    op="store_reconciliation_cleanup_order",
                    args={"marker_delete_ok": mdok, "copies_delete_ok": cdok},
                    expr=f"_fmt_cleanup_commit(M.clear_transient_fallback_data({_b(mdok)}, {_b(cdok)}))",
                    kind="raw_json",
                )
            )

    relay_scenarios = (
        (
            "offline_fail",
            "M.relay_finish_unsubscribe(M.RelayTopicState{1n, 0n, 1n, 0n, 1n, 1n, False{}}, 1n, 0n, 1n, False{}, False{})",
        ),
        (
            "rpc_confirmed",
            "M.relay_finish_unsubscribe(M.RelayTopicState{1n, 0n, 1n, 0n, 1n, 1n, False{}}, 1n, 0n, 1n, False{}, True{})",
        ),
        (
            "stale_sub_fence",
            "M.relay_finish_unsubscribe(M.RelayTopicState{2n, 2n, 1n, 0n, 2n, 0n, False{}}, 1n, 0n, 1n, True{}, False{})",
        ),
        (
            "concurrent_unsub_fence",
            "M.relay_finish_unsubscribe(M.RelayTopicState{2n, 0n, 2n, 2n, 0n, 0n, False{}}, 1n, 0n, 1n, False{}, False{})",
        ),
    )
    for scen, expr in relay_scenarios:
        cases.append(
            OracleCase(
                id=f"relay_unsub_{scen}",
                op="relay_unsubscribe_fencing",
                args={"scenario": scen},
                expr=f"_fmt_relay_unsub({expr})",
                kind="raw_json",
            )
        )

    restore_inputs = (
        ("cold_restore_ok", False, False, False, True),
        ("active_sub_blocks", True, False, False, True),
        ("existing_preserved_blocks", False, True, False, True),
        ("topic_map_entry_blocks", False, False, True, True),
        ("empty_persisted_ignored", False, False, False, False),
    )
    for label, has_sub, has_pr, has_tm, non_empty in restore_inputs:
        lsub = "1n" if has_sub else "0n"
        tm = "1n" if (has_sub or has_tm) else "0n"
        pr = "1n" if has_pr else "0n"
        pid = "9n" if non_empty else "0n"
        cases.append(
            OracleCase(
                id=f"relay_restore_{label}",
                op="relay_restore_preserved_id",
                args={
                    "has_active_sub": has_sub,
                    "has_existing_preserved": has_pr,
                    "has_topic_map_entry": has_tm,
                    "persisted_id_non_empty": non_empty,
                },
                expr=(
                    f"Nat.is_eq(M.relay_preserved_id(M.relay_restore_preserved_id("
                    f"M.RelayTopicState{{1n, {lsub}, 0n, 0n, {tm}, {pr}, False{{}}}}, {pid})), 9n)"
                ),
                kind="bool",
            )
        )

    for op_kind, expr in (
        ("pair_during_pending_reset", "M.can_admit_pair(True{}, False{}, True{})"),
        ("approve_during_pending_reset", "M.can_admit_approve_session(False{}, True{}, True{})"),
        ("finalize_after_gen_advance", "M.can_finalize_approved_session(False{}, True{}, False{}, 2n, 1n, True{})"),
        ("finalize_matching_gen", "M.can_finalize_approved_session(False{}, True{}, False{}, 1n, 1n, True{})"),
    ):
        cases.append(
            OracleCase(
                id=f"svc_admit_{op_kind}",
                op="service_reset_admission_and_finalize",
                args={"op_kind": op_kind},
                expr=expr,
                kind="bool",
            )
        )

    for mw in (False, True):
        for ds in (False, True):
            cases.append(
                OracleCase(
                    id=f"reset_dur_m{int(mw)}_d{int(ds)}",
                    op="service_reset_marker_durability",
                    args={"marker_write_ok": mw, "delete_succeeds": ds},
                    expr=f"_fmt_reset_durability({_b(mw)}, {_b(ds)})",
                    kind="raw_json",
                )
            )

    for frok in (False, True):
        for sa in (False, True):
            cases.append(
                OracleCase(
                    id=f"idem_deliv_r{int(frok)}_s{int(sa)}",
                    op="service_idempotent_request_delivery",
                    args={"first_respond_ok": frok, "session_active_on_retry": sa},
                    expr=f"_fmt_idem_delivery({_b(frok)}, {_b(sa)})",
                    kind="raw_json",
                )
            )

    for rep in (False, True):
        cur_ep = "2n" if rep else "1n"
        cases.append(
            OracleCase(
                id=f"topic_epoch_rep{int(rep)}",
                op="service_topic_epoch_fencing",
                args={"replacement_created": rep},
                expr=f"M.is_pending_unsub_obsolete(1n, {cur_ep}, False{{}}, {_b(rep)})",
                kind="bool",
            )
        )

    return cases


# ---------------------------------------------------------------------------
# Registered Domain Oracle Specs, Bend Model Faults, and Dart Source Faults
# ---------------------------------------------------------------------------

ORACLE_SPECS: tuple[DomainOracleSpec, ...] = (
    DomainOracleSpec(
        domain="amounts",
        imports={"test/bend/amounts/model.bend": "M"},
        cases_fn=_amounts_cases,
        helpers=_AMOUNTS_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="wallet_lifecycle",
        imports={"test/bend/wallet_lifecycle/model.bend": "M"},
        cases_fn=_wallet_lifecycle_cases,
        helpers=_WALLET_LIFECYCLE_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="tx_pipeline",
        imports={"test/bend/tx_pipeline/model.bend": "M"},
        cases_fn=_tx_pipeline_cases,
        helpers=_TX_PIPELINE_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="node_sync",
        imports={"test/bend/node_sync/model.bend": "M"},
        cases_fn=_node_sync_cases,
        helpers=_NODE_SYNC_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="wallet_connect",
        imports={"test/bend/wallet_connect/model.bend": "M"},
        cases_fn=_wallet_connect_cases,
        helpers=_WC_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="wc_crash_safety",
        imports={"test/bend/wc_crash_safety/model.bend": "M"},
        cases_fn=_wc_crash_safety_cases,
        helpers=_WC_CRASH_SAFETY_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="plasma_staking",
        imports={"test/bend/plasma_staking/model.bend": "M"},
        cases_fn=_plasma_staking_cases,
        helpers=_PLASMA_STAKING_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="pillars_sentinels",
        imports={"test/bend/pillars_sentinels/model.bend": "M"},
        cases_fn=_pillars_sentinels_cases,
        helpers=_PILLARS_SENTINELS_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="tokens_zts",
        imports={"test/bend/tokens_zts/model.bend": "M"},
        cases_fn=_tokens_zts_cases,
        helpers=_TOKENS_ZTS_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="p2p_htlc",
        imports={"test/bend/p2p_htlc/model.bend": "M"},
        cases_fn=_p2p_htlc_cases,
        helpers=_P2P_HTLC_HELPERS,
        chunk_size=24,
    ),
    DomainOracleSpec(
        domain="accelerator",
        imports={"test/bend/accelerator/model.bend": "M"},
        cases_fn=_accelerator_cases,
        helpers=_ACCELERATOR_HELPERS,
        chunk_size=24,
    ),
)

MODEL_FAULTS: tuple[ModelFault, ...] = (
    # amounts (2 model faults)
    ModelFault(
        name="amounts_correct_value_zero_max_ignores_can_eq",
        domain="amounts",
        old="Bool.and(Nat.is_eq(max_val, 0n), Bool.not(can_eq_min))",
        new="Nat.is_eq(max_val, 0n)",
        expected_law="correct_value_blank_iff",
    ),
    ModelFault(
        name="amounts_asset_cmp_znn_not_reflexive",
        domain="amounts",
        old=(
            "def asset_cmp(a: AssetKind, b: AssetKind) -> Cmp:\n"
            "  match a b:\n"
            "    case Znn{} Znn{}:\n"
            "      EQ{}"
        ),
        new=(
            "def asset_cmp(a: AssetKind, b: AssetKind) -> Cmp:\n"
            "  match a b:\n"
            "    case Znn{} Znn{}:\n"
            "      LT{}"
        ),
        expected_law="asset_cmp_irrefl",
    ),
    # wallet_lifecycle (2 model faults)
    ModelFault(
        name="wl_closed_reopens_to_idle",
        domain="wallet_lifecycle",
        old="case FileClosed{} _:\n      FileOutcome{FileClosed{}, False{}}",
        new="case FileClosed{} _:\n      FileOutcome{FileIdle{}, True{}}",
        expected_law="wallet_file_mutual_exclusion",
    ),
    ModelFault(
        name="wl_unlock_incorrect_skips_failed_increment",
        domain="wallet_lifecycle",
        old="unlock_incorrect_branch(1n+failed, limit, init_done, Nat.is_ge(1n+failed, limit))",
        new="unlock_incorrect_branch(failed, limit, init_done, Nat.is_ge(failed, limit))",
        expected_law="unlock_incorrect_increments_failed",
    ),
    # tx_pipeline (2 model faults)
    ModelFault(
        name="tx_sync_off_by_one",
        domain="tx_pipeline",
        old="Nat.is_lt(Nat.sub(tgt, cur), 20n)",
        new="Nat.is_lt(Nat.sub(tgt, cur), 19n)",
        expected_law="tx_sync_boundary_19_synced",
    ),
    ModelFault(
        name="poll_overshoot_deadline",
        domain="tx_pipeline",
        old="poll_sleep_gate(Nat.is_le(rem_after, poll_interval), poll_interval)",
        new="poll_sleep_gate(Nat.is_lt(rem_after, poll_interval), poll_interval)",
        expected_law="poll_never_sleeps_past_deadline",
    ),
    # node_sync (2 model faults)
    ModelFault(
        name="sync_jitter_disjoint_broken",
        domain="node_sync",
        old="Bool.and(sync_has_valid_heights(cur, tgt), Nat.is_lt(Nat.sub(tgt, cur), 3n))",
        new="Bool.and(sync_has_valid_heights(cur, tgt), Nat.is_le(Nat.sub(tgt, cur), 3n))",
        expected_law="sync_non_done_synced_and_behind_disjoint",
    ),
    ModelFault(
        name="macos_perm_bypass",
        domain="node_sync",
        old="case True{} True{} False{}:\n      prev",
        new="case True{} True{} False{}:\n      True{}",
        expected_law="wallet_opt_persist_fail_rolls_back",
    ),
    # wallet_connect (2 model faults)
    ModelFault(
        name="wc_url_allows_javascript_scheme",
        domain="wallet_connect",
        old="case SchemeJavascript{}:\n      False{}",
        new="case SchemeJavascript{}:\n      True{}",
        expected_law="sanitize_http_url_blocks_dangerous_schemes_and_empty_host",
    ),
    ModelFault(
        name="wc_uri_accepts_v1_instead_of_v2",
        domain="wallet_connect",
        old="Nat.is_eq(version, 2n),",
        new="Nat.is_eq(version, 1n),",
        expected_law="wc_uri_rejects_non_v2",
    ),
    # wc_crash_safety (2 model faults)
    ModelFault(
        name="wc_fallback_reverts_to_secure",
        domain="wc_crash_safety",
        old="case ModeAuthoritativeFallback{}:\n      ModeAuthoritativeFallback{}",
        new="case ModeAuthoritativeFallback{}:\n      ModeSecure{}",
        expected_law="authoritative_fallback_is_sticky_forever",
    ),
    ModelFault(
        name="wc_cached_unsent_reexecutes_handler",
        domain="wc_crash_safety",
        old="case ReqCachedUnsent{+rid} True{} False{}:\n      ActionRetryCachedDelivery{rid}",
        new="case ReqCachedUnsent{+rid} True{} False{}:\n      ActionExecuteHandler{}",
        expected_law="idempotent_delivery_never_reexecutes_completed_or_cached",
    ),
    # plasma_staking (2 model faults)
    ModelFault(
        name="plasma_fuse_below_min_bypass",
        domain="plasma_staking",
        old="Nat.is_ge(qsr, fuse_min_qsr()),",
        new="True{},",
        expected_law="fuse_rejects_below_min",
    ),
    ModelFault(
        name="plasma_stake_months_allows_13",
        domain="plasma_staking",
        old="Nat.is_le(months, 12n)",
        new="Nat.is_le(months, 13n)",
        expected_law="stake_months_bounds",
    ),
    # pillars_sentinels (2 model faults)
    ModelFault(
        name="pillars_producer_allows_wallet_addr",
        domain="pillars_sentinels",
        old="Bool.and(addr_valid, Bool.not(in_wallet_addresses))",
        new="addr_valid",
        expected_law="producer_rejects_wallet_address",
    ),
    ModelFault(
        name="pillars_deposit_confirm_allows_zero",
        domain="pillars_sentinels",
        old="Bool.and(Nat.is_gt(amount, 0n), Nat.is_ge(observed, Nat.add(initial, amount)))",
        new="Nat.is_ge(observed, Nat.add(initial, amount))",
        expected_law="deposit_confirm_rejects_zero_amount",
    ),
    # tokens_zts (2 model faults)
    ModelFault(
        name="tokens_burn_drops_owner_override",
        domain="tokens_zts",
        old="Bool.or(is_burnable, is_sel_owner),\n    is_wallet_owner}",
        new="is_burnable,\n    is_wallet_owner}",
        expected_law="caps_burn_protocol_rule",
    ),
    ModelFault(
        name="tokens_mintable_allows_zero_max",
        domain="tokens_zts",
        old="Nat.is_ge(max_in, 1n),",
        new="True{},",
        expected_law="supply_mintable_rejects_zero_max",
    ),
    # p2p_htlc (2 model faults)
    ModelFault(
        name="p2p_htlc_delete_reclaimable",
        domain="p2p_htlc",
        old="case Reclaimable{}:\n      False{}",
        new="case Reclaimable{}:\n      True{}",
        expected_law="safe_deletion_partition",
    ),
    ModelFault(
        name="p2p_htlc_rollback_drops_sync",
        domain="p2p_htlc",
        old="ChgPwdRes{False{}, storage_set_sync(rollback_rekey(st1, old_k), True{})}",
        new="ChgPwdRes{False{}, storage_set_sync(rollback_rekey(st1, old_k), False{})}",
        expected_law="change_password_always_restarts_sync",
    ),
    # accelerator (2 model faults)
    ModelFault(
        name="accelerator_quorum_missing_plus_one",
        domain="accelerator",
        old="1n+Nat.div(Nat.mul(1n+p, QUORUM_NUM()), QUORUM_DEN())",
        new="Nat.div(Nat.mul(1n+p, QUORUM_NUM()), QUORUM_DEN())",
        expected_law="quorum_bounded_by_one_and_n",
    ),
    ModelFault(
        name="accelerator_donation_double_znn",
        domain="accelerator",
        old="DonAttempt{True{}, False{}, DonForm{0n, 1n+qp, DonFailed{True{}}}}",
        new="DonAttempt{True{}, False{}, DonForm{1n+zp, 1n+qp, DonFailed{True{}}}}",
        expected_law="donation_partial_failure_no_double_znn",
    ),
)

DART_FAULTS: tuple[DartFault, ...] = (
    # amounts (2 real Dart source faults)
    DartFault(
        name="amounts_correct_value_zero_max_dart",
        domain="amounts",
        source_path="lib/utils/input_validators.dart",
        old="if (maxValue == BigInt.zero && !canBeEqualToMin) {",
        new="if (maxValue == BigInt.zero) {",
        test_file="test/bend_conformance/amounts_conformance_test.dart",
    ),
    DartFault(
        name="amounts_plasma_high_off_by_one_dart",
        domain="amounts",
        source_path="lib/utils/plasma_tier_utils.dart",
        old="if (currentPlasma >= kPlasmaHighThreshold) {",
        new="if (currentPlasma > kPlasmaHighThreshold) {",
        test_file="test/bend_conformance/amounts_conformance_test.dart",
    ),
    # wallet_lifecycle (2 real Dart source faults)
    DartFault(
        name="wl_keystore_salt_min_4_dart",
        domain="wallet_lifecycle",
        source_path="lib/utils/wallet_file.dart",
        old="if (!_isValidPrefixedHex(argon2Params['salt'], minBytes: 8) ||",
        new="if (!_isValidPrefixedHex(argon2Params['salt'], minBytes: 4) ||",
        test_file="test/bend_conformance/wallet_lifecycle_conformance_test.dart",
    ),
    DartFault(
        name="wl_unlock_auto_erase_gt_dart",
        domain="wallet_lifecycle",
        source_path="lib/rearchitecture/features/lock/bloc/wallet_unlock_bloc.dart",
        old="if (updatedAttempts >= limit) {",
        new="if (updatedAttempts > limit) {",
        test_file="test/bend_conformance/wallet_lifecycle_conformance_test.dart",
    ),
    # tx_pipeline (2 real Dart source faults)
    DartFault(
        name="account_block_sync_le_20",
        domain="tx_pipeline",
        source_path="lib/utils/account_block_utils.dart",
        old="(syncInfo.targetHeight - syncInfo.currentHeight) < 20",
        new="(syncInfo.targetHeight - syncInfo.currentHeight) <= 20",
        test_file="test/bend_conformance/tx_pipeline_conformance_test.dart",
    ),
    DartFault(
        name="poll_sleep_boundary_lt",
        domain="tx_pipeline",
        source_path="lib/rearchitecture/utils/functions/poll_until_confirmed.dart",
        old="remainingAfterFetch <= effectivePollInterval",
        new="remainingAfterFetch < effectivePollInterval",
        test_file="test/bend_conformance/tx_pipeline_conformance_test.dart",
    ),
    # node_sync (2 real Dart source faults)
    DartFault(
        name="sync_tolerance_drift",
        domain="node_sync",
        source_path="lib/rearchitecture/utils/extensions/sync_info_extension.dart",
        old="const int _kSyncHeightTolerance = 3;",
        new="const int _kSyncHeightTolerance = 4;",
        test_file="test/bend_conformance/node_sync_conformance_test.dart",
    ),
    DartFault(
        name="notif_stale_dismiss_bypass",
        domain="node_sync",
        source_path="lib/rearchitecture/features/notifications/bloc/notifications_bloc.dart",
        old="if (revision == null || revision == state.revision)",
        new="if (revision == null || revision >= 0)",
        test_file="test/bend_conformance/node_sync_conformance_test.dart",
    ),
    # wallet_connect (2 real Dart source faults)
    DartFault(
        name="wc_url_allows_javascript_dart",
        domain="wallet_connect",
        source_path="lib/rearchitecture/utils/wallet_connect_metadata_utils.dart",
        old="(uri.scheme != 'http' && uri.scheme != 'https') ||",
        new="(uri.scheme != 'http' && uri.scheme != 'https' && uri.scheme != 'javascript') ||",
        test_file="test/bend_conformance/wallet_connect_conformance_test.dart",
    ),
    DartFault(
        name="wc_unknown_error_maps_4001_dart",
        domain="wallet_connect",
        source_path="lib/utils/wallet_connect_request_utils.dart",
        old="return JsonRpcError(code: 5000, message: error.toString());",
        new="return JsonRpcError(code: 4001, message: error.toString());",
        test_file="test/bend_conformance/wallet_connect_conformance_test.dart",
    ),
    # wc_crash_safety (2 real Dart source faults)
    DartFault(
        name="wc_delete_ignores_manifest_isolation_dart",
        domain="wc_crash_safety",
        source_path="lib/services/sticky_fallback_secure_store.dart",
        old=(
            "final bool ownsFallbackKey =\n"
            "          !_hasFallbackKeyManifest || _ownedFallbackKeys.contains(key);"
        ),
        new="const bool ownsFallbackKey = true;",
        test_file="test/bend_conformance/wc_crash_safety_conformance_test.dart",
    ),
    DartFault(
        name="wc_finalize_ignores_reset_gen_dart",
        domain="wc_crash_safety",
        source_path="lib/services/web3wallet_service.dart",
        old=(
            "(expectedResetGeneration != null &&\n"
            "            _resetGeneration != expectedResetGeneration)) {"
        ),
        new=(
            "(false && expectedResetGeneration != null &&\n"
            "            _resetGeneration != expectedResetGeneration)) {"
        ),
        test_file="test/bend_conformance/wc_crash_safety_conformance_test.dart",
    ),
    # plasma_staking (2 real Dart source faults)
    DartFault(
        name="plasma_correct_value_zero_max_bypass",
        domain="plasma_staking",
        source_path="lib/utils/input_validators.dart",
        old=(
            "if (maxValue == BigInt.zero && !canBeEqualToMin) {\n"
            "          return resolvedL10n.emptyBalance;\n"
            "        }"
        ),
        new=(
            "if (maxValue == BigInt.zero) {\n"
            "          if (canBeEqualToMin) {\n"
            "            return null;\n"
            "          }\n"
            "          return resolvedL10n.emptyBalance;\n"
            "        }"
        ),
        test_file="test/bend_conformance/plasma_staking_conformance_test.dart",
    ),
    DartFault(
        name="plasma_stake_threshold_drift",
        domain="plasma_staking",
        source_path="lib/utils/constants.dart",
        old="const int kStakePlasmaAmountNeeded = 105000;",
        new="const int kStakePlasmaAmountNeeded = 84000;",
        test_file="test/bend_conformance/plasma_staking_conformance_test.dart",
    ),
    # pillars_sentinels (2 real Dart source faults)
    DartFault(
        name="pillars_max_qsr_deposit_uncapped",
        domain="pillars_sentinels",
        source_path="lib/rearchitecture/utils/functions/pillar_qsr_deposit_utils.dart",
        old="final BigInt maxDeposit = MathUtils.bigMin(effectiveBalance, remaining);",
        new="final BigInt maxDeposit = effectiveBalance;",
        test_file="test/bend_conformance/pillars_sentinels_conformance_test.dart",
    ),
    DartFault(
        name="pillars_producer_allows_wallet_addr",
        domain="pillars_sentinels",
        source_path="lib/utils/input_validators.dart",
        old="if (kDefaultAddressList.contains(value)) {",
        new="if (false && kDefaultAddressList.contains(value)) {",
        test_file="test/bend_conformance/pillars_sentinels_conformance_test.dart",
    ),
    # tokens_zts (2 real Dart source faults)
    DartFault(
        name="tokens_burn_drops_owner_override",
        domain="tokens_zts",
        source_path="lib/rearchitecture/features/tokens/utils/token_capabilities.dart",
        old="canBurn: isBurnable || isSelectedOwner,",
        new="canBurn: isBurnable,",
        test_file="test/bend_conformance/tokens_zts_conformance_test.dart",
    ),
    DartFault(
        name="tokens_trusted_drops_qsr",
        domain="tokens_zts",
        source_path="lib/utils/zts_utils.dart",
        old="    znnTokenStandard,\n    qsrTokenStandard,",
        new="    znnTokenStandard,",
        test_file="test/bend_conformance/tokens_zts_conformance_test.dart",
    ),
    # p2p_htlc (2 real Dart source faults)
    DartFault(
        name="htlc_join_window_strict_gt",
        domain="p2p_htlc",
        source_path="lib/rearchitecture/features/initial_htlc_validation/utils/htlc_window_utils.dart",
        old="final bool canSafelyJoin = safeJoinSeconds >= 0;",
        new="final bool canSafelyJoin = safeJoinSeconds > 0;",
        test_file="test/bend_conformance/p2p_htlc_conformance_test.dart",
    ),
    DartFault(
        name="swap_sanitizer_depth_cap_6",
        domain="p2p_htlc",
        source_path="lib/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart",
        old="for (int depth = 0; depth < 5 && current != null; depth += 1)",
        new="for (int depth = 0; depth < 6 && current != null; depth += 1)",
        test_file="test/bend_conformance/p2p_htlc_conformance_test.dart",
    ),
    # accelerator (2 real Dart source faults)
    DartFault(
        name="accelerator_negative_donation_leg",
        domain="accelerator",
        source_path="lib/rearchitecture/features/accelerator_donation_stepper/bloc/submit_donation_bloc.dart",
        old=(
            "znnAmount >= BigInt.zero &&\n"
            "    qsrAmount >= BigInt.zero &&\n"
            "    (znnAmount > BigInt.zero || qsrAmount > BigInt.zero);"
        ),
        new="znnAmount > BigInt.zero || qsrAmount > BigInt.zero;",
        test_file="test/bend_conformance/accelerator_conformance_test.dart",
    ),
    DartFault(
        name="accelerator_quorum_missing_plus_one_dart",
        domain="accelerator",
        source_path="lib/rearchitecture/features/accelerator_projects/utils/accelerator_vote_summary.dart",
        old="? (safePillars * 33) ~/ 100 + 1",
        new="? (safePillars * 33) ~/ 100",
        test_file="test/bend_conformance/accelerator_conformance_test.dart",
    ),
)
