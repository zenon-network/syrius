import Base
import ./model.bend as M

# Formal verification laws for Syrius transaction pipeline, send locks, PoW,
# auto-receive worker, confirmation polling, and BLoC list/fetch/timer invariants.

# --- 1. AccountBlockUtils preconditions & wallet-identity fence ---

law tx_sync_done_always_synced:
  for +cur: Nat
  for +tgt: Nat
  {M.node_is_synced_for_tx(M.SyncDone{}, cur, tgt) == True{} : Bool}

law tx_sync_zero_target_not_synced:
  for +cur: Nat
  {M.node_is_synced_for_tx(M.Syncing{}, cur, 0n) == False{} : Bool}

law tx_sync_boundary_19_synced:
  for +cp: Nat
  {M.node_is_synced_for_tx(M.Syncing{}, 1n+cp, Nat.add(1n+cp, 19n)) == True{} : Bool}

law tx_sync_boundary_20_unsynced:
  for +cp: Nat
  {M.node_is_synced_for_tx(M.Syncing{}, 1n+cp, Nat.add(1n+cp, 20n)) == False{} : Bool}

law tx_precond_unsynced_rejected:
  for +st: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for +ea: Maybe<&2, Nat>
  for +sa: Maybe<&2, Nat>
  for +in_w: Bool
  for +wid: Maybe<&2, Nat>
  for e: {M.node_is_synced_for_tx(st, cur, tgt) == False{} : Bool}
  {M.check_create_preconditions(st, cur, tgt, ea, sa, in_w, wid) == M.ErrNodeNotSynced{} : M.PrecondOutcome}

law tx_precond_addr_not_in_wallet_rejected:
  for +cur: Nat
  for +tgt: Nat
  for +addr: Nat
  for +sa: Maybe<&2, Nat>
  for +wid: Maybe<&2, Nat>
  {M.check_create_preconditions(M.SyncDone{}, cur, tgt, Some{addr}, sa, False{}, wid) == M.ErrAddressNotInWallet{} : M.PrecondOutcome}

law tx_precond_wallet_locked_rejected:
  for +cur: Nat
  for +tgt: Nat
  for +addr: Nat
  for +sa: Maybe<&2, Nat>
  {M.check_create_preconditions(M.SyncDone{}, cur, tgt, Some{addr}, sa, True{}, None{}) == M.ErrWalletNotUnlocked{} : M.PrecondOutcome}

law tx_publish_fence_locked_after_lock_aborts:
  for +wid: Nat
  for +addr_ok: Bool
  for +w_acc: Maybe<&2, Nat>
  {M.check_publish_fence(wid, None{}, addr_ok, w_acc) == M.AbortedWalletChanged{} : M.PublishFenceOutcome}

law tx_publish_fence_swapped_after_lock_aborts:
  for +wid: Nat
  for +other: Nat
  for +addr_ok: Bool
  for +w_acc: Maybe<&2, Nat>
  for neq: {Nat.is_eq(wid, other) == False{} : Bool}
  {M.check_publish_fence(wid, Some{other}, addr_ok, w_acc) == M.AbortedWalletChanged{} : M.PublishFenceOutcome}

law tx_publish_fence_changed_in_access_aborts:
  for +wid: Nat
  for +w_acc: Maybe<&2, Nat>
  for mismatch: {M.wallet_identity_matches(wid, w_acc) == False{} : Bool}
  {M.check_publish_fence(wid, Some{wid}, True{}, w_acc) == M.AbortedWalletChanged{} : M.PublishFenceOutcome}

# --- 2. Per-address send lock ref-counter ---

law lock_acquire_increments_and_present:
  for +s: M.AddrLockState
  {M.lock_acquire(s) == M.AddrLockState{1n+M.lock_count(s), True{}} : M.AddrLockState}

law lock_release_evicts_iff_zero:
  for +s: M.AddrLockState
  {M.lock_entry_evicted(M.lock_release(s)) == Nat.is_eq(M.lock_count(M.lock_release(s)), 0n) : Bool}

