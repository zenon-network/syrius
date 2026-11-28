import Base

# Syrius P2P HTLC Swap Formal Verification Model
# ==============================================
#
# Unit Scaling Convention (for conformance tests):
# - All HTLC duration / timestamp / cooldown quantities use 1-minute units
#   (1 Nat unit = 60 seconds). Every Syrius timelock constant is an exact
#   integer multiple of 60 seconds:
#     INITIAL_HTLC_DURATION     = 480  (8 hours  = 28,800s)
#     COUNTER_HTLC_DURATION     =  60  (1 hour   =  3,600s)
#     MAX_INITIAL_HTLC_DURATION = 1440 (24 hours = 86,400s)
#     MIN_SAFE_FIND_PREIMAGE    = 360  (6 hours  = 21,600s)
#     MIN_SAFE_COMPLETE_SWAP    =  10  (10 mins  =    600s)
#     AUTO_UNLOCK_COOLDOWN      =   2  (2 mins   =    120s)
# - Conformance callers convert seconds <-> model units via exact multiples
#   of 60s (or call the parametric *_with helpers directly with arbitrary units).
# - Address lookahead limit: RECLAIM_LOOKAHEAD_LIMIT = 50 addresses.
# - SQLCipher encryption key length: SQLCIPHER_KEY_LEN = 32 bytes.
# - Error sanitizer unwrap bound: SANITIZER_MAX_DEPTH = 5 iterations (<= 4 wrappers).
# - Maximum stored swaps cap: MAX_STORED_SWAPS = 500 entries.

# ------------------------------------------------------------------------------
# 1. Constants (1-minute time units)
# ------------------------------------------------------------------------------

def INITIAL_HTLC_DURATION() -> Nat:
  Nat.mul(8n, 60n)

def COUNTER_HTLC_DURATION() -> Nat:
  60n

def MAX_INITIAL_HTLC_DURATION() -> Nat:
  Nat.mul(24n, 60n)

def MIN_SAFE_FIND_PREIMAGE() -> Nat:
  Nat.mul(6n, 60n)

def MIN_SAFE_COMPLETE_SWAP() -> Nat:
  10n

def AUTO_UNLOCK_COOLDOWN() -> Nat:
  2n

def RECLAIM_LOOKAHEAD_LIMIT() -> Nat:
  50n

def SQLCIPHER_KEY_LEN() -> Nat:
  32n

def SANITIZER_MAX_DEPTH() -> Nat:
  5n

def MAX_STORED_SWAPS() -> Nat:
  Nat.mul(5n, 100n)

# ------------------------------------------------------------------------------
# 2. HTLC Timelock & Safe-Join Window Algebra
# ------------------------------------------------------------------------------

type JoinError is Data:
  ErrNotForYou{}
  ErrOwnSwap{}
  ErrAlreadyUsed{}
  ErrExpired{}
  ErrExpiresTooSoon{}
  ErrRemainingTooLong{}
  ErrCreationUnconfirmed{}
  ErrCreationDurationTooLong{}
  ErrDuplicateHashLock{}

type JoinValidation is Data:
  JoinOk{}
  JoinErr{reason: JoinError}

def remaining_time(+exp: Nat, +now: Nat) -> Nat:
  Nat.sub(exp, now)

def safe_join_min_remaining_with(+min_safe_find: Nat, +counter_dur: Nat) -> Nat:
  Nat.add(min_safe_find, counter_dur)

def safe_join_min_remaining() -> Nat:
  safe_join_min_remaining_with(MIN_SAFE_FIND_PREIMAGE(), COUNTER_HTLC_DURATION())

def can_safely_join_window_with(+exp: Nat, +now: Nat, +min_safe_find: Nat, +counter_dur: Nat) -> Bool:
  Nat.is_ge(Nat.sub(exp, now), Nat.add(min_safe_find, counter_dur))

def can_safely_join_window(+exp: Nat, +now: Nat) -> Bool:
  can_safely_join_window_with(exp, now, MIN_SAFE_FIND_PREIMAGE(), COUNTER_HTLC_DURATION())

def counter_expiration_with(+now: Nat, +counter_dur: Nat) -> Nat:
  Nat.add(now, counter_dur)

def counter_expiration(+now: Nat) -> Nat:
  counter_expiration_with(now, COUNTER_HTLC_DURATION())

def can_unlock_with(+exp: Nat, +now: Nat, +min_safe_complete: Nat) -> Bool:
  Nat.is_gt(exp, Nat.add(now, min_safe_complete))

