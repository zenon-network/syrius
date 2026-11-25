import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _RecordingBlocObserver extends BlocObserver {
  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

class _FakeWalletAccount implements WalletAccount {
  _FakeWalletAccount(this._address);

  final Address _address;

  @override
  Future<Address> getAddress() async => _address;

  @override
  Future<List<int>> getPublicKey() => throw UnimplementedError();

  @override
  Future<List<int>> sign(List<int> message) => throw UnimplementedError();

  @override
  Future<List<int>> signTx(AccountBlockTemplate tx) =>
      throw UnimplementedError();
}

class _FakeWallet implements Wallet {
  _FakeWallet(this._addresses);

  final List<Address> _addresses;

  @override
  Future<WalletAccount> getAccount([int accountIndex = 0]) async {
    if (accountIndex < _addresses.length) {
      return _FakeWalletAccount(_addresses[accountIndex]);
    }
    return _FakeWalletAccount(emptyAddress);
  }
}

class _InMemoryWalletFile extends WalletFile {
  _InMemoryWalletFile(this._wallet, {this._isHardwareWallet = false})
    : super('in-memory');

  final Wallet _wallet;
  final bool _isHardwareWallet;
  int accessCalls = 0;

  @override
  String get walletType => _isHardwareWallet ? 'ledger' : keyStoreWalletType;

  @override
  bool get isOpen => false;

  @override
  bool get isHardwareWallet => _isHardwareWallet;

  @override
  Future<Wallet> open() async => _wallet;

  @override
  void close() {}

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) {
    accessCalls++;
    return super.access(accessSection);
  }
}

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

