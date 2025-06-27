import 'package:flutter/material.dart';
import 'color_palette.dart';

class AppTheme {
  static ThemeData fromColorPalette(ColorPalette palette) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: _getBrightnessFromPalette(palette),
    ).copyWith(
      primary: palette.primary,
      secondary: palette.secondary,
      surface: palette.surface,
      error: palette.error,
      onPrimary: palette.onPrimary,
      onSecondary: palette.onSecondary,
      onSurface: palette.onSurface,
      onError: palette.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.surface,
      dividerColor: palette.divider,
      shadowColor: palette.shadow,
      disabledColor: palette.disabled,
      hintColor: palette.hint,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        labelStyle: TextStyle(color: palette.hint),
        hintStyle: TextStyle(color: palette.hint),
      ),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: palette.onSurface,
      ),
      
      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accent,
        foregroundColor: palette.onPrimary,
      ),
      
      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: palette.onSurface),
        headlineMedium: TextStyle(color: palette.onSurface),
        headlineSmall: TextStyle(color: palette.onSurface),
        titleLarge: TextStyle(color: palette.onSurface),
        titleMedium: TextStyle(color: palette.onSurface),
        titleSmall: TextStyle(color: palette.onSurface),
        bodyLarge: TextStyle(color: palette.onSurface),
        bodyMedium: TextStyle(color: palette.onSurface),
        bodySmall: TextStyle(color: palette.hint),
        labelLarge: TextStyle(color: palette.onSurface),
        labelMedium: TextStyle(color: palette.onSurface),
        labelSmall: TextStyle(color: palette.hint),
      ),
    );
  }

  static Brightness _getBrightnessFromPalette(ColorPalette palette) {
    // Calculate luminance of surface color to determine brightness
    final luminance = palette.surface.computeLuminance();
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }

  // Common theme extensions for custom colors
  static Color accentColor(BuildContext context, ColorPalette palette) => palette.accent;
  static Color dividerColor(BuildContext context, ColorPalette palette) => palette.divider;
  static Color shadowColor(BuildContext context, ColorPalette palette) => palette.shadow;
  static Color disabledColor(BuildContext context, ColorPalette palette) => palette.disabled;
  static Color hintColor(BuildContext context, ColorPalette palette) => palette.hint;
}