def can_unlock(+exp: Nat, +now: Nat) -> Bool:
  can_unlock_with(exp, now, MIN_SAFE_COMPLETE_SWAP())

def can_reclaim(+exp: Nat, +now: Nat) -> Bool:
  Nat.is_le(exp, now)

def is_sync_expired_counter(+now: Nat, +counter_exp: Maybe<&2, Nat>) -> Bool:
  match counter_exp:
    case None{}:
      False{}
    case Some{ce}:
      Nat.is_lt(ce, Nat.add(now, MIN_SAFE_COMPLETE_SWAP()))

def is_sync_expired(+init_exp: Nat, +counter_exp: Maybe<&2, Nat>, +now: Nat) -> Bool:
  Bool.or(Nat.is_lt(init_exp, now), is_sync_expired_counter(now, counter_exp))

def join_validation_is_ok(+r: JoinValidation) -> Bool:
  match r:
    case JoinOk{}:
      True{}
    case JoinErr{_}:
      False{}

def validate_join.step8(+onchain_conflict: Bool) -> JoinValidation:
  match onchain_conflict:
    case True{}:
      JoinErr{ErrDuplicateHashLock{}}
    case False{}:
      JoinOk{}

def validate_join.step7(+creation_ok: Bool, +onchain_conflict: Bool) -> JoinValidation:
  match creation_ok:
    case False{}:
      JoinErr{ErrCreationDurationTooLong{}}
    case True{}:
      validate_join.step8(onchain_conflict)

def validate_join.step6(+creation_confirmed: Bool, +exp: Nat, +created: Nat, +max_initial: Nat, +onchain_conflict: Bool) -> JoinValidation:
  match creation_confirmed:
    case False{}:
      JoinErr{ErrCreationUnconfirmed{}}
    case True{}:
      validate_join.step7(Nat.is_le(Nat.sub(exp, created), max_initial), onchain_conflict)

def validate_join.step5(+rem_within_max: Bool, +creation_confirmed: Bool, +exp: Nat, +created: Nat, +max_initial: Nat, +onchain_conflict: Bool) -> JoinValidation:
  match rem_within_max:
    case False{}:
      JoinErr{ErrRemainingTooLong{}}
    case True{}:
      validate_join.step6(creation_confirmed, exp, created, max_initial, onchain_conflict)

def validate_join.step4(+safe_win: Bool, +exp: Nat, +now: Nat, +created: Nat, +creation_confirmed: Bool, +max_initial: Nat, +onchain_conflict: Bool) -> JoinValidation:
  match safe_win:
    case False{}:
      JoinErr{ErrExpiresTooSoon{}}
    case True{}:
      validate_join.step5(Nat.is_le(Nat.sub(exp, now), max_initial), creation_confirmed, exp, created, max_initial, onchain_conflict)

def validate_join.step3(+not_expired: Bool, +exp: Nat, +now: Nat, +created: Nat, +creation_confirmed: Bool, +min_safe_find: Nat, +counter_dur: Nat, +max_initial: Nat, +onchain_conflict: Bool) -> JoinValidation:
  match not_expired:
    case False{}:
      JoinErr{ErrExpired{}}
    case True{}:
      validate_join.step4(can_safely_join_window_with(exp, now, min_safe_find, counter_dur), exp, now, created, creation_confirmed, max_initial, onchain_conflict)

def validate_join.step2(+locally_used: Bool, +exp: Nat, +now: Nat, +created: Nat, +creation_confirmed: Bool, +min_safe_find: Nat, +counter_dur: Nat, +max_initial: Nat, +onchain_conflict: Bool) -> JoinValidation:
  match locally_used:
    case True{}:
      JoinErr{ErrAlreadyUsed{}}
    case False{}:
      validate_join.step3(Nat.is_gt(Nat.sub(exp, now), 0n), exp, now, created, creation_confirmed, min_safe_find, counter_dur, max_initial, onchain_conflict)

def validate_join.step1(+time_locked_is_mine: Bool, +locally_used: Bool, +exp: Nat, +now: Nat, +created: Nat, +creation_confirmed: Bool, +min_safe_find: Nat, +counter_dur: Nat, +max_initial: Nat, +onchain_conflict: Bool) -> JoinValidation:
  match time_locked_is_mine:
    case True{}:
      JoinErr{ErrOwnSwap{}}
    case False{}:
      validate_join.step2(locally_used, exp, now, created, creation_confirmed, min_safe_find, counter_dur, max_initial, onchain_conflict)

