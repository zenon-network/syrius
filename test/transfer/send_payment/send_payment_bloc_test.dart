// //ignore_for_file: prefer_const_constructors
// import 'package:bloc_test/bloc_test.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/send_payment/send_payment_bloc.dart';
// import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
// import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
// import 'package:znn_sdk_dart/znn_sdk_dart.dart';
//
// //Cubit not testable: use of static methods interferes with testing
//
// class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}
//
// class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}
//
// class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}
//
// void main() {
//   late SendPaymentBloc sendPaymentBloc;
//   late MockAccountBlockUtils mockAccountBlockUtils;
//   late MockZenonAddressUtils mockZenonAddressUtils;
//
//   setUp(() {
//     mockAccountBlockUtils = MockAccountBlockUtils();
//     mockZenonAddressUtils = MockZenonAddressUtils();
//     sendPaymentBloc = SendPaymentBloc();
//   });
//
//   tearDown(() {
//     sendPaymentBloc.close();
//   });
//
//   group('SendPaymentBloc', () {
//     final String testToAddress = emptyAddress.toString();
//     final String testFromAddress = emptyAddress.toString();
//     const String testTokenStandard = znnTokenStandard;
//     const int testAmount = 1000;
//     const List<int> testData = [1, 2, 3];
//     final MockAccountBlockTemplate mockAccountBlockTemplate =
//         MockAccountBlockTemplate();
//     final Exception exception = Exception();
//
//     // blocTest<SendPaymentBloc, SendPaymentState>(
//     //   'emits [loading, success] when SendTransfer is successful',
//     //   setUp: () {
//     //     when(() => AccountBlockUtils.createAccountBlock(
//     //       any(),
//     //       any(),
//     //       any(),
//     //       any(),
//     //     )).thenAnswer((_) async => mockAccountBlockTemplate);
//     //     when(() => mockZenonAddressUtils.refreshBalance()).thenAnswer((_) async => {});
//     //   },
//     //   build: () => sendPaymentBloc,
//     //   act: (SendPaymentBloc bloc) => bloc.add(SendTransfer(
//     //     toAddress: testToAddress,
//     //     fromAddress: testFromAddress,
//     //     token: any(),
//     //     amount: BigInt.from(testAmount),
//     //     data: testData,
//     //   )),
//     //   expect: () => [
//     //     SendPaymentState(status: SendPaymentStatus.loading),
//     //     SendPaymentState(
//     //       status: SendPaymentStatus.success,
//     //       data: mockAccountBlockTemplate,
//     //     ),
//     //   ],
//     // );
//
//     // blocTest<SendPaymentBloc, SendPaymentState>(
//     //   'emits [loading, failure] when SendTransfer fails',
//     //   setUp: () {
//     //     when(() => mockAccountBlockUtils.createAccountBlock(
//     //       any(),
//     //       any(),
//     //       address: any(named: 'address'),
//     //       waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
//     //     )).thenThrow(exception);
//     //   },
//     //   build: () => sendPaymentBloc,
//     //   act: (bloc) => bloc.add(SendTransfer(
//     //     toAddress: testToAddress,
//     //     fromAddress: testFromAddress,
//     //     token: Token(testTokenStandard, 'Token', 'TKN', 2),
//     //     amount: testAmount,
//     //     data: testData,
//     //   )),
//     //   expect: () => [
//     //     SendPaymentState(status: SendPaymentStatus.loading),
//     //     SendPaymentState(
//     //       status: SendPaymentStatus.failure,
//     //       error: exception,
//     //     ),
//     //   ],
//     // );
//
//     blocTest<SendPaymentBloc, SendPaymentState>(
//       'emits [loading, success] when SendTransferWithBlock is successful',
//       setUp: () {
//         when(() => mockAccountBlockUtils.createAccountBlock(
//               any(),
//               any(),
//               address: any(named: 'address'),
//               waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
//             )).thenAnswer((_) async => mockAccountBlockTemplate);
//         when(() => mockZenonAddressUtils.refreshBalance())
//             .thenAnswer((_) async => {});
//       },
//       build: () => sendPaymentBloc,
//       act: (bloc) => bloc.add(SendTransferWithBlock(
//         block: mockAccountBlockTemplate,
//         fromAddress: testFromAddress,
//       )),
//       expect: () => [
//         SendPaymentState(status: SendPaymentStatus.loading),
//         SendPaymentState(
//           status: SendPaymentStatus.success,
//           data: mockAccountBlockTemplate,
//         ),
//       ],
//     );
//   });
// }
//
// //     blocTest<SendPaymentBloc, SendPaymentState>(
// //       'emits [loading, failure] when SendTransferWithBlock fails',
// //       setUp: () {
// //         when(() => mockAccountBlockUtils.createAccountBlock(
// //           any(),
// //           any(),
// //           address: any(named: 'address'),
// //           waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
// //         )).thenThrow(exception);
// //       },
// //       build: () => sendPaymentBloc,
// //       act: (bloc) => bloc.add(SendTransferWithBlock(
// //         block: mockAccountBlockTemplate,
// //         fromAddress: testFromAddress,
// //       )),
// //       expect: () => [
// //         SendPaymentState(status: SendPaymentStatus.loading),
// //         SendPaymentState(
// //           status: SendPaymentStatus.failure,
// //           error: exception,
// //         ),
// //       ],
// //     );
// //   });
// // }
