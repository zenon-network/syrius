import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# Constructive proofs of all Syrius amounts, decimal, validator, sorting,
# plasma-tier, password-strength, and UI-edge laws.

# Local Nat & Word/U32 helper lemmas
# ----------------------------------

def dup_bool_true(+x: Bool, e: {x == True{} : Bool}) -> {x == True{} : Bool} & {x == True{} : Bool}:
  match x:
    case True{}:
      ({==}, {==})
    case False{}:
      Empty.absurd({False{} == True{} : Bool} & {False{} == True{} : Bool}, NatL.false_is_not_true(e))

def big_min_step_succ(+ap: Nat, +bp: Nat, le: Bool) -> {M.big_min_branch(1n+ap, 1n+bp, le) == 1n+M.big_min_branch(ap, bp, le) : Nat}:
  match le:
    case True{}:
      {==}
    case False{}:
      {==}

def big_min_eq_nat_min(+a: Nat, +b: Nat) -> {M.big_min(a, b) == Nat.min(a, b) : Nat}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      %big_min_eq_nat_min(ap, bp) : {M.big_min_branch(1n+ap, 1n+bp, Nat.is_le(ap, bp)) == 1n+_ : Nat}
      big_min_step_succ(ap, bp, Nat.is_le(ap, bp))

def big_max_step_succ(+ap: Nat, +bp: Nat, le: Bool) -> {M.big_max_branch(1n+ap, 1n+bp, le) == 1n+M.big_max_branch(ap, bp, le) : Nat}:
  match le:
    case True{}:
      {==}
    case False{}:
      {==}

def big_max_eq_nat_max(+a: Nat, +b: Nat) -> {M.big_max(a, b) == Nat.max(a, b) : Nat}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      %big_max_eq_nat_max(ap, bp) : {M.big_max_branch(1n+ap, 1n+bp, Nat.is_le(ap, bp)) == 1n+_ : Nat}
      big_max_step_succ(ap, bp, Nat.is_le(ap, bp))

def nat_le_max_left(+a: Nat, +b: Nat) -> {Nat.is_le(a, Nat.max(a, b)) == True{} : Bool}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      NatL.is_le_refl(ap)
    case 1n+ap 1n+bp:
      nat_le_max_left(ap, bp)

def nat_le_max_right(+a: Nat, +b: Nat) -> {Nat.is_le(b, Nat.max(a, b)) == True{} : Bool}:
  match a b:
    case 0n _:
      NatL.is_le_refl(b)
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      nat_le_max_right(ap, bp)

def nat_min_comm(+a: Nat, +b: Nat) -> {Nat.min(a, b) == Nat.min(b, a) : Nat}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      %nat_min_comm(ap, bp) : {1n+Nat.min(ap, bp) == 1n+_ : Nat}
      {==}

def nat_max_comm(+a: Nat, +b: Nat) -> {Nat.max(a, b) == Nat.max(b, a) : Nat}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      %nat_max_comm(ap, bp) : {1n+Nat.max(ap, bp) == 1n+_ : Nat}
      {==}

def nat_max_self(+a: Nat) -> {Nat.max(a, a) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %nat_max_self(p) : {1n+Nat.max(p, p) == 1n+_ : Nat}
      {==}

def nat_min_max_add(+a: Nat, +b: Nat) -> {Nat.add(Nat.min(a, b), Nat.max(a, b)) == Nat.add(a, b) : Nat}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Equal.sym(Nat, Nat.add(1n+ap, 0n), 1n+ap, NatL.add_zero(1n+ap))
    case 1n+ap 1n+bp:
      %Equal.sym(Nat, Nat.add(Nat.min(ap, bp), 1n+Nat.max(ap, bp)), 1n+Nat.add(Nat.min(ap, bp), Nat.max(ap, bp)), NatL.add_succ(Nat.min(ap, bp), Nat.max(ap, bp))) : {1n+_ == 1n+Nat.add(ap, 1n+bp) : Nat}
      %Equal.sym(Nat, Nat.add(ap, 1n+bp), 1n+Nat.add(ap, bp), NatL.add_succ(ap, bp)) : {2n+Nat.add(Nat.min(ap, bp), Nat.max(ap, bp)) == 1n+_ : Nat}
      %nat_min_max_add(ap, bp) : {2n+Nat.add(Nat.min(ap, bp), Nat.max(ap, bp)) == 2n+_ : Nat}
      {==}

def nat_min_eq_big_min(+a: Nat, +b: Nat) -> {Nat.min(a, b) == M.big_min(a, b) : Nat}:
  Equal.sym(Nat, M.big_min(a, b), Nat.min(a, b), big_min_eq_nat_min(a, b))

def nat_max_eq_big_max(+a: Nat, +b: Nat) -> {Nat.max(a, b) == M.big_max(a, b) : Nat}:
  Equal.sym(Nat, M.big_max(a, b), Nat.max(a, b), big_max_eq_nat_max(a, b))

# 1. BigInt min/max lattice proofs
# --------------------------------

def Laws.big_min_comm(a, b):
  %nat_min_eq_big_min(a, b) : {_ == M.big_min(b, a) : Nat}
  %nat_min_eq_big_min(b, a) : {Nat.min(a, b) == _ : Nat}
  nat_min_comm(a, b)

def Laws.big_max_comm(a, b):
  %nat_max_eq_big_max(a, b) : {_ == M.big_max(b, a) : Nat}
  %nat_max_eq_big_max(b, a) : {Nat.max(a, b) == _ : Nat}
  nat_max_comm(a, b)

def Laws.big_min_idem(a):
  %nat_min_eq_big_min(a, a) : {_ == a : Nat}
  NatL.min_self(a)

def Laws.big_max_idem(a):
  %nat_max_eq_big_max(a, a) : {_ == a : Nat}
  nat_max_self(a)

def Laws.big_min_le_bounds(a, b):
  %nat_min_eq_big_min(a, b) : {Bool.and(Nat.is_le(_, a), Nat.is_le(_, b)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(Nat.min(a, b), a), True{}, NatL.min_le_left(a, b)) : {Bool.and(_, Nat.is_le(Nat.min(a, b), b)) == True{} : Bool}
  NatL.min_le_right(a, b)

def Laws.big_max_ge_bounds(a, b):
  %nat_max_eq_big_max(a, b) : {Bool.and(Nat.is_le(a, _), Nat.is_le(b, _)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(a, Nat.max(a, b)), True{}, nat_le_max_left(a, b)) : {Bool.and(_, Nat.is_le(b, Nat.max(a, b))) == True{} : Bool}
  nat_le_max_right(a, b)

def Laws.big_min_max_conservation(a, b):
  %nat_min_eq_big_min(a, b) : {Nat.add(_, M.big_max(a, b)) == Nat.add(a, b) : Nat}
  %nat_max_eq_big_max(a, b) : {Nat.add(Nat.min(a, b), _) == Nat.add(a, b) : Nat}
  nat_min_max_add(a, b)

# 2. Decimal scaling & canonical roundtrip proofs
# -----------------------------------------------

def mul_pos(+a: Nat, +b: Nat, ea: {Nat.is_gt(a, 0n) == True{} : Bool}, eb: {Nat.is_gt(b, 0n) == True{} : Bool}) -> {Nat.is_gt(Nat.mul(a, b), 0n) == True{} : Bool}:
  match a b:
    case 0n _:
      Empty.absurd({Nat.is_gt(Nat.mul(0n, b), 0n) == True{} : Bool}, NatL.false_is_not_true(ea))
    case 1n+ap 0n:
      Empty.absurd({Nat.is_gt(Nat.mul(1n+ap, 0n), 0n) == True{} : Bool}, NatL.false_is_not_true(eb))
    case 1n+ap 1n+bp:
      {==}

def Laws.pow10_positive(d):
  match d:
    case 0n:
      {==}
    case 1n+p:
      mul_pos(10n, M.pow10(p), {==}, Laws.pow10_positive(p))

def nat_div_zero_go(bp: Nat, d: Nat, r: Nat) -> {Nat.divmod.go(0n, bp, d, r) == (d, r) : Nat & Nat}:
  {==}

def nat_div_zero(+b: Nat) -> {Nat.div(0n, b) == 0n : Nat}:
  match b:
    case 0n:
      {==}
    case 1n+bp:
      {==}

def scale_frac_zero_branch(+fl: Nat, +d: Nat, le: Bool) -> {M.scale_frac_branch(0n, fl, d, le) == 0n : Nat}:
  match le:
    case True{}:
      {==}
    case False{}:
      nat_div_zero(M.pow10(Nat.sub(fl, d)))

def Laws.extract_decimals_zero(fl, d):
  scale_frac_zero_branch(fl, d, Nat.is_le(fl, d))

def mul_one_right(+a: Nat) -> {Nat.mul(a, 1n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %mul_one_right(p) : {1n+Nat.mul(p, 1n) == 1n+_ : Nat}
      {==}

# Divmod soundness: for Nat.divmod.go(n, m, d, r),
# with divisor k = 1 + m + r, the result (q, rem) satisfies
# q * k + rem == n + d * k + r.
def divmod_go_sound(+n: Nat, +m: Nat, +d: Nat, +r: Nat) -> {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(n, m, d, r)), 1n+Nat.add(m, r)), Pair.snd(Nat, Nat, Nat.divmod.go(n, m, d, r))) == Nat.add(n, Nat.add(Nat.mul(d, 1n+Nat.add(m, r)), r)) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+np:
      match m:
        case 0n:
          # Divisor is 1n + r; recursive call is Nat.divmod.go(np, r, 1n+d, 0n)
          # whose divisor is 1n + Nat.add(r, 0n) == 1n + r.
          %NatL.add_zero(r) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n))) == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
          %Equal.sym(Nat, Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n)), 1n+Nat.add(r, 0n)), Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n))), Nat.add(np, Nat.add(Nat.mul(1n+d, 1n+Nat.add(r, 0n)), 0n)), divmod_go_sound(np, r, 1n+d, 0n)) : {_ == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
          %Equal.sym(Nat, Nat.add(r, 0n), r, NatL.add_zero(r)) : {Nat.add(np, Nat.add(Nat.mul(1n+d, 1n+_), 0n)) == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
          %Equal.sym(Nat, Nat.add(Nat.mul(1n+d, 1n+r), 0n), Nat.mul(1n+d, 1n+r), NatL.add_zero(Nat.mul(1n+d, 1n+r))) : {Nat.add(np, _) == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
          %NatL.add_comm(Nat.mul(d, 1n+r), r) : {Nat.add(np, 1n+_) == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
          NatL.add_succ(np, Nat.add(Nat.mul(d, 1n+r), r))
        case 1n+mp:
          # Divisor is 1n + (1n + mp) + r == 1n + mp + (1n + r)
          %NatL.add_succ(mp, r) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r))) == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+_), r)) : Nat}
          %Equal.sym(Nat, Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r)), 1n+Nat.add(mp, 1n+r)), Pair.snd(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r))), Nat.add(np, Nat.add(Nat.mul(d, 1n+Nat.add(mp, 1n+r)), 1n+r)), divmod_go_sound(np, mp, d, 1n+r)) : {_ == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+Nat.add(mp, 1n+r)), r)) : Nat}
          %Equal.sym(Nat, Nat.add(Nat.mul(d, 1n+Nat.add(mp, 1n+r)), 1n+r), 1n+Nat.add(Nat.mul(d, 1n+Nat.add(mp, 1n+r)), r), NatL.add_succ(Nat.mul(d, 1n+Nat.add(mp, 1n+r)), r)) : {Nat.add(np, _) == 1n+Nat.add(np, Nat.add(Nat.mul(d, 1n+Nat.add(mp, 1n+r)), r)) : Nat}
          NatL.add_succ(np, Nat.add(Nat.mul(d, 1n+Nat.add(mp, 1n+r)), r))

