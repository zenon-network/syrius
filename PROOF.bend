import Base
import ./LAWS.bend as Laws
import ./test/bend/common/nat.bend as NatL

# Import all 11 domain models for type annotations in root proof helpers
import ./test/bend/amounts/model.bend as Amt
import ./test/bend/wallet_lifecycle/model.bend as WL
import ./test/bend/plasma_staking/model.bend as PS
import ./test/bend/pillars_sentinels/model.bend as Pil
import ./test/bend/tokens_zts/model.bend as Tok
import ./test/bend/tx_pipeline/model.bend as Tx
import ./test/bend/node_sync/model.bend as NS
import ./test/bend/p2p_htlc/model.bend as Htlc
import ./test/bend/accelerator/model.bend as Acc
import ./test/bend/wallet_connect/model.bend as WC
import ./test/bend/wc_crash_safety/model.bend as WcSafe

# Import all 11 domain LAWS + PROOF modules so a single `bend PROOF.bend`
# (and `./scripts/bend PROOF.bend --verdict`) verifies EVERY law in Syrius.
import ./test/bend/amounts/PROOF.bend as PAmounts
import ./test/bend/wallet_lifecycle/PROOF.bend as PWalletLifecycle
import ./test/bend/plasma_staking/PROOF.bend as PPlasmaStaking
import ./test/bend/pillars_sentinels/PROOF.bend as PPillarsSentinels
import ./test/bend/tokens_zts/PROOF.bend as PTokensZts
import ./test/bend/tx_pipeline/PROOF.bend as PTxPipeline
import ./test/bend/node_sync/PROOF.bend as PNodeSync
import ./test/bend/p2p_htlc/PROOF.bend as PP2pHtlc
import ./test/bend/p2p_htlc/LAWS.bend as HtlcLaws
import ./test/bend/accelerator/PROOF.bend as PAccelerator
import ./test/bend/accelerator/LAWS.bend as AccLaws
import ./test/bend/wallet_connect/PROOF.bend as PWalletConnect
import ./test/bend/wc_crash_safety/PROOF.bend as PWcCrashSafety

# Local proof helpers
# -------------------

def bool_eq_refl_local(+b: Bool) -> {Laws.root_bool_eq(b, b) == True{} : Bool}:
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

def and_false_r(+a: Bool) -> {Bool.and(a, False{}) == False{} : Bool}:
  match a:
    case False{}:
      {==}
    case True{}:
      {==}

def and_false_2(+a: Bool, +b: Bool) -> {Bool.and(a, Bool.and(False{}, b)) == False{} : Bool}:
  match a:
    case False{}:
      {==}
    case True{}:
      {==}

def and_false_3(+a: Bool, +b: Bool, +c: Bool) -> {Bool.and(a, Bool.and(b, Bool.and(False{}, c))) == False{} : Bool}:
  match a b:
    case False{} _:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def and_false_3_r(+a: Bool, +b: Bool) -> {Bool.and(a, Bool.and(b, False{})) == False{} : Bool}:
  match a b:
    case False{} _:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def and_false_4(+a: Bool, +b: Bool, +c: Bool, +d: Bool) -> {Bool.and(a, Bool.and(b, Bool.and(c, Bool.and(False{}, d)))) == False{} : Bool}:
  match a b c:
    case False{} _ _:
      {==}
    case True{} False{} _:
      {==}
    case True{} True{} False{}:
      {==}
    case True{} True{} True{}:
      {==}

def locked_wallet_precond_step(
  +synced: Bool,
  +exp_addr: Maybe<&2, Nat>,
  +sel_addr: Maybe<&2, Nat>,
  +addr_ok: Bool
) -> {Laws.root_precond_is_ok(Tx.check_precond_gate(synced, exp_addr, sel_addr, addr_ok, None{})) == False{} : Bool}:
  match synced:
    case False{}:
      {==}
    case True{}:
      match exp_addr:
        case Some{_}:
          match addr_ok:
            case False{}:
              {==}
            case True{}:
              {==}
        case None{}:
          match sel_addr:
            case None{}:
              {==}
            case Some{_}:
              match addr_ok:
                case False{}:
                  {==}
                case True{}:
                  {==}

def notif_lock_false(+has_active: Bool, +has_cb: Bool) -> {NS.notif_widget_can_see_more(True{}, has_active, has_cb) == False{} : Bool}:
  match has_active:
    case False{}:
      {==}
    case True{}:
      {==}

def can_burn_zero_bal(+val: Nat, +total: Nat, +is_burn: Bool, +is_own: Bool) -> {Tok.can_burn_amount(val, 0n, total, is_burn, is_own) == False{} : Bool}:
  match val:
    case 0n:
      and_false_2(Bool.or(is_burn, is_own), Bool.and(Nat.is_le(0n, 0n), Nat.is_le(0n, total)))
    case 1n+vp:
      and_false_3(Bool.or(is_burn, is_own), True{}, Nat.is_le(1n+vp, total))

def donation_zero_bals(+znn_d: Acc.SignedAmt, +qsr_d: Acc.SignedAmt) -> {Acc.is_valid_donation(znn_d, qsr_d, 0n, 0n) == False{} : Bool}:
  match znn_d qsr_d:
    case Acc.NonNeg{0n} Acc.NonNeg{0n}:
      {==}
    case Acc.NonNeg{0n} Acc.NonNeg{1n+_}:
      {==}
    case Acc.NonNeg{1n+_} Acc.NonNeg{_}:
      {==}
    case Acc.NonNeg{_} Acc.Neg{_}:
      {==}
    case Acc.Neg{_} _:
      {==}

def il_status_eq_refl(+s: Tx.ListStatus) -> {Laws.root_il_status_eq(s, s) == True{} : Bool}:
  match s:
    case Tx.ListInitial{}:
      {==}
    case Tx.ListSuccess{}:
      {==}
    case Tx.ListFailure{}:
      {==}

