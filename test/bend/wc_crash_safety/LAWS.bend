import Base
import ./model.bend as M

# Formal laws for Syrius WalletConnect crash-safety, sticky fallback
# secure storage, ConfirmingRelayClient fencing, and Web3WalletService
# reset durability, epoch fencing, and idempotent request delivery.

# ---------------------------------------------------------------------------
# 1. StickyFallbackSecureStore tri-state machine (13 laws)
# ---------------------------------------------------------------------------

law authoritative_fallback_is_sticky_forever:
  for +op: M.StoreOp
  for +os_ok: Bool
  for +fb_ok: Bool
  {M.store_step_mode(M.ModeAuthoritativeFallback{}, op, os_ok, fb_ok) == M.ModeAuthoritativeFallback{} : M.StoreMode}

law authoritative_and_legacy_markers_boot_authoritative:
  for +os_read_ok: Bool
  for +os_write_ok: Bool
  for +fb_ok: Bool
  for +kc_entries: Bool
  {Bool.and(
    M.is_mode_authoritative(M.store_boot_mode(M.MarkerAuthoritative{}, os_read_ok, os_write_ok, fb_ok, kc_entries)),
    M.is_mode_authoritative(M.store_boot_mode(M.MarkerLegacy{}, os_read_ok, os_write_ok, fb_ok, kc_entries))
  ) == True{} : Bool}

law transient_restart_empty_keychain_preserves_transient_keys:
  for +os_rw: Bool
  for +fb_ok: Bool
  {M.store_step_mode(
    M.ModeTransientFallback{},
    M.StoreOpRestart{False{}, False{}, False{}, True{}, os_rw, False{}},
    True{},
    fb_ok
  ) == M.ModeTransientFallback{} : M.StoreMode}

law fallback_flag_never_deleted_or_lazy_read:
  for +mode: M.StoreMode
  for +use_fb: Bool
  for +has_manifest: Bool
  for +owned: List<&2, Nat>
  {Bool.and(
    Bool.not(M.can_delete_key(mode, has_manifest, owned, M.KeyFallbackFlag{})),
    Bool.not(M.can_lazy_read_fallback(use_fb, has_manifest, owned, M.KeyFallbackFlag{}))
  ) == True{} : Bool}

law foreign_keys_isolated_from_delete_and_manifest_read:
  for +mode: M.StoreMode
  for +use_fb: Bool
  for +has_manifest: Bool
  for +owned: List<&2, Nat>
  for +fid: Nat
  {Bool.and(
    Bool.not(M.can_delete_key(mode, True{}, owned, M.KeyForeign{fid})),
    Bool.and(
      Bool.not(M.can_delete_key(M.ModeSecure{}, has_manifest, owned, M.KeyForeign{fid})),
      Bool.not(M.can_lazy_read_fallback(use_fb, True{}, owned, M.KeyForeign{fid}))
    )
  ) == True{} : Bool}

law delete_all_preserves_flag_and_foreign_entries:
  for +flag_present: Bool
  for +owned_count: Nat
  for +foreign_count: Nat
  {Bool.and(
    Bool.and(
      Nat.is_eq(M.snap_owned_count(M.delete_all_fallback_snapshot(M.FallbackStoreSnapshot{flag_present, owned_count, foreign_count})), 0n),
      Nat.is_eq(M.snap_foreign_count(M.delete_all_fallback_snapshot(M.FallbackStoreSnapshot{flag_present, owned_count, foreign_count})), foreign_count)
    ),
    Bool.not(Bool.xor(M.snap_flag_present(M.delete_all_fallback_snapshot(M.FallbackStoreSnapshot{flag_present, owned_count, foreign_count})), flag_present))
  ) == True{} : Bool}

law reconcile_cleared_all_wipes_os:
  for +in_del: Bool
  for +in_rep: Bool
  for +os_entry: Maybe<&2, M.EntryVal>
  {M.reconcile_key_view(True{}, in_del, in_rep, os_entry, None{}) == None{} : Maybe<&2, M.EntryVal>}

law reconcile_deleted_tombstone_deletes_os:
  for +in_rep: Bool
  for +os_entry: Maybe<&2, M.EntryVal>
  {M.reconcile_key_view(False{}, True{}, in_rep, os_entry, None{}) == None{} : Maybe<&2, M.EntryVal>}

law reconcile_replaced_key_transient_wins:
  for +cleared_all: Bool
  for +in_del: Bool
  for +os_entry: Maybe<&2, M.EntryVal>
  for +tv: M.EntryVal
  {M.reconcile_key_view(cleared_all, in_del, True{}, os_entry, Some{tv}) == Some{tv} : Maybe<&2, M.EntryVal>}

