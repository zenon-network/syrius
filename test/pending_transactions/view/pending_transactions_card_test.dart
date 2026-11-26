import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pending_transactions/pending_transactions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class _MockPendingTransactionsBloc
    extends MockBloc<InfiniteListEvent, InfiniteListState<AccountBlock>>
    implements PendingTransactionsBloc {}

class _MockZenon extends Mock implements Zenon {}

class _MockWsClient extends Mock implements WsClient {}

class _MockLedger extends Mock implements LedgerApi {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _FakeAddress extends Fake implements Address {}

AccountBlock _buildPendingBlock(int seed) {
  final String hashHex = seed.toRadixString(16).padLeft(64, '0');
  return AccountBlock.fromJson(<String, dynamic>{
    'descendantBlocks': const <AccountBlock>[],
    'basePlasma': 1000,
    'usedPlasma': 500,
    'changesHash': emptyHash.toString(),
    'confirmationDetail': <String, dynamic>{
      'numConfirmations': 12,
      'momentumHeight': 1000 + seed,
      'momentumHash': emptyHash.toString(),
      'momentumTimestamp': 1700000000 + seed,
    },
    'version': 1,
    'chainIdentifier': 1,
    'blockType': 2,
    'hash': hashHex,
    'previousHash': emptyHash.toString(),
    'height': seed,
    'momentumAcknowledged': <String, dynamic>{
      'hash': emptyHash.toString(),
      'height': 999 + seed,
    },
    'address': emptyAddress.toString(),
    'toAddress': emptyAddress.toString(),
    'amount': '${seed}00000000',
    'tokenStandard': znnTokenStandard,
    'fromBlockHash': emptyHash.toString(),
    'data': null,
    'fusedPlasma': 0,
    'difficulty': 0,
    'nonce': '1',
    'publicKey': null,
    'signature': null,
    'token': kZnnCoin.toJson(),
    'pairedAccountBlock': null,
  });
}

void main() {
  initHydratedStorage();

  const String selectedAddressStr =
      'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
  final Address selectedAddress = Address.parse(selectedAddressStr);

  setUpAll(() {
    registerFallbackValue(_FakeAddress());
    registerFallbackValue(const InfiniteListRequested());
  });

  group('PendingTransactionsCard pagination', () {
    late String? previousSelectedAddress;
    late SharedPrefsService? previousSharedPrefsService;
    late _MockSharedPrefsService mockSharedPrefsService;

    setUp(() {
      previousSelectedAddress = kSelectedAddress;
      previousSharedPrefsService = app.sharedPrefsService;
      mockSharedPrefsService = _MockSharedPrefsService();
      when(
        () => mockSharedPrefsService.get(
          any<String>(),
          defaultValue: any<dynamic>(named: 'defaultValue'),
        ),
      ).thenReturn(false);
      app.sharedPrefsService = mockSharedPrefsService;
      kSelectedAddress = selectedAddressStr;
    });

    tearDown(() {
      kSelectedAddress = previousSelectedAddress;
      app.sharedPrefsService = previousSharedPrefsService;
    });

    Future<void> pumpCard(
      WidgetTester tester,
      PendingTransactionsBloc bloc,
    ) async {
      tester.view.physicalSize = const Size(1400, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BlocProvider<PendingTransactionsBloc>.value(
          value: bloc,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 360,
                child: PendingTransactionsCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'dispatches InfiniteListMoreRequested (not InfiniteListRequested) when '
      'scrolled to bottom',
      (WidgetTester tester) async {
        final _MockPendingTransactionsBloc mockBloc =
            _MockPendingTransactionsBloc();
        final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
        addTearDown(isLoading.dispose);

        final List<AccountBlock> items = List<AccountBlock>.generate(
          20,
          (int i) => _buildPendingBlock(i + 1),
        );

        when(() => mockBloc.isLoadingListenable).thenReturn(isLoading);
        when(() => mockBloc.state).thenReturn(
          InfiniteListState<AccountBlock>(
            status: InfiniteListStatus.success,
            data: items,
          ),
        );
        whenListen<InfiniteListState<AccountBlock>>(
          mockBloc,
          const Stream<InfiniteListState<AccountBlock>>.empty(),
          initialState: InfiniteListState<AccountBlock>(
            status: InfiniteListStatus.success,
            data: items,
          ),
        );

        await pumpCard(tester, mockBloc);

        // Scroll past the 90% threshold to reach the bottom of the table.
        final Finder scrollView = find.byType(CustomScrollView);
        await tester.drag(scrollView, const Offset(0, -3000));
        await tester.pump();

        verify(
          () => mockBloc.add(
            InfiniteListMoreRequested(address: selectedAddress),
          ),
        ).called(1);
        verifyNever(
          () => mockBloc.add(
            any(that: isA<InfiniteListRequested>()),
          ),
        );
      },
    );

    testWidgets(
      'paginates page 1 and appends items when scrolling to bottom with real '
      'PendingTransactionsBloc',
      (WidgetTester tester) async {
        const int pageSize = 15;
        final _MockZenon mockZenon = _MockZenon();
        final _MockWsClient mockWsClient = _MockWsClient();
        final _MockLedger mockLedger = _MockLedger();

        final List<AccountBlock> page0 = List<AccountBlock>.generate(
          pageSize,
          (int i) => _buildPendingBlock(i + 1),
        );
        final List<AccountBlock> page1 = <AccountBlock>[
          _buildPendingBlock(101),
          _buildPendingBlock(102),
        ];

        when(() => mockZenon.wsClient).thenReturn(mockWsClient);
        when(() => mockZenon.ledger).thenReturn(mockLedger);
        when(
          () => mockWsClient.restartedStream,
        ).thenAnswer((_) => const Stream<bool>.empty());
        when(
          () => mockLedger.getUnreceivedBlocksByAddress(
            any(),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final int pageIndex = invocation.namedArguments[#pageIndex]! as int;
          if (pageIndex == 0) {
            return AccountBlockList(
              count: page0.length + page1.length,
              list: page0,
              more: true,
            );
          }
          return AccountBlockList(
            count: page0.length + page1.length,
            list: page1,
            more: false,
          );
        });

        final PendingTransactionsBloc bloc = PendingTransactionsBloc(
          zenon: mockZenon,
          pageSize: pageSize,
        );
        try {
          bloc.add(InfiniteListRequested(address: selectedAddress));
          await pumpCard(tester, bloc);
          await tester.pump(const Duration(milliseconds: 150));

          expect(bloc.state.data, hasLength(pageSize));
          expect(bloc.state.hasReachedMax, isFalse);

          final Finder scrollView = find.byType(CustomScrollView);
          await tester.drag(scrollView, const Offset(0, -3000));
          await tester.pump(const Duration(milliseconds: 150));
          await tester.pump();

          verify(
            () => mockLedger.getUnreceivedBlocksByAddress(
              selectedAddress,
              pageSize: pageSize,
            ),
          ).called(1);
          verify(
            () => mockLedger.getUnreceivedBlocksByAddress(
              selectedAddress,
              pageIndex: 1,
              pageSize: pageSize,
            ),
          ).called(1);
          expect(bloc.state.data, hasLength(pageSize + page1.length));
          expect(bloc.state.hasReachedMax, isTrue);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          unawaited(bloc.close());
          await tester.pump(const Duration(milliseconds: 200));
        }
      },
    );
  });
}
