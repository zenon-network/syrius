import Base

# Executable Bend specification for Syrius core amount arithmetic, decimal
# scaling, amount validation, asset sorting, plasma tiering, password strength,
# exchange-rate guard, MAX clamping, address label validation, and URL protocol
# argument validation.
#
# Corresponds to:
# - lib/utils/math_utils.dart (MathUtils.bigMin, MathUtils.bigMax)
# - lib/utils/extensions.dart (extractDecimals, addDecimals)
# - lib/utils/input_validators.dart (correctValue, validatePassword, checkPasswordMatch)
# - lib/rearchitecture/utils/functions/tokens.dart (sortAssets)
# - lib/utils/widget_utils.dart & lib/utils/color_utils.dart (plasma tiers)
# - lib/widgets/reusable_widgets/progress_bars.dart (PasswordProgressBar)
# - lib/rearchitecture/utils/widgets/exchange_rate.dart (ExchangeRate)
# - lib/rearchitecture/utils/widgets/amount_text_field.dart (_onMaxPressed)
# - lib/rearchitecture/features/settings_addresses/bloc/settings_addresses_bloc.dart
# - lib/rearchitecture/utils/url_protocol/protocol.dart (ProtocolHandler.getArguments)

# 1. BigInt min/max lattice (MathUtils.bigMin / bigMax)
# -----------------------------------------------------

def big_min_branch(+a: Nat, +b: Nat, le: Bool) -> Nat:
  match le:
    case True{}:
      a
    case False{}:
      b

def big_min(+a: Nat, +b: Nat) -> Nat:
  big_min_branch(a, b, Nat.is_le(a, b))

def big_max_branch(+a: Nat, +b: Nat, le: Bool) -> Nat:
  match le:
    case True{}:
      b
    case False{}:
      a

def big_max(+a: Nat, +b: Nat) -> Nat:
  big_max_branch(a, b, Nat.is_le(a, b))

# 2. Decimal scaling & canonical roundtrip (extractDecimals / addDecimals)
# ------------------------------------------------------------------------

def pow10(d: Nat) -> Nat:
  match d:
    case 0n:
      1n
    case 1n+p:
      Nat.mul(10n, pow10(p))

type DecimalParts is Data:
  DecimalParts{whole: Nat, frac: Nat, frac_len: Nat}

def scale_frac_branch(+frac: Nat, +frac_len: Nat, +decimals: Nat, le: Bool) -> Nat:
  match le:
    case True{}:
      Nat.mul(frac, pow10(Nat.sub(decimals, frac_len)))
    case False{}:
      Nat.div(frac, pow10(Nat.sub(frac_len, decimals)))

def scale_frac(+frac: Nat, +frac_len: Nat, +decimals: Nat) -> Nat:
  scale_frac_branch(frac, frac_len, decimals, Nat.is_le(frac_len, decimals))

def extract_decimals(+whole: Nat, +frac: Nat, +frac_len: Nat, +decimals: Nat) -> Nat:
  Nat.add(Nat.mul(whole, pow10(decimals)), scale_frac(frac, frac_len, decimals))

def add_decimals_from_pair(qr: Nat & Nat, +decimals: Nat) -> DecimalParts:
  (q, r) = qr
  DecimalParts{q, r, decimals}

def add_decimals(+base_units: Nat, +decimals: Nat) -> DecimalParts:
  add_decimals_from_pair(Nat.divmod(base_units, pow10(decimals)), decimals)

def roundtrip_decimals_parts(p: DecimalParts, +decimals: Nat) -> Nat:
  match p:
    case DecimalParts{+w, +f, +fl}:
      extract_decimals(w, f, fl, decimals)

def roundtrip_decimals(+base_units: Nat, +decimals: Nat) -> Nat:
  roundtrip_decimals_parts(add_decimals(base_units, decimals), decimals)

# 3. Amount validator (InputValidators.correctValue, with zero-max bypass fixed)
# ------------------------------------------------------------------------------

type AmountError is Data:
  AmountOk{}
  AmountErrBlank{}
  AmountErrParse{}
  AmountErrTooManyDecimals{}
  AmountErrMaxBelowMin{}
  AmountErrEmptyBalance{}
  AmountErrOutOfRange{}

def amount_is_ok(res: AmountError) -> Bool:
  match res:
    case AmountOk{}:
      True{}
    case _:
      False{}

