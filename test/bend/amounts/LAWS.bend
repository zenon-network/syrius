import Base
import ./model.bend as M

# Formal laws for Syrius core amounts, decimal scaling, input validators,
# asset sorting, plasma tier classification, password strength, and UI-edge guards.

# 1. BigInt min/max lattice laws
# ------------------------------

law big_min_comm:
  for +a: Nat
  for +b: Nat
  {M.big_min(a, b) == M.big_min(b, a) : Nat}

law big_max_comm:
  for +a: Nat
  for +b: Nat
  {M.big_max(a, b) == M.big_max(b, a) : Nat}

law big_min_idem:
  for +a: Nat
  {M.big_min(a, a) == a : Nat}

law big_max_idem:
  for +a: Nat
  {M.big_max(a, a) == a : Nat}

law big_min_le_bounds:
  for +a: Nat
  for +b: Nat
  {Bool.and(Nat.is_le(M.big_min(a, b), a), Nat.is_le(M.big_min(a, b), b)) == True{} : Bool}

law big_max_ge_bounds:
  for +a: Nat
  for +b: Nat
  {Bool.and(Nat.is_le(a, M.big_max(a, b)), Nat.is_le(b, M.big_max(a, b))) == True{} : Bool}

law big_min_max_conservation:
  for +a: Nat
  for +b: Nat
  {Nat.add(M.big_min(a, b), M.big_max(a, b)) == Nat.add(a, b) : Nat}

# 2. Decimal scaling & canonical roundtrip laws
# ---------------------------------------------

law pow10_positive:
  for +d: Nat
  {Nat.is_gt(M.pow10(d), 0n) == True{} : Bool}

law extract_decimals_zero:
  for +fl: Nat
  for +d: Nat
  {M.extract_decimals(0n, 0n, fl, d) == 0n : Nat}

law decimals_canonical_roundtrip:
  for +base_units: Nat
  for +d: Nat
  {M.roundtrip_decimals(base_units, d) == base_units : Nat}

law scale_frac_truncation_exact:
  for +frac: Nat
  for +d: Nat
  for +extra: Nat
  {M.scale_frac(frac, Nat.add(d, 1n+extra), d) == Nat.div(frac, M.pow10(1n+extra)) : Nat}

# 3. Amount validator (correct_value) laws
# ----------------------------------------

law correct_value_empty_balance_rejected:
  for +val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_be_blank: Bool
  for +is_blank: Bool
  for +parse_ok: Bool
  for +frac_digits: Nat
  {M.correct_value(val, 0n, dec, min_val, False{}, can_be_blank, is_blank, parse_ok, frac_digits) == M.AmountErrEmptyBalance{} : M.AmountError}

law correct_value_blank_iff:
  for +val: Nat
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +parse_ok: Bool
  for +frac_digits: Nat
  for e_non_empty: {Bool.and(Nat.is_eq(max_val, 0n), Bool.not(can_eq_min)) == False{} : Bool}
  {M.amount_is_ok(M.correct_value(val, max_val, dec, min_val, can_eq_min, can_be_blank, True{}, parse_ok, frac_digits)) == can_be_blank : Bool}

law correct_value_parse_error_rejected:
  for +val: Nat
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +frac_digits: Nat
  {M.amount_is_ok(M.correct_value(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, False{}, frac_digits)) == False{} : Bool}

law correct_value_too_many_decimals_rejected:
  for +val: Nat
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +parse_ok: Bool
  for +frac_digits: Nat
  for e: {Nat.is_gt(frac_digits, dec) == True{} : Bool}
  {M.amount_is_ok(M.correct_value(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits)) == False{} : Bool}

law correct_value_max_below_min_rejected:
  for +val: Nat
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +parse_ok: Bool
  for +frac_digits: Nat
  for e: {Nat.is_lt(max_val, min_val) == True{} : Bool}
  {M.amount_is_ok(M.correct_value(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits)) == False{} : Bool}

law correct_value_gt_max_rejected:
  for +val: Nat
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +parse_ok: Bool
  for +frac_digits: Nat
  for e: {Nat.is_gt(val, max_val) == True{} : Bool}
  {M.amount_is_ok(M.correct_value(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits)) == False{} : Bool}

law correct_value_lt_min_rejected:
  for +val: Nat
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +parse_ok: Bool
  for +frac_digits: Nat
  for e: {Nat.is_lt(val, min_val) == True{} : Bool}
  {M.amount_is_ok(M.correct_value(val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, parse_ok, frac_digits)) == False{} : Bool}

law correct_value_at_min_iff:
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +frac_digits: Nat
  for e_frac: {Nat.is_le(frac_digits, dec) == True{} : Bool}
  for e_bounds: {Nat.is_le(min_val, max_val) == True{} : Bool}
  {M.amount_is_ok(M.correct_value(min_val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, True{}, frac_digits)) == can_eq_min : Bool}

law correct_value_at_max_iff:
  for +max_val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_eq_min: Bool
  for +can_be_blank: Bool
  for +frac_digits: Nat
  for e_frac: {Nat.is_le(frac_digits, dec) == True{} : Bool}
  for e_bounds: {Nat.is_le(min_val, max_val) == True{} : Bool}
  {M.amount_is_ok(M.correct_value(max_val, max_val, dec, min_val, can_eq_min, can_be_blank, False{}, True{}, frac_digits)) == Bool.or(can_eq_min, Nat.is_lt(min_val, max_val)) : Bool}

# 4. Asset sort comparator laws
# -----------------------------

law asset_cmp_irrefl:
  for +x: M.AssetKind
  {M.asset_cmp(x, x) == EQ{} : Cmp}

law asset_cmp_antisym:
  for +a: M.AssetKind
  for +b: M.AssetKind
  {M.cmp_flip(M.asset_cmp(a, b)) == M.asset_cmp(b, a) : Cmp}