def validate_join_htlc_with(
  +hash_locked_is_mine: Bool,
  +time_locked_is_mine: Bool,
  +locally_used: Bool,
  +exp: Nat,
  +now: Nat,
  +created: Nat,
  +creation_confirmed: Bool,
  +onchain_conflict: Bool,
  +min_safe_find: Nat,
  +counter_dur: Nat,
  +max_initial: Nat
) -> JoinValidation:
  match hash_locked_is_mine:
    case False{}:
      JoinErr{ErrNotForYou{}}
    case True{}:
      validate_join.step1(time_locked_is_mine, locally_used, exp, now, created, creation_confirmed, min_safe_find, counter_dur, max_initial, onchain_conflict)

def validate_join_htlc(
  +hash_locked_is_mine: Bool,
  +time_locked_is_mine: Bool,
  +locally_used: Bool,
  +exp: Nat,
  +now: Nat,
  +created: Nat,
  +creation_confirmed: Bool,
  +onchain_conflict: Bool
) -> JoinValidation:
  validate_join_htlc_with(
    hash_locked_is_mine,
    time_locked_is_mine,
    locally_used,
    exp,
    now,
    created,
    creation_confirmed,
    onchain_conflict,
    MIN_SAFE_FIND_PREIMAGE(),
    COUNTER_HTLC_DURATION(),
    MAX_INITIAL_HTLC_DURATION()
  )

def is_safe_join(
  +hash_locked_is_mine: Bool,
  +time_locked_is_mine: Bool,
  +locally_used: Bool,
  +exp: Nat,
  +now: Nat,
  +created: Nat,
  +creation_confirmed: Bool,
  +onchain_conflict: Bool
) -> Bool:
  join_validation_is_ok(validate_join_htlc(
    hash_locked_is_mine,
    time_locked_is_mine,
    locally_used,
    exp,
    now,
    created,
    creation_confirmed,
    onchain_conflict
  ))

# ------------------------------------------------------------------------------
# 3. 6-State Swap Lifecycle Automaton
# ------------------------------------------------------------------------------

type SwapState is Data:
  Pending{}
  Active{}
  Completed{}
  Reclaimable{}
  Unsuccessful{}
  Error{}

type SwapDir is Data:
  Outgoing{}
  Incoming{}

type HtlcRole is Data:
  InitialHtlc{}
  CounterHtlc{}

type SwapRecord is Data:
  SwapRec{dir: SwapDir, state: SwapState, has_counter: Bool, has_preimage: Bool}

type SwapEvent is Data:
  EvCreate{is_counter: Bool, counter_valid: Bool}
  EvUnlock{target: HtlcRole, has_descendants: Bool, preimage_present: Bool}
  EvReclaim{target: HtlcRole, has_descendants: Bool}
  EvExpire{}

def swap_state_eq(+a: SwapState, +b: SwapState) -> Bool:
  match a b:
    case Pending{} Pending{}:
      True{}
    case Active{} Active{}:
      True{}
    case Completed{} Completed{}:
      True{}
    case Reclaimable{} Reclaimable{}:
      True{}
    case Unsuccessful{} Unsuccessful{}:
      True{}
    case Error{} Error{}:
      True{}
    case _ _:
      False{}

def htlc_role_eq(+a: HtlcRole, +b: HtlcRole) -> Bool:
  match a b:
    case InitialHtlc{} InitialHtlc{}:
      True{}
    case CounterHtlc{} CounterHtlc{}:
      True{}
    case _ _:
      False{}

def swap_dir_eq(+a: SwapDir, +b: SwapDir) -> Bool:
  match a b:
    case Outgoing{} Outgoing{}:
      True{}
    case Incoming{} Incoming{}:
      True{}
    case _ _:
      False{}

def swap_state(+rec: SwapRecord) -> SwapState:
  match rec:
    case SwapRec{_, st, _, _}:
      st

def swap_has_preimage(+rec: SwapRecord) -> Bool:
  match rec:
    case SwapRec{_, _, _, hp}:
      hp

def start_outgoing_swap() -> SwapRecord:
  SwapRec{Outgoing{}, Pending{}, False{}, True{}}

def join_incoming_swap() -> SwapRecord:
  SwapRec{Incoming{}, Active{}, True{}, False{}}

