import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# =============================================================================
# Local helper lemmas
# =============================================================================

def eq_zero_not_gt_zero(+x: Nat) -> {Bool.not(Nat.is_gt(x, 0n)) == Nat.is_eq(x, 0n) : Bool}:
  match x:
    case 0n:
      {==}
    case 1n+p:
      {==}

def sub_step_one(+c: Nat, +p: Nat) -> {Nat.sub(Nat.sub(c, 1n), p) == Nat.sub(c, 1n+p) : Nat}:
  match c:
    case 0n:
      {==}
    case 1n+cp:
      %Equal.sym(Nat, Nat.sub(cp, 0n), cp, NatL.sub_zero(cp)) : {Nat.sub(_, p) == Nat.sub(cp, p) : Nat}
      {==}

def is_le_succ_right(+a: Nat) -> {Nat.is_le(a, 1n+a) == True{} : Bool}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      is_le_succ_right(p)

def is_lt_from_le_succ(+a: Nat, +b: Nat, e: {Nat.is_le(a, b) == True{} : Bool}) -> {Nat.is_lt(a, 1n+b) == True{} : Bool}:
  match a b:
    case 0n _:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 1n) == True{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ap 1n+bp:
      is_lt_from_le_succ(ap, bp, e)

def le_false_from_lt(+iv: Nat, +ra: Nat, e: {Nat.is_lt(iv, ra) == True{} : Bool}) -> {Nat.is_le(ra, iv) == False{} : Bool}:
  match iv ra:
    case 0n 0n:
      Empty.absurd({Nat.is_le(0n, 0n) == False{} : Bool}, NatL.false_is_not_true(e))
    case 0n 1n+rap:
      {==}
    case 1n+ivp 0n:
      Empty.absurd({Nat.is_le(0n, 1n+ivp) == False{} : Bool}, NatL.false_is_not_true(e))
    case 1n+ivp 1n+rap:
      le_false_from_lt(ivp, rap, e)

def bool_eq_refl_local(+b: Bool) -> {M.bool_eq(b, b) == True{} : Bool}:
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

def lock_acquire_n_count(+n: Nat, +s: M.AddrLockState) -> {M.lock_count(M.lock_acquire_n(n, s)) == Nat.add(n, M.lock_count(s)) : Nat}:
  match n s:
    case 0n _:
      {==}
    case 1n+p M.AddrLockState{c, _}:
      %NatL.add_succ(p, c) : {M.lock_count(M.lock_acquire_n(p, M.AddrLockState{1n+c, True{}})) == _ : Nat}
      lock_acquire_n_count(p, M.AddrLockState{1n+c, True{}})

def lock_release_n_count(+n: Nat, +s: M.AddrLockState) -> {M.lock_count(M.lock_release_n(n, s)) == Nat.sub(M.lock_count(s), n) : Nat}:
  match n:
    case 0n:
      match s:
        case M.AddrLockState{c, _}:
          Equal.sym(Nat, Nat.sub(c, 0n), c, NatL.sub_zero(c))
    case 1n+p:
      match s:
        case M.AddrLockState{c, _}:
          %sub_step_one(c, p) : {M.lock_count(M.lock_release_n(p, M.AddrLockState{Nat.sub(c, 1n), Nat.is_gt(Nat.sub(c, 1n), 0n)})) == _ : Nat}
          lock_release_n_count(p, M.AddrLockState{Nat.sub(c, 1n), Nat.is_gt(Nat.sub(c, 1n), 0n)})

def pow_status_for_count_is_gen(+c: Nat) -> {M.pow_is_generating(M.PowState{c, M.pow_status_for_count(c)}) == Nat.is_gt(c, 0n) : Bool}:
  match c:
    case 0n:
      {==}
    case 1n+p:
      {==}

def pow_apply_n_gen_state(+n: Nat, +c: Nat) -> {M.pow_apply_n_gen(n, M.PowState{c, M.pow_status_for_count(c)}) == M.PowState{Nat.add(n, c), M.pow_status_for_count(Nat.add(n, c))} : M.PowState}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %NatL.add_succ(p, c) : {M.pow_apply_n_gen(p, M.PowState{1n+c, M.PowActive{}}) == M.PowState{_, M.pow_status_for_count(_)} : M.PowState}
      pow_apply_n_gen_state(p, 1n+c)

def pow_apply_n_done_state(+n: Nat, +c: Nat) -> {M.pow_apply_n_done(n, M.PowState{c, M.pow_status_for_count(c)}) == M.PowState{Nat.sub(c, n), M.pow_status_for_count(Nat.sub(c, n))} : M.PowState}:
  match n:
    case 0n:
      %NatL.sub_zero(c) : {M.PowState{_, M.pow_status_for_count(_)} == M.PowState{Nat.sub(c, 0n), M.pow_status_for_count(Nat.sub(c, 0n))} : M.PowState}
      {==}
    case 1n+p:
      %sub_step_one(c, p) : {M.pow_apply_n_done(p, M.PowState{Nat.sub(c, 1n), M.pow_status_for_count(Nat.sub(c, 1n))}) == M.PowState{_, M.pow_status_for_count(_)} : M.PowState}
      pow_apply_n_done_state(p, Nat.sub(c, 1n))

def snoc_len(+xs: List<&2, Nat>, +x: Nat) -> {M.nat_list_len(M.nat_list_snoc(xs, x)) == 1n+M.nat_list_len(xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %snoc_len(t, x) : {1n+M.nat_list_len(M.nat_list_snoc(t, x)) == 1n+_ : Nat}
      {==}

def snoc_contains_self(+xs: List<&2, Nat>, +x: Nat) -> {M.nat_list_contains(M.nat_list_snoc(xs, x), x) == True{} : Bool}:
  match xs:
    case Nil{}:
      %Equal.sym(Bool, Nat.is_eq(x, x), True{}, NatL.is_eq_same(x)) : {Bool.or(_, False{}) == True{} : Bool}
      {==}
    case h <> t:
      %Equal.sym(Bool, M.nat_list_contains(M.nat_list_snoc(t, x), x), True{}, snoc_contains_self(t, x)) : {Bool.or(Nat.is_eq(h, x), _) == True{} : Bool}
      NatL.or_true_right(Nat.is_eq(h, x))

def poll_sleep_gate_within(+ra: Nat, +iv: Nat, +too_late: Bool, e: {too_late == Nat.is_le(ra, iv) : Bool}) -> {M.poll_decision_within_deadline(ra, M.poll_sleep_gate(too_late, iv)) == True{} : Bool}:
  match too_late:
    case True{}:
      {==}
    case False{}:
      %NatL.is_gt_as_lt(ra, iv) : {_ == True{} : Bool}
      %NatL.not_le_is_gt(ra, iv) : {_ == True{} : Bool}
      %e : {Bool.not(_) == True{} : Bool}
      {==}

# Euclidean division invariants for Base's Nat.divmod.go
# ------------------------------------------------------

def divmod_step_zero_arith(+np: Nat, +r: Nat, +d: Nat) -> {Nat.add(np, Nat.add(Nat.mul(1n+d, 1n+r), 0n)) == Nat.add(1n+np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}:
  %Equal.sym(Nat, Nat.add(Nat.mul(1n+d, 1n+r), 0n), Nat.mul(1n+d, 1n+r), NatL.add_zero(Nat.mul(1n+d, 1n+r))) : {Nat.add(np, _) == Nat.add(1n+np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
  %NatL.add_comm(Nat.mul(d, 1n+r), 1n+r) : {Nat.add(np, _) == Nat.add(1n+np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
  %Equal.sym(Nat, Nat.add(Nat.mul(d, 1n+r), 1n+r), 1n+Nat.add(Nat.mul(d, 1n+r), r), NatL.add_succ(Nat.mul(d, 1n+r), r)) : {Nat.add(np, _) == Nat.add(1n+np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
  NatL.add_succ(np, Nat.add(Nat.mul(d, 1n+r), r))

def divmod_step_succ_arith(+np: Nat, +x: Nat, +r: Nat) -> {Nat.add(np, Nat.add(x, 1n+r)) == Nat.add(1n+np, Nat.add(x, r)) : Nat}:
  %Equal.sym(Nat, Nat.add(x, 1n+r), 1n+Nat.add(x, r), NatL.add_succ(x, r)) : {Nat.add(np, _) == Nat.add(1n+np, Nat.add(x, r)) : Nat}
  NatL.add_succ(np, Nat.add(x, r))

def divmod_go_eq(+n: Nat, +m: Nat, +d: Nat, +r: Nat) -> {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(n, m, d, r)), 1n+Nat.add(m, r)), Pair.snd(Nat, Nat, Nat.divmod.go(n, m, d, r))) == Nat.add(n, Nat.add(Nat.mul(d, 1n+Nat.add(m, r)), r)) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+np:
      match m:
        case 0n:
          %NatL.add_zero(r) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n))) == Nat.add(1n+np, Nat.add(Nat.mul(d, 1n+r), r)) : Nat}
          %divmod_step_zero_arith(np, r, d) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n)), 1n+Nat.add(r, 0n)), Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n))) == _ : Nat}
          %NatL.add_zero(r) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n)), 1n+Nat.add(r, 0n)), Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n))) == Nat.add(np, Nat.add(Nat.mul(1n+d, 1n+_), 0n)) : Nat}
          divmod_go_eq(np, r, 1n+d, 0n)
        case 1n+mp:
          %NatL.add_succ(mp, r) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r))) == Nat.add(1n+np, Nat.add(Nat.mul(d, 1n+_), r)) : Nat}
          %divmod_step_succ_arith(np, Nat.mul(d, 1n+Nat.add(mp, 1n+r)), r) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r)), 1n+Nat.add(mp, 1n+r)), Pair.snd(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r))) == _ : Nat}
          divmod_go_eq(np, mp, d, 1n+r)

