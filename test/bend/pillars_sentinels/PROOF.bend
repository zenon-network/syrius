import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# Local helper lemmas
# -------------------

def and_split(+a: Bool, +b: Bool, e: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool} & {b == True{} : Bool}:
  match a:
    case False{}:
      Empty.absurd({False{} == True{} : Bool} & {b == True{} : Bool}, NatL.false_is_not_true(e))
    case True{}:
      ({==}, e)

def not_ge_from_lt(+a: Nat, +b: Nat, lt: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_ge(a, b) == False{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_ge(0n, 0n) == False{} : Bool}, NatL.false_is_not_true(lt))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_ge(1n+ap, 0n) == False{} : Bool}, NatL.false_is_not_true(lt))
    case 1n+ap 1n+bp:
      not_ge_from_lt(ap, bp, lt)

def pick_create_rank_ge(+ok: Bool, +s: M.CreateStep, +n: M.CreateStep, h: {Nat.is_le(M.create_step_rank(s), M.create_step_rank(n)) == True{} : Bool}) -> {Nat.is_le(M.create_step_rank(s), M.create_step_rank(M.pick_create_step(ok, n, s))) == True{} : Bool}:
  match ok:
    case True{}:
      h
    case False{}:
      NatL.is_le_refl(M.create_step_rank(s))

def sub_zero_when_ge(+dep: Nat, +cost: Nat, ge: {Nat.is_ge(dep, cost) == True{} : Bool}) -> {Nat.sub(cost, dep) == 0n : Nat}:
  match dep cost:
    case 0n 0n:
      {==}
    case 0n 1n+cp:
      Empty.absurd({Nat.sub(1n+cp, 0n) == 0n : Nat}, NatL.false_is_not_true(ge))
    case 1n+dp 0n:
      {==}
    case 1n+dp 1n+cp:
      sub_zero_when_ge(dp, cp, ge)

def add_min_sub_le_max(+dep: Nat, +cost: Nat, +bal: Nat) -> {Nat.is_le(Nat.add(dep, Nat.min(bal, Nat.sub(cost, dep))), Nat.max(cost, dep)) == True{} : Bool}:
  match dep cost:
    case 0n 0n:
      NatL.min_le_right(bal, 0n)
    case 0n 1n+cp:
      NatL.min_le_right(bal, 1n+cp)
    case 1n+dp 0n:
      z = NatL.is_le_zero_eq(Nat.min(bal, 0n), NatL.min_le_right(bal, 0n))
      %Equal.sym(Nat, Nat.min(bal, 0n), 0n, z) : {Nat.is_le(Nat.add(1n+dp, _), 1n+dp) == True{} : Bool}
      %Equal.sym(Nat, Nat.add(1n+dp, 0n), 1n+dp, NatL.add_zero(1n+dp)) : {Nat.is_le(_, 1n+dp) == True{} : Bool}
      NatL.is_le_refl(1n+dp)
    case 1n+dp 1n+cp:
      add_min_sub_le_max(dp, cp, bal)

def min_add_sub_eq(+cost: Nat, +dep: Nat) -> {Nat.add(Nat.min(dep, cost), Nat.sub(cost, dep)) == cost : Nat}:
  match cost dep:
    case 0n 0n:
      {==}
    case 0n 1n+dp:
      {==}
    case 1n+cp 0n:
      {==}
    case 1n+cp 1n+dp:
      %min_add_sub_eq(cp, dp) : {1n+Nat.add(Nat.min(dp, cp), Nat.sub(cp, dp)) == 1n+_ : Nat}
      {==}

def add_pos_lt(+init: Nat, +amt: Nat, pos: {Nat.is_gt(amt, 0n) == True{} : Bool}) -> {Nat.is_lt(init, Nat.add(init, amt)) == True{} : Bool}:
  match init amt:
    case 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(pos))
    case 0n 1n+ap:
      {==}
    case 1n+ip 0n:
      Empty.absurd({Nat.is_lt(1n+ip, Nat.add(1n+ip, 0n)) == True{} : Bool}, NatL.false_is_not_true(pos))
    case 1n+ip 1n+ap:
      add_pos_lt(ip, 1n+ap, pos)

