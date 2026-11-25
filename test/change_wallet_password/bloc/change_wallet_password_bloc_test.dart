import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/change_wallet_password/change_wallet_password.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_local_storage_api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/legacy_htlc_swaps_migrator.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_sync_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockWalletFile extends Mock implements WalletFile {}

class MockHtlcSwapSyncService extends Mock implements HtlcSwapSyncService {}

class MockHtlcSwapLocalStorageApi extends Mock
    implements HtlcSwapLocalStorageApi {}

class MockLegacyHtlcSwapsMigrator extends Mock
    implements LegacyHtlcSwapsMigrator {}

void main() {
  group('ChangeWalletPasswordBloc', () {
    const String walletPath = '/tmp/test-wallet';
    const String baseAddress = 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
    const String currentPassword = 'OldPassword1!';
    const String newPassword = 'NewPassword2@';

    late List<int> oldKey;
    late List<int> newKey;
    late MockWalletFile mockWalletFile;
    late MockHtlcSwapSyncService mockSyncService;
    late MockHtlcSwapLocalStorageApi mockStorageApi;
    late MockLegacyHtlcSwapsMigrator mockMigrator;
    late List<String> reportedErrorTitles;

    setUp(() {
      oldKey = Crypto.digest(utf8.encode(currentPassword));
      newKey = Crypto.digest(utf8.encode(newPassword));
      mockWalletFile = MockWalletFile();
      mockSyncService = MockHtlcSwapSyncService();
      mockStorageApi = MockHtlcSwapLocalStorageApi();
      mockMigrator = MockLegacyHtlcSwapsMigrator();
      reportedErrorTitles = <String>[];

      when(() => mockSyncService.stop()).thenAnswer((_) async {});
      when(() => mockSyncService.start()).thenReturn(null);
      when(
        () => mockMigrator.migrateIfNeeded(
          walletBaseAddress: any(named: 'walletBaseAddress'),
          encryptionKey: any(named: 'encryptionKey'),
        ),
      ).thenAnswer(
        (_) async => const LegacyHtlcSwapsMigrationResult(
          migratedCount: 0,
          failedCount: 0,
          deletedLegacyBoxes: true,
        ),
      );
      when(
        () => mockStorageApi.beginRekey(
          oldEncryptionKey: any(named: 'oldEncryptionKey'),
          newEncryptionKey: any(named: 'newEncryptionKey'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockStorageApi.commitRekey()).thenAnswer((_) async {});
      when(() => mockStorageApi.rollbackRekey(any())).thenAnswer((_) async {});
      when(
        () => mockWalletFile.changePassword(any(), any()),
      ).thenAnswer((_) async {});
    });

    ChangeWalletPasswordBloc buildBloc({
      Future<WalletFile> Function(String path, String password)? decrypt,
      String? baseAddressValue = baseAddress,
    }) => ChangeWalletPasswordBloc(
      decryptWalletFile: decrypt ?? (_, _) async => mockWalletFile,
      walletPathProvider: () => walletPath,
      walletFileProvider: () => mockWalletFile,
      walletBaseAddressProvider: () => baseAddressValue,
      syncService: mockSyncService,
      storageApi: mockStorageApi,
      legacyMigrator: mockMigrator,
      reportError: (Object error, String title) async {
        reportedErrorTitles.add(title);
      },
    );

    blocTest<ChangeWalletPasswordBloc, ChangeWalletPasswordState>(
      'emits IncorrectCurrentPassword without stopping sync or rekeying',
      build: () => buildBloc(
        decrypt: (_, _) async => throw IncorrectPasswordException(),
      ),
      act: (ChangeWalletPasswordBloc bloc) => bloc.add(
        const ChangeWalletPasswordSubmitted(
          currentPassword: 'wrong',
          newPassword: newPassword,
          decryptErrorTitle: 'Decrypt error',
          changePasswordErrorTitle: 'Change error',
        ),
      ),
      expect: () => const <ChangeWalletPasswordState>[
        ChangeWalletPasswordLoading(),
        ChangeWalletPasswordIncorrectCurrentPassword(),
      ],
      verify: (_) {
        verifyNever(() => mockSyncService.stop());
        verifyNever(
          () => mockStorageApi.beginRekey(
            oldEncryptionKey: any(named: 'oldEncryptionKey'),
            newEncryptionKey: any(named: 'newEncryptionKey'),
          ),
        );
        expect(reportedErrorTitles, isEmpty);
      },
    );

    blocTest<ChangeWalletPasswordBloc, ChangeWalletPasswordState>(
      'executes atomic stop -> migrate -> beginRekey -> changePassword -> '
      'commitRekey -> start in exact order',
      build: buildBloc,
      act: (ChangeWalletPasswordBloc bloc) => bloc.add(
        const ChangeWalletPasswordSubmitted(
          currentPassword: currentPassword,
          newPassword: newPassword,
          decryptErrorTitle: 'Decrypt error',
          changePasswordErrorTitle: 'Change error',
        ),
      ),
      expect: () => const <ChangeWalletPasswordState>[
        ChangeWalletPasswordLoading(),
        ChangeWalletPasswordSuccess(),
      ],
      verify: (_) {
        verifyInOrder(<Object? Function()>[
          () => mockSyncService.stop(),
          () => mockMigrator.migrateIfNeeded(
            walletBaseAddress: baseAddress,
            encryptionKey: oldKey,
          ),
          () => mockStorageApi.beginRekey(
            oldEncryptionKey: oldKey,
            newEncryptionKey: newKey,
          ),
          () => mockWalletFile.changePassword(currentPassword, newPassword),
          () => mockStorageApi.commitRekey(),
          () => mockSyncService.start(),
        ]);
        verifyNever(() => mockStorageApi.rollbackRekey(any()));
      },
    );

    blocTest<ChangeWalletPasswordBloc, ChangeWalletPasswordState>(
      'rolls back rekey and restarts sync service if changePassword fails',
      setUp: () {
        when(
          () => mockWalletFile.changePassword(any(), any()),
        ).thenThrow(StateError('write failed'));
      },
      build: buildBloc,
      act: (ChangeWalletPasswordBloc bloc) => bloc.add(
        const ChangeWalletPasswordSubmitted(
          currentPassword: currentPassword,
          newPassword: newPassword,
          decryptErrorTitle: 'Decrypt error',
          changePasswordErrorTitle: 'Change error',
        ),
      ),
      expect: () => <Matcher>[
        isA<ChangeWalletPasswordLoading>(),
        isA<ChangeWalletPasswordFailure>(),
      ],
      verify: (_) {
        verifyInOrder(<Object? Function()>[
          () => mockSyncService.stop(),
          () => mockMigrator.migrateIfNeeded(
            walletBaseAddress: baseAddress,
            encryptionKey: oldKey,
          ),
          () => mockStorageApi.beginRekey(
            oldEncryptionKey: oldKey,
            newEncryptionKey: newKey,
          ),
          () => mockWalletFile.changePassword(currentPassword, newPassword),
          () => mockStorageApi.rollbackRekey(oldKey),
          () => mockSyncService.start(),
        ]);
        verifyNever(() => mockStorageApi.commitRekey());
        expect(reportedErrorTitles, <String>['Change error']);
      },
    );

    blocTest<ChangeWalletPasswordBloc, ChangeWalletPasswordState>(
      'still restarts sync service if pre-rekey migration throws',
      setUp: () {
        when(
          () => mockMigrator.migrateIfNeeded(
            walletBaseAddress: any(named: 'walletBaseAddress'),
            encryptionKey: any(named: 'encryptionKey'),
          ),
        ).thenThrow(StateError('migration failed'));
      },
      build: buildBloc,
      act: (ChangeWalletPasswordBloc bloc) => bloc.add(
        const ChangeWalletPasswordSubmitted(
          currentPassword: currentPassword,
          newPassword: newPassword,
          decryptErrorTitle: 'Decrypt error',
          changePasswordErrorTitle: 'Change error',
        ),
      ),
      expect: () => <Matcher>[
        isA<ChangeWalletPasswordLoading>(),
        isA<ChangeWalletPasswordFailure>(),
      ],
      verify: (_) {
        verify(() => mockSyncService.stop()).called(1);
        verify(() => mockSyncService.start()).called(1);
        verifyNever(
          () => mockStorageApi.beginRekey(
            oldEncryptionKey: any(named: 'oldEncryptionKey'),
            newEncryptionKey: any(named: 'newEncryptionKey'),
          ),
        );
      },
    );

    test(
      'drops concurrent submissions while a rekey is already in progress',
      () async {
        final Completer<WalletFile> decryptCompleter = Completer<WalletFile>();
        final ChangeWalletPasswordBloc bloc = buildBloc(
          decrypt: (_, _) => decryptCompleter.future,
        );
        addTearDown(bloc.close);

        const ChangeWalletPasswordSubmitted event =
            ChangeWalletPasswordSubmitted(
              currentPassword: currentPassword,
              newPassword: newPassword,
              decryptErrorTitle: 'Decrypt error',
              changePasswordErrorTitle: 'Change error',
            );

        bloc
          ..add(event)
          ..add(event);

        await Future<void>.delayed(Duration.zero);
        decryptCompleter.complete(mockWalletFile);
        await expectLater(
          bloc.stream,
          emitsThrough(const ChangeWalletPasswordSuccess()),
        );

        verify(() => mockSyncService.stop()).called(1);
        verify(
          () => mockWalletFile.changePassword(currentPassword, newPassword),
        ).called(1);
        verify(() => mockStorageApi.commitRekey()).called(1);
        verifyNever(() => mockStorageApi.rollbackRekey(any()));
      },
    );
  });
}