def divmod_sound(+n: Nat, +b: Nat, pos: {Nat.is_gt(b, 0n) == True{} : Bool}) -> {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod(n, b)), b), Pair.snd(Nat, Nat, Nat.divmod(n, b))) == n : Nat}:
  match b:
    case 0n:
      Empty.absurd({Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod(n, 0n)), 0n), Pair.snd(Nat, Nat, Nat.divmod(n, 0n))) == n : Nat}, NatL.false_is_not_true(pos))
    case 1n+bp:
      %NatL.add_zero(bp) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(n, bp, 0n, 0n)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(n, bp, 0n, 0n))) == n : Nat}
      %Equal.sym(Nat, Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(n, bp, 0n, 0n)), 1n+Nat.add(bp, 0n)), Pair.snd(Nat, Nat, Nat.divmod.go(n, bp, 0n, 0n))), Nat.add(n, Nat.add(Nat.mul(0n, 1n+Nat.add(bp, 0n)), 0n)), divmod_go_sound(n, bp, 0n, 0n)) : {_ == n : Nat}
      NatL.add_zero(n)

def roundtrip_pair_eq(qr: Nat & Nat, +d: Nat) -> {M.roundtrip_decimals_parts(M.add_decimals_from_pair(qr, d), d) == Nat.add(Nat.mul(Pair.fst(Nat, Nat, qr), M.pow10(d)), Pair.snd(Nat, Nat, qr)) : Nat}:
  (q, r) = qr
  %Equal.sym(Bool, Nat.is_le(d, d), True{}, NatL.is_le_refl(d)) : {Nat.add(Nat.mul(q, M.pow10(d)), M.scale_frac_branch(r, d, d, _)) == Nat.add(Nat.mul(q, M.pow10(d)), r) : Nat}
  %Equal.sym(Nat, Nat.sub(d, d), 0n, NatL.sub_self(d)) : {Nat.add(Nat.mul(q, M.pow10(d)), Nat.mul(r, M.pow10(_))) == Nat.add(Nat.mul(q, M.pow10(d)), r) : Nat}
  %mul_one_right(r) : {Nat.add(Nat.mul(q, M.pow10(d)), Nat.mul(r, 1n)) == Nat.add(Nat.mul(q, M.pow10(d)), _) : Nat}
  {==}

def Laws.decimals_canonical_roundtrip(base_units, d):
  Equal.trans(Nat,
    M.roundtrip_decimals_parts(M.add_decimals_from_pair(Nat.divmod(base_units, M.pow10(d)), d), d),
    Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod(base_units, M.pow10(d))), M.pow10(d)), Pair.snd(Nat, Nat, Nat.divmod(base_units, M.pow10(d)))),
    base_units,
    roundtrip_pair_eq(Nat.divmod(base_units, M.pow10(d)), d),
    divmod_sound(base_units, M.pow10(d), Laws.pow10_positive(d)))

def is_le_add_succ_false(+d: Nat, +extra: Nat) -> {Nat.is_le(Nat.add(d, 1n+extra), d) == False{} : Bool}:
  match d:
    case 0n:
      {==}
    case 1n+dp:
      is_le_add_succ_false(dp, extra)

def Laws.scale_frac_truncation_exact(frac, d, extra):
  %Equal.sym(Bool, Nat.is_le(Nat.add(d, 1n+extra), d), False{}, is_le_add_succ_false(d, extra)) : {M.scale_frac_branch(frac, Nat.add(d, 1n+extra), d, _) == Nat.div(frac, M.pow10(1n+extra)) : Nat}
  %NatL.sub_cancel_add_left(d, 1n+extra) : {Nat.div(frac, M.pow10(Nat.sub(Nat.add(d, 1n+extra), d))) == Nat.div(frac, M.pow10(_)) : Nat}
  {==}

# 3. Amount validator (correct_value) proofs
# ------------------------------------------

def Laws.correct_value_empty_balance_rejected(val, dec, min_val, can_eq_min, can_be_blank, is_blank, parse_ok, frac_digits, e_empty):
  match min_val can_eq_min:
    case 0n False{}:
      {==}
    case 0n True{}:
      Empty.absurd({M.correct_value(val, 0n, dec, 0n, True{}, can_be_blank, is_blank, parse_ok, frac_digits) == M.AmountErrEmptyBalance{} : M.AmountError}, NatL.false_is_not_true(e_empty))
    case 1n+_ False{}:
      {==}
    case 1n+_ True{}:
      {==}

