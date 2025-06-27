import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:local_notes/features/editor/note_editor_page.dart';
import 'package:local_notes/main.dart';
import 'package:local_notes/domain/note.dart';
import 'package:local_notes/theme/theme_controller.dart';

void main() {
  group('Theme Golden Tests', () {
    setUpAll(() async {
      // Load fonts for golden tests
      await loadAppFonts();
    });

    testGoldens('Home page light theme', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletPortrait]);

      await tester.pumpDeviceBuilder(
        builder
          ..addScenario(
            widget: ProviderScope(
              overrides: [
                themeControllerProvider.overrideWith((ref) {
                  final controller = ThemeController();
                  // Force light theme
                  Future.microtask(() => controller.setTheme('light'));
                  return controller;
                }),
              ],
              child: const LocalNotesApp(),
            ),
            name: 'home_light',
          ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await screenMatchesGolden(tester, 'home_light_theme');
    });

    testGoldens('Home page dark theme', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletPortrait]);

      await tester.pumpDeviceBuilder(
        builder
          ..addScenario(
            widget: ProviderScope(
              overrides: [
                themeControllerProvider.overrideWith((ref) {
                  final controller = ThemeController();
                  // Force dark theme
                  Future.microtask(() => controller.setTheme('dark'));
                  return controller;
                }),
              ],
              child: const LocalNotesApp(),
            ),
            name: 'home_dark',
          ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await screenMatchesGolden(tester, 'home_dark_theme');
    });

    testGoldens('Editor page light theme', (tester) async {
      final testNote = Note(
        id: 1,
        title: 'Sample Note',
        bodyMd: '''# Hello World

This is a **sample** note with *markdown* content.

## Features
- Live preview
- Theme support
- Auto-save

> This is a quote block

```dart
void main() {
  print('Hello, World!');
}
```

[Link example](https://example.com)
''',
        tags: ['test', 'markdown', 'sample'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.tabletLandscape]);

      await tester.pumpDeviceBuilder(
        builder
          ..addScenario(
            widget: ProviderScope(
              overrides: [
                themeControllerProvider.overrideWith((ref) {
                  final controller = ThemeController();
                  // Force light theme
                  Future.microtask(() => controller.setTheme('light'));
                  return controller;
                }),
              ],
              child: MaterialApp(
                home: NoteEditorPage(initialNote: testNote),
              ),
            ),
            name: 'editor_light',
          ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await screenMatchesGolden(tester, 'editor_light_theme');
    });

    testGoldens('Editor page dark theme', (tester) async {
      final testNote = Note(
        id: 1,
        title: 'Sample Note',
        bodyMd: '''# Hello World

This is a **sample** note with *markdown* content.

## Features
- Live preview
- Theme support
- Auto-save

> This is a quote block

```dart
void main() {
  print('Hello, World!');
}
```

[Link example](https://example.com)
''',
        tags: ['test', 'markdown', 'sample'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.tabletLandscape]);

      await tester.pumpDeviceBuilder(
        builder
          ..addScenario(
            widget: ProviderScope(
              overrides: [
                themeControllerProvider.overrideWith((ref) {
                  final controller = ThemeController();
                  // Force dark theme
                  Future.microtask(() => controller.setTheme('dark'));
                  return controller;
                }),
              ],
              child: MaterialApp(
                home: NoteEditorPage(initialNote: testNote),
              ),
            ),
            name: 'editor_dark',
          ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await screenMatchesGolden(tester, 'editor_dark_theme');
    });

    testGoldens('Editor mobile layout', (tester) async {
      final testNote = Note(
        id: 1,
        title: 'Mobile Test',
        bodyMd: '# Mobile Layout\n\nTesting mobile editor layout with tabs.',
        tags: ['mobile'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone]);

      await tester.pumpDeviceBuilder(
        builder
          ..addScenario(
            widget: ProviderScope(
              overrides: [
                themeControllerProvider.overrideWith((ref) {
                  final controller = ThemeController();
                  // Force light theme
                  Future.microtask(() => controller.setTheme('light'));
                  return controller;
                }),
              ],
              child: MaterialApp(
                home: NoteEditorPage(initialNote: testNote),
              ),
            ),
            name: 'editor_mobile',
          ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      await screenMatchesGolden(tester, 'editor_mobile_layout');
    });

    testGoldens('Theme selector dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => Consumer(
                            builder: (context, ref, child) {
                              final palette = ref.watch(currentPaletteProvider);
                              return AlertDialog(
                                title: const Text('Select Theme'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: const Text('Light'),
                                      leading: Icon(Icons.light_mode, color: palette.accent),
                                      onTap: () => Navigator.pop(context),
                                    ),
                                    ListTile(
                                      title: const Text('Dark'),
                                      leading: Icon(Icons.dark_mode, color: palette.accent),
                                      onTap: () => Navigator.pop(context),
                                    ),
                                    ListTile(
                                      title: const Text('Default'),
                                      leading: Icon(Icons.brightness_auto, color: palette.accent),
                                      onTap: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('Show Theme Selector'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Show Theme Selector'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'theme_selector_dialog');
    });
  });
}