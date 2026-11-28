import Base

# Domain 1: Plasma & Staking protocol and UI-edge specification for Syrius.
#
# Exact Zenon protocol constants:
# - 1 QSR = 2100 Plasma, fuse_min_qsr = 10 QSR -> 21,000 Plasma.
# - Operation plasma thresholds (raw Plasma / kilo-plasma):
#     OpMinPlasma  =  21,000 ( 21k)
#     OpDelegate   =  84,000 ( 84k)
#     OpStake      = 105,000 (105k)
#     OpIssueToken = 189,000 (189k)
#     OpPillar     = 252,000 (252k)
#     OpSentinel   = 252,000 (252k)
# - Momentum interval = 10 seconds.
# - Staking duration unit = 30 days = 2,592,000 seconds; allowed months = 1..12.
# - Minimum stake amount = 1 ZNN; staking rewards are QSR-only.

type PlasmaOp is Data:
  OpMinPlasma{}
  OpDelegate{}
  OpStake{}
  OpIssueToken{}
  OpPillar{}
  OpSentinel{}

type FusionStatus is Data:
  FusionRevocable{}
  FusionLocked{seconds: Nat}

type CancelTimerState is Data:
  CancelTimerState{remaining: Nat, running: Bool, fired_count: Nat}

type PageSlice is Data:
  PageSlice{start: Nat, end: Nat}

type StakeLockStatus is Data:
  StakeExpired{}
  StakeLocked{seconds: Nat}

# QSR <-> Plasma arithmetic
# -------------------------

def fuse_min_qsr() -> Nat:
  10n

def plasma_for_qsr(+qsr: Nat, +rate: Nat) -> Nat:
  Nat.mul(qsr, rate)

def plasma_for_qsr_u32(+qsr: U32) -> U32:
  (qsr * 2100 : U32)

# Operation plasma thresholds (in kilo-plasma for Nat induction, and exact U32)
# -----------------------------------------------------------------------------

def op_plasma_k(+op: PlasmaOp) -> Nat:
  match op:
    case OpMinPlasma{}:
      21n
    case OpDelegate{}:
      84n
    case OpStake{}:
      105n
    case OpIssueToken{}:
      189n
    case OpPillar{}:
      252n
    case OpSentinel{}:
      252n

def op_plasma_u32(+op: PlasmaOp) -> U32:
  match op:
    case OpMinPlasma{}:
      21000
    case OpDelegate{}:
      84000
    case OpStake{}:
      105000
    case OpIssueToken{}:
      189000
    case OpPillar{}:
      252000
    case OpSentinel{}:
      252000

def meets_plasma(+current: Nat, +required: Nat) -> Bool:
  Nat.is_ge(current, required)

# FusePlasma validation (rejects 0 balance, < 10 QSR, > balance, fractional, bad beneficiary)
# -------------------------------------------------------------------------------------------

def can_fuse_plasma(+qsr: Nat, +balance: Nat, +is_integer: Bool, +valid_beneficiary: Bool) -> Bool:
  Bool.and(
    Nat.is_gt(balance, 0n),
    Bool.and(
      Nat.is_ge(qsr, fuse_min_qsr()),
      Bool.and(
        Nat.is_le(qsr, balance),
        Bool.and(is_integer, valid_beneficiary))))

# FusedPlasma revocability & countdown partition
# ----------------------------------------------

def fusion_countdown_secs(+last_height: Nat, +exp_height: Nat) -> Nat:
  Nat.mul(10n, Nat.sub(exp_height, last_height))

def fusion_status_from_gt(+is_gt: Bool, +last_height: Nat, +exp_height: Nat) -> FusionStatus:
  match is_gt:
    case True{}:
      FusionRevocable{}
    case False{}:
      FusionLocked{fusion_countdown_secs(last_height, exp_height)}

def fusion_status(+last_height: Nat, +exp_height: Nat) -> FusionStatus:
  fusion_status_from_gt(Nat.is_gt(last_height, exp_height), last_height, exp_height)

def fusion_is_revocable(+s: FusionStatus) -> Bool:
  match s:
    case FusionRevocable{}:
      True{}
    case FusionLocked{_}:
      False{}

def fusion_is_locked(+s: FusionStatus) -> Bool:
  match s:
    case FusionRevocable{}:
      False{}
    case FusionLocked{_}:
      True{}

# CancelTimer terminating reducer (normative target contract: fixes infinite 1Hz
# polling storm at <= 0s; current lib/widgets/reusable_widgets/cancel_timer.dart
# leaves _countDownTimer running and fires on the tick after reaching 0s)
# ------------------------------------------------------------------------------

def cancel_timer_tick_go(+running: Bool, +remaining: Nat, +fired_count: Nat) -> CancelTimerState:
  match running:
    case False{}:
      CancelTimerState{remaining, False{}, fired_count}
    case True{}:
      match remaining:
        case 0n:
          CancelTimerState{0n, False{}, 1n+fired_count}
        case 1n:
          CancelTimerState{0n, False{}, 1n+fired_count}
        case 2n+r:
          CancelTimerState{1n+r, True{}, fired_count}

