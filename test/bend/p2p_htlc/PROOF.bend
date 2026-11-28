import Base
import ./model.bend as M
import ./LAWS.bend as Laws
import ../common/nat.bend as NatL

# Local Nat & Domain Helper Lemmas
# --------------------------------

# Nat.sub(Nat.sub(a, b), c) == Nat.sub(a, Nat.add(b, c))
law sub_sub:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  {Nat.sub(Nat.sub(a, b), c) == Nat.sub(a, Nat.add(b, c)) : Nat}

def sub_sub(a, b, c):
  match a b:
    case 0n 0n:
      {==}
    case 1n+ap 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 1n+bp:
      sub_sub(ap, bp, c)

# Helper: rewrite Nat.is_le(Nat.add(a, 1n+bp), c) -> Nat.is_le(1n+Nat.add(a, bp), c)
law le_add_succ_elim:
  for +a: Nat
  for +bp: Nat
  for +c: Nat
  for e: {Nat.is_le(Nat.add(a, 1n+bp), c) == True{} : Bool}
  {Nat.is_le(1n+Nat.add(a, bp), c) == True{} : Bool}

def le_add_succ_elim(a, bp, c, e):
  %NatL.add_succ(a, bp) : {Nat.is_le(_, c) == True{} : Bool}
  e

law le_add_zero_elim:
  for +a: Nat
  for +c: Nat
  for e: {Nat.is_le(Nat.add(a, 0n), c) == True{} : Bool}
  {Nat.is_le(a, c) == True{} : Bool}

def le_add_zero_elim(a, c, e):
  %NatL.add_zero(a) : {Nat.is_le(_, c) == True{} : Bool}
  e

# Nat.is_le(Nat.add(a, b), c) == True => Nat.is_le(a, Nat.sub(c, b)) == True
law add_le_to_le_sub:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for e: {Nat.is_le(Nat.add(a, b), c) == True{} : Bool}
  {Nat.is_le(a, Nat.sub(c, b)) == True{} : Bool}

def add_le_to_le_sub(a, b, c, e):
  match b c:
    case 0n _:
      %Equal.sym(Nat, Nat.sub(c, 0n), c, NatL.sub_zero(c)) : {Nat.is_le(a, _) == True{} : Bool}
      le_add_zero_elim(a, c, e)
    case 1n+bp 0n:
      Empty.absurd({Nat.is_le(a, 0n) == True{} : Bool}, NatL.false_is_not_true(le_add_succ_elim(a, bp, 0n, e)))
    case 1n+bp 1n+cp:
      add_le_to_le_sub(a, bp, cp, le_add_succ_elim(a, bp, 1n+cp, e))

law le_to_ge:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_le(a, b) == True{} : Bool}
  {Nat.is_ge(b, a) == True{} : Bool}

def le_to_ge(a, b, e):
  %Equal.sym(Bool, Nat.is_ge(b, a), Nat.is_le(a, b), NatL.is_ge_as_le(b, a)) : {_ == True{} : Bool}
  e

law ge_to_le:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_ge(a, b) == True{} : Bool}
  {Nat.is_le(b, a) == True{} : Bool}

def ge_to_le(a, b, e):
  %NatL.is_ge_as_le(a, b) : {_ == True{} : Bool}
  e

law gt_add_implies_not_le:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for e: {Nat.is_gt(a, Nat.add(b, c)) == True{} : Bool}
  {Nat.is_le(a, b) == False{} : Bool}

def gt_add_implies_not_le(a, b, c, e):
  match a b:
    case 0n 0n:
      match c:
        case 0n:
          Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(e))
        case 1n+cp:
          Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(e))
    case 0n 1n+bp:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      gt_add_implies_not_le(ap, bp, c, e)

law gt_implies_le_false:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_gt(a, b) == True{} : Bool}
  {Nat.is_le(a, b) == False{} : Bool}

def gt_implies_le_false(a, b, e):
  match a b:
    case 0n 0n:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(e))
    case 0n 1n+bp:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      gt_implies_le_false(ap, bp, e)

law ge_implies_lt_false:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_ge(a, b) == True{} : Bool}
  {Nat.is_lt(a, b) == False{} : Bool}

def ge_implies_lt_false(a, b, e):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      ge_implies_lt_false(ap, bp, e)

law succ_sub_le_of_lt_add:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for ab: {Nat.is_le(a, b) == True{} : Bool}
  for bc: {Nat.is_lt(b, Nat.add(a, c)) == True{} : Bool}
  {Nat.is_le(1n+Nat.sub(b, a), c) == True{} : Bool}