law asset_cmp_trans:
  for +a: M.AssetKind
  for +b: M.AssetKind
  for +c: M.AssetKind
  for ab: {Cmp.is_le(M.asset_cmp(a, b)) == True{} : Bool}
  for bc: {Cmp.is_le(M.asset_cmp(b, c)) == True{} : Bool}
  {Cmp.is_le(M.asset_cmp(a, c)) == True{} : Bool}

law asset_order_hierarchy:
  for +id: Nat
  {Bool.and(Cmp.is_lt(M.asset_cmp(M.Znn{}, M.Qsr{})),
    Bool.and(Cmp.is_lt(M.asset_cmp(M.Qsr{}, M.Zts{id})),
      Cmp.is_lt(M.asset_cmp(M.Znn{}, M.Zts{id})))) == True{} : Bool}

# 5. Plasma 4-tier classifier laws
# --------------------------------

law plasma_tier_monotone:
  for +p1: U32
  for +p2: U32
  for e: {U32.is_le(p1, p2) == True{} : Bool}
  {Nat.is_le(M.plasma_tier_rank(M.plasma_tier(p1)), M.plasma_tier_rank(M.plasma_tier(p2))) == True{} : Bool}

law plasma_tier_exact_boundaries:
  {(M.plasma_tier(20999), (M.plasma_tier(21000), (M.plasma_tier(188999), (M.plasma_tier(189000), (M.plasma_tier(251999), M.plasma_tier(252000))))))
    == (M.PlasmaInsufficient{}, (M.PlasmaLow{}, (M.PlasmaLow{}, (M.PlasmaAverage{}, (M.PlasmaAverage{}, M.PlasmaHigh{})))))
    : M.PlasmaTier & (M.PlasmaTier & (M.PlasmaTier & (M.PlasmaTier & (M.PlasmaTier & M.PlasmaTier))))}

law plasma_color_tooltip_agreement:
  for +p: U32
  {(M.color_to_tooltip(M.plasma_color(p)), M.tooltip_to_color(M.plasma_tooltip(p)))
    == (M.plasma_tooltip(p), M.plasma_color(p))
    : M.PlasmaTooltip & M.PlasmaColor}

# 6. Password strength & matching laws
# ------------------------------------

law password_invalid_never_medium_or_strong:
  for +len: Nat
  for +u: Bool
  for +l: Bool
  for +d: Bool
  for +s: Bool
  for e: {M.password_is_valid(len, u, l, d, s) == False{} : Bool}
  {Nat.is_le(M.password_strength_rank(M.password_strength(len, u, l, d, s)), 1n) == True{} : Bool}

law password_strength_monotone_valid:
  for +len1: Nat
  for +len2: Nat
  for e: {Nat.is_le(len1, len2) == True{} : Bool}
  {Nat.is_le(M.password_strength_rank(M.password_strength(len1, True{}, True{}, True{}, True{})),
    M.password_strength_rank(M.password_strength(len2, True{}, True{}, True{}, True{}))) == True{} : Bool}

law password_match_refl:
  for +a: List<&2, Nat>
  {M.password_match(a, a) == True{} : Bool}

law password_match_sound:
  for +a: List<&2, Nat>
  for +b: List<&2, Nat>
  for e: {M.password_match(a, b) == True{} : Bool}
  {a == b : List<&2, Nat>}

# 7. UI-edge guard laws
# ---------------------

law exchange_rate_zero_guard:
  for +from_amt: Nat
  for +to_amt: Nat
  {Bool.or(M.exchange_rate_defined(0n, to_amt), M.exchange_rate_defined(from_amt, 0n)) == False{} : Bool}

law exchange_rate_positive_defined:
  for +a: Nat
  for +b: Nat
  {M.exchange_rate_defined(1n+a, 1n+b) == True{} : Bool}

law resolve_max_always_clamps:
  for +cur: Nat
  for +max_bal: Nat
  {M.resolve_max_amount(cur, max_bal) == max_bal : Nat}

law resolve_max_update_noop_iff_equal:
  for +cur: Nat
  for +max_bal: Nat
  for e_neq: {Nat.is_eq(cur, max_bal) == False{} : Bool}
  {(M.resolve_max_update(None{}, max_bal), (M.resolve_max_update(Some{max_bal}, max_bal), M.resolve_max_update(Some{cur}, max_bal)))
    == (Some{max_bal}, (None{}, Some{max_bal}))
    : Maybe<&2, Nat> & (Maybe<&2, Nat> & Maybe<&2, Nat>)}

law address_label_validation_iff:
  for +len: Nat
  for +is_dup: Bool
  {M.label_is_ok(M.validate_address_label(len, is_dup))
    == Bool.and(Nat.is_ge(len, 1n), Bool.and(Nat.is_le(len, 80n), Bool.not(is_dup))) : Bool}

law protocol_args_rejects_empty_or_missing_placeholder:
  for +count: Nat
  for +has_ph: Bool
  {Bool.or(M.validate_protocol_args(0n, has_ph), M.validate_protocol_args(count, False{})) == False{} : Bool}

law protocol_args_accepts_nonempty_with_placeholder:
  for +k: Nat
  {M.validate_protocol_args(1n+k, True{}) == True{} : Bool}

# 8. Parallel batch evaluation equivalence
# ----------------------------------------

law batch_par_eq_seq:
  for +p1: U32
  for +p2: U32
  for +a: Nat
  for +b: Nat
  for +arg_count: Nat
  for +has_ph: Bool
  {M.eval_batch_par(p1, p2, a, b, arg_count, has_ph)
    == M.eval_batch_seq(p1, p2, a, b, arg_count, has_ph) : M.BatchEvalResult}
