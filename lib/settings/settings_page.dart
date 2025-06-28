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
        border: Border.all(color: palette.outline, width: 1),
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
      int importedCount = 0;
      
      for (final file in result.files) {
        if (file.path != null) {
          final success = await importService.importFile(File(file.path!));
          if (success) importedCount++;
        }
      }
      
      // Refresh notes list
      ref.invalidate(notesRepositoryProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $importedCount of ${result.files.length} files'),
            backgroundColor: Colors.green,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${selectedNotes.length} notes to ${exportedFile.path}'),
            backgroundColor: Colors.green,
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
}