law lock_balanced_acquire_release:
  for +s: M.AddrLockState
  {M.lock_count(M.lock_release(M.lock_acquire(s))) == M.lock_count(s) : Nat}

law lock_nested_balanced_n:
  for +n: Nat
  for +s: M.AddrLockState
  {M.lock_count(M.lock_release_n(n, M.lock_acquire_n(n, s))) == M.lock_count(s) : Nat}

# --- 3. PowGeneratingStatusBloc ref-count reducer & HW review deferral ---

law pow_status_matches_count:
  for +s: M.PowState
  for +ev: M.PowEvent
  {M.pow_is_generating(M.pow_step_state(s, ev)) == Nat.is_gt(M.pow_count(M.pow_step_state(s, ev)), 0n) : Bool}

law pow_done_at_zero_clamps:
  {M.pow_step(M.pow_init(), M.PowDone{}) == M.PowStepResult{M.pow_init(), False{}} : M.PowStepResult}

law pow_balanced_nesting_returns_idle:
  for +n: Nat
  {M.pow_apply_n_done(n, M.pow_apply_n_gen(n, M.pow_init())) == M.pow_init() : M.PowState}

law pow_edge_only_emission:
  for +s: M.PowState
  for +ev: M.PowEvent
  {M.pow_step_emitted(s, ev) == Bool.not(M.pow_status_eq(M.pow_status(s), M.pow_status(M.pow_step_state(s, ev)))) : Bool}

law hw_review_deferred_iff_plasma:
  for +need_plasma: Bool
  {M.review_is_deferred(M.hw_review_timing(True{}, need_plasma)) == need_plasma : Bool}

# --- 4. AutoReceiveTxWorker queue / mutex / preemption ---

law auto_receive_add_hash_requires_sync:
  for +s: M.AutoReceiveState
  for +h: Nat
  {M.auto_receive_add_hash(s, h, False{}) == s : M.AutoReceiveState}

law auto_receive_add_hash_dedup:
  for +s: M.AutoReceiveState
  for +h: Nat
  for +synced: Bool
  for dup: {M.nat_list_contains(M.ar_pool(s), h) == True{} : Bool}
  {M.auto_receive_add_hash(s, h, synced) == s : M.AutoReceiveState}

law auto_receive_add_hash_enqueues:
  for +s: M.AutoReceiveState
  for +h: Nat
  for fresh: {M.nat_list_contains(M.ar_pool(s), h) == False{} : Bool}
  {Bool.and(
    Nat.is_eq(M.nat_list_len(M.ar_pool(M.auto_receive_add_hash(s, h, True{}))), 1n+M.nat_list_len(M.ar_pool(s))),
    M.nat_list_contains(M.ar_pool(M.auto_receive_add_hash(s, h, True{})), h)
  ) == True{} : Bool}

law auto_receive_disabled_clears_pool:
  for +s: M.AutoReceiveState
  for +htlc: Bool
  for +out: M.ReceiveOutcome
  {M.ar_pool(M.ar_res_state(M.auto_receive_loop_step(s, False{}, htlc, out))) == Nil{} : List<&2, Nat>}

law auto_receive_htlc_preempts_preserving_pool:
  for +s: M.AutoReceiveState
  for +out: M.ReceiveOutcome
  {M.auto_receive_loop_step(s, True{}, True{}, out) == M.AutoReceiveStepResult{s, False{}, False{}} : M.AutoReceiveStepResult}

law auto_receive_single_flight_rejects_reentry:
  for +pool: List<&2, Nat>
  for +seq: Nat
  for +htlc: Bool
  {M.ar_res_accepted(M.auto_receive_enter(M.AutoReceiveState{pool, True{}, seq}, True{}, htlc)) == False{} : Bool}

