import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# Constructive proofs for all Syrius WalletConnect crash-safety laws.

# ---------------------------------------------------------------------------
# Domain-specific helper lemmas
# ---------------------------------------------------------------------------

def not_xor_self(+b: Bool) -> {Bool.not(Bool.xor(b, b)) == True{} : Bool}:
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

def nat_gt_succ_self(+n: Nat) -> {Nat.is_gt(1n+n, n) == True{} : Bool}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      nat_gt_succ_self(p)

def nat_gt_irrefl(+n: Nat) -> {Nat.is_gt(n, n) == False{} : Bool}:
  %Equal.sym(Bool, Nat.is_gt(n, n), Nat.is_lt(n, n), NatL.is_gt_as_lt(n, n)) : {_ == False{} : Bool}
  NatL.is_lt_irrefl(n)

def nat_gt_implies_eq_false(+a: Nat, +b: Nat, h: {Nat.is_gt(a, b) == True{} : Bool}) -> {Nat.is_eq(a, b) == False{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(h))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      {==}
    case 1n+ap 1n+bp:
      nat_gt_implies_eq_false(ap, bp, h)

def nat_le_implies_lt_succ(+a: Nat, +b: Nat, h: {Nat.is_le(a, b) == True{} : Bool}) -> {Nat.is_lt(a, 1n+b) == True{} : Bool}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_lt(1n+ap, 1n) == True{} : Bool}, NatL.false_is_not_true(h))
    case 1n+ap 1n+bp:
      nat_le_implies_lt_succ(ap, bp, h)

def take_n_len_le(+cap: Nat, +xs: List<&2, Nat>) -> {Nat.is_le(List.length(&2, Nat, M.take_n(cap, xs)), cap) == True{} : Bool}:
  match cap xs:
    case 0n _:
      {==}
    case 1n+cp Nil{}:
      {==}
    case 1n+cp Con{_, +t}:
      take_n_len_le(cp, t)

def bool_and_left_false(+a: Bool, +b: Bool, h: {a == False{} : Bool}) -> {Bool.and(a, b) == False{} : Bool}:
  %Equal.sym(Bool, a, False{}, h) : {Bool.and(_, b) == False{} : Bool}
  {==}

def bool_and_right_false(+a: Bool, +b: Bool, h: {b == False{} : Bool}) -> {Bool.and(a, b) == False{} : Bool}:
  %Equal.sym(Bool, b, False{}, h) : {Bool.and(a, _) == False{} : Bool}
  NatL.and_false_right(a)

def bool_or_left_true(+a: Bool, +b: Bool, h: {a == True{} : Bool}) -> {Bool.or(a, b) == True{} : Bool}:
  %Equal.sym(Bool, a, True{}, h) : {Bool.or(_, b) == True{} : Bool}
  {==}

def bool_not_true_is_false(+a: Bool, h: {Bool.not(a) == True{} : Bool}) -> {a == False{} : Bool}:
  match a:
    case False{}:
      {==}
    case True{}:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(h))

def relay_unconfirmed_stale_unchanged(+rpc_conf: Bool, +conc: Bool, +unconf: Bool) -> {M.relay_finish_unsub.unconfirmed(rpc_conf, True{}, True{}, conc, unconf) == unconf : Bool}:
  match rpc_conf:
    case True{}:
      {==}
    case False{}:
      {==}

def relay_unconfirmed_concurrent_false(
  +replaced_by_new_sub: Bool,
  +is_fenced: Bool,
  +conf_conc: Bool,
  h: {conf_conc == True{} : Bool}
) -> {M.relay_finish_unsub.unconfirmed(False{}, replaced_by_new_sub, is_fenced, conf_conc, False{}) == False{} : Bool}:
  match is_fenced:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, conf_conc, True{}, h) : {M.relay_finish_unsub.unconfirmed(False{}, replaced_by_new_sub, False{}, _, False{}) == False{} : Bool}
      {==}

