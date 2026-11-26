import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

class _CustomAppLocalizations extends AppLocalizationsEn {
  _CustomAppLocalizations() : super('en');

  @override
  String get incorrectPassword => '[L10N] incorrectPassword';

  @override
  String get walletNotUnlocked => '[L10N] walletNotUnlocked';

  @override
  String get noWalletAddressSelected => '[L10N] noWalletAddressSelected';

  @override
  String addressNotInWalletList(String address) =>
      '[L10N] addressNotInWalletList:$address';

  @override
  String get unableToRetrieveTokenInformation =>
      '[L10N] unableToRetrieveTokenInformation';

  @override
  String get depositNotIntendedForYou => '[L10N] depositNotIntendedForYou';

  @override
  String get cannotJoinOwnSwap => '[L10N] cannotJoinOwnSwap';

  @override
  String get depositAlreadyUsedInSwap => '[L10N] depositAlreadyUsedInSwap';

  @override
  String get depositHashlockAlreadyUsedInSwap =>
      '[L10N] depositHashlockAlreadyUsedInSwap';

  @override
  String get depositExpired => '[L10N] depositExpired';

  @override
  String get depositExpiresTooSoonForSafeSwap =>
      '[L10N] depositExpiresTooSoonForSafeSwap';

  @override
  String get unableToVerifyDepositCreationTime =>
      '[L10N] unableToVerifyDepositCreationTime';

  @override
  String depositDurationTooLong(int maxHours) =>
      '[L10N] depositDurationTooLong:$maxHours';

  @override
  String get hashlockNotUnique => '[L10N] hashlockNotUnique';

  @override
  String get swapDoesNotExist => '[L10N] swapDoesNotExist';

  @override
  String get invalidSwap => '[L10N] invalidSwap';

  @override
  String get swapAddressNotInDefaultAddresses =>
      '[L10N] swapAddressNotInDefaultAddresses';

  @override
  String get swapExpiresTooSoonForSafeSwap =>
      '[L10N] swapExpiresTooSoonForSafeSwap';

  @override
  String get invalidSwapSecret => '[L10N] invalidSwapSecret';

  @override
  String get swapSecretExceedsMaxSize => '[L10N] swapSecretExceedsMaxSize';

  @override
  String depositLockedUntil(String expirationDate) =>
      '[L10N] depositLockedUntil:$expirationDate';

  @override
  String get depositDoesNotBelongToYou => '[L10N] depositDoesNotBelongToYou';

  @override
  String get depositAddressNotInWalletAddresses =>
      '[L10N] depositAddressNotInWalletAddresses';

  @override
  String get unableToAddDepositAddressToWallet =>
      '[L10N] unableToAddDepositAddressToWallet';

  @override
  String get somethingWentWrong => '[L10N] somethingWentWrong';

  @override
  String get nodeNotSynced => '[L10N] nodeNotSynced';

  @override
  String get noRewardsInLastWeek => '[L10N] noRewardsInLastWeek';

  @override
  String get acceleratorFundEmpty => '[L10N] acceleratorFundEmpty';

  @override
  String get emptyAccountChain => '[L10N] emptyAccountChain';

  @override
  String get donationAmountMustBePositive =>
      '[L10N] donationAmountMustBePositive';

  @override
  String get addressOwnsOrProducesNoPillar =>
      '[L10N] addressOwnsOrProducesNoPillar';

  @override
  String get emptyBalanceOnSelectedAddress =>
      '[L10N] emptyBalanceOnSelectedAddress';

  @override
  String get noDelegationStatsAvailable => '[L10N] noDelegationStatsAvailable';

  @override
  String get pillarNameAlreadyExists => '[L10N] pillarNameAlreadyExists';

  @override
  String get noAccountBlocksAvailable => '[L10N] noAccountBlocksAvailable';

  @override
  String get noActiveStakingEntries => '[L10N] noActiveStakingEntries';

  @override
  String get notEnoughMomentums => '[L10N] notEnoughMomentums';

  @override
  String get notConnectedToNetwork => '[L10N] notConnectedToNetwork';
}

class _CustomL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _CustomL10nDelegate(this.l10n);

  final AppLocalizations l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(l10n);

  @override
  bool shouldReload(covariant _CustomL10nDelegate old) => old.l10n != l10n;
}

class _MockInitialHtlcValidationBloc
    extends MockBloc<InitialHtlcValidationEvent, InitialHtlcValidationState>
    implements InitialHtlcValidationBloc {}

