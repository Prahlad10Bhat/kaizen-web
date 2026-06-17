import 'package:flutter/material.dart';

class CanvasSelectionOverlay extends StatelessWidget {
  final Rect? selectionRect;

  const CanvasSelectionOverlay({
    super.key,
    required this.selectionRect,
  });

  @override
  Widget build(BuildContext context) {
    if (selectionRect == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Positioned(
      left: selectionRect!.left,
      top: selectionRect!.top,
      width: selectionRect!.width,
      height: selectionRect!.height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
