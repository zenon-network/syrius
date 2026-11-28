import Base
import ./model.bend as M

# Domain 3: Tokens (ZTS) formal laws (28 laws).

# 1. Exact Zenon issuance constants (189,000 Plasma, 1 ZNN fee).
law issue_constants_exact:
  {Bool.and(
    U32.is_eq(M.issue_plasma_req_u32(), 189000),
    Bool.and(
      Nat.is_eq(M.issue_plasma_req_k(), 189n),
      Nat.is_eq(M.issue_znn_fee(), 1n))) == True{} : Bool}

# 2. Issue token 6-step machine never moves backward.
law issue_step_monotone:
  for +step: M.IssueStep
  for +plasma_k: Nat
  for +znn_bal: Nat
  for +details_ok: Bool
  for +metrics_ok: Bool
  for +submit_ok: Bool
  {Nat.is_le(
    M.issue_step_rank(step),
    M.issue_step_rank(M.advance_issue_step(step, plasma_k, znn_bal, details_ok, metrics_ok, submit_ok))) == True{} : Bool}

# 3. Cannot advance past plasma step with plasma < 189k.
law issue_plasma_gate:
  for +plasma_k: Nat
  for +znn_bal: Nat
  for +details_ok: Bool
  for +metrics_ok: Bool
  for +submit_ok: Bool
  for lt: {Nat.is_lt(plasma_k, M.issue_plasma_req_k()) == True{} : Bool}
  {M.advance_issue_step(M.IssuePlasma{}, plasma_k, znn_bal, details_ok, metrics_ok, submit_ok) == M.IssuePlasma{} : M.IssueStep}

# 4. Cannot advance past ZNN fee step with 0 ZNN; details/metrics/submit gates block invalid steps; Done absorbing.
law issue_prerequisite_gates:
  for +plasma_k: Nat
  for +znn_bal: Nat
  for +details_ok: Bool
  for +metrics_ok: Bool
  for +submit_ok: Bool
  {Bool.and(
    Nat.is_eq(M.issue_step_rank(M.advance_issue_step(M.IssueZnn{}, plasma_k, 0n, details_ok, metrics_ok, submit_ok)), 1n),
    Bool.and(
      Nat.is_eq(M.issue_step_rank(M.advance_issue_step(M.IssueDetails{}, plasma_k, znn_bal, False{}, metrics_ok, submit_ok)), 2n),
      Bool.and(
        Nat.is_eq(M.issue_step_rank(M.advance_issue_step(M.IssueMetrics{}, plasma_k, znn_bal, details_ok, False{}, submit_ok)), 4n),
        Bool.and(
          Nat.is_eq(M.issue_step_rank(M.advance_issue_step(M.IssueSubmit{}, plasma_k, znn_bal, details_ok, metrics_ok, False{})), 5n),
          Nat.is_eq(M.issue_step_rank(M.advance_issue_step(M.IssueDone{}, plasma_k, znn_bal, details_ok, metrics_ok, submit_ok)), 6n))))) == True{} : Bool}

# 5. Token name length bounds: rejects 0 and >= 41, accepts 1 and 40.
law token_name_bounds:
  for +k: Nat
  {Bool.and(
    Bool.not(M.valid_token_name_len(0n)),
    Bool.and(
      M.valid_token_name_len(1n),
      Bool.and(
        M.valid_token_name_len(40n),
        Bool.not(M.valid_token_name_len(41n+k))))) == True{} : Bool}

# 6. Token symbol always rejects reserved native symbols ZNN and QSR.
law token_symbol_rejects_reserved:
  for +len: Nat
  {Bool.and(
    Bool.not(M.valid_token_symbol(len, M.SymZnn{})),
    Bool.not(M.valid_token_symbol(len, M.SymQsr{}))) == True{} : Bool}

# 7. Token symbol length (1..10), domain length (1..128), and decimals (0..18) bounds.
law token_symbol_domain_decimals_bounds:
  for +k: Nat
  {Bool.and(
    Bool.not(M.valid_token_symbol(0n, M.SymCustom{})),
    Bool.and(
      M.valid_token_symbol(10n, M.SymCustom{}),
      Bool.and(
        Bool.not(M.valid_token_symbol(11n+k, M.SymCustom{})),
        Bool.and(
          Bool.not(M.valid_token_domain_len(0n)),
          Bool.and(
            M.valid_token_domain_len(128n),
            Bool.and(
              Bool.not(M.valid_token_domain_len(129n+k)),
              Bool.and(
                M.valid_decimals(0n),
                Bool.and(
                  M.valid_decimals(18n),
                  Bool.not(M.valid_decimals(19n+k)))))))))) == True{} : Bool}

