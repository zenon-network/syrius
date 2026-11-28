import Base

# Domain 2: Pillars & Sentinels protocol and UI-edge specification for Syrius.
#
# Exact Zenon protocol constants:
# - Pillar:   252,000 Plasma (252k), 15,000 ZNN locked (15k), dynamic QSR cost BURNED,
#             rewards ZNN-only, delegation requires >= 1 ZNN, producer != wallet seed,
#             reward splits in 0..100%.
# - Sentinel: 252,000 Plasma (252k),  5,000 ZNN locked (5k), 50,000 QSR locked/refundable (50k),
#             rewards dual-coin (ZNN + QSR), one active Sentinel per address, owner-only revoke.

type NodeRole is Data:
  RolePillar{}
  RoleSentinel{}

type CreateStep is Data:
  StepPlasma{}
  StepQsr{}
  StepZnn{}
  StepDeploy{}
  StepDone{}

type UpdateStep is Data:
  UpdDetails{}
  UpdRewards{}
  UpdSubmit{}
  UpdDone{}

type DelegationState is Data:
  NotDelegated{}
  Delegated{pillar_id: Nat, status: Nat}

type SentinelAuth is Data:
  SentinelAuth{can_spawn: Bool, show_timer: Bool, can_revoke: Bool}

type RewardEntry is Data:
  RewardEntry{znn: Nat, qsr: Nat}

# Role constants (kilo-units for Nat + exact U32)
# -----------------------------------------------

def role_plasma_req_k(+role: NodeRole) -> Nat:
  match role:
    case RolePillar{}:
      252n
    case RoleSentinel{}:
      252n

def role_plasma_req_u32(+role: NodeRole) -> U32:
  match role:
    case RolePillar{}:
      252000
    case RoleSentinel{}:
      252000

def role_znn_collateral_k(+role: NodeRole) -> Nat:
  match role:
    case RolePillar{}:
      15n
    case RoleSentinel{}:
      5n

def role_znn_collateral_u32(+role: NodeRole) -> U32:
  match role:
    case RolePillar{}:
      15000
    case RoleSentinel{}:
      5000

def sentinel_qsr_cost_k() -> Nat:
  50n

def sentinel_qsr_cost_u32() -> U32:
  50000

def role_qsr_burned(+role: NodeRole) -> Bool:
  match role:
    case RolePillar{}:
      True{}
    case RoleSentinel{}:
      False{}

# Unified 4-step Create Pillar / Create Sentinel stepper
# ------------------------------------------------------

def create_step_rank(+s: CreateStep) -> Nat:
  match s:
    case StepPlasma{}:
      0n
    case StepQsr{}:
      1n
    case StepZnn{}:
      2n
    case StepDeploy{}:
      3n
    case StepDone{}:
      4n

def pick_create_step(+ok: Bool, +next: CreateStep, +stay: CreateStep) -> CreateStep:
  match ok:
    case True{}:
      next
    case False{}:
      stay

def advance_create_step(
  +step: CreateStep,
  +plasma: Nat,
  +plasma_req: Nat,
  +deposit: Nat,
  +qsr_cost: Nat,
  +znn_bal: Nat,
  +znn_req: Nat,
  +deploy_valid: Bool
) -> CreateStep:
  match step:
    case StepPlasma{}:
      pick_create_step(Nat.is_ge(plasma, plasma_req), StepQsr{}, StepPlasma{})
    case StepQsr{}:
      pick_create_step(Nat.is_ge(deposit, qsr_cost), StepZnn{}, StepQsr{})
    case StepZnn{}:
      pick_create_step(Nat.is_ge(znn_bal, znn_req), StepDeploy{}, StepZnn{})
    case StepDeploy{}:
      pick_create_step(deploy_valid, StepDone{}, StepDeploy{})
    case StepDone{}:
      StepDone{}

# QSR deposit/withdraw arithmetic & confirmation polling predicates
# -----------------------------------------------------------------

def qsr_remaining(+cost: Nat, +deposit: Nat) -> Nat:
  Nat.sub(cost, deposit)

def max_qsr_deposit(+bal: Nat, +cost: Nat, +deposit: Nat) -> Nat:
  Nat.min(bal, Nat.sub(cost, deposit))

def qsr_covered(+deposit: Nat, +cost: Nat) -> Bool:
  Nat.is_ge(deposit, cost)

def can_withdraw_qsr(+deposit: Nat) -> Bool:
  Nat.is_gt(deposit, 0n)

def clamped_qsr_deposit(+cost: Nat, +deposit: Nat) -> Nat:
  Nat.min(deposit, cost)

# Normative confirmation contract: requires strictly positive deposit amount
# (enforced by UI input validator; PillarDepositQsrBloc/SentinelDepositQsrBloc
# themselves do not re-check event.amount > 0).
def is_deposit_confirmed(+initial: Nat, +amount: Nat, +observed: Nat) -> Bool:
  Bool.and(Nat.is_gt(amount, 0n), Nat.is_ge(observed, Nat.add(initial, amount)))

def is_withdraw_confirmed(+has_initial: Bool, +initial: Nat, +observed: Nat) -> Bool:
  match has_initial:
    case True{}:
      Bool.and(Nat.is_gt(initial, 0n), Nat.is_lt(observed, initial))
    case False{}:
      Nat.is_eq(observed, 0n)

# Pillar Update 3-step machine, producer/reward validation & reward split conservation
# ------------------------------------------------------------------------------------

