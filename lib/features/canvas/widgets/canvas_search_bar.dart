import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/viewport_controller.dart';

class CanvasSearchBar extends StatefulWidget {
  const CanvasSearchBar({super.key});

  @override
  State<CanvasSearchBar> createState() => _CanvasSearchBarState();
}

class _CanvasSearchBarState extends State<CanvasSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    context.read<CanvasController>().updateSearchQuery(value);
    _goToCurrentResult();
  }

  void _goToCurrentResult() {
    final canvasController = context.read<CanvasController>();
    final viewportController = context.read<ViewportController>();
    
    if (canvasController.searchResults.isNotEmpty && canvasController.currentSearchIndex != -1) {
      final nodeId = canvasController.searchResults[canvasController.currentSearchIndex];
      final node = canvasController.document.nodes.firstWhere((n) => n.id == nodeId);
      
      final viewportSize = MediaQuery.of(context).size;
      viewportController.centerOnPosition(
        node.position + Offset(node.size.width / 2, node.size.height / 2),
        viewportSize,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasController = context.watch<CanvasController>();
    final theme = Theme.of(context);

    return Positioned(
      top: 32,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.search,
                size: 18,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onSearch,
                  onSubmitted: (_) => canvasController.nextSearchIndex(),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search nodes...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (canvasController.searchResults.isNotEmpty) ...[
                Text(
                  '${canvasController.currentSearchIndex + 1} of ${canvasController.searchResults.length}',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                _IconButton(
                  icon: LucideIcons.chevronUp,
                  onTap: () {
                    canvasController.previousSearchIndex();
                    _goToCurrentResult();
                  },
                ),
                _IconButton(
                  icon: LucideIcons.chevronDown,
                  onTap: () {
                    canvasController.nextSearchIndex();
                    _goToCurrentResult();
                  },
                ),
              ] else if (canvasController.searchQuery.isNotEmpty) ...[
                Text(
                  'No results',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _IconButton(
                icon: LucideIcons.x,
                onTap: () => canvasController.setSearchOpen(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          icon,
          size: 16,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
