import Base
import ../common/nat.bend as NatL
import ./model.bend as M
import ./LAWS.bend as Laws

# =============================================================================
# Local helper lemmas
# =============================================================================

def is_lt_succ_self(+a: Nat) -> {Nat.is_lt(a, 1n+a) == True{} : Bool}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      is_lt_succ_self(p)

def is_gt_succ_self(+a: Nat) -> {Nat.is_gt(1n+a, a) == True{} : Bool}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      is_gt_succ_self(p)

def is_gt_add_succ(+a: Nat, +b: Nat) -> {Nat.is_gt(Nat.add(1n+a, b), a) == True{} : Bool}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      is_gt_add_succ(p, b)

def sub_add_right_zero(+a: Nat, +b: Nat) -> {Nat.sub(a, Nat.add(a, b)) == 0n : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      sub_add_right_zero(p, b)

def abs_diff_add_right(+l: Nat, +k: Nat) -> {M.abs_diff(Nat.add(l, k), l) == k : Nat}:
  %Equal.sym(Nat, Nat.sub(Nat.add(l, k), l), k, NatL.sub_cancel_add_left(l, k)) : {Nat.add(_, Nat.sub(l, Nat.add(l, k))) == k : Nat}
  %Equal.sym(Nat, Nat.sub(l, Nat.add(l, k)), 0n, sub_add_right_zero(l, k)) : {Nat.add(k, _) == k : Nat}
  NatL.add_zero(k)

def ge_false_implies_rev_ge(+a: Nat, +b: Nat, e: {Nat.is_ge(a, b) == False{} : Bool}) -> {Nat.is_ge(b, a) == True{} : Bool}:
  match a b:
    case 0n 0n:
      Empty.absurd({Nat.is_ge(0n, 0n) == True{} : Bool}, NatL.true_is_not_false(e))
    case 0n 1n+bp:
      {==}
    case 1n+ap 0n:
      Empty.absurd({Nat.is_ge(0n, 1n+ap) == True{} : Bool}, NatL.true_is_not_false(e))
    case 1n+ap 1n+bp:
      ge_false_implies_rev_ge(ap, bp, e)

def ge_from_lt_false(+a: Nat, +b: Nat, e: {Nat.is_lt(a, b) == True{} : Bool}) -> {Nat.is_ge(a, b) == False{} : Bool}:
  %NatL.not_lt_is_ge(a, b) : {_ == False{} : Bool}
  %Equal.sym(Bool, Nat.is_lt(a, b), True{}, e) : {Bool.not(_) == False{} : Bool}
  {==}

def sync_eq_sound(+a: M.SyncStateKind, +b: M.SyncStateKind, e: {M.sync_state_eq(a, b) == True{} : Bool}) -> {a == b : M.SyncStateKind}:
  match a b:
    case M.SyncUnknown{} M.SyncUnknown{}:
      {==}
    case M.Syncing{} M.Syncing{}:
      {==}
    case M.SyncDone{} M.SyncDone{}:
      {==}
    case M.NotEnoughPeers{} M.NotEnoughPeers{}:
      {==}
    case M.SyncUnknown{} M.Syncing{}:
      Empty.absurd({M.SyncUnknown{} == M.Syncing{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.SyncUnknown{} M.SyncDone{}:
      Empty.absurd({M.SyncUnknown{} == M.SyncDone{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.SyncUnknown{} M.NotEnoughPeers{}:
      Empty.absurd({M.SyncUnknown{} == M.NotEnoughPeers{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.Syncing{} M.SyncUnknown{}:
      Empty.absurd({M.Syncing{} == M.SyncUnknown{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.Syncing{} M.SyncDone{}:
      Empty.absurd({M.Syncing{} == M.SyncDone{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.Syncing{} M.NotEnoughPeers{}:
      Empty.absurd({M.Syncing{} == M.NotEnoughPeers{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.SyncDone{} M.SyncUnknown{}:
      Empty.absurd({M.SyncDone{} == M.SyncUnknown{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.SyncDone{} M.Syncing{}:
      Empty.absurd({M.SyncDone{} == M.Syncing{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.SyncDone{} M.NotEnoughPeers{}:
      Empty.absurd({M.SyncDone{} == M.NotEnoughPeers{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.NotEnoughPeers{} M.SyncUnknown{}:
      Empty.absurd({M.NotEnoughPeers{} == M.SyncUnknown{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.NotEnoughPeers{} M.Syncing{}:
      Empty.absurd({M.NotEnoughPeers{} == M.Syncing{} : M.SyncStateKind}, NatL.false_is_not_true(e))
    case M.NotEnoughPeers{} M.SyncDone{}:
      Empty.absurd({M.NotEnoughPeers{} == M.SyncDone{} : M.SyncStateKind}, NatL.false_is_not_true(e))

def pick_sync_eq(+eq_b: Bool, +last: M.SyncStateKind, +inc: M.SyncStateKind, e: {eq_b == M.sync_state_eq(last, inc) : Bool}) -> {M.pick_sync_state(Bool.not(eq_b), inc, last) == inc : M.SyncStateKind}:
  match eq_b:
    case False{}:
      {==}
    case True{}:
      sync_eq_sound(last, inc, Equal.sym(Bool, True{}, M.sync_state_eq(last, inc), e))

def nm_recover_selected_is_prev(+need_redial: Bool, +s: M.NodeMgmtState, +prev: Nat, +rb_ok: Bool, +rest_cid: Nat) -> {M.nm_selected(M.nm_recover_branch(need_redial, s, prev, rb_ok, rest_cid)) == prev : Nat}:
  match need_redial s rb_ok:
    case True{} M.NodeMgmtState{_, _, _, _, _, _, _, _, _, _} True{}:
      {==}
    case True{} M.NodeMgmtState{_, _, _, _, _, _, _, _, _, _} False{}:
      {==}
    case False{} M.NodeMgmtState{_, _, _, _, _, _, _, _, _, _} _:
      {==}

def nm_recover_saved_unchanged(+need_redial: Bool, +s: M.NodeMgmtState, +prev: Nat, +rb_ok: Bool, +rest_cid: Nat) -> {M.nm_saved(M.nm_recover_branch(need_redial, s, prev, rb_ok, rest_cid)) == M.nm_saved(s) : Nat}:
  match need_redial s rb_ok:
    case True{} M.NodeMgmtState{_, _, _, _, _, _, _, _, _, _} True{}:
      {==}
    case True{} M.NodeMgmtState{_, _, _, _, _, _, _, _, _, _} False{}:
      {==}
    case False{} M.NodeMgmtState{_, _, _, _, _, _, _, _, _, _} _:
      {==}

def sync_disjoint_helper(+vh: Bool, +diff: Nat) -> {Bool.and(Bool.and(vh, Nat.is_lt(diff, 3n)), Bool.and(vh, Nat.is_ge(diff, 3n))) == False{} : Bool}:
  match vh:
    case False{}:
      {==}
    case True{}:
      NatL.lt_ge_disjoint(diff, 3n)

# Notification repository list, eviction & sorting lemmas
# -------------------------------------------------------

def notif_snoc_len(+xs: List<&2, M.NotifEntry>, +e: M.NotifEntry) -> {M.notif_len(M.notif_snoc(xs, e)) == 1n+M.notif_len(xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %notif_snoc_len(t, e) : {1n+M.notif_len(M.notif_snoc(t, e)) == 1n+_ : Nat}
      {==}

def notif_evict_pick_le(+fits: Bool, +h: M.NotifEntry, +t: List<&2, M.NotifEntry>, +rec: List<&2, M.NotifEntry>, +cap: Nat, ef: {fits == Nat.is_le(1n+M.notif_len(t), cap) : Bool}, er: {Nat.is_le(M.notif_len(rec), cap) == True{} : Bool}) -> {Nat.is_le(M.notif_len(M.notif_evict_pick(fits, h, t, rec)), cap) == True{} : Bool}:
  match fits:
    case True{}:
      Equal.sym(Bool, True{}, Nat.is_le(1n+M.notif_len(t), cap), ef)
    case False{}:
      er

def notif_evict_to_le(+xs: List<&2, M.NotifEntry>, +cap: Nat) -> {Nat.is_le(M.notif_len(M.notif_evict_to(xs, cap)), cap) == True{} : Bool}:
  match xs:
    case Nil{}:
      NatL.is_le_zero(cap)
    case h <> t:
      notif_evict_pick_le(
        Nat.is_le(1n+M.notif_len(t), cap),
        h,
        t,
        M.notif_evict_to(t, cap),
        cap,
        {==},
        notif_evict_to_le(t, cap)
      )

def notif_rev_go_len(+xs: List<&2, M.NotifEntry>, +acc: List<&2, M.NotifEntry>) -> {M.notif_len(M.notif_rev_go(xs, acc)) == Nat.add(M.notif_len(xs), M.notif_len(acc)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %NatL.add_succ(M.notif_len(t), M.notif_len(acc)) : {M.notif_len(M.notif_rev_go(t, h <> acc)) == _ : Nat}
      notif_rev_go_len(t, h <> acc)

def notif_insert_pick_len(+pf: Bool, +e: M.NotifEntry, +h: M.NotifEntry, +t: List<&2, M.NotifEntry>, +rec: List<&2, M.NotifEntry>, er: {M.notif_len(rec) == 1n+M.notif_len(t) : Nat}) -> {M.notif_len(M.notif_insert_pick(pf, e, h, t, rec)) == 2n+M.notif_len(t) : Nat}:
  match pf:
    case True{}:
      {==}
    case False{}:
      %er : {1n+M.notif_len(rec) == 1n+_ : Nat}
      {==}

def notif_insert_desc_len(+xs: List<&2, M.NotifEntry>, +e: M.NotifEntry) -> {M.notif_len(M.notif_insert_desc(xs, e)) == 1n+M.notif_len(xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      notif_insert_pick_len(
        Nat.is_ge(M.notif_ts(e), M.notif_ts(h)),
        e,
        h,
        t,
        M.notif_insert_desc(t, e),
        notif_insert_desc_len(t, e)
      )

def notif_sort_desc_len(+xs: List<&2, M.NotifEntry>) -> {M.notif_len(M.notif_sort_desc(xs)) == M.notif_len(xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %Equal.sym(Nat, M.notif_len(M.notif_insert_desc(M.notif_sort_desc(t), h)), 1n+M.notif_len(M.notif_sort_desc(t)), notif_insert_desc_len(M.notif_sort_desc(t), h)) : {_ == 1n+M.notif_len(t) : Nat}
      %notif_sort_desc_len(t) : {1n+M.notif_len(M.notif_sort_desc(t)) == 1n+_ : Nat}
      {==}

def notif_take_len(+limit: Nat, +xs: List<&2, M.NotifEntry>) -> {M.notif_len(M.notif_take(limit, xs)) == Nat.min(M.notif_len(xs), limit) : Nat}:
  match limit xs:
    case 0n Nil{}:
      {==}
    case 0n Con{h, t}:
      {==}
    case 1n+lp Nil{}:
      {==}
    case 1n+lp Con{h, t}:
      %notif_take_len(lp, t) : {1n+M.notif_len(M.notif_take(lp, t)) == 1n+_ : Nat}
      {==}

def notif_ge_head_insert_pick(+pf: Bool, +bound: Nat, +e: M.NotifEntry, +h: M.NotifEntry, +t: List<&2, M.NotifEntry>, +rec: List<&2, M.NotifEntry>, be: {Nat.is_ge(bound, M.notif_ts(e)) == True{} : Bool}, bh: {Nat.is_ge(bound, M.notif_ts(h)) == True{} : Bool}) -> {M.notif_ge_head(bound, M.notif_insert_pick(pf, e, h, t, rec)) == True{} : Bool}:
  match pf:
    case True{}:
      be
    case False{}:
      bh

def notif_ge_head_insert(+xs: List<&2, M.NotifEntry>, +bound: Nat, +e: M.NotifEntry, be: {Nat.is_ge(bound, M.notif_ts(e)) == True{} : Bool}, bx: {M.notif_ge_head(bound, xs) == True{} : Bool}) -> {M.notif_ge_head(bound, M.notif_insert_desc(xs, e)) == True{} : Bool}:
  match xs:
    case Nil{}:
      be
    case h <> t:
      notif_ge_head_insert_pick(
        Nat.is_ge(M.notif_ts(e), M.notif_ts(h)),
        bound,
        e,
        h,
        t,
        M.notif_insert_desc(t, e),
        be,
        bx
      )

def bool_mp(+p: Bool, +q: Bool, hp: {p == True{} : Bool}, himp: {Bool.or(Bool.not(p), q) == True{} : Bool}) -> {q == True{} : Bool}:
  match p:
    case False{}:
      Empty.absurd({q == True{} : Bool}, NatL.false_is_not_true(hp))
    case True{}:
      himp

def notif_insert_step_bool(
  +pf: Bool,
  +ht_ge: Bool,
  +t_s: Bool,
  +e: M.NotifEntry,
  +h: M.NotifEntry,
  +t: List<&2, M.NotifEntry>,
  epf: {pf == Nat.is_ge(M.notif_ts(e), M.notif_ts(h)) : Bool},
  eht: {ht_ge == M.notif_ge_head(M.notif_ts(h), t) : Bool},
  ets: {t_s == M.notif_is_sorted_desc(t) : Bool},
  ih: {Bool.or(Bool.not(M.notif_is_sorted_desc(t)), M.notif_is_sorted_desc(M.notif_insert_desc(t, e))) == True{} : Bool}
) -> {Bool.or(Bool.not(Bool.and(ht_ge, t_s)), M.notif_is_sorted_desc(M.notif_insert_pick(pf, e, h, t, M.notif_insert_desc(t, e)))) == True{} : Bool}:
  match pf ht_ge t_s:
    case _ False{} _:
      {==}
    case _ True{} False{}:
      {==}
    case True{} True{} True{}:
      %Equal.sym(Bool, Nat.is_ge(M.notif_ts(e), M.notif_ts(h)), True{}, Equal.sym(Bool, True{}, Nat.is_ge(M.notif_ts(e), M.notif_ts(h)), epf)) : {Bool.and(_, Bool.and(M.notif_ge_head(M.notif_ts(h), t), M.notif_is_sorted_desc(t))) == True{} : Bool}
      %Equal.sym(Bool, M.notif_ge_head(M.notif_ts(h), t), True{}, Equal.sym(Bool, True{}, M.notif_ge_head(M.notif_ts(h), t), eht)) : {Bool.and(_, M.notif_is_sorted_desc(t)) == True{} : Bool}
      Equal.sym(Bool, True{}, M.notif_is_sorted_desc(t), ets)
    case False{} True{} True{}:
      %Equal.sym(Bool, M.notif_ge_head(M.notif_ts(h), M.notif_insert_desc(t, e)), True{}, notif_ge_head_insert(t, M.notif_ts(h), e, ge_false_implies_rev_ge(M.notif_ts(e), M.notif_ts(h), Equal.sym(Bool, False{}, Nat.is_ge(M.notif_ts(e), M.notif_ts(h)), epf)), Equal.sym(Bool, True{}, M.notif_ge_head(M.notif_ts(h), t), eht))) : {Bool.and(_, M.notif_is_sorted_desc(M.notif_insert_desc(t, e))) == True{} : Bool}
      bool_mp(
        M.notif_is_sorted_desc(t),
        M.notif_is_sorted_desc(M.notif_insert_desc(t, e)),
        Equal.sym(Bool, True{}, M.notif_is_sorted_desc(t), ets),
        ih
      )

def notif_insert_desc_sorted(+xs: List<&2, M.NotifEntry>, +e: M.NotifEntry) -> {Bool.or(Bool.not(M.notif_is_sorted_desc(xs)), M.notif_is_sorted_desc(M.notif_insert_desc(xs, e))) == True{} : Bool}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      notif_insert_step_bool(
        Nat.is_ge(M.notif_ts(e), M.notif_ts(h)),
        M.notif_ge_head(M.notif_ts(h), t),
        M.notif_is_sorted_desc(t),
        e,
        h,
        t,
        {==},
        {==},
        {==},
        notif_insert_desc_sorted(t, e)
      )

def notif_sort_desc_sorted(+xs: List<&2, M.NotifEntry>) -> {M.notif_is_sorted_desc(M.notif_sort_desc(xs)) == True{} : Bool}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      bool_mp(
        M.notif_is_sorted_desc(M.notif_sort_desc(t)),
        M.notif_is_sorted_desc(M.notif_insert_desc(M.notif_sort_desc(t), h)),
        notif_sort_desc_sorted(t),
        notif_insert_desc_sorted(M.notif_sort_desc(t), h)
      )

def notif_ge_head_take(+limit: Nat, +xs: List<&2, M.NotifEntry>, +bound: Nat, e: {M.notif_ge_head(bound, xs) == True{} : Bool}) -> {M.notif_ge_head(bound, M.notif_take(limit, xs)) == True{} : Bool}:
  match limit xs:
    case 0n _:
      {==}
    case 1n+_ Nil{}:
      {==}
    case 1n+_ Con{h, t}:
      e

def notif_take_step_bool(
  +ht_ge: Bool,
  +t_s: Bool,
  +lp: Nat,
  +h: M.NotifEntry,
  +t: List<&2, M.NotifEntry>,
  eht: {ht_ge == M.notif_ge_head(M.notif_ts(h), t) : Bool},
  ets: {t_s == M.notif_is_sorted_desc(t) : Bool},
  ih: {Bool.or(Bool.not(M.notif_is_sorted_desc(t)), M.notif_is_sorted_desc(M.notif_take(lp, t))) == True{} : Bool}
) -> {Bool.or(Bool.not(Bool.and(ht_ge, t_s)), Bool.and(M.notif_ge_head(M.notif_ts(h), M.notif_take(lp, t)), M.notif_is_sorted_desc(M.notif_take(lp, t)))) == True{} : Bool}:
  match ht_ge t_s:
    case False{} _:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      %Equal.sym(Bool, M.notif_ge_head(M.notif_ts(h), M.notif_take(lp, t)), True{}, notif_ge_head_take(lp, t, M.notif_ts(h), Equal.sym(Bool, True{}, M.notif_ge_head(M.notif_ts(h), t), eht))) : {Bool.and(_, M.notif_is_sorted_desc(M.notif_take(lp, t))) == True{} : Bool}
      bool_mp(
        M.notif_is_sorted_desc(t),
        M.notif_is_sorted_desc(M.notif_take(lp, t)),
        Equal.sym(Bool, True{}, M.notif_is_sorted_desc(t), ets),
        ih
      )

def notif_take_sorted(+limit: Nat, +xs: List<&2, M.NotifEntry>) -> {Bool.or(Bool.not(M.notif_is_sorted_desc(xs)), M.notif_is_sorted_desc(M.notif_take(limit, xs))) == True{} : Bool}:
  match limit xs:
    case 0n _:
      NatL.or_true_right(Bool.not(M.notif_is_sorted_desc(xs)))
    case 1n+_ Nil{}:
      {==}
    case 1n+lp Con{h, t}:
      notif_take_step_bool(
        M.notif_ge_head(M.notif_ts(h), t),
        M.notif_is_sorted_desc(t),
        lp,
        h,
        t,
        {==},
        {==},
        notif_take_sorted(lp, t)
      )

# =============================================================================
# Proofs of LAWS.bend
# =============================================================================

# --- 1. NodeManagementBloc transactional switch & chain-ID TOCTOU ---

def Laws.node_busy_drops_confirm(sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar, chk, conn_ok, live_cid, pre_ok, rb_ok, rest_cid, not_ok):
  {==}

def Laws.node_mismatch_pauses_without_saving(sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar, live_cid, pre_ok, rb_ok, rest_cid, not_ok, mismatch):
  %Equal.sym(Bool, Nat.is_eq(live_cid, ccid), False{}, mismatch) : {Bool.and(M.nm_has_pending_mismatch(M.nm_confirm_mismatch_gate(Bool.not(_), M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, sel, conf, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), Nat.is_eq(M.nm_saved(M.nm_confirm_mismatch_gate(Bool.not(_), M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar}, sel, conf, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), sav)) == True{} : Bool}
  NatL.is_eq_same(sav)

def Laws.node_proceed_toctou_drift_reprompts(sel, conf, sav, ccid, conn_cid, nc, ar, target, prev, prompted_cid, live_cid, pre_ok, rb_ok, rest_cid, not_ok, neq_client, neq_prompted):
  %Equal.sym(Bool, Nat.is_eq(live_cid, ccid), False{}, neq_client) : {Bool.and(M.nm_has_pending_mismatch(M.nm_proceed_toctou_gate(Bool.and(Bool.not(_), Bool.not(Nat.is_eq(live_cid, prompted_cid))), M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, False{}, Some{M.MismatchPrompt{target, prev, prompted_cid, ccid, False{}}}, nc, ar}, target, prev, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), Nat.is_eq(M.nm_saved(M.nm_proceed_toctou_gate(Bool.and(Bool.not(_), Bool.not(Nat.is_eq(live_cid, prompted_cid))), M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, False{}, Some{M.MismatchPrompt{target, prev, prompted_cid, ccid, False{}}}, nc, ar}, target, prev, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), sav)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(live_cid, prompted_cid), False{}, neq_prompted) : {Bool.and(M.nm_has_pending_mismatch(M.nm_proceed_toctou_gate(Bool.not(_), M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, False{}, Some{M.MismatchPrompt{target, prev, prompted_cid, ccid, False{}}}, nc, ar}, target, prev, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), Nat.is_eq(M.nm_saved(M.nm_proceed_toctou_gate(Bool.not(_), M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, False{}, Some{M.MismatchPrompt{target, prev, prompted_cid, ccid, False{}}}, nc, ar}, target, prev, ccid, live_cid, pre_ok, rb_ok, rest_cid, not_ok)), sav)) == True{} : Bool}
  NatL.is_eq_same(sav)

def Laws.node_cancel_reconnect_ok_restores_prev(sel, conf, sav, ccid, conn_cid, disc, nc, ar, target, prev, ncid, pcid, rf, rest_cid):
  {==}

def Laws.node_cancel_reconnect_fail_marks_disconnected_retry(sel, conf, sav, ccid, conn_cid, disc, nc, ar, target, prev, ncid, pcid, rf, rest_cid):
  {==}

def Laws.node_precommit_error_rolls_back(sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar, live_cid, rb_ok, rest_cid, not_ok):
  +st = {M.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar} : M.NodeMgmtState}
  +nr = Bool.not(Nat.is_eq(sel, conf))
  %Equal.sym(Nat, M.nm_selected(M.nm_recover_branch(nr, st, conf, rb_ok, rest_cid)), conf, nm_recover_selected_is_prev(nr, st, conf, rb_ok, rest_cid)) : {Bool.and(Nat.is_eq(_, conf), Nat.is_eq(M.nm_saved(M.nm_recover_branch(nr, st, conf, rb_ok, rest_cid)), sav)) == True{} : Bool}
  %Equal.sym(Bool, Nat.is_eq(conf, conf), True{}, NatL.is_eq_same(conf)) : {Bool.and(_, Nat.is_eq(M.nm_saved(M.nm_recover_branch(nr, st, conf, rb_ok, rest_cid)), sav)) == True{} : Bool}
  %Equal.sym(Nat, M.nm_saved(M.nm_recover_branch(nr, st, conf, rb_ok, rest_cid)), sav, nm_recover_saved_unchanged(nr, st, conf, rb_ok, rest_cid)) : {Nat.is_eq(_, sav) == True{} : Bool}
  NatL.is_eq_same(sav)

def Laws.node_postcommit_notify_error_never_rolls_back(sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar, live_cid, rb_ok, rest_cid):
  {==}

# --- 2. Custom node CRUD & auto-receive rollback ---

def Laws.node_custom_protects_default_and_community(is_def, is_comm):
  match is_def:
    case False{}:
      {==}
    case True{}:
      {==}

def Laws.node_add_rejects_duplicate(nodes, node, dup):
  %Equal.sym(Bool, M.nat_list_contains(nodes, node), True{}, dup) : {M.add_custom_node_gate(_, nodes, node) == nodes : List<&2, Nat>}
  {==}

def Laws.node_edit_rejects_empty(node, existing):
  {==}

def Laws.node_edit_rejects_over_80(extra, node, existing):
  %Equal.sym(Bool, Nat.is_gt(Nat.add(81n, extra), 80n), True{}, is_gt_add_succ(80n, extra)) : {M.edit_check_len(_, node, existing) == M.EditErrTooLong{} : M.EditNodeValidation}
  {==}

def Laws.node_edit_rejects_default(is_comm, len, node, existing):
  {==}

def Laws.node_edit_rejects_community(is_def, len, node, existing):
  match is_def:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.node_edit_rejects_duplicate(lenp, node, existing, fit, dup):
  %Equal.sym(Bool, Nat.is_gt(1n+lenp, 80n), False{}, fit) : {M.edit_check_len(_, node, existing) == M.EditErrDuplicate{} : M.EditNodeValidation}
  %Equal.sym(Bool, M.nat_list_contains(existing, node), True{}, dup) : {M.edit_check_dup(_) == M.EditErrDuplicate{} : M.EditNodeValidation}
  {==}

def Laws.node_rename_updates_selected(old_n, new_n):
  %Equal.sym(Bool, Nat.is_eq(old_n, old_n), True{}, NatL.is_eq_same(old_n)) : {M.pick_nat(_, new_n, old_n) == new_n : Nat}
  {==}

def Laws.node_rename_preserves_other_selected(sel, old_n, new_n, neq):
  %Equal.sym(Bool, Nat.is_eq(sel, old_n), False{}, neq) : {M.pick_nat(_, new_n, sel) == sel : Nat}
  {==}

def Laws.node_delete_falls_back_to_confirmed(del_n, conf):
  %Equal.sym(Bool, Nat.is_eq(del_n, del_n), True{}, NatL.is_eq_same(del_n)) : {M.pick_nat(_, conf, del_n) == conf : Nat}
  {==}

def Laws.node_delete_preserves_other_selected(sel, conf, del_n, neq):
  %Equal.sym(Bool, Nat.is_eq(sel, del_n), False{}, neq) : {M.pick_nat(_, conf, sel) == sel : Nat}
  {==}

def Laws.node_auto_receive_rollback_on_save_fail(cur, des):
  {==}

# --- 3. SyncInfoExtension, NodeSyncStatusCubit hysteresis & clock skew ---

def Laws.sync_hysteresis_retains_on_jitter(last, inc, cur, tgt, not_done, jitter):
  %Equal.sym(Bool, M.sync_is_done(inc), False{}, not_done) : {M.pick_sync_state(Bool.and(Bool.not(M.sync_state_eq(last, inc)), Bool.or(_, M.sync_info_is_clearly_behind(cur, tgt))), inc, last) == last : M.SyncStateKind}
  %Equal.sym(Bool, Nat.is_ge(Nat.sub(tgt, cur), 3n), False{}, ge_from_lt_false(Nat.sub(tgt, cur), 3n, jitter)) : {M.pick_sync_state(Bool.and(Bool.not(M.sync_state_eq(last, inc)), Bool.and(M.sync_has_valid_heights(cur, tgt), _)), inc, last) == last : M.SyncStateKind}
  %Equal.sym(Bool, Bool.and(M.sync_has_valid_heights(cur, tgt), False{}), False{}, NatL.and_false_right(M.sync_has_valid_heights(cur, tgt))) : {M.pick_sync_state(Bool.and(Bool.not(M.sync_state_eq(last, inc)), _), inc, last) == last : M.SyncStateKind}
  %Equal.sym(Bool, Bool.and(Bool.not(M.sync_state_eq(last, inc)), False{}), False{}, NatL.and_false_right(Bool.not(M.sync_state_eq(last, inc)))) : {M.pick_sync_state(_, inc, last) == last : M.SyncStateKind}
  {==}

def Laws.sync_hysteresis_transitions_on_sync_done(last, cur, tgt):
  %Equal.sym(Bool, Bool.and(Bool.not(M.sync_state_eq(last, M.SyncDone{})), True{}), Bool.not(M.sync_state_eq(last, M.SyncDone{})), NatL.and_true_right(Bool.not(M.sync_state_eq(last, M.SyncDone{})))) : {M.pick_sync_state(_, M.SyncDone{}, last) == M.SyncDone{} : M.SyncStateKind}
  pick_sync_eq(M.sync_state_eq(last, M.SyncDone{}), last, M.SyncDone{}, {==})

def Laws.sync_hysteresis_transitions_on_clearly_behind(last, inc, cur, tgt, behind):
  %Equal.sym(Bool, M.sync_info_is_clearly_behind(cur, tgt), True{}, behind) : {M.pick_sync_state(Bool.and(Bool.not(M.sync_state_eq(last, inc)), Bool.or(M.sync_is_done(inc), _)), inc, last) == inc : M.SyncStateKind}
  %Equal.sym(Bool, Bool.or(M.sync_is_done(inc), True{}), True{}, NatL.or_true_right(M.sync_is_done(inc))) : {M.pick_sync_state(Bool.and(Bool.not(M.sync_state_eq(last, inc)), _), inc, last) == inc : M.SyncStateKind}
  %Equal.sym(Bool, Bool.and(Bool.not(M.sync_state_eq(last, inc)), True{}), Bool.not(M.sync_state_eq(last, inc)), NatL.and_true_right(Bool.not(M.sync_state_eq(last, inc)))) : {M.pick_sync_state(_, inc, last) == inc : M.SyncStateKind}
  pick_sync_eq(M.sync_state_eq(last, inc), last, inc, {==})

def Laws.sync_non_done_synced_and_behind_disjoint(st, cur, tgt, not_done):
  %Equal.sym(Bool, M.sync_is_done(st), False{}, not_done) : {Bool.and(Bool.or(_, Bool.and(M.sync_has_valid_heights(cur, tgt), Nat.is_lt(Nat.sub(tgt, cur), 3n))), Bool.and(M.sync_has_valid_heights(cur, tgt), Nat.is_ge(Nat.sub(tgt, cur), 3n))) == False{} : Bool}
  sync_disjoint_helper(M.sync_has_valid_heights(cur, tgt), Nat.sub(tgt, cur))

def Laws.clock_skew_silent_when_unsynced(st, cur, tgt, f, l, unsynced):
  %Equal.sym(Bool, M.node_is_synced_20(st, cur, tgt), False{}, unsynced) : {Bool.and(_, Nat.is_gt(M.abs_diff(f, l), M.clock_skew_threshold())) == False{} : Bool}
  {==}

def Laws.clock_skew_symmetric(st, cur, tgt, f, l):
  %NatL.add_comm(Nat.sub(l, f), Nat.sub(f, l)) : {Bool.and(M.node_is_synced_20(st, cur, tgt), Nat.is_gt(_, M.clock_skew_threshold())) == Bool.and(M.node_is_synced_20(st, cur, tgt), Nat.is_gt(Nat.add(Nat.sub(l, f), Nat.sub(f, l)), M.clock_skew_threshold())) : Bool}
  {==}

def Laws.clock_skew_boundary_300_silent(cur, tgt, l):
  %Equal.sym(Nat, M.abs_diff(Nat.add(l, M.clock_skew_threshold()), l), M.clock_skew_threshold(), abs_diff_add_right(l, M.clock_skew_threshold())) : {Nat.is_gt(_, M.clock_skew_threshold()) == False{} : Bool}
  %Equal.sym(Bool, Nat.is_gt(M.clock_skew_threshold(), M.clock_skew_threshold()), Nat.is_lt(M.clock_skew_threshold(), M.clock_skew_threshold()), NatL.is_gt_as_lt(M.clock_skew_threshold(), M.clock_skew_threshold())) : {_ == False{} : Bool}
  NatL.is_lt_irrefl(M.clock_skew_threshold())

def Laws.clock_skew_boundary_301_warns(cur, tgt, l):
  %Equal.sym(Nat, M.abs_diff(Nat.add(l, 1n+M.clock_skew_threshold()), l), 1n+M.clock_skew_threshold(), abs_diff_add_right(l, 1n+M.clock_skew_threshold())) : {Nat.is_gt(_, M.clock_skew_threshold()) == True{} : Bool}
  is_gt_succ_self(M.clock_skew_threshold())

# --- 4. AboutBloc 3-RPC partial-degradation lattice ---

def Laws.about_failure_iff_all_three_fail(r1, r2, r3):
  match r1 r2 r3:
    case M.RpcOk{_} _ _:
      {==}
    case M.RpcErr{_} M.RpcOk{_} _:
      {==}
    case M.RpcErr{_} M.RpcErr{_} M.RpcOk{_}:
      {==}
    case M.RpcErr{_} M.RpcErr{_} M.RpcErr{_}:
      {==}

def Laws.about_populated_carries_first_error(r1, r2, r3):
  match r1 r2 r3:
    case M.RpcOk{_} M.RpcOk{_} M.RpcOk{_}:
      {==}
    case M.RpcOk{_} M.RpcOk{_} M.RpcErr{_}:
      {==}
    case M.RpcOk{_} M.RpcErr{_} M.RpcOk{_}:
      {==}
    case M.RpcOk{_} M.RpcErr{_} M.RpcErr{_}:
      {==}
    case M.RpcErr{_} M.RpcOk{_} M.RpcOk{_}:
      {==}
    case M.RpcErr{_} M.RpcOk{_} M.RpcErr{_}:
      {==}
    case M.RpcErr{_} M.RpcErr{_} M.RpcOk{_}:
      {==}
    case M.RpcErr{_} M.RpcErr{_} M.RpcErr{_}:
      {==}

# --- 5. HiveNotificationsRepository bounded FIFO & newest-first sort ---

def Laws.notif_repo_zero_cap_clears(box, e):
  {==}

def Laws.notif_repo_add_preserves_cap(box, e, max_e):
  match max_e:
    case 0n:
      {==}
    case 1n+mp:
      %Equal.sym(Nat, M.notif_len(M.notif_snoc(M.notif_evict_to(box, mp), e)), 1n+M.notif_len(M.notif_evict_to(box, mp)), notif_snoc_len(M.notif_evict_to(box, mp), e)) : {Nat.is_le(_, 1n+mp) == True{} : Bool}
      notif_evict_to_le(box, mp)

def Laws.notif_repo_load_len_exact_min(box, limit):
  %Equal.sym(Nat, M.notif_len(M.notif_take(limit, M.notif_sort_desc(M.notif_rev_go(box, Nil{})))), Nat.min(M.notif_len(M.notif_sort_desc(M.notif_rev_go(box, Nil{}))), limit), notif_take_len(limit, M.notif_sort_desc(M.notif_rev_go(box, Nil{})))) : {_ == Nat.min(M.notif_len(box), limit) : Nat}
  %Equal.sym(Nat, M.notif_len(M.notif_sort_desc(M.notif_rev_go(box, Nil{}))), M.notif_len(M.notif_rev_go(box, Nil{})), notif_sort_desc_len(M.notif_rev_go(box, Nil{}))) : {Nat.min(_, limit) == Nat.min(M.notif_len(box), limit) : Nat}
  %Equal.sym(Nat, M.notif_len(M.notif_rev_go(box, Nil{})), Nat.add(M.notif_len(box), 0n), notif_rev_go_len(box, Nil{})) : {Nat.min(_, limit) == Nat.min(M.notif_len(box), limit) : Nat}
  %Equal.sym(Nat, Nat.add(M.notif_len(box), 0n), M.notif_len(box), NatL.add_zero(M.notif_len(box))) : {Nat.min(_, limit) == Nat.min(M.notif_len(box), limit) : Nat}
  {==}

def Laws.notif_repo_load_sorted_desc(box, limit):
  bool_mp(
    M.notif_is_sorted_desc(M.notif_sort_desc(M.notif_rev_go(box, Nil{}))),
    M.notif_is_sorted_desc(M.notif_take(limit, M.notif_sort_desc(M.notif_rev_go(box, Nil{})))),
    notif_sort_desc_sorted(M.notif_rev_go(box, Nil{})),
    notif_take_sorted(limit, M.notif_sort_desc(M.notif_rev_go(box, Nil{})))
  )

# --- 6. NotificationsBloc revision fencing & lock-screen guard ---

def Laws.notif_bloc_repo_fail_leaves_banner_unchanged(s, nid):
  match s:
    case M.NotifBannerState{a, r}:
      {==}

def Laws.notif_bloc_add_strictly_bumps_revision(s, nid):
  match s:
    case M.NotifBannerState{a, r}:
      is_lt_succ_self(r)

def Laws.notif_bloc_dismiss_matching_clears(a, r):
  %Equal.sym(Bool, Nat.is_eq(r, r), True{}, NatL.is_eq_same(r)) : {M.banner_active(M.notif_dismiss_gate(_, M.NotifBannerState{a, r})) == None{} : Maybe<&2, Nat>}
  {==}

def Laws.notif_bloc_dismiss_stale_noop(a, r, stale_r, neq):
  %Equal.sym(Bool, Nat.is_eq(stale_r, r), False{}, neq) : {M.notif_dismiss_gate(_, M.NotifBannerState{a, r}) == M.NotifBannerState{a, r} : M.NotifBannerState}
  {==}

def Laws.notif_bloc_dismiss_none_always_clears(s):
  match s:
    case M.NotifBannerState{a, r}:
      {==}

def Laws.notif_lock_screen_hides_see_more(has_active, has_cb):
  NatL.and_false_right(has_active)

# --- 7. SettingsWalletOptionsBloc rollback & macOS permission gate ---

def Laws.wallet_opt_persist_fail_rolls_back(prev, des, is_mac, perm):
  match des is_mac perm:
    case False{} _ _:
      {==}
    case True{} False{} _:
      {==}
    case True{} True{} False{}:
      {==}
    case True{} True{} True{}:
      {==}

def Laws.wallet_opt_macos_requires_permission(prev, save_ok):
  {==}

# --- 8. Parallel evaluator equivalence ---

def Laws.node_sync_batch_par_equiv_seq(st, cur, tgt, f, l, r1, r2, r3, prev, des, mac, perm, ok):
  {==}