law reconcile_absent_os_transient_wins:
  for +cleared_all: Bool
  for +in_del: Bool
  for +in_rep: Bool
  for +tv: M.EntryVal
  {M.reconcile_key_view(cleared_all, in_del, in_rep, None{}, Some{tv}) == Some{tv} : Maybe<&2, M.EntryVal>}

law reconcile_existing_os_merges_only_missing_subkeys:
  for +oa: Nat
  for +ta: Nat
  for +tb: Nat
  {M.reconcile_key_view(
    False{},
    False{},
    False{},
    Some{M.EntryVal{Some{oa}, None{}}},
    Some{M.EntryVal{Some{ta}, Some{tb}}}
  ) == Some{M.EntryVal{Some{oa}, Some{tb}}} : Maybe<&2, M.EntryVal>}

law migration_writes_entries_before_authoritative_marker:
  for +marker_ok: Bool
  {Bool.and(
    Bool.not(M.migration_marker_persisted(M.migrate_to_authoritative(False{}, marker_ok))),
    M.is_mode_secure(M.migration_next_mode(M.migrate_to_authoritative(False{}, marker_ok)))
  ) == True{} : Bool}

law migration_marker_failure_preserves_secure_mode:
  for +entries_ok: Bool
  {M.migration_next_mode(M.migrate_to_authoritative(entries_ok, False{})) == M.ModeSecure{} : M.StoreMode}

law reconciliation_deletes_marker_before_transient_copies:
  for +marker_ok: Bool
  for +copies_ok: Bool
  for del_copies: {M.cleanup_copies_deleted(M.clear_transient_fallback_data(marker_ok, copies_ok)) == True{} : Bool}
  {M.cleanup_marker_deleted(M.clear_transient_fallback_data(marker_ok, copies_ok)) == True{} : Bool}

# ---------------------------------------------------------------------------
# 2. ConfirmingRelayClient sequence-fenced arbiter (6 laws)
# ---------------------------------------------------------------------------

law relay_op_seq_strictly_monotonic:
  for +s: Nat
  {Nat.is_gt(M.relay_begin_op(s), s) == True{} : Bool}

law relay_failed_unsub_preserves_id_and_marks_unconfirmed:
  for +op_s: Nat
  for +lsub: Nat
  for +lunsub: Nat
  for +cseq: Nat
  for +tm: Nat
  for +sub_id: Nat
  for +unconf: Bool
  for +call_seq: Nat
  for not_stale: {Nat.is_gt(lsub, call_seq) == False{} : Bool}
  {Bool.and(
    Nat.is_eq(
      M.relay_preserved_id(M.relay_finish_unsubscribe(M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, sub_id, unconf}, call_seq, cseq, sub_id, False{}, False{})),
      sub_id
    ),
    M.relay_unconfirmed(M.relay_finish_unsubscribe(M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, sub_id, unconf}, call_seq, cseq, sub_id, False{}, False{}))
  ) == True{} : Bool}

law relay_stale_unsub_fence_preserves_topic_map_and_status:
  for +op_s: Nat
  for +lsub: Nat
  for +lunsub: Nat
  for +cseq: Nat
  for +tm: Nat
  for +pr: Nat
  for +unconf: Bool
  for +call_seq: Nat
  for +conf_start: Nat
  for +sub_id: Nat
  for +mapped_rep: Bool
  for +rpc_conf: Bool
  for stale: {Nat.is_gt(lsub, call_seq) == True{} : Bool}
  {Bool.and(
    Nat.is_eq(
      M.relay_topic_map_id(M.relay_finish_unsubscribe(M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, pr, unconf}, call_seq, conf_start, sub_id, mapped_rep, rpc_conf)),
      tm
    ),
    Bool.not(Bool.xor(
      M.relay_unconfirmed(M.relay_finish_unsubscribe(M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, pr, unconf}, call_seq, conf_start, sub_id, mapped_rep, rpc_conf)),
      unconf
    ))
  ) == True{} : Bool}

law relay_concurrent_unsub_fence_blocks_remarking:
  for +op_s: Nat
  for +lsub: Nat
  for +lunsub: Nat
  for +cseq: Nat
  for +tm: Nat
  for +pr: Nat
  for +call_seq: Nat
  for +conf_start: Nat
  for +sub_id: Nat
  for +mapped_rep: Bool
  for concurrent_confirmed: {Nat.is_gt(cseq, conf_start) == True{} : Bool}
  {M.relay_unconfirmed(M.relay_finish_unsubscribe(M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, pr, False{}}, call_seq, conf_start, sub_id, mapped_rep, False{})) == False{} : Bool}

