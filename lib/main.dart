import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/theme_controller.dart';
import 'features/editor/plain_text_editor_screen.dart';
import 'providers/notes_repository.dart';
import 'settings/theme_gallery_page.dart';

void main() {
  runApp(const ProviderScope(child: LocalNotesApp()));
}

class LocalNotesApp extends ConsumerWidget {
  const LocalNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(currentThemeDataProvider);
    final isLoading = ref.watch(isThemeLoadingProvider);
    
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Local Notes',
      theme: themeData,
      home: const NotesHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotesHomePage extends ConsumerWidget {
  const NotesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final notesAsync = ref.watch(notesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette, color: palette.accent),
            onPressed: () => _navigateToThemeGallery(context),
            tooltip: 'Themes',
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) => notes.isEmpty
            ? _buildEmptyState(palette)
            : _buildNotesList(notes, palette),
        loading: () => Center(
          child: CircularProgressIndicator(color: palette.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: palette.error),
              const SizedBox(height: 16),
              Text(
                'Error loading notes',
                style: TextStyle(color: palette.error),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: palette.hint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(context),
        backgroundColor: palette.accent,
        foregroundColor: palette.onPrimary,
        tooltip: 'Create new note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(dynamic palette) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 96,
            color: palette.disabled,
          ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: palette.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first note',
            style: TextStyle(
              fontSize: 16,
              color: palette.hint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<dynamic> notes, dynamic palette) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: palette.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.body,
                    style: TextStyle(color: palette.onBackground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: note.tags.take(3).map((tag) => Chip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.onPrimary,
                        ),
                      ),
                      backgroundColor: palette.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Updated ${_formatDate(note.updatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.hint,
                  ),
                ),
              ],
            ),
            onTap: () => _navigateToEditor(context, note: note),
            trailing: Icon(
              Icons.chevron_right,
              color: palette.hint,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToEditor(BuildContext context, {dynamic note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlainTextEditorScreen(
          noteId: note?.id ?? -1,
        ),
      ),
    );
  }

  void _navigateToThemeGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThemeGalleryPage(),
      ),
    );
  }
}