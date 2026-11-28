# Bend Formal Verification for Syrius

Syrius uses [Bend 2.0.40](https://github.com/bendlang/bend) to state and
mechanically prove core wallet, protocol, security, state-machine, and UI-edge
invariants, then checks agreement between those verified models and real Dart
production code under `lib/`.

**This is subsystem contract verification and bounded differential testing, not
a formal proof of the entire Flutter/Dart application.** Bend proves universal
and inductive theorems over small, pure executable models; Bend's independent
Lean kernel (`--verdict`) rechecks every proof; differential conformance tests
compare fresh Bend oracle outputs against real Syrius Dart implementations; and
deliberate fault injection verifies that both proofs and conformance tests
actually detect regressions.

---

## 1. Architecture Overview

### Repository Layout

| Path | Role |
|---|---|
| `LAWS.bend` | Root cross-cutting wallet invariants (reviewable specification) |
| `PROOF.bend` | Root proof entrypoint importing `./LAWS.bend` and every domain `PROOF.bend` so a single `bend PROOF.bend` / `--verdict` verifies the full proof graph |
| `test/bend/common/nat.bend` | Shared constructive `Bool` and `Nat` arithmetic/order lemma library (47 proven laws + 5 refutation/equality helpers) |
| `test/bend/<domain>/model.bend` | Executable pure Bend model (`is Data` ADTs, total structural recursion, zero `@unsafe`/foreign code) |
| `test/bend/<domain>/LAWS.bend` | Domain laws stated over `./model.bend` |
| `test/bend/<domain>/PROOF.bend` | Constructive proofs (`def Laws.<name>(...)`) closing every law in `./LAWS.bend` |
| `test/bend/coverage.json` | Machine-checked contract inventory linking domains, laws, and executable Dart evidence |
| `test/bend/specs.py` | Declarative oracle vector specs, Bend model faults, and real Dart source faults |
| `test/bend/run.py`, `test/bend/run.sh` | Parallel 6-stage verification gate (Python 3 standard library only) |
| `test/bend/test_harness.py` | Unit tests for `run.py` parsers, static audit, inventory checks, and fault classification |
| `test/bend/Dockerfile`, `Dockerfile.verdict` | Pinned Bend `2.0.40` and Lean `v4.34.0` (`elan 4.4.0`) checker images |
| `scripts/bend` | Hardened container launcher for local and CI Bend invocations |
| `test/bend_conformance/*_test.dart` | Dart <-> Bend differential conformance suites tagged `@Tags(<String>['bend'])` |
| `.github/workflows/bend.yml` | GitHub Actions workflow running the full gate on PRs and pushes to `develop` |

### Six-Stage Verification Gate (`test/bend/run.sh`)

1. **Static proof-graph & coverage inventory (`Stage 1`)**: Verifies
   `test/bend/coverage.json`, traverses the full transitive Bend import graph
   from root `PROOF.bend`, `test/bend/common/nat.bend`, and all 11 domains,
   enforces 1:1 `law <name>:` <-> `def Laws.<name>(` parity, asserts per-domain
   `oracle_ops` matches `test/bend/specs.py` 1:1 and that `normative_target_laws`
   is a valid subset of `model_only_laws`, and rejects orphaned `.bend` files,
   missing Dart evidence files, `@unsafe`, `def f?(`, `?TODO` / `?` holes, and
   foreign/nonlocal imports.
2. **Parallel proof & Lean kernel verification (`Stage 2`)**: Checks
   `test/bend/common/nat.bend`, all 11 domain `PROOF.bend` files, and root
   `PROOF.bend` concurrently via `ThreadPoolExecutor` under both `--check-only`
   and `--verdict` (Lean 4.34.0 BendTT kernel). Strictly requires `exit == 0`,
   `ALL PROOFS CHECK` present, and `SOME PROOFS FAIL` absent.
3. **Parallel Bend oracle vector generation (`Stage 3`)**: Generates chunked
   `oracle_<domain>_<offset>.bend` files inside `.bend-work/run-<id>/oracles/`
   (explicitly `0755`/`0644` for non-root Linux container UID `10001`), using
   Bend parallel-let (`c0 c1 c2 c3 = _chunk_0() _chunk_1() _chunk_2() _chunk_3()`)
   over balanced binary `++` trees, and runs all 40 chunks concurrently via
   `ThreadPoolExecutor` through real Bend to emit
   `.bend-work/run-<id>/vectors.json`. No Python or Dart substitute model
   supplies expected values.
4. **Dart <-> Bend differential conformance (`Stage 4`)**: Invokes
   `flutter test --no-pub --tags bend --machine` with `BEND_VECTORS` pointing to
   the freshly generated `vectors.json`. Every one of the **107** conformance
   ops across all 11 suites exercises real production `lib/` code, verifies the
   exact expected `seenOps` set (catching missing/unexecuted ops), and emits
   `BEND_MISMATCH` strictly when real `lib/` output disagrees with Bend
   `vectors.json` `expected`. Strictly parses `--machine` NDJSON events and fails
   on any test failure, error, skipped test, 0-test run, or missing required
   conformance suite.
5. **Parallel Bend model fault injection (`Stage 5`)**: Copies domain models
   into `.bend-work/run-<id>/mut-model-<name>/`, injects exact single-hit
   semantic faults into `model.bend`, asserts that (a) the mutated `model.bend`
   still typechecks cleanly, and (b) `PROOF.bend` fails with
   `SOME PROOFS FAIL` and `Location: Laws.<expected_law>`, and cleans up each
   temporary mutation tree in a `finally:` block.
6. **Parallel real Dart source fault injection (`Stage 6`)**: Stages an
   isolated symlink-overlay workspace under `.bend-work/run-<id>/mut-dart-<name>/`
   (copying `pubspec.*`, `dart_test.yaml`, `l10n.yaml`, and
   `.dart_tool/{package_config.json,package_graph.json,version}`, symlinking
   `assets/`, `test/`, `drift_schemas/`, and all untouched `lib/` siblings so
   large embedded node binaries are never copied), mutates only the single
   copied target `lib/.../*.dart` file across all **34** deliberate Dart faults,
   and asserts the matching conformance test fails with `BEND_MISMATCH`.
   Compile/load/timeout errors are classified as `ERROR`, never `caught`. Live
   working tree files are never modified.

### Parallelism Model (Host Concurrency vs Bend Parallel-Let)

- **Actual wall-clock parallelism**: comes from Python's `ThreadPoolExecutor`
  in `test/bend/run.py`, running containerized Bend processes and isolated
  Flutter test overlays concurrently across 13 proof/verdict targets, 40 oracle
  chunks, 22 Bend model mutations, and 34 real Dart source mutations (~3x
  wall-clock speedup over serial execution).
- **Bend parallel-let (`a b = f(x) g(y)`)**: Oracle `main() -> String` modules
  are normalized by the Bend checker rather than compiled to native/GPU
  parallel executables. Domain models and root `LAWS.bend` include Bend
  parallel-let evaluators and prove `--verdict`-verified fork-join equivalence
  to their sequential counterparts (`*_par_equiv_seq` / `parallel_*_equiv`),
  ensuring the pure specifications are ready for compiled parallel Bend targets
  without overclaiming GPU/native parallel execution during checking.

### Toolchain Pinning & Container Hardening

- `scripts/bend` and `test/bend/run.py` execute Bend inside containers with
  `--network none --read-only --cap-drop ALL --security-opt no-new-privileges
  --pids-limit 256 --memory 2g --tmpfs /tmp:rw,nosuid,size=256m`, non-root user
  `bend` (UID `10001`), and a read-only bind mount of the repository root.
- `test/bend/Dockerfile` pins Debian by digest
  (`debian@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc`)
  and verifies Bend `2.0.40` Linux `arm64`/`x64` release archives against
  explicit SHA-256 digests.
- `test/bend/Dockerfile.verdict` verifies `elan 4.4.0` release archives against
  explicit `aarch64`/`x86_64` SHA-256 digests, installs `leanprover/lean4:v4.34.0`,
  and warms the BendTT verdict kernel at image build time. Lean binary downloads
  are version-selected by `elan` rather than independently checksummed here;
  this is an explicit toolchain trust boundary, not a fully hermetic build.

---

## 2. Honest Verification Boundaries

Reviewers and maintainers must keep these boundaries explicit:

### What Bend Proves
- Universal and structural-induction theorems stated in `LAWS.bend` and
  `test/bend/<domain>/LAWS.bend` over their pure Bend models (e.g., balance and
  supply conservation, state-machine safety invariants over arbitrary finite
  event histories, quorum `> 33%` arithmetic bounds, monotone pagination/lock
  fences, single-flight/ref-count invariants, and non-overlapping time windows).
- Every theorem is checked twice: once by Bend 2.0.40 and once by the
  independent Lean-verified BendTT kernel (`--verdict`), with zero `@unsafe`
  or foreign code in the proof graph.

### What Differential Conformance & Mutation Tests Demonstrate
- Bounded agreement between real Syrius Dart production code (`lib/`) and fresh
  Bend oracle outputs across representative, boundary, exhaustive short-sequence
  (`--depth`), and deterministic seeded-history (`--seed`) inputs. Every op in
  all 11 conformance suites exercises live production `lib/` code, verifies
  exact `seenOps` coverage, and emits `BEND_MISMATCH` strictly on Bend oracle
  mismatches (never on hardcoded Dart literals).
- Sensitivity of both Bend laws and Dart conformance suites to realistic
  semantic bugs via **22** deliberate Bend model mutations (`Stage 5`) and
  **34** deliberate real Dart source mutations (`Stage 6`, **56** total).

### Differential Oracle Surface vs. Model-Only & Normative Laws

All **445** laws (root `17` + domain `381` + `test/bend/common/nat.bend` `47`)
are mechanically proved in Bend and rechecked by the Lean `--verdict` kernel.
The differential Dart <-> Bend conformance surface is **exact 107 oracle ops
across 11 suites** (**833** Bend oracle vectors at default `depth=3, seed=1`),
mechanically cross-checked 1:1 between `test/bend/coverage.json` (`oracle_ops`),
`test/bend/specs.py` (`ORACLE_SPECS`), and Dart `seenOps`.

Every law outside those 107 oracle ops is proved strictly at the Bend/Lean model
level and enumerated explicitly in `test/bend/coverage.json`:

- **291 oracle-exercised domain laws**: laws whose subject model functions are
  directly or transitively evaluated against real `lib/` production code through
  the 107 oracle ops.
- **107 model-only laws (`model_only_laws` in `coverage.json`: 90 domain + 17
  root)**: proved in Bend and Lean `--verdict` without direct Bend oracle
  differential execution. These comprise:
  - All **17** root cross-cutting composition laws (`LAWS.bend`), which compose
    already-verified domain models;
  - Bend parallel-let vs. sequential equivalence proofs (`batch_par_eq_seq`,
    `lifecycle_par_eq_seq`, `tx_batch_par_equiv_seq`,
    `node_sync_batch_par_equiv_seq`, `parallel_crash_safety_gate_*`,
    `parallel_accelerator_audit_equiv`);
  - Arbitrary-precision `Nat` inductive siblings of `U32`-oracle-tested
    functions (`plasma_for_qsr_*`, `op_plasma_strict_order`,
    `stake_duration_strictly_monotone`, `meets_plasma_monotone`,
    `wallet_file_closed_permanent_run`);
  - Widget/UI-stepper, desktop window-manager, async concurrency/mutex/polling,
    and storage-lifecycle models (`exchange_rate_*`, `seed_*`, `window_*`,
    `tx_publish_fence_*`, `lock_*`, `auto_receive_single_flight_*`,
    `fetch_loading_*`, `timer_step_*`, `node_add/rename/delete/auto_receive_*`,
    `clock_skew_*`, `notif_lock_screen_*`, `uri_card_clears_*`,
    `relay_op_seq_*`, `relay_capped_*`, `topic_unsub_epoch_*`,
    `provisional_purge_*`, `orphan_cleanup_*`, `page_slice_*`, `epoch_day_*`,
    `create_step_*`, `withdraw_confirm_*`, `deploy_pillar_*`, `update_step_*`,
    `sentinel_authorization_matrix`, `issue_step_*`, `search_*`,
    `start_and_join_*`, `create/unlock/reclaim/expire` swap lifecycle,
    `pruning_*`, `open_crash_recovery_*`, `legacy_migration_safety`,
    `can_submit_vote` / `non_pillar_never_votes`, `clamped_bar_*`,
    `quorum_progress_bar_conserved`), many of which are additionally covered by
    ordinary Dart unit/BLoC/widget tests linked in `coverage.json`;
  - The **8** normative target laws below.
- **8 normative target laws (`normative_target_laws` in `coverage.json`,
  mechanically enforced as a subset of `model_only_laws`)**, where the Bend
  model intentionally specifies a stricter target contract than current `lib/`:
  - `plasma_staking` (5): `cancel_timer_stopped_idempotent`,
    `cancel_timer_terminates_cleanly`, `cancel_timer_no_storm_after_zero`
    (`lib/widgets/reusable_widgets/cancel_timer.dart` leaves its 1s periodic
    timer running at `<= 0s`; deferred widget fix); `stake_lock_expired_at_or_past`,
    `stake_lock_positive_countdown_before_exp` (`StakesCard` uses strict `<`,
    leaving a 0s gap at `nowMs == exp*1000`).
  - `pillars_sentinels` (2): `deposit_confirm_rejects_zero_amount`,
    `deposit_confirm_strictly_increases` (`PillarDepositQsrBloc` /
    `SentinelDepositQsrBloc` rely on UI validators rather than re-checking
    `event.amount > 0`).
  - `p2p_htlc` (1): `completed_is_terminal_absorbing`
    (`HtlcSwapSyncService._getReclaimUpdate` lacks an explicit `completed`
    guard; tracked below for dedicated hardening).
- **47 shared constructive `Bool`/`Nat` lemmas** in `test/bend/common/nat.bend`
  used to prove domain and root laws.

### What Is NOT Formally Proved
- **Flutter UI rendering, layout, focus, and animation**: Widget trees, pixel
  rendering, platform channels, and pointer/keyboard routing remain covered by
  ordinary widget and integration tests.
- **Cryptography and binary compatibility**: Ed25519 signing/verification,
  BIP39/BIP44 derivation, Argon2id/AES-GCM keystore encryption, SHA3/SHA256
  hashing, PoW links, and ABI binary encoding are NOT proved by Bend; existing
  SDK, crypto, and devnet integration tests remain required.
- **Persistence & OS boundaries**: SQLCipher C library encryption, filesystem
  atomicity under power loss, OS secure storage / keychain APIs, Ledger USB/HID
  transport, and embedded `libznn` native binaries are outside the Bend models.
- **Network & concurrency**: Arbitrary WebSocket/RPC packet loss, WalletConnect
  relay behavior, and all Dart async microtask / isolate / OS thread
  interleavings are NOT exhaustively proved; state-machine models prove
  abstract transition invariants over modeled event sequences.
- **Trusted components**: Bend's parser/compiler/runtime, Lean 4 / BendTT
  kernel, Docker, Dart/Flutter SDK, and the Python/Dart test adapters are
  trusted components.

---

## 3. Known Implementation Findings & Category-A Fixes

Auditing Syrius up to the Flutter edge uncovered both unambiguous edge bugs
fixed directly in this branch and compatibility-sensitive behaviors intentionally
preserved and documented below.

### Category-A Fixes Landed in `lib/`

1. **`sortAssets` strict weak ordering**
   (`lib/rearchitecture/utils/functions/tokens.dart`): Previously returned `-1`
   for `(ZNN, ZNN)` and `+1` for `(QSR, QSR)`, violating comparator reflexivity
   and antisymmetry. Extracted `compareAssets(Token a, Token b)` returning `0`
   on equal `tokenStandard` while preserving `ZNN < QSR < non-coin` ordering.
2. **`InputValidators.correctValue` zero-max validation bypass**
   (`lib/utils/input_validators.dart`): Previously short-circuited to `null`
   (valid) when `maxValue == BigInt.zero && canBeEqualToMin == true`, accepting
   arbitrary strings like `"abc"` or `"999"` on zero-balance stake/plasma/token
   inputs. Fixed so `maxValue == BigInt.zero && !canBeEqualToMin` still returns
   `emptyBalance`, while `canBeEqualToMin == true` executes full empty, parse,
   multi-dot (`split('.').length > 2`), decimal-count, and `[minValue, maxValue]`
   checks.
3. **`ProtocolHandler.getArguments` guard**
   (`lib/rearchitecture/utils/url_protocol/protocol.dart`): Changed
   `arguments.isEmpty && !arguments.any(...)` to `||` so non-empty custom
   protocol argument lists lacking `'%s'` properly throw `ArgumentError`.
4. **`SubmitDonationBloc` negative-leg guard**
   (`lib/rearchitecture/features/accelerator_donation_stepper/bloc/submit_donation_bloc.dart`):
   Previously checked `znnAmount <= 0 && qsrAmount <= 0`, allowing a negative
   leg whenever the other leg was positive. Extracted `isValidDonationAmounts`
   enforcing `znnAmount >= 0 && qsrAmount >= 0 && (znnAmount > 0 || qsrAmount > 0)`.
5. **`PillarsCard` momentum uptime `isInfinite` crash**
   (`lib/rearchitecture/features/pillars/view/pillars_card.dart`): Previously
   checked only `percentage.isNaN`, causing `double.infinity.round()` to throw
   when `expectedMomentums == 0 && producedMomentums > 0`. Extracted
   `computeMomentumUptimePercentage(int produced, int expected)` guarding
   non-positive `expected`, negative `produced`, `isNaN`, and `isInfinite`.
6. **`PasswordProgressBar` stuck-green strength bar**
   (`lib/widgets/reusable_widgets/progress_bars.dart`): Previously omitted an
   `else` branch for passwords of length `>= 8` failing complexity validation,
   leaving prior green segments stuck on screen. Extracted
   `classifyPasswordStrength` with exhaustive switching over
   `PasswordStrengthTier`.
7. **`AmountTextField` MAX button clamping, parse safety & disabled state**
   (`lib/rearchitecture/utils/widgets/amount_text_field.dart`): Previously only
   updated when `currentBalance < maxBalance` (ignoring amounts exceeding
   `maxBalance`), threw on unparseable or over-precision text, and kept MAX
   clickable when `enabled == false`. Extracted `resolveMaxAmountText`, guarded
   `parts.length <= 2` and `parts[1].length <= selectedToken.decimals` before
   `extractDecimals`, and gated MAX on `_enabled != false`.
8. **`AcceleratorProjectListItem` unified vote-summary delegation**
   (`lib/rearchitecture/features/accelerator_projects/widgets/accelerator_project_list_item.dart`):
   Delegated quorum (`> 33%`), majority, and clamped progress-bar calculations
   to `computeAcceleratorVoteSummary` and replaced direct `voteBreakdown.total`
   reads with `summary.totalVotes` so rendered tooltips and bars use the exact
   conformance-checked non-negative totals.
9. **`PlasmaStatsBloc` pagination slice clamping**
   (`lib/rearchitecture/features/plasma_stats/bloc/plasma_stats_bloc.dart`):
   Clamped `start` and `end` indices to `[0, kDefaultAddressList.length]` before
   calling `kDefaultAddressList.sublist(start, end)` so out-of-range page
   indices cannot throw `RangeError`.
10. **`TokensCard` trimmed search query consistency**
    (`lib/rearchitecture/features/tokens/view/tokens_card.dart`): Trimmed
    `value.text` before switching between `_buildTokensList()` and
    `_buildSearchToken(...)` and compared `state.query != searchQuery.trim()`,
    preventing whitespace-only or padded search input from stalling on an
    indefinite loading spinner.
11. **`NoMService.revalidateInteractiveRequest` authoritative lock guard**
    (`lib/services/nom_service.dart`): Enforced `kCurrentPage == Tabs.lock`
    (`code: 9000`) directly inside `revalidateInteractiveRequest(...)` so the
    post-confirmation revalidation entrypoint itself blocks locked-wallet
    execution rather than relying solely on caller pre-checks.

### Pure Flutter-Free Production Helpers Extracted (18 Modules)

To let both production widgets/BLoCs and Dart conformance tests execute the
exact same pure `lib/` logic without Flutter rendering dependencies, **18**
pure helpers are wired live into Syrius production code:

- `lib/utils/plasma_tier_utils.dart`: `PlasmaTier`, `classifyPlasmaTier` (derives
  thresholds from `constants.dart`; used by `ColorUtils.getPlasmaColor` and
  `WidgetUtils.getPlasmaToolTipMessage`)
- `lib/utils/password_strength_utils.dart`: `PasswordStrengthTier`,
  `classifyPasswordStrength`
- `lib/rearchitecture/utils/functions/tokens.dart`: `compareAssets`, `sortAssets`
- `lib/rearchitecture/utils/functions/amount_max_utils.dart`:
  `resolveMaxAmountText`
- `lib/rearchitecture/utils/functions/pillar_qsr_deposit_utils.dart`:
  `PillarQsrDepositSummary`, `computePillarQsrDepositSummary` (shared by
  `PillarQsrManagementStep` and `SentinelQsrManagementStep`)
- `lib/rearchitecture/features/lock/utils/auto_lock_utils.dart`:
  `shouldAutoLockOnTimer` (used by `_MainAppContainerState._createAutoLockTimer`)
- `lib/rearchitecture/features/pillars/utils/pillar_momentum_utils.dart`:
  `computeMomentumUptimePercentage`
- `lib/rearchitecture/features/pillars/utils/pillar_rules_utils.dart`:
  `canDelegateWithZnnBalance`, `isValidPillarRewardPercentage`,
  `computeOwnerRewardPercentage`, `canCollectPillarRewards`,
  `canCollectSentinelRewards`, `hasPillarRewardHistory`,
  `hasSentinelRewardHistory`, `hasSufficientSpawnPlasma`,
  `hasSufficientSpawnZnn`
- `lib/rearchitecture/features/fused_plasma/utils/fusion_expiration_utils.dart`:
  `isFusionRevocable`, `computeFusionCountdownSeconds`
- `lib/rearchitecture/features/fuse_plasma/utils/fuse_plasma_validation_utils.dart`:
  `isIntegerQsrAmount`, `canFusePlasma`
- `lib/rearchitecture/features/create_stake/utils/stake_duration_utils.dart`:
  `stakeDurationForMonths`, `isValidStakeMonths`, `buildValidStakeDurations`,
  `canCreateStake`
- `lib/rearchitecture/features/stake_collect/utils/stake_reward_utils.dart`:
  `canCollectStakeRewards`, `hasStakingRewardHistory` (wired live into
  `StakeCollectCard` (`stake_collect_card.dart`) and
  `StakingRewardsHistoryBloc` (`staking_rewards_history_bloc.dart`))
- `lib/rearchitecture/features/tokens/utils/token_capabilities.dart`:
  `TokenCapabilities`, `evaluateTokenCapabilities`, `canMintTokenAmount`,
  `canBurnTokenAmount`
- `lib/rearchitecture/features/create_token_stepper/utils/token_validation_utils.dart`:
  `kTokenDomainMaxLength`, `isValidTokenDecimals`, `isValidTokenDomainLength`,
  `validateTokenNameError`, `validateTokenSymbolError`,
  `validateTokenDomainError`, `resolveEffectiveTokenMaxSupply`,
  `validateTokenSupplyMetrics`
- `lib/rearchitecture/features/accelerator_projects/utils/accelerator_vote_summary.dart`:
  `AcceleratorVoteSummary`, `computeAcceleratorVoteSummary`
- `lib/rearchitecture/features/accelerator_projects/utils/accelerator_lifecycle_utils.dart`:
  `hasSufficientProjectCreationFee`, `isValidAcceleratorProjectBudget`,
  `canCreateAcceleratorPhase`, `canUpdateAcceleratorPhase`
- `lib/rearchitecture/features/accelerator_donation_stepper/bloc/submit_donation_bloc.dart`:
  `isValidDonationAmounts`
- `lib/rearchitecture/features/initial_htlc_validation/utils/htlc_window_utils.dart`:
  `HtlcWindowDecision`, `evaluateHtlcJoinWindow`, `evaluateHtlcExpiration`,
  `exceedsMaxInitialHtlcDuration` (used live by `HtlcInfoExtension`,
  `InitialHtlcValidationBloc`, and `ReclaimDepositBloc`)

### Preserved Behaviors & Follow-Up Hardening Candidates

The following audit findings were intentionally **not** changed silently in this
verification PR due to protocol/compatibility/UI-scope boundaries and are
tracked for dedicated follow-up fixes:

- **`SettingsSecurityBloc` legacy signing format**: Message/file signing format
  was preserved unchanged to maintain external signature verification
  compatibility.
- **Sync-lag threshold differences across call sites**: Syrius currently uses
  three distinct sync-lag checks: `< 3` momentums in `SyncInfoExtension.isSynced`,
  `< 20` in `AccountBlockUtils` transaction preconditions, and `> 20` in
  `SyncInfoExtension.isClearlyBehind`. Each is modeled accurately as implemented
  rather than silently unified.
- **HTLC clock source & 1-second boundary**: P2P swap expiry/reclaim UI checks
  compare `expirationTime` against local wall-clock time (`DateTime.now()`),
  whereas on-chain finality depends on frontier momentum timestamps (mitigated
  separately by Syrius's clock-skew warning at `> 300s` drift).
- **`HtlcSwapSyncService._getReclaimUpdate` terminal `completed` state guard**
  (`lib/rearchitecture/features/p2p_swaps/services/htlc_swap_sync_service.dart`):
  The `p2p_htlc` Bend model specifies `Completed` as a strictly absorbing
  terminal state (`completed_is_terminal_absorbing`), whereas real
  `_getSwapUpdateFromBlock` / `_getReclaimUpdate` currently lack an explicit
  `swap.state == P2pSwapState.completed` guard. For an outgoing swap already
  completed via counter-HTLC unlock, if an unclaimed initial HTLC were later
  reclaimed while another unresolved swap kept sync polling active,
  `_getReclaimUpdate` could transition `completed -> unsuccessful`. Tracked for
  a dedicated `lib/` hardening fix.
- **`CancelTimer` periodic timer lifecycle**
  (`lib/widgets/reusable_widgets/cancel_timer.dart`): `Timer.periodic(1s)` is
  not cancelled upon reaching zero and lacks `didUpdateWidget` handling; the
  ideal clean-termination invariant is formalized in `plasma_staking` and
  tracked for a dedicated widget fix.
- **`InfiniteScrollTable` / `InfiniteScrollGrid` pagination wedge**:
  `_isRequestingMore` only resets in `didUpdateWidget` when `items` identity or
  `hasReachedMax` changes, so a failed page fetch can leave bottom-scroll
  pagination stalled until refresh.
- **String/date utility edge cases** (`lib/utils/extensions.dart`,
  `lib/utils/format_utils.dart`): `extractDecimals` maps bare `"."` with
  `decimals > 0` to `0`; `ShortString.short` assumes `length >= 6`;
  `StringExtensions.capitalize` assumes non-empty string; `ZipTwoLists.zip` uses
  `indexOf` (incorrect on duplicate elements); `formatDateForTable` can format
  negative seconds on future timestamps.

---

## 4. How to Run Locally & in CI

### Prerequisites

- **Docker** running (on macOS with Colima, keep the checkout under `$HOME`
  so the VM can bind-mount it)
- **Flutter SDK** (`3.47.6`, matching `.github/actions/setup-flutter`) with
  dependencies installed (`flutter pub get`)
- **Python 3.9+** (standard library only; no `pip` packages required)

### Common Commands

```bash
# Build pinned Bend 2.0.40 and Lean v4.34.0 verdict Docker images (once; cached)
docker build -t syrius-bend:2.0.40 test/bend
docker build -f test/bend/Dockerfile.verdict -t syrius-bend:2.0.40-verdict test/bend

# Check all Bend proofs via root PROOF.bend (containerized)
./scripts/bend PROOF.bend --check-only
./scripts/bend PROOF.bend --verdict

# Run the Bend harness unit tests
python3 -B -m unittest discover -s test/bend -p 'test_*.py' -v

# Run the FULL 6-stage Bend gate (inventory, proofs, --verdict, oracle,
# Dart conformance, model mutations, real Dart source mutations)
./test/bend/run.sh

# Fast developer loop (skips Lean --verdict and mutations; prints PARTIAL PASS)
./test/bend/run.sh --fast

# Check a single domain during iteration (prints PARTIAL PASS)
./test/bend/run.sh --fast --only plasma_staking
./test/bend/run.sh --only tx_pipeline,node_sync

# Static inventory & proof-graph check only (no Docker or Flutter required)
./test/bend/run.sh --inventory-only

# Ordinary Syrius analysis & unit/widget suite (Docker-free; excludes chain & bend)
flutter analyze --no-pub
flutter test --no-pub --exclude-tags chain,bend
```

### CI Integration

- **`.github/workflows/bend.yml`** runs on pull requests to `develop`/`master`,
  pushes to `develop`, and `workflow_dispatch` (with configurable `depth` and
  `seed` inputs; PR and push runs deterministically default to `BEND_DEPTH=3`
  and `BEND_SEED=1`). It runs `flutter pub get --enforce-lockfile`, the Python
  harness unit tests, and the full `./test/bend/run.sh` gate, uploading
  `.bend-work/run-*/*.log` for 7 days on failure.
- **`.github/workflows/pr-validation.yml`** runs fast offline checks
  (`flutter analyze --no-pub`, `flutter test --no-pub test --exclude-tags chain,bend`,
  and generated-file freshness) without requiring Docker or Bend containers.
- **`dart_test.yaml`** declares the `bend` tag alongside `chain`.

---

## 5. Domain Law Catalog

### Summary Table (445 Total Lean-Verified Laws, 107 Oracle Ops / 833 Real Bend Oracle Vectors at Default `depth=3, seed=1`, 56 Fault Injections)

Stage 1 audits **398 laws across 12 proof suites** (root `LAWS.bend` + 11 domain
`LAWS.bend` files across **36 audited `.bend` files** — **291** oracle-exercised
domain laws and **107** model-only laws, of which **8** are normative targets),
and Stage 2 also checks and Lean-verifies the **47 shared lemmas** in
`test/bend/common/nat.bend`, for a grand total of **445 Lean-verified laws**.
Vector counts below reflect the default `--depth 3 --seed 1` run (exhaustive
short sequences + deterministic seeded histories scale with `--depth` and
`--seed`).

| Module / Domain | Laws | Model-Only (Normative) | Lean `--verdict` | Oracle Ops | Bend Oracle Vectors | Conformance Suite (`test/bend_conformance/`) | Model / Dart Faults | Primary Syrius `lib/` Scope |
|---|---:|---:|:---:|---:|---:|---|:---:|---|
| Root `LAWS.bend` / `PROOF.bend` | 17 | 17 (0) | Pass | — | — | All 11 suites + `test/bend/test_harness.py` | — | Cross-cutting invariants composing all 11 domains |
| `test/bend/common/nat.bend` | 47 | — | Pass | — | — | Imported by all 11 domain `PROOF.bend` suites | — | Shared constructive `Bool`/`Nat` algebra, order & refutation lemmas |
| `test/bend/amounts/` | 39 | 3 (0) | Pass | 11 | 84 | `amounts_conformance_test.dart` | 2 / 2 | `math_utils`, `extensions`, `input_validators`, `format_utils`, `plasma_tier_utils`, `password_strength_utils`, `amount_max_utils`, `tokens` (`compareAssets`/`sortAssets`), `url_protocol`, `exchange_rate` |
| `test/bend/wallet_lifecycle/` | 39 | 8 (0) | Pass | 9 | 95 | `wallet_lifecycle_conformance_test.dart` | 2 / 3 | `wallet_file`, `wallet_service`, `wallet_unlock_bloc`, `lock`, `auto_lock_utils`, `splash`, `hide_widget_cubit`, `onboarding` seed verification, `window_geometry` |
| `test/bend/tx_pipeline/` | 43 | 11 (0) | Pass | 10 | 84 | `tx_pipeline_conformance_test.dart` | 2 / 2 | `account_block_utils`, `pow_generating_status`, `auto_receive_tx`, `poll_until_confirmed`, `infinite_list_bloc`, `fetch_bloc`, `timer_cubit`, `balance`, `account_chain_stats` |
| `test/bend/node_sync/` | 42 | 12 (0) | Pass | 8 | 63 | `node_sync_conformance_test.dart` | 2 / 2 | `node_management`, `sync_info_extension`, `node_sync_status_cubit`, `node_utils`, `about`, `notifications`, `settings_wallet_options` |
| `test/bend/wallet_connect/` | 38 | 1 (0) | Pass | 14 | 91 | `wallet_connect_conformance_test.dart` | 2 / 3 | `wallet_connect_uri_utils`, `wallet_connect_request_utils`, `wallet_connect_metadata_utils`, `web3wallet_service` namespaces/revalidation, `nom_service` lock/send/signer/sign-payload guards |
| `test/bend/wc_crash_safety/` | 36 | 8 (0) | Pass | 12 | 58 | `wc_crash_safety_conformance_test.dart` | 2 / 2 | `sticky_fallback_secure_store`, `ConfirmingRelayClient`, `web3wallet_service` reset barriers, generation fencing, topic epochs & idempotent delivery |
| `test/bend/plasma_staking/` | 27 | 14 (5) | Pass | 10 | 83 | `plasma_staking_conformance_test.dart` | 2 / 5 | `fuse_plasma`, `fused_plasma`, `fusion_expiration_utils`, `fuse_plasma_validation_utils`, `cancel_plasma`, `plasma_stats`, `create_stake`, `stake_duration_utils`, `stakes`, `staking`, `stake_collect`, `stake_reward_utils`, `staking_rewards_history`, `cancel_timer` |
| `test/bend/pillars_sentinels/` | 26 | 12 (2) | Pass | 9 | 82 | `pillars_sentinels_conformance_test.dart` | 2 / 6 | `pillars`, `pillar_rules_utils`, `create_pillar_*`, `deploy_pillar`, `update_pillar*`, `revoke_pillar`, `delegation*`, `undelegate`, `sentinels*`, `pillar_qsr_deposit_utils`, `pillar_momentum_utils` |
| `test/bend/tokens_zts/` | 28 | 5 (0) | Pass | 8 | 78 | `tokens_zts_conformance_test.dart` | 2 / 3 | `tokens`, `create_token*`, `token_validation_utils`, `mint_token`, `burn_token`, `transfer_token`, `token_favorite`, `search_token`, `token_capabilities`, `zts_utils` |
| `test/bend/p2p_htlc/` | 35 | 10 (1) | Pass | 9 | 61 | `p2p_htlc_conformance_test.dart` | 2 / 3 | `p2p_swap`, `initial_htlc_validation`, `htlc_window_utils`, `reclaim_deposit`, `htlc_swaps_dao`, 2-phase SQLCipher rekey, legacy migrator, `swap_storage_error_sanitizer` |
| `test/bend/accelerator/` | 28 | 6 (0) | Pass | 7 | 54 | `accelerator_conformance_test.dart` | 2 / 3 | `accelerator_pillar`, `accelerator_projects`, `accelerator_lifecycle_utils`, `accelerator_project_details`, `accelerator_vote_summary`, `accelerator_donation_stepper`, `create_project_stepper`, `create_phase_stepper`, `update_phase_stepper` |
| **Total** | **445** | **107 (8)** | **13/13 Pass** | **107** | **833** | **11 suites** | **22 / 34** | **All 11 wallet domains + root + shared Nat library** |

---

### Root Cross-Cutting Specification — `LAWS.bend` / `PROOF.bend` (17 laws)

Composes all 11 domain proof suites into a single top-level verification
entrypoint (`./scripts/bend PROOF.bend --verdict`) and proves end-to-end
cross-domain invariants spanning wallet locking, hardware-wallet boundaries,
HTLC preemption, reset barriers, chain-ID alignment, plasma hierarchies,
zero-balance spend protection, revision fencing, preimage isolation, governance
roles, asset ordering, sync/clock coherence, and parallel-let audit equivalence:

- **Laws (17)**: `locked_wallet_blocks_sensitive_ops`,
  `hardware_wallet_safety_boundaries`, `active_incoming_htlc_protection`,
  `active_incoming_htlc_preserves_autoreceive_pool`,
  `reset_barrier_and_splash_retry_safety`,
  `chain_id_mismatch_blocks_node_wc_and_htlc`,
  `wc_revalidation_chain_mismatch_rejects_5003`,
  `plasma_thresholds_and_tiers_coherence`,
  `plasma_sufficiency_cross_domain_hierarchy`,
  `zero_balance_rejects_all_spend_ops`,
  `stale_revision_fences_ui_across_domains`, `security_defense_in_depth`,
  `sanitizer_zero_preimage_leakage_and_key_isolation`,
  `pillar_governance_and_role_coherence`,
  `token_and_asset_ordering_coherence`,
  `sync_threshold_and_clock_skew_coherence`, `root_audit_par_equiv_seq`.

---

### Shared Lemma Library — `test/bend/common/nat.bend` (47 laws + 5 helpers)

Provides constructive proofs unavailable in Bend's `Base` library:
- **Refutation & Bool equality helpers (5)**: `Not.true`, `Not.false`,
  `false_is_not_true`, `true_is_not_false`, `bool_eq`.
- **Bool laws (13)**: `not_not`, `and_true_right`, `and_false_right`,
  `or_false_right`, `or_true_right`, `and_comm`, `or_comm`, `and_true_left`,
  `and_true_right_elim`, `or_false_left`, `or_false_right_elim`, `bool_eq_refl`,
  `bool_eq_sound`.
- **Nat arithmetic laws (11)**: `add_zero`, `add_succ`, `add_assoc`, `add_comm`,
  `add_swap`, `sub_zero`, `sub_self`, `sub_add`, `sub_cancel_add_left`,
  `sub_cancel_add_right`, `mul_zero_right`.
- **Nat equality, order & minimum laws (23)**: `is_eq_same`, `is_eq_sym`,
  `is_eq_sound`, `is_le_refl`, `is_le_zero`, `is_le_zero_eq`, `is_le_add_right`,
  `is_le_add_left`, `is_lt_irrefl`, `lt_ge_disjoint`, `le_gt_disjoint`,
  `is_ge_as_le`, `is_gt_as_lt`, `not_lt_is_ge`, `not_le_is_gt`,
  `lt_implies_le`, `le_trans`, `lt_trans`, `le_antisym`, `add_monotone_le`,
  `min_le_left`, `min_le_right`, `min_self`.

---

### Verified Domain: `plasma_staking` (27 laws)

- **Scope**: Plasma-per-QSR scaling, operation plasma tiers (`21k..252k`), fuse
  preconditions (minimum `10 QSR`, integer amount, balance & beneficiary),
  fusion revocation height boundary, clean cancel-timer termination, pagination
  slices, staking durations (`1..12` months), lock expiration, QSR-only staking
  reward collection, epoch-day monotonicity, and parallel-let check equivalence
  (`parallel_plasma_staking_check`).
- **Laws (27)**: `plasma_for_qsr_zero`, `plasma_for_qsr_additive`,
  `plasma_for_qsr_monotone`, `op_plasma_u32_exact`, `op_plasma_strict_order`,
  `meets_plasma_monotone`, `fuse_rejects_zero_balance`,
  `fuse_rejects_below_min`, `fuse_rejects_above_balance`,
  `fuse_requires_integer_and_beneficiary`, `fusion_status_exact_partition`,
  `fusion_eq_boundary_locked_zero`, `fusion_above_exp_revocable`,
  `cancel_timer_stopped_idempotent`, `cancel_timer_terminates_cleanly`,
  `cancel_timer_no_storm_after_zero`, `page_slice_start_le_end`,
  `page_slice_end_le_len`, `stake_months_bounds`,
  `stake_duration_strictly_monotone`, `stake_duration_u32_exact`,
  `create_stake_guards`, `stake_lock_expired_at_or_past`,
  `stake_lock_positive_countdown_before_exp`,
  `stake_collect_qsr_only_and_history_gate`, `epoch_day_monotone`,
  `parallel_plasma_staking_equiv`.

---

### Verified Domain: `pillars_sentinels` (26 laws)

- **Scope**: Pillar vs Sentinel protocol constants (plasma, ZNN collateral, QSR
  burn/cost), monotone creation stepper gates (`StepPlasma -> StepQsr -> StepZnn -> StepDeploy -> StepDone`),
  QSR deposit clamping and pie-chart conservation (`clamped + remaining == cost`),
  deposit/withdrawal confirmation predicates, producer-address wallet-exclusion
  rule, reward-share conservation (`0..100%`), update stepper navigation, safe
  uptime percentage bounds, delegation eligibility & undelegation, Sentinel
  authorization matrix, role-specific reward collection, and 3-way parallel-let
  spawn readiness (`parallel_spawn_readiness`).
- **Laws (26)**: `role_protocol_constants`, `create_step_monotone`,
  `create_step_plasma_gate`, `create_step_qsr_gate`, `create_step_znn_gate`,
  `create_step_deploy_gate_and_done_absorbing`, `max_qsr_deposit_le_balance`,
  `max_qsr_deposit_never_overdeposits`, `qsr_covered_implies_zero_remaining`,
  `qsr_pie_conservation`, `can_withdraw_iff_positive`,
  `deposit_confirm_rejects_zero_amount`, `deposit_confirm_strictly_increases`,
  `withdraw_confirm_with_snapshot_decreases`,
  `withdraw_confirm_without_snapshot_zero`, `producer_rejects_wallet_address`,
  `deploy_pillar_rejects_wallet_producer`, `reward_pct_conservation`,
  `reward_pct_rejects_over_100`, `update_step_navigation`,
  `safe_uptime_zero_expected`, `safe_uptime_bounded_100`, `delegation_rules`,
  `sentinel_authorization_matrix`, `reward_collect_pillar_vs_sentinel`,
  `parallel_spawn_readiness_equiv`.

---

### Verified Domain: `tokens_zts` (28 laws)

- **Scope**: ZTS issuance constants (`189k` plasma, `1 ZNN` fee), monotone
  issuance stepper gates, token name/symbol/domain/decimals validation (including
  reserved `ZNN`/`QSR` symbol rejection), mintable vs non-mintable supply rules,
  `TokenCapabilities` ownership & supply-cap authorization, mint/burn supply and
  balance conservation, trusted-token predicate, favorite toggle single-flight,
  action disjointness, completion guarding & recovery state machine, search
  cache invalidation & native-coin exclusion, and 4-way parallel-let metadata
  validation (`parallel_token_metadata_valid`).
- **Laws (28)**: `issue_constants_exact`, `issue_step_monotone`,
  `issue_plasma_gate`, `issue_prerequisite_gates`, `token_name_bounds`,
  `token_symbol_rejects_reserved`, `token_symbol_domain_decimals_bounds`,
  `supply_mintable_rejects_zero_max`,
  `supply_non_mintable_effective_max_eq_total`, `supply_valid_total_le_eff_max`,
  `supply_valid_eff_max_positive`, `caps_transfer_iff_owner`,
  `caps_non_mintable_never_mints`, `caps_full_supply_never_mints`,
  `caps_mint_requires_owner`, `caps_burn_protocol_rule`,
  `mint_conserves_max_supply`, `mint_strictly_increases_supply`,
  `burn_conserves_balance`, `burn_reduces_total_supply`,
  `trusted_token_iff_native_or_fav`, `fav_loading_drops_concurrent`,
  `fav_idempotency_and_recovery`, `fav_actions_disjoint`,
  `fav_non_loading_ignores_completions`, `search_trimmed_settled_not_loading`,
  `search_excludes_native_and_invalidates_cache`, `parallel_token_metadata_equiv`.

---

### Verified Domain: `tx_pipeline` (43 laws)

- **Scope**: Transaction sync preconditions (`< 20` lag boundary), wallet/address
  publish fencing across lock & wallet-access boundaries, re-entrant per-address
  lock balancing, PoW generating-status reference counting & edge-only emissions,
  hardware-wallet review deferral under plasma generation, `AutoReceiveTxWorker`
  sync/dedup/disabled-clear/HTLC-preemption/single-flight/error-retention rules,
  `pollUntilConfirmed` deadline non-overshoot, `InfiniteListBloc` stale-request
  generation fencing, `FetchBloc` in-flight ref-counting, `TimerState` invariant
  preservation, balance population partition, Euclidean `ceil_div` page-count
  coverage & minimality, and 4-way parallel-let batch evaluation
  (`eval_tx_batch_par`).
- **Laws (43)**: `tx_sync_done_always_synced`, `tx_sync_zero_target_not_synced`,
  `tx_sync_boundary_19_synced`, `tx_sync_boundary_20_unsynced`,
  `tx_precond_unsynced_rejected`, `tx_precond_addr_not_in_wallet_rejected`,
  `tx_precond_wallet_locked_rejected`,
  `tx_publish_fence_locked_after_lock_aborts`,
  `tx_publish_fence_swapped_after_lock_aborts`,
  `tx_publish_fence_changed_in_access_aborts`,
  `lock_acquire_increments_and_present`, `lock_release_evicts_iff_zero`,
  `lock_balanced_acquire_release`, `lock_nested_balanced_n`,
  `pow_status_matches_count`, `pow_done_at_zero_clamps`,
  `pow_balanced_nesting_returns_idle`, `pow_edge_only_emission`,
  `hw_review_deferred_iff_plasma`, `auto_receive_add_hash_requires_sync`,
  `auto_receive_add_hash_dedup`, `auto_receive_add_hash_enqueues`,
  `auto_receive_disabled_clears_pool`,
  `auto_receive_htlc_preempts_preserving_pool`,
  `auto_receive_single_flight_rejects_reentry`,
  `auto_receive_ok_and_already_received_pop_head`,
  `auto_receive_other_error_preserves_head`, `auto_receive_seq_monotonic`,
  `poll_never_sleeps_past_deadline`, `poll_confirmed_returns_true`,
  `poll_cancelled_returns_false`, `poll_transient_error_continues`,
  `il_stale_first_page_discarded`, `il_stale_more_page_discarded`,
  `il_more_noop_when_max`, `il_more_noop_on_addr_mismatch`,
  `il_has_reached_max_iff_short`, `fetch_loading_iff_inflight`,
  `timer_step_preserves_valid`, `balance_non_empty_partition`,
  `account_chain_stats_ceil_div_covers`, `account_chain_stats_ceil_div_minimal`,
  `tx_batch_par_equiv_seq`.

---

### Verified Domain: `node_sync` (42 laws)

- **Scope**: `NodeManagementBloc` busy-drop guard, chain-ID mismatch pause &
  TOCTOU drift re-prompt, cancel rollback vs disconnected-retry fallback,
  pre-commit rollback vs post-commit non-rollback, custom node CRUD protections
  (default/community immutability, length `<= 80`, duplicate rejection, rename &
  delete selection updates and non-selected preservation), auto-receive
  persistence rollback, `NodeSyncStatusCubit` hysteresis & disjoint
  `isSynced`/`isClearlyBehind` bands, symmetric clock-skew warning (`> 300s`
  only when synced), `AboutBloc` 3-RPC partial-availability lattice,
  `HiveNotificationsRepository` FIFO capacity & descending timestamp sort,
  `NotificationsBloc` persist-before-banner & monotonic revision dismiss,
  lock-screen navigation guard, `SettingsWalletOptionsBloc` persistence & macOS
  notification permission guards, and 4-way parallel-let batch evaluation
  (`eval_node_sync_batch_par`).
- **Laws (42)**: `node_busy_drops_confirm`, `node_mismatch_pauses_without_saving`,
  `node_proceed_toctou_drift_reprompts`,
  `node_cancel_reconnect_ok_restores_prev`,
  `node_cancel_reconnect_fail_marks_disconnected_retry`,
  `node_precommit_error_rolls_back`, `node_postcommit_notify_error_never_rolls_back`,
  `node_custom_protects_default_and_community`, `node_add_rejects_duplicate`,
  `node_edit_rejects_empty`, `node_edit_rejects_over_80`,
  `node_edit_rejects_default`, `node_edit_rejects_community`,
  `node_edit_rejects_duplicate`, `node_rename_updates_selected`,
  `node_rename_preserves_other_selected`, `node_delete_falls_back_to_confirmed`,
  `node_delete_preserves_other_selected`, `node_auto_receive_rollback_on_save_fail`,
  `sync_hysteresis_retains_on_jitter`, `sync_hysteresis_transitions_on_sync_done`,
  `sync_hysteresis_transitions_on_clearly_behind`,
  `sync_non_done_synced_and_behind_disjoint`, `clock_skew_silent_when_unsynced`,
  `clock_skew_symmetric`, `clock_skew_boundary_300_silent`,
  `clock_skew_boundary_301_warns`, `about_failure_iff_all_three_fail`,
  `about_populated_carries_first_error`, `notif_repo_zero_cap_clears`,
  `notif_repo_add_preserves_cap`, `notif_repo_load_len_exact_min`,
  `notif_repo_load_sorted_desc`, `notif_bloc_repo_fail_leaves_banner_unchanged`,
  `notif_bloc_add_strictly_bumps_revision`, `notif_bloc_dismiss_matching_clears`,
  `notif_bloc_dismiss_stale_noop`, `notif_bloc_dismiss_none_always_clears`,
  `notif_lock_screen_hides_see_more`, `wallet_opt_persist_fail_rolls_back`,
  `wallet_opt_macos_requires_permission`, `node_sync_batch_par_equiv_seq`.

---

### Verified Domain: `amounts` (39 laws)

- **Scope**: `MathUtils.bigMin`/`bigMax` lattice laws & sum conservation,
  canonical base-10 decimal scaling/truncation & roundtrip,
  `InputValidators.correctValue` zero-max/blank/parse/precision/range guards,
  `compareAssets`/`sortAssets` strict weak ordering (`ZNN < QSR < ZTS`),
  4-tier `PlasmaTier` monotonicity, exact threshold boundaries & color-tooltip
  bijection, `classifyPasswordStrength` validity-gated monotonicity & list
  equality soundness, exchange-rate zero guard, `resolveMaxAmountText` clamping
  & noop idempotency, address label validation (`1..80`, non-duplicate),
  `ProtocolHandler.getArguments` `'%s'` placeholder guard, and parallel-let
  batch evaluation equivalence (`eval_batch_par`).
- **Laws (39)**: `big_min_comm`, `big_max_comm`, `big_min_idem`, `big_max_idem`,
  `big_min_le_bounds`, `big_max_ge_bounds`, `big_min_max_conservation`,
  `pow10_positive`, `extract_decimals_zero`, `decimals_canonical_roundtrip`,
  `scale_frac_truncation_exact`, `correct_value_empty_balance_rejected`,
  `correct_value_blank_iff`, `correct_value_parse_error_rejected`,
  `correct_value_too_many_decimals_rejected`,
  `correct_value_max_below_min_rejected`, `correct_value_gt_max_rejected`,
  `correct_value_lt_min_rejected`, `correct_value_at_min_iff`,
  `correct_value_at_max_iff`, `asset_cmp_irrefl`, `asset_cmp_antisym`,
  `asset_cmp_trans`, `asset_order_hierarchy`, `plasma_tier_monotone`,
  `plasma_tier_exact_boundaries`, `plasma_color_tooltip_agreement`,
  `password_invalid_never_medium_or_strong`, `password_strength_monotone_valid`,
  `password_match_refl`, `password_match_sound`, `exchange_rate_zero_guard`,
  `exchange_rate_positive_defined`, `resolve_max_always_clamps`,
  `resolve_max_update_noop_iff_equal`, `address_label_validation_iff`,
  `protocol_args_rejects_empty_or_missing_placeholder`,
  `protocol_args_accepts_nonempty_with_placeholder`, `batch_par_eq_seq`.

---

### Verified Domain: `wallet_lifecycle` (39 laws)

- **Scope**: `_WalletFileLifecycle` mutual exclusion, permanent close & draining
  on end-access, keystore JSON schema minimum lengths (`salt >= 8B`,
  `cipher >= 16B`, `nonce >= 12B`), wallet-type dispatch, software-only unlocked
  backup gating, `WalletUnlockBloc` empty-password noop, failed-attempt
  accounting, auto-erase at limit, Ledger/IO error preservation, remaining
  attempt conservation & first-unlock init tracking, `LockBloc` monotonic
  sequence, locked activity suppression, active incoming HTLC auto-lock
  suppression & manual handle clearing, `SplashBloc` routing and destructive
  retry gating, `HideWidgetCubit` password-free hide vs password-gated unhide,
  seed-confirmation multiset conservation & mismatch reset, window geometry
  minimum-size/non-negative coordinate clamping & idempotency, and parallel-let
  lifecycle equivalence (`eval_lifecycle_par`).
- **Laws (39)**: `wallet_file_mutual_exclusion`, `wallet_file_idle_grants_access`,
  `wallet_file_closed_permanent_step`, `wallet_file_closed_permanent_run`,
  `wallet_file_close_idempotent`, `wallet_file_closing_completes_on_end_access`,
  `keystore_schema_requires_min_lengths`, `keystore_schema_rejects_short_salt`,
  `wallet_type_dispatch_sound`, `backup_blocked_when_locked_or_hardware`,
  `backup_allowed_for_unlocked_software`, `unlock_empty_password_noop`,
  `unlock_incorrect_increments_failed`, `unlock_auto_erase_at_limit`,
  `unlock_below_limit_stays_failure`, `unlock_ledger_error_preserves_failed`,
  `unlock_io_error_preserves_failed`, `unlock_success_resets_and_marks_init`,
  `unlock_first_vs_subsequent_init`, `unlock_remaining_conservation`,
  `lock_sequence_monotone`, `lock_activity_suppressed_when_locked`,
  `lock_autolock_suppressed_by_htlc`, `lock_manual_clears_handle_and_locks`,
  `splash_delete_cache_exits_app`, `splash_no_wallet_routes_access`,
  `splash_with_node_or_dev_routes_home`,
  `splash_normal_without_node_routes_node_mgmt`,
  `splash_retry_blocks_non_destructive_and_non_clearing`,
  `splash_retry_allows_destructive_clearing_failure`,
  `hide_widget_hide_never_needs_password`,
  `hide_widget_unhide_requires_password`, `seed_drop_conserves_multiset`,
  `seed_verify_mismatch_clears_all`, `seed_verify_iff_all_matched`,
  `window_size_meets_minimums`, `window_coord_nonneg_fallback`,
  `window_geometry_idempotent`, `lifecycle_par_eq_seq`.

---

### Verified Domain: `wallet_connect` (38 laws)

- **Scope**: WalletConnect v2 URI extraction (version `2`, topic/relay/symKey
  required, idempotency, Windows slash-query handling), interactive request
  dedup keys, JSON-RPC / Reown error-code preservation with `5000` fallback,
  Reown Verify API scam dominance & strict severity precedence
  (`Scam > Invalid > Unverified > Verified`), HTTP/HTTPS URL sanitization
  blocking `javascript:`/`file:`/`data:`/empty-host links, display-value
  fallbacks, required/approved Zenon namespace & active-chain enforcement,
  domain-separated signed-message payload injectivity & disjointness from
  unprefixed hashes, `znn_send` account-block validation (`userSend`, empty
  `fromBlockHash`, block/session/active chain equality, `5003` rejection),
  owned-only signer address resolution, interactive request revalidation
  (locked wallet, inactive session, non-pending `5005`, chain drift `5003`),
  URI card revision clearing, and 3-way parallel-let send preflight
  (`parallel_send_preflight`).
- **Laws (38)**: `wc_uri_extracted_requires_valid_v2_fields`,
  `wc_uri_rejects_non_v2`, `wc_uri_rejects_missing_required_fields`,
  `wc_uri_extract_idempotent`, `request_key_distinct_ids_never_collide`,
  `request_key_with_id_ignores_params`, `wc_error_preserves_known_codes`,
  `wc_error_unknown_maps_to_5000`, `verify_scam_cases_complete`,
  `verify_scam_dominates_all_validations`, `verify_severity_strict_precedence`,
  `verify_verified_requires_non_scam_valid`,
  `sanitize_http_url_allows_only_http_https_with_host`,
  `sanitize_http_url_blocks_dangerous_schemes_and_empty_host`,
  `display_value_fallback_on_empty_or_null`,
  `namespace_rejects_unsupported_active_chain`,
  `namespace_rejects_non_zenon_required`,
  `namespace_accepted_implies_all_requirements_supported`,
  `approved_namespaces_only_active_chain_and_supported`,
  `approved_namespaces_chains_is_singleton_active`,
  `approved_namespaces_empty_grants_all_supported`,
  `signed_message_payload_injective`, `signed_message_payload_has_domain_prefix`,
  `signed_message_payload_length_lower_bound`,
  `signed_message_payload_disjoint_from_unprefixed_hash`,
  `send_block_valid_implies_all_invariants`,
  `send_block_any_violation_rejected_5003`,
  `signer_null_or_empty_defaults_to_active`, `signer_owned_address_allowed`,
  `signer_foreign_address_rejected`, `revalidate_rejects_locked_wallet`,
  `revalidate_rejects_inactive_session`, `revalidate_rejects_non_pending_5005`,
  `revalidate_rejects_chain_drift_5003`, `uri_card_clears_iff_revision_matches`,
  `parallel_send_preflight_equiv_sequential`,
  `parallel_preflight_accepts_valid_send`,
  `parallel_preflight_blocks_scam_or_locked`.

---

### Verified Domain: `wc_crash_safety` (36 laws)

- **Scope**: `StickyFallbackSecureStore` authoritative sticky-forever mode,
  authoritative/legacy boot precedence, transient empty-keychain preservation,
  fallback-flag protection & foreign-key manifest isolation, `deleteAll`
  preservation of flag and foreign entries, reconciliation precedence
  (`clearedAll`, tombstones, replaced keys, missing-subkey merge), crash-safe
  migration commit ordering (entries before marker) & reconciliation cleanup
  ordering (marker before transient copies), `ConfirmingRelayClient` strictly
  monotonic op sequences, failed-unsubscribe ID preservation, stale/concurrent
  unsubscribe fencing, cold-restart restore guard & capped tracking bounds,
  `Web3WalletService` durable reset markers, admission barriers, session
  finalization generation fencing, topic unsubscribe epoch obsolescence,
  provisional/orphan pairing protection, idempotent request delivery (no
  double-execution of completed or cached-unsent handlers), and 3-way
  parallel-let crash-safety gate (`parallel_wc_crash_safety_gate`).
- **Laws (36)**: `authoritative_fallback_is_sticky_forever`,
  `authoritative_and_legacy_markers_boot_authoritative`,
  `transient_restart_empty_keychain_preserves_transient_keys`,
  `fallback_flag_never_deleted_or_lazy_read`,
  `foreign_keys_isolated_from_delete_and_manifest_read`,
  `delete_all_preserves_flag_and_foreign_entries`,
  `reconcile_cleared_all_wipes_os`, `reconcile_deleted_tombstone_deletes_os`,
  `reconcile_replaced_key_transient_wins`, `reconcile_absent_os_transient_wins`,
  `reconcile_existing_os_merges_only_missing_subkeys`,
  `migration_writes_entries_before_authoritative_marker`,
  `migration_marker_failure_preserves_secure_mode`,
  `reconciliation_deletes_marker_before_transient_copies`,
  `relay_op_seq_strictly_monotonic`,
  `relay_failed_unsub_preserves_id_and_marks_unconfirmed`,
  `relay_stale_unsub_fence_preserves_topic_map_and_status`,
  `relay_concurrent_unsub_fence_blocks_remarking`,
  `relay_restore_never_overwrites_active_or_fresher`,
  `relay_capped_tracking_bounded_by_cap`,
  `reset_aborts_before_deletes_if_marker_fails`,
  `reset_marker_clears_when_empty_and_same_epoch`,
  `reset_marker_retained_when_unfinished_or_epoch_advanced`,
  `reset_admission_barrier_blocks_pair_and_approve`,
  `finalize_approved_session_rejects_advanced_generation`,
  `topic_unsub_epoch_not_obsolete_when_current_or_newer`,
  `topic_unsub_epoch_strictly_older_always_obsolete`,
  `active_subscription_fences_prior_deferred_unsub`,
  `provisional_purge_never_deletes_confirmed_pairing`,
  `orphan_cleanup_protects_live_pairings`,
  `idempotent_delivery_never_reexecutes_completed_or_cached`,
  `idempotent_delivery_cached_retries_only_delivery`,
  `idempotent_delivery_post_handler_never_reverts_to_fresh`,
  `parallel_crash_safety_gate_equiv_sequential`,
  `parallel_crash_safety_gate_accepts_safe_state`,
  `parallel_crash_safety_gate_blocks_flag_or_reset_or_stale_epoch`.

---

### Verified Domain: `p2p_htlc` (35 laws)

- **Scope**: HTLC join safety-window arithmetic (participants, unused/unique
  hashlock, 24h cap, parametric & 420-minute preimage safety margin), unlock vs
  reclaim mutual exclusion with strict 10-minute reclaim buffer, swap lifecycle
  transitions (initial states, pending->active, unlock completion & preimage
  recording, reclaim unsuccessful, expiry, terminal absorbing `Completed`, safe
  deletion partition), funded HTLC role bijection, reclaim address derivation
  (hardware wallet never derives, unexpired never derives, software lookahead
  bounded to `<= 50`), single-flight auto-unlock mutex & 2-minute cooldown,
  32-byte SQLCipher key validation, processed-block chain matching, swap pruning
  protecting unresolved swaps, 2-phase atomic SQLCipher rekey/rollback with
  guaranteed sync restart, crash recovery & stale backup cleanup, legacy Hive
  migration safety, zero-preimage-leakage & 5-layer-cap error sanitization, and
  parallel-let swap safety check (`parallel_swap_safety_check`).
- **Laws (35)**: `safe_join_requires_participants`,
  `safe_join_requires_unused_and_unique`, `safe_join_requires_duration_caps`,
  `safe_join_window_margin_parametric`, `safe_join_guarantees_preimage_margin`,
  `unlock_reclaim_mutually_exclusive`, `unlock_has_strict_reclaim_buffer`,
  `start_and_join_initial_states`, `create_flips_pending_to_active`,
  `unlock_incoming_completes_and_records_preimage`,
  `unlock_outgoing_active_completes`, `reclaim_non_completed_funded_unsuccessful`,
  `expire_moves_pending_and_active_only`, `completed_is_terminal_absorbing`,
  `safe_deletion_partition`, `funded_htlc_direction_bijection`,
  `reclaim_hw_rejects_missing_never_derives`, `reclaim_unexpired_never_derives`,
  `reclaim_sw_lookahead_exact_and_bounded`, `reclaim_sw_out_of_window_rejected`,
  `auto_unlock_mutex_blocks_reentry`, `auto_unlock_cooldown_blocks_retry`,
  `auto_unlock_cooldown_expires_allows_retry`, `sqlcipher_key_requires_32_bytes`,
  `sqlcipher_key_rejects_invalid_bytes_and_accepts_32`,
  `processed_block_requires_matching_chain`,
  `pruning_never_evicts_unresolved_swaps`, `begin_rekey_retains_old_backup`,
  `change_password_atomicity_commit_and_rollback`,
  `change_password_always_restarts_sync`,
  `open_crash_recovery_and_stale_backup_cleanup`, `legacy_migration_safety`,
  `sanitizer_zero_preimage_leakage`, `sanitizer_five_layer_cap`,
  `parallel_swap_safety_check_equiv`.

---

### Verified Domain: `accelerator` (28 laws)

- **Scope**: Pillar owner-over-producer precedence & vote-method resolution
  (`ByName` vs `ByProdAddress`), non-pillar voting prohibition & voting-status
  gate, quorum arithmetic (`0` when no pillars, `1 <= quorum <= n`, strictly
  `> 33%`), abstain counting for quorum but not majority, strict majority
  (ties fail), clamped 3-segment & quorum progress-bar conservation with
  zero-total safety, pillar vs non-pillar project visibility, voting-tag
  stripping upon losing pillar role & strict AND filter conjunction,
  non-negative donation leg validation & partial-failure no-double-ZNN retry
  safety, project budget caps (`1 ZNN` fee, `10..5000 ZNN`, `100..50000 QSR`) &
  remaining-funds conservation, sequential phase creation/update gates, and
  parallel-let accelerator audit (`parallel_accelerator_audit`).
- **Laws (28)**: `pillar_owner_takes_precedence`,
  `pillar_owner_beats_earlier_producer`, `pillar_producer_fallback`,
  `vote_method_owner_vs_producer`, `non_pillar_never_votes`,
  `can_submit_vote_requires_pillar_and_voting`, `quorum_zero_when_no_pillars`,
  `quorum_bounded_by_one_and_n`, `quorum_strictly_exceeds_33_percent`,
  `abstains_count_for_quorum_not_majority`, `majority_strict_tie_fails`,
  `clamped_bar_zero_total_safe`, `clamped_bar_3_conserved`,
  `quorum_progress_bar_conserved`, `pillar_sees_all_statuses`,
  `non_pillar_visibility_exact`, `losing_pillar_strips_voting_tags`,
  `filter_tags_strict_and_conjunction`, `donation_rejects_negative_legs`,
  `donation_valid_bounds_and_positive`, `donation_partial_failure_no_double_znn`,
  `donation_both_succeed_reaches_submitted`, `valid_project_budget_enforces_caps`,
  `budget_conservation`, `phase_funds_never_overspend_total`,
  `sequential_phase_create_and_update_gate`,
  `can_create_phase_requires_owner_and_active`, `parallel_accelerator_audit_equiv`.

---

## 6. Maintenance Policy

When modifying verified wallet logic or extending formal coverage:

1. State or update the contract in `LAWS.bend` (or `test/bend/<domain>/LAWS.bend`),
   implement the model change in `model.bend`, and prove it in `PROOF.bend`.
2. Keep `test/bend/specs.py`, `test/bend_conformance/*_test.dart`,
   `test/bend/coverage.json`, and this catalog in sync with code changes.
3. Add deliberate model and Dart source faults whenever adding a new protection
   so the gate proves it would detect regressions.
4. Treat edits that weaken a law as explicit contract changes requiring review;
   never weaken a law merely to make a check pass.
5. Run `./test/bend/run.sh`, `flutter analyze --no-pub`, and
   `flutter test --no-pub test --exclude-tags chain,bend` before
   committing.
