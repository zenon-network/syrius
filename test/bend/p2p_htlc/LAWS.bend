import Base
import ./model.bend as M

# Formal Laws for Syrius P2P HTLC Swaps, Reclaim Lookahead, Auto-Unlock,
# Drift Persistence, 2-Phase SQLCipher Rekey, Legacy Migration & Error Sanitizer.

# ------------------------------------------------------------------------------
# Section 1: HTLC Timelock & Safe-Join Window Algebra
# ------------------------------------------------------------------------------

# Law 1: Safe join requires hashLocked in wallet and timeLocked NOT in wallet
# (cannot join own swap).
law safe_join_requires_participants:
  for +hl_mine: Bool
  for +tl_mine: Bool
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +conflict: Bool
  for ok: {M.is_safe_join(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict) == True{} : Bool}
  {Bool.and(hl_mine, Bool.not(tl_mine)) == True{} : Bool}

# Law 2: Safe join requires unused locally and no on-chain hashlock conflict.
law safe_join_requires_unused_and_unique:
  for +hl_mine: Bool
  for +tl_mine: Bool
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +conflict: Bool
  for ok: {M.is_safe_join(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict) == True{} : Bool}
  {Bool.and(Bool.not(used), Bool.not(conflict)) == True{} : Bool}

# Law 3: Safe join enforces remaining > 0, remaining <= 24h, confirmed creation,
# and (exp - created) <= 24h.
law safe_join_requires_duration_caps:
  for +hl_mine: Bool
  for +tl_mine: Bool
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +conflict: Bool
  for ok: {M.is_safe_join(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict) == True{} : Bool}
  {Bool.and(
    Nat.is_gt(M.remaining_time(exp, now), 0n),
    Bool.and(
      Nat.is_le(M.remaining_time(exp, now), M.MAX_INITIAL_HTLC_DURATION()),
      Bool.and(confirmed, Nat.is_le(Nat.sub(exp, created), M.MAX_INITIAL_HTLC_DURATION()))
    )
  ) == True{} : Bool}

# Law 4 (Fundamental HTLC Safety-Margin Theorem — parametric):
# For ANY counter duration and min-safe-find margin, a safe join window
# guarantees initial_exp - counter_exp >= min_safe_find.
law safe_join_window_margin_parametric:
  for +exp: Nat
  for +now: Nat
  for +min_safe_find: Nat
  for +counter_dur: Nat
  for safe: {M.can_safely_join_window_with(exp, now, min_safe_find, counter_dur) == True{} : Bool}
  {Nat.is_ge(Nat.sub(exp, M.counter_expiration_with(now, counter_dur)), min_safe_find) == True{} : Bool}

# Law 5 (Fundamental HTLC Safety-Margin Theorem — Syrius constants):
# Every safely joined swap where counter HTLC expires at now + 1h leaves at
# least 6h (360 min) between counter expiry and initial expiry.
law safe_join_guarantees_preimage_margin:
  for +hl_mine: Bool
  for +tl_mine: Bool
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +conflict: Bool
  for ok: {M.is_safe_join(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict) == True{} : Bool}
  {Nat.is_ge(Nat.sub(exp, M.counter_expiration(now)), M.MIN_SAFE_FIND_PREIMAGE()) == True{} : Bool}

# Law 6 (Unlock vs Reclaim Mutual Exclusion Theorem):
# For ALL expiration times and current times, unlock and reclaim are NEVER
# simultaneously permitted.
law unlock_reclaim_mutually_exclusive:
  for +exp: Nat
  for +now: Nat
  {Bool.and(M.can_unlock(exp, now), M.can_reclaim(exp, now)) == False{} : Bool}

# Law 7 (Strict min_safe_complete Buffer Separation Theorem):
# Whenever unlock is allowed at `now`, reclaim is still disallowed even after
# advancing time by the full MIN_SAFE_COMPLETE_SWAP (10 min) buffer.
law unlock_has_strict_reclaim_buffer:
  for +exp: Nat
  for +now: Nat
  for u: {M.can_unlock(exp, now) == True{} : Bool}
  {M.can_reclaim(exp, Nat.add(now, M.MIN_SAFE_COMPLETE_SWAP())) == False{} : Bool}

