import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class ExportService {
  Future<List<File>> createTextFiles({required List<dynamic> selectedNotes}) async {
    try {
      if (kDebugMode) {
        print('Exporting ${selectedNotes.length} notes as individual .txt files');
      }
      
      // Get accessible export directory with timestamp
      final directory = await _getExportDirectory();
      
      // Ensure directory exists
      await directory.create(recursive: true);
      
      final exportedFiles = <File>[];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      for (final note in selectedNotes) {
        final fileName = _createFileName(note.title);
        final timestampedFileName = '${timestamp}_$fileName';
        final txtFile = File(path.join(directory.path, timestampedFileName));
        
        // Ensure we're getting the most recent version
        final content = _formatNoteContent(note, includeVersionInfo: true);
        
        // Write with atomic operation
        final tempFile = File('${txtFile.path}.tmp');
        await tempFile.writeAsString(content);
        await tempFile.rename(txtFile.path);
        
        exportedFiles.add(txtFile);
        
        if (kDebugMode) {
          print('Created: ${txtFile.path}');
        }
      }
      
      // Create backup manifest
      await _createBackupManifest(directory, exportedFiles, timestamp);
      
      if (kDebugMode) {
        print('Export complete: ${exportedFiles.length} files created');
      }
      
      return exportedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('Export error: $e');
      }
      rethrow;
    }
  }

  Future<bool> shareExportFiles({required List<File> exportFiles}) async {
    try {
      if (Platform.isIOS) {
        // Use iOS native share sheet for multiple files
        final xFiles = exportFiles.map((file) => XFile(file.path)).toList();
        final result = await Share.shareXFiles(
          xFiles,
          text: 'Local Notes Export - ${exportFiles.length} note${exportFiles.length > 1 ? 's' : ''}',
          subject: 'Notes Backup - ${DateTime.now().toString().split(' ')[0]}',
        );
        return result.status == ShareResultStatus.success;
      } else {
        // For Android, use the existing file path approach
        // This maintains the current Android behavior unchanged
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Share error: $e');
      }
      return false;
    }
  }

  static String _createFileName(String title) {
    if (title.isEmpty) return 'untitled.txt';
    
    // Replace invalid filename characters
    String fileName = title
        .replaceAll(RegExp(r'[<>:"/|?*\\]'), '_')  // Invalid filename chars
        .replaceAll(RegExp(r'\s+'), '_')           // Multiple spaces to single underscore
        .replaceAll(RegExp(r'_+'), '_')            // Multiple underscores to single
        .replaceAll(RegExp(r'^_|_$'), '');         // Remove leading/trailing underscores
    
    if (fileName.isEmpty) fileName = 'untitled';
    
    // Limit length (leaving room for .txt extension)
    if (fileName.length > 100) {
      fileName = fileName.substring(0, 100);
    }
    
    return '$fileName.txt';
  }

  static String _formatNoteContent(dynamic note, {bool includeVersionInfo = false}) {
    final buffer = StringBuffer();
    
    // Title
    if (note.title.isNotEmpty) {
      buffer.writeln(note.title);
      buffer.writeln('=' * note.title.length);
      buffer.writeln();
    }
    
    // Body
    if (note.body.isNotEmpty) {
      buffer.writeln(note.body);
      buffer.writeln();
    }
    
    // Tags
    if (note.tags != null && (note.tags as List).isNotEmpty) {
      buffer.writeln('Tags: ${(note.tags as List<String>).join(', ')}');
      buffer.writeln();
    }
    
    // Metadata
    buffer.writeln('---');
    buffer.writeln('Created: ${note.createdAt}');
    buffer.writeln('Updated: ${note.updatedAt}');
    if (note.id != null) {
      buffer.writeln('ID: ${note.id}');
    }
    
    if (includeVersionInfo) {
      buffer.writeln('Exported: ${DateTime.now()}');
      buffer.writeln('Export Version: LATEST');
      buffer.writeln('Backup Status: DUAL_BACKUP_ENABLED');
    }
    
    return buffer.toString();
  }


  static Future<Directory> _getExportDirectory() async {
    // Use app's documents directory - guaranteed to work and accessible via Files app
    final documentsDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final exportDir = Directory(path.join(documentsDir.path, 'exports', timestamp));
    
    if (kDebugMode) {
      print('Using app documents directory: ${exportDir.path}');
    }
    
    return exportDir;
  }
  
  static Future<void> _createBackupManifest(Directory exportDir, List<File> exportedFiles, int timestamp) async {
    final manifestFile = File(path.join(exportDir.path, 'backup_manifest.json'));
    
    final manifest = {
      'backup_timestamp': timestamp,
      'backup_date': DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String(),
      'notes_count': exportedFiles.length,
      'files': exportedFiles.map((f) => {
        'filename': path.basename(f.path),
        'size_bytes': f.lengthSync(),
      }).toList(),
      'backup_type': 'FULL_EXPORT_WITH_DUAL_BACKUP',
      'app_version': '1.0.0+1',
    };
    
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest)
    );
  }

  static Future<bool> _canCreateDirectory(Directory dir) async {
    try {
      await dir.create(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }
}