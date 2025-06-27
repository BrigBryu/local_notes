import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/note.dart';

class DatabaseProvider {
  static const String _databaseName = 'notes.db';
  static const int _databaseVersion = 2;
  
  static const String tableNotes = 'notes';
  static const String tableFts = 'notes_fts';
  
  static Database? _database;
  
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
    
    await db.execute('''
      CREATE VIRTUAL TABLE $tableFts USING fts5(
        title, 
        body_md, 
        content='$tableNotes', 
        content_rowid='id'
      )
    ''');
    
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
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2: No schema changes needed, bodyMd field name stays the same in DB for compatibility
    }
  }
  
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert(tableNotes, note.toMap());
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
    return await db.update(
      tableNotes,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }
  
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<List<Note>> searchNotes(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getAllNotes();
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT n.* FROM $tableNotes n
      INNER JOIN $tableFts fts ON n.id = fts.rowid
      WHERE $tableFts MATCH ?
      ORDER BY rank
    ''', [keyword]);
    
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
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
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
  }
}