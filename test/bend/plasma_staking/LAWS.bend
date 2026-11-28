import Base
import ./model.bend as M

# Domain 1: Plasma & Staking formal laws (27 laws).

# 1. Zero QSR yields zero Plasma at any conversion rate.
law plasma_for_qsr_zero:
  for +rate: Nat
  {M.plasma_for_qsr(0n, rate) == 0n : Nat}

# 2. QSR-to-Plasma conversion is additive: plasma(a + b) == plasma(a) + plasma(b).
law plasma_for_qsr_additive:
  for +a: Nat
  for +b: Nat
  for +rate: Nat
  {M.plasma_for_qsr(Nat.add(a, b), rate) == Nat.add(M.plasma_for_qsr(a, rate), M.plasma_for_qsr(b, rate)) : Nat}

# 3. QSR-to-Plasma conversion is monotone in fused QSR.
law plasma_for_qsr_monotone:
  for +a: Nat
  for +b: Nat
  for +rate: Nat
  for h: {Nat.is_le(a, b) == True{} : Bool}
  {Nat.is_le(M.plasma_for_qsr(a, rate), M.plasma_for_qsr(b, rate)) == True{} : Bool}

# 4. Exact Zenon constant check: 10 QSR -> 21,000 Plasma and exact op thresholds.
law op_plasma_u32_exact:
  {Bool.and(
    U32.is_eq(M.plasma_for_qsr_u32(10), M.op_plasma_u32(M.OpMinPlasma{})),
    Bool.and(
      U32.is_eq(M.plasma_for_qsr_u32(40), M.op_plasma_u32(M.OpDelegate{})),
      Bool.and(
        U32.is_eq(M.plasma_for_qsr_u32(50), M.op_plasma_u32(M.OpStake{})),
        Bool.and(
          U32.is_eq(M.plasma_for_qsr_u32(90), M.op_plasma_u32(M.OpIssueToken{})),
          Bool.and(
            U32.is_eq(M.plasma_for_qsr_u32(120), M.op_plasma_u32(M.OpPillar{})),
            U32.is_eq(M.op_plasma_u32(M.OpPillar{}), M.op_plasma_u32(M.OpSentinel{}))))))) == True{} : Bool}

# 5. Strict ascending order of operation plasma thresholds:
#    min_plasma (21k) < delegate (84k) < stake (105k) < issue_token (189k) < pillar == sentinel (252k).
law op_plasma_strict_order:
  {Bool.and(
    Nat.is_lt(M.op_plasma_k(M.OpMinPlasma{}), M.op_plasma_k(M.OpDelegate{})),
    Bool.and(
      Nat.is_lt(M.op_plasma_k(M.OpDelegate{}), M.op_plasma_k(M.OpStake{})),
      Bool.and(
        Nat.is_lt(M.op_plasma_k(M.OpStake{}), M.op_plasma_k(M.OpIssueToken{})),
        Bool.and(
          Nat.is_lt(M.op_plasma_k(M.OpIssueToken{}), M.op_plasma_k(M.OpPillar{})),
          Nat.is_eq(M.op_plasma_k(M.OpPillar{}), M.op_plasma_k(M.OpSentinel{})))))) == True{} : Bool}

# 6. meets_plasma is monotone in current plasma.
law meets_plasma_monotone:
  for +p1: Nat
  for +p2: Nat
  for +req: Nat
  for le: {Nat.is_le(p1, p2) == True{} : Bool}
  for ok: {M.meets_plasma(p1, req) == True{} : Bool}
  {M.meets_plasma(p2, req) == True{} : Bool}

# 7. FusePlasma rejects zero balance regardless of input (blocks correctValue 0-balance bypass).
law fuse_rejects_zero_balance:
  for +qsr: Nat
  for +is_int: Bool
  for +valid_ben: Bool
  {M.can_fuse_plasma(qsr, 0n, is_int, valid_ben) == False{} : Bool}

# 8. FusePlasma rejects amounts strictly below 10 QSR.
law fuse_rejects_below_min:
  for +qsr: Nat
  for +bal: Nat
  for +is_int: Bool
  for +valid_ben: Bool
  for lt: {Nat.is_lt(qsr, M.fuse_min_qsr()) == True{} : Bool}
  {M.can_fuse_plasma(qsr, bal, is_int, valid_ben) == False{} : Bool}