def valid_pillar_producer(+addr_valid: Bool, +in_wallet_addresses: Bool) -> Bool:
  Bool.and(addr_valid, Bool.not(in_wallet_addresses))

def valid_reward_pct(+pct: Nat) -> Bool:
  Nat.is_le(pct, 100n)

def owner_reward_pct(+delegate_pct: Nat) -> Nat:
  Nat.sub(100n, delegate_pct)

def valid_pillar_deploy(
  +name_valid: Bool,
  +name_available: Bool,
  +reward_valid: Bool,
  +prod_valid: Bool,
  +prod_in_wallet: Bool,
  +mom_pct: Nat,
  +del_pct: Nat
) -> Bool:
  Bool.and(
    name_valid,
    Bool.and(
      name_available,
      Bool.and(
        reward_valid,
        Bool.and(
          valid_pillar_producer(prod_valid, prod_in_wallet),
          Bool.and(valid_reward_pct(mom_pct), valid_reward_pct(del_pct))))))

def pick_update_step(+ok: Bool, +next: UpdateStep, +stay: UpdateStep) -> UpdateStep:
  match ok:
    case True{}:
      next
    case False{}:
      stay

def advance_update_step(+step: UpdateStep, +details_valid: Bool, +rewards_valid: Bool, +submit_ok: Bool) -> UpdateStep:
  match step:
    case UpdDetails{}:
      pick_update_step(details_valid, UpdRewards{}, UpdDetails{})
    case UpdRewards{}:
      pick_update_step(rewards_valid, UpdSubmit{}, UpdRewards{})
    case UpdSubmit{}:
      pick_update_step(submit_ok, UpdDone{}, UpdSubmit{})
    case UpdDone{}:
      UpdDone{}

def update_step_rank(+step: UpdateStep) -> Nat:
  match step:
    case UpdDetails{}:
      0n
    case UpdRewards{}:
      1n
    case UpdSubmit{}:
      2n
    case UpdDone{}:
      3n

def back_update_step(+step: UpdateStep) -> UpdateStep:
  match step:
    case UpdDetails{}:
      UpdDetails{}
    case UpdRewards{}:
      UpdDetails{}
    case UpdSubmit{}:
      UpdRewards{}
    case UpdDone{}:
      UpdDone{}

# Safe momentum uptime percentage (prevents 0/0 NaN and >0/0 Infinity crash;
# uses exact half-away-from-zero rounding matching Dart's (produced / expected * 100).round())
# --------------------------------------------------------------------------------------------

def safe_uptime_pct(+produced: Nat, +expected: Nat) -> Nat:
  match expected:
    case 0n:
      0n
    case 1n+ep:
      Nat.div(Nat.add(Nat.mul(produced, 200n), 1n+ep), Nat.mul(2n, 1n+ep))

# Delegation eligibility & state transitions
# ------------------------------------------

def can_delegate(+znn_bal: Nat) -> Bool:
  Nat.is_ge(znn_bal, 1n)

def delegation_is_active(+d: DelegationState) -> Bool:
  match d:
    case NotDelegated{}:
      False{}
    case Delegated{_, status}:
      Nat.is_eq(status, 1n)

def undelegate_state(+d: DelegationState) -> DelegationState:
  NotDelegated{}

# Sentinel authorization matrix
# -----------------------------

def sentinel_auth(+is_owner: Bool, +is_revocable: Bool, +has_active: Bool) -> SentinelAuth:
  SentinelAuth{Bool.not(has_active), is_owner, Bool.and(is_owner, is_revocable)}

def auth_can_spawn(+a: SentinelAuth) -> Bool:
  match a:
    case SentinelAuth{cs, _, _}:
      cs

def auth_show_timer(+a: SentinelAuth) -> Bool:
  match a:
    case SentinelAuth{_, st, _}:
      st

def auth_can_revoke(+a: SentinelAuth) -> Bool:
  match a:
    case SentinelAuth{_, _, cr}:
      cr

# Reward collectability & history gates (Pillar ZNN-only vs Sentinel dual-coin)
# -----------------------------------------------------------------------------

def can_collect_rewards(+role: NodeRole, +znn: Nat, +qsr: Nat) -> Bool:
  match role:
    case RolePillar{}:
      Nat.is_gt(znn, 0n)
    case RoleSentinel{}:
      Bool.or(Nat.is_gt(znn, 0n), Nat.is_gt(qsr, 0n))

def has_reward_history(+role: NodeRole, +entries: +List<RewardEntry>) -> Bool:
  match entries:
    case Nil{}:
      False{}
    case Con{RewardEntry{znn, qsr}, rest}:
      Bool.or(can_collect_rewards(role, znn, qsr), has_reward_history(role, rest))

# Parallelized multi-check helper (3-way Bend parallel-let with named defs on RHS)
# --------------------------------------------------------------------------------

def meets_req(+have: Nat, +need: Nat) -> Bool:
  Nat.is_ge(have, need)

def parallel_spawn_readiness(
  +plasma: Nat,
  +plasma_req: Nat,
  +deposit: Nat,
  +qsr_cost: Nat,
  +znn_bal: Nat,
  +znn_req: Nat
) -> Bool:
  p q z = meets_req(plasma, plasma_req) qsr_covered(deposit, qsr_cost) meets_req(znn_bal, znn_req)
  Bool.and(p, Bool.and(q, z))
