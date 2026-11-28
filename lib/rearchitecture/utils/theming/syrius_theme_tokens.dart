import 'package:flutter/material.dart';

/// Semantic design tokens for the redesigned Syrius light and dark themes.
@immutable
class SyriusThemeTokens extends ThemeExtension<SyriusThemeTokens> {
  /// Creates a [SyriusThemeTokens] palette.
  const SyriusThemeTokens({
    required this.shellBackground,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSubtle,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.znnGreen,
    required this.qsrBlue,
    required this.ztsMagenta,
    required this.warning,
    required this.warningSurface,
    required this.warningBorder,
    required this.error,
    required this.errorSurface,
    required this.errorBorder,
    required this.successSurface,
    required this.successForeground,
    required this.infoSurface,
    required this.infoForeground,
    required this.releaseSurface,
    required this.releaseForeground,
    required this.railActiveSurface,
    required this.heroGlowLeft,
    required this.heroGlowRight,
    required this.ambientGreen,
    required this.ambientViolet,
    required this.ambientBlue,
    required this.gradientButtonForeground,
    required this.modalBarrierColor,
  });

  /// Exact dark-mode tokens sampled from the redesign mockups.
  static const SyriusThemeTokens dark = SyriusThemeTokens(
    shellBackground: Color(0xFF1B1C1B),
    surface: Color(0xFF262726),
    surfaceElevated: Color(0xFF2E302E),
    surfaceSubtle: Color(0xFF202120),
    border: Color(0xFF353735),
    borderStrong: Color(0xFF4B4E4B),
    textPrimary: Color(0xFFF0F2F0),
    textSecondary: Color(0xFFA0A5A0),
    textMuted: Color(0xFF6E736E),
    znnGreen: Color(0xFF4FD166),
    qsrBlue: Color(0xFF3B8BFF),
    ztsMagenta: Color(0xFFFC54AE),
    warning: Color(0xFFE6B543),
    warningSurface: Color(0xFF373225),
    warningBorder: Color(0xFF5D5132),
    error: Color(0xFFF04465),
    errorSurface: Color(0xFF3B2129),
    errorBorder: Color(0xFF683040),
    successSurface: Color(0xFF233928),
    successForeground: Color(0xFF4FD166),
    infoSurface: Color(0xFF1E3048),
    infoForeground: Color(0xFF5C9DFF),
    releaseSurface: Color(0xFF3B2032),
    releaseForeground: Color(0xFFFC54AE),
    railActiveSurface: Color(0xFF262A26),
    heroGlowLeft: Color(0xFF2D4531),
    heroGlowRight: Color(0xFF223249),
    ambientGreen: Color(0x284FD166),
    ambientViolet: Color(0x20B0427F),
    ambientBlue: Color(0x2A006AFF),
    gradientButtonForeground: Color(0xFF0A140E),
    modalBarrierColor: Color(0x990D0E0D),
  );