# 8. Mintable token strictly rejects max_supply == 0.
law supply_mintable_rejects_zero_max:
  for +total: Nat
  for +cap: Nat
  for +dec: Nat
  {M.valid_token_supply(True{}, total, 0n, cap, dec) == False{} : Bool}

# 9. Non-mintable token sets effective_max_supply == total_supply.
law supply_non_mintable_effective_max_eq_total:
  for +total: Nat
  for +max_in: Nat
  {M.effective_max_supply(False{}, total, max_in) == total : Nat}

# 10. Every valid token satisfies total_supply <= effective_max_supply.
law supply_valid_total_le_eff_max:
  for +is_mintable: Bool
  for +total: Nat
  for +max_in: Nat
  for +cap: Nat
  for +dec: Nat
  for ok: {M.valid_token_supply(is_mintable, total, max_in, cap, dec) == True{} : Bool}
  {Nat.is_le(total, M.effective_max_supply(is_mintable, total, max_in)) == True{} : Bool}

# 11. Every valid token satisfies effective_max_supply >= 1.
law supply_valid_eff_max_positive:
  for +is_mintable: Bool
  for +total: Nat
  for +max_in: Nat
  for +cap: Nat
  for +dec: Nat
  for ok: {M.valid_token_supply(is_mintable, total, max_in, cap, dec) == True{} : Bool}
  {Nat.is_ge(M.effective_max_supply(is_mintable, total, max_in), 1n) == True{} : Bool}

# 12. Capability matrix: ownership transfer iff selected address is owner.
law caps_transfer_iff_owner:
  for +m: Bool
  for +b: Bool
  for +tot: Nat
  for +mx: Nat
  for +own: Bool
  for +wown: Bool
  {M.caps_can_transfer(M.token_caps(m, b, tot, mx, own, wown)) == own : Bool}

# 13. Non-mintable token NEVER shows or enables minting.
law caps_non_mintable_never_mints:
  for +b: Bool
  for +tot: Nat
  for +mx: Nat
  for +own: Bool
  for +wown: Bool
  {Bool.and(
    Bool.not(M.caps_show_mint(M.token_caps(False{}, b, tot, mx, own, wown))),
    Bool.not(M.caps_can_mint(M.token_caps(False{}, b, tot, mx, own, wown)))) == True{} : Bool}

# 14. Full-supply token (total >= max_supply) NEVER shows or enables minting.
law caps_full_supply_never_mints:
  for +m: Bool
  for +b: Bool
  for +tot: Nat
  for +mx: Nat
  for +own: Bool
  for +wown: Bool
  for ge: {Nat.is_ge(tot, mx) == True{} : Bool}
  {Bool.and(
    Bool.not(M.caps_show_mint(M.token_caps(m, b, tot, mx, own, wown))),
    Bool.not(M.caps_can_mint(M.token_caps(m, b, tot, mx, own, wown)))) == True{} : Bool}

# 15. Mint enabled strictly requires selected owner (non-owner cannot mint).
law caps_mint_requires_owner:
  for +m: Bool
  for +b: Bool
  for +tot: Nat
  for +mx: Nat
  for +wown: Bool
  {M.caps_can_mint(M.token_caps(m, b, tot, mx, False{}, wown)) == False{} : Bool}

# 16. Burn protocol rule: can_burn <=> is_burnable || is_selected_owner.
law caps_burn_protocol_rule:
  for +m: Bool
  for +b: Bool
  for +tot: Nat
  for +mx: Nat
  for +own: Bool
  for +wown: Bool
  {M.caps_can_burn(M.token_caps(m, b, tot, mx, own, wown)) == Bool.or(b, own) : Bool}

# 17. Valid mint preserves total_supply + amt <= max_supply.
law mint_conserves_max_supply:
  for +amt: Nat
  for +total: Nat
  for +max_sup: Nat
  for +m: Bool
  for +own: Bool
  for ok: {M.can_mint_amount(amt, total, max_sup, m, own) == True{} : Bool}
  {Nat.is_le(M.apply_mint(total, amt), max_sup) == True{} : Bool}

# 18. Valid mint strictly increases total_supply.
law mint_strictly_increases_supply:
  for +amt: Nat
  for +total: Nat
  for +max_sup: Nat
  for +m: Bool
  for +own: Bool
  for ok: {M.can_mint_amount(amt, total, max_sup, m, own) == True{} : Bool}
  {Nat.is_lt(total, M.apply_mint(total, amt)) == True{} : Bool}