def lt_le_trans(+a: Nat, +b: Nat, +c: Nat, ab: {Nat.is_lt(a, b) == True{} : Bool}, bc: {Nat.is_le(b, c) == True{} : Bool}) -> {Nat.is_lt(a, c) == True{} : Bool}:
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
      lt_le_trans(ap, bp, cp, ab, bc)

def and_false_in_fourth(+a: Bool, +b: Bool, +c: Bool, +d: Bool) -> {Bool.and(a, Bool.and(b, Bool.and(c, Bool.and(False{}, d)))) == False{} : Bool}:
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

def Laws.role_protocol_constants():
  {==}

def Laws.create_step_monotone(step, plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid):
  match step:
    case M.StepPlasma{}:
      pick_create_rank_ge(Nat.is_ge(plasma, plasma_req), M.StepPlasma{}, M.StepQsr{}, {==})
    case M.StepQsr{}:
      pick_create_rank_ge(Nat.is_ge(deposit, qsr_cost), M.StepQsr{}, M.StepZnn{}, {==})
    case M.StepZnn{}:
      pick_create_rank_ge(Nat.is_ge(znn_bal, znn_req), M.StepZnn{}, M.StepDeploy{}, {==})
    case M.StepDeploy{}:
      pick_create_rank_ge(deploy_valid, M.StepDeploy{}, M.StepDone{}, {==})
    case M.StepDone{}:
      {==}

def Laws.create_step_plasma_gate(plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid, lt):
  ng = not_ge_from_lt(plasma, plasma_req, lt)
  %Equal.sym(Bool, Nat.is_ge(plasma, plasma_req), False{}, ng) : {M.pick_create_step(_, M.StepQsr{}, M.StepPlasma{}) == M.StepPlasma{} : M.CreateStep}
  {==}

def Laws.create_step_qsr_gate(plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid, lt):
  ng = not_ge_from_lt(deposit, qsr_cost, lt)
  %Equal.sym(Bool, Nat.is_ge(deposit, qsr_cost), False{}, ng) : {M.pick_create_step(_, M.StepZnn{}, M.StepQsr{}) == M.StepQsr{} : M.CreateStep}
  {==}

def Laws.create_step_znn_gate(plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid, lt):
  ng = not_ge_from_lt(znn_bal, znn_req, lt)
  %Equal.sym(Bool, Nat.is_ge(znn_bal, znn_req), False{}, ng) : {M.pick_create_step(_, M.StepDeploy{}, M.StepZnn{}) == M.StepZnn{} : M.CreateStep}
  {==}

def Laws.create_step_deploy_gate_and_done_absorbing(plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid):
  {==}

def Laws.max_qsr_deposit_le_balance(bal, cost, dep):
  NatL.min_le_left(bal, Nat.sub(cost, dep))

def Laws.max_qsr_deposit_never_overdeposits(bal, cost, dep):
  add_min_sub_le_max(dep, cost, bal)

def Laws.qsr_covered_implies_zero_remaining(dep, cost, cov):
  sub_zero_when_ge(dep, cost, cov)

def Laws.qsr_pie_conservation(cost, dep):
  min_add_sub_eq(cost, dep)

def Laws.can_withdraw_iff_positive(d):
  {==}

def Laws.deposit_confirm_rejects_zero_amount(init, obs):
  {==}

def deposit_confirm_from_pair(
  +init: Nat,
  +amt: Nat,
  +obs: Nat,
  pair: {Nat.is_gt(amt, 0n) == True{} : Bool} & {Nat.is_ge(obs, Nat.add(init, amt)) == True{} : Bool}
) -> {Nat.is_lt(init, obs) == True{} : Bool}:
  (pos, ge_sum) = pair
  le_sum = Equal.trans(
    Bool,
    Nat.is_le(Nat.add(init, amt), obs),
    Nat.is_ge(obs, Nat.add(init, amt)),
    True{},
    Equal.sym(Bool, Nat.is_ge(obs, Nat.add(init, amt)), Nat.is_le(Nat.add(init, amt), obs), NatL.is_ge_as_le(obs, Nat.add(init, amt))),
    ge_sum)
  lt_le_trans(init, Nat.add(init, amt), obs, add_pos_lt(init, amt, pos), le_sum)

def Laws.deposit_confirm_strictly_increases(init, amt, obs, ok):
  deposit_confirm_from_pair(init, amt, obs, and_split(Nat.is_gt(amt, 0n), Nat.is_ge(obs, Nat.add(init, amt)), ok))

