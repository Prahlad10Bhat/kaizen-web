import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

import '../controllers/canvas_controller.dart';
import '../controllers/viewport_controller.dart';
import '../../../utils/snackbar_utils.dart';

class CanvasToolbar extends StatelessWidget {
  final CanvasController canvasController;
  final ViewportController viewportController;
  final VoidCallback onAddNode;
  final VoidCallback onBack;

  const CanvasToolbar({
    super.key,
    required this.canvasController,
    required this.viewportController,
    required this.onAddNode,
    required this.onBack,
  });

  void _showControlsDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            Icon(LucideIcons.mousePointer2, color: theme.primaryColor, size: 24),
            const Gap(12),
            const Text('Canvas Controls'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlRow('Pan', 'Right-click + Drag'),
              _buildControlRow('Zoom', 'Mouse Wheel or Toolbar'),
              _buildControlRow('Select Node', 'Left-click'),
              _buildControlRow('Multi-Select', 'Shift + Click or Drag Box'),
              _buildControlRow('Delete Node', 'Right-click or Delete Key'),
              _buildControlRow('Add Node', 'Double-click or Toolbar'),
              _buildControlRow('Find Node', 'Toolbar'),
              _buildControlRow('Undo/Redo', 'Ctrl + Z / Ctrl + Y'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }


  Widget _buildControlRow(String action, String shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(shortcut, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: canvasController,
      builder: (context, child) {
        return Positioned(
          top: 200,
          right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 6,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolbarButton(
                  icon: LucideIcons.arrowLeft,
                  tooltip: 'Back to projects',
                  onTap: onBack,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(),
                ),

                _ToolbarButton(
                  icon: LucideIcons.plus,
                  tooltip: 'Add node',
                  onTap: onAddNode,
                ),
                const SizedBox(height: 8),

                _ToolbarButton(
                  icon: LucideIcons.maximize,
                  tooltip: 'Go to Home View',
                  onTap: viewportController.reset,
                ),
                const SizedBox(height: 8),
                _ToolbarButton(
                  icon: LucideIcons.crosshair,
                  tooltip: 'Set as Home View',
                  onTap: () {
                    viewportController.setHomeView();
                    canvasController.saveViewportState(viewportController.offset, viewportController.scale);
                    SnackbarUtils.showCustomSnackBar(context, 'Home view updated');
                  },
                ),
                const SizedBox(height: 8),
                _ToolbarButton(
                  icon: LucideIcons.undo2,
                  tooltip: 'Undo',
                  onTap: canvasController.canUndo ? canvasController.undo : null,
                ),
                const SizedBox(height: 8),
                _ToolbarButton(
                  icon: LucideIcons.redo2,
                  tooltip: 'Redo',
                  onTap: canvasController.canRedo ? canvasController.redo : null,
                ),
                const SizedBox(height: 8),
                _ToolbarButton(
                  icon: LucideIcons.search,
                  tooltip: 'Find',
                  isActive: canvasController.isSearchOpen,
                  onTap: () => canvasController.setSearchOpen(!canvasController.isSearchOpen),
                ),
                const SizedBox(height: 8),
                _ToolbarButton(
                  icon: LucideIcons.helpCircle,
                  tooltip: 'Canvas Controls',
                  onTap: () => _showControlsDialog(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return _LeftTooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? theme.colorScheme.primary
                : enabled
                    ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)
                    : theme.disabledColor,
          ),
        ),
      ),
    ),
  );
}
}

class _LeftTooltip extends StatefulWidget {
  final String message;
  final Widget child;

  const _LeftTooltip({required this.message, required this.child});

  @override
  State<_LeftTooltip> createState() => _LeftTooltipState();
}

class _LeftTooltipState extends State<_LeftTooltip> {
  OverlayEntry? _entry;

  void _showTooltip() {
    if (_entry != null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _entry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + (renderBox.size.height / 2) - 16,
        right: (MediaQuery.of(context).size.width - offset.dx) + 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Darker tooltip container
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void _hideTooltip() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showTooltip(),
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }
}
