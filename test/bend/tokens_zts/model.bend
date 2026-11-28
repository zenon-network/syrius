import Base

# Domain 3: Tokens (ZTS) protocol, capability matrix, issuance, mint/burn,
# favorites, and search state-machine specification for Syrius.
#
# Exact Zenon protocol constants:
# - Issue Plasma required = 189,000 (189k), Issue ZNN fee = 1 ZNN.
# - Token name length: 1..40; symbol length: 1..10 (excluding reserved ZNN & QSR);
#   domain length: 1..128; decimals: 0..18.
# - Supply invariants:
#     is_mintable  => 1 <= max_supply <= cap && total_supply <= max_supply
#     !is_mintable => 1 <= total_supply <= cap && effective_max_supply == total_supply
# - Capability matrix:
#     can_transfer <=> is_selected_owner
#     show_mint    <=> is_mintable && total_supply < max_supply
#     can_mint     <=> is_mintable && total_supply < max_supply && is_selected_owner
#     can_burn     <=> is_burnable || is_selected_owner  (Zenon protocol rule!)
# - Trusted token <=> is_znn || is_qsr || is_favorite.

type IssueStep is Data:
  IssuePlasma{}
  IssueZnn{}
  IssueDetails{}
  IssueFlags{}
  IssueMetrics{}
  IssueSubmit{}
  IssueDone{}

type SymbolKind is Data:
  SymZnn{}
  SymQsr{}
  SymCustom{}

type TokenCaps is Data:
  TokenCaps{can_transfer: Bool, show_mint: Bool, can_mint: Bool, can_burn: Bool, show_own_badge: Bool}

type FavStatus is Data:
  FavNotFavorite{}
  FavFavorite{}
  FavLoading{}
  FavAddFailed{}
  FavRemoveFailed{}

type FavEvent is Data:
  FavAdd{}
  FavRemove{}
  FavAddOk{}
  FavRemoveOk{}
  FavAddErr{}
  FavRemoveErr{}

type SearchState is Data:
  SearchState{settled_query_id: Nat, cache_valid: Bool}

# Issue Token 6-step prerequisite state machine
# ---------------------------------------------

def issue_plasma_req_k() -> Nat:
  189n

def issue_plasma_req_u32() -> U32:
  189000

def issue_znn_fee() -> Nat:
  1n

def issue_step_rank(+s: IssueStep) -> Nat:
  match s:
    case IssuePlasma{}:
      0n
    case IssueZnn{}:
      1n
    case IssueDetails{}:
      2n
    case IssueFlags{}:
      3n
    case IssueMetrics{}:
      4n
    case IssueSubmit{}:
      5n
    case IssueDone{}:
      6n

def pick_issue_step(+ok: Bool, +next: IssueStep, +stay: IssueStep) -> IssueStep:
  match ok:
    case True{}:
      next
    case False{}:
      stay

def advance_issue_step(
  +step: IssueStep,
  +plasma_k: Nat,
  +znn_bal: Nat,
  +details_ok: Bool,
  +metrics_ok: Bool,
  +submit_ok: Bool
) -> IssueStep:
  match step:
    case IssuePlasma{}:
      pick_issue_step(Nat.is_ge(plasma_k, issue_plasma_req_k()), IssueZnn{}, IssuePlasma{})
    case IssueZnn{}:
      pick_issue_step(Nat.is_ge(znn_bal, issue_znn_fee()), IssueDetails{}, IssueZnn{})
    case IssueDetails{}:
      pick_issue_step(details_ok, IssueFlags{}, IssueDetails{})
    case IssueFlags{}:
      IssueMetrics{}
    case IssueMetrics{}:
      pick_issue_step(metrics_ok, IssueSubmit{}, IssueMetrics{})
    case IssueSubmit{}:
      pick_issue_step(submit_ok, IssueDone{}, IssueSubmit{})
    case IssueDone{}:
      IssueDone{}

# Token identifier & metrics validators
# -------------------------------------