def Laws.withdraw_confirm_with_snapshot_decreases(init, obs, ok):
  NatL.and_true_right_elim(Nat.is_gt(init, 0n), Nat.is_lt(obs, init), ok)

def Laws.withdraw_confirm_without_snapshot_zero(init, obs, ok):
  NatL.is_eq_sound(obs, 0n, ok)

def Laws.producer_rejects_wallet_address(addr_valid):
  NatL.and_false_right(addr_valid)

def Laws.deploy_pillar_rejects_wallet_producer(nv, na, rv, pv, mp, dp):
  e = NatL.and_false_right(pv)
  %Equal.sym(Bool, Bool.and(pv, False{}), False{}, e) : {Bool.and(nv, Bool.and(na, Bool.and(rv, Bool.and(_, Bool.and(M.valid_reward_pct(mp), M.valid_reward_pct(dp)))))) == False{} : Bool}
  and_false_in_fourth(nv, na, rv, Bool.and(M.valid_reward_pct(mp), M.valid_reward_pct(dp)))

def Laws.reward_pct_conservation(pct, ok):
  NatL.sub_add(pct, 100n, ok)

def Laws.reward_pct_rejects_over_100(k):
  {==}

def pick_update_rank_ge(+ok: Bool, +s: M.UpdateStep, +n: M.UpdateStep, h: {Nat.is_le(M.update_step_rank(s), M.update_step_rank(n)) == True{} : Bool}) -> {Nat.is_le(M.update_step_rank(s), M.update_step_rank(M.pick_update_step(ok, n, s))) == True{} : Bool}:
  match ok:
    case True{}:
      h
    case False{}:
      NatL.is_le_refl(M.update_step_rank(s))

def update_step_monotone(+step: M.UpdateStep, +dv: Bool, +rv: Bool, +so: Bool) -> {Nat.is_le(M.update_step_rank(step), M.update_step_rank(M.advance_update_step(step, dv, rv, so))) == True{} : Bool}:
  match step:
    case M.UpdDetails{}:
      pick_update_rank_ge(dv, M.UpdDetails{}, M.UpdRewards{}, {==})
    case M.UpdRewards{}:
      pick_update_rank_ge(rv, M.UpdRewards{}, M.UpdSubmit{}, {==})
    case M.UpdSubmit{}:
      pick_update_rank_ge(so, M.UpdSubmit{}, M.UpdDone{}, {==})
    case M.UpdDone{}:
      {==}

def Laws.update_step_navigation(step, dv, rv, so):
  e = update_step_monotone(step, dv, rv, so)
  %Equal.sym(Bool, Nat.is_le(M.update_step_rank(step), M.update_step_rank(M.advance_update_step(step, dv, rv, so))), True{}, e) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

def Laws.safe_uptime_zero_expected(produced):
  {==}

# Euclidean division & multiplication lemmas for exact half-away-from-zero uptime bound
def lt_add_cancel_left(+k: Nat, +x: Nat, +y: Nat, e: {Nat.is_lt(Nat.add(k, x), Nat.add(k, y)) == True{} : Bool}) -> {Nat.is_lt(x, y) == True{} : Bool}:
  match k:
    case 0n:
      e
    case 1n+kp:
      lt_add_cancel_left(kp, x, y, e)

def mul_lt_cancel_right(+a: Nat, +c: Nat, +bp: Nat, e: {Nat.is_lt(Nat.mul(a, 1n+bp), Nat.mul(c, 1n+bp)) == True{} : Bool}) -> {Nat.is_lt(a, c) == True{} : Bool}:
  match a c:
    case 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 0n 1n+cp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 1n+cp:
      mul_lt_cancel_right(ap, cp, bp, lt_add_cancel_left(1n+bp, Nat.mul(ap, 1n+bp), Nat.mul(cp, 1n+bp), e))

def lt_zero_absurd(+a: Nat, lt: {Nat.is_lt(a, 0n) == True{} : Bool}) -> Empty:
  match a:
    case 0n:
      NatL.false_is_not_true(lt)
    case 1n+ap:
      NatL.false_is_not_true(lt)

