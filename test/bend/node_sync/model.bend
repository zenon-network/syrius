import Base

# Formal verification model for Syrius node management, chain-ID rollback &
# TOCTOU re-verification, sync status hysteresis, local clock skew, AboutBloc
# 3-RPC partial degradation, HiveNotificationsRepository bounded FIFO & sort,
# NotificationsBloc revision fencing, and SettingsWalletOptionsBloc.
#
# Grounded in:
# - lib/rearchitecture/features/node_management/bloc/node_management_bloc.dart
# - lib/rearchitecture/features/node_management/widgets/settings_node_tile.dart
# - lib/rearchitecture/features/node_sync_status/cubit/node_sync_status_cubit.dart
# - lib/rearchitecture/utils/extensions/sync_info_extension.dart
# - lib/utils/node_utils.dart
# - lib/rearchitecture/features/about/bloc/about_bloc.dart
# - lib/rearchitecture/features/about/model/about_node_info.dart
# - lib/rearchitecture/features/notifications/data/notifications_repository.dart
# - lib/rearchitecture/features/notifications/bloc/notifications_bloc.dart
# - lib/rearchitecture/features/notifications/view/notification_widget.dart
# - lib/rearchitecture/features/settings_wallet_options/bloc/settings_wallet_options_bloc.dart

# =============================================================================
# Common Nat list helpers
# =============================================================================

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

# =============================================================================
# 1. NodeManagementBloc transactional switch, chain-ID TOCTOU & custom CRUD
# =============================================================================

type MismatchPrompt is Data:
  MismatchPrompt{
    node: Nat,
    prev_node: Nat,
    node_chain_id: Nat,
    client_chain_id: Nat,
    reconnect_failed: Bool
  }

def prompt_node_chain_id(+p: MismatchPrompt) -> Nat:
  match p:
    case MismatchPrompt{_, _, ncid, _, _}:
      ncid

def prompt_reconnect_failed(+p: MismatchPrompt) -> Bool:
  match p:
    case MismatchPrompt{_, _, _, _, rf}:
      rf

type NodeMgmtState is Data:
  NodeMgmtState{
    busy: Bool,
    selected_node: Nat,
    confirmed_node: Nat,
    saved_node: Nat,
    client_chain_id: Nat,
    connected_chain_id: Nat,
    is_disconnected: Bool,
    pending_mismatch: Maybe<&2, MismatchPrompt>,
    confirmed_nonce: Nat,
    auto_receive: Bool
  }

def nm_selected(+s: NodeMgmtState) -> Nat:
  match s:
    case NodeMgmtState{_, sel, _, _, _, _, _, _, _, _}:
      sel

def nm_confirmed(+s: NodeMgmtState) -> Nat:
  match s:
    case NodeMgmtState{_, _, conf, _, _, _, _, _, _, _}:
      conf

def nm_saved(+s: NodeMgmtState) -> Nat:
  match s:
    case NodeMgmtState{_, _, _, sav, _, _, _, _, _, _}:
      sav

def nm_connected_chain_id(+s: NodeMgmtState) -> Nat:
  match s:
    case NodeMgmtState{_, _, _, _, _, conn_cid, _, _, _, _}:
      conn_cid

def nm_is_disconnected(+s: NodeMgmtState) -> Bool:
  match s:
    case NodeMgmtState{_, _, _, _, _, _, disc, _, _, _}:
      disc

def nm_pending_mismatch(+s: NodeMgmtState) -> Maybe<&2, MismatchPrompt>:
  match s:
    case NodeMgmtState{_, _, _, _, _, _, _, pm, _, _}:
      pm

def nm_nonce(+s: NodeMgmtState) -> Nat:
  match s:
    case NodeMgmtState{_, _, _, _, _, _, _, _, nc, _}:
      nc

def nm_has_pending_mismatch(+s: NodeMgmtState) -> Bool:
  Maybe.is_some(&2, MismatchPrompt, nm_pending_mismatch(s))

