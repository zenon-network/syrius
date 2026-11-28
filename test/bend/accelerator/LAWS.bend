import Base
import ./model.bend as M

# Formal Laws for Syrius Accelerator-Z Governance, Quorum, Visibility,
# Donations, Budget Conservation, and Sequential Phase Lifecycle.

# ------------------------------------------------------------------------------
# Section 1: Pillar Role & Voting Authorization
# ------------------------------------------------------------------------------

# Law 1: Owner match strictly takes precedence over producer match across the
# entire pillar registry.
law pillar_owner_takes_precedence:
  for +pillars: +List<M.PillarEntry>
  for +addr: Nat
  for +p: M.PillarEntry
  for own_found: {M.find_owner(pillars, addr) == Some{p} : Maybe<&2, M.PillarEntry>}
  {M.pillar_for_address(pillars, addr) == Some{p} : Maybe<&2, M.PillarEntry>}

# Law 2: Even when a producer-matching pillar appears BEFORE an owner-matching
# pillar in the list, pillar_for_address selects the owner-matching pillar.
law pillar_owner_beats_earlier_producer:
  for +id1: Nat
  for +own1: Nat
  for +id2: Nat
  for +prod2: Nat
  for +addr: Nat
  for +rest: +List<M.PillarEntry>
  for not_own1: {Nat.is_eq(own1, addr) == False{} : Bool}
  {M.pillar_for_address(
    M.Pillar{id1, own1, addr} <> (M.Pillar{id2, addr, prod2} <> rest),
    addr
  ) == Some{M.Pillar{id2, addr, prod2}} : Maybe<&2, M.PillarEntry>}

# Law 3: When no owner matches, pillar_for_address falls back to producer match.
law pillar_producer_fallback:
  for +pillars: +List<M.PillarEntry>
  for +addr: Nat
  for no_own: {M.find_owner(pillars, addr) == None{} : Maybe<&2, M.PillarEntry>}
  {M.pillar_for_address(pillars, addr) == M.find_producer(pillars, addr) : Maybe<&2, M.PillarEntry>}

# Law 4: Owner address votes ByName; non-owner (producer) address votes ByProdAddress
# (total bijective partition for eligible pillar addresses).
law vote_method_owner_vs_producer:
  for +id: Nat
  for +own: Nat
  for +prod: Nat
  for +other: Nat
  for neq: {Nat.is_eq(own, other) == False{} : Bool}
  {Bool.and(
    M.vote_method_is_by_name(M.vote_method_for(M.Pillar{id, own, prod}, own)),
    M.vote_method_is_by_prod(M.vote_method_for(M.Pillar{id, own, prod}, other))
  ) == True{} : Bool}

# Law 5: Non-pillar addresses NEVER submit a vote regardless of status.
law non_pillar_never_votes:
  for +status: M.ProjectStatus
  {M.can_submit_vote(None{}, status) == False{} : Bool}

# Law 6: Submitting a vote requires BOTH a non-null pillar AND Voting status.
law can_submit_vote_requires_pillar_and_voting:
  for +pillar: Maybe<&2, M.PillarEntry>
  for +status: M.ProjectStatus
  for ok: {M.can_submit_vote(pillar, status) == True{} : Bool}
  {status == M.Voting{} : M.ProjectStatus}

# ------------------------------------------------------------------------------
# Section 2: Quorum, Majority & Progress-Bar Conservation
# ------------------------------------------------------------------------------

# Law 7: Quorum needed is 0 and quorum is NEVER reached when total_pillars == 0.
law quorum_zero_when_no_pillars:
  for +votes: Nat
  {Bool.and(
    Nat.is_eq(M.quorum_needed(0n), 0n),
    Bool.not(M.quorum_reached(votes, 0n))
  ) == True{} : Bool}

# Law 8: For ALL n >= 1 (n = 1n+p), 1 <= quorum_needed(n) <= n.
law quorum_bounded_by_one_and_n:
  for +p: Nat
  {Bool.and(
    Nat.is_le(1n, M.quorum_needed(1n+p)),
    Nat.is_le(M.quorum_needed(1n+p), 1n+p)
  ) == True{} : Bool}

# Law 9 (Strict >33% Quorum Theorem):
# For ALL n >= 1 (n = 1n+p), quorum_needed(n) * 100 > n * 33.
law quorum_strictly_exceeds_33_percent:
  for +p: Nat
  {Nat.is_gt(Nat.mul(M.quorum_needed(1n+p), 100n), Nat.mul(1n+p, 33n)) == True{} : Bool}