def amount_range_check(ok: Bool) -> AmountError:
  match ok:
    case True{}:
      AmountOk{}
    case False{}:
      AmountErrOutOfRange{}

def amount_lower_ok(+val: Nat, +min_val: Nat, can_eq_min: Bool) -> Bool:
  match can_eq_min:
    case True{}:
      Nat.is_le(min_val, val)
    case False{}:
      Nat.is_lt(min_val, val)

def correct_value_check_bounds(+val: Nat, +max_val: Nat, +min_val: Nat, +can_eq_min: Bool, max_lt_min: Bool) -> AmountError:
  match max_lt_min:
    case True{}:
      AmountErrMaxBelowMin{}
    case False{}:
      amount_range_check(Bool.and(amount_lower_ok(val, min_val, can_eq_min), Nat.is_le(val, max_val)))

def correct_value_check_frac(+val: Nat, +max_val: Nat, +min_val: Nat, +can_eq_min: Bool, too_many_frac: Bool) -> AmountError:
  match too_many_frac:
    case True{}:
      AmountErrTooManyDecimals{}
    case False{}:
      correct_value_check_bounds(val, max_val, min_val, can_eq_min, Nat.is_lt(max_val, min_val))

def correct_value_nonblank(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, parse_ok: Bool, +frac_digits: Nat) -> AmountError:
  match parse_ok:
    case False{}:
      AmountErrParse{}
    case True{}:
      correct_value_check_frac(val, max_val, min_val, can_eq_min, Nat.is_gt(frac_digits, dec))

def correct_value_blank(can_be_blank: Bool) -> AmountError:
  match can_be_blank:
    case True{}:
      AmountOk{}
    case False{}:
      AmountErrBlank{}

def correct_value_after_empty(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, is_blank: Bool, parse_ok: Bool, +frac_digits: Nat) -> AmountError:
  match is_blank:
    case True{}:
      correct_value_blank(can_be_blank)
    case False{}:
      correct_value_nonblank(val, max_val, dec, min_val, can_eq_min, parse_ok, frac_digits)

def correct_value_check_empty_bal(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, is_blank: Bool, parse_ok: Bool, +frac_digits: Nat, empty_bal: Bool) -> AmountError:
  match empty_bal:
    case True{}:
      AmountErrEmptyBalance{}
    case False{}:
      correct_value_after_empty(val, max_val, dec, min_val, can_eq_min, can_be_blank, is_blank, parse_ok, frac_digits)

def correct_value(+val: Nat, +max_val: Nat, +dec: Nat, +min_val: Nat, +can_eq_min: Bool, can_be_blank: Bool, is_blank: Bool, parse_ok: Bool, +frac_digits: Nat) -> AmountError:
  correct_value_check_empty_bal(val, max_val, dec, min_val, can_eq_min, can_be_blank, is_blank, parse_ok, frac_digits, Bool.and(Nat.is_eq(max_val, 0n), Bool.or(Bool.not(can_eq_min), Nat.is_gt(min_val, 0n))))

# 4. Asset sort comparator (sortAssets strict weak ordering)
# ----------------------------------------------------------

type AssetKind is Data:
  Znn{}
  Qsr{}
  Zts{id: Nat}

def cmp_flip(c: Cmp) -> Cmp:
  match c:
    case LT{}:
      GT{}
    case EQ{}:
      EQ{}
    case GT{}:
      LT{}

def asset_cmp(a: AssetKind, b: AssetKind) -> Cmp:
  match a b:
    case Znn{} Znn{}:
      EQ{}
    case Znn{} _:
      LT{}
    case Qsr{} Znn{}:
      GT{}
    case Qsr{} Qsr{}:
      EQ{}
    case Qsr{} Zts{_}:
      LT{}
    case Zts{_} Znn{}:
      GT{}
    case Zts{_} Qsr{}:
      GT{}
    case Zts{_} Zts{_}:
      EQ{}

# 5. Plasma 4-tier classifier (WidgetUtils / ColorUtils)
# ------------------------------------------------------
# Thresholds:
#   < 21000         -> Insufficient (ZtsPurple / TipInsufficient)
#   [21000, 189000) -> Low          (Orange    / TipLow)
#   [189000,252000) -> Average      (Yellow    / TipAverage)
#   >= 252000       -> High         (ZnnGreen  / TipHigh)

type PlasmaTier is Data:
  PlasmaInsufficient{}
  PlasmaLow{}
  PlasmaAverage{}
  PlasmaHigh{}