law relay_restore_never_overwrites_active_or_fresher:
  for +op_s: Nat
  for +lsub: Nat
  for +lunsub: Nat
  for +cseq: Nat
  for +tm: Nat
  for +pr: Nat
  for +unconf: Bool
  for +persisted_id: Nat
  for protected: {Bool.or(Nat.is_gt(lsub, 0n), Bool.or(Nat.is_gt(pr, 0n), Nat.is_gt(tm, 0n))) == True{} : Bool}
  {M.relay_restore_preserved_id(M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, pr, unconf}, persisted_id) == M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, pr, unconf} : M.RelayTopicState}

law relay_capped_tracking_bounded_by_cap:
  for +cap: Nat
  for +xs: List<&2, Nat>
  for +topic: Nat
  {Nat.is_le(List.length(&2, Nat, M.capped_topic_insert(cap, xs, topic)), cap) == True{} : Bool}

# ---------------------------------------------------------------------------
# 3. Web3WalletService reset durability, epoch fencing & idempotency (11 laws)
# ---------------------------------------------------------------------------

law reset_aborts_before_deletes_if_marker_fails:
  {M.sweep_performed_deletes(M.reset_sweep_step(False{})) == False{} : Bool}

law reset_marker_clears_when_empty_and_same_epoch:
  for +ep: Nat
  {M.should_clear_reset_marker(0n, 0n, ep, ep, False{}) == True{} : Bool}

law reset_marker_retained_when_unfinished_or_epoch_advanced:
  for +rs: Nat
  for +rp: Nat
  for +cur_ep: Nat
  for +cap_ep: Nat
  for +pend_disc: Bool
  for advanced: {Nat.is_gt(cur_ep, cap_ep) == True{} : Bool}
  {Bool.and(
    Bool.not(M.should_clear_reset_marker(1n+rs, rp, cur_ep, cap_ep, pend_disc)),
    Bool.and(
      Bool.not(M.should_clear_reset_marker(rs, 1n+rp, cur_ep, cap_ep, pend_disc)),
      Bool.and(
        Bool.not(M.should_clear_reset_marker(rs, rp, cur_ep, cap_ep, pend_disc)),
        Bool.not(M.should_clear_reset_marker(rs, rp, cur_ep, cur_ep, True{}))
      )
    )
  ) == True{} : Bool}

law reset_admission_barrier_blocks_pair_and_approve:
  for +is_init: Bool
  for +is_disp: Bool
  for +has_client: Bool
  {Bool.and(
    Bool.not(M.can_admit_pair(is_init, is_disp, True{})),
    Bool.not(M.can_admit_approve_session(is_disp, has_client, True{}))
  ) == True{} : Bool}

law finalize_approved_session_rejects_advanced_generation:
  for +is_disp: Bool
  for +has_client: Bool
  for +blocked: Bool
  for +cur_gen: Nat
  for +exp_gen: Nat
  for +live_sess: Bool
  for advanced: {Nat.is_gt(cur_gen, exp_gen) == True{} : Bool}
  {M.can_finalize_approved_session(is_disp, has_client, blocked, cur_gen, exp_gen, live_sess) == False{} : Bool}

law topic_unsub_epoch_not_obsolete_when_current_or_newer:
  for +queued_epoch: Nat
  for +current_epoch: Nat
  for current_or_newer: {Nat.is_ge(queued_epoch, current_epoch) == True{} : Bool}
  {M.is_pending_unsub_epoch_obsolete(queued_epoch, current_epoch) == False{} : Bool}

law topic_unsub_epoch_strictly_older_always_obsolete:
  for +queued_epoch: Nat
  for +current_epoch: Nat
  for +in_flight_pair: Bool
  for +live_in_stores: Bool
  for older: {Nat.is_lt(queued_epoch, current_epoch) == True{} : Bool}
  {M.is_pending_unsub_obsolete(queued_epoch, current_epoch, in_flight_pair, live_in_stores) == True{} : Bool}

law active_subscription_fences_prior_deferred_unsub:
  for +queued_epoch: Nat
  for +prev_epoch: Nat
  for +in_flight_pair: Bool
  for +live_in_stores: Bool
  for older_or_eq: {Nat.is_le(queued_epoch, prev_epoch) == True{} : Bool}
  {M.is_pending_unsub_obsolete(queued_epoch, M.mark_topic_subscription_active(prev_epoch), in_flight_pair, live_in_stores) == True{} : Bool}