def il_state_preserved_refl(+s: Tx.ListStatus, +c: Nat, +h: Bool, +r: Nat, +a: Maybe<&2, Nat>, +p: Nat) -> {Laws.root_il_state_preserved(Tx.InfiniteListModel{s, c, h, r, a, p}, Tx.InfiniteListModel{s, c, h, r, a, p}) == True{} : Bool}:
  %Equal.sym(Bool, Laws.root_il_status_eq(s, s), True{}, il_status_eq_refl(s)) : {Bool.and(_, Bool.and(Nat.is_eq(c, c), Bool.and(Laws.root_bool_eq(h, h), Bool.and(Nat.is_eq(r, r), Nat.is_eq(p, p))))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(c, c), True{}, NatL.is_eq_same(c)) : {Bool.and(_, Bool.and(Laws.root_bool_eq(h, h), Bool.and(Nat.is_eq(r, r), Nat.is_eq(p, p)))) == True{} : Bool}
  %Equal.sym(Bool, Laws.root_bool_eq(h, h), True{}, bool_eq_refl_local(h)) : {Bool.and(_, Bool.and(Nat.is_eq(r, r), Nat.is_eq(p, p))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(r, r), True{}, NatL.is_eq_same(r)) : {Bool.and(_, Nat.is_eq(p, p)) == True{} : Bool}
  NatL.is_eq_same(p)

def summary_eq_refl(+s: Htlc.SanitizedSummary) -> {Laws.root_summary_eq(s, s) == True{} : Bool}:
  match s:
    case Htlc.SummarySqlite{w, c}:
      %Equal.sym(Bool, Laws.root_bool_eq(w, w), True{}, bool_eq_refl_local(w)) : {Bool.and(_, Nat.is_eq(c, c)) == True{} : Bool}
      NatL.is_eq_same(c)
    case Htlc.SummaryRpc{c}:
      NatL.is_eq_same(c)
    case Htlc.SummaryTypeOnly{}:
      {==}

def is_le_252_add(+a: Nat, +b: Nat, h: {Nat.is_le(a, 252n) == True{} : Bool}, +extra: Nat) -> {Nat.is_ge(Nat.add(252n, extra), a) == True{} : Bool}:
  %Equal.sym(Bool, Nat.is_ge(Nat.add(252n, extra), a), Nat.is_le(a, Nat.add(252n, extra)), NatL.is_ge_as_le(Nat.add(252n, extra), a)) : {_ == True{} : Bool}
  NatL.le_trans(a, 252n, Nat.add(252n, extra), h, NatL.is_le_add_right(252n, extra))

def lt_le_trans_root(+a: Nat, +b: Nat, +c: Nat, ab: {Nat.is_lt(a, b) == True{} : Bool}, bc: {Nat.is_le(b, c) == True{} : Bool}) -> {Nat.is_lt(a, c) == True{} : Bool}:
  match a b c:
    case 0n 0n _:
      Empty.absurd({Nat.is_lt(0n, c) == True{} : Bool}, NatL.false_is_not_true(ab))
    case 0n 1n+bp 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(bc))
    case 0n 1n+bp 1n+cp:
      {==}
    case 1n+ap 0n _:
      Empty.absurd({Nat.is_lt(1n+ap, c) == True{} : Bool}, NatL.false_is_not_true(ab))
    case 1n+ap 1n+bp 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 0n) == True{} : Bool}, NatL.false_is_not_true(bc))
    case 1n+ap 1n+bp 1n+cp:
      lt_le_trans_root(ap, bp, cp, ab, bc)

def not_ge_from_lt_root(+a: Nat, +b: Nat, lt: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_ge(a, b) == False{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_ge(0n, 0n) == False{} : Bool}, NatL.false_is_not_true(lt))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_ge(1n+ap, 0n) == False{} : Bool}, NatL.false_is_not_true(lt))
    case 1n+ap 1n+bp:
      not_ge_from_lt_root(ap, bp, lt)

def lt_from_not_ge(+a: Nat, +b: Nat, nge: {Nat.is_ge(a, b) == False{} : Bool}) -> {Nat.is_lt(a, b) == True{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.true_is_not_false(nge))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 0n) == True{} : Bool}, NatL.true_is_not_false(nge))
    case 1n+ap 1n+bp:
      lt_from_not_ge(ap, bp, nge)

def op_plasma_bounds(+op: PS.PlasmaOp) -> {Nat.is_le(21n, PS.op_plasma_k(op)) == True{} : Bool} & {Nat.is_le(PS.op_plasma_k(op), 252n) == True{} : Bool}:
  match op:
    case PS.OpMinPlasma{}:
      ({==}, {==})
    case PS.OpDelegate{}:
      ({==}, {==})
    case PS.OpStake{}:
      ({==}, {==})
    case PS.OpIssueToken{}:
      ({==}, {==})
    case PS.OpPillar{}:
      ({==}, {==})
    case PS.OpSentinel{}:
      ({==}, {==})

def plasma_low_finish(
  +role: Pil.NodeRole,
  +pk: Nat,
  +op: PS.PlasmaOp,
  e_op: {Nat.is_ge(pk, PS.op_plasma_k(op)) == False{} : Bool},
  e_tok: {Nat.is_ge(pk, 189n) == False{} : Bool},
  e_role: {Nat.is_ge(pk, 252n) == False{} : Bool}
) -> {Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, Pil.role_plasma_req_k(role))))) == True{} : Bool}:
  match role:
    case Pil.RolePillar{}:
      %Equal.sym(Bool, Nat.is_ge(pk, PS.op_plasma_k(op)), False{}, e_op) : {Bool.and(Bool.not(_), Bool.and(Bool.not(Nat.is_ge(pk, 189n)), Bool.not(Nat.is_ge(pk, 252n)))) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_ge(pk, 189n), False{}, e_tok) : {Bool.and(True{}, Bool.and(Bool.not(_), Bool.not(Nat.is_ge(pk, 252n)))) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_ge(pk, 252n), False{}, e_role) : {Bool.and(True{}, Bool.and(True{}, Bool.not(_))) == True{} : Bool}
      {==}
    case Pil.RoleSentinel{}:
      %Equal.sym(Bool, Nat.is_ge(pk, PS.op_plasma_k(op)), False{}, e_op) : {Bool.and(Bool.not(_), Bool.and(Bool.not(Nat.is_ge(pk, 189n)), Bool.not(Nat.is_ge(pk, 252n)))) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_ge(pk, 189n), False{}, e_tok) : {Bool.and(True{}, Bool.and(Bool.not(_), Bool.not(Nat.is_ge(pk, 252n)))) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_ge(pk, 252n), False{}, e_role) : {Bool.and(True{}, Bool.and(True{}, Bool.not(_))) == True{} : Bool}
      {==}

