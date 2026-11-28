@Tags(<String>['bend'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_token_stepper/create_token_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/token_favorite/token_favorite.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/tokens.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'tokens_zts';

final BigInt _kBaseUnit = BigInt.from(100000000);
final TokenStandard _kCustomZts = TokenStandard.fromBytes(
  List<int>.filled(10, 7),
);

class _InMemoryFavoriteTokensRepository implements FavoriteTokensRepository {
  _InMemoryFavoriteTokensRepository({
    required Set<String> initial,
    this.failAdd = false,
    this.failRemove = false,
  }) : _items = Set<String>.of(initial);

  final Set<String> _items;
  final bool failAdd;
  final bool failRemove;

  @override
  bool contains(TokenStandard tokenStandard) =>
      _items.contains(tokenStandard.toString());

  @override
  Future<void> add(TokenStandard tokenStandard) async {
    if (failAdd) {
      throw AddingToFavoriteTokensException(cause: Exception('injected add'));
    }
    _items.add(tokenStandard.toString());
  }

  @override
  Future<void> remove(TokenStandard tokenStandard) async {
    if (failRemove) {
      throw RemovingFromFavoriteTokensException(
        cause: Exception('injected remove'),
      );
    }
    _items.remove(tokenStandard.toString());
  }
}

/// Builds a syntactically valid domain of exact length [domLen] for
/// `domLen >= 5` (with every DNS label within `[2, 63]` chars) so
/// [validateTokenDomainError] exercises both `tokenDomainRegExp` and
/// [kTokenDomainMaxLength].
String _buildDomainCandidate(int domLen) {
  if (domLen <= 4) {
    return 'a' * domLen;
  }
  if (domLen <= 66) {
    return '${'a' * (domLen - 3)}.io';
  }
  if (domLen <= 69) {
    return 'aa.${'b' * (domLen - 6)}.io';
  }
  return '${'a' * (domLen - 67)}.${'b' * 63}.io';
}

bool _evalRealTokenMetadata({
  required int nameLen,
  required int symLen,
  required String symKind,
  required int domLen,
  required int dec,
}) {
  final String name = 'A' * nameLen;
  final String symbol = switch (symKind) {
    'znn' => 'ZNN',
    'qsr' => 'QSR',
    'custom' => 'X' * symLen,
    _ => fail('Unknown symKind "$symKind"'),
  };
  final String domain = _buildDomainCandidate(domLen);

  final bool nameOk = validateTokenNameError(name) == null;
  final bool symbolOk = validateTokenSymbolError(symbol) == null;
  final bool domainOk = domLen >= 1 && domLen <= 4
      ? isValidTokenDomainLength(domain)
      : validateTokenDomainError(domain) == null;
  final bool decOk = isValidTokenDecimals(dec);
  return nameOk && symbolOk && domainOk && decOk;
}

void main() {
  late Directory tempHiveDir;

  setUpAll(() async {
    tempHiveDir = await Directory.systemTemp.createTemp('syrius_bend_zts_');
    Hive.init(tempHiveDir.path);
    await Hive.openBox<dynamic>(kFavoriteTokensBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempHiveDir.existsSync()) {
      await tempHiveDir.delete(recursive: true);
    }
  });

  group('Bend conformance: $_kDomain', () {
    test(
      'all Bend oracle vectors match Syrius ZTS token logic & BLoCs',
      () async {
        final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
        final Box<dynamic> favBox = Hive.box<dynamic>(kFavoriteTokensBox);
        final Set<String> seenOps = <String>{};

        for (final Map<String, dynamic> vector in vectors) {
          final String caseId = requireCaseId(vector);
          final String op = requireOp(vector);
          final Map<String, dynamic> args = requireArgs(vector);
          final Object? expected = vector['expected'];
          seenOps.add(op);

          switch (op) {
            case 'issue_constants':
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'plasma_u32': kIssueTokenPlasmaAmountNeeded,
                  'znn_fee': (tokenZtsIssueFeeInZnn ~/ _kBaseUnit).toInt(),
                },
                expected: expected,
              );
            case 'token_caps':
              final TokenCapabilities caps = evaluateTokenCapabilities(
                isMintable: requireBool(args, 'is_mintable'),
                isBurnable: requireBool(args, 'is_burnable'),
                totalSupply: BigInt.from(requireInt(args, 'total')),
                maxSupply: BigInt.from(requireInt(args, 'max_sup')),
                isSelectedOwner: requireBool(args, 'is_sel_owner'),
                isWalletOwner: requireBool(args, 'is_wallet_owner'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'can_transfer': caps.canTransferOwnership,
                  'show_mint': caps.showMintButton,
                  'can_mint': caps.canMint,
                  'can_burn': caps.canBurn,
                  'show_own_badge': caps.showOwnBadge,
                },
                expected: expected,
              );
            case 'valid_token_supply':
              final TokenSupplyMetricsValidation validation =
                  validateTokenSupplyMetrics(
                    isMintable: requireBool(args, 'is_mintable'),
                    totalSupplyText: '${requireInt(args, 'total')}',
                    maxSupplyText: '${requireInt(args, 'max_in')}',
                    decimals: requireInt(args, 'dec'),
                    maxSupplyCap: BigInt.from(requireInt(args, 'cap')),
                    scaleDecimals: 0,
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'valid': validation.isValid,
                  'effective_max': validation.effectiveMaxSupply.toInt(),
                },
                expected: expected,
              );
            case 'can_mint_amount':
              final bool actual = canMintTokenAmount(
                amount: BigInt.from(requireInt(args, 'amt')),
                totalSupply: BigInt.from(requireInt(args, 'total')),
                maxSupply: BigInt.from(requireInt(args, 'max_sup')),
                isMintable: requireBool(args, 'is_mintable'),
                isSelectedOwner: requireBool(args, 'is_sel_owner'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'can_burn_amount':
              final bool actual = canBurnTokenAmount(
                amount: BigInt.from(requireInt(args, 'amt')),
                balance: BigInt.from(requireInt(args, 'balance')),
                totalSupply: BigInt.from(requireInt(args, 'total')),
                isBurnable: requireBool(args, 'is_burnable'),
                isSelectedOwner: requireBool(args, 'is_sel_owner'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'valid_token_metadata':
              final bool actual = _evalRealTokenMetadata(
                nameLen: requireInt(args, 'name_len'),
                symLen: requireInt(args, 'sym_len'),
                symKind: requireString(args, 'sym_kind'),
                domLen: requireInt(args, 'dom_len'),
                dec: requireInt(args, 'dec'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'is_trusted_token':
              final bool isZnn = requireBool(args, 'is_znn');
              final bool isQsr = requireBool(args, 'is_qsr');
              final bool isFav = requireBool(args, 'is_favorite');
              await favBox.clear();
              if (isFav) {
                await favBox.add(_kCustomZts.toString());
              }
              final String targetZts = isZnn
                  ? znnTokenStandard
                  : (isQsr ? qsrTokenStandard : _kCustomZts.toString());
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: isTrustedToken(targetZts),
                expected: expected,
              );
            case 'fav_transition':
              final String initial = requireString(args, 'initial');
              final String eventName = requireString(args, 'event');
              final bool failOp = requireBool(args, 'fail');
              final _InMemoryFavoriteTokensRepository repo =
                  _InMemoryFavoriteTokensRepository(
                    initial: initial == 'favorite'
                        ? <String>{_kCustomZts.toString()}
                        : <String>{},
                    failAdd: failOp && eventName == 'add',
                    failRemove: failOp && eventName == 'remove',
                  );
              final TokenFavoriteBloc bloc = TokenFavoriteBloc(
                tokenStandard: _kCustomZts,
                repository: repo,
              );
              if (eventName == 'add') {
                bloc.add(const TokenFavoriteAdded());
              } else if (eventName == 'remove') {
                bloc.add(const TokenFavoriteRemoved());
              } else {
                fail('Unknown fav event "$eventName"');
              }
              await Future<void>.delayed(Duration.zero);
              final TokenFavoriteState finalState = bloc.state;
              await bloc.close();
              final bool showsAdd = switch (finalState) {
                TokenFavoriteNotFavorited() => true,
                TokenFavoriteFailure(
                  exception: AddingToFavoriteTokensException(),
                ) =>
                  true,
                _ => false,
              };
              final bool showsRemove = switch (finalState) {
                TokenFavoriteFavorited() => true,
                TokenFavoriteFailure(
                  exception: RemovingFromFavoriteTokensException(),
                ) =>
                  true,
                _ => false,
              };
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'shows_add': showsAdd,
                  'shows_remove': showsRemove,
                },
                expected: expected,
              );
            default:
              fail('Unhandled Bend conformance op "$_kDomain/$op"');
          }
        }

        expect(
          seenOps,
          equals(const <String>{
            'issue_constants',
            'token_caps',
            'valid_token_supply',
            'can_mint_amount',
            'can_burn_amount',
            'valid_token_metadata',
            'is_trusted_token',
            'fav_transition',
          }),
        );
      },
    );

    test('compareAssets and sortAssets satisfy strict weak ordering', () {
      final Token customA = Token(
        'Alpha',
        'ALP',
        'alpha.example',
        BigInt.from(100),
        8,
        emptyAddress,
        _kCustomZts,
        BigInt.from(1000),
        true,
        true,
        true,
      );
      final List<Token> tokens = <Token>[kZnnCoin, kQsrCoin, customA];
      for (final Token a in tokens) {
        expect(compareAssets(a, a), equals(0));
        for (final Token b in tokens) {
          expect(compareAssets(a, b), equals(-compareAssets(b, a)));
        }
      }
      final List<Token> sorted = sortAssets(<Token>[
        customA,
        kQsrCoin,
        kZnnCoin,
      ]);
      expect(
        sorted.map((Token t) => t.symbol).toList(),
        equals(<String>['ZNN', 'QSR', 'ALP']),
      );
    });
  });
}
