import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# Local arithmetic helper lemmas
# ------------------------------

def add_lt_left(+a: Nat, +b: Nat, +c: Nat, lt: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_lt(Nat.add(c, a), Nat.add(c, b)) == True{} : Bool}:
  match c:
    case 0n:
      lt
    case 1n+cp:
      add_lt_left(a, b, cp, lt)

def lt_implies_sub_gt_zero(+a: Nat, +b: Nat, lt: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_gt(Nat.sub(b, a), 0n) == True{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_gt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(lt))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_gt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(lt))
    case 1n+ap 1n+bp:
      lt_implies_sub_gt_zero(ap, bp, lt)

def not_le_from_gt_rec(+a: Nat, +b: Nat, gt: {Nat.is_gt(a, b) == True{} : Bool}) -> {Nat.is_le(a, b) == False{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_le(0n, 0n) == False{} : Bool}, NatL.false_is_not_true(gt))
    case 0n 1n+bp:
      Empty.absurd({Nat.is_le(0n, 1n+bp) == False{} : Bool}, NatL.false_is_not_true(gt))
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      not_le_from_gt_rec(ap, bp, gt)

def not_ge_from_lt_rec(+a: Nat, +b: Nat, lt: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_ge(a, b) == False{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_ge(0n, 0n) == False{} : Bool}, NatL.false_is_not_true(lt))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_ge(1n+ap, 0n) == False{} : Bool}, NatL.false_is_not_true(lt))
    case 1n+ap 1n+bp:
      not_ge_from_lt_rec(ap, bp, lt)

def min_add_ge_left(+s: Nat, +p: Nat, +l: Nat, sl: {Nat.is_le(s, l) == True{} : Bool}) -> {Nat.is_le(s, Nat.min(Nat.add(s, p), l)) == True{} : Bool}:
  match s l:
    case 0n _:
      NatL.is_le_zero(Nat.min(Nat.add(0n, p), l))
    case 1n+sp 0n:
      Empty.absurd({Nat.is_le(1n+sp, Nat.min(Nat.add(1n+sp, p), 0n)) == True{} : Bool}, NatL.false_is_not_true(sl))
    case 1n+sp 1n+lp:
      min_add_ge_left(sp, p, lp, sl)

