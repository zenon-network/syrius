import Base
import ./model.bend as M

# Formal laws for Syrius wallet file lifecycle, keystore validation, unlock &
# auto-erase, lock & auto-lock, splash routing, hide-widget gating, seed
# confirmation multiset conservation, and window geometry clamping.

# 1. _WalletFileLifecycle state machine laws
# ------------------------------------------

law wallet_file_mutual_exclusion:
  for +s: M.FileState
  for e: {M.file_state_is_idle(s) == False{} : Bool}
  {M.file_outcome_granted(M.wallet_file_step(s, M.FileBeginAccess{})) == False{} : Bool}

law wallet_file_idle_grants_access:
  {M.wallet_file_step(M.FileIdle{}, M.FileBeginAccess{}) == M.FileOutcome{M.FileSessionActive{}, True{}} : M.FileOutcome}

law wallet_file_closed_permanent_step:
  for +e: M.FileEvent
  {M.wallet_file_step(M.FileClosed{}, e) == M.FileOutcome{M.FileClosed{}, False{}} : M.FileOutcome}

law wallet_file_closed_permanent_run:
  for +events: List<&2, M.FileEvent>
  {M.wallet_file_run(events, M.FileClosed{}) == M.FileClosed{} : M.FileState}

law wallet_file_close_idempotent:
  for +s: M.FileState
  {M.file_outcome_state(M.wallet_file_step(M.file_outcome_state(M.wallet_file_step(s, M.FileRequestClose{})), M.FileRequestClose{}))
    == M.file_outcome_state(M.wallet_file_step(s, M.FileRequestClose{})) : M.FileState}

law wallet_file_closing_completes_on_end_access:
  {M.file_outcome_state(M.wallet_file_step(M.FileClosing{}, M.FileEndAccess{})) == M.FileClosed{} : M.FileState}

# 2. Keystore schema, wallet type dispatch & backup gating laws
# -------------------------------------------------------------

law keystore_schema_requires_min_lengths:
  for +sb: Nat
  for +cb: Nat
  for +nb: Nat
  for +sh: Bool
  for +ch: Bool
  for +nh: Bool
  for +cn: Bool
  for +kdf: Bool
  for +mt: Bool
  for e: {M.validate_keystore_schema(sb, cb, nb, sh, ch, nh, cn, kdf, mt) == True{} : Bool}
  {Bool.and(Nat.is_ge(sb, 8n), Bool.and(Nat.is_ge(cb, 16n), Nat.is_ge(nb, 12n))) == True{} : Bool}

law keystore_schema_rejects_short_salt:
  for +sb: Nat
  for +cb: Nat
  for +nb: Nat
  for +sh: Bool
  for +ch: Bool
  for +nh: Bool
  for +cn: Bool
  for +kdf: Bool
  for +mt: Bool
  for e: {Nat.is_lt(sb, 8n) == True{} : Bool}
  {M.validate_keystore_schema(sb, cb, nb, sh, ch, nh, cn, kdf, mt) == False{} : Bool}

law wallet_type_dispatch_sound:
  for +code: Nat
  {(M.dispatch_wallet_type(M.RawTypeNone{}), (M.dispatch_wallet_type(M.RawTypeKeyStore{}), (M.dispatch_wallet_type(M.RawTypeLedger{}), M.dispatch_wallet_type(M.RawTypeOther{code}))))
    == (M.WalletKeyStore{}, (M.WalletKeyStore{}, (M.WalletLedger{}, M.WalletUnsupported{})))
    : M.ResolvedWalletType & (M.ResolvedWalletType & (M.ResolvedWalletType & M.ResolvedWalletType))}

law backup_blocked_when_locked_or_hardware:
  for +unlocked: Bool
  for +is_hw: Bool
  {Bool.or(M.can_backup_wallet(False{}, is_hw), M.can_backup_wallet(unlocked, True{})) == False{} : Bool}

law backup_allowed_for_unlocked_software:
  {M.can_backup_wallet(True{}, False{}) == True{} : Bool}

# 3. WalletUnlockBloc failed-attempt & auto-erase laws
# ----------------------------------------------------

law unlock_empty_password_noop:
  for +s: M.UnlockState
  for +limit: Nat
  {M.unlock_step(s, limit, M.AttemptEmptyPassword{}) == s : M.UnlockState}

law unlock_incorrect_increments_failed:
  for +s: M.UnlockState
  for +limit: Nat
  {M.unlock_failed(M.unlock_step(s, limit, M.AttemptIncorrectPassword{})) == 1n+M.unlock_failed(s) : Nat}