# Law 10: Abstains contribute to total votes for quorum (monotonically), while
# majority depends strictly on yes > no.
law abstains_count_for_quorum_not_majority:
  for +yes: Nat
  for +no: Nat
  for +abstain: Nat
  for +extra: Nat
  for +tp: Nat
  for qr: {M.quorum_reached(M.vote_total(yes, no, abstain), tp) == True{} : Bool}
  {M.quorum_reached(M.vote_total(yes, no, Nat.add(abstain, extra)), tp) == True{} : Bool}

# Law 11: Majority requires strictly more yes votes than no votes (ties fail).
law majority_strict_tie_fails:
  for +n: Nat
  {M.has_majority(n, n) == False{} : Bool}

# Law 12: Clamped 3-span bar has zero div-by-zero when total == 0.
law clamped_bar_zero_total_safe:
  for +v1: Nat
  for +v2: Nat
  for +v3: Nat
  {M.clamped_bar_3(v1, v2, v3, 0n) == M.Spans3{0n, 0n, 0n} : M.BarSpans3}

# Law 13 (3-Span Progress-Bar Conservation Theorem):
# For ALL (yes, no, abstain, total), yes_span + no_span + abstain_span <= 100.
law clamped_bar_3_conserved:
  for +v1: Nat
  for +v2: Nat
  for +v3: Nat
  for +total: Nat
  {Nat.is_le(M.bar_span_sum(M.clamped_bar_3(v1, v2, v3, total)), 100n) == True{} : Bool}

# Law 14: Quorum 3-span bar (quorum, votes_to_quorum, remaining_pillars) also
# conserves sum <= 100 for ALL quorum and total_pillars.
law quorum_progress_bar_conserved:
  for +quorum: Nat
  for +total_pillars: Nat
  {Nat.is_le(M.bar_span_sum(M.quorum_progress_bar(quorum, total_pillars)), 100n) == True{} : Bool}

# ------------------------------------------------------------------------------
# Section 3: ProjectListBloc Visibility & Tag Conjunction
# ------------------------------------------------------------------------------

# Law 15: Pillar sees ALL project statuses.
law pillar_sees_all_statuses:
  for +status: M.ProjectStatus
  for +is_owner: Bool
  {M.is_visible_project(True{}, status, is_owner) == True{} : Bool}

# Law 16: Non-pillar ALWAYS sees Active projects and owned projects, and NEVER
# sees non-owned Voting, Paid, Closed, or Completed projects.
law non_pillar_visibility_exact:
  for +status: M.ProjectStatus
  for +is_owner: Bool
  {Bool.and(
    Bool.and(
      M.is_visible_project(False{}, M.Active{}, is_owner),
      M.is_visible_project(False{}, status, True{})
    ),
    Bool.and(
      Bool.and(
        Bool.not(M.is_visible_project(False{}, M.Voting{}, False{})),
        Bool.not(M.is_visible_project(False{}, M.Paid{}, False{}))
      ),
      Bool.and(
        Bool.not(M.is_visible_project(False{}, M.Closed{}, False{})),
        Bool.not(M.is_visible_project(False{}, M.Completed{}, False{}))
      )
    )
  ) == True{} : Bool}

# Law 17: Losing pillar status ALWAYS strips needs_voting and already_voted tags
# while preserving my_projects and only_accepted.
law losing_pillar_strips_voting_tags:
  for +mp: Bool
  for +oa: Bool
  for +nv: Bool
  for +av: Bool
  {M.strip_pillar_tags(False{}, M.Tags{mp, oa, nv, av}) == M.Tags{mp, oa, False{}, False{}} : M.FilterTags}

# Law 18: Active filter tags form a strict AND-conjunction (every enabled tag
# MUST be satisfied by any matching project).
law filter_tags_strict_and_conjunction:
  for +proj: M.ProjectView
  for m: {M.matches_tags(True{}, M.Tags{True{}, True{}, True{}, True{}}, proj) == True{} : Bool}
  {M.proj_all_tags_satisfied(proj) == True{} : Bool}

# ------------------------------------------------------------------------------
# Section 4: Donation Validation & Partial-Commit Retry Safety
# ------------------------------------------------------------------------------

