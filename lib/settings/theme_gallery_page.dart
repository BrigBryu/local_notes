import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_registry.dart';
import '../theme/color_palette.dart';

extension StringExtension on String {
  String get titleCase {
    return split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class ThemeGalleryPage extends ConsumerWidget {
  const ThemeGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final currentThemeId = ref.watch(themeControllerProvider.notifier).currentThemeId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Themes"),
        backgroundColor: palette.surface,
        foregroundColor: palette.onSurface,
      ),
      backgroundColor: palette.background,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: kThemeRegistry.length,
        itemBuilder: (context, index) {
          final themeInfo = kThemeRegistry[index];
          final isActive = themeInfo.id == currentThemeId;

          return ThemeCard(
            themeInfo: themeInfo,
            isActive: isActive,
            onTap: () {
              ref.read(themeControllerProvider.notifier).loadById(themeInfo.id);
            },
          );
        },
      ),
    );
  }
}

class ThemeCard extends ConsumerStatefulWidget {
  final ThemeInfo themeInfo;
  final bool isActive;
  final VoidCallback onTap;

  const ThemeCard({
    super.key,
    required this.themeInfo,
    required this.isActive,
    required this.onTap,
  });

  @override
  ConsumerState<ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends ConsumerState<ThemeCard> {
  ColorPalette? _previewPalette;

  @override
  void initState() {
    super.initState();
    _loadPreviewPalette();
  }

  Future<void> _loadPreviewPalette() async {
    try {
      final palette = await ColorPalette.fromAsset(widget.themeInfo.assetPath);
      if (mounted) {
        setState(() {
          _previewPalette = palette;
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPalette = ref.watch(currentPaletteProvider);
    
    return Card(
      elevation: widget.isActive ? 4 : 2,
      shape: RoundedRectangleBorder(
        side: widget.isActive 
            ? BorderSide(width: 2, color: currentPalette.accent)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      color: currentPalette.surface,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.themeInfo.id.titleCase,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentPalette.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (_previewPalette != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.themeInfo.swatchKeys
                      .map((key) => _SwatchCircle(
                            color: _getColorFromPalette(_previewPalette!, key),
                          ))
                      .toList(),
                ),
              ] else ...[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: currentPalette.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromPalette(ColorPalette palette, String key) {
    switch (key) {
      case 'background':
        return palette.background;
      case 'primary':
        return palette.primary;
      case 'secondary':
        return palette.secondary;
      case 'accent':
        return palette.accent;
      case 'error':
        return palette.error;
      case 'red':
        return palette.red ?? palette.error;
      case 'green':
        return palette.green ?? palette.accent;
      case 'yellow':
        return palette.yellow ?? palette.primary;
      case 'blue':
        return palette.blue ?? palette.primary;
      case 'magenta':
        return palette.magenta ?? palette.secondary;
      case 'cyan':
        return palette.cyan ?? palette.secondary;
      default:
        return palette.primary;
    }
  }
}

class _SwatchCircle extends StatelessWidget {
  final Color color;

  const _SwatchCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 0.5,
        ),
      ),
    );
  }
}