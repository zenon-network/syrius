import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# Constructive proofs of all Syrius wallet lifecycle, keystore schema, unlock &
# auto-erase, lock & auto-lock, splash routing, hide-widget, seed confirmation,
# and window geometry laws.

# 1. _WalletFileLifecycle proofs
# ------------------------------

def Laws.wallet_file_mutual_exclusion(s, e):
  match s:
    case M.FileIdle{}:
      Empty.absurd({True{} == False{} : Bool}, NatL.true_is_not_false(e))
    case M.FileSessionActive{}:
      {==}
    case M.FileClosing{}:
      {==}
    case M.FileClosed{}:
      {==}

def Laws.wallet_file_idle_grants_access():
  {==}

def Laws.wallet_file_closed_permanent_step(e):
  match e:
    case M.FileBeginAccess{}:
      {==}
    case M.FileEndAccess{}:
      {==}
    case M.FileRequestClose{}:
      {==}
    case M.FileFinishClose{}:
      {==}

def Laws.wallet_file_closed_permanent_run(events):
  match events:
    case Nil{}:
      {==}
    case Con{+e, +rest}:
      %Laws.wallet_file_closed_permanent_step(e) : {M.wallet_file_run(rest, M.file_outcome_state(_)) == M.FileClosed{} : M.FileState}
      Laws.wallet_file_closed_permanent_run(rest)

def Laws.wallet_file_close_idempotent(s):
  match s:
    case M.FileIdle{}:
      {==}
    case M.FileSessionActive{}:
      {==}
    case M.FileClosing{}:
      {==}
    case M.FileClosed{}:
      {==}

def Laws.wallet_file_closing_completes_on_end_access():
  {==}

# 2. Keystore schema, wallet type dispatch & backup gating proofs
# ---------------------------------------------------------------

def dup_bool_true(+x: Bool, e: {x == True{} : Bool}) -> {x == True{} : Bool} & {x == True{} : Bool}:
  match x:
    case True{}:
      ({==}, {==})
    case False{}:
      Empty.absurd({False{} == True{} : Bool} & {False{} == True{} : Bool}, NatL.false_is_not_true(e))

def and_true_3(+a: Bool, +b: Bool, +c: Bool, +d: Bool, e: {Bool.and(a, Bool.and(b, Bool.and(c, d))) == True{} : Bool}) -> {Bool.and(a, Bool.and(b, c)) == True{} : Bool}:
  match a b c:
    case True{} True{} True{}:
      {==}
    case False{} _ _:
      Empty.absurd({False{} == True{} : Bool}, NatL.false_is_not_true(e))
    case True{} False{} _:
      Empty.absurd({False{} == True{} : Bool}, NatL.false_is_not_true(e))
    case True{} True{} False{}:
      Empty.absurd({False{} == True{} : Bool}, NatL.false_is_not_true(e))

def Laws.keystore_schema_requires_min_lengths(sb, cb, nb, sh, ch, nh, cn, kdf, mt, e):
  and_true_3(Nat.is_ge(sb, 8n), Nat.is_ge(cb, 16n), Nat.is_ge(nb, 12n),
    Bool.and(sh, Bool.and(ch, Bool.and(nh, Bool.and(cn, Bool.and(kdf, mt))))), e)

def lt_implies_ge_false(+a: Nat, +b: Nat, e: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_ge(a, b) == False{} : Bool}:
  %NatL.not_lt_is_ge(a, b) : {_ == False{} : Bool}
  %Equal.sym(Bool, Nat.is_lt(a, b), True{}, e) : {Bool.not(_) == False{} : Bool}
  {==}

def Laws.keystore_schema_rejects_short_salt(sb, cb, nb, sh, ch, nh, cn, kdf, mt, e):
  %Equal.sym(Bool, Nat.is_ge(sb, 8n), False{}, lt_implies_ge_false(sb, 8n, e)) : {Bool.and(_, Bool.and(Nat.is_ge(cb, 16n), Bool.and(Nat.is_ge(nb, 12n), Bool.and(sh, Bool.and(ch, Bool.and(nh, Bool.and(cn, Bool.and(kdf, mt)))))))) == False{} : Bool}
  {==}

def Laws.wallet_type_dispatch_sound(code):
  {==}

def Laws.backup_blocked_when_locked_or_hardware(unlocked, is_hw):
  NatL.and_false_right(unlocked)

