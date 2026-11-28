import Base
import ./model.bend as M

# Formal laws for Syrius WalletConnect v2 security and protocol semantics.

# ---------------------------------------------------------------------------
# 1. WalletConnect v2 URI validation & extraction (4 laws)
# ---------------------------------------------------------------------------

law wc_uri_extracted_requires_valid_v2_fields:
  for +cand: M.WcUriCandidate
  for +is_windows: Bool
  for ok: {M.is_wc_uri_extracted(M.extract_wc_uri(cand, is_windows)) == True{} : Bool}
  {M.cand_has_valid_v2_fields(cand) == True{} : Bool}

law wc_uri_rejects_non_v2:
  for +src: M.WcUriSource
  for +slash_q: Bool
  for +ws: Bool
  for +v: Nat
  for +t: Bool
  for +r: Bool
  for +s: Bool
  for +is_windows: Bool
  for not_v2: {Nat.is_eq(v, 2n) == False{} : Bool}
  {M.extract_wc_uri(M.WcUriCandidate{src, slash_q, ws, v, t, r, s}, is_windows) == M.UriRejected{} : M.WcUriExtractResult}

law wc_uri_rejects_missing_required_fields:
  for +src: M.WcUriSource
  for +slash_q: Bool
  for +ws: Bool
  for +v: Nat
  for +t: Bool
  for +r: Bool
  for +s: Bool
  for +is_windows: Bool
  for missing: {Bool.and(t, Bool.and(r, s)) == False{} : Bool}
  {M.extract_wc_uri(M.WcUriCandidate{src, slash_q, ws, v, t, r, s}, is_windows) == M.UriRejected{} : M.WcUriExtractResult}

law wc_uri_extract_idempotent:
  for +cand: M.WcUriCandidate
  for +is_windows: Bool
  {M.reextract_wc_uri(M.extract_wc_uri(cand, is_windows), is_windows) == M.extract_wc_uri(cand, is_windows) : M.WcUriExtractResult}

# ---------------------------------------------------------------------------
# 2. Canonical request identity & error mapping (4 laws)
# ---------------------------------------------------------------------------

law request_key_distinct_ids_never_collide:
  for +m1: Nat
  for +m2: Nat
  for +t1: Nat
  for +t2: Nat
  for +fp1: Nat
  for +fp2: Nat
  for +id1: Nat
  for +id2: Nat
  for diff: {Nat.is_eq(id1, id2) == False{} : Bool}
  {M.request_key_eq(M.interactive_request_key(m1, t1, fp1, Some{id1}), M.interactive_request_key(m2, t2, fp2, Some{id2})) == False{} : Bool}

law request_key_with_id_ignores_params:
  for +m: Nat
  for +t: Nat
  for +fp1: Nat
  for +fp2: Nat
  for +rid: Nat
  {M.interactive_request_key(m, t, fp1, Some{rid}) == M.interactive_request_key(m, t, fp2, Some{rid}) : M.RequestKey}

law wc_error_preserves_known_codes:
  for +kind: M.KnownErrorKind
  for +code: U32
  {M.wc_error_to_json_rpc_code(M.make_known_error(kind, code)) == code : U32}

law wc_error_unknown_maps_to_5000:
  {M.wc_error_to_json_rpc_code(M.ErrUnknown{}) == 5000 : U32}

# ---------------------------------------------------------------------------
# 3. Verify API & metadata sanitization (7 laws)
# ---------------------------------------------------------------------------

law verify_scam_cases_complete:
  for +is_scam_flag: Bool
  for +val: M.VerifyValidation
  {Bool.and(
    Bool.not(M.is_verify_scam(M.NoVerifyContext{})),
    Bool.and(
      M.is_verify_scam(M.HasVerifyContext{True{}, val}),
      Bool.and(
        M.is_verify_scam(M.HasVerifyContext{is_scam_flag, M.ValScam{}}),
        Bool.and(
          Bool.not(M.is_verify_scam(M.HasVerifyContext{False{}, M.ValValid{}})),
          Bool.and(
            Bool.not(M.is_verify_scam(M.HasVerifyContext{False{}, M.ValInvalid{}})),
            Bool.not(M.is_verify_scam(M.HasVerifyContext{False{}, M.ValUnknown{}}))
          )
        )
      )
    )
  ) == True{} : Bool}

law verify_scam_dominates_all_validations:
  for +ctx: M.VerifyContext
  for scam: {M.is_verify_scam(ctx) == True{} : Bool}
  {M.describe_verify_context(ctx) == M.SevScam{} : M.VerifySeverity}

