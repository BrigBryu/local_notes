import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/note.dart';
import '../../providers/notes_repository.dart';
import '../../theme/theme_controller.dart';
import 'widgets/markdown_text_field.dart';
import 'widgets/markdown_preview.dart';
import 'widgets/editor_toolbar.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  final int? noteId;
  final Note? initialNote;

  const NoteEditorPage({
    super.key,
    this.noteId,
    this.initialNote,
  });

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage>
    with AutomaticKeepAliveClientMixin {
  
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _tagsController;
  Timer? _debounceTimer;
  
  Note? _currentNote;
  bool _hasChanges = false;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadNote();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _tagsController = TextEditingController();

    // Add listeners for auto-save
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
    _tagsController.addListener(_onTextChanged);
  }

  Future<void> _loadNote() async {
    if (widget.initialNote != null) {
      _setNoteData(widget.initialNote!);
    } else if (widget.noteId != null) {
      setState(() => _isLoading = true);
      try {
        final repository = ref.read(notesRepositoryProvider.notifier);
        final note = await repository.getNoteById(widget.noteId!);
        if (note != null) {
          _setNoteData(note);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading note: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      // Create new note
      _setNoteData(Note(
        title: '',
        body: '',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  void _setNoteData(Note note) {
    setState(() {
      _currentNote = note;
      _titleController.text = note.title;
      _bodyController.text = note.body;
      _tagsController.text = note.tags.join(', ');
      _hasChanges = false;
    });
  }

  void _onTextChanged() {
    setState(() => _hasChanges = true);
    
    // More aggressive auto-save with shorter debounce
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _autoSaveNote();
    });
  }

  // Auto-save with gentle error handling
  Future<void> _autoSaveNote() async {
    if (!_hasChanges || _currentNote == null) return;

    try {
      final updatedNote = _currentNote!.copyWith(
        title: _titleController.text.trim(),
        body: _bodyController.text,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(notesRepositoryProvider.notifier);
      
      bool success = false;
      if (_currentNote!.id == null) {
        // For new notes, use regular add (creates ID)
        await repository.addNote(updatedNote);
        success = true;
      } else {
        // For existing notes, use auto-save (gentler)
        success = await repository.autoSaveNote(updatedNote);
      }

      if (success) {
        setState(() {
          _currentNote = updatedNote;
          _hasChanges = false;
        });
      }
    } catch (e) {
      // Don't show error for auto-save failures - they're silent
      print('Auto-save failed: $e');
    }
  }
  
  // Manual save with full error handling
  Future<void> _saveNote() async {
    if (!_hasChanges || _currentNote == null) return;

    try {
      final updatedNote = _currentNote!.copyWith(
        title: _titleController.text.trim(),
        body: _bodyController.text,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(notesRepositoryProvider.notifier);
      
      if (_currentNote!.id == null) {
        await repository.addNote(updatedNote);
      } else {
        await repository.forceSaveNote(updatedNote);
      }

      setState(() {
        _currentNote = updatedNote;
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _saveNote,
            ),
          ),
        );
      }
    }
  }

  void _insertMarkdown(String markdown) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      markdown,
    );
    
    _bodyController.value = _bodyController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + markdown.length,
      ),
    );
  }

  @override
  void dispose() {
    // Force save any remaining changes before disposal
    if (_hasChanges && _currentNote != null) {
      _saveNote();
    }
    
    _debounceTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final palette = ref.watch(currentPaletteProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 768;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentNote?.title.isEmpty == true 
            ? 'New Note' 
            : _currentNote?.title ?? 'Note Editor'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showVersionHistory,
            tooltip: 'Version History',
          ),
          IconButton(
            icon: Icon(Icons.palette, color: palette.accent),
            onPressed: () => _showThemeSelector(context),
            tooltip: 'Change Theme',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: palette.primary),
            )
          : _buildEditorLayout(isTablet, palette),
    );
  }

  Widget _buildEditorLayout(bool isTablet, palette) {
    if (isTablet) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildEditorPanel(palette),
          ),
          VerticalDivider(color: palette.divider, width: 1),
          Expanded(
            flex: 1,
            child: _buildPreviewPanel(palette),
          ),
        ],
      );
    } else {
      return OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(child: _buildEditorPanel(palette)),
                VerticalDivider(color: palette.divider, width: 1),
                Expanded(child: _buildPreviewPanel(palette)),
              ],
            );
          } else {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: palette.primary,
                    unselectedLabelColor: palette.hint,
                    indicatorColor: palette.primary,
                    tabs: const [
                      Tab(text: 'Edit', icon: Icon(Icons.edit)),
                      Tab(text: 'Preview', icon: Icon(Icons.visibility)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildEditorPanel(palette),
                        _buildPreviewPanel(palette),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildEditorPanel(palette) {
    return Column(
      children: [
        // Title field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: palette.divider),
              ),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        // Tags field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'Tags (comma separated)',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: palette.divider),
              ),
            ),
          ),
        ),
        
        // Toolbar
        EditorToolbar(
          onInsertMarkdown: _insertMarkdown,
          palette: palette,
        ),
        
        // Markdown text field
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MarkdownTextField(
              controller: _bodyController,
              palette: palette,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(palette) {
    return MarkdownPreview(
      content: _bodyController.text,
      palette: palette,
    );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Icon(Icons.light_mode),
              onTap: () {
                ref.read(themeControllerProvider.notifier).setTheme('light');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Icon(Icons.dark_mode),
              onTap: () {
                ref.read(themeControllerProvider.notifier).setTheme('dark');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Default'),
              leading: Icon(Icons.brightness_auto),
              onTap: () {
                ref.read(themeControllerProvider.notifier).setTheme('default');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showVersionHistory() {
    if (_currentNote?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save note first to view history')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version History'),
        content: FutureBuilder<Note?>(
          future: ref.read(notesRepositoryProvider.notifier).getPreviousVersion(_currentNote!.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            
            final previousVersion = snapshot.data;
            if (previousVersion == null) {
              return const Text('No previous version available');
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Previous version:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Title: ${previousVersion.title}'),
                const SizedBox(height: 4),
                Text('Updated: ${previousVersion.updatedAt}'),
                const SizedBox(height: 8),
                Text('Content preview:', style: Theme.of(context).textTheme.titleSmall),
                Container(
                  height: 100,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(previousVersion.body),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final repository = ref.read(notesRepositoryProvider.notifier);
              final previousVersion = await repository.getPreviousVersion(_currentNote!.id!);
              if (previousVersion != null) {
                _setNoteData(previousVersion);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restored previous version')),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}