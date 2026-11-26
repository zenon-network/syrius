import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout/layout.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockKeyStoreWalletFile extends Mock implements KeyStoreWalletFile {}

class _MockLedgerWalletFile extends Mock implements LedgerWalletFile {}

class _MockWalletManager extends Mock implements WalletManager {}

class _MockLedgerWallet extends Mock implements LedgerWallet {}

class _MockLedgerWalletAccount extends Mock implements LedgerWalletAccount {}

class _FakeWalletDefinition extends Fake implements WalletDefinition {
  _FakeWalletDefinition({required this.walletId, required this.walletName});

  @override
  final String walletId;

  @override
  final String walletName;
}

Widget _buildDesktopApp(Widget home) {
  return Layout(
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void _configureDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 950);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      _FakeWalletDefinition(walletId: 'fallback', walletName: 'Fallback'),
    );
  });

  group('AccessWalletScreen', () {
    testWidgets('renders localized header and all three wallet options', (
      WidgetTester tester,
    ) async {
      _configureDesktopViewport(tester);

      await tester.pumpWidget(_buildDesktopApp(const AccessWalletScreen()));

      expect(find.text('Welcome'), findsOneWidget);
      expect(
        find.text('Select an option to access your wallet'),
        findsOneWidget,
      );
      expect(find.text('Create wallet'), findsOneWidget);
      expect(find.text('Import wallet'), findsOneWidget);
      expect(find.text('Hardware wallet'), findsOneWidget);
    });
  });

  group('ImportWalletSeedChoiceScreen & ImportWalletDecryptScreen', () {
    testWidgets(
      'accepts dropped extensionless keystore file and navigates to decrypt',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        await tester.pumpWidget(
          _buildDesktopApp(
            ImportWalletSeedChoiceScreen(clearAddressesBox: () async {}),
          ),
        );

        expect(find.text('Import your wallet'), findsOneWidget);

        // Continue button starts disabled.
        final OnboardingButton initialContinue = tester
            .widgetList<OnboardingButton>(find.byType(OnboardingButton))
            .last;
        expect(initialContinue.onPressed, isNull);

        // Drop an extensionless keystore file (Issue #136 / PR #154).
        final DropTarget dropTarget = tester.widget<DropTarget>(
          find.byType(DropTarget),
        );
        dropTarget.onDragDone!(
          DropDoneDetails(
            files: <DropItem>[DropItemFile('/home/user/znn_keystore')],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();

        expect(find.text('/home/user/znn_keystore'), findsOneWidget);
        final OnboardingButton enabledContinue = tester
            .widgetList<OnboardingButton>(find.byType(OnboardingButton))
            .last;
        expect(enabledContinue.onPressed, isNotNull);

        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.byType(ImportWalletDecryptScreen), findsOneWidget);
        expect(find.text('Unlock your Seed Vault'), findsOneWidget);
      },
    );

    testWidgets(
      'shows localized Incorrect password error on IncorrectPasswordException',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final DecryptWalletFileBloc bloc = DecryptWalletFileBloc(
          decryptWalletFile: (_, _) =>
              Future<WalletFile>.error(IncorrectPasswordException()),
        );

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              ImportWalletDecryptScreen('/tmp/wallet', decryptBloc: bloc),
            ),
          );

          await tester.enterText(find.byType(TextFormField), 'bad-pass');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Incorrect password'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'shows localized oversized file error when file exceeds keystore size '
      'limit',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final Directory tempDir = Directory.systemTemp.createTempSync(
          'onboarding_oversized_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        final File oversized = File('${tempDir.path}/huge.json')
          ..writeAsStringSync('x' * (WalletFile.maxWalletFileSizeBytes + 1));

        final DecryptWalletFileBloc bloc = DecryptWalletFileBloc();

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              ImportWalletDecryptScreen(oversized.path, decryptBloc: bloc),
            ),
          );

          await tester.enterText(find.byType(TextFormField), 'pass');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(
            find.text('Wallet file is too large to be a valid keystore file'),
            findsOneWidget,
          );
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'shows localized missing file error when wallet file does not exist',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final Directory tempDir = Directory.systemTemp.createTempSync(
          'onboarding_missing_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        final String missingPath = '${tempDir.path}/does_not_exist.json';

        final DecryptWalletFileBloc bloc = DecryptWalletFileBloc();

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              ImportWalletDecryptScreen(missingPath, decryptBloc: bloc),
            ),
          );

          await tester.enterText(find.byType(TextFormField), 'pass');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Wallet file does not exist'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'shows localized keystore format error when file is missing required '
      'keystore fields',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final Directory tempDir = Directory.systemTemp.createTempSync(
          'onboarding_invalid_keystore_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });
        final File invalidKeystore = File('${tempDir.path}/empty.json')
          ..writeAsStringSync('{}');

        final DecryptWalletFileBloc bloc = DecryptWalletFileBloc();

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              ImportWalletDecryptScreen(
                invalidKeystore.path,
                decryptBloc: bloc,
              ),
            ),
          );

          await tester.enterText(find.byType(TextFormField), 'pass');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Not a valid keystore file'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'shows non-regular file WalletException when a directory is provided',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final Directory tempDir = Directory.systemTemp.createTempSync(
          'onboarding_dir_drop_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final DecryptWalletFileBloc bloc = DecryptWalletFileBloc();

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              ImportWalletDecryptScreen(tempDir.path, decryptBloc: bloc),
            ),
          );

          await tester.enterText(find.byType(TextFormField), 'pass');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(
            find.text('Selected wallet path is not a regular file'),
            findsOneWidget,
          );
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'shows unsupported wallet file type error when decrypted file is Ledger',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final _MockLedgerWalletFile ledgerFile = _MockLedgerWalletFile();
        final DecryptWalletFileBloc bloc = DecryptWalletFileBloc(
          decryptWalletFile: (_, _) async => ledgerFile,
        );

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              ImportWalletDecryptScreen('/tmp/ledger-file', decryptBloc: bloc),
            ),
          );

          await tester.enterText(find.byType(TextFormField), 'pass');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Unsupported wallet file type'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets('shows localized unsupported wallet file type error on '
        'WalletFileReadException(unsupportedWalletType)', (
      WidgetTester tester,
    ) async {
      _configureDesktopViewport(tester);

      final DecryptWalletFileBloc bloc = DecryptWalletFileBloc(
        decryptWalletFile: (_, _) => Future<WalletFile>.error(
          WalletFileReadException(
            WalletFileReadFailureReason.unsupportedWalletType,
            'Wallet type (unknown) is not supported',
          ),
        ),
      );

      try {
        await tester.pumpWidget(
          _buildDesktopApp(
            ImportWalletDecryptScreen('/tmp/unsupported', decryptBloc: bloc),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'pass');
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Unsupported wallet file type'), findsOneWidget);
      } finally {
        await bloc.close();
      }
    });

    testWidgets(
      'navigates to ImportWalletPasswordScreen on valid KeyStoreWalletFile',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final _MockKeyStoreWalletFile keyStoreFile = _MockKeyStoreWalletFile();
        final KeyStore keyStore = KeyStore.fromMnemonic(
          Mnemonic.generateMnemonic(128),
        );
        when(() => keyStoreFile.access<String>(any())).thenAnswer((
          Invocation invocation,
        ) async {
          final Future<String> Function(Wallet) callback =
              invocation.positionalArguments.first
                  as Future<String> Function(Wallet);
          return await callback(keyStore);
        });

        final DecryptWalletFileBloc bloc = DecryptWalletFileBloc(
          decryptWalletFile: (_, _) async => keyStoreFile,
        );

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              ImportWalletDecryptScreen('/tmp/wallet', decryptBloc: bloc),
            ),
          );

          await tester.enterText(find.byType(TextFormField), 'GoodPass1!');
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(ImportWalletPasswordScreen), findsOneWidget);
          expect(find.text('Create a wallet password'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );
  });

  group('Onboarding password screens', () {
    testWidgets(
      'NewWalletPasswordScreen enables Confirm password only for strong '
      'matching passwords',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        await tester.pumpWidget(
          _buildDesktopApp(
            NewWalletPasswordScreen(Mnemonic.generateMnemonic(128).split(' ')),
          ),
        );

        OnboardingButton confirmButton() => tester
            .widgetList<OnboardingButton>(find.byType(OnboardingButton))
            .last;

        expect(confirmButton().onPressed, isNull);

        final Finder fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'weak');
        await tester.enterText(fields.at(1), 'weak');
        await tester.pump();
        expect(confirmButton().onPressed, isNull);

        await tester.enterText(fields.at(0), 'StrongPass1!');
        await tester.enterText(fields.at(1), 'Different1!');
        await tester.pump();
        expect(confirmButton().onPressed, isNull);

        await tester.enterText(fields.at(1), 'StrongPass1!');
        await tester.pump();
        expect(confirmButton().onPressed, isNotNull);
      },
    );
  });

  group('NewWalletConfirmSeedScreen', () {
    testWidgets(
      'resets missing words on failed verify and enables Continue on exact '
      'match',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final List<String> words = <String>[
          'alpha',
          'bravo',
          'charlie',
          'delta',
          'echo',
          'foxtrot',
          'golf',
          'hotel',
          'india',
          'juliet',
          'kilo',
          'lima',
        ];

        await tester.pumpWidget(
          _buildDesktopApp(
            NewWalletConfirmSeedScreen(words, randomIndexes: const <int>[0, 1]),
          ),
        );

        expect(find.text('Confirm your seed'), findsOneWidget);
        expect(find.text('Verify'), findsOneWidget);

        // Verify with empty missing slots stays on Verify.
        await tester.tap(find.text('Verify'));
        await tester.pump();
        expect(find.text('Verify'), findsOneWidget);
        expect(find.text('Continue'), findsNothing);

        // Drop the correct words into slots 0 and 1.
        final List<DragTarget<String>> targets = tester
            .widgetList<DragTarget<String>>(find.byType(DragTarget<String>))
            .toList();
        targets[0].onAcceptWithDetails!(
          DragTargetDetails<String>(data: 'alpha', offset: Offset.zero),
        );
        targets[1].onAcceptWithDetails!(
          DragTargetDetails<String>(data: 'bravo', offset: Offset.zero),
        );
        await tester.pump();

        await tester.tap(find.text('Verify'));
        await tester.pump();

        expect(find.text('Continue'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.byType(NewWalletPasswordScreen), findsOneWidget);
      },
    );
  });

  group('CreateKeyStoreScreen & CreateLedgerWalletScreen', () {
    testWidgets(
      'CreateKeyStoreScreen transitions from loading to node management step '
      'to WalletSuccessScreen',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final _MockKeyStoreWalletFile walletFile = _MockKeyStoreWalletFile();
        final KeyStoreFileBloc bloc = KeyStoreFileBloc(
          createKeyStoreWalletFile: (_, _) async {},
          initWalletAfterDecryption: (_) async {},
          getWalletFile: () => walletFile,
        );

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              CreateKeyStoreScreen(
                'seed',
                'StrongPass1!',
                keyStoreFileBloc: bloc,
                nodeManagementBuilder: (VoidCallback onConfirmed) =>
                    ElevatedButton(
                      onPressed: onConfirmed,
                      child: const Text('confirm-node'),
                    ),
              ),
            ),
          );

          expect(find.byType(SyriusLoadingWidget), findsOneWidget);

          bloc.add(
            const KeyStoreFileCreateRequested(
              mnemonic: 'seed',
              password: 'StrongPass1!',
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(find.text('confirm-node'), findsOneWidget);

          await tester.tap(find.text('confirm-node'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(WalletSuccessScreen), findsOneWidget);
          expect(find.text("You're all set"), findsOneWidget);
          expect(find.text('Access wallet'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'CreateLedgerWalletScreen renders error widget when creation fails',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final LedgerWalletFileBloc bloc = LedgerWalletFileBloc(
          createLedgerWalletFile: (_, _, {String? walletName}) =>
              Future<void>.error(Exception('ledger init failed')),
          initWalletAfterDecryption: (_) async {},
          getWalletFile: () => null,
        );

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              CreateLedgerWalletScreen(
                _FakeWalletDefinition(walletId: 'id', walletName: 'Nano X'),
                'StrongPass1!',
                ledgerWalletFileBloc: bloc,
              ),
            ),
          );

          bloc.add(
            const LedgerWalletFileCreateRequested(
              walletId: 'id',
              password: 'StrongPass1!',
              walletName: 'Nano X',
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(find.byType(SyriusErrorWidget), findsOneWidget);
          expect(find.textContaining('ledger init failed'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );
  });

  group('HardwareWalletDeviceChoiceScreen', () {
    testWidgets(
      'scans devices, selects a device, and enables Continue once resolved',
      (WidgetTester tester) async {
        _configureDesktopViewport(tester);

        final _MockWalletManager manager = _MockWalletManager();
        final _MockLedgerWallet wallet = _MockLedgerWallet();
        final _MockLedgerWalletAccount account = _MockLedgerWalletAccount();
        final _FakeWalletDefinition device = _FakeWalletDefinition(
          walletId: 'usb-0',
          walletName: 'Nano X',
        );

        final Address testAddress = Address.parse(
          'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
        );

        when(
          manager.getWalletDefinitions,
        ).thenAnswer((_) async => <WalletDefinition>[device]);
        when(() => manager.supportsWallet(any())).thenAnswer((_) async => true);
        when(() => manager.getWallet(any())).thenAnswer((_) async => wallet);
        when(wallet.getAccount).thenAnswer((_) async => account);
        when(
          () => account.getAddress(true),
        ).thenAnswer((_) async => testAddress);
        when(wallet.disconnect).thenAnswer((_) async {});

        final HardwareWalletDeviceBloc bloc = HardwareWalletDeviceBloc(
          walletManagers: <WalletManager>[manager],
          clearAddressesBox: () async {},
          sendNotification: (_) async {},
        );

        try {
          await tester.pumpWidget(
            _buildDesktopApp(
              HardwareWalletDeviceChoiceScreen(
                deviceBloc: bloc,
                showNotificationBanner: false,
              ),
            ),
          );

          expect(find.text('Choose your device'), findsOneWidget);

          await tester.tap(find.text('Scan devices'));
          await tester.pumpAndSettle();

          expect(find.text('Nano X'), findsOneWidget);
          expect(find.text('Select to connect the device'), findsOneWidget);

          await tester.tap(find.text('Nano X'));
          await tester.pumpAndSettle();

          expect(find.text(testAddress.toString()), findsOneWidget);

          final OnboardingButton continueButton = tester
              .widgetList<OnboardingButton>(find.byType(OnboardingButton))
              .last;
          expect(continueButton.onPressed, isNotNull);
        } finally {
          await tester.runAsync(bloc.close);
        }
      },
    );
  });
}