def funded_htlc_role(+dir: SwapDir) -> HtlcRole:
  match dir:
    case Outgoing{}:
      InitialHtlc{}
    case Incoming{}:
      CounterHtlc{}

def unlock_target_role(+dir: SwapDir) -> HtlcRole:
  match dir:
    case Outgoing{}:
      CounterHtlc{}
    case Incoming{}:
      InitialHtlc{}

def dir_for_funded_role(+role: HtlcRole) -> SwapDir:
  match role:
    case InitialHtlc{}:
      Outgoing{}
    case CounterHtlc{}:
      Incoming{}

def can_delete_swap(+s: SwapState) -> Bool:
  match s:
    case Completed{}:
      True{}
    case Unsuccessful{}:
      True{}
    case Error{}:
      True{}
    case Pending{}:
      False{}
    case Active{}:
      False{}
    case Reclaimable{}:
      False{}

def step_create(+dir: SwapDir, +st: SwapState, +hc: Bool, +hp: Bool, +is_counter: Bool, +counter_valid: Bool) -> SwapRecord:
  match st:
    case Pending{}:
      SwapRec{dir, Active{}, hc, hp}
    case Active{}:
      match hc is_counter counter_valid:
        case False{} True{} True{}:
          SwapRec{dir, Active{}, True{}, hp}
        case _ _ _:
          SwapRec{dir, Active{}, hc, hp}
    case s:
      SwapRec{dir, s, hc, hp}

def step_unlock.apply(+dir: SwapDir, +st: SwapState, +hc: Bool, +target: HtlcRole) -> SwapRecord:
  match dir st target:
    case Incoming{} _ InitialHtlc{}:
      SwapRec{Incoming{}, Completed{}, hc, True{}}
    case Outgoing{} Active{} CounterHtlc{}:
      SwapRec{Outgoing{}, Completed{}, hc, True{}}
    case d s _:
      SwapRec{d, s, hc, True{}}

def step_unlock(+dir: SwapDir, +st: SwapState, +hc: Bool, +hp: Bool, +target: HtlcRole, +has_desc: Bool, +preimage_present: Bool) -> SwapRecord:
  match hp has_desc preimage_present:
    case _ False{} _:
      SwapRec{dir, st, hc, hp}
    case False{} True{} False{}:
      SwapRec{dir, st, hc, False{}}
    case _ True{} _:
      step_unlock.apply(dir, st, hc, target)

def step_reclaim.apply(+dir: SwapDir, +st: SwapState, +hc: Bool, +hp: Bool, +matches: Bool) -> SwapRecord:
  match matches:
    case True{}:
      SwapRec{dir, Unsuccessful{}, hc, hp}
    case False{}:
      SwapRec{dir, st, hc, hp}

def step_reclaim(+dir: SwapDir, +st: SwapState, +hc: Bool, +hp: Bool, +target: HtlcRole, +has_desc: Bool) -> SwapRecord:
  match has_desc:
    case False{}:
      SwapRec{dir, st, hc, hp}
    case True{}:
      step_reclaim.apply(dir, st, hc, hp, htlc_role_eq(target, funded_htlc_role(dir)))

def step_expire(+dir: SwapDir, +st: SwapState, +hc: Bool, +hp: Bool) -> SwapRecord:
  match st:
    case Pending{}:
      SwapRec{dir, Reclaimable{}, hc, hp}
    case Active{}:
      SwapRec{dir, Reclaimable{}, hc, hp}
    case s:
      SwapRec{dir, s, hc, hp}

def step_swap.dispatch(+dir: SwapDir, +st: SwapState, +hc: Bool, +hp: Bool, +ev: SwapEvent) -> SwapRecord:
  match ev:
    case EvCreate{ic, cv}:
      step_create(dir, st, hc, hp, ic, cv)
    case EvUnlock{tgt, desc, pp}:
      step_unlock(dir, st, hc, hp, tgt, desc, pp)
    case EvReclaim{tgt, desc}:
      step_reclaim(dir, st, hc, hp, tgt, desc)
    case EvExpire{}:
      step_expire(dir, st, hc, hp)

# Normative spec: Completed is strictly terminal-absorbing (note: current
# HtlcSwapSyncService._getReclaimUpdate omits a terminal Completed guard,
# tracked as an audit finding in docs/BEND_LAWS.md).
def step_swap(+rec: SwapRecord, +ev: SwapEvent) -> SwapRecord:
  match rec:
    case SwapRec{dir, Completed{}, hc, hp}:
      SwapRec{dir, Completed{}, hc, hp}
    case SwapRec{dir, st, hc, hp}:
      step_swap.dispatch(dir, st, hc, hp, ev)