def lt_succ_implies_le(+a: Nat, +b: Nat, lt: {Nat.is_lt(a, 1n+b) == True{} : Bool}) -> {Nat.is_le(a, b) == True{} : Bool}:
  match a b:
    case 0n _:
      NatL.is_le_zero(b)
    case 1n+ap 0n:
      Empty.absurd({Nat.is_le(1n+ap, 0n) == True{} : Bool}, lt_zero_absurd(ap, lt))
    case 1n+ap 1n+bp:
      lt_succ_implies_le(ap, bp, lt)

def le_lt_trans(+a: Nat, +b: Nat, +c: Nat, ab: {Nat.is_le(a, b) == True{} : Bool}, bc: {Nat.is_lt(b, c) == True{} : Bool}) -> {Nat.is_lt(a, c) == True{} : Bool}:
  match a b c:
    case 0n 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(bc))
    case 0n 1n+bp 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(bc))
    case 0n _ 1n+cp:
      {==}
    case 1n+ap 0n _:
      Empty.absurd({Nat.is_lt(1n+ap, c) == True{} : Bool}, NatL.false_is_not_true(ab))
    case 1n+ap 1n+bp 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 0n) == True{} : Bool}, NatL.false_is_not_true(bc))
    case 1n+ap 1n+bp 1n+cp:
      le_lt_trans(ap, bp, cp, ab, bc)

def divmod_step_zero_rhs(+np: Nat, +d: Nat, +r: Nat) -> {Nat.add(Nat.add(np, Nat.mul(1n+d, 1n+r)), 0n) == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}:
  %Equal.sym(Nat, Nat.add(Nat.add(np, Nat.mul(1n+d, 1n+r)), 0n), Nat.add(np, Nat.mul(1n+d, 1n+r)), NatL.add_zero(Nat.add(np, Nat.mul(1n+d, 1n+r)))) : {_ == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  %Equal.sym(Nat, Nat.add(np, 1n+Nat.add(r, Nat.mul(d, 1n+r))), 1n+Nat.add(np, Nat.add(r, Nat.mul(d, 1n+r))), NatL.add_succ(np, Nat.add(r, Nat.mul(d, 1n+r)))) : {_ == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  %Equal.sym(Nat, Nat.add(r, Nat.mul(d, 1n+r)), Nat.add(Nat.mul(d, 1n+r), r), NatL.add_comm(r, Nat.mul(d, 1n+r))) : {1n+Nat.add(np, _) == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  %NatL.add_assoc(np, Nat.mul(d, 1n+r), r) : {1n+_ == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  {==}

def divmod_go_eq(+n: Nat, +m: Nat, +d: Nat, +r: Nat) -> {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(n, m, d, r)), 1n+Nat.add(m, r)), Pair.snd(Nat, Nat, Nat.divmod.go(n, m, d, r))) == Nat.add(Nat.add(n, Nat.mul(d, 1n+Nat.add(m, r))), r) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+np:
      match m:
        case 0n:
          +q = Pair.fst(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n))
          +rem = Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n))
          %divmod_step_zero_rhs(np, d, r) : {Nat.add(Nat.mul(q, 1n+r), rem) == _ : Nat}
          %NatL.add_zero(r) : {Nat.add(Nat.mul(q, 1n+_), rem) == Nat.add(Nat.add(np, Nat.mul(1n+d, 1n+_)), 0n) : Nat}
          divmod_go_eq(np, r, 1n+d, 0n)
        case 1n+mp:
          +q = Pair.fst(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r))
          +rem = Pair.snd(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r))
          %NatL.add_succ(Nat.add(np, Nat.mul(d, 1n+1n+Nat.add(mp, r))), r) : {Nat.add(Nat.mul(q, 1n+1n+Nat.add(mp, r)), rem) == _ : Nat}
          %NatL.add_succ(mp, r) : {Nat.add(Nat.mul(q, 1n+_), rem) == Nat.add(Nat.add(np, Nat.mul(d, 1n+_)), 1n+r) : Nat}
          divmod_go_eq(np, mp, d, 1n+r)

def divmod_eq(+a: Nat, +bp: Nat) -> {Nat.add(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp)) == a : Nat}:
  %NatL.add_zero(a) : {Nat.add(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp)) == _ : Nat}
  %NatL.add_zero(a) : {Nat.add(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp)) == Nat.add(_, 0n) : Nat}
  %NatL.add_zero(bp) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(a, bp, 0n, 0n)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(a, bp, 0n, 0n))) == Nat.add(Nat.add(a, 0n), 0n) : Nat}
  divmod_go_eq(a, bp, 0n, 0n)