# Law 19: Negative ZNN or QSR donation legs are ALWAYS rejected.
law donation_rejects_negative_legs:
  for +m: Nat
  for +other: M.SignedAmt
  for +bz: Nat
  for +bq: Nat
  {Bool.and(
    Bool.not(M.is_valid_donation(M.Neg{m}, other, bz, bq)),
    Bool.not(M.is_valid_donation(other, M.Neg{m}, bz, bq))
  ) == True{} : Bool}

# Law 20: Non-negative donations reject zero-zero and any leg exceeding balance,
# while accepting positive in-balance ZNN-only or QSR-only donations.
law donation_valid_bounds_and_positive:
  for +z: Nat
  for +q: Nat
  for +bz: Nat
  for +bq: Nat
  for +over: Nat
  {Bool.and(
    Bool.and(
      Bool.not(M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{0n}, bz, bq)),
      Bool.and(
        Bool.not(M.is_valid_donation(M.NonNeg{Nat.add(bz, 1n+over)}, M.NonNeg{q}, bz, bq)),
        Bool.not(M.is_valid_donation(M.NonNeg{z}, M.NonNeg{Nat.add(bq, 1n+over)}, bz, bq))
      )
    ),
    Bool.and(
      M.is_valid_donation(M.NonNeg{1n+z}, M.NonNeg{0n}, 1n+z, bq),
      M.is_valid_donation(M.NonNeg{0n}, M.NonNeg{1n+q}, bz, 1n+q)
    )
  ) == True{} : Bool}

# Law 21 (No Double-Donation Theorem):
# If ZNN succeeds and QSR fails on a dual-coin donation, znn_submitted == True,
# ZNN is cleared, retry NEVER re-submits ZNN, and QSR succeeding reaches Submitted!
law donation_partial_failure_no_double_znn:
  for +zp: Nat
  for +qp: Nat
  for +retry_znn_ok: Bool
  {Bool.and(
    Bool.and(
      M.attempt_sent_znn(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{})),
      Bool.and(
        Bool.not(M.attempt_sent_qsr(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{}))),
        Bool.and(
          Nat.is_eq(M.form_znn(M.attempt_form(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{}))), 0n),
          Bool.and(
            Nat.is_eq(M.form_qsr(M.attempt_form(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{}))), 1n+qp),
            M.don_status_znn_submitted(M.form_status(M.attempt_form(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{}))))
          )
        )
      )
    ),
    Bool.and(
      Bool.not(M.attempt_sent_znn(M.submit_donation_attempt(
        M.attempt_form(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{})),
        retry_znn_ok,
        True{}
      ))),
      Bool.and(
        M.attempt_sent_qsr(M.submit_donation_attempt(
          M.attempt_form(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{})),
          retry_znn_ok,
          True{}
        )),
        M.don_status_is_submitted(M.form_status(M.attempt_form(M.submit_donation_attempt(
          M.attempt_form(M.submit_donation_attempt(M.DonForm{1n+zp, 1n+qp, M.DonInitial{}}, True{}, False{})),
          retry_znn_ok,
          True{}
        ))))
      )
    )
  ) == True{} : Bool}

# Law 22: When both tx outcomes succeed and at least one leg is positive,
# submit_donation_attempt reaches DonSubmitted.
law donation_both_succeed_reaches_submitted:
  for +z: Nat
  for +q: Nat
  for pos: {Bool.or(Nat.is_gt(z, 0n), Nat.is_gt(q, 0n)) == True{} : Bool}
  {M.form_status(M.attempt_form(M.submit_donation_attempt(M.DonForm{z, q, M.DonInitial{}}, True{}, True{}))) == M.DonSubmitted{} : M.DonationStatus}

# ------------------------------------------------------------------------------
# Section 5: Project & Phase Budget Conservation & Sequential Phase Gate
# ------------------------------------------------------------------------------

