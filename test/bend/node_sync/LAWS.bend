import Base
import ./model.bend as M

# Formal verification laws for Syrius node management, chain-ID rollback &
# TOCTOU re-verification, sync hysteresis, clock skew, AboutBloc 3-RPC lattice,
# HiveNotificationsRepository bounded FIFO, NotificationsBloc, and wallet options.

# --- 1. NodeManagementBloc transactional switch & chain-ID TOCTOU ---

law node_busy_drops_confirm:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +disc: Bool
  for +pm: Maybe<&2, M.MismatchPrompt>
  for +nc: Nat
  for +ar: Bool
  for +chk: Bool
  for +conn_ok: Bool
  for +live_cid: Nat
  for +pre_ok: Bool
  for +rb_ok: Bool
  for +rest_cid: Nat
  for +not_ok: Bool
  {M.nm_confirm_node(M.NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, chk, conn_ok, live_cid, pre_ok, rb_ok, rest_cid, not_ok) == M.NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar} : M.NodeMgmtState}

law node_mismatch_pauses_without_saving:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +disc: Bool
  for +pm: Maybe<&2, M.MismatchPrompt>
  for +nc: Nat
  for +ar: Bool
  for +live_cid: Nat
  for +pre_ok: Bool
  for +rb_ok: Bool
  for +rest_cid: Nat
  for +not_ok: Bool
  for mismatch: {Nat.is_eq(live_cid, ccid) == False{} : Bool}
  {Bool.and(
    M.nm_has_pending_mismatch(M.nm_confirm_node(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, True{}, True{}, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
    Nat.is_eq(M.nm_saved(M.nm_confirm_node(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, True{}, True{}, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), sav)
  ) == True{} : Bool}

law node_proceed_toctou_drift_reprompts:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +nc: Nat
  for +ar: Bool
  for +target: Nat
  for +prev: Nat
  for +prompted_cid: Nat
  for +live_cid: Nat
  for +pre_ok: Bool
  for +rb_ok: Bool
  for +rest_cid: Nat
  for +not_ok: Bool
  for neq_client: {Nat.is_eq(live_cid, ccid) == False{} : Bool}
  for neq_prompted: {Nat.is_eq(live_cid, prompted_cid) == False{} : Bool}
  {Bool.and(
    M.nm_has_pending_mismatch(M.nm_resolve_proceed(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, False{}, Some{M.MismatchPrompt{target, prev, prompted_cid, ccid, False{}}}, nc, ar}, True{}, True{}, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
    Nat.is_eq(M.nm_saved(M.nm_resolve_proceed(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, False{}, Some{M.MismatchPrompt{target, prev, prompted_cid, ccid, False{}}}, nc, ar}, True{}, True{}, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), sav)
  ) == True{} : Bool}

law node_cancel_reconnect_ok_restores_prev:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +disc: Bool
  for +nc: Nat
  for +ar: Bool
  for +target: Nat
  for +prev: Nat
  for +ncid: Nat
  for +pcid: Nat
  for +rf: Bool
  for +rest_cid: Nat
  {M.nm_resolve_cancel(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, Some{M.MismatchPrompt{target, prev, ncid, pcid, rf}}, nc, ar}, True{}, rest_cid) == M.NodeMgmtState{False{}, prev, conf, sav, ccid, rest_cid, False{}, None{}, nc, ar} : M.NodeMgmtState}

law node_cancel_reconnect_fail_marks_disconnected_retry:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +disc: Bool
  for +nc: Nat
  for +ar: Bool
  for +target: Nat
  for +prev: Nat
  for +ncid: Nat
  for +pcid: Nat
  for +rf: Bool
  for +rest_cid: Nat
  {M.nm_resolve_cancel(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, Some{M.MismatchPrompt{target, prev, ncid, pcid, rf}}, nc, ar}, False{}, rest_cid) == M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, True{}, Some{M.MismatchPrompt{target, prev, ncid, pcid, True{}}}, nc, ar} : M.NodeMgmtState}

law node_precommit_error_rolls_back:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +disc: Bool
  for +pm: Maybe<&2, M.MismatchPrompt>
  for +nc: Nat
  for +ar: Bool
  for +live_cid: Nat
  for +rb_ok: Bool
  for +rest_cid: Nat
  for +not_ok: Bool
  {Bool.and(
    Nat.is_eq(M.nm_selected(M.nm_confirm_node(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, False{}, True{}, live_cid, False{}, rb_ok, rest_cid, not_ok)), conf),
    Nat.is_eq(M.nm_saved(M.nm_confirm_node(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, False{}, True{}, live_cid, False{}, rb_ok, rest_cid, not_ok)), sav)
  ) == True{} : Bool}

law node_postcommit_notify_error_never_rolls_back:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +disc: Bool
  for +pm: Maybe<&2, M.MismatchPrompt>
  for +nc: Nat
  for +ar: Bool
  for +live_cid: Nat
  for +rb_ok: Bool
  for +rest_cid: Nat
  {M.nm_confirm_node(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, False{}, True{}, live_cid, True{}, rb_ok, rest_cid, False{}) == M.nm_confirm_node(M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, False{}, True{}, live_cid, True{}, rb_ok, rest_cid, True{}) : M.NodeMgmtState}

# --- 2. Custom node CRUD & auto-receive rollback ---

law node_custom_protects_default_and_community:
  for +is_def: Bool
  for +is_comm: Bool
  {Bool.and(
    Bool.not(M.is_custom_node(True{}, is_comm)),
    Bool.and(
      Bool.not(M.is_custom_node(is_def, True{})),
      M.is_custom_node(False{}, False{})
    )
  ) == True{} : Bool}

law node_add_rejects_duplicate:
  for +nodes: List<&2, Nat>
  for +node: Nat
  for dup: {M.nat_list_contains(nodes, node) == True{} : Bool}
  {M.add_custom_node(nodes, node) == nodes : List<&2, Nat>}

law node_edit_rejects_empty:
  for +node: Nat
  for +existing: List<&2, Nat>
  {M.validate_edit_node(False{}, False{}, 0n, node, existing) == M.EditErrEmpty{} : M.EditNodeValidation}

law node_edit_rejects_over_80:
  for +extra: Nat
  for +node: Nat
  for +existing: List<&2, Nat>
  {M.validate_edit_node(False{}, False{}, Nat.add(81n, extra), node, existing) == M.EditErrTooLong{} : M.EditNodeValidation}

law node_edit_rejects_default:
  for +is_comm: Bool
  for +len: Nat
  for +node: Nat
  for +existing: List<&2, Nat>
  {M.validate_edit_node(True{}, is_comm, len, node, existing) == M.EditErrProtected{} : M.EditNodeValidation}

law node_edit_rejects_community:
  for +is_def: Bool
  for +len: Nat
  for +node: Nat
  for +existing: List<&2, Nat>
  {M.validate_edit_node(is_def, True{}, len, node, existing) == M.EditErrProtected{} : M.EditNodeValidation}

law node_edit_rejects_duplicate:
  for +lenp: Nat
  for +node: Nat
  for +existing: List<&2, Nat>
  for fit: {Nat.is_gt(1n+lenp, 80n) == False{} : Bool}
  for dup: {M.nat_list_contains(existing, node) == True{} : Bool}
  {M.validate_edit_node(False{}, False{}, 1n+lenp, node, existing) == M.EditErrDuplicate{} : M.EditNodeValidation}

law node_rename_updates_selected:
  for +old_n: Nat
  for +new_n: Nat
  {M.rename_selected_node(old_n, old_n, new_n) == new_n : Nat}

law node_rename_preserves_other_selected:
  for +sel: Nat
  for +old_n: Nat
  for +new_n: Nat
  for neq: {Nat.is_eq(sel, old_n) == False{} : Bool}
  {M.rename_selected_node(sel, old_n, new_n) == sel : Nat}

law node_delete_falls_back_to_confirmed:
  for +del_n: Nat
  for +conf: Nat
  {M.delete_selected_fallback(del_n, conf, del_n) == conf : Nat}

law node_delete_preserves_other_selected:
  for +sel: Nat
  for +conf: Nat
  for +del_n: Nat
  for neq: {Nat.is_eq(sel, del_n) == False{} : Bool}
  {M.delete_selected_fallback(sel, conf, del_n) == sel : Nat}

law node_auto_receive_rollback_on_save_fail:
  for +cur: Bool
  for +des: Bool
  {M.toggle_auto_receive(cur, des, False{}) == cur : Bool}

# --- 3. SyncInfoExtension, NodeSyncStatusCubit hysteresis & clock skew ---

law sync_hysteresis_retains_on_jitter:
  for +last: M.SyncStateKind
  for +inc: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for not_done: {M.sync_is_done(inc) == False{} : Bool}
  for jitter: {Nat.is_lt(Nat.sub(tgt, cur), 3n) == True{} : Bool}
  {M.sync_cubit_step(last, inc, cur, tgt) == last : M.SyncStateKind}

law sync_hysteresis_transitions_on_sync_done:
  for +last: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  {M.sync_cubit_step(last, M.SyncDone{}, cur, tgt) == M.SyncDone{} : M.SyncStateKind}

law sync_hysteresis_transitions_on_clearly_behind:
  for +last: M.SyncStateKind
  for +inc: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for behind: {M.sync_info_is_clearly_behind(cur, tgt) == True{} : Bool}
  {M.sync_cubit_step(last, inc, cur, tgt) == inc : M.SyncStateKind}

law sync_non_done_synced_and_behind_disjoint:
  for +st: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for not_done: {M.sync_is_done(st) == False{} : Bool}
  {Bool.and(M.sync_info_is_synced(st, cur, tgt), M.sync_info_is_clearly_behind(cur, tgt)) == False{} : Bool}

law clock_skew_silent_when_unsynced:
  for +st: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for +f: Nat
  for +l: Nat
  for unsynced: {M.node_is_synced_20(st, cur, tgt) == False{} : Bool}
  {M.should_warn_clock_skew(st, cur, tgt, f, l) == False{} : Bool}

law clock_skew_symmetric:
  for +st: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for +f: Nat
  for +l: Nat
  {M.should_warn_clock_skew(st, cur, tgt, f, l) == M.should_warn_clock_skew(st, cur, tgt, l, f) : Bool}

law clock_skew_boundary_300_silent:
  for +cur: Nat
  for +tgt: Nat
  for +l: Nat
  {M.should_warn_clock_skew(M.SyncDone{}, cur, tgt, Nat.add(l, M.clock_skew_threshold()), l) == False{} : Bool}

law clock_skew_boundary_301_warns:
  for +cur: Nat
  for +tgt: Nat
  for +l: Nat
  {M.should_warn_clock_skew(M.SyncDone{}, cur, tgt, Nat.add(l, 1n+M.clock_skew_threshold()), l) == True{} : Bool}

# --- 4. AboutBloc 3-RPC partial-degradation lattice ---

law about_failure_iff_all_three_fail:
  for +r1: M.RpcRes
  for +r2: M.RpcRes
  for +r3: M.RpcRes
  {M.about_is_failure(M.about_reduce(r1, r2, r3)) == Bool.and(M.rpc_is_err(r1), Bool.and(M.rpc_is_err(r2), M.rpc_is_err(r3))) : Bool}

law about_populated_carries_first_error:
  for +r1: M.RpcRes
  for +r2: M.RpcRes
  for +r3: M.RpcRes
  {M.about_first_err(M.about_reduce(r1, r2, r3)) == M.first_rpc_err(r1, r2, r3) : Maybe<&2, Nat>}

# --- 5. HiveNotificationsRepository bounded FIFO & newest-first sort ---

law notif_repo_zero_cap_clears:
  for +box: List<&2, M.NotifEntry>
  for +e: M.NotifEntry
  {M.notif_repo_add(box, e, 0n) == Nil{} : List<&2, M.NotifEntry>}

law notif_repo_add_preserves_cap:
  for +box: List<&2, M.NotifEntry>
  for +e: M.NotifEntry
  for +max_e: Nat
  {Nat.is_le(M.notif_len(M.notif_repo_add(box, e, max_e)), max_e) == True{} : Bool}

law notif_repo_load_len_exact_min:
  for +box: List<&2, M.NotifEntry>
  for +limit: Nat
  {M.notif_len(M.notif_repo_load(box, limit)) == Nat.min(M.notif_len(box), limit) : Nat}

law notif_repo_load_sorted_desc:
  for +box: List<&2, M.NotifEntry>
  for +limit: Nat
  {M.notif_is_sorted_desc(M.notif_repo_load(box, limit)) == True{} : Bool}

# --- 6. NotificationsBloc revision fencing & lock-screen guard ---

law notif_bloc_repo_fail_leaves_banner_unchanged:
  for +s: M.NotifBannerState
  for +nid: Nat
  {M.notif_bloc_add(s, nid, False{}) == s : M.NotifBannerState}

law notif_bloc_add_strictly_bumps_revision:
  for +s: M.NotifBannerState
  for +nid: Nat
  {Nat.is_lt(M.banner_revision(s), M.banner_revision(M.notif_bloc_add(s, nid, True{}))) == True{} : Bool}

law notif_bloc_dismiss_matching_clears:
  for +a: Maybe<&2, Nat>
  for +r: Nat
  {M.banner_active(M.notif_bloc_dismiss(M.NotifBannerState{a, r}, Some{r})) == None{} : Maybe<&2, Nat>}

law notif_bloc_dismiss_stale_noop:
  for +a: Maybe<&2, Nat>
  for +r: Nat
  for +stale_r: Nat
  for neq: {Nat.is_eq(stale_r, r) == False{} : Bool}
  {M.notif_bloc_dismiss(M.NotifBannerState{a, r}, Some{stale_r}) == M.NotifBannerState{a, r} : M.NotifBannerState}

law notif_bloc_dismiss_none_always_clears:
  for +s: M.NotifBannerState
  {M.banner_active(M.notif_bloc_dismiss(s, None{})) == None{} : Maybe<&2, Nat>}

law notif_lock_screen_hides_see_more:
  for +has_active: Bool
  for +has_cb: Bool
  {M.notif_widget_can_see_more(True{}, has_active, has_cb) == False{} : Bool}

# --- 7. SettingsWalletOptionsBloc rollback & macOS permission gate ---

law wallet_opt_persist_fail_rolls_back:
  for +prev: Bool
  for +des: Bool
  for +is_mac: Bool
  for +perm: Bool
  {M.wallet_opt_toggle_desktop_notifs(prev, des, is_mac, perm, False{}) == prev : Bool}

law wallet_opt_macos_requires_permission:
  for +prev: Bool
  for +save_ok: Bool
  {M.wallet_opt_toggle_desktop_notifs(prev, True{}, True{}, False{}, save_ok) == prev : Bool}

# --- 8. Parallel evaluator equivalence ---

law node_sync_batch_par_equiv_seq:
  for +st: M.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for +f: Nat
  for +l: Nat
  for +r1: M.RpcRes
  for +r2: M.RpcRes
  for +r3: M.RpcRes
  for +prev: Bool
  for +des: Bool
  for +mac: Bool
  for +perm: Bool
  for +ok: Bool
  {M.eval_node_sync_batch_par(st, cur, tgt, f, l, r1, r2, r3, prev, des, mac, perm, ok) == M.eval_node_sync_batch_seq(st, cur, tgt, f, l, r1, r2, r3, prev, des, mac, perm, ok) : M.NodeSyncBatchCheck}
