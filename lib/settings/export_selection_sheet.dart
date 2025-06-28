import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_controller.dart';

class ExportSelectionSheet extends ConsumerStatefulWidget {
  final List<dynamic> notes;

  const ExportSelectionSheet({
    super.key,
    required this.notes,
  });

  @override
  ConsumerState<ExportSelectionSheet> createState() => _ExportSelectionSheetState();
}

class _ExportSelectionSheetState extends ConsumerState<ExportSelectionSheet> {
  final Set<int> _selectedNoteIds = <int>{};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Start with all notes selected
    _selectAll = true;
    _selectedNoteIds.addAll(widget.notes.map((note) => note.id as int));
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: palette.hint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Select Notes to Export',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: palette.primary)),
                ),
              ],
            ),
          ),
          
          // Select All toggle
          CheckboxListTile(
            title: Text(
              'Select All (${widget.notes.length} notes)',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: palette.onSurface,
              ),
            ),
            value: _selectAll,
            onChanged: (value) {
              setState(() {
                _selectAll = value ?? false;
                if (_selectAll) {
                  _selectedNoteIds.addAll(widget.notes.map((note) => note.id as int));
                } else {
                  _selectedNoteIds.clear();
                }
              });
            },
            activeColor: palette.primary,
            checkColor: palette.onPrimary,
          ),
          
          const Divider(),
          
          // Notes list
          Expanded(
            child: ListView.builder(
              itemCount: widget.notes.length,
              itemBuilder: (context, index) {
                final note = widget.notes[index];
                final isSelected = _selectedNoteIds.contains(note.id);
                
                return CheckboxListTile(
                  title: Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    style: TextStyle(
                      color: palette.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: note.body.isNotEmpty
                      ? Text(
                          note.body,
                          style: TextStyle(
                            color: palette.hint,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedNoteIds.add(note.id);
                      } else {
                        _selectedNoteIds.remove(note.id);
                      }
                      _selectAll = _selectedNoteIds.length == widget.notes.length;
                    });
                  },
                  activeColor: palette.primary,
                  checkColor: palette.onPrimary,
                );
              },
            ),
          ),
          
          // Export button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedNoteIds.isEmpty
                    ? null
                    : () {
                        final selectedNotes = widget.notes
                            .where((note) => _selectedNoteIds.contains(note.id))
                            .toList();
                        Navigator.of(context).pop(selectedNotes);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Export ${_selectedNoteIds.length} Notes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}