# ------------------------------------------------------------------------------
# 4. Reclaim Address Lookahead Machine (ReclaimDepositBloc)
# ------------------------------------------------------------------------------

type ReclaimOutcome is Data:
  ReclaimOk{derived_count: Nat}
  ReclaimErrNotMine{}
  ReclaimErrHwMissing{}
  ReclaimErrStillLocked{}

def reclaim_is_ok(+o: ReclaimOutcome) -> Bool:
  match o:
    case ReclaimOk{_}:
      True{}
    case _:
      False{}

def reclaim_derived_count(+o: ReclaimOutcome) -> Nat:
  match o:
    case ReclaimOk{n}:
      n
    case _:
      0n

def reclaim.check_exp(+expired: Bool, +derive_count: Nat) -> ReclaimOutcome:
  match expired:
    case False{}:
      ReclaimErrStillLocked{}
    case True{}:
      ReclaimOk{derive_count}

def reclaim.check_window(+in_window: Bool, +idx: Nat, +wallet_len: Nat, +exp: Nat, +now: Nat) -> ReclaimOutcome:
  match in_window:
    case False{}:
      ReclaimErrNotMine{}
    case True{}:
      reclaim.check_exp(can_reclaim(exp, now), 1n+Nat.sub(idx, wallet_len))

def reclaim.scan_sw(+derived_match: Maybe<&2, Nat>, +wallet_len: Nat, +lookahead: Nat, +exp: Nat, +now: Nat) -> ReclaimOutcome:
  match derived_match:
    case None{}:
      ReclaimErrNotMine{}
    case Some{idx}:
      reclaim.check_window(
        Bool.and(Nat.is_le(wallet_len, idx), Nat.is_lt(idx, Nat.add(wallet_len, lookahead))),
        idx,
        wallet_len,
        exp,
        now
      )

def reclaim.resolve_missing(+has_wallet: Bool, +is_hw: Bool, +wallet_len: Nat, +lookahead: Nat, +derived_match: Maybe<&2, Nat>, +exp: Nat, +now: Nat) -> ReclaimOutcome:
  match has_wallet is_hw:
    case False{} _:
      ReclaimErrNotMine{}
    case True{} True{}:
      ReclaimErrHwMissing{}
    case True{} False{}:
      reclaim.scan_sw(derived_match, wallet_len, lookahead, exp, now)

def evaluate_reclaim_with(
  +in_wallet: Bool,
  +has_wallet: Bool,
  +is_hw: Bool,
  +wallet_len: Nat,
  +lookahead: Nat,
  +derived_match: Maybe<&2, Nat>,
  +exp: Nat,
  +now: Nat
) -> ReclaimOutcome:
  match in_wallet:
    case True{}:
      reclaim.check_exp(can_reclaim(exp, now), 0n)
    case False{}:
      reclaim.resolve_missing(has_wallet, is_hw, wallet_len, lookahead, derived_match, exp, now)

def evaluate_reclaim(
  +in_wallet: Bool,
  +has_wallet: Bool,
  +is_hw: Bool,
  +wallet_len: Nat,
  +derived_match: Maybe<&2, Nat>,
  +exp: Nat,
  +now: Nat
) -> ReclaimOutcome:
  evaluate_reclaim_with(in_wallet, has_wallet, is_hw, wallet_len, RECLAIM_LOOKAHEAD_LIMIT(), derived_match, exp, now)

# ------------------------------------------------------------------------------
# 5. Auto-Unlock Single-Flight Mutex & 2-Min Cooldown Arbiter
# ------------------------------------------------------------------------------

type AutoUnlockState is Data:
  AutoUnlock{is_unlocking: Bool, last_attempt: Maybe<&2, Nat>}

type AutoUnlockStep is Data:
  UnlockStep{started: Bool, next_state: AutoUnlockState}

def is_in_cooldown(+last_attempt: Maybe<&2, Nat>, +now: Nat) -> Bool:
  match last_attempt:
    case None{}:
      False{}
    case Some{t}:
      Nat.is_lt(Nat.sub(now, t), AUTO_UNLOCK_COOLDOWN())

