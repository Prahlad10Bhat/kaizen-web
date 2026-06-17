import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'command_palette.dart';

import '../providers/navigation_provider.dart';
import '../providers/sidebar_provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/app_tour_service.dart';

class AppSidebar extends ConsumerWidget {
  final bool isDrawer;
  const AppSidebar({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarProvider);
    final activePage = ref.watch(navigationProvider);
    final user = ref.watch(userProvider);
    final double sidebarWidth = isDrawer ? 240 : (isExpanded ? 240 : 64);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = theme.scaffoldBackgroundColor;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : theme.dividerColor.withValues(alpha: 0.1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: ClipRect(
        child: OverflowBox(
          minWidth: 240,
          maxWidth: 240,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(8),
              // Navigation History Arrows
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: _buildHistoryArrows(context, ref, centered: true),
                    ),
                  ],
                ),
              ),

              // Header Logo Area & Collapse
              SizedBox(
                height: 56,
                child: InkWell(
                  onTap: () {
                    if (!isDrawer) {
                      ref.read(sidebarProvider.notifier).toggle();
                    }
                  },
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 64,
                        child: Center(
                          child: TriangleLogo(),
                        ),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isExpanded ? 1.0 : 0.0,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Kaizen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              if (!isDrawer)
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.panelLeftClose,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    ref.read(sidebarProvider.notifier).toggle();
                                  },
                                  splashRadius: 20,
                                ),
                              const Gap(8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Gap(8),
              
              // Faux Search Bar
              _buildSearchBar(context, isExpanded),
              
              // Navigation Section
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildNavItem(context, ref, LucideIcons.home, 'Dashboard', AppPage.home, activePage == AppPage.home, isExpanded, key: AppTourKeys.homeKey),
                    _buildNavItem(context, ref, LucideIcons.stickyNote, 'Notes', AppPage.notes, activePage == AppPage.notes, isExpanded, key: AppTourKeys.notesKey),
                    _buildNavItem(context, ref, LucideIcons.checkSquare, 'Tasks', AppPage.tasks, activePage == AppPage.tasks, isExpanded, key: AppTourKeys.tasksKey),
                    _buildNavItem(context, ref, LucideIcons.calendar, 'Calendar', AppPage.calendar, activePage == AppPage.calendar, isExpanded, key: AppTourKeys.calendarKey),
                    
                    _buildSectionHeader(context, 'Tools', isExpanded),
                    _buildNavItem(context, ref, LucideIcons.flame, 'Habit Tracker', AppPage.habits, activePage == AppPage.habits, isExpanded, key: AppTourKeys.habitsKey),
                    _buildNavItem(context, ref, LucideIcons.box, 'Canvas', AppPage.canvas, activePage == AppPage.canvas, isExpanded, key: AppTourKeys.canvasKey),
                    _buildNavItem(context, ref, LucideIcons.clock, 'BoxClock', AppPage.boxclock, activePage == AppPage.boxclock, isExpanded, key: AppTourKeys.boxclockKey),
                    _buildNavItem(context, ref, LucideIcons.activity, 'Workout', AppPage.workout, activePage == AppPage.workout, isExpanded, key: AppTourKeys.workoutKey),
                    _buildNavItem(context, ref, LucideIcons.monitor, 'App Tracker', AppPage.appTracker, activePage == AppPage.appTracker, isExpanded, key: AppTourKeys.appTrackerKey),
                    
                    const Gap(16),
                  ],
                ),
              ),
              
              // Bottom Actions
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _NavItemWidget(
                      icon: LucideIcons.messageSquare,
                      label: 'Feedback',
                      page: AppPage.feedback,
                      isActive: activePage == AppPage.feedback,
                      isExpanded: isExpanded,
                      isDrawer: isDrawer,
                      tourKey: AppTourKeys.feedbackKey,
                    ),
                    _NavItemWidget(
                      icon: LucideIcons.settings,
                      label: 'Settings',
                      page: AppPage.settings,
                      isActive: activePage == AppPage.settings,
                      isExpanded: isExpanded,
                      isDrawer: isDrawer,
                      tourKey: AppTourKeys.settingsKey,
                    ),
                    _UserProfileWidget(
                      user: user,
                      activePage: activePage,
                      isExpanded: isExpanded,
                      isDrawer: isDrawer,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryArrows(BuildContext context, WidgetRef ref, {bool centered = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canGoBack = ref.read(navigationProvider.notifier).canGoBack;
    final canGoForward = ref.read(navigationProvider.notifier).canGoForward;
    
    final activeColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7);
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2);

    return Row(
      mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: canGoBack ? () => ref.read(navigationProvider.notifier).goBack() : null,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(LucideIcons.chevronLeft, size: 18, color: canGoBack ? activeColor : inactiveColor),
          ),
        ),
        const Gap(4),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: canGoForward ? () => ref.read(navigationProvider.notifier).goForward() : null,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(LucideIcons.chevronRight, size: 18, color: canGoForward ? activeColor : inactiveColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isExpanded) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      key: AppTourKeys.sidebarSearchKey,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 150),
      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: SizedBox(
        height: 48,
        width: 240,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 64,
            child: Center(
              child: IconButton(
                icon: Icon(LucideIcons.search, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), size: 18),
                onPressed: () => CommandPalette.show(context),
              ),
            ),
          ),
        ),
      ),
      secondChild: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            mouseCursor: SystemMouseCursors.click,
            onTap: () => CommandPalette.show(context),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 14, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5)),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Search',
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ctrl F',
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isExpanded) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 150),
      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Container(
        width: 240,
        height: 24,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Container(
          width: 32,
          height: 2,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
      secondChild: Container(
        width: 240,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, IconData icon, String label, AppPage page, bool isActive, bool isExpanded, {GlobalKey? key}) {
    return _NavItemWidget(
      icon: icon,
      label: label,
      page: page,
      isActive: isActive,
      isExpanded: isExpanded,
      isDrawer: isDrawer,
      tourKey: key,
    );
  }

  Widget _buildProjectItem(BuildContext context, String title, Color dotColor) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }
}

