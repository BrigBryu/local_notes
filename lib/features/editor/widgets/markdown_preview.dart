import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../theme/color_palette.dart';

class MarkdownPreview extends StatefulWidget {
  final String content;
  final ColorPalette palette;

  const MarkdownPreview({
    super.key,
    required this.content,
    required this.palette,
  });

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<MarkdownPreview>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Container(
      decoration: BoxDecoration(
        color: widget.palette.background,
        border: Border.all(color: widget.palette.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: widget.content.isEmpty
          ? _buildEmptyState()
          : _buildMarkdownContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 64,
            color: widget.palette.disabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Preview will appear here',
            style: TextStyle(
              color: widget.palette.hint,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start typing in the editor to see live preview',
            style: TextStyle(
              color: widget.palette.hint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent() {
    return Markdown(
      data: widget.content,
      padding: const EdgeInsets.all(16),
      styleSheet: _buildMarkdownStyleSheet(),
      physics: const ClampingScrollPhysics(),
      shrinkWrap: false,
      selectable: true,
      onTapLink: (text, href, title) {
        // Handle link taps if needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link tapped: $href'),
            backgroundColor: widget.palette.primary,
          ),
        );
      },
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      // Text styles
      p: TextStyle(
        color: widget.palette.onBackground,
        fontSize: 16,
        height: 1.6,
      ),
      h1: TextStyle(
        color: widget.palette.onSurface,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      h2: TextStyle(
        color: widget.palette.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h3: TextStyle(
        color: widget.palette.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h4: TextStyle(
        color: widget.palette.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h5: TextStyle(
        color: widget.palette.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h6: TextStyle(
        color: widget.palette.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      
      // Emphasis styles
      strong: TextStyle(
        color: widget.palette.onBackground,
        fontWeight: FontWeight.bold,
      ),
      em: TextStyle(
        color: widget.palette.onBackground,
        fontStyle: FontStyle.italic,
      ),
      del: TextStyle(
        color: widget.palette.hint,
        decoration: TextDecoration.lineThrough,
      ),
      
      // Code styles
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: widget.palette.accent,
        backgroundColor: widget.palette.surface,
      ),
      codeblockDecoration: BoxDecoration(
        color: widget.palette.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: widget.palette.divider),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      
      // Quote styles
      blockquote: TextStyle(
        color: widget.palette.hint,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: widget.palette.surface,
        border: Border(
          left: BorderSide(
            color: widget.palette.accent,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(16),
      
      // List styles
      listBullet: TextStyle(
        color: widget.palette.primary,
        fontSize: 16,
      ),
      listIndent: 24,
      
      // Link styles
      a: TextStyle(
        color: widget.palette.primary,
        decoration: TextDecoration.underline,
      ),
      
      // Table styles
      tableHead: TextStyle(
        color: widget.palette.onSurface,
        fontWeight: FontWeight.bold,
      ),
      tableBody: TextStyle(
        color: widget.palette.onBackground,
      ),
      tableBorder: TableBorder.all(
        color: widget.palette.divider,
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.all(8),
      
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: widget.palette.divider,
            width: 2,
          ),
        ),
      ),
    );
  }
}