import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'issue_token_event.dart';

part 'issue_token_state.dart';

/// A bloc that issues a new ZTS token on-chain.
class IssueTokenBloc extends Bloc<IssueTokenEvent, IssueTokenState> {
  /// Creates an [IssueTokenBloc].
  IssueTokenBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const IssueTokenInitial()) {
    on<IssueTokenRequested>(_onIssueTokenRequested);
  }

  final AccountBlockUtils _accountBlockUtils;

  final Zenon _zenon;

  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onIssueTokenRequested(
    IssueTokenRequested event,
    Emitter<IssueTokenState> emit,
  ) async {
    try {
      emit(const IssueTokenLoading());

      final NewTokenData tokenData = event.tokenData;
      final AccountBlockTemplate transactionParams = _zenon.embedded.token
          .issueToken(
            tokenData.tokenName,
            tokenData.tokenSymbol,
            tokenData.tokenDomain,
            tokenData.totalSupply,
            tokenData.maxSupply,
            tokenData.decimals,
            tokenData.isMintable,
            tokenData.isBurnable,
            tokenData.isUtility,
          );

      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'issue token',
            address: Address.parse(tokenData.address),
            waitForRequiredPlasma: true,
          );

      _zenonAddressUtils.refreshBalance();

      // Info on how the new token standard is generate can be found at:
      // https://github.com/zenon-network/go-zenon/blob/667a69d9e9a418edf7580b08492ba5dcb9efd63a/vm/embedded/implementation/token.go#L71
      // and
      // https://github.com/zenon-network/go-zenon/blob/667a69d9e9a418edf7580b08492ba5dcb9efd63a/common/types/tokenstandard.go#L12-L25
      final TokenStandard newTokenStandard = TokenStandard.fromBytes(
        Crypto.digest(response.hash.getBytes()!).sublist(
          0,
          TokenStandard.coreSize,
        ),
      );

      emit(
        IssueTokenDone(
          accountBlock: response,
          newTokenStandard: newTokenStandard,
        ),
      );
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(IssueTokenFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(IssueTokenFailure(exception: FailureException()));
    }
  }
}