law verify_severity_strict_precedence:
  {Bool.and(
    Nat.is_gt(M.severity_rank(M.describe_verify_context(M.HasVerifyContext{True{}, M.ValValid{}})),
              M.severity_rank(M.describe_verify_context(M.HasVerifyContext{False{}, M.ValInvalid{}}))),
    Bool.and(
      Nat.is_gt(M.severity_rank(M.describe_verify_context(M.HasVerifyContext{False{}, M.ValInvalid{}})),
                M.severity_rank(M.describe_verify_context(M.HasVerifyContext{False{}, M.ValUnknown{}}))),
      Bool.and(
        Nat.is_eq(M.severity_rank(M.describe_verify_context(M.HasVerifyContext{False{}, M.ValUnknown{}})),
                  M.severity_rank(M.describe_verify_context(M.NoVerifyContext{}))),
        Nat.is_gt(M.severity_rank(M.describe_verify_context(M.NoVerifyContext{})),
                  M.severity_rank(M.describe_verify_context(M.HasVerifyContext{False{}, M.ValValid{}})))
      )
    )
  ) == True{} : Bool}

law verify_verified_requires_non_scam_valid:
  for +ctx: M.VerifyContext
  for ok: {M.describe_verify_context(ctx) == M.SevVerified{} : M.VerifySeverity}
  {ctx == M.HasVerifyContext{False{}, M.ValValid{}} : M.VerifyContext}

law sanitize_http_url_allows_only_http_https_with_host:
  for +u: M.ParsedUrl
  for ok: {M.is_url_allowed(M.sanitize_http_url(u)) == True{} : Bool}
  {M.parsed_url_is_valid_http(u) == True{} : Bool}

law sanitize_http_url_blocks_dangerous_schemes_and_empty_host:
  for +has_auth: Bool
  for +host_ok: Bool
  for +s: M.UrlScheme
  {Bool.and(
    Bool.not(M.is_url_allowed(M.sanitize_http_url(M.UrlParsed{M.SchemeJavascript{}, has_auth, host_ok}))),
    Bool.and(
      Bool.not(M.is_url_allowed(M.sanitize_http_url(M.UrlParsed{M.SchemeFile{}, has_auth, host_ok}))),
      Bool.and(
        Bool.not(M.is_url_allowed(M.sanitize_http_url(M.UrlParsed{M.SchemeData{}, has_auth, host_ok}))),
        Bool.and(
          Bool.not(M.is_url_allowed(M.sanitize_http_url(M.UrlParsed{s, False{}, host_ok}))),
          Bool.not(M.is_url_allowed(M.sanitize_http_url(M.UrlParsed{s, has_auth, False{}})))
        )
      )
    )
  ) == True{} : Bool}

law display_value_fallback_on_empty_or_null:
  for +fb: Nat
  for +txt: Nat
  {Bool.and(
    Nat.is_eq(M.display_value(M.DisplayNull{}, fb), fb),
    Bool.and(
      Nat.is_eq(M.display_value(M.DisplayWhitespaceOnly{}, fb), fb),
      Bool.and(
        Nat.is_eq(M.display_value(M.DisplayLiteralNull{}, fb), fb),
        Nat.is_eq(M.display_value(M.DisplayText{txt}, fb), txt)
      )
    )
  ) == True{} : Bool}

# ---------------------------------------------------------------------------
# 4. Namespace allowlist & negotiation (6 laws)
# ---------------------------------------------------------------------------

law namespace_rejects_unsupported_active_chain:
  for +active: M.ChainId
  for +reqs: List<&2, M.NamespaceEntry>
  for bad: {M.is_supported_chain(active) == False{} : Bool}
  {M.unsupported_required_namespace_reason(active, reqs) == M.NsRejectUnsupportedActiveChain{} : M.NamespaceCheckResult}

law namespace_rejects_non_zenon_required:
  for +active: M.ChainId
  for +reqs: List<&2, M.NamespaceEntry>
  for has_other: {M.has_non_zenon_ns(reqs) == True{} : Bool}
  {M.is_ns_accepted(M.unsupported_required_namespace_reason(active, reqs)) == False{} : Bool}

law namespace_accepted_implies_all_requirements_supported:
  for +active: M.ChainId
  for +reqs: List<&2, M.NamespaceEntry>
  for ok: {M.unsupported_required_namespace_reason(active, reqs) == M.NsAccepted{} : M.NamespaceCheckResult}
  {Bool.and(M.is_supported_chain(active), M.all_entries_valid(reqs, active)) == True{} : Bool}

