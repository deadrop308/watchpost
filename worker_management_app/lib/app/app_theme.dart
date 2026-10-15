import 'package:flutter/material.dart';

/// Central light and dark themes for the whole app.
/// Screens should NOT hardcode colors like Colors.blue[700] or
/// Colors.white — they inherit from here, so dark mode just works.
/// When a screen needs a specific color, use `context.colors.<role>`.
class AppTheme {
  AppTheme._();

  /// The app's brand blue (same as Colors.blue[700])
  static const Color brandBlue = Color(0xFF1976D2);

  /// Light grey page background used in light mode (Colors.grey[100])
  static const Color _lightBackground = Color(0xFFF5F5F5);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    /// In light mode we pin the exact brand blue so the app looks
    /// identical to before. In dark mode Flutter picks a lighter,
    /// readable blue from the same seed.
    final ColorScheme scheme = isDark
        ? ColorScheme.fromSeed(seedColor: brandBlue, brightness: brightness)
        : ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: brightness,
      primary: brandBlue,
      onPrimary: Colors.white,
    );

    /// Header color used by AppBars and table headers
    final Color headerBackground =
    isDark ? scheme.surfaceContainerHigh : brandBlue;
    final Color headerForeground = isDark ? scheme.onSurface : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? scheme.surface : _lightBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: headerBackground,
        foregroundColor: headerForeground,
        iconTheme: IconThemeData(color: headerForeground),
        actionsIconTheme: IconThemeData(color: headerForeground),
      ),

      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),

      /// Every TextField / TextFormField / Dropdown gets a filled,
      /// outlined look — no need for filled/fillColor on each field
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHighest : Colors.white,
        border: const OutlineInputBorder(),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(headerBackground),
        headingTextStyle: TextStyle(
          color: headerForeground,
          fontWeight: FontWeight.bold,
        ),
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}

/// Short access to the current color scheme: `context.colors.primary`.
extension ThemeColorsContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
}