def valid_token_name_len(+len: Nat) -> Bool:
  Bool.and(Nat.is_ge(len, 1n), Nat.is_le(len, 40n))

def valid_token_symbol(+len: Nat, +kind: SymbolKind) -> Bool:
  match kind:
    case SymZnn{}:
      False{}
    case SymQsr{}:
      False{}
    case SymCustom{}:
      Bool.and(Nat.is_ge(len, 1n), Nat.is_le(len, 10n))

def valid_token_domain_len(+len: Nat) -> Bool:
  Bool.and(Nat.is_ge(len, 1n), Nat.is_le(len, 128n))

def valid_decimals(+dec: Nat) -> Bool:
  Nat.is_le(dec, 18n)

# Supply invariants
# -----------------

def effective_max_supply(+is_mintable: Bool, +total: Nat, +max_in: Nat) -> Nat:
  match is_mintable:
    case True{}:
      max_in
    case False{}:
      total

def valid_token_supply(+is_mintable: Bool, +total: Nat, +max_in: Nat, +cap: Nat, +dec: Nat) -> Bool:
  match is_mintable:
    case True{}:
      Bool.and(
        valid_decimals(dec),
        Bool.and(
          Nat.is_ge(max_in, 1n),
          Bool.and(
            Nat.is_le(max_in, cap),
            Nat.is_le(total, max_in))))
    case False{}:
      Bool.and(
        valid_decimals(dec),
        Bool.and(
          Nat.is_ge(total, 1n),
          Nat.is_le(total, cap)))

# Capability / authorization matrix
# ---------------------------------

def token_caps(
  +is_mintable: Bool,
  +is_burnable: Bool,
  +total: Nat,
  +max_sup: Nat,
  +is_sel_owner: Bool,
  +is_wallet_owner: Bool
) -> TokenCaps:
  +show_m = Bool.and(is_mintable, Nat.is_lt(total, max_sup))
  TokenCaps{
    is_sel_owner,
    show_m,
    Bool.and(show_m, is_sel_owner),
    Bool.or(is_burnable, is_sel_owner),
    is_wallet_owner}

def caps_can_transfer(+c: TokenCaps) -> Bool:
  match c:
    case TokenCaps{ct, _, _, _, _}:
      ct

def caps_show_mint(+c: TokenCaps) -> Bool:
  match c:
    case TokenCaps{_, sm, _, _, _}:
      sm

def caps_can_mint(+c: TokenCaps) -> Bool:
  match c:
    case TokenCaps{_, _, cm, _, _}:
      cm

def caps_can_burn(+c: TokenCaps) -> Bool:
  match c:
    case TokenCaps{_, _, _, cb, _}:
      cb

def caps_show_own_badge(+c: TokenCaps) -> Bool:
  match c:
    case TokenCaps{_, _, _, _, ob}:
      ob

# Mint & Burn bounds and supply/balance conservation
# --------------------------------------------------

def mint_remaining(+total: Nat, +max_sup: Nat) -> Nat:
  Nat.sub(max_sup, total)

def can_mint_amount(+amt: Nat, +total: Nat, +max_sup: Nat, +is_mintable: Bool, +is_sel_owner: Bool) -> Bool:
  Bool.and(
    is_mintable,
    Bool.and(
      is_sel_owner,
      Bool.and(
        Nat.is_gt(amt, 0n),
        Bool.and(
          Nat.is_le(total, max_sup),
          Nat.is_le(amt, Nat.sub(max_sup, total))))))

def apply_mint(+total: Nat, +amt: Nat) -> Nat:
  Nat.add(total, amt)

def can_burn_amount(+amt: Nat, +balance: Nat, +total: Nat, +is_burnable: Bool, +is_sel_owner: Bool) -> Bool:
  Bool.and(
    Bool.or(is_burnable, is_sel_owner),
    Bool.and(
      Nat.is_gt(amt, 0n),
      Bool.and(
        Nat.is_le(amt, balance),
        Nat.is_le(amt, total))))

