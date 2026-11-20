import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/tab_children_widgets/accelerator_tab_child.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

Map<String, dynamic> _pillarJson(String name, Address owner, Address producer) =>
    {
      'name': name,
      'rank': 1,
      'type': PillarInfo.regularPillarType,
      'ownerAddress': owner.toString(),
      'producerAddress': producer.toString(),
      'withdrawAddress': owner.toString(),
      'giveMomentumRewardPercentage': 0,
      'giveDelegateRewardPercentage': 100,
      'isRevocable': false,
      'revokeCooldown': 0,
      'revokeTimestamp': 0,
      'currentStats': {'producedMomentums': 0, 'expectedMomentums': 0},
      'weight': '0',
    };

Widget _harness(AsyncSnapshot<PillarInfo?> snapshot) {
  return MaterialApp(
    home: Scaffold(
      body: acceleratorTabBody(
        snapshot,
        (pillarInfo) => Text('layout:${pillarInfo?.name ?? 'none'}'),
      ),
    ),
  );
}

void main() {
  testWidgets('a finished lookup with no pillar shows the layout, not the spinner',
      (tester) async {
    // Regression: the future completes with null for an address that has
    // no pillar role, and snapshot.hasData is false there, so branching on
    // hasData kept ordinary accounts on the loading widget forever.
    await tester.pumpWidget(
      _harness(const AsyncSnapshot.withData(ConnectionState.done, null)),
    );

    expect(find.byType(SyriusLoadingWidget), findsNothing);
    expect(find.text('layout:none'), findsOneWidget);
  });

  testWidgets('a finished lookup with a pillar passes it to the layout',
      (tester) async {
    final pillar = PillarInfo.fromJson(
      _pillarJson('test-pillar', _address(1), _address(2)),
    );
    await tester.pumpWidget(
      _harness(AsyncSnapshot.withData(ConnectionState.done, pillar)),
    );

    expect(find.text('layout:test-pillar'), findsOneWidget);
  });

  testWidgets('a lookup still in flight shows the loading widget',
      (tester) async {
    await tester.pumpWidget(_harness(const AsyncSnapshot.nothing()));

    expect(find.byType(SyriusLoadingWidget), findsOneWidget);
  });

  testWidgets('a failed lookup shows the error widget', (tester) async {
    await tester.pumpWidget(
      _harness(AsyncSnapshot.withError(ConnectionState.done, 'node offline')),
    );

    expect(find.byType(SyriusErrorWidget), findsOneWidget);
    expect(find.textContaining('node offline'), findsOneWidget);
  });
}
