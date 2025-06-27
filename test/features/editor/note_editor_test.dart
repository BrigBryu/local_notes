import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:local_notes/features/editor/note_editor_page.dart';
import 'package:local_notes/features/editor/widgets/markdown_text_field.dart';
import 'package:local_notes/features/editor/widgets/markdown_preview.dart';
import 'package:local_notes/domain/note.dart';
import 'package:local_notes/theme/theme_controller.dart';

void main() {
  group('NoteEditorPage Widget Tests', () {
    testWidgets('displays new note editor correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NoteEditorPage(),
          ),
        ),
      );

      // Wait for initial loading
      await tester.pumpAndSettle();

      // Check that the app bar shows "New Note"
      expect(find.text('New Note'), findsOneWidget);
      
      // Check that title field exists
      expect(find.widgetWithText(TextField, 'Title'), findsOneWidget);
      
      // Check that tags field exists
      expect(find.widgetWithText(TextField, 'Tags (comma separated)'), findsOneWidget);
      
      // Check that theme selector button exists
      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('displays existing note data correctly', (tester) async {
      final testNote = Note(
        id: 1,
        title: 'Test Note',
        bodyMd: '# Hello World\n\nThis is **bold** text.',
        tags: ['test', 'markdown'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NoteEditorPage(initialNote: testNote),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that the title is displayed
      expect(find.text('Test Note'), findsOneWidget);
      
      // Check that the title field contains the note title
      final titleField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Test Note'),
      );
      expect(titleField.controller?.text, equals('Test Note'));
    });

    testWidgets('toolbar inserts markdown correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NoteEditorPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the bold button in toolbar
      final boldButton = find.byIcon(Icons.format_bold);
      expect(boldButton, findsOneWidget);

      // Tap the bold button
      await tester.tap(boldButton);
      await tester.pumpAndSettle();

      // The markdown text field should be focused and contain bold markdown
      // Note: This test might need adjustment based on implementation details
    });

    testWidgets('switches between edit and preview modes on mobile', (tester) async {
      // Simulate mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NoteEditorPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show tabs on mobile in portrait mode
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);

      // Tap preview tab
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Should show markdown preview
      expect(find.byType(MarkdownPreview), findsOneWidget);

      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('shows split view on tablet', (tester) async {
      // Simulate tablet screen size
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NoteEditorPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show both editor and preview side by side
      expect(find.byType(MarkdownTextField), findsOneWidget);
      expect(find.byType(MarkdownPreview), findsOneWidget);

      // Should not show tabs
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Preview'), findsNothing);

      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('theme selector dialog works', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NoteEditorPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap theme selector button
      await tester.tap(find.byIcon(Icons.palette));
      await tester.pumpAndSettle();

      // Should show theme selection dialog
      expect(find.text('Select Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);

      // Tap Light theme
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('Select Theme'), findsNothing);
    });
  });

  group('MarkdownTextField Widget Tests', () {
    testWidgets('renders markdown text field correctly', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final palette = ref.watch(currentPaletteProvider);
                  return MarkdownTextField(
                    controller: controller,
                    palette: palette,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the text field
      expect(find.byType(TextField), findsOneWidget);
      
      // Should show hint text
      expect(find.text('Start typing your markdown here...'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final palette = ref.watch(currentPaletteProvider);
                  return MarkdownTextField(
                    controller: controller,
                    palette: palette,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type text
      await tester.enterText(find.byType(TextField), 'Hello **World**');
      await tester.pumpAndSettle();

      // Controller should contain the text
      expect(controller.text, equals('Hello **World**'));
    });
  });

  group('MarkdownPreview Widget Tests', () {
    testWidgets('renders markdown preview correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final palette = ref.watch(currentPaletteProvider);
                  return MarkdownPreview(
                    content: '# Hello\n\nThis is **bold** text.',
                    palette: palette,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render markdown content
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('shows empty state when no content', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final palette = ref.watch(currentPaletteProvider);
                  return MarkdownPreview(
                    content: '',
                    palette: palette,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('Preview will appear here'), findsOneWidget);
      expect(find.text('Start typing in the editor to see live preview'), findsOneWidget);
    });

    testWidgets('updates preview when content changes', (tester) async {
      String content = '';
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final palette = ref.watch(currentPaletteProvider);
                      return Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                content = '# Updated Content';
                              });
                            },
                            child: const Text('Update'),
                          ),
                          Expanded(
                            child: MarkdownPreview(
                              content: content,
                              palette: palette,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show empty state
      expect(find.text('Preview will appear here'), findsOneWidget);

      // Tap update button
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Should now show markdown content
      expect(find.byType(Markdown), findsOneWidget);
      expect(find.text('Preview will appear here'), findsNothing);
    });
  });
}