law approved_namespaces_only_active_chain_and_supported:
  for +active: M.ChainId
  for +reqs: List<&2, M.NamespaceEntry>
  for +opts: List<&2, M.NamespaceEntry>
  {Bool.and(
    M.all_methods_supported(M.approved_methods(M.build_approved_namespaces(active, reqs, opts))),
    M.all_events_supported(M.approved_events(M.build_approved_namespaces(active, reqs, opts)))
  ) == True{} : Bool}

law approved_namespaces_chains_is_singleton_active:
  for +active: M.ChainId
  for +reqs: List<&2, M.NamespaceEntry>
  for +opts: List<&2, M.NamespaceEntry>
  {M.approved_chains(M.build_approved_namespaces(active, reqs, opts)) == [active] : List<&2, M.ChainId>}

law approved_namespaces_empty_grants_all_supported:
  for +active: M.ChainId
  {M.build_approved_namespaces(active, Nil{}, Nil{}) == M.ApprovedNamespace{[active], M.all_supported_methods(), M.all_supported_events()} : M.ApprovedNamespace}

# ---------------------------------------------------------------------------
# 5. Signing domain separation (3 laws)
# ---------------------------------------------------------------------------

law signed_message_payload_injective:
  for +m1: List<&2, U32>
  for +m2: List<&2, U32>
  for eq: {M.encode_signed_message_payload(m1) == M.encode_signed_message_payload(m2) : List<&2, U32>}
  {m1 == m2 : List<&2, U32>}

law signed_message_payload_has_domain_prefix:
  for +msg: List<&2, U32>
  {M.has_signed_message_prefix(M.encode_signed_message_payload(msg)) == True{} : Bool}

law signed_message_payload_length_lower_bound:
  for +msg: List<&2, U32>
  {Nat.is_le(Nat.add(25n, List.length(&2, U32, msg)), List.length(&2, U32, M.encode_signed_message_payload(msg))) == True{} : Bool}

law signed_message_payload_disjoint_from_unprefixed_hash:
  for +msg: List<&2, U32>
  for +raw_hash: List<&2, U32>
  for no_pref: {M.has_signed_message_prefix(raw_hash) == False{} : Bool}
  for eq: {M.encode_signed_message_payload(msg) == raw_hash : List<&2, U32>}
  Empty

# ---------------------------------------------------------------------------
# 6. znn_send AccountBlock validation (2 laws)
# ---------------------------------------------------------------------------

law send_block_valid_implies_all_invariants:
  for +blk: M.SendAccountBlock
  for +active_id: Nat
  for ok: {M.validate_send_account_block(blk, active_id) == M.ValidOk{} : M.ValidationOutcome}
  {M.send_block_invariants_hold(blk, active_id) == True{} : Bool}

law send_block_any_violation_rejected_5003:
  for +blk: M.SendAccountBlock
  for +active_id: Nat
  for bad: {M.send_block_invariants_hold(blk, active_id) == False{} : Bool}
  {M.validate_send_account_block(blk, active_id) == M.ValidErr{5003} : M.ValidationOutcome}

# ---------------------------------------------------------------------------
# 7. Signer address authorization (3 laws)
# ---------------------------------------------------------------------------

law signer_null_or_empty_defaults_to_active:
  for +active: Nat
  for +owned: List<&2, Nat>
  {Bool.and(
    M.signer_resolution_eq(M.resolve_signer_address(active, M.ReqAddrNone{}, owned), M.SignerResolved{active}),
    M.signer_resolution_eq(M.resolve_signer_address(active, M.ReqAddrEmpty{}, owned), M.SignerResolved{active})
  ) == True{} : Bool}

law signer_owned_address_allowed:
  for +active: Nat
  for +req: Nat
  for +owned: List<&2, Nat>
  for is_owned: {M.nat_list_contains(owned, req) == True{} : Bool}
  {M.resolve_signer_address(active, M.ReqAddrValue{req}, owned) == M.SignerResolved{req} : M.SignerResolution}

law signer_foreign_address_rejected:
  for +active: Nat
  for +req: Nat
  for +owned: List<&2, Nat>
  for not_owned: {M.nat_list_contains(owned, req) == False{} : Bool}
  {M.resolve_signer_address(active, M.ReqAddrValue{req}, owned) == M.SignerRejectedUnsupportedAccounts{} : M.SignerResolution}

# ---------------------------------------------------------------------------
# 8. Post-confirmation TOCTOU revalidation (4 laws)
# ---------------------------------------------------------------------------