def relay_restore_protected_cases(
  +lsub: Nat,
  +pr: Nat,
  +tm: Nat,
  +persisted_id: Nat,
  +st: M.RelayTopicState,
  h: {Bool.or(Nat.is_gt(lsub, 0n), Bool.or(Nat.is_gt(pr, 0n), Nat.is_gt(tm, 0n))) == True{} : Bool}
) -> {M.relay_restore.apply(
    Bool.and(Nat.is_gt(persisted_id, 0n), Bool.and(Nat.is_eq(lsub, 0n), Bool.and(Nat.is_eq(pr, 0n), Nat.is_eq(tm, 0n)))),
    st,
    persisted_id
  ) == st : M.RelayTopicState}:
  match lsub pr tm:
    case 1n+lp _ _:
      e_and = bool_and_right_false(Nat.is_gt(persisted_id, 0n), False{}, {==})
      %Equal.sym(Bool, Bool.and(Nat.is_gt(persisted_id, 0n), False{}), False{}, e_and) : {M.relay_restore.apply(_, st, persisted_id) == st : M.RelayTopicState}
      {==}
    case 0n 1n+pp _:
      e_and = bool_and_right_false(Nat.is_gt(persisted_id, 0n), False{}, {==})
      %Equal.sym(Bool, Bool.and(Nat.is_gt(persisted_id, 0n), False{}), False{}, e_and) : {M.relay_restore.apply(_, st, persisted_id) == st : M.RelayTopicState}
      {==}
    case 0n 0n 1n+tp:
      e_and = bool_and_right_false(Nat.is_gt(persisted_id, 0n), False{}, {==})
      %Equal.sym(Bool, Bool.and(Nat.is_gt(persisted_id, 0n), False{}), False{}, e_and) : {M.relay_restore.apply(_, st, persisted_id) == st : M.RelayTopicState}
      {==}
    case 0n 0n 0n:
      Empty.absurd(
        {M.relay_restore.apply(Bool.and(Nat.is_gt(persisted_id, 0n), True{}), st, persisted_id) == st : M.RelayTopicState},
        NatL.false_is_not_true(h)
      )

# ---------------------------------------------------------------------------
# Proofs of Laws (31 laws)
# ---------------------------------------------------------------------------

def Laws.authoritative_fallback_is_sticky_forever(op, os_ok, fb_ok):
  {==}

def Laws.authoritative_and_legacy_markers_boot_authoritative(os_read_ok, os_write_ok, fb_ok, kc_entries):
  {==}

def Laws.transient_restart_empty_keychain_preserves_transient_keys(os_rw, fb_ok):
  {==}

def Laws.fallback_flag_never_deleted_or_lazy_read(mode, use_fb, has_manifest, owned):
  match mode use_fb has_manifest:
    case M.ModeSecure{} False{} False{}: {==}
    case M.ModeSecure{} False{} True{}: {==}
    case M.ModeSecure{} True{} False{}: {==}
    case M.ModeSecure{} True{} True{}: {==}
    case M.ModeTransientFallback{} False{} False{}: {==}
    case M.ModeTransientFallback{} False{} True{}: {==}
    case M.ModeTransientFallback{} True{} False{}: {==}
    case M.ModeTransientFallback{} True{} True{}: {==}
    case M.ModeAuthoritativeFallback{} False{} False{}: {==}
    case M.ModeAuthoritativeFallback{} False{} True{}: {==}
    case M.ModeAuthoritativeFallback{} True{} False{}: {==}
    case M.ModeAuthoritativeFallback{} True{} True{}: {==}

def Laws.foreign_keys_isolated_from_delete_and_manifest_read(mode, use_fb, has_manifest, owned, fid):
  match mode use_fb has_manifest:
    case M.ModeSecure{} False{} False{}: {==}
    case M.ModeSecure{} False{} True{}: {==}
    case M.ModeSecure{} True{} False{}: {==}
    case M.ModeSecure{} True{} True{}: {==}
    case M.ModeTransientFallback{} False{} False{}: {==}
    case M.ModeTransientFallback{} False{} True{}: {==}
    case M.ModeTransientFallback{} True{} False{}: {==}
    case M.ModeTransientFallback{} True{} True{}: {==}
    case M.ModeAuthoritativeFallback{} False{} False{}: {==}
    case M.ModeAuthoritativeFallback{} False{} True{}: {==}
    case M.ModeAuthoritativeFallback{} True{} False{}: {==}
    case M.ModeAuthoritativeFallback{} True{} True{}: {==}

