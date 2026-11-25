import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  group('PowGeneratingStatusBloc', () {
    test('initial state is idle (PowStatus.done)', () {
      final PowGeneratingStatusBloc bloc = PowGeneratingStatusBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const PowGeneratingStatusState());
      expect(bloc.state.isGenerating, isFalse);
    });

    blocTest<PowGeneratingStatusBloc, PowGeneratingStatusState>(
      'emits generating and done states on status changes',
      build: PowGeneratingStatusBloc.new,
      act: (PowGeneratingStatusBloc bloc) => bloc
        ..add(const PowGeneratingStatusChanged(PowStatus.generating))
        ..add(const PowGeneratingStatusChanged(PowStatus.done)),
      expect: () => const <PowGeneratingStatusState>[
        PowGeneratingStatusState(status: PowStatus.generating),
        PowGeneratingStatusState(),
      ],
    );
  });

  group('PowGeneratingStatusIcon', () {
    testWidgets(
      'renders idle bolt icon and switches to Lottie when generating',
      (WidgetTester tester) async {
        final PowGeneratingStatusBloc bloc = PowGeneratingStatusBloc();
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PowGeneratingStatusIcon(bloc: bloc)),
          ),
        );

        expect(
          find.byIcon(MaterialCommunityIcons.lightning_bolt),
          findsOneWidget,
        );
        expect(find.byTooltip('Plasma generation idle'), findsOneWidget);

        bloc.add(const PowGeneratingStatusChanged(PowStatus.generating));
        await tester.pump();

        expect(find.byType(Lottie), findsOneWidget);
        expect(find.byTooltip('Generating Plasma'), findsOneWidget);
      },
    );
  });
}