def divmod_go_rem_le(+n: Nat, +m: Nat, +d: Nat, +r: Nat) -> {Nat.is_le(Pair.snd(Nat, Nat, Nat.divmod.go(n, m, d, r)), Nat.add(m, r)) == True{} : Bool}:
  match n:
    case 0n:
      NatL.is_le_add_left(m, r)
    case 1n+np:
      match m:
        case 0n:
          %NatL.add_zero(r) : {Nat.is_le(Pair.snd(Nat, Nat, Nat.divmod.go(np, r, 1n+d, 0n)), _) == True{} : Bool}
          divmod_go_rem_le(np, r, 1n+d, 0n)
        case 1n+mp:
          %NatL.add_succ(mp, r) : {Nat.is_le(Pair.snd(Nat, Nat, Nat.divmod.go(np, mp, d, 1n+r)), _) == True{} : Bool}
          divmod_go_rem_le(np, mp, d, 1n+r)

def divmod_eq(+a: Nat, +dp: Nat) -> {Nat.add(Nat.mul(Nat.div(a, 1n+dp), 1n+dp), Nat.mod(a, 1n+dp)) == a : Nat}:
  %NatL.add_zero(a) : {Nat.add(Nat.mul(Nat.div(a, 1n+dp), 1n+dp), Nat.mod(a, 1n+dp)) == _ : Nat}
  %NatL.add_zero(dp) : {Nat.add(Nat.mul(Pair.fst(Nat, Nat, Nat.divmod.go(a, dp, 0n, 0n)), 1n+_), Pair.snd(Nat, Nat, Nat.divmod.go(a, dp, 0n, 0n))) == Nat.add(a, 0n) : Nat}
  divmod_go_eq(a, dp, 0n, 0n)

