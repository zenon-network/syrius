import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    final BigInt testAmount = BigInt.from(1000);
    final TokenStandard tokenStandard = znnZts;
    final AccountBlockTemplate accountBlockTemplate =
        AccountBlockTemplate(blockType: 1);
    registerFallbackValue(testAmount);
    registerFallbackValue(accountBlockTemplate);
    registerFallbackValue(tokenStandard);
    registerFallbackValue(FakeAddress());
  });

  late SendTransactionBloc sendTransactionBloc;
  late AccountBlockTemplate testAccBlockTemplate;
  late MockAccountBlockUtils mockAccountBlockUtils;
  late MockZenonAddressUtils mockZenonAddressUtils;
  late String testToAddress;
  late String testFromAddress;
  late int testAmount;
  late List<int> testData;
  late SyriusException exception;

  setUp(() {
    mockAccountBlockUtils = MockAccountBlockUtils();
    mockZenonAddressUtils = MockZenonAddressUtils();
    sendTransactionBloc = SendTransactionBloc(
      accountBlockUtilsHelper: mockAccountBlockUtils,
      zenonAddressUtils: mockZenonAddressUtils,
    );
    testToAddress = emptyAddress.toString();
    testFromAddress = emptyAddress.toString();
    testAmount = 1000;
    testData = <int>[1, 2, 3];
    testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
    exception = FailureException();

    when(
      () => mockAccountBlockUtils.createAccountBlock(
        any(),
        any(),
        address: any(named: 'address'),
        waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
      ),
    ).thenAnswer((_) async => testAccBlockTemplate);

    when(() => mockZenonAddressUtils.refreshBalance()).thenAnswer((_) {});
  });

  tearDown(() {
    sendTransactionBloc.close();
  });

  group('fromJson/toJson', () {
    test('can (de)serialize initial state', () {
      const SendTransactionState initialState = SendTransactionState();

      final Map<String, dynamic>? serialized = sendTransactionBloc.toJson(
        initialState,
      );
      final SendTransactionState? deserialized =
          sendTransactionBloc.fromJson(serialized!);

      expect(deserialized, equals(initialState));
    });

    test('can (de)serialize loading state', () {
      const SendTransactionState loadingState = SendTransactionState(
        status: SendTransactionStatus.loading,
      );

      final Map<String, dynamic>? serialized = sendTransactionBloc.toJson(
        loadingState,
      );
      final SendTransactionState? deserialized = sendTransactionBloc.fromJson(
        serialized!,
      );
      expect(deserialized, equals(loadingState));
    });

    test('can (de)serialize success state', () {
      final SendTransactionState successState = SendTransactionState(
        status: SendTransactionStatus.success,
        data: testAccBlockTemplate,
      );

      final Map<String, dynamic>? serialized = sendTransactionBloc.toJson(
        successState,
      );
      final SendTransactionState? deserialized = sendTransactionBloc.fromJson(
        serialized!,
      );
      expect(deserialized, isA<SendTransactionState>());
      expect(deserialized!.status, equals(SendTransactionStatus.success));
      expect(deserialized.data, isA<AccountBlockTemplate?>());
    });

    test('can (de)serialize failure state', () {
      final SendTransactionState failureState = SendTransactionState(
        status: SendTransactionStatus.failure,
        error: exception,
      );
      final Map<String, dynamic>? serialized = sendTransactionBloc.toJson(
        failureState,
      );
      final SendTransactionState? deserialized = sendTransactionBloc.fromJson(
        serialized!,
      );
      expect(deserialized, equals(failureState));
    });
  });

  group('SendTransactionBloc', () {
    blocTest<SendTransactionBloc, SendTransactionState>(
      'emits [loading, success] when SendTransfer is successful',
      build: () => sendTransactionBloc,
      act: (SendTransactionBloc bloc) => bloc.add(
        SendTransactionInitiate(
          toAddress: testToAddress,
          fromAddress: testFromAddress,
          token: kZnnCoin,
          amount: BigInt.from(testAmount),
          data: testData,
        ),
      ),
      expect: () => <SendTransactionState>[
        const SendTransactionState(status: SendTransactionStatus.loading),
        SendTransactionState(
          status: SendTransactionStatus.success,
          data: testAccBlockTemplate,
        ),
      ],
    );

    blocTest<SendTransactionBloc, SendTransactionState>(
      'emits [loading, failure] when SendTransfer fails',
      setUp: () {
        when(
          () => mockAccountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(exception);
      },
      build: () => sendTransactionBloc,
      act: (SendTransactionBloc bloc) => bloc.add(
        SendTransactionInitiate(
          toAddress: testToAddress,
          fromAddress: testFromAddress,
          token: kZnnCoin,
          amount: BigInt.from(testAmount),
          data: testData,
        ),
      ),
      expect: () => <SendTransactionState>[
        const SendTransactionState(status: SendTransactionStatus.loading),
        SendTransactionState(
          status: SendTransactionStatus.failure,
          error: exception,
        ),
      ],
    );

    blocTest<SendTransactionBloc, SendTransactionState>(
      'emits [loading, success] when SendTransferWithBlock is successful',
      build: () => sendTransactionBloc,
      act: (SendTransactionBloc bloc) => bloc.add(
        SendTransactionInitiateFromBlock(
          block: testAccBlockTemplate,
          fromAddress: testFromAddress,
        ),
      ),
      expect: () => <SendTransactionState>[
        const SendTransactionState(status: SendTransactionStatus.loading),
        SendTransactionState(
          status: SendTransactionStatus.success,
          data: testAccBlockTemplate,
        ),
      ],
    );

    blocTest<SendTransactionBloc, SendTransactionState>(
      'emits [loading, failure] when SendTransferWithBlock fails',
      setUp: () {
        when(
          () => mockAccountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(exception);
      },
      build: () => sendTransactionBloc,
      act: (SendTransactionBloc bloc) => bloc.add(
        SendTransactionInitiateFromBlock(
          block: testAccBlockTemplate,
          fromAddress: testFromAddress,
        ),
      ),
      expect: () => <SendTransactionState>[
        const SendTransactionState(status: SendTransactionStatus.loading),
        SendTransactionState(
          status: SendTransactionStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}