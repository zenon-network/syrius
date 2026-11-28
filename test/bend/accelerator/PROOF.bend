import Base
import ./model.bend as M
import ./LAWS.bend as Laws
import ../common/nat.bend as NatL

# Local Arithmetic & Euclidean Division Lemmas for Accelerator-Z
# --------------------------------------------------------------

law lt_add_left:
  for +c: Nat
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_lt(a, b) == True{} : Bool}
  {Nat.is_lt(Nat.add(c, a), Nat.add(c, b)) == True{} : Bool}

def lt_add_left(c, a, b, e):
  match c:
    case 0n:
      e
    case 1n+cp:
      lt_add_left(cp, a, b, e)

law lt_add_right:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for e: {Nat.is_lt(a, b) == True{} : Bool}
  {Nat.is_lt(Nat.add(a, c), Nat.add(b, c)) == True{} : Bool}

def lt_add_right(a, b, c, e):
  %NatL.add_comm(c, a) : {Nat.is_lt(_, Nat.add(b, c)) == True{} : Bool}
  %NatL.add_comm(c, b) : {Nat.is_lt(Nat.add(c, a), _) == True{} : Bool}
  lt_add_left(c, a, b, e)

law lt_add_cancel_left:
  for +k: Nat
  for +x: Nat
  for +y: Nat
  for e: {Nat.is_lt(Nat.add(k, x), Nat.add(k, y)) == True{} : Bool}
  {Nat.is_lt(x, y) == True{} : Bool}

def lt_add_cancel_left(k, x, y, e):
  match k:
    case 0n:
      e
    case 1n+kp:
      lt_add_cancel_left(kp, x, y, e)

law le_lt_trans:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for ab: {Nat.is_le(a, b) == True{} : Bool}
  for bc: {Nat.is_lt(b, c) == True{} : Bool}
  {Nat.is_lt(a, c) == True{} : Bool}

def le_lt_trans(a, b, c, ab, bc):
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

law add_lt_le:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for +d: Nat
  for ab: {Nat.is_lt(a, b) == True{} : Bool}
  for cd: {Nat.is_le(c, d) == True{} : Bool}
  {Nat.is_lt(Nat.add(a, c), Nat.add(b, d)) == True{} : Bool}

def add_lt_le(a, b, c, d, ab, cd):
  e1 = NatL.add_monotone_le(a, a, c, d, NatL.is_le_refl(a), cd)
  e2 = lt_add_right(a, b, d, ab)
  le_lt_trans(Nat.add(a, c), Nat.add(a, d), Nat.add(b, d), e1, e2)

law mul_monotone_lt_left:
  for +p: Nat
  for +a: Nat
  for +b: Nat
  for +ab: {Nat.is_lt(a, b) == True{} : Bool}
  {Nat.is_lt(Nat.mul(1n+p, a), Nat.mul(1n+p, b)) == True{} : Bool}

def mul_monotone_lt_left(p, a, b, ab):
  match p:
    case 0n:
      %Equal.sym(Nat, Nat.add(a, 0n), a, NatL.add_zero(a)) : {Nat.is_lt(_, Nat.add(b, 0n)) == True{} : Bool}
      %Equal.sym(Nat, Nat.add(b, 0n), b, NatL.add_zero(b)) : {Nat.is_lt(a, _) == True{} : Bool}
      ab
    case 1n+pp:
      ih = mul_monotone_lt_left(pp, a, b, ab)
      add_lt_le(a, b, Nat.mul(1n+pp, a), Nat.mul(1n+pp, b), ab, NatL.lt_implies_le(Nat.mul(1n+pp, a), Nat.mul(1n+pp, b), ih))

law mul_lt_cancel_right:
  for +a: Nat
  for +c: Nat
  for +bp: Nat
  for e: {Nat.is_lt(Nat.mul(a, 1n+bp), Nat.mul(c, 1n+bp)) == True{} : Bool}
  {Nat.is_lt(a, c) == True{} : Bool}

def mul_lt_cancel_right(a, c, bp, e):
  match a c:
    case 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 0n 1n+cp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 1n+cp:
      mul_lt_cancel_right(ap, cp, bp, lt_add_cancel_left(1n+bp, Nat.mul(ap, 1n+bp), Nat.mul(cp, 1n+bp), e))

# Helper for divmod_go_eq step m = 0
law divmod_step_zero_rhs:
  for +np: Nat
  for +d: Nat
  for +r: Nat
  {Nat.add(Nat.add(np, Nat.mul(1n+d, 1n+r)), 0n) == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}

