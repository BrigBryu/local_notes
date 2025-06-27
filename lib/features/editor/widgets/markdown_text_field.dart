import 'package:flutter/material.dart';
import '../../../theme/color_palette.dart';

class MarkdownTextField extends StatelessWidget {
  final TextEditingController controller;
  final ColorPalette palette;
  final String? hintText;
  final VoidCallback? onChanged;

  const MarkdownTextField({
    super.key,
    required this.controller,
    required this.palette,
    this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.divider),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: palette.onSurface,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hintText ?? 'Start typing your markdown here...',
          hintStyle: TextStyle(
            color: palette.hint,
            fontFamily: 'monospace',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          fillColor: palette.surface,
          filled: true,
        ),
        onChanged: onChanged != null ? (_) => onChanged!() : null,
        cursorColor: palette.primary,
        selectionControls: MaterialTextSelectionControls(),
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
          if (!isFocused) return null;
          return Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Text(
              '$currentLength characters',
              style: TextStyle(
                color: palette.hint,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}