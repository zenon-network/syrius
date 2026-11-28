import Base
import ./model.bend as M

# Domain 2: Pillars & Sentinels formal laws (26 laws).

# 1. Exact Zenon protocol constants for Pillar vs Sentinel.
law role_protocol_constants:
  {Bool.and(
    U32.is_eq(M.role_plasma_req_u32(M.RolePillar{}), 252000),
    Bool.and(
      U32.is_eq(M.role_plasma_req_u32(M.RoleSentinel{}), 252000),
      Bool.and(
        U32.is_eq(M.role_znn_collateral_u32(M.RolePillar{}), 15000),
        Bool.and(
          U32.is_eq(M.role_znn_collateral_u32(M.RoleSentinel{}), 5000),
          Bool.and(
            U32.is_eq(M.sentinel_qsr_cost_u32(), 50000),
            Bool.and(
              M.role_qsr_burned(M.RolePillar{}),
              Bool.not(M.role_qsr_burned(M.RoleSentinel{})))))))) == True{} : Bool}

# 2. Create stepper never moves backward (rank is monotone).
law create_step_monotone:
  for +step: M.CreateStep
  for +plasma: Nat
  for +plasma_req: Nat
  for +deposit: Nat
  for +qsr_cost: Nat
  for +znn_bal: Nat
  for +znn_req: Nat
  for +deploy_valid: Bool
  {Nat.is_le(
    M.create_step_rank(step),
    M.create_step_rank(M.advance_create_step(step, plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid))) == True{} : Bool}

# 3. Cannot advance past StepPlasma without sufficient plasma.
law create_step_plasma_gate:
  for +plasma: Nat
  for +plasma_req: Nat
  for +deposit: Nat
  for +qsr_cost: Nat
  for +znn_bal: Nat
  for +znn_req: Nat
  for +deploy_valid: Bool
  for lt: {Nat.is_lt(plasma, plasma_req) == True{} : Bool}
  {M.advance_create_step(M.StepPlasma{}, plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid) == M.StepPlasma{} : M.CreateStep}

# 4. Cannot advance past StepQsr until QSR deposit covers QSR cost.
law create_step_qsr_gate:
  for +plasma: Nat
  for +plasma_req: Nat
  for +deposit: Nat
  for +qsr_cost: Nat
  for +znn_bal: Nat
  for +znn_req: Nat
  for +deploy_valid: Bool
  for lt: {Nat.is_lt(deposit, qsr_cost) == True{} : Bool}
  {M.advance_create_step(M.StepQsr{}, plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid) == M.StepQsr{} : M.CreateStep}

# 5. Cannot advance past StepZnn without sufficient ZNN collateral.
law create_step_znn_gate:
  for +plasma: Nat
  for +plasma_req: Nat
  for +deposit: Nat
  for +qsr_cost: Nat
  for +znn_bal: Nat
  for +znn_req: Nat
  for +deploy_valid: Bool
  for lt: {Nat.is_lt(znn_bal, znn_req) == True{} : Bool}
  {M.advance_create_step(M.StepZnn{}, plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid) == M.StepZnn{} : M.CreateStep}

# 6. Cannot deploy with invalid form; StepDone is absorbing.
law create_step_deploy_gate_and_done_absorbing:
  for +plasma: Nat
  for +plasma_req: Nat
  for +deposit: Nat
  for +qsr_cost: Nat
  for +znn_bal: Nat
  for +znn_req: Nat
  for +deploy_valid: Bool
  {Bool.and(
    Nat.is_eq(M.create_step_rank(M.advance_create_step(M.StepDeploy{}, plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, False{})), 3n),
    Nat.is_eq(M.create_step_rank(M.advance_create_step(M.StepDone{}, plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req, deploy_valid)), 4n)) == True{} : Bool}

# 7. max_qsr_deposit never exceeds available balance.
law max_qsr_deposit_le_balance:
  for +bal: Nat
  for +cost: Nat
  for +dep: Nat
  {Nat.is_le(M.max_qsr_deposit(bal, cost, dep), bal) == True{} : Bool}

# 8. Depositing max_qsr_deposit never over-deposits beyond max(cost, dep).
law max_qsr_deposit_never_overdeposits:
  for +bal: Nat
  for +cost: Nat
  for +dep: Nat
  {Nat.is_le(Nat.add(dep, M.max_qsr_deposit(bal, cost, dep)), Nat.max(cost, dep)) == True{} : Bool}

