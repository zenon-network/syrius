import Base

# Formal model for Syrius WalletConnect crash-safety, sticky fallback
# secure storage, sequence-fenced relay unsubscriptions, reset durability,
# topic subscription epoch fencing, and idempotent request delivery.
#
# Mirrors:
#   - lib/services/sticky_fallback_secure_store.dart
#   - lib/services/web3wallet_service.dart
#   - lib/services/desktop_signing_wallet_kit.dart

# ---------------------------------------------------------------------------
# 1. StickyFallbackSecureStore tri-state crash-safe keystore machine
# ---------------------------------------------------------------------------

type StoreMode is Data:
  ModeSecure{}
  ModeTransientFallback{}
  ModeAuthoritativeFallback{}

def is_mode_authoritative(+m: StoreMode) -> Bool:
  match m:
    case ModeAuthoritativeFallback{}:
      True{}
    case ModeSecure{}:
      False{}
    case ModeTransientFallback{}:
      False{}

def is_mode_secure(+m: StoreMode) -> Bool:
  match m:
    case ModeSecure{}:
      True{}
    case ModeTransientFallback{}:
      False{}
    case ModeAuthoritativeFallback{}:
      False{}

type MarkerKind is Data:
  MarkerNone{}
  MarkerTransient{
    cleared_all: Bool,
    has_deleted: Bool,
    has_replaced: Bool,
    has_transient_keys: Bool
  }
  MarkerAuthoritative{}
  MarkerLegacy{}

type StoreOp is Data:
  StoreOpRead{}
  StoreOpWrite{}
  StoreOpDelete{}
  StoreOpDeleteAll{}
  StoreOpRestart{
    cleared_all: Bool,
    has_deleted: Bool,
    has_replaced: Bool,
    has_transient_keys: Bool,
    os_reconcile_write_ok: Bool,
    keychain_had_entries: Bool
  }

def store_boot_mode.reconcile(
  +needs_reconcile: Bool,
  +has_transient_keys: Bool,
  +os_reconcile_write_ok: Bool,
  +fallback_write_ok: Bool
) -> StoreMode:
  match needs_reconcile:
    case True{}:
      match os_reconcile_write_ok:
        case True{}:
          ModeSecure{}
        case False{}:
          match fallback_write_ok:
            case True{}:
              ModeAuthoritativeFallback{}
            case False{}:
              ModeTransientFallback{}
    case False{}:
      match has_transient_keys:
        case True{}:
          ModeTransientFallback{}
        case False{}:
          ModeSecure{}

def store_boot_mode.transient(
  +os_read_ok: Bool,
  +os_reconcile_write_ok: Bool,
  +fallback_write_ok: Bool,
  +cleared_all: Bool,
  +has_deleted: Bool,
  +has_replaced: Bool,
  +has_transient_keys: Bool,
  +keychain_had_entries: Bool
) -> StoreMode:
  match os_read_ok:
    case False{}:
      ModeTransientFallback{}
    case True{}:
      store_boot_mode.reconcile(
        Bool.or(keychain_had_entries, Bool.or(cleared_all, Bool.or(has_deleted, has_replaced))),
        has_transient_keys,
        os_reconcile_write_ok,
        fallback_write_ok
      )

def store_boot_mode(
  +marker: MarkerKind,
  +os_read_ok: Bool,
  +os_reconcile_write_ok: Bool,
  +fallback_write_ok: Bool,
  +keychain_had_entries: Bool
) -> StoreMode:
  match marker:
    case MarkerAuthoritative{}:
      ModeAuthoritativeFallback{}
    case MarkerLegacy{}:
      ModeAuthoritativeFallback{}
    case MarkerNone{}:
      match os_read_ok:
        case True{}:
          ModeSecure{}
        case False{}:
          ModeTransientFallback{}
    case MarkerTransient{+ca, +hd, +hr, +ht}:
      store_boot_mode.transient(
        os_read_ok,
        os_reconcile_write_ok,
        fallback_write_ok,
        ca,
        hd,
        hr,
        ht,
        keychain_had_entries
      )