def xor_fusion_from_gt(+b: Bool, +l: Nat, +e: Nat) -> {Bool.xor(M.fusion_is_revocable(M.fusion_status_from_gt(b, l, e)), M.fusion_is_locked(M.fusion_status_from_gt(b, l, e))) == True{} : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def and_false_middle(+a: Bool, +b: Bool) -> {Bool.and(a, Bool.and(False{}, b)) == False{} : Bool}:
  match a:
    case False{}:
      {==}
    case True{}:
      {==}

def and_false_third(+a: Bool, +b: Bool, +c: Bool) -> {Bool.and(a, Bool.and(b, Bool.and(False{}, c))) == False{} : Bool}:
  match a b:
    case False{} _:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def and_false_fourth(+a: Bool, +b: Bool, +c: Bool, +d: Bool) -> {Bool.and(a, Bool.and(b, Bool.and(c, Bool.and(d, False{})))) == False{} : Bool}:
  match a b c d:
    case False{} _ _ _:
      {==}
    case True{} False{} _ _:
      {==}
    case True{} True{} False{} _:
      {==}
    case True{} True{} True{} False{}:
      {==}
    case True{} True{} True{} True{}:
      {==}

def and_false_fourth_l(+a: Bool, +b: Bool, +c: Bool, +d: Bool) -> {Bool.and(a, Bool.and(b, Bool.and(c, Bool.and(False{}, d)))) == False{} : Bool}:
  match a b c:
    case False{} _ _:
      {==}
    case True{} False{} _:
      {==}
    case True{} True{} False{}:
      {==}
    case True{} True{} True{}:
      {==}

# Law proofs
# ----------

def Laws.plasma_for_qsr_zero(rate):
  {==}

def Laws.plasma_for_qsr_additive(a, b, rate):
  match a:
    case 0n:
      {==}
    case 1n+ap:
      ih = Laws.plasma_for_qsr_additive(ap, b, rate)
      %Equal.sym(Nat, Nat.mul(Nat.add(ap, b), rate), Nat.add(Nat.mul(ap, rate), Nat.mul(b, rate)), ih) : {Nat.add(rate, _) == Nat.add(Nat.add(rate, Nat.mul(ap, rate)), Nat.mul(b, rate)) : Nat}
      Equal.sym(
        Nat,
        Nat.add(Nat.add(rate, Nat.mul(ap, rate)), Nat.mul(b, rate)),
        Nat.add(rate, Nat.add(Nat.mul(ap, rate), Nat.mul(b, rate))),
        NatL.add_assoc(rate, Nat.mul(ap, rate), Nat.mul(b, rate)))

def Laws.plasma_for_qsr_monotone(a, b, rate, h):
  match a b:
    case 0n _:
      NatL.is_le_zero(Nat.mul(b, rate))
    case 1n+ap 0n:
      Empty.absurd({Nat.is_le(Nat.mul(1n+ap, rate), 0n) == True{} : Bool}, NatL.false_is_not_true(h))
    case 1n+ap 1n+bp:
      NatL.add_monotone_le(
        rate,
        rate,
        Nat.mul(ap, rate),
        Nat.mul(bp, rate),
        NatL.is_le_refl(rate),
        Laws.plasma_for_qsr_monotone(ap, bp, rate, h))

def Laws.op_plasma_u32_exact():
  {==}

def Laws.op_plasma_strict_order():
  {==}

def Laws.meets_plasma_monotone(p1, p2, req, le, ok):
  req_le_p1 = Equal.trans(
    Bool,
    Nat.is_le(req, p1),
    Nat.is_ge(p1, req),
    True{},
    Equal.sym(Bool, Nat.is_ge(p1, req), Nat.is_le(req, p1), NatL.is_ge_as_le(p1, req)),
    ok)
  %Equal.sym(Bool, Nat.is_ge(p2, req), Nat.is_le(req, p2), NatL.is_ge_as_le(p2, req)) : {_ == True{} : Bool}
  NatL.le_trans(req, p1, p2, req_le_p1, le)

def Laws.fuse_rejects_zero_balance(qsr, is_int, valid_ben):
  {==}

def Laws.fuse_rejects_below_min(qsr, bal, is_int, valid_ben, lt):
  ng = not_ge_from_lt_rec(qsr, 10n, lt)
  %Equal.sym(Bool, Nat.is_ge(qsr, 10n), False{}, ng) : {Bool.and(Nat.is_gt(bal, 0n), Bool.and(_, Bool.and(Nat.is_le(qsr, bal), Bool.and(is_int, valid_ben)))) == False{} : Bool}
  and_false_middle(Nat.is_gt(bal, 0n), Bool.and(Nat.is_le(qsr, bal), Bool.and(is_int, valid_ben)))

def Laws.fuse_rejects_above_balance(qsr, bal, is_int, valid_ben, gt):
  nl = not_le_from_gt_rec(qsr, bal, gt)
  %Equal.sym(Bool, Nat.is_le(qsr, bal), False{}, nl) : {Bool.and(Nat.is_gt(bal, 0n), Bool.and(Nat.is_ge(qsr, 10n), Bool.and(_, Bool.and(is_int, valid_ben)))) == False{} : Bool}
  and_false_third(Nat.is_gt(bal, 0n), Nat.is_ge(qsr, 10n), Bool.and(is_int, valid_ben))

def Laws.fuse_requires_integer_and_beneficiary(qsr, bal):
  e1 = and_false_fourth_l(Nat.is_gt(bal, 0n), Nat.is_ge(qsr, 10n), Nat.is_le(qsr, bal), True{})
  e2 = and_false_fourth(Nat.is_gt(bal, 0n), Nat.is_ge(qsr, 10n), Nat.is_le(qsr, bal), True{})
  %Equal.sym(Bool, M.can_fuse_plasma(qsr, bal, False{}, True{}), False{}, e1) : {Bool.and(Bool.not(_), Bool.and(Bool.not(M.can_fuse_plasma(qsr, bal, True{}, False{})), True{})) == True{} : Bool}
  %Equal.sym(Bool, M.can_fuse_plasma(qsr, bal, True{}, False{}), False{}, e2) : {Bool.and(True{}, Bool.and(Bool.not(_), True{})) == True{} : Bool}
  {==}

def Laws.fusion_status_exact_partition(last_height, exp_height):
  xor_fusion_from_gt(Nat.is_gt(last_height, exp_height), last_height, exp_height)

def Laws.fusion_eq_boundary_locked_zero(h):
  %Equal.sym(Bool, Nat.is_gt(h, h), Nat.is_lt(h, h), NatL.is_gt_as_lt(h, h)) : {M.fusion_status_from_gt(_, h, h) == M.FusionLocked{0n} : M.FusionStatus}
  %Equal.sym(Bool, Nat.is_lt(h, h), False{}, NatL.is_lt_irrefl(h)) : {M.fusion_status_from_gt(_, h, h) == M.FusionLocked{0n} : M.FusionStatus}
  %Equal.sym(Nat, Nat.sub(h, h), 0n, NatL.sub_self(h)) : {M.FusionLocked{Nat.mul(10n, _)} == M.FusionLocked{0n} : M.FusionStatus}
  {==}

def Laws.fusion_above_exp_revocable(last_height, exp_height, gt):
  %Equal.sym(Bool, Nat.is_gt(last_height, exp_height), True{}, gt) : {M.fusion_status_from_gt(_, last_height, exp_height) == M.FusionRevocable{} : M.FusionStatus}
  {==}

def Laws.cancel_timer_stopped_idempotent(rem, fired):
  {==}

def Laws.cancel_timer_terminates_cleanly(fired):
  %Equal.sym(Bool, Nat.is_eq(fired, fired), True{}, NatL.is_eq_same(fired)) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

def Laws.cancel_timer_no_storm_after_zero(k, fired):
  match k:
    case 0n:
      {==}
    case 1n+kp:
      Laws.cancel_timer_no_storm_after_zero(kp, fired)

def Laws.page_slice_start_le_end(list_len, page_index, page_size):
  min_add_ge_left(
    Nat.min(Nat.mul(page_index, page_size), list_len),
    page_size,
    list_len,
    NatL.min_le_right(Nat.mul(page_index, page_size), list_len))

def Laws.page_slice_end_le_len(list_len, page_index, page_size):
  NatL.min_le_right(
    Nat.add(Nat.min(Nat.mul(page_index, page_size), list_len), page_size),
    list_len)

def Laws.stake_months_bounds(k):
  {==}

def Laws.stake_duration_strictly_monotone(m1, m2, u, lt):
  match m1 m2:
    case 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(lt))
    case 0n 1n+m2p:
      {==}
    case 1n+m1p 0n:
      Empty.absurd({Nat.is_lt(Nat.mul(1n+m1p, 1n+u), 0n) == True{} : Bool}, NatL.false_is_not_true(lt))
    case 1n+m1p 1n+m2p:
      add_lt_left(
        Nat.mul(m1p, 1n+u),
        Nat.mul(m2p, 1n+u),
        1n+u,
        Laws.stake_duration_strictly_monotone(m1p, m2p, u, lt))