def succ_sub_le_of_lt_add(a, b, c, ab, bc):
  match a b:
    case 0n 0n:
      match c:
        case 0n:
          Empty.absurd({Nat.is_le(1n, 0n) == True{} : Bool}, NatL.false_is_not_true(bc))
        case 1n+cp:
          NatL.is_le_zero(cp)
    case 0n 1n+bp:
      match c:
        case 0n:
          Empty.absurd({Nat.is_le(2n+bp, 0n) == True{} : Bool}, NatL.false_is_not_true(bc))
        case 1n+cp:
          %NatL.sub_zero(bp) : {Nat.is_le(1n+_, cp) == True{} : Bool}
          succ_sub_le_of_lt_add(0n, bp, cp, NatL.is_le_zero(bp), bc)
    case 1n+ap 0n:
      Empty.absurd({Nat.is_le(1n, c) == True{} : Bool}, NatL.false_is_not_true(ab))
    case 1n+ap 1n+bp:
      succ_sub_le_of_lt_add(ap, bp, c, ab, bc)

law add_succ_sub:
  for +a: Nat
  for +b: Nat
  for ab: {Nat.is_le(a, b) == True{} : Bool}
  {Nat.add(a, 1n+Nat.sub(b, a)) == 1n+b : Nat}

def add_succ_sub(a, b, ab):
  %Equal.sym(Nat, Nat.add(a, 1n+Nat.sub(b, a)), 1n+Nat.add(a, Nat.sub(b, a)), NatL.add_succ(a, Nat.sub(b, a))) : {_ == 1n+b : Nat}
  %NatL.add_comm(Nat.sub(b, a), a) : {1n+_ == 1n+b : Nat}
  %NatL.sub_add(a, b, ab) : {1n+Nat.add(Nat.sub(b, a), a) == 1n+_ : Nat}
  {==}

law add_succ_sub_eq_true:
  for +a: Nat
  for +b: Nat
  for ab: {Nat.is_le(a, b) == True{} : Bool}
  {Nat.is_eq(Nat.add(a, 1n+Nat.sub(b, a)), 1n+b) == True{} : Bool}

def add_succ_sub_eq_true(a, b, ab):
  %add_succ_sub(a, b, ab) : {Nat.is_eq(Nat.add(a, 1n+Nat.sub(b, a)), _) == True{} : Bool}
  NatL.is_eq_same(Nat.add(a, 1n+Nat.sub(b, a)))

law sub_add_add_not_lt:
  for +t: Nat
  for +d: Nat
  for +e: Nat
  {Nat.is_lt(Nat.sub(Nat.add(Nat.add(t, d), e), t), d) == False{} : Bool}

def sub_add_add_not_lt(t, d, e):
  %Equal.sym(Nat, Nat.add(Nat.add(t, d), e), Nat.add(t, Nat.add(d, e)), NatL.add_assoc(t, d, e)) : {Nat.is_lt(Nat.sub(_, t), d) == False{} : Bool}
  %Equal.sym(Nat, Nat.sub(Nat.add(t, Nat.add(d, e)), t), Nat.add(d, e), NatL.sub_cancel_add_left(t, Nat.add(d, e))) : {Nat.is_lt(_, d) == False{} : Bool}
  ge_implies_lt_false(Nat.add(d, e), d, le_to_ge(d, Nat.add(d, e), NatL.is_le_add_right(d, e)))

law unwrap_sqlite_secret_invariant:
  for fuel: Nat
  for +err: M.SwapError
  for +s1: Nat
  for +s2: Nat
  {M.unwrap_sqlite(fuel, M.replace_secrets(err, s1)) == M.unwrap_sqlite(fuel, M.replace_secrets(err, s2)) : Maybe<&2, Nat>}

def unwrap_sqlite_secret_invariant(fuel, err, s1, s2):
  match fuel:
    case 0n:
      {==}
    case 1n+p:
      match err:
        case M.SqliteErr{code, _}:
          {==}
        case M.RpcErr{_, _}:
          {==}
        case M.DriftWrap{inner, _}:
          unwrap_sqlite_secret_invariant(p, inner, s1, s2)
        case M.RollbackWrap{inner, _}:
          unwrap_sqlite_secret_invariant(p, inner, s1, s2)
        case M.OtherErr{_}:
          {==}

law is_direct_sqlite_secret_invariant:
  for +err: M.SwapError
  for +s1: Nat
  for +s2: Nat
  {M.is_direct_sqlite(M.replace_secrets(err, s1)) == M.is_direct_sqlite(M.replace_secrets(err, s2)) : Bool}

def is_direct_sqlite_secret_invariant(err, s1, s2):
  match err:
    case M.SqliteErr{_, _}:
      {==}
    case M.RpcErr{_, _}:
      {==}
    case M.DriftWrap{_, _}:
      {==}
    case M.RollbackWrap{_, _}:
      {==}
    case M.OtherErr{_}:
      {==}

law sanitize_finish_secret_invariant:
  for +u: Maybe<&2, Nat>
  for +d: Bool
  for +err: M.SwapError
  for +s1: Nat
  for +s2: Nat
  {M.sanitize.finish(u, d, M.replace_secrets(err, s1)) == M.sanitize.finish(u, d, M.replace_secrets(err, s2)) : M.SanitizedSummary}