def store_step_mode(
  +mode: StoreMode,
  +op: StoreOp,
  +os_ok: Bool,
  +fallback_write_ok: Bool
) -> StoreMode:
  match mode:
    case ModeAuthoritativeFallback{}:
      ModeAuthoritativeFallback{}
    case ModeSecure{}:
      match op:
        case StoreOpRead{}:
          ModeSecure{}
        case StoreOpWrite{}:
          match os_ok:
            case True{}:
              ModeSecure{}
            case False{}:
              match fallback_write_ok:
                case True{}:
                  ModeAuthoritativeFallback{}
                case False{}:
                  ModeSecure{}
        case StoreOpDelete{}:
          ModeSecure{}
        case StoreOpDeleteAll{}:
          ModeSecure{}
        case StoreOpRestart{_, _, _, _, +os_rw, +kc}:
          store_boot_mode(MarkerNone{}, os_ok, os_rw, fallback_write_ok, kc)
    case ModeTransientFallback{}:
      match op:
        case StoreOpRead{}:
          ModeTransientFallback{}
        case StoreOpWrite{}:
          ModeTransientFallback{}
        case StoreOpDelete{}:
          ModeTransientFallback{}
        case StoreOpDeleteAll{}:
          ModeTransientFallback{}
        case StoreOpRestart{+ca, +hd, +hr, +ht, +os_rw, +kc}:
          store_boot_mode(MarkerTransient{ca, hd, hr, ht}, os_ok, os_rw, fallback_write_ok, kc)

# ---------------------------------------------------------------------------
# 2. Ownership & prefix isolation
# ---------------------------------------------------------------------------

type StoreKey is Data:
  KeyFallbackFlag{}
  KeyOwned{id: Nat}
  KeyForeign{id: Nat}

def nat_list_contains(+xs: List<&2, Nat>, +target: Nat) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case Con{+h, +t}:
      Bool.or(Nat.is_eq(h, target), nat_list_contains(t, target))

def is_fallback_flag_key(+key: StoreKey) -> Bool:
  match key:
    case KeyFallbackFlag{}:
      True{}
    case KeyOwned{_}:
      False{}
    case KeyForeign{_}:
      False{}

def can_delete_key(
  +mode: StoreMode,
  +has_manifest: Bool,
  +owned_keys: List<&2, Nat>,
  +key: StoreKey
) -> Bool:
  match mode has_manifest key:
    case _ _ KeyFallbackFlag{}:
      False{}
    case ModeSecure{} _ KeyForeign{_}:
      False{}
    case ModeTransientFallback{} True{} KeyForeign{_}:
      False{}
    case ModeTransientFallback{} False{} KeyForeign{_}:
      True{}
    case ModeAuthoritativeFallback{} True{} KeyForeign{_}:
      False{}
    case ModeAuthoritativeFallback{} False{} KeyForeign{_}:
      True{}
    case ModeSecure{} _ KeyOwned{_}:
      True{}
    case ModeTransientFallback{} True{} KeyOwned{+id}:
      nat_list_contains(owned_keys, id)
    case ModeTransientFallback{} False{} KeyOwned{_}:
      True{}
    case ModeAuthoritativeFallback{} True{} KeyOwned{+id}:
      nat_list_contains(owned_keys, id)
    case ModeAuthoritativeFallback{} False{} KeyOwned{_}:
      True{}

def can_lazy_read_fallback(
  +use_fallback: Bool,
  +has_manifest: Bool,
  +owned_keys: List<&2, Nat>,
  +key: StoreKey
) -> Bool:
  match use_fallback has_manifest key:
    case False{} _ _:
      False{}
    case True{} _ KeyFallbackFlag{}:
      False{}
    case True{} True{} KeyForeign{_}:
      False{}
    case True{} False{} KeyForeign{_}:
      True{}
    case True{} True{} KeyOwned{+id}:
      nat_list_contains(owned_keys, id)
    case True{} False{} KeyOwned{_}:
      True{}

type FallbackStoreSnapshot is Data:
  FallbackStoreSnapshot{
    flag_present: Bool,
    owned_count: Nat,
    foreign_count: Nat
  }