def divmod_rem_le(+a: Nat, +dp: Nat) -> {Nat.is_le(Nat.mod(a, 1n+dp), dp) == True{} : Bool}:
  %NatL.add_zero(dp) : {Nat.is_le(Pair.snd(Nat, Nat, Nat.divmod.go(a, dp, 0n, 0n)), _) == True{} : Bool}
  divmod_go_rem_le(a, dp, 0n, 0n)

# =============================================================================
# Proofs of LAWS.bend
# =============================================================================

# --- 1. AccountBlockUtils preconditions & wallet-identity fence ---

def Laws.tx_sync_done_always_synced(cur, tgt):
  {==}

def Laws.tx_sync_zero_target_not_synced(cur):
  {==}

def Laws.tx_sync_boundary_19_synced(cp):
  %Equal.sym(Nat, Nat.sub(Nat.add(1n+cp, 19n), 1n+cp), 19n, NatL.sub_cancel_add_left(1n+cp, 19n)) : {Nat.is_lt(_, 20n) == True{} : Bool}
  {==}

def Laws.tx_sync_boundary_20_unsynced(cp):
  %Equal.sym(Nat, Nat.sub(Nat.add(1n+cp, 20n), 1n+cp), 20n, NatL.sub_cancel_add_left(1n+cp, 20n)) : {Nat.is_lt(_, 20n) == False{} : Bool}
  {==}

