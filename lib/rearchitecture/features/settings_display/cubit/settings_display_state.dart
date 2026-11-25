part of 'settings_display_cubit.dart';

/// State managed by [SettingsDisplayCubit].
class SettingsDisplayState extends Equatable {
  /// Creates a [SettingsDisplayState].
  const SettingsDisplayState({
    this.selectedLocale = LocaleType.english,
    this.isSavingTheme = false,
    this.isSavingTextScaling = false,
  });

  /// Currently selected UI locale.
  final LocaleType selectedLocale;

  /// Whether theme persistence is in progress.
  final bool isSavingTheme;

  /// Whether text scaling persistence is in progress.
  final bool isSavingTextScaling;

  /// Returns a copy of this state with updated fields.
  SettingsDisplayState copyWith({
    LocaleType? selectedLocale,
    bool? isSavingTheme,
    bool? isSavingTextScaling,
  }) {
    return SettingsDisplayState(
      selectedLocale: selectedLocale ?? this.selectedLocale,
      isSavingTheme: isSavingTheme ?? this.isSavingTheme,
      isSavingTextScaling: isSavingTextScaling ?? this.isSavingTextScaling,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedLocale,
    isSavingTheme,
    isSavingTextScaling,
  ];
}