# Law 23: Valid project budget rejects insufficient fee (< 1 ZNN), out-of-range
# ZNN (< 10 or > 5000), and out-of-range QSR (< 100 or > 50000), while accepting
# exact min (10 ZNN, 100 QSR) and exact max (5000 ZNN, 50000 QSR) boundaries.
law valid_project_budget_enforces_caps:
  for +bal: Nat
  for +znn: Nat
  for +qsr: Nat
  for +over: Nat
  {Bool.and(
    Bool.and(
      Bool.not(M.valid_project_budget(0n, znn, qsr)),
      Bool.and(
        Bool.not(M.valid_project_budget(bal, 9n, qsr)),
        Bool.and(
          Bool.not(M.valid_project_budget(bal, Nat.add(M.PROJECT_MAX_ZNN(), 1n+over), qsr)),
          Bool.and(
            Bool.not(M.valid_project_budget(bal, znn, 99n)),
            Bool.not(M.valid_project_budget(bal, znn, Nat.add(M.PROJECT_MAX_QSR(), 1n+over)))
          )
        )
      )
    ),
    Bool.and(
      M.valid_project_budget(1n+bal, M.PROJECT_MIN_ZNN(), M.PROJECT_MIN_QSR()),
      M.valid_project_budget(1n+bal, M.PROJECT_MAX_ZNN(), M.PROJECT_MAX_QSR())
    )
  ) == True{} : Bool}

# Law 24 (Budget Conservation Theorem):
# Whenever paid <= total, paid + remaining(total, paid) == total.
law budget_conservation:
  for +paid: Nat
  for +total: Nat
  for le: {Nat.is_le(paid, total) == True{} : Bool}
  {Nat.add(paid, M.remaining_funds(total, paid)) == total : Nat}

# Law 25 (Phase Budget Non-Overspend Theorem):
# Whenever paid <= total and phase_funds <= remaining(total, paid),
# paid + phase_funds <= total.
law phase_funds_never_overspend_total:
  for +paid: Nat
  for +phase: Nat
  for +total: Nat
  for le_pt: {Nat.is_le(paid, total) == True{} : Bool}
  for le_rem: {Nat.is_le(phase, M.remaining_funds(total, paid)) == True{} : Bool}
  {Nat.is_le(Nat.add(paid, phase), total) == True{} : Bool}

# Law 26 (Sequential Phase Creation & Update Gate):
# can_create_phase requires owner + Active project + (no phases || last phase Paid);
# can_update_phase requires owner + Voting phase.
law sequential_phase_create_and_update_gate:
  for +is_owner: Bool
  for +proj_st: M.ProjectStatus
  for +last_ph: Maybe<&2, M.ProjectStatus>
  for +ph_st: M.ProjectStatus
  {Bool.and(
    Bool.and(
      Bool.not(M.can_create_phase(False{}, proj_st, last_ph)),
      Bool.and(
        M.can_create_phase(True{}, M.Active{}, None{}),
        M.can_create_phase(True{}, M.Active{}, Some{M.Paid{}})
      )
    ),
    Bool.and(
      Bool.not(M.can_create_phase(True{}, M.Active{}, Some{M.Voting{}})),
      Bool.and(
        Bool.not(M.can_update_phase(False{}, ph_st)),
        M.can_update_phase(True{}, M.Voting{})
      )
    )
  ) == True{} : Bool}

# Law 27: can_create_phase == True implies is_owner == True and proj_status == Active.
law can_create_phase_requires_owner_and_active:
  for +is_owner: Bool
  for +proj_st: M.ProjectStatus
  for +last_ph: Maybe<&2, M.ProjectStatus>
  for ok: {M.can_create_phase(is_owner, proj_st, last_ph) == True{} : Bool}
  {Bool.and(is_owner, M.status_is_active(proj_st)) == True{} : Bool}

# Law 28: Parallelized multi-check helper equals sequential conjunction of its legs.
law parallel_accelerator_audit_equiv:
  for +pillar: Maybe<&2, M.PillarEntry>
  for +vote_status: M.ProjectStatus
  for +yes: Nat
  for +no: Nat
  for +abstain: Nat
  for +total_pillars: Nat
  for +owner_znn_bal: Nat
  for +znn_needed: Nat
  for +qsr_needed: Nat
  for +is_owner: Bool
  for +proj_status: M.ProjectStatus
  for +last_phase: Maybe<&2, M.ProjectStatus>
  {M.parallel_accelerator_audit(
    pillar, vote_status, yes, no, abstain, total_pillars,
    owner_znn_bal, znn_needed, qsr_needed, is_owner, proj_status, last_phase
  ) == Bool.and(
    M.check_governance_leg(pillar, vote_status, yes, no, abstain, total_pillars),
    M.check_budget_leg(owner_znn_bal, znn_needed, qsr_needed, is_owner, proj_status, last_phase)
  ) : Bool}