# 9. Once QSR cost is covered (dep >= cost), remaining QSR is 0.
law qsr_covered_implies_zero_remaining:
  for +dep: Nat
  for +cost: Nat
  for cov: {M.qsr_covered(dep, cost) == True{} : Bool}
  {M.qsr_remaining(cost, dep) == 0n : Nat}

# 10. Clamped QSR pie chart conserves total cost: min(dep, cost) + (cost - dep) == cost.
law qsr_pie_conservation:
  for +cost: Nat
  for +dep: Nat
  {Nat.add(M.clamped_qsr_deposit(cost, dep), M.qsr_remaining(cost, dep)) == cost : Nat}

# 11. Withdraw button visible iff deposited QSR > 0.
law can_withdraw_iff_positive:
  for +d: Nat
  {Bool.and(
    Bool.not(M.can_withdraw_qsr(0n)),
    M.can_withdraw_qsr(1n+d)) == True{} : Bool}

# 12. Deposit confirmation rejects zero amount (prevents instant false-confirm bug).
law deposit_confirm_rejects_zero_amount:
  for +init: Nat
  for +obs: Nat
  {M.is_deposit_confirmed(init, 0n, obs) == False{} : Bool}

# 13. Confirmed deposit strictly increases deposited QSR above initial snapshot.
law deposit_confirm_strictly_increases:
  for +init: Nat
  for +amt: Nat
  for +obs: Nat
  for ok: {M.is_deposit_confirmed(init, amt, obs) == True{} : Bool}
  {Nat.is_lt(init, obs) == True{} : Bool}

# 14. Confirmed withdraw strictly decreases deposit (with snapshot) or hits 0 (without snapshot).
law withdraw_confirm_with_snapshot_decreases:
  for +init: Nat
  for +obs: Nat
  for ok: {M.is_withdraw_confirmed(True{}, init, obs) == True{} : Bool}
  {Nat.is_lt(obs, init) == True{} : Bool}

law withdraw_confirm_without_snapshot_zero:
  for +init: Nat
  for +obs: Nat
  for ok: {M.is_withdraw_confirmed(False{}, init, obs) == True{} : Bool}
  {obs == 0n : Nat}

# 16. Pillar producer address MUST NOT belong to the wallet's own address list.
law producer_rejects_wallet_address:
  for +addr_valid: Bool
  {M.valid_pillar_producer(addr_valid, True{}) == False{} : Bool}

law deploy_pillar_rejects_wallet_producer:
  for +nv: Bool
  for +na: Bool
  for +rv: Bool
  for +pv: Bool
  for +mp: Nat
  for +dp: Nat
  {M.valid_pillar_deploy(nv, na, rv, pv, True{}, mp, dp) == False{} : Bool}

# 18. Pillar reward split conservation: for any valid pct <= 100, (100 - pct) + pct == 100.
law reward_pct_conservation:
  for +pct: Nat
  for ok: {M.valid_reward_pct(pct) == True{} : Bool}
  {Nat.add(M.owner_reward_pct(pct), pct) == 100n : Nat}

# 19. Pillar reward percentages > 100 are always rejected.
law reward_pct_rejects_over_100:
  for +k: Nat
  {M.valid_reward_pct(101n+k) == False{} : Bool}

# 20. Update Pillar 3-step navigation: universal monotonicity on advance, False-gate blocking,
#     reversibility between Details/Rewards/Submit, and UpdDone absorbing on advance & back.
law update_step_navigation:
  for +step: M.UpdateStep
  for +dv: Bool
  for +rv: Bool
  for +so: Bool
  {Bool.and(
    Nat.is_le(M.update_step_rank(step), M.update_step_rank(M.advance_update_step(step, dv, rv, so))),
    Bool.and(
      Nat.is_eq(M.update_step_rank(M.advance_update_step(M.UpdDetails{}, False{}, rv, so)), 0n),
      Bool.and(
        Nat.is_eq(M.update_step_rank(M.advance_update_step(M.UpdRewards{}, dv, False{}, so)), 1n),
        Bool.and(
          Nat.is_eq(M.update_step_rank(M.advance_update_step(M.UpdSubmit{}, dv, rv, False{})), 2n),
          Bool.and(
            Nat.is_eq(M.update_step_rank(M.back_update_step(M.advance_update_step(M.UpdDetails{}, True{}, rv, so))), 0n),
            Bool.and(
              Nat.is_eq(M.update_step_rank(M.back_update_step(M.advance_update_step(M.UpdRewards{}, dv, True{}, so))), 1n),
              Bool.and(
                Nat.is_eq(M.update_step_rank(M.advance_update_step(M.UpdDone{}, dv, rv, so)), 3n),
                Nat.is_eq(M.update_step_rank(M.back_update_step(M.UpdDone{})), 3n)))))))) == True{} : Bool}