def dup3_bool_eq(+a: Bool, +b: Bool, e: {a == b : Bool}) -> {a == b : Bool} & ({a == b : Bool} & {a == b : Bool}):
  match a b:
    case False{} False{}:
      ({==}, ({==}, {==}))
    case True{} True{}:
      ({==}, ({==}, {==}))
    case False{} True{}:
      Empty.absurd({False{} == True{} : Bool} & ({False{} == True{} : Bool} & {False{} == True{} : Bool}), NatL.false_is_not_true(e))
    case True{} False{}:
      Empty.absurd({True{} == False{} : Bool} & ({True{} == False{} : Bool} & {True{} == False{} : Bool}), NatL.true_is_not_false(e))

def plasma_low_from_triple(
  +pk: Nat,
  +op: PS.PlasmaOp,
  +role: Pil.NodeRole,
  lo_op: {Nat.is_le(21n, PS.op_plasma_k(op)) == True{} : Bool},
  p1: {Nat.is_lt(pk, 21n) == True{} : Bool} & ({Nat.is_lt(pk, 21n) == True{} : Bool} & {Nat.is_lt(pk, 21n) == True{} : Bool})
) -> {Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, Pil.role_plasma_req_k(role))))) == True{} : Bool}:
  (lt21_a, rest) = p1
  (lt21_b, lt21_c) = rest
  lt_op = lt_le_trans_root(pk, 21n, PS.op_plasma_k(op), lt21_a, lo_op)
  lt_tok = lt_le_trans_root(pk, 21n, 189n, lt21_b, {==})
  lt_role = lt_le_trans_root(pk, 21n, 252n, lt21_c, {==})
  e_op = not_ge_from_lt_root(pk, PS.op_plasma_k(op), lt_op)
  e_tok = not_ge_from_lt_root(pk, 189n, lt_tok)
  e_role = not_ge_from_lt_root(pk, 252n, lt_role)
  plasma_low_finish(role, pk, op, e_op, e_tok, e_role)

def plasma_low_branch(
  +ge21: Bool,
  +pk: Nat,
  +op: PS.PlasmaOp,
  +role: Pil.NodeRole,
  e_ge: {Nat.is_ge(pk, 21n) == ge21 : Bool},
  lo_op: {Nat.is_le(21n, PS.op_plasma_k(op)) == True{} : Bool}
) -> {Bool.or(ge21, Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, Pil.role_plasma_req_k(role)))))) == True{} : Bool}:
  match ge21:
    case True{}:
      {==}
    case False{}:
      plasma_low_from_triple(pk, op, role, lo_op, dup3_bool_eq(Nat.is_lt(pk, 21n), True{}, lt_from_not_ge(pk, 21n, e_ge)))

def plasma_hierarchy_finish(
  +role: Pil.NodeRole,
  +pk: Nat,
  +op: PS.PlasmaOp,
  +extra: Nat,
  e_hi_op: {Nat.is_ge(Nat.add(252n, extra), PS.op_plasma_k(op)) == True{} : Bool},
  e_hi_tok: {Nat.is_ge(Nat.add(252n, extra), 189n) == True{} : Bool},
  e_low: {Bool.or(Nat.is_ge(pk, 21n), Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, Pil.role_plasma_req_k(role)))))) == True{} : Bool}
) -> {Bool.and(
    Bool.and(
      PS.meets_plasma(Nat.add(Pil.role_plasma_req_k(role), extra), PS.op_plasma_k(op)),
      PS.meets_plasma(Nat.add(Pil.role_plasma_req_k(role), extra), 189n)),
    Bool.or(
      Nat.is_ge(pk, 21n),
      Bool.and(
        Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))),
        Bool.and(
          Bool.not(PS.meets_plasma(pk, 189n)),
          Bool.not(PS.meets_plasma(pk, Pil.role_plasma_req_k(role))))))) == True{} : Bool}:
  match role:
    case Pil.RolePillar{}:
      %Equal.sym(Bool, Nat.is_ge(Nat.add(252n, extra), PS.op_plasma_k(op)), True{}, e_hi_op) : {Bool.and(Bool.and(_, Nat.is_ge(Nat.add(252n, extra), 189n)), Bool.or(Nat.is_ge(pk, 21n), Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, 252n)))))) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_ge(Nat.add(252n, extra), 189n), True{}, e_hi_tok) : {Bool.and(Bool.and(True{}, _), Bool.or(Nat.is_ge(pk, 21n), Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, 252n)))))) == True{} : Bool}
      e_low
    case Pil.RoleSentinel{}:
      %Equal.sym(Bool, Nat.is_ge(Nat.add(252n, extra), PS.op_plasma_k(op)), True{}, e_hi_op) : {Bool.and(Bool.and(_, Nat.is_ge(Nat.add(252n, extra), 189n)), Bool.or(Nat.is_ge(pk, 21n), Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, 252n)))))) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_ge(Nat.add(252n, extra), 189n), True{}, e_hi_tok) : {Bool.and(Bool.and(True{}, _), Bool.or(Nat.is_ge(pk, 21n), Bool.and(Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))), Bool.and(Bool.not(PS.meets_plasma(pk, 189n)), Bool.not(PS.meets_plasma(pk, 252n)))))) == True{} : Bool}
      e_low

def plasma_hierarchy_from_bounds(
  +pk: Nat,
  +op: PS.PlasmaOp,
  +role: Pil.NodeRole,
  +extra: Nat,
  bounds: {Nat.is_le(21n, PS.op_plasma_k(op)) == True{} : Bool} & {Nat.is_le(PS.op_plasma_k(op), 252n) == True{} : Bool}
) -> {Bool.and(
    Bool.and(
      PS.meets_plasma(Nat.add(Pil.role_plasma_req_k(role), extra), PS.op_plasma_k(op)),
      PS.meets_plasma(Nat.add(Pil.role_plasma_req_k(role), extra), 189n)),
    Bool.or(
      Nat.is_ge(pk, 21n),
      Bool.and(
        Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))),
        Bool.and(
          Bool.not(PS.meets_plasma(pk, 189n)),
          Bool.not(PS.meets_plasma(pk, Pil.role_plasma_req_k(role))))))) == True{} : Bool}:
  (lo_op, hi_op) = bounds
  e_hi_op = is_le_252_add(PS.op_plasma_k(op), 252n, hi_op, extra)
  e_hi_tok = is_le_252_add(189n, 252n, {==}, extra)
  e_low = plasma_low_branch(Nat.is_ge(pk, 21n), pk, op, role, {==}, lo_op)
  plasma_hierarchy_finish(role, pk, op, extra, e_hi_op, e_hi_tok, e_low)