# ------------------------------------------------------------------------------
# Section 2: 6-State Swap Lifecycle Automaton
# ------------------------------------------------------------------------------

# Law 8: Outgoing Start initializes to Pending (with preimage); Incoming Join
# initializes to Active (with counter HTLC, without preimage).
law start_and_join_initial_states:
  {Bool.and(
    Bool.and(
      M.swap_state_eq(M.swap_state(M.start_outgoing_swap()), M.Pending{}),
      M.swap_has_preimage(M.start_outgoing_swap())
    ),
    Bool.and(
      M.swap_state_eq(M.swap_state(M.join_incoming_swap()), M.Active{}),
      Bool.not(M.swap_has_preimage(M.join_incoming_swap()))
    )
  ) == True{} : Bool}

# Law 9: On-chain Create flips Pending -> Active.
law create_flips_pending_to_active:
  for +dir: M.SwapDir
  for +hc: Bool
  for +hp: Bool
  for +ic: Bool
  for +cv: Bool
  {M.swap_state(M.step_swap(M.SwapRec{dir, M.Pending{}, hc, hp}, M.EvCreate{ic, cv})) == M.Active{} : M.SwapState}

# Law 10: Unlock on non-completed incoming swap's initial HTLC (with descendants +
# preimage) transitions to Completed AND records the preimage (even when hp == False).
law unlock_incoming_completes_and_records_preimage:
  for +st: M.SwapState
  for +hc: Bool
  for +hp: Bool
  for not_comp: {M.swap_state_eq(st, M.Completed{}) == False{} : Bool}
  {Bool.and(
    M.swap_state_eq(
      M.swap_state(M.step_swap(M.SwapRec{M.Incoming{}, st, hc, hp}, M.EvUnlock{M.InitialHtlc{}, True{}, True{}})),
      M.Completed{}
    ),
    M.swap_has_preimage(M.step_swap(M.SwapRec{M.Incoming{}, st, hc, hp}, M.EvUnlock{M.InitialHtlc{}, True{}, True{}}))
  ) == True{} : Bool}

# Law 11: Unlock on active outgoing swap's counter HTLC (with descendants +
# preimage) completes the swap and records the preimage.
law unlock_outgoing_active_completes:
  for +hc: Bool
  for +hp: Bool
  {Bool.and(
    M.swap_state_eq(
      M.swap_state(M.step_swap(M.SwapRec{M.Outgoing{}, M.Active{}, hc, hp}, M.EvUnlock{M.CounterHtlc{}, True{}, True{}})),
      M.Completed{}
    ),
    M.swap_has_preimage(M.step_swap(M.SwapRec{M.Outgoing{}, M.Active{}, hc, hp}, M.EvUnlock{M.CounterHtlc{}, True{}, True{}}))
  ) == True{} : Bool}

# Law 12: Reclaim on a non-completed swap's funded HTLC transitions to Unsuccessful.
law reclaim_non_completed_funded_unsuccessful:
  for +dir: M.SwapDir
  for +st: M.SwapState
  for +hc: Bool
  for +hp: Bool
  for not_comp: {M.swap_state_eq(st, M.Completed{}) == False{} : Bool}
  {M.swap_state(M.step_swap(M.SwapRec{dir, st, hc, hp}, M.EvReclaim{M.funded_htlc_role(dir), True{}})) == M.Unsuccessful{} : M.SwapState}

# Law 13: Expiry moves Pending and Active to Reclaimable, leaving other states unchanged.
law expire_moves_pending_and_active_only:
  for +dir: M.SwapDir
  for +hc: Bool
  for +hp: Bool
  {Bool.and(
    M.swap_state_eq(M.swap_state(M.step_swap(M.SwapRec{dir, M.Pending{}, hc, hp}, M.EvExpire{})), M.Reclaimable{}),
    Bool.and(
      M.swap_state_eq(M.swap_state(M.step_swap(M.SwapRec{dir, M.Active{}, hc, hp}, M.EvExpire{})), M.Reclaimable{}),
      Bool.and(
        M.swap_state_eq(M.swap_state(M.step_swap(M.SwapRec{dir, M.Unsuccessful{}, hc, hp}, M.EvExpire{})), M.Unsuccessful{}),
        M.swap_state_eq(M.swap_state(M.step_swap(M.SwapRec{dir, M.Error{}, hc, hp}, M.EvExpire{})), M.Error{})
      )
    )
  ) == True{} : Bool}