def delete_all_fallback_snapshot(+snap: FallbackStoreSnapshot) -> FallbackStoreSnapshot:
  match snap:
    case FallbackStoreSnapshot{+flag_present, _, +foreign_count}:
      FallbackStoreSnapshot{flag_present, 0n, foreign_count}

def snap_flag_present(+snap: FallbackStoreSnapshot) -> Bool:
  match snap:
    case FallbackStoreSnapshot{+f, _, _}:
      f

def snap_owned_count(+snap: FallbackStoreSnapshot) -> Nat:
  match snap:
    case FallbackStoreSnapshot{_, +o, _}:
      o

def snap_foreign_count(+snap: FallbackStoreSnapshot) -> Nat:
  match snap:
    case FallbackStoreSnapshot{_, _, +fr}:
      fr

# ---------------------------------------------------------------------------
# 3. Reconciliation view precedence
# ---------------------------------------------------------------------------

type EntryVal is Data:
  EntryVal{sub_a: Maybe<&2, Nat>, sub_b: Maybe<&2, Nat>}

def merge_opt(+os_sub: Maybe<&2, Nat>, +tr_sub: Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match os_sub:
    case Some{+v}:
      Some{v}
    case None{}:
      tr_sub

def merge_missing_subkeys(+os_val: EntryVal, +tr_val: EntryVal) -> EntryVal:
  match os_val tr_val:
    case EntryVal{+oa, +ob} EntryVal{+ta, +tb}:
      EntryVal{merge_opt(oa, ta), merge_opt(ob, tb)}

def reconcile_apply_transient(
  +eff_os: Maybe<&2, EntryVal>,
  +tr_entry: Maybe<&2, EntryVal>,
  +in_replaced_keys: Bool
) -> Maybe<&2, EntryVal>:
  match eff_os tr_entry in_replaced_keys:
    case +os None{} _:
      os
    case None{} Some{+tv} _:
      Some{tv}
    case Some{_} Some{+tv} True{}:
      Some{tv}
    case Some{+ov} Some{+tv} False{}:
      Some{merge_missing_subkeys(ov, tv)}

def reconcile_key_view(
  +cleared_all: Bool,
  +in_deleted_keys: Bool,
  +in_replaced_keys: Bool,
  +os_entry: Maybe<&2, EntryVal>,
  +tr_entry: Maybe<&2, EntryVal>
) -> Maybe<&2, EntryVal>:
  match cleared_all:
    case True{}:
      reconcile_apply_transient(None{}, tr_entry, in_replaced_keys)
    case False{}:
      match in_deleted_keys:
        case True{}:
          reconcile_apply_transient(None{}, tr_entry, in_replaced_keys)
        case False{}:
          reconcile_apply_transient(os_entry, tr_entry, in_replaced_keys)

# ---------------------------------------------------------------------------
# 4. Crash-safe commit ordering
# ---------------------------------------------------------------------------

type MigrationCommitResult is Data:
  MigrationCommitResult{
    entries_written: Bool,
    marker_persisted: Bool,
    next_mode: StoreMode
  }

def migrate_to_authoritative(+entries_write_ok: Bool, +marker_write_ok: Bool) -> MigrationCommitResult:
  match entries_write_ok:
    case False{}:
      MigrationCommitResult{False{}, False{}, ModeSecure{}}
    case True{}:
      match marker_write_ok:
        case False{}:
          MigrationCommitResult{True{}, False{}, ModeSecure{}}
        case True{}:
          MigrationCommitResult{True{}, True{}, ModeAuthoritativeFallback{}}

def migration_marker_persisted(+r: MigrationCommitResult) -> Bool:
  match r:
    case MigrationCommitResult{_, +m, _}:
      m

def migration_entries_written(+r: MigrationCommitResult) -> Bool:
  match r:
    case MigrationCommitResult{+e, _, _}:
      e

def migration_next_mode(+r: MigrationCommitResult) -> StoreMode:
  match r:
    case MigrationCommitResult{_, _, +m}:
      m

type CleanupCommitResult is Data:
  CleanupCommitResult{
    marker_deleted: Bool,
    transient_copies_deleted: Bool
  }

def clear_transient_fallback_data(+marker_delete_ok: Bool, +copies_delete_ok: Bool) -> CleanupCommitResult:
  match marker_delete_ok:
    case False{}:
      CleanupCommitResult{False{}, False{}}
    case True{}:
      CleanupCommitResult{True{}, copies_delete_ok}

def cleanup_marker_deleted(+r: CleanupCommitResult) -> Bool:
  match r:
    case CleanupCommitResult{+m, _}:
      m

def cleanup_copies_deleted(+r: CleanupCommitResult) -> Bool:
  match r:
    case CleanupCommitResult{_, +c}:
      c

# ---------------------------------------------------------------------------
# 5. ConfirmingRelayClient sequence-fenced subscribe/unsubscribe arbiter
# ---------------------------------------------------------------------------

def default_max_tracked_topics() -> U32:
  512

type RelayTopicState is Data:
  RelayTopicState{
    op_seq: Nat,
    latest_sub_seq: Nat,
    latest_unsub_seq: Nat,
    confirmed_unsub_seq: Nat,
    topic_map_sub_id: Nat,
    preserved_sub_id: Nat,
    unconfirmed_unsub: Bool
  }

def relay_topic_map_id(+st: RelayTopicState) -> Nat:
  match st:
    case RelayTopicState{_, _, _, _, +tm, _, _}:
      tm

def relay_preserved_id(+st: RelayTopicState) -> Nat:
  match st:
    case RelayTopicState{_, _, _, _, _, +pr, _}:
      pr

def relay_unconfirmed(+st: RelayTopicState) -> Bool:
  match st:
    case RelayTopicState{_, _, _, _, _, _, +u}:
      u

def relay_begin_op(+op_seq: Nat) -> Nat:
  1n+op_seq

def relay_finish_unsub.preserved(
  +rpc_confirmed: Bool,
  +same_id: Bool,
  +cur_preserved: Nat
) -> Nat:
  match rpc_confirmed:
    case True{}:
      match same_id:
        case True{}:
          0n
        case False{}:
          cur_preserved
    case False{}:
      cur_preserved

def relay_finish_unsub.unconfirmed(
  +rpc_confirmed: Bool,
  +replaced_by_new_sub: Bool,
  +is_fenced: Bool,
  +confirmed_by_concurrent: Bool,
  +cur_unconfirmed: Bool
) -> Bool:
  match rpc_confirmed:
    case True{}:
      match replaced_by_new_sub:
        case False{}:
          False{}
        case True{}:
          cur_unconfirmed
    case False{}:
      match is_fenced:
        case True{}:
          cur_unconfirmed
        case False{}:
          match confirmed_by_concurrent:
            case True{}:
              cur_unconfirmed
            case False{}:
              True{}

def relay_finish_unsub.topic_map(+is_fenced: Bool, +cur_tm: Nat) -> Nat:
  match is_fenced:
    case True{}:
      cur_tm
    case False{}:
      0n

def relay_finish_unsub.conf_seq(+rpc_confirmed: Bool, +call_seq: Nat, +cur_conf: Nat) -> Nat:
  match rpc_confirmed:
    case True{}:
      call_seq
    case False{}:
      cur_conf

def relay_finish_unsubscribe(
  +st: RelayTopicState,
  +call_seq: Nat,
  +confirmed_seq_at_start: Nat,
  +sub_id_used: Nat,
  +mapped_id_replaced: Bool,
  +rpc_confirmed: Bool
) -> RelayTopicState:
  match st:
    case RelayTopicState{+op_s, +lsub, +lunsub, +cseq, +tm, +pr, +unconf}:
      RelayTopicState{
        op_s,
        lsub,
        lunsub,
        relay_finish_unsub.conf_seq(rpc_confirmed, call_seq, cseq),
        relay_finish_unsub.topic_map(Bool.or(Nat.is_gt(lsub, call_seq), mapped_id_replaced), tm),
        relay_finish_unsub.preserved(rpc_confirmed, Nat.is_eq(pr, sub_id_used), pr),
        relay_finish_unsub.unconfirmed(
          rpc_confirmed,
          Nat.is_gt(lsub, call_seq),
          Bool.or(Nat.is_gt(lsub, call_seq), mapped_id_replaced),
          Bool.or(
            Nat.is_gt(cseq, confirmed_seq_at_start),
            Bool.and(Nat.is_gt(sub_id_used, 0n), Bool.not(Nat.is_eq(pr, sub_id_used)))
          ),
          unconf
        )
      }

def relay_restore.apply(+can_restore: Bool, +st: RelayTopicState, +persisted_id: Nat) -> RelayTopicState:
  match can_restore:
    case False{}:
      st
    case True{}:
      match st:
        case RelayTopicState{+op_s, +lsub, +lunsub, +cseq, +tm, _, +unconf}:
          RelayTopicState{op_s, lsub, lunsub, cseq, tm, persisted_id, unconf}

def relay_restore_preserved_id(+st: RelayTopicState, +persisted_id: Nat) -> RelayTopicState:
  match st:
    case RelayTopicState{+op_s, +lsub, +lunsub, +cseq, +tm, +pr, +unconf}:
      relay_restore.apply(
        Bool.and(
          Nat.is_gt(persisted_id, 0n),
          Bool.and(
            Nat.is_eq(lsub, 0n),
            Bool.and(Nat.is_eq(pr, 0n), Nat.is_eq(tm, 0n))
          )
        ),
        RelayTopicState{op_s, lsub, lunsub, cseq, tm, pr, unconf},
        persisted_id
      )

def remove_nat_once.step(+h: Nat, +rest: List<&2, Nat>, +eq: Bool) -> List<&2, Nat>:
  match eq:
    case True{}:
      rest
    case False{}:
      h <> rest

def remove_nat(+xs: List<&2, Nat>, +target: Nat) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+h, +t}:
      remove_nat_once.step(h, remove_nat(t, target), Nat.is_eq(h, target))

