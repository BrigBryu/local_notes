import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import 'package:local_notes/features/editor/plain_text_editor_screen.dart';
import 'package:local_notes/domain/note.dart';
import 'package:local_notes/theme/theme_controller.dart';
import 'package:local_notes/theme/color_palette.dart';
import 'package:local_notes/providers/notes_repository.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  group('PlainTextEditorScreen Golden Tests', () {
    late MockNotesRepository mockRepository;

    setUp(() {
      mockRepository = MockNotesRepository();
    });

    testGoldens('displays note content correctly', (tester) async {
      // Arrange
      const noteId = 1;
      final testNote = Note(
        id: noteId,
        title: 'Sample Note Title',
        body: 'This is the content of the note.\nIt has multiple lines.\n\nAnd paragraphs.',
        tags: ['work', 'important'],
        createdAt: DateTime(2023, 6, 15, 10, 30),
        updatedAt: DateTime(2023, 6, 15, 14, 45),
      );

      when(() => mockRepository.getNoteById(noteId))
          .thenAnswer((_) async => testNote);

      final widget = ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWith(() => mockRepository),
          // Override theme to ensure consistent golden test results
          currentPaletteProvider.overrideWith((ref) => _getTestPalette()),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          home: const PlainTextEditorScreen(noteId: noteId),
        ),
      );

      // Act & Assert
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812), // iPhone X dimensions
      );
      
      // Wait for the async provider to load
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'plain_text_editor_screen_with_content');
    });

    testGoldens('displays loading state correctly', (tester) async {
      // Arrange
      const noteId = 1;
      
      // Make repository delay to test loading state
      when(() => mockRepository.getNoteById(noteId))
          .thenAnswer((_) => Future.delayed(
            const Duration(seconds: 10),
            () => Note(
              id: noteId,
              title: 'Test',
              body: 'Test',
              tags: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ));

      final widget = ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWith(() => mockRepository),
          currentPaletteProvider.overrideWith((ref) => _getTestPalette()),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          home: const PlainTextEditorScreen(noteId: noteId),
        ),
      );

      // Act & Assert
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      
      // Don't wait for settle - we want to capture loading state
      await tester.pump();

      await screenMatchesGolden(tester, 'plain_text_editor_screen_loading');
    });

    testGoldens('displays error state correctly', (tester) async {
      // Arrange
      const noteId = 999; // Non-existent note
      
      when(() => mockRepository.getNoteById(noteId))
          .thenThrow(Exception('Note not found'));

      final widget = ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWith(() => mockRepository),
          currentPaletteProvider.overrideWith((ref) => _getTestPalette()),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          home: const PlainTextEditorScreen(noteId: noteId),
        ),
      );

      // Act & Assert
      await tester.pumpWidgetBuilder(
        widget,
        surfaceSize: const Size(375, 812),
      );
      
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'plain_text_editor_screen_error');
    });
  });
}

// Helper function to provide consistent theme for golden tests
ColorPalette _getTestPalette() {
  return const ColorPalette(
    name: "Test Theme",
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    primary: Color(0xFF2196F3),
    primaryVariant: Color(0xFF1976D2),
    secondary: Color(0xFF03DAC6),
    secondaryVariant: Color(0xFF018786),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    onBackground: Color(0xFF000000),
    onSurface: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
    accent: Color(0xFF2196F3),
    divider: Color(0xFFE0E0E0),
    shadow: Color(0xFF000000),
    error: Color(0xFFB00020),
    disabled: Color(0xFF9E9E9E),
    hint: Color(0xFF757575),
  );
}