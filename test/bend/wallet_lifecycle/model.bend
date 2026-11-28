import Base

# Executable Bend specification for Syrius wallet lifecycle, file locking,
# keystore schema validation, unlock/auto-erase, lock/auto-lock, splash routing,
# hide-widget password gating, seed confirmation multiset, and window geometry.
#
# Corresponds to:
# - lib/utils/wallet_file.dart (_WalletFileLifecycle, _validateEncryptedFileJson, decrypt)
# - lib/rearchitecture/features/settings_backup/cubit/settings_backup_cubit.dart
# - lib/rearchitecture/features/lock/bloc/wallet_unlock_bloc.dart
# - lib/rearchitecture/features/lock/bloc/lock_bloc.dart & lib/widgets/main_app_container.dart
# - lib/rearchitecture/features/splash/bloc/splash_bloc.dart & view/splash_screen.dart
# - lib/rearchitecture/utils/cubits/hide_widget/hide_widget_cubit.dart
# - lib/rearchitecture/features/onboarding/view/new_wallet/new_wallet_confirm_seed_screen.dart
# - lib/main.dart (window geometry restore)

# 1. _WalletFileLifecycle state machine
# -------------------------------------

type FileState is Data:
  FileIdle{}
  FileSessionActive{}
  FileClosing{}
  FileClosed{}

type FileEvent is Data:
  FileBeginAccess{}
  FileEndAccess{}
  FileRequestClose{}
  FileFinishClose{}

type FileOutcome is Data:
  FileOutcome{state: FileState, access_granted: Bool}

def file_outcome_state(o: FileOutcome) -> FileState:
  match o:
    case FileOutcome{s, _}:
      s

def file_outcome_granted(o: FileOutcome) -> Bool:
  match o:
    case FileOutcome{_, g}:
      g

def file_state_is_idle(s: FileState) -> Bool:
  match s:
    case FileIdle{}:
      True{}
    case _:
      False{}

def wallet_file_step(s: FileState, e: FileEvent) -> FileOutcome:
  match s e:
    case FileIdle{} FileBeginAccess{}:
      FileOutcome{FileSessionActive{}, True{}}
    case FileIdle{} FileRequestClose{}:
      FileOutcome{FileClosed{}, False{}}
    case FileIdle{} _:
      FileOutcome{FileIdle{}, False{}}
    case FileSessionActive{} FileEndAccess{}:
      FileOutcome{FileIdle{}, False{}}
    case FileSessionActive{} FileRequestClose{}:
      FileOutcome{FileClosing{}, False{}}
    case FileSessionActive{} _:
      FileOutcome{FileSessionActive{}, False{}}
    case FileClosing{} FileEndAccess{}:
      FileOutcome{FileClosed{}, False{}}
    case FileClosing{} FileFinishClose{}:
      FileOutcome{FileClosed{}, False{}}
    case FileClosing{} _:
      FileOutcome{FileClosing{}, False{}}
    case FileClosed{} _:
      FileOutcome{FileClosed{}, False{}}

def wallet_file_run(events: List<&2, FileEvent>, s: FileState) -> FileState:
  match events:
    case Nil{}:
      s
    case Con{e, rest}:
      wallet_file_run(rest, file_outcome_state(wallet_file_step(s, e)))

# 2. Keystore JSON schema guard, wallet type dispatch & backup gating
# -------------------------------------------------------------------

def validate_keystore_schema(+salt_bytes: Nat, +cipher_bytes: Nat, +nonce_bytes: Nat, salt_hex_ok: Bool, cipher_hex_ok: Bool, nonce_hex_ok: Bool, has_cipher_name: Bool, has_kdf: Bool, meta_types_ok: Bool) -> Bool:
  Bool.and(Nat.is_ge(salt_bytes, 8n),
    Bool.and(Nat.is_ge(cipher_bytes, 16n),
      Bool.and(Nat.is_ge(nonce_bytes, 12n),
        Bool.and(salt_hex_ok,
          Bool.and(cipher_hex_ok,
            Bool.and(nonce_hex_ok,
              Bool.and(has_cipher_name,
                Bool.and(has_kdf, meta_types_ok))))))))

type RawWalletType is Data:
  RawTypeNone{}
  RawTypeKeyStore{}
  RawTypeLedger{}
  RawTypeOther{code: Nat}

type ResolvedWalletType is Data:
  WalletKeyStore{}
  WalletLedger{}
  WalletUnsupported{}

def dispatch_wallet_type(raw: RawWalletType) -> ResolvedWalletType:
  match raw:
    case RawTypeNone{}:
      WalletKeyStore{}
    case RawTypeKeyStore{}:
      WalletKeyStore{}
    case RawTypeLedger{}:
      WalletLedger{}
    case RawTypeOther{_}:
      WalletUnsupported{}