def divmod_step_zero_rhs(np, d, r):
  %Equal.sym(Nat, Nat.add(Nat.add(np, Nat.mul(1n+d, 1n+r)), 0n), Nat.add(np, Nat.mul(1n+d, 1n+r)), NatL.add_zero(Nat.add(np, Nat.mul(1n+d, 1n+r)))) : {_ == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  %Equal.sym(Nat, Nat.add(np, 1n+Nat.add(r, Nat.mul(d, 1n+r))), 1n+Nat.add(np, Nat.add(r, Nat.mul(d, 1n+r))), NatL.add_succ(np, Nat.add(r, Nat.mul(d, 1n+r)))) : {_ == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  %Equal.sym(Nat, Nat.add(r, Nat.mul(d, 1n+r)), Nat.add(Nat.mul(d, 1n+r), r), NatL.add_comm(r, Nat.mul(d, 1n+r))) : {1n+Nat.add(np, _) == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  %NatL.add_assoc(np, Nat.mul(d, 1n+r), r) : {1n+_ == 1n+Nat.add(Nat.add(np, Nat.mul(d, 1n+r)), r) : Nat}
  {==}

law divmod_go_eq:
  for +n: Nat
  for +m: Nat
  for +d: Nat
  for +r: Nat
  {Nat.add(
    Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(n, m, d, r)), 1n+Nat.add(m, r)),
    Pair.snd(Nat, Nat, Nat.divmod.go(n, m, d, r))
  ) == Nat.add(Nat.add(n, Nat.mul(d, 1n+Nat.add(m, r))), r) : Nat}

def divmod_go_eq(n, m, d, r):
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

law divmod_go_rem_le:
  for +n: Nat
  for +m: Nat
  for +d: Nat
  for +r: Nat
  {Nat.is_le(Pair.snd(Nat, Nat, Nat.divmod.go(n, m, d, r)), Nat.add(m, r)) == True{} : Bool}

def divmod_go_rem_le(n, m, d, r):
  match n:
    case 0n:
      NatL.is_le_add_left(m, r)
    case 1n+np:
      match m:
        case 0n:
          %NatL.add_zero(r) : {Nat.is_le(Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n)), _) == True{} : Bool}
          divmod_go_rem_le(np, r, 1n+d, 0n)
        case 1n+mp:
          %NatL.add_succ(mp, r) : {Nat.is_le(Pair.snd(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r)), _) == True{} : Bool}
          divmod_go_rem_le(np, mp, d, 1n+r)

law divmod_eq:
  for +a: Nat
  for +bp: Nat
  {Nat.add(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp)) == a : Nat}

def divmod_eq(a, bp):
  %NatL.add_zero(a) : {Nat.add(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp)) == _ : Nat}
  %NatL.add_zero(a) : {Nat.add(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp)) == Nat.add(_, 0n) : Nat}
  %NatL.add_zero(bp) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(a, bp, 0n, 0n)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(a, bp, 0n, 0n))) == Nat.add(Nat.add(a, 0n), 0n) : Nat}
  divmod_go_eq(a, bp, 0n, 0n)

law le_to_lt_succ:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_le(a, b) == True{} : Bool}
  {Nat.is_lt(a, 1n+b) == True{} : Bool}

def le_to_lt_succ(a, b, e):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 1n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 1n+bp:
      le_to_lt_succ(ap, bp, e)

law divmod_rem_le:
  for +a: Nat
  for +bp: Nat
  {Nat.is_le(Nat.mod(a, 1n+bp), bp) == True{} : Bool}

def divmod_rem_le(a, bp):
  %NatL.add_zero(bp) : {Nat.is_le(Nat.mod(a, 1n+bp), _) == True{} : Bool}
  divmod_go_rem_le(a, bp, 0n, 0n)

law divmod_rem_lt:
  for +a: Nat
  for +bp: Nat
  {Nat.is_lt(Nat.mod(a, 1n+bp), 1n+bp) == True{} : Bool}

def divmod_rem_lt(a, bp):
  le_to_lt_succ(Nat.mod(a, 1n+bp), bp, divmod_rem_le(a, bp))

law succ_div_mul_gt:
  for +a: Nat
  for +bp: Nat
  {Nat.is_gt(Nat.mul(1n+Nat.div(a, 1n+bp), 1n+bp), a) == True{} : Bool}

def succ_div_mul_gt(a, bp):
  +q = Nat.div(a, 1n+bp)
  +r = Nat.mod(a, 1n+bp)
  %Equal.sym(Bool, Nat.is_gt(Nat.mul(1n+q, 1n+bp), a), Nat.is_lt(a, Nat.mul(1n+q, 1n+bp)), NatL.is_gt_as_lt(Nat.mul(1n+q, 1n+bp), a)) : {_ == True{} : Bool}
  %NatL.add_comm(Nat.mul(q, 1n+bp), 1n+bp) : {Nat.is_lt(a, _) == True{} : Bool}
  %divmod_eq(a, bp) : {Nat.is_lt(_, Nat.add(Nat.mul(q, 1n+bp), 1n+bp)) == True{} : Bool}
  lt_add_left(Nat.mul(q, 1n+bp), r, 1n+bp, divmod_rem_lt(a, bp))