# 9. FusePlasma rejects amounts strictly exceeding available balance.
law fuse_rejects_above_balance:
  for +qsr: Nat
  for +bal: Nat
  for +is_int: Bool
  for +valid_ben: Bool
  for gt: {Nat.is_gt(qsr, bal) == True{} : Bool}
  {M.can_fuse_plasma(qsr, bal, is_int, valid_ben) == False{} : Bool}

# 10. FusePlasma requires integer QSR and valid beneficiary, and accepts minimum boundary 10 QSR.
law fuse_requires_integer_and_beneficiary:
  for +qsr: Nat
  for +bal: Nat
  {Bool.and(
    Bool.not(M.can_fuse_plasma(qsr, bal, False{}, True{})),
    Bool.and(
      Bool.not(M.can_fuse_plasma(qsr, bal, True{}, False{})),
      M.can_fuse_plasma(10n, 10n, True{}, True{}))) == True{} : Bool}

# 11. FusedPlasma status is an exact disjoint partition between Revocable and Locked.
law fusion_status_exact_partition:
  for +last_height: Nat
  for +exp_height: Nat
  {Bool.xor(
    M.fusion_is_revocable(M.fusion_status(last_height, exp_height)),
    M.fusion_is_locked(M.fusion_status(last_height, exp_height))) == True{} : Bool}

# 12. At exact expiration boundary (last == exp), fusion is still Locked with 0s countdown.
law fusion_eq_boundary_locked_zero:
  for +h: Nat
  {M.fusion_status(h, h) == M.FusionLocked{0n} : M.FusionStatus}

# 13. Strictly past expiration height (last > exp), fusion is Revocable.
law fusion_above_exp_revocable:
  for +last_height: Nat
  for +exp_height: Nat
  for gt: {Nat.is_gt(last_height, exp_height) == True{} : Bool}
  {M.fusion_status(last_height, exp_height) == M.FusionRevocable{} : M.FusionStatus}

# 14. A stopped CancelTimer never fires again or mutates state on further ticks.
law cancel_timer_stopped_idempotent:
  for +rem: Nat
  for +fired: Nat
  {M.cancel_timer_tick(M.CancelTimerState{rem, False{}, fired}) == M.CancelTimerState{rem, False{}, fired} : M.CancelTimerState}

# 15. A running CancelTimer at 0s or 1s terminates cleanly with remaining == 0n, running == False{}, fired + 1.
law cancel_timer_terminates_cleanly:
  for +fired: Nat
  {Bool.and(
    Bool.and(
      Nat.is_eq(M.timer_remaining(M.cancel_timer_tick(M.CancelTimerState{0n, True{}, fired})), 0n),
      Bool.not(M.timer_running(M.cancel_timer_tick(M.CancelTimerState{0n, True{}, fired})))),
    Bool.and(
      Nat.is_eq(M.timer_fired(M.cancel_timer_tick(M.CancelTimerState{1n, True{}, fired})), 1n+fired),
      Bool.not(M.timer_running(M.cancel_timer_tick(M.CancelTimerState{1n, True{}, fired}))))) == True{} : Bool}

# 16. Once a timer fires at 0s, running any additional k ticks keeps fired_count constant (no 1Hz storm).
law cancel_timer_no_storm_after_zero:
  for +k: Nat
  for +fired: Nat
  {M.cancel_timer_run(k, M.cancel_timer_tick(M.CancelTimerState{0n, True{}, fired})) == M.CancelTimerState{0n, False{}, 1n+fired} : M.CancelTimerState}

# 17. PlasmaStatsBloc safe page slicing always satisfies 0 <= start <= end <= list_len.
law page_slice_start_le_end:
  for +list_len: Nat
  for +page_index: Nat
  for +page_size: Nat
  {Nat.is_le(M.page_slice_start(M.page_slice(list_len, page_index, page_size)), M.page_slice_end(M.page_slice(list_len, page_index, page_size))) == True{} : Bool}

law page_slice_end_le_len:
  for +list_len: Nat
  for +page_index: Nat
  for +page_size: Nat
  {Nat.is_le(M.page_slice_end(M.page_slice(list_len, page_index, page_size)), list_len) == True{} : Bool}