def Laws.backup_allowed_for_unlocked_software():
  {==}

# 3. WalletUnlockBloc proofs
# --------------------------

def Laws.unlock_empty_password_noop(s, limit):
  match s:
    case M.UnlockState{_, _, _, _, _}:
      {==}

def unlock_incorrect_failed_branch(+nf: Nat, +limit: Nat, ic: Bool, reached: Bool) -> {M.unlock_failed(M.unlock_incorrect_branch(nf, limit, ic, reached)) == nf : Nat}:
  match reached:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.unlock_incorrect_increments_failed(s, limit):
  match s:
    case M.UnlockState{_, +f, _, ic, _}:
      unlock_incorrect_failed_branch(1n+f, limit, ic, Nat.is_ge(1n+f, limit))

def Laws.unlock_auto_erase_at_limit(s, limit, e):
  match s:
    case M.UnlockState{_, +f, _, ic, _}:
      %Equal.sym(Bool, Nat.is_ge(1n+f, limit), True{}, e) : {(M.unlock_status(M.unlock_incorrect_branch(1n+f, limit, ic, _)), M.unlock_remaining(M.unlock_incorrect_branch(1n+f, limit, ic, _))) == (M.UnlockAutoErase{}, 0n) : M.UnlockStatus & Nat}
      {==}

