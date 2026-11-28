import Base
import ./test/bend/amounts/model.bend as Amt
import ./test/bend/wallet_lifecycle/model.bend as WL
import ./test/bend/plasma_staking/model.bend as PS
import ./test/bend/pillars_sentinels/model.bend as Pil
import ./test/bend/tokens_zts/model.bend as Tok
import ./test/bend/tx_pipeline/model.bend as Tx
import ./test/bend/node_sync/model.bend as NS
import ./test/bend/p2p_htlc/model.bend as Htlc
import ./test/bend/accelerator/model.bend as Acc
import ./test/bend/wallet_connect/model.bend as WC
import ./test/bend/wc_crash_safety/model.bend as WcSafe

# =============================================================================
# Syrius Root System-Wide Cross-Cutting Formal Laws (17 laws across 11 domains)
# =============================================================================
#
# Verified by `bend PROOF.bend --check-only` and independently checked by the
# Lean 4 kernel via `./scripts/bend PROOF.bend --verdict`.
# Root `PROOF.bend` also transitively imports and verifies all 11 domain
# `PROOF.bend` modules and `test/bend/common/nat.bend` in a single gate.

# Cross-domain inspection helpers (pure, total, zero @unsafe)
# -----------------------------------------------------------

def root_bool_eq(+a: Bool, +b: Bool) -> Bool:
  match a b:
    case False{} False{}:
      True{}
    case True{} True{}:
      True{}
    case _ _:
      False{}

def root_precond_is_ok(+o: Tx.PrecondOutcome) -> Bool:
  match o:
    case Tx.PrecondOk{_, _}:
      True{}
    case _:
      False{}

def root_reval_is_code(+r: WC.RevalidationResult, +code: U32) -> Bool:
  match r:
    case WC.RevalOk{}:
      False{}
    case WC.RevalErr{+c}:
      U32.is_eq(c, code)

def root_val_is_code(+r: WC.ValidationOutcome, +code: U32) -> Bool:
  match r:
    case WC.ValidOk{}:
      False{}
    case WC.ValidErr{+c}:
      U32.is_eq(c, code)

def root_color_eq(+a: Amt.PlasmaColor, +b: Amt.PlasmaColor) -> Bool:
  match a b:
    case Amt.ColorZts{} Amt.ColorZts{}:
      True{}
    case Amt.ColorOrange{} Amt.ColorOrange{}:
      True{}
    case Amt.ColorYellow{} Amt.ColorYellow{}:
      True{}
    case Amt.ColorZnn{} Amt.ColorZnn{}:
      True{}
    case _ _:
      False{}

def root_tooltip_eq(+a: Amt.PlasmaTooltip, +b: Amt.PlasmaTooltip) -> Bool:
  match a b:
    case Amt.TipInsufficient{} Amt.TipInsufficient{}:
      True{}
    case Amt.TipLow{} Amt.TipLow{}:
      True{}
    case Amt.TipAverage{} Amt.TipAverage{}:
      True{}
    case Amt.TipHigh{} Amt.TipHigh{}:
      True{}
    case _ _:
      False{}

def root_cmp_eq(+a: Cmp, +b: Cmp) -> Bool:
  match a b:
    case LT{} LT{}:
      True{}
    case EQ{} EQ{}:
      True{}
    case GT{} GT{}:
      True{}
    case _ _:
      False{}

def root_summary_eq(+a: Htlc.SanitizedSummary, +b: Htlc.SanitizedSummary) -> Bool:
  match a b:
    case Htlc.SummarySqlite{+w1, +c1} Htlc.SummarySqlite{+w2, +c2}:
      Bool.and(root_bool_eq(w1, w2), Nat.is_eq(c1, c2))
    case Htlc.SummaryRpc{+c1} Htlc.SummaryRpc{+c2}:
      Nat.is_eq(c1, c2)
    case Htlc.SummaryTypeOnly{} Htlc.SummaryTypeOnly{}:
      True{}
    case _ _:
      False{}

def root_pillar_opt_has_id(+m: Maybe<&2, Acc.PillarEntry>, +target_id: Nat) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{Acc.Pillar{+id, _, _}}:
      Nat.is_eq(id, target_id)

def root_il_status_eq(+a: Tx.ListStatus, +b: Tx.ListStatus) -> Bool:
  match a b:
    case Tx.ListInitial{} Tx.ListInitial{}:
      True{}
    case Tx.ListSuccess{} Tx.ListSuccess{}:
      True{}
    case Tx.ListFailure{} Tx.ListFailure{}:
      True{}
    case _ _:
      False{}