# 19. Staking duration catalog rejects 0 months and > 12 months, accepts 1..12.
law stake_months_bounds:
  for +k: Nat
  {Bool.and(
    Bool.not(M.valid_stake_months(0n)),
    Bool.and(
      M.valid_stake_months(1n),
      Bool.and(
        M.valid_stake_months(12n),
        Bool.not(M.valid_stake_months(13n+k))))) == True{} : Bool}

# 20. Staking duration in seconds is strictly monotone in months for any positive unit_sec,
#     and matches exact U32 protocol bounds (1 mo = 2,592,000s, 12 mo = 31,104,000s).
law stake_duration_strictly_monotone:
  for +m1: Nat
  for +m2: Nat
  for +u: Nat
  for lt: {Nat.is_lt(m1, m2) == True{} : Bool}
  {Nat.is_lt(M.stake_duration_secs(m1, 1n+u), M.stake_duration_secs(m2, 1n+u)) == True{} : Bool}

law stake_duration_u32_exact:
  {Bool.and(
    U32.is_eq(M.stake_duration_u32(1), 2592000),
    U32.is_eq(M.stake_duration_u32(12), 31104000)) == True{} : Bool}

# 22. CreateStake rejects zero balance, zero amount, amt > bal, invalid months (0 or >= 13),
#     and accepts valid minimum (1 ZNN, 1 mo).
law create_stake_guards:
  for +amt: Nat
  for +bal: Nat
  for +months: Nat
  for +k: Nat
  {Bool.and(
    Bool.not(M.can_create_stake(amt, 0n, months)),
    Bool.and(
      Bool.not(M.can_create_stake(0n, bal, months)),
      Bool.and(
        Bool.not(M.can_create_stake(Nat.add(bal, 1n+k), bal, months)),
        Bool.and(
          Bool.not(M.can_create_stake(amt, bal, 0n)),
          Bool.and(
            Bool.not(M.can_create_stake(amt, bal, 13n+k)),
            M.can_create_stake(1n, 1n, 1n)))))) == True{} : Bool}

# 23. Stake expiration vs positive countdown is a strict partition (no 0s non-expired gap).
law stake_lock_expired_at_or_past:
  for +now_sec: Nat
  for +exp_sec: Nat
  for ge: {Nat.is_ge(now_sec, exp_sec) == True{} : Bool}
  {M.stake_lock_status(now_sec, exp_sec) == M.StakeExpired{} : M.StakeLockStatus}

law stake_lock_positive_countdown_before_exp:
  for +now_sec: Nat
  for +exp_sec: Nat
  for lt: {Nat.is_lt(now_sec, exp_sec) == True{} : Bool}
  {Nat.is_gt(M.stake_locked_secs(M.stake_lock_status(now_sec, exp_sec)), 0n) == True{} : Bool}

# 25. StakeCollect is strictly QSR-only; StakingRewardsHistory requires at least one positive QSR epoch.
law stake_collect_qsr_only_and_history_gate:
  for +q: Nat
  for +znn: Nat
  for +rest: +List<Nat>
  {Bool.and(
    Bool.not(M.can_collect_stake_rewards(0n, znn)),
    Bool.and(
      M.can_collect_stake_rewards(1n+q, 0n),
      Bool.and(
        Bool.not(M.has_staking_reward_history(Nil{})),
        M.has_staking_reward_history((1n+q) <> rest)))) == True{} : Bool}

# 26. Epoch dates are monotone in epoch index.
law epoch_day_monotone:
  for +g: Nat
  for +e1: Nat
  for +e2: Nat
  for le: {Nat.is_le(e1, e2) == True{} : Bool}
  {Nat.is_le(M.epoch_day(g, e1), M.epoch_day(g, e2)) == True{} : Bool}

# 27. Parallel plasma+staking check equals sequential conjunction.
law parallel_plasma_staking_equiv:
  for +qsr: Nat
  for +qsr_bal: Nat
  for +is_int: Bool
  for +valid_ben: Bool
  for +znn: Nat
  for +znn_bal: Nat
  for +months: Nat
  {M.parallel_plasma_staking_check(qsr, qsr_bal, is_int, valid_ben, znn, znn_bal, months) == Bool.and(M.can_fuse_plasma(qsr, qsr_bal, is_int, valid_ben), M.can_create_stake(znn, znn_bal, months)) : Bool}
