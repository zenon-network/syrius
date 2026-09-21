import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockMultipleBalanceBloc
    extends MockBloc<MultipleBalanceEvent, MultipleBalanceState>
    implements MultipleBalanceBloc {}

void main() {
  const String owner = 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d';
  const String holder = 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e';

  late Directory hiveDirectory;
  late MockMultipleBalanceBloc multipleBalanceBloc;

  setUpAll(() async {
    hiveDirectory = Directory.systemTemp.createTempSync(
      'syrius_token_card_test_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox<dynamic>(kFavoriteTokensBox);
  });

  setUp(() {
    multipleBalanceBloc = MockMultipleBalanceBloc();
    when(
      () => multipleBalanceBloc.state,
    ).thenReturn(const MultipleBalanceState());
    kSelectedAddress = holder;
    kDefaultAddressList = <String?>[holder];
    kAddressLabelMap = <String, String>{holder: 'Holder'};
  });

  tearDown(() {
    kSelectedAddress = null;
    kDefaultAddressList = <String?>[];
    kAddressLabelMap = <String, String>{};
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('allows a non-owner to burn a publicly burnable token', (
    WidgetTester tester,
  ) async {
    await _pumpTokenCard(
      tester,
      multipleBalanceBloc,
      _buildToken(owner: owner, isBurnable: true),
    );

    final Finder burnButton = find.byKey(const Key('token_burn_button'));
    expect(burnButton, findsOneWidget);
    expect(tester.widget<IconButton>(burnButton).onPressed, isNotNull);
  });

  testWidgets('allows the owner to burn an owner-only token', (
    WidgetTester tester,
  ) async {
    kSelectedAddress = owner;
    kDefaultAddressList = <String?>[owner];
    kAddressLabelMap = <String, String>{owner: 'Owner'};

    await _pumpTokenCard(
      tester,
      multipleBalanceBloc,
      _buildToken(owner: owner, isBurnable: false),
    );

    final Finder burnButton = find.byKey(const Key('token_burn_button'));
    expect(burnButton, findsOneWidget);
    expect(tester.widget<IconButton>(burnButton).onPressed, isNotNull);
  });

  testWidgets('hides owner-only burn from the selected non-owner', (
    WidgetTester tester,
  ) async {
    kDefaultAddressList = <String?>[holder, owner];
    kAddressLabelMap = <String, String>{
      holder: 'Holder',
      owner: 'Owner',
    };

    await _pumpTokenCard(
      tester,
      multipleBalanceBloc,
      _buildToken(owner: owner, isBurnable: false),
    );

    expect(find.byKey(const Key('token_burn_button')), findsNothing);
  });
}

Token _buildToken({required String owner, required bool isBurnable}) => Token(
  'Test Token',
  'TST',
  'zenon.org',
  BigInt.from(85),
  0,
  Address.parse(owner),
  znnZts,
  BigInt.from(100),
  isBurnable,
  false,
  true,
);

Future<void> _pumpTokenCard(
  WidgetTester tester,
  MultipleBalanceBloc multipleBalanceBloc,
  Token token,
) async {
  await tester.pumpWidget(
    BlocProvider<MultipleBalanceBloc>.value(
      value: multipleBalanceBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 500,
            child: TokenCard(token: token, favoritesCallback: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