def auto_unlock.after_prune(+in_cd: Bool, +last_attempt: Maybe<&2, Nat>, +node_synced: Bool, +now: Nat) -> AutoUnlockStep:
  match in_cd node_synced:
    case True{} _:
      UnlockStep{False{}, AutoUnlock{False{}, last_attempt}}
    case False{} False{}:
      UnlockStep{False{}, AutoUnlock{False{}, None{}}}
    case False{} True{}:
      UnlockStep{True{}, AutoUnlock{True{}, Some{now}}}

def try_start_auto_unlock(+st: AutoUnlockState, +wallet_open: Bool, +node_synced: Bool, +now: Nat) -> AutoUnlockStep:
  match st:
    case AutoUnlock{is_u, last}:
      match is_u wallet_open:
        case True{} _:
          UnlockStep{False{}, AutoUnlock{True{}, last}}
        case False{} False{}:
          UnlockStep{False{}, AutoUnlock{False{}, last}}
        case False{} True{}:
          auto_unlock.after_prune(is_in_cooldown(last, now), last, node_synced, now)

def finish_auto_unlock(+st: AutoUnlockState) -> AutoUnlockState:
  match st:
    case AutoUnlock{_, last}:
      AutoUnlock{False{}, last}

def unlock_step_started(+s: AutoUnlockStep) -> Bool:
  match s:
    case UnlockStep{b, _}:
      b

def unlock_step_state(+s: AutoUnlockStep) -> AutoUnlockState:
  match s:
    case UnlockStep{_, st}:
      st

def auto_unlock_is_busy(+st: AutoUnlockState) -> Bool:
  match st:
    case AutoUnlock{b, _}:
      b

# ------------------------------------------------------------------------------
# 6. Drift Persistence, Pruning, 2-Phase Atomic SQLCipher Rekey,
#    Legacy Migration & Error Sanitizer
# ------------------------------------------------------------------------------

def is_valid_sqlcipher_key(+key_len: Nat, +all_bytes_in_range: Bool) -> Bool:
  Bool.and(Nat.is_eq(key_len, SQLCIPHER_KEY_LEN()), all_bytes_in_range)

def can_write_processed_block(+active_chain: Nat, +updated_chain: Maybe<&2, Nat>) -> Bool:
  match updated_chain:
    case None{}:
      True{}
    case Some{c}:
      Nat.is_eq(c, active_chain)

def is_prunable_state(+s: SwapState) -> Bool:
  match s:
    case Completed{}:
      True{}
    case Unsuccessful{}:
      True{}
    case _:
      False{}

def should_evict_swap(+total_count: Nat, +max_swaps: Nat, +swap_chain: Nat, +prune_chain: Maybe<&2, Nat>, +st: SwapState) -> Bool:
  match prune_chain:
    case None{}:
      False{}
    case Some{pc}:
      Bool.and(
        Nat.is_gt(total_count, max_swaps),
        Bool.and(Nat.is_eq(swap_chain, pc), is_prunable_state(st))
      )

type FileState is Data:
  NoFile{}
  EncFile{key: Nat}

type StorageState is Data:
  Storage{is_open: Bool, open_key: Nat, primary: FileState, backup: FileState, sync_running: Bool}

type ChangePwdResult is Data:
  ChgPwdRes{succeeded: Bool, storage: StorageState}

def file_has_key(+f: FileState, +k: Nat) -> Bool:
  match f:
    case NoFile{}:
      False{}
    case EncFile{fk}:
      Nat.is_eq(fk, k)

def file_is_none(+f: FileState) -> Bool:
  match f:
    case NoFile{}:
      True{}
    case EncFile{_}:
      False{}

def storage_is_open(+st: StorageState) -> Bool:
  match st:
    case Storage{is_o, _, _, _, _}:
      is_o

def storage_open_key(+st: StorageState) -> Nat:
  match st:
    case Storage{_, ok, _, _, _}:
      ok

def storage_primary(+st: StorageState) -> FileState:
  match st:
    case Storage{_, _, prim, _, _}:
      prim

def storage_backup(+st: StorageState) -> FileState:
  match st:
    case Storage{_, _, _, bak, _}:
      bak

def storage_sync_running(+st: StorageState) -> Bool:
  match st:
    case Storage{_, _, _, _, sync_r}:
      sync_r

def storage_set_sync(+st: StorageState, +sync_r: Bool) -> StorageState:
  match st:
    case Storage{is_o, ok, prim, bak, _}:
      Storage{is_o, ok, prim, bak, sync_r}