# Pre-commit rollback helper (NodeManagementBloc._recoverAfterPreCommitFailure)
def nm_recover_reconnect(+rollback_ok: Bool, +s: NodeMgmtState, +prev: Nat, +restored_cid: Nat) -> NodeMgmtState:
  match rollback_ok s:
    case True{} NodeMgmtState{_, _, conf, sav, ccid, _, _, _, nc, ar}:
      NodeMgmtState{False{}, prev, conf, sav, ccid, restored_cid, False{}, None{}, nc, ar}
    case False{} NodeMgmtState{_, _, conf, sav, ccid, conn_cid, _, _, nc, ar}:
      NodeMgmtState{False{}, prev, conf, sav, ccid, conn_cid, True{}, None{}, nc, ar}

def nm_recover_branch(+need_redial: Bool, +s: NodeMgmtState, +prev: Nat, +rollback_ok: Bool, +restored_cid: Nat) -> NodeMgmtState:
  match need_redial:
    case True{}:
      nm_recover_reconnect(rollback_ok, s, prev, restored_cid)
    case False{}:
      match s:
        case NodeMgmtState{_, _, conf, sav, ccid, conn_cid, disc, _, nc, ar}:
          NodeMgmtState{False{}, prev, conf, sav, ccid, conn_cid, disc, None{}, nc, ar}

def nm_recover_precommit(+s: NodeMgmtState, +prev: Nat, +target: Nat, +connected_to_target: Bool, +rollback_ok: Bool, +restored_cid: Nat) -> NodeMgmtState:
  nm_recover_branch(
    Bool.and(connected_to_target, Bool.not(Nat.is_eq(target, prev))),
    s,
    prev,
    rollback_ok,
    restored_cid
  )

# Commit boundary (NodeManagementBloc._finalizeNodeSwitch):
# Pre-commit failure rolls back; once savedSelectedNode succeeds, post-commit
# notification failure (notify_ok == False) NEVER rolls back saved/confirmed node.
def nm_finalize_switch(
  +s: NodeMgmtState,
  +prev: Nat,
  +target: Nat,
  +live_cid: Nat,
  +precommit_ok: Bool,
  +rollback_ok: Bool,
  +restored_cid: Nat,
  +notify_ok: Bool
) -> NodeMgmtState:
  match s precommit_ok:
    case NodeMgmtState{_, _, _, _, ccid, _, _, _, nc, ar} True{}:
      NodeMgmtState{False{}, target, target, target, ccid, live_cid, False{}, None{}, 1n+nc, ar}
    case NodeMgmtState{b, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar} False{}:
      nm_recover_precommit(
        NodeMgmtState{b, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
        prev,
        target,
        True{},
        rollback_ok,
        restored_cid
      )

def nm_confirm_mismatch_gate(
  +is_mismatch: Bool,
  +s: NodeMgmtState,
  +target: Nat,
  +prev: Nat,
  +client_cid: Nat,
  +live_cid: Nat,
  +precommit_ok: Bool,
  +rollback_ok: Bool,
  +restored_cid: Nat,
  +notify_ok: Bool
) -> NodeMgmtState:
  match is_mismatch s:
    case True{} NodeMgmtState{_, sel, conf, sav, ccid, conn_cid, disc, _, nc, ar}:
      NodeMgmtState{
        False{},
        sel,
        conf,
        sav,
        ccid,
        conn_cid,
        disc,
        Some{MismatchPrompt{target, prev, live_cid, client_cid, False{}}},
        nc,
        ar
      }
    case False{} NodeMgmtState{b, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}:
      nm_finalize_switch(
        NodeMgmtState{b, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
        prev,
        target,
        live_cid,
        precommit_ok,
        rollback_ok,
        restored_cid,
        notify_ok
      )

# NodeManagementBloc._onConfirmNodeRequested
def nm_confirm_node(
  +s: NodeMgmtState,
  +check_mismatch: Bool,
  +connect_ok: Bool,
  +live_cid: Nat,
  +precommit_ok: Bool,
  +rollback_ok: Bool,
  +restored_cid: Nat,
  +notify_ok: Bool
) -> NodeMgmtState:
  match s connect_ok:
    case NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar} _:
      NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}
    case NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar} False{}:
      nm_recover_precommit(
        NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
        conf,
        sel,
        False{},
        rollback_ok,
        restored_cid
      )
    case NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar} True{}:
      nm_confirm_mismatch_gate(
        Bool.and(check_mismatch, Bool.not(Nat.is_eq(live_cid, ccid))),
        NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
        sel,
        conf,
        ccid,
        live_cid,
        precommit_ok,
        rollback_ok,
        restored_cid,
        notify_ok
      )

