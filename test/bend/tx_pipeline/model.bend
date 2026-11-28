import Base

# Formal verification model for Syrius transaction pipeline, per-address
# send locking, PoW ref-counting, auto-receive worker, confirmation polling,
# InfiniteListBloc pagination/fencing, FetchBloc loading, TimerState,
# BalanceCubit, and AccountChainStats pagination.
#
# Grounded in:
# - lib/utils/account_block_utils.dart
# - lib/rearchitecture/features/pow_generating_status/bloc/pow_generating_status_bloc.dart
# - lib/rearchitecture/features/auto_receive_tx/cubit/auto_receive_tx_worker.dart
# - lib/rearchitecture/utils/functions/poll_until_confirmed.dart
# - lib/rearchitecture/utils/blocs/infinite_list/infinite_list_bloc.dart
# - lib/rearchitecture/utils/blocs/fetch_bloc/fetch_bloc.dart
# - lib/rearchitecture/utils/cubits/timer_cubit.dart
# - lib/rearchitecture/utils/cubits/timer_state.dart
# - lib/rearchitecture/features/balance/cubit/balance_cubit.dart
# - lib/rearchitecture/features/account_chain_stats/bloc/account_chain_stats_bloc.dart

def bool_eq(+a: Bool, +b: Bool) -> Bool:
  match a b:
    case False{} False{}:
      True{}
    case True{} True{}:
      True{}
    case _ _:
      False{}

# =============================================================================
# 1. AccountBlockUtils.createAccountBlock preconditions & wallet-identity fence
# =============================================================================

type SyncStateKind is Data:
  SyncUnknown{}
  Syncing{}
  SyncDone{}
  NotEnoughPeers{}

def sync_is_done(+st: SyncStateKind) -> Bool:
  match st:
    case SyncDone{}:
      True{}
    case _:
      False{}

# AccountBlockUtils.createAccountBlock (lines 89-93):
# syncInfo.state == SyncState.syncDone ||
#   (targetHeight > 0 && currentHeight > 0 && targetHeight - currentHeight < 20)
def node_is_synced_for_tx(+st: SyncStateKind, +cur: Nat, +tgt: Nat) -> Bool:
  Bool.or(
    sync_is_done(st),
    Bool.and(
      Nat.is_gt(tgt, 0n),
      Bool.and(
        Nat.is_gt(cur, 0n),
        Nat.is_lt(Nat.sub(tgt, cur), 20n)
      )
    )
  )

type PrecondOutcome is Data:
  PrecondOk{addr: Nat, wallet_id: Nat}
  ErrNodeNotSynced{}
  ErrNoAddressSelected{}
  ErrAddressNotInWallet{}
  ErrWalletNotUnlocked{}

