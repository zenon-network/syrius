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

def not_lt_from_ge(+a: Nat, +b: Nat, ge: {Nat.is_ge(a, b) == True{} : Bool}) -> {Nat.is_lt(a, b) == False{} : Bool}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      Empty.absurd({Nat.is_lt(0n, 1n+bp) == False{} : Bool}, NatL.false_is_not_true(ge))
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      not_lt_from_ge(ap, bp, ge)

def pick_issue_rank_ge(+ok: Bool, +s: M.IssueStep, +n: M.IssueStep, h: {Nat.is_le(M.issue_step_rank(s), M.issue_step_rank(n)) == True{} : Bool}) -> {Nat.is_le(M.issue_step_rank(s), M.issue_step_rank(M.pick_issue_step(ok, n, s))) == True{} : Bool}:
  match ok:
    case True{}:
      h
    case False{}:
      NatL.is_le_refl(M.issue_step_rank(s))

def add_pos_lt(+total: Nat, +amt: Nat, pos: {Nat.is_gt(amt, 0n) == True{} : Bool}) -> {Nat.is_lt(total, Nat.add(total, amt)) == True{} : Bool}:
  match total amt:
    case 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(pos))
    case 0n 1n+ap:
      {==}
    case 1n+tp 0n:
      Empty.absurd({Nat.is_lt(1n+tp, Nat.add(1n+tp, 0n)) == True{} : Bool}, NatL.false_is_not_true(pos))
    case 1n+tp 1n+ap:
      add_pos_lt(tp, 1n+ap, pos)

def lt_self_succ_le(+x: Nat) -> {Nat.is_le(x, 1n+x) == True{} : Bool}:
  match x:
    case 0n:
      {==}
    case 1n+xp:
      lt_self_succ_le(xp)

def sub_le_self(+a: Nat, +b: Nat) -> {Nat.is_le(Nat.sub(a, b), a) == True{} : Bool}:
  match a b:
    case 0n _:
      {==}
    case 1n+ap 0n:
      NatL.is_le_refl(1n+ap)
    case 1n+ap 1n+bp:
      NatL.le_trans(Nat.sub(ap, bp), ap, 1n+ap, sub_le_self(ap, bp), lt_self_succ_le(ap))

def le_implies_lt_succ(+a: Nat, +b: Nat, le: {Nat.is_le(a, b) == True{} : Bool}) -> {Nat.is_lt(a, 1n+b) == True{} : Bool}:
  match a b:
    case 0n _:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 1n) == True{} : Bool}, NatL.false_is_not_true(le))
    case 1n+ap 1n+bp:
      le_implies_lt_succ(ap, bp, le)

