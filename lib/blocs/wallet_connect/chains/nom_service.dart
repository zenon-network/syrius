import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart' hide Address;
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/block_data.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/wallet_connect_metadata_utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_request_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/link_icon.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Inspection result describing any contract/raw `data` attached to an
/// incoming WalletConnect `znn_send` account block.
class WalletConnectBlockDataInspection {
  /// Creates a [WalletConnectBlockDataInspection].
  const WalletConnectBlockDataInspection({
    required this.isEmbeddedContract,
    required this.rawByteLength,
    this.contractName,
    this.decodedBlockData,
    this.rawHexPreview,
  });

  /// Whether the block's `toAddress` is a Zenon embedded contract address.
  final bool isEmbeddedContract;

  /// Length of `accountBlock.data` in bytes.
  final int rawByteLength;

  /// Human-readable embedded contract name when [isEmbeddedContract] is true.
  final String? contractName;

  /// Decoded embedded contract method and arguments, if ABI decoding succeeded.
  final BlockData? decodedBlockData;

  /// Truncated hex representation of raw bytes when [rawByteLength] > 0.
  final String? rawHexPreview;

  /// Whether the account block carries any non-empty `data` payload.
  bool get hasData => rawByteLength > 0;
}

/// Supported Network of Momentum (Zenon) WalletConnect chain identifiers.
enum NoMChainId {
  /// Zenon Alphanet (`zenon:1`).
  mainnet,

  /// Zenon Testnet (`zenon:3`).
  testnet,
}

/// Formats a [NoMChainId] as a CAIP-2 chain identifier (`zenon:<id>`).
extension NoMChainIdX on NoMChainId {
  /// Returns the CAIP-2 chain string for this chain identifier.
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

/// Network of Momentum (Zenon) WalletConnect request handler for `znn_info`,
/// `znn_sign`, and `znn_send`.
class NoMService extends IChain {
  /// Creates a [NoMService] bound to the configured WalletConnect service.
  NoMService({
    required this.reference,
    @visibleForTesting IWeb3WalletService? web3WalletService,
  }) : _web3WalletService = web3WalletService ?? sl<IWeb3WalletService>();

  /// CAIP-2 namespace for Zenon Network.
  static const String namespace = 'zenon';

  /// Domain-separation prefix prepended to UTF-8 message bytes signed by
  /// `znn_sign` so a message signature can never collide with a 32-byte
  /// account-block hash.
  static const String signedMessagePrefix = '\x19Zenon Signed Message:\n';

  static final Map<Address, ({String name, Abi abi})> _embeddedContractAbis =
      <Address, ({String name, Abi abi})>{
        plasmaAddress: (name: 'Plasma', abi: Definitions.plasma),
        pillarAddress: (name: 'Pillar', abi: Definitions.pillar),
        tokenAddress: (name: 'Token', abi: Definitions.token),
        sentinelAddress: (name: 'Sentinel', abi: Definitions.sentinel),
        swapAddress: (name: 'Swap', abi: Definitions.swap),
        stakeAddress: (name: 'Stake', abi: Definitions.stake),
        acceleratorAddress: (name: 'Accelerator', abi: Definitions.accelerator),
        bridgeAddress: (name: 'Bridge', abi: Definitions.bridge),
        liquidityAddress: (name: 'Liquidity', abi: Definitions.liquidity),
        sporkAddress: (name: 'Spork', abi: Definitions.spork),
        htlcAddress: (name: 'HTLC', abi: Definitions.htlc),
      };

  final IWeb3WalletService _web3WalletService;
  final Logger _logger = Logger('NoMWalletConnectService');

  /// Chain identifier handled by this service instance.
  final NoMChainId reference;

  final ReownCoreError _walletLockedError = const ReownCoreError(
    code: 9000,
    message: 'Wallet is locked',
  );

  final Map<String, Future<dynamic>> _interactiveRequestFutures =
      <String, Future<dynamic>>{};

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

