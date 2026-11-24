import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockInitialHtlcValidationBloc
    extends MockBloc<InitialHtlcValidationEvent, InitialHtlcValidationState>
    implements InitialHtlcValidationBloc {}

void main() {
  testWidgets('dispatches validation to the provided bloc', (
    WidgetTester tester,
  ) async {
    final Hash depositId = Hash.digest(<int>[1, 2, 3]);
    final MockInitialHtlcValidationBloc bloc = MockInitialHtlcValidationBloc();
    when(
      () => bloc.state,
    ).thenReturn(const InitialHtlcValidationInitial());

    await tester.pumpWidget(
      BlocProvider<InitialHtlcValidationBloc>.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InitialHtlcValidationButton(
              depositId: depositId.toString(),
              isEnabled: true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => bloc.add(InitialHtlcValidationRequested(id: depositId)),
    ).called(1);
  });
}