def lt_sub_pos(+a: Nat, +b: Nat, e: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_gt(Nat.sub(b, a), 0n) == True{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_gt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_gt(0n, 0n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 1n+bp:
      lt_sub_pos(ap, bp, e)

def unlock_below_limit_pair(+f: Nat, +limit: Nat, ic: Bool, es: {Nat.is_lt(1n+f, limit) == True{} : Bool} & {Nat.is_lt(1n+f, limit) == True{} : Bool}) -> {(M.unlock_status(M.unlock_incorrect_branch(1n+f, limit, ic, Nat.is_ge(1n+f, limit))), Nat.is_gt(M.unlock_remaining(M.unlock_incorrect_branch(1n+f, limit, ic, Nat.is_ge(1n+f, limit))), 0n)) == (M.UnlockFailure{}, True{}) : M.UnlockStatus & Bool}:
  (e1, e2) = es
  %Equal.sym(Bool, Nat.is_ge(1n+f, limit), False{}, lt_implies_ge_false(1n+f, limit, e1)) : {(M.unlock_status(M.unlock_incorrect_branch(1n+f, limit, ic, _)), Nat.is_gt(M.unlock_remaining(M.unlock_incorrect_branch(1n+f, limit, ic, _)), 0n)) == (M.UnlockFailure{}, True{}) : M.UnlockStatus & Bool}
  %Equal.sym(Bool, Nat.is_gt(Nat.sub(limit, 1n+f), 0n), True{}, lt_sub_pos(1n+f, limit, e2)) : {(M.UnlockFailure{}, _) == (M.UnlockFailure{}, True{}) : M.UnlockStatus & Bool}
  {==}

def Laws.unlock_below_limit_stays_failure(s, limit, e):
  match s:
    case M.UnlockState{_, +f, _, ic, _}:
      unlock_below_limit_pair(f, limit, ic, dup_bool_true(Nat.is_lt(1n+f, limit), e))

def Laws.unlock_ledger_error_preserves_failed(s, limit):
  match s:
    case M.UnlockState{_, +f, _, ic, _}:
      {==}

def Laws.unlock_io_error_preserves_failed(s, limit):
  match s:
    case M.UnlockState{_, +f, _, ic, _}:
      {==}

def Laws.unlock_success_resets_and_marks_init(s, limit):
  match s:
    case M.UnlockState{_, _, _, +ic, _}:
      {==}

def Laws.unlock_first_vs_subsequent_init(s, limit):
  match s:
    case M.UnlockState{_, _, _, +ic, _}:
      {==}

def Laws.unlock_remaining_conservation(limit, failed, e):
  NatL.sub_add(failed, limit, e)

# 4. LockBloc + auto-lock proofs
# ------------------------------

def le_succ_self(+n: Nat) -> {Nat.is_le(n, 1n+n) == True{} : Bool}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      le_succ_self(p)

def Laws.lock_sequence_monotone(s, ev):
  match s ev:
    case M.LockScreenState{True{}, _, _, +seq} M.LockUserActivity{}:
      NatL.is_le_refl(seq)
    case M.LockScreenState{False{}, _, _, +seq} M.LockUserActivity{}:
      le_succ_self(seq)
    case M.LockScreenState{_, _, _, +seq} M.LockManualLock{}:
      le_succ_self(seq)
    case M.LockScreenState{_, _, _, +seq} M.LockTimerFired{True{}}:
      NatL.is_le_refl(seq)
    case M.LockScreenState{True{}, _, _, +seq} M.LockTimerFired{False{}}:
      NatL.is_le_refl(seq)
    case M.LockScreenState{False{}, _, False{}, +seq} M.LockTimerFired{False{}}:
      NatL.is_le_refl(seq)
    case M.LockScreenState{False{}, _, True{}, +seq} M.LockTimerFired{False{}}:
      le_succ_self(seq)
    case M.LockScreenState{_, _, _, +seq} M.LockUnlocked{}:
      le_succ_self(seq)

def Laws.lock_activity_suppressed_when_locked(h, t, seq):
  {==}

def Laws.lock_autolock_suppressed_by_htlc(s):
  match s:
    case M.LockScreenState{True{}, _, _, _}:
      {==}
    case M.LockScreenState{False{}, _, True{}, _}:
      {==}
    case M.LockScreenState{False{}, _, False{}, _}:
      {==}

def Laws.lock_manual_clears_handle_and_locks(s):
  match s:
    case M.LockScreenState{True{}, _, _, _}:
      {==}
    case M.LockScreenState{False{}, _, True{}, _}:
      {==}
    case M.LockScreenState{False{}, _, False{}, _}:
      {==}

# 5. SplashBloc routing & retry proofs
# ------------------------------------

def Laws.splash_delete_cache_exits_app(has_wp, has_node):
  {==}

def Laws.splash_no_wallet_routes_access(flow, has_node, e):
  match flow:
    case M.FlowNormal{}:
      {==}
    case M.FlowDev{}:
      {==}
    case M.FlowResetWallet{}:
      {==}
    case M.FlowDeleteCache{}:
      Empty.absurd({M.DestExitApp{} == M.DestAccessWallet{} : M.SplashDest}, NatL.true_is_not_false(e))

def splash_dev_home(has_node: Bool) -> {M.splash_dest_with_wallet(M.FlowDev{}, has_node) == M.DestHome{} : M.SplashDest}:
  match has_node:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.splash_with_node_or_dev_routes_home(flow, has_node, e):
  match flow:
    case M.FlowNormal{}:
      %splash_dev_home(has_node) : {(M.splash_dest_with_wallet(M.FlowDev{}, has_node), M.DestHome{}) == (_, M.DestHome{}) : M.SplashDest & M.SplashDest}
      {==}
    case M.FlowDev{}:
      %splash_dev_home(has_node) : {(M.splash_dest_with_wallet(M.FlowDev{}, has_node), M.DestHome{}) == (_, M.DestHome{}) : M.SplashDest & M.SplashDest}
      {==}
    case M.FlowResetWallet{}:
      %splash_dev_home(has_node) : {(M.splash_dest_with_wallet(M.FlowDev{}, has_node), M.DestHome{}) == (_, M.DestHome{}) : M.SplashDest & M.SplashDest}
      {==}
    case M.FlowDeleteCache{}:
      Empty.absurd({(M.splash_dest_with_wallet(M.FlowDev{}, has_node), M.DestExitApp{}) == (M.DestHome{}, M.DestHome{}) : M.SplashDest & M.SplashDest}, NatL.true_is_not_false(e))

def Laws.splash_normal_without_node_routes_node_mgmt():
  {==}

def Laws.splash_retry_blocks_non_destructive_and_non_clearing(flow, fwc):
  %Equal.sym(Bool, Bool.and(fwc, False{}), False{}, NatL.and_false_right(fwc)) : {(_, (_, False{})) == (False{}, (False{}, False{})) : Bool & (Bool & Bool)}
  {==}

def Laws.splash_retry_allows_destructive_clearing_failure():
  {==}

# 6. HideWidgetCubit proofs
# -------------------------

def Laws.hide_widget_hide_never_needs_password(cur, pw_ok):
  {==}

def Laws.hide_widget_unhide_requires_password(cur):
  {==}

# 7. Seed confirmation multiset verifier proofs
# ---------------------------------------------

def Laws.seed_drop_conserves_multiset(s, occ, old_m, new_m):
  match s:
    case M.SeedConfirmState{_, 0n, _, _, _}:
      {==}
    case M.SeedConfirmState{_, 1n+pp, +pl, _, _}:
      match occ:
        case False{}:
          NatL.add_succ(pp, pl)
        case True{}:
          {==}

def seed_verify_branch_false(+b: Nat, ok: Bool, e: {M.seed_verified(M.seed_verify_branch(b, ok)) == False{} : Bool}) -> {(M.seed_placed(M.seed_verify_branch(b, ok)), (M.seed_matched(M.seed_verify_branch(b, ok)), M.seed_pool(M.seed_verify_branch(b, ok)))) == (0n, (0n, b)) : Nat & (Nat & Nat)}:
  match ok:
    case True{}:
      Empty.absurd({(b, (b, 0n)) == (0n, (0n, b)) : Nat & (Nat & Nat)}, NatL.true_is_not_false(e))
    case False{}:
      {==}

def Laws.seed_verify_mismatch_clears_all(s, e):
  match s:
    case M.SeedConfirmState{+b, +p, +pl, +m, _}:
      seed_verify_branch_false(b, M.seed_all_matched(b, p, pl, m), e)

def seed_verify_branch_verified(+b: Nat, ok: Bool) -> {M.seed_verified(M.seed_verify_branch(b, ok)) == ok : Bool}:
  match ok:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.seed_verify_iff_all_matched(s):
  match s:
    case M.SeedConfirmState{+b, +p, +pl, +m, _}:
      seed_verify_branch_verified(b, M.seed_all_matched(b, p, pl, m))

# 8. Window geometry clamping proofs
# ----------------------------------

def window_size_min_helper(+w: U32, +h: U32, ok: Bool, e: {Bool.and(U32.is_ge(w, 1200), U32.is_ge(h, 600)) == ok : Bool}) -> {Bool.and(U32.is_ge(Pair.fst(U32, U32, M.clamp_window_size_branch(w, h, ok)), 1200), U32.is_ge(Pair.snd(U32, U32, M.clamp_window_size_branch(w, h, ok)), 600)) == True{} : Bool}:
  match ok:
    case True{}:
      e
    case False{}:
      {==}

def Laws.window_size_meets_minimums(w, h):
  window_size_min_helper(w, h, Bool.and(U32.is_ge(w, 1200), U32.is_ge(h, 600)), {==})

def Laws.window_coord_nonneg_fallback(v):
  {==}

def window_size_idem_helper(+w: U32, +h: U32, ok: Bool, e: {Bool.and(U32.is_ge(w, 1200), U32.is_ge(h, 600)) == ok : Bool}) -> {M.clamp_window_size(Pair.fst(U32, U32, M.clamp_window_size_branch(w, h, ok)), Pair.snd(U32, U32, M.clamp_window_size_branch(w, h, ok))) == M.clamp_window_size_branch(w, h, ok) : U32 & U32}:
  match ok:
    case True{}:
      %Equal.sym(Bool, Bool.and(U32.is_ge(w, 1200), U32.is_ge(h, 600)), True{}, e) : {M.clamp_window_size_branch(w, h, _) == (w, h) : U32 & U32}
      {==}
    case False{}:
      {==}

def Laws.window_geometry_idempotent(w, h, xn, x, yn, y):
  %window_size_idem_helper(w, h, Bool.and(U32.is_ge(w, 1200), U32.is_ge(h, 600)), {==}) : {M.build_window_rect(M.clamp_window_size(Pair.fst(U32, U32, M.clamp_window_size(w, h)), Pair.snd(U32, U32, M.clamp_window_size(w, h))), M.clamp_window_coord(xn, x), M.clamp_window_coord(yn, y)) == M.build_window_rect(_, M.clamp_window_coord(xn, x), M.clamp_window_coord(yn, y)) : M.WindowRect}
  {==}

# 9. Parallelized lifecycle evaluator equivalence proof
# -----------------------------------------------------

def Laws.lifecycle_par_eq_seq(events, fs, us, limit, res, ls, li, flow, has_wp, has_node, w, h, xn, x, yn, y):
  {==}