def can_backup_wallet(is_unlocked: Bool, is_hardware: Bool) -> Bool:
  Bool.and(is_unlocked, Bool.not(is_hardware))

# 3. WalletUnlockBloc failed-attempt & auto-erase state machine
# -------------------------------------------------------------

type UnlockStatus is Data:
  UnlockInitial{}
  UnlockSuccess{}
  UnlockFailure{}
  UnlockAutoErase{}

type UnlockAttemptResult is Data:
  AttemptEmptyPassword{}
  AttemptOk{}
  AttemptIncorrectPassword{}
  AttemptLedgerError{}
  AttemptIoError{}

type UnlockState is Data:
  UnlockState{status: UnlockStatus, failed_attempts: Nat, remaining_attempts: Nat, init_completed: Bool, last_needed_init: Bool}

def compute_remaining(+limit: Nat, +failed: Nat) -> Nat:
  Nat.sub(limit, failed)

def unlock_status(s: UnlockState) -> UnlockStatus:
  match s:
    case UnlockState{st, _, _, _, _}:
      st

def unlock_failed(s: UnlockState) -> Nat:
  match s:
    case UnlockState{_, f, _, _, _}:
      f

def unlock_remaining(s: UnlockState) -> Nat:
  match s:
    case UnlockState{_, _, r, _, _}:
      r

def unlock_init_completed(s: UnlockState) -> Bool:
  match s:
    case UnlockState{_, _, _, ic, _}:
      ic

def unlock_last_needed_init(s: UnlockState) -> Bool:
  match s:
    case UnlockState{_, _, _, _, lni}:
      lni

def unlock_incorrect_branch(+next_failed: Nat, +limit: Nat, init_done: Bool, reached_limit: Bool) -> UnlockState:
  match reached_limit:
    case True{}:
      UnlockState{UnlockAutoErase{}, next_failed, 0n, init_done, False{}}
    case False{}:
      UnlockState{UnlockFailure{}, next_failed, compute_remaining(limit, next_failed), init_done, False{}}

def unlock_step(s: UnlockState, +limit: Nat, res: UnlockAttemptResult) -> UnlockState:
  match s res:
    case UnlockState{st, f, r, ic, lni} AttemptEmptyPassword{}:
      UnlockState{st, f, r, ic, lni}
    case UnlockState{_, _, _, +init_done, _} AttemptOk{}:
      UnlockState{UnlockSuccess{}, 0n, limit, True{}, Bool.not(init_done)}
    case UnlockState{_, +failed, _, init_done, _} AttemptIncorrectPassword{}:
      unlock_incorrect_branch(1n+failed, limit, init_done, Nat.is_ge(1n+failed, limit))
    case UnlockState{_, +failed, _, init_done, _} AttemptLedgerError{}:
      UnlockState{UnlockFailure{}, failed, compute_remaining(limit, failed), init_done, False{}}
    case UnlockState{_, +failed, _, init_done, _} AttemptIoError{}:
      UnlockState{UnlockFailure{}, failed, compute_remaining(limit, failed), init_done, False{}}

# 4. LockBloc + auto-lock state machine
# -------------------------------------

type LockScreenState is Data:
  LockScreenState{is_locked: Bool, has_wallet_handle: Bool, timer_active: Bool, sequence: Nat}

type LockInput is Data:
  LockUserActivity{}
  LockManualLock{}
  LockTimerFired{has_active_incoming_swaps: Bool}
  LockUnlocked{}

def lock_is_locked(s: LockScreenState) -> Bool:
  match s:
    case LockScreenState{l, _, _, _}:
      l

def lock_has_handle(s: LockScreenState) -> Bool:
  match s:
    case LockScreenState{_, h, _, _}:
      h

def lock_timer_active(s: LockScreenState) -> Bool:
  match s:
    case LockScreenState{_, _, t, _}:
      t

def lock_sequence(s: LockScreenState) -> Nat:
  match s:
    case LockScreenState{_, _, _, seq}:
      seq

def lock_step(s: LockScreenState, ev: LockInput) -> LockScreenState:
  match s ev:
    case LockScreenState{True{}, h, t, seq} LockUserActivity{}:
      LockScreenState{True{}, h, t, seq}
    case LockScreenState{False{}, h, _, seq} LockUserActivity{}:
      LockScreenState{False{}, h, True{}, 1n+seq}
    case LockScreenState{_, _, _, seq} LockManualLock{}:
      LockScreenState{True{}, False{}, False{}, 1n+seq}
    case LockScreenState{l, h, t, seq} LockTimerFired{True{}}:
      LockScreenState{l, h, t, seq}
    case LockScreenState{True{}, h, t, seq} LockTimerFired{False{}}:
      LockScreenState{True{}, h, t, seq}
    case LockScreenState{False{}, h, False{}, seq} LockTimerFired{False{}}:
      LockScreenState{False{}, h, False{}, seq}
    case LockScreenState{False{}, _, True{}, seq} LockTimerFired{False{}}:
      LockScreenState{True{}, False{}, False{}, 1n+seq}
    case LockScreenState{_, _, _, seq} LockUnlocked{}:
      LockScreenState{False{}, True{}, True{}, 1n+seq}

