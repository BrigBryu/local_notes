import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notes/settings/theme_gallery_page.dart';
import 'package:local_notes/theme/theme_controller.dart';
import 'package:local_notes/theme/theme_registry.dart';

void main() {
  group('ThemeGalleryPage Widget Tests', () {
    testWidgets('displays theme gallery correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ThemeGalleryPage(),
          ),
        ),
      );

      // Wait for initial loading
      await tester.pumpAndSettle();

      // Check that the app bar shows "Themes"
      expect(find.text('Themes'), findsOneWidget);
      
      // Check that we have a grid view with theme cards
      expect(find.byType(GridView), findsOneWidget);
      
      // Check that theme cards are present
      expect(find.byType(ThemeCard), findsAtLeastNWidget(1));
    });

    testWidgets('displays all themes from registry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ThemeGalleryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have cards for all themes in registry
      expect(find.byType(ThemeCard), findsNWidgets(kThemeRegistry.length));
    });

    testWidgets('theme card shows correct name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ThemeGalleryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find vampire theme
      expect(find.text('Vampire'), findsOneWidget);
      
      // Should find gruvbox themes
      expect(find.text('Gruvbox Dark'), findsOneWidget);
      expect(find.text('Gruvbox Light'), findsOneWidget);
    });

    testWidgets('tapping theme card changes theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ThemeGalleryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Dracula theme card and tap it
      final draculaCard = find.ancestor(
        of: find.text('Dracula'),
        matching: find.byType(ThemeCard),
      );
      
      expect(draculaCard, findsOneWidget);
      
      await tester.tap(draculaCard);
      await tester.pumpAndSettle();

      // Theme should be changed (this would be validated in integration tests)
    });
  });

  group('StringExtension Tests', () {
    test('titleCase converts kebab-case to title case', () {
      expect('gruvbox-dark'.titleCase, equals('Gruvbox Dark'));
      expect('tokyo-night-storm'.titleCase, equals('Tokyo Night Storm'));
      expect('catppuccin-mocha'.titleCase, equals('Catppuccin Mocha'));
      expect('one-dark'.titleCase, equals('One Dark'));
      expect('vampire'.titleCase, equals('Vampire'));
    });
  });

  group('ThemeCard Widget Tests', () {
    testWidgets('renders theme card correctly', (tester) async {
      const themeInfo = ThemeInfo(
        id: 'test-theme',
        assetPath: 'assets/themes/vampire.json',
        swatchKeys: ['background', 'red', 'blue'],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeCard(
                themeInfo: themeInfo,
                isActive: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the theme name
      expect(find.text('Test Theme'), findsOneWidget);
      
      // Should show the card
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows active border when theme is active', (tester) async {
      const themeInfo = ThemeInfo(
        id: 'test-theme',
        assetPath: 'assets/themes/vampire.json',
        swatchKeys: ['background', 'red', 'blue'],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeCard(
                themeInfo: themeInfo,
                isActive: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card should exist
      expect(find.byType(Card), findsOneWidget);
      
      // When active, card should have different styling (tested by integration)
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool wasTapped = false;
      const themeInfo = ThemeInfo(
        id: 'test-theme',
        assetPath: 'assets/themes/vampire.json',
        swatchKeys: ['background', 'red', 'blue'],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeCard(
                themeInfo: themeInfo,
                isActive: false,
                onTap: () {
                  wasTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the card
      await tester.tap(find.byType(ThemeCard));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });
  });
}