# Law 14 (Terminal Absorption): Completed NEVER regresses to Reclaimable,
# Unsuccessful, or any other state under ANY SwapEvent.
law completed_is_terminal_absorbing:
  for +dir: M.SwapDir
  for +hc: Bool
  for +hp: Bool
  for +ev: M.SwapEvent
  {M.swap_state(M.step_swap(M.SwapRec{dir, M.Completed{}, hc, hp}, ev)) == M.Completed{} : M.SwapState}

# Law 15 (Safe Deletion Law): Pending, Active, and Reclaimable are NEVER
# deletable; Completed, Unsuccessful, and Error ARE deletable.
law safe_deletion_partition:
  {Bool.and(
    Bool.and(
      M.can_delete_swap(M.Completed{}),
      Bool.and(M.can_delete_swap(M.Unsuccessful{}), M.can_delete_swap(M.Error{}))
    ),
    Bool.and(
      Bool.not(M.can_delete_swap(M.Pending{})),
      Bool.and(Bool.not(M.can_delete_swap(M.Active{})), Bool.not(M.can_delete_swap(M.Reclaimable{})))
    )
  ) == True{} : Bool}

# Law 16 (funded_htlc & Direction Bijection): Outgoing <=> InitialHtlc and
# Incoming <=> CounterHtlc, and funded role != unlock target role.
law funded_htlc_direction_bijection:
  for +dir: M.SwapDir
  for +role: M.HtlcRole
  {Bool.and(
    M.swap_dir_eq(M.dir_for_funded_role(M.funded_htlc_role(dir)), dir),
    Bool.and(
      M.htlc_role_eq(M.funded_htlc_role(M.dir_for_funded_role(role)), role),
      Bool.not(M.htlc_role_eq(M.funded_htlc_role(dir), M.unlock_target_role(dir)))
    )
  ) == True{} : Bool}

# ------------------------------------------------------------------------------
# Section 3: Reclaim Address Lookahead Machine
# ------------------------------------------------------------------------------

# Law 17: Hardware wallets ALWAYS reject missing reclaim address and derive 0.
law reclaim_hw_rejects_missing_never_derives:
  for +has_wallet: Bool
  for +wlen: Nat
  for +lookahead: Nat
  for +match_idx: Maybe<&2, Nat>
  for +exp: Nat
  for +now: Nat
  {Bool.and(
    Bool.not(M.reclaim_is_ok(M.evaluate_reclaim_with(False{}, has_wallet, True{}, wlen, lookahead, match_idx, exp, now))),
    Nat.is_eq(M.reclaim_derived_count(M.evaluate_reclaim_with(False{}, has_wallet, True{}, wlen, lookahead, match_idx, exp, now)), 0n)
  ) == True{} : Bool}

# Law 18: Unexpired HTLC NEVER persists generated addresses (persistent
# _ensureAddressGenerated / derived_count runs strictly after can_reclaim,
# whereas read-only _findDerivedAddressIndex scans before).
law reclaim_unexpired_never_derives:
  for +in_wallet: Bool
  for +has_wallet: Bool
  for +is_hw: Bool
  for +wlen: Nat
  for +lookahead: Nat
  for +match_idx: Maybe<&2, Nat>
  for +exp: Nat
  for +now: Nat
  for unexp: {M.can_reclaim(exp, now) == False{} : Bool}
  {Bool.and(
    Bool.not(M.reclaim_is_ok(M.evaluate_reclaim_with(in_wallet, has_wallet, is_hw, wlen, lookahead, match_idx, exp, now))),
    Nat.is_eq(M.reclaim_derived_count(M.evaluate_reclaim_with(in_wallet, has_wallet, is_hw, wlen, lookahead, match_idx, exp, now)), 0n)
  ) == True{} : Bool}

