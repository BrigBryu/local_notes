import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_notes/theme/theme_controller.dart';
import 'package:local_notes/theme/theme_registry.dart';

void main() {
  group('ThemeController Tests', () {
    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('loads default theme on initialization', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for the controller to initialize
      await container.read(themeControllerProvider.future);

      final themeState = container.read(themeControllerProvider);
      
      expect(themeState.isLoading, isFalse);
      expect(themeState.palette.name, contains('Vampire')); // Default theme
    });

    test('loadById changes theme and persists selection', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeControllerProvider.notifier);
      
      // Wait for initial load
      await container.read(themeControllerProvider.future);
      
      // Load a different theme
      await notifier.loadById('dracula');
      
      final themeState = container.read(themeControllerProvider);
      expect(themeState.palette.name, equals('Dracula'));
      
      // Check that preference was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_theme'), equals('dracula'));
    });

    test('loadById with persist=false does not save preference', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeControllerProvider.notifier);
      
      // Wait for initial load
      await container.read(themeControllerProvider.future);
      
      // Load theme without persisting
      await notifier.loadById('nord', persist: false);
      
      final themeState = container.read(themeControllerProvider);
      expect(themeState.palette.name, equals('Nord'));
      
      // Check that preference was not saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_theme'), isNull);
    });

    test('loadById falls back to default for invalid theme', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeControllerProvider.notifier);
      
      // Wait for initial load
      await container.read(themeControllerProvider.future);
      
      // Try to load invalid theme
      await notifier.loadById('invalid-theme');
      
      final themeState = container.read(themeControllerProvider);
      expect(themeState.palette.name, contains('Vampire')); // Should fallback to default
    });

    test('currentThemeId returns correct theme ID', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeControllerProvider.notifier);
      
      // Wait for initial load
      await container.read(themeControllerProvider.future);
      
      // Load specific theme
      await notifier.loadById('gruvbox-dark');
      
      expect(notifier.currentThemeId, equals('gruvbox-dark'));
    });

    test('currentThemeName returns theme display name', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeControllerProvider.notifier);
      
      // Wait for initial load
      await container.read(themeControllerProvider.future);
      
      // Load specific theme
      await notifier.loadById('tokyo-night-storm');
      
      expect(notifier.currentThemeName, equals('Tokyo Night Storm'));
    });

    test('isDarkTheme correctly identifies dark themes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeControllerProvider.notifier);
      
      // Wait for initial load
      await container.read(themeControllerProvider.future);
      
      // Test dark theme
      await notifier.loadById('vampire');
      expect(notifier.isDarkTheme, isTrue);
      
      // Test light theme
      await notifier.loadById('gruvbox-light');
      expect(notifier.isDarkTheme, isFalse);
    });

    test('restores saved theme on initialization', () async {
      // Set up saved preference
      SharedPreferences.setMockInitialValues({
        'selected_theme': 'dracula',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initialization
      await container.read(themeControllerProvider.future);
      
      final themeState = container.read(themeControllerProvider);
      expect(themeState.palette.name, equals('Dracula'));
    });
  });

  group('ThemeRegistry Tests', () {
    test('contains all expected themes', () {
      final themeIds = kThemeRegistry.map((t) => t.id).toList();
      
      expect(themeIds, contains('vampire'));
      expect(themeIds, contains('gruvbox-dark'));
      expect(themeIds, contains('gruvbox-light'));
      expect(themeIds, contains('solarized-dark'));
      expect(themeIds, contains('solarized-light'));
      expect(themeIds, contains('dracula'));
      expect(themeIds, contains('nord'));
      expect(themeIds, contains('monokai'));
      expect(themeIds, contains('one-dark'));
      expect(themeIds, contains('tokyo-night-storm'));
      expect(themeIds, contains('catppuccin-mocha'));
      expect(themeIds, contains('default'));
      expect(themeIds, contains('light'));
      expect(themeIds, contains('dark'));
    });

    test('all themes have valid asset paths', () {
      for (final theme in kThemeRegistry) {
        expect(theme.assetPath, startsWith('assets/themes/'));
        expect(theme.assetPath, endsWith('.json'));
      }
    });

    test('all themes have swatch keys', () {
      for (final theme in kThemeRegistry) {
        expect(theme.swatchKeys, isNotEmpty);
        expect(theme.swatchKeys.length, greaterThanOrEqualTo(3));
      }
    });
  });
}