void main() {
  group('LocalizedSyriusException', () {
    final _CustomAppLocalizations custom = _CustomAppLocalizations();

    test('maps every SyriusErrorCode through AppLocalizations', () {
      for (final SyriusErrorCode code in SyriusErrorCode.values) {
        final LocalizedSyriusException exception = switch (code) {
          SyriusErrorCode.addressNotInWalletList =>
            LocalizedSyriusException.addressNotInWalletList(
              address: 'z1testaddr',
            ),
          SyriusErrorCode.depositDurationTooLong =>
            LocalizedSyriusException.depositDurationTooLong(maxHours: 8),
          SyriusErrorCode.depositLockedUntil =>
            LocalizedSyriusException.depositLockedUntil(
              expirationDate: '2026-01-01 12:00',
            ),
          _ => LocalizedSyriusException(code),
        };

        expect(
          exception.localizedMessage(custom),
          startsWith('[L10N] '),
          reason: 'Expected ${code.name} to resolve via AppLocalizations',
        );
        expect(exception.message, isNotEmpty);
      }
    });

    test('interpolates parameterized arguments cleanly', () {
      expect(
        LocalizedSyriusException.addressNotInWalletList(
          address: 'z1abc',
        ).localizedMessage(custom),
        '[L10N] addressNotInWalletList:z1abc',
      );
      expect(
        LocalizedSyriusException.depositDurationTooLong(
          maxHours: 12,
        ).localizedMessage(custom),
        '[L10N] depositDurationTooLong:12',
      );
      expect(
        LocalizedSyriusException.depositLockedUntil(
          expirationDate: '01/01/2026 12:00',
        ).localizedMessage(custom),
        '[L10N] depositLockedUntil:01/01/2026 12:00',
      );
    });

    test('supports value equality and JSON round-trip via '
        'SyriusException.fromJson', () {
      final LocalizedSyriusException original =
          LocalizedSyriusException.depositDurationTooLong(maxHours: 8);
      final Map<String, dynamic> json = original.toJson();
      final SyriusException restored = SyriusException.fromJson(json);

      expect(restored, isA<LocalizedSyriusException>());
      expect(restored, equals(original));
      expect(restored.hashCode, original.hashCode);
      expect(
        restored.localizedMessage(custom),
        '[L10N] depositDurationTooLong:8',
      );
    });

    test(
      'falls back to plain SyriusException when deserializing an unknown code',
      () {
        final SyriusException restored =
            SyriusException.fromJson(<String, dynamic>{
              'runtimeType': 'LocalizedSyriusException',
              'code': 'futureUnknownCode',
              'message': 'Persisted fallback message',
            });

        expect(restored, isNot(isA<LocalizedSyriusException>()));
        expect(restored.message, 'Persisted fallback message');
      },
    );

    test('existing domain SyriusException subclasses localize default messages '
        'and preserve custom messages', () {
      expect(
        FailureException().localizedMessage(custom),
        '[L10N] somethingWentWrong',
      );
      expect(
        FailureException(message: 'Custom failure').localizedMessage(custom),
        'Custom failure',
      );
      expect(
        NodeNotSyncedException().localizedMessage(custom),
        '[L10N] nodeNotSynced',
      );
      expect(
        NoRewardsLastWeekException().localizedMessage(custom),
        '[L10N] noRewardsInLastWeek',
      );
      expect(
        AcceleratorFundEmptyException().localizedMessage(custom),
        '[L10N] acceleratorFundEmpty',
      );
      expect(
        EmptyAccountChainException().localizedMessage(custom),
        '[L10N] emptyAccountChain',
      );
      expect(
        InvalidDonationAmountException().localizedMessage(custom),
        '[L10N] donationAmountMustBePositive',
      );
      expect(
        NoPillarForAddressException().localizedMessage(custom),
        '[L10N] addressOwnsOrProducesNoPillar',
      );
      expect(
        NoBalanceException().localizedMessage(custom),
        '[L10N] emptyBalanceOnSelectedAddress',
      );
      expect(
        NoDelegationStatsException().localizedMessage(custom),
        '[L10N] noDelegationStatsAvailable',
      );
      expect(
        PillarNameAlreadyExistsException().localizedMessage(custom),
        '[L10N] pillarNameAlreadyExists',
      );
      expect(
        NoBlocksAvailableException().localizedMessage(custom),
        '[L10N] noAccountBlocksAvailable',
      );
      expect(
        NoActiveStakingEntriesException().localizedMessage(custom),
        '[L10N] noActiveStakingEntries',
      );
      expect(
        NotEnoughMomentumsException().localizedMessage(custom),
        '[L10N] notEnoughMomentums',
      );
    });

    testWidgets(
      'SyriusErrorWidget resolves LocalizedSyriusException via context.l10n',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              _CustomL10nDelegate(custom),
              ...AppLocalizations.localizationsDelegates.skip(1),
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SyriusErrorWidget(
                LocalizedSyriusException(SyriusErrorCode.swapDoesNotExist),
              ),
            ),
          ),
        );

        expect(find.text('[L10N] swapDoesNotExist'), findsOneWidget);
      },
    );

    testWidgets(
      'SyriusErrorWidget localizes closed-client errors via context.l10n',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              _CustomL10nDelegate(custom),
              ...AppLocalizations.localizationsDelegates.skip(1),
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SyriusErrorWidget('Bad state: The client is closed'),
            ),
          ),
        );

        expect(find.text('[L10N] notConnectedToNetwork'), findsOneWidget);
      },
    );

    testWidgets(
      'InitialHtlcValidationForm renders LocalizedSyriusException via '
      'context.l10n',
      (WidgetTester tester) async {
        final _MockInitialHtlcValidationBloc bloc =
            _MockInitialHtlcValidationBloc();
        when(() => bloc.state).thenReturn(
          InitialHtlcValidationFailure(
            exception: LocalizedSyriusException(SyriusErrorCode.depositExpired),
          ),
        );

        await tester.pumpWidget(
          BlocProvider<InitialHtlcValidationBloc>.value(
            value: bloc,
            child: MaterialApp(
              localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                _CustomL10nDelegate(custom),
                ...AppLocalizations.localizationsDelegates.skip(1),
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: InitialHtlcValidationForm()),
            ),
          ),
        );

        expect(find.text('[L10N] depositExpired'), findsOneWidget);
      },
    );
  });
}