law div_mul_le_a:
  for +a: Nat
  for +bp: Nat
  {Nat.is_le(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), a) == True{} : Bool}

def div_mul_le_a(a, bp):
  %divmod_eq(a, bp) : {Nat.is_le(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), _) == True{} : Bool}
  NatL.is_le_add_right(Nat.mul(Nat.div(a, 1n+bp), 1n+bp), Nat.mod(a, 1n+bp))

law lt_succ_to_le:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_lt(a, 1n+b) == True{} : Bool}
  {Nat.is_le(a, b) == True{} : Bool}

def lt_succ_to_le(a, b, e):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n 0n:
      Empty.absurd({Nat.is_le(1n, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 2n+app 0n:
      Empty.absurd({Nat.is_le(2n+app, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 1n+bp:
      lt_succ_to_le(ap, bp, e)

law div_mul_lt_self:
  for +p: Nat
  for +k: Nat
  for +bp: Nat
  for klt: {Nat.is_lt(k, 1n+bp) == True{} : Bool}
  {Nat.is_le(1n+Nat.div(Nat.mul(1n+p, k), 1n+bp), 1n+p) == True{} : Bool}

def div_mul_lt_self(p, k, bp, klt):
  +a = Nat.mul(1n+p, k)
  +q = Nat.div(a, 1n+bp)
  e_le = div_mul_le_a(a, bp)
  e_mul_lt = mul_monotone_lt_left(p, k, 1n+bp, klt)
  e_q_mul_lt = le_lt_trans(Nat.mul(q, 1n+bp), a, Nat.mul(1n+p, 1n+bp), e_le, e_mul_lt)
  lt_succ_to_le(q, p, mul_lt_cancel_right(q, 1n+p, bp, e_q_mul_lt))

# Helper for clamped_bar_3_with conservation:
law add_le_of_sub_bound:
  for +s: Nat
  for +x: Nat
  for +bound: Nat
  for hs: {Nat.is_le(s, bound) == True{} : Bool}
  for hx: {Nat.is_le(x, Nat.sub(bound, s)) == True{} : Bool}
  {Nat.is_le(Nat.add(s, x), bound) == True{} : Bool}

def add_le_of_sub_bound(s, x, bound, hs, hx):
  %NatL.sub_add(s, bound, hs) : {Nat.is_le(Nat.add(s, x), _) == True{} : Bool}
  %NatL.add_comm(s, Nat.sub(bound, s)) : {Nat.is_le(Nat.add(s, x), _) == True{} : Bool}
  NatL.add_monotone_le(s, s, x, Nat.sub(bound, s), NatL.is_le_refl(s), hx)

law clamped_bar_3_with_le_scale:
  for +v1: Nat
  for +v2: Nat
  for +v3: Nat
  for +denom: Nat
  for +scale: Nat
  {Nat.is_le(M.bar_span_sum(M.clamped_bar_3_with(v1, v2, v3, denom, scale)), scale) == True{} : Bool}

def clamped_bar_3_with_le_scale(v1, v2, v3, denom, scale):
  match denom:
    case 0n:
      NatL.is_le_zero(scale)
    case 1n+dp:
      +s1 = Nat.min(scale, Nat.div(Nat.mul(v1, scale), 1n+dp))
      +rem1 = Nat.sub(scale, s1)
      +s2 = Nat.min(rem1, Nat.div(Nat.mul(v2, scale), 1n+dp))
      +rem2 = Nat.sub(rem1, s2)
      +s3 = Nat.min(rem2, Nat.div(Nat.mul(v3, scale), 1n+dp))
      e_s1 = NatL.min_le_left(scale, Nat.div(Nat.mul(v1, scale), 1n+dp))
      e_s2 = NatL.min_le_left(rem1, Nat.div(Nat.mul(v2, scale), 1n+dp))
      e_s3 = NatL.min_le_left(rem2, Nat.div(Nat.mul(v3, scale), 1n+dp))
      e23 = add_le_of_sub_bound(s2, s3, rem1, e_s2, e_s3)
      e123 = add_le_of_sub_bound(s1, Nat.add(s2, s3), scale, e_s1, e23)
      %Equal.sym(Nat, Nat.add(Nat.add(s1, s2), s3), Nat.add(s1, Nat.add(s2, s3)), NatL.add_assoc(s1, s2, s3)) : {Nat.is_le(_, scale) == True{} : Bool}
      e123

# ------------------------------------------------------------------------------
# Proofs of Laws 1-28
# ------------------------------------------------------------------------------

def Laws.pillar_owner_takes_precedence(pillars, addr, p, own_found):
  %Equal.sym(Maybe<&2, M.PillarEntry>, M.find_owner(pillars, addr), Some{p}, own_found) : {M.pillar_for_address.or(_, pillars, addr) == Some{p} : Maybe<&2, M.PillarEntry>}
  {==}

def Laws.pillar_owner_beats_earlier_producer(id1, own1, id2, prod2, addr, rest, not_own1):
  %Equal.sym(Bool, Nat.is_eq(own1, addr), False{}, not_own1) : {M.pillar_for_address.or(M.pick_pillar(_, M.Pillar{id1, own1, addr}, M.find_owner(M.Pillar{id2, addr, prod2} <> rest, addr)), M.Pillar{id1, own1, addr} <> (M.Pillar{id2, addr, prod2} <> rest), addr) == Some{M.Pillar{id2, addr, prod2}} : Maybe<&2, M.PillarEntry>}
  %Equal.sym(Bool, Nat.is_eq(addr, addr), True{}, NatL.is_eq_same(addr)) : {M.pillar_for_address.or(M.pick_pillar(_, M.Pillar{id2, addr, prod2}, M.find_owner(rest, addr)), M.Pillar{id1, own1, addr} <> (M.Pillar{id2, addr, prod2} <> rest), addr) == Some{M.Pillar{id2, addr, prod2}} : Maybe<&2, M.PillarEntry>}
  {==}

def Laws.pillar_producer_fallback(pillars, addr, no_own):
  %Equal.sym(Maybe<&2, M.PillarEntry>, M.find_owner(pillars, addr), None{}, no_own) : {M.pillar_for_address.or(_, pillars, addr) == M.find_producer(pillars, addr) : Maybe<&2, M.PillarEntry>}
  {==}

def Laws.vote_method_owner_vs_producer(id, own, prod, other, neq):
  %Equal.sym(Bool, Nat.is_eq(own, own), True{}, NatL.is_eq_same(own)) : {Bool.and(M.vote_method_is_by_name(M.vote_method_for.pick(_)), M.vote_method_is_by_prod(M.vote_method_for.pick(Nat.is_eq(own, other)))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(own, other), False{}, neq) : {M.vote_method_is_by_prod(M.vote_method_for.pick(_)) == True{} : Bool}
  {==}

def Laws.non_pillar_never_votes(status):
  {==}

def Laws.can_submit_vote_requires_pillar_and_voting(pillar, status, ok):
  match pillar:
    case None{}:
      Empty.absurd({status == M.Voting{} : M.ProjectStatus}, NatL.false_is_not_true(ok))
    case Some{_}:
      match status:
        case M.Voting{}:
          {==}
        case M.Active{}:
          Empty.absurd({M.Active{} == M.Voting{} : M.ProjectStatus}, NatL.false_is_not_true(ok))
        case M.Paid{}:
          Empty.absurd({M.Paid{} == M.Voting{} : M.ProjectStatus}, NatL.false_is_not_true(ok))
        case M.Closed{}:
          Empty.absurd({M.Closed{} == M.Voting{} : M.ProjectStatus}, NatL.false_is_not_true(ok))
        case M.Completed{}:
          Empty.absurd({M.Completed{} == M.Voting{} : M.ProjectStatus}, NatL.false_is_not_true(ok))

def Laws.quorum_zero_when_no_pillars(votes):
  {==}

def Laws.quorum_bounded_by_one_and_n(p):
  +q = Nat.div(Nat.mul(1n+p, 33n), 100n)
  %Equal.sym(Bool, Nat.is_le(0n, q), True{}, NatL.is_le_zero(q)) : {Bool.and(_, Nat.is_le(1n+q, 1n+p)) == True{} : Bool}
  div_mul_lt_self(p, 33n, 99n, {==})

def Laws.quorum_strictly_exceeds_33_percent(p):
  succ_div_mul_gt(Nat.mul(1n+p, 33n), 99n)

law ge_to_le_local:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_ge(a, b) == True{} : Bool}
  {Nat.is_le(b, a) == True{} : Bool}

def ge_to_le_local(a, b, e):
  %NatL.is_ge_as_le(a, b) : {_ == True{} : Bool}
  e

def Laws.abstains_count_for_quorum_not_majority(yes, no, abstain, extra, tp, qr):
  match tp:
    case 0n:
      Empty.absurd({False{} == True{} : Bool}, NatL.false_is_not_true(qr))
    case 1n+p:
      +qn = M.quorum_needed(1n+p)
      e_le = ge_to_le_local(M.vote_total(yes, no, abstain), qn, qr)
      e_step = NatL.is_le_add_right(M.vote_total(yes, no, abstain), extra)
      e_trans = NatL.le_trans(qn, M.vote_total(yes, no, abstain), Nat.add(M.vote_total(yes, no, abstain), extra), e_le, e_step)
      %Equal.sym(Bool, Nat.is_ge(M.vote_total(yes, no, Nat.add(abstain, extra)), qn), Nat.is_le(qn, M.vote_total(yes, no, Nat.add(abstain, extra))), NatL.is_ge_as_le(M.vote_total(yes, no, Nat.add(abstain, extra)), qn)) : {_ == True{} : Bool}
      %NatL.add_assoc(Nat.add(yes, no), abstain, extra) : {Nat.is_le(qn, _) == True{} : Bool}
      e_trans

def Laws.majority_strict_tie_fails(n):
  %Equal.sym(Bool, Nat.is_gt(n, n), Nat.is_lt(n, n), NatL.is_gt_as_lt(n, n)) : {_ == False{} : Bool}
  NatL.is_lt_irrefl(n)

def Laws.clamped_bar_zero_total_safe(v1, v2, v3):
  {==}

def Laws.clamped_bar_3_conserved(v1, v2, v3, total):
  clamped_bar_3_with_le_scale(v1, v2, v3, total, M.BAR_SCALE())

def Laws.quorum_progress_bar_conserved(quorum, total_pillars):
  +qn = M.quorum_needed(total_pillars)
  +to_quorum = Nat.min(Nat.sub(qn, quorum), total_pillars)
  +can_still = Nat.min(Nat.sub(Nat.sub(total_pillars, quorum), to_quorum), total_pillars)
  clamped_bar_3_with_le_scale(quorum, to_quorum, can_still, total_pillars, M.BAR_SCALE())

def Laws.pillar_sees_all_statuses(status, is_owner):
  {==}

law is_le_add_succ_false:
  for +a: Nat
  for +k: Nat
  {Nat.is_le(Nat.add(a, 1n+k), a) == False{} : Bool}

def is_le_add_succ_false(a, k):
  match a:
    case 0n:
      {==}
    case 1n+ap:
      is_le_add_succ_false(ap, k)

law bool_and_intro_local:
  for +a: Bool
  for +b: Bool
  for ea: {a == True{} : Bool}
  for eb: {b == True{} : Bool}
  {Bool.and(a, b) == True{} : Bool}

def bool_and_intro_local(a, b, ea, eb):
  %Equal.sym(Bool, a, True{}, ea) : {Bool.and(_, b) == True{} : Bool}
  eb

def Laws.non_pillar_visibility_exact(status, is_owner):
  %Equal.sym(Bool, Bool.or(M.status_is_active(status), True{}), True{}, NatL.or_true_right(M.status_is_active(status))) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

def Laws.losing_pillar_strips_voting_tags(mp, oa, nv, av):
  {==}

def Laws.filter_tags_strict_and_conjunction(proj, m):
  match proj:
    case M.ProjView{st, own, hnv, hav}:
      m

def Laws.donation_rejects_negative_legs(m, other, bz, bq):
  match other:
    case M.NonNeg{_}:
      {==}
    case M.Neg{_}:
      {==}

law donation_zero_zero_false:
  for +bz: Nat
  for +bq: Nat
  {M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{0n}, bz, bq) == False{} : Bool}

def donation_zero_zero_false(bz, bq):
  %Equal.sym(Bool, Bool.and(Nat.is_le(0n, bq), False{}), False{}, NatL.and_false_right(Nat.is_le(0n, bq))) : {Bool.and(Nat.is_le(0n, bz), _) == False{} : Bool}
  NatL.and_false_right(Nat.is_le(0n, bz))

law donation_over_znn_false:
  for +bz: Nat
  for +over: Nat
  for +q: Nat
  for +bq: Nat
  {M.is_valid_donation(M.NonNeg{Nat.add(bz, 1n+over)}, M.NonNeg{q}, bz, bq) == False{} : Bool}

def donation_over_znn_false(bz, over, q, bq):
  %Equal.sym(Bool, Nat.is_le(Nat.add(bz, 1n+over), bz), False{}, is_le_add_succ_false(bz, over)) : {Bool.and(_, Bool.and(Nat.is_le(q, bq), Bool.or(Nat.is_gt(Nat.add(bz, 1n+over), 0n), Nat.is_gt(q, 0n)))) == False{} : Bool}
  {==}

law donation_over_qsr_false:
  for +z: Nat
  for +bz: Nat
  for +bq: Nat
  for +over: Nat
  {M.is_valid_donation(M.NonNeg{z}, M.NonNeg{Nat.add(bq, 1n+over)}, bz, bq) == False{} : Bool}

def donation_over_qsr_false(z, bz, bq, over):
  %Equal.sym(Bool, Nat.is_le(Nat.add(bq, 1n+over), bq), False{}, is_le_add_succ_false(bq, over)) : {Bool.and(Nat.is_le(z, bz), Bool.and(_, Bool.or(Nat.is_gt(z, 0n), Nat.is_gt(Nat.add(bq, 1n+over), 0n)))) == False{} : Bool}
  NatL.and_false_right(Nat.is_le(z, bz))

law donation_pos_znn_true:
  for +z: Nat
  for +bq: Nat
  {M.is_valid_donation(M.NonNeg{1n+z}, M.NonNeg{0n}, 1n+z, bq) == True{} : Bool}

def donation_pos_znn_true(z, bq):
  %Equal.sym(Bool, Nat.is_le(1n+z, 1n+z), True{}, NatL.is_le_refl(1n+z)) : {Bool.and(_, Bool.and(Nat.is_le(0n, bq), True{})) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(0n, bq), True{}, NatL.is_le_zero(bq)) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

law donation_pos_qsr_true:
  for +q: Nat
  for +bz: Nat
  {M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{1n+q}, bz, 1n+q) == True{} : Bool}

def donation_pos_qsr_true(q, bz):
  %Equal.sym(Bool, Nat.is_le(0n, bz), True{}, NatL.is_le_zero(bz)) : {Bool.and(_, Bool.and(Nat.is_le(1n+q, 1n+q), True{})) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(1n+q, 1n+q), True{}, NatL.is_le_refl(1n+q)) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

law not_false_eq_true:
  for +b: Bool
  for e: {b == False{} : Bool}
  {Bool.not(b) == True{} : Bool}

def not_false_eq_true(b, e):
  %Equal.sym(Bool, b, False{}, e) : {Bool.not(_) == True{} : Bool}
  {==}

def Laws.donation_valid_bounds_and_positive(z, q, bz, bq, over):
  e_zz = not_false_eq_true(M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{0n}, bz, bq), donation_zero_zero_false(bz, bq))
  e_oz = not_false_eq_true(M.is_valid_donation(M.NonNeg{Nat.add(bz, 1n+over)}, M.NonNeg{q}, bz, bq), donation_over_znn_false(bz, over, q, bq))
  e_oq = not_false_eq_true(M.is_valid_donation(M.NonNeg{z}, M.NonNeg{Nat.add(bq, 1n+over)}, bz, bq), donation_over_qsr_false(z, bz, bq, over))
  e_pz = donation_pos_znn_true(z, bq)
  e_pq = donation_pos_qsr_true(q, bz)
  bool_and_intro_local(
    Bool.and(Bool.not(M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{0n}, bz, bq)), Bool.and(Bool.not(M.is_valid_donation(M.NonNeg{Nat.add(bz, 1n+over)}, M.NonNeg{q}, bz, bq)), Bool.not(M.is_valid_donation(M.NonNeg{z}, M.NonNeg{Nat.add(bq, 1n+over)}, bz, bq)))),
    Bool.and(M.is_valid_donation(M.NonNeg{1n+z}, M.NonNeg{0n}, 1n+z, bq), M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{1n+q}, bz, 1n+q)),
    bool_and_intro_local(
      Bool.not(M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{0n}, bz, bq)),
      Bool.and(Bool.not(M.is_valid_donation(M.NonNeg{Nat.add(bz, 1n+over)}, M.NonNeg{q}, bz, bq)), Bool.not(M.is_valid_donation(M.NonNeg{z}, M.NonNeg{Nat.add(bq, 1n+over)}, bz, bq))),
      e_zz,
      bool_and_intro_local(
        Bool.not(M.is_valid_donation(M.NonNeg{Nat.add(bz, 1n+over)}, M.NonNeg{q}, bz, bq)),
        Bool.not(M.is_valid_donation(M.NonNeg{z}, M.NonNeg{Nat.add(bq, 1n+over)}, bz, bq)),
        e_oz,
        e_oq
      )
    ),
    bool_and_intro_local(
      M.is_valid_donation(M.NonNeg{1n+z}, M.NonNeg{0n}, 1n+z, bq),
      M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{1n+q}, bz, 1n+q),
      e_pz,
      e_pq
    )
  )