# Law 19: Software wallet reclaiming an expired HTLC at index in [len, len + limit)
# derives exactly (idx - len + 1) addresses, bounded by [1, limit], reaching idx + 1.
law reclaim_sw_lookahead_exact_and_bounded:
  for +wlen: Nat
  for +lookahead: Nat
  for +idx: Nat
  for +exp: Nat
  for +now: Nat
  for +ge_len: {Nat.is_le(wlen, idx) == True{} : Bool}
  for +lt_end: {Nat.is_lt(idx, Nat.add(wlen, lookahead)) == True{} : Bool}
  for +expired: {M.can_reclaim(exp, now) == True{} : Bool}
  {Bool.and(
    Nat.is_eq(
      M.reclaim_derived_count(M.evaluate_reclaim_with(False{}, True{}, False{}, wlen, lookahead, Some{idx}, exp, now)),
      1n+Nat.sub(idx, wlen)
    ),
    Bool.and(
      Nat.is_le(
        M.reclaim_derived_count(M.evaluate_reclaim_with(False{}, True{}, False{}, wlen, lookahead, Some{idx}, exp, now)),
        lookahead
      ),
      Nat.is_eq(
        Nat.add(wlen, M.reclaim_derived_count(M.evaluate_reclaim_with(False{}, True{}, False{}, wlen, lookahead, Some{idx}, exp, now))),
        1n+idx
      )
    )
  ) == True{} : Bool}

# Law 20: Software wallet rejects missing address outside [len, len + limit).
law reclaim_sw_out_of_window_rejected:
  for +wlen: Nat
  for +lookahead: Nat
  for +idx: Nat
  for +exp: Nat
  for +now: Nat
  for oob: {Nat.is_ge(idx, Nat.add(wlen, lookahead)) == True{} : Bool}
  {M.reclaim_is_ok(M.evaluate_reclaim_with(False{}, True{}, False{}, wlen, lookahead, Some{idx}, exp, now)) == False{} : Bool}

# ------------------------------------------------------------------------------
# Section 4: Auto-Unlock Single-Flight Mutex & 2-Min Cooldown Arbiter
# ------------------------------------------------------------------------------

# Law 21: Single-flight mutex blocks concurrent re-entry whenever is_unlocking == True.
law auto_unlock_mutex_blocks_reentry:
  for +last: Maybe<&2, Nat>
  for +wallet_open: Bool
  for +node_synced: Bool
  for +now: Nat
  {Bool.and(
    Bool.not(M.unlock_step_started(M.try_start_auto_unlock(M.AutoUnlock{True{}, last}, wallet_open, node_synced, now))),
    M.auto_unlock_is_busy(M.unlock_step_state(M.try_start_auto_unlock(M.AutoUnlock{True{}, last}, wallet_open, node_synced, now)))
  ) == True{} : Bool}

# Law 22: Cooldown blocks immediate retry (and any retry within < 2 min) after an attempt at t.
law auto_unlock_cooldown_blocks_retry:
  for +t: Nat
  for +delta: Nat
  for +wallet_open: Bool
  for +node_synced: Bool
  for within_cd: {Nat.is_lt(delta, M.AUTO_UNLOCK_COOLDOWN()) == True{} : Bool}
  {M.unlock_step_started(M.try_start_auto_unlock(M.AutoUnlock{False{}, Some{t}}, wallet_open, node_synced, Nat.add(t, delta))) == False{} : Bool}

# Law 23: After cooldown expires (now = t + 2 + extra), retry succeeds when
# wallet is open and node is synced, and acquires the single-flight mutex.
law auto_unlock_cooldown_expires_allows_retry:
  for +t: Nat
  for +extra: Nat
  {Bool.and(
    M.unlock_step_started(M.try_start_auto_unlock(M.AutoUnlock{False{}, Some{t}}, True{}, True{}, Nat.add(Nat.add(t, M.AUTO_UNLOCK_COOLDOWN()), extra))),
    M.auto_unlock_is_busy(M.unlock_step_state(M.try_start_auto_unlock(M.AutoUnlock{False{}, Some{t}}, True{}, True{}, Nat.add(Nat.add(t, M.AUTO_UNLOCK_COOLDOWN()), extra))))
  ) == True{} : Bool}

# ------------------------------------------------------------------------------
# Section 5: Drift Persistence, Pruning, 2-Phase Rekey, Migration & Sanitizer
# ------------------------------------------------------------------------------