def sub_pos_lt_clean(+total: Nat, +amt: Nat, pos: {Nat.is_gt(amt, 0n) == True{} : Bool}, le: {Nat.is_le(amt, total) == True{} : Bool}) -> {Nat.is_lt(Nat.sub(total, amt), total) == True{} : Bool}:
  match total amt:
    case 0n 0n:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(pos))
    case 0n 1n+ap:
      Empty.absurd({Nat.is_lt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(le))
    case 1n+tp 0n:
      Empty.absurd({Nat.is_lt(1n+tp, 1n+tp) == True{} : Bool}, NatL.false_is_not_true(pos))
    case 1n+tp 1n+ap:
      le_implies_lt_succ(Nat.sub(tp, ap), tp, sub_le_self(tp, ap))

def and_false_second(+a: Bool, +b: Bool) -> {Bool.and(a, Bool.and(False{}, b)) == False{} : Bool}:
  match a:
    case False{}:
      {==}
    case True{}:
      {==}

# Law proofs
# ----------

def Laws.issue_constants_exact():
  {==}

def Laws.issue_step_monotone(step, plasma_k, znn_bal, details_ok, metrics_ok, submit_ok):
  match step:
    case M.IssuePlasma{}:
      pick_issue_rank_ge(Nat.is_ge(plasma_k, 189n), M.IssuePlasma{}, M.IssueZnn{}, {==})
    case M.IssueZnn{}:
      pick_issue_rank_ge(Nat.is_ge(znn_bal, 1n), M.IssueZnn{}, M.IssueDetails{}, {==})
    case M.IssueDetails{}:
      pick_issue_rank_ge(details_ok, M.IssueDetails{}, M.IssueFlags{}, {==})
    case M.IssueFlags{}:
      {==}
    case M.IssueMetrics{}:
      pick_issue_rank_ge(metrics_ok, M.IssueMetrics{}, M.IssueSubmit{}, {==})
    case M.IssueSubmit{}:
      pick_issue_rank_ge(submit_ok, M.IssueSubmit{}, M.IssueDone{}, {==})
    case M.IssueDone{}:
      {==}

def Laws.issue_plasma_gate(plasma_k, znn_bal, details_ok, metrics_ok, submit_ok, lt):
  ng = not_ge_from_lt(plasma_k, 189n, lt)
  %Equal.sym(Bool, Nat.is_ge(plasma_k, 189n), False{}, ng) : {M.pick_issue_step(_, M.IssueZnn{}, M.IssuePlasma{}) == M.IssuePlasma{} : M.IssueStep}
  {==}

def Laws.issue_prerequisite_gates(plasma_k, znn_bal, details_ok, metrics_ok, submit_ok):
  {==}

def Laws.token_name_bounds(k):
  {==}

def Laws.token_symbol_rejects_reserved(len):
  {==}

def Laws.token_symbol_domain_decimals_bounds(k):
  {==}

def Laws.supply_mintable_rejects_zero_max(total, cap, dec):
  and_false_second(M.valid_decimals(dec), Bool.and(Nat.is_le(0n, cap), Nat.is_le(total, 0n)))

def Laws.supply_non_mintable_effective_max_eq_total(total, max_in):
  {==}

def Laws.supply_valid_total_le_eff_max(is_mintable, total, max_in, cap, dec, ok):
  match is_mintable:
    case True{}:
      r1 = NatL.and_true_right_elim(M.valid_decimals(dec), Bool.and(Nat.is_ge(max_in, 1n), Bool.and(Nat.is_le(max_in, cap), Nat.is_le(total, max_in))), ok)
      r2 = NatL.and_true_right_elim(Nat.is_ge(max_in, 1n), Bool.and(Nat.is_le(max_in, cap), Nat.is_le(total, max_in)), r1)
      NatL.and_true_right_elim(Nat.is_le(max_in, cap), Nat.is_le(total, max_in), r2)
    case False{}:
      NatL.is_le_refl(total)

def Laws.supply_valid_eff_max_positive(is_mintable, total, max_in, cap, dec, ok):
  match is_mintable:
    case True{}:
      r1 = NatL.and_true_right_elim(M.valid_decimals(dec), Bool.and(Nat.is_ge(max_in, 1n), Bool.and(Nat.is_le(max_in, cap), Nat.is_le(total, max_in))), ok)
      NatL.and_true_left(Nat.is_ge(max_in, 1n), Bool.and(Nat.is_le(max_in, cap), Nat.is_le(total, max_in)), r1)
    case False{}:
      r1 = NatL.and_true_right_elim(M.valid_decimals(dec), Bool.and(Nat.is_ge(total, 1n), Nat.is_le(total, cap)), ok)
      NatL.and_true_left(Nat.is_ge(total, 1n), Nat.is_le(total, cap), r1)

def Laws.caps_transfer_iff_owner(m, b, tot, mx, own, wown):
  {==}

def Laws.caps_non_mintable_never_mints(b, tot, mx, own, wown):
  {==}

def caps_full_from_lt(+lt_res: Bool, +m: Bool, +own: Bool, e: {lt_res == False{} : Bool}) -> {Bool.and(Bool.not(Bool.and(m, lt_res)), Bool.not(Bool.and(Bool.and(m, lt_res), own))) == True{} : Bool}:
  match lt_res:
    case True{}:
      Empty.absurd({Bool.and(Bool.not(Bool.and(m, True{})), Bool.not(Bool.and(Bool.and(m, True{}), own))) == True{} : Bool}, NatL.true_is_not_false(e))
    case False{}:
      match m:
        case False{}:
          {==}
        case True{}:
          {==}

def Laws.caps_full_supply_never_mints(m, b, tot, mx, own, wown, ge):
  caps_full_from_lt(Nat.is_lt(tot, mx), m, own, not_lt_from_ge(tot, mx, ge))

def Laws.caps_mint_requires_owner(m, b, tot, mx, wown):
  NatL.and_false_right(Bool.and(m, Nat.is_lt(tot, mx)))

def Laws.caps_burn_protocol_rule(m, b, tot, mx, own, wown):
  {==}

def mint_conserves_from_pair(
  +amt: Nat,
  +total: Nat,
  +max_sup: Nat,
  pair: {Nat.is_le(total, max_sup) == True{} : Bool} & {Nat.is_le(amt, Nat.sub(max_sup, total)) == True{} : Bool}
) -> {Nat.is_le(Nat.add(total, amt), max_sup) == True{} : Bool}:
  (tot_le, amt_le) = pair
  sum_le = NatL.add_monotone_le(total, total, amt, Nat.sub(max_sup, total), NatL.is_le_refl(total), amt_le)
  %NatL.sub_add(total, max_sup, tot_le) : {Nat.is_le(Nat.add(total, amt), _) == True{} : Bool}
  %NatL.add_comm(total, Nat.sub(max_sup, total)) : {Nat.is_le(Nat.add(total, amt), _) == True{} : Bool}
  sum_le

def Laws.mint_conserves_max_supply(amt, total, max_sup, m, own, ok):
  r1 = NatL.and_true_right_elim(m, Bool.and(own, Bool.and(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(total, max_sup), Nat.is_le(amt, Nat.sub(max_sup, total))))), ok)
  r2 = NatL.and_true_right_elim(own, Bool.and(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(total, max_sup), Nat.is_le(amt, Nat.sub(max_sup, total)))), r1)
  r3 = NatL.and_true_right_elim(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(total, max_sup), Nat.is_le(amt, Nat.sub(max_sup, total))), r2)
  mint_conserves_from_pair(amt, total, max_sup, and_split(Nat.is_le(total, max_sup), Nat.is_le(amt, Nat.sub(max_sup, total)), r3))