def Laws.delete_all_preserves_flag_and_foreign_entries(flag_present, owned_count, foreign_count):
  e_fc = NatL.is_eq_same(foreign_count)
  e_fp = not_xor_self(flag_present)
  %Equal.sym(Bool, Nat.is_eq(foreign_count, foreign_count), True{}, e_fc) : {Bool.and(_, Bool.not(Bool.xor(flag_present, flag_present))) == True{} : Bool}
  e_fp

def Laws.reconcile_cleared_all_wipes_os(in_del, in_rep, os_entry):
  {==}

def Laws.reconcile_deleted_tombstone_deletes_os(in_rep, os_entry):
  {==}

def Laws.reconcile_replaced_key_transient_wins(cleared_all, in_del, os_entry, tv):
  match cleared_all in_del os_entry:
    case True{} _ _:
      {==}
    case False{} True{} _:
      {==}
    case False{} False{} None{}:
      {==}
    case False{} False{} Some{_}:
      {==}

def Laws.reconcile_absent_os_transient_wins(cleared_all, in_del, in_rep, tv):
  match cleared_all in_del:
    case True{} _:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

def Laws.reconcile_existing_os_merges_only_missing_subkeys(oa, ta, tb):
  {==}

def Laws.migration_writes_entries_before_authoritative_marker(marker_ok):
  {==}

def Laws.migration_marker_failure_preserves_secure_mode(entries_ok):
  match entries_ok:
    case False{}:
      {==}
    case True{}:
      {==}

def Laws.reconciliation_deletes_marker_before_transient_copies(marker_ok, copies_ok, del_copies):
  match marker_ok:
    case True{}:
      {==}
    case False{}:
      del_copies

def Laws.relay_op_seq_strictly_monotonic(s):
  nat_gt_succ_self(s)