def chg_pwd_succeeded(+r: ChangePwdResult) -> Bool:
  match r:
    case ChgPwdRes{s, _}:
      s

def chg_pwd_storage(+r: ChangePwdResult) -> StorageState:
  match r:
    case ChgPwdRes{_, st}:
      st

type BeginRekeyResult is Data:
  BeginRekeyRes{rekey_ok: Bool, storage: StorageState}

def begin_rekey_storage(+r: BeginRekeyResult) -> StorageState:
  match r:
    case BeginRekeyRes{_, st}:
      st

def begin_rekey(+st: StorageState, +old_k: Nat, +new_k: Nat, +rekey_ok: Bool) -> BeginRekeyResult:
  match st:
    case Storage{_, _, _, _, sync_r}:
      match rekey_ok:
        case True{}:
          BeginRekeyRes{True{}, Storage{True{}, new_k, EncFile{new_k}, EncFile{old_k}, sync_r}}
        case False{}:
          BeginRekeyRes{False{}, Storage{True{}, old_k, EncFile{old_k}, NoFile{}, sync_r}}

def commit_rekey(+st: StorageState) -> StorageState:
  match st:
    case Storage{is_o, ok, prim, _, sync_r}:
      Storage{is_o, ok, prim, NoFile{}, sync_r}

def rollback_rekey(+st: StorageState, +old_k: Nat) -> StorageState:
  match st:
    case Storage{_, _, _, bak, sync_r}:
      match bak:
        case NoFile{}:
          Storage{False{}, old_k, NoFile{}, NoFile{}, sync_r}
        case EncFile{bk}:
          Storage{True{}, old_k, EncFile{bk}, NoFile{}, sync_r}

def change_password.finish(+ok: Bool, +st1: StorageState, +old_k: Nat, +wallet_pwd_ok: Bool) -> ChangePwdResult:
  match ok wallet_pwd_ok:
    case False{} _:
      ChgPwdRes{False{}, storage_set_sync(st1, True{})}
    case True{} False{}:
      ChgPwdRes{False{}, storage_set_sync(rollback_rekey(st1, old_k), True{})}
    case True{} True{}:
      ChgPwdRes{True{}, storage_set_sync(commit_rekey(st1), True{})}

def change_password.after_rekey(+rekey_res: BeginRekeyResult, +old_k: Nat, +wallet_pwd_ok: Bool) -> ChangePwdResult:
  match rekey_res:
    case BeginRekeyRes{ok, st1}:
      change_password.finish(ok, st1, old_k, wallet_pwd_ok)

def change_password_txn(+st: StorageState, +old_k: Nat, +new_k: Nat, +rekey_ok: Bool, +wallet_pwd_ok: Bool) -> ChangePwdResult:
  change_password.after_rekey(
    begin_rekey(storage_set_sync(st, False{}), old_k, new_k, rekey_ok),
    old_k,
    wallet_pwd_ok
  )

def open.try_backup_match(+matched: Bool, +prim: FileState, +bk: Nat, +key: Nat, +sync_r: Bool) -> StorageState:
  match matched:
    case True{}:
      Storage{True{}, key, EncFile{key}, NoFile{}, sync_r}
    case False{}:
      Storage{False{}, 0n, prim, EncFile{bk}, sync_r}

def open.try_backup(+prim: FileState, +bak: FileState, +key: Nat, +sync_r: Bool) -> StorageState:
  match bak:
    case NoFile{}:
      Storage{False{}, 0n, prim, NoFile{}, sync_r}
    case EncFile{bk}:
      open.try_backup_match(Nat.is_eq(bk, key), prim, bk, key, sync_r)

def open.check_primary(+matches: Bool, +prim: FileState, +bak: FileState, +key: Nat, +sync_r: Bool) -> StorageState:
  match matches:
    case True{}:
      Storage{True{}, key, EncFile{key}, NoFile{}, sync_r}
    case False{}:
      open.try_backup(prim, bak, key, sync_r)

def open_with_recovery(+prim: FileState, +bak: FileState, +key: Nat, +sync_r: Bool) -> StorageState:
  match prim:
    case NoFile{}:
      open.try_backup(NoFile{}, bak, key, sync_r)
    case EncFile{pk}:
      open.check_primary(Nat.is_eq(pk, key), EncFile{pk}, bak, key, sync_r)