def blank_is_ok_eq(can_be_blank: Bool) -> {M.amount_is_ok(M.correct_value_blank(can_be_blank)) == can_be_blank : Bool}:
  match can_be_blank:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.correct_value_blank_iff(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, e_non_empty):
  %Equal.sym(Bool, Bool.and(Nat.is_eq(max_val, 0n), Bool.or(Bool.not(can_eq_min), Nat.is_gt(min_val, 0n))), False{}, e_non_empty) : {M.amount_is_ok(M.correct_value_check_empty_bal(val, max_val, dec, min_val, can_eq_min, can_be_blank, True{}, parse_ok, frac_digits, _)) == can_be_blank : Bool}
  blank_is_ok_eq(can_be_blank)

def check_empty_parse_err(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, +frac_digits: Nat, empty_bal: Bool) -> {M.amount_is_ok(M.correct_value_check_empty_bal(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, False{}, frac_digits, empty_bal)) == False{} : Bool}:
  match empty_bal:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.correct_value_parse_error_rejected(val, max_val, dec, min_val, can_eq_min, can_be_blank, frac_digits):
  check_empty_parse_err(val, max_val, dec, min_val, can_eq_min, can_be_blank, frac_digits, Bool.and(Nat.is_eq(max_val, 0n), Bool.or(Bool.not(can_eq_min), Nat.is_gt(min_val, 0n))))