def Laws.stake_duration_u32_exact():
  {==}

def not_le_add_pos(+bal: Nat, +k: Nat) -> {Nat.is_le(Nat.add(bal, 1n+k), bal) == False{} : Bool}:
  match bal:
    case 0n:
      {==}
    case 1n+bp:
      not_le_add_pos(bp, k)

def and_false_third_right(+a: Bool, +b: Bool, +c: Bool) -> {Bool.and(a, Bool.and(b, Bool.and(c, False{}))) == False{} : Bool}:
  match a b c:
    case False{} _ _:
      {==}
    case True{} False{} _:
      {==}
    case True{} True{} False{}:
      {==}
    case True{} True{} True{}:
      {==}

def Laws.create_stake_guards(amt, bal, months, k):
  e_zero_amt = and_false_middle(Nat.is_gt(bal, 0n), Bool.and(Nat.is_le(0n, bal), M.valid_stake_months(months)))
  nl = not_le_add_pos(bal, k)
  e_gt_bal_step = and_false_third(Nat.is_gt(bal, 0n), Nat.is_ge(Nat.add(bal, 1n+k), 1n), M.valid_stake_months(months))
  e_m0 = and_false_third_right(Nat.is_gt(bal, 0n), Nat.is_ge(amt, 1n), Nat.is_le(amt, bal))
  e_m13 = and_false_third_right(Nat.is_gt(bal, 0n), Nat.is_ge(amt, 1n), Nat.is_le(amt, bal))
  %Equal.sym(Bool, M.can_create_stake(0n, bal, months), False{}, e_zero_amt) : {Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(Bool.not(M.can_create_stake(Nat.add(bal, 1n+k), bal, months)), Bool.and(Bool.not(M.can_create_stake(amt, bal, 0n)), Bool.and(Bool.not(M.can_create_stake(amt, bal, 13n+k)), True{}))))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(Nat.add(bal, 1n+k), bal), False{}, nl) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(Bool.and(Nat.is_gt(bal, 0n), Bool.and(Nat.is_ge(Nat.add(bal, 1n+k), 1n), Bool.and(_, M.valid_stake_months(months))))), Bool.and(Bool.not(M.can_create_stake(amt, bal, 0n)), Bool.and(Bool.not(M.can_create_stake(amt, bal, 13n+k)), True{}))))) == True{} : Bool}
  %Equal.sym(Bool, Bool.and(Nat.is_gt(bal, 0n), Bool.and(Nat.is_ge(Nat.add(bal, 1n+k), 1n), Bool.and(False{}, M.valid_stake_months(months)))), False{}, e_gt_bal_step) : {Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(Bool.not(M.can_create_stake(amt, bal, 0n)), Bool.and(Bool.not(M.can_create_stake(amt, bal, 13n+k)), True{}))))) == True{} : Bool}
  %Equal.sym(Bool, M.can_create_stake(amt, bal, 0n), False{}, e_m0) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), Bool.and(Bool.not(M.can_create_stake(amt, bal, 13n+k)), True{}))))) == True{} : Bool}
  %Equal.sym(Bool, M.can_create_stake(amt, bal, 13n+k), False{}, e_m13) : {Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(True{}, Bool.and(Bool.not(_), True{}))))) == True{} : Bool}
  {==}

