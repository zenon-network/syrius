import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_pairings_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_sessions_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/link_icon.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletConnectService {
  WalletConnectService._internal();

  factory WalletConnectService() => _instance;

  static final WalletConnectService _instance =
      WalletConnectService._internal();

  final List<int> _idSessionsApproved = [];

  late Web3Wallet _wcClient;
  late BuildContext _context;

  final List<SessionData> dAppsActiveSessions = [];

  set context(BuildContext context) => _context = context;

  final _walletLockedError = const WalletConnectError(
    code: 9000,
    message: 'Wallet is locked',
  );

  Future<void> initClient() async {
    if (kWcProjectId.isNotEmpty) {
      _wcClient = await Web3Wallet.createInstance(
        projectId: kWcProjectId,
        metadata: const PairingMetadata(
          name: 's y r i u s',
          description: 'A wallet for interacting with Zenon Network',
          url: 'https://zenon.network',
          icons: [
            'https://raw.githubusercontent.com/zenon-network/syrius/master/macos/Runner/Assets.xcassets/AppIcon.appiconset/Icon-MacOS-512x512%402x.png'
          ],
        ),
      ).onError((e, stackTrace) {
        Logger('WalletConnectService')
            .log(Level.SEVERE, 'initClient onError ', e, stackTrace);
        if (e != null) {
          NotificationUtils.sendNotificationError(
              e, 'WalletConnect initialization failed');
        }
        throw 'WalletConnect init failed';
      });

      for (var pairingInfo in pairings) {
        dAppsActiveSessions
            .addAll(getSessionsForPairing(pairingInfo.topic).values);

        Logger('WalletConnectService')
            .log(Level.INFO, 'active pairings: $pairingInfo');
      }
      Logger('WalletConnectService')
          .log(Level.INFO, 'pairings num: ${pairings.length}');
      Logger('WalletConnectService')
          .log(Level.INFO, 'active sessions: ${getActiveSessions()}');
      _initListeners();
      _initialChecks();
    } else {
      Logger('WalletConnectService').log(Level.INFO, 'kWcProjectId missing');
      return;
    }
    return;
  }

  Future<PairingInfo> pair(Uri uri) => _wcClient.pair(uri: uri);

  void _initListeners() {
    _wcClient.onSessionProposal.subscribe(onSessionProposal);

    _wcClient.core.relayClient.onRelayClientDisconnect.subscribe((args) {
      Logger('WalletConnectService').log(
          Level.INFO, 'onRelayClientDisconnect triggered', args.toString());
      _wcClient.core.relayClient.connect();
    });

    _wcClient.core.pairing.onPairingCreate.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onPairingCreate triggered', args.toString());
      sl.get<WalletConnectPairingsBloc>().refreshResults();
    });

    _wcClient.core.pairing.onPairingActivate.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onPairingActivate triggered', args.toString());
      sl.get<WalletConnectPairingsBloc>().refreshResults();
    });

    _wcClient.core.pairing.onPairingInvalid.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onPairingInvalid triggered', args.toString());
    });

    _wcClient.core.pairing.onPairingPing.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onPairingPing triggered', args.toString());
    });

    _wcClient.core.pairing.onPairingDelete.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onPairingDelete triggered', args.toString());
    });

    _wcClient.core.pairing.onPairingExpire.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onPairingExpire triggered', args.toString());
    });

    _wcClient.onSessionPing.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onSessionPing triggered', args.toString());
    });

    _wcClient.onSessionDelete.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onSessionDelete triggered', args.toString());
      sl.get<WalletConnectSessionsBloc>().refreshResults();
    });

    _wcClient.onSessionProposalError.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onSessionProposalError triggered', args.toString());
      sl.get<WalletConnectSessionsBloc>().refreshResults();
    });

    _wcClient.onSessionConnect.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onSessionConnect triggered', args.toString());
      Future.delayed(const Duration(seconds: 3)).then(
          (value) => sl.get<WalletConnectSessionsBloc>().refreshResults());
    });

    _wcClient.onSessionRequest.subscribe((SessionRequestEvent? request) async {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onSessionRequest triggered', request.toString());
    });

    _wcClient.onAuthRequest.subscribe((args) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onAuthRequest triggered', args.toString());
    });

    _wcClient.registerRequestHandler(
      chainId: 'zenon:1',
      method: 'znn_info',
      handler: (topic, params) async {
        if (!await windowManager.isFocused() ||
            !await windowManager.isVisible()) {
          windowManager.show();
        }
        final dAppMetadata = dAppsActiveSessions
            .firstWhere((element) => element.topic == topic)
            .peer
            .metadata;

        if (kCurrentPage != Tabs.lock) {
          if (_context.mounted) {
            final actionWasAccepted = await showDialogWithNoAndYesOptions(
              context: _context,
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
                'address': kSelectedAddress,
                'nodeUrl': kCurrentNode,
                'chainId': getChainIdentifier(),
              };
            } else {
              NotificationUtils.sendNotificationError(
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
      },
    );

    _wcClient.onAuthRequest.subscribe((AuthRequest? args) async {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onAuthRequest triggered', args.toString());
    });

    _wcClient.registerRequestHandler(
      chainId: 'zenon:1',
      method: 'znn_sign',
      handler: (topic, params) async {
        if (!await windowManager.isFocused() ||
            !await windowManager.isVisible()) {
          windowManager.show();
        }
        final dAppMetadata = dAppsActiveSessions
            .firstWhere((element) => element.topic == topic)
            .peer
            .metadata;
        if (kCurrentPage != Tabs.lock) {
          final message = params as String;

          if (_context.mounted) {
            final actionWasAccepted = await showDialogWithNoAndYesOptions(
              context: _context,
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
              return await walletSign(message.codeUnits);
            } else {
              NotificationUtils.sendNotificationError(
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
      },
    );

    _wcClient.registerRequestHandler(
      chainId: 'zenon:1',
      method: 'znn_send',
      handler: (topic, params) async {
        if (!await windowManager.isFocused() ||
            !await windowManager.isVisible()) {
          windowManager.show();
        }
        final dAppMetadata = dAppsActiveSessions
            .firstWhere((element) => element.topic == topic)
            .peer
            .metadata;
        if (kCurrentPage != Tabs.lock) {
          final accountBlock =
              AccountBlockTemplate.fromJson(params['accountBlock']);

          final toAddress = ZenonAddressUtils.getLabel(
            accountBlock.toAddress.toString(),
          );

          final token =
              await zenon!.embedded.token.getByZts(accountBlock.tokenStandard);

          final amount = accountBlock.amount.addDecimals(token!.decimals);

          final sendPaymentBloc = SendPaymentBloc();

          if (_context.mounted) {
            final wasActionAccepted = await showDialogWithNoAndYesOptions(
              context: _context,
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
                fromAddress: params['fromAddress'],
                block: AccountBlockTemplate.fromJson(params['accountBlock']),
              );

              final result = await sendPaymentBloc.stream.firstWhere(
                (element) => element != null,
              );

              return result!;
            } else {
              NotificationUtils.sendNotificationError(
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
      },
    );
  }

  List<PairingInfo> get pairings => _wcClient.pairings.getAll();

  Future<ApproveResponse> approveSession(
      {required int id, Map<String, Namespace>? namespaces}) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      windowManager.show();
    }
    namespaces = namespaces ??
        {
          'zenon': Namespace(
            accounts: _getWalletAccounts(),
            methods: [
              'znn_sign',
              'znn_info',
              'znn_send',
            ],
            events: ['chainIdChange', 'addressChange'],
          ),
        };
    return _wcClient.approveSession(
      id: id,
      namespaces: namespaces,
    );
  }

  Future<void> rejectSession({
    required int id,
    required WalletConnectError reason,
  }) =>
      _wcClient.rejectSession(id: id, reason: reason);

  String _generateAccount(String address, int chainId) =>
      '$kZenonNameSpace:1:$address';

  List<String> _getWalletAccounts() => kAddressLabelMap.values
      .map(
        (address) => _generateAccount(address, getChainIdentifier()),
      )
      .toList();

  Future<void> activatePairing({
    required String topic,
  }) =>
      _wcClient.core.pairing.activate(
        topic: topic,
      );

  Future<void> deactivatePairing({
    required String topic,
  }) async {
    try {
      _wcClient.core.pairing.disconnect(topic: topic);
    } on WalletConnectError catch (e) {
      // technically look for WalletConnectError 6 : Expired.  to consider it a warning
      Logger('WalletConnectService')
          .log(Level.INFO, 'deactivatePairing ${e.code} : ${e.message}');
    } catch (e, s) {
      // Catch anything else (not just Exceptions) and log stack
      Logger('WalletConnectService').log(Level.INFO,
          'disconnectAllParings - Unexpected error: $e, topic $topic\n$s');
    }
  }

  // Future<void> disconnectSessions() async {
  //   IPairingStore pairingStore = getPairings();
  //   pairingStore.getAll().forEach((element) async {
  //     await _wcClient.disconnectSession(
  //         topic: element.topic,
  //         reason: Errors.getSdkError(Errors.USER_DISCONNECTED));
  //   });
  // }

  Future<void> disconnectSession({required String topic}) async =>
      _wcClient.disconnectSession(
        topic: topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );

  Future<void> _emitEventForTheDApps({
    required String changeName,
    required String newValue,
  }) async {
    final sessionTopics =
        pairings.fold<List<String>>(<String>[], (previousValue, pairing) {
      if (pairing.active) {
        var sessionsPerPairing = getSessionsForPairing(pairing.topic).keys;
        previousValue.addAll(sessionsPerPairing);
        return previousValue;
      }
      return previousValue;
    });

    for (var sessionTopic in sessionTopics) {
      _emitEventForADApp(
        sessionTopic: sessionTopic,
        changeName: changeName,
        newValue: newValue,
      );
    }
  }

  Future<void> _emitEventForADApp({
    required String sessionTopic,
    required String changeName,
    required String newValue,
  }) =>
      _wcClient.emitSessionEvent(
        topic: sessionTopic,
        chainId: 'zenon:1',
        event: SessionEventParams(
          name: changeName,
          data: newValue,
        ),
      );

  Future<void> emitAddressChangeEvent(String newAddress) {
    return _emitEventForTheDApps(
      changeName: 'addressChange',
      newValue: newAddress,
    );
  }

  Future<void> emitChainIdChangeEvent(String newChainId) {
    return _emitEventForTheDApps(
      changeName: 'chainIdChange',
      newValue: newChainId,
    );
  }

  Map<String, SessionData> getActiveSessions() => _wcClient.getActiveSessions();

  Map<String, SessionData> getSessionsForPairing(String pairingTopic) =>
      _wcClient.getSessionsForPairing(
        pairingTopic: pairingTopic,
      );

  void _sendSuccessfullyApprovedSessionNotification(
      PairingMetadata dAppMetadata) {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully connected to ${dAppMetadata.name}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Successfully connected to ${dAppMetadata.name} '
                'via WalletConnect',
            type: NotificationType.paymentSent,
          ),
        );
  }

  void onSessionProposal(SessionProposalEvent? event) async {
    Logger('WalletConnectService')
        .log(Level.INFO, 'onSessionProposal triggered', event.toString());

    if (event != null) {
      Logger('WalletConnectService')
          .log(Level.INFO, 'session proposal event', event.params.toJson());

      final dAppMetadata = event.params.proposer.metadata;

      final actionWasAccepted = await showDialogWithNoAndYesOptions(
        context: _context,
        isBarrierDismissible: false,
        title: 'Approve session',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Are you sure you want to '
                'connect to ${dAppMetadata.name} ?'),
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
        if (!_idSessionsApproved.contains(event.id)) {
          _idSessionsApproved.add(event.id);
          ApproveResponse approveResponse = await _wcClient.approveSession(
            id: event.id,
            namespaces: {
              'zenon': Namespace(
                accounts: _getWalletAccounts(),
                methods: [
                  'znn_sign',
                  'znn_info',
                  'znn_send',
                ],
                events: [
                  'chainIdChange',
                  'addressChange',
                ],
              ),
            },
          );

          _sendSuccessfullyApprovedSessionNotification(dAppMetadata);
          dAppsActiveSessions.add(approveResponse.session);
        }
      } else {
        await _wcClient.rejectSession(
          id: event.id,
          reason: Errors.getSdkError(
            Errors.USER_REJECTED,
          ),
        );
      }
    }
  }

  void _initialChecks() {
    final pendingProposals = _wcClient.getPendingSessionProposals();
    Logger('WalletConnectService').log(
        Level.INFO, 'checkForPendingRequests', pendingProposals.keys.length);
    if (pendingProposals.isNotEmpty) {
      pendingProposals.forEach((key, value) {
        _wcClient.approveSession(id: value.id, namespaces: {
          'zenon': Namespace(
            accounts: _getWalletAccounts(),
            methods: [
              'znn_sign',
              'znn_info',
              'znn_send',
            ],
            events: [
              'chainIdChange',
              'addressChange',
            ],
          ),
        });
      });
    }
  }
}