# TOCTOU re-verify gate on Proceed (NodeManagementBloc._onChainIdMismatchResolved lines 218-245)
def nm_proceed_toctou_gate(
  +drifted: Bool,
  +s: NodeMgmtState,
  +target: Nat,
  +prev: Nat,
  +client_cid: Nat,
  +live_cid: Nat,
  +precommit_ok: Bool,
  +rollback_ok: Bool,
  +restored_cid: Nat,
  +notify_ok: Bool
) -> NodeMgmtState:
  match drifted s:
    case True{} NodeMgmtState{_, sel, conf, sav, ccid, conn_cid, _, _, nc, ar}:
      NodeMgmtState{
        False{},
        sel,
        conf,
        sav,
        ccid,
        conn_cid,
        False{},
        Some{MismatchPrompt{target, prev, live_cid, client_cid, False{}}},
        nc,
        ar
      }
    case False{} NodeMgmtState{b, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}:
      nm_finalize_switch(
        NodeMgmtState{b, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
        prev,
        target,
        live_cid,
        precommit_ok,
        rollback_ok,
        restored_cid,
        notify_ok
      )

def nm_proceed_connected_gate(
  +has_conn: Bool,
  +s: NodeMgmtState,
  +target: Nat,
  +prev: Nat,
  +prompted_cid: Nat,
  +client_cid: Nat,
  +check_mismatch: Bool,
  +live_cid: Nat,
  +precommit_ok: Bool,
  +rollback_ok: Bool,
  +restored_cid: Nat,
  +notify_ok: Bool
) -> NodeMgmtState:
  match has_conn:
    case False{}:
      nm_recover_precommit(s, prev, target, False{}, rollback_ok, restored_cid)
    case True{}:
      nm_proceed_toctou_gate(
        Bool.and(
          check_mismatch,
          Bool.and(
            Bool.not(Nat.is_eq(live_cid, client_cid)),
            Bool.not(Nat.is_eq(live_cid, prompted_cid))
          )
        ),
        s,
        target,
        prev,
        client_cid,
        live_cid,
        precommit_ok,
        rollback_ok,
        restored_cid,
        notify_ok
      )

def nm_resolve_proceed(
  +s: NodeMgmtState,
  +check_mismatch: Bool,
  +reconnect_target_ok: Bool,
  +live_cid: Nat,
  +precommit_ok: Bool,
  +rollback_ok: Bool,
  +restored_cid: Nat,
  +notify_ok: Bool
) -> NodeMgmtState:
  match s:
    case NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}:
      NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}
    case NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, None{}, nc, ar}:
      NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, None{}, nc, ar}
    case NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, Some{MismatchPrompt{target, prev, ncid, pcid, rf}}, nc, ar}:
      +already_conn = Bool.and(Bool.not(rf), Bool.not(disc))
      nm_proceed_connected_gate(
        Bool.or(already_conn, reconnect_target_ok),
        NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, Some{MismatchPrompt{target, prev, ncid, pcid, rf}}, nc, ar},
        target,
        prev,
        ncid,
        ccid,
        check_mismatch,
        live_cid,
        precommit_ok,
        rollback_ok,
        restored_cid,
        notify_ok
      )

# Cancel path (NodeManagementBloc._onChainIdMismatchResolved lines 264-299)
def nm_resolve_cancel(+s: NodeMgmtState, +reconnect_prev_ok: Bool, +restored_cid: Nat) -> NodeMgmtState:
  match s reconnect_prev_ok:
    case NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar} _:
      NodeMgmtState{True{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}
    case NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, None{}, nc, ar} _:
      NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, None{}, nc, ar}
    case NodeMgmtState{False{}, _, conf, sav, ccid, _, _, Some{MismatchPrompt{_, prev, _, _, _}}, nc, ar} True{}:
      NodeMgmtState{False{}, prev, conf, sav, ccid, restored_cid, False{}, None{}, nc, ar}
    case NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, _, Some{MismatchPrompt{target, prev, ncid, pcid, _}}, nc, ar} False{}:
      NodeMgmtState{
        False{},
        sel,
        conf,
        sav,
        ccid,
        conn_cid,
        True{},
        Some{MismatchPrompt{target, prev, ncid, pcid, True{}}},
        nc,
        ar
      }