law unlock_auto_erase_at_limit:
  for +s: M.UnlockState
  for +limit: Nat
  for e: {Nat.is_ge(1n+M.unlock_failed(s), limit) == True{} : Bool}
  {(M.unlock_status(M.unlock_step(s, limit, M.AttemptIncorrectPassword{})), M.unlock_remaining(M.unlock_step(s, limit, M.AttemptIncorrectPassword{})))
    == (M.UnlockAutoErase{}, 0n) : M.UnlockStatus & Nat}

law unlock_below_limit_stays_failure:
  for +s: M.UnlockState
  for +limit: Nat
  for e: {Nat.is_lt(1n+M.unlock_failed(s), limit) == True{} : Bool}
  {(M.unlock_status(M.unlock_step(s, limit, M.AttemptIncorrectPassword{})), Nat.is_gt(M.unlock_remaining(M.unlock_step(s, limit, M.AttemptIncorrectPassword{})), 0n))
    == (M.UnlockFailure{}, True{}) : M.UnlockStatus & Bool}

law unlock_ledger_error_preserves_failed:
  for +s: M.UnlockState
  for +limit: Nat
  {(M.unlock_status(M.unlock_step(s, limit, M.AttemptLedgerError{})), M.unlock_failed(M.unlock_step(s, limit, M.AttemptLedgerError{})))
    == (M.UnlockFailure{}, M.unlock_failed(s)) : M.UnlockStatus & Nat}

law unlock_io_error_preserves_failed:
  for +s: M.UnlockState
  for +limit: Nat
  {(M.unlock_status(M.unlock_step(s, limit, M.AttemptIoError{})), M.unlock_failed(M.unlock_step(s, limit, M.AttemptIoError{})))
    == (M.UnlockFailure{}, M.unlock_failed(s)) : M.UnlockStatus & Nat}

law unlock_success_resets_and_marks_init:
  for +s: M.UnlockState
  for +limit: Nat
  {(M.unlock_status(M.unlock_step(s, limit, M.AttemptOk{})), (M.unlock_failed(M.unlock_step(s, limit, M.AttemptOk{})), (M.unlock_remaining(M.unlock_step(s, limit, M.AttemptOk{})), M.unlock_init_completed(M.unlock_step(s, limit, M.AttemptOk{})))))
    == (M.UnlockSuccess{}, (0n, (limit, True{}))) : M.UnlockStatus & (Nat & (Nat & Bool))}

law unlock_first_vs_subsequent_init:
  for +s: M.UnlockState
  for +limit: Nat
  {M.unlock_last_needed_init(M.unlock_step(s, limit, M.AttemptOk{})) == Bool.not(M.unlock_init_completed(s)) : Bool}

law unlock_remaining_conservation:
  for +limit: Nat
  for +failed: Nat
  for e: {Nat.is_le(failed, limit) == True{} : Bool}
  {Nat.add(M.compute_remaining(limit, failed), failed) == limit : Nat}

# 4. LockBloc + auto-lock laws
# ----------------------------

law lock_sequence_monotone:
  for +s: M.LockScreenState
  for +ev: M.LockInput
  {Nat.is_le(M.lock_sequence(s), M.lock_sequence(M.lock_step(s, ev))) == True{} : Bool}

law lock_activity_suppressed_when_locked:
  for +h: Bool
  for +t: Bool
  for +seq: Nat
  {M.lock_step(M.LockScreenState{True{}, h, t, seq}, M.LockUserActivity{}) == M.LockScreenState{True{}, h, t, seq} : M.LockScreenState}

law lock_autolock_suppressed_by_htlc:
  for +s: M.LockScreenState
  {M.lock_step(s, M.LockTimerFired{True{}}) == s : M.LockScreenState}

law lock_manual_clears_handle_and_locks:
  for +s: M.LockScreenState
  {(M.lock_is_locked(M.lock_step(s, M.LockManualLock{})), (M.lock_has_handle(M.lock_step(s, M.LockManualLock{})), M.lock_timer_active(M.lock_step(s, M.LockManualLock{}))))
    == (True{}, (False{}, False{})) : Bool & (Bool & Bool)}

# 5. SplashBloc routing & retry laws
# ----------------------------------

law splash_delete_cache_exits_app:
  for +has_wp: Bool
  for +has_node: Bool
  {M.splash_destination(M.FlowDeleteCache{}, has_wp, has_node) == M.DestExitApp{} : M.SplashDest}

law splash_no_wallet_routes_access:
  for +flow: M.SplashFlow
  for +has_node: Bool
  for e: {M.splash_is_delete_cache(flow) == False{} : Bool}
  {M.splash_destination(flow, False{}, has_node) == M.DestAccessWallet{} : M.SplashDest}

law splash_with_node_or_dev_routes_home:
  for +flow: M.SplashFlow
  for +has_node: Bool
  for e: {M.splash_is_delete_cache(flow) == False{} : Bool}
  {(M.splash_destination(M.FlowDev{}, True{}, has_node), M.splash_destination(flow, True{}, True{}))
    == (M.DestHome{}, M.DestHome{}) : M.SplashDest & M.SplashDest}