def sanitize_finish_secret_invariant(u, d, err, s1, s2):
  match u:
    case Some{code}:
      {==}
    case None{}:
      match err:
        case M.SqliteErr{_, _}:
          {==}
        case M.RpcErr{_, _}:
          {==}
        case M.DriftWrap{_, _}:
          {==}
        case M.RollbackWrap{_, _}:
          {==}
        case M.OtherErr{_}:
          {==}

law step8_ok_implies_no_conflict:
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step8(conflict)) == True{} : Bool}
  {conflict == False{} : Bool}

def step8_ok_implies_no_conflict(conflict, ok):
  match conflict:
    case False{}:
      {==}
    case True{}:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(ok))

law step7_ok_implies:
  for +c_ok: Bool
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step7(c_ok, conflict)) == True{} : Bool}
  {Bool.and(c_ok, Bool.not(conflict)) == True{} : Bool}

def step7_ok_implies(c_ok, conflict, ok):
  match c_ok:
    case False{}:
      Empty.absurd({Bool.and(False{}, Bool.not(conflict)) == True{} : Bool}, NatL.false_is_not_true(ok))
    case True{}:
      %Equal.sym(Bool, conflict, False{}, step8_ok_implies_no_conflict(conflict, ok)) : {Bool.not(_) == True{} : Bool}
      {==}

law step6_ok_implies:
  for +confirmed: Bool
  for +exp: Nat
  for +created: Nat
  for +max_init: Nat
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step6(confirmed, exp, created, max_init, conflict)) == True{} : Bool}
  {Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict))) == True{} : Bool}

def step6_ok_implies(confirmed, exp, created, max_init, conflict, ok):
  match confirmed:
    case False{}:
      Empty.absurd({Bool.and(False{}, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict))) == True{} : Bool}, NatL.false_is_not_true(ok))
    case True{}:
      step7_ok_implies(Nat.is_le(Nat.sub(exp, created), max_init), conflict, ok)

law step5_ok_implies:
  for +rem_ok: Bool
  for +confirmed: Bool
  for +exp: Nat
  for +created: Nat
  for +max_init: Nat
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step5(rem_ok, confirmed, exp, created, max_init, conflict)) == True{} : Bool}
  {Bool.and(rem_ok, Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict)))) == True{} : Bool}

def step5_ok_implies(rem_ok, confirmed, exp, created, max_init, conflict, ok):
  match rem_ok:
    case False{}:
      Empty.absurd({Bool.and(False{}, Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict)))) == True{} : Bool}, NatL.false_is_not_true(ok))
    case True{}:
      step6_ok_implies(confirmed, exp, created, max_init, conflict, ok)

law step4_ok_implies:
  for +safe_win: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +max_init: Nat
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step4(safe_win, exp, now, created, confirmed, max_init, conflict)) == True{} : Bool}
  {Bool.and(safe_win, Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict))))) == True{} : Bool}

def step4_ok_implies(safe_win, exp, now, created, confirmed, max_init, conflict, ok):
  match safe_win:
    case False{}:
      Empty.absurd({Bool.and(False{}, Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict))))) == True{} : Bool}, NatL.false_is_not_true(ok))
    case True{}:
      step5_ok_implies(Nat.is_le(Nat.sub(exp, now), max_init), confirmed, exp, created, max_init, conflict, ok)

law step3_ok_implies:
  for +not_exp: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +msf: Nat
  for +cd: Nat
  for +max_init: Nat
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step3(not_exp, exp, now, created, confirmed, msf, cd, max_init, conflict)) == True{} : Bool}
  {Bool.and(not_exp, Bool.and(M.can_safely_join_window_with(exp, now, msf, cd), Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict)))))) == True{} : Bool}

def step3_ok_implies(not_exp, exp, now, created, confirmed, msf, cd, max_init, conflict, ok):
  match not_exp:
    case False{}:
      Empty.absurd({Bool.and(False{}, Bool.and(M.can_safely_join_window_with(exp, now, msf, cd), Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict)))))) == True{} : Bool}, NatL.false_is_not_true(ok))
    case True{}:
      step4_ok_implies(M.can_safely_join_window_with(exp, now, msf, cd), exp, now, created, confirmed, max_init, conflict, ok)

law step2_ok_implies:
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +msf: Nat
  for +cd: Nat
  for +max_init: Nat
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step2(used, exp, now, created, confirmed, msf, cd, max_init, conflict)) == True{} : Bool}
  {Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window_with(exp, now, msf, cd), Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict))))))) == True{} : Bool}

def step2_ok_implies(used, exp, now, created, confirmed, msf, cd, max_init, conflict, ok):
  match used:
    case True{}:
      Empty.absurd({Bool.and(False{}, Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window_with(exp, now, msf, cd), Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict))))))) == True{} : Bool}, NatL.false_is_not_true(ok))
    case False{}:
      step3_ok_implies(Nat.is_gt(Nat.sub(exp, now), 0n), exp, now, created, confirmed, msf, cd, max_init, conflict, ok)