def Laws.donation_partial_failure_no_double_znn(zp, qp, retry_znn_ok):
  %Equal.sym(Bool, Nat.is_eq(qp, qp), True{}, NatL.is_eq_same(qp)) : {Bool.and(Bool.and(_, True{}), True{}) == True{} : Bool}
  {==}

def Laws.donation_both_succeed_reaches_submitted(z, q, pos):
  match z q:
    case 0n 0n:
      Empty.absurd({M.DonFailed{False{}} == M.DonSubmitted{} : M.DonationStatus}, NatL.false_is_not_true(pos))
    case 1n+zp 0n:
      {==}
    case 0n 1n+qp:
      {==}
    case 1n+zp 1n+qp:
      {==}

law budget_low_znn_false:
  for +bal: Nat
  for +qsr: Nat
  {M.valid_project_budget(bal, 9n, qsr) == False{} : Bool}

def budget_low_znn_false(bal, qsr):
  NatL.and_false_right(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()))

law budget_over_znn_false:
  for +bal: Nat
  for +over: Nat
  for +qsr: Nat
  {M.valid_project_budget(bal, Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), qsr) == False{} : Bool}

def budget_over_znn_false(bal, over, qsr):
  %Equal.sym(Bool, Nat.is_le(Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), M.PROJECT_MAX_ZNN()), False{}, is_le_add_succ_false(M.PROJECT_MAX_ZNN(), over)) : {Bool.and(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()), Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), Nat.add(M.PROJECT_MAX_ZNN(), 1n+over)), _), Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), qsr), Nat.is_le(qsr, M.PROJECT_MAX_QSR())))) == False{} : Bool}
  %Equal.sym(Bool, Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), Nat.add(M.PROJECT_MAX_ZNN(), 1n+over)), False{}), False{}, NatL.and_false_right(Nat.is_le(M.PROJECT_MIN_ZNN(), Nat.add(M.PROJECT_MAX_ZNN(), 1n+over)))) : {Bool.and(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()), Bool.and(_, Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), qsr), Nat.is_le(qsr, M.PROJECT_MAX_QSR())))) == False{} : Bool}
  NatL.and_false_right(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()))

