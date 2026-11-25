import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class _MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(BigInt.zero);
    registerFallbackValue(znnZts);
  });

  group('SubmitDonationBloc', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockAcceleratorApi acceleratorApi;
    late _MockAccountBlockUtils accountBlockUtils;
    late _MockZenonAddressUtils zenonAddressUtils;
    late _MockAccountBlockTemplate znnTemplate;
    late _MockAccountBlockTemplate qsrTemplate;
    late _MockAccountBlockTemplate znnResponse;
    late _MockAccountBlockTemplate qsrResponse;
    final Address donorAddress = Address.fromPublicKey(List<int>.filled(32, 7));

    setUp(() {
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      acceleratorApi = _MockAcceleratorApi();
      accountBlockUtils = _MockAccountBlockUtils();
      zenonAddressUtils = _MockZenonAddressUtils();
      znnTemplate = _MockAccountBlockTemplate();
      qsrTemplate = _MockAccountBlockTemplate();
      znnResponse = _MockAccountBlockTemplate();
      qsrResponse = _MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.accelerator).thenReturn(acceleratorApi);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});
    });

    test('initial state is SubmitDonationInitial', () async {
      final SubmitDonationBloc bloc = SubmitDonationBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
      expect(bloc.state, const SubmitDonationInitial());
      await bloc.close();
    });

    blocTest<SubmitDonationBloc, SubmitDonationState>(
      'submits ZNN-only donation with pinned address',
      setUp: () {
        when(
          () => acceleratorApi.donate(BigInt.from(50), kZnnCoin.tokenStandard),
        ).thenReturn(znnTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            znnTemplate,
            'donate for accelerator',
            address: donorAddress,
          ),
        ).thenAnswer((_) async => znnResponse);
      },
      build: () => SubmitDonationBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      ),
      act: (SubmitDonationBloc bloc) => bloc.add(
        SubmitDonationRequested(
          address: donorAddress,
          znnAmount: BigInt.from(50),
          qsrAmount: BigInt.zero,
        ),
      ),
      expect: () => <SubmitDonationState>[
        const SubmitDonationLoading(),
        SubmitDonationDone(blocks: <AccountBlockTemplate>[znnResponse]),
      ],
      verify: (_) {
        verify(
          () => acceleratorApi.donate(BigInt.from(50), kZnnCoin.tokenStandard),
        ).called(1);
        verifyNever(() => acceleratorApi.donate(any(), kQsrCoin.tokenStandard));
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SubmitDonationBloc, SubmitDonationState>(
      'submits QSR-only donation with pinned address',
      setUp: () {
        when(
          () => acceleratorApi.donate(BigInt.from(25), kQsrCoin.tokenStandard),
        ).thenReturn(qsrTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            qsrTemplate,
            'donate for accelerator',
            address: donorAddress,
          ),
        ).thenAnswer((_) async => qsrResponse);
      },
      build: () => SubmitDonationBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      ),
      act: (SubmitDonationBloc bloc) => bloc.add(
        SubmitDonationRequested(
          address: donorAddress,
          znnAmount: BigInt.zero,
          qsrAmount: BigInt.from(25),
        ),
      ),
      expect: () => <SubmitDonationState>[
        const SubmitDonationLoading(),
        SubmitDonationDone(blocks: <AccountBlockTemplate>[qsrResponse]),
      ],
      verify: (_) {
        verifyNever(() => acceleratorApi.donate(any(), kZnnCoin.tokenStandard));
        verify(
          () => acceleratorApi.donate(BigInt.from(25), kQsrCoin.tokenStandard),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SubmitDonationBloc, SubmitDonationState>(
      'submits both ZNN and QSR donations and emits done once after both '
      'finish',
      setUp: () {
        when(
          () => acceleratorApi.donate(BigInt.from(10), kZnnCoin.tokenStandard),
        ).thenReturn(znnTemplate);
        when(
          () => acceleratorApi.donate(BigInt.from(20), kQsrCoin.tokenStandard),
        ).thenReturn(qsrTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            znnTemplate,
            'donate for accelerator',
            address: donorAddress,
          ),
        ).thenAnswer((_) async => znnResponse);
        when(
          () => accountBlockUtils.createAccountBlock(
            qsrTemplate,
            'donate for accelerator',
            address: donorAddress,
          ),
        ).thenAnswer((_) async => qsrResponse);
      },
      build: () => SubmitDonationBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      ),
      act: (SubmitDonationBloc bloc) => bloc.add(
        SubmitDonationRequested(
          address: donorAddress,
          znnAmount: BigInt.from(10),
          qsrAmount: BigInt.from(20),
        ),
      ),
      expect: () => <SubmitDonationState>[
        const SubmitDonationLoading(),
        SubmitDonationDone(
          blocks: <AccountBlockTemplate>[znnResponse, qsrResponse],
        ),
      ],
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SubmitDonationBloc, SubmitDonationState>(
      'emits failure when both donation amounts are zero',
      build: () => SubmitDonationBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      ),
      act: (SubmitDonationBloc bloc) => bloc.add(
        SubmitDonationRequested(
          address: donorAddress,
          znnAmount: BigInt.zero,
          qsrAmount: BigInt.zero,
        ),
      ),
      expect: () => <Matcher>[isA<SubmitDonationFailure>()],
      verify: (_) {
        verifyNever(() => acceleratorApi.donate(any(), any()));
      },
    );

    blocTest<SubmitDonationBloc, SubmitDonationState>(
      'refreshes balance if ZNN succeeded before QSR threw',
      setUp: () {
        when(
          () => acceleratorApi.donate(BigInt.from(10), kZnnCoin.tokenStandard),
        ).thenReturn(znnTemplate);
        when(
          () => acceleratorApi.donate(BigInt.from(20), kQsrCoin.tokenStandard),
        ).thenReturn(qsrTemplate);
        when(
          () => accountBlockUtils.createAccountBlock(
            znnTemplate,
            'donate for accelerator',
            address: donorAddress,
          ),
        ).thenAnswer((_) async => znnResponse);
        when(
          () => accountBlockUtils.createAccountBlock(
            qsrTemplate,
            'donate for accelerator',
            address: donorAddress,
          ),
        ).thenThrow(Exception('qsr failed'));
      },
      build: () => SubmitDonationBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      ),
      act: (SubmitDonationBloc bloc) => bloc.add(
        SubmitDonationRequested(
          address: donorAddress,
          znnAmount: BigInt.from(10),
          qsrAmount: BigInt.from(20),
        ),
      ),
      expect: () => <Matcher>[
        isA<SubmitDonationLoading>(),
        isA<SubmitDonationFailure>().having(
          (SubmitDonationFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );
  });
}