def Laws.tx_precond_unsynced_rejected(st, cur, tgt, ea, sa, in_w, wid, e):
  %Equal.sym(Bool, M.node_is_synced_for_tx(st, cur, tgt), False{}, e) : {M.check_precond_gate(_, ea, sa, in_w, wid) == M.ErrNodeNotSynced{} : M.PrecondOutcome}
  {==}

def Laws.tx_precond_addr_not_in_wallet_rejected(cur, tgt, addr, sa, wid):
  {==}

def Laws.tx_precond_wallet_locked_rejected(cur, tgt, addr, sa):
  {==}

def Laws.tx_publish_fence_locked_after_lock_aborts(wid, addr_ok, w_acc):
  {==}

def Laws.tx_publish_fence_swapped_after_lock_aborts(wid, other, addr_ok, w_acc, neq):
  %Equal.sym(Bool, Nat.is_eq(wid, other), False{}, neq) : {M.check_publish_fence_lock(_, addr_ok, wid, w_acc) == M.AbortedWalletChanged{} : M.PublishFenceOutcome}
  {==}

def Laws.tx_publish_fence_changed_in_access_aborts(wid, w_acc, mismatch):
  %Equal.sym(Bool, Nat.is_eq(wid, wid), True{}, NatL.is_eq_same(wid)) : {M.check_publish_fence_lock(_, True{}, wid, w_acc) == M.AbortedWalletChanged{} : M.PublishFenceOutcome}
  %Equal.sym(Bool, M.wallet_identity_matches(wid, w_acc), False{}, mismatch) : {M.check_publish_fence_access(_) == M.AbortedWalletChanged{} : M.PublishFenceOutcome}
  {==}

# --- 2. Per-address send lock ref-counter ---

def Laws.lock_acquire_increments_and_present(s):
  match s:
    case M.AddrLockState{c, p}:
      {==}

def Laws.lock_release_evicts_iff_zero(s):
  match s:
    case M.AddrLockState{c, p}:
      eq_zero_not_gt_zero(Nat.sub(c, 1n))

def Laws.lock_balanced_acquire_release(s):
  match s:
    case M.AddrLockState{c, p}:
      NatL.sub_zero(c)

def Laws.lock_nested_balanced_n(n, s):
  %Equal.sym(Nat, M.lock_count(M.lock_release_n(n, M.lock_acquire_n(n, s))), Nat.sub(M.lock_count(M.lock_acquire_n(n, s)), n), lock_release_n_count(n, M.lock_acquire_n(n, s))) : {_ == M.lock_count(s) : Nat}
  %Equal.sym(Nat, M.lock_count(M.lock_acquire_n(n, s)), Nat.add(n, M.lock_count(s)), lock_acquire_n_count(n, s)) : {Nat.sub(_, n) == M.lock_count(s) : Nat}
  NatL.sub_cancel_add_left(n, M.lock_count(s))

# --- 3. PowGeneratingStatusBloc ref-count reducer & HW review deferral ---

def Laws.pow_status_matches_count(s, ev):
  match s:
    case M.PowState{c, st}:
      pow_status_for_count_is_gen(M.pow_next_count(c, ev))

def Laws.pow_done_at_zero_clamps():
  {==}