law budget_low_qsr_false:
  for +bal: Nat
  for +znn: Nat
  {M.valid_project_budget(bal, znn, 99n) == False{} : Bool}

def budget_low_qsr_false(bal, znn):
  %Equal.sym(Bool, Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), znn), Nat.is_le(znn, M.PROJECT_MAX_ZNN())), False{}), False{}, NatL.and_false_right(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), znn), Nat.is_le(znn, M.PROJECT_MAX_ZNN())))) : {Bool.and(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()), _) == False{} : Bool}
  NatL.and_false_right(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()))

law budget_over_qsr_false:
  for +bal: Nat
  for +znn: Nat
  for +over: Nat
  {M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over)) == False{} : Bool}

def budget_over_qsr_false(bal, znn, over):
  %Equal.sym(Bool, Nat.is_le(Nat.add(M.PROJECT_MAX_QSR(), 1n+over), M.PROJECT_MAX_QSR()), False{}, is_le_add_succ_false(M.PROJECT_MAX_QSR(), over)) : {Bool.and(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()), Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), znn), Nat.is_le(znn, M.PROJECT_MAX_ZNN())), Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), Nat.add(M.PROJECT_MAX_QSR(), 1n+over)), _))) == False{} : Bool}
  %Equal.sym(Bool, Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), Nat.add(M.PROJECT_MAX_QSR(), 1n+over)), False{}), False{}, NatL.and_false_right(Nat.is_le(M.PROJECT_MIN_QSR(), Nat.add(M.PROJECT_MAX_QSR(), 1n+over)))) : {Bool.and(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()), Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), znn), Nat.is_le(znn, M.PROJECT_MAX_ZNN())), _)) == False{} : Bool}
  %Equal.sym(Bool, Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), znn), Nat.is_le(znn, M.PROJECT_MAX_ZNN())), False{}), False{}, NatL.and_false_right(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), znn), Nat.is_le(znn, M.PROJECT_MAX_ZNN())))) : {Bool.and(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()), _) == False{} : Bool}
  NatL.and_false_right(Nat.is_ge(bal, M.PROJECT_CREATION_FEE_ZNN()))