# Law 24: SQLCipher encryption key requires exact 32-byte length AND valid byte
# range [0..255]: any valid key has len == 32, invalid bytes are always rejected,
# and a valid 32-byte key is accepted.
law sqlcipher_key_requires_32_bytes:
  for +len: Nat
  for +bytes_ok: Bool
  for valid: {M.is_valid_sqlcipher_key(len, bytes_ok) == True{} : Bool}
  {len == M.SQLCIPHER_KEY_LEN() : Nat}

# Law 24b: SQLCipher key validation always rejects out-of-range bytes regardless
# of length and accepts 32 valid bytes.
law sqlcipher_key_rejects_invalid_bytes_and_accepts_32:
  for +len: Nat
  {Bool.and(
    Bool.not(M.is_valid_sqlcipher_key(len, False{})),
    M.is_valid_sqlcipher_key(M.SQLCIPHER_KEY_LEN(), True{})
  ) == True{} : Bool}

# Law 25: writeProcessedHtlcBlock enforces strict chain_id equality on updated swaps.
law processed_block_requires_matching_chain:
  for +active_chain: Nat
  for +swap_chain: Nat
  for ok: {M.can_write_processed_block(active_chain, Some{swap_chain}) == True{} : Bool}
  {swap_chain == active_chain : Nat}

# Law 26: Pruning cap NEVER evicts Pending, Active, or Reclaimable swaps.
law pruning_never_evicts_unresolved_swaps:
  for +total: Nat
  for +max_swaps: Nat
  for +sc: Nat
  for +pc: Maybe<&2, Nat>
  {Bool.and(
    Bool.not(M.should_evict_swap(total, max_swaps, sc, pc, M.Pending{})),
    Bool.and(
      Bool.not(M.should_evict_swap(total, max_swaps, sc, pc, M.Active{})),
      Bool.not(M.should_evict_swap(total, max_swaps, sc, pc, M.Reclaimable{}))
    )
  ) == True{} : Bool}

# Law 27: begin_rekey creates a backup encrypted with old_k before switching primary to new_k.
law begin_rekey_retains_old_backup:
  for +st: M.StorageState
  for +old_k: Nat
  for +new_k: Nat
  {Bool.and(
    M.storage_is_open(M.begin_rekey_storage(M.begin_rekey(st, old_k, new_k, True{}))),
    Bool.and(
      Nat.is_eq(M.storage_open_key(M.begin_rekey_storage(M.begin_rekey(st, old_k, new_k, True{}))), new_k),
      Bool.and(
        M.file_has_key(M.storage_primary(M.begin_rekey_storage(M.begin_rekey(st, old_k, new_k, True{}))), new_k),
        M.file_has_key(M.storage_backup(M.begin_rekey_storage(M.begin_rekey(st, old_k, new_k, True{}))), old_k)
      )
    )
  ) == True{} : Bool}

# Law 28: Wallet-password failure after begin_rekey rolls back to old_k and
# deletes backup; both succeeding commits new_k and deletes backup.
law change_password_atomicity_commit_and_rollback:
  for +st: M.StorageState
  for +old_k: Nat
  for +new_k: Nat
  {Bool.and(
    Bool.and(
      Bool.not(M.chg_pwd_succeeded(M.change_password_txn(st, old_k, new_k, True{}, False{}))),
      Bool.and(
        M.storage_is_open(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, False{}))),
        Bool.and(
          Nat.is_eq(M.storage_open_key(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, False{}))), old_k),
          Bool.and(
            M.file_has_key(M.storage_primary(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, False{}))), old_k),
            M.file_is_none(M.storage_backup(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, False{}))))
          )
        )
      )
    ),
    Bool.and(
      M.chg_pwd_succeeded(M.change_password_txn(st, old_k, new_k, True{}, True{})),
      Bool.and(
        M.storage_is_open(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, True{}))),
        Bool.and(
          Nat.is_eq(M.storage_open_key(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, True{}))), new_k),
          Bool.and(
            M.file_has_key(M.storage_primary(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, True{}))), new_k),
            M.file_is_none(M.storage_backup(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, True{}, True{}))))
          )
        )
      )
    )
  ) == True{} : Bool}

