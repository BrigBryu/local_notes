import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notes_repository.dart';
import '../../domain/note.dart';

class PlainTextNoteState {
  final Note note;
  final bool isDirty;
  final bool isNew;

  const PlainTextNoteState({
    required this.note,
    required this.isDirty,
    required this.isNew,
  });

  PlainTextNoteState copyWith({
    Note? note,
    bool? isDirty,
    bool? isNew,
  }) {
    return PlainTextNoteState(
      note: note ?? this.note,
      isDirty: isDirty ?? this.isDirty,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlainTextNoteState &&
        other.note == note &&
        other.isDirty == isDirty &&
        other.isNew == isNew;
  }

  @override
  int get hashCode => note.hashCode ^ isDirty.hashCode ^ isNew.hashCode;
}

class NoteEditorNotifier extends FamilyAsyncNotifier<PlainTextNoteState, int> {
  Timer? _autoSaveTimer;
  
  @override
  Future<PlainTextNoteState> build(int noteId) async {
    // Keep alive if note should survive backgrounding
    ref.keepAlive();
    
    final repository = ref.read(notesRepositoryProvider.notifier);
    
    if (noteId == -1) {
      // Create new note
      final nextIndex = await repository.getNextUnnamedIndex();
      final newNote = Note(
        title: 'Unnamed Note $nextIndex',
        body: '',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return PlainTextNoteState(
        note: newNote,
        isDirty: false,
        isNew: true,
      );
    } else {
      // Load existing note
      final note = await repository.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note with id $noteId not found');
      }
      
      return PlainTextNoteState(
        note: note,
        isDirty: false,
        isNew: false,
      );
    }
  }

  void updateTitle(String newTitle) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedNote = currentState.note.copyWith(title: newTitle);
    final newState = currentState.copyWith(
      note: updatedNote,
      isDirty: true,
    );
    
    state = AsyncValue.data(newState);
    
    if (!newState.isNew) {
      _scheduleAutoSave();
    }
  }

  void updateBody(String newBody) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedNote = currentState.note.copyWith(body: newBody);
    final newState = currentState.copyWith(
      note: updatedNote,
      isDirty: true,
    );
    
    state = AsyncValue.data(newState);
    
    if (!newState.isNew) {
      _scheduleAutoSave();
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 300), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    final currentState = state.value;
    if (currentState == null || !currentState.isDirty || currentState.isNew) {
      return;
    }
    
    await save();
  }

  Future<void> save() async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final repository = ref.read(notesRepositoryProvider.notifier);
      final noteToSave = currentState.note.copyWith(
        updatedAt: DateTime.now(),
      );

      if (currentState.isNew) {
        await repository.addNote(noteToSave);
        // Refresh the notes list after first save
        ref.invalidate(notesRepositoryProvider);
        
        state = AsyncValue.data(currentState.copyWith(
          note: noteToSave,
          isDirty: false,
          isNew: false,
        ));
      } else {
        await repository.updateNote(noteToSave);
        state = AsyncValue.data(currentState.copyWith(
          note: noteToSave,
          isDirty: false,
        ));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void cleanup() {
    _autoSaveTimer?.cancel();
  }
}