type PlasmaColor is Data:
  ColorZts{}
  ColorOrange{}
  ColorYellow{}
  ColorZnn{}

type PlasmaTooltip is Data:
  TipInsufficient{}
  TipLow{}
  TipAverage{}
  TipHigh{}

def plasma_tier_low(ge_low: Bool) -> PlasmaTier:
  match ge_low:
    case True{}:
      PlasmaLow{}
    case False{}:
      PlasmaInsufficient{}

def plasma_tier_avg(+p: U32, ge_avg: Bool) -> PlasmaTier:
  match ge_avg:
    case True{}:
      PlasmaAverage{}
    case False{}:
      plasma_tier_low(U32.is_ge(p, 21000))

def plasma_tier_high(+p: U32, ge_high: Bool) -> PlasmaTier:
  match ge_high:
    case True{}:
      PlasmaHigh{}
    case False{}:
      plasma_tier_avg(p, U32.is_ge(p, 189000))

def plasma_tier(+p: U32) -> PlasmaTier:
  plasma_tier_high(p, U32.is_ge(p, 252000))

def plasma_tier_rank(t: PlasmaTier) -> Nat:
  match t:
    case PlasmaInsufficient{}:
      0n
    case PlasmaLow{}:
      1n
    case PlasmaAverage{}:
      2n
    case PlasmaHigh{}:
      3n

def plasma_color_from_tier(t: PlasmaTier) -> PlasmaColor:
  match t:
    case PlasmaInsufficient{}:
      ColorZts{}
    case PlasmaLow{}:
      ColorOrange{}
    case PlasmaAverage{}:
      ColorYellow{}
    case PlasmaHigh{}:
      ColorZnn{}

def plasma_tooltip_from_tier(t: PlasmaTier) -> PlasmaTooltip:
  match t:
    case PlasmaInsufficient{}:
      TipInsufficient{}
    case PlasmaLow{}:
      TipLow{}
    case PlasmaAverage{}:
      TipAverage{}
    case PlasmaHigh{}:
      TipHigh{}

def plasma_color(+p: U32) -> PlasmaColor:
  plasma_color_from_tier(plasma_tier(p))

def plasma_tooltip(+p: U32) -> PlasmaTooltip:
  plasma_tooltip_from_tier(plasma_tier(p))

def color_to_tooltip(c: PlasmaColor) -> PlasmaTooltip:
  match c:
    case ColorZts{}:
      TipInsufficient{}
    case ColorOrange{}:
      TipLow{}
    case ColorYellow{}:
      TipAverage{}
    case ColorZnn{}:
      TipHigh{}

def tooltip_to_color(t: PlasmaTooltip) -> PlasmaColor:
  match t:
    case TipInsufficient{}:
      ColorZts{}
    case TipLow{}:
      ColorOrange{}
    case TipAverage{}:
      ColorYellow{}
    case TipHigh{}:
      ColorZnn{}

# 6. Password strength 4-tier reducer & equality match
# ----------------------------------------------------

type PasswordStrength is Data:
  PwEmpty{}
  PwWeak{}
  PwMedium{}
  PwStrong{}

def password_strength_rank(s: PasswordStrength) -> Nat:
  match s:
    case PwEmpty{}:
      0n
    case PwWeak{}:
      1n
    case PwMedium{}:
      2n
    case PwStrong{}:
      3n

def password_is_valid(+len: Nat, has_upper: Bool, has_lower: Bool, has_digit: Bool, has_special: Bool) -> Bool:
  Bool.and(Nat.is_ge(len, 8n),
    Bool.and(has_upper,
      Bool.and(has_lower,
        Bool.and(has_digit, has_special))))

def password_strength_valid_len(ge_16: Bool) -> PasswordStrength:
  match ge_16:
    case True{}:
      PwStrong{}
    case False{}:
      PwMedium{}

def password_strength_checked(+len: Nat, valid: Bool) -> PasswordStrength:
  match valid:
    case False{}:
      PwWeak{}
    case True{}:
      password_strength_valid_len(Nat.is_ge(len, 16n))

def password_strength(+len: Nat, has_upper: Bool, has_lower: Bool, has_digit: Bool, has_special: Bool) -> PasswordStrength:
  match len:
    case 0n:
      PwEmpty{}
    case 1n+p:
      password_strength_checked(1n+p, password_is_valid(1n+p, has_upper, has_lower, has_digit, has_special))