# 21. Safe momentum uptime returns 0 when expected == 0 (no div-by-zero / Infinity crash)
#     and satisfies safe_uptime_pct(produced, expected) <= 100 whenever produced <= expected.
law safe_uptime_zero_expected:
  for +produced: Nat
  {M.safe_uptime_pct(produced, 0n) == 0n : Nat}

law safe_uptime_bounded_100:
  for +produced: Nat
  for +expected: Nat
  for le: {Nat.is_le(produced, expected) == True{} : Bool}
  {Nat.is_le(M.safe_uptime_pct(produced, expected), 100n) == True{} : Bool}

# 23. Delegation requires >= 1 ZNN; active iff status == 1 (rejecting 0 and >= 2);
#     undelegate always clears delegation.
law delegation_rules:
  for +d: M.DelegationState
  for +pid: Nat
  for +k: Nat
  {Bool.and(
    Bool.not(M.can_delegate(0n)),
    Bool.and(
      M.can_delegate(1n+k),
      Bool.and(
        M.delegation_is_active(M.Delegated{pid, 1n}),
        Bool.and(
          Bool.not(M.delegation_is_active(M.Delegated{pid, 0n})),
          Bool.and(
            Bool.not(M.delegation_is_active(M.Delegated{pid, 2n+k})),
            Bool.not(M.delegation_is_active(M.undelegate_state(d)))))))) == True{} : Bool}

# 24. Sentinel authorization matrix: active Sentinel blocks spawn; non-owner NEVER sees timer or revoke;
#     revoke enabled iff owner && revocable.
law sentinel_authorization_matrix:
  for +is_owner: Bool
  for +is_rev: Bool
  for +has_act: Bool
  {Bool.and(
    Bool.not(M.auth_can_spawn(M.sentinel_auth(is_owner, is_rev, True{}))),
    Bool.and(
      Bool.not(M.auth_show_timer(M.sentinel_auth(False{}, is_rev, has_act))),
      Bool.and(
        Bool.not(M.auth_can_revoke(M.sentinel_auth(False{}, is_rev, has_act))),
        Bool.and(
          Bool.not(M.auth_can_revoke(M.sentinel_auth(is_owner, False{}, has_act))),
          M.auth_can_revoke(M.sentinel_auth(True{}, True{}, has_act)))))) == True{} : Bool}

# 25. Reward collectability & history: Pillar is strictly ZNN-only; Sentinel is dual-coin (ZNN || QSR).
law reward_collect_pillar_vs_sentinel:
  for +z: Nat
  for +q: Nat
  for +rest: +List<M.RewardEntry>
  {Bool.and(
    Bool.not(M.can_collect_rewards(M.RolePillar{}, 0n, q)),
    Bool.and(
      M.can_collect_rewards(M.RolePillar{}, 1n+z, 0n),
      Bool.and(
        Bool.not(M.can_collect_rewards(M.RoleSentinel{}, 0n, 0n)),
        Bool.and(
          M.can_collect_rewards(M.RoleSentinel{}, 0n, 1n+q),
          Bool.and(
            M.can_collect_rewards(M.RoleSentinel{}, 1n+z, 0n),
            Bool.and(
              Bool.not(M.has_reward_history(M.RolePillar{}, Nil{})),
              M.has_reward_history(M.RoleSentinel{}, M.RewardEntry{0n, 1n+q} <> rest))))))) == True{} : Bool}

# 26. Parallel spawn readiness check equals sequential conjunction.
law parallel_spawn_readiness_equiv:
  for +plasma: Nat
  for +plasma_req: Nat
  for +deposit: Nat
  for +qsr_cost: Nat
  for +znn_bal: Nat
  for +znn_req: Nat
  {M.parallel_spawn_readiness(plasma, plasma_req, deposit, qsr_cost, znn_bal, znn_req) == Bool.and(M.meets_req(plasma, plasma_req), Bool.and(M.qsr_covered(deposit, qsr_cost), M.meets_req(znn_bal, znn_req))) : Bool}