# Custom node CRUD & protection rules
def is_custom_node(+is_default: Bool, +is_community: Bool) -> Bool:
  Bool.and(Bool.not(is_default), Bool.not(is_community))

def add_custom_node_gate(+dup: Bool, +nodes: List<&2, Nat>, +node: Nat) -> List<&2, Nat>:
  match dup:
    case True{}:
      nodes
    case False{}:
      nat_list_snoc(nodes, node)

def add_custom_node(+nodes: List<&2, Nat>, +node: Nat) -> List<&2, Nat>:
  add_custom_node_gate(nat_list_contains(nodes, node), nodes, node)

type EditNodeValidation is Data:
  EditValid{}
  EditErrProtected{}
  EditErrEmpty{}
  EditErrTooLong{}
  EditErrDuplicate{}

def edit_check_dup(+dup: Bool) -> EditNodeValidation:
  match dup:
    case True{}:
      EditErrDuplicate{}
    case False{}:
      EditValid{}

def edit_check_len(+too_long: Bool, +new_node: Nat, +existing: List<&2, Nat>) -> EditNodeValidation:
  match too_long:
    case True{}:
      EditErrTooLong{}
    case False{}:
      edit_check_dup(nat_list_contains(existing, new_node))

def edit_check_nonempty(+new_len: Nat, +new_node: Nat, +existing: List<&2, Nat>) -> EditNodeValidation:
  match new_len:
    case 0n:
      EditErrEmpty{}
    case 1n+p:
      edit_check_len(Nat.is_gt(1n+p, 80n), new_node, existing)

def edit_check_custom(+custom: Bool, +new_len: Nat, +new_node: Nat, +existing: List<&2, Nat>) -> EditNodeValidation:
  match custom:
    case False{}:
      EditErrProtected{}
    case True{}:
      edit_check_nonempty(new_len, new_node, existing)

# Combined edit validation: SettingsNodeTile gates edit/delete by is_custom_node
# (!default && !community, settings_node_tile.dart:77-78,142), while
# NodeManagementBloc._onEditNodeRequested validates empty / >80 / duplicate
# (node_management_bloc.dart:451-507; updateCustomNode throws StateError if
# invoked directly on a non-custom node).
def validate_edit_node(+is_default: Bool, +is_community: Bool, +new_len: Nat, +new_node: Nat, +existing: List<&2, Nat>) -> EditNodeValidation:
  edit_check_custom(is_custom_node(is_default, is_community), new_len, new_node, existing)

def pick_nat(+cond: Bool, +if_true: Nat, +if_false: Nat) -> Nat:
  match cond:
    case True{}:
      if_true
    case False{}:
      if_false

def rename_selected_node(+selected: Nat, +old_node: Nat, +new_node: Nat) -> Nat:
  pick_nat(Nat.is_eq(selected, old_node), new_node, selected)

def delete_selected_fallback(+selected: Nat, +confirmed: Nat, +deleted_node: Nat) -> Nat:
  pick_nat(Nat.is_eq(selected, deleted_node), confirmed, selected)

def toggle_auto_receive(+current: Bool, +desired: Bool, +save_ok: Bool) -> Bool:
  match save_ok:
    case True{}:
      desired
    case False{}:
      current

# =============================================================================
# 2. SyncInfoExtension, NodeSyncStatusCubit hysteresis & local clock skew
# =============================================================================

type SyncStateKind is Data:
  SyncUnknown{}
  Syncing{}
  SyncDone{}
  NotEnoughPeers{}

def sync_state_eq(+a: SyncStateKind, +b: SyncStateKind) -> Bool:
  match a b:
    case SyncUnknown{} SyncUnknown{}:
      True{}
    case Syncing{} Syncing{}:
      True{}
    case SyncDone{} SyncDone{}:
      True{}
    case NotEnoughPeers{} NotEnoughPeers{}:
      True{}
    case _ _:
      False{}

def sync_is_done(+st: SyncStateKind) -> Bool:
  match st:
    case SyncDone{}:
      True{}
    case _:
      False{}

def sync_has_valid_heights(+cur: Nat, +tgt: Nat) -> Bool:
  Bool.and(Nat.is_gt(tgt, 0n), Nat.is_gt(cur, 0n))

