import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/link_icon.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum NoMChainId {
  mainnet,
  testnet,
}

extension NoMChainIdX on NoMChainId {
  String chain() {
    String name = '';

    switch (this) {
      case NoMChainId.mainnet:
        name = '1';
      case NoMChainId.testnet:
        name = '3';
    }

    return '${NoMService.namespace}:$name';
  }
}

class NoMService extends IChain {

  NoMService({
    required this.reference,
  }) {
    wallet = _web3WalletService.getWeb3Wallet();

    // Register event emitters
    // wallet!.registerEventEmitter(chainId: getChainId(), event: 'chainIdChange');
    // wallet!.registerEventEmitter(chainId: getChainId(), event: 'addressChange');

    // Register request handlers
    wallet!.registerRequestHandler(
      chainId: getChainId(),
      method: 'znn_info',
      handler: _methodZnnInfo,
    );
    wallet!.registerRequestHandler(
      chainId: getChainId(),
      method: 'znn_sign',
      handler: _methodZnnSign,
    );
    wallet!.registerRequestHandler(
      chainId: getChainId(),
      method: 'znn_send',
      handler: _methodZnnSend,
    );
  }
  static const String namespace = 'zenon';

  final IWeb3WalletService _web3WalletService = sl<IWeb3WalletService>();

  final NoMChainId reference;

  final WalletConnectError _walletLockedError = const WalletConnectError(
    code: 9000,
    message: 'Wallet is locked',
  );

  Web3Wallet? wallet;

  @override
  String getNamespace() {
    return namespace;
  }

  @override
  String getChainId() {
    return reference.chain();
  }

  @override
  List<String> getEvents() {
    return <String>['chainIdChange', 'addressChange'];
  }

  Future _methodZnnInfo(String topic, dynamic params) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      windowManager.show();
    }
    final PairingMetadata dAppMetadata = wallet!
        .getActiveSessions()
        .values
        .firstWhere((SessionData element) => element.topic == topic)
        .peer
        .metadata;

    if (kCurrentPage != Tabs.lock) {
      if (globalNavigatorKey.currentContext!.mounted) {
        final bool? actionWasAccepted = await showDialogWithNoAndYesOptions(
          context: globalNavigatorKey.currentContext!,
          isBarrierDismissible: false,
          title: '${dAppMetadata.name} - Information',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Are you sure you want to allow ${dAppMetadata.name} to '
                  'retrieve the current address, node URL and chain identifier information?'),
              kVerticalSpacing,
              Image(
                image: NetworkImage(dAppMetadata.icons.first),
                height: 100,
                fit: BoxFit.fitHeight,
              ),
              kVerticalSpacing,
              Text(dAppMetadata.description),
              kVerticalSpacing,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(dAppMetadata.url),
                  LinkIcon(
                    url: dAppMetadata.url,
                  ),
                ],
              ),
            ],
          ),
        );

        if (actionWasAccepted ?? false) {
          return <String, Object?>{
            'address': kSelectedAddress,
            'nodeUrl': kCurrentNode,
            'chainId': getChainIdentifier(),
          };
        } else {
          await NotificationUtils.sendNotificationError(
            Errors.getSdkError(Errors.USER_REJECTED),
            'You have rejected the WalletConnect request',
          );
          throw Errors.getSdkError(Errors.USER_REJECTED);
        }
      } else {
        throw _walletLockedError;
      }
    } else {
      throw _walletLockedError;
    }
  }

  Future _methodZnnSign(String topic, dynamic params) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      windowManager.show();
    }
    final PairingMetadata dAppMetadata = wallet!
        .getActiveSessions()
        .values
        .firstWhere((SessionData element) => element.topic == topic)
        .peer
        .metadata;
    if (kCurrentPage != Tabs.lock) {
      final String message = params as String;

      if (globalNavigatorKey.currentContext!.mounted) {
        final bool? actionWasAccepted = await showDialogWithNoAndYesOptions(
          context: globalNavigatorKey.currentContext!,
          isBarrierDismissible: false,
          title: '${dAppMetadata.name} - Sign Message',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Are you sure you want to '
                  'sign message $message ?'),
              kVerticalSpacing,
              Image(
                image: NetworkImage(dAppMetadata.icons.first),
                height: 100,
                fit: BoxFit.fitHeight,
              ),
              kVerticalSpacing,
              Text(dAppMetadata.description),
              kVerticalSpacing,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(dAppMetadata.url),
                  LinkIcon(
                    url: dAppMetadata.url,
                  ),
                ],
              ),
            ],
          ),
        );

        if (actionWasAccepted ?? false) {
          return walletSign(message.codeUnits);
        } else {
          await NotificationUtils.sendNotificationError(
            Errors.getSdkError(Errors.USER_REJECTED),
            'You have rejected the WalletConnect request',
          );
          throw Errors.getSdkError(Errors.USER_REJECTED);
        }
      } else {
        throw _walletLockedError;
      }
    } else {
      throw _walletLockedError;
    }
  }

  Future _methodZnnSend(String topic, dynamic params) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      windowManager.show();
    }
    final PairingMetadata dAppMetadata = wallet!
        .getActiveSessions()
        .values
        .firstWhere((SessionData element) => element.topic == topic)
        .peer
        .metadata;
    if (kCurrentPage != Tabs.lock) {
      final AccountBlockTemplate accountBlock =
      AccountBlockTemplate.fromJson(params['accountBlock']);

      final String toAddress = ZenonAddressUtils.getLabel(
        accountBlock.toAddress.toString(),
      );

      final Token? token =
      await zenon!.embedded.token.getByZts(accountBlock.tokenStandard);

      final String amount = accountBlock.amount.addDecimals(token!.decimals);

      if (globalNavigatorKey.currentContext!.mounted) {
        final wasActionAccepted = await showDialogWithNoAndYesOptions(
          context: globalNavigatorKey.currentContext!,
          isBarrierDismissible: false,
          title: '${dAppMetadata.name} - Send Payment',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Are you sure you want to transfer '
                  '$amount ${token.symbol} to '
                  '$toAddress ?'),
              kVerticalSpacing,
              Image(
                image: NetworkImage(dAppMetadata.icons.first),
                height: 100,
                fit: BoxFit.fitHeight,
              ),
              kVerticalSpacing,
              Text(dAppMetadata.description),
              kVerticalSpacing,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(dAppMetadata.url),
                  LinkIcon(
                    url: dAppMetadata.url,
                  ),
                ],
              ),
            ],
          ),
          description: 'Are you sure you want to transfer '
              '$amount ${token.symbol} to '
              '$toAddress ?',
        );

        if (wasActionAccepted ?? false) {
          final SendTransactionBloc sendTransactionBloc =
          globalNavigatorKey.currentContext!.read<SendTransactionBloc>()..add(
            SendTransactionInitiateFromBlock(
              fromAddress: params['fromAddress'],
              block: AccountBlockTemplate.fromJson(params['accountBlock']),
            ),
          );

          final SendTransactionState state = await sendTransactionBloc.stream
              .firstWhere(
                (SendTransactionState newState) =>
            newState.status == SendTransactionStatus.success,
          );

          final AccountBlockTemplate result = state.data!;

          return result;
        } else {
          await NotificationUtils.sendNotificationError(
            Errors.getSdkError(Errors.USER_REJECTED),
            'You have rejected the WalletConnect request',
          );
          throw Errors.getSdkError(Errors.USER_REJECTED);
        }
      } else {
        throw _walletLockedError;
      }
    } else {
      throw _walletLockedError;
    }
  }
}