def sub_add_20_ge(+cur: Nat) -> {Nat.is_lt(Nat.sub(Nat.add(1n+cur, 20n), 1n+cur), 20n) == False{} : Bool}:
  %Equal.sym(Nat, Nat.sub(Nat.add(cur, 20n), cur), 20n, NatL.sub_cancel_add_left(cur, 20n)) : {Nat.is_lt(_, 20n) == False{} : Bool}
  {==}

def lt3_implies_lt20(+d: Nat, h: {Nat.is_lt(d, 3n) == True{} : Bool}) -> {Nat.is_lt(d, 20n) == True{} : Bool}:
  lt_le_trans_root(d, 3n, 20n, h, {==})

def sync3_heights(+cur: Nat, +tgt: Nat, +vh: Bool, +lt3: Bool, e_lt3: {Nat.is_lt(Nat.sub(tgt, cur), 3n) == lt3 : Bool}) -> {Bool.or(Bool.not(Bool.and(vh, lt3)), Bool.and(vh, Nat.is_lt(Nat.sub(tgt, cur), 20n))) == True{} : Bool}:
  match vh lt3:
    case False{} _:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      lt3_implies_lt20(Nat.sub(tgt, cur), e_lt3)

def sync3_implies_sync20(+st: NS.SyncStateKind, +cur: Nat, +tgt: Nat) -> {Bool.or(Bool.not(NS.sync_info_is_synced(st, cur, tgt)), NS.node_is_synced_20(st, cur, tgt)) == True{} : Bool}:
  match st:
    case NS.SyncDone{}:
      {==}
    case NS.SyncUnknown{}:
      sync3_heights(cur, tgt, NS.sync_has_valid_heights(cur, tgt), Nat.is_lt(Nat.sub(tgt, cur), 3n), {==})
    case NS.Syncing{}:
      sync3_heights(cur, tgt, NS.sync_has_valid_heights(cur, tgt), Nat.is_lt(Nat.sub(tgt, cur), 3n), {==})
    case NS.NotEnoughPeers{}:
      sync3_heights(cur, tgt, NS.sync_has_valid_heights(cur, tgt), Nat.is_lt(Nat.sub(tgt, cur), 3n), {==})

def clock_skew_zero(+st: NS.SyncStateKind, +cur: Nat, +tgt: Nat, +f: Nat) -> {NS.should_warn_clock_skew(st, cur, tgt, f, f) == False{} : Bool}:
  %Equal.sym(Nat, Nat.sub(f, f), 0n, NatL.sub_self(f)) : {Bool.and(NS.node_is_synced_20(st, cur, tgt), Nat.is_gt(Nat.add(_, _), NS.clock_skew_threshold())) == False{} : Bool}
  and_false_r(NS.node_is_synced_20(st, cur, tgt))

# =============================================================================
# 17 Root Law Proofs
# =============================================================================

def Laws.locked_wallet_blocks_sensitive_ops(is_hw, st, cur, tgt, exp_addr, sel_addr, addr_ok, wc_method, sess_act, has_rid, pending, svc_c, sess_c, act_c):
  e_pc = locked_wallet_precond_step(Tx.node_is_synced_for_tx(st, cur, tgt), exp_addr, sel_addr, addr_ok)
  e_nf = notif_lock_false(has_rid, sess_act)
  %Equal.sym(Bool, Laws.root_precond_is_ok(Tx.check_create_preconditions(st, cur, tgt, exp_addr, sel_addr, addr_ok, None{})), False{}, e_pc) : {Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(True{}, Bool.and(True{}, Bool.not(NS.notif_widget_can_see_more(True{}, has_rid, sess_act)))))) == True{} : Bool}
  %Equal.sym(Bool, NS.notif_widget_can_see_more(True{}, has_rid, sess_act), False{}, e_nf) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.not(_))))) == True{} : Bool}
  {==}

def Laws.hardware_wallet_safety_boundaries(is_unlocked, wlen, dmatch, exp, now, need_plasma):
  match is_unlocked need_plasma:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def lock_timer_htlc_noop(+l: Bool, +h: Bool, +t: Bool, +seq: Nat) -> {WL.lock_step(WL.LockScreenState{l, h, t, seq}, WL.LockTimerFired{True{}}) == WL.LockScreenState{l, h, t, seq} : WL.LockScreenState}:
  match l t:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def Laws.active_incoming_htlc_protection(l, h, t, seq, pool, ar_run, nseq, out):
  %Equal.sym(WL.LockScreenState, WL.lock_step(WL.LockScreenState{l, h, t, seq}, WL.LockTimerFired{True{}}), WL.LockScreenState{l, h, t, seq}, lock_timer_htlc_noop(l, h, t, seq)) : {Bool.and(Laws.root_bool_eq(WL.lock_is_locked(_), l), Bool.and(Laws.root_bool_eq(WL.lock_has_handle(_), h), Bool.and(Nat.is_eq(WL.lock_sequence(_), seq), True{}))) == True{} : Bool}
  %Equal.sym(Bool, Laws.root_bool_eq(l, l), True{}, bool_eq_refl_local(l)) : {Bool.and(_, Bool.and(Laws.root_bool_eq(h, h), Bool.and(Nat.is_eq(seq, seq), True{}))) == True{} : Bool}
  %Equal.sym(Bool, Laws.root_bool_eq(h, h), True{}, bool_eq_refl_local(h)) : {Bool.and(_, Bool.and(Nat.is_eq(seq, seq), True{})) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(seq, seq), True{}, NatL.is_eq_same(seq)) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

def Laws.active_incoming_htlc_preserves_autoreceive_pool(pool, ar_run, nseq, out):
  {==}

def decide_req_reset_skip(+req_st: WcSafe.RequestDeliveryStatus, +has_act_sess: Bool) -> {WcSafe.decide_request_action(req_st, has_act_sess, True{}) == WcSafe.ActionSkipDuplicate{} : WcSafe.RequestAction}:
  match req_st has_act_sess:
    case WcSafe.ReqFresh{} False{}:
      {==}
    case WcSafe.ReqFresh{} True{}:
      {==}
    case WcSafe.ReqInFlight{} False{}:
      {==}
    case WcSafe.ReqInFlight{} True{}:
      {==}
    case WcSafe.ReqCachedUnsent{_} False{}:
      {==}
    case WcSafe.ReqCachedUnsent{_} True{}:
      {==}
    case WcSafe.ReqCompleted{} False{}:
      {==}
    case WcSafe.ReqCompleted{} True{}:
      {==}

