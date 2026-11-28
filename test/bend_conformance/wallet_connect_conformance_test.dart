@Tags(<String>['bend'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart' hide Address;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/wallet_connect_metadata_utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_request_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_uri_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'wallet_connect';

const List<String> _kTestAddresses = <String>[
  'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
  'z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz',
  'z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0',
  'z1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsggv2f',
];

class _MockWeb3WalletService extends Mock implements IWeb3WalletService {}

String _addrForId(int id) {
  if (id < 0 || id >= _kTestAddresses.length) {
    fail('Address id out of range [0..${_kTestAddresses.length - 1}]: $id');
  }
  return _kTestAddresses[id];
}

int _idForAddr(String address) {
  final int index = _kTestAddresses.indexOf(address);
  if (index < 0) {
    fail('Unexpected resolved address "$address"');
  }
  return index;
}

String _buildRawWcLink({
  required String source,
  required bool hasWindowsSlashQuery,
  required bool hasOuterWhitespace,
  required int version,
  required bool topicNonEmpty,
  required bool relayProtocolNonEmpty,
  required bool symKeyNonEmpty,
}) {
  if (source == 'non_wc') {
    return hasOuterWhitespace ? '   https://zenon.network/not-wc   ' : 'hello';
  }
  final String topic = topicNonEmpty ? 'abc123topic' : '';
  final String querySep = hasWindowsSlashQuery ? '/?' : '?';
  final List<String> params = <String>[
    if (relayProtocolNonEmpty) 'relay-protocol=irn',
    if (symKeyNonEmpty) 'symKey=0123456789abcdef',
  ];
  final String query = params.isEmpty ? 'foo=bar' : params.join('&');
  final String coreUri = 'wc:$topic@$version$querySep$query';

  final String doubleEncoded = Uri.encodeComponent(
    Uri.encodeComponent(coreUri),
  );
  final String wrapped = switch (source) {
    'direct' => coreUri,
    'percent_once' => Uri.encodeComponent(coreUri),
    'percent_twice' => 'custom:::prefix uri=$doubleEncoded',
    'query_param' => 'syrius://wc?uri=${Uri.encodeComponent(coreUri)}',
    'regex_fallback' => 'custom:::prefix uri=${Uri.encodeComponent(coreUri)}',
    _ => fail('Unknown WcUriSource "$source"'),
  };

  return hasOuterWhitespace ? '  $wrapped\n' : wrapped;
}

Validation _parseValidation(String value) {
  return switch (value) {
    'valid' => Validation.VALID,
    'invalid' => Validation.INVALID,
    'unknown' => Validation.UNKNOWN,
    'scam' => Validation.SCAM,
    _ => fail('Unknown VerifyValidation "$value"'),
  };
}

VerifyContext? _buildVerifyContext({
  required bool present,
  required bool isScamFlag,
  required String validation,
}) {
  if (!present) {
    return null;
  }
  return VerifyContext(
    origin: 'https://dapp.example',
    validation: _parseValidation(validation),
    verifyUrl: 'https://verify.walletconnect.org',
    isScam: isScamFlag,
  );
}

String? _buildRawUrl({
  required bool malformed,
  required String scheme,
  required bool hasAuthority,
  required bool hostNonEmpty,
}) {
  if (malformed) {
    return ':::malformed-uri';
  }
  final String schemeText = switch (scheme) {
    'http' => 'http',
    'https' => 'https',
    'javascript' => 'javascript',
    'file' => 'file',
    'data' => 'data',
    'other' => 'ftp',
    _ => fail('Unknown UrlScheme "$scheme"'),
  };
  if (!hasAuthority) {
    return hostNonEmpty ? '$schemeText:example.com/path' : '$schemeText:';
  }
  return hostNonEmpty ? '$schemeText://example.com/app' : '$schemeText:///path';
}

Map<String, RequiredNamespace> _buildNamespaceMap(Object? rawEntries) {
  if (rawEntries is! List<dynamic>) {
    fail('Expected List for namespace entries, got $rawEntries');
  }
  final Map<String, RequiredNamespace> result = <String, RequiredNamespace>{};
  for (int i = 0; i < rawEntries.length; i += 1) {
    final Object? item = rawEntries[i];
    if (item is! Map<String, dynamic>) {
      fail('Malformed namespace entry at index $i: $item');
    }
    final String nsKey = requireString(item, 'ns_key');
    final List<String> chains = _requireStringList(item, 'chains');
    final List<String> methods = _requireStringList(item, 'methods');
    final List<String> events = _requireStringList(item, 'events');
    final String mapKey = result.containsKey(nsKey)
        ? '$nsKey:${i + 1}'
        : nsKey;
    result[mapKey] = RequiredNamespace(
      chains: chains,
      methods: methods,
      events: events,
    );
  }
  return result;
}

List<String> _requireStringList(Map<String, dynamic> map, String key) {
  final Object? value = map[key];
  if (value is! List<dynamic>) {
    fail('Expected List<String> for "$key" in $map, got $value');
  }
  final List<String> out = <String>[];
  for (final Object? element in value) {
    if (element is! String) {
      fail('Expected String element in "$key" of $map, got $element');
    }
    out.add(element);
  }
  return out;
}

NoMChainId _parseNoMChainId(String chain) {
  return switch (chain) {
    'mainnet' => NoMChainId.mainnet,
    'testnet' => NoMChainId.testnet,
    _ => fail('Unknown NoMChainId "$chain"'),
  };
}

SessionData _buildSession({
  required String topic,
  required String caip2Chain,
}) {
  return SessionData(
    topic: topic,
    pairingTopic: 'pairing-$topic',
    relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
    expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    acknowledged: true,
    controller: 'controller-key',
    namespaces: <String, Namespace>{
      'zenon': Namespace(
        chains: <String>[caip2Chain],
        accounts: <String>['$caip2Chain:${_kTestAddresses[0]}'],
        methods: const <String>['znn_info', 'znn_sign', 'znn_send'],
        events: const <String>['chainIdChange', 'addressChange'],
      ),
    },
    self: const ConnectionMetadata(
      publicKey: 'self-key',
      metadata: PairingMetadata(
        name: 's y r i u s',
        description: 'Zenon wallet',
        url: 'https://zenon.network',
      ),
    ),
    peer: const ConnectionMetadata(
      publicKey: 'peer-key',
      metadata: PairingMetadata(
        name: 'Test dApp',
        description: 'dApp',
        url: 'https://example.invalid',
      ),
    ),
  );
}

int _realValidateSendBlock({
  required String blockType,
  required bool fromHashEmpty,
  required int blockChainId,
  required String sessionChain,
  required int activeChainId,
  required IWeb3WalletService walletService,
}) {
  setChainIdentifier(chainIdentifier: activeChainId);
  final NoMService nom = NoMService(
    reference: _parseNoMChainId(sessionChain),
    web3WalletService: walletService,
  );
  final AccountBlockTemplate block =
      (switch (blockType) {
          'user_send' => AccountBlockTemplate.send(
            Address.parse(_kTestAddresses[1]),
            znnZts,
            BigInt.from(100000000),
          ),
          'user_receive' => AccountBlockTemplate.receive(Hash.parse('a' * 64)),
          'contract_send' => AccountBlockTemplate.send(
            Address.parse(_kTestAddresses[1]),
            znnZts,
            BigInt.from(100000000),
          )..blockType = BlockTypeEnum.contractSend.index,
          'contract_receive' => AccountBlockTemplate.send(
            Address.parse(_kTestAddresses[1]),
            znnZts,
            BigInt.from(100000000),
          )..blockType = BlockTypeEnum.contractReceive.index,
          _ => fail('Unknown block_type "$blockType"'),
        })
        ..chainIdentifier = blockChainId
        ..fromBlockHash = fromHashEmpty ? emptyHash : Hash.parse('b' * 64);

  try {
    nom.validateSendAccountBlock(block);
    return 0;
  } on ReownCoreError catch (error) {
    return error.code;
  }
}

int _realResolveSigner({
  required int activeAddrId,
  required String reqKind,
  required int reqAddrId,
  required List<int> ownedIds,
  required IWeb3WalletService walletService,
}) {
  final Map<String, String> labels = <String, String>{};
  final List<String?> defaults = <String?>[];
  for (final int ownedId in ownedIds) {
    final String addr = _addrForId(ownedId);
    labels[addr] = 'Addr $ownedId';
    defaults.add(addr);
  }
  kAddressLabelMap = labels;
  kDefaultAddressList = defaults;

  final NoMService nom = NoMService(
    reference: NoMChainId.mainnet,
    web3WalletService: walletService,
  );
  final String? requested = switch (reqKind) {
    'none' => null,
    'empty' => '',
    'value' => _addrForId(reqAddrId),
    _ => fail('Unknown req_kind "$reqKind"'),
  };

  try {
    final String resolved = nom.resolveSignerAddress(
      activeAddress: _addrForId(activeAddrId),
      requestedFromAddress: requested,
      method: 'znn_send',
      topic: 'topic-conformance',
    );
    return _idForAddr(resolved);
  } on ReownCoreError catch (error) {
    final int expectedCode = Errors.getSdkError(
      Errors.UNSUPPORTED_ACCOUNTS,
    ).code;
    if (error.code != expectedCode) {
      fail(
        'Expected UNSUPPORTED_ACCOUNTS ($expectedCode), got ${error.code}',
      );
    }
    return -1;
  }
}

int _realRevalidateInteractiveRequest({
  required String method,
  required bool walletLocked,
  required bool sessionActive,
  required bool hasRequestId,
  required bool requestStillPending,
  required String serviceChain,
  required String sessionChain,
  required int activeChainId,
  required _MockWeb3WalletService walletService,
}) {
  final Tabs? savedPage = kCurrentPage;
  kCurrentPage = walletLocked ? Tabs.lock : Tabs.transfer;
  try {
    setChainIdentifier(chainIdentifier: activeChainId);
    final String sessionCaip2 = _parseNoMChainId(sessionChain).chain();
    when(walletService.getActiveSessions).thenReturn(
      sessionActive
          ? <String, SessionData>{
              'topic-reval': _buildSession(
                topic: 'topic-reval',
                caip2Chain: sessionCaip2,
              ),
            }
          : <String, SessionData>{},
    );
    when(walletService.getPendingSessionRequests).thenReturn(
      requestStillPending
          ? <String, SessionRequest>{
              '55': SessionRequest(
                id: 55,
                topic: 'topic-reval',
                method: method,
                chainId: sessionCaip2,
                params: const <String, dynamic>{},
                verifyContext: const VerifyContext(
                  origin: 'https://dapp.example',
                  validation: Validation.VALID,
                  verifyUrl: '',
                ),
              ),
            }
          : <String, SessionRequest>{},
    );

    final NoMService nom = NoMService(
      reference: _parseNoMChainId(serviceChain),
      web3WalletService: walletService,
    );
    try {
      nom.revalidateInteractiveRequest(
        topic: 'topic-reval',
        requestId: hasRequestId ? 55 : null,
        requireActiveChainMatch: method != 'znn_info',
      );
      return 0;
    } on ReownCoreError catch (error) {
      return error.code;
    }
  } finally {
    kCurrentPage = savedPage;
  }
}

void main() {
  group('Bend conformance: $_kDomain', () {
    late Map<String, String> previousAddressMap;
    late List<String?> previousAddressList;
    late int previousChainId;
    late Tabs? previousPage;

    setUp(() {
      previousAddressMap = Map<String, String>.from(kAddressLabelMap);
      previousAddressList = List<String?>.from(kDefaultAddressList);
      previousChainId = getChainIdentifier();
      previousPage = kCurrentPage;
    });

    tearDown(() {
      kAddressLabelMap = previousAddressMap;
      kDefaultAddressList = previousAddressList;
      setChainIdentifier(chainIdentifier: previousChainId);
      kCurrentPage = previousPage;
    });

    test('all Bend oracle vectors match Syrius WalletConnect logic', () {
      final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
      final _MockWeb3WalletService mockWalletService = _MockWeb3WalletService();
      final Web3WalletService nsService = Web3WalletService();
      addTearDown(nsService.onDispose);
      final Set<String> seenOps = <String>{};

      for (final Map<String, dynamic> vector in vectors) {
        final String caseId = requireCaseId(vector);
        final String op = requireOp(vector);
        final Map<String, dynamic> args = requireArgs(vector);
        final Object? expected = vector['expected'];
        seenOps.add(op);

        switch (op) {
          case 'extract_wc_uri':
            final bool isWindows = requireBool(args, 'is_windows');
            final String rawLink = _buildRawWcLink(
              source: requireString(args, 'source'),
              hasWindowsSlashQuery: requireBool(
                args,
                'has_windows_slash_query',
              ),
              hasOuterWhitespace: requireBool(args, 'has_outer_whitespace'),
              version: requireInt(args, 'version'),
              topicNonEmpty: requireBool(args, 'topic_non_empty'),
              relayProtocolNonEmpty: requireBool(
                args,
                'relay_protocol_non_empty',
              ),
              symKeyNonEmpty: requireBool(args, 'sym_key_non_empty'),
            );
            final String? extracted = extractWalletConnectUri(
              rawLink,
              isWindows: isWindows,
            );
            final bool actual = extracted != null;
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
            expect(isWalletConnectUri(rawLink, isWindows: isWindows), actual);
            if (extracted != null) {
              expect(
                extractWalletConnectUri(extracted, isWindows: isWindows),
                extracted,
              );
            }

          case 'interactive_request_key_eq':
            final Object? rawId1 = args['request_id1'];
            final Object? rawId2 = args['request_id2'];
            final String key1 = interactiveRequestKey(
              method: 'm${requireInt(args, 'method1')}',
              topic: 't${requireInt(args, 'topic1')}',
              params: <String, int>{'fp': requireInt(args, 'fp1')},
              requestId: rawId1 is int ? rawId1 : null,
            );
            final String key2 = interactiveRequestKey(
              method: 'm${requireInt(args, 'method2')}',
              topic: 't${requireInt(args, 'topic2')}',
              params: <String, int>{'fp': requireInt(args, 'fp2')},
              requestId: rawId2 is int ? rawId2 : null,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: key1 == key2,
              expected: expected,
            );

          case 'wc_error_to_json_rpc_code':
            final String kind = requireString(args, 'kind');
            final int code = requireInt(args, 'code');
            final Object errorObj = switch (kind) {
              'json_rpc' => JsonRpcError(code: code, message: 'rpc err'),
              'reown_sign' => ReownSignError(code: code, message: 'sign err'),
              'reown_core' => ReownCoreError(code: code, message: 'core err'),
              'unknown' => StateError('unexpected failure'),
              _ => fail('Unknown WcHandlerError kind "$kind"'),
            };
            final JsonRpcError mapped = walletConnectErrorToJsonRpcError(
              errorObj,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: mapped.code,
              expected: expected,
            );

          case 'is_verify_scam':
            final VerifyContext? ctx = _buildVerifyContext(
              present: requireBool(args, 'present'),
              isScamFlag: requireBool(args, 'is_scam_flag'),
              validation: requireString(args, 'validation'),
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: isWalletConnectVerifyScam(ctx),
              expected: expected,
            );

          case 'describe_verify_context':
            final VerifyContext? ctx = _buildVerifyContext(
              present: requireBool(args, 'present'),
              isScamFlag: requireBool(args, 'is_scam_flag'),
              validation: requireString(args, 'validation'),
            );
            final WalletConnectVerifySummary summary =
                describeWalletConnectVerifyContext(ctx);
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: summary.severity.name,
              expected: expected,
            );

          case 'sanitize_http_url':
            final String? rawUrl = _buildRawUrl(
              malformed: requireBool(args, 'malformed'),
              scheme: requireString(args, 'scheme'),
              hasAuthority: requireBool(args, 'has_authority'),
              hostNonEmpty: requireBool(args, 'host_non_empty'),
            );
            final bool allowed = sanitizeWalletConnectHttpUrl(rawUrl) != null;
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: allowed,
              expected: expected,
            );

          case 'display_value':
            final String kind = requireString(args, 'kind');
            final int textId = requireInt(args, 'text_id');
            final int fallbackId = requireInt(args, 'fallback_id');
            final String? raw = switch (kind) {
              'null' => null,
              'whitespace' => '   \t\n ',
              'literal_null' => '  NuLl  ',
              'text' => '  val-$textId  ',
              _ => fail('Unknown RawDisplayInput kind "$kind"'),
            };
            final String actualLabel = walletConnectDisplayValue(
              raw,
              'val-$fallbackId',
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actualLabel,
              expected: 'val-$expected',
            );

          case 'unsupported_required_namespace_reason':
            setChainIdentifier(
              chainIdentifier: requireInt(args, 'active_chain_id'),
            );
            final Map<String, RequiredNamespace> reqs = _buildNamespaceMap(
              args['entries'],
            );
            final bool accepted =
                nsService.unsupportedRequiredNamespaceReason(reqs) == null;
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: accepted,
              expected: expected,
            );

          case 'build_approved_namespaces':
            final int activeChainId = requireInt(args, 'active_chain_id');
            setChainIdentifier(chainIdentifier: activeChainId);
            kAddressLabelMap = <String, String>{
              _kTestAddresses[0]: 'Address 1',
            };
            final ProposalData proposal = ProposalData(
              id: 1,
              expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
              relays: <Relay>[Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL)],
              proposer: const ConnectionMetadata(
                publicKey: 'peer',
                metadata: PairingMetadata(
                  name: 'Test dApp',
                  description: 'desc',
                  url: 'https://example.invalid',
                ),
              ),
              requiredNamespaces: _buildNamespaceMap(args['required']),
              optionalNamespaces: _buildNamespaceMap(args['optional']),
              pairingTopic: 'pairing-topic',
            );
            final Map<String, Namespace> approved = nsService
                .buildApprovedNamespaces(proposal);
            final Namespace? zenonNs = approved['zenon'];
            if (zenonNs == null) {
              fail('buildApprovedNamespaces omitted "zenon" namespace');
            }
            final List<String> actualChains = List<String>.from(
              zenonNs.chains ?? const <String>[],
            );
            final List<String> actualMethods = List<String>.from(
              zenonNs.methods,
            )..sort();
            final List<String> actualEvents = List<String>.from(
              zenonNs.events,
            )..sort();
            if (expected is! Map<String, dynamic>) {
              fail('Expected map for build_approved_namespaces, got $expected');
            }
            final List<String> expChains = _requireStringList(
              expected,
              'chains',
            );
            final List<String> expMethods = _requireStringList(
              expected,
              'methods',
            )..sort();
            final List<String> expEvents = _requireStringList(
              expected,
              'events',
            )..sort();
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: <String, Object>{
                'chains': actualChains,
                'methods': actualMethods,
                'events': actualEvents,
              },
              expected: <String, Object>{
                'chains': expChains,
                'methods': expMethods,
                'events': expEvents,
              },
            );

          case 'encode_signed_message_payload':
            final String message = requireString(args, 'message');
            final Uint8List bytes = NoMService.encodeSignedMessagePayload(
              message,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: bytes.toList(),
              expected: expected,
            );

          case 'validate_send_account_block':
            final int actualCode = _realValidateSendBlock(
              blockType: requireString(args, 'block_type'),
              fromHashEmpty: requireBool(args, 'from_hash_empty'),
              blockChainId: requireInt(args, 'block_chain_id'),
              sessionChain: requireString(args, 'session_chain'),
              activeChainId: requireInt(args, 'active_chain_id'),
              walletService: mockWalletService,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actualCode,
              expected: expected,
            );

          case 'resolve_signer_address':
            final int actualAddrId = _realResolveSigner(
              activeAddrId: requireInt(args, 'active_addr_id'),
              reqKind: requireString(args, 'req_kind'),
              reqAddrId: requireInt(args, 'req_addr_id'),
              ownedIds: requireIntList(args, 'owned_ids'),
              walletService: mockWalletService,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actualAddrId,
              expected: expected,
            );

          case 'revalidate_interactive_request':
            final int actualCode = _realRevalidateInteractiveRequest(
              method: requireString(args, 'method'),
              walletLocked: requireBool(args, 'wallet_locked'),
              sessionActive: requireBool(args, 'session_active'),
              hasRequestId: requireBool(args, 'has_request_id'),
              requestStillPending: requireBool(args, 'request_still_pending'),
              serviceChain: requireString(args, 'service_chain'),
              sessionChain: requireString(args, 'session_chain'),
              activeChainId: requireInt(args, 'active_chain_id'),
              walletService: mockWalletService,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actualCode,
              expected: expected,
            );

          case 'parallel_send_preflight':
            final VerifyContext? ctx = _buildVerifyContext(
              present: requireBool(args, 'ctx_present'),
              isScamFlag: requireBool(args, 'is_scam_flag'),
              validation: requireString(args, 'validation'),
            );
            final String? rawUrl = _buildRawUrl(
              malformed: requireBool(args, 'url_malformed'),
              scheme: requireString(args, 'url_scheme'),
              hasAuthority: requireBool(args, 'url_has_authority'),
              hostNonEmpty: requireBool(args, 'url_host_non_empty'),
            );
            final bool metaOk =
                !isWalletConnectVerifyScam(ctx) &&
                sanitizeWalletConnectHttpUrl(rawUrl) != null;
            final bool blockOk =
                _realValidateSendBlock(
                  blockType: requireString(args, 'block_type'),
                  fromHashEmpty: requireBool(args, 'from_hash_empty'),
                  blockChainId: requireInt(args, 'block_chain_id'),
                  sessionChain: requireString(args, 'session_chain'),
                  activeChainId: requireInt(args, 'active_chain_id'),
                  walletService: mockWalletService,
                ) ==
                0;
            final bool signerOk =
                _realResolveSigner(
                  activeAddrId: requireInt(args, 'active_addr_id'),
                  reqKind: requireString(args, 'req_kind'),
                  reqAddrId: requireInt(args, 'req_addr_id'),
                  ownedIds: requireIntList(args, 'owned_ids'),
                  walletService: mockWalletService,
                ) >=
                0;
            final bool revalOk =
                _realRevalidateInteractiveRequest(
                  method: 'znn_send',
                  walletLocked: requireBool(args, 'wallet_locked'),
                  sessionActive: requireBool(args, 'session_active'),
                  hasRequestId: requireBool(args, 'has_request_id'),
                  requestStillPending: requireBool(
                    args,
                    'request_still_pending',
                  ),
                  serviceChain: requireString(args, 'service_chain'),
                  sessionChain: requireString(args, 'session_chain'),
                  activeChainId: requireInt(args, 'active_chain_id'),
                  walletService: mockWalletService,
                ) ==
                0;
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: metaOk && blockOk && signerOk && revalOk,
              expected: expected,
            );

          default:
            fail('Unhandled Bend conformance op "$_kDomain/$op"');
        }
      }

      expect(
        seenOps,
        equals(<String>{
          'extract_wc_uri',
          'interactive_request_key_eq',
          'wc_error_to_json_rpc_code',
          'is_verify_scam',
          'describe_verify_context',
          'sanitize_http_url',
          'display_value',
          'unsupported_required_namespace_reason',
          'build_approved_namespaces',
          'encode_signed_message_payload',
          'validate_send_account_block',
          'resolve_signer_address',
          'revalidate_interactive_request',
          'parallel_send_preflight',
        }),
      );
    });
  }, skip: bendConformanceSkipReason);
}