law budget_min_ok:
  for +bal: Nat
  {M.valid_project_budget(1n+bal, M.PROJECT_MIN_ZNN(), M.PROJECT_MIN_QSR()) == True{} : Bool}

def budget_min_ok(bal):
  %Equal.sym(Bool, Nat.is_ge(bal, 0n), Nat.is_le(0n, bal), NatL.is_ge_as_le(bal, 0n)) : {Bool.and(_, Bool.and(Bool.and(True{}, Nat.is_le(M.PROJECT_MIN_ZNN(), M.PROJECT_MAX_ZNN())), Bool.and(True{}, Nat.is_le(M.PROJECT_MIN_QSR(), M.PROJECT_MAX_QSR())))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(0n, bal), True{}, NatL.is_le_zero(bal)) : {Bool.and(_, Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), M.PROJECT_MAX_ZNN()), Nat.is_le(M.PROJECT_MIN_QSR(), M.PROJECT_MAX_QSR()))) == True{} : Bool}
  {==}

law budget_max_ok:
  for +bal: Nat
  {M.valid_project_budget(1n+bal, M.PROJECT_MAX_ZNN(), M.PROJECT_MAX_QSR()) == True{} : Bool}

def budget_max_ok(bal):
  %Equal.sym(Bool, Nat.is_ge(bal, 0n), Nat.is_le(0n, bal), NatL.is_ge_as_le(bal, 0n)) : {Bool.and(_, Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), M.PROJECT_MAX_ZNN()), Nat.is_le(M.PROJECT_MAX_ZNN(), M.PROJECT_MAX_ZNN())), Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), M.PROJECT_MAX_QSR()), Nat.is_le(M.PROJECT_MAX_QSR(), M.PROJECT_MAX_QSR())))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(0n, bal), True{}, NatL.is_le_zero(bal)) : {Bool.and(_, Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), M.PROJECT_MAX_ZNN()), Nat.is_le(M.PROJECT_MAX_ZNN(), M.PROJECT_MAX_ZNN())), Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), M.PROJECT_MAX_QSR()), Nat.is_le(M.PROJECT_MAX_QSR(), M.PROJECT_MAX_QSR())))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(M.PROJECT_MAX_ZNN(), M.PROJECT_MAX_ZNN()), True{}, NatL.is_le_refl(M.PROJECT_MAX_ZNN())) : {Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), M.PROJECT_MAX_ZNN()), _), Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), M.PROJECT_MAX_QSR()), Nat.is_le(M.PROJECT_MAX_QSR(), M.PROJECT_MAX_QSR()))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(M.PROJECT_MAX_QSR(), M.PROJECT_MAX_QSR()), True{}, NatL.is_le_refl(M.PROJECT_MAX_QSR())) : {Bool.and(Bool.and(Nat.is_le(M.PROJECT_MIN_ZNN(), M.PROJECT_MAX_ZNN()), True{}), Bool.and(Nat.is_le(M.PROJECT_MIN_QSR(), M.PROJECT_MAX_QSR()), _)) == True{} : Bool}
  {==}