law splash_normal_without_node_routes_node_mgmt:
  {M.splash_destination(M.FlowNormal{}, True{}, False{}) == M.DestNodeManagement{} : M.SplashDest}

law splash_retry_blocks_non_destructive_and_non_clearing:
  for +flow: M.SplashFlow
  for +fwc: Bool
  {(M.splash_can_retry(M.FlowNormal{}, fwc), (M.splash_can_retry(M.FlowDev{}, fwc), M.splash_can_retry(flow, False{})))
    == (False{}, (False{}, False{})) : Bool & (Bool & Bool)}

law splash_retry_allows_destructive_clearing_failure:
  {(M.splash_can_retry(M.FlowResetWallet{}, True{}), M.splash_can_retry(M.FlowDeleteCache{}, True{}))
    == (True{}, True{}) : Bool & Bool}

# 6. HideWidgetCubit laws
# -----------------------

law hide_widget_hide_never_needs_password:
  for +cur: Bool
  for +pw_ok: Bool
  {M.hide_widget_step(cur, True{}, pw_ok) == True{} : Bool}

law hide_widget_unhide_requires_password:
  for +cur: Bool
  {(M.hide_widget_step(True{}, False{}, False{}), M.hide_widget_step(cur, False{}, True{}))
    == (True{}, False{}) : Bool & Bool}

# 7. Seed confirmation multiset verifier laws
# -------------------------------------------

law seed_drop_conserves_multiset:
  for +s: M.SeedConfirmState
  for +occ: Bool
  for +old_m: Bool
  for +new_m: Bool
  {Nat.add(M.seed_pool(M.seed_drop_word(s, occ, old_m, new_m)), M.seed_placed(M.seed_drop_word(s, occ, old_m, new_m)))
    == Nat.add(M.seed_pool(s), M.seed_placed(s)) : Nat}

law seed_verify_mismatch_clears_all:
  for +s: M.SeedConfirmState
  for e: {M.seed_verified(M.seed_verify(s)) == False{} : Bool}
  {(M.seed_placed(M.seed_verify(s)), (M.seed_matched(M.seed_verify(s)), M.seed_pool(M.seed_verify(s))))
    == (0n, (0n, M.seed_blanked(s))) : Nat & (Nat & Nat)}

law seed_verify_iff_all_matched:
  for +s: M.SeedConfirmState
  {M.seed_verified(M.seed_verify(s))
    == M.seed_all_matched(M.seed_blanked(s), M.seed_pool(s), M.seed_placed(s), M.seed_matched(s)) : Bool}

# 8. Window geometry clamping laws
# --------------------------------

law window_size_meets_minimums:
  for +w: U32
  for +h: U32
  {Bool.and(U32.is_ge(Pair.fst(U32, U32, M.clamp_window_size(w, h)), 1200),
    U32.is_ge(Pair.snd(U32, U32, M.clamp_window_size(w, h)), 600)) == True{} : Bool}

law window_coord_nonneg_fallback:
  for +v: U32
  {(M.clamp_window_coord(True{}, v), M.clamp_window_coord(False{}, v)) == (100, v) : U32 & U32}

law window_geometry_idempotent:
  for +w: U32
  for +h: U32
  for +xn: Bool
  for +x: U32
  for +yn: Bool
  for +y: U32
  {M.restore_window_geometry(
    Pair.fst(U32, U32, M.clamp_window_size(w, h)),
    Pair.snd(U32, U32, M.clamp_window_size(w, h)),
    False{},
    M.clamp_window_coord(xn, x),
    False{},
    M.clamp_window_coord(yn, y))
    == M.restore_window_geometry(w, h, xn, x, yn, y) : M.WindowRect}

# 9. Parallelized lifecycle evaluator equivalence
# -----------------------------------------------

law lifecycle_par_eq_seq:
  for +events: List<&2, M.FileEvent>
  for +fs: M.FileState
  for +us: M.UnlockState
  for +limit: Nat
  for +res: M.UnlockAttemptResult
  for +ls: M.LockScreenState
  for +li: M.LockInput
  for +flow: M.SplashFlow
  for +has_wp: Bool
  for +has_node: Bool
  for +w: U32
  for +h: U32
  for +xn: Bool
  for +x: U32
  for +yn: Bool
  for +y: U32
  {M.eval_lifecycle_par(events, fs, us, limit, res, ls, li, flow, has_wp, has_node, w, h, xn, x, yn, y)
    == M.eval_lifecycle_seq(events, fs, us, limit, res, ls, li, flow, has_wp, has_node, w, h, xn, x, yn, y)
    : M.LifecycleEvalResult}