  /// Handles a `znn_info` session request with single-flight deduplication.
  Future<dynamic> handleZnnInfo(
    String topic,
    dynamic params, {
    int? requestId,
    VerifyContext? verifyContext,
  }) {
    // znn_info approval does not depend on params, so without a request id
    // the key stays topic-scoped.
    final String key = interactiveRequestKey(
      method: 'znn_info',
      topic: topic,
      params: null,
      requestId: requestId,
    );
    return _runSingleFlight(
      key,
      () => _methodZnnInfo(
        topic,
        params,
        requestId: requestId,
        verifyContext: verifyContext,
      ),
    );
  }

  /// Handles a `znn_sign` session request with single-flight deduplication.
  Future<dynamic> handleZnnSign(
    String topic,
    dynamic params, {
    int? requestId,
    VerifyContext? verifyContext,
  }) {
    final String key = interactiveRequestKey(
      method: 'znn_sign',
      topic: topic,
      params: params,
      requestId: requestId,
    );
    return _runSingleFlight(
      key,
      () => _methodZnnSign(
        topic,
        params,
        requestId: requestId,
        verifyContext: verifyContext,
      ),
    );
  }

  /// Handles a `znn_send` session request with single-flight deduplication.
  Future<dynamic> handleZnnSend(
    String topic,
    dynamic params, {
    int? requestId,
    VerifyContext? verifyContext,
  }) {
    final String key = interactiveRequestKey(
      method: 'znn_send',
      topic: topic,
      params: params,
      requestId: requestId,
    );
    return _runSingleFlight(
      key,
      () => _methodZnnSend(
        topic,
        params,
        requestId: requestId,
        verifyContext: verifyContext,
      ),
    );
  }

  /// Resolves an active session by [topic], throwing a controlled
  /// [ReownCoreError] when the client is unavailable or the session is absent.
  @visibleForTesting
  SessionData sessionByTopicForTesting(String topic) => _sessionByTopic(topic);

  SessionData _sessionByTopic(String topic) {
    return _web3WalletService.getActiveSessions().values.firstWhere(
      (SessionData element) => element.topic == topic,
      orElse: () =>
          // ReownCoreError does not implement Error/Exception upstream.
          // ignore: only_throw_errors
          throw const ReownCoreError(
            code: 5001,
            message: 'WalletConnect session not found',
          ),
    );
  }

  /// Extracts and validates the non-empty message string for `znn_sign`.
  @visibleForTesting
  static String resolveSignMessage(dynamic params) {
    final Object? rawMessage = params is Map ? params['message'] : params;
    if (rawMessage is! String || rawMessage.isEmpty) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw const ReownCoreError(
        code: 5003,
        message: 'Invalid znn_sign message parameter',
      );
    }
    return rawMessage;
  }

  /// Builds the domain-separated byte payload signed by `znn_sign`:
  /// `utf8("\x19Zenon Signed Message:\n<byteLength>\n") + utf8(message)`.
  @visibleForTesting
  static Uint8List encodeSignedMessagePayload(String message) {
    final List<int> messageBytes = utf8.encode(message);
    final List<int> prefixBytes = utf8.encode(
      '$signedMessagePrefix${messageBytes.length}\n',
    );
    return Uint8List.fromList(<int>[...prefixBytes, ...messageBytes]);
  }

