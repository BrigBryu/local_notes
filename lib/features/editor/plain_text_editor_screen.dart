import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../theme/theme_controller.dart';

class PlainTextEditorScreen extends ConsumerStatefulWidget {
  final int noteId;

  const PlainTextEditorScreen({
    super.key,
    required this.noteId,
  });

  @override
  ConsumerState<PlainTextEditorScreen> createState() => _PlainTextEditorScreenState();
}

class _PlainTextEditorScreenState extends ConsumerState<PlainTextEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isEditingTitle = false;
  bool _controllersInitialized = false;

  @override
  void dispose() {
    if (_controllersInitialized) {
      _titleController.dispose();
      _bodyController.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(String title, String body) {
    if (!_controllersInitialized) {
      _titleController = TextEditingController(text: title);
      _bodyController = TextEditingController(text: body);
      _controllersInitialized = true;
    } else {
      // Update controllers if content has changed
      if (_titleController.text != title) {
        _titleController.text = title;
      }
      if (_bodyController.text != body) {
        _bodyController.text = body;
      }
    }
  }

  Future<bool> _onWillPop() async {
    final editorState = ref.read(noteEditorProvider(widget.noteId));
    
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
    final editorState = ref.watch(noteEditorProvider(widget.noteId));
    
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
            data: (state) {
              _initializeControllers(state.note.title, state.note.body);
              return _buildTitleWidget(state, palette);
            },
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Error'),
          ),
          actions: editorState.when(
            data: (state) => [
              if (state.isNew && state.isDirty)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    await ref.read(noteEditorProvider(widget.noteId).notifier).save();
                  },
                  tooltip: 'Save',
                ),
            ],
            loading: () => [],
            error: (_, __) => [],
          ),
        ),
        body: editorState.when(
          data: (state) {
            _initializeControllers(state.note.title, state.note.body);
            return _buildEditor(state, palette);
          },
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

  Widget _buildTitleWidget(dynamic state, dynamic palette) {
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
          ref.read(noteEditorProvider(widget.noteId).notifier).updateTitle(value.trim());
          setState(() => _isEditingTitle = false);
        },
        onEditingComplete: () {
          ref.read(noteEditorProvider(widget.noteId).notifier).updateTitle(_titleController.text.trim());
          setState(() => _isEditingTitle = false);
        },
      );
    } else {
      return GestureDetector(
        onTap: () => setState(() => _isEditingTitle = true),
        child: Text(
          _controllersInitialized && _titleController.text.isNotEmpty 
              ? _titleController.text 
              : 'Untitled',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }
  }

  Widget _buildEditor(dynamic state, dynamic palette) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Semantics(
        label: 'Note content editor',
        multiline: true,
        textField: true,
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
            ref.read(noteEditorProvider(widget.noteId).notifier).updateBody(value);
          },
        ),
      ),
    );
  }
}