import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sidebar_provider.dart';
import '../providers/settings_provider.dart';
import '../features/notes/providers/notes_providers.dart';
import 'dart:ui';

class AppTourKeys {
  static final GlobalKey homeKey = GlobalKey();
  static final GlobalKey notesKey = GlobalKey();
  static final GlobalKey tasksKey = GlobalKey();
  static final GlobalKey calendarKey = GlobalKey();
  static final GlobalKey canvasKey = GlobalKey();
  static final GlobalKey boxclockKey = GlobalKey();
  static final GlobalKey habitsKey = GlobalKey();
  static final GlobalKey workoutKey = GlobalKey();
  static final GlobalKey appTrackerKey = GlobalKey();
  static final GlobalKey feedbackKey = GlobalKey();
  static final GlobalKey settingsKey = GlobalKey();
  static final GlobalKey profileKey = GlobalKey();
  static final GlobalKey sidebarSearchKey = GlobalKey();

  // Home Page Keys
  static final GlobalKey homeCommandHubKey = GlobalKey();
  static final GlobalKey homeActivitySummaryKey = GlobalKey();
  static final GlobalKey focusTimerKey = GlobalKey();

  // Task Board Keys
  static final GlobalKey taskBoardKey = GlobalKey();

  // Notes Keys
  static final GlobalKey notesSearchKey = GlobalKey();
  static final GlobalKey notesAddKey = GlobalKey();
  static final GlobalKey notesSampleNoteKey = GlobalKey();
  
  // Note Editor Keys
  static final GlobalKey notesEditorTitleKey = GlobalKey();
  static final GlobalKey notesEditorMediaKey = GlobalKey();
  static final GlobalKey notesEditorColorKey = GlobalKey();
}

