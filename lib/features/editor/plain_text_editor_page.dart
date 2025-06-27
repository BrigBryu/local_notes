import 'dart:async';
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
  
  @override
  Future<PlainTextNoteState> build() async {
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
    if (existingNote != null) {
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
    await state.whenData((currentState) async {
      if (currentState.isDirty && !currentState.isNew) {
        await _saveNote(currentState);
      }
    });
  }

  Future<void> saveNote() async {
    await state.whenData((currentState) async {
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

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
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
    Note? noteToLoad;
    
    if (widget.initialNote != null) {
      noteToLoad = widget.initialNote;
    } else if (widget.noteId != null) {
      final repository = ref.read(notesRepositoryProvider.notifier);
      noteToLoad = await repository.getNoteById(widget.noteId!);
    }
    
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
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
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
    if (_isEditingTitle) {
      _titleController.text = state.note.title;
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
          state.note.title.isEmpty ? 'Untitled' : state.note.title,
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
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _bodyController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
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