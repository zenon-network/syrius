import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/model/block_data.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/utils/htlc_info_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'initial_htlc_validation_event.dart';
part 'initial_htlc_validation_state.dart';

/// Fetches account blocks created after a Unix timestamp.
typedef AccountBlocksAfterTimeFetcher =
    Future<List<AccountBlock>> Function(Address address, int time);

/// Fetches and validates an initial HTLC before joining a swap.
class InitialHtlcValidationBloc
    extends Bloc<InitialHtlcValidationEvent, InitialHtlcValidationState> {
  /// Creates an [InitialHtlcValidationBloc].
  InitialHtlcValidationBloc({
    required this._accountBlocksAfterTimeFetcher,
    required this._htlcSwapRepository,
    required this._walletAddresses,
    required this._zenon,
  }) : super(const InitialHtlcValidationInitial()) {
    on<InitialHtlcValidationRequested>(_onValidationRequested);
    on<InitialHtlcValidationRefreshed>(_onValidationRefreshed);
  }

  final AccountBlocksAfterTimeFetcher _accountBlocksAfterTimeFetcher;
  final HtlcSwapRepository _htlcSwapRepository;
  final Set<String> _walletAddresses;
  final Zenon _zenon;

  FutureOr<void> _onValidationRequested(
    InitialHtlcValidationRequested event,
    Emitter<InitialHtlcValidationState> emit,
  ) async {
    try {
      emit(const InitialHtlcValidationLoading());

      final HtlcInfo htlc = await _zenon.embedded.htlc.getById(event.id);

      _validateParticipants(htlc);
      await _validateUnusedDeposit(htlc);
      _validateExpiration(htlc);
      await _validateCreationDuration(htlc);
      await _validateUniqueHashLock(htlc);

      final Token? token = await _zenon.embedded.token.getByZts(
        htlc.tokenStandard,
      );
      if (token == null) {
        throw LocalizedSyriusException(
          SyriusErrorCode.unableToRetrieveTokenInformation,
        );
      }
      final AccountInfo accountInfo = await _zenon.ledger
          .getAccountInfoByAddress(htlc.hashLocked);

      emit(
        InitialHtlcValidationDone(
          accountInfo: accountInfo,
          htlc: htlc,
          token: token,
        ),
      );
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(InitialHtlcValidationFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(sanitizeSwapErrorForLogging(error), stackTrace);
      emit(InitialHtlcValidationFailure(exception: FailureException()));
    }
  }

  void _validateParticipants(HtlcInfo htlc) {
    if (!_walletAddresses.contains(htlc.hashLocked.toString())) {
      throw LocalizedSyriusException(SyriusErrorCode.depositNotIntendedForYou);
    }
    if (_walletAddresses.contains(htlc.timeLocked.toString())) {
      throw LocalizedSyriusException(SyriusErrorCode.cannotJoinOwnSwap);
    }
  }

  Future<void> _validateUnusedDeposit(HtlcInfo htlc) async {
    if (await _htlcSwapRepository.getSwapByHtlcId(htlc.id.toString()) != null) {
      throw LocalizedSyriusException(SyriusErrorCode.depositAlreadyUsedInSwap);
    }
    if (await _htlcSwapRepository.getSwapByHashLock(htlc.hashLockHex) != null) {
      throw LocalizedSyriusException(
        SyriusErrorCode.depositHashlockAlreadyUsedInSwap,
      );
    }
  }

  void _validateExpiration(HtlcInfo htlc) {
    final int now = DateTime.now().unixTimestamp;
    final Duration remainingDuration = htlc.remainingDurationAt(now);
    if (remainingDuration.inSeconds <= 0) {
      throw LocalizedSyriusException(SyriusErrorCode.depositExpired);
    }
    if (!htlc.canBeSafelyJoinedAt(now)) {
      throw LocalizedSyriusException(
        SyriusErrorCode.depositExpiresTooSoonForSafeSwap,
      );
    }

    _validateMaximumDuration(remainingDuration);
  }

  Future<void> _validateCreationDuration(HtlcInfo htlc) async {
    final AccountBlock? creationBlock = await _zenon.ledger
        .getAccountBlockByHash(htlc.id);
    final int? creationTime =
        creationBlock?.confirmationDetail?.momentumTimestamp;
    if (creationTime == null) {
      throw LocalizedSyriusException(
        SyriusErrorCode.unableToVerifyDepositCreationTime,
      );
    }

    _validateMaximumDuration(
      Duration(seconds: htlc.expirationTime - creationTime),
    );
  }

  void _validateMaximumDuration(Duration duration) {
    if (duration > kMaxAllowedInitialHtlcDuration) {
      throw LocalizedSyriusException.depositDurationTooLong(
        maxHours: kMaxAllowedInitialHtlcDuration.inHours,
      );
    }
  }

  Future<void> _validateUniqueHashLock(HtlcInfo htlc) async {
    final List<AccountBlock> htlcBlocks = await _accountBlocksAfterTimeFetcher(
      htlcAddress,
      htlc.expirationTime - kMaxAllowedInitialHtlcDuration.inSeconds,
    );
    final bool hasDuplicate = htlcBlocks.any(
      (AccountBlock block) => _isConflictingHtlcBlock(block, htlc),
    );
    if (hasDuplicate) {
      throw LocalizedSyriusException(SyriusErrorCode.hashlockNotUnique);
    }
  }

  bool _isConflictingHtlcBlock(AccountBlock block, HtlcInfo htlc) {
    if (block.blockType != BlockTypeEnum.contractReceive.index) {
      return false;
    }

    final AccountBlock? pairedBlock = block.pairedAccountBlock;
    if (pairedBlock == null || pairedBlock.hash == htlc.id) {
      return false;
    }

    final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
      Definitions.htlc,
      pairedBlock.data,
    );
    if (blockData == null || blockData.function != 'Create') {
      return false;
    }

    final Object? encodedHashLock = blockData.params['hashLock'];
    if (encodedHashLock is! List<int>) {
      return false;
    }

    return FormatUtils.encodeHexString(encodedHashLock) == htlc.hashLockHex;
  }

  FutureOr<void> _onValidationRefreshed(
    InitialHtlcValidationRefreshed event,
    Emitter<InitialHtlcValidationState> emit,
  ) {
    emit(const InitialHtlcValidationInitial());
  }
}
