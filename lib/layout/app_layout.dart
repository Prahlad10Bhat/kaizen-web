import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../features/tasks/task_board_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/profile/profile_page.dart';
import '../features/habits/habits_page.dart';
import '../features/canvas/canvas_page.dart';
import '../features/home/home_page.dart';
import '../features/notes/notes_page.dart';
import '../features/notes/providers/notes_providers.dart';
import '../features/boxclock/boxclock_page.dart';
import '../providers/navigation_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import 'sidebar.dart';
import 'command_palette.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/feedback_page.dart';
import '../features/ai/ai_page.dart';
import '../features/workout/workout_page.dart';
import '../features/app_tracker/app_tracker_page.dart';
import '../widgets/universal_task_dialog.dart';
import '../providers/task_provider.dart';
import '../services/app_tour_service.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/app_tracker_provider.dart';

import '../widgets/window_buttons.dart';
import '../widgets/focus_timer.dart';
import '../services/update_service.dart';
import '../widgets/changelog_dialog.dart';
import '../services/notification_scheduler.dart';
import 'package:kaizen/utils/snackbar_utils.dart';
import '../services/window_tracker_service.dart';

class AppLayout extends ConsumerStatefulWidget {
  const AppLayout({super.key});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class _AppLayoutState extends ConsumerState<AppLayout> with WindowListener {
  Offset? _timerCenter;
  late final WindowTrackerService _windowTracker;
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _windowTracker = ref.read(windowTrackerServiceProvider);
    _initApp();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _windowTracker.stop();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final isTrackingEnabled = ref.read(appTrackerProvider).isTrackingEnabled;
    if (isTrackingEnabled) {
      bool? shouldHide = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Text('App Tracker is Running', style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text('Do you want to keep tracking in the background or exit the app and stop tracking?', style: TextStyle(color: Colors.grey.shade300)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Stop & Exit', style: TextStyle(color: Colors.red.shade400)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                child: const Text('Keep Tracking', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      );
      
      if (shouldHide == null) return; // dialog dismissed without selection
      
      if (shouldHide) {
        await windowManager.hide();
      } else {
        ref.read(appTrackerProvider.notifier).toggleGlobalTracking();
        await windowManager.destroy();
      }
    } else {
      await windowManager.destroy();
    }
  }

  Future<void> _initApp() async {
    await _checkForUpdates();
    Future.microtask(() async {
      // Start the notification scheduler
      ref.read(notificationSchedulerProvider);
      
      // Start window tracker
      ref.read(windowTrackerServiceProvider).start();

      await ChangelogDialog.checkAndShow(context);
    });
  }

  Future<void> _checkForUpdates() async {
    // Wait a bit for the app to settle
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    try {
      final updateAvailable = await UpdateService.isUpdateAvailable();
      if (updateAvailable && mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    } catch (e) {
      print('Update check failed: $e');
    }
  }

  void _setupNotificationListener() {
    ref.listen<NotificationMessage?>(notificationProvider, (previous, next) {
      if (next != null) {
        final theme = Theme.of(context);
        SnackbarUtils.showCustomSnackBar(context, next.message, isError: next.isError);
        ref.read(notificationProvider.notifier).clear();
      }
    });
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        ref.read(navigationProvider.notifier).setPage(AppPage.home);
        break;
      case 1:
        ref.read(navigationProvider.notifier).setPage(AppPage.notes);
        break;
      case 2:
        ref.read(navigationProvider.notifier).setPage(AppPage.ai);
        break;
      case 3:
        ref.read(navigationProvider.notifier).setPage(AppPage.calendar);
        break;
      case 4:
        ref.read(navigationProvider.notifier).setPage(AppPage.profile);
        break;
    }
  }

  void _showNewHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        title: Text('New Habit', style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter habit name...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(habitsProvider.notifier).addHabit(nameController.text, 'ðŸ”¥', theme.primaryColor);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
            ),
            child: const Text('Add Habit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuickCaptureSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Gap(20),
                Text(
                  'QUICK CAPTURE',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey.shade500,
                  ),
                ),
                Gap(16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildCaptureCard(
                      context,
                      icon: LucideIcons.stickyNote,
                      label: 'New Note',
                      color: theme.primaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        final id = ref.read(notesProvider.notifier).addNote();
                        ref.read(selectedNoteIdProvider.notifier).set(id);
                        ref.read(navigationProvider.notifier).setPage(AppPage.notes);
                      },
                    ),
                    _buildCaptureCard(
                      context,
                      icon: LucideIcons.checkSquare,
                      label: 'New Task',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => const UniversalTaskDialog(isEventContext: false),
                        );
                      },
                    ),
                    _buildCaptureCard(
                      context,
                      icon: LucideIcons.timer,
                      label: 'Focus Timer',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(timerProvider.notifier).startTimer();
                      },
                    ),
                    _buildCaptureCard(
                      context,
                      icon: LucideIcons.sparkles,
                      label: 'Ask AI',
                      color: Colors.cyan,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(navigationProvider.notifier).setPage(AppPage.ai);
                      },
                    ),
                    _buildCaptureCard(
                      context,
                      icon: LucideIcons.flame,
                      label: 'New Habit',
                      color: const Color(0xFFF43F5E),
                      onTap: () {
                        Navigator.pop(context);
                        _showNewHabitDialog(context);
                      },
                    ),
                    _buildCaptureCard(
                      context,
                      icon: LucideIcons.calendar,
                      label: 'New Event',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => const UniversalTaskDialog(isEventContext: true),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaptureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Gap(10),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFab(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: FloatingActionButton(
          backgroundColor: theme.primaryColor,
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () => _showQuickCaptureSheet(context),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setupNotificationListener();
    final activePage = ref.watch(navigationProvider);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 800;

    int currentIndex = 0;
    if (activePage == AppPage.notes || activePage == AppPage.canvas) {
      currentIndex = 1;
    } else if (activePage == AppPage.ai) {
      currentIndex = 2;
    } else if (activePage == AppPage.calendar) {
      currentIndex = 3;
    } else if (activePage == AppPage.profile || activePage == AppPage.settings || activePage == AppPage.feedback) {
      currentIndex = 4;
    }

    final isRinging = ref.watch(timerProvider.select((state) => state.isRinging));

    return Focus(
      autofocus: true,
      child: Scaffold(
        key: ref.watch(scaffoldKeyProvider),
        backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
          Row(
            children: [
              if (!isMobile) 
                Stack(
                  children: [
                    const AppSidebar(),
                    if (activePage == AppPage.notes && ref.watch(selectedNoteIdProvider) != null)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            final selectedId = ref.read(selectedNoteIdProvider);
                            if (selectedId != null) {
                              final notes = ref.read(notesProvider);
                              try {
                                final note = notes.firstWhere((n) => n.id == selectedId);
                                if (note.title.trim().isEmpty && 
                                    note.content.trim().isEmpty && 
                                    note.mediaPaths.isEmpty) {
                                  ref.read(notesProvider.notifier).deleteNote(note.id);
                                }
                              } catch (_) {}
                              ref.read(selectedNoteIdProvider.notifier).set(null);
                            }
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(color: Colors.black.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                  ],
                ),
              Expanded(
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: _buildPage(activePage),
                ),
              ),
            ],
          ),
          // Window Control Bar (Drag area + Buttons) - Only on Desktop
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 32,
                child: Stack(
                  children: [
                    const DragToMoveArea(
                      child: SizedBox.expand(),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: const WindowButtons(),
                    ),
                  ],
                ),
              ),
            ),
          // Focus Timer
          if (ref.watch(settingsProvider).showTimer)
            Builder(
              builder: (context) {
              final isExpanded = ref.watch(timerProvider).isExpanded;
              final timerWidth = isExpanded ? 240.0 : 120.0;
              final timerHeight = isExpanded ? 80.0 : 36.0;
              
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              
              final defaultTop = screenHeight - timerHeight - 24.0;
              final defaultCenterX = screenWidth - (timerWidth / 2) - 24.0;

              double centerX = defaultCenterX;
              double top = defaultTop;

              if (_timerCenter != null) {
                centerX = _timerCenter!.dx;
                top = _timerCenter!.dy;
              }

              double left = centerX - (timerWidth / 2);

              // Clamp to borders
              if (left < 16.0) {
                 left = 16.0;
              }
              if (left + timerWidth > screenWidth - 16.0) {
                 left = screenWidth - timerWidth - 16.0;
              }
              
              if (top < 16.0) top = 16.0;
              if (top + timerHeight > screenHeight - 16.0) {
                top = screenHeight - timerHeight - 16.0;
              }

              return AnimatedPositioned(
                key: AppTourKeys.focusTimerKey,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                top: top,
                left: left,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      if (_timerCenter == null) {
                        _timerCenter = Offset(defaultCenterX, defaultTop);
                      }
                      
                      double newCenterX = _timerCenter!.dx + details.delta.dx;
                      double newTop = _timerCenter!.dy + details.delta.dy;

                      // Clamp the drag origin so it doesn't get lost off-screen
                      double minCenterX = timerWidth / 2 + 16.0;
                      double maxCenterX = screenWidth - (timerWidth / 2) - 16.0;
                      if (newCenterX < minCenterX) newCenterX = minCenterX;
                      if (newCenterX > maxCenterX) newCenterX = maxCenterX;
                      
                      if (newTop < 0) newTop = 0;
                      if (newTop > screenHeight - timerHeight) newTop = screenHeight - timerHeight;

                      _timerCenter = Offset(newCenterX, newTop);
                    });
                  },
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: FocusTimer(),
                  ),
                ),
              );
            }
          ),
          // Update Banner
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutExpo,
            top: _updateAvailable 
                ? (Platform.isWindows || Platform.isLinux || Platform.isMacOS ? 48.0 : MediaQuery.of(context).padding.top + 16.0) 
                : -100.0,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.arrowUpCircle, color: Colors.white, size: 20),
                      const Gap(12),
                      Text(
                        'A new update is available!',
                        style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Gap(16),
                      InkWell(
                        onTap: () {
                          UpdateService.downloadAndInstallUpdate();
                          setState(() => _updateAvailable = false);
                          SnackbarUtils.showCustomSnackBar(context, 'Downloading update in background...');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Update Now',
                            style: GoogleFonts.sora(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Gap(8),
                      InkWell(
                        onTap: () => setState(() => _updateAvailable = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isMobile ? _buildMobileFab(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isMobile ? Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
        ),
        child: Theme(
          data: theme.copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF0D0D0D),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            selectedItemColor: theme.primaryColor,
            unselectedItemColor: const Color(0xFF6E6E6E),
            selectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: GoogleFonts.sora(fontWeight: FontWeight.w500, fontSize: 11),
            onTap: _onBottomNavTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.home, size: 20),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.stickyNote, size: 20),
                ),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.sparkles, size: 20),
                ),
                label: 'AI',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.calendar, size: 20),
                ),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.user, size: 20),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ) : null,
    ));
  }

  Widget _buildPage(AppPage page) {
    switch (page) {
      case AppPage.home:
        return const HomePage();
      case AppPage.calendar:
        return const AppCalendarPage();
      case AppPage.profile:
        return const ProfilePage();
      case AppPage.habits:
        return const HabitsPage();
      case AppPage.canvas:
        return const CanvasPage();
      case AppPage.notes:
        return const NotesPage();
      case AppPage.ai:
        return const AIPage();
      case AppPage.boxclock:
        return const BoxClockPage();
      case AppPage.settings:
        return const SettingsPage();
      case AppPage.feedback:
        return const FeedbackPage();
      case AppPage.workout:
        return const WorkoutPage();
      case AppPage.appTracker:
        return const AppTrackerPage();
      case AppPage.tasks:
      default:
        return const TaskBoardPage();
    }
  }
}