def root_il_state_preserved(+orig: Tx.InfiniteListModel, +after: Tx.InfiniteListModel) -> Bool:
  match orig after:
    case Tx.InfiniteListModel{+s1, +c1, +h1, +r1, _, +p1} Tx.InfiniteListModel{+s2, +c2, +h2, +r2, _, +p2}:
      Bool.and(
        root_il_status_eq(s1, s2),
        Bool.and(
          Nat.is_eq(c1, c2),
          Bool.and(
            root_bool_eq(h1, h2),
            Bool.and(Nat.is_eq(r1, r2), Nat.is_eq(p1, p2)))))

# Balanced 2-level binary parallel-let audit across all 11 domains
# ----------------------------------------------------------------

def eval_core_a(
  +plasma_u32: U32,
  +is_unlocked: Bool,
  +is_hw: Bool,
  +qsr: Nat,
  +qsr_bal: Nat
) -> Bool:
  Bool.and(
    Amt.amount_is_ok(Amt.correct_value(qsr, qsr_bal, 0n, 10n, True{}, False{}, False{}, True{}, 0n)),
    Bool.and(
      WL.can_backup_wallet(is_unlocked, is_hw),
      Bool.and(
        PS.can_fuse_plasma(qsr, qsr_bal, True{}, True{}),
        Nat.is_ge(Amt.plasma_tier_rank(Amt.plasma_tier(plasma_u32)), 1n))))

def eval_core_b(
  +znn_bal: Nat,
  +is_mintable: Bool,
  +is_burnable: Bool,
  +is_owner: Bool,
  +tx_st: Tx.SyncStateKind,
  +tx_cur: Nat,
  +tx_tgt: Nat
) -> Bool:
  Bool.and(
    Pil.can_delegate(znn_bal),
    Bool.and(
      Tok.caps_can_burn(Tok.token_caps(is_mintable, is_burnable, 10n, 100n, is_owner, is_owner)),
      Tx.node_is_synced_for_tx(tx_st, tx_cur, tx_tgt)))

def eval_feat_a(
  +ns_st: NS.SyncStateKind,
  +ns_cur: Nat,
  +ns_tgt: Nat,
  +htlc_exp: Nat,
  +htlc_now: Nat,
  +yes_v: Nat,
  +no_v: Nat
) -> Bool:
  Bool.and(
    NS.sync_info_is_synced(ns_st, ns_cur, ns_tgt),
    Bool.and(
      Htlc.can_safely_join_window(htlc_exp, htlc_now),
      Acc.has_majority(yes_v, no_v)))

def eval_feat_b(
  +verify_ctx: WC.VerifyContext,
  +wc_url: WC.ParsedUrl,
  +wc_init: Bool,
  +wc_disp: Bool,
  +wc_reset: Bool
) -> Bool:
  Bool.and(
    Bool.and(Bool.not(WC.is_verify_scam(verify_ctx)), WC.is_url_allowed(WC.sanitize_http_url(wc_url))),
    WcSafe.can_admit_pair(wc_init, wc_disp, wc_reset))

def eval_core_half(
  +plasma_u32: U32,
  +is_unlocked: Bool,
  +is_hw: Bool,
  +qsr: Nat,
  +qsr_bal: Nat,
  +znn_bal: Nat,
  +is_mintable: Bool,
  +is_burnable: Bool,
  +is_owner: Bool,
  +tx_st: Tx.SyncStateKind,
  +tx_cur: Nat,
  +tx_tgt: Nat
) -> Bool:
  ca cb = eval_core_a(plasma_u32, is_unlocked, is_hw, qsr, qsr_bal) eval_core_b(znn_bal, is_mintable, is_burnable, is_owner, tx_st, tx_cur, tx_tgt)
  Bool.and(ca, cb)

def eval_feature_half(
  +ns_st: NS.SyncStateKind,
  +ns_cur: Nat,
  +ns_tgt: Nat,
  +htlc_exp: Nat,
  +htlc_now: Nat,
  +yes_v: Nat,
  +no_v: Nat,
  +verify_ctx: WC.VerifyContext,
  +wc_url: WC.ParsedUrl,
  +wc_init: Bool,
  +wc_disp: Bool,
  +wc_reset: Bool
) -> Bool:
  fa fb = eval_feat_a(ns_st, ns_cur, ns_tgt, htlc_exp, htlc_now, yes_v, no_v) eval_feat_b(verify_ctx, wc_url, wc_init, wc_disp, wc_reset)
  Bool.and(fa, fb)