law step1_ok_implies:
  for +tl_mine: Bool
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +msf: Nat
  for +cd: Nat
  for +max_init: Nat
  for +conflict: Bool
  for ok: {M.join_validation_is_ok(M.validate_join.step1(tl_mine, used, exp, now, created, confirmed, msf, cd, max_init, conflict)) == True{} : Bool}
  {Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window_with(exp, now, msf, cd), Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict)))))))) == True{} : Bool}

def step1_ok_implies(tl_mine, used, exp, now, created, confirmed, msf, cd, max_init, conflict, ok):
  match tl_mine:
    case True{}:
      Empty.absurd({Bool.and(False{}, Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window_with(exp, now, msf, cd), Bool.and(Nat.is_le(Nat.sub(exp, now), max_init), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), max_init), Bool.not(conflict)))))))) == True{} : Bool}, NatL.false_is_not_true(ok))
    case False{}:
      step2_ok_implies(used, exp, now, created, confirmed, msf, cd, max_init, conflict, ok)

law safe_join_full_elim:
  for +hl_mine: Bool
  for +tl_mine: Bool
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +conflict: Bool
  for ok: {M.is_safe_join(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict) == True{} : Bool}
  {Bool.and(hl_mine, Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))))))) == True{} : Bool}

def safe_join_full_elim(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok):
  match hl_mine:
    case False{}:
      Empty.absurd({Bool.and(False{}, Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))))))) == True{} : Bool}, NatL.false_is_not_true(ok))
    case True{}:
      step1_ok_implies(tl_mine, used, exp, now, created, confirmed, M.MIN_SAFE_FIND_PREIMAGE(), M.COUNTER_HTLC_DURATION(), M.MAX_INITIAL_HTLC_DURATION(), conflict, ok)

law bool_and_intro:
  for +a: Bool
  for +b: Bool
  for ea: {a == True{} : Bool}
  for eb: {b == True{} : Bool}
  {Bool.and(a, b) == True{} : Bool}

def bool_and_intro(a, b, ea, eb):
  %Equal.sym(Bool, a, True{}, ea) : {Bool.and(_, b) == True{} : Bool}
  eb

# ------------------------------------------------------------------------------
# Proofs of Laws 1-34
# ------------------------------------------------------------------------------

def Laws.safe_join_requires_participants(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok):
  +all = safe_join_full_elim(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok)
  e_hl = NatL.and_true_left(hl_mine, Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))))), all)
  r1 = NatL.and_true_right_elim(hl_mine, Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))))), all)
  e_tl = NatL.and_true_left(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))))), r1)
  bool_and_intro(hl_mine, Bool.not(tl_mine), e_hl, e_tl)

def Laws.safe_join_requires_unused_and_unique(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok):
  +all = safe_join_full_elim(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok)
  +r1 = NatL.and_true_right_elim(hl_mine, Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))))), all)
  +r2 = NatL.and_true_right_elim(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))))), r1)
  e_used = NatL.and_true_left(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))), r2)
  +r3 = NatL.and_true_right_elim(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))), r2)
  +r4 = NatL.and_true_right_elim(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))), r3)
  +r5 = NatL.and_true_right_elim(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))), r4)
  +r6 = NatL.and_true_right_elim(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))), r5)
  +r7 = NatL.and_true_right_elim(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)), r6)
  e_conf = NatL.and_true_right_elim(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict), r7)
  bool_and_intro(Bool.not(used), Bool.not(conflict), e_used, e_conf)

def Laws.safe_join_requires_duration_caps(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok):
  +all = safe_join_full_elim(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok)
  +r1 = NatL.and_true_right_elim(hl_mine, Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))))), all)
  +r2 = NatL.and_true_right_elim(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))))), r1)
  +r3 = NatL.and_true_right_elim(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))), r2)
  e_gt0 = NatL.and_true_left(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))), r3)
  +r4 = NatL.and_true_right_elim(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))), r3)
  +r5 = NatL.and_true_right_elim(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))), r4)
  e_rem = NatL.and_true_left(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))), r5)
  +r6 = NatL.and_true_right_elim(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))), r5)
  e_conf = NatL.and_true_left(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)), r6)
  +r7 = NatL.and_true_right_elim(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)), r6)
  e_cre = NatL.and_true_left(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict), r7)
  bool_and_intro(
    Nat.is_gt(M.remaining_time(exp, now), 0n),
    Bool.and(Nat.is_le(M.remaining_time(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()))),
    e_gt0,
    bool_and_intro(
      Nat.is_le(M.remaining_time(exp, now), M.MAX_INITIAL_HTLC_DURATION()),
      Bool.and(confirmed, Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION())),
      e_rem,
      bool_and_intro(confirmed, Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), e_conf, e_cre)
    )
  )

def Laws.safe_join_window_margin_parametric(exp, now, min_safe_find, counter_dur, safe):
  e_le = ge_to_le(Nat.sub(exp, now), Nat.add(min_safe_find, counter_dur), safe)
  e_sub = add_le_to_le_sub(min_safe_find, counter_dur, Nat.sub(exp, now), e_le)
  e_ge = le_to_ge(min_safe_find, Nat.sub(Nat.sub(exp, now), counter_dur), e_sub)
  %sub_sub(exp, now, counter_dur) : {Nat.is_ge(_, min_safe_find) == True{} : Bool}
  e_ge