def Laws.valid_project_budget_enforces_caps(bal, znn, qsr, over):
  e_lz = not_false_eq_true(M.valid_project_budget(bal, 9n, qsr), budget_low_znn_false(bal, qsr))
  e_oz = not_false_eq_true(M.valid_project_budget(bal, Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), qsr), budget_over_znn_false(bal, over, qsr))
  e_lq = not_false_eq_true(M.valid_project_budget(bal, znn, 99n), budget_low_qsr_false(bal, znn))
  e_oq = not_false_eq_true(M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over)), budget_over_qsr_false(bal, znn, over))
  e_min = budget_min_ok(bal)
  e_max = budget_max_ok(bal)
  bool_and_intro_local(
    Bool.and(Bool.not(M.valid_project_budget(0n, znn, qsr)), Bool.and(Bool.not(M.valid_project_budget(bal, 9n, qsr)), Bool.and(Bool.not(M.valid_project_budget(bal, Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), qsr)), Bool.and(Bool.not(M.valid_project_budget(bal, znn, 99n)), Bool.not(M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over))))))),
    Bool.and(M.valid_project_budget(1n+bal, M.PROJECT_MIN_ZNN(), M.PROJECT_MIN_QSR()), M.valid_project_budget(1n+bal, M.PROJECT_MAX_ZNN(), M.PROJECT_MAX_QSR())),
    bool_and_intro_local(
      Bool.not(M.valid_project_budget(0n, znn, qsr)),
      Bool.and(Bool.not(M.valid_project_budget(bal, 9n, qsr)), Bool.and(Bool.not(M.valid_project_budget(bal, Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), qsr)), Bool.and(Bool.not(M.valid_project_budget(bal, znn, 99n)), Bool.not(M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over)))))),
      {==},
      bool_and_intro_local(
        Bool.not(M.valid_project_budget(bal, 9n, qsr)),
        Bool.and(Bool.not(M.valid_project_budget(bal, Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), qsr)), Bool.and(Bool.not(M.valid_project_budget(bal, znn, 99n)), Bool.not(M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over))))),
        e_lz,
        bool_and_intro_local(
          Bool.not(M.valid_project_budget(bal, Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), qsr)),
          Bool.and(Bool.not(M.valid_project_budget(bal, znn, 99n)), Bool.not(M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over)))),
          e_oz,
          bool_and_intro_local(
            Bool.not(M.valid_project_budget(bal, znn, 99n)),
            Bool.not(M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over))),
            e_lq,
            e_oq
          )
        )
      )
    ),
    bool_and_intro_local(
      M.valid_project_budget(1n+bal, M.PROJECT_MIN_ZNN(), M.PROJECT_MIN_QSR()),
      M.valid_project_budget(1n+bal, M.PROJECT_MAX_ZNN(), M.PROJECT_MAX_QSR()),
      e_min,
      e_max
    )
  )

def Laws.budget_conservation(paid, total, le):
  %NatL.add_comm(M.remaining_funds(total, paid), paid) : {_ == total : Nat}
  NatL.sub_add(paid, total, le)

def Laws.phase_funds_never_overspend_total(paid, phase, total, le_pt, le_rem):
  e1 = NatL.add_monotone_le(paid, paid, phase, M.remaining_funds(total, paid), NatL.is_le_refl(paid), le_rem)
  %Laws.budget_conservation(paid, total, le_pt) : {Nat.is_le(Nat.add(paid, phase), _) == True{} : Bool}
  e1

def Laws.sequential_phase_create_and_update_gate(is_owner, proj_st, last_ph, ph_st):
  {==}

def Laws.can_create_phase_requires_owner_and_active(is_owner, proj_st, last_ph, ok):
  match is_owner:
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, NatL.false_is_not_true(ok))
    case True{}:
      NatL.and_true_left(M.status_is_active(proj_st), M.last_phase_allows_next(last_ph), ok)

def Laws.parallel_accelerator_audit_equiv(pillar, vote_status, yes, no, abstain, total_pillars, owner_znn_bal, znn_needed, qsr_needed, is_owner, proj_status, last_phase):
  {==}
