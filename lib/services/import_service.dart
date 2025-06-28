import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../providers/notes_repository.dart';

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.read(notesRepositoryProvider.notifier));
});

class ImportService {
  final dynamic notesRepository;

  ImportService(this.notesRepository);

  Future<bool> importFile(File file) async {
    try {
      if (kDebugMode) {
        print('Importing file: ${file.path}');
      }
      
      // Run heavy I/O operations in isolate
      final result = await Isolate.run(() => _processFileInIsolate(file));
      
      if (result != null) {
        // Add the note to the repository
        await notesRepository.createNote(
          title: result['title'] as String,
          body: result['body'] as String,
          tags: (result['tags'] as List<dynamic>).cast<String>(),
        );
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Import error: $e');
      }
      return false;
    }
  }

  static Map<String, dynamic>? _processFileInIsolate(File file) {
    try {
      final extension = path.extension(file.path).toLowerCase();
      final content = file.readAsStringSync();
      
      switch (extension) {
        case '.txt':
          return _processTextFile(file, content);
        case '.md':
          return _processMarkdownFile(file, content);
        case '.json':
          return _processJsonFile(content);
        default:
          // Try to read as text for unknown file types
          return _processTextFile(file, content);
      }
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _processTextFile(File file, String content) {
    final fileName = path.basenameWithoutExtension(file.path);
    final lines = content.split('\n');
    
    // First line as title if it looks like a title, otherwise use filename
    String title = fileName;
    String body = content;
    
    if (lines.isNotEmpty && lines.first.length < 100 && !lines.first.contains('\n')) {
      title = lines.first.trim();
      if (lines.length > 1) {
        body = lines.skip(1).join('\n').trim();
      } else {
        body = '';
      }
    }
    
    return {
      'title': title,
      'body': body,
      'tags': <String>[],
    };
  }

  static Map<String, dynamic> _processMarkdownFile(File file, String content) {
    final fileName = path.basenameWithoutExtension(file.path);
    final lines = content.split('\n');
    
    String title = fileName;
    String body = content;
    List<String> tags = [];
    
    // Look for markdown title (# Title)
    if (lines.isNotEmpty && lines.first.startsWith('# ')) {
      title = lines.first.substring(2).trim();
      if (lines.length > 1) {
        body = lines.skip(1).join('\n').trim();
      } else {
        body = '';
      }
    }
    
    // Extract tags from content (basic #tag extraction)
    final tagRegex = RegExp(r'#(\w+)');
    final matches = tagRegex.allMatches(content);
    tags = matches.map((match) => match.group(1)!).toSet().toList();
    
    return {
      'title': title,
      'body': body,
      'tags': tags,
    };
  }

  static Map<String, dynamic> _processJsonFile(String content) {
    try {
      final data = jsonDecode(content);
      
      if (data is Map<String, dynamic>) {
        return {
          'title': data['title'] ?? 'Imported Note',
          'body': data['body'] ?? data['content'] ?? '',
          'tags': (data['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[],
        };
      } else if (data is List) {
        // If it's an array, take the first item or concatenate
        if (data.isNotEmpty && data.first is Map) {
          final first = data.first as Map<String, dynamic>;
          return {
            'title': first['title'] ?? 'Imported Notes',
            'body': first['body'] ?? first['content'] ?? '',
            'tags': (first['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[],
          };
        }
      }
      
      // Fallback: convert to string
      return {
        'title': 'Imported JSON',
        'body': content,
        'tags': <String>[],
      };
    } catch (e) {
      // If JSON parsing fails, treat as text
      return {
        'title': 'Imported Data',
        'body': content,
        'tags': <String>[],
      };
    }
  }
}