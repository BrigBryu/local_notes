import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_palette.dart';
import 'app_theme.dart';
import 'theme_registry.dart';

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
  static const String _defaultThemeId = 'vampire';

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
      final savedThemeId = prefs.getString(_themePreferenceKey) ?? _defaultThemeId;
      
      await loadById(savedThemeId, persist: false);
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

  Future<void> loadById(String themeId, {bool persist = true}) async {
    final themeInfo = kThemeRegistry.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => kThemeRegistry.firstWhere((theme) => theme.id == _defaultThemeId),
    );

    try {
      state = state.copyWith(isLoading: true);
      
      final palette = await ColorPalette.fromAsset(themeInfo.assetPath);
      final themeData = AppTheme.fromColorPalette(palette);

      // Save preference if requested
      if (persist) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themePreferenceKey, themeId);
      }

      state = ThemeState(
        palette: palette,
        themeData: themeData,
        isLoading: false,
      );
    } catch (e) {
      // Revert loading state on error
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  @deprecated
  Future<void> setTheme(String themeKey) async {
    // Backward compatibility mapping
    await loadById(themeKey);
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

  String get currentThemeId {
    for (final themeInfo in kThemeRegistry) {
      if (themeInfo.assetPath.contains(state.palette.name.toLowerCase().replaceAll(' ', '-'))) {
        return themeInfo.id;
      }
    }
    return _defaultThemeId;
  }

  String get currentThemeName {
    return state.palette.name;
  }

  @deprecated
  String get currentThemeKey => currentThemeId;

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