def Laws.safe_join_guarantees_preimage_margin(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok):
  +all = safe_join_full_elim(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, ok)
  r1 = NatL.and_true_right_elim(hl_mine, Bool.and(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))))), all)
  r2 = NatL.and_true_right_elim(Bool.not(tl_mine), Bool.and(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))))), r1)
  r3 = NatL.and_true_right_elim(Bool.not(used), Bool.and(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))))), r2)
  r4 = NatL.and_true_right_elim(Nat.is_gt(Nat.sub(exp, now), 0n), Bool.and(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict))))), r3)
  e_win = NatL.and_true_left(M.can_safely_join_window(exp, now), Bool.and(Nat.is_le(Nat.sub(exp, now), M.MAX_INITIAL_HTLC_DURATION()), Bool.and(confirmed, Bool.and(Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()), Bool.not(conflict)))), r4)
  Laws.safe_join_window_margin_parametric(exp, now, M.MIN_SAFE_FIND_PREIMAGE(), M.COUNTER_HTLC_DURATION(), e_win)

law unlock_reclaim_disjoint.go:
  for +u: Bool
  for +exp: Nat
  for +now: Nat
  for eq_u: {M.can_unlock(exp, now) == u : Bool}
  {Bool.and(u, M.can_reclaim(exp, now)) == False{} : Bool}

def unlock_reclaim_disjoint.go(u, exp, now, eq_u):
  match u:
    case False{}:
      {==}
    case True{}:
      gt_add_implies_not_le(exp, now, M.MIN_SAFE_COMPLETE_SWAP(), eq_u)

def Laws.unlock_reclaim_mutually_exclusive(exp, now):
  unlock_reclaim_disjoint.go(M.can_unlock(exp, now), exp, now, {==})

def Laws.unlock_has_strict_reclaim_buffer(exp, now, u):
  gt_implies_le_false(exp, Nat.add(now, M.MIN_SAFE_COMPLETE_SWAP()), u)

def Laws.start_and_join_initial_states():
  {==}

def Laws.create_flips_pending_to_active(dir, hc, hp, ic, cv):
  {==}

def Laws.unlock_incoming_completes_and_records_preimage(st, hc, hp, not_comp):
  match st hp:
    case M.Completed{} _:
      Empty.absurd({Bool.and(True{}, hp) == True{} : Bool}, NatL.true_is_not_false(not_comp))
    case M.Pending{} False{}:
      {==}
    case M.Pending{} True{}:
      {==}
    case M.Active{} False{}:
      {==}
    case M.Active{} True{}:
      {==}
    case M.Reclaimable{} False{}:
      {==}
    case M.Reclaimable{} True{}:
      {==}
    case M.Unsuccessful{} False{}:
      {==}
    case M.Unsuccessful{} True{}:
      {==}
    case M.Error{} False{}:
      {==}
    case M.Error{} True{}:
      {==}

def Laws.unlock_outgoing_active_completes(hc, hp):
  match hp:
    case False{}:
      {==}
    case True{}:
      {==}

def Laws.reclaim_non_completed_funded_unsuccessful(dir, st, hc, hp, not_comp):
  match dir st:
    case _ M.Completed{}:
      Empty.absurd({M.Completed{} == M.Unsuccessful{} : M.SwapState}, NatL.true_is_not_false(not_comp))
    case M.Outgoing{} M.Pending{}:
      {==}
    case M.Incoming{} M.Pending{}:
      {==}
    case M.Outgoing{} M.Active{}:
      {==}
    case M.Incoming{} M.Active{}:
      {==}
    case M.Outgoing{} M.Reclaimable{}:
      {==}
    case M.Incoming{} M.Reclaimable{}:
      {==}
    case M.Outgoing{} M.Unsuccessful{}:
      {==}
    case M.Incoming{} M.Unsuccessful{}:
      {==}
    case M.Outgoing{} M.Error{}:
      {==}
    case M.Incoming{} M.Error{}:
      {==}

def Laws.expire_moves_pending_and_active_only(dir, hc, hp):
  {==}

def Laws.completed_is_terminal_absorbing(dir, hc, hp, ev):
  {==}

def Laws.safe_deletion_partition():
  {==}

def Laws.funded_htlc_direction_bijection(dir, role):
  match dir role:
    case M.Outgoing{} M.InitialHtlc{}:
      {==}
    case M.Outgoing{} M.CounterHtlc{}:
      {==}
    case M.Incoming{} M.InitialHtlc{}:
      {==}
    case M.Incoming{} M.CounterHtlc{}:
      {==}

def Laws.reclaim_hw_rejects_missing_never_derives(has_wallet, wlen, lookahead, match_idx, exp, now):
  match has_wallet:
    case False{}:
      {==}
    case True{}:
      {==}