def div_mul_le(+a: Nat, +bp: Nat) -> {Nat.is_le(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), a) == True{} : Bool}:
  %divmod_eq(a, bp) : {Nat.is_le(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), _) == True{} : Bool}
  NatL.is_le_add_right(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp))

def mul_monotone_le_left(+a: Nat, +b: Nat, +c: Nat, le: {Nat.is_le(a, b) == True{} : Bool}) -> {Nat.is_le(Nat.mul(a, c), Nat.mul(b, c)) == True{} : Bool}:
  match a b:
    case 0n _:
      NatL.is_le_zero(Nat.mul(b, c))
    case 1n+ap 0n:
      Empty.absurd({Nat.is_le(Nat.mul(1n+ap, c), 0n) == True{} : Bool}, NatL.false_is_not_true(le))
    case 1n+ap 1n+bp:
      NatL.add_monotone_le(c, c, Nat.mul(ap, c), Nat.mul(bp, c), NatL.is_le_refl(c), mul_monotone_le_left(ap, bp, c, le))

def mul_add_right(+a: Nat, +b: Nat, +c: Nat) -> {Nat.mul(Nat.add(a, b), c) == Nat.add(Nat.mul(a, c), Nat.mul(b, c)) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+ap:
      ih = mul_add_right(ap, b, c)
      %Equal.sym(Nat, Nat.mul(Nat.add(ap, b), c), Nat.add(Nat.mul(ap, c), Nat.mul(b, c)), ih) : {Nat.add(c, _) == Nat.add(Nat.add(c, Nat.mul(ap, c)), Nat.mul(b, c)) : Nat}
      Equal.sym(
        Nat,
        Nat.add(Nat.add(c, Nat.mul(ap, c)), Nat.mul(b, c)),
        Nat.add(c, Nat.add(Nat.mul(ap, c), Nat.mul(b, c))),
        NatL.add_assoc(c, Nat.mul(ap, c), Nat.mul(b, c)))

def mul_assoc(+a: Nat, +b: Nat, +c: Nat) -> {Nat.mul(Nat.mul(a, b), c) == Nat.mul(a, Nat.mul(b, c)) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+ap:
      %Equal.sym(Nat, Nat.mul(Nat.add(b, Nat.mul(ap, b)), c), Nat.add(Nat.mul(b, c), Nat.mul(Nat.mul(ap, b), c)), mul_add_right(b, Nat.mul(ap, b), c)) : {_ == Nat.add(Nat.mul(b, c), Nat.mul(ap, Nat.mul(b, c))) : Nat}
      %mul_assoc(ap, b, c) : {Nat.add(Nat.mul(b, c), Nat.mul(Nat.mul(ap, b), c)) == Nat.add(Nat.mul(b, c), _) : Nat}
      {==}

def add_left_comm(+a: Nat, +b: Nat, +c: Nat) -> {Nat.add(a, Nat.add(b, c)) == Nat.add(b, Nat.add(a, c)) : Nat}:
  %NatL.add_assoc(a, b, c) : {_ == Nat.add(b, Nat.add(a, c)) : Nat}
  %NatL.add_assoc(b, a, c) : {Nat.add(Nat.add(a, b), c) == _ : Nat}
  %NatL.add_comm(a, b) : {Nat.add(Nat.add(a, b), c) == Nat.add(_, c) : Nat}
  {==}

def mul_succ_right(+a: Nat, +b: Nat) -> {Nat.mul(a, 1n+b) == Nat.add(a, Nat.mul(a, b)) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+ap:
      %Equal.sym(Nat, Nat.mul(ap, 1n+b), Nat.add(ap, Nat.mul(ap, b)), mul_succ_right(ap, b)) : {1n+Nat.add(b, _) == 1n+Nat.add(ap, Nat.add(b, Nat.mul(ap, b))) : Nat}
      %add_left_comm(b, ap, Nat.mul(ap, b)) : {1n+Nat.add(b, Nat.add(ap, Nat.mul(ap, b))) == 1n+_ : Nat}
      {==}

def mul_comm(+a: Nat, +b: Nat) -> {Nat.mul(a, b) == Nat.mul(b, a) : Nat}:
  match a:
    case 0n:
      Equal.sym(Nat, Nat.mul(b, 0n), 0n, NatL.mul_zero_right(b))
    case 1n+ap:
      %Equal.sym(Nat, Nat.mul(b, 1n+ap), Nat.add(b, Nat.mul(b, ap)), mul_succ_right(b, ap)) : {Nat.add(b, Nat.mul(ap, b)) == _ : Nat}
      %mul_comm(ap, b) : {Nat.add(b, Nat.mul(ap, b)) == Nat.add(b, _) : Nat}
      {==}

def lt_add_pos_left(+x: Nat, +ep: Nat) -> {Nat.is_lt(x, Nat.add(1n+ep, x)) == True{} : Bool}:
  match x:
    case 0n:
      {==}
    case 1n+xp:
      %Equal.sym(Nat, Nat.add(ep, 1n+xp), 1n+Nat.add(ep, xp), NatL.add_succ(ep, xp)) : {Nat.is_lt(xp, _) == True{} : Bool}
      lt_add_pos_left(xp, ep)

def bound_201_lt_101d(+ep: Nat) -> {Nat.is_lt(Nat.add(Nat.mul(1n+ep, 200n), 1n+ep), Nat.mul(101n, Nat.mul(2n, 1n+ep))) == True{} : Bool}:
  %mul_assoc(101n, 2n, 1n+ep) : {Nat.is_lt(Nat.add(Nat.mul(1n+ep, 200n), 1n+ep), _) == True{} : Bool}
  %Equal.sym(Nat, Nat.add(Nat.mul(1n+ep, 200n), 1n+ep), Nat.add(1n+ep, Nat.mul(1n+ep, 200n)), NatL.add_comm(Nat.mul(1n+ep, 200n), 1n+ep)) : {Nat.is_lt(_, Nat.mul(202n, 1n+ep)) == True{} : Bool}
  %Equal.sym(Nat, Nat.mul(1n+ep, 200n), Nat.mul(200n, 1n+ep), mul_comm(1n+ep, 200n)) : {Nat.is_lt(Nat.add(1n+ep, _), Nat.mul(202n, 1n+ep)) == True{} : Bool}
  lt_add_pos_left(Nat.mul(201n, 1n+ep), ep)

def Laws.safe_uptime_bounded_100(produced, expected, le):
  match expected:
    case 0n:
      {==}
    case 1n+ep:
      +dp = Nat.add(ep, Nat.add(1n+ep, 0n))
      +a = Nat.add(Nat.mul(produced, 200n), 1n+ep)
      +q = Nat.div(a, 1n+dp)
      e_qd_le_a = div_mul_le(a, dp)
      e_prod_le = mul_monotone_le_left(produced, 1n+ep, 200n, le)
      e_a_le = NatL.add_monotone_le(Nat.mul(produced, 200n), Nat.mul(1n+ep, 200n), 1n+ep, 1n+ep, e_prod_le, NatL.is_le_refl(1n+ep))
      e_qd_le_201 = NatL.le_trans(Nat.mul(q, 1n+dp), a, Nat.add(Nat.mul(1n+ep, 200n), 1n+ep), e_qd_le_a, e_a_le)
      e_qd_lt_101d = le_lt_trans(Nat.mul(q, 1n+dp), Nat.add(Nat.mul(1n+ep, 200n), 1n+ep), Nat.mul(101n, 1n+dp), e_qd_le_201, bound_201_lt_101d(ep))
      e_q_lt_101 = mul_lt_cancel_right(q, 101n, dp, e_qd_lt_101d)
      lt_succ_implies_le(q, 100n, e_q_lt_101)

def Laws.delegation_rules(d, pid, k):
  match k:
    case 0n:
      {==}
    case 1n+kp:
      {==}

def Laws.sentinel_authorization_matrix(is_owner, is_rev, has_act):
  match is_owner is_rev has_act:
    case False{} False{} False{}:
      {==}
    case False{} False{} True{}:
      {==}
    case False{} True{} False{}:
      {==}
    case False{} True{} True{}:
      {==}
    case True{} False{} False{}:
      {==}
    case True{} False{} True{}:
      {==}
    case True{} True{} False{}:
      {==}
    case True{} True{} True{}:
      {==}

def Laws.reward_collect_pillar_vs_sentinel(z, q, rest):
  {==}

def Laws.parallel_spawn_readiness_equiv(plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req):
  {==}
