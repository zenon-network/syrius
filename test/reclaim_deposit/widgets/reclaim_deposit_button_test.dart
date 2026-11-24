import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockReclaimDepositBloc
    extends MockBloc<ReclaimDepositEvent, ReclaimDepositState>
    implements ReclaimDepositBloc {}

void main() {
  testWidgets('dispatches a reclaim request to the provided bloc', (
    WidgetTester tester,
  ) async {
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final MockReclaimDepositBloc bloc = MockReclaimDepositBloc();
    when(() => bloc.state).thenReturn(const ReclaimDepositInitial());

    await tester.pumpWidget(
      BlocProvider<ReclaimDepositBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(
            body: ReclaimDepositButton(
              depositId: htlcId.toString(),
              isEnabled: true,
              text: 'Reclaim',
              loadingText: 'Reclaiming',
              successMessage: 'Reclaim submitted',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => bloc.add(ReclaimDepositRequested(depositId: htlcId)),
    ).called(1);
  });
}
