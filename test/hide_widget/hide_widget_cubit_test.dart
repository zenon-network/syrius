import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/hide_widget/hide_widget_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';

class _MockWalletFile extends Mock implements WalletFile {}

void main() {
  initHydratedStorage();

  group('HideWidgetCubit temporary WalletFile cleanup', () {
    test('closes temporary WalletFile after unhiding succeeds', () async {
      final _MockWalletFile walletFile = _MockWalletFile();
      when(walletFile.close).thenAnswer((_) async {});
      bool? persistedHidden;

      final HideWidgetCubit cubit = HideWidgetCubit(
        walletPathProvider: () => '/tmp/wallet',
        decryptWalletFile: (_, _) async => walletFile,
        markWidgetAsHidden: (String title, {required bool isHidden}) async {
          expect(title, 'Balance');
          persistedHidden = isHidden;
        },
      );
      addTearDown(cubit.close);

      await cubit.saveValue(
        isHidden: false,
        widgetTitle: 'Balance',
        password: 'Password1!',
      );

      expect(persistedHidden, isFalse);
      expect(cubit.state.status, HideWidgetStatus.success);
      expect(cubit.state.isHidden, isFalse);
      verify(walletFile.close).called(1);
    });

    test(
      'closes temporary WalletFile even when persisting visibility fails',
      () async {
        final _MockWalletFile walletFile = _MockWalletFile();
        when(walletFile.close).thenAnswer((_) async {});

        final HideWidgetCubit cubit = HideWidgetCubit(
          walletPathProvider: () => '/tmp/wallet',
          decryptWalletFile: (_, _) async => walletFile,
          markWidgetAsHidden: (_, {required bool isHidden}) =>
              Future<void>.error(StateError('prefs failed')),
        );
        addTearDown(cubit.close);

        await cubit.saveValue(
          isHidden: false,
          widgetTitle: 'Balance',
          password: 'Password1!',
        );

        expect(cubit.state.status, HideWidgetStatus.failure);
        verify(walletFile.close).called(1);
      },
    );

    test('emits failure with incorrect-password message when decrypt throws '
        'IncorrectPasswordException', () async {
      bool persisted = false;
      final HideWidgetCubit cubit = HideWidgetCubit(
        walletPathProvider: () => '/tmp/wallet',
        decryptWalletFile: (_, _) =>
            Future<WalletFile>.error(IncorrectPasswordException()),
        markWidgetAsHidden: (_, {required bool isHidden}) async {
          persisted = true;
        },
      );
      addTearDown(cubit.close);

      await cubit.saveValue(
        isHidden: false,
        widgetTitle: 'Balance',
        password: 'wrong',
      );

      expect(persisted, isFalse);
      expect(cubit.state.status, HideWidgetStatus.failure);
      expect(
        cubit.state.exception?.message,
        kIncorrectPasswordNotificationTitle,
      );
    });
  });
}
