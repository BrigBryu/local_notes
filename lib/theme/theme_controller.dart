import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_palette.dart';
import 'app_theme.dart';

class ThemeState {
  final ColorPalette palette;
  final ThemeData themeData;
  final bool isLoading;

  const ThemeState({
    required this.palette,
    required this.themeData,
    this.isLoading = false,
  });

  ThemeState copyWith({
    ColorPalette? palette,
    ThemeData? themeData,
    bool? isLoading,
  }) {
    return ThemeState(
      palette: palette ?? this.palette,
      themeData: themeData ?? this.themeData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ThemeController extends StateNotifier<ThemeState> {
  static const String _themePreferenceKey = 'selected_theme';
  static const String _defaultThemePath = 'assets/themes/default.json';
  
  static const Map<String, String> availableThemes = {
    'light': 'assets/themes/light.json',
    'dark': 'assets/themes/dark.json',
    'default': 'assets/themes/default.json',
  };

  ThemeController() : super(ThemeState(
    palette: _getDefaultPalette(),
    themeData: AppTheme.fromColorPalette(_getDefaultPalette()),
    isLoading: true,
  )) {
    _loadTheme();
  }

  static ColorPalette _getDefaultPalette() {
    // Fallback palette in case assets fail to load
    return const ColorPalette(
      name: 'Fallback',
      primary: Color(0xFF2563eb),
      primaryVariant: Color(0xFF1d4ed8),
      secondary: Color(0xFF7c3aed),
      secondaryVariant: Color(0xFF6d28d9),
      surface: Color(0xFFffffff),
      background: Color(0xFFf8fafc),
      error: Color(0xFFdc2626),
      onPrimary: Color(0xFFffffff),
      onSecondary: Color(0xFFffffff),
      onSurface: Color(0xFF1e293b),
      onBackground: Color(0xFF334155),
      onError: Color(0xFFffffff),
      accent: Color(0xFF059669),
      divider: Color(0xFFe2e8f0),
      shadow: Color(0xFF64748b),
      disabled: Color(0xFF94a3b8),
      hint: Color(0xFF64748b),
    );
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey) ?? 'default';
      
      final themePath = availableThemes[savedTheme] ?? _defaultThemePath;
      final palette = await ColorPalette.fromAsset(themePath);
      final themeData = AppTheme.fromColorPalette(palette);

      state = ThemeState(
        palette: palette,
        themeData: themeData,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to default if loading fails
      final defaultPalette = _getDefaultPalette();
      state = ThemeState(
        palette: defaultPalette,
        themeData: AppTheme.fromColorPalette(defaultPalette),
        isLoading: false,
      );
    }
  }

  Future<void> setTheme(String themeKey) async {
    if (!availableThemes.containsKey(themeKey)) return;

    try {
      state = state.copyWith(isLoading: true);
      
      final themePath = availableThemes[themeKey]!;
      final palette = await ColorPalette.fromAsset(themePath);
      final themeData = AppTheme.fromColorPalette(palette);

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, themeKey);

      state = ThemeState(
        palette: palette,
        themeData: themeData,
        isLoading: false,
      );
    } catch (e) {
      // Revert loading state on error
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setCustomPalette(ColorPalette palette) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final themeData = AppTheme.fromColorPalette(palette);
      
      state = ThemeState(
        palette: palette,
        themeData: themeData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  String get currentThemeKey {
    for (final entry in availableThemes.entries) {
      if (entry.value.contains(state.palette.name.toLowerCase())) {
        return entry.key;
      }
    }
    return 'default';
  }

  bool get isDarkTheme {
    return state.palette.background.computeLuminance() < 0.5;
  }
}

// Providers
final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController();
});

// Convenience providers
final currentPaletteProvider = Provider<ColorPalette>((ref) {
  return ref.watch(themeControllerProvider).palette;
});

final currentThemeDataProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeControllerProvider).themeData;
});

final isThemeLoadingProvider = Provider<bool>((ref) {
  return ref.watch(themeControllerProvider).isLoading;
});