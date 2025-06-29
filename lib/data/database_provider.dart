import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/note.dart';

class DatabaseProvider {
  static const String _databaseName = 'notes.db';
  static const String _backupDatabaseName = 'notes_backup.db';
  static const int _databaseVersion = 3;
  
  static const String tableNotes = 'notes';
  static const String tableFts = 'notes_fts';
  static const String tableNoteVersions = 'note_versions';
  
  static Database? _database;
  static Database? _backupDatabase;
  static bool _hasFts5Support = false;
  
  DatabaseProvider._();
  static final DatabaseProvider instance = DatabaseProvider._();
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<Database> get backupDatabase async {
    _backupDatabase ??= await _initBackupDatabase();
    return _backupDatabase!;
  }
  
  Future<Database> _initBackupDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final backupPath = path.join(documentsDirectory.path, _backupDatabaseName);
    
    return await openDatabase(
      backupPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body_md TEXT NOT NULL,
        tags TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // Version history table for dual backup system
    await db.execute('''
      CREATE TABLE $tableNoteVersions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body_md TEXT NOT NULL,
        tags TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        version_created_at INTEGER NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES $tableNotes (id) ON DELETE CASCADE
      )
    ''');
    
    // Try to create FTS5 table, fall back gracefully if not supported
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE $tableFts USING fts5(
          title, 
          body_md, 
          content='$tableNotes', 
          content_rowid='id'
        )
      ''');
      _hasFts5Support = true;
    } catch (e) {
      print('FTS5 not available, falling back to basic search: $e');
      _hasFts5Support = false;
    }
    
    // Only create FTS triggers if FTS5 is supported
    if (_hasFts5Support) {
      await db.execute('''
        CREATE TRIGGER ${tableNotes}_ai AFTER INSERT ON $tableNotes BEGIN
          INSERT INTO $tableFts(rowid, title, body_md) VALUES (new.id, new.title, new.body_md);
        END
      ''');
      
      await db.execute('''
        CREATE TRIGGER ${tableNotes}_ad AFTER DELETE ON $tableNotes BEGIN
          INSERT INTO $tableFts($tableFts, rowid, title, body_md) VALUES('delete', old.id, old.title, old.body_md);
        END
      ''');
      
      await db.execute('''
        CREATE TRIGGER ${tableNotes}_au AFTER UPDATE ON $tableNotes BEGIN
          INSERT INTO $tableFts($tableFts, rowid, title, body_md) VALUES('delete', old.id, old.title, old.body_md);
          INSERT INTO $tableFts(rowid, title, body_md) VALUES (new.id, new.title, new.body_md);
        END
      ''');
    }
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2: No schema changes needed, body field name stays the same in DB for compatibility
    }
    if (oldVersion < 3) {
      // Version 3: Add note versions table for backup system
      await db.execute('''
        CREATE TABLE $tableNoteVersions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          note_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          body_md TEXT NOT NULL,
          tags TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          version_created_at INTEGER NOT NULL,
          is_current INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (note_id) REFERENCES $tableNotes (id) ON DELETE CASCADE
        )
      ''');
    }
  }
  
  Future<int> insertNote(Note note) async {
    final db = await database;
    final backupDb = await backupDatabase;
    
    try {
      // Insert into main database
      final noteId = await db.insert(tableNotes, note.toMap());
      
      // Create version record
      final versionData = {
        'note_id': noteId,
        'title': note.title,
        'body_md': note.body,
        'tags': note.tags.join(','),
        'created_at': note.createdAt.millisecondsSinceEpoch,
        'updated_at': note.updatedAt.millisecondsSinceEpoch,
        'version_created_at': DateTime.now().millisecondsSinceEpoch,
        'is_current': 1,
      };
      
      await db.insert(tableNoteVersions, versionData);
      
      // Backup to secondary database
      final noteWithId = note.copyWith(id: noteId);
      await backupDb.insert(tableNotes, noteWithId.toMap());
      await backupDb.insert(tableNoteVersions, versionData);
      
      return noteId;
    } catch (e) {
      print('Error inserting note: $e');
      rethrow;
    }
  }
  
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }
  
  Future<int> updateNote(Note note) async {
    final db = await database;
    final backupDb = await backupDatabase;
    
    try {
      // Store current version as backup before updating
      await _createBackupVersion(note.id!);
      
      // Update main database
      final result = await db.update(
        tableNotes,
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      
      // Create new current version record
      final versionData = {
        'note_id': note.id,
        'title': note.title,
        'body_md': note.body,
        'tags': note.tags.join(','),
        'created_at': note.createdAt.millisecondsSinceEpoch,
        'updated_at': note.updatedAt.millisecondsSinceEpoch,
        'version_created_at': DateTime.now().millisecondsSinceEpoch,
        'is_current': 1,
      };
      
      // Mark previous version as not current
      await db.update(
        tableNoteVersions,
        {'is_current': 0},
        where: 'note_id = ? AND is_current = 1',
        whereArgs: [note.id],
      );
      
      // Insert new current version
      await db.insert(tableNoteVersions, versionData);
      
      // Update backup database
      await backupDb.update(
        tableNotes,
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      
      await backupDb.update(
        tableNoteVersions,
        {'is_current': 0},
        where: 'note_id = ? AND is_current = 1',
        whereArgs: [note.id],
      );
      
      await backupDb.insert(tableNoteVersions, versionData);
      
      return result;
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }
  
  Future<void> _createBackupVersion(int noteId) async {
    final db = await database;
    
    // Get current note data
    final currentNotes = await db.query(
      tableNotes,
      where: 'id = ?',
      whereArgs: [noteId],
    );
    
    if (currentNotes.isNotEmpty) {
      final currentNote = currentNotes.first;
      
      // Create backup version record
      final backupData = {
        'note_id': noteId,
        'title': currentNote['title'],
        'body_md': currentNote['body_md'],
        'tags': currentNote['tags'],
        'created_at': currentNote['created_at'],
        'updated_at': currentNote['updated_at'],
        'version_created_at': DateTime.now().millisecondsSinceEpoch,
        'is_current': 0,
      };
      
      await db.insert(tableNoteVersions, backupData);
      
      // Clean up old versions (keep only last 2 per note)
      await _cleanupOldVersions(noteId);
    }
  }
  
  Future<void> _cleanupOldVersions(int noteId) async {
    final db = await database;
    
    // Keep only the most recent 3 versions (current + 2 backups)
    await db.execute('''
      DELETE FROM $tableNoteVersions 
      WHERE note_id = ? AND id NOT IN (
        SELECT id FROM $tableNoteVersions 
        WHERE note_id = ? 
        ORDER BY version_created_at DESC 
        LIMIT 3
      )
    ''', [noteId, noteId]);
  }
  
  Future<int> deleteNote(int id) async {
    final db = await database;
    final backupDb = await backupDatabase;
    
    try {
      // Store final backup before deletion
      await _createBackupVersion(id);
      
      // Delete from main database (CASCADE will handle versions)
      final result = await db.delete(
        tableNotes,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Delete versions from main database
      await db.delete(
        tableNoteVersions,
        where: 'note_id = ?',
        whereArgs: [id],
      );
      
      // Delete from backup database
      await backupDb.delete(
        tableNotes,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await backupDb.delete(
        tableNoteVersions,
        where: 'note_id = ?',
        whereArgs: [id],
      );
      
      return result;
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }
  
  Future<List<Note>> searchNotes(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getAllNotes();
    }
    
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (_hasFts5Support) {
      // Use FTS5 for fast full-text search
      maps = await db.rawQuery('''
        SELECT n.* FROM $tableNotes n
        INNER JOIN $tableFts fts ON n.id = fts.rowid
        WHERE $tableFts MATCH ?
        ORDER BY rank
      ''', [keyword]);
    } else {
      // Fallback to basic LIKE search when FTS5 is not available
      final searchTerm = '%${keyword.toLowerCase()}%';
      maps = await db.rawQuery('''
        SELECT * FROM $tableNotes
        WHERE LOWER(title) LIKE ? OR LOWER(body_md) LIKE ?
        ORDER BY updated_at DESC
      ''', [searchTerm, searchTerm]);
    }
    
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<void> close() async {
    final db = _database;
    final backupDb = _backupDatabase;
    
    if (db != null) {
      await db.close();
      _database = null;
    }
    
    if (backupDb != null) {
      await backupDb.close();
      _backupDatabase = null;
    }
  }
  
  Future<int> getNextUnnamedIndex() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT MAX(CAST(SUBSTR(title, 13) AS INTEGER)) as max_index 
      FROM $tableNotes 
      WHERE title LIKE 'Unnamed Note %'
    ''');
    
    final maxIndex = result.first['max_index'] as int?;
    return (maxIndex ?? 0) + 1;
  }

  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, _databaseName);
    final backupPath = path.join(documentsDirectory.path, _backupDatabaseName);
    
    final file = File(dbPath);
    final backupFile = File(backupPath);
    
    if (await file.exists()) {
      await file.delete();
    }
    
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    
    _database = null;
    _backupDatabase = null;
  }
  
  // Get previous version of a note
  Future<Note?> getPreviousVersion(int noteId) async {
    final db = await database;
    
    final versions = await db.query(
      tableNoteVersions,
      where: 'note_id = ? AND is_current = 0',
      whereArgs: [noteId],
      orderBy: 'version_created_at DESC',
      limit: 1,
    );
    
    if (versions.isNotEmpty) {
      final versionData = versions.first;
      return Note(
        id: versionData['note_id'] as int,
        title: versionData['title'] as String,
        body: versionData['body_md'] as String,
        tags: (versionData['tags'] as String).split(',').where((tag) => tag.isNotEmpty).toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(versionData['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(versionData['updated_at'] as int),
      );
    }
    
    return null;
  }
  
  // Restore from backup database if main is corrupted
  Future<bool> restoreFromBackup() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDirectory.path, _databaseName);
      final backupPath = path.join(documentsDirectory.path, _backupDatabaseName);
      
      final mainFile = File(dbPath);
      final backupFile = File(backupPath);
      
      if (await backupFile.exists()) {
        // Close current databases
        await close();
        
        // Copy backup to main
        await backupFile.copy(dbPath);
        
        // Reinitialize
        _database = null;
        _backupDatabase = null;
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }
}