def Laws.reset_barrier_and_splash_retry_safety(is_init, is_disp, has_cli, cur_gen, exp_gen, live_sess, rem_sess, rem_pair, cur_ep, cap_ep, pend_disc, req_st, has_act_sess, failed_clear):
  e_pair = and_false_3_r(is_init, Bool.not(is_disp))
  e_app = and_false_3_r(Bool.not(is_disp), has_cli)
  e_fin = and_false_3(Bool.not(is_disp), has_cli, Bool.and(Nat.is_eq(cur_gen, exp_gen), live_sess))
  e_req = decide_req_reset_skip(req_st, has_act_sess)
  e_rem2 = and_false_2(Nat.is_eq(rem_sess, 0n), Bool.and(Nat.is_eq(cur_ep, cap_ep), Bool.not(pend_disc)))
  e_norm = and_false_r(failed_clear)
  e_dev = and_false_r(failed_clear)
  %Equal.sym(WcSafe.RequestAction, WcSafe.decide_request_action(req_st, has_act_sess, True{}), WcSafe.ActionSkipDuplicate{}, e_req) : {Bool.and(Bool.not(WcSafe.can_admit_pair(is_init, is_disp, True{})), Bool.and(Bool.not(WcSafe.can_admit_approve_session(is_disp, has_cli, True{})), Bool.and(Bool.not(WcSafe.can_finalize_approved_session(is_disp, has_cli, True{}, cur_gen, exp_gen, live_sess)), Bool.and(Bool.not(WcSafe.action_executes_handler(_)), Bool.and(True{}, Bool.and(Bool.not(WcSafe.should_clear_reset_marker(rem_sess, 1n+rem_pair, cur_ep, cap_ep, pend_disc)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowNormal{}, failed_clear)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowDev{}, failed_clear)), True{})))))))) == True{} : Bool}
  %Equal.sym(Bool, WcSafe.can_admit_pair(is_init, is_disp, True{}), False{}, e_pair) : {Bool.and(Bool.not(_), Bool.and(Bool.not(WcSafe.can_admit_approve_session(is_disp, has_cli, True{})), Bool.and(Bool.not(WcSafe.can_finalize_approved_session(is_disp, has_cli, True{}, cur_gen, exp_gen, live_sess)), Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(WcSafe.should_clear_reset_marker(rem_sess, 1n+rem_pair, cur_ep, cap_ep, pend_disc)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowNormal{}, failed_clear)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowDev{}, failed_clear)), True{})))))))) == True{} : Bool}
  %Equal.sym(Bool, WcSafe.can_admit_approve_session(is_disp, has_cli, True{}), False{}, e_app) : {Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(Bool.not(WcSafe.can_finalize_approved_session(is_disp, has_cli, True{}, cur_gen, exp_gen, live_sess)), Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(WcSafe.should_clear_reset_marker(rem_sess, 1n+rem_pair, cur_ep, cap_ep, pend_disc)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowNormal{}, failed_clear)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowDev{}, failed_clear)), True{})))))))) == True{} : Bool}
  %Equal.sym(Bool, WcSafe.can_finalize_approved_session(is_disp, has_cli, True{}, cur_gen, exp_gen, live_sess), False{}, e_fin) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(WcSafe.should_clear_reset_marker(rem_sess, 1n+rem_pair, cur_ep, cap_ep, pend_disc)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowNormal{}, failed_clear)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowDev{}, failed_clear)), True{})))))))) == True{} : Bool}
  %Equal.sym(Bool, WcSafe.should_clear_reset_marker(rem_sess, 1n+rem_pair, cur_ep, cap_ep, pend_disc), False{}, e_rem2) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowNormal{}, failed_clear)), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowDev{}, failed_clear)), True{})))))))) == True{} : Bool}
  %Equal.sym(Bool, WL.splash_can_retry(WL.FlowNormal{}, failed_clear), False{}, e_norm) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(Bool.not(WL.splash_can_retry(WL.FlowDev{}, failed_clear)), True{})))))))) == True{} : Bool}
  %Equal.sym(Bool, WL.splash_can_retry(WL.FlowDev{}, failed_clear), False{}, e_dev) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), True{})))))))) == True{} : Bool}
  {==}