# Legacy Hive Migration
def insert_or_ignore(+existing: Maybe<&2, Nat>, +legacy_val: Nat) -> Nat:
  match existing:
    case Some{v}:
      v
    case None{}:
      legacy_val

def should_delete_hive_box(+failed_count: Nat) -> Bool:
  Nat.is_eq(failed_count, 0n)

# Error Sanitizer (max 5 unwrap steps, zero raw secret / preimage leakage)
type SwapError is Data:
  SqliteErr{code: Nat, raw_secret: Nat}
  RpcErr{code: Nat, raw_secret: Nat}
  DriftWrap{inner: SwapError, raw_secret: Nat}
  RollbackWrap{inner: SwapError, raw_secret: Nat}
  OtherErr{raw_secret: Nat}

type SanitizedSummary is Data:
  SummarySqlite{wrapped: Bool, code: Nat}
  SummaryRpc{code: Nat}
  SummaryTypeOnly{}

def unwrap_sqlite(fuel: Nat, err: SwapError) -> Maybe<&2, Nat>:
  match fuel:
    case 0n:
      None{}
    case 1n+p:
      match err:
        case SqliteErr{code, _}:
          Some{code}
        case DriftWrap{inner, _}:
          unwrap_sqlite(p, inner)
        case RollbackWrap{inner, _}:
          unwrap_sqlite(p, inner)
        case _:
          None{}

def is_direct_sqlite(+err: SwapError) -> Bool:
  match err:
    case SqliteErr{_, _}:
      True{}
    case _:
      False{}

def sanitize.finish(+unwrapped: Maybe<&2, Nat>, +direct: Bool, +err: SwapError) -> SanitizedSummary:
  match unwrapped:
    case Some{code}:
      SummarySqlite{Bool.not(direct), code}
    case None{}:
      match err:
        case RpcErr{code, _}:
          SummaryRpc{code}
        case _:
          SummaryTypeOnly{}

def sanitize_error(+err: SwapError) -> SanitizedSummary:
  sanitize.finish(unwrap_sqlite(SANITIZER_MAX_DEPTH(), err), is_direct_sqlite(err), err)

def replace_secrets(err: SwapError, +new_secret: Nat) -> SwapError:
  match err:
    case SqliteErr{code, _}:
      SqliteErr{code, new_secret}
    case RpcErr{code, _}:
      RpcErr{code, new_secret}
    case DriftWrap{inner, _}:
      DriftWrap{replace_secrets(inner, new_secret), new_secret}
    case RollbackWrap{inner, _}:
      RollbackWrap{replace_secrets(inner, new_secret), new_secret}
    case OtherErr{_}:
      OtherErr{new_secret}

# ------------------------------------------------------------------------------
# 7. Parallelized Multi-Check Helper (Bend parallel-let with named defs on RHS)
# ------------------------------------------------------------------------------

def check_swap_protocol_leg(
  +hash_locked_is_mine: Bool,
  +time_locked_is_mine: Bool,
  +locally_used: Bool,
  +exp: Nat,
  +now: Nat,
  +created: Nat,
  +creation_confirmed: Bool,
  +onchain_conflict: Bool
) -> Bool:
  is_safe_join(
    hash_locked_is_mine,
    time_locked_is_mine,
    locally_used,
    exp,
    now,
    created,
    creation_confirmed,
    onchain_conflict
  )

def check_swap_storage_leg(
  +key_len: Nat,
  +bytes_ok: Bool,
  +active_chain: Nat,
  +updated_chain: Maybe<&2, Nat>
) -> Bool:
  Bool.and(
    is_valid_sqlcipher_key(key_len, bytes_ok),
    can_write_processed_block(active_chain, updated_chain)
  )

def parallel_swap_safety_check(
  +hash_locked_is_mine: Bool,
  +time_locked_is_mine: Bool,
  +locally_used: Bool,
  +exp: Nat,
  +now: Nat,
  +created: Nat,
  +creation_confirmed: Bool,
  +onchain_conflict: Bool,
  +key_len: Nat,
  +bytes_ok: Bool,
  +active_chain: Nat,
  +updated_chain: Maybe<&2, Nat>
) -> Bool:
  a b = check_swap_protocol_leg(hash_locked_is_mine, time_locked_is_mine, locally_used, exp, now, created, creation_confirmed, onchain_conflict) check_swap_storage_leg(key_len, bytes_ok, active_chain, updated_chain)
  Bool.and(a, b)