def sync_info_is_synced(+st: SyncStateKind, +cur: Nat, +tgt: Nat) -> Bool:
  Bool.or(
    sync_is_done(st),
    Bool.and(sync_has_valid_heights(cur, tgt), Nat.is_lt(Nat.sub(tgt, cur), 3n))
  )

def sync_info_is_clearly_behind(+cur: Nat, +tgt: Nat) -> Bool:
  Bool.and(sync_has_valid_heights(cur, tgt), Nat.is_ge(Nat.sub(tgt, cur), 3n))

def pick_sync_state(+should_update: Bool, +incoming: SyncStateKind, +last: SyncStateKind) -> SyncStateKind:
  match should_update:
    case True{}:
      incoming
    case False{}:
      last

# NodeSyncStatusCubit.fetch (lines 41-43)
def sync_cubit_step(+last: SyncStateKind, +incoming: SyncStateKind, +cur: Nat, +tgt: Nat) -> SyncStateKind:
  pick_sync_state(
    Bool.and(
      Bool.not(sync_state_eq(last, incoming)),
      Bool.or(sync_is_done(incoming), sync_info_is_clearly_behind(cur, tgt))
    ),
    incoming,
    last
  )

# NodeUtils.checkForLocalTimeDiscrepancy (lines 175-188)
# Pure Nat constant 300 = 200 + 100 (avoids U32.to_nat desugaring).
def clock_skew_threshold() -> Nat:
  Nat.add(200n, 100n)

def abs_diff(+a: Nat, +b: Nat) -> Nat:
  Nat.add(Nat.sub(a, b), Nat.sub(b, a))

def node_is_synced_20(+st: SyncStateKind, +cur: Nat, +tgt: Nat) -> Bool:
  Bool.or(
    sync_is_done(st),
    Bool.and(sync_has_valid_heights(cur, tgt), Nat.is_lt(Nat.sub(tgt, cur), 20n))
  )

def should_warn_clock_skew(+st: SyncStateKind, +cur: Nat, +tgt: Nat, +frontier: Nat, +local: Nat) -> Bool:
  Bool.and(
    node_is_synced_20(st, cur, tgt),
    Nat.is_gt(abs_diff(frontier, local), clock_skew_threshold())
  )

# =============================================================================
# 3. AboutBloc 3-RPC partial-degradation lattice
# =============================================================================

type RpcRes is Data:
  RpcOk{val: Nat}
  RpcErr{code: Nat}

def rpc_is_ok(+r: RpcRes) -> Bool:
  match r:
    case RpcOk{_}:
      True{}
    case RpcErr{_}:
      False{}

def rpc_is_err(+r: RpcRes) -> Bool:
  match r:
    case RpcOk{_}:
      False{}
    case RpcErr{_}:
      True{}

def first_rpc_err(+r1: RpcRes, +r2: RpcRes, +r3: RpcRes) -> Maybe<&2, Nat>:
  match r1 r2 r3:
    case RpcErr{e1} _ _:
      Some{e1}
    case RpcOk{_} RpcErr{e2} _:
      Some{e2}
    case RpcOk{_} RpcOk{_} RpcErr{e3}:
      Some{e3}
    case RpcOk{_} RpcOk{_} RpcOk{_}:
      None{}

type AboutOutcome is Data:
  AboutOutFailure{err: Nat}
  AboutOutPopulated{has_momentum: Bool, has_process: Bool, has_os: Bool, first_err: Maybe<&2, Nat>}

def about_is_failure(+o: AboutOutcome) -> Bool:
  match o:
    case AboutOutFailure{_}:
      True{}
    case AboutOutPopulated{_, _, _, _}:
      False{}

def about_first_err(+o: AboutOutcome) -> Maybe<&2, Nat>:
  match o:
    case AboutOutFailure{e}:
      Some{e}
    case AboutOutPopulated{_, _, _, fe}:
      fe

def about_reduce(+r1: RpcRes, +r2: RpcRes, +r3: RpcRes) -> AboutOutcome:
  match r1 r2 r3:
    case RpcErr{e1} RpcErr{_} RpcErr{_}:
      AboutOutFailure{e1}
    case a b c:
      AboutOutPopulated{rpc_is_ok(a), rpc_is_ok(b), rpc_is_ok(c), first_rpc_err(a, b, c)}

# =============================================================================
# 4. HiveNotificationsRepository bounded FIFO & newest-first sort
# =============================================================================