def check_empty_too_many(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, parse_ok: Bool, +frac_digits: Nat, empty_bal: Bool, e: {Nat.is_gt(frac_digits, dec) == True{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_empty_bal(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits, empty_bal)) == False{} : Bool}:
  match parse_ok empty_bal:
    case _ True{}:
      {==}
    case False{} False{}:
      {==}
    case True{} False{}:
      %Equal.sym(Bool, Nat.is_gt(frac_digits, dec), True{}, e) : {M.amount_is_ok(M.correct_value_check_frac(val, max_val, min_val, can_eq_min, _)) == False{} : Bool}
      {==}

def Laws.correct_value_too_many_decimals_rejected(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, e):
  check_empty_too_many(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, Bool.and(Nat.is_eq(max_val, 0n), Bool.or(Bool.not(can_eq_min), Nat.is_gt(min_val, 0n))), e)

def correct_value_check_frac_when_max_lt_min(+val: Nat, +max_val: Nat, +min_val: Nat, +can_eq_min: Bool, too_many: Bool, e: {Nat.is_lt(max_val, min_val) == True{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_frac(val, max_val, min_val, can_eq_min, too_many)) == False{} : Bool}:
  match too_many:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_lt(max_val, min_val), True{}, e) : {M.amount_is_ok(M.correct_value_check_bounds(val, max_val, min_val, can_eq_min, _)) == False{} : Bool}
      {==}

def check_empty_max_lt_min(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, parse_ok: Bool, +frac_digits: Nat, empty_bal: Bool, e: {Nat.is_lt(max_val, min_val) == True{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_empty_bal(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits, empty_bal)) == False{} : Bool}:
  match parse_ok empty_bal:
    case _ True{}:
      {==}
    case False{} False{}:
      {==}
    case True{} False{}:
      correct_value_check_frac_when_max_lt_min(val, max_val, min_val, can_eq_min, Nat.is_gt(frac_digits, dec), e)

def Laws.correct_value_max_below_min_rejected(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, e):
  check_empty_max_lt_min(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, Bool.and(Nat.is_eq(max_val, 0n), Bool.or(Bool.not(can_eq_min), Nat.is_gt(min_val, 0n))), e)

def not_eq_true_is_false(+x: Bool, e: {Bool.not(x) == True{} : Bool}) -> {x == False{} : Bool}:
  match x:
    case False{}:
      {==}
    case True{}:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(e))

def gt_implies_le_false(+a: Nat, +b: Nat, e: {Nat.is_gt(a, b) == True{} : Bool}) -> {Nat.is_le(a, b) == False{} : Bool}:
  not_eq_true_is_false(Nat.is_le(a, b),
    Equal.trans(Bool, Bool.not(Nat.is_le(a, b)), Nat.is_gt(a, b), True{}, NatL.not_le_is_gt(a, b), e))

def correct_value_check_bounds_when_le_false(+val: Nat, +max_val: Nat, +min_val: Nat, +can_eq_min: Bool, max_lt_min: Bool, e_le: {Nat.is_le(val, max_val) == False{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_bounds(val, max_val, min_val, can_eq_min, max_lt_min)) == False{} : Bool}:
  match max_lt_min:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_le(val, max_val), False{}, e_le) : {M.amount_is_ok(M.amount_range_check(Bool.and(M.amount_lower_ok(val, min_val, can_eq_min), _))) == False{} : Bool}
      %Equal.sym(Bool, Bool.and(M.amount_lower_ok(val, min_val, can_eq_min), False{}), False{}, NatL.and_false_right(M.amount_lower_ok(val, min_val, can_eq_min))) : {M.amount_is_ok(M.amount_range_check(_)) == False{} : Bool}
      {==}

def correct_value_check_frac_when_le_false(+val: Nat, +max_val: Nat, +min_val: Nat, +can_eq_min: Bool, too_many: Bool, e_le: {Nat.is_le(val, max_val) == False{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_frac(val, max_val, min_val, can_eq_min, too_many)) == False{} : Bool}:
  match too_many:
    case True{}:
      {==}
    case False{}:
      correct_value_check_bounds_when_le_false(val, max_val, min_val, can_eq_min, Nat.is_lt(max_val, min_val), e_le)

def check_empty_le_false(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, parse_ok: Bool, +frac_digits: Nat, empty_bal: Bool, e_le: {Nat.is_le(val, max_val) == False{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_empty_bal(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits, empty_bal)) == False{} : Bool}:
  match parse_ok empty_bal:
    case _ True{}:
      {==}
    case False{} False{}:
      {==}
    case True{} False{}:
      correct_value_check_frac_when_le_false(val, max_val, min_val, can_eq_min, Nat.is_gt(frac_digits, dec), e_le)

def Laws.correct_value_gt_max_rejected(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, e):
  check_empty_le_false(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, Bool.and(Nat.is_eq(max_val, 0n), Bool.or(Bool.not(can_eq_min), Nat.is_gt(min_val, 0n))), gt_implies_le_false(val, max_val, e))

def lt_implies_lower_false(+val: Nat, +min_val: Nat, can_eq_min: Bool, e: {Nat.is_lt(val, min_val) == True{} : Bool}) -> {M.amount_lower_ok(val, min_val, can_eq_min) == False{} : Bool}:
  match can_eq_min:
    case True{}:
      not_eq_true_is_false(Nat.is_le(min_val, val),
        Equal.trans(Bool, Bool.not(Nat.is_le(min_val, val)), Nat.is_gt(min_val, val), True{},
          NatL.not_le_is_gt(min_val, val),
          Equal.trans(Bool, Nat.is_gt(min_val, val), Nat.is_lt(val, min_val), True{},
            NatL.is_gt_as_lt(min_val, val), e)))
    case False{}:
      not_eq_true_is_false(Nat.is_lt(min_val, val),
        Equal.trans(Bool, Bool.not(Nat.is_lt(min_val, val)), Nat.is_ge(min_val, val), True{},
          NatL.not_lt_is_ge(min_val, val),
          Equal.trans(Bool, Nat.is_ge(min_val, val), Nat.is_le(val, min_val), True{},
            NatL.is_ge_as_le(min_val, val),
            NatL.lt_implies_le(val, min_val, e))))

def correct_value_check_bounds_when_lower_false(+val: Nat, +max_val: Nat, +min_val: Nat, +can_eq_min: Bool, max_lt_min: Bool, e_lo: {M.amount_lower_ok(val, min_val, can_eq_min) == False{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_bounds(val, max_val, min_val, can_eq_min, max_lt_min)) == False{} : Bool}:
  match max_lt_min:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, M.amount_lower_ok(val, min_val, can_eq_min), False{}, e_lo) : {M.amount_is_ok(M.amount_range_check(Bool.and(_, Nat.is_le(val, max_val)))) == False{} : Bool}
      {==}

def correct_value_check_frac_when_lower_false(+val: Nat, +max_val: Nat, +min_val: Nat, +can_eq_min: Bool, too_many: Bool, e_lo: {M.amount_lower_ok(val, min_val, can_eq_min) == False{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_frac(val, max_val, min_val, can_eq_min, too_many)) == False{} : Bool}:
  match too_many:
    case True{}:
      {==}
    case False{}:
      correct_value_check_bounds_when_lower_false(val, max_val, min_val, can_eq_min, Nat.is_lt(max_val, min_val), e_lo)

def check_empty_lower_false(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, parse_ok: Bool, +frac_digits: Nat, empty_bal: Bool, e_lo: {M.amount_lower_ok(val, min_val, can_eq_min) == False{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_empty_bal(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits, empty_bal)) == False{} : Bool}:
  match parse_ok empty_bal:
    case _ True{}:
      {==}
    case False{} False{}:
      {==}
    case True{} False{}:
      correct_value_check_frac_when_lower_false(val, max_val, min_val, can_eq_min, Nat.is_gt(frac_digits, dec), e_lo)

def Laws.correct_value_lt_min_rejected(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, e):
  check_empty_lower_false(val, max_val, dec, min_val, can_eq_min, can_be_blank, parse_ok, frac_digits, Bool.and(Nat.is_eq(max_val, 0n), Bool.or(Bool.not(can_eq_min), Nat.is_gt(min_val, 0n))), lt_implies_lower_false(val, min_val, can_eq_min, e))

def le_implies_gt_false(+a: Nat, +b: Nat, e: {Nat.is_le(a, b) == True{} : Bool}) -> {Nat.is_gt(a, b) == False{} : Bool}:
  %NatL.not_le_is_gt(a, b) : {_ == False{} : Bool}
  %Equal.sym(Bool, Nat.is_le(a, b), True{}, e) : {Bool.not(_) == False{} : Bool}
  {==}

def le_implies_lt_rev_false(+a: Nat, +b: Nat, e: {Nat.is_le(a, b) == True{} : Bool}) -> {Nat.is_lt(b, a) == False{} : Bool}:
  %NatL.is_gt_as_lt(a, b) : {_ == False{} : Bool}
  le_implies_gt_false(a, b, e)

def dup3_bool_true(+x: Bool, e: {x == True{} : Bool}) -> {x == True{} : Bool} & ({x == True{} : Bool} & {x == True{} : Bool}):
  match x:
    case True{}:
      ({==}, ({==}, {==}))
    case False{}:
      Empty.absurd({False{} == True{} : Bool} & ({False{} == True{} : Bool} & {False{} == True{} : Bool}), NatL.false_is_not_true(e))

def le_implies_not_zero_max_pos_min(+min_val: Nat, +max_val: Nat, eb: {Nat.is_le(min_val, max_val) == True{} : Bool}) -> {Bool.and(Nat.is_eq(max_val, 0n), Nat.is_gt(min_val, 0n)) == False{} : Bool}:
  match min_val max_val:
    case 0n 0n:
      {==}
    case 0n 1n+_:
      {==}
    case 1n+mnp 0n:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(eb))
    case 1n+_ 1n+_:
      {==}

def at_min_false_empty(+max_val: Nat, +dec: Nat, +min_val: Nat, can_be_blank: Bool, +frac_digits: Nat, empty_bal: Bool, e_frac: {Nat.is_le(frac_digits, dec) == True{} : Bool}, e_bounds: {Nat.is_le(min_val, max_val) == True{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_empty_bal(min_val, max_val, dec, min_val, False{}, can_be_blank, False{}, True{}, frac_digits, empty_bal)) == False{} : Bool}:
  match empty_bal:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_gt(frac_digits, dec), False{}, le_implies_gt_false(frac_digits, dec, e_frac)) : {M.amount_is_ok(M.correct_value_check_frac(min_val, max_val, min_val, False{}, _)) == False{} : Bool}
      %Equal.sym(Bool, Nat.is_lt(max_val, min_val), False{}, le_implies_lt_rev_false(min_val, max_val, e_bounds)) : {M.amount_is_ok(M.correct_value_check_bounds(min_val, max_val, min_val, False{}, _)) == False{} : Bool}
      %Equal.sym(Bool, Nat.is_lt(min_val, min_val), False{}, NatL.is_lt_irrefl(min_val)) : {M.amount_is_ok(M.amount_range_check(Bool.and(_, Nat.is_le(min_val, max_val)))) == False{} : Bool}
      {==}

def at_min_true_pair(+max_val: Nat, +dec: Nat, +min_val: Nat, can_be_blank: Bool, +frac_digits: Nat, e_frac: {Nat.is_le(frac_digits, dec) == True{} : Bool}, ebs: {Nat.is_le(min_val, max_val) == True{} : Bool} & ({Nat.is_le(min_val, max_val) == True{} : Bool} & {Nat.is_le(min_val, max_val) == True{} : Bool})) -> {M.amount_is_ok(M.correct_value(min_val, max_val, dec, min_val, True{}, can_be_blank, False{}, True{}, frac_digits)) == True{} : Bool}:
  (eb0, rest) = ebs
  (eb1, eb2) = rest
  %Equal.sym(Bool, Bool.and(Nat.is_eq(max_val, 0n), Nat.is_gt(min_val, 0n)), False{}, le_implies_not_zero_max_pos_min(min_val, max_val, eb0)) : {M.amount_is_ok(M.correct_value_check_empty_bal(min_val, max_val, dec, min_val, True{}, can_be_blank, False{}, True{}, frac_digits, _)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_gt(frac_digits, dec), False{}, le_implies_gt_false(frac_digits, dec, e_frac)) : {M.amount_is_ok(M.correct_value_check_frac(min_val, max_val, min_val, True{}, _)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_lt(max_val, min_val), False{}, le_implies_lt_rev_false(min_val, max_val, eb1)) : {M.amount_is_ok(M.correct_value_check_bounds(min_val, max_val, min_val, True{}, _)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(min_val, min_val), True{}, NatL.is_le_refl(min_val)) : {M.amount_is_ok(M.amount_range_check(Bool.and(_, Nat.is_le(min_val, max_val)))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(min_val, max_val), True{}, eb2) : {M.amount_is_ok(M.amount_range_check(_)) == True{} : Bool}
  {==}

def Laws.correct_value_at_min_iff(max_val, dec, min_val, can_eq_min, can_be_blank, frac_digits, e_frac, e_bounds):
  match can_eq_min:
    case True{}:
      at_min_true_pair(max_val, dec, min_val, can_be_blank, frac_digits, e_frac, dup3_bool_true(Nat.is_le(min_val, max_val), e_bounds))
    case False{}:
      at_min_false_empty(max_val, dec, min_val, can_be_blank, frac_digits, Bool.and(Nat.is_eq(max_val, 0n), True{}), e_frac, e_bounds)

def lt_zero_max_impossible(+min_val: Nat) -> {Nat.is_lt(min_val, 0n) == False{} : Bool}:
  match min_val:
    case 0n:
      {==}
    case 1n+p:
      {==}

def range_check_is_ok_id(b: Bool) -> {M.amount_is_ok(M.amount_range_check(b)) == b : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def correct_value_at_max_false_branch(+max_val: Nat, +dec: Nat, +min_val: Nat, can_be_blank: Bool, +frac_digits: Nat, e_frac: {Nat.is_le(frac_digits, dec) == True{} : Bool}, e_bounds: {Nat.is_le(min_val, max_val) == True{} : Bool}) -> {M.amount_is_ok(M.correct_value_check_empty_bal(max_val, max_val, dec, min_val, False{}, can_be_blank, False{}, True{}, frac_digits, Nat.is_eq(max_val, 0n))) == Nat.is_lt(min_val, max_val) : Bool}:
  match max_val:
    case 0n:
      Equal.sym(Bool, Nat.is_lt(min_val, 0n), False{}, lt_zero_max_impossible(min_val))
    case 1n+mp:
      %Equal.sym(Bool, Nat.is_gt(frac_digits, dec), False{}, le_implies_gt_false(frac_digits, dec, e_frac)) : {M.amount_is_ok(M.correct_value_check_frac(1n+mp, 1n+mp, min_val, False{}, _)) == Nat.is_lt(min_val, 1n+mp) : Bool}
      %Equal.sym(Bool, Nat.is_lt(1n+mp, min_val), False{}, le_implies_lt_rev_false(min_val, 1n+mp, e_bounds)) : {M.amount_is_ok(M.correct_value_check_bounds(1n+mp, 1n+mp, min_val, False{}, _)) == Nat.is_lt(min_val, 1n+mp) : Bool}
      %Equal.sym(Bool, Nat.is_le(1n+mp, 1n+mp), True{}, NatL.is_le_refl(1n+mp)) : {M.amount_is_ok(M.amount_range_check(Bool.and(Nat.is_lt(min_val, 1n+mp), _))) == Nat.is_lt(min_val, 1n+mp) : Bool}
      %Equal.sym(Bool, Bool.and(Nat.is_lt(min_val, 1n+mp), True{}), Nat.is_lt(min_val, 1n+mp), NatL.and_true_right(Nat.is_lt(min_val, 1n+mp))) : {M.amount_is_ok(M.amount_range_check(_)) == Nat.is_lt(min_val, 1n+mp) : Bool}
      range_check_is_ok_id(Nat.is_lt(min_val, 1n+mp))

def at_max_true_pair(+max_val: Nat, +dec: Nat, +min_val: Nat, can_be_blank: Bool, +frac_digits: Nat, e_frac: {Nat.is_le(frac_digits, dec) == True{} : Bool}, ebs: {Nat.is_le(min_val, max_val) == True{} : Bool} & ({Nat.is_le(min_val, max_val) == True{} : Bool} & {Nat.is_le(min_val, max_val) == True{} : Bool})) -> {M.amount_is_ok(M.correct_value(max_val, max_val, dec, min_val, True{}, can_be_blank, False{}, True{}, frac_digits)) == True{} : Bool}:
  (eb0, rest) = ebs
  (eb1, eb2) = rest
  %Equal.sym(Bool, Bool.and(Nat.is_eq(max_val, 0n), Nat.is_gt(min_val, 0n)), False{}, le_implies_not_zero_max_pos_min(min_val, max_val, eb0)) : {M.amount_is_ok(M.correct_value_check_empty_bal(max_val, max_val, dec, min_val, True{}, can_be_blank, False{}, True{}, frac_digits, _)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_gt(frac_digits, dec), False{}, le_implies_gt_false(frac_digits, dec, e_frac)) : {M.amount_is_ok(M.correct_value_check_frac(max_val, max_val, min_val, True{}, _)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_lt(max_val, min_val), False{}, le_implies_lt_rev_false(min_val, max_val, eb1)) : {M.amount_is_ok(M.correct_value_check_bounds(max_val, max_val, min_val, True{}, _)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(min_val, max_val), True{}, eb2) : {M.amount_is_ok(M.amount_range_check(Bool.and(_, Nat.is_le(max_val, max_val)))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_le(max_val, max_val), True{}, NatL.is_le_refl(max_val)) : {M.amount_is_ok(M.amount_range_check(_)) == True{} : Bool}
  {==}

def Laws.correct_value_at_max_iff(max_val, dec, min_val, can_eq_min, can_be_blank, frac_digits, e_frac, e_bounds):
  match can_eq_min:
    case True{}:
      at_max_true_pair(max_val, dec, min_val, can_be_blank, frac_digits, e_frac, dup3_bool_true(Nat.is_le(min_val, max_val), e_bounds))
    case False{}:
      %Equal.sym(Bool, Bool.and(Nat.is_eq(max_val, 0n), True{}), Nat.is_eq(max_val, 0n), NatL.and_true_right(Nat.is_eq(max_val, 0n))) : {M.amount_is_ok(M.correct_value_check_empty_bal(max_val, max_val, dec, min_val, False{}, can_be_blank, False{}, True{}, frac_digits, _)) == Nat.is_lt(min_val, max_val) : Bool}
      correct_value_at_max_false_branch(max_val, dec, min_val, can_be_blank, frac_digits, e_frac, e_bounds)

# 4. Asset sort comparator proofs
# -------------------------------

def Laws.asset_cmp_irrefl(x):
  match x:
    case M.Znn{}:
      {==}
    case M.Qsr{}:
      {==}
    case M.Zts{id}:
      {==}

def Laws.asset_cmp_antisym(a, b):
  match a b:
    case M.Znn{} M.Znn{}:
      {==}
    case M.Znn{} M.Qsr{}:
      {==}
    case M.Znn{} M.Zts{_}:
      {==}
    case M.Qsr{} M.Znn{}:
      {==}
    case M.Qsr{} M.Qsr{}:
      {==}
    case M.Qsr{} M.Zts{_}:
      {==}
    case M.Zts{_} M.Znn{}:
      {==}
    case M.Zts{_} M.Qsr{}:
      {==}
    case M.Zts{_} M.Zts{_}:
      {==}

def Laws.asset_cmp_trans(a, b, c, ab, bc):
  match a b c:
    case M.Znn{} _ M.Znn{}:
      {==}
    case M.Znn{} _ M.Qsr{}:
      {==}
    case M.Znn{} _ M.Zts{_}:
      {==}
    case M.Qsr{} M.Znn{} _:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Qsr{}, c)) == True{} : Bool}, NatL.false_is_not_true(ab))
    case M.Qsr{} M.Qsr{} M.Znn{}:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Qsr{}, M.Znn{})) == True{} : Bool}, NatL.false_is_not_true(bc))
    case M.Qsr{} M.Qsr{} M.Qsr{}:
      {==}
    case M.Qsr{} M.Qsr{} M.Zts{_}:
      {==}
    case M.Qsr{} M.Zts{_} M.Znn{}:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Qsr{}, M.Znn{})) == True{} : Bool}, NatL.false_is_not_true(bc))
    case M.Qsr{} M.Zts{_} M.Qsr{}:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Qsr{}, M.Qsr{})) == True{} : Bool}, NatL.false_is_not_true(bc))
    case M.Qsr{} M.Zts{_} M.Zts{_}:
      {==}
    case M.Zts{id} M.Znn{} _:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Zts{id}, c)) == True{} : Bool}, NatL.false_is_not_true(ab))
    case M.Zts{id} M.Qsr{} _:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Zts{id}, c)) == True{} : Bool}, NatL.false_is_not_true(ab))
    case M.Zts{id} M.Zts{_} M.Znn{}:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Zts{id}, M.Znn{})) == True{} : Bool}, NatL.false_is_not_true(bc))
    case M.Zts{id} M.Zts{_} M.Qsr{}:
      Empty.absurd({Cmp.is_le(M.asset_cmp(M.Zts{id}, M.Qsr{})) == True{} : Bool}, NatL.false_is_not_true(bc))
    case M.Zts{_} M.Zts{_} M.Zts{_}:
      {==}