# 5. SplashBloc destination routing & retry eligibility
# -----------------------------------------------------

type SplashFlow is Data:
  FlowNormal{}
  FlowDev{}
  FlowDeleteCache{}
  FlowResetWallet{}

type SplashDest is Data:
  DestAccessWallet{}
  DestHome{}
  DestNodeManagement{}
  DestExitApp{}

def splash_is_delete_cache(flow: SplashFlow) -> Bool:
  match flow:
    case FlowDeleteCache{}:
      True{}
    case _:
      False{}

def splash_dest_with_wallet(flow: SplashFlow, has_node: Bool) -> SplashDest:
  match flow has_node:
    case FlowDeleteCache{} _:
      DestExitApp{}
    case FlowDev{} _:
      DestHome{}
    case _ True{}:
      DestHome{}
    case _ False{}:
      DestNodeManagement{}

def splash_dest_non_delete(flow: SplashFlow, has_wallet_path: Bool, has_node: Bool) -> SplashDest:
  match has_wallet_path:
    case False{}:
      DestAccessWallet{}
    case True{}:
      splash_dest_with_wallet(flow, has_node)

def splash_destination(flow: SplashFlow, has_wallet_path: Bool, has_node: Bool) -> SplashDest:
  match flow:
    case FlowDeleteCache{}:
      DestExitApp{}
    case FlowNormal{}:
      splash_dest_non_delete(FlowNormal{}, has_wallet_path, has_node)
    case FlowDev{}:
      splash_dest_non_delete(FlowDev{}, has_wallet_path, has_node)
    case FlowResetWallet{}:
      splash_dest_non_delete(FlowResetWallet{}, has_wallet_path, has_node)

def splash_is_destructive_flow(flow: SplashFlow) -> Bool:
  match flow:
    case FlowResetWallet{}:
      True{}
    case FlowDeleteCache{}:
      True{}
    case _:
      False{}

def splash_can_retry(flow: SplashFlow, failed_while_clearing: Bool) -> Bool:
  Bool.and(failed_while_clearing, splash_is_destructive_flow(flow))

# 6. HideWidgetCubit password gate
# --------------------------------

def hide_widget_unhide(currently_hidden: Bool, password_valid: Bool) -> Bool:
  match password_valid:
    case True{}:
      False{}
    case False{}:
      currently_hidden

def hide_widget_step(currently_hidden: Bool, target_hidden: Bool, password_valid: Bool) -> Bool:
  match target_hidden:
    case True{}:
      True{}
    case False{}:
      hide_widget_unhide(currently_hidden, password_valid)

# 7. NewWalletConfirmSeedScreen multiset verifier
# -----------------------------------------------

type SeedConfirmState is Data:
  SeedConfirmState{blanked_count: Nat, pool_count: Nat, placed_count: Nat, matched_count: Nat, verified: Bool}

def seed_blanked(s: SeedConfirmState) -> Nat:
  match s:
    case SeedConfirmState{b, _, _, _, _}:
      b

def seed_pool(s: SeedConfirmState) -> Nat:
  match s:
    case SeedConfirmState{_, p, _, _, _}:
      p

def seed_placed(s: SeedConfirmState) -> Nat:
  match s:
    case SeedConfirmState{_, _, pl, _, _}:
      pl

def seed_matched(s: SeedConfirmState) -> Nat:
  match s:
    case SeedConfirmState{_, _, _, m, _}:
      m

def seed_verified(s: SeedConfirmState) -> Bool:
  match s:
    case SeedConfirmState{_, _, _, _, v}:
      v

def adjust_matched(+matched: Nat, slot_was_occupied: Bool, old_matched: Bool, new_matches: Bool) -> Nat:
  match slot_was_occupied old_matched new_matches:
    case False{} _ True{}:
      1n+matched
    case False{} _ False{}:
      matched
    case True{} True{} False{}:
      Nat.sub(matched, 1n)
    case True{} False{} True{}:
      1n+matched
    case True{} _ _:
      matched

def seed_drop_word(s: SeedConfirmState, slot_was_occupied: Bool, old_matched: Bool, new_matches: Bool) -> SeedConfirmState:
  match s:
    case SeedConfirmState{b, 0n, pl, m, v}:
      SeedConfirmState{b, 0n, pl, m, v}
    case SeedConfirmState{b, 1n+pp, pl, m, _}:
      match slot_was_occupied:
        case False{}:
          SeedConfirmState{b, pp, 1n+pl, adjust_matched(m, False{}, old_matched, new_matches), False{}}
        case True{}:
          SeedConfirmState{b, 1n+pp, pl, adjust_matched(m, True{}, old_matched, new_matches), False{}}