def Laws.stake_lock_expired_at_or_past(now_sec, exp_sec, ge):
  %Equal.sym(Bool, Nat.is_ge(now_sec, exp_sec), True{}, ge) : {M.stake_lock_from_ge(_, now_sec, exp_sec) == M.StakeExpired{} : M.StakeLockStatus}
  {==}

def stake_lock_succ_eq(+b: Bool, +np: Nat, +ep: Nat) -> {M.stake_lock_from_ge(b, 1n+np, 1n+ep) == M.stake_lock_from_ge(b, np, ep) : M.StakeLockStatus}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.stake_lock_positive_countdown_before_exp(now_sec, exp_sec, lt):
  match now_sec exp_sec:
    case 0n 0n:
      Empty.absurd({Nat.is_gt(M.stake_locked_secs(M.stake_lock_status(0n, 0n)), 0n) == True{} : Bool}, NatL.false_is_not_true(lt))
    case 0n 1n+ep:
      {==}
    case 1n+np 0n:
      Empty.absurd({Nat.is_gt(M.stake_locked_secs(M.stake_lock_status(1n+np, 0n)), 0n) == True{} : Bool}, NatL.false_is_not_true(lt))
    case 1n+np 1n+ep:
      %Equal.sym(M.StakeLockStatus, M.stake_lock_from_ge(Nat.is_ge(np, ep), 1n+np, 1n+ep), M.stake_lock_from_ge(Nat.is_ge(np, ep), np, ep), stake_lock_succ_eq(Nat.is_ge(np, ep), np, ep)) : {Nat.is_gt(M.stake_locked_secs(_), 0n) == True{} : Bool}
      Laws.stake_lock_positive_countdown_before_exp(np, ep, lt)

def Laws.stake_collect_qsr_only_and_history_gate(q, znn, rest):
  {==}

def Laws.epoch_day_monotone(g, e1, e2, le):
  NatL.add_monotone_le(g, g, 1n+e1, 1n+e2, NatL.is_le_refl(g), le)

def Laws.parallel_plasma_staking_equiv(qsr, qsr_bal, is_int, valid_ben, znn, znn_bal, months):
  {==}
