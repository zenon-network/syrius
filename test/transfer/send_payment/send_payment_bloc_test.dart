import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/send_payment/send_payment_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_template_send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/zenon_address_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenonAddressUtils extends Mock implements ZenonAddressUtilsHelper {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtilsHelper {}

class FakeAddress extends Fake implements Address {}

class MockAccountBlockTemplateSend extends Mock
    implements AccountBlockTemplateSend {}

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

  late SendPaymentBloc sendPaymentBloc;
  late AccountBlockTemplate testAccBlockTemplate;
  late MockAccountBlockUtils mockAccountBlockUtils;
  late MockZenonAddressUtils mockZenonAddressUtils;
  late MockAccountBlockTemplateSend mockAccountBlockTemplateSend;
  late String testToAddress;
  late String testFromAddress;
  late int testAmount;
  late List<int> testData;
  late Exception exception;

  setUp(() {
    mockAccountBlockUtils = MockAccountBlockUtils();
    mockZenonAddressUtils = MockZenonAddressUtils();
    mockAccountBlockTemplateSend = MockAccountBlockTemplateSend();
    sendPaymentBloc = SendPaymentBloc(
      mockAccountBlockUtils,
      mockZenonAddressUtils,
      mockAccountBlockTemplateSend,
    );
    testToAddress = emptyAddress.toString();
    testFromAddress = emptyAddress.toString();
    testAmount = 1000;
    testData = <int>[1, 2, 3];
    testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
    exception = CubitFailureException();

    when(
      () => mockAccountBlockUtils.createAccountBlock(
        any(),
        any(),
        address: any(named: 'address'),
        waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
      ),
    ).thenAnswer((_) async => testAccBlockTemplate);

    when(
      () => mockAccountBlockTemplateSend.createSendBlock(
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenReturn(testAccBlockTemplate);

    when(() => mockZenonAddressUtils.refreshBalance()).thenAnswer((_) async {});
  });

  tearDown(() {
    sendPaymentBloc.close();
  });

  group('fromJson/toJson', () {
    test('can (de)serialize initial state', () {
      const SendPaymentState initialState = SendPaymentState();

      final Map<String, dynamic>? serialized = sendPaymentBloc.toJson(
        initialState,
      );
      final SendPaymentState? deserialized =
      sendPaymentBloc.fromJson(serialized!);

      expect(deserialized, equals(initialState));
    });

    test('can (de)serialize loading state', () {
      const SendPaymentState loadingState = SendPaymentState(
        status: SendPaymentStatus.loading,
      );

      final Map<String, dynamic>? serialized = sendPaymentBloc.toJson(
        loadingState,
      );
      final SendPaymentState? deserialized =
      sendPaymentBloc.fromJson(
        serialized!,
      );
      expect(deserialized, equals(loadingState));
    });

    test('can (de)serialize success state', () {
      final SendPaymentState successState = SendPaymentState(
        status: SendPaymentStatus.success,
        data: testAccBlockTemplate,
      );

      final Map<String, dynamic>? serialized = sendPaymentBloc.toJson(
        successState,
      );
      final SendPaymentState? deserialized =
      sendPaymentBloc.fromJson(
        serialized!,
      );
      expect(deserialized, isA<SendPaymentState>());
      expect(deserialized!.status, equals(SendPaymentStatus.success));
      expect(deserialized.data, isA<AccountBlockTemplate?>());
    });

    test('can (de)serialize failure state', () {
      final SendPaymentState failureState = SendPaymentState(
        status: SendPaymentStatus.failure,
        error: exception,
      );
      final Map<String, dynamic>? serialized = sendPaymentBloc.toJson(
        failureState,
      );
      final SendPaymentState? deserialized =
      sendPaymentBloc.fromJson(
        serialized!,
      );
      expect(deserialized, equals(failureState));
    });
  });

      group('SendPaymentBloc', () {
    blocTest<SendPaymentBloc, SendPaymentState>(
      'emits [loading, success] when SendTransfer is successful',
      build: () => sendPaymentBloc,
      act: (SendPaymentBloc bloc) => bloc.add(
        SendTransfer(
          toAddress: testToAddress,
          fromAddress: testFromAddress,
          token: kZnnCoin,
          amount: BigInt.from(testAmount),
          data: testData,
        ),
      ),
      expect: () => <SendPaymentState>[
        const SendPaymentState(status: SendPaymentStatus.loading),
        SendPaymentState(
          status: SendPaymentStatus.success,
          data: testAccBlockTemplate,
        ),
      ],
    );

    blocTest<SendPaymentBloc, SendPaymentState>(
      'emits [loading, failure] when SendTransfer fails',
      setUp: () {
        when(
          () => mockAccountBlockTemplateSend.createSendBlock(
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenThrow(exception);
      },
      build: () => sendPaymentBloc,
      act: (SendPaymentBloc bloc) => bloc.add(SendTransfer(
        toAddress: testToAddress,
        fromAddress: testFromAddress,
        token: kZnnCoin,
        amount: BigInt.from(testAmount),
        data: testData,
      ),),
      expect: () => <SendPaymentState>[
        const SendPaymentState(status: SendPaymentStatus.loading),
        SendPaymentState(
          status: SendPaymentStatus.failure,
          error: exception,
        ),
      ],
    );

    blocTest<SendPaymentBloc, SendPaymentState>(
      'emits [loading, success] when SendTransferWithBlock is successful',
      build: () => sendPaymentBloc,
      act: (SendPaymentBloc bloc) => bloc.add(
        SendTransferWithBlock(
          block: testAccBlockTemplate,
          fromAddress: testFromAddress,
        ),
      ),
      expect: () => <SendPaymentState>[
        const SendPaymentState(status: SendPaymentStatus.loading),
        SendPaymentState(
          status: SendPaymentStatus.success,
          data: testAccBlockTemplate,
        ),
      ],
    );

    blocTest<SendPaymentBloc, SendPaymentState>(
      'emits [loading, failure] when SendTransferWithBlock fails',
      setUp: () {
        when(() => mockAccountBlockUtils.createAccountBlock(
              any(),
              any(),
              address: any(named: 'address'),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),).thenThrow(exception);
      },
      build: () => sendPaymentBloc,
      act: (SendPaymentBloc bloc) => bloc.add(SendTransferWithBlock(
        block: testAccBlockTemplate,
        fromAddress: testFromAddress,
      ),),
      expect: () => <SendPaymentState>[
        const SendPaymentState(status: SendPaymentStatus.loading),
        SendPaymentState(
          status: SendPaymentStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
