import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'reclaim_deposit_event.dart';

part 'reclaim_deposit_state.dart';

/// Provides the wallet's currently generated addresses in derivation-index
/// order.
typedef WalletAddressesProvider = List<String?> Function();

/// Provides the currently unlocked [WalletFile], if available.
typedef WalletFileProvider = WalletFile? Function();

/// Generates [count] additional wallet addresses and persists them.
typedef WalletAddressGenerator = Future<void> Function(int count);

/// Maximum number of sequential ungenerated derivation indices scanned when
/// locating an HTLC reclaim address beyond the wallet's current address list.
const int kReclaimAddressLookaheadLimit = 50;

/// Reclaims an expired deposit owned by the wallet.
class ReclaimDepositBloc
    extends Bloc<ReclaimDepositEvent, ReclaimDepositState> {
  /// Creates a [ReclaimDepositBloc].
  ReclaimDepositBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
    WalletAddressesProvider? walletAddressesProvider,
    WalletFileProvider? walletFileProvider,
    WalletAddressGenerator? generateAddresses,
    int addressLookaheadLimit = kReclaimAddressLookaheadLimit,
    int Function()? unixTimeProvider,
  }) : assert(
         addressLookaheadLimit >= 0,
         'addressLookaheadLimit must be non-negative',
       ),
       _walletAddressesProvider =
           walletAddressesProvider ?? _defaultWalletAddresses,
       _walletFileProvider = walletFileProvider ?? _defaultWalletFile,
       _generateAddresses = generateAddresses ?? _defaultGenerateAddresses,
       _addressLookaheadLimit = addressLookaheadLimit,
       _unixTimeProvider = unixTimeProvider ?? _currentUnixTime,
       super(const ReclaimDepositInitial()) {
    on<ReclaimDepositRequested>(_onReclaimDepositRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final WalletAddressesProvider _walletAddressesProvider;
  final WalletFileProvider _walletFileProvider;
  final WalletAddressGenerator _generateAddresses;
  final int _addressLookaheadLimit;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;
  final int Function() _unixTimeProvider;

  static List<String?> _defaultWalletAddresses() => kDefaultAddressList;

  static WalletFile? _defaultWalletFile() => kWalletFile;

  static Future<void> _defaultGenerateAddresses(int count) =>
      ZenonAddressUtils.generateNewAddress(numAddr: count);

  static int _currentUnixTime() => DateTime.now().unixTimestamp;

  FutureOr<void> _onReclaimDepositRequested(
    ReclaimDepositRequested event,
    Emitter<ReclaimDepositState> emit,
  ) async {
    try {
      emit(const ReclaimDepositLoading());

      final HtlcInfo htlc = await _zenon.embedded.htlc.getById(event.depositId);

      final int? missingAddressIndex = await _resolveMissingAddressIndex(
        htlc.timeLocked,
      );

      if (htlc.expirationTime - _unixTimeProvider() > 0) {
        final String expirationDate = FormatUtils.formatDate(
          htlc.expirationTime * Duration.millisecondsPerSecond,
          dateFormat: kDefaultDateTimeFormat,
        );
        throw SyriusException('The deposit is locked until $expirationDate.');
      }

      if (missingAddressIndex != null) {
        await _ensureAddressGenerated(
          targetAddress: htlc.timeLocked,
          targetIndex: missingAddressIndex,
        );
      }

      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .reclaim(event.depositId);
      final AccountBlockTemplate block = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'reclaim deposit',
            address: htlc.timeLocked,
            waitForRequiredPlasma: true,
          );

      _zenonAddressUtils.refreshBalance();
      emit(ReclaimDepositDone(block: block));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(ReclaimDepositFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(sanitizeSwapErrorForLogging(error), stackTrace);
      emit(ReclaimDepositFailure(exception: FailureException()));
    }
  }

  Future<int?> _resolveMissingAddressIndex(Address targetAddress) async {
    final List<String?> currentAddresses = _walletAddressesProvider();
    final String targetAddressString = targetAddress.toString();
    if (currentAddresses.contains(targetAddressString)) {
      return null;
    }

    final WalletFile? walletFile = _walletFileProvider();
    if (walletFile == null) {
      throw SyriusException('The deposit does not belong to you.');
    }

    if (walletFile.isHardwareWallet) {
      throw SyriusException(
        'The deposit address is not in your wallet addresses. If you created '
        'this deposit from another address in this wallet, generate '
        'additional addresses in Settings and try again.',
      );
    }

    final int? derivedIndex = await _findDerivedAddressIndex(
      walletFile: walletFile,
      targetAddress: targetAddress,
      startIndex: currentAddresses.length,
    );
    if (derivedIndex == null) {
      throw SyriusException('The deposit does not belong to you.');
    }

    return derivedIndex;
  }

  Future<int?> _findDerivedAddressIndex({
    required WalletFile walletFile,
    required Address targetAddress,
    required int startIndex,
  }) async {
    if (_addressLookaheadLimit == 0) {
      return null;
    }

    return await walletFile.access<int?>((Wallet wallet) async {
      final int endIndex = startIndex + _addressLookaheadLimit;
      for (int index = startIndex; index < endIndex; index++) {
        final WalletAccount account = await wallet.getAccount(index);
        final Address derivedAddress = await account.getAddress();
        if (derivedAddress == targetAddress) {
          return index;
        }
      }
      return null;
    });
  }

  Future<void> _ensureAddressGenerated({
    required Address targetAddress,
    required int targetIndex,
  }) async {
    final String targetAddressString = targetAddress.toString();
    final List<String?> currentAddresses = _walletAddressesProvider();
    if (currentAddresses.contains(targetAddressString)) {
      return;
    }

    final int missingCount = targetIndex - currentAddresses.length + 1;
    if (missingCount > 0) {
      await _generateAddresses(missingCount);
    }

    if (!_walletAddressesProvider().contains(targetAddressString)) {
      throw SyriusException(
        'Unable to add the deposit address to your wallet addresses. '
        'Generate additional addresses in Settings and try again.',
      );
    }
  }
}