def root_audit_par(
  +plasma_u32: U32,
  +is_unlocked: Bool,
  +is_hw: Bool,
  +qsr: Nat,
  +qsr_bal: Nat,
  +znn_bal: Nat,
  +is_mintable: Bool,
  +is_burnable: Bool,
  +is_owner: Bool,
  +tx_st: Tx.SyncStateKind,
  +tx_cur: Nat,
  +tx_tgt: Nat,
  +ns_st: NS.SyncStateKind,
  +ns_cur: Nat,
  +ns_tgt: Nat,
  +htlc_exp: Nat,
  +htlc_now: Nat,
  +yes_v: Nat,
  +no_v: Nat,
  +verify_ctx: WC.VerifyContext,
  +wc_url: WC.ParsedUrl,
  +wc_init: Bool,
  +wc_disp: Bool,
  +wc_reset: Bool
) -> Bool:
  l r = eval_core_half(plasma_u32, is_unlocked, is_hw, qsr, qsr_bal, znn_bal, is_mintable, is_burnable, is_owner, tx_st, tx_cur, tx_tgt) eval_feature_half(ns_st, ns_cur, ns_tgt, htlc_exp, htlc_now, yes_v, no_v, verify_ctx, wc_url, wc_init, wc_disp, wc_reset)
  Bool.and(l, r)

def root_audit_seq(
  +plasma_u32: U32,
  +is_unlocked: Bool,
  +is_hw: Bool,
  +qsr: Nat,
  +qsr_bal: Nat,
  +znn_bal: Nat,
  +is_mintable: Bool,
  +is_burnable: Bool,
  +is_owner: Bool,
  +tx_st: Tx.SyncStateKind,
  +tx_cur: Nat,
  +tx_tgt: Nat,
  +ns_st: NS.SyncStateKind,
  +ns_cur: Nat,
  +ns_tgt: Nat,
  +htlc_exp: Nat,
  +htlc_now: Nat,
  +yes_v: Nat,
  +no_v: Nat,
  +verify_ctx: WC.VerifyContext,
  +wc_url: WC.ParsedUrl,
  +wc_init: Bool,
  +wc_disp: Bool,
  +wc_reset: Bool
) -> Bool:
  Bool.and(
    Bool.and(
      eval_core_a(plasma_u32, is_unlocked, is_hw, qsr, qsr_bal),
      eval_core_b(znn_bal, is_mintable, is_burnable, is_owner, tx_st, tx_cur, tx_tgt)),
    Bool.and(
      eval_feat_a(ns_st, ns_cur, ns_tgt, htlc_exp, htlc_now, yes_v, no_v),
      eval_feat_b(verify_ctx, wc_url, wc_init, wc_disp, wc_reset)))

# =============================================================================
# 17 Cross-Cutting System-Wide Laws
# =============================================================================

# 1. Cross-domain locked-wallet safety: a locked wallet simultaneously blocks
#    backup (wallet_lifecycle), rejects tx creation (tx_pipeline), rejects WC
#    post-confirmation revalidation with 9000 (wallet_connect), keeps hidden
#    widgets hidden without valid password (wallet_lifecycle), and hides the
#    notification "See more" action on the lock screen (node_sync).
law locked_wallet_blocks_sensitive_ops:
  for +is_hw: Bool
  for +st: Tx.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for +exp_addr: Maybe<&2, Nat>
  for +sel_addr: Maybe<&2, Nat>
  for +addr_ok: Bool
  for +wc_method: WC.WcInteractiveMethod
  for +sess_act: Bool
  for +has_rid: Bool
  for +pending: Bool
  for +svc_c: WC.ChainId
  for +sess_c: WC.ChainId
  for +act_c: WC.ChainId
  {Bool.and(
    Bool.not(WL.can_backup_wallet(False{}, is_hw)),
    Bool.and(
      Bool.not(root_precond_is_ok(Tx.check_create_preconditions(st, cur, tgt, exp_addr, sel_addr, addr_ok, None{}))),
      Bool.and(
        root_reval_is_code(
          WC.revalidate_interactive_request(
            wc_method,
            WC.RevalidationState{True{}, sess_act, has_rid, pending, svc_c, sess_c, act_c}),
          9000),
        Bool.and(
          WL.hide_widget_step(True{}, False{}, False{}),
          Bool.not(NS.notif_widget_can_see_more(True{}, has_rid, sess_act)))))) == True{} : Bool}

# 2. Cross-domain hardware-wallet safety: a hardware wallet simultaneously
#    blocks mnemonic backup (wallet_lifecycle), rejects missing-address HTLC
#    reclaim without deriving software addresses (p2p_htlc), and enforces
#    plasma-dependent hardware review timing (tx_pipeline).
law hardware_wallet_safety_boundaries:
  for +is_unlocked: Bool
  for +wlen: Nat
  for +dmatch: Maybe<&2, Nat>
  for +exp: Nat
  for +now: Nat
  for +need_plasma: Bool
  {Bool.and(
    Bool.not(WL.can_backup_wallet(is_unlocked, True{})),
    Bool.and(
      Bool.not(Htlc.reclaim_is_ok(Htlc.evaluate_reclaim(False{}, True{}, True{}, wlen, dmatch, exp, now))),
      Bool.and(
        Nat.is_eq(Htlc.reclaim_derived_count(Htlc.evaluate_reclaim(False{}, True{}, True{}, wlen, dmatch, exp, now)), 0n),
        root_bool_eq(Tx.review_is_deferred(Tx.hw_review_timing(True{}, need_plasma)), need_plasma)))) == True{} : Bool}

