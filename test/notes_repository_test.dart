import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_notes/domain/note.dart';
import 'package:local_notes/data/database_provider.dart';

class TestDatabaseProvider {
  static Database? _testDatabase;
  
  TestDatabaseProvider._();
  static final TestDatabaseProvider instance = TestDatabaseProvider._();
  
  @override
  Future<Database> get database async {
    _testDatabase ??= await _initTestDatabase();
    return _testDatabase!;
  }
  
  Future<Database> _initTestDatabase() async {
    return await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body_md TEXT NOT NULL,
        tags TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE VIRTUAL TABLE notes_fts USING fts5(
        title, 
        body_md, 
        content='notes', 
        content_rowid='id'
      )
    ''');
    
    await db.execute('''
      CREATE TRIGGER notes_ai AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, title, body_md) VALUES (new.id, new.title, new.body_md);
      END
    ''');
    
    await db.execute('''
      CREATE TRIGGER notes_ad AFTER DELETE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, body_md) VALUES('delete', old.id, old.title, old.body_md);
      END
    ''');
    
    await db.execute('''
      CREATE TRIGGER notes_au AFTER UPDATE ON notes BEGIN
        INSERT INTO notes_fts(notes_fts, rowid, title, body_md) VALUES('delete', old.id, old.title, old.body_md);
        INSERT INTO notes_fts(rowid, title, body_md) VALUES (new.id, new.title, new.body_md);
      END
    ''');
  }
  
  @override
  Future<void> close() async {
    final db = _testDatabase;
    if (db != null) {
      await db.close();
      _testDatabase = null;
    }
  }
  
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }
  
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
  
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
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
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }
  
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
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
      SELECT n.* FROM notes n
      INNER JOIN notes_fts fts ON n.id = fts.rowid
      WHERE notes_fts MATCH ?
      ORDER BY rank
    ''', [keyword]);
    
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }
}

void main() {
  late TestDatabaseProvider databaseProvider;
  
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  
  setUp(() {
    databaseProvider = TestDatabaseProvider.instance;
  });
  
  tearDown(() async {
    await databaseProvider.close();
  });

  group('Notes Repository Tests', () {
    test('should insert and retrieve a note', () async {
      final note = Note(
        title: 'Test Note',
        bodyMd: 'This is a test note content.',
        tags: ['test', 'flutter'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await databaseProvider.insertNote(note);
      expect(id, greaterThan(0));

      final retrievedNote = await databaseProvider.getNoteById(id);
      expect(retrievedNote, isNotNull);
      expect(retrievedNote!.title, equals(note.title));
      expect(retrievedNote.bodyMd, equals(note.bodyMd));
    });

    test('should update a note', () async {
      final note = Note(
        title: 'Original Title',
        bodyMd: 'Original content',
        tags: ['original'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await databaseProvider.insertNote(note);
      final updatedNote = note.copyWith(
        id: id,
        title: 'Updated Title',
        updatedAt: DateTime.now(),
      );

      await databaseProvider.updateNote(updatedNote);
      final retrievedNote = await databaseProvider.getNoteById(id);
      
      expect(retrievedNote!.title, equals('Updated Title'));
    });

    test('should delete a note', () async {
      final note = Note(
        title: 'Note to Delete',
        bodyMd: 'This note will be deleted.',
        tags: ['delete'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await databaseProvider.insertNote(note);
      await databaseProvider.deleteNote(id);
      
      final retrievedNote = await databaseProvider.getNoteById(id);
      expect(retrievedNote, isNull);
    });

    test('performance test: 1000 notes insertion and search under 50ms', () async {
      final random = Random();
      final words = [
        'flutter', 'dart', 'mobile', 'development', 'app', 'widget', 'state',
        'async', 'future', 'stream', 'riverpod', 'provider', 'sqlite', 'database',
        'search', 'performance', 'test', 'unit', 'integration', 'ui', 'ux',
        'design', 'material', 'cupertino', 'animation', 'transition', 'responsive',
        'cross-platform', 'native', 'hybrid', 'web', 'desktop', 'ios', 'android'
      ];

      // Insert 1000 notes
      final insertStopwatch = Stopwatch()..start();
      final futures = <Future<int>>[];
      
      for (int i = 0; i < 1000; i++) {
        final title = 'Note ${i + 1}: ${words[random.nextInt(words.length)]} ${words[random.nextInt(words.length)]}';
        final bodyContent = List.generate(
          5 + random.nextInt(10),
          (index) => words[random.nextInt(words.length)]
        ).join(' ');
        
        final note = Note(
          title: title,
          bodyMd: bodyContent,
          tags: List.generate(
            1 + random.nextInt(3), 
            (index) => words[random.nextInt(words.length)]
          ),
          createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
          updatedAt: DateTime.now().subtract(Duration(hours: random.nextInt(24))),
        );
        
        futures.add(databaseProvider.insertNote(note));
      }
      
      await Future.wait(futures);
      insertStopwatch.stop();
      
      print('Inserted 1000 notes in ${insertStopwatch.elapsedMilliseconds}ms');

      // Perform 10 different searches and measure each
      final searchKeywords = ['flutter', 'dart', 'mobile', 'app', 'test', 'performance', 'state', 'database', 'search', 'widget'];
      
      for (final keyword in searchKeywords) {
        final searchStopwatch = Stopwatch()..start();
        final results = await databaseProvider.searchNotes(keyword);
        searchStopwatch.stop();
        
        final searchTime = searchStopwatch.elapsedMilliseconds;
        print('Search for "$keyword" returned ${results.length} results in ${searchTime}ms');
        
        // Assert search time is under 50ms
        expect(searchTime, lessThan(50), reason: 'Search for "$keyword" took ${searchTime}ms, expected < 50ms');
      }

      // Test retrieving all notes
      final getAllStopwatch = Stopwatch()..start();
      final allNotes = await databaseProvider.getAllNotes();
      getAllStopwatch.stop();
      
      expect(allNotes.length, equals(1000));
      print('Retrieved all 1000 notes in ${getAllStopwatch.elapsedMilliseconds}ms');
    });

    test('should search notes with FTS5', () async {
      final notes = [
        Note(
          title: 'Flutter Development Guide',
          bodyMd: 'Learn how to build mobile apps with Flutter framework.',
          tags: ['flutter', 'mobile'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Note(
          title: 'Dart Programming',
          bodyMd: 'Master Dart language for Flutter development.',
          tags: ['dart', 'programming'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Note(
          title: 'Database Design',
          bodyMd: 'SQLite database optimization techniques.',
          tags: ['database', 'sqlite'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final note in notes) {
        await databaseProvider.insertNote(note);
      }

      // Search by title
      final flutterResults = await databaseProvider.searchNotes('Flutter');
      expect(flutterResults.length, greaterThanOrEqualTo(1));
      expect(flutterResults.first.title, contains('Flutter'));

      // Search by body content
      final dartResults = await databaseProvider.searchNotes('Dart');
      expect(dartResults.length, greaterThanOrEqualTo(1)); // Found in at least one note

      // Search by partial word
      final devResults = await databaseProvider.searchNotes('development');
      expect(devResults.length, greaterThanOrEqualTo(1));
    });

    test('should handle empty search gracefully', () async {
      final note = Note(
        title: 'Test Note',
        bodyMd: 'Content',
        tags: ['test'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await databaseProvider.insertNote(note);

      final emptyResults = await databaseProvider.searchNotes('');
      expect(emptyResults.length, equals(1));

      final whitespaceResults = await databaseProvider.searchNotes('   ');
      expect(whitespaceResults.length, equals(1));
    });
  });
}