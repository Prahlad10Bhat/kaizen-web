import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomContextMenuItem {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  final String? shortcut;
  final bool isDestructive;
  final bool isDivider;

  CustomContextMenuItem({
    this.icon,
    this.label,
    this.onTap,
    this.shortcut,
    this.isDestructive = false,
    this.isDivider = false,
  });

  factory CustomContextMenuItem.divider() {
    return CustomContextMenuItem(isDivider: true);
  }
}

Future<void> showCustomContextMenu({
  required BuildContext context,
  required Offset position,
  required List<CustomContextMenuItem> items,
}) async {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return _CustomContextMenuOverlay(
        position: position,
        items: items,
        onDismiss: () => entry.remove(),
      );
    },
  );

  overlay.insert(entry);
}

class _CustomContextMenuOverlay extends StatefulWidget {
  final Offset position;
  final List<CustomContextMenuItem> items;
  final VoidCallback onDismiss;

  const _CustomContextMenuOverlay({
    required this.position,
    required this.items,
    required this.onDismiss,
  });

  @override
  State<_CustomContextMenuOverlay> createState() => _CustomContextMenuOverlayState();
}

class _CustomContextMenuOverlayState extends State<_CustomContextMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  void _handleItemTap(CustomContextMenuItem item) async {
    if (item.isDivider) return;
    
    HapticFeedback.lightImpact();
    if (item.onTap != null) {
      item.onTap!();
    }
    _handleDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Position constraints to ensure menu doesn't go off-screen
    final screenSize = MediaQuery.of(context).size;
    final double menuWidth = 240;
    // Estimate menu height: ~36px per item, ~17px per divider, plus 16px padding
    final int itemHeight = 36;
    final int dividerHeight = 17;
    final double estimatedHeight = 16.0 + widget.items.fold(0, (sum, item) => sum + (item.isDivider ? dividerHeight : itemHeight));
    
    double left = widget.position.dx;
    double top = widget.position.dy;

    if (left + menuWidth > screenSize.width) {
      left = screenSize.width - menuWidth - 8;
    }
    if (top + estimatedHeight > screenSize.height) {
      top = screenSize.height - estimatedHeight - 8;
    }

    return Stack(
      children: [
        // Background dismiss detector
        Positioned.fill(
          child: Listener(
            onPointerDown: (event) {
              // Right or left click outside dismisses
              _handleDismiss();
            },
            onPointerSignal: (event) {
              // Scroll wheel dismisses the menu (canvas can then handle the scroll)
              _handleDismiss();
            },
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        
        // The menu
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: Alignment.topLeft,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: menuWidth,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((item) {
                    if (item.isDivider) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        child: Container(
                          height: 1,
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                        ),
                      );
                    }
                    
                    return _CustomContextMenuItemWidget(
                      item: item,
                      onTap: () => _handleItemTap(item),
                      isDark: isDark,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomContextMenuItemWidget extends StatefulWidget {
  final CustomContextMenuItem item;
  final VoidCallback onTap;
  final bool isDark;

  const _CustomContextMenuItemWidget({
    required this.item,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_CustomContextMenuItemWidget> createState() => _CustomContextMenuItemWidgetState();
}

class _CustomContextMenuItemWidgetState extends State<_CustomContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDestructive = widget.item.isDestructive;
    
    final Color textColor = isDestructive 
        ? Colors.redAccent 
        : (widget.isDark ? const Color(0xFFE5E5E5) : const Color(0xFF1A1A1A));
        
    final Color iconColor = isDestructive
        ? Colors.redAccent
        : (widget.isDark ? const Color(0xFFA0A0A0) : const Color(0xFF606060));
        
    final Color hoverColor = widget.isDark 
        ? const Color(0xFF2A2A2A) 
        : const Color(0xFFF0F0F0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 16,
                  color: iconColor,
                ),
                const Gap(12),
              ],
              Expanded(
                child: Text(
                  widget.item.label ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.item.shortcut != null) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.item.shortcut!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? const Color(0xFFA0A0A0) : const Color(0xFF808080),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
