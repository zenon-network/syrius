import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/send_payment/send_payment_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

// TODO(maznnwell): Cubit not testable: the use of static constructors has to be wrapped in more general purpose classes which can be injected in the cubit.


class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  late SendPaymentBloc sendPaymentBloc;
  late MockAccountBlockUtils mockAccountBlockUtils;
  late MockZenonAddressUtils mockZenonAddressUtils;
  late String testToAddress;
  late String testFromAddress;
  late String testTokenStandard;
  late int testAmount;
  late List<int> testData;
  late MockAccountBlockTemplate mockAccountBlockTemplate;
  late Exception exception;

  setUp(() {
    mockAccountBlockUtils = MockAccountBlockUtils();
    mockZenonAddressUtils = MockZenonAddressUtils();
    sendPaymentBloc = SendPaymentBloc();
  });

  tearDown(() {
    sendPaymentBloc.close();
  });

  group('SendPaymentBloc', () {
    testToAddress = emptyAddress.toString();
    testFromAddress = emptyAddress.toString();
    testTokenStandard = znnTokenStandard;
    testAmount = 1000;
    testData = <int>[1, 2, 3];
    mockAccountBlockTemplate = MockAccountBlockTemplate();
    exception = Exception();

    blocTest<SendPaymentBloc, SendPaymentState>(
      'emits [loading, success] when SendTransfer is successful',
      setUp: () {
        when(
          () => AccountBlockUtils.createAccountBlock(
            any(),
            any(),
          ),
        ).thenAnswer((_) async => mockAccountBlockTemplate);
      },
      build: () => sendPaymentBloc,
      act: (SendPaymentBloc bloc) => bloc.add(SendTransfer(
        toAddress: testToAddress,
        fromAddress: testFromAddress,
        token: kZnnCoin,
        amount: BigInt.from(testAmount),
        data: testData,
      )),
      expect: () => <SendPaymentState>[
        const SendPaymentState(status: SendPaymentStatus.loading),
        SendPaymentState(
          status: SendPaymentStatus.success,
          data: mockAccountBlockTemplate,
        ),
      ],
    );

    blocTest<SendPaymentBloc, SendPaymentState>(
      'emits [loading, failure] when SendTransfer fails',
      setUp: () {
        when(() => AccountBlockUtils.createAccountBlock(
              any(),
              any(),
            ),).thenThrow(exception);
      },
      build: () => sendPaymentBloc,
      act: (SendPaymentBloc bloc) => bloc.add(SendTransfer(
        toAddress: testToAddress,
        fromAddress: testFromAddress,
        token: kZnnCoin,
        amount: BigInt.from(testAmount),
        data: testData,
      )),
      expect: () => [
        const SendPaymentState(status: SendPaymentStatus.loading),
        SendPaymentState(
          status: SendPaymentStatus.failure,
          error: exception,
        ),
      ],
    );
    //
    // blocTest<SendPaymentBloc, SendPaymentState>(
    //   'emits [loading, success] when SendTransferWithBlock is successful',
    //   setUp: () {
    //     when(() => mockAccountBlockUtils.createAccountBlock(
    //           any(),
    //           any(),
    //           address: any(named: 'address'),
    //           waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
    //         )).thenAnswer((_) async => mockAccountBlockTemplate);
    //     when(() => mockZenonAddressUtils.refreshBalance())
    //         .thenAnswer((_) async => {});
    //   },
    //   build: () => sendPaymentBloc,
    //   act: (bloc) => bloc.add(SendTransferWithBlock(
    //     block: mockAccountBlockTemplate,
    //     fromAddress: testFromAddress,
    //   )),
    //   expect: () => [
    //     SendPaymentState(status: SendPaymentStatus.loading),
    //     SendPaymentState(
    //       status: SendPaymentStatus.success,
    //       data: mockAccountBlockTemplate,
    //     ),
    //   ],
    // );
    //
    // blocTest<SendPaymentBloc, SendPaymentState>(
    //   'emits [loading, failure] when SendTransferWithBlock fails',
    //   setUp: () {
    //     when(() => mockAccountBlockUtils.createAccountBlock(
    //           any(),
    //           any(),
    //           address: any(named: 'address'),
    //           waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
    //         )).thenThrow(exception);
    //   },
    //   build: () => sendPaymentBloc,
    //   act: (bloc) => bloc.add(SendTransferWithBlock(
    //     block: mockAccountBlockTemplate,
    //     fromAddress: testFromAddress,
    //   )),
    //   expect: () => [
    //     SendPaymentState(status: SendPaymentStatus.loading),
    //     SendPaymentState(
    //       status: SendPaymentStatus.failure,
    //       error: exception,
    //     ),
    //   ],
    // );
  });
}