def chain_mismatch_from_eq(
  +eq_res: Bool,
  +sel: Nat,
  +conf: Nat,
  +sav: Nat,
  +ccid: Nat,
  +conn_cid: Nat,
  +disc: Bool,
  +pm: Maybe<&2, NS.MismatchPrompt>,
  +nc: Nat,
  +ar: Bool,
  +live_cid: Nat,
  +pre_ok: Bool,
  +rb_ok: Bool,
  +rest_cid: Nat,
  +not_ok: Bool,
  +bt: WC.BlockType,
  +fh: WC.HashKind,
  +sch: WC.ChainId,
  h: {eq_res == False{} : Bool}
) -> {Bool.and(
    NS.nm_has_pending_mismatch(
      NS.nm_confirm_mismatch_gate(
        Bool.not(eq_res),
        NS.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
        sel, conf, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
    Bool.and(
      Nat.is_eq(
        NS.nm_saved(
          NS.nm_confirm_mismatch_gate(
            Bool.not(eq_res),
            NS.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
            sel, conf, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
        sav),
      Bool.and(
        Laws.root_val_is_code(
          WC.validate_send_account_block.pick(
            Bool.and(WC.is_user_send_block(bt), Bool.and(WC.is_empty_hash(fh), Bool.and(eq_res, WC.chain_id_eq(sch, WC.chain_from_nat(ccid)))))),
          5003),
        Bool.not(eq_res)))) == True{} : Bool}:
  match eq_res:
    case True{}:
      Empty.absurd(
        {Bool.and(
          NS.nm_has_pending_mismatch(
            NS.nm_confirm_mismatch_gate(
              False{},
              NS.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
              sel, conf, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
          Bool.and(
            Nat.is_eq(
              NS.nm_saved(
                NS.nm_confirm_mismatch_gate(
                  False{},
                  NS.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
                  sel, conf, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
              sav),
            Bool.and(
              Laws.root_val_is_code(
                WC.validate_send_account_block.pick(
                  Bool.and(WC.is_user_send_block(bt), Bool.and(WC.is_empty_hash(fh), Bool.and(True{}, WC.chain_id_eq(sch, WC.chain_from_nat(ccid)))))),
                5003),
              False{}))) == True{} : Bool},
        NatL.true_is_not_false(h))
    case False{}:
      e_blk = and_false_3(WC.is_user_send_block(bt), WC.is_empty_hash(fh), WC.chain_id_eq(sch, WC.chain_from_nat(ccid)))
      %Equal.sym(Bool, Nat.is_eq(sav, sav), True{}, NatL.is_eq_same(sav)) : {Bool.and(True{}, Bool.and(_, Bool.and(Laws.root_val_is_code(WC.validate_send_account_block.pick(Bool.and(WC.is_user_send_block(bt), Bool.and(WC.is_empty_hash(fh), Bool.and(False{}, WC.chain_id_eq(sch, WC.chain_from_nat(ccid)))))), 5003), True{}))) == True{} : Bool}
      %Equal.sym(Bool, Bool.and(WC.is_user_send_block(bt), Bool.and(WC.is_empty_hash(fh), Bool.and(False{}, WC.chain_id_eq(sch, WC.chain_from_nat(ccid))))), False{}, e_blk) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Laws.root_val_is_code(WC.validate_send_account_block.pick(_), 5003), True{}))) == True{} : Bool}
      {==}

def Laws.chain_id_mismatch_blocks_node_wc_and_htlc(sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar, live_cid, pre_ok, rb_ok, rest_cid, not_ok, bt, fh, sch, neq):
  chain_mismatch_from_eq(Nat.is_eq(live_cid, ccid), sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar, live_cid, pre_ok, rb_ok, rest_cid, not_ok, bt, fh, sch, neq)

def reval_5003_from_eq(+eq_res: Bool, +svc_eq: Bool, h: {eq_res == False{} : Bool}) -> {Bool.and(
    Laws.root_reval_is_code(WC.revalidate.chain(True{}, Bool.and(svc_eq, eq_res)), 5003),
    Laws.root_reval_is_code(WC.revalidate.chain(True{}, Bool.and(svc_eq, eq_res)), 5003)) == True{} : Bool}:
  match eq_res:
    case True{}:
      Empty.absurd(
        {Bool.and(
          Laws.root_reval_is_code(WC.revalidate.chain(True{}, Bool.and(svc_eq, True{})), 5003),
          Laws.root_reval_is_code(WC.revalidate.chain(True{}, Bool.and(svc_eq, True{})), 5003)) == True{} : Bool},
        NatL.true_is_not_false(h))
    case False{}:
      match svc_eq:
        case False{}:
          {==}
        case True{}:
          {==}

def Laws.wc_revalidation_chain_mismatch_rejects_5003(has_rid, svc_c, sess_c, act_c, neq):
  match has_rid:
    case False{}:
      reval_5003_from_eq(WC.chain_id_eq(sess_c, act_c), WC.chain_id_eq(svc_c, act_c), neq)
    case True{}:
      reval_5003_from_eq(WC.chain_id_eq(sess_c, act_c), WC.chain_id_eq(svc_c, act_c), neq)

def plasma_color_tooltip_bijection(+t: Amt.PlasmaTier) -> {Bool.and(
    Laws.root_color_eq(Amt.tooltip_to_color(Amt.plasma_tooltip_from_tier(t)), Amt.plasma_color_from_tier(t)),
    Laws.root_tooltip_eq(Amt.color_to_tooltip(Amt.plasma_color_from_tier(t)), Amt.plasma_tooltip_from_tier(t))) == True{} : Bool}:
  match t:
    case Amt.PlasmaInsufficient{}:
      {==}
    case Amt.PlasmaLow{}:
      {==}
    case Amt.PlasmaAverage{}:
      {==}
    case Amt.PlasmaHigh{}:
      {==}

def Laws.plasma_thresholds_and_tiers_coherence(p):
  plasma_color_tooltip_bijection(Amt.plasma_tier(p))

def Laws.plasma_sufficiency_cross_domain_hierarchy(pk, op, role, extra):
  plasma_hierarchy_from_bounds(pk, op, role, extra, op_plasma_bounds(op))

def zero_bal_parse_err_rejected(+val: Nat, +dec: Nat, +min_val: Nat, +can_blank: Bool, +frac: Nat) -> {Amt.amount_is_ok(Amt.correct_value(val, 0n, dec, min_val, True{}, can_blank, False{}, False{}, frac)) == False{} : Bool}:
  match min_val:
    case 0n:
      {==}
    case 1n+_:
      {==}

def Laws.zero_balance_rejects_all_spend_ops(val, dec, min_val, can_blank, is_blank, parse_ok, frac, is_int, valid_ben, months, total, is_burn, is_own, znn_d, qsr_d):
  e_cv = zero_bal_parse_err_rejected(val, dec, min_val, can_blank, frac)
  e_burn = can_burn_zero_bal(val, total, is_burn, is_own)
  e_don = donation_zero_bals(znn_d, qsr_d)
  %Equal.sym(Bool, Amt.amount_is_ok(Amt.correct_value(val, 0n, dec, min_val, True{}, can_blank, False{}, False{}, frac)), False{}, e_cv) : {Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(Tok.can_burn_amount(val, 0n, total, is_burn, is_own)), Bool.and(Bool.not(Acc.is_valid_donation(znn_d, qsr_d, 0n, 0n)), True{})))))) == True{} : Bool}
  %Equal.sym(Bool, Tok.can_burn_amount(val, 0n, total, is_burn, is_own), False{}, e_burn) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(Bool.not(Acc.is_valid_donation(znn_d, qsr_d, 0n, 0n)), True{})))))) == True{} : Bool}
  %Equal.sym(Bool, Acc.is_valid_donation(znn_d, qsr_d, 0n, 0n), False{}, e_don) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), True{})))))) == True{} : Bool}
  {==}