def Laws.relay_failed_unsub_preserves_id_and_marks_unconfirmed(op_s, lsub, lunsub, cseq, tm, sub_id, unconf, call_seq, not_stale):
  e_sub = NatL.is_eq_same(sub_id)
  e_cseq = nat_gt_irrefl(cseq)
  %Equal.sym(Bool, Nat.is_gt(lsub, call_seq), False{}, not_stale) : {Bool.and(Nat.is_eq(sub_id, sub_id), M.relay_finish_unsub.unconfirmed(False{}, _, Bool.or(_, False{}), Bool.or(Nat.is_gt(cseq, cseq), Bool.and(Nat.is_gt(sub_id, 0n), Bool.not(Nat.is_eq(sub_id, sub_id)))), unconf)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_gt(cseq, cseq), False{}, e_cseq) : {Bool.and(Nat.is_eq(sub_id, sub_id), M.relay_finish_unsub.unconfirmed(False{}, False{}, False{}, Bool.or(_, Bool.and(Nat.is_gt(sub_id, 0n), Bool.not(Nat.is_eq(sub_id, sub_id)))), unconf)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(sub_id, sub_id), True{}, e_sub) : {Bool.and(_, M.relay_finish_unsub.unconfirmed(False{}, False{}, False{}, Bool.and(Nat.is_gt(sub_id, 0n), Bool.not(_)), unconf)) == True{} : Bool}
  %Equal.sym(Bool, Bool.and(Nat.is_gt(sub_id, 0n), False{}), False{}, NatL.and_false_right(Nat.is_gt(sub_id, 0n))) : {M.relay_finish_unsub.unconfirmed(False{}, False{}, False{}, _, unconf) == True{} : Bool}
  {==}

def Laws.relay_stale_unsub_fence_preserves_topic_map_and_status(op_s, lsub, lunsub, cseq, tm, pr, unconf, call_seq, conf_start, sub_id, mapped_rep, rpc_conf, stale):
  e_tm = NatL.is_eq_same(tm)
  e_un = not_xor_self(unconf)
  conc = Bool.or(Nat.is_gt(cseq, conf_start), Bool.and(Nat.is_gt(sub_id, 0n), Bool.not(Nat.is_eq(pr, sub_id))))
  e_u = relay_unconfirmed_stale_unchanged(rpc_conf, conc, unconf)
  %Equal.sym(Bool, Nat.is_gt(lsub, call_seq), True{}, stale) : {Bool.and(Nat.is_eq(M.relay_finish_unsub.topic_map(Bool.or(_, mapped_rep), tm), tm), Bool.not(Bool.xor(M.relay_finish_unsub.unconfirmed(rpc_conf, _, Bool.or(_, mapped_rep), conc, unconf), unconf))) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(tm, tm), True{}, e_tm) : {Bool.and(_, Bool.not(Bool.xor(M.relay_finish_unsub.unconfirmed(rpc_conf, True{}, True{}, conc, unconf), unconf))) == True{} : Bool}
  %Equal.sym(Bool, M.relay_finish_unsub.unconfirmed(rpc_conf, True{}, True{}, conc, unconf), unconf, e_u) : {Bool.not(Bool.xor(_, unconf)) == True{} : Bool}
  e_un

def Laws.relay_concurrent_unsub_fence_blocks_remarking(op_s, lsub, lunsub, cseq, tm, pr, call_seq, conf_start, sub_id, mapped_rep, concurrent_confirmed):
  h_conc = bool_or_left_true(
    Nat.is_gt(cseq, conf_start),
    Bool.and(Nat.is_gt(sub_id, 0n), Bool.not(Nat.is_eq(pr, sub_id))),
    concurrent_confirmed
  )
  relay_unconfirmed_concurrent_false(
    Nat.is_gt(lsub, call_seq),
    Bool.or(Nat.is_gt(lsub, call_seq), mapped_rep),
    Bool.or(Nat.is_gt(cseq, conf_start), Bool.and(Nat.is_gt(sub_id, 0n), Bool.not(Nat.is_eq(pr, sub_id)))),
    h_conc
  )

def Laws.relay_restore_never_overwrites_active_or_fresher(op_s, lsub, lunsub, cseq, tm, pr, unconf, persisted_id, protected):
  relay_restore_protected_cases(lsub, pr, tm, persisted_id, M.RelayTopicState{op_s, lsub, lunsub, cseq, tm, pr, unconf}, protected)

def Laws.relay_capped_tracking_bounded_by_cap(cap, xs, topic):
  take_n_len_le(cap, topic <> M.remove_nat(xs, topic))

def Laws.reset_aborts_before_deletes_if_marker_fails():
  {==}

def Laws.reset_marker_clears_when_empty_and_same_epoch(ep):
  e = NatL.is_eq_same(ep)
  %Equal.sym(Bool, Nat.is_eq(ep, ep), True{}, e) : {Bool.and(_, True{}) == True{} : Bool}
  {==}

def Laws.reset_marker_retained_when_unfinished_or_epoch_advanced(rs, rp, cur_ep, cap_ep, pend_disc, advanced):
  e_neq = nat_gt_implies_eq_false(cur_ep, cap_ep, advanced)
  e_rp = bool_and_right_false(Nat.is_eq(rs, 0n), False{}, {==})
  e_ep_inner = bool_and_left_false(Nat.is_eq(cur_ep, cap_ep), Bool.not(pend_disc), e_neq)
  e_ep_mid = bool_and_right_false(Nat.is_eq(rp, 0n), Bool.and(Nat.is_eq(cur_ep, cap_ep), Bool.not(pend_disc)), e_ep_inner)
  e_ep = bool_and_right_false(Nat.is_eq(rs, 0n), Bool.and(Nat.is_eq(rp, 0n), Bool.and(Nat.is_eq(cur_ep, cap_ep), Bool.not(pend_disc))), e_ep_mid)
  e_pd_inner = NatL.and_false_right(Nat.is_eq(cur_ep, cur_ep))
  e_pd_mid = bool_and_right_false(Nat.is_eq(rp, 0n), Bool.and(Nat.is_eq(cur_ep, cur_ep), False{}), e_pd_inner)
  e_pd = bool_and_right_false(Nat.is_eq(rs, 0n), Bool.and(Nat.is_eq(rp, 0n), Bool.and(Nat.is_eq(cur_ep, cur_ep), False{})), e_pd_mid)
  %Equal.sym(Bool, M.should_clear_reset_marker(rs, 1n+rp, cur_ep, cap_ep, pend_disc), False{}, e_rp) : {Bool.and(Bool.not(_), Bool.and(Bool.not(M.should_clear_reset_marker(rs, rp, cur_ep, cap_ep, pend_disc)), Bool.not(M.should_clear_reset_marker(rs, rp, cur_ep, cur_ep, True{})))) == True{} : Bool}
  %Equal.sym(Bool, M.should_clear_reset_marker(rs, rp, cur_ep, cap_ep, pend_disc), False{}, e_ep) : {Bool.and(Bool.not(_), Bool.not(M.should_clear_reset_marker(rs, rp, cur_ep, cur_ep, True{}))) == True{} : Bool}
  %Equal.sym(Bool, M.should_clear_reset_marker(rs, rp, cur_ep, cur_ep, True{}), False{}, e_pd) : {Bool.not(_) == True{} : Bool}
  {==}

def Laws.reset_admission_barrier_blocks_pair_and_approve(is_init, is_disp, has_client):
  e1 = bool_and_right_false(is_init, Bool.and(Bool.not(is_disp), False{}), NatL.and_false_right(Bool.not(is_disp)))
  e2 = bool_and_right_false(Bool.not(is_disp), Bool.and(has_client, False{}), NatL.and_false_right(has_client))
  %Equal.sym(Bool, M.can_admit_pair(is_init, is_disp, True{}), False{}, e1) : {Bool.and(Bool.not(_), Bool.not(M.can_admit_approve_session(is_disp, has_client, True{}))) == True{} : Bool}
  %Equal.sym(Bool, M.can_admit_approve_session(is_disp, has_client, True{}), False{}, e2) : {Bool.not(_) == True{} : Bool}
  {==}

def Laws.finalize_approved_session_rejects_advanced_generation(is_disp, has_client, blocked, cur_gen, exp_gen, live_sess, advanced):
  e_neq = nat_gt_implies_eq_false(cur_gen, exp_gen, advanced)
  e_inner = bool_and_left_false(Nat.is_eq(cur_gen, exp_gen), live_sess, e_neq)
  e1 = bool_and_right_false(Bool.not(blocked), Bool.and(Nat.is_eq(cur_gen, exp_gen), live_sess), e_inner)
  e2 = bool_and_right_false(has_client, Bool.and(Bool.not(blocked), Bool.and(Nat.is_eq(cur_gen, exp_gen), live_sess)), e1)
  bool_and_right_false(Bool.not(is_disp), Bool.and(has_client, Bool.and(Bool.not(blocked), Bool.and(Nat.is_eq(cur_gen, exp_gen), live_sess))), e2)

def Laws.topic_unsub_epoch_not_obsolete_when_current_or_newer(queued_epoch, current_epoch, current_or_newer):
  e_not_lt = Equal.trans(
    Bool,
    Bool.not(Nat.is_lt(queued_epoch, current_epoch)),
    Nat.is_ge(queued_epoch, current_epoch),
    True{},
    NatL.not_lt_is_ge(queued_epoch, current_epoch),
    current_or_newer
  )
  bool_not_true_is_false(Nat.is_lt(queued_epoch, current_epoch), e_not_lt)

def Laws.topic_unsub_epoch_strictly_older_always_obsolete(queued_epoch, current_epoch, in_flight_pair, live_in_stores, older):
  bool_or_left_true(Nat.is_lt(queued_epoch, current_epoch), Bool.and(Bool.not(in_flight_pair), live_in_stores), older)

def Laws.active_subscription_fences_prior_deferred_unsub(queued_epoch, prev_epoch, in_flight_pair, live_in_stores, older_or_eq):
  e_lt = nat_le_implies_lt_succ(queued_epoch, prev_epoch, older_or_eq)
  bool_or_left_true(Nat.is_lt(queued_epoch, 1n+prev_epoch), Bool.and(Bool.not(in_flight_pair), live_in_stores), e_lt)

def Laws.provisional_purge_never_deletes_confirmed_pairing(pair_ok, stored, ep_ok, last_inflight, reset_act, gen_ok):
  NatL.and_false_right(Bool.not(pair_ok))

def orphan_protected_cases(
  +has_sess: Bool,
  +prot_prop: Bool,
  +gt_ep: Bool,
  +active_op: Bool,
  +pairing_act: Bool,
  +gt_exp: Bool,
  +expiry_sec: Nat,
  +now_sec: Nat,
  e_gt_exp: {Nat.is_gt(expiry_sec, now_sec) == gt_exp : Bool},
  h: {Bool.or(has_sess, Bool.or(prot_prop, Bool.or(gt_ep, Bool.or(active_op, Bool.and(pairing_act, gt_exp))))) == True{} : Bool}
) -> {Bool.and(Bool.not(has_sess), Bool.and(Bool.not(prot_prop), Bool.and(Bool.not(gt_ep), Bool.and(Bool.not(active_op), Bool.or(Bool.not(pairing_act), Nat.is_le(expiry_sec, now_sec)))))) == False{} : Bool}:
  match has_sess prot_prop gt_ep active_op pairing_act gt_exp:
    case True{} _ _ _ _ _:
      {==}
    case False{} True{} _ _ _ _:
      {==}
    case False{} False{} True{} _ _ _:
      {==}
    case False{} False{} False{} True{} _ _:
      {==}
    case False{} False{} False{} False{} True{} True{}:
      e_not_le = Equal.trans(
        Bool,
        Bool.not(Nat.is_le(expiry_sec, now_sec)),
        Nat.is_gt(expiry_sec, now_sec),
        True{},
        NatL.not_le_is_gt(expiry_sec, now_sec),
        e_gt_exp
      )
      bool_not_true_is_false(Nat.is_le(expiry_sec, now_sec), e_not_le)
    case False{} False{} False{} False{} True{} False{}:
      Empty.absurd({Nat.is_le(expiry_sec, now_sec) == False{} : Bool}, NatL.false_is_not_true(h))
    case False{} False{} False{} False{} False{} _:
      Empty.absurd({True{} == False{} : Bool}, NatL.false_is_not_true(h))

def Laws.orphan_cleanup_protects_live_pairings(has_sess, prot_prop, created_ep, start_ep, active_op, pairing_act, expiry_sec, now_sec, protected):
  orphan_protected_cases(
    has_sess,
    prot_prop,
    Nat.is_gt(created_ep, start_ep),
    active_op,
    pairing_act,
    Nat.is_gt(expiry_sec, now_sec),
    expiry_sec,
    now_sec,
    {==},
    protected
  )

def Laws.idempotent_delivery_never_reexecutes_completed_or_cached(rid, has_sess, reset_act):
  match has_sess reset_act:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def Laws.idempotent_delivery_cached_retries_only_delivery(rid):
  {==}

def Laws.idempotent_delivery_post_handler_never_reverts_to_fresh(rid, delivery_ok, perm_err):
  match delivery_ok perm_err:
    case True{} _:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

def flag_key_blocks_delete(
  +mode: M.StoreMode,
  +has_manifest: Bool,
  +owned: List<&2, Nat>
) -> {M.can_delete_key(mode, has_manifest, owned, M.KeyFallbackFlag{}) == False{} : Bool}:
  match mode has_manifest:
    case M.ModeSecure{} False{}: {==}
    case M.ModeSecure{} True{}: {==}
    case M.ModeTransientFallback{} False{}: {==}
    case M.ModeTransientFallback{} True{}: {==}
    case M.ModeAuthoritativeFallback{} False{}: {==}
    case M.ModeAuthoritativeFallback{} True{}: {==}

def Laws.parallel_crash_safety_gate_equiv_sequential(
  mode,
  has_manifest,
  owned,
  key,
  queued_epoch,
  current_epoch,
  is_init,
  is_disp,
  reset_act,
  req_status,
  has_sess
):
  {==}

def Laws.parallel_crash_safety_gate_accepts_safe_state(key_id, ep):
  e_irrefl = NatL.is_lt_irrefl(ep)
  %Equal.sym(Bool, Nat.is_lt(ep, ep), False{}, e_irrefl) : {Bool.and(Bool.not(_), True{}) == True{} : Bool}
  {==}

def safety_gate_cases(
  +is_flag: Bool,
  +obs: Bool,
  +reset_act: Bool,
  +mode: M.StoreMode,
  +has_manifest: Bool,
  +owned: List<&2, Nat>,
  +key: M.StoreKey,
  +is_init: Bool,
  +is_disp: Bool,
  +req_status: M.RequestDeliveryStatus,
  +has_sess: Bool,
  e_store_flag: {M.is_fallback_flag_key(key) == is_flag : Bool},
  h: {Bool.or(is_flag, Bool.or(obs, reset_act)) == True{} : Bool}
) -> {Bool.and(M.can_delete_key(mode, has_manifest, owned, key), Bool.and(Bool.not(obs), M.check_service_admission_branch(is_init, is_disp, reset_act, req_status, has_sess))) == False{} : Bool}:
  match is_flag obs reset_act:
    case True{} _ _:
      match key:
        case M.KeyFallbackFlag{}:
          e_del = flag_key_blocks_delete(mode, has_manifest, owned)
          bool_and_left_false(
            M.can_delete_key(mode, has_manifest, owned, M.KeyFallbackFlag{}),
            Bool.and(Bool.not(obs), M.check_service_admission_branch(is_init, is_disp, reset_act, req_status, has_sess)),
            e_del
          )
        case M.KeyOwned{+id}:
          Empty.absurd(
            {Bool.and(M.can_delete_key(mode, has_manifest, owned, M.KeyOwned{id}), Bool.and(Bool.not(obs), M.check_service_admission_branch(is_init, is_disp, reset_act, req_status, has_sess))) == False{} : Bool},
            NatL.false_is_not_true(e_store_flag)
          )
        case M.KeyForeign{+id}:
          Empty.absurd(
            {Bool.and(M.can_delete_key(mode, has_manifest, owned, M.KeyForeign{id}), Bool.and(Bool.not(obs), M.check_service_admission_branch(is_init, is_disp, reset_act, req_status, has_sess))) == False{} : Bool},
            NatL.false_is_not_true(e_store_flag)
          )
    case False{} True{} _:
      NatL.and_false_right(M.can_delete_key(mode, has_manifest, owned, key))
    case False{} False{} True{}:
      e_admit = bool_and_right_false(is_init, Bool.and(Bool.not(is_disp), False{}), NatL.and_false_right(Bool.not(is_disp)))
      e_svc = bool_and_left_false(
        M.can_admit_pair(is_init, is_disp, True{}),
        M.action_executes_handler(M.decide_request_action(req_status, has_sess, True{})),
        e_admit
      )
      bool_and_right_false(M.can_delete_key(mode, has_manifest, owned, key), M.check_service_admission_branch(is_init, is_disp, True{}, req_status, has_sess), e_svc)
    case False{} False{} False{}:
      Empty.absurd(
        {Bool.and(M.can_delete_key(mode, has_manifest, owned, key), M.check_service_admission_branch(is_init, is_disp, False{}, req_status, has_sess)) == False{} : Bool},
        NatL.false_is_not_true(h)
      )

def Laws.parallel_crash_safety_gate_blocks_flag_or_reset_or_stale_epoch(
  mode,
  has_manifest,
  owned,
  key,
  queued_epoch,
  current_epoch,
  is_init,
  is_disp,
  reset_act,
  req_status,
  has_sess,
  blocked
):
  safety_gate_cases(
    M.is_fallback_flag_key(key),
    M.is_pending_unsub_epoch_obsolete(queued_epoch, current_epoch),
    reset_act,
    mode,
    has_manifest,
    owned,
    key,
    is_init,
    is_disp,
    req_status,
    has_sess,
    {==},
    blocked
  )
