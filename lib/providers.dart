import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/editor/plain_text_editor_notifier.dart';

// Re-export the notes repository provider
export 'providers/notes_repository.dart' show notesRepositoryProvider;

// Global provider for note editing, parameterized by noteId
final noteEditorProvider = AsyncNotifierProvider.family<
    NoteEditorNotifier,
    PlainTextNoteState,
    int>(
  () => NoteEditorNotifier(),
);