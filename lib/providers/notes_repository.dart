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
}

final notesRepositoryProvider = AsyncNotifierProvider<NotesRepository, List<Note>>(() {
  return NotesRepository();
});