  /// Validates that this service's session chain matches the wallet's
  /// currently active chain identifier.
  @visibleForTesting
  void validateSessionChainMatchesActive() {
    final String activeCaip2Chain = '$namespace:${getChainIdentifier()}';
    if (reference.chain() != activeCaip2Chain) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw ReownCoreError(
        code: 5003,
        message:
            'Session chain ${reference.chain()} does not match active '
            'chain $activeCaip2Chain',
      );
    }
  }

  /// Validates that [accountBlock] is a user-send block matching both this
  /// service's session chain and the wallet's currently active network.
  @visibleForTesting
  void validateSendAccountBlock(AccountBlockTemplate accountBlock) {
    final int activeChainId = getChainIdentifier();
    final String activeCaip2Chain = '$namespace:$activeChainId';
    if (accountBlock.blockType != BlockTypeEnum.userSend.index ||
        accountBlock.fromBlockHash != emptyHash ||
        accountBlock.chainIdentifier != activeChainId ||
        reference.chain() != activeCaip2Chain) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw const ReownCoreError(
        code: 5003,
        message: 'accountBlock does not match this session',
      );
    }
  }

  /// Re-validates after interactive confirmation that the session is still
  /// active, [requestId] is still pending (when provided), and (when
  /// [requireActiveChainMatch] is true) the active chain still matches this
  /// session.
  @visibleForTesting
  void revalidateInteractiveRequest({
    required String topic,
    required int? requestId,
    required bool requireActiveChainMatch,
  }) {
    final SessionData liveSession = _sessionByTopic(topic);

    if (requestId != null) {
      final Map<String, SessionRequest> pendingRequests = _web3WalletService
          .getPendingSessionRequests();
      final bool isStillPending =
          pendingRequests.containsKey(requestId.toString()) ||
          pendingRequests.values.any(
            (SessionRequest request) => request.id == requestId,
          );
      if (!isStillPending) {
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw const ReownCoreError(
          code: 5005,
          message: 'WalletConnect request expired or no longer pending',
        );
      }
    }

    if (requireActiveChainMatch) {
      final String activeCaip2Chain = '$namespace:${getChainIdentifier()}';
      final List<String>? sessionChains =
          liveSession.namespaces[namespace]?.chains;
      final bool sessionMatchesActive =
          sessionChains != null &&
          sessionChains.isNotEmpty &&
          sessionChains.first == activeCaip2Chain;
      if (reference.chain() != activeCaip2Chain || !sessionMatchesActive) {
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw const ReownCoreError(
          code: 5003,
          message: 'Active network changed while awaiting confirmation',
        );
      }
    }
  }

  /// Inspects [accountBlock] calldata so the `znn_send` confirmation dialog can
  /// display decoded embedded contract calls or warn about raw undecoded data.
  @visibleForTesting
  static WalletConnectBlockDataInspection inspectSendAccountBlockData(
    AccountBlockTemplate accountBlock,
  ) {
    final List<int> data = accountBlock.data;
    final ({String name, Abi abi})? embeddedContract =
        _embeddedContractAbis[accountBlock.toAddress];
    final bool isEmbedded =
        embeddedContract != null || accountBlock.toAddress.isEmbedded();
    if (data.isEmpty) {
      return WalletConnectBlockDataInspection(
        isEmbeddedContract: isEmbedded,
        rawByteLength: 0,
        contractName: embeddedContract?.name,
      );
    }

    BlockData? decoded;
    if (embeddedContract != null) {
      decoded =
          _tryDecodeBlockData(embeddedContract.abi, data) ??
          _tryDecodeBlockData(Definitions.common, data);
    }

    final String fullHex = BytesUtils.bytesToHex(data);
    final String previewHex = fullHex.length > 64
        ? '0x${fullHex.substring(0, 64)}…'
        : '0x$fullHex';

    return WalletConnectBlockDataInspection(
      isEmbeddedContract: isEmbedded,
      rawByteLength: data.length,
      contractName: embeddedContract?.name,
      decodedBlockData: decoded,
      rawHexPreview: previewHex,
    );
  }

  static BlockData? _tryDecodeBlockData(Abi abi, List<int> data) {
    try {
      return AccountBlockUtils.getDecodedBlockData(abi, data);
    } on Object {
      return null;
    }
  }

  static String _formatDecodedParamValue(Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is List<int>) {
      final String hex = BytesUtils.bytesToHex(value);
      return hex.length > 64 ? '0x${hex.substring(0, 64)}…' : '0x$hex';
    }
    final String text = value.toString();
    return text.length > 96 ? '${text.substring(0, 96)}…' : text;
  }

  String _networkLabel() {
    return switch (reference) {
      NoMChainId.mainnet => 'Mainnet (${reference.chain()})',
      NoMChainId.testnet => 'Testnet (${reference.chain()})',
    };
  }

  void _rejectIfScam(VerifyContext? verifyContext) {
    if (isWalletConnectVerifyScam(verifyContext)) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw ReownCoreError(
        code: Errors.getSdkError(Errors.USER_REJECTED).code,
        message: 'WalletConnect request blocked: peer flagged as scam',
      );
    }
  }

  Widget _buildVerifyStatusBanner(VerifyContext? verifyContext) {
    final WalletConnectVerifySummary summary =
        describeWalletConnectVerifyContext(verifyContext);
    final Color accentColor = switch (summary.severity) {
      WalletConnectVerifySeverity.verified => Colors.green,
      WalletConnectVerifySeverity.unverified => Colors.orange,
      WalletConnectVerifySeverity.invalid ||
      WalletConnectVerifySeverity.scam => Colors.red,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        border: Border.all(color: accentColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            summary.title,
            style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(summary.detail),
        ],
      ),
    );
  }

  Widget _buildAccountBlockDataDetails(
    WalletConnectBlockDataInspection inspection,
  ) {
    final BlockData? decoded = inspection.decodedBlockData;
    if (decoded != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          border: Border.all(color: Colors.amber),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Embedded contract call: '
              '${inspection.contractName ?? 'Contract'}.${decoded.function}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final MapEntry<String, dynamic> param
                in decoded.params.entries) ...<Widget>[
              const SizedBox(height: 4),
              Text('${param.key}: ${_formatDecodedParamValue(param.value)}'),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Warning: ${inspection.rawByteLength} bytes of undecoded raw data',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Raw payload: ${inspection.rawHexPreview}. '
            'Only approve if you fully trust this dApp.',
          ),
        ],
      ),
    );
  }

  String _resolveActiveAddress() {
    final String? selected = kSelectedAddress;
    if (selected == null || selected.isEmpty) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw const ReownCoreError(
        code: 5002,
        message: 'No selected address available',
      );
    }
    return selected;
  }

  /// Extracts an optional `fromAddress` string from WalletConnect request
  /// [params].
  @visibleForTesting
  static String? extractRequestedFromAddress(dynamic params) {
    if (params is Map) {
      final dynamic fromAddress = params['fromAddress'];
      if (fromAddress is String && fromAddress.isNotEmpty) {
        return fromAddress;
      }
    }
    return null;
  }

  /// Resolves the wallet address that will sign or submit a request, rejecting
  /// any requested `fromAddress` that is not owned by this wallet.
  @visibleForTesting
  String resolveSignerAddress({
    required String activeAddress,
    required String? requestedFromAddress,
    required String method,
    required String topic,
  }) {
    if (requestedFromAddress == null || requestedFromAddress.isEmpty) {
      return activeAddress;
    }

    final bool isWalletOwned = _isWalletOwnedAddress(requestedFromAddress);

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
      'rejecting request - method=$method topic=$topic '
      'requested=$requestedFromAddress active=$activeAddress',
    );
    // ReownCoreError does not implement Error/Exception upstream.
    // ignore: only_throw_errors
    throw ReownCoreError(
      code: Errors.getSdkError(Errors.UNSUPPORTED_ACCOUNTS).code,
      message: 'fromAddress is not owned by this wallet',
    );
  }

  bool _isWalletOwnedAddress(String address) {
    return kAddressLabelMap.containsKey(address) ||
        kDefaultAddressList.contains(address);
  }

  /// Executes [action] under single-flight deduplication keyed by [key].
  @visibleForTesting
  Future<dynamic> runSingleFlightForTesting(
    String key,
    Future<dynamic> Function() action,
  ) => _runSingleFlight(key, action);

  Future<dynamic> _runSingleFlight(
    String key,
    Future<dynamic> Function() action,
  ) {
    final Future<dynamic>? existing = _interactiveRequestFutures[key];
    if (existing != null) {
      _logger.fine('Reusing in-flight interactive request: $key');
      return existing;
    }

    final Future<dynamic> future = _executeSingleFlight(key, action);
    _interactiveRequestFutures[key] = future;
    return future;
  }

  Future<dynamic> _executeSingleFlight(
    String key,
    Future<dynamic> Function() action,
  ) async {
    try {
      return await action();
    } finally {
      final Future<dynamic>? _ = _interactiveRequestFutures.remove(key);
    }
  }

  Future<dynamic> _methodZnnInfo(
    String topic,
    dynamic params, {
    int? requestId,
    VerifyContext? verifyContext,
  }) async {
    _rejectIfScam(verifyContext);
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }
    final SessionData session = _sessionByTopic(topic);
    final PairingMetadata dAppMetadata = session.peer.metadata;
    final String dAppName = _dAppName(dAppMetadata);
    final String dAppDescription = _dAppDescription(dAppMetadata);
    final String? dAppUrl = _dAppUrl(dAppMetadata);
    final String? dAppIconUrl = _dAppIconUrl(dAppMetadata);

    final String activeAddress = _resolveActiveAddress();
    _logger.info(
      'WalletConnect request method=znn_info topic=$topic '
      'activeAddress=$activeAddress',
    );

    final BuildContext? context = globalNavigatorKey.currentContext;
    if (kCurrentPage != Tabs.lock && context != null && context.mounted) {
      final bool? actionWasAccepted = await showDialogWithNoAndYesOptions(
        context: context,
        isBarrierDismissible: false,
        title: '$dAppName - Information',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Are you sure you want to allow $dAppName to '
                'retrieve the current address, node URL and chain identifier '
                'information?',
              ),
              kVerticalSpacing,
              _buildVerifyStatusBanner(verifyContext),
              kVerticalSpacing,
              Text('Network: ${_networkLabel()}'),
              kVerticalSpacing,
              if (dAppIconUrl != null)
                Image(
                  image: NetworkImage(dAppIconUrl),
                  height: 100,
                  fit: BoxFit.fitHeight,
                ),
              kVerticalSpacing,
              Text(dAppDescription),
              kVerticalSpacing,
              if (dAppUrl != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(dAppUrl, overflow: TextOverflow.ellipsis),
                    ),
                    LinkIcon(url: dAppUrl),
                  ],
                ),
            ],
          ),
        ),
      );

      if (actionWasAccepted ?? false) {
        if (kCurrentPage == Tabs.lock) {
          // ReownCoreError does not implement Error/Exception upstream.
          // ignore: only_throw_errors
          throw _walletLockedError;
        }
        revalidateInteractiveRequest(
          topic: topic,
          requestId: requestId,
          requireActiveChainMatch: false,
        );
        return <String, Object?>{
          'address': activeAddress,
          'nodeUrl': kCurrentNode,
          'chainId': getChainIdentifier(),
        };
      } else {
        await NotificationUtils.sendNotificationError(
          Errors.getSdkError(Errors.USER_REJECTED),
          'You have rejected the WalletConnect request',
        );
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw Errors.getSdkError(Errors.USER_REJECTED);
      }
    } else {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }
  }

  Future<dynamic> _methodZnnSign(
    String topic,
    dynamic params, {
    int? requestId,
    VerifyContext? verifyContext,
  }) async {
    _rejectIfScam(verifyContext);
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }
    final SessionData session = _sessionByTopic(topic);
    final PairingMetadata dAppMetadata = session.peer.metadata;
    final String dAppName = _dAppName(dAppMetadata);
    final String dAppDescription = _dAppDescription(dAppMetadata);
    final String? dAppUrl = _dAppUrl(dAppMetadata);
    final String? dAppIconUrl = _dAppIconUrl(dAppMetadata);
    final String activeAddress = _resolveActiveAddress();
    final String? requestedFromAddress = extractRequestedFromAddress(params);
    final String signerAddress = resolveSignerAddress(
      activeAddress: activeAddress,
      requestedFromAddress: requestedFromAddress,
      method: 'znn_sign',
      topic: topic,
    );

    if (kCurrentPage == Tabs.lock) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }

    validateSessionChainMatchesActive();
    final String message = resolveSignMessage(params);
    final BuildContext? context = globalNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }

    _logger.info(
      'WalletConnect request method=znn_sign topic=$topic '
      'activeAddress=$activeAddress requestedFrom=$requestedFromAddress',
    );

    final bool? actionWasAccepted = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: false,
      title: '$dAppName - Sign Message',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Are you sure you want to sign this message for $dAppName?'),
            kVerticalSpacing,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(message),
            ),
            kVerticalSpacing,
            _buildVerifyStatusBanner(verifyContext),
            kVerticalSpacing,
            Text('Network: ${_networkLabel()}'),
            kVerticalSpacing,
            Text('Signing address: $signerAddress'),
            kVerticalSpacing,
            if (dAppIconUrl != null)
              Image(
                image: NetworkImage(dAppIconUrl),
                height: 100,
                fit: BoxFit.fitHeight,
              ),
            kVerticalSpacing,
            Text(dAppDescription),
            kVerticalSpacing,
            if (dAppUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(dAppUrl, overflow: TextOverflow.ellipsis),
                  ),
                  LinkIcon(url: dAppUrl),
                ],
              ),
          ],
        ),
      ),
    );

    if (actionWasAccepted ?? false) {
      if (kCurrentPage == Tabs.lock) {
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw _walletLockedError;
      }
      revalidateInteractiveRequest(
        topic: topic,
        requestId: requestId,
        requireActiveChainMatch: true,
      );
      final Signature signature = await walletSign(
        encodeSignedMessagePayload(message),
        address: signerAddress,
      );
      return <String, String>{
        'signature': signature.signature,
        'publicKey': signature.publicKey,
      };
    } else {
      await NotificationUtils.sendNotificationError(
        Errors.getSdkError(Errors.USER_REJECTED),
        'You have rejected the WalletConnect request',
      );
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getSdkError(Errors.USER_REJECTED);
    }
  }

  Future<dynamic> _methodZnnSend(
    String topic,
    dynamic params, {
    int? requestId,
    VerifyContext? verifyContext,
  }) async {
    _rejectIfScam(verifyContext);
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }
    final SessionData session = _sessionByTopic(topic);
    final PairingMetadata dAppMetadata = session.peer.metadata;
    final String dAppName = _dAppName(dAppMetadata);
    final String dAppDescription = _dAppDescription(dAppMetadata);
    final String? dAppUrl = _dAppUrl(dAppMetadata);
    final String? dAppIconUrl = _dAppIconUrl(dAppMetadata);
    final String activeAddress = _resolveActiveAddress();
    final String? requestedFromAddress = extractRequestedFromAddress(params);
    final String signerAddress = resolveSignerAddress(
      activeAddress: activeAddress,
      requestedFromAddress: requestedFromAddress,
      method: 'znn_send',
      topic: topic,
    );

    if (kCurrentPage == Tabs.lock) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }

    if (params is! Map || params['accountBlock'] is! Map) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw const ReownCoreError(
        code: 5003,
        message: 'Invalid accountBlock parameters',
      );
    }

    final Map<String, dynamic> accountBlockJson = Map<String, dynamic>.from(
      params['accountBlock'] as Map<dynamic, dynamic>,
    );
    final AccountBlockTemplate accountBlock = AccountBlockTemplate.fromJson(
      accountBlockJson,
    );
    validateSendAccountBlock(accountBlock);

    final WalletConnectBlockDataInspection dataInspection =
        inspectSendAccountBlockData(accountBlock);

    _logger.info(
      'WalletConnect request method=znn_send topic=$topic '
      'activeAddress=$activeAddress requestedFrom=$requestedFromAddress '
      'to=${accountBlock.toAddress} dataBytes=${dataInspection.rawByteLength}',
    );

    final String toAddress = ZenonAddressUtils.getLabel(
      accountBlock.toAddress.toString(),
    );

    final Token? token = await zenon!.embedded.token.getByZts(
      accountBlock.tokenStandard,
    );
    if (token == null) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw ReownCoreError(
        code: 5004,
        message: 'Unknown token standard ${accountBlock.tokenStandard}',
      );
    }

    final String amount = accountBlock.amount.addDecimals(token.decimals);

    final BuildContext? context = globalNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }

    final bool? wasActionAccepted = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: false,
      title: '$dAppName - Send Payment',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Are you sure you want to transfer '
              '$amount ${token.symbol} to '
              '$toAddress ?',
            ),
            kVerticalSpacing,
            _buildVerifyStatusBanner(verifyContext),
            kVerticalSpacing,
            Text('Network: ${_networkLabel()}'),
            kVerticalSpacing,
            Text('Source address: $signerAddress'),
            if (dataInspection.hasData) ...<Widget>[
              kVerticalSpacing,
              _buildAccountBlockDataDetails(dataInspection),
            ],
            kVerticalSpacing,
            if (dAppIconUrl != null)
              Image(
                image: NetworkImage(dAppIconUrl),
                height: 100,
                fit: BoxFit.fitHeight,
              ),
            kVerticalSpacing,
            Text(dAppDescription),
            kVerticalSpacing,
            if (dAppUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(dAppUrl, overflow: TextOverflow.ellipsis),
                  ),
                  LinkIcon(url: dAppUrl),
                ],
              ),
          ],
        ),
      ),
      description:
          'Are you sure you want to transfer '
          '$amount ${token.symbol} to '
          '$toAddress from $signerAddress on ${_networkLabel()} ?',
    );

    if (wasActionAccepted ?? false) {
      if (kCurrentPage == Tabs.lock) {
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw _walletLockedError;
      }
      revalidateInteractiveRequest(
        topic: topic,
        requestId: requestId,
        requireActiveChainMatch: true,
      );
      final AccountBlockTemplate blockToSend = AccountBlockTemplate.fromJson(
        accountBlockJson,
      );
      validateSendAccountBlock(blockToSend);

      final SendTransactionBloc sendPaymentBloc = SendTransactionBloc();
      try {
        sendPaymentBloc.add(
          SendTransactionInitiateFromBlock(
            block: blockToSend,
            fromAddress: signerAddress,
            reasonForGeneratingPlasma: 'Execute transfer',
          ),
        );

        final SendTransactionState result = await sendPaymentBloc.stream
            .firstWhere(
              (SendTransactionState element) =>
                  element.status == .success || element.status == .failure,
            );

        if (result.status == .success) {
          return result.data;
        } else {
          throw result.error!;
        }
      } finally {
        unawaited(sendPaymentBloc.close());
      }
    } else {
      await NotificationUtils.sendNotificationError(
        Errors.getSdkError(Errors.USER_REJECTED),
        'You have rejected the WalletConnect request',
      );
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getSdkError(Errors.USER_REJECTED);
    }
  }

  String _dAppName(PairingMetadata metadata) {
    return walletConnectDisplayValue(metadata.name, 'Unknown dApp');
  }

  String _dAppDescription(PairingMetadata metadata) {
    return walletConnectDisplayValue(
      metadata.description,
      'No description provided',
    );
  }

  String? _dAppUrl(PairingMetadata metadata) {
    return sanitizeWalletConnectHttpUrl(metadata.url);
  }

  String? _dAppIconUrl(PairingMetadata metadata) {
    for (final String icon in metadata.icons) {
      final String? sanitized = sanitizeWalletConnectHttpUrl(icon);
      if (sanitized != null) {
        return sanitized;
      }
    }
    return null;
  }
}
