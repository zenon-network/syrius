import Base

# Reusable Bool and Nat proof-lemma library for Syrius Bend proofs.
# Base provides definitions and basic Equal lemmas, but omits most Bool/Nat
# algebraic and order theorems; each lemma here is proven constructively and
# verified by both Bend and the independent Lean kernel (--verdict).

# Bool lemmas
# -----------

def Not.true(b: Bool) -> Type:
  match b:
    case True{}:
      Empty
    case False{}:
      Unit

def Not.false(b: Bool) -> Type:
  match b:
    case True{}:
      Unit
    case False{}:
      Empty

def false_is_not_true(e: {False{} == True{} : Bool}) -> Empty:
  %e : Not.true(_)
  Unit{}

def true_is_not_false(e: {True{} == False{} : Bool}) -> Empty:
  %e : Not.false(_)
  Unit{}

def bool_eq(+a: Bool, +b: Bool) -> Bool:
  match a b:
    case False{} False{}:
      True{}
    case True{} True{}:
      True{}
    case _ _:
      False{}

law not_not:
  for +b: Bool
  {Bool.not(Bool.not(b)) == b : Bool}

def not_not(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

law and_true_right:
  for +b: Bool
  {Bool.and(b, True{}) == b : Bool}

def and_true_right(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

law and_false_right:
  for +b: Bool
  {Bool.and(b, False{}) == False{} : Bool}

def and_false_right(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

law or_false_right:
  for +b: Bool
  {Bool.or(b, False{}) == b : Bool}

def or_false_right(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

law or_true_right:
  for +b: Bool
  {Bool.or(b, True{}) == True{} : Bool}

def or_true_right(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

law and_comm:
  for +a: Bool
  for +b: Bool
  {Bool.and(a, b) == Bool.and(b, a) : Bool}

def and_comm(a, b):
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

law or_comm:
  for +a: Bool
  for +b: Bool
  {Bool.or(a, b) == Bool.or(b, a) : Bool}

def or_comm(a, b):
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

law and_true_left:
  for +a: Bool
  for +b: Bool
  for e: {Bool.and(a, b) == True{} : Bool}
  {a == True{} : Bool}

def and_true_left(a, b, e):
  match a:
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, false_is_not_true(e))
    case True{}:
      {==}

law and_true_right_elim:
  for +a: Bool
  for +b: Bool
  for e: {Bool.and(a, b) == True{} : Bool}
  {b == True{} : Bool}

def and_true_right_elim(a, b, e):
  match a:
    case False{}:
      Empty.absurd({b == True{} : Bool}, false_is_not_true(e))
    case True{}:
      e

law or_false_left:
  for +a: Bool
  for +b: Bool
  for e: {Bool.or(a, b) == False{} : Bool}
  {a == False{} : Bool}

def or_false_left(a, b, e):
  match a:
    case False{}:
      {==}
    case True{}:
      Empty.absurd({True{} == False{} : Bool}, true_is_not_false(e))

law or_false_right_elim:
  for +a: Bool
  for +b: Bool
  for e: {Bool.or(a, b) == False{} : Bool}
  {b == False{} : Bool}

def or_false_right_elim(a, b, e):
  match a:
    case False{}:
      e
    case True{}:
      Empty.absurd({b == False{} : Bool}, true_is_not_false(e))

law bool_eq_refl:
  for +b: Bool
  {bool_eq(b, b) == True{} : Bool}

def bool_eq_refl(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

law bool_eq_sound:
  for +a: Bool
  for +b: Bool
  for e: {bool_eq(a, b) == True{} : Bool}
  {a == b : Bool}

def bool_eq_sound(a, b, e):
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      Empty.absurd({False{} == True{} : Bool}, false_is_not_true(e))
    case True{} False{}:
      Empty.absurd({True{} == False{} : Bool}, false_is_not_true(e))
    case True{} True{}:
      {==}

# Nat arithmetic lemmas
# ---------------------

law add_zero:
  for +x: Nat
  {Nat.add(x, 0n) == x : Nat}

def add_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

law add_succ:
  for +x: Nat
  for +y: Nat
  {Nat.add(x, 1n+y) == 1n+Nat.add(x, y) : Nat}

def add_succ(x, y):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, y) : {1n+Nat.add(p, 1n+y) == 1n+_ : Nat}
      {==}

law add_assoc:
  for +x: Nat
  for +y: Nat
  for +z: Nat
  {Nat.add(Nat.add(x, y), z) == Nat.add(x, Nat.add(y, z)) : Nat}

def add_assoc(x, y, z):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %add_assoc(p, y, z) : {1n+Nat.add(Nat.add(p, y), z) == 1n+_ : Nat}
      {==}

law add_comm:
  for +x: Nat
  for +y: Nat
  {Nat.add(x, y) == Nat.add(y, x) : Nat}

def add_comm(x, y):
  match x:
    case 0n:
      Equal.sym(Nat, Nat.add(y, 0n), y, add_zero(y))
    case 1n+p:
      %Equal.sym(Nat, Nat.add(y, 1n+p), 1n+Nat.add(y, p), add_succ(y, p)) : {1n+Nat.add(p, y) == _ : Nat}
      %add_comm(p, y) : {1n+Nat.add(p, y) == 1n+_ : Nat}
      {==}

# (x + a) + h == (x + h) + a
law add_swap:
  for +x: Nat
  for +a: Nat
  for +h: Nat
  {Nat.add(Nat.add(x, a), h) == Nat.add(Nat.add(x, h), a) : Nat}

def add_swap(x, a, h):
  %Equal.sym(Nat, Nat.add(Nat.add(x, h), a), Nat.add(x, Nat.add(h, a)), add_assoc(x, h, a)) : {Nat.add(Nat.add(x, a), h) == _ : Nat}
  %add_comm(a, h) : {Nat.add(Nat.add(x, a), h) == Nat.add(x, _) : Nat}
  add_assoc(x, a, h)

law sub_zero:
  for +x: Nat
  {Nat.sub(x, 0n) == x : Nat}

def sub_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      {==}

law sub_self:
  for +x: Nat
  {Nat.sub(x, x) == 0n : Nat}

def sub_self(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      sub_self(p)

# (b - a) + a == b whenever a <= b
law sub_add:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_le(a, b) == True{} : Bool}
  {Nat.add(Nat.sub(b, a), a) == b : Nat}

def sub_add(a, b, e):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      add_zero(1n+bp)
    case 1n+ap 0n:
      Empty.absurd({Nat.add(Nat.sub(0n, 1n+ap), 1n+ap) == 0n : Nat}, false_is_not_true(e))
    case 1n+ap 1n+bp:
      %sub_add(ap, bp, e) : {Nat.add(Nat.sub(bp, ap), 1n+ap) == 1n+_ : Nat}
      add_succ(Nat.sub(bp, ap), ap)

law sub_cancel_add_left:
  for +a: Nat
  for +b: Nat
  {Nat.sub(Nat.add(a, b), a) == b : Nat}

def sub_cancel_add_left(a, b):
  match a:
    case 0n:
      sub_zero(b)
    case 1n+ap:
      sub_cancel_add_left(ap, b)

law sub_cancel_add_right:
  for +a: Nat
  for +b: Nat
  {Nat.sub(Nat.add(a, b), b) == a : Nat}

def sub_cancel_add_right(a, b):
  %add_comm(b, a) : {Nat.sub(_, b) == a : Nat}
  sub_cancel_add_left(b, a)

law mul_zero_right:
  for +a: Nat
  {Nat.mul(a, 0n) == 0n : Nat}

def mul_zero_right(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      mul_zero_right(p)

# Nat equality and order lemmas
# -----------------------------

law is_eq_same:
  for +x: Nat
  {Nat.is_eq(x, x) == True{} : Bool}

def is_eq_same(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      is_eq_same(p)

law is_eq_sym:
  for +x: Nat
  for +y: Nat
  {Nat.is_eq(x, y) == Nat.is_eq(y, x) : Bool}

def is_eq_sym(x, y):
  match x y:
    case 0n 0n:
      {==}
    case 0n 1n+yp:
      {==}
    case 1n+xp 0n:
      {==}
    case 1n+xp 1n+yp:
      is_eq_sym(xp, yp)

law is_eq_sound:
  for +x: Nat
  for +y: Nat
  for e: {Nat.is_eq(x, y) == True{} : Bool}
  {x == y : Nat}

def is_eq_sound(x, y, e):
  match x y:
    case 0n 0n:
      {==}
    case 0n 1n+yp:
      Empty.absurd({0n == 1n+yp : Nat}, false_is_not_true(e))
    case 1n+xp 0n:
      Empty.absurd({1n+xp == 0n : Nat}, false_is_not_true(e))
    case 1n+xp 1n+yp:
      %is_eq_sound(xp, yp, e) : {1n+xp == 1n+_ : Nat}
      {==}

law is_le_refl:
  for +x: Nat
  {Nat.is_le(x, x) == True{} : Bool}

def is_le_refl(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      is_le_refl(p)

law is_le_zero:
  for +x: Nat
  {Nat.is_le(0n, x) == True{} : Bool}

def is_le_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      {==}

law is_le_zero_eq:
  for +x: Nat
  for e: {Nat.is_le(x, 0n) == True{} : Bool}
  {x == 0n : Nat}

def is_le_zero_eq(x, e):
  match x:
    case 0n:
      {==}
    case 1n+p:
      Empty.absurd({1n+p == 0n : Nat}, false_is_not_true(e))

law is_le_add_right:
  for +a: Nat
  for +b: Nat
  {Nat.is_le(a, Nat.add(a, b)) == True{} : Bool}

def is_le_add_right(a, b):
  match a:
    case 0n:
      is_le_zero(b)
    case 1n+ap:
      is_le_add_right(ap, b)

law is_le_add_left:
  for +a: Nat
  for +b: Nat
  {Nat.is_le(b, Nat.add(a, b)) == True{} : Bool}

def is_le_add_left(a, b):
  %add_comm(b, a) : {Nat.is_le(b, _) == True{} : Bool}
  is_le_add_right(b, a)

law is_lt_irrefl:
  for +x: Nat
  {Nat.is_lt(x, x) == False{} : Bool}

def is_lt_irrefl(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      is_lt_irrefl(p)

law lt_ge_disjoint:
  for +a: Nat
  for +b: Nat
  {Bool.and(Nat.is_lt(a, b), Nat.is_ge(a, b)) == False{} : Bool}

def lt_ge_disjoint(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      lt_ge_disjoint(ap, bp)

law le_gt_disjoint:
  for +a: Nat
  for +b: Nat
  {Bool.and(Nat.is_le(a, b), Nat.is_gt(a, b)) == False{} : Bool}

def le_gt_disjoint(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      le_gt_disjoint(ap, bp)

law is_ge_as_le:
  for +a: Nat
  for +b: Nat
  {Nat.is_ge(a, b) == Nat.is_le(b, a) : Bool}

def is_ge_as_le(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      is_ge_as_le(ap, bp)

law is_gt_as_lt:
  for +a: Nat
  for +b: Nat
  {Nat.is_gt(a, b) == Nat.is_lt(b, a) : Bool}

def is_gt_as_lt(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      is_gt_as_lt(ap, bp)

law not_lt_is_ge:
  for +a: Nat
  for +b: Nat
  {Bool.not(Nat.is_lt(a, b)) == Nat.is_ge(a, b) : Bool}

def not_lt_is_ge(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      not_lt_is_ge(ap, bp)

law not_le_is_gt:
  for +a: Nat
  for +b: Nat
  {Bool.not(Nat.is_le(a, b)) == Nat.is_gt(a, b) : Bool}

def not_le_is_gt(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      not_le_is_gt(ap, bp)

law lt_implies_le:
  for +a: Nat
  for +b: Nat
  for e: {Nat.is_lt(a, b) == True{} : Bool}
  {Nat.is_le(a, b) == True{} : Bool}

def lt_implies_le(a, b, e):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_le(1n+ap, 0n) == True{} : Bool}, false_is_not_true(e))
    case 1n+ap 1n+bp:
      lt_implies_le(ap, bp, e)

law le_trans:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for ab: {Nat.is_le(a, b) == True{} : Bool}
  for bc: {Nat.is_le(b, c) == True{} : Bool}
  {Nat.is_le(a, c) == True{} : Bool}

def le_trans(a, b, c, ab, bc):
  match a b c:
    case 0n _ 0n:
      {==}
    case 0n _ 1n+cp:
      {==}
    case 1n+ap 0n _:
      Empty.absurd({Nat.is_le(1n+ap, c) == True{} : Bool}, false_is_not_true(ab))
    case 1n+ap 1n+bp 0n:
      Empty.absurd({Nat.is_le(1n+ap, 0n) == True{} : Bool}, false_is_not_true(bc))
    case 1n+ap 1n+bp 1n+cp:
      le_trans(ap, bp, cp, ab, bc)

law lt_trans:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for ab: {Nat.is_lt(a, b) == True{} : Bool}
  for bc: {Nat.is_lt(b, c) == True{} : Bool}
  {Nat.is_lt(a, c) == True{} : Bool}

def lt_trans(a, b, c, ab, bc):
  match a b c:
    case 0n 0n _:
      Empty.absurd({Nat.is_lt(0n, c) == True{} : Bool}, false_is_not_true(ab))
    case 0n 1n+bp 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, false_is_not_true(bc))
    case 0n 1n+bp 1n+cp:
      {==}
    case 1n+ap 0n _:
      Empty.absurd({Nat.is_lt(1n+ap, c) == True{} : Bool}, false_is_not_true(ab))
    case 1n+ap 1n+bp 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 0n) == True{} : Bool}, false_is_not_true(bc))
    case 1n+ap 1n+bp 1n+cp:
      lt_trans(ap, bp, cp, ab, bc)

law le_antisym:
  for +a: Nat
  for +b: Nat
  for ab: {Nat.is_le(a, b) == True{} : Bool}
  for ba: {Nat.is_le(b, a) == True{} : Bool}
  {a == b : Nat}

def le_antisym(a, b, ab, ba):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      Empty.absurd({0n == 1n+bp : Nat}, false_is_not_true(ba))
    case 1n+ap 0n:
      Empty.absurd({1n+ap == 0n : Nat}, false_is_not_true(ab))
    case 1n+ap 1n+bp:
      %le_antisym(ap, bp, ab, ba) : {1n+ap == 1n+_ : Nat}
      {==}

law add_monotone_le:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  for +d: Nat
  for ab: {Nat.is_le(a, b) == True{} : Bool}
  for cd: {Nat.is_le(c, d) == True{} : Bool}
  {Nat.is_le(Nat.add(a, c), Nat.add(b, d)) == True{} : Bool}

def add_monotone_le(a, b, c, d, ab, cd):
  match a b:
    case 0n 0n:
      cd
    case 0n 1n+bp:
      le_trans(c, d, 1n+Nat.add(bp, d), cd, is_le_add_left(1n+bp, d))
    case 1n+ap 0n:
      Empty.absurd({Nat.is_le(Nat.add(1n+ap, c), Nat.add(0n, d)) == True{} : Bool}, false_is_not_true(ab))
    case 1n+ap 1n+bp:
      add_monotone_le(ap, bp, c, d, ab, cd)

law min_le_left:
  for +a: Nat
  for +b: Nat
  {Nat.is_le(Nat.min(a, b), a) == True{} : Bool}

def min_le_left(a, b):
  match a b:
    case 0n _:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      min_le_left(ap, bp)

law min_le_right:
  for +a: Nat
  for +b: Nat
  {Nat.is_le(Nat.min(a, b), b) == True{} : Bool}

def min_le_right(a, b):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      min_le_right(ap, bp)

law min_self:
  for +a: Nat
  {Nat.min(a, a) == a : Nat}

def min_self(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %min_self(p) : {1n+Nat.min(p, p) == 1n+_ : Nat}
      {==}
