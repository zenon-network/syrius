import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_display/settings_display.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class MockSharedPrefsService extends Mock implements SharedPrefsService {}

void main() {
  group('SettingsDisplayCubit', () {
    late MockSharedPrefsService prefs;
    late List<WalletNotification> notifications;
    late List<String> errorTitles;

    setUp(() {
      prefs = MockSharedPrefsService();
      notifications = <WalletNotification>[];
      errorTitles = <String>[];
      when(() => prefs.put(any(), any<dynamic>())).thenAnswer((_) async {});
    });

    SettingsDisplayCubit buildCubit() => SettingsDisplayCubit(
      prefsService: prefs,
      addNotification: (WalletNotification notification) async {
        notifications.add(notification);
      },
      reportError: (Object error, String title) async {
        errorTitles.add(title);
      },
    );

    test('initial state defaults to english and idle', () {
      final SettingsDisplayCubit cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const SettingsDisplayState());
    });

    blocTest<SettingsDisplayCubit, SettingsDisplayState>(
      'confirmThemeMode persists theme mode and sends notification',
      build: buildCubit,
      act: (SettingsDisplayCubit cubit) => cubit.confirmThemeMode(
        themeMode: ThemeMode.light,
        notificationTitle: 'Theme mode changed',
        notificationDetails: 'Changed to Light',
        errorTitle: 'Theme mode change failed',
      ),
      expect: () => const <SettingsDisplayState>[
        SettingsDisplayState(isSavingTheme: true),
        SettingsDisplayState(),
      ],
      verify: (_) {
        verify(
          () => prefs.put(kThemeModeKey, ThemeMode.light.toString()),
        ).called(1);
        expect(notifications, hasLength(1));
        expect(notifications.single.title, 'Theme mode changed');
      },
    );

    blocTest<SettingsDisplayCubit, SettingsDisplayState>(
      'confirmTextScaling persists text scaling and reports error on throw',
      setUp: () {
        when(
          () => prefs.put(kTextScalingKey, any<dynamic>()),
        ).thenThrow(StateError('disk full'));
      },
      build: buildCubit,
      act: (SettingsDisplayCubit cubit) => cubit.confirmTextScaling(
        textScaling: TextScaling.large,
        notificationTitle: 'Text scale changed',
        notificationDetails: 'Changed to Large',
        errorTitle: 'Text scale change failed',
      ),
      expect: () => const <SettingsDisplayState>[
        SettingsDisplayState(isSavingTextScaling: true),
        SettingsDisplayState(),
      ],
      verify: (_) {
        expect(errorTitles, <String>['Text scale change failed']);
        expect(notifications, isEmpty);
      },
    );
  });
}