type NotifEntry is Data:
  NotifEntry{id: Nat, ts: Nat}

def notif_ts(+e: NotifEntry) -> Nat:
  match e:
    case NotifEntry{_, t}:
      t

def notif_len(+xs: List<&2, NotifEntry>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case _ <> t:
      1n+notif_len(t)

def notif_snoc(+xs: List<&2, NotifEntry>, +e: NotifEntry) -> List<&2, NotifEntry>:
  match xs:
    case Nil{}:
      e <> Nil{}
    case h <> t:
      h <> notif_snoc(t, e)

def notif_evict_pick(+fits: Bool, +h: NotifEntry, +t: List<&2, NotifEntry>, +rec: List<&2, NotifEntry>) -> List<&2, NotifEntry>:
  match fits:
    case True{}:
      h <> t
    case False{}:
      rec

def notif_evict_to(+xs: List<&2, NotifEntry>, +cap: Nat) -> List<&2, NotifEntry>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      notif_evict_pick(Nat.is_le(1n+notif_len(t), cap), h, t, notif_evict_to(t, cap))

# HiveNotificationsRepository.addNotification (lines 114-127)
def notif_repo_add(+box: List<&2, NotifEntry>, +e: NotifEntry, +max_entries: Nat) -> List<&2, NotifEntry>:
  match max_entries:
    case 0n:
      Nil{}
    case 1n+mp:
      notif_snoc(notif_evict_to(box, mp), e)

def notif_rev_go(+xs: List<&2, NotifEntry>, +acc: List<&2, NotifEntry>) -> List<&2, NotifEntry>:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      notif_rev_go(t, h <> acc)

def notif_insert_pick(+put_first: Bool, +e: NotifEntry, +h: NotifEntry, +t: List<&2, NotifEntry>, +rec: List<&2, NotifEntry>) -> List<&2, NotifEntry>:
  match put_first:
    case True{}:
      e <> (h <> t)
    case False{}:
      h <> rec

def notif_insert_desc(+xs: List<&2, NotifEntry>, +e: NotifEntry) -> List<&2, NotifEntry>:
  match xs:
    case Nil{}:
      e <> Nil{}
    case h <> t:
      notif_insert_pick(Nat.is_ge(notif_ts(e), notif_ts(h)), e, h, t, notif_insert_desc(t, e))

def notif_sort_desc(+xs: List<&2, NotifEntry>) -> List<&2, NotifEntry>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      notif_insert_desc(notif_sort_desc(t), h)

def notif_take(+limit: Nat, +xs: List<&2, NotifEntry>) -> List<&2, NotifEntry>:
  match limit xs:
    case 0n _:
      Nil{}
    case 1n+_ Nil{}:
      Nil{}
    case 1n+lp Con{h, t}:
      h <> notif_take(lp, t)

# HiveNotificationsRepository.loadNotifications (lines 72-111):
# Reversing oldest-first box puts newer insertionIndex first, then stable
# insertion-sort by ts DESC yields exact (ts DESC, insertionIndex DESC) order.
def notif_repo_load(+box: List<&2, NotifEntry>, +limit: Nat) -> List<&2, NotifEntry>:
  notif_take(limit, notif_sort_desc(notif_rev_go(box, Nil{})))

def notif_ge_head(+bound: Nat, +xs: List<&2, NotifEntry>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> _:
      Nat.is_ge(bound, notif_ts(h))

def notif_is_sorted_desc(+xs: List<&2, NotifEntry>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(notif_ge_head(notif_ts(h), t), notif_is_sorted_desc(t))

# =============================================================================
# 5. NotificationsBloc revision fencing & lock-screen hiding
# =============================================================================

type NotifBannerState is Data:
  NotifBannerState{active: Maybe<&2, Nat>, revision: Nat}

def banner_active(+s: NotifBannerState) -> Maybe<&2, Nat>:
  match s:
    case NotifBannerState{a, _}:
      a

def banner_revision(+s: NotifBannerState) -> Nat:
  match s:
    case NotifBannerState{_, r}:
      r

# Persists before banner update; repo failure leaves banner & revision unchanged.
def notif_bloc_add(+s: NotifBannerState, +notif_id: Nat, +repo_ok: Bool) -> NotifBannerState:
  match s repo_ok:
    case NotifBannerState{a, r} False{}:
      NotifBannerState{a, r}
    case NotifBannerState{_, r} True{}:
      NotifBannerState{Some{notif_id}, 1n+r}

def notif_dismiss_gate(+matches: Bool, +s: NotifBannerState) -> NotifBannerState:
  match matches s:
    case False{} NotifBannerState{a, r}:
      NotifBannerState{a, r}
    case True{} NotifBannerState{_, r}:
      NotifBannerState{None{}, r}

def notif_bloc_dismiss(+s: NotifBannerState, +rev: Maybe<&2, Nat>) -> NotifBannerState:
  match s rev:
    case NotifBannerState{_, r} None{}:
      NotifBannerState{None{}, r}
    case NotifBannerState{a, r} Some{target_rev}:
      notif_dismiss_gate(Nat.is_eq(target_rev, r), NotifBannerState{a, r})

# NotificationWidget lock-screen guard (notification_widget.dart lines 185, 215)
def notif_widget_can_see_more(+on_lock_screen: Bool, +has_active: Bool, +has_callback: Bool) -> Bool:
  Bool.and(has_active, Bool.and(Bool.not(on_lock_screen), has_callback))

# =============================================================================
# 6. SettingsWalletOptionsBloc rollback & macOS permission gate
# =============================================================================

def wallet_opt_toggle(+prev: Bool, +desired: Bool, +save_ok: Bool) -> Bool:
  match save_ok:
    case True{}:
      desired
    case False{}:
      prev

def wallet_opt_toggle_desktop_notifs(+prev: Bool, +desired: Bool, +is_macos: Bool, +os_perm_granted: Bool, +save_ok: Bool) -> Bool:
  match desired is_macos os_perm_granted:
    case True{} True{} False{}:
      prev
    case _ _ _:
      wallet_opt_toggle(prev, desired, save_ok)

# =============================================================================
# 7. Parallelized multi-check evaluator (Bend parallel-let)
# =============================================================================

type NodeSyncBatchCheck is Data:
  NodeSyncBatchCheck{
    synced: Bool,
    skew_warn: Bool,
    about_fail: Bool,
    desktop_opt: Bool
  }

def ns_branch_sync(+st: SyncStateKind, +cur: Nat, +tgt: Nat) -> Bool:
  sync_info_is_synced(st, cur, tgt)

def ns_branch_skew(+st: SyncStateKind, +cur: Nat, +tgt: Nat, +f: Nat, +l: Nat) -> Bool:
  should_warn_clock_skew(st, cur, tgt, f, l)

def ns_branch_about(+r1: RpcRes, +r2: RpcRes, +r3: RpcRes) -> Bool:
  about_is_failure(about_reduce(r1, r2, r3))

def ns_branch_opt(+prev: Bool, +des: Bool, +mac: Bool, +perm: Bool, +ok: Bool) -> Bool:
  wallet_opt_toggle_desktop_notifs(prev, des, mac, perm, ok)

def eval_node_sync_batch_par(
  +st: SyncStateKind, +cur: Nat, +tgt: Nat, +f: Nat, +l: Nat,
  +r1: RpcRes, +r2: RpcRes, +r3: RpcRes,
  +prev: Bool, +des: Bool, +mac: Bool, +perm: Bool, +ok: Bool
) -> NodeSyncBatchCheck:
  c1 c2 c3 c4 = ns_branch_sync(st, cur, tgt) ns_branch_skew(st, cur, tgt, f, l) ns_branch_about(r1, r2, r3) ns_branch_opt(prev, des, mac, perm, ok)
  NodeSyncBatchCheck{c1, c2, c3, c4}

def eval_node_sync_batch_seq(
  +st: SyncStateKind, +cur: Nat, +tgt: Nat, +f: Nat, +l: Nat,
  +r1: RpcRes, +r2: RpcRes, +r3: RpcRes,
  +prev: Bool, +des: Bool, +mac: Bool, +perm: Bool, +ok: Bool
) -> NodeSyncBatchCheck:
  NodeSyncBatchCheck{
    ns_branch_sync(st, cur, tgt),
    ns_branch_skew(st, cur, tgt, f, l),
    ns_branch_about(r1, r2, r3),
    ns_branch_opt(prev, des, mac, perm, ok)
  }
