import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_provider.dart';
import '../domain/note.dart';

class NotesRepository extends AsyncNotifier<List<Note>> {
  late DatabaseProvider _databaseProvider;

  @override
  Future<List<Note>> build() async {
    _databaseProvider = DatabaseProvider.instance;
    return await _databaseProvider.getAllNotes();
  }

  Future<void> addNote(Note note) async {
    state = const AsyncValue.loading();
    try {
      await _databaseProvider.insertNote(note);
      final notes = await _databaseProvider.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      // Try backup restore if main database fails
      print('Error adding note, attempting backup restore: $error');
      final restored = await _databaseProvider.restoreFromBackup();
      if (restored) {
        try {
          await _databaseProvider.insertNote(note);
          final notes = await _databaseProvider.getAllNotes();
          state = AsyncValue.data(notes);
          return;
        } catch (e) {
          print('Failed even after backup restore: $e');
        }
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateNote(Note note) async {
    state = const AsyncValue.loading();
    try {
      await _databaseProvider.updateNote(note);
      final notes = await _databaseProvider.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      // Try backup restore if main database fails
      print('Error updating note, attempting backup restore: $error');
      final restored = await _databaseProvider.restoreFromBackup();
      if (restored) {
        try {
          await _databaseProvider.updateNote(note);
          final notes = await _databaseProvider.getAllNotes();
          state = AsyncValue.data(notes);
          return;
        } catch (e) {
          print('Failed even after backup restore: $e');
        }
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteNote(int id) async {
    state = const AsyncValue.loading();
    try {
      await _databaseProvider.deleteNote(id);
      final notes = await _databaseProvider.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      // Try backup restore if main database fails
      print('Error deleting note, attempting backup restore: $error');
      final restored = await _databaseProvider.restoreFromBackup();
      if (restored) {
        try {
          await _databaseProvider.deleteNote(id);
          final notes = await _databaseProvider.getAllNotes();
          state = AsyncValue.data(notes);
          return;
        } catch (e) {
          print('Failed even after backup restore: $e');
        }
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Note>> searchNotes(String keyword) async {
    try {
      return await _databaseProvider.searchNotes(keyword);
    } catch (error) {
      rethrow;
    }
  }

  Future<Note?> getNoteById(int id) async {
    try {
      return await _databaseProvider.getNoteById(id);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> refreshNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _databaseProvider.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<int> getNextUnnamedIndex() async {
    try {
      return await _databaseProvider.getNextUnnamedIndex();
    } catch (error) {
      rethrow;
    }
  }
  
  // Get previous version of a note for recovery
  Future<Note?> getPreviousVersion(int noteId) async {
    try {
      return await _databaseProvider.getPreviousVersion(noteId);
    } catch (error) {
      print('Error getting previous version: $error');
      return null;
    }
  }
  
  // Auto-save with enhanced error handling
  Future<bool> autoSaveNote(Note note) async {
    try {
      if (note.id == null) {
        await _databaseProvider.insertNote(note);
      } else {
        await _databaseProvider.updateNote(note);
      }
      return true;
    } catch (error) {
      print('Auto-save failed: $error');
      // Don't update state on auto-save failure to avoid UI disruption
      return false;
    }
  }
  
  // Force save with backup restore if needed
  Future<void> forceSaveNote(Note note) async {
    try {
      if (note.id == null) {
        await addNote(note);
      } else {
        await updateNote(note);
      }
    } catch (error) {
      print('Force save failed: $error');
      rethrow;
    }
  }
}

final notesRepositoryProvider = AsyncNotifierProvider<NotesRepository, List<Note>>(() {
  return NotesRepository();
});