law auto_receive_ok_and_already_received_pop_head:
  for +h: Nat
  for +t: List<&2, Nat>
  for +r: Bool
  for +seq: Nat
  {Bool.and(
    Nat.is_eq(M.nat_list_len(M.ar_pool(M.ar_res_state(M.auto_receive_loop_step(M.AutoReceiveState{h <> t, r, seq}, True{}, False{}, M.ReceiveOk{})))), M.nat_list_len(t)),
    Nat.is_eq(M.nat_list_len(M.ar_pool(M.ar_res_state(M.auto_receive_loop_step(M.AutoReceiveState{h <> t, r, seq}, True{}, False{}, M.ReceiveAlreadyReceived{})))), M.nat_list_len(t))
  ) == True{} : Bool}

law auto_receive_other_error_preserves_head:
  for +h: Nat
  for +t: List<&2, Nat>
  for +r: Bool
  for +seq: Nat
  {M.auto_receive_loop_step(M.AutoReceiveState{h <> t, r, seq}, True{}, False{}, M.ReceiveOtherError{}) == M.AutoReceiveStepResult{M.AutoReceiveState{h <> t, r, 1n+seq}, False{}, True{}} : M.AutoReceiveStepResult}

law auto_receive_seq_monotonic:
  for +s: M.AutoReceiveState
  for +en: Bool
  for +htlc: Bool
  for +out: M.ReceiveOutcome
  {Nat.is_le(M.ar_notif_seq(s), M.ar_notif_seq(M.ar_res_state(M.auto_receive_loop_step(s, en, htlc, out)))) == True{} : Bool}

# --- 5. pollUntilConfirmed ---

law poll_never_sleeps_past_deadline:
  for +cb: Bool
  for +rb: Nat
  for +out: M.PollFetchOutcome
  for +ca: Bool
  for +ra: Nat
  for +iv: Nat
  {M.poll_decision_within_deadline(ra, M.poll_step(cb, rb, out, ca, ra, iv)) == True{} : Bool}

law poll_confirmed_returns_true:
  for +rbp: Nat
  for +ca: Bool
  for +ra: Nat
  for +iv: Nat
  {M.poll_step(False{}, 1n+rbp, M.FetchConfirmed{}, ca, ra, iv) == M.PollDone{True{}} : M.PollStepDecision}

law poll_cancelled_returns_false:
  for +rb: Nat
  for +out: M.PollFetchOutcome
  for +ca: Bool
  for +ra: Nat
  for +iv: Nat
  {M.poll_step(True{}, rb, out, ca, ra, iv) == M.PollDone{False{}} : M.PollStepDecision}

law poll_transient_error_continues:
  for +rbp: Nat
  for +ra: Nat
  for +iv: Nat
  for has_time: {Nat.is_lt(iv, ra) == True{} : Bool}
  {M.poll_step(False{}, 1n+rbp, M.FetchTransientError{}, False{}, ra, iv) == M.PollSleep{iv} : M.PollStepDecision}

# --- 6. InfiniteListBloc pagination & generation fencing ---

law il_stale_first_page_discarded:
  for +s: M.InfiniteListModel
  for +rid: Nat
  for +fetched: Nat
  for +ok: Bool
  for stale: {Nat.is_eq(rid, M.il_active_req_id(s)) == False{} : Bool}
  {M.il_apply_first_page(s, rid, fetched, ok) == s : M.InfiniteListModel}

law il_stale_more_page_discarded:
  for +s: M.InfiniteListModel
  for +rid: Nat
  for +snap: Nat
  for +ea: Maybe<&2, Nat>
  for +fetched: Nat
  for +ok: Bool
  for stale: {Nat.is_eq(rid, M.il_active_req_id(s)) == False{} : Bool}
  {M.il_apply_more_page(s, rid, snap, ea, fetched, ok) == s : M.InfiniteListModel}