# 3. Cross-domain active incoming HTLC protection: active incoming HTLC
#    simultaneously suppresses auto-lock preserving lock state & sequence
#    (wallet_lifecycle), preempts auto-receive (tx_pipeline), and forbids
#    deleting active/pending/reclaimable swaps (p2p_htlc).
law active_incoming_htlc_protection:
  for +l: Bool
  for +h: Bool
  for +t: Bool
  for +seq: Nat
  for +pool: List<&2, Nat>
  for +ar_run: Bool
  for +nseq: Nat
  for +out: Tx.ReceiveOutcome
  {Bool.and(
    root_bool_eq(WL.lock_is_locked(WL.lock_step(WL.LockScreenState{l, h, t, seq}, WL.LockTimerFired{True{}})), l),
    Bool.and(
      root_bool_eq(WL.lock_has_handle(WL.lock_step(WL.LockScreenState{l, h, t, seq}, WL.LockTimerFired{True{}})), h),
      Bool.and(
        Nat.is_eq(WL.lock_sequence(WL.lock_step(WL.LockScreenState{l, h, t, seq}, WL.LockTimerFired{True{}})), seq),
        Bool.and(
          Bool.not(Tx.ar_res_continue(Tx.auto_receive_loop_step(Tx.AutoReceiveState{pool, ar_run, nseq}, True{}, True{}, out))),
          Bool.and(
            Bool.not(Htlc.can_delete_swap(Htlc.Active{})),
            Bool.and(
              Bool.not(Htlc.can_delete_swap(Htlc.Pending{})),
              Bool.not(Htlc.can_delete_swap(Htlc.Reclaimable{})))))))) == True{} : Bool}

# 4. Cross-domain active HTLC auto-receive pool preservation: HTLC preemption
#    returns the exact AutoReceiveState pool and notification sequence intact.
law active_incoming_htlc_preserves_autoreceive_pool:
  for +pool: List<&2, Nat>
  for +ar_run: Bool
  for +nseq: Nat
  for +out: Tx.ReceiveOutcome
  {Tx.auto_receive_loop_step(Tx.AutoReceiveState{pool, ar_run, nseq}, True{}, True{}, out) == Tx.AutoReceiveStepResult{Tx.AutoReceiveState{pool, ar_run, nseq}, False{}, False{}} : Tx.AutoReceiveStepResult}

# 5. Cross-domain reset barrier & crash durability: active/pending reset
#    simultaneously blocks WC pair, approve_session, finalize_approved_session,
#    and request execution; retains reset marker whenever sessions or pairings
#    remain (wc_crash_safety); and SplashBloc restricts retry strictly to
#    destructive clearing failures (wallet_lifecycle).
law reset_barrier_and_splash_retry_safety:
  for +is_init: Bool
  for +is_disp: Bool
  for +has_cli: Bool
  for +cur_gen: Nat
  for +exp_gen: Nat
  for +live_sess: Bool
  for +rem_sess: Nat
  for +rem_pair: Nat
  for +cur_ep: Nat
  for +cap_ep: Nat
  for +pend_disc: Bool
  for +req_st: WcSafe.RequestDeliveryStatus
  for +has_act_sess: Bool
  for +failed_clear: Bool
  {Bool.and(
    Bool.not(WcSafe.can_admit_pair(is_init, is_disp, True{})),
    Bool.and(
      Bool.not(WcSafe.can_admit_approve_session(is_disp, has_cli, True{})),
      Bool.and(
        Bool.not(WcSafe.can_finalize_approved_session(is_disp, has_cli, True{}, cur_gen, exp_gen, live_sess)),
        Bool.and(
          Bool.not(WcSafe.action_executes_handler(WcSafe.decide_request_action(req_st, has_act_sess, True{}))),
          Bool.and(
            Bool.not(WcSafe.should_clear_reset_marker(1n+rem_sess, rem_pair, cur_ep, cap_ep, pend_disc)),
            Bool.and(
              Bool.not(WcSafe.should_clear_reset_marker(rem_sess, 1n+rem_pair, cur_ep, cap_ep, pend_disc)),
              Bool.and(
                Bool.not(WL.splash_can_retry(WL.FlowNormal{}, failed_clear)),
                Bool.and(
                  Bool.not(WL.splash_can_retry(WL.FlowDev{}, failed_clear)),
                  Bool.and(
                    Bool.not(WL.splash_can_retry(WL.FlowResetWallet{}, False{})),
                    Bool.and(
                      WL.splash_can_retry(WL.FlowResetWallet{}, True{}),
                      WL.splash_can_retry(WL.FlowDeleteCache{}, True{}))))))))))) == True{} : Bool}