class TriangleLogo extends ConsumerWidget {
  const TriangleLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    String logoPath = 'assets/transparent_logos/dark_trans.png';
    switch (settings.themeMode) {
      case AppThemeMode.light:
        logoPath = 'assets/transparent_logos/dark_trans.png';
        break;
      case AppThemeMode.dark:
        // Use reagle if it was the light colored one, or just fallback
        logoPath = 'assets/transparent_logos/reagle_transparent.png'; 
        break;
      case AppThemeMode.cherryBlossom:
        logoPath = 'assets/transparent_logos/cherry_transparent.png';
        break;
      case AppThemeMode.coffee:
        logoPath = 'assets/transparent_logos/coffee_transparent.png';
        break;
      case AppThemeMode.ember:
        logoPath = 'assets/transparent_logos/ember_transparent.png';
        break;
      case AppThemeMode.ivory:
        logoPath = 'assets/transparent_logos/ivory_transparent.png';
        break;
      case AppThemeMode.ash:
        logoPath = 'assets/logo_ash.png'; // No ash_transparent.png found
        break;
      case AppThemeMode.plush:
        logoPath = 'assets/transparent_logos/plush_transparent.png';
        break;
      case AppThemeMode.system:
        final brightness = MediaQuery.platformBrightnessOf(context);
        logoPath = brightness == Brightness.dark ? 'assets/transparent_logos/reagle_transparent.png' : 'assets/transparent_logos/dark_trans.png';
        break;
    }

    return Image.asset(
      logoPath,
      width: 48,
      height: 48,
    );
  }
}

class _NavItemWidget extends ConsumerStatefulWidget {
  final IconData icon;
  final String label;
  final AppPage page;
  final bool isActive;
  final bool isExpanded;
  final bool isDrawer;
  final GlobalKey? tourKey;

  const _NavItemWidget({
    required this.icon,
    required this.label,
    required this.page,
    required this.isActive,
    required this.isExpanded,
    required this.isDrawer,
    this.tourKey,
  });

  @override
  ConsumerState<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends ConsumerState<_NavItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final activeBgColor = theme.primaryColor.withValues(alpha: 0.15);
    final hoverBgColor = theme.primaryColor.withValues(alpha: 0.08);
    
    final activeColor = theme.primaryColor;
    final hoverColor = theme.primaryColor.withValues(alpha: 0.8);
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6);

    final currentColor = widget.isActive ? activeColor : (_isHovered ? hoverColor : inactiveColor);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(navigationProvider.notifier).setPage(widget.page);
          if (widget.isDrawer) {
            Navigator.pop(context);
          }
        },
        child: Padding(
          key: widget.tourKey,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            decoration: BoxDecoration(
              color: widget.isActive ? activeBgColor : (_isHovered ? hoverBgColor : Colors.transparent),
            ),
            child: Stack(
              children: [
                if (widget.isActive)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: currentColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: Icon(
                            widget.icon,
                            size: 18,
                            color: currentColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: widget.isExpanded ? 1.0 : 0.0,
                          child: Row(
                            children: [
                              const Gap(4),
                              Expanded(
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: currentColor,
                                    fontWeight: widget.isActive || _isHovered ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserProfileWidget extends ConsumerStatefulWidget {
  final dynamic user;
  final AppPage activePage;
  final bool isExpanded;
  final bool isDrawer;

  const _UserProfileWidget({
    required this.user,
    required this.activePage,
    required this.isExpanded,
    required this.isDrawer,
  });

  @override
  ConsumerState<_UserProfileWidget> createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends ConsumerState<_UserProfileWidget> {
  bool _isHovered = false;

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = widget.activePage == AppPage.profile;
    
    final activeBgColor = theme.primaryColor.withValues(alpha: 0.15);
    final hoverBgColor = theme.primaryColor.withValues(alpha: 0.08);
    
    final activeColor = theme.primaryColor;
    final hoverColor = theme.primaryColor.withValues(alpha: 0.8);
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6);

    final currentColor = isActive ? activeColor : (_isHovered ? hoverColor : inactiveColor);

    return Padding(
      key: AppTourKeys.profileKey,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            ref.read(navigationProvider.notifier).setPage(AppPage.profile);
            if (widget.isDrawer) Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? activeBgColor : (_isHovered ? hoverBgColor : Colors.transparent),
            ),
            child: Stack(
              children: [
                if (isActive)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: currentColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: theme.primaryColor,
                            backgroundImage: (widget.user.profilePic.isNotEmpty && !widget.user.profilePic.contains('randomuser.me')) 
                                ? _getImageProvider(widget.user.profilePic) 
                                : null,
                            child: widget.user.profilePic.isEmpty || widget.user.profilePic.contains('randomuser.me')
                                ? const Icon(
                                    LucideIcons.user,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (widget.isExpanded) ...[
                        const Gap(8),
                        Expanded(
                          child: Text(
                            widget.user.name,
                            style: TextStyle(
                              fontWeight: isActive || _isHovered ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                              color: currentColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