law provisional_purge_never_deletes_confirmed_pairing:
  for +pair_ok: Bool
  for +stored: Bool
  for +ep_ok: Bool
  for +last_inflight: Bool
  for +reset_act: Bool
  for +gen_ok: Bool
  {M.should_purge_provisional_pairing(pair_ok, True{}, False{}, stored, ep_ok, last_inflight, reset_act, gen_ok) == False{} : Bool}

law orphan_cleanup_protects_live_pairings:
  for +has_sess: Bool
  for +prot_prop: Bool
  for +created_ep: Nat
  for +start_ep: Nat
  for +active_op: Bool
  for +pairing_act: Bool
  for +expiry_sec: Nat
  for +now_sec: Nat
  for protected: {Bool.or(
    has_sess,
    Bool.or(
      prot_prop,
      Bool.or(
        Nat.is_gt(created_ep, start_ep),
        Bool.or(active_op, Bool.and(pairing_act, Nat.is_gt(expiry_sec, now_sec)))
      )
    )
  ) == True{} : Bool}
  {M.should_cleanup_orphan_pairing(has_sess, prot_prop, created_ep, start_ep, active_op, pairing_act, expiry_sec, now_sec) == False{} : Bool}

law idempotent_delivery_never_reexecutes_completed_or_cached:
  for +rid: Nat
  for +has_sess: Bool
  for +reset_act: Bool
  {Bool.and(
    Bool.not(M.action_executes_handler(M.decide_request_action(M.ReqCompleted{}, has_sess, reset_act))),
    Bool.and(
      Bool.not(M.action_executes_handler(M.decide_request_action(M.ReqInFlight{}, has_sess, reset_act))),
      Bool.not(M.action_executes_handler(M.decide_request_action(M.ReqCachedUnsent{rid}, has_sess, reset_act)))
    )
  ) == True{} : Bool}

law idempotent_delivery_cached_retries_only_delivery:
  for +rid: Nat
  {M.decide_request_action(M.ReqCachedUnsent{rid}, True{}, False{}) == M.ActionRetryCachedDelivery{rid} : M.RequestAction}

law idempotent_delivery_post_handler_never_reverts_to_fresh:
  for +rid: Nat
  for +delivery_ok: Bool
  for +perm_err: Bool
  {M.is_req_fresh(M.post_handler_delivery_step(rid, delivery_ok, perm_err)) == False{} : Bool}

# ---------------------------------------------------------------------------
# 4. Parallelized crash-safety audit gate (3 laws)
# ---------------------------------------------------------------------------

law parallel_crash_safety_gate_equiv_sequential:
  for +mode: M.StoreMode
  for +has_manifest: Bool
  for +owned: List<&2, Nat>
  for +key: M.StoreKey
  for +queued_epoch: Nat
  for +current_epoch: Nat
  for +is_init: Bool
  for +is_disp: Bool
  for +reset_act: Bool
  for +req_status: M.RequestDeliveryStatus
  for +has_sess: Bool
  {M.parallel_wc_crash_safety_gate(mode, has_manifest, owned, key, queued_epoch, current_epoch, is_init, is_disp, reset_act, req_status, has_sess) == M.sequential_wc_crash_safety_gate(mode, has_manifest, owned, key, queued_epoch, current_epoch, is_init, is_disp, reset_act, req_status, has_sess) : Bool}

law parallel_crash_safety_gate_accepts_safe_state:
  for +key_id: Nat
  for +ep: Nat
  {M.parallel_wc_crash_safety_gate(
    M.ModeSecure{},
    True{},
    [key_id],
    M.KeyOwned{key_id},
    ep,
    ep,
    True{},
    False{},
    False{},
    M.ReqFresh{},
    True{}
  ) == True{} : Bool}

law parallel_crash_safety_gate_blocks_flag_or_reset_or_stale_epoch:
  for +mode: M.StoreMode
  for +has_manifest: Bool
  for +owned: List<&2, Nat>
  for +key: M.StoreKey
  for +queued_epoch: Nat
  for +current_epoch: Nat
  for +is_init: Bool
  for +is_disp: Bool
  for +reset_act: Bool
  for +req_status: M.RequestDeliveryStatus
  for +has_sess: Bool
  for blocked: {Bool.or(
    M.is_fallback_flag_key(key),
    Bool.or(
      M.is_pending_unsub_epoch_obsolete(queued_epoch, current_epoch),
      reset_act
    )
  ) == True{} : Bool}
  {M.parallel_wc_crash_safety_gate(mode, has_manifest, owned, key, queued_epoch, current_epoch, is_init, is_disp, reset_act, req_status, has_sess) == False{} : Bool}