def stale_rev_from_eq(
  +eq_res: Bool,
  +nid: Nat,
  +cur_rev: Nat,
  +field_ne: Bool,
  +il_st: Tx.ListStatus,
  +il_cnt: Nat,
  +il_hrm: Bool,
  +il_addr: Maybe<&2, Nat>,
  +il_ps: Nat,
  +fetched: Nat,
  +fetch_ok: Bool,
  h: {eq_res == False{} : Bool}
) -> {Bool.and(
    Maybe.is_some(&2, Nat, NS.banner_active(NS.notif_dismiss_gate(eq_res, NS.NotifBannerState{Some{nid}, cur_rev}))),
    Bool.and(
      Nat.is_eq(NS.banner_revision(NS.notif_dismiss_gate(eq_res, NS.NotifBannerState{Some{nid}, cur_rev})), cur_rev),
      Bool.and(
        Bool.not(WC.card_outcome_cleared(WC.uri_card_on_pair_success.pick(cur_rev, field_ne, eq_res))),
        Laws.root_il_state_preserved(
          Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps},
          Tx.il_apply_first_gate(eq_res, Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps}, fetched, fetch_ok))))) == True{} : Bool}:
  match eq_res:
    case True{}:
      Empty.absurd(
        {Bool.and(
          Maybe.is_some(&2, Nat, NS.banner_active(NS.notif_dismiss_gate(True{}, NS.NotifBannerState{Some{nid}, cur_rev}))),
          Bool.and(
            Nat.is_eq(NS.banner_revision(NS.notif_dismiss_gate(True{}, NS.NotifBannerState{Some{nid}, cur_rev})), cur_rev),
            Bool.and(
              Bool.not(WC.card_outcome_cleared(WC.uri_card_on_pair_success.pick(cur_rev, field_ne, True{}))),
              Laws.root_il_state_preserved(
                Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps},
                Tx.il_apply_first_gate(True{}, Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps}, fetched, fetch_ok))))) == True{} : Bool},
        NatL.true_is_not_false(h))
    case False{}:
      %Equal.sym(Bool, Nat.is_eq(cur_rev, cur_rev), True{}, NatL.is_eq_same(cur_rev)) : {Bool.and(True{}, Bool.and(_, Bool.and(True{}, Laws.root_il_state_preserved(Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps}, Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps})))) == True{} : Bool}
      il_state_preserved_refl(il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps)

def Laws.stale_revision_fences_ui_across_domains(nid, stale_rev, cur_rev, field_ne, il_st, il_cnt, il_hrm, il_addr, il_ps, fetched, fetch_ok, neq):
  stale_rev_from_eq(Nat.is_eq(stale_rev, cur_rev), nid, cur_rev, field_ne, il_st, il_cnt, il_hrm, il_addr, il_ps, fetched, fetch_ok, neq)

def Laws.security_defense_in_depth(val, url, blk, acid, aaddr, raddr, oaddrs, rst, op, os_ok, fb_ok, bytes_ok, k):
  {==}

def can_delete_key_isolated(+mode: WcSafe.StoreMode, +has_man: Bool, +owned: List<&2, Nat>, +fid: Nat) -> {Bool.and(
    Bool.not(WcSafe.can_delete_key(mode, has_man, owned, WcSafe.KeyFallbackFlag{})),
    Bool.and(
      Bool.not(WcSafe.can_delete_key(mode, True{}, owned, WcSafe.KeyForeign{fid})),
      Bool.not(WcSafe.can_delete_key(WcSafe.ModeSecure{}, has_man, owned, WcSafe.KeyForeign{fid})))) == True{} : Bool}:
  match mode has_man:
    case WcSafe.ModeSecure{} False{}:
      {==}
    case WcSafe.ModeSecure{} True{}:
      {==}
    case WcSafe.ModeTransientFallback{} False{}:
      {==}
    case WcSafe.ModeTransientFallback{} True{}:
      {==}
    case WcSafe.ModeAuthoritativeFallback{} False{}:
      {==}
    case WcSafe.ModeAuthoritativeFallback{} True{}:
      {==}

def Laws.sanitizer_zero_preimage_leakage_and_key_isolation(err, s1, s2, mode, has_man, owned, fid):
  e_san = HtlcLaws.sanitizer_zero_preimage_leakage(err, s1, s2)
  e_iso = can_delete_key_isolated(mode, has_man, owned, fid)
  %Equal.sym(Htlc.SanitizedSummary, Htlc.sanitize_error(Htlc.replace_secrets(err, s1)), Htlc.sanitize_error(Htlc.replace_secrets(err, s2)), e_san) : {Bool.and(Laws.root_summary_eq(_, Htlc.sanitize_error(Htlc.replace_secrets(err, s2))), Bool.and(Bool.not(WcSafe.can_delete_key(mode, has_man, owned, WcSafe.KeyFallbackFlag{})), Bool.and(Bool.not(WcSafe.can_delete_key(mode, True{}, owned, WcSafe.KeyForeign{fid})), Bool.not(WcSafe.can_delete_key(WcSafe.ModeSecure{}, has_man, owned, WcSafe.KeyForeign{fid}))))) == True{} : Bool}
  %Equal.sym(Bool, Laws.root_summary_eq(Htlc.sanitize_error(Htlc.replace_secrets(err, s2)), Htlc.sanitize_error(Htlc.replace_secrets(err, s2))), True{}, summary_eq_refl(Htlc.sanitize_error(Htlc.replace_secrets(err, s2)))) : {Bool.and(_, Bool.and(Bool.not(WcSafe.can_delete_key(mode, has_man, owned, WcSafe.KeyFallbackFlag{})), Bool.and(Bool.not(WcSafe.can_delete_key(mode, True{}, owned, WcSafe.KeyForeign{fid})), Bool.not(WcSafe.can_delete_key(WcSafe.ModeSecure{}, has_man, owned, WcSafe.KeyForeign{fid}))))) == True{} : Bool}
  e_iso