def Laws.mint_strictly_increases_supply(amt, total, max_sup, m, own, ok):
  r1 = NatL.and_true_right_elim(m, Bool.and(own, Bool.and(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(total, max_sup), Nat.is_le(amt, Nat.sub(max_sup, total))))), ok)
  r2 = NatL.and_true_right_elim(own, Bool.and(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(total, max_sup), Nat.is_le(amt, Nat.sub(max_sup, total)))), r1)
  pos = NatL.and_true_left(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(total, max_sup), Nat.is_le(amt, Nat.sub(max_sup, total))), r2)
  add_pos_lt(total, amt, pos)

def Laws.burn_conserves_balance(amt, bal, total, b, own, ok):
  r1 = NatL.and_true_right_elim(Bool.or(b, own), Bool.and(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(amt, bal), Nat.is_le(amt, total))), ok)
  r2 = NatL.and_true_right_elim(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(amt, bal), Nat.is_le(amt, total)), r1)
  le_bal = NatL.and_true_left(Nat.is_le(amt, bal), Nat.is_le(amt, total), r2)
  NatL.sub_add(amt, bal, le_bal)

def burn_reduces_from_pair(
  +amt: Nat,
  +bal: Nat,
  +total: Nat,
  pair: {Nat.is_gt(amt, 0n) == True{} : Bool} & {Bool.and(Nat.is_le(amt, bal), Nat.is_le(amt, total)) == True{} : Bool}
) -> {Nat.is_lt(Nat.sub(total, amt), total) == True{} : Bool}:
  (pos, r2) = pair
  le_tot = NatL.and_true_right_elim(Nat.is_le(amt, bal), Nat.is_le(amt, total), r2)
  sub_pos_lt_clean(total, amt, pos, le_tot)

def Laws.burn_reduces_total_supply(amt, bal, total, b, own, ok):
  r1 = NatL.and_true_right_elim(Bool.or(b, own), Bool.and(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(amt, bal), Nat.is_le(amt, total))), ok)
  burn_reduces_from_pair(amt, bal, total, and_split(Nat.is_gt(amt, 0n), Bool.and(Nat.is_le(amt, bal), Nat.is_le(amt, total)), r1))

def Laws.trusted_token_iff_native_or_fav(z, q, f):
  match z f:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def Laws.fav_actions_disjoint(st):
  match st:
    case M.FavNotFavorite{}:
      {==}
    case M.FavFavorite{}:
      {==}
    case M.FavLoading{}:
      {==}
    case M.FavAddFailed{}:
      {==}
    case M.FavRemoveFailed{}:
      {==}

