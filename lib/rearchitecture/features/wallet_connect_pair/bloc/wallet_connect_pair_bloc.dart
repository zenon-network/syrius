import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_uri_utils.dart';

part 'wallet_connect_pair_event.dart';
part 'wallet_connect_pair_state.dart';

/// BLoC that validates a WalletConnect v2 URI and pairs with a dApp through
/// [IWeb3WalletService].
class WalletConnectPairBloc
    extends Bloc<WalletConnectPairEvent, WalletConnectPairState> {
  /// Creates a [WalletConnectPairBloc] backed by [_web3WalletService].
  WalletConnectPairBloc({required this._web3WalletService})
    : super(const WalletConnectPairState()) {
    on<WalletConnectPairRequested>(_onPairRequested);
  }

  final IWeb3WalletService _web3WalletService;
  final Logger _logger = Logger('WalletConnectPairBloc');

  Future<void> _onPairRequested(
    WalletConnectPairRequested event,
    Emitter<WalletConnectPairState> emit,
  ) async {
    if (state.status == WalletConnectPairStatus.loading) {
      return;
    }

    final String? extractedUri = extractWalletConnectUri(
      event.rawUri,
      isWindows: event.isWindows,
    );
    if (extractedUri == null) {
      const FormatException error = FormatException(
        'Invalid WalletConnect URI',
      );
      emit(
        state.copyWith(
          status: WalletConnectPairStatus.failure,
          error: error,
          errorCount: state.errorCount + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: WalletConnectPairStatus.loading, clearError: true),
    );

    try {
      final PairingInfo pairingInfo = await _web3WalletService.pair(
        Uri.parse(extractedUri),
      );
      _logger.info('WalletConnect pairing created: ${pairingInfo.topic}');
      emit(
        state.copyWith(
          status: WalletConnectPairStatus.success,
          pairingInfo: pairingInfo,
          successCount: state.successCount + 1,
          clearError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      _logger.warning('WalletConnect pairing failed', error, stackTrace);
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: WalletConnectPairStatus.failure,
          error: error,
          errorCount: state.errorCount + 1,
        ),
      );
    }
  }
}