def cancel_timer_tick(+st: CancelTimerState) -> CancelTimerState:
  match st:
    case CancelTimerState{remaining, running, fired_count}:
      cancel_timer_tick_go(running, remaining, fired_count)

def timer_remaining(+st: CancelTimerState) -> Nat:
  match st:
    case CancelTimerState{r, _, _}:
      r

def timer_running(+st: CancelTimerState) -> Bool:
  match st:
    case CancelTimerState{_, run, _}:
      run

def timer_fired(+st: CancelTimerState) -> Nat:
  match st:
    case CancelTimerState{_, _, f}:
      f

def cancel_timer_run(+ticks: Nat, +st: CancelTimerState) -> CancelTimerState:
  match ticks:
    case 0n:
      st
    case 1n+p:
      cancel_timer_run(p, cancel_timer_tick(st))

# PlasmaStatsBloc safe page slicing (normative target contract: clamps start <= end
# <= list_len to prevent RangeError when start > list_len if address list shrinks)
# ---------------------------------------------------------------------------------

def page_slice_from_start(+list_len: Nat, +start: Nat, +page_size: Nat) -> PageSlice:
  PageSlice{start, Nat.min(Nat.add(start, page_size), list_len)}

def page_slice(+list_len: Nat, +page_index: Nat, +page_size: Nat) -> PageSlice:
  page_slice_from_start(list_len, Nat.min(Nat.mul(page_index, page_size), list_len), page_size)

def page_slice_start(+s: PageSlice) -> Nat:
  match s:
    case PageSlice{start, _}:
      start

def page_slice_end(+s: PageSlice) -> Nat:
  match s:
    case PageSlice{_, end}:
      end

# Staking duration catalog, creation validation, expiration, rewards & history
# ----------------------------------------------------------------------------

def valid_stake_months(+months: Nat) -> Bool:
  Bool.and(Nat.is_ge(months, 1n), Nat.is_le(months, 12n))

def stake_duration_secs(+months: Nat, +unit_sec: Nat) -> Nat:
  Nat.mul(months, unit_sec)

def stake_duration_u32(+months: U32) -> U32:
  (months * 2592000 : U32)

def can_create_stake(+amount: Nat, +balance: Nat, +months: Nat) -> Bool:
  Bool.and(
    Nat.is_gt(balance, 0n),
    Bool.and(
      Nat.is_ge(amount, 1n),
      Bool.and(
        Nat.is_le(amount, balance),
        valid_stake_months(months))))

# Normative target contract: now_sec >= exp_sec => StakeExpired (gap-free partition;
# current lib/rearchitecture/features/stakes/view/stakes_card.dart uses strict <,
# leaving a 0s non-expired gap at nowMs == exp*1000).
def stake_lock_from_ge(+is_ge: Bool, +now_sec: Nat, +exp_sec: Nat) -> StakeLockStatus:
  match is_ge:
    case True{}:
      StakeExpired{}
    case False{}:
      StakeLocked{Nat.sub(exp_sec, now_sec)}

def stake_lock_status(+now_sec: Nat, +exp_sec: Nat) -> StakeLockStatus:
  stake_lock_from_ge(Nat.is_ge(now_sec, exp_sec), now_sec, exp_sec)

def stake_is_expired(+s: StakeLockStatus) -> Bool:
  match s:
    case StakeExpired{}:
      True{}
    case StakeLocked{_}:
      False{}

def stake_locked_secs(+s: StakeLockStatus) -> Nat:
  match s:
    case StakeExpired{}:
      0n
    case StakeLocked{secs}:
      secs

def can_collect_stake_rewards(+qsr_amount: Nat, +znn_amount: Nat) -> Bool:
  Nat.is_gt(qsr_amount, 0n)

def has_staking_reward_history(+entries: +List<Nat>) -> Bool:
  match entries:
    case Nil{}:
      False{}
    case Con{qsr, rest}:
      Bool.or(Nat.is_gt(qsr, 0n), has_staking_reward_history(rest))

def epoch_day(+genesis_day: Nat, +epoch: Nat) -> Nat:
  Nat.add(genesis_day, 1n+epoch)

# Parallelized multi-check helper (uses Bend parallel-let with named defs on RHS)
# -------------------------------------------------------------------------------

def parallel_plasma_staking_check(
  +qsr: Nat,
  +qsr_bal: Nat,
  +is_int: Bool,
  +valid_ben: Bool,
  +znn: Nat,
  +znn_bal: Nat,
  +months: Nat
) -> Bool:
  a b = can_fuse_plasma(qsr, qsr_bal, is_int, valid_ben) can_create_stake(znn, znn_bal, months)
  Bool.and(a, b)