def seed_all_matched(+b: Nat, +p: Nat, +pl: Nat, +m: Nat) -> Bool:
  Bool.and(Nat.is_eq(m, b), Bool.and(Nat.is_eq(pl, b), Nat.is_eq(p, 0n)))

def seed_verify_branch(+b: Nat, ok: Bool) -> SeedConfirmState:
  match ok:
    case True{}:
      SeedConfirmState{b, 0n, b, b, True{}}
    case False{}:
      SeedConfirmState{b, b, 0n, 0n, False{}}

def seed_verify(s: SeedConfirmState) -> SeedConfirmState:
  match s:
    case SeedConfirmState{+b, +p, +pl, +m, _}:
      seed_verify_branch(b, seed_all_matched(b, p, pl, m))

# 8. Window geometry clamping (lib/main.dart)
# -------------------------------------------

type WindowRect is Data:
  WindowRect{width: U32, height: U32, x: U32, y: U32}

def clamp_window_size_branch(+w: U32, +h: U32, ok: Bool) -> U32 & U32:
  match ok:
    case True{}:
      (w, h)
    case False{}:
      (1200, 600)

def clamp_window_size(+w: U32, +h: U32) -> U32 & U32:
  clamp_window_size_branch(w, h, Bool.and(U32.is_ge(w, 1200), U32.is_ge(h, 600)))

def clamp_window_coord(is_negative: Bool, +val: U32) -> U32:
  match is_negative:
    case True{}:
      100
    case False{}:
      val

def build_window_rect(wh: U32 & U32, x: U32, y: U32) -> WindowRect:
  (w, h) = wh
  WindowRect{w, h, x, y}

def restore_window_geometry(+w: U32, +h: U32, x_neg: Bool, +x: U32, y_neg: Bool, +y: U32) -> WindowRect:
  build_window_rect(clamp_window_size(w, h), clamp_window_coord(x_neg, x), clamp_window_coord(y_neg, y))

# 9. Parallelized multi-invariant / trace evaluator using Bend parallel-let
# -------------------------------------------------------------------------

type LifecycleEvalResult is Data:
  LifecycleEvalResult{file_state: FileState, unlock_state: UnlockState, lock_state: LockScreenState, splash_dest: SplashDest, window: WindowRect}

def eval_wallet_branch(events: List<&2, FileEvent>, fs: FileState, us: UnlockState, +limit: Nat, res: UnlockAttemptResult) -> FileState & UnlockState:
  (wallet_file_run(events, fs), unlock_step(us, limit, res))

def eval_shell_branch(ls: LockScreenState, li: LockInput, flow: SplashFlow, has_wp: Bool, has_node: Bool, +w: U32, +h: U32, xn: Bool, +x: U32, yn: Bool, +y: U32) -> LockScreenState & (SplashDest & WindowRect):
  (lock_step(ls, li), (splash_destination(flow, has_wp, has_node), restore_window_geometry(w, h, xn, x, yn, y)))

def combine_lifecycle(wb: FileState & UnlockState, sb: LockScreenState & (SplashDest & WindowRect)) -> LifecycleEvalResult:
  (fs, us) = wb
  (ls, rest) = sb
  (sd, wr) = rest
  LifecycleEvalResult{fs, us, ls, sd, wr}

def eval_lifecycle_seq(events: List<&2, FileEvent>, fs: FileState, us: UnlockState, +limit: Nat, res: UnlockAttemptResult, ls: LockScreenState, li: LockInput, flow: SplashFlow, has_wp: Bool, has_node: Bool, +w: U32, +h: U32, xn: Bool, +x: U32, yn: Bool, +y: U32) -> LifecycleEvalResult:
  wb = eval_wallet_branch(events, fs, us, limit, res)
  sb = eval_shell_branch(ls, li, flow, has_wp, has_node, w, h, xn, x, yn, y)
  combine_lifecycle(wb, sb)

def eval_lifecycle_par(events: List<&2, FileEvent>, fs: FileState, us: UnlockState, +limit: Nat, res: UnlockAttemptResult, ls: LockScreenState, li: LockInput, flow: SplashFlow, has_wp: Bool, has_node: Bool, +w: U32, +h: U32, xn: Bool, +x: U32, yn: Bool, +y: U32) -> LifecycleEvalResult:
  wb sb = eval_wallet_branch(events, fs, us, limit, res) eval_shell_branch(ls, li, flow, has_wp, has_node, w, h, xn, x, yn, y)
  combine_lifecycle(wb, sb)
