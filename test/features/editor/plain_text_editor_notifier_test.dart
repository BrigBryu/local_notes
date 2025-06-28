import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:local_notes/providers/notes_repository.dart';
import 'package:local_notes/domain/note.dart';
import 'package:local_notes/providers.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  group('NoteEditorNotifier', () {
    late MockNotesRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockNotesRepository();
      registerFallbackValue(Note(
        title: '',
        body: '',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      
      container = ProviderContainer(
        overrides: [
          notesRepositoryProvider.overrideWith(() => mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build() loads existing note correctly', () async {
      // Arrange
      const noteId = 1;
      final testNote = Note(
        id: noteId,
        title: 'Test Note',
        body: 'Test content',
        tags: ['tag1'],
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      when(() => mockRepository.getNoteById(noteId))
          .thenAnswer((_) async => testNote);

      // Act
      final result = await container.read(noteEditorProvider(noteId).future);

      // Assert
      expect(result.note, equals(testNote));
      expect(result.isDirty, false);
      expect(result.isNew, false);
      verify(() => mockRepository.getNoteById(noteId)).called(1);
    });

    test('build() creates new note for noteId -1', () async {
      // Arrange
      const noteId = -1;
      when(() => mockRepository.getNextUnnamedIndex())
          .thenAnswer((_) async => 5);

      // Act
      final result = await container.read(noteEditorProvider(noteId).future);

      // Assert
      expect(result.note.title, 'Unnamed Note 5');
      expect(result.note.body, '');
      expect(result.isDirty, false);
      expect(result.isNew, true);
      verify(() => mockRepository.getNextUnnamedIndex()).called(1);
    });

    test('updateTitle() mutates state correctly', () async {
      // Arrange
      const noteId = 1;
      final testNote = Note(
        id: noteId,
        title: 'Original Title',
        body: 'Test content',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRepository.getNoteById(noteId))
          .thenAnswer((_) async => testNote);

      final notifier = container.read(noteEditorProvider(noteId).notifier);
      await container.read(noteEditorProvider(noteId).future); // Initialize

      // Act
      notifier.updateTitle('New Title');

      // Assert
      final result = container.read(noteEditorProvider(noteId)).value!;
      expect(result.note.title, 'New Title');
      expect(result.isDirty, true);
      expect(result.isNew, false);
    });

    test('updateBody() mutates state correctly', () async {
      // Arrange
      const noteId = 1;
      final testNote = Note(
        id: noteId,
        title: 'Test Title',
        body: 'Original content',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRepository.getNoteById(noteId))
          .thenAnswer((_) async => testNote);

      final notifier = container.read(noteEditorProvider(noteId).notifier);
      await container.read(noteEditorProvider(noteId).future); // Initialize

      // Act
      notifier.updateBody('New content');

      // Assert
      final result = container.read(noteEditorProvider(noteId)).value!;
      expect(result.note.body, 'New content');
      expect(result.isDirty, true);
      expect(result.isNew, false);
    });

    test('save() persists new note correctly', () async {
      // Arrange
      const noteId = -1;
      when(() => mockRepository.getNextUnnamedIndex())
          .thenAnswer((_) async => 1);
      when(() => mockRepository.addNote(any()))
          .thenAnswer((_) async {});

      final notifier = container.read(noteEditorProvider(noteId).notifier);
      await container.read(noteEditorProvider(noteId).future); // Initialize
      
      notifier.updateTitle('Test Title');
      notifier.updateBody('Test Content');

      // Act
      await notifier.save();

      // Assert
      final result = container.read(noteEditorProvider(noteId)).value!;
      expect(result.isDirty, false);
      expect(result.isNew, false);
      verify(() => mockRepository.addNote(any())).called(1);
    });
  });
}