law il_more_noop_when_max:
  for +st: M.ListStatus
  for +cnt: Nat
  for +rid: Nat
  for +aa: Maybe<&2, Nat>
  for +ps: Nat
  for +req: Nat
  for +snap: Nat
  for +ea: Maybe<&2, Nat>
  for +fetched: Nat
  for +ok: Bool
  {M.il_apply_more_page(M.InfiniteListModel{st, cnt, True{}, rid, aa, ps}, req, snap, ea, fetched, ok) == M.InfiniteListModel{st, cnt, True{}, rid, aa, ps} : M.InfiniteListModel}

law il_more_noop_on_addr_mismatch:
  for +st: M.ListStatus
  for +cnt: Nat
  for +hrm: Bool
  for +ridp: Nat
  for +aa: Nat
  for +ps: Nat
  for +ea: Nat
  for neq: {Nat.is_eq(ea, aa) == False{} : Bool}
  {M.il_can_load_more(M.InfiniteListModel{st, cnt, hrm, 1n+ridp, Some{aa}, ps}, Some{ea}) == False{} : Bool}

law il_has_reached_max_iff_short:
  for +s: M.InfiniteListModel
  for +fetched: Nat
  {M.il_has_reached_max(M.il_apply_first_page(s, M.il_active_req_id(s), fetched, True{})) == Nat.is_lt(fetched, M.il_page_size(s)) : Bool}

# --- 7. FetchBloc, TimerState, BalanceCubit & AccountChainStats ---

law fetch_loading_iff_inflight:
  for +s: M.FetchLoadingState
  {Bool.and(
    M.bool_eq(M.fetch_is_loading(M.fetch_begin(s)), Nat.is_gt(M.fetch_in_flight(M.fetch_begin(s)), 0n)),
    M.bool_eq(M.fetch_is_loading(M.fetch_end(s)), Nat.is_gt(M.fetch_in_flight(M.fetch_end(s)), 0n))
  ) == True{} : Bool}

law timer_step_preserves_valid:
  for +s: M.TimerStateModel
  for +ws_open: Bool
  for +fetch_ok: Bool
  {M.timer_state_valid(M.timer_step_fetch(s, ws_open, fetch_ok)) == True{} : Bool}

law balance_non_empty_partition:
  for +znn: Nat
  for +qsr: Nat
  for +bc: Nat
  {Bool.and(
    Bool.not(M.balance_is_populated(0n, znn, qsr)),
    Bool.and(
      Bool.not(M.balance_is_populated(bc, 0n, 0n)),
      Bool.and(
        M.balance_is_populated(1n+bc, 1n+znn, qsr),
        M.balance_is_populated(1n+bc, znn, 1n+qsr)
      )
    )
  ) == True{} : Bool}

law account_chain_stats_ceil_div_covers:
  for +bp: Nat
  for +pp: Nat
  {Nat.is_le(1n+bp, Nat.mul(M.ceil_div(1n+bp, 1n+pp), 1n+pp)) == True{} : Bool}

law account_chain_stats_ceil_div_minimal:
  for +bp: Nat
  for +pp: Nat
  {Nat.is_lt(Nat.mul(Nat.sub(M.ceil_div(1n+bp, 1n+pp), 1n), 1n+pp), 1n+bp) == True{} : Bool}

# --- 8. Parallel evaluator equivalence ---

law tx_batch_par_equiv_seq:
  for +st: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for +wid: Nat
  for +w_lock: Maybe<&2, Nat>
  for +addr_ok: Bool
  for +w_acc: Maybe<&2, Nat>
  for +ps: M.PowState
  for +ev: M.PowEvent
  for +rem_after: Nat
  for +poll_interval: Nat
  for +out: M.PollFetchOutcome
  {M.eval_tx_batch_par(st, cur, tgt, wid, w_lock, addr_ok, w_acc, ps, ev, rem_after, poll_interval, out) == M.eval_tx_batch_seq(st, cur, tgt, wid, w_lock, addr_ok, w_acc, ps, ev, rem_after, poll_interval, out) : M.TxBatchCheck}
