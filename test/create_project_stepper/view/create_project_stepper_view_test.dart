import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_project_stepper/create_project_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/multiple_balance/multiple_balance.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/loading_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockMultipleBalanceBloc
    extends MockBloc<MultipleBalanceEvent, MultipleBalanceState>
    implements MultipleBalanceBloc {}

class _MockCreateProjectBloc
    extends MockBloc<CreateProjectEvent, CreateProjectState>
    implements CreateProjectBloc {}

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
  final Address ownerAddress = Address.fromPublicKey(List<int>.filled(32, 11));

  setUpAll(() {
    registerFallbackValue(const MultipleBalanceFetch(addresses: <String>[]));
    registerFallbackValue(
      CreateProjectRequested(
        address: emptyAddress,
        name: '',
        description: '',
        url: '',
        znnFundsNeeded: BigInt.zero,
        qsrFundsNeeded: BigInt.zero,
      ),
    );
  });

  group('CreateProjectStepperView', () {
    late _MockMultipleBalanceBloc multipleBalanceBloc;
    late _MockCreateProjectBloc createProjectBloc;
    late String? previousSelectedAddress;
    late List<String?> previousDefaultAddressList;

    setUp(() {
      previousSelectedAddress = kSelectedAddress;
      previousDefaultAddressList = List<String?>.from(kDefaultAddressList);

      kSelectedAddress = ownerAddress.toString();
      kDefaultAddressList = <String?>[ownerAddress.toString()];

      multipleBalanceBloc = _MockMultipleBalanceBloc();
      createProjectBloc = _MockCreateProjectBloc();
    });

    tearDown(() async {
      kSelectedAddress = previousSelectedAddress;
      kDefaultAddressList = previousDefaultAddressList;
      await multipleBalanceBloc.close();
      await createProjectBloc.close();
    });

    testWidgets(
      'keeps CreateProjectBloc listener mounted while MultipleBalanceBloc '
      'reloads so completion is never missed',
      (WidgetTester tester) async {
        final AccountInfo accountInfo = _accountInfo(
          address: ownerAddress.toString(),
          znn: BigInt.from(100 * oneZnn),
          qsr: BigInt.from(100 * oneQsr),
        );
        final MultipleBalanceState loadedState = MultipleBalanceState(
          status: MultipleBalanceStatus.success,
          data: <String, AccountInfo>{ownerAddress.toString(): accountInfo},
        );
        final StreamController<MultipleBalanceState> balanceStates =
            StreamController<MultipleBalanceState>.broadcast();
        final StreamController<CreateProjectState> projectStates =
            StreamController<CreateProjectState>.broadcast();
        addTearDown(balanceStates.close);
        addTearDown(projectStates.close);

        whenListen<MultipleBalanceState>(
          multipleBalanceBloc,
          balanceStates.stream,
          initialState: loadedState,
        );
        whenListen<CreateProjectState>(
          createProjectBloc,
          projectStates.stream,
          initialState: const CreateProjectInitial(),
        );

        int onCreatedCount = 0;
        tester.view.physicalSize = const Size(1400, 1200);
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
                  BlocProvider<CreateProjectBloc>.value(
                    value: createProjectBloc,
                  ),
                ],
                child: CreateProjectStepperView(
                  onProjectCreated: () {
                    onCreatedCount += 1;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Step 1 -> Step 2 (Continue)
        await tester.tap(find.text('Continue').first);
        await tester.pumpAndSettle();

        // Fill project details (name, description, URL, ZNN, QSR).
        final Finder fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Hyperion');
        await tester.enterText(fields.at(1), 'Upgrade Accelerator UX');
        await tester.enterText(fields.at(2), 'zenon.network');
        await tester.enterText(fields.at(3), '100');
        await tester.enterText(fields.at(4), '1000');
        await tester.pumpAndSettle();

        // Step 2 -> Step 3 (Continue)
        final Finder step2Continue = find.text('Continue').at(1);
        await tester.ensureVisible(step2Continue);
        await tester.tap(step2Continue);
        await tester.pumpAndSettle();

        // Submit project.
        final Finder submitButton = find.byType(LoadingButton);
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        verify(
          () => createProjectBloc.add(
            CreateProjectRequested(
              address: ownerAddress,
              name: 'Hyperion',
              description: 'Upgrade Accelerator UX',
              url: 'zenon.network',
              znnFundsNeeded: BigInt.from(100 * oneZnn),
              qsrFundsNeeded: BigInt.from(1000 * oneQsr),
            ),
          ),
        ).called(1);

        // Balance reload replaces stepper body with loading indicator while
        // project creation finishes.
        balanceStates.add(
          const MultipleBalanceState(status: MultipleBalanceStatus.loading),
        );
        await tester.pump();

        projectStates.add(
          CreateProjectDone(accountBlock: _MockAccountBlockTemplate()),
        );
        await tester.pump();

        expect(onCreatedCount, 1);

        // Once balances return, the stepper must show the completed controls
        // rather than leaving the user on an incomplete Submit step.
        balanceStates.add(loadedState);
        await tester.pump();

        expect(find.text('Create another project'), findsOneWidget);
        expect(find.text('View projects'), findsOneWidget);
      },
    );
  });
}