law reclaim_unexpired_window.go:
  for +in_win: Bool
  for +idx: Nat
  for +wlen: Nat
  for +exp: Nat
  for +now: Nat
  for unexp: {M.can_reclaim(exp, now) == False{} : Bool}
  {Bool.and(
    Bool.not(M.reclaim_is_ok(M.reclaim.check_window(in_win, idx, wlen, exp, now))),
    Nat.is_eq(M.reclaim_derived_count(M.reclaim.check_window(in_win, idx, wlen, exp, now)), 0n)
  ) == True{} : Bool}

def reclaim_unexpired_window.go(in_win, idx, wlen, exp, now, unexp):
  match in_win:
    case False{}:
      {==}
    case True{}:
      %Equal.sym(Bool, M.can_reclaim(exp, now), False{}, unexp) : {Bool.and(Bool.not(M.reclaim_is_ok(M.reclaim.check_exp(_, 1n+Nat.sub(idx, wlen)))), Nat.is_eq(M.reclaim_derived_count(M.reclaim.check_exp(_, 1n+Nat.sub(idx, wlen))), 0n)) == True{} : Bool}
      {==}

def Laws.reclaim_unexpired_never_derives(in_wallet, has_wallet, is_hw, wlen, lookahead, match_idx, exp, now, unexp):
  match in_wallet:
    case True{}:
      %Equal.sym(Bool, M.can_reclaim(exp, now), False{}, unexp) : {Bool.and(Bool.not(M.reclaim_is_ok(M.reclaim.check_exp(_, 0n))), Nat.is_eq(M.reclaim_derived_count(M.reclaim.check_exp(_, 0n)), 0n)) == True{} : Bool}
      {==}
    case False{}:
      match has_wallet is_hw:
        case False{} _:
          {==}
        case True{} True{}:
          {==}
        case True{} False{}:
          match match_idx:
            case None{}:
              {==}
            case Some{idx}:
              reclaim_unexpired_window.go(
                Bool.and(Nat.is_le(wlen, idx), Nat.is_lt(idx, Nat.add(wlen, lookahead))),
                idx, wlen, exp, now, unexp
              )

def Laws.reclaim_sw_lookahead_exact_and_bounded(wlen, lookahead, idx, exp, now, ge_len, lt_end, expired):
  +in_win = bool_and_intro(Nat.is_le(wlen, idx), Nat.is_lt(idx, Nat.add(wlen, lookahead)), ge_len, lt_end)
  %Equal.sym(Bool, Bool.and(Nat.is_le(wlen, idx), Nat.is_lt(idx, Nat.add(wlen, lookahead))), True{}, in_win) : {Bool.and(Nat.is_eq(M.reclaim_derived_count(M.reclaim.check_window(_, idx, wlen, exp, now)), 1n+Nat.sub(idx, wlen)), Bool.and(Nat.is_le(M.reclaim_derived_count(M.reclaim.check_window(_, idx, wlen, exp, now)), lookahead), Nat.is_eq(Nat.add(wlen, M.reclaim_derived_count(M.reclaim.check_window(_, idx, wlen, exp, now))), 1n+idx))) == True{} : Bool}
  %Equal.sym(Bool, M.can_reclaim(exp, now), True{}, expired) : {Bool.and(Nat.is_eq(M.reclaim_derived_count(M.reclaim.check_exp(_, 1n+Nat.sub(idx, wlen))), 1n+Nat.sub(idx, wlen)), Bool.and(Nat.is_le(M.reclaim_derived_count(M.reclaim.check_exp(_, 1n+Nat.sub(idx, wlen))), lookahead), Nat.is_eq(Nat.add(wlen, M.reclaim_derived_count(M.reclaim.check_exp(_, 1n+Nat.sub(idx, wlen)))), 1n+idx))) == True{} : Bool}
  e1 = NatL.is_eq_same(1n+Nat.sub(idx, wlen))
  e2 = succ_sub_le_of_lt_add(wlen, idx, lookahead, ge_len, lt_end)
  e3 = add_succ_sub_eq_true(wlen, idx, ge_len)
  bool_and_intro(
    Nat.is_eq(1n+Nat.sub(idx, wlen), 1n+Nat.sub(idx, wlen)),
    Bool.and(Nat.is_le(1n+Nat.sub(idx, wlen), lookahead), Nat.is_eq(Nat.add(wlen, 1n+Nat.sub(idx, wlen)), 1n+idx)),
    e1,
    bool_and_intro(Nat.is_le(1n+Nat.sub(idx, wlen), lookahead), Nat.is_eq(Nat.add(wlen, 1n+Nat.sub(idx, wlen)), 1n+idx), e2, e3)
  )