class AppTourService {
  static Future<void> startTour(BuildContext context, WidgetRef ref, {required String section}) async {
    final theme = Theme.of(context);
    final showTimer = ref.read(settingsProvider).showTimer;
    
    List<TargetFocus> targets;
    switch (section) {
      case 'Home':
        targets = _buildHomeTargets(theme, showTimer: showTimer, tourName: 'Home');
        break;
      case 'Tasks':
        targets = _buildTasksTargets(theme, tourName: 'Tasks');
        break;
      case 'Notes':
        final notes = ref.read(notesProvider);
        if (notes.isEmpty) {
          final newNoteId = ref.read(notesProvider.notifier).addNote();
          final allNotes = ref.read(notesProvider);
          final newNote = allNotes.firstWhere((n) => n.id == newNoteId);
          ref.read(notesProvider.notifier).updateNote(newNote.copyWith(
            title: 'Welcome to Notes!',
            content: 'This is a sample note. You can click on it to edit, add tags, or attach media.',
          ));
          await Future.delayed(const Duration(milliseconds: 300));
        }
        targets = _buildNotesTargets(theme, tourName: 'Notes');
        break;
      case 'Sidebar':
      default:
        final isExpanded = ref.read(sidebarProvider);
        if (!isExpanded) {
          ref.read(sidebarProvider.notifier).setExpanded(true);
          await Future.delayed(const Duration(milliseconds: 300));
        }
        targets = _buildSidebarTargets(theme, tourName: 'Sidebar');
        break;
    }

    late TutorialCoachMark tutorialCoachMark;

    tutorialCoachMark = TutorialCoachMark(
      pulseEnable: false,
      targets: targets,
      colorShadow: Colors.black,
      skipWidget: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.skipForward, size: 16, color: theme.primaryColor),
                    const Gap(8),
                    Text(
                      "Skip ${section} Tour",
                      style: GoogleFonts.inter(
                        color: theme.textTheme.bodyLarge?.color ?? Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      paddingFocus: 2,
      opacityShadow: 0.85,
      onFinish: () {
        if (section == 'Notes') {
          // Find the sample note id (first note)
          final notes = ref.read(notesProvider);
          if (notes.isNotEmpty) {
            final sampleNote = notes.first;
            ref.read(selectedNoteIdProvider.notifier).set(sampleNote.id);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                _startNoteEditorTour(context, ref);
              }
            });
          }
        }
      },
      onClickOverlay: (target) => tutorialCoachMark.next(),
      onSkip: () {
        return true;
      },
    );
    
    tutorialCoachMark.show(context: context);
  }

  static Future<void> _startNoteEditorTour(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "NoteEditorTitle",
        keyTarget: AppTourKeys.notesEditorTitleKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Editing a Note",
                description: "This is the note editor. You can give your note a title and start typing your thoughts.",
                icon: LucideIcons.edit3,
                tourName: 'Note Editor',
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "NoteEditorMedia",
        keyTarget: AppTourKeys.notesEditorMediaKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Add Media",
                description: "Attach images, videos, and audio files directly to your notes.",
                icon: LucideIcons.imagePlus,
                tourName: 'Note Editor',
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "NoteEditorColor",
        keyTarget: AppTourKeys.notesEditorColorKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                isLast: true,
                title: "Customize Note Color",
                description: "Color code your note to make it stand out on the dashboard.",
                icon: LucideIcons.palette,
                tourName: 'Note Editor',
              );
            },
          ),
        ],
      ),
    ];

    late TutorialCoachMark tutorialCoachMark;

    tutorialCoachMark = TutorialCoachMark(
      pulseEnable: false,
      targets: targets,
      colorShadow: Colors.black,
      skipWidget: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.skipForward, size: 16, color: theme.primaryColor),
                    const Gap(8),
                    Text(
                      "Skip Editor Tour",
                      style: GoogleFonts.inter(
                        color: theme.textTheme.bodyLarge?.color ?? Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      paddingFocus: 2,
      opacityShadow: 0.85,
      onFinish: () {},
      onClickOverlay: (target) => tutorialCoachMark.next(),
      onSkip: () {
        return true;
      },
    );
    
    tutorialCoachMark.show(context: context);
  }

  static List<TargetFocus> _buildHomeTargets(ThemeData theme, {required bool showTimer, required String tourName}) {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "CommandHub",
        keyTarget: AppTourKeys.homeCommandHubKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Smart Command Hub",
                description: "Type or use voice commands to quickly add tasks, create notes, and navigate the app.",
                icon: LucideIcons.sparkles,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
    ];

    if (showTimer) {
      targets.add(
        TargetFocus(
          identify: "Timer",
          keyTarget: AppTourKeys.focusTimerKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.RRect,
          radius: 100,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return _buildTourContent(
                  theme,
                  controller: controller,
                  title: "Focus Timer",
                  description: "Boost your productivity! Use this timer to stay focused. You can even drag it around.",
                  icon: LucideIcons.timer,
                  tourName: tourName,
                );
              },
            ),
          ],
        ),
      );
    }

    targets.add(
      TargetFocus(
        identify: "ActivitySummary",
        keyTarget: AppTourKeys.homeActivitySummaryKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                isLast: true,
                title: "Activity Summary",
                description: "Get a quick glance at your pending tasks, recent notes, and consistency.",
                icon: LucideIcons.barChart2,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }

  static List<TargetFocus> _buildTasksTargets(ThemeData theme, {required String tourName}) {
    return [
      TargetFocus(
        identify: "TaskBoard",
        keyTarget: AppTourKeys.taskBoardKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                isLast: true,
                title: "Kanban Board",
                description: "Organize your work visually. Drag and drop tasks between To Do, In Progress, and Done.",
                icon: LucideIcons.columns,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
    ];
  }

  static List<TargetFocus> _buildNotesTargets(ThemeData theme, {required String tourName}) {
    return [
      TargetFocus(
        identify: "NotesSearch",
        keyTarget: AppTourKeys.notesSearchKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Search & Filter",
                description: "Quickly find notes by searching titles, content, or filtering by tags.",
                icon: LucideIcons.search,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "NotesSample",
        keyTarget: AppTourKeys.notesSampleNoteKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Your Notes",
                description: "This is a note card. Click on it to open the editor. Right-click to pin or delete it.",
                icon: LucideIcons.fileText,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "NotesAdd",
        keyTarget: AppTourKeys.notesAddKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                isLast: true,
                title: "Create Note",
                description: "Click here to create a new note. You can add images, tags, and link it to tasks or goals.",
                icon: LucideIcons.plus,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
    ];
  }

  static List<TargetFocus> _buildSidebarTargets(ThemeData theme, {required String tourName}) {
    return [
      TargetFocus(
        identify: "SidebarSearch",
        keyTarget: AppTourKeys.sidebarSearchKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Search Hub",
                description: "Quickly access the Command Palette to search across all your notes, tasks, settings, and more. You can also use Ctrl+F.",
                icon: LucideIcons.search,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Home",
        keyTarget: AppTourKeys.homeKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Your Dashboard",
                description: "This is the Home page. It gives you a quick overview of your goals, tasks, pending notes, and provides the smart command bar.",
                icon: LucideIcons.home,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Notes",
        keyTarget: AppTourKeys.notesKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Quick Notes",
                description: "Capture thoughts instantly. Your notes can be organized into tasks and linked directly to your goals.",
                icon: LucideIcons.stickyNote,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Tasks",
        keyTarget: AppTourKeys.tasksKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Task Board",
                description: "Manage your to-dos with a Kanban-style board. Drag and drop tasks between columns to track your progress.",
                icon: LucideIcons.checkSquare,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Calendar",
        keyTarget: AppTourKeys.calendarKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Schedule",
                description: "View and manage your tasks on a timeline. Drag and drop tasks to reorganize your day effortlessly.",
                icon: LucideIcons.calendar,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Habits",
        keyTarget: AppTourKeys.habitsKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Habit Tracker",
                description: "Build consistency. Track your daily habits and maintain your streaks.",
                icon: LucideIcons.flame,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Canvas",
        keyTarget: AppTourKeys.canvasKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Infinite Canvas",
                description: "Map out your goals and tasks visually. You can link nodes directly to specific tasks or goals here.",
                icon: LucideIcons.layoutGrid,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Boxclock",
        keyTarget: AppTourKeys.boxclockKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Boxclock",
                description: "A specialized tool for visualizing your time in a box format and setting goals.",
                icon: LucideIcons.clock,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Workout",
        keyTarget: AppTourKeys.workoutKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Workouts",
                description: "Log your exercises and monitor your fitness journey right from the app.",
                icon: LucideIcons.activity,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "AppTracker",
        keyTarget: AppTourKeys.appTrackerKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "App Tracker",
                description: "Manually track the time you spend on specific applications or projects.",
                icon: LucideIcons.monitor,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Feedback",
        keyTarget: AppTourKeys.feedbackKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Feedback",
                description: "We'd love to hear from you! Share your thoughts, report bugs, or suggest new features here.",
                icon: LucideIcons.messageSquare,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Settings",
        keyTarget: AppTourKeys.settingsKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                title: "Settings",
                description: "Customize Kaizen to your liking. Manage themes, notifications, and more.",
                icon: LucideIcons.settings,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Profile",
        keyTarget: AppTourKeys.profileKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTourContent(
                theme,
                controller: controller,
                isLast: true,
                title: "Your Profile",
                description: "View and edit your personal information and account details here.",
                icon: LucideIcons.user,
                tourName: tourName,
              );
            },
          ),
        ],
      ),
    ];
  }

  static Widget _buildTourContent(ThemeData theme, {required String title, required String description, required IconData icon, double yOffset = 0, TutorialCoachMarkController? controller, bool isLast = false, String tourName = 'tour'}) {
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: theme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.sora(
                            color: theme.textTheme.bodyLarge?.color ?? Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8) ?? Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  if (controller != null) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLast) {
                            controller.skip();
                          } else {
                            controller.next();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          isLast ? "End $tourName tour" : "Next",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
