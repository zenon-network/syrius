import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/multiple_balance/multiple_balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/loading_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockMultipleBalanceBloc
    extends MockBloc<MultipleBalanceEvent, MultipleBalanceState>
    implements MultipleBalanceBloc {}

class _MockSubmitDonationBloc
    extends MockBloc<SubmitDonationEvent, SubmitDonationState>
    implements SubmitDonationBloc {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

class _MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

AccountInfo _accountInfo({
  required String address,
  required BigInt znn,
  required BigInt qsr,
}) {
  return AccountInfo.fromJson(<String, dynamic>{
    'address': address,
    'accountHeight': 1,
    'balanceInfoMap': <String, dynamic>{
      znnZts.toString(): <String, dynamic>{
        'token': <String, dynamic>{
          'name': 'Zenon',
          'symbol': 'ZNN',
          'domain': 'zenon.network',
          'totalSupply': '0',
          'decimals': coinDecimals,
          'owner': emptyAddress.toString(),
          'tokenStandard': znnZts.toString(),
          'maxSupply': '0',
          'isBurnable': true,
          'isMintable': true,
          'isUtility': true,
        },
        'balance': znn.toString(),
      },
      qsrZts.toString(): <String, dynamic>{
        'token': <String, dynamic>{
          'name': 'Quasar',
          'symbol': 'QSR',
          'domain': 'zenon.network',
          'totalSupply': '0',
          'decimals': coinDecimals,
          'owner': emptyAddress.toString(),
          'tokenStandard': qsrZts.toString(),
          'maxSupply': '0',
          'isBurnable': true,
          'isMintable': true,
          'isUtility': true,
        },
        'balance': qsr.toString(),
      },
    },
  });
}

void main() {
  final Address donorAddress = Address.fromPublicKey(List<int>.filled(32, 9));

  setUpAll(() {
    registerFallbackValue(const MultipleBalanceFetch(addresses: <String>[]));
    registerFallbackValue(
      SubmitDonationRequested(
        address: emptyAddress,
        znnAmount: BigInt.zero,
        qsrAmount: BigInt.zero,
      ),
    );
  });

  group('AcceleratorDonationStepperView', () {
    late _MockMultipleBalanceBloc multipleBalanceBloc;
    late _MockSubmitDonationBloc submitDonationBloc;
    late _MockNotificationsBloc notificationsBloc;
    late String? previousSelectedAddress;
    late List<String?> previousDefaultAddressList;

    setUp(() async {
      previousSelectedAddress = kSelectedAddress;
      previousDefaultAddressList = List<String?>.from(kDefaultAddressList);

      kSelectedAddress = donorAddress.toString();
      kDefaultAddressList = <String?>[donorAddress.toString()];

      multipleBalanceBloc = _MockMultipleBalanceBloc();
      submitDonationBloc = _MockSubmitDonationBloc();
      notificationsBloc = _MockNotificationsBloc();

      when(
        () => notificationsBloc.addErrorNotification(any(), any()),
      ).thenAnswer((_) async {});

      if (sl.isRegistered<NotificationsBloc>()) {
        await sl.unregister<NotificationsBloc>();
      }
      sl.registerSingleton<NotificationsBloc>(notificationsBloc);
    });

    tearDown(() async {
      kSelectedAddress = previousSelectedAddress;
      kDefaultAddressList = previousDefaultAddressList;
      if (sl.isRegistered<NotificationsBloc>()) {
        await sl.unregister<NotificationsBloc>();
      }
      await multipleBalanceBloc.close();
      await submitDonationBloc.close();
    });

    Future<void> pumpStepper(
      WidgetTester tester, {
      VoidCallback? onDonationSubmitted,
    }) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MultiBlocProvider(
              providers: <SingleChildWidget>[
                BlocProvider<MultipleBalanceBloc>.value(
                  value: multipleBalanceBloc,
                ),
                BlocProvider<SubmitDonationBloc>.value(
                  value: submitDonationBloc,
                ),
              ],
              child: AcceleratorDonationStepperView(
                onDonationSubmitted: onDonationSubmitted,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'shows error widget when selected address is missing from loaded '
      'balances',
      (WidgetTester tester) async {
        when(() => multipleBalanceBloc.state).thenReturn(
          const MultipleBalanceState(
            status: MultipleBalanceStatus.success,
            data: <String, AccountInfo>{},
          ),
        );
        when(
          () => submitDonationBloc.state,
        ).thenReturn(const SubmitDonationInitial());

        await pumpStepper(tester);

        expect(find.byType(SyriusErrorWidget), findsOneWidget);
        expect(
          find.textContaining('Balance is unavailable for the selected'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'partial ZNN failure refreshes balance and retries only remaining QSR',
      (WidgetTester tester) async {
        final AccountInfo accountInfo = _accountInfo(
          address: donorAddress.toString(),
          znn: BigInt.from(100 * oneZnn),
          qsr: BigInt.from(200 * oneQsr),
        );
        final StreamController<SubmitDonationState> submitStates =
            StreamController<SubmitDonationState>.broadcast();
        addTearDown(submitStates.close);

        when(() => multipleBalanceBloc.state).thenReturn(
          MultipleBalanceState(
            status: MultipleBalanceStatus.success,
            data: <String, AccountInfo>{donorAddress.toString(): accountInfo},
          ),
        );
        whenListen<SubmitDonationState>(
          submitDonationBloc,
          submitStates.stream,
          initialState: const SubmitDonationInitial(),
        );

        int onSubmittedCount = 0;
        await pumpStepper(
          tester,
          onDonationSubmitted: () {
            onSubmittedCount += 1;
          },
        );

        // Step 1 -> Step 2 (Continue)
        await tester.tap(find.text('Continue').first);
        await tester.pumpAndSettle();

        // Enter ZNN and QSR amounts.
        final Finder textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), '10');
        await tester.enterText(textFields.at(1), '25');
        await tester.pumpAndSettle();

        // Step 2 -> Step 3 (Continue)
        final Finder step2Continue = find.text('Continue').at(1);
        await tester.ensureVisible(step2Continue);
        await tester.tap(step2Continue);
        await tester.pumpAndSettle();

        // First submit attempt dispatches both ZNN and QSR.
        final Finder submitButton = find.byType(LoadingButton);
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        verify(
          () => submitDonationBloc.add(
            SubmitDonationRequested(
              address: donorAddress,
              znnAmount: BigInt.from(10 * oneZnn),
              qsrAmount: BigInt.from(25 * oneQsr),
            ),
          ),
        ).called(1);

        // Simulate partial failure where ZNN block succeeded before QSR failed.
        submitStates.add(
          SubmitDonationFailure(
            exception: FailureException(),
            sentBlocks: <AccountBlockTemplate>[_MockAccountBlockTemplate()],
            znnSubmitted: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(onSubmittedCount, 1);

        // Retrying Submit must ONLY dispatch the remaining QSR amount and NOT
        // re-donate ZNN.
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        verify(
          () => submitDonationBloc.add(
            SubmitDonationRequested(
              address: donorAddress,
              znnAmount: BigInt.zero,
              qsrAmount: BigInt.from(25 * oneQsr),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'keeps SubmitDonationBloc listener mounted while MultipleBalanceBloc '
      'reloads so partial ZNN failure is never missed',
      (WidgetTester tester) async {
        final AccountInfo accountInfo = _accountInfo(
          address: donorAddress.toString(),
          znn: BigInt.from(100 * oneZnn),
          qsr: BigInt.from(200 * oneQsr),
        );
        final MultipleBalanceState loadedState = MultipleBalanceState(
          status: MultipleBalanceStatus.success,
          data: <String, AccountInfo>{donorAddress.toString(): accountInfo},
        );
        final StreamController<MultipleBalanceState> balanceStates =
            StreamController<MultipleBalanceState>.broadcast();
        final StreamController<SubmitDonationState> submitStates =
            StreamController<SubmitDonationState>.broadcast();
        addTearDown(balanceStates.close);
        addTearDown(submitStates.close);

        whenListen<MultipleBalanceState>(
          multipleBalanceBloc,
          balanceStates.stream,
          initialState: loadedState,
        );
        whenListen<SubmitDonationState>(
          submitDonationBloc,
          submitStates.stream,
          initialState: const SubmitDonationInitial(),
        );

        int onSubmittedCount = 0;
        await pumpStepper(
          tester,
          onDonationSubmitted: () {
            onSubmittedCount += 1;
          },
        );

        // Step 1 -> Step 2 (Continue)
        await tester.tap(find.text('Continue').first);
        await tester.pumpAndSettle();

        // Enter ZNN and QSR amounts.
        final Finder textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), '10');
        await tester.enterText(textFields.at(1), '25');
        await tester.pumpAndSettle();

        // Step 2 -> Step 3 (Continue)
        final Finder step2Continue = find.text('Continue').at(1);
        await tester.ensureVisible(step2Continue);
        await tester.tap(step2Continue);
        await tester.pumpAndSettle();

        // Trigger submission.
        final Finder submitButton = find.byType(LoadingButton);
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        // Balance reload replaces stepper body with loading indicator while
        // submission is still in flight.
        balanceStates.add(
          const MultipleBalanceState(status: MultipleBalanceStatus.loading),
        );
        await tester.pump();

        // Partial failure arrives while balances are loading.
        submitStates.add(
          SubmitDonationFailure(
            exception: FailureException(),
            sentBlocks: <AccountBlockTemplate>[_MockAccountBlockTemplate()],
            znnSubmitted: true,
          ),
        );
        await tester.pump();

        expect(onSubmittedCount, 1);

        // Balances finish loading and stepper remounts; retry must send ONLY
        // the remaining QSR amount (znnAmount == 0).
        balanceStates.add(loadedState);
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        verify(
          () => submitDonationBloc.add(
            SubmitDonationRequested(
              address: donorAddress,
              znnAmount: BigInt.zero,
              qsrAmount: BigInt.from(25 * oneQsr),
            ),
          ),
        ).called(1);
      },
    );
  });
}