def take_n(+n: Nat, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match n xs:
    case 0n _:
      Nil{}
    case 1n+_ Nil{}:
      Nil{}
    case 1n+np Con{+h, +t}:
      h <> take_n(np, t)

# Capped topic insertion: keeps newest entries up to `cap` (matching LRU cap <= 512).
def capped_topic_insert(+cap: Nat, +xs: List<&2, Nat>, +topic: Nat) -> List<&2, Nat>:
  take_n(cap, topic <> remove_nat(xs, topic))

# ---------------------------------------------------------------------------
# 6. Web3WalletService crash-safe reset, topic epoch fencing & idempotency
# ---------------------------------------------------------------------------

type ResetSweepOutcome is Data:
  SweepAbortedNoDeletes{}
  SweepExecuted{}

def reset_sweep_step(+marker_persisted_ok: Bool) -> ResetSweepOutcome:
  match marker_persisted_ok:
    case False{}:
      SweepAbortedNoDeletes{}
    case True{}:
      SweepExecuted{}

def sweep_performed_deletes(+r: ResetSweepOutcome) -> Bool:
  match r:
    case SweepAbortedNoDeletes{}:
      False{}
    case SweepExecuted{}:
      True{}

def should_clear_reset_marker(
  +remaining_sessions: Nat,
  +remaining_pairings: Nat,
  +current_epoch: Nat,
  +captured_epoch: Nat,
  +pending_disconnect: Bool
) -> Bool:
  Bool.and(
    Nat.is_eq(remaining_sessions, 0n),
    Bool.and(
      Nat.is_eq(remaining_pairings, 0n),
      Bool.and(
        Nat.is_eq(current_epoch, captured_epoch),
        Bool.not(pending_disconnect)
      )
    )
  )

def has_active_or_pending_reset(
  +active_reset_depth: Nat,
  +has_unresolved_reset: Bool,
  +has_unconfirmed_clear: Bool,
  +pending_disconnect: Bool,
  +has_marker: Bool
) -> Bool:
  Bool.or(
    Nat.is_gt(active_reset_depth, 0n),
    Bool.or(
      has_unresolved_reset,
      Bool.or(has_unconfirmed_clear, Bool.or(pending_disconnect, has_marker))
    )
  )

def can_admit_pair(
  +is_initialized: Bool,
  +is_disposed: Bool,
  +active_or_pending_reset: Bool
) -> Bool:
  Bool.and(is_initialized, Bool.and(Bool.not(is_disposed), Bool.not(active_or_pending_reset)))

def can_admit_approve_session(
  +is_disposed: Bool,
  +has_client: Bool,
  +blocked_by_reset: Bool
) -> Bool:
  Bool.and(Bool.not(is_disposed), Bool.and(has_client, Bool.not(blocked_by_reset)))

def can_finalize_approved_session(
  +is_disposed: Bool,
  +has_client: Bool,
  +blocked_by_reset: Bool,
  +current_gen: Nat,
  +expected_gen: Nat,
  +live_session_exists: Bool
) -> Bool:
  Bool.and(
    Bool.not(is_disposed),
    Bool.and(
      has_client,
      Bool.and(
        Bool.not(blocked_by_reset),
        Bool.and(Nat.is_eq(current_gen, expected_gen), live_session_exists)
      )
    )
  )

def mark_topic_subscription_active(+current_epoch: Nat) -> Nat:
  1n+current_epoch

def is_pending_unsub_epoch_obsolete(+queued_epoch: Nat, +current_epoch: Nat) -> Bool:
  Nat.is_lt(queued_epoch, current_epoch)

def is_pending_unsub_obsolete(
  +queued_epoch: Nat,
  +current_epoch: Nat,
  +in_flight_pair: Bool,
  +live_in_stores: Bool
) -> Bool:
  Bool.or(
    Nat.is_lt(queued_epoch, current_epoch),
    Bool.and(Bool.not(in_flight_pair), live_in_stores)
  )

def should_purge_provisional_pairing(
  +pair_succeeded: Bool,
  +had_confirmed_before: Bool,
  +was_already_provisional: Bool,
  +stored_after_fail: Bool,
  +epoch_unchanged: Bool,
  +is_last_in_flight: Bool,
  +active_or_pending_reset: Bool,
  +gen_unchanged: Bool
) -> Bool:
  Bool.and(
    Bool.not(pair_succeeded),
    Bool.and(
      Bool.or(Bool.not(had_confirmed_before), was_already_provisional),
      Bool.and(
        stored_after_fail,
        Bool.and(
          epoch_unchanged,
          Bool.and(
            is_last_in_flight,
            Bool.and(Bool.not(active_or_pending_reset), gen_unchanged)
          )
        )
      )
    )
  )

def should_cleanup_orphan_pairing(
  +has_active_sessions: Bool,
  +protected_by_proposal: Bool,
  +created_epoch: Nat,
  +cleanup_start_epoch: Nat,
  +has_active_topic_op: Bool,
  +pairing_active: Bool,
  +expiry_sec: Nat,
  +now_sec: Nat
) -> Bool:
  Bool.and(
    Bool.not(has_active_sessions),
    Bool.and(
      Bool.not(protected_by_proposal),
      Bool.and(
        Bool.not(Nat.is_gt(created_epoch, cleanup_start_epoch)),
        Bool.and(
          Bool.not(has_active_topic_op),
          Bool.or(Bool.not(pairing_active), Nat.is_le(expiry_sec, now_sec))
        )
      )
    )
  )

type RequestDeliveryStatus is Data:
  ReqFresh{}
  ReqInFlight{}
  ReqCachedUnsent{response_id: Nat}
  ReqCompleted{}

type RequestAction is Data:
  ActionSkipDuplicate{}
  ActionDropStaleSession{}
  ActionRetryCachedDelivery{response_id: Nat}
  ActionExecuteHandler{}

def decide_request_action(
  +status: RequestDeliveryStatus,
  +has_active_session: Bool,
  +reset_active: Bool
) -> RequestAction:
  match status has_active_session reset_active:
    case _ _ True{}:
      ActionSkipDuplicate{}
    case ReqCompleted{} _ False{}:
      ActionSkipDuplicate{}
    case ReqInFlight{} _ False{}:
      ActionSkipDuplicate{}
    case ReqCachedUnsent{_} False{} False{}:
      ActionDropStaleSession{}
    case ReqCachedUnsent{+rid} True{} False{}:
      ActionRetryCachedDelivery{rid}
    case ReqFresh{} False{} False{}:
      ActionDropStaleSession{}
    case ReqFresh{} True{} False{}:
      ActionExecuteHandler{}

def action_executes_handler(+act: RequestAction) -> Bool:
  match act:
    case ActionExecuteHandler{}:
      True{}
    case ActionSkipDuplicate{}:
      False{}
    case ActionDropStaleSession{}:
      False{}
    case ActionRetryCachedDelivery{_}:
      False{}

def post_handler_delivery_step(
  +response_id: Nat,
  +delivery_succeeded: Bool,
  +permanent_error: Bool
) -> RequestDeliveryStatus:
  match delivery_succeeded:
    case True{}:
      ReqCompleted{}
    case False{}:
      match permanent_error:
        case True{}:
          ReqCompleted{}
        case False{}:
          ReqCachedUnsent{response_id}

def is_req_fresh(+st: RequestDeliveryStatus) -> Bool:
  match st:
    case ReqFresh{}:
      True{}
    case ReqInFlight{}:
      False{}
    case ReqCachedUnsent{_}:
      False{}
    case ReqCompleted{}:
      False{}

# ---------------------------------------------------------------------------
# 7. Parallelized crash-safety audit gate (Bend parallel-let)
# ---------------------------------------------------------------------------

def check_store_safety_branch(+mode: StoreMode, +has_manifest: Bool, +owned: List<&2, Nat>, +key: StoreKey) -> Bool:
  can_delete_key(mode, has_manifest, owned, key)

def check_relay_fence_branch(+queued_epoch: Nat, +current_epoch: Nat) -> Bool:
  Bool.not(is_pending_unsub_epoch_obsolete(queued_epoch, current_epoch))

def check_service_admission_branch(
  +is_initialized: Bool,
  +is_disposed: Bool,
  +active_or_pending_reset: Bool,
  +req_status: RequestDeliveryStatus,
  +has_active_session: Bool
) -> Bool:
  Bool.and(
    can_admit_pair(is_initialized, is_disposed, active_or_pending_reset),
    action_executes_handler(decide_request_action(req_status, has_active_session, active_or_pending_reset))
  )

def sequential_wc_crash_safety_gate(
  +mode: StoreMode,
  +has_manifest: Bool,
  +owned: List<&2, Nat>,
  +key: StoreKey,
  +queued_epoch: Nat,
  +current_epoch: Nat,
  +is_initialized: Bool,
  +is_disposed: Bool,
  +active_or_pending_reset: Bool,
  +req_status: RequestDeliveryStatus,
  +has_active_session: Bool
) -> Bool:
  Bool.and(
    check_store_safety_branch(mode, has_manifest, owned, key),
    Bool.and(
      check_relay_fence_branch(queued_epoch, current_epoch),
      check_service_admission_branch(is_initialized, is_disposed, active_or_pending_reset, req_status, has_active_session)
    )
  )

def parallel_wc_crash_safety_gate(
  +mode: StoreMode,
  +has_manifest: Bool,
  +owned: List<&2, Nat>,
  +key: StoreKey,
  +queued_epoch: Nat,
  +current_epoch: Nat,
  +is_initialized: Bool,
  +is_disposed: Bool,
  +active_or_pending_reset: Bool,
  +req_status: RequestDeliveryStatus,
  +has_active_session: Bool
) -> Bool:
  store_ok relay_ok svc_ok = check_store_safety_branch(mode, has_manifest, owned, key) check_relay_fence_branch(queued_epoch, current_epoch) check_service_admission_branch(is_initialized, is_disposed, active_or_pending_reset, req_status, has_active_session)
  Bool.and(store_ok, Bool.and(relay_ok, svc_ok))
