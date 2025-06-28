import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../theme/theme_controller.dart';
import '../providers/notes_repository.dart';
import 'theme_gallery_page.dart';
import 'settings_tile.dart';
import 'export_selection_sheet.dart';
import '../services/import_service.dart';
import '../services/export_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final themeState = ref.watch(themeControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: palette.surface,
        foregroundColor: palette.onSurface,
      ),
      body: ListView(
        children: [
          SettingsTile(
            title: 'Themes',
            subtitle: themeState.isLoading ? 'Loading...' : themeState.palette.name,
            leading: _buildThemePreviewSwatches(palette),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemeGalleryPage()),
            ),
          ),
          const Divider(),
          SettingsTile(
            title: 'Import Notes',
            subtitle: 'Import notes from files',
            leading: Icon(Icons.download, color: palette.primary),
            onTap: () => _importNotes(context, ref),
          ),
          SettingsTile(
            title: 'Export Notes',
            subtitle: 'Export selected notes',
            leading: Icon(Icons.upload, color: palette.primary),
            onTap: () => _exportNotes(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreviewSwatches(dynamic palette) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.divider, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(color: palette.secondary),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importNotes(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        dialogTitle: 'Select files to import',
      );
      
      if (result == null) return;
      
      final importService = ref.read(importServiceProvider);
      int totalNotesImported = 0;
      int filesProcessed = 0;
      
      for (final file in result.files) {
        if (file.path != null) {
          final notesImported = await importService.importFile(File(file.path!));
          totalNotesImported += notesImported;
          if (notesImported > 0) filesProcessed++;
        }
      }
      
      // Refresh notes list
      ref.invalidate(notesRepositoryProvider);
      
      if (context.mounted) {
        final message = totalNotesImported > 0
            ? 'Imported $totalNotesImported notes from $filesProcessed of ${result.files.length} files'
            : 'No notes could be imported from the selected files';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: totalNotesImported > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportNotes(BuildContext context, WidgetRef ref) async {
    try {
      final notesAsync = ref.read(notesRepositoryProvider);
      final notes = notesAsync.valueOrNull;
      
      if (notes == null || notes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No notes to export')),
          );
        }
        return;
      }

      // Show selection sheet
      final selectedNotes = await showModalBottomSheet<List<dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => ExportSelectionSheet(notes: notes),
      );

      if (selectedNotes == null || selectedNotes.isEmpty) return;

      final exportService = ref.read(exportServiceProvider);
      final exportedFile = await exportService.createZip(selectedNotes: selectedNotes);
      
      if (context.mounted) {
        final friendlyPath = _getFriendlyPath(exportedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exported ${selectedNotes.length} notes successfully!'),
                const SizedBox(height: 4),
                Text(
                  'Location: $friendlyPath',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => _showExportPathDialog(context, exportedFile.path, friendlyPath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFriendlyPath(String fullPath) {
    final fileName = fullPath.split('/').last;
    
    // Convert technical path to user-friendly description
    if (fullPath.contains('/storage/emulated/0/Download') || fullPath.contains('/sdcard/Download')) {
      return 'Downloads/LocalNotes/$fileName';
    } else if (fullPath.contains('/storage/emulated/0/LocalNotes')) {
      return 'LocalNotes/$fileName (in device storage)';
    } else if (fullPath.contains('/Android/data/')) {
      return 'App Files/LocalNotes/$fileName (restricted access)';
    } else if (fullPath.contains('app_flutter')) {
      return 'App Documents/$fileName (hidden)';
    } else {
      // Just show the filename if path structure is unknown
      return fileName;
    }
  }

  void _showExportPathDialog(BuildContext context, String fullPath, String friendlyPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your notes have been exported to:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Friendly Path:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friendlyPath,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Full Path:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fullPath,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can find this file using your device\'s file manager app.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}