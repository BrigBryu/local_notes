import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../providers/notes_repository.dart';

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(ref.read(notesRepositoryProvider.notifier));
});

class ImportService {
  final dynamic notesRepository;

  ImportService(this.notesRepository);

  Future<int> importFile(File file) async {
    try {
      if (kDebugMode) {
        print('Importing file: ${file.path}');
      }
      
      // Run heavy I/O operations in isolate
      final results = await Isolate.run(() => _processFileInIsolate(file));
      
      if (results != null && results.isNotEmpty) {
        // Add notes to the repository
        int importedCount = 0;
        for (final result in results) {
          try {
            await notesRepository.createNote(
              title: result['title'] as String,
              body: result['body'] as String,
              tags: (result['tags'] as List<dynamic>).cast<String>(),
            );
            importedCount++;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to import note: ${result['title']}, error: $e');
            }
          }
        }
        return importedCount;
      }
      
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Import error: $e');
      }
      return 0;
    }
  }

  static List<Map<String, dynamic>>? _processFileInIsolate(File file) {
    try {
      final extension = path.extension(file.path).toLowerCase();
      
      switch (extension) {
        case '.zip':
          return _processZipFile(file);
        case '.txt':
          final content = file.readAsStringSync();
          final result = _processTextFile(file, content);
          return result != null ? [result] : null;
        case '.md':
          final content = file.readAsStringSync();
          final result = _processMarkdownFile(file, content);
          return result != null ? [result] : null;
        case '.json':
          final content = file.readAsStringSync();
          final result = _processJsonFile(content);
          return result != null ? [result] : null;
        default:
          // Try to read as text for unknown file types
          final content = file.readAsStringSync();
          final result = _processTextFile(file, content);
          return result != null ? [result] : null;
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

  static List<Map<String, dynamic>>? _processZipFile(File file) {
    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final notes = <Map<String, dynamic>>[];
      
      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.txt')) {
          // Skip the summary file
          if (file.name.contains('_export_summary.txt')) {
            continue;
          }
          
          final content = utf8.decode(file.content as List<int>);
          final note = _parseExportedNoteContent(file.name, content);
          if (note != null) {
            notes.add(note);
          }
        }
      }
      
      return notes.isNotEmpty ? notes : null;
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _parseExportedNoteContent(String fileName, String content) {
    try {
      final lines = content.split('\n');
      String title = '';
      String body = '';
      List<String> tags = [];
      
      bool inBody = false;
      bool inMetadata = false;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        if (i == 0 && !line.startsWith('=') && !line.startsWith('-')) {
          // First line is likely the title
          title = line.trim();
          continue;
        }
        
        if (line.startsWith('=') || line.startsWith('-')) {
          // Skip separator lines
          continue;
        }
        
        if (line.trim() == '---') {
          // Start of metadata section
          inMetadata = true;
          inBody = false;
          continue;
        }
        
        if (inMetadata) {
          if (line.startsWith('Tags: ')) {
            final tagStr = line.substring(6).trim();
            if (tagStr.isNotEmpty) {
              tags = tagStr.split(', ').map((tag) => tag.trim()).toList();
            }
          }
          continue;
        }
        
        if (line.startsWith('Tags: ')) {
          final tagStr = line.substring(6).trim();
          if (tagStr.isNotEmpty) {
            tags = tagStr.split(', ').map((tag) => tag.trim()).toList();
          }
          continue;
        }
        
        // Everything else is body content
        if (!inMetadata && line.trim().isNotEmpty) {
          if (body.isNotEmpty) {
            body += '\n';
          }
          body += line;
        }
      }
      
      // If no title was found, use filename
      if (title.isEmpty) {
        title = path.basenameWithoutExtension(fileName);
      }
      
      return {
        'title': title,
        'body': body.trim(),
        'tags': tags,
      };
    } catch (e) {
      return null;
    }
  }
}