import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/fuse_plasma/fuse_plasma.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/initial_htlc_validation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/tokens.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _TestProtocolHandler extends ProtocolHandler {
  @override
  void register(String scheme, {String? executable, List<String>? arguments}) {}

  @override
  void unregister(String scheme) {}
}

Token _token(String symbol, TokenStandard zts) => Token(
  symbol,
  symbol,
  'zenon.network',
  BigInt.from(100),
  8,
  emptyAddress,
  zts,
  BigInt.from(1000),
  true,
  true,
  true,
);

PlasmaInfo _plasma(int currentPlasma) => PlasmaInfo.fromJson(<String, dynamic>{
  'currentPlasma': currentPlasma,
  'maxPlasma': currentPlasma,
  'qsrAmount': '0',
});

void main() {
  group('sortAssets and compareAssets', () {
    final Token znn = _token('ZNN', znnZts);
    final Token qsr = _token('QSR', qsrZts);
    final Token ztsA = _token(
      'AAA',
      TokenStandard.fromBytes(List<int>.filled(10, 1)),
    );
    final Token ztsB = _token(
      'BBB',
      TokenStandard.fromBytes(List<int>.filled(10, 2)),
    );

    test('satisfies reflexivity and antisymmetry across all token pairs', () {
      final List<Token> all = <Token>[znn, qsr, ztsA, ztsB];
      for (final Token a in all) {
        expect(compareAssets(a, a), 0);
        for (final Token b in all) {
          expect(compareAssets(a, b), -compareAssets(b, a));
        }
      }
      expect(compareAssets(znn, qsr), -1);
      expect(compareAssets(qsr, znn), 1);
      expect(compareAssets(qsr, ztsA), -1);
      expect(compareAssets(ztsA, ztsB), 0);
    });

    test('places ZNN then QSR before custom tokens', () {
      final List<Token> sorted = sortAssets(<Token>[ztsA, qsr, ztsB, znn]);
      expect(sorted.map((Token t) => t.symbol).toList(), <String>[
        'ZNN',
        'QSR',
        'AAA',
        'BBB',
      ]);
    });

    test('preserves relative order of >32 custom tokens (stable sort)', () {
      final List<Token> customTokens = <Token>[
        for (int i = 0; i < 50; i += 1)
          _token(
            'T$i',
            TokenStandard.fromBytes(<int>[1, 2, 3, 4, 5, 6, 7, 8, 0, i]),
          ),
      ];
      final List<Token> input = <Token>[
        ...customTokens.sublist(0, 17),
        qsr,
        ...customTokens.sublist(17, 35),
        znn,
        ...customTokens.sublist(35),
      ];
      final List<Token> sorted = sortAssets(input);
      expect(
        sorted.map((Token t) => t.symbol).toList(),
        <String>['ZNN', 'QSR', for (int i = 0; i < 50; i += 1) 'T$i'],
      );
    });
  });

  group('truncateToWholeQsr', () {
    test('truncates fractional QSR balances down to whole units', () {
      final BigInt unit = BigInt.from(10).pow(coinDecimals);
      final BigInt fractional = BigInt.from(25) * unit + BigInt.from(50000000);
      final BigInt truncated = truncateToWholeQsr(fractional);
      expect(truncated, BigInt.from(25) * unit);
      final String formatted = truncated.addDecimals(coinDecimals);
      expect(formatted, '25');
      expect(isIntegerQsrAmount(formatted), isTrue);
      expect(
        canFusePlasma(
          amountText: formatted,
          maxQsrBalance: fractional,
          beneficiaryAddress: emptyAddress.toString(),
        ),
        isTrue,
      );

      expect(
        truncateToWholeQsr(BigInt.from(10) * unit),
        BigInt.from(10) * unit,
      );
      expect(truncateToWholeQsr(BigInt.from(50000000)), BigInt.zero);
      expect(truncateToWholeQsr(BigInt.zero), BigInt.zero);
      expect(truncateToWholeQsr(BigInt.from(-100)), BigInt.zero);
    });
  });

  group('ProtocolHandler.getArguments', () {
    final _TestProtocolHandler handler = _TestProtocolHandler();

    test('defaults to ["%s"] when null', () {
      expect(handler.getArguments(null), <String>['%s']);
    });

    test('rejects empty list and non-empty list without %s', () {
      expect(() => handler.getArguments(<String>[]), throwsArgumentError);
      expect(
        () => handler.getArguments(<String>['--open', 'url']),
        throwsArgumentError,
      );
    });

    test('accepts list containing %s', () {
      expect(
        handler.getArguments(<String>['--open', '%s']),
        <String>['--open', '%s'],
      );
    });
  });

  group('computeMomentumUptimePercentage', () {
    test('guards zero/negative expected and negative produced without throwing',
        () {
      expect(computeMomentumUptimePercentage(0, 0), 0);
      expect(computeMomentumUptimePercentage(5, 0), 0);
      expect(computeMomentumUptimePercentage(5, -2), 0);
      expect(computeMomentumUptimePercentage(-1, 10), 0);
      expect(computeMomentumUptimePercentage(0, 10), 0);
      expect(computeMomentumUptimePercentage(1, 3), 33);
      expect(computeMomentumUptimePercentage(2, 3), 67);
      expect(computeMomentumUptimePercentage(10, 10), 100);
    });
  });

  group('PlasmaTier classification, color, and tooltip agreement', () {
    test('partitions bands monotonically and agrees with ColorUtils and '
        'WidgetUtils', () {
      final List<(int, PlasmaTier, Color, String)> cases =
          <(int, PlasmaTier, Color, String)>[
            (0, PlasmaTier.insufficient, AppColors.ztsColor,
                'Insufficient Plasma'),
            (20999, PlasmaTier.insufficient, AppColors.ztsColor,
                'Insufficient Plasma'),
            (21000, PlasmaTier.low, Colors.orange, 'Low Plasma'),
            (188999, PlasmaTier.low, Colors.orange, 'Low Plasma'),
            (189000, PlasmaTier.average, Colors.yellow, 'Average Plasma'),
            (251999, PlasmaTier.average, Colors.yellow, 'Average Plasma'),
            (252000, PlasmaTier.high, AppColors.znnColor, 'High Plasma'),
            (500000, PlasmaTier.high, AppColors.znnColor, 'High Plasma'),
          ];
      for (final (int plasma, PlasmaTier tier, Color color, String label)
          in cases) {
        expect(classifyPlasmaTier(plasma), tier);
        expect(ColorUtils.getPlasmaColor(_plasma(plasma)), color);
        expect(WidgetUtils.getPlasmaToolTipMessage(_plasma(plasma)), label);
      }
    });
  });

  group('classifyPasswordStrength', () {
    test('classifies empty, short, invalid-long, medium, and strong', () {
      expect(
        classifyPasswordStrength('', isValid: false),
        PasswordStrengthTier.empty,
      );
      expect(
        classifyPasswordStrength('Ab1!', isValid: true),
        PasswordStrengthTier.weak,
      );
      expect(
        classifyPasswordStrength('a' * 20, isValid: false),
        PasswordStrengthTier.weak,
      );
      expect(
        classifyPasswordStrength('Strong1!', isValid: true),
        PasswordStrengthTier.medium,
      );
      expect(
        classifyPasswordStrength('VeryStrongPass1!', isValid: true),
        PasswordStrengthTier.strong,
      );
    });
  });

  group('resolveMaxAmountText', () {
    test('clamps below and above max, resets null, and is idempotent at max',
        () {
      expect(
        resolveMaxAmountText(
          maxBalance: BigInt.from(150000000),
          decimals: 8,
          currentAmount: null,
        ),
        '1.5',
      );
      expect(
        resolveMaxAmountText(
          maxBalance: BigInt.from(150000000),
          decimals: 8,
          currentAmount: BigInt.from(100000000),
        ),
        '1.5',
      );
      expect(
        resolveMaxAmountText(
          maxBalance: BigInt.from(150000000),
          decimals: 8,
          currentAmount: BigInt.from(999000000),
        ),
        '1.5',
      );
      expect(
        resolveMaxAmountText(
          maxBalance: BigInt.from(150000000),
          decimals: 8,
          currentAmount: BigInt.from(150000000),
        ),
        isNull,
      );
      expect(
        resolveMaxAmountText(
          maxBalance: BigInt.from(-5),
          decimals: 0,
          currentAmount: BigInt.one,
        ),
        '0',
      );
    });
  });

  group('evaluateTokenCapabilities', () {
    test('enforces ownership, mint supply cap, and burnability rules', () {
      final TokenCapabilities cappedOwner = evaluateTokenCapabilities(
        isMintable: true,
        isBurnable: false,
        totalSupply: BigInt.from(100),
        maxSupply: BigInt.from(100),
        isSelectedOwner: true,
        isWalletOwner: true,
      );
      expect(cappedOwner.showOwnBadge, isTrue);
      expect(cappedOwner.canTransferOwnership, isTrue);
      expect(cappedOwner.showMintButton, isFalse);
      expect(cappedOwner.canMint, isFalse);
      expect(cappedOwner.canBurn, isTrue);

      final TokenCapabilities walletNonSelected = evaluateTokenCapabilities(
        isMintable: true,
        isBurnable: false,
        totalSupply: BigInt.from(50),
        maxSupply: BigInt.from(100),
        isSelectedOwner: false,
        isWalletOwner: true,
      );
      expect(walletNonSelected.showOwnBadge, isTrue);
      expect(walletNonSelected.canTransferOwnership, isFalse);
      expect(walletNonSelected.showMintButton, isTrue);
      expect(walletNonSelected.canMint, isFalse);
      expect(walletNonSelected.canBurn, isFalse);
    });
  });

  group('computeAcceleratorVoteSummary', () {
    test('enforces strictly > 33% quorum, majority, and span conservation', () {
      final AcceleratorVoteSummary justBelow = computeAcceleratorVoteSummary(
        yes: 33,
        no: 0,
        total: 33,
        totalPillars: 100,
      );
      expect(justBelow.quorumNeeded, 34);
      expect(justBelow.votesToAchieveQuorum, 1);
      expect(justBelow.quorumReached, isFalse);
      expect(justBelow.hasMajority, isTrue);
      expect(
        justBelow.quorumFraction +
            justBelow.remainingQuorumFraction +
            justBelow.remainingPillarsFraction,
        lessThanOrEqualTo(1.0 + 1e-12),
      );

      final AcceleratorVoteSummary abstainHeavy = computeAcceleratorVoteSummary(
        yes: 10,
        no: 10,
        total: 40,
        totalPillars: 100,
      );
      expect(abstainHeavy.quorumReached, isTrue);
      expect(abstainHeavy.hasMajority, isFalse);

      final AcceleratorVoteSummary zeroPillars = computeAcceleratorVoteSummary(
        yes: 0,
        no: 0,
        total: 0,
        totalPillars: 0,
      );
      expect(zeroPillars.quorumNeeded, 0);
      expect(zeroPillars.quorumReached, isFalse);
      expect(zeroPillars.yesFraction, 0.0);
    });
  });

  group('computePillarQsrDepositSummary', () {
    test('preserves conservation and bounds across partial and over-deposited '
        'states', () {
      final PillarQsrDepositSummary partial = computePillarQsrDepositSummary(
        qsrBalance: BigInt.from(100),
        qsrCost: BigInt.from(150),
        qsrDeposit: BigInt.from(60),
      );
      expect(partial.remaining, BigInt.from(90));
      expect(partial.maxDeposit, BigInt.from(90));
      expect(partial.isCovered, isFalse);
      expect(partial.canWithdraw, isTrue);
      expect(partial.clampedDeposit + partial.remaining, BigInt.from(150));

      final PillarQsrDepositSummary covered = computePillarQsrDepositSummary(
        qsrBalance: BigInt.from(100),
        qsrCost: BigInt.from(150),
        qsrDeposit: BigInt.from(200),
      );
      expect(covered.remaining, BigInt.zero);
      expect(covered.maxDeposit, BigInt.zero);
      expect(covered.isCovered, isTrue);
      expect(covered.canWithdraw, isTrue);
      expect(covered.clampedDeposit, BigInt.from(150));
      expect(covered.depositedFraction, 1.0);
      expect(covered.remainingFraction, 0.0);
    });
  });

  group('HTLC window and expiration helpers', () {
    test('evaluates exact cutoff boundaries', () {
      const int cutoff = 100000;
      final int exp = cutoff + kDefaultMinSafeJoinSeconds;

      final HtlcWindowDecision before = evaluateHtlcJoinWindow(
        expirationTime: exp,
        unixTime: cutoff - 1,
      );
      expect(before.canSafelyJoin, isTrue);
      expect(before.minutesLeftToJoin, 1);

      final HtlcWindowDecision exact = evaluateHtlcJoinWindow(
        expirationTime: exp,
        unixTime: cutoff,
      );
      expect(exact.canSafelyJoin, isTrue);
      expect(exact.minutesLeftToJoin, 0);

      final HtlcWindowDecision after = evaluateHtlcJoinWindow(
        expirationTime: exp,
        unixTime: cutoff + 1,
      );
      expect(after.canSafelyJoin, isFalse);

      expect(evaluateHtlcExpiration(expirationTime: exp, unixTime: exp - 1),
          isFalse);
      expect(evaluateHtlcExpiration(expirationTime: exp, unixTime: exp),
          isTrue);
      expect(evaluateHtlcExpiration(expirationTime: exp, unixTime: exp + 1),
          isTrue);
    });
  });
}