def Laws.pow_balanced_nesting_returns_idle(n):
  %Equal.sym(M.PowState, M.pow_apply_n_gen(n, M.PowState{0n, M.PowIdle{}}), M.PowState{Nat.add(n, 0n), M.pow_status_for_count(Nat.add(n, 0n))}, pow_apply_n_gen_state(n, 0n)) : {M.pow_apply_n_done(n, _) == M.PowState{0n, M.PowIdle{}} : M.PowState}
  %Equal.sym(M.PowState, M.pow_apply_n_done(n, M.PowState{Nat.add(n, 0n), M.pow_status_for_count(Nat.add(n, 0n))}), M.PowState{Nat.sub(Nat.add(n, 0n), n), M.pow_status_for_count(Nat.sub(Nat.add(n, 0n), n))}, pow_apply_n_done_state(n, Nat.add(n, 0n))) : {_ == M.PowState{0n, M.PowIdle{}} : M.PowState}
  %Equal.sym(Nat, Nat.sub(Nat.add(n, 0n), n), 0n, NatL.sub_cancel_add_left(n, 0n)) : {M.PowState{_, M.pow_status_for_count(_)} == M.PowState{0n, M.PowIdle{}} : M.PowState}
  {==}

def Laws.pow_edge_only_emission(s, ev):
  match s:
    case M.PowState{c, st}:
      {==}

def Laws.hw_review_deferred_iff_plasma(need_plasma):
  match need_plasma:
    case False{}:
      {==}
    case True{}:
      {==}

# --- 4. AutoReceiveTxWorker queue / mutex / preemption ---

def Laws.auto_receive_add_hash_requires_sync(s, h):
  %Equal.sym(Bool, Bool.and(Bool.not(M.nat_list_contains(M.ar_pool(s), h)), False{}), False{}, NatL.and_false_right(Bool.not(M.nat_list_contains(M.ar_pool(s), h)))) : {M.ar_add_hash_gate(_, s, h) == s : M.AutoReceiveState}
  {==}

def Laws.auto_receive_add_hash_dedup(s, h, synced, dup):
  %Equal.sym(Bool, M.nat_list_contains(M.ar_pool(s), h), True{}, dup) : {M.ar_add_hash_gate(Bool.and(Bool.not(_), synced), s, h) == s : M.AutoReceiveState}
  {==}

def Laws.auto_receive_add_hash_enqueues(s, h, fresh):
  match s:
    case M.AutoReceiveState{p, r, n}:
      %Equal.sym(Bool, M.nat_list_contains(p, h), False{}, fresh) : {Bool.and(Nat.is_eq(M.nat_list_len(M.ar_pool(M.ar_add_hash_gate(Bool.and(Bool.not(_), True{}), M.AutoReceiveState{p, r, n}, h))), 1n+M.nat_list_len(p)), M.nat_list_contains(M.ar_pool(M.ar_add_hash_gate(Bool.and(Bool.not(_), True{}), M.AutoReceiveState{p, r, n}, h)), h)) == True{} : Bool}
      %Equal.sym(Nat, M.nat_list_len(M.nat_list_snoc(p, h)), 1n+M.nat_list_len(p), snoc_len(p, h)) : {Bool.and(Nat.is_eq(_, 1n+M.nat_list_len(p)), M.nat_list_contains(M.nat_list_snoc(p, h), h)) == True{} : Bool}
      %Equal.sym(Bool, Nat.is_eq(1n+M.nat_list_len(p), 1n+M.nat_list_len(p)), True{}, NatL.is_eq_same(1n+M.nat_list_len(p))) : {Bool.and(_, M.nat_list_contains(M.nat_list_snoc(p, h), h)) == True{} : Bool}
      snoc_contains_self(p, h)

def Laws.auto_receive_disabled_clears_pool(s, htlc, out):
  match s:
    case M.AutoReceiveState{p, r, n}:
      {==}

def Laws.auto_receive_htlc_preempts_preserving_pool(s, out):
  match s:
    case M.AutoReceiveState{p, r, n}:
      {==}

def Laws.auto_receive_single_flight_rejects_reentry(pool, seq, htlc):
  {==}