void main() {
  group('ReclaimDepositBloc', () {
    const int now = 1000;
    const String testMnemonic =
        'route become dream access impulse price inform obtain engage ski '
        'believe awful absent pig thing vibrant possible exotic flee pepper '
        'marble rural fire fancy';

    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final Address selfAddress = emptyAddress;
    final Address otherAddress = htlcAddress;

    late KeyStore sharedKeyStore;
    late List<Address> derivedAddresses;
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late AccountBlockTemplate transactionParams;
    late HtlcInfo htlc;
    late List<String?> walletAddresses;
    late WalletFile? walletFile;
    late List<int> generatedCounts;
    late ReclaimDepositBloc bloc;

    setUpAll(() async {
      sharedKeyStore = KeyStore.fromMnemonic(testMnemonic);
      final List<Address?> derived = await sharedKeyStore
          .deriveAddressesByRange(0, 10);
      derivedAddresses = derived.whereType<Address>().toList();
    });

    HtlcInfo buildHtlc({
      required Address timeLocked,
      required int expirationTime,
    }) => HtlcInfo(
      id: htlcId,
      timeLocked: timeLocked,
      hashLocked: otherAddress,
      tokenStandard: kZnnCoin.tokenStandard,
      amount: BigInt.one,
      expirationTime: expirationTime,
      hashType: htlcHashTypeSha3,
      keyMaxSize: htlcPreimageMaxLength,
      hashLock: <int>[4, 5, 6],
    );

    ReclaimDepositBloc createBloc({
      WalletAddressGenerator? generateAddresses,
      int addressLookaheadLimit = kReclaimAddressLookaheadLimit,
    }) => ReclaimDepositBloc(
      accountBlockUtils: accountBlockUtils,
      walletAddressesProvider: () => walletAddresses,
      walletFileProvider: () => walletFile,
      generateAddresses:
          generateAddresses ??
          (int count) async {
            generatedCounts.add(count);
          },
      addressLookaheadLimit: addressLookaheadLimit,
      zenon: zenon,
      zenonAddressUtils: zenonAddressUtils,
      unixTimeProvider: () => now,
    );

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      transactionParams = AccountBlockTemplate(blockType: 1);
      htlc = buildHtlc(timeLocked: selfAddress, expirationTime: now);
      walletAddresses = <String?>[selfAddress.toString()];
      walletFile = null;
      generatedCounts = <int>[];

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(() => htlcApi.getById(htlcId)).thenAnswer((_) async => htlc);
      when(() => htlcApi.reclaim(htlcId)).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'reclaim deposit',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => transactionParams);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = createBloc();
    });

    test('initial state is correct', () {
      expect(bloc.state, const ReclaimDepositInitial());
    });

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'submits the reclaim transaction and refreshes balances',
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <ReclaimDepositState>[
        const ReclaimDepositLoading(),
        ReclaimDepositDone(block: transactionParams),
      ],
      verify: (_) {
        verify(() => htlcApi.getById(htlcId)).called(1);
        verify(() => htlcApi.reclaim(htlcId)).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'reclaim deposit',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'reads wallet addresses dynamically when an address is added after '
      'bloc creation',
      setUp: () {
        walletAddresses = <String?>[otherAddress.toString()];
        bloc = createBloc();
        walletAddresses.add(selfAddress.toString());
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <ReclaimDepositState>[
        const ReclaimDepositLoading(),
        ReclaimDepositDone(block: transactionParams),
      ],
      verify: (_) {
        expect(generatedCounts, isEmpty);
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'rejects a deposit that does not belong to the wallet',
      setUp: () {
        htlc = buildHtlc(timeLocked: otherAddress, expirationTime: now);
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <Matcher>[
        isA<ReclaimDepositLoading>(),
        isA<ReclaimDepositFailure>().having(
          (ReclaimDepositFailure state) => state.exception.message,
          'message',
          'The deposit does not belong to you.',
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'rejects a deposit that is still locked',
      setUp: () {
        htlc = buildHtlc(timeLocked: selfAddress, expirationTime: now + 1);
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () {
        final String expectedDate = FormatUtils.formatDate(
          (now + 1) * Duration.millisecondsPerSecond,
          dateFormat: kDefaultDateTimeFormat,
        );
        return <Matcher>[
          isA<ReclaimDepositLoading>(),
          isA<ReclaimDepositFailure>().having(
            (ReclaimDepositFailure state) => state.exception.message,
            'message',
            'The deposit is locked until $expectedDate.',
          ),
        ];
      },
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    test('discovers and generates missing addresses when deposit belongs to a '
        'higher-index derived address after wallet reset', () async {
      final Address tenthAddress = derivedAddresses[9];

      walletAddresses = <String?>[
        for (final Address address in derivedAddresses.sublist(0, 3))
          address.toString(),
      ];
      final _InMemoryWalletFile inMemoryWallet = _InMemoryWalletFile(
        sharedKeyStore,
      );
      walletFile = inMemoryWallet;
      htlc = buildHtlc(timeLocked: tenthAddress, expirationTime: now);

      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'reclaim deposit',
          address: tenthAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => transactionParams);

      final ReclaimDepositBloc derivedBloc = createBloc(
        generateAddresses: (int count) async {
          generatedCounts.add(count);
          final int start = walletAddresses.length;
          walletAddresses.addAll(
            derivedAddresses
                .sublist(start, start + count)
                .map((Address address) => address.toString()),
          );
        },
      );
      addTearDown(derivedBloc.close);

      final Future<void> expectation = expectLater(
        derivedBloc.stream,
        emitsInOrder(<ReclaimDepositState>[
          const ReclaimDepositLoading(),
          ReclaimDepositDone(block: transactionParams),
        ]),
      );

      derivedBloc.add(ReclaimDepositRequested(depositId: htlcId));
      await expectation;

      expect(inMemoryWallet.accessCalls, 1);
      expect(generatedCounts, <int>[7]);
      expect(walletAddresses, hasLength(10));
      expect(walletAddresses[9], tenthAddress.toString());
      verify(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'reclaim deposit',
          address: tenthAddress,
          waitForRequiredPlasma: true,
        ),
      ).called(1);
      verify(() => zenonAddressUtils.refreshBalance()).called(1);
    });

    test('does not generate missing addresses when a higher-index deposit is '
        'still locked', () async {
      final Address tenthAddress = derivedAddresses[9];

      walletAddresses = <String?>[
        for (final Address address in derivedAddresses.sublist(0, 3))
          address.toString(),
      ];
      walletFile = _InMemoryWalletFile(_FakeWallet(derivedAddresses));
      htlc = buildHtlc(timeLocked: tenthAddress, expirationTime: now + 60);

      final ReclaimDepositBloc derivedBloc = createBloc();
      addTearDown(derivedBloc.close);

      final String expectedDate = FormatUtils.formatDate(
        (now + 60) * Duration.millisecondsPerSecond,
        dateFormat: kDefaultDateTimeFormat,
      );

      final Future<void> expectation = expectLater(
        derivedBloc.stream,
        emitsInOrder(<Matcher>[
          isA<ReclaimDepositLoading>(),
          isA<ReclaimDepositFailure>().having(
            (ReclaimDepositFailure state) => state.exception.message,
            'message',
            'The deposit is locked until $expectedDate.',
          ),
        ]),
      );

      derivedBloc.add(ReclaimDepositRequested(depositId: htlcId));
      await expectation;

      expect(generatedCounts, isEmpty);
      expect(walletAddresses, hasLength(3));
      verifyNever(() => htlcApi.reclaim(htlcId));
    });

    test('fails cleanly when generating missing addresses does not add the '
        'deposit address', () async {
      final Address sixthAddress = derivedAddresses[5];

      walletAddresses = <String?>[
        for (final Address address in derivedAddresses.sublist(0, 3))
          address.toString(),
      ];
      walletFile = _InMemoryWalletFile(_FakeWallet(derivedAddresses));
      htlc = buildHtlc(timeLocked: sixthAddress, expirationTime: now);

      final ReclaimDepositBloc derivedBloc = createBloc(
        generateAddresses: (int count) async {
          generatedCounts.add(count);
        },
      );
      addTearDown(derivedBloc.close);

      final Future<void> expectation = expectLater(
        derivedBloc.stream,
        emitsInOrder(<Matcher>[
          isA<ReclaimDepositLoading>(),
          isA<ReclaimDepositFailure>().having(
            (ReclaimDepositFailure state) => state.exception.message,
            'message',
            contains('Unable to add the deposit address'),
          ),
        ]),
      );

      derivedBloc.add(ReclaimDepositRequested(depositId: htlcId));
      await expectation;

      expect(generatedCounts, <int>[3]);
      verifyNever(() => htlcApi.reclaim(htlcId));
      verifyNever(() => zenonAddressUtils.refreshBalance());
    });

    test('rejects a deposit beyond addressLookaheadLimit without generating '
        'addresses', () async {
      final Address tenthAddress = derivedAddresses[9];

      walletAddresses = <String?>[
        for (final Address address in derivedAddresses.sublist(0, 3))
          address.toString(),
      ];
      walletFile = _InMemoryWalletFile(_FakeWallet(derivedAddresses));
      htlc = buildHtlc(timeLocked: tenthAddress, expirationTime: now);

      final ReclaimDepositBloc derivedBloc = createBloc(
        addressLookaheadLimit: 5,
      );
      addTearDown(derivedBloc.close);

      final Future<void> expectation = expectLater(
        derivedBloc.stream,
        emitsInOrder(<Matcher>[
          isA<ReclaimDepositLoading>(),
          isA<ReclaimDepositFailure>().having(
            (ReclaimDepositFailure state) => state.exception.message,
            'message',
            'The deposit does not belong to you.',
          ),
        ]),
      );

      derivedBloc.add(ReclaimDepositRequested(depositId: htlcId));
      await expectation;

      expect(generatedCounts, isEmpty);
      verifyNever(() => htlcApi.reclaim(htlcId));
    });

    test(
      'does not scan a hardware wallet when deposit address is missing',
      () async {
        final _InMemoryWalletFile hardwareWallet = _InMemoryWalletFile(
          _FakeWallet(derivedAddresses),
          isHardwareWallet: true,
        );
        walletFile = hardwareWallet;
        htlc = buildHtlc(timeLocked: otherAddress, expirationTime: now);

        final ReclaimDepositBloc hwBloc = createBloc();
        addTearDown(hwBloc.close);

        final Future<void> expectation = expectLater(
          hwBloc.stream,
          emitsInOrder(<Matcher>[
            isA<ReclaimDepositLoading>(),
            isA<ReclaimDepositFailure>().having(
              (ReclaimDepositFailure state) => state.exception.message,
              'message',
              contains('generate additional addresses in Settings'),
            ),
          ]),
        );

        hwBloc.add(ReclaimDepositRequested(depositId: htlcId));
        await expectation;

        expect(hardwareWallet.accessCalls, 0);
        expect(generatedCounts, isEmpty);
        verifyNever(() => htlcApi.reclaim(htlcId));
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'preserves a SyriusException from transaction submission',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'reclaim deposit',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(SyriusException('Unable to reclaim deposit.'));
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <Matcher>[
        isA<ReclaimDepositLoading>(),
        isA<ReclaimDepositFailure>().having(
          (ReclaimDepositFailure state) => state.exception.message,
          'message',
          'Unable to reclaim deposit.',
        ),
      ],
      verify: (_) {
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'converts an unexpected error to FailureException',
      setUp: () {
        when(() => htlcApi.getById(htlcId)).thenThrow(StateError('boom'));
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <Matcher>[
        isA<ReclaimDepositLoading>(),
        isA<ReclaimDepositFailure>().having(
          (ReclaimDepositFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    test(
      'sanitizes unexpected reclaim errors before reporting to BlocObserver',
      () async {
        const String sensitiveDetail = 'sensitive-reclaim-detail';
        final BlocObserver previousObserver = Bloc.observer;
        final _RecordingBlocObserver observer = _RecordingBlocObserver();
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        when(
          () => htlcApi.getById(htlcId),
        ).thenThrow(StateError(sensitiveDetail));

        final ReclaimDepositBloc observedBloc = createBloc()
          ..add(ReclaimDepositRequested(depositId: htlcId));
        addTearDown(observedBloc.close);

        await expectLater(
          observedBloc.stream,
          emitsThrough(isA<ReclaimDepositFailure>()),
        );

        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
        expect(observer.errors.single.toString(), 'StateError');
        expect(
          observer.errors.single.toString(),
          isNot(contains(sensitiveDetail)),
        );
      },
    );
  });
}