def Laws.pillar_governance_and_role_coherence(addr_valid, nv, na, rv, pv, mp, dp, id1, id2, own1, addr, prod2, rest, status, p, neq):
  e_prod = and_false_r(addr_valid)
  e_pv = and_false_r(pv)
  e_dep = and_false_4(nv, na, rv, Bool.and(Pil.valid_reward_pct(mp), Pil.valid_reward_pct(dp)))
  e_quor = AccLaws.quorum_strictly_exceeds_33_percent(p)
  %Equal.sym(Bool, Pil.valid_pillar_producer(addr_valid, True{}), False{}, e_prod) : {Bool.and(Bool.not(_), Bool.and(Bool.not(Pil.valid_pillar_deploy(nv, na, rv, pv, True{}, mp, dp)), Bool.and(True{}, Bool.and(Laws.root_pillar_opt_has_id(Acc.pillar_for_address(Acc.Pillar{id1, own1, addr} <> (Acc.Pillar{id2, addr, prod2} <> rest), addr), id2), Bool.and(Acc.vote_method_is_by_name(Acc.vote_method_for(Acc.Pillar{id2, addr, prod2}, addr)), Nat.is_gt(Nat.mul(Acc.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n))))))) == True{} : Bool}
  %Equal.sym(Bool, Bool.and(pv, False{}), False{}, e_pv) : {Bool.and(True{}, Bool.and(Bool.not(Bool.and(nv, Bool.and(na, Bool.and(rv, Bool.and(_, Bool.and(Pil.valid_reward_pct(mp), Pil.valid_reward_pct(dp))))))), Bool.and(True{}, Bool.and(Laws.root_pillar_opt_has_id(Acc.pillar_for_address(Acc.Pillar{id1, own1, addr} <> (Acc.Pillar{id2, addr, prod2} <> rest), addr), id2), Bool.and(Acc.vote_method_is_by_name(Acc.vote_method_for(Acc.Pillar{id2, addr, prod2}, addr)), Nat.is_gt(Nat.mul(Acc.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n))))))) == True{} : Bool}
  %Equal.sym(Bool, Bool.and(nv, Bool.and(na, Bool.and(rv, Bool.and(False{}, Bool.and(Pil.valid_reward_pct(mp), Pil.valid_reward_pct(dp)))))), False{}, e_dep) : {Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(True{}, Bool.and(Laws.root_pillar_opt_has_id(Acc.pillar_for_address(Acc.Pillar{id1, own1, addr} <> (Acc.Pillar{id2, addr, prod2} <> rest), addr), id2), Bool.and(Acc.vote_method_is_by_name(Acc.vote_method_for(Acc.Pillar{id2, addr, prod2}, addr)), Nat.is_gt(Nat.mul(Acc.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n))))))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(own1, addr), False{}, neq) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Laws.root_pillar_opt_has_id(Acc.pillar_for_address.or(Acc.pick_pillar(_, Acc.Pillar{id1, own1, addr}, Acc.pick_pillar(Nat.is_eq(addr, addr), Acc.Pillar{id2, addr, prod2}, Acc.find_owner(rest, addr))), Acc.Pillar{id1, own1, addr} <> (Acc.Pillar{id2, addr, prod2} <> rest), addr), id2), Bool.and(Acc.vote_method_is_by_name(Acc.vote_method_for.pick(Nat.is_eq(addr, addr))), Nat.is_gt(Nat.mul(Acc.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n))))))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(addr, addr), True{}, NatL.is_eq_same(addr)) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Laws.root_pillar_opt_has_id(Acc.pillar_for_address.or(Acc.pick_pillar(_, Acc.Pillar{id2, addr, prod2}, Acc.find_owner(rest, addr)), Acc.Pillar{id1, own1, addr} <> (Acc.Pillar{id2, addr, prod2} <> rest), addr), id2), Bool.and(Acc.vote_method_is_by_name(Acc.vote_method_for.pick(_)), Nat.is_gt(Nat.mul(Acc.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n))))))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(id2, id2), True{}, NatL.is_eq_same(id2)) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(_, Bool.and(True{}, Nat.is_gt(Nat.mul(Acc.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n))))))) == True{} : Bool}
  e_quor

def Laws.token_and_asset_ordering_coherence(a, b, m, burn, tot, mx, own, wown):
  match a b m:
    case Amt.Znn{} Amt.Znn{} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Znn{} Amt.Znn{} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Znn{} Amt.Qsr{} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Znn{} Amt.Qsr{} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Znn{} Amt.Zts{_} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Znn{} Amt.Zts{_} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Qsr{} Amt.Znn{} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Qsr{} Amt.Znn{} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Qsr{} Amt.Qsr{} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Qsr{} Amt.Qsr{} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Qsr{} Amt.Zts{_} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Qsr{} Amt.Zts{_} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Zts{_} Amt.Znn{} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Zts{_} Amt.Znn{} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Zts{_} Amt.Qsr{} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Zts{_} Amt.Qsr{} True{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Zts{_} Amt.Zts{_} False{}:
      bool_eq_refl_local(Bool.or(burn, own))
    case Amt.Zts{_} Amt.Zts{_} True{}:
      bool_eq_refl_local(Bool.or(burn, own))

def Laws.sync_threshold_and_clock_skew_coherence(st, cur, tgt, frontier):
  e_lag20 = sub_add_20_ge(cur)
  e_imp = sync3_implies_sync20(st, cur, tgt)
  e_skew = clock_skew_zero(st, cur, tgt, frontier)
  %Equal.sym(Bool, Nat.is_lt(Nat.sub(Nat.add(1n+cur, 20n), 1n+cur), 20n), False{}, e_lag20) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(Bool.and(Nat.is_gt(Nat.add(1n+cur, 20n), 0n), Bool.and(True{}, _))), Bool.and(Bool.or(Bool.not(NS.sync_info_is_synced(st, cur, tgt)), NS.node_is_synced_20(st, cur, tgt)), Bool.not(NS.should_warn_clock_skew(st, cur, tgt, frontier, frontier)))))) == True{} : Bool}
  %Equal.sym(Bool, Bool.or(Bool.not(NS.sync_info_is_synced(st, cur, tgt)), NS.node_is_synced_20(st, cur, tgt)), True{}, e_imp) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(Bool.and(Nat.is_gt(Nat.add(1n+cur, 20n), 0n), False{})), Bool.and(_, Bool.not(NS.should_warn_clock_skew(st, cur, tgt, frontier, frontier)))))) == True{} : Bool}
  %Equal.sym(Bool, NS.should_warn_clock_skew(st, cur, tgt, frontier, frontier), False{}, e_skew) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(Bool.and(Nat.is_gt(Nat.add(1n+cur, 20n), 0n), False{})), Bool.and(True{}, Bool.not(_))))) == True{} : Bool}
  %Equal.sym(Bool, Bool.and(Nat.is_gt(Nat.add(1n+cur, 20n), 0n), False{}), False{}, and_false_r(Nat.is_gt(Nat.add(1n+cur, 20n), 0n))) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), True{}))) == True{} : Bool}
  {==}

def Laws.root_audit_par_equiv_seq(
  plasma_u32, is_unlocked, is_hw, qsr, qsr_bal,
  znn_bal, is_mintable, is_burnable, is_owner, tx_st, tx_cur, tx_tgt,
  ns_st, ns_cur, ns_tgt, htlc_exp, htlc_now, yes_v, no_v,
  verify_ctx, wc_url, wc_init, wc_disp, wc_reset
):
  {==}