def apply_burn(+value: Nat, +amt: Nat) -> Nat:
  Nat.sub(value, amt)

# Trust & TokenFavoriteBloc state machine
# ---------------------------------------

def is_trusted_token(+is_znn: Bool, +is_qsr: Bool, +is_favorite: Bool) -> Bool:
  Bool.or(is_znn, Bool.or(is_qsr, is_favorite))

def fav_is_loading(+st: FavStatus) -> Bool:
  match st:
    case FavLoading{}:
      True{}
    case _:
      False{}

def fav_is_user_event(+ev: FavEvent) -> Bool:
  match ev:
    case FavAdd{}:
      True{}
    case FavRemove{}:
      True{}
    case _:
      False{}

# Faithfully models TokenFavoriteBloc (lib/rearchitecture/features/token_favorite/bloc/token_favorite_bloc.dart):
# ONLY TokenFavoriteLoading drops incoming Add/Remove events; every non-loading state enters
# FavLoading on FavAdd/FavRemove and resolves via FavAddOk/FavAddErr/FavRemoveOk/FavRemoveErr.
def fav_step(+st: FavStatus, +ev: FavEvent) -> FavStatus:
  match st ev:
    case FavLoading{} FavAdd{}:
      FavLoading{}
    case FavLoading{} FavRemove{}:
      FavLoading{}
    case FavLoading{} FavAddOk{}:
      FavFavorite{}
    case FavLoading{} FavRemoveOk{}:
      FavNotFavorite{}
    case FavLoading{} FavAddErr{}:
      FavAddFailed{}
    case FavLoading{} FavRemoveErr{}:
      FavRemoveFailed{}
    case _ FavAdd{}:
      FavLoading{}
    case _ FavRemove{}:
      FavLoading{}
    case s _:
      s

def fav_shows_add_action(+st: FavStatus) -> Bool:
  match st:
    case FavNotFavorite{}:
      True{}
    case FavAddFailed{}:
      True{}
    case _:
      False{}

def fav_shows_remove_action(+st: FavStatus) -> Bool:
  match st:
    case FavFavorite{}:
      True{}
    case FavRemoveFailed{}:
      True{}
    case _:
      False{}

# SearchTokenBloc state machine (normative trimmed-query equality contract, native
# exclusion, cache refresh; current lib/rearchitecture/features/tokens/view/tokens_card.dart
# compares trimmed state.query against untrimmed value.text)
# ------------------------------------------------------------------------------------------

def search_is_loading(+settled_trimmed: Nat, +input_trimmed: Nat) -> Bool:
  Nat.is_ne(settled_trimmed, input_trimmed)

def search_includes_token(+is_znn: Bool, +is_qsr: Bool, +matches_query: Bool) -> Bool:
  Bool.and(Bool.not(Bool.or(is_znn, is_qsr)), matches_query)

def search_refresh(+st: SearchState, +query_id: Nat, +force_refresh: Bool) -> SearchState:
  match st force_refresh:
    case SearchState{_, _} True{}:
      SearchState{query_id, False{}}
    case SearchState{_, cache_valid} False{}:
      SearchState{query_id, cache_valid}

def search_cache_valid(+st: SearchState) -> Bool:
  match st:
    case SearchState{_, cv}:
      cv

def search_settled_query(+st: SearchState) -> Nat:
  match st:
    case SearchState{q, _}:
      q

# Parallelized multi-check helper (4-way Bend parallel-let with named defs on RHS)
# --------------------------------------------------------------------------------

def parallel_token_metadata_valid(
  +name_len: Nat,
  +sym_len: Nat,
  +sym_kind: SymbolKind,
  +dom_len: Nat,
  +dec: Nat
) -> Bool:
  n s d c = valid_token_name_len(name_len) valid_token_symbol(sym_len, sym_kind) valid_token_domain_len(dom_len) valid_decimals(dec)
  Bool.and(n, Bool.and(s, Bool.and(d, c)))
