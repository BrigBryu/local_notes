import 'package:flutter/material.dart';
import '../../../theme/color_palette.dart';

class EditorToolbar extends StatelessWidget {
  final Function(String) onInsertMarkdown;
  final ColorPalette palette;

  const EditorToolbar({
    super.key,
    required this.onInsertMarkdown,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.divider),
          bottom: BorderSide(color: palette.divider),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Bold',
              onPressed: () => onInsertMarkdown('**bold text**'),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Italic',
              onPressed: () => onInsertMarkdown('*italic text*'),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.format_strikethrough,
              tooltip: 'Strikethrough',
              onPressed: () => onInsertMarkdown('~~strikethrough~~'),
              palette: palette,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.title,
              tooltip: 'Heading',
              onPressed: () => onInsertMarkdown('# Heading'),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.format_quote,
              tooltip: 'Quote',
              onPressed: () => onInsertMarkdown('> Quote'),
              palette: palette,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Bullet List',
              onPressed: () => onInsertMarkdown('- List item'),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered List',
              onPressed: () => onInsertMarkdown('1. List item'),
              palette: palette,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.link,
              tooltip: 'Link',
              onPressed: () => onInsertMarkdown('[link text](url)'),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.image,
              tooltip: 'Image',
              onPressed: () => onInsertMarkdown('![alt text](image_url)'),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.code,
              tooltip: 'Inline Code',
              onPressed: () => onInsertMarkdown('`code`'),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.code_outlined,
              tooltip: 'Code Block',
              onPressed: () => onInsertMarkdown('```\ncode block\n```'),
              palette: palette,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.table_chart,
              tooltip: 'Table',
              onPressed: () => onInsertMarkdown(
                '| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |'
              ),
              palette: palette,
            ),
            _ToolbarButton(
              icon: Icons.horizontal_rule,
              tooltip: 'Horizontal Rule',
              onPressed: () => onInsertMarkdown('\n---\n'),
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ColorPalette palette;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: palette.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}