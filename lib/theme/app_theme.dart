import 'package:flutter/material.dart';

/// Light palette
class _Light {
  static const text = Color(0xFF081D02);
  static const background = Color(0xFFECFDE2);
  static const primary = Color(0xFF27850A);
  static const secondary = Color(0xFF59E1F3);
  static const accent = Color(0xFF1159E8);
}

/// Dark palette
class _Dark {
  static const text = Color(0xFFE8FDE2);
  static const background = Color(0xFF0C1F02);
  static const primary = Color(0xFF95F578);
  static const secondary = Color(0xFF0C93A4);
  static const accent = Color(0xFF155DEE);
}

class AppTheme {
  AppTheme._();

  // ─── Shared ───
  static const String fontFamily = 'Roboto';
  static const double cardRadius = 16;
  static const double buttonRadius = 12;

  // ─── Helpers for screens that need raw colours ───
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color bg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color card(BuildContext context) =>
      Theme.of(context).cardTheme.color ??
      Theme.of(context).colorScheme.surface;
  static Color textColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color subtextColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  // ─── Light ThemeData ───
  static final ThemeData light = _build(
    brightness: Brightness.light,
    text: _Light.text,
    background: _Light.background,
    primary: _Light.primary,
    secondary: _Light.secondary,
    accent: _Light.accent,
    cardColor: Colors.white,
    surfaceColor: const Color(0xFFF4FFF0),
  );

  // ─── Dark ThemeData ───
  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    text: _Dark.text,
    background: _Dark.background,
    primary: _Dark.primary,
    secondary: _Dark.secondary,
    accent: _Dark.accent,
    cardColor: const Color(0xFF162B0A),
    surfaceColor: const Color(0xFF132506),
  );

  // ─── Builder ───
  static ThemeData _build({
    required Brightness brightness,
    required Color text,
    required Color background,
    required Color primary,
    required Color secondary,
    required Color accent,
    required Color cardColor,
    required Color surfaceColor,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final Color onPrimary = isDark ? const Color(0xFF081D02) : Colors.white;
    final Color divider = text.withValues(alpha: 0.12);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withValues(alpha: 0.15),
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: isDark ? Colors.black : Colors.white,
      secondaryContainer: secondary.withValues(alpha: 0.15),
      onSecondaryContainer: secondary,
      tertiary: accent,
      onTertiary: Colors.white,
      tertiaryContainer: accent.withValues(alpha: 0.15),
      onTertiaryContainer: accent,
      error: const Color(0xFFCF6679),
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: text,
      outline: divider,
      shadow: Colors.black.withValues(alpha: 0.2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        iconTheme: IconThemeData(color: text),
      ),

      // ─── Cards ───
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── ElevatedButton ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),

      // ─── OutlinedButton ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),

      // ─── TextButton ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Chips ───
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          color: text,
        ),
        side: BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ─── Switch / Slider ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary
              : text.withValues(alpha: 0.3),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.4)
              : text.withValues(alpha: 0.1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.15),
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: TextStyle(
          color: onPrimary,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(color: divider, thickness: 1),

      // ─── SnackBar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1A3A0A)
            : const Color(0xFF2E7D32),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: text.withValues(alpha: 0.8),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        textColor: text,
        iconColor: text.withValues(alpha: 0.7),
      ),

      // ─── SegmentedButton ───
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : text,
          ),
          side: WidgetStateProperty.all(BorderSide(color: divider)),
        ),
      ),

      // ─── ProgressIndicator ───
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.15),
      ),
    );
  }
}