# 6. Cross-domain chain-ID consistency: a live vs active chain-ID mismatch
#    simultaneously pauses node switching without saving (node_sync), rejects
#    znn_send AccountBlock validation with 5003 (wallet_connect), and rejects
#    Drift processed-block writes (p2p_htlc).
law chain_id_mismatch_blocks_node_wc_and_htlc:
  for +sel: Nat
  for +conf: Nat
  for +sav: Nat
  for +ccid: Nat
  for +conn_cid: Nat
  for +disc: Bool
  for +pm: Maybe<&2, NS.MismatchPrompt>
  for +nc: Nat
  for +ar: Bool
  for +live_cid: Nat
  for +pre_ok: Bool
  for +rb_ok: Bool
  for +rest_cid: Nat
  for +not_ok: Bool
  for +bt: WC.BlockType
  for +fh: WC.HashKind
  for +sch: WC.ChainId
  for neq: {Nat.is_eq(live_cid, ccid) == False{} : Bool}
  {Bool.and(
    NS.nm_has_pending_mismatch(
      NS.nm_confirm_node(
        NS.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
        True{}, True{}, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
    Bool.and(
      Nat.is_eq(
        NS.nm_saved(
          NS.nm_confirm_node(
            NS.NodeMgmtState{False{}, sel, conf, sav, ccid, conn_cid, disc, pm, nc, ar},
            True{}, True{}, live_cid, pre_ok, rb_ok, rest_cid, not_ok)),
        sav),
      Bool.and(
        root_val_is_code(WC.validate_send_account_block(WC.SendAccountBlock{bt, fh, live_cid, sch}, ccid), 5003),
        Bool.not(Htlc.can_write_processed_block(ccid, Some{live_cid}))))) == True{} : Bool}

# 7. Cross-domain WC post-confirmation chain-ID mismatch: whenever active chain
#    drifts from session chain, both znn_sign and znn_send revalidation fail
#    with exact JSON-RPC error 5003.
law wc_revalidation_chain_mismatch_rejects_5003:
  for +has_rid: Bool
  for +svc_c: WC.ChainId
  for +sess_c: WC.ChainId
  for +act_c: WC.ChainId
  for neq: {WC.chain_id_eq(sess_c, act_c) == False{} : Bool}
  {Bool.and(
    root_reval_is_code(
      WC.revalidate_interactive_request(
        WC.InteractiveZnnSign{},
        WC.RevalidationState{False{}, True{}, has_rid, True{}, svc_c, sess_c, act_c}),
      5003),
    root_reval_is_code(
      WC.revalidate_interactive_request(
        WC.InteractiveZnnSend{},
        WC.RevalidationState{False{}, True{}, has_rid, True{}, svc_c, sess_c, act_c}),
      5003)) == True{} : Bool}

# 8. Cross-domain plasma tier & operation-threshold coherence across amounts,
#    plasma_staking, tokens_zts, and pillars_sentinels: exact U32 constant
#    identity, exact tier boundaries (Insufficient < 21000, Low at 21000,
#    Average at ZTS issue 189000, High at Pillar/Sentinel 252000), and universal
#    color <-> tooltip bijection.
law plasma_thresholds_and_tiers_coherence:
  for +p: U32
  {Bool.and(
    U32.is_eq(PS.plasma_for_qsr_u32(10), PS.op_plasma_u32(PS.OpMinPlasma{})),
    Bool.and(
      U32.is_eq(PS.op_plasma_u32(PS.OpIssueToken{}), Tok.issue_plasma_req_u32()),
      Bool.and(
        U32.is_eq(PS.op_plasma_u32(PS.OpPillar{}), Pil.role_plasma_req_u32(Pil.RolePillar{})),
        Bool.and(
          U32.is_eq(PS.op_plasma_u32(PS.OpSentinel{}), Pil.role_plasma_req_u32(Pil.RoleSentinel{})),
          Bool.and(
            Nat.is_eq(Amt.plasma_tier_rank(Amt.plasma_tier(20999)), 0n),
            Bool.and(
              Nat.is_eq(Amt.plasma_tier_rank(Amt.plasma_tier(PS.op_plasma_u32(PS.OpMinPlasma{}))), 1n),
              Bool.and(
                Nat.is_eq(Amt.plasma_tier_rank(Amt.plasma_tier(Tok.issue_plasma_req_u32())), 2n),
                Bool.and(
                  Nat.is_eq(Amt.plasma_tier_rank(Amt.plasma_tier(Pil.role_plasma_req_u32(Pil.RolePillar{}))), 3n),
                  Bool.and(
                    Nat.is_eq(Amt.plasma_tier_rank(Amt.plasma_tier(Pil.role_plasma_req_u32(Pil.RoleSentinel{}))), 3n),
                    Bool.and(
                      root_color_eq(Amt.tooltip_to_color(Amt.plasma_tooltip(p)), Amt.plasma_color(p)),
                      root_tooltip_eq(Amt.color_to_tooltip(Amt.plasma_color(p)), Amt.plasma_tooltip(p)))))))))))) == True{} : Bool}

# 9. Cross-domain plasma sufficiency hierarchy: plasma < 21k (Insufficient)
#    fails EVERY operation across plasma_staking, tokens_zts, and
#    pillars_sentinels; plasma >= 252k (High) satisfies EVERY operation.
law plasma_sufficiency_cross_domain_hierarchy:
  for +pk: Nat
  for +op: PS.PlasmaOp
  for +role: Pil.NodeRole
  for +extra: Nat
  {Bool.and(
    Bool.and(
      PS.meets_plasma(Nat.add(Pil.role_plasma_req_k(role), extra), PS.op_plasma_k(op)),
      PS.meets_plasma(Nat.add(Pil.role_plasma_req_k(role), extra), Tok.issue_plasma_req_k())),
    Bool.or(
      Nat.is_ge(pk, PS.op_plasma_k(PS.OpMinPlasma{})),
      Bool.and(
        Bool.not(PS.meets_plasma(pk, PS.op_plasma_k(op))),
        Bool.and(
          Bool.not(PS.meets_plasma(pk, Tok.issue_plasma_req_k())),
          Bool.not(PS.meets_plasma(pk, Pil.role_plasma_req_k(role))))))) == True{} : Bool}

# 10. Cross-domain value & zero-balance safety: zero balance simultaneously
#     rejects correct_value (can_eq_min=False), can_fuse_plasma, can_create_stake,
#     can_burn_amount, is_valid_donation (0/0 balances), and can_delegate; and
#     invalid parse NEVER passes correct_value even at max=0, can_eq_min=True.
law zero_balance_rejects_all_spend_ops:
  for +val: Nat
  for +dec: Nat
  for +min_val: Nat
  for +can_blank: Bool
  for +is_blank: Bool
  for +parse_ok: Bool
  for +frac: Nat
  for +is_int: Bool
  for +valid_ben: Bool
  for +months: Nat
  for +total: Nat
  for +is_burn: Bool
  for +is_own: Bool
  for +znn_d: Acc.SignedAmt
  for +qsr_d: Acc.SignedAmt
  {Bool.and(
    Bool.not(Amt.amount_is_ok(Amt.correct_value(val, 0n, dec, min_val, False{}, can_blank, is_blank, parse_ok, frac))),
    Bool.and(
      Bool.not(Amt.amount_is_ok(Amt.correct_value(val, 0n, dec, min_val, True{}, can_blank, False{}, False{}, frac))),
      Bool.and(
        Bool.not(PS.can_fuse_plasma(val, 0n, is_int, valid_ben)),
        Bool.and(
          Bool.not(PS.can_create_stake(val, 0n, months)),
          Bool.and(
            Bool.not(Tok.can_burn_amount(val, 0n, total, is_burn, is_own)),
            Bool.and(
              Bool.not(Acc.is_valid_donation(znn_d, qsr_d, 0n, 0n)),
              Bool.not(Pil.can_delegate(0n)))))))) == True{} : Bool}

# 11. Cross-domain UI-edge revision & staleness fencing: a stale revision
#     simultaneously fails to dismiss a newer notification banner (node_sync),
#     refuses to clear a newer WC URI input (wallet_connect), and discards
#     stale first-page results without mutating InfiniteListBloc (tx_pipeline).
law stale_revision_fences_ui_across_domains:
  for +nid: Nat
  for +stale_rev: Nat
  for +cur_rev: Nat
  for +field_ne: Bool
  for +il_st: Tx.ListStatus
  for +il_cnt: Nat
  for +il_hrm: Bool
  for +il_addr: Maybe<&2, Nat>
  for +il_ps: Nat
  for +fetched: Nat
  for +fetch_ok: Bool
  for neq: {Nat.is_eq(stale_rev, cur_rev) == False{} : Bool}
  {Bool.and(
    Maybe.is_some(&2, Nat, NS.banner_active(NS.notif_bloc_dismiss(NS.NotifBannerState{Some{nid}, cur_rev}, Some{stale_rev}))),
    Bool.and(
      Nat.is_eq(NS.banner_revision(NS.notif_bloc_dismiss(NS.NotifBannerState{Some{nid}, cur_rev}, Some{stale_rev})), cur_rev),
      Bool.and(
        Bool.not(WC.card_outcome_cleared(WC.uri_card_on_pair_success(WC.UriCardState{cur_rev, Some{stale_rev}, field_ne}))),
        root_il_state_preserved(
          Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps},
          Tx.il_apply_first_page(Tx.InfiniteListModel{il_st, il_cnt, il_hrm, cur_rev, il_addr, il_ps}, stale_rev, fetched, fetch_ok))))) == True{} : Bool}

# 12. Cross-domain security defense-in-depth: WC scam verification (flag or
#     ValScam) always blocks send preflight (wallet_connect),
#     AuthoritativeFallback stays sticky permanently across all ops
#     (wc_crash_safety), and SQLCipher rejects non-32-byte keys (p2p_htlc).
law security_defense_in_depth:
  for +val: WC.VerifyValidation
  for +url: WC.ParsedUrl
  for +blk: WC.SendAccountBlock
  for +acid: Nat
  for +aaddr: Nat
  for +raddr: WC.RequestedAddress
  for +oaddrs: List<&2, Nat>
  for +rst: WC.RevalidationState
  for +op: WcSafe.StoreOp
  for +os_ok: Bool
  for +fb_ok: Bool
  for +bytes_ok: Bool
  for +k: Nat
  {Bool.and(
    Bool.not(WC.parallel_send_preflight(WC.HasVerifyContext{True{}, val}, url, blk, acid, aaddr, raddr, oaddrs, rst)),
    Bool.and(
      Bool.not(WC.parallel_send_preflight(WC.HasVerifyContext{False{}, WC.ValScam{}}, url, blk, acid, aaddr, raddr, oaddrs, rst)),
      Bool.and(
        WcSafe.is_mode_authoritative(WcSafe.store_step_mode(WcSafe.ModeAuthoritativeFallback{}, op, os_ok, fb_ok)),
        Bool.and(
          Bool.not(Htlc.is_valid_sqlcipher_key(0n, bytes_ok)),
          Bool.not(Htlc.is_valid_sqlcipher_key(33n+k, bytes_ok)))))) == True{} : Bool}

# 13. Cross-domain secret & key isolation: error sanitizer output is invariant
#     under arbitrary secret/preimage substitution s1 vs s2 (p2p_htlc) while
#     fallback store deletion strictly forbids deleting the fallback flag (any
#     mode) or any foreign key (unconditionally in ModeSecure and whenever a
#     manifest is present in fallback modes) (wc_crash_safety).
law sanitizer_zero_preimage_leakage_and_key_isolation:
  for +err: Htlc.SwapError
  for +s1: Nat
  for +s2: Nat
  for +mode: WcSafe.StoreMode
  for +has_man: Bool
  for +owned: List<&2, Nat>
  for +fid: Nat
  {Bool.and(
    root_summary_eq(Htlc.sanitize_error(Htlc.replace_secrets(err, s1)), Htlc.sanitize_error(Htlc.replace_secrets(err, s2))),
    Bool.and(
      Bool.not(WcSafe.can_delete_key(mode, has_man, owned, WcSafe.KeyFallbackFlag{})),
      Bool.and(
        Bool.not(WcSafe.can_delete_key(mode, True{}, owned, WcSafe.KeyForeign{fid})),
        Bool.not(WcSafe.can_delete_key(WcSafe.ModeSecure{}, has_man, owned, WcSafe.KeyForeign{fid}))))) == True{} : Bool}

# 14. Cross-domain Pillar governance & role coherence: wallet addresses are
#     rejected as Pillar producers (pillars_sentinels), non-pillars never vote
#     (accelerator), owner resolution strictly beats an earlier producer entry
#     and votes ByName (accelerator), and quorum strictly exceeds 33% for any
#     positive pillar set (accelerator).
law pillar_governance_and_role_coherence:
  for +addr_valid: Bool
  for +nv: Bool
  for +na: Bool
  for +rv: Bool
  for +pv: Bool
  for +mp: Nat
  for +dp: Nat
  for +id1: Nat
  for +id2: Nat
  for +own1: Nat
  for +addr: Nat
  for +prod2: Nat
  for +rest: +List<Acc.PillarEntry>
  for +status: Acc.ProjectStatus
  for +p: Nat
  for neq: {Nat.is_eq(own1, addr) == False{} : Bool}
  {Bool.and(
    Bool.not(Pil.valid_pillar_producer(addr_valid, True{})),
    Bool.and(
      Bool.not(Pil.valid_pillar_deploy(nv, na, rv, pv, True{}, mp, dp)),
      Bool.and(
        Bool.not(Acc.can_submit_vote(None{}, status)),
        Bool.and(
          root_pillar_opt_has_id(
            Acc.pillar_for_address(Acc.Pillar{id1, own1, addr} <> (Acc.Pillar{id2, addr, prod2} <> rest), addr),
            id2),
          Bool.and(
            Acc.vote_method_is_by_name(Acc.vote_method_for(Acc.Pillar{id2, addr, prod2}, addr)),
            Nat.is_gt(Nat.mul(Acc.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n))))))) == True{} : Bool}

# 15. Cross-domain asset ordering, native token trust & ZTS burn protocol rule:
#     asset_cmp is reflexive, antisymmetric, and orders ZNN < QSR < ZTS
#     (amounts); native ZNN/QSR are always trusted and reserved from custom
#     symbol issuance; and can_burn obeys is_burnable || is_selected_owner
#     (tokens_zts).
law token_and_asset_ordering_coherence:
  for +a: Amt.AssetKind
  for +b: Amt.AssetKind
  for +m: Bool
  for +burn: Bool
  for +tot: Nat
  for +mx: Nat
  for +own: Bool
  for +wown: Bool
  {Bool.and(
    root_cmp_eq(Amt.asset_cmp(a, a), EQ{}),
    Bool.and(
      root_cmp_eq(Amt.asset_cmp(a, b), Amt.cmp_flip(Amt.asset_cmp(b, a))),
      Bool.and(
        root_cmp_eq(Amt.asset_cmp(Amt.Znn{}, Amt.Qsr{}), LT{}),
        Bool.and(
          root_cmp_eq(Amt.asset_cmp(Amt.Qsr{}, Amt.Zts{tot}), LT{}),
          Bool.and(
            Tok.is_trusted_token(True{}, burn, own),
            Bool.and(
              Tok.is_trusted_token(m, True{}, own),
              Bool.and(
                Bool.not(Tok.valid_token_symbol(tot, Tok.SymZnn{})),
                Bool.and(
                  Bool.not(Tok.valid_token_symbol(tot, Tok.SymQsr{})),
                  root_bool_eq(
                    Tok.caps_can_burn(Tok.token_caps(m, burn, tot, mx, own, wown)),
                    Bool.or(burn, own)))))))))) == True{} : Bool}

# 16. Cross-domain sync threshold & clock-skew coherence: SyncDone is synced in
#     both tx_pipeline and node_sync; <3-block sync implies <20-block sync;
#     exact 20-block lag is unsynced for tx creation; and zero clock skew never
#     triggers a discrepancy warning.
law sync_threshold_and_clock_skew_coherence:
  for +st: NS.SyncStateKind
  for +cur: Nat
  for +tgt: Nat
  for +frontier: Nat
  {Bool.and(
    Tx.node_is_synced_for_tx(Tx.SyncDone{}, cur, tgt),
    Bool.and(
      NS.sync_info_is_synced(NS.SyncDone{}, cur, tgt),
      Bool.and(
        Bool.not(Tx.node_is_synced_for_tx(Tx.Syncing{}, 1n+cur, Nat.add(1n+cur, 20n))),
        Bool.and(
          Bool.or(Bool.not(NS.sync_info_is_synced(st, cur, tgt)), NS.node_is_synced_20(st, cur, tgt)),
          Bool.not(NS.should_warn_clock_skew(st, cur, tgt, frontier, frontier)))))) == True{} : Bool}

# 17. Root balanced parallel-let multi-domain evaluation equivalence:
#     evaluating all 11 domains via a balanced 2-level binary parallel-let tree
#     is mathematically identical to sequential evaluation for all inputs.
law root_audit_par_equiv_seq:
  for +plasma_u32: U32
  for +is_unlocked: Bool
  for +is_hw: Bool
  for +qsr: Nat
  for +qsr_bal: Nat
  for +znn_bal: Nat
  for +is_mintable: Bool
  for +is_burnable: Bool
  for +is_owner: Bool
  for +tx_st: Tx.SyncStateKind
  for +tx_cur: Nat
  for +tx_tgt: Nat
  for +ns_st: NS.SyncStateKind
  for +ns_cur: Nat
  for +ns_tgt: Nat
  for +htlc_exp: Nat
  for +htlc_now: Nat
  for +yes_v: Nat
  for +no_v: Nat
  for +verify_ctx: WC.VerifyContext
  for +wc_url: WC.ParsedUrl
  for +wc_init: Bool
  for +wc_disp: Bool
  for +wc_reset: Bool
  {root_audit_par(
    plasma_u32, is_unlocked, is_hw, qsr, qsr_bal,
    znn_bal, is_mintable, is_burnable, is_owner, tx_st, tx_cur, tx_tgt,
    ns_st, ns_cur, ns_tgt, htlc_exp, htlc_now, yes_v, no_v,
    verify_ctx, wc_url, wc_init, wc_disp, wc_reset)
  == root_audit_seq(
    plasma_u32, is_unlocked, is_hw, qsr, qsr_bal,
    znn_bal, is_mintable, is_burnable, is_owner, tx_st, tx_cur, tx_tgt,
    ns_st, ns_cur, ns_tgt, htlc_exp, htlc_now, yes_v, no_v,
    verify_ctx, wc_url, wc_init, wc_disp, wc_reset) : Bool}