law revalidate_rejects_locked_wallet:
  for +m: M.WcInteractiveMethod
  for +sess_active: Bool
  for +has_req_id: Bool
  for +still_pending: Bool
  for +svc_ch: M.ChainId
  for +sess_ch: M.ChainId
  for +act_ch: M.ChainId
  {M.revalidate_interactive_request(m, M.RevalidationState{True{}, sess_active, has_req_id, still_pending, svc_ch, sess_ch, act_ch}) == M.RevalErr{9000} : M.RevalidationResult}

law revalidate_rejects_inactive_session:
  for +m: M.WcInteractiveMethod
  for +has_req_id: Bool
  for +still_pending: Bool
  for +svc_ch: M.ChainId
  for +sess_ch: M.ChainId
  for +act_ch: M.ChainId
  {M.revalidate_interactive_request(m, M.RevalidationState{False{}, False{}, has_req_id, still_pending, svc_ch, sess_ch, act_ch}) == M.RevalErr{5001} : M.RevalidationResult}

law revalidate_rejects_non_pending_5005:
  for +m: M.WcInteractiveMethod
  for +svc_ch: M.ChainId
  for +sess_ch: M.ChainId
  for +act_ch: M.ChainId
  {M.revalidate_interactive_request(m, M.RevalidationState{False{}, True{}, True{}, False{}, svc_ch, sess_ch, act_ch}) == M.RevalErr{5005} : M.RevalidationResult}

law revalidate_rejects_chain_drift_5003:
  for +m: M.WcInteractiveMethod
  for +svc_ch: M.ChainId
  for +sess_ch: M.ChainId
  for +act_ch: M.ChainId
  for need_chain: {M.method_requires_active_chain_match(m) == True{} : Bool}
  for drifted: {Bool.and(M.chain_id_eq(svc_ch, act_ch), M.chain_id_eq(sess_ch, act_ch)) == False{} : Bool}
  {M.revalidate_interactive_request(m, M.RevalidationState{False{}, True{}, True{}, True{}, svc_ch, sess_ch, act_ch}) == M.RevalErr{5003} : M.RevalidationResult}

# ---------------------------------------------------------------------------
# 9. WalletConnectUriCard revision guard (1 law)
# ---------------------------------------------------------------------------

law uri_card_clears_iff_revision_matches:
  for +cur_rev: Nat
  for +sub_rev: Nat
  for +non_empty: Bool
  {M.card_outcome_cleared(M.uri_card_on_pair_success(M.UriCardState{cur_rev, Some{sub_rev}, non_empty})) == Nat.is_eq(sub_rev, cur_rev) : Bool}

# ---------------------------------------------------------------------------
# 10. Parallelized preflight safety gate (3 laws)
# ---------------------------------------------------------------------------

law parallel_send_preflight_equiv_sequential:
  for +ctx: M.VerifyContext
  for +url: M.ParsedUrl
  for +blk: M.SendAccountBlock
  for +active_chain_id: Nat
  for +active_addr: Nat
  for +req_addr: M.RequestedAddress
  for +owned_addrs: List<&2, Nat>
  for +reval_st: M.RevalidationState
  {M.parallel_send_preflight(ctx, url, blk, active_chain_id, active_addr, req_addr, owned_addrs, reval_st) == M.sequential_send_preflight(ctx, url, blk, active_chain_id, active_addr, req_addr, owned_addrs, reval_st) : Bool}

law parallel_preflight_accepts_valid_send:
  for +active_addr: Nat
  {M.parallel_send_preflight(
    M.HasVerifyContext{False{}, M.ValValid{}},
    M.UrlParsed{M.SchemeHttps{}, True{}, True{}},
    M.SendAccountBlock{M.BlockUserSend{}, M.HashEmpty{}, 1n, M.ChainMainnet{}},
    1n,
    active_addr,
    M.ReqAddrNone{},
    [active_addr],
    M.RevalidationState{False{}, True{}, True{}, True{}, M.ChainMainnet{}, M.ChainMainnet{}, M.ChainMainnet{}}
  ) == True{} : Bool}

law parallel_preflight_blocks_scam_or_locked:
  for +ctx: M.VerifyContext
  for +url: M.ParsedUrl
  for +blk: M.SendAccountBlock
  for +active_chain_id: Nat
  for +active_addr: Nat
  for +req_addr: M.RequestedAddress
  for +owned_addrs: List<&2, Nat>
  for +reval_st: M.RevalidationState
  for blocked: {Bool.or(M.is_verify_scam(ctx), M.reval_wallet_locked(reval_st)) == True{} : Bool}
  {M.parallel_send_preflight(ctx, url, blk, active_chain_id, active_addr, req_addr, owned_addrs, reval_st) == False{} : Bool}