def Laws.asset_order_hierarchy(id):
  {==}

# 5. Plasma 4-tier classifier proofs (exact U32 order transitivity via Word.cmp)
# ------------------------------------------------------------------------------

def cmp_trans_ok(c1: Cmp, c2: Cmp, c3: Cmp) -> Bool:
  match c1:
    case GT{}:
      True{}
    case LT{}:
      match c2:
        case GT{}:
          True{}
        case LT{}:
          match c3:
            case LT{}:
              True{}
            case _:
              False{}
        case EQ{}:
          match c3:
            case LT{}:
              True{}
            case _:
              False{}
    case EQ{}:
      match c2:
        case GT{}:
          True{}
        case LT{}:
          match c3:
            case LT{}:
              True{}
            case _:
              False{}
        case EQ{}:
          match c3:
            case EQ{}:
              True{}
            case _:
              False{}

def word_cmp_trans_step(t1: Cmp, t2: Cmp, t3: Cmp, ab: Bool, bb: Bool, cb: Bool, h: {cmp_trans_ok(t1, t2, t3) == True{} : Bool}) -> {cmp_trans_ok(Word.cmp.fin(ab, bb, t1), Word.cmp.fin(bb, cb, t2), Word.cmp.fin(ab, cb, t3)) == True{} : Bool}:
  match t1 t2 t3:
    case LT{} LT{} LT{}:
      {==}
    case LT{} EQ{} LT{}:
      match bb cb:
        case False{} False{}:
          {==}
        case False{} True{}:
          {==}
        case True{} False{}:
          {==}
        case True{} True{}:
          {==}
    case EQ{} LT{} LT{}:
      match ab bb:
        case False{} False{}:
          {==}
        case False{} True{}:
          {==}
        case True{} False{}:
          {==}
        case True{} True{}:
          {==}
    case EQ{} EQ{} EQ{}:
      match ab bb cb:
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
    case LT{} GT{} _:
      {==}
    case GT{} _ _:
      {==}
    case EQ{} GT{} _:
      match ab bb:
        case False{} False{}:
          {==}
        case False{} True{}:
          {==}
        case True{} False{}:
          {==}
        case True{} True{}:
          {==}
    case LT{} LT{} EQ{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, LT{}), Word.cmp.fin(bb, cb, LT{}), Word.cmp.fin(ab, cb, EQ{})) == True{} : Bool}, NatL.false_is_not_true(h))
    case LT{} LT{} GT{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, LT{}), Word.cmp.fin(bb, cb, LT{}), Word.cmp.fin(ab, cb, GT{})) == True{} : Bool}, NatL.false_is_not_true(h))
    case LT{} EQ{} EQ{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, LT{}), Word.cmp.fin(bb, cb, EQ{}), Word.cmp.fin(ab, cb, EQ{})) == True{} : Bool}, NatL.false_is_not_true(h))
    case LT{} EQ{} GT{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, LT{}), Word.cmp.fin(bb, cb, EQ{}), Word.cmp.fin(ab, cb, GT{})) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} LT{} EQ{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, EQ{}), Word.cmp.fin(bb, cb, LT{}), Word.cmp.fin(ab, cb, EQ{})) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} LT{} GT{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, EQ{}), Word.cmp.fin(bb, cb, LT{}), Word.cmp.fin(ab, cb, GT{})) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} EQ{} LT{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, EQ{}), Word.cmp.fin(bb, cb, EQ{}), Word.cmp.fin(ab, cb, LT{})) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} EQ{} GT{}:
      Empty.absurd({cmp_trans_ok(Word.cmp.fin(ab, bb, EQ{}), Word.cmp.fin(bb, cb, EQ{}), Word.cmp.fin(ab, cb, GT{})) == True{} : Bool}, NatL.false_is_not_true(h))

