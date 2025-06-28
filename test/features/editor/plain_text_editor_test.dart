import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notes/features/editor/plain_text_editor_page.dart';
import 'package:local_notes/domain/note.dart';

void main() {
  group('PlainTextEditorPage Widget Tests', () {
    testWidgets('displays new note editor correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const PlainTextEditorPage(),
          ),
        ),
      );

      // Wait for initial loading
      await tester.pumpAndSettle();

      // Check that the app bar exists with back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Check that full-screen text field exists
      expect(find.byType(TextField), findsWidgets);
      
      // Check that title area exists (should be tappable)
      expect(find.text('Untitled'), findsOneWidget);
    });

    testWidgets('displays existing note data correctly', (tester) async {
      final testNote = Note(
        id: 1,
        title: 'Test Note',
        body: 'This is plain text content.',
        tags: ['test'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PlainTextEditorPage(initialNote: testNote),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that the title is displayed
      expect(find.text('Test Note'), findsOneWidget);
    });

    testWidgets('allows editing title when tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const PlainTextEditorPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the title to edit it
      await tester.tap(find.text('Untitled'));
      await tester.pumpAndSettle();

      // Should now show a text field for editing title
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('shows save button for new notes when dirty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const PlainTextEditorPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no save button should be visible
      expect(find.byIcon(Icons.save), findsNothing);

      // Type in the body text field to make it dirty
      final bodyField = find.byType(TextField).last;
      await tester.enterText(bodyField, 'Some content');
      await tester.pumpAndSettle();

      // Save button should now appear
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows back navigation confirmation when dirty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const PlainTextEditorPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type in the body text field to make it dirty
      final bodyField = find.byType(TextField).last;
      await tester.enterText(bodyField, 'Some content');
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
    });
  });

  group('PlainTextEditorNotifier Tests', () {
    test('initializes with correct state', () async {
      final container = ProviderContainer();
      
      final notifier = container.read(
        AsyncNotifierProvider<PlainTextEditorNotifier, PlainTextNoteState>(
          () => PlainTextEditorNotifier(),
        ).notifier,
      );
      
      await notifier.build();
      
      final state = container.read(
        AsyncNotifierProvider<PlainTextEditorNotifier, PlainTextNoteState>(
          () => PlainTextEditorNotifier(),
        ),
      );
      
      expect(state.hasValue, true);
      expect(state.value?.isNew, true);
      expect(state.value?.isDirty, false);
      
      container.dispose();
    });
  });
}