def Laws.auto_receive_ok_and_already_received_pop_head(h, t, r, seq):
  %Equal.sym(Bool, Nat.is_eq(M.nat_list_len(t), M.nat_list_len(t)), True{}, NatL.is_eq_same(M.nat_list_len(t))) : {Bool.and(_, _) == True{} : Bool}
  {==}

def Laws.auto_receive_other_error_preserves_head(h, t, r, seq):
  {==}

def Laws.auto_receive_seq_monotonic(s, en, htlc, out):
  match s en htlc:
    case M.AutoReceiveState{p, r, n} False{} _:
      NatL.is_le_refl(n)
    case M.AutoReceiveState{p, r, n} True{} True{}:
      NatL.is_le_refl(n)
    case M.AutoReceiveState{Nil{}, r, n} True{} False{}:
      NatL.is_le_refl(n)
    case M.AutoReceiveState{h <> t, r, n} True{} False{}:
      match out:
        case M.ReceiveOk{}:
          is_le_succ_right(n)
        case M.ReceiveAlreadyReceived{}:
          is_le_succ_right(n)
        case M.ReceiveOtherError{}:
          is_le_succ_right(n)

# --- 5. pollUntilConfirmed ---

def Laws.poll_never_sleeps_past_deadline(cb, rb, out, ca, ra, iv):
  match cb:
    case True{}:
      {==}
    case False{}:
      match rb:
        case 0n:
          {==}
        case 1n+rbp:
          match out:
            case M.FetchTimedOut{}:
              {==}
            case M.FetchConfirmed{}:
              {==}
            case M.FetchNotConfirmed{}:
              match ca:
                case True{}:
                  {==}
                case False{}:
                  poll_sleep_gate_within(ra, iv, Nat.is_le(ra, iv), {==})
            case M.FetchTransientError{}:
              match ca:
                case True{}:
                  {==}
                case False{}:
                  poll_sleep_gate_within(ra, iv, Nat.is_le(ra, iv), {==})

def Laws.poll_confirmed_returns_true(rbp, ca, ra, iv):
  {==}

def Laws.poll_cancelled_returns_false(rb, out, ca, ra, iv):
  {==}

def Laws.poll_transient_error_continues(rbp, ra, iv, has_time):
  %Equal.sym(Bool, Nat.is_le(ra, iv), False{}, le_false_from_lt(iv, ra, has_time)) : {M.poll_sleep_gate(_, iv) == M.PollSleep{iv} : M.PollStepDecision}
  {==}

# --- 6. InfiniteListBloc pagination & generation fencing ---

def Laws.il_stale_first_page_discarded(s, rid, fetched, ok, stale):
  %Equal.sym(Bool, Nat.is_eq(rid, M.il_active_req_id(s)), False{}, stale) : {M.il_apply_first_gate(_, s, fetched, ok) == s : M.InfiniteListModel}
  {==}

def Laws.il_stale_more_page_discarded(s, rid, snap, ea, fetched, ok, stale):
  match s:
    case M.InfiniteListModel{st, cnt, hrm, arid, aa, ps}:
      %Equal.sym(Bool, Nat.is_eq(rid, arid), False{}, stale) : {M.il_apply_more_gate(Bool.and(M.il_can_load_more(M.InfiniteListModel{st, cnt, hrm, arid, aa, ps}, ea), Bool.and(_, Nat.is_eq(cnt, snap))), M.InfiniteListModel{st, cnt, hrm, arid, aa, ps}, fetched, ok) == M.InfiniteListModel{st, cnt, hrm, arid, aa, ps} : M.InfiniteListModel}
      %Equal.sym(Bool, Bool.and(M.il_can_load_more(M.InfiniteListModel{st, cnt, hrm, arid, aa, ps}, ea), False{}), False{}, NatL.and_false_right(M.il_can_load_more(M.InfiniteListModel{st, cnt, hrm, arid, aa, ps}, ea))) : {M.il_apply_more_gate(_, M.InfiniteListModel{st, cnt, hrm, arid, aa, ps}, fetched, ok) == M.InfiniteListModel{st, cnt, hrm, arid, aa, ps} : M.InfiniteListModel}
      {==}

