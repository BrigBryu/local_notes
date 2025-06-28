import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/note.dart';
import '../../providers/notes_repository.dart';
import '../../theme/theme_controller.dart';

class PlainTextNoteState {
  final Note note;
  final bool isDirty;
  final bool isNew;

  const PlainTextNoteState({
    required this.note,
    required this.isDirty,
    required this.isNew,
  });

  PlainTextNoteState copyWith({
    Note? note,
    bool? isDirty,
    bool? isNew,
  }) {
    return PlainTextNoteState(
      note: note ?? this.note,
      isDirty: isDirty ?? this.isDirty,
      isNew: isNew ?? this.isNew,
    );
  }
}

class PlainTextEditorNotifier extends AsyncNotifier<PlainTextNoteState> {
  Timer? _autoSaveTimer;
  bool _hasBeenInitialized = false;
  
  @override
  Future<PlainTextNoteState> build() async {
    if (kDebugMode) print('DEBUG: PlainTextEditorNotifier.build() called - hasBeenInitialized: $_hasBeenInitialized');
    // Don't create default state if we've already been initialized
    if (_hasBeenInitialized) {
      if (kDebugMode) print('DEBUG: Already initialized, returning current state');
      return state.value ?? PlainTextNoteState(
        note: Note(
          title: '',
          body: '',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        isDirty: false,
        isNew: true,
      );
    }
    
    if (kDebugMode) print('DEBUG: Creating initial empty state');
    return PlainTextNoteState(
      note: Note(
        title: '',
        body: '',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      isDirty: false,
      isNew: true,
    );
  }

  Future<void> initializeWithNote(Note? existingNote) async {
    if (kDebugMode) print('DEBUG: initializeWithNote called with existingNote: $existingNote');
    _hasBeenInitialized = true;
    if (existingNote != null) {
      if (kDebugMode) print('DEBUG: Setting state with existing note');
      state = AsyncValue.data(PlainTextNoteState(
        note: existingNote,
        isDirty: false,
        isNew: false,
      ));
    } else {
      // Create new note with auto-generated title
      final repository = ref.read(notesRepositoryProvider.notifier);
      final nextIndex = await repository.getNextUnnamedIndex();
      final newNote = Note(
        title: 'Unnamed Note $nextIndex',
        body: '',
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      state = AsyncValue.data(PlainTextNoteState(
        note: newNote,
        isDirty: false,
        isNew: true,
      ));
    }
  }

  void updateTitle(String newTitle) {
    state.whenData((currentState) {
      final updatedNote = currentState.note.copyWith(title: newTitle);
      final newState = currentState.copyWith(
        note: updatedNote,
        isDirty: true,
      );
      state = AsyncValue.data(newState);
      
      if (!newState.isNew) {
        _scheduleAutoSave();
      }
    });
  }

  void updateBody(String newBody) {
    state.whenData((currentState) {
      final updatedNote = currentState.note.copyWith(body: newBody);
      final newState = currentState.copyWith(
        note: updatedNote,
        isDirty: true,
      );
      state = AsyncValue.data(newState);
      
      if (!newState.isNew) {
        _scheduleAutoSave();
      }
    });
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 300), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    state.whenData((currentState) async {
      if (currentState.isDirty && !currentState.isNew) {
        await _saveNote(currentState);
      }
    });
  }

  Future<void> saveNote() async {
    state.whenData((currentState) async {
      await _saveNote(currentState);
    });
  }

  Future<void> _saveNote(PlainTextNoteState currentState) async {
    try {
      final repository = ref.read(notesRepositoryProvider.notifier);
      final noteToSave = currentState.note.copyWith(
        updatedAt: DateTime.now(),
      );

      if (currentState.isNew) {
        await repository.addNote(noteToSave);
        // Refresh the notes list after first save
        ref.invalidate(notesRepositoryProvider);
        
        state = AsyncValue.data(currentState.copyWith(
          note: noteToSave,
          isDirty: false,
          isNew: false,
        ));
      } else {
        await repository.updateNote(noteToSave);
        state = AsyncValue.data(currentState.copyWith(
          note: noteToSave,
          isDirty: false,
        ));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void cleanup() {
    _autoSaveTimer?.cancel();
  }
}

class PlainTextEditorPage extends ConsumerStatefulWidget {
  final int? noteId;
  final Note? initialNote;

  const PlainTextEditorPage({
    super.key,
    this.noteId,
    this.initialNote,
  });

  @override
  ConsumerState<PlainTextEditorPage> createState() => _PlainTextEditorPageState();
}

class _PlainTextEditorPageState extends ConsumerState<PlainTextEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isEditingTitle = false;
  
  late AsyncNotifierProvider<PlainTextEditorNotifier, PlainTextNoteState> _editorProvider;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    
    _editorProvider = AsyncNotifierProvider<PlainTextEditorNotifier, PlainTextNoteState>(
      () => PlainTextEditorNotifier(),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeNote();
    });
  }

  Future<void> _initializeNote() async {
    if (kDebugMode) print('DEBUG: _initializeNote called');
    Note? noteToLoad;
    
    if (kDebugMode) print('DEBUG: widget.initialNote: ${widget.initialNote}');
    if (kDebugMode) print('DEBUG: widget.noteId: ${widget.noteId}');
    
    if (widget.initialNote != null) {
      noteToLoad = widget.initialNote;
      if (kDebugMode) print('DEBUG: Using widget.initialNote');
    } else if (widget.noteId != null) {
      if (kDebugMode) print('DEBUG: Loading note by ID: ${widget.noteId}');
      final repository = ref.read(notesRepositoryProvider.notifier);
      noteToLoad = await repository.getNoteById(widget.noteId!);
      if (kDebugMode) print('DEBUG: Loaded note: $noteToLoad');
    } else {
      if (kDebugMode) print('DEBUG: No note to load - creating new note');
    }
    
    if (kDebugMode) print('DEBUG: About to call initializeWithNote with: $noteToLoad');
    await ref.read(_editorProvider.notifier).initializeWithNote(noteToLoad);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final editorState = ref.read(_editorProvider);
    
    return editorState.when(
      data: (state) async {
        if (state.isDirty && state.isNew) {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text('You have unsaved changes. Are you sure you want to exit without saving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ) ?? false;
        }
        return true;
      },
      loading: () => true,
      error: (_, __) => true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final editorState = ref.watch(_editorProvider);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop() && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: editorState.when(
            data: (state) => _buildTitleWidget(state, palette),
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Error'),
          ),
          actions: editorState.when(
            data: (state) => [
              if (state.isNew && state.isDirty)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    await ref.read(_editorProvider.notifier).saveNote();
                  },
                  tooltip: 'Save',
                ),
            ],
            loading: () => [],
            error: (_, __) => [],
          ),
        ),
        body: editorState.when(
          data: (state) => _buildEditor(state, palette),
          loading: () => Center(
            child: CircularProgressIndicator(color: palette.primary),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWidget(PlainTextNoteState state, palette) {
    // Set the title controller text if it doesn't match the current state
    if (_titleController.text != state.note.title) {
      _titleController.text = state.note.title;
    }
    
    if (kDebugMode) print('DEBUG: _buildTitleWidget - controller.text: "${_titleController.text}", state.note.title: "${state.note.title}", isEditing: $_isEditingTitle');
    
    if (_isEditingTitle) {
      return TextField(
        controller: _titleController,
        autofocus: true,
        style: Theme.of(context).textTheme.titleLarge,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Note title',
        ),
        onSubmitted: (value) {
          ref.read(_editorProvider.notifier).updateTitle(value.trim());
          setState(() => _isEditingTitle = false);
        },
        onEditingComplete: () {
          ref.read(_editorProvider.notifier).updateTitle(_titleController.text.trim());
          setState(() => _isEditingTitle = false);
        },
      );
    } else {
      return GestureDetector(
        onTap: () => setState(() => _isEditingTitle = true),
        child: Text(
          _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }
  }

  Widget _buildEditor(PlainTextNoteState state, palette) {
    // Set the body controller text if it doesn't match the current state
    if (_bodyController.text != state.note.body) {
      _bodyController.text = state.note.body;
    }
    
    if (kDebugMode) print('DEBUG: _buildEditor - controller.text: "${_bodyController.text}", state.note.body: "${state.note.body}"');
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _bodyController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start writing...',
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: (value) {
          ref.read(_editorProvider.notifier).updateBody(value);
        },
      ),
    );
  }
}