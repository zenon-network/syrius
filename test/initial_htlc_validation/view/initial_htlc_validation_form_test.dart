import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class MockInitialHtlcValidationBloc
    extends MockBloc<InitialHtlcValidationEvent, InitialHtlcValidationState>
    implements InitialHtlcValidationBloc {}

void main() {
  testWidgets('shows a validation failure', (WidgetTester tester) async {
    final MockInitialHtlcValidationBloc bloc = MockInitialHtlcValidationBloc();
    when(() => bloc.state).thenReturn(
      InitialHtlcValidationFailure(
        exception: SyriusException('Invalid deposit'),
      ),
    );

    await tester.pumpWidget(
      BlocProvider<InitialHtlcValidationBloc>.value(
        value: bloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: InitialHtlcValidationForm()),
        ),
      ),
    );

    expect(find.text('Invalid deposit'), findsOneWidget);
  });
}