def password_match(a: List<&2, Nat>, b: List<&2, Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case Con{ah, at} Con{bh, bt}:
      Bool.and(Nat.is_eq(ah, bh), password_match(at, bt))
    case _ _:
      False{}

# 7. UI-edge guards: ExchangeRate, MAX clamping, Address Label, Protocol Args
# ---------------------------------------------------------------------------

def exchange_rate_defined(+from_amt: Nat, +to_amt: Nat) -> Bool:
  Bool.and(Nat.is_gt(from_amt, 0n), Nat.is_gt(to_amt, 0n))

def resolve_max_update_eq(+max_bal: Nat, eq: Bool) -> Maybe<&2, Nat>:
  match eq:
    case True{}:
      None{}
    case False{}:
      Some{max_bal}

def resolve_max_update(cur: Maybe<&2, Nat>, +max_bal: Nat) -> Maybe<&2, Nat>:
  match cur:
    case None{}:
      Some{max_bal}
    case Some{+c}:
      resolve_max_update_eq(max_bal, Nat.is_eq(c, max_bal))

def apply_max_update(cur: Nat, upd: Maybe<&2, Nat>) -> Nat:
  match upd:
    case None{}:
      cur
    case Some{v}:
      v

def resolve_max_amount(+cur: Nat, +max_bal: Nat) -> Nat:
  apply_max_update(cur, resolve_max_update(Some{cur}, max_bal))

type LabelError is Data:
  LabelOk{}
  LabelEmpty{}
  LabelTooLong{}
  LabelDuplicate{}

def label_is_ok(e: LabelError) -> Bool:
  match e:
    case LabelOk{}:
      True{}
    case _:
      False{}

def validate_label_dup(is_dup: Bool) -> LabelError:
  match is_dup:
    case True{}:
      LabelDuplicate{}
    case False{}:
      LabelOk{}

def validate_label_len(too_long: Bool, is_dup: Bool) -> LabelError:
  match too_long:
    case True{}:
      LabelTooLong{}
    case False{}:
      validate_label_dup(is_dup)

def validate_address_label(+len: Nat, is_dup: Bool) -> LabelError:
  match len:
    case 0n:
      LabelEmpty{}
    case 1n+p:
      validate_label_len(Nat.is_gt(1n+p, 80n), is_dup)

def validate_protocol_args(+arg_count: Nat, has_placeholder: Bool) -> Bool:
  Bool.and(Nat.is_gt(arg_count, 0n), has_placeholder)

# 8. Parallelized batch validator/evaluator using Bend parallel-let
# -----------------------------------------------------------------

type BatchEvalResult is Data:
  BatchEvalResult{tier_a: PlasmaTier, tier_b: PlasmaTier, min_ab: Nat, max_ab: Nat, rate_ok: Bool, proto_ok: Bool}

def eval_half_a(+p: U32, +a: Nat, +b: Nat) -> PlasmaTier & Nat:
  (plasma_tier(p), big_min(a, b))

def eval_half_b(+p: U32, +a: Nat, +b: Nat, +arg_count: Nat, has_ph: Bool) -> PlasmaTier & (Nat & (Bool & Bool)):
  (plasma_tier(p), (big_max(a, b), (exchange_rate_defined(a, b), validate_protocol_args(arg_count, has_ph))))

def combine_batch(ha: PlasmaTier & Nat, hb: PlasmaTier & (Nat & (Bool & Bool))) -> BatchEvalResult:
  (ta, mn) = ha
  (tb, rest1) = hb
  (mx, rest2) = rest1
  (rok, pok) = rest2
  BatchEvalResult{ta, tb, mn, mx, rok, pok}

def eval_batch_seq(+p1: U32, +p2: U32, +a: Nat, +b: Nat, +arg_count: Nat, +has_ph: Bool) -> BatchEvalResult:
  ha = eval_half_a(p1, a, b)
  hb = eval_half_b(p2, a, b, arg_count, has_ph)
  combine_batch(ha, hb)

def eval_batch_par(+p1: U32, +p2: U32, +a: Nat, +b: Nat, +arg_count: Nat, +has_ph: Bool) -> BatchEvalResult:
  ha hb = eval_half_a(p1, a, b) eval_half_b(p2, a, b, arg_count, has_ph)
  combine_batch(ha, hb)
