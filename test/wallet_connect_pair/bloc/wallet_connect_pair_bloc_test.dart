import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/wallet_connect_camera/wallet_connect_camera.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/wallet_connect_pair/wallet_connect_pair.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';

class _MockWeb3WalletService extends Mock implements IWeb3WalletService {}

PairingInfo _buildPairing(String topic) {
  return PairingInfo(
    topic: topic,
    expiry: 1700000000,
    relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
    active: false,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Uri.parse('wc:fallback@2?relay-protocol=irn&symKey=1'),
    );
  });

  group('WalletConnectPairBloc', () {
    const String validWcUri =
        'wc:1234abcd@2?relay-protocol=irn&symKey=abcdef0123456789';

    late _MockWeb3WalletService web3WalletService;
    late PairingInfo createdPairing;

    WalletConnectPairBloc buildBloc() =>
        WalletConnectPairBloc(web3WalletService: web3WalletService);

    setUp(() {
      web3WalletService = _MockWeb3WalletService();
      createdPairing = _buildPairing('1234abcd');
      when(
        () => web3WalletService.pair(any()),
      ).thenAnswer((_) async => createdPairing);
    });

    test('initial state is WalletConnectPairStatus.initial', () {
      final WalletConnectPairBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const WalletConnectPairState());
    });

    blocTest<WalletConnectPairBloc, WalletConnectPairState>(
      'pairs with a valid direct WalletConnect v2 URI',
      build: buildBloc,
      act: (WalletConnectPairBloc bloc) {
        bloc.add(const WalletConnectPairRequested(rawUri: validWcUri));
      },
      verify: (_) {
        verify(() => web3WalletService.pair(Uri.parse(validWcUri))).called(1);
      },
      expect: () => <WalletConnectPairState>[
        const WalletConnectPairState(status: WalletConnectPairStatus.loading),
        WalletConnectPairState(
          status: WalletConnectPairStatus.success,
          pairingInfo: createdPairing,
          successCount: 1,
        ),
      ],
    );

    blocTest<WalletConnectPairBloc, WalletConnectPairState>(
      'extracts WalletConnect URI from syrius://wc wrapper link before pairing',
      build: buildBloc,
      act: (WalletConnectPairBloc bloc) {
        final String encoded = Uri.encodeComponent(validWcUri);
        bloc.add(
          WalletConnectPairRequested(
            rawUri: 'syrius://wc/?uri=$encoded',
            isWindows: true,
          ),
        );
      },
      verify: (_) {
        verify(() => web3WalletService.pair(Uri.parse(validWcUri))).called(1);
      },
      expect: () => <WalletConnectPairState>[
        const WalletConnectPairState(status: WalletConnectPairStatus.loading),
        WalletConnectPairState(
          status: WalletConnectPairStatus.success,
          pairingInfo: createdPairing,
          successCount: 1,
        ),
      ],
    );

    blocTest<WalletConnectPairBloc, WalletConnectPairState>(
      'emits failure without calling service when URI is invalid',
      build: buildBloc,
      act: (WalletConnectPairBloc bloc) {
        bloc.add(
          const WalletConnectPairRequested(rawUri: 'https://example.invalid'),
        );
      },
      verify: (_) {
        verifyNever(() => web3WalletService.pair(any()));
      },
      expect: () => <Matcher>[
        isA<WalletConnectPairState>()
            .having(
              (WalletConnectPairState s) => s.status,
              'status',
              WalletConnectPairStatus.failure,
            )
            .having(
              (WalletConnectPairState s) => s.error,
              'error',
              isA<FormatException>(),
            )
            .having(
              (WalletConnectPairState s) => s.errorCount,
              'errorCount',
              1,
            ),
      ],
    );

    blocTest<WalletConnectPairBloc, WalletConnectPairState>(
      'emits failure and increments errorCount when service.pair throws',
      setUp: () {
        when(
          () => web3WalletService.pair(any()),
        ).thenThrow(StateError('relay offline'));
      },
      build: buildBloc,
      act: (WalletConnectPairBloc bloc) {
        bloc.add(const WalletConnectPairRequested(rawUri: validWcUri));
      },
      errors: () => <Matcher>[isA<StateError>()],
      expect: () => <Object>[
        const WalletConnectPairState(status: WalletConnectPairStatus.loading),
        isA<WalletConnectPairState>()
            .having(
              (WalletConnectPairState s) => s.status,
              'status',
              WalletConnectPairStatus.failure,
            )
            .having(
              (WalletConnectPairState s) => s.error,
              'error',
              isA<StateError>(),
            )
            .having(
              (WalletConnectPairState s) => s.errorCount,
              'errorCount',
              1,
            ),
      ],
    );

    blocTest<WalletConnectPairBloc, WalletConnectPairState>(
      'ignores duplicate pairing requests while already loading',
      setUp: () {
        final Completer<PairingInfo> completer = Completer<PairingInfo>();
        when(
          () => web3WalletService.pair(any()),
        ).thenAnswer((_) => completer.future);
      },
      build: buildBloc,
      act: (WalletConnectPairBloc bloc) {
        bloc
          ..add(const WalletConnectPairRequested(rawUri: validWcUri))
          ..add(const WalletConnectPairRequested(rawUri: validWcUri));
      },
      verify: (_) {
        verify(() => web3WalletService.pair(any())).called(1);
      },
      expect: () => <WalletConnectPairState>[
        const WalletConnectPairState(status: WalletConnectPairStatus.loading),
      ],
    );
  });

  group('extractWalletConnectUriFromBarcodes', () {
    const String validWcUri =
        'wc:5678efgh@2?relay-protocol=irn&symKey=fedcba9876543210';

    test('skips null and invalid barcodes and returns first valid WC URI', () {
      final String? extracted = extractWalletConnectUriFromBarcodes(<String?>[
        null,
        'https://example.invalid',
        'wc:missing-params@2',
        validWcUri,
      ]);

      expect(extracted, validWcUri);
    });

    test('returns null when no barcode contains a valid WC v2 URI', () {
      final String? extracted = extractWalletConnectUriFromBarcodes(<String?>[
        null,
        'not-a-wc-uri',
        'wc:legacy@1?relay-protocol=irn&symKey=abc',
      ]);

      expect(extracted, isNull);
    });
  });
}