def word_cmp_trans(+n: Nat, +a: Word(n), +b: Word(n), +c: Word(n)) -> {cmp_trans_ok(Word.cmp(n, a, b), Word.cmp(n, b, c), Word.cmp(n, a, c)) == True{} : Bool}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      match a b c:
        case WCon{+ab, +at} WCon{+bb, +bt} WCon{+cb, +ct}:
          word_cmp_trans_step(Word.cmp(p, at, bt), Word.cmp(p, bt, ct), Word.cmp(p, at, ct), ab, bb, cb, word_cmp_trans(p, at, bt, ct))

def cmp_trans_to_le(c1: Cmp, c2: Cmp, c3: Cmp, h: {cmp_trans_ok(c1, c2, c3) == True{} : Bool}, e1: {Cmp.is_le(c1) == True{} : Bool}, e2: {Cmp.is_le(c2) == True{} : Bool}) -> {Cmp.is_le(c3) == True{} : Bool}:
  match c1 c2 c3:
    case LT{} LT{} LT{}:
      {==}
    case LT{} EQ{} LT{}:
      {==}
    case EQ{} LT{} LT{}:
      {==}
    case EQ{} EQ{} EQ{}:
      {==}
    case GT{} _ _:
      Empty.absurd({Cmp.is_le(c3) == True{} : Bool}, NatL.false_is_not_true(e1))
    case _ GT{} _:
      Empty.absurd({Cmp.is_le(c3) == True{} : Bool}, NatL.false_is_not_true(e2))
    case LT{} LT{} EQ{}:
      Empty.absurd({Cmp.is_le(EQ{}) == True{} : Bool}, NatL.false_is_not_true(h))
    case LT{} LT{} GT{}:
      Empty.absurd({Cmp.is_le(GT{}) == True{} : Bool}, NatL.false_is_not_true(h))
    case LT{} EQ{} EQ{}:
      Empty.absurd({Cmp.is_le(EQ{}) == True{} : Bool}, NatL.false_is_not_true(h))
    case LT{} EQ{} GT{}:
      Empty.absurd({Cmp.is_le(GT{}) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} LT{} EQ{}:
      Empty.absurd({Cmp.is_le(EQ{}) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} LT{} GT{}:
      Empty.absurd({Cmp.is_le(GT{}) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} EQ{} LT{}:
      Empty.absurd({Cmp.is_le(LT{}) == True{} : Bool}, NatL.false_is_not_true(h))
    case EQ{} EQ{} GT{}:
      Empty.absurd({Cmp.is_le(GT{}) == True{} : Bool}, NatL.false_is_not_true(h))

def u32_le_trans(+a: U32, +b: U32, +c: U32, ab: {U32.is_le(a, b) == True{} : Bool}, bc: {U32.is_le(b, c) == True{} : Bool}) -> {U32.is_le(a, c) == True{} : Bool}:
  match a b c:
    case U32{+wa} U32{+wb} U32{+wc}:
      cmp_trans_to_le(Word.cmp(32n, wa, wb), Word.cmp(32n, wb, wc), Word.cmp(32n, wa, wc), word_cmp_trans(32n, wa, wb, wc), ab, bc)

def word_cmp_flip_step(t: Cmp, ab: Bool, bb: Bool) -> {M.cmp_flip(Word.cmp.fin(ab, bb, t)) == Word.cmp.fin(bb, ab, M.cmp_flip(t)) : Cmp}:
  match t:
    case LT{}:
      {==}
    case GT{}:
      {==}
    case EQ{}:
      match ab bb:
        case False{} False{}:
          {==}
        case False{} True{}:
          {==}
        case True{} False{}:
          {==}
        case True{} True{}:
          {==}

def word_cmp_flip(+n: Nat, +a: Word(n), +b: Word(n)) -> {M.cmp_flip(Word.cmp(n, a, b)) == Word.cmp(n, b, a) : Cmp}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      match a b:
        case WCon{+ab, +at} WCon{+bb, +bt}:
          %word_cmp_flip(p, at, bt) : {M.cmp_flip(Word.cmp.fin(ab, bb, Word.cmp(p, at, bt))) == Word.cmp.fin(bb, ab, _) : Cmp}
          word_cmp_flip_step(Word.cmp(p, at, bt), ab, bb)

def cmp_is_ge_flip(c: Cmp) -> {Cmp.is_ge(c) == Cmp.is_le(M.cmp_flip(c)) : Bool}:
  match c:
    case LT{}:
      {==}
    case EQ{}:
      {==}
    case GT{}:
      {==}

def u32_ge_as_le(+a: U32, +b: U32) -> {U32.is_ge(a, b) == U32.is_le(b, a) : Bool}:
  match a b:
    case U32{+wa} U32{+wb}:
      %word_cmp_flip(32n, wa, wb) : {Cmp.is_ge(Word.cmp(32n, wa, wb)) == Cmp.is_le(_) : Bool}
      cmp_is_ge_flip(Word.cmp(32n, wa, wb))

def u32_ge_monotone(+p1: U32, +p2: U32, +thresh: U32, e_le: {U32.is_le(p1, p2) == True{} : Bool}, e_ge: {U32.is_ge(p1, thresh) == True{} : Bool}) -> {U32.is_ge(p2, thresh) == True{} : Bool}:
  %Equal.sym(Bool, U32.is_ge(p2, thresh), U32.is_le(thresh, p2), u32_ge_as_le(p2, thresh)) : {_ == True{} : Bool}
  u32_le_trans(thresh, p1, p2,
    Equal.trans(Bool, U32.is_le(thresh, p1), U32.is_ge(p1, thresh), True{},
      Equal.sym(Bool, U32.is_ge(p1, thresh), U32.is_le(thresh, p1), u32_ge_as_le(p1, thresh)), e_ge),
    e_le)

def plasma_rank_le_3(t: M.PlasmaTier) -> {Nat.is_le(M.plasma_tier_rank(t), 3n) == True{} : Bool}:
  match t:
    case M.PlasmaInsufficient{}:
      {==}
    case M.PlasmaLow{}:
      {==}
    case M.PlasmaAverage{}:
      {==}
    case M.PlasmaHigh{}:
      {==}

def plasma_low_rank_le_2(b: Bool) -> {Nat.is_le(M.plasma_tier_rank(M.plasma_tier_low(b)), 2n) == True{} : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def plasma_mono_low(+p1: U32, +p2: U32, e: {U32.is_le(p1, p2) == True{} : Bool}, l1: Bool, l2: Bool, el1: {U32.is_ge(p1, 21000) == l1 : Bool}, el2: {U32.is_ge(p2, 21000) == l2 : Bool}) -> {Nat.is_le(M.plasma_tier_rank(M.plasma_tier_low(l1)), M.plasma_tier_rank(M.plasma_tier_low(l2))) == True{} : Bool}:
  match l1 l2:
    case True{} True{}:
      {==}
    case True{} False{}:
      Empty.absurd({Nat.is_le(1n, 0n) == True{} : Bool},
        NatL.true_is_not_false(Equal.trans(Bool, True{}, U32.is_ge(p2, 21000), False{},
          Equal.sym(Bool, U32.is_ge(p2, 21000), True{}, u32_ge_monotone(p1, p2, 21000, e, el1)), el2)))
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

def plasma_mono_avg(+p1: U32, +p2: U32, e: {U32.is_le(p1, p2) == True{} : Bool}, a1: Bool, a2: Bool, ea1: {U32.is_ge(p1, 189000) == a1 : Bool}, ea2: {U32.is_ge(p2, 189000) == a2 : Bool}) -> {Nat.is_le(M.plasma_tier_rank(M.plasma_tier_avg(p1, a1)), M.plasma_tier_rank(M.plasma_tier_avg(p2, a2))) == True{} : Bool}:
  match a1 a2:
    case True{} True{}:
      {==}
    case True{} False{}:
      Empty.absurd({Nat.is_le(2n, M.plasma_tier_rank(M.plasma_tier_low(U32.is_ge(p2, 21000)))) == True{} : Bool},
        NatL.true_is_not_false(Equal.trans(Bool, True{}, U32.is_ge(p2, 189000), False{},
          Equal.sym(Bool, U32.is_ge(p2, 189000), True{}, u32_ge_monotone(p1, p2, 189000, e, ea1)), ea2)))
    case False{} True{}:
      plasma_low_rank_le_2(U32.is_ge(p1, 21000))
    case False{} False{}:
      plasma_mono_low(p1, p2, e, U32.is_ge(p1, 21000), U32.is_ge(p2, 21000), {==}, {==})

def plasma_mono_high(+p1: U32, +p2: U32, e: {U32.is_le(p1, p2) == True{} : Bool}, h1: Bool, h2: Bool, eh1: {U32.is_ge(p1, 252000) == h1 : Bool}, eh2: {U32.is_ge(p2, 252000) == h2 : Bool}) -> {Nat.is_le(M.plasma_tier_rank(M.plasma_tier_high(p1, h1)), M.plasma_tier_rank(M.plasma_tier_high(p2, h2))) == True{} : Bool}:
  match h1 h2:
    case True{} True{}:
      {==}
    case True{} False{}:
      Empty.absurd({Nat.is_le(3n, M.plasma_tier_rank(M.plasma_tier_avg(p2, U32.is_ge(p2, 189000)))) == True{} : Bool},
        NatL.true_is_not_false(Equal.trans(Bool, True{}, U32.is_ge(p2, 252000), False{},
          Equal.sym(Bool, U32.is_ge(p2, 252000), True{}, u32_ge_monotone(p1, p2, 252000, e, eh1)), eh2)))
    case False{} True{}:
      plasma_rank_le_3(M.plasma_tier_avg(p1, U32.is_ge(p1, 189000)))
    case False{} False{}:
      plasma_mono_avg(p1, p2, e, U32.is_ge(p1, 189000), U32.is_ge(p2, 189000), {==}, {==})

def Laws.plasma_tier_monotone(p1, p2, e):
  plasma_mono_high(p1, p2, e, U32.is_ge(p1, 252000), U32.is_ge(p2, 252000), {==}, {==})

def Laws.plasma_tier_exact_boundaries():
  {==}

def color_tooltip_biject_tier(t: M.PlasmaTier) -> {(M.color_to_tooltip(M.plasma_color_from_tier(t)), M.tooltip_to_color(M.plasma_tooltip_from_tier(t))) == (M.plasma_tooltip_from_tier(t), M.plasma_color_from_tier(t)) : M.PlasmaTooltip & M.PlasmaColor}:
  match t:
    case M.PlasmaInsufficient{}:
      {==}
    case M.PlasmaLow{}:
      {==}
    case M.PlasmaAverage{}:
      {==}
    case M.PlasmaHigh{}:
      {==}

def Laws.plasma_color_tooltip_agreement(p):
  color_tooltip_biject_tier(M.plasma_tier(p))

# 6. Password strength & matching proofs
# --------------------------------------

def Laws.password_invalid_never_medium_or_strong(len, u, l, d, s, e):
  match len:
    case 0n:
      {==}
    case 1n+p:
      %Equal.sym(Bool, M.password_is_valid(1n+p, u, l, d, s), False{}, e) : {Nat.is_le(M.password_strength_rank(M.password_strength_checked(1n+p, _)), 1n) == True{} : Bool}
      {==}

def nat_ge_monotone(+a: Nat, +b: Nat, +k: Nat, ab: {Nat.is_le(a, b) == True{} : Bool}, ge_a: {Nat.is_ge(a, k) == True{} : Bool}) -> {Nat.is_ge(b, k) == True{} : Bool}:
  %Equal.sym(Bool, Nat.is_ge(b, k), Nat.is_le(k, b), NatL.is_ge_as_le(b, k)) : {_ == True{} : Bool}
  NatL.le_trans(k, a, b,
    Equal.trans(Bool, Nat.is_le(k, a), Nat.is_ge(a, k), True{},
      Equal.sym(Bool, Nat.is_ge(a, k), Nat.is_le(k, a), NatL.is_ge_as_le(a, k)), ge_a),
    ab)

def pw_valid_all_true(+len: Nat) -> {M.password_is_valid(len, True{}, True{}, True{}, True{}) == Nat.is_ge(len, 8n) : Bool}:
  NatL.and_true_right(Nat.is_ge(len, 8n))

def pw_valid_rank_ge_1(b: Bool) -> {Nat.is_le(1n, M.password_strength_rank(M.password_strength_valid_len(b))) == True{} : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def pw_mono_strong(+p1: Nat, +p2: Nat, e: {Nat.is_le(1n+p1, 1n+p2) == True{} : Bool}, s1: Bool, s2: Bool, es1: {Nat.is_ge(1n+p1, 16n) == s1 : Bool}, es2: {Nat.is_ge(1n+p2, 16n) == s2 : Bool}) -> {Nat.is_le(M.password_strength_rank(M.password_strength_valid_len(s1)), M.password_strength_rank(M.password_strength_valid_len(s2))) == True{} : Bool}:
  match s1 s2:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} True{}:
      {==}
    case True{} False{}:
      Empty.absurd({Nat.is_le(3n, 2n) == True{} : Bool},
        NatL.true_is_not_false(Equal.trans(Bool, True{}, Nat.is_ge(1n+p2, 16n), False{},
          Equal.sym(Bool, Nat.is_ge(1n+p2, 16n), True{}, nat_ge_monotone(1n+p1, 1n+p2, 16n, e, es1)), es2)))

def pw_mono_helper(+p1: Nat, +p2: Nat, e: {Nat.is_le(1n+p1, 1n+p2) == True{} : Bool}, v1: Bool, v2: Bool, ev1: {Nat.is_ge(1n+p1, 8n) == v1 : Bool}, ev2: {Nat.is_ge(1n+p2, 8n) == v2 : Bool}) -> {Nat.is_le(M.password_strength_rank(M.password_strength_checked(1n+p1, v1)), M.password_strength_rank(M.password_strength_checked(1n+p2, v2))) == True{} : Bool}:
  match v1 v2:
    case False{} False{}:
      {==}
    case False{} True{}:
      pw_valid_rank_ge_1(Nat.is_ge(1n+p2, 16n))
    case True{} False{}:
      Empty.absurd({Nat.is_le(M.password_strength_rank(M.password_strength_valid_len(Nat.is_ge(1n+p1, 16n))), 1n) == True{} : Bool},
        NatL.true_is_not_false(Equal.trans(Bool, True{}, Nat.is_ge(1n+p2, 8n), False{},
          Equal.sym(Bool, Nat.is_ge(1n+p2, 8n), True{}, nat_ge_monotone(1n+p1, 1n+p2, 8n, e, ev1)), ev2)))
    case True{} True{}:
      pw_mono_strong(p1, p2, e, Nat.is_ge(1n+p1, 16n), Nat.is_ge(1n+p2, 16n), {==}, {==})

def Laws.password_strength_monotone_valid(len1, len2, e):
  match len1 len2:
    case 0n _:
      NatL.is_le_zero(M.password_strength_rank(M.password_strength(len2, True{}, True{}, True{}, True{})))
    case 1n+p1 0n:
      Empty.absurd({Nat.is_le(M.password_strength_rank(M.password_strength(1n+p1, True{}, True{}, True{}, True{})), 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 1n+p1 1n+p2:
      %Equal.sym(Bool, M.password_is_valid(1n+p1, True{}, True{}, True{}, True{}), Nat.is_ge(1n+p1, 8n), pw_valid_all_true(1n+p1)) : {Nat.is_le(M.password_strength_rank(M.password_strength_checked(1n+p1, _)), M.password_strength_rank(M.password_strength_checked(1n+p2, M.password_is_valid(1n+p2, True{}, True{}, True{}, True{})))) == True{} : Bool}
      %Equal.sym(Bool, M.password_is_valid(1n+p2, True{}, True{}, True{}, True{}), Nat.is_ge(1n+p2, 8n), pw_valid_all_true(1n+p2)) : {Nat.is_le(M.password_strength_rank(M.password_strength_checked(1n+p1, Nat.is_ge(1n+p1, 8n))), M.password_strength_rank(M.password_strength_checked(1n+p2, _))) == True{} : Bool}
      pw_mono_helper(p1, p2, e, Nat.is_ge(1n+p1, 8n), Nat.is_ge(1n+p2, 8n), {==}, {==})

def Laws.password_match_refl(a):
  match a:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      %Equal.sym(Bool, Nat.is_eq(h, h), True{}, NatL.is_eq_same(h)) : {Bool.and(_, M.password_match(t, t)) == True{} : Bool}
      Laws.password_match_refl(t)

def cons_eq(+ah: Nat, +bh: Nat, +at: List<&2, Nat>, +bt: List<&2, Nat>, eh: {ah == bh : Nat}, et: {at == bt : List<&2, Nat>}) -> {Con{ah, at} == Con{bh, bt} : List<&2, Nat>}:
  %eh : {Con{ah, at} == Con{_, bt} : List<&2, Nat>}
  %et : {Con{ah, at} == Con{ah, _} : List<&2, Nat>}
  {==}

def split_and_true_k(+x: Bool, +y: Bool, e: {Bool.and(x, y) == True{} : Bool}, P: Type, k: {x == True{} : Bool} -> {y == True{} : Bool} -> P) -> P:
  match x y:
    case True{} True{}:
      k({==}, {==})
    case False{} _:
      Empty.absurd(P, NatL.false_is_not_true(e))
    case True{} False{}:
      Empty.absurd(P, NatL.false_is_not_true(e))

def Laws.password_match_sound(a, b, e):
  match a b:
    case Nil{} Nil{}:
      {==}
    case Nil{} Con{bh, bt}:
      Empty.absurd({Nil{} == Con{bh, bt} : List<&2, Nat>}, NatL.false_is_not_true(e))
    case Con{ah, at} Nil{}:
      Empty.absurd({Con{ah, at} == Nil{} : List<&2, Nat>}, NatL.false_is_not_true(e))
    case Con{+ah, +at} Con{+bh, +bt}:
      split_and_true_k(Nat.is_eq(ah, bh), M.password_match(at, bt), e, {Con{ah, at} == Con{bh, bt} : List<&2, Nat>},
        e1 => e2 => cons_eq(ah, bh, at, bt, NatL.is_eq_sound(ah, bh, e1), Laws.password_match_sound(at, bt, e2)))

# 7. UI-edge guard proofs
# -----------------------

def Laws.exchange_rate_zero_guard(from_amt, to_amt):
  match from_amt:
    case 0n:
      {==}
    case 1n+p:
      {==}

def Laws.exchange_rate_positive_defined(a, b):
  {==}

def resolve_max_clamp_helper(+cur: Nat, +max_bal: Nat, eq: Bool, e_eq: {Nat.is_eq(cur, max_bal) == eq : Bool}) -> {M.apply_max_update(cur, M.resolve_max_update_eq(max_bal, eq)) == max_bal : Nat}:
  match eq:
    case True{}:
      NatL.is_eq_sound(cur, max_bal, e_eq)
    case False{}:
      {==}

def Laws.resolve_max_always_clamps(cur, max_bal):
  resolve_max_clamp_helper(cur, max_bal, Nat.is_eq(cur, max_bal), {==})

def Laws.resolve_max_update_noop_iff_equal(cur, max_bal, e_neq):
  %Equal.sym(Bool, Nat.is_eq(max_bal, max_bal), True{}, NatL.is_eq_same(max_bal)) : {(Some{max_bal}, (M.resolve_max_update_eq(max_bal, _), M.resolve_max_update_eq(max_bal, Nat.is_eq(cur, max_bal)))) == (Some{max_bal}, (None{}, Some{max_bal})) : Maybe<&2, Nat> & (Maybe<&2, Nat> & Maybe<&2, Nat>)}
  %Equal.sym(Bool, Nat.is_eq(cur, max_bal), False{}, e_neq) : {(Some{max_bal}, (None{}, M.resolve_max_update_eq(max_bal, _))) == (Some{max_bal}, (None{}, Some{max_bal})) : Maybe<&2, Nat> & (Maybe<&2, Nat> & Maybe<&2, Nat>)}
  {==}

def label_ok_helper(too_long: Bool, is_dup: Bool) -> {M.label_is_ok(M.validate_label_len(too_long, is_dup)) == Bool.and(Bool.not(too_long), Bool.not(is_dup)) : Bool}:
  match too_long is_dup:
    case True{} True{}:
      {==}
    case True{} False{}:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

def ge_zero_true(+p: Nat) -> {Nat.is_ge(p, 0n) == True{} : Bool}:
  match p:
    case 0n:
      {==}
    case 1n+_:
      {==}

def Laws.address_label_validation_iff(len, is_dup):
  match len:
    case 0n:
      {==}
    case 1n+p:
      %Equal.sym(Bool, Nat.is_ge(p, 0n), True{}, ge_zero_true(p)) : {M.label_is_ok(M.validate_label_len(Nat.is_gt(1n+p, 80n), is_dup)) == Bool.and(_, Bool.and(Nat.is_le(1n+p, 80n), Bool.not(is_dup))) : Bool}
      %NatL.not_le_is_gt(1n+p, 80n) : {M.label_is_ok(M.validate_label_len(_, is_dup)) == Bool.and(Nat.is_le(1n+p, 80n), Bool.not(is_dup)) : Bool}
      %Equal.sym(Bool, M.label_is_ok(M.validate_label_len(Bool.not(Nat.is_le(1n+p, 80n)), is_dup)), Bool.and(Bool.not(Bool.not(Nat.is_le(1n+p, 80n))), Bool.not(is_dup)), label_ok_helper(Bool.not(Nat.is_le(1n+p, 80n)), is_dup)) : {_ == Bool.and(Nat.is_le(1n+p, 80n), Bool.not(is_dup)) : Bool}
      %NatL.not_not(Nat.is_le(1n+p, 80n)) : {Bool.and(Bool.not(Bool.not(Nat.is_le(1n+p, 80n))), Bool.not(is_dup)) == Bool.and(_, Bool.not(is_dup)) : Bool}
      {==}

def Laws.protocol_args_rejects_empty_or_missing_placeholder(count, has_ph):
  NatL.and_false_right(Nat.is_gt(count, 0n))

def Laws.protocol_args_accepts_nonempty_with_placeholder(k):
  {==}

# 8. Parallel batch evaluation equivalence proof
# ----------------------------------------------

def Laws.batch_par_eq_seq(p1, p2, a, b, arg_count, has_ph):
  {==}