def resolve_address(+explicit_addr: Maybe<&2, Nat>, +selected_addr: Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match explicit_addr:
    case Some{a}:
      Some{a}
    case None{}:
      selected_addr

def check_precond_wallet(+addr: Nat, +wallet_id: Maybe<&2, Nat>) -> PrecondOutcome:
  match wallet_id:
    case None{}:
      ErrWalletNotUnlocked{}
    case Some{wid}:
      PrecondOk{addr, wid}

def check_precond_membership(+addr: Nat, +addr_in_wallet: Bool, +wallet_id: Maybe<&2, Nat>) -> PrecondOutcome:
  match addr_in_wallet:
    case False{}:
      ErrAddressNotInWallet{}
    case True{}:
      check_precond_wallet(addr, wallet_id)

def check_precond_address(+resolved: Maybe<&2, Nat>, +addr_in_wallet: Bool, +wallet_id: Maybe<&2, Nat>) -> PrecondOutcome:
  match resolved:
    case None{}:
      ErrNoAddressSelected{}
    case Some{a}:
      check_precond_membership(a, addr_in_wallet, wallet_id)

def check_precond_gate(+synced: Bool, +explicit_addr: Maybe<&2, Nat>, +selected_addr: Maybe<&2, Nat>, +addr_in_wallet: Bool, +wallet_id: Maybe<&2, Nat>) -> PrecondOutcome:
  match synced:
    case False{}:
      ErrNodeNotSynced{}
    case True{}:
      check_precond_address(resolve_address(explicit_addr, selected_addr), addr_in_wallet, wallet_id)

def check_create_preconditions(+st: SyncStateKind, +cur: Nat, +tgt: Nat, +explicit_addr: Maybe<&2, Nat>, +selected_addr: Maybe<&2, Nat>, +addr_in_wallet: Bool, +wallet_id: Maybe<&2, Nat>) -> PrecondOutcome:
  check_precond_gate(node_is_synced_for_tx(st, cur, tgt), explicit_addr, selected_addr, addr_in_wallet, wallet_id)

# Wallet-identity fence across lock acquisition and walletFile.access
# (AccountBlockUtils._createAndPublishAccountBlock lines 140-191).
def wallet_identity_matches(+expected_wid: Nat, +current_wallet: Maybe<&2, Nat>) -> Bool:
  match current_wallet:
    case None{}:
      False{}
    case Some{wid}:
      Nat.is_eq(expected_wid, wid)

type PublishFenceOutcome is Data:
  PublishAllowed{}
  AbortedWalletChanged{}
  AbortedAddressRemoved{}

def publish_is_allowed(+o: PublishFenceOutcome) -> Bool:
  match o:
    case PublishAllowed{}:
      True{}
    case _:
      False{}

def check_publish_fence_access(+ok_access: Bool) -> PublishFenceOutcome:
  match ok_access:
    case False{}:
      AbortedWalletChanged{}
    case True{}:
      PublishAllowed{}

def check_publish_fence_addr(+addr_still_in_wallet: Bool, +expected_wid: Nat, +wallet_in_access: Maybe<&2, Nat>) -> PublishFenceOutcome:
  match addr_still_in_wallet:
    case False{}:
      AbortedAddressRemoved{}
    case True{}:
      check_publish_fence_access(wallet_identity_matches(expected_wid, wallet_in_access))

def check_publish_fence_lock(+ok_lock: Bool, +addr_still_in_wallet: Bool, +expected_wid: Nat, +wallet_in_access: Maybe<&2, Nat>) -> PublishFenceOutcome:
  match ok_lock:
    case False{}:
      AbortedWalletChanged{}
    case True{}:
      check_publish_fence_addr(addr_still_in_wallet, expected_wid, wallet_in_access)

def check_publish_fence(+expected_wid: Nat, +wallet_after_lock: Maybe<&2, Nat>, +addr_still_in_wallet: Bool, +wallet_in_access: Maybe<&2, Nat>) -> PublishFenceOutcome:
  check_publish_fence_lock(
    wallet_identity_matches(expected_wid, wallet_after_lock),
    addr_still_in_wallet,
    expected_wid,
    wallet_in_access
  )

# =============================================================================
# 2. Per-address send lock ref-counter (_withAddressSendLock)
# =============================================================================

type AddrLockState is Data:
  AddrLockState{active_count: Nat, entry_present: Bool}

def lock_init() -> AddrLockState:
  AddrLockState{0n, False{}}

def lock_count(+s: AddrLockState) -> Nat:
  match s:
    case AddrLockState{c, _}:
      c

def lock_entry_present(+s: AddrLockState) -> Bool:
  match s:
    case AddrLockState{_, p}:
      p

def lock_entry_evicted(+s: AddrLockState) -> Bool:
  Bool.not(lock_entry_present(s))

def lock_acquire(+s: AddrLockState) -> AddrLockState:
  match s:
    case AddrLockState{c, _}:
      AddrLockState{1n+c, True{}}

def lock_release(+s: AddrLockState) -> AddrLockState:
  match s:
    case AddrLockState{c, _}:
      +next = Nat.sub(c, 1n)
      AddrLockState{next, Nat.is_gt(next, 0n)}

def lock_acquire_n(+n: Nat, +s: AddrLockState) -> AddrLockState:
  match n:
    case 0n:
      s
    case 1n+p:
      lock_acquire_n(p, lock_acquire(s))

def lock_release_n(+n: Nat, +s: AddrLockState) -> AddrLockState:
  match n:
    case 0n:
      s
    case 1n+p:
      lock_release_n(p, lock_release(s))

# =============================================================================
# 3. PowGeneratingStatusBloc ref-count reducer & HW review deferral
# =============================================================================

type PowEvent is Data:
  PowGenerating{}
  PowDone{}

type PowStatusKind is Data:
  PowIdle{}
  PowActive{}

def pow_status_eq(+a: PowStatusKind, +b: PowStatusKind) -> Bool:
  match a b:
    case PowIdle{} PowIdle{}:
      True{}
    case PowActive{} PowActive{}:
      True{}
    case _ _:
      False{}

type PowState is Data:
  PowState{active_count: Nat, status: PowStatusKind}

type PowStepResult is Data:
  PowStepResult{next_state: PowState, emitted: Bool}

def pow_init() -> PowState:
  PowState{0n, PowIdle{}}

def pow_count(+s: PowState) -> Nat:
  match s:
    case PowState{c, _}:
      c

def pow_status(+s: PowState) -> PowStatusKind:
  match s:
    case PowState{_, st}:
      st

def pow_is_generating(+s: PowState) -> Bool:
  match s:
    case PowState{_, PowActive{}}:
      True{}
    case PowState{_, PowIdle{}}:
      False{}

def pow_status_for_count(+c: Nat) -> PowStatusKind:
  match c:
    case 0n:
      PowIdle{}
    case 1n+_:
      PowActive{}

def pow_next_count(+c: Nat, +ev: PowEvent) -> Nat:
  match ev:
    case PowGenerating{}:
      1n+c
    case PowDone{}:
      Nat.sub(c, 1n)

def pow_step(+s: PowState, +ev: PowEvent) -> PowStepResult:
  match s:
    case PowState{c, st}:
      +nc = pow_next_count(c, ev)
      +nst = pow_status_for_count(nc)
      PowStepResult{PowState{nc, nst}, Bool.not(pow_status_eq(st, nst))}

def pow_res_state(+r: PowStepResult) -> PowState:
  match r:
    case PowStepResult{ns, _}:
      ns

def pow_res_emitted(+r: PowStepResult) -> Bool:
  match r:
    case PowStepResult{_, em}:
      em

def pow_step_state(+s: PowState, +ev: PowEvent) -> PowState:
  pow_res_state(pow_step(s, ev))

def pow_step_emitted(+s: PowState, +ev: PowEvent) -> Bool:
  pow_res_emitted(pow_step(s, ev))

def pow_apply_n_gen(+n: Nat, +s: PowState) -> PowState:
  match n:
    case 0n:
      s
    case 1n+p:
      pow_apply_n_gen(p, pow_step_state(s, PowGenerating{}))

def pow_apply_n_done(+n: Nat, +s: PowState) -> PowState:
  match n:
    case 0n:
      s
    case 1n+p:
      pow_apply_n_done(p, pow_step_state(s, PowDone{}))

# AccountBlockUtils._prepareAndSend (lines 241-265):
# HW review notification deferred until PowStatus.done iff need_plasma, else immediate.
type ReviewTiming is Data:
  NoReview{}
  ReviewImmediate{}
  ReviewDeferredUntilPowDone{}

def hw_review_timing(+need_review: Bool, +need_plasma: Bool) -> ReviewTiming:
  match need_review need_plasma:
    case False{} _:
      NoReview{}
    case True{} False{}:
      ReviewImmediate{}
    case True{} True{}:
      ReviewDeferredUntilPowDone{}

def review_is_deferred(+rt: ReviewTiming) -> Bool:
  match rt:
    case ReviewDeferredUntilPowDone{}:
      True{}
    case _:
      False{}

# =============================================================================
# 4. AutoReceiveTxWorker queue / mutex / preemption machine
# =============================================================================

def nat_list_len(+xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case _ <> t:
      1n+nat_list_len(t)

def nat_list_is_empty(+xs: List<&2, Nat>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case _ <> _:
      False{}

def nat_list_contains(+xs: List<&2, Nat>, +x: Nat) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(Nat.is_eq(h, x), nat_list_contains(t, x))

def nat_list_snoc(+xs: List<&2, Nat>, +x: Nat) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      x <> Nil{}
    case h <> t:
      h <> nat_list_snoc(t, x)

type AutoReceiveState is Data:
  AutoReceiveState{pool: List<&2, Nat>, running: Bool, notif_seq: Nat}

def ar_pool(+s: AutoReceiveState) -> List<&2, Nat>:
  match s:
    case AutoReceiveState{p, _, _}:
      p

def ar_running(+s: AutoReceiveState) -> Bool:
  match s:
    case AutoReceiveState{_, r, _}:
      r

def ar_notif_seq(+s: AutoReceiveState) -> Nat:
  match s:
    case AutoReceiveState{_, _, n}:
      n

def ar_add_hash_gate(+can_add: Bool, +s: AutoReceiveState, +hash: Nat) -> AutoReceiveState:
  match can_add:
    case False{}:
      s
    case True{}:
      match s:
        case AutoReceiveState{p, r, n}:
          AutoReceiveState{nat_list_snoc(p, hash), r, n}

# AutoReceiveTxWorker.addHash (line 212):
# if (!_pool.contains(hash) && syncInfo.isSynced) { _pool.add(hash); }
def auto_receive_add_hash(+s: AutoReceiveState, +hash: Nat, +is_synced: Bool) -> AutoReceiveState:
  ar_add_hash_gate(
    Bool.and(Bool.not(nat_list_contains(ar_pool(s), hash)), is_synced),
    s,
    hash
  )

type ReceiveOutcome is Data:
  ReceiveOk{}
  ReceiveAlreadyReceived{}
  ReceiveOtherError{}

type AutoReceiveStepResult is Data:
  AutoReceiveStepResult{state: AutoReceiveState, should_continue: Bool, accepted: Bool}

def ar_res_state(+r: AutoReceiveStepResult) -> AutoReceiveState:
  match r:
    case AutoReceiveStepResult{s, _, _}:
      s

def ar_res_continue(+r: AutoReceiveStepResult) -> Bool:
  match r:
    case AutoReceiveStepResult{_, c, _}:
      c

def ar_res_accepted(+r: AutoReceiveStepResult) -> Bool:
  match r:
    case AutoReceiveStepResult{_, _, a}:
      a

def ar_enter_check(+blocked: Bool, +s: AutoReceiveState) -> AutoReceiveStepResult:
  match blocked:
    case True{}:
      AutoReceiveStepResult{s, False{}, False{}}
    case False{}:
      match s:
        case AutoReceiveState{p, _, n}:
          AutoReceiveStepResult{AutoReceiveState{p, True{}, n}, True{}, True{}}

# AutoReceiveTxWorker.autoReceive entry guard (lines 138-148).
def auto_receive_enter(+s: AutoReceiveState, +enabled: Bool, +htlc_unlocking: Bool) -> AutoReceiveStepResult:
  match s enabled:
    case AutoReceiveState{_, r, n} False{}:
      AutoReceiveStepResult{AutoReceiveState{Nil{}, r, n}, False{}, False{}}
    case AutoReceiveState{p, r, n} True{}:
      ar_enter_check(
        Bool.or(r, Bool.or(nat_list_is_empty(p), htlc_unlocking)),
        AutoReceiveState{p, r, n}
      )

def ar_step_pool(+pool: List<&2, Nat>, +running: Bool, +seq: Nat, +outcome: ReceiveOutcome) -> AutoReceiveStepResult:
  match pool:
    case Nil{}:
      AutoReceiveStepResult{AutoReceiveState{Nil{}, running, seq}, False{}, False{}}
    case h <> t:
      match outcome:
        case ReceiveOk{}:
          AutoReceiveStepResult{AutoReceiveState{t, running, 1n+seq}, True{}, True{}}
        case ReceiveAlreadyReceived{}:
          AutoReceiveStepResult{AutoReceiveState{t, running, 1n+seq}, True{}, True{}}
        case ReceiveOtherError{}:
          AutoReceiveStepResult{AutoReceiveState{h <> t, running, 1n+seq}, False{}, True{}}

def ar_step_htlc(+htlc_unlocking: Bool, +s: AutoReceiveState, +outcome: ReceiveOutcome) -> AutoReceiveStepResult:
  match htlc_unlocking:
    case True{}:
      AutoReceiveStepResult{s, False{}, False{}}
    case False{}:
      match s:
        case AutoReceiveState{p, r, n}:
          ar_step_pool(p, r, n, outcome)

# AutoReceiveTxWorker.autoReceive loop body (lines 150-200).
def auto_receive_loop_step(+s: AutoReceiveState, +enabled: Bool, +htlc_unlocking: Bool, +outcome: ReceiveOutcome) -> AutoReceiveStepResult:
  match s enabled:
    case AutoReceiveState{_, r, n} False{}:
      AutoReceiveStepResult{AutoReceiveState{Nil{}, r, n}, False{}, False{}}
    case AutoReceiveState{p, r, n} True{}:
      ar_step_htlc(htlc_unlocking, AutoReceiveState{p, r, n}, outcome)

# =============================================================================
# 5. pollUntilConfirmed (lib/rearchitecture/utils/functions/poll_until_confirmed.dart)
# =============================================================================

type PollFetchOutcome is Data:
  FetchConfirmed{}
  FetchNotConfirmed{}
  FetchTransientError{}
  FetchTimedOut{}

type PollStepDecision is Data:
  PollDone{confirmed: Bool}
  PollSleep{sleep_ms: Nat}

def poll_sleep_gate(+too_late: Bool, +poll_interval: Nat) -> PollStepDecision:
  match too_late:
    case True{}:
      PollDone{False{}}
    case False{}:
      PollSleep{poll_interval}

def poll_after_fetch(+cancelled_after: Bool, +rem_after: Nat, +poll_interval: Nat) -> PollStepDecision:
  match cancelled_after:
    case True{}:
      PollDone{False{}}
    case False{}:
      poll_sleep_gate(Nat.is_le(rem_after, poll_interval), poll_interval)

def poll_on_outcome(+outcome: PollFetchOutcome, +cancelled_after: Bool, +rem_after: Nat, +poll_interval: Nat) -> PollStepDecision:
  match outcome:
    case FetchTimedOut{}:
      PollDone{False{}}
    case FetchConfirmed{}:
      PollDone{True{}}
    case FetchNotConfirmed{}:
      poll_after_fetch(cancelled_after, rem_after, poll_interval)
    case FetchTransientError{}:
      poll_after_fetch(cancelled_after, rem_after, poll_interval)

def poll_check_budget(+rem_before: Nat, +outcome: PollFetchOutcome, +cancelled_after: Bool, +rem_after: Nat, +poll_interval: Nat) -> PollStepDecision:
  match rem_before:
    case 0n:
      PollDone{False{}}
    case 1n+_:
      poll_on_outcome(outcome, cancelled_after, rem_after, poll_interval)

def poll_step(+cancelled_before: Bool, +rem_before: Nat, +outcome: PollFetchOutcome, +cancelled_after: Bool, +rem_after: Nat, +poll_interval: Nat) -> PollStepDecision:
  match cancelled_before:
    case True{}:
      PollDone{False{}}
    case False{}:
      poll_check_budget(rem_before, outcome, cancelled_after, rem_after, poll_interval)

def poll_decision_within_deadline(+rem_after: Nat, +dec: PollStepDecision) -> Bool:
  match dec:
    case PollDone{_}:
      True{}
    case PollSleep{ms}:
      Nat.is_lt(ms, rem_after)

# =============================================================================
# 6. InfiniteListBloc pagination & generation fencing
# =============================================================================

type ListStatus is Data:
  ListInitial{}
  ListSuccess{}
  ListFailure{}

type InfiniteListModel is Data:
  InfiniteListModel{
    status: ListStatus,
    item_count: Nat,
    has_reached_max: Bool,
    active_req_id: Nat,
    active_addr: Maybe<&2, Nat>,
    page_size: Nat
  }

def il_page_index(+item_count: Nat, +page_size: Nat) -> Nat:
  Nat.div(item_count, page_size)

def il_has_reached_max(+s: InfiniteListModel) -> Bool:
  match s:
    case InfiniteListModel{_, _, hrm, _, _, _}:
      hrm

def il_page_size(+s: InfiniteListModel) -> Nat:
  match s:
    case InfiniteListModel{_, _, _, _, _, ps}:
      ps

def il_active_req_id(+s: InfiniteListModel) -> Nat:
  match s:
    case InfiniteListModel{_, _, _, rid, _, _}:
      rid

def il_begin_first_page(+s: InfiniteListModel, +addr: Maybe<&2, Nat>, +is_refresh: Bool) -> InfiniteListModel:
  match s is_refresh:
    case InfiniteListModel{_, _, _, rid, _, ps} True{}:
      InfiniteListModel{ListInitial{}, 0n, False{}, 1n+rid, addr, ps}
    case InfiniteListModel{st, cnt, hrm, rid, _, ps} False{}:
      InfiniteListModel{st, cnt, hrm, 1n+rid, addr, ps}

def il_apply_first_gate(+matches: Bool, +s: InfiniteListModel, +fetched_len: Nat, +ok: Bool) -> InfiniteListModel:
  match matches:
    case False{}:
      s
    case True{}:
      match s ok:
        case InfiniteListModel{_, _, _, rid, aa, ps} True{}:
          InfiniteListModel{ListSuccess{}, fetched_len, Nat.is_lt(fetched_len, ps), rid, aa, ps}
        case InfiniteListModel{_, cnt, hrm, rid, aa, ps} False{}:
          InfiniteListModel{ListFailure{}, cnt, hrm, rid, aa, ps}

def il_apply_first_page(+s: InfiniteListModel, +req_id: Nat, +fetched_len: Nat, +ok: Bool) -> InfiniteListModel:
  il_apply_first_gate(Nat.is_eq(req_id, il_active_req_id(s)), s, fetched_len, ok)

def il_addr_compatible(+active_req_id: Nat, +active_addr: Maybe<&2, Nat>, +event_addr: Maybe<&2, Nat>) -> Bool:
  match active_req_id:
    case 0n:
      True{}
    case 1n+_:
      match active_addr event_addr:
        case Some{aa} Some{ea}:
          Nat.is_eq(ea, aa)
        case _ _:
          True{}

def il_can_load_more(+s: InfiniteListModel, +event_addr: Maybe<&2, Nat>) -> Bool:
  match s:
    case InfiniteListModel{_, _, True{}, _, _, _}:
      False{}
    case InfiniteListModel{_, _, False{}, rid, aa, _}:
      il_addr_compatible(rid, aa, event_addr)

def il_apply_more_gate(+allowed: Bool, +s: InfiniteListModel, +fetched_len: Nat, +ok: Bool) -> InfiniteListModel:
  match allowed:
    case False{}:
      s
    case True{}:
      match s ok:
        case InfiniteListModel{_, cnt, _, rid, aa, ps} True{}:
          InfiniteListModel{ListSuccess{}, Nat.add(cnt, fetched_len), Nat.is_lt(fetched_len, ps), rid, aa, ps}
        case InfiniteListModel{_, cnt, hrm, rid, aa, ps} False{}:
          InfiniteListModel{ListFailure{}, cnt, hrm, rid, aa, ps}

def il_apply_more_page(+s: InfiniteListModel, +req_id: Nat, +snapshot_count: Nat, +event_addr: Maybe<&2, Nat>, +fetched_len: Nat, +ok: Bool) -> InfiniteListModel:
  match s:
    case InfiniteListModel{st, cnt, hrm, rid, aa, ps}:
      +cur = {InfiniteListModel{st, cnt, hrm, rid, aa, ps} : InfiniteListModel}
      +ok_fence = Bool.and(
        il_can_load_more(cur, event_addr),
        Bool.and(Nat.is_eq(req_id, rid), Nat.is_eq(cnt, snapshot_count))
      )
      il_apply_more_gate(ok_fence, cur, fetched_len, ok)

# =============================================================================
# 7. FetchBloc, TimerState, BalanceCubit & AccountChainStats
# =============================================================================

type FetchLoadingState is Data:
  FetchLoadingState{in_flight: Nat, is_loading: Bool}

def fetch_in_flight(+s: FetchLoadingState) -> Nat:
  match s:
    case FetchLoadingState{c, _}:
      c

def fetch_is_loading(+s: FetchLoadingState) -> Bool:
  match s:
    case FetchLoadingState{_, l}:
      l

def fetch_begin(+s: FetchLoadingState) -> FetchLoadingState:
  match s:
    case FetchLoadingState{c, _}:
      FetchLoadingState{1n+c, True{}}

def fetch_end(+s: FetchLoadingState) -> FetchLoadingState:
  match s:
    case FetchLoadingState{c, _}:
      +next = Nat.sub(c, 1n)
      FetchLoadingState{next, Nat.is_gt(next, 0n)}

type TimerStatusKind is Data:
  TimerInitial{}
  TimerLoading{}
  TimerSuccess{}
  TimerFailure{}

type TimerStateModel is Data:
  TimerStateModel{status: TimerStatusKind, has_data: Bool, has_error: Bool}

def timer_state_valid(+s: TimerStateModel) -> Bool:
  match s:
    case TimerStateModel{TimerInitial{}, hd, he}:
      Bool.and(Bool.not(hd), Bool.not(he))
    case TimerStateModel{TimerSuccess{}, hd, _}:
      hd
    case TimerStateModel{TimerFailure{}, _, he}:
      he
    case TimerStateModel{TimerLoading{}, _, _}:
      True{}

# TimerCubit.fetchDataPeriodically (lines 76-100):
# Preserves success without loading flicker; ws closed or fetch error -> failure with error;
# fetch ok -> success with data.
def timer_enters_loading(+s: TimerStateModel) -> Bool:
  match s:
    case TimerStateModel{TimerSuccess{}, _, _}:
      False{}
    case _:
      True{}

def timer_step_fetch(+s: TimerStateModel, +ws_open: Bool, +fetch_ok: Bool) -> TimerStateModel:
  match s:
    case TimerStateModel{_, hd, he}:
      match ws_open fetch_ok:
        case False{} _:
          TimerStateModel{TimerFailure{}, hd, True{}}
        case True{} False{}:
          TimerStateModel{TimerFailure{}, hd, True{}}
        case True{} True{}:
          TimerStateModel{TimerSuccess{}, True{}, he}

# BalanceCubit.fetch (lines 35-40):
# blockCount > 0 && (znn > 0 || qsr > 0)
def balance_is_populated(+block_count: Nat, +znn: Nat, +qsr: Nat) -> Bool:
  Bool.and(
    Nat.is_gt(block_count, 0n),
    Bool.or(Nat.is_gt(znn, 0n), Nat.is_gt(qsr, 0n))
  )

# AccountChainStatsBloc.getData (line 40):
# pageCount = (blockCount / rpcMaxPageSize).ceil()
def ceil_div(+block_count: Nat, +page_size: Nat) -> Nat:
  match block_count page_size:
    case 0n _:
      0n
    case _ 0n:
      0n
    case 1n+bp 1n+pp:
      1n+Nat.div(bp, 1n+pp)

# =============================================================================
# 8. Parallelized multi-invariant evaluator (Bend parallel-let)
# =============================================================================

type TxBatchCheck is Data:
  TxBatchCheck{
    synced_ok: Bool,
    fence_ok: Bool,
    pow_ok: Bool,
    poll_ok: Bool
  }

def eval_branch_sync(+st: SyncStateKind, +cur: Nat, +tgt: Nat) -> Bool:
  node_is_synced_for_tx(st, cur, tgt)

def eval_branch_fence(+wid: Nat, +w_lock: Maybe<&2, Nat>, +addr_ok: Bool, +w_acc: Maybe<&2, Nat>) -> Bool:
  publish_is_allowed(check_publish_fence(wid, w_lock, addr_ok, w_acc))

def eval_branch_pow(+ps: PowState, +ev: PowEvent) -> Bool:
  +ns = pow_step_state(ps, ev)
  bool_eq(pow_is_generating(ns), Nat.is_gt(pow_count(ns), 0n))

def eval_branch_poll(+rem_after: Nat, +poll_interval: Nat, +out: PollFetchOutcome) -> Bool:
  poll_decision_within_deadline(
    rem_after,
    poll_step(False{}, 1n, out, False{}, rem_after, poll_interval)
  )

def eval_tx_batch_par(
  +st: SyncStateKind, +cur: Nat, +tgt: Nat,
  +wid: Nat, +w_lock: Maybe<&2, Nat>, +addr_ok: Bool, +w_acc: Maybe<&2, Nat>,
  +ps: PowState, +ev: PowEvent,
  +rem_after: Nat, +poll_interval: Nat, +out: PollFetchOutcome
) -> TxBatchCheck:
  b1 b2 b3 b4 = eval_branch_sync(st, cur, tgt) eval_branch_fence(wid, w_lock, addr_ok, w_acc) eval_branch_pow(ps, ev) eval_branch_poll(rem_after, poll_interval, out)
  TxBatchCheck{b1, b2, b3, b4}

def eval_tx_batch_seq(
  +st: SyncStateKind, +cur: Nat, +tgt: Nat,
  +wid: Nat, +w_lock: Maybe<&2, Nat>, +addr_ok: Bool, +w_acc: Maybe<&2, Nat>,
  +ps: PowState, +ev: PowEvent,
  +rem_after: Nat, +poll_interval: Nat, +out: PollFetchOutcome
) -> TxBatchCheck:
  TxBatchCheck{
    eval_branch_sync(st, cur, tgt),
    eval_branch_fence(wid, w_lock, addr_ok, w_acc),
    eval_branch_pow(ps, ev),
    eval_branch_poll(rem_after, poll_interval, out)
  }