def Laws.reclaim_sw_out_of_window_rejected(wlen, lookahead, idx, exp, now, oob):
  e_lt_false = ge_implies_lt_false(idx, Nat.add(wlen, lookahead), oob)
  %Equal.sym(Bool, Nat.is_lt(idx, Nat.add(wlen, lookahead)), False{}, e_lt_false) : {M.reclaim_is_ok(M.reclaim.check_window(Bool.and(Nat.is_le(wlen, idx), _), idx, wlen, exp, now)) == False{} : Bool}
  %Equal.sym(Bool, Bool.and(Nat.is_le(wlen, idx), False{}), False{}, NatL.and_false_right(Nat.is_le(wlen, idx))) : {M.reclaim_is_ok(M.reclaim.check_window(_, idx, wlen, exp, now)) == False{} : Bool}
  {==}

def Laws.auto_unlock_mutex_blocks_reentry(last, wallet_open, node_synced, now):
  {==}

def Laws.auto_unlock_cooldown_blocks_retry(t, delta, wallet_open, node_synced, within_cd):
  match wallet_open:
    case False{}:
      {==}
    case True{}:
      %Equal.sym(Nat, Nat.sub(Nat.add(t, delta), t), delta, NatL.sub_cancel_add_left(t, delta)) : {M.unlock_step_started(M.auto_unlock.after_prune(Nat.is_lt(_, M.AUTO_UNLOCK_COOLDOWN()), Some{t}, node_synced, Nat.add(t, delta))) == False{} : Bool}
      %Equal.sym(Bool, Nat.is_lt(delta, M.AUTO_UNLOCK_COOLDOWN()), True{}, within_cd) : {M.unlock_step_started(M.auto_unlock.after_prune(_, Some{t}, node_synced, Nat.add(t, delta))) == False{} : Bool}
      {==}

def Laws.auto_unlock_cooldown_expires_allows_retry(t, extra):
  e_cd = sub_add_add_not_lt(t, M.AUTO_UNLOCK_COOLDOWN(), extra)
  %Equal.sym(Bool, Nat.is_lt(Nat.sub(Nat.add(Nat.add(t, M.AUTO_UNLOCK_COOLDOWN()), extra), t), M.AUTO_UNLOCK_COOLDOWN()), False{}, e_cd) : {Bool.and(M.unlock_step_started(M.auto_unlock.after_prune(_, Some{t}, True{}, Nat.add(Nat.add(t, M.AUTO_UNLOCK_COOLDOWN()), extra))), M.auto_unlock_is_busy(M.unlock_step_state(M.auto_unlock.after_prune(_, Some{t}, True{}, Nat.add(Nat.add(t, M.AUTO_UNLOCK_COOLDOWN()), extra))))) == True{} : Bool}
  {==}

def Laws.sqlcipher_key_requires_32_bytes(len, bytes_ok, valid):
  e_eq = NatL.and_true_left(Nat.is_eq(len, M.SQLCIPHER_KEY_LEN()), bytes_ok, valid)
  NatL.is_eq_sound(len, M.SQLCIPHER_KEY_LEN(), e_eq)

def Laws.sqlcipher_key_rejects_invalid_bytes_and_accepts_32(len):
  %Equal.sym(Bool, Bool.and(Nat.is_eq(len, M.SQLCIPHER_KEY_LEN()), False{}), False{}, NatL.and_false_right(Nat.is_eq(len, M.SQLCIPHER_KEY_LEN()))) : {Bool.and(Bool.not(_), True{}) == True{} : Bool}
  {==}

def Laws.processed_block_requires_matching_chain(active_chain, swap_chain, ok):
  NatL.is_eq_sound(swap_chain, active_chain, ok)

def Laws.pruning_never_evicts_unresolved_swaps(total, max_swaps, sc, pc):
  match pc:
    case None{}:
      {==}
    case Some{p}:
      %Equal.sym(Bool, Bool.and(Nat.is_eq(sc, p), False{}), False{}, NatL.and_false_right(Nat.is_eq(sc, p))) : {Bool.and(Bool.not(Bool.and(Nat.is_gt(total, max_swaps), _)), Bool.and(Bool.not(Bool.and(Nat.is_gt(total, max_swaps), _)), Bool.not(Bool.and(Nat.is_gt(total, max_swaps), _)))) == True{} : Bool}
      %Equal.sym(Bool, Bool.and(Nat.is_gt(total, max_swaps), False{}), False{}, NatL.and_false_right(Nat.is_gt(total, max_swaps))) : {Bool.and(Bool.not(_), Bool.and(Bool.not(_), Bool.not(_))) == True{} : Bool}
      {==}

def Laws.begin_rekey_retains_old_backup(st, old_k, new_k):
  match st:
    case M.Storage{_, _, _, _, _}:
      %Equal.sym(Bool, Nat.is_eq(new_k, new_k), True{}, NatL.is_eq_same(new_k)) : {Bool.and(_, Bool.and(_, Nat.is_eq(old_k, old_k))) == True{} : Bool}
      NatL.is_eq_same(old_k)