# Law 29: HtlcSwapSyncService is ALWAYS restarted in finally regardless of
# whether beginRekey or wallet changePassword succeeded or failed.
law change_password_always_restarts_sync:
  for +st: M.StorageState
  for +old_k: Nat
  for +new_k: Nat
  for +rekey_ok: Bool
  for +wallet_pwd_ok: Bool
  {M.storage_sync_running(M.chg_pwd_storage(M.change_password_txn(st, old_k, new_k, rekey_ok, wallet_pwd_ok))) == True{} : Bool}

# Law 30: Crash-recovery open() falls back to .rekey-backup when primary fails
# and cleans up stale backup whenever primary opens cleanly.
law open_crash_recovery_and_stale_backup_cleanup:
  for +key: Nat
  for +wrong_key: Nat
  for +stale_bak: M.FileState
  for +sync_r: Bool
  for neq: {Nat.is_eq(wrong_key, key) == False{} : Bool}
  {Bool.and(
    Bool.and(
      M.storage_is_open(M.open_with_recovery(M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)),
      Bool.and(
        Nat.is_eq(M.storage_open_key(M.open_with_recovery(M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)), key),
        Bool.and(
          M.file_has_key(M.storage_primary(M.open_with_recovery(M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)), key),
          M.file_is_none(M.storage_backup(M.open_with_recovery(M.EncFile{wrong_key}, M.EncFile{key}, key, sync_r)))
        )
      )
    ),
    Bool.and(
      M.storage_is_open(M.open_with_recovery(M.EncFile{key}, stale_bak, key, sync_r)),
      Bool.and(
        Nat.is_eq(M.storage_open_key(M.open_with_recovery(M.EncFile{key}, stale_bak, key, sync_r)), key),
        M.file_is_none(M.storage_backup(M.open_with_recovery(M.EncFile{key}, stale_bak, key, sync_r)))
      )
    )
  ) == True{} : Bool}

# Law 31: Legacy migration deletes Hive box iff failed_count == 0 and never
# overwrites existing Drift rows.
law legacy_migration_safety:
  for +failed: Nat
  for +existing_val: Nat
  for +legacy_val: Nat
  {Bool.and(
    Bool.and(
      M.should_delete_hive_box(0n),
      Bool.not(M.should_delete_hive_box(1n+failed))
    ),
    Nat.is_eq(M.insert_or_ignore(Some{existing_val}, legacy_val), existing_val)
  ) == True{} : Bool}

# Law 32: Error sanitizer satisfies strict information-flow non-interference
# (zero raw message / SQL bind param / preimage leakage at any nesting depth).
law sanitizer_zero_preimage_leakage:
  for +err: M.SwapError
  for +s1: Nat
  for +s2: Nat
  {M.sanitize_error(M.replace_secrets(err, s1)) == M.sanitize_error(M.replace_secrets(err, s2)) : M.SanitizedSummary}

# Law 33: Error sanitizer strictly caps unwrap depth at 5 steps (5 wrapper layers
# around SqliteErr does not unwrap past the bound).
law sanitizer_five_layer_cap:
  for +code: Nat
  for +s: Nat
  {M.sanitize_error(
    M.DriftWrap{M.DriftWrap{M.DriftWrap{M.DriftWrap{M.DriftWrap{M.SqliteErr{code, s}, s}, s}, s}, s}, s}
  ) == M.SummaryTypeOnly{} : M.SanitizedSummary}

# Law 34: Parallelized multi-check helper equals sequential conjunction of its legs.
law parallel_swap_safety_check_equiv:
  for +hl_mine: Bool
  for +tl_mine: Bool
  for +used: Bool
  for +exp: Nat
  for +now: Nat
  for +created: Nat
  for +confirmed: Bool
  for +conflict: Bool
  for +key_len: Nat
  for +bytes_ok: Bool
  for +active_chain: Nat
  for +updated_chain: Maybe<&2, Nat>
  {M.parallel_swap_safety_check(
    hl_mine, tl_mine, used, exp, now, created, confirmed, conflict,
    key_len, bytes_ok, active_chain, updated_chain
  ) == Bool.and(
    M.check_swap_protocol_leg(hl_mine, tl_mine, used, exp, now, created, confirmed, conflict),
    M.check_swap_storage_leg(key_len, bytes_ok, active_chain, updated_chain)
  ) : Bool}