  /// Exact light-mode tokens sampled from the redesign mockups.
  static const SyriusThemeTokens light = SyriusThemeTokens(
    shellBackground: Color(0xFFEAEAEA),
    surface: Color(0xFFF6F7F6),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFEEF0EE),
    border: Color(0xFFD5D8D5),
    borderStrong: Color(0xFFB5BBB5),
    textPrimary: Color(0xFF161816),
    textSecondary: Color(0xFF5D635D),
    textMuted: Color(0xFF888E88),
    znnGreen: Color(0xFF1DA84C),
    qsrBlue: Color(0xFF0061EB),
    ztsMagenta: Color(0xFFE53D96),
    warning: Color(0xFFB37E0C),
    warningSurface: Color(0xFFFBF3DC),
    warningBorder: Color(0xFFE3CA86),
    error: Color(0xFFD91F48),
    errorSurface: Color(0xFFFCE8EC),
    errorBorder: Color(0xFFEDAEB9),
    successSurface: Color(0xFFDDF3E3),
    successForeground: Color(0xFF17863D),
    infoSurface: Color(0xFFDCEAFD),
    infoForeground: Color(0xFF1263D6),
    releaseSurface: Color(0xFFF9DFEE),
    releaseForeground: Color(0xFFB82174),
    railActiveSurface: Color(0xFFFFFFFF),
    heroGlowLeft: Color(0xFFD8F0DC),
    heroGlowRight: Color(0xFFCFDFF6),
    ambientGreen: Color(0x244FD166),
    ambientViolet: Color(0x18E062A6),
    ambientBlue: Color(0x22006AFF),
    gradientButtonForeground: Color(0xFF0A140E),
    modalBarrierColor: Color(0x66161816),
  );

  /// Outer window, sidebar rail, and canvas backdrop color.
  final Color shellBackground;

  /// Primary card, table container, and bottom strip background color.
  final Color surface;

  /// Elevated input, pill button, active segmented item, and hover background.
  final Color surfaceElevated;

  /// Recessed sub-surface used inside expanded table rows and nested boxes.
  final Color surfaceSubtle;

  /// Default 1px hairline border and divider color.
  final Color border;

  /// Emphasized border color for focused fields and active outlines.
  final Color borderStrong;

  /// Primary foreground text color.
  final Color textPrimary;

  /// Secondary foreground text color for metadata and labels.
  final Color textSecondary;

  /// Muted micro-label, caption, and hint foreground color.
  final Color textMuted;

  /// ZNN brand green accent color adjusted for theme contrast.
  final Color znnGreen;

  /// QSR brand blue accent color adjusted for theme contrast.
  final Color qsrBlue;

  /// ZTS magenta accent color.
  final Color ztsMagenta;

  /// Warning accent color (amber).
  final Color warning;

  /// Warning banner background fill.
  final Color warningSurface;

  /// Warning banner hairline border.
  final Color warningBorder;

  /// Destructive/error accent color.
  final Color error;

  /// Error badge/banner background fill.
  final Color errorSurface;

  /// Error badge/banner hairline border.
  final Color errorBorder;

  /// Positive status badge background.
  final Color successSurface;

  /// Positive status badge foreground.
  final Color successForeground;

  /// Informational / countdown badge background.
  final Color infoSurface;

  /// Informational / countdown badge foreground.
  final Color infoForeground;

  /// Release tag pill background.
  final Color releaseSurface;

  /// Release tag pill foreground.
  final Color releaseForeground;

  /// Active sidebar navigation item background.
  final Color railActiveSurface;

  /// Top-left green glow color on the Home hero card.
  final Color heroGlowLeft;

  /// Bottom-right blue glow color on the Home hero card.
  final Color heroGlowRight;

  /// Ambient backdrop top-left green glow.
  final Color ambientGreen;

  /// Ambient backdrop top-right violet glow.
  final Color ambientViolet;

  /// Ambient backdrop bottom-right blue glow.
  final Color ambientBlue;

  /// High-contrast text/icon color placed over the green-to-blue gradient CTA.
  final Color gradientButtonForeground;

  /// Backdrop dimming overlay color behind modals.
  final Color modalBarrierColor;

  /// Signature Zenon green-to-blue horizontal pill gradient.
  LinearGradient get primaryGradient => const LinearGradient(
    colors: <Color>[Color(0xFF4FD166), Color(0xFF006AFF)],
  );

  /// Signature Home balance hero banner gradient.
  LinearGradient get heroBannerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[heroGlowLeft, surface, heroGlowRight],
    stops: const <double>[0, 0.48, 1],
  );

  /// Monospace font family stack for addresses, hashes, and tabular figures.
  static const List<String> monoFontFallback = <String>[
    'SF Mono',
    'Menlo',
    'Consolas',
    'Roboto Mono',
    'monospace',
  ];

  /// Standard monospace text style with tabular numerals.
  TextStyle monoStyle({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'SF Mono',
      fontFamilyFallback: monoFontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimary,
      letterSpacing: letterSpacing,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  /// Small-caps uppercase micro-label style used above metrics and table cols.
  TextStyle microLabelStyle({Color? color}) {
    return TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.75,
      color: color ?? textMuted,
    );
  }

  @override
  SyriusThemeTokens copyWith({
    Color? shellBackground,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSubtle,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? znnGreen,
    Color? qsrBlue,
    Color? ztsMagenta,
    Color? warning,
    Color? warningSurface,
    Color? warningBorder,
    Color? error,
    Color? errorSurface,
    Color? errorBorder,
    Color? successSurface,
    Color? successForeground,
    Color? infoSurface,
    Color? infoForeground,
    Color? releaseSurface,
    Color? releaseForeground,
    Color? railActiveSurface,
    Color? heroGlowLeft,
    Color? heroGlowRight,
    Color? ambientGreen,
    Color? ambientViolet,
    Color? ambientBlue,
    Color? gradientButtonForeground,
    Color? modalBarrierColor,
  }) {
    return SyriusThemeTokens(
      shellBackground: shellBackground ?? this.shellBackground,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      znnGreen: znnGreen ?? this.znnGreen,
      qsrBlue: qsrBlue ?? this.qsrBlue,
      ztsMagenta: ztsMagenta ?? this.ztsMagenta,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      warningBorder: warningBorder ?? this.warningBorder,
      error: error ?? this.error,
      errorSurface: errorSurface ?? this.errorSurface,
      errorBorder: errorBorder ?? this.errorBorder,
      successSurface: successSurface ?? this.successSurface,
      successForeground: successForeground ?? this.successForeground,
      infoSurface: infoSurface ?? this.infoSurface,
      infoForeground: infoForeground ?? this.infoForeground,
      releaseSurface: releaseSurface ?? this.releaseSurface,
      releaseForeground: releaseForeground ?? this.releaseForeground,
      railActiveSurface: railActiveSurface ?? this.railActiveSurface,
      heroGlowLeft: heroGlowLeft ?? this.heroGlowLeft,
      heroGlowRight: heroGlowRight ?? this.heroGlowRight,
      ambientGreen: ambientGreen ?? this.ambientGreen,
      ambientViolet: ambientViolet ?? this.ambientViolet,
      ambientBlue: ambientBlue ?? this.ambientBlue,
      gradientButtonForeground:
          gradientButtonForeground ?? this.gradientButtonForeground,
      modalBarrierColor: modalBarrierColor ?? this.modalBarrierColor,
    );
  }

  @override
  SyriusThemeTokens lerp(ThemeExtension<SyriusThemeTokens>? other, double t) {
    if (other is! SyriusThemeTokens) {
      return this;
    }
    return SyriusThemeTokens(
      shellBackground: Color.lerp(shellBackground, other.shellBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      znnGreen: Color.lerp(znnGreen, other.znnGreen, t)!,
      qsrBlue: Color.lerp(qsrBlue, other.qsrBlue, t)!,
      ztsMagenta: Color.lerp(ztsMagenta, other.ztsMagenta, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      successForeground: Color.lerp(
        successForeground,
        other.successForeground,
        t,
      )!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      releaseSurface: Color.lerp(releaseSurface, other.releaseSurface, t)!,
      releaseForeground: Color.lerp(
        releaseForeground,
        other.releaseForeground,
        t,
      )!,
      railActiveSurface: Color.lerp(
        railActiveSurface,
        other.railActiveSurface,
        t,
      )!,
      heroGlowLeft: Color.lerp(heroGlowLeft, other.heroGlowLeft, t)!,
      heroGlowRight: Color.lerp(heroGlowRight, other.heroGlowRight, t)!,
      ambientGreen: Color.lerp(ambientGreen, other.ambientGreen, t)!,
      ambientViolet: Color.lerp(ambientViolet, other.ambientViolet, t)!,
      ambientBlue: Color.lerp(ambientBlue, other.ambientBlue, t)!,
      gradientButtonForeground: Color.lerp(
        gradientButtonForeground,
        other.gradientButtonForeground,
        t,
      )!,
      modalBarrierColor: Color.lerp(
        modalBarrierColor,
        other.modalBarrierColor,
        t,
      )!,
    );
  }
}
