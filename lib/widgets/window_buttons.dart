import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/app_tour_service.dart';
import '../providers/navigation_provider.dart';

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final isMax = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = isMax;
        });
      }
    }
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AppTourButton(),
        _WindowButton(
          icon: LucideIcons.minus,
          onPressed: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: _isMaximized ? LucideIcons.copy : LucideIcons.square,
          onPressed: () async {
            if (_isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: LucideIcons.x,
          onPressed: () => windowManager.close(),
          hoverColor: Colors.red.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovering 
                ? (widget.hoverColor ?? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08))) 
                : Colors.transparent,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 14,
              color: _isHovering 
                  ? (widget.hoverColor != null ? Colors.white : iconColor) 
                  : iconColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      )),
    );
  }
}

class _AppTourButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppTourButton> createState() => _AppTourButtonState();
}

class _AppTourButtonState extends ConsumerState<_AppTourButton> {
  bool _isHovering = false;

  String? _getSectionForPage(AppPage page) {
    switch (page) {
      case AppPage.home:
        return 'Home';
      case AppPage.tasks:
        return 'Tasks';
      case AppPage.notes:
        return 'Notes';
      default:
        return null;
    }
  }

  void _startTourForCurrentPage() {
    final activePage = ref.read(navigationProvider);
    final section = _getSectionForPage(activePage);
    
    if (section != null) {
      AppTourService.startTour(context, ref, section: section);
    } else {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.info, color: theme.colorScheme.onInverseSurface, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No tour available for this page yet.',
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: theme.colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          elevation: 8,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: PopupMenuButton<String>(
        tooltip: 'App Tour Menu',
        position: PopupMenuPosition.under,
        color: theme.cardColor,
        elevation: 8,
        onSelected: (value) {
          switch (value) {
            case 'Sidebar':
              // Sidebar tour can be run from anywhere, but let's just run it
              AppTourService.startTour(context, ref, section: 'Sidebar');
              break;
            case 'CurrentPage':
              _startTourForCurrentPage();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'Sidebar',
            child: Row(
              children: [
                Icon(LucideIcons.layoutTemplate, size: 16, color: iconColor),
                const SizedBox(width: 12),
                const Text('Navigation & Sidebar'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'CurrentPage',
            child: Row(
              children: [
                Icon(LucideIcons.fileText, size: 16, color: iconColor),
                const SizedBox(width: 12),
                const Text('This Page'),
              ],
            ),
          ),
        ],
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isHovering 
                ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08))
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.helpCircle,
                size: 14,
                color: _isHovering ? iconColor : iconColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                "App Tour",
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovering ? iconColor : iconColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
