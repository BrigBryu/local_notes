import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        type: FileType.custom,
        allowedExtensions: ['zip', 'txt', 'md', 'json'],
        dialogTitle: 'Select notes files to import',
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
      final exportedFiles = await exportService.createTextFiles(selectedNotes: selectedNotes);
      
      if (context.mounted) {
        if (Platform.isIOS) {
          // On iOS, show share sheet immediately
          final shareSuccess = await exportService.shareExportFiles(exportFiles: exportedFiles);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(shareSuccess 
                  ? 'Exported ${selectedNotes.length} note${selectedNotes.length > 1 ? 's' : ''} successfully!'
                  : 'Export completed but sharing failed'),
              backgroundColor: shareSuccess ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // On Android, maintain existing behavior with first file path
          final firstFile = exportedFiles.isNotEmpty ? exportedFiles.first : null;
          final exportDir = firstFile?.parent.path ?? 'Unknown location';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exported ${selectedNotes.length} note${selectedNotes.length > 1 ? 's' : ''} successfully!'),
                  const SizedBox(height: 4),
                  Text(
                    'Location: $exportDir',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'COPY PATH',
                textColor: Colors.white,
                onPressed: () => _copyPathToClipboard(context, exportDir),
              ),
            ),
          );
        }
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

  Future<void> _copyPathToClipboard(BuildContext context, String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Path copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}