# 19. Valid burn conserves balance: (bal - amt) + amt == bal.
law burn_conserves_balance:
  for +amt: Nat
  for +bal: Nat
  for +total: Nat
  for +b: Bool
  for +own: Bool
  for ok: {M.can_burn_amount(amt, bal, total, b, own) == True{} : Bool}
  {Nat.add(M.apply_burn(bal, amt), amt) == bal : Nat}

# 20. Valid burn strictly reduces total_supply and never exceeds total_supply.
law burn_reduces_total_supply:
  for +amt: Nat
  for +bal: Nat
  for +total: Nat
  for +b: Bool
  for +own: Bool
  for ok: {M.can_burn_amount(amt, bal, total, b, own) == True{} : Bool}
  {Nat.is_lt(M.apply_burn(total, amt), total) == True{} : Bool}

# 21. Trusted token iff ZNN, QSR, or user favorite.
law trusted_token_iff_native_or_fav:
  for +z: Bool
  for +q: Bool
  for +f: Bool
  {Bool.and(
    M.is_trusted_token(True{}, q, f),
    Bool.and(
      M.is_trusted_token(z, True{}, f),
      Bool.not(Bool.xor(M.is_trusted_token(False{}, False{}, f), f)))) == True{} : Bool}

# 22. TokenFavoriteBloc add and remove actions are mutually exclusive for every state.
law fav_actions_disjoint:
  for +st: M.FavStatus
  {Bool.and(M.fav_shows_add_action(st), M.fav_shows_remove_action(st)) == False{} : Bool}

# 23. TokenFavoriteBloc loading guard: any user event (FavAdd/FavRemove) from any state
#     enters/stays in FavLoading (dropping concurrent events while loading and hiding both actions).
law fav_loading_drops_concurrent:
  for +st: M.FavStatus
  for +ev: M.FavEvent
  for u: {M.fav_is_user_event(ev) == True{} : Bool}
  {M.fav_step(st, ev) == M.FavLoading{} : M.FavStatus}

# 24. TokenFavoriteBloc ignores completion events (Ok/Err) when not in FavLoading.
law fav_non_loading_ignores_completions:
  for +st: M.FavStatus
  for +ev: M.FavEvent
  for nl: {M.fav_is_loading(st) == False{} : Bool}
  for nc: {M.fav_is_user_event(ev) == False{} : Bool}
  {M.fav_step(st, ev) == st : M.FavStatus}

# 25. TokenFavoriteBloc add/remove idempotency & failure recovery from every state via Ok/Err.
law fav_idempotency_and_recovery:
  for +st: M.FavStatus
  {Bool.and(
    Bool.not(M.fav_shows_add_action(M.FavLoading{})),
    Bool.and(
      Bool.not(M.fav_shows_remove_action(M.FavLoading{})),
      Bool.and(
        M.fav_shows_remove_action(M.fav_step(M.fav_step(st, M.FavAdd{}), M.FavAddOk{})),
        Bool.and(
          M.fav_shows_add_action(M.fav_step(M.fav_step(st, M.FavRemove{}), M.FavRemoveOk{})),
          Bool.and(
            M.fav_shows_add_action(M.fav_step(M.fav_step(st, M.FavAdd{}), M.FavAddErr{})),
            M.fav_shows_remove_action(M.fav_step(M.fav_step(st, M.FavRemove{}), M.FavRemoveErr{}))))))) == True{} : Bool}

# 24. SearchTokenBloc: matching trimmed query is NEVER stuck loading (prevents whitespace spinner bug).
law search_trimmed_settled_not_loading:
  for +q: Nat
  {M.search_is_loading(q, q) == False{} : Bool}

# 25. SearchTokenBloc excludes native coins {ZNN, QSR} and invalidates cache on force refresh.
law search_excludes_native_and_invalidates_cache:
  for +z: Bool
  for +q: Bool
  for +m: Bool
  for +st: M.SearchState
  for +qid: Nat
  {Bool.and(
    Bool.not(M.search_includes_token(True{}, q, m)),
    Bool.and(
      Bool.not(M.search_includes_token(z, True{}, m)),
      Bool.not(M.search_cache_valid(M.search_refresh(st, qid, True{}))))) == True{} : Bool}

# 26. Parallel 4-way metadata validation equals sequential conjunction.
law parallel_token_metadata_equiv:
  for +name_len: Nat
  for +sym_len: Nat
  for +sym_kind: M.SymbolKind
  for +dom_len: Nat
  for +dec: Nat
  {M.parallel_token_metadata_valid(name_len, sym_len, sym_kind, dom_len, dec) == Bool.and(M.valid_token_name_len(name_len), Bool.and(M.valid_token_symbol(sym_len, sym_kind), Bool.and(M.valid_token_domain_len(dom_len), M.valid_decimals(dec)))) : Bool}