def Laws.change_password_atomicity_commit_and_rollback(st, old_k, new_k):
  match st:
    case M.Storage{_, _, _, _, _}:
      %Equal.sym(Bool, Nat.is_eq(old_k, old_k), True{}, NatL.is_eq_same(old_k)) : {Bool.and(Bool.and(_, Bool.and(_, True{})), Bool.and(Nat.is_eq(new_k, new_k), Bool.and(Nat.is_eq(new_k, new_k), True{}))) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_eq(new_k, new_k), True{}, NatL.is_eq_same(new_k)) : {Bool.and(_, Bool.and(_, True{})) == True{} : Bool}
      {==}

def Laws.change_password_always_restarts_sync(st, old_k, new_k, rekey_ok, wallet_pwd_ok):
  match st:
    case M.Storage{_, _, _, _, _}:
      match rekey_ok wallet_pwd_ok:
        case False{} False{}:
          {==}
        case False{} True{}:
          {==}
        case True{} False{}:
          {==}
        case True{} True{}:
          {==}

def Laws.open_crash_recovery_and_stale_backup_cleanup(key, wrong_key, stale_bak, sync_r, neq):
  %Equal.sym(Bool, Nat.is_eq(wrong_key, key), False{}, neq) : {Bool.and(Bool.and(M.storage_is_open(M.open.check_primary(_, M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)), Bool.and(Nat.is_eq(M.storage_open_key(M.open.check_primary(_, M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)), key), Bool.and(M.file_has_key(M.storage_primary(M.open.check_primary(_, M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)), key), M.file_is_none(M.storage_backup(M.open.check_primary(_, M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)))))), Bool.and(M.storage_is_open(M.open.check_primary(Nat.is_eq(key, key), M.EncFile{key}, stale_bak, key, sync_r)), Bool.and(Nat.is_eq(M.storage_open_key(M.open.check_primary(Nat.is_eq(key, key), M.EncFile{key}, stale_bak, key, sync_r)), key), M.file_is_none(M.storage_backup(M.open.check_primary(Nat.is_eq(key, key), M.EncFile{key}, stale_bak, key, sync_r)))))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(key, key), True{}, NatL.is_eq_same(key)) : {Bool.and(Bool.and(M.storage_is_open(M.open.try_backup_match(_, M.EncFile{wrong_key}, key, key, sync_r)), Bool.and(Nat.is_eq(M.storage_open_key(M.open.try_backup_match(_, M.EncFile{wrong_key}, key, key, sync_r)), key), Bool.and(M.file_has_key(M.storage_primary(M.open.try_backup_match(_, M.EncFile{wrong_key}, key, key, sync_r)), key), M.file_is_none(M.storage_backup(M.open.try_backup_match(_, M.EncFile{wrong_key}, key, key, sync_r)))))), Bool.and(M.storage_is_open(M.open.check_primary(_, M.EncFile{key}, stale_bak, key, sync_r)), Bool.and(Nat.is_eq(M.storage_open_key(M.open.check_primary(_, M.EncFile{key}, stale_bak, key, sync_r)), key), M.file_is_none(M.storage_backup(M.open.check_primary(_, M.EncFile{key}, stale_bak, key, sync_r)))))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(key, key), True{}, NatL.is_eq_same(key)) : {Bool.and(Bool.and(_, Bool.and(_, True{})), Bool.and(_, True{})) == True{} : Bool}
  {==}

def Laws.legacy_migration_safety(failed, existing_val, legacy_val):
  NatL.is_eq_same(existing_val)

def Laws.sanitizer_zero_preimage_leakage(err, s1, s2):
  %unwrap_sqlite_secret_invariant(M.SANITIZER_MAX_DEPTH(), err, s1, s2) : {M.sanitize.finish(M.unwrap_sqlite(M.SANITIZER_MAX_DEPTH(), M.replace_secrets(err, s1)), M.is_direct_sqlite(M.replace_secrets(err, s1)), M.replace_secrets(err, s1)) == M.sanitize.finish(_, M.is_direct_sqlite(M.replace_secrets(err, s2)), M.replace_secrets(err, s2)) : M.SanitizedSummary}
  %is_direct_sqlite_secret_invariant(err, s1, s2) : {M.sanitize.finish(M.unwrap_sqlite(M.SANITIZER_MAX_DEPTH(), M.replace_secrets(err, s1)), M.is_direct_sqlite(M.replace_secrets(err, s1)), M.replace_secrets(err, s1)) == M.sanitize.finish(M.unwrap_sqlite(M.SANITIZER_MAX_DEPTH(), M.replace_secrets(err, s1)), _, M.replace_secrets(err, s2)) : M.SanitizedSummary}
  sanitize_finish_secret_invariant(
    M.unwrap_sqlite(M.SANITIZER_MAX_DEPTH(), M.replace_secrets(err, s1)),
    M.is_direct_sqlite(M.replace_secrets(err, s1)),
    err, s1, s2
  )

def Laws.sanitizer_five_layer_cap(code, s):
  {==}

def Laws.parallel_swap_safety_check_equiv(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict, key_len, bytes_ok, active_chain, updated_chain):
  {==}