def Laws.il_more_noop_when_max(st, cnt, rid, aa, ps, req, snap, ea, fetched, ok):
  {==}

def Laws.il_more_noop_on_addr_mismatch(st, cnt, hrm, ridp, aa, ps, ea, neq):
  match hrm:
    case True{}:
      {==}
    case False{}:
      neq

def Laws.il_has_reached_max_iff_short(s, fetched):
  match s:
    case M.InfiniteListModel{st, cnt, hrm, rid, aa, ps}:
      %Equal.sym(Bool, Nat.is_eq(rid, rid), True{}, NatL.is_eq_same(rid)) : {M.il_has_reached_max(M.il_apply_first_gate(_, M.InfiniteListModel{st, cnt, hrm, rid, aa, ps}, fetched, True{})) == Nat.is_lt(fetched, ps) : Bool}
      {==}

# --- 7. FetchBloc, TimerState, BalanceCubit & AccountChainStats ---

def Laws.fetch_loading_iff_inflight(s):
  match s:
    case M.FetchLoadingState{c, l}:
      bool_eq_refl_local(Nat.is_gt(Nat.sub(c, 1n), 0n))

def Laws.timer_step_preserves_valid(s, ws_open, fetch_ok):
  match s:
    case M.TimerStateModel{st, hd, he}:
      match ws_open fetch_ok:
        case False{} _:
          {==}
        case True{} False{}:
          {==}
        case True{} True{}:
          {==}

def Laws.balance_non_empty_partition(znn, qsr, bc):
  %Equal.sym(Bool, Bool.and(Nat.is_gt(bc, 0n), False{}), False{}, NatL.and_false_right(Nat.is_gt(bc, 0n))) : {Bool.and(Bool.not(_), Bool.or(Nat.is_gt(znn, 0n), True{})) == True{} : Bool}
  NatL.or_true_right(Nat.is_gt(znn, 0n))

def Laws.account_chain_stats_ceil_div_covers(bp, pp):
  %divmod_eq(bp, pp) : {Nat.is_le(_, Nat.add(pp, Nat.mul(Nat.div(bp, 1n+pp), 1n+pp))) == True{} : Bool}
  %NatL.add_comm(Nat.mod(bp, 1n+pp), Nat.mul(Nat.div(bp, 1n+pp), 1n+pp)) : {Nat.is_le(_, Nat.add(pp, Nat.mul(Nat.div(bp, 1n+pp), 1n+pp))) == True{} : Bool}
  NatL.add_monotone_le(
    Nat.mod(bp, 1n+pp), pp,
    Nat.mul(Nat.div(bp, 1n+pp), 1n+pp), Nat.mul(Nat.div(bp, 1n+pp), 1n+pp),
    divmod_rem_le(bp, pp),
    NatL.is_le_refl(Nat.mul(Nat.div(bp, 1n+pp), 1n+pp))
  )

def Laws.account_chain_stats_ceil_div_minimal(bp, pp):
  %Equal.sym(Nat, Nat.sub(Nat.div(bp, 1n+pp), 0n), Nat.div(bp, 1n+pp), NatL.sub_zero(Nat.div(bp, 1n+pp))) : {Nat.is_lt(Nat.mul(_, 1n+pp), 1n+bp) == True{} : Bool}
  %divmod_eq(bp, pp) : {Nat.is_lt(Nat.mul(Nat.div(bp, 1n+pp), 1n+pp), 1n+_) == True{} : Bool}
  is_lt_from_le_succ(
    Nat.mul(Nat.div(bp, 1n+pp), 1n+pp),
    Nat.add(Nat.mul(Nat.div(bp, 1n+pp), 1n+pp), Nat.mod(bp, 1n+pp)),
    NatL.is_le_add_right(Nat.mul(Nat.div(bp, 1n+pp), 1n+pp), Nat.mod(bp, 1n+pp))
  )

# --- 8. Parallel evaluator equivalence ---

def Laws.tx_batch_par_equiv_seq(st, cur, tgt, wid, w_lock, addr_ok, w_acc, ps, ev, rem_after, poll_interval, out):
  {==}
