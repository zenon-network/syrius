import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/send_payment_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
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
        break;
      case NoMChainId.testnet:
        name = '3';
        break;
    }

    return '${NoMService.namespace}:$name';
  }
}

class NoMService extends IChain {
  static const namespace = 'zenon';

  final IWeb3WalletService _web3WalletService = sl<IWeb3WalletService>();
  final Logger _logger = Logger('NoMWalletConnectService');

  final NoMChainId reference;

  final _walletLockedError = const ReownCoreError(
    code: 9000,
    message: 'Wallet is locked',
  );

  ReownWalletKit? wallet;
  final Map<String, Future<dynamic>> _interactiveRequestFutures =
      <String, Future<dynamic>>{};

  NoMService({
    required this.reference,
  }) {
    wallet = _web3WalletService.getWeb3Wallet();
  }

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
    return ['chainIdChange', 'addressChange'];
  }

  Future<dynamic> handleZnnInfo(String topic, dynamic params) {
    final key = 'znn_info:$topic';
    return _runSingleFlight(key, () => _methodZnnInfo(topic, params));
  }

  Future<dynamic> handleZnnSign(String topic, dynamic params) {
    final key = 'znn_sign:$topic:${params.hashCode}';
    return _runSingleFlight(key, () => _methodZnnSign(topic, params));
  }

  Future<dynamic> handleZnnSend(String topic, dynamic params) {
    final key = 'znn_send:$topic:${params.hashCode}';
    return _runSingleFlight(key, () => _methodZnnSend(topic, params));
  }

  SessionData _sessionByTopic(String topic) {
    return wallet!.getActiveSessions().values.firstWhere(
          (element) => element.topic == topic,
          orElse: () => throw const ReownCoreError(
            code: 5001,
            message: 'WalletConnect session not found',
          ),
        );
  }

  String _resolveActiveAddress() {
    final selected = kSelectedAddress;
    if (selected == null || selected.isEmpty) {
      throw const ReownCoreError(
        code: 5002,
        message: 'No selected address available',
      );
    }
    return selected;
  }

  String? _extractRequestedFromAddress(dynamic params) {
    if (params is Map) {
      final fromAddress = params['fromAddress'];
      if (fromAddress is String && fromAddress.isNotEmpty) {
        return fromAddress;
      }
    }
    return null;
  }

  String _resolveSignerAddress({
    required String activeAddress,
    required String? requestedFromAddress,
    required String method,
    required String topic,
  }) {
    if (requestedFromAddress == null || requestedFromAddress.isEmpty) {
      return activeAddress;
    }

    final isWalletOwned = kAddressLabelMap.containsKey(requestedFromAddress) ||
        kDefaultAddressList.contains(requestedFromAddress);

    if (isWalletOwned) {
      if (requestedFromAddress != activeAddress) {
        _logger.info(
          'WalletConnect using requested fromAddress for method=$method '
          'topic=$topic requested=$requestedFromAddress active=$activeAddress',
        );
      }
      return requestedFromAddress;
    }

    _logger.warning(
      'WalletConnect requested fromAddress not wallet-owned; '
      'fallback to active - method=$method topic=$topic '
      'requested=$requestedFromAddress active=$activeAddress',
    );
    return activeAddress;
  }

  Future<dynamic> _runSingleFlight(
    String key,
    Future<dynamic> Function() action,
  ) {
    final existing = _interactiveRequestFutures[key];
    if (existing != null) {
      _logger.fine('Reusing in-flight interactive request: $key');
      return existing;
    }

    final future = action();
    _interactiveRequestFutures[key] = future;
    future.whenComplete(() => _interactiveRequestFutures.remove(key));
    return future;
  }

  Future _methodZnnInfo(String topic, dynamic params) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      windowManager.show();
    }
    final session = _sessionByTopic(topic);
    final dAppMetadata = session.peer.metadata;

    final activeAddress = _resolveActiveAddress();
    _logger.info(
        'WalletConnect request method=znn_info topic=$topic activeAddress=$activeAddress');

    if (kCurrentPage != Tabs.lock) {
      if (globalNavigatorKey.currentContext!.mounted) {
        final actionWasAccepted = await showDialogWithNoAndYesOptions(
          context: globalNavigatorKey.currentContext!,
          isBarrierDismissible: false,
          title: '${dAppMetadata.name} - Information',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Are you sure you want to allow ${dAppMetadata.name} to '
                  'retrieve the current address, node URL and chain identifier information?'),
              kVerticalSpacing,
              Image(
                image: NetworkImage(dAppMetadata.icons.first),
                height: 100.0,
                fit: BoxFit.fitHeight,
              ),
              kVerticalSpacing,
              Text(dAppMetadata.description),
              kVerticalSpacing,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dAppMetadata.url),
                  LinkIcon(
                    url: dAppMetadata.url,
                  )
                ],
              ),
            ],
          ),
          onYesButtonPressed: () async {},
          onNoButtonPressed: () {},
        );

        if (actionWasAccepted) {
          return {
            'address': activeAddress,
            'nodeUrl': kCurrentNode,
            'chainId': getChainIdentifier(),
          };
        } else {
          await NotificationUtils.sendNotificationError(
              Errors.getSdkError(Errors.USER_REJECTED),
              'You have rejected the WalletConnect request');
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
    final session = _sessionByTopic(topic);
    final dAppMetadata = session.peer.metadata;
    final activeAddress = _resolveActiveAddress();
    final requestedFromAddress = _extractRequestedFromAddress(params);
    final signerAddress = _resolveSignerAddress(
      activeAddress: activeAddress,
      requestedFromAddress: requestedFromAddress,
      method: 'znn_sign',
      topic: topic,
    );

    if (kCurrentPage != Tabs.lock) {
      final message = params is String
          ? params
          : (params is Map ? (params['message']?.toString() ?? '') : '');
      _logger.info(
        'WalletConnect request method=znn_sign topic=$topic '
        'activeAddress=$activeAddress requestedFrom=$requestedFromAddress',
      );

      if (globalNavigatorKey.currentContext!.mounted) {
        final actionWasAccepted = await showDialogWithNoAndYesOptions(
          context: globalNavigatorKey.currentContext!,
          isBarrierDismissible: false,
          title: '${dAppMetadata.name} - Sign Message',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Are you sure you want to '
                  'sign message $message ?'),
              kVerticalSpacing,
              Image(
                image: NetworkImage(dAppMetadata.icons.first),
                height: 100.0,
                fit: BoxFit.fitHeight,
              ),
              kVerticalSpacing,
              Text(dAppMetadata.description),
              kVerticalSpacing,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dAppMetadata.url),
                  LinkIcon(
                    url: dAppMetadata.url,
                  )
                ],
              ),
            ],
          ),
          onYesButtonPressed: () async {},
          onNoButtonPressed: () {},
        );

        if (actionWasAccepted) {
          return await walletSign(message.codeUnits, address: signerAddress);
        } else {
          await NotificationUtils.sendNotificationError(
              Errors.getSdkError(Errors.USER_REJECTED),
              'You have rejected the WalletConnect request');
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
    final session = _sessionByTopic(topic);
    final dAppMetadata = session.peer.metadata;
    final activeAddress = _resolveActiveAddress();
    final requestedFromAddress = _extractRequestedFromAddress(params);
    final signerAddress = _resolveSignerAddress(
      activeAddress: activeAddress,
      requestedFromAddress: requestedFromAddress,
      method: 'znn_send',
      topic: topic,
    );

    if (kCurrentPage != Tabs.lock) {
      final accountBlock =
          AccountBlockTemplate.fromJson(params['accountBlock']);

      _logger.info(
        'WalletConnect request method=znn_send topic=$topic '
        'activeAddress=$activeAddress requestedFrom=$requestedFromAddress '
        'to=${accountBlock.toAddress}',
      );

      final toAddress = ZenonAddressUtils.getLabel(
        accountBlock.toAddress.toString(),
      );

      final token =
          await zenon!.embedded.token.getByZts(accountBlock.tokenStandard);

      final amount = accountBlock.amount.addDecimals(token!.decimals);

      final sendPaymentBloc = SendPaymentBloc();

      if (globalNavigatorKey.currentContext!.mounted) {
        final wasActionAccepted = await showDialogWithNoAndYesOptions(
          context: globalNavigatorKey.currentContext!,
          isBarrierDismissible: false,
          title: '${dAppMetadata.name} - Send Payment',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Are you sure you want to transfer '
                  '$amount ${token.symbol} to '
                  '$toAddress ?'),
              kVerticalSpacing,
              Image(
                image: NetworkImage(dAppMetadata.icons.first),
                height: 100.0,
                fit: BoxFit.fitHeight,
              ),
              kVerticalSpacing,
              Text(dAppMetadata.description),
              kVerticalSpacing,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dAppMetadata.url),
                  LinkIcon(
                    url: dAppMetadata.url,
                  )
                ],
              ),
            ],
          ),
          description: 'Are you sure you want to transfer '
              '$amount ${token.symbol} to '
              '$toAddress ?',
          onYesButtonPressed: () {},
          onNoButtonPressed: () {},
        );

        if (wasActionAccepted) {
          sendPaymentBloc.sendTransfer(
            fromAddress: signerAddress,
            block: AccountBlockTemplate.fromJson(params['accountBlock']),
          );

          final result = await sendPaymentBloc.stream.firstWhere(
            (element) => element != null,
          );

          return result!;
        } else {
          await NotificationUtils.sendNotificationError(
              Errors.getSdkError(Errors.USER_REJECTED),
              'You have rejected the WalletConnect request');
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