def Laws.fav_loading_drops_concurrent(st, ev, u):
  match st ev:
    case M.FavNotFavorite{} M.FavAdd{}:
      {==}
    case M.FavFavorite{} M.FavAdd{}:
      {==}
    case M.FavLoading{} M.FavAdd{}:
      {==}
    case M.FavAddFailed{} M.FavAdd{}:
      {==}
    case M.FavRemoveFailed{} M.FavAdd{}:
      {==}
    case M.FavNotFavorite{} M.FavRemove{}:
      {==}
    case M.FavFavorite{} M.FavRemove{}:
      {==}
    case M.FavLoading{} M.FavRemove{}:
      {==}
    case M.FavAddFailed{} M.FavRemove{}:
      {==}
    case M.FavRemoveFailed{} M.FavRemove{}:
      {==}
    case _ M.FavAddOk{}:
      Empty.absurd({M.fav_step(st, M.FavAddOk{}) == M.FavLoading{} : M.FavStatus}, NatL.false_is_not_true(u))
    case _ M.FavRemoveOk{}:
      Empty.absurd({M.fav_step(st, M.FavRemoveOk{}) == M.FavLoading{} : M.FavStatus}, NatL.false_is_not_true(u))
    case _ M.FavAddErr{}:
      Empty.absurd({M.fav_step(st, M.FavAddErr{}) == M.FavLoading{} : M.FavStatus}, NatL.false_is_not_true(u))
    case _ M.FavRemoveErr{}:
      Empty.absurd({M.fav_step(st, M.FavRemoveErr{}) == M.FavLoading{} : M.FavStatus}, NatL.false_is_not_true(u))

def Laws.fav_non_loading_ignores_completions(st, ev, nl, nc):
  match st:
    case M.FavLoading{}:
      Empty.absurd({M.fav_step(M.FavLoading{}, ev) == M.FavLoading{} : M.FavStatus}, NatL.true_is_not_false(nl))
    case M.FavNotFavorite{}:
      match ev:
        case M.FavAdd{}:
          Empty.absurd({M.FavLoading{} == M.FavNotFavorite{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavRemove{}:
          Empty.absurd({M.FavLoading{} == M.FavNotFavorite{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavAddOk{}:
          {==}
        case M.FavRemoveOk{}:
          {==}
        case M.FavAddErr{}:
          {==}
        case M.FavRemoveErr{}:
          {==}
    case M.FavFavorite{}:
      match ev:
        case M.FavAdd{}:
          Empty.absurd({M.FavLoading{} == M.FavFavorite{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavRemove{}:
          Empty.absurd({M.FavLoading{} == M.FavFavorite{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavAddOk{}:
          {==}
        case M.FavRemoveOk{}:
          {==}
        case M.FavAddErr{}:
          {==}
        case M.FavRemoveErr{}:
          {==}
    case M.FavAddFailed{}:
      match ev:
        case M.FavAdd{}:
          Empty.absurd({M.FavLoading{} == M.FavAddFailed{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavRemove{}:
          Empty.absurd({M.FavLoading{} == M.FavAddFailed{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavAddOk{}:
          {==}
        case M.FavRemoveOk{}:
          {==}
        case M.FavAddErr{}:
          {==}
        case M.FavRemoveErr{}:
          {==}
    case M.FavRemoveFailed{}:
      match ev:
        case M.FavAdd{}:
          Empty.absurd({M.FavLoading{} == M.FavRemoveFailed{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavRemove{}:
          Empty.absurd({M.FavLoading{} == M.FavRemoveFailed{} : M.FavStatus}, NatL.true_is_not_false(nc))
        case M.FavAddOk{}:
          {==}
        case M.FavRemoveOk{}:
          {==}
        case M.FavAddErr{}:
          {==}
        case M.FavRemoveErr{}:
          {==}

def Laws.fav_idempotency_and_recovery(st):
  match st:
    case M.FavNotFavorite{}:
      {==}
    case M.FavFavorite{}:
      {==}
    case M.FavLoading{}:
      {==}
    case M.FavAddFailed{}:
      {==}
    case M.FavRemoveFailed{}:
      {==}

def Laws.search_trimmed_settled_not_loading(q):
  %Equal.sym(Bool, Nat.is_eq(q, q), True{}, NatL.is_eq_same(q)) : {Bool.not(_) == False{} : Bool}
  {==}

def Laws.search_excludes_native_and_invalidates_cache(z, q, m, st, qid):
  match z st:
    case False{} M.SearchState{_, _}:
      {==}
    case True{} M.SearchState{_, _}:
      {==}

def Laws.parallel_token_metadata_equiv(name_len, sym_len, sym_kind, dom_len, dec):
  {==}
