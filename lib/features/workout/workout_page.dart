import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

import '../../providers/workout_provider.dart';
import 'widgets/streak_calendar_widget.dart';
import 'widgets/folder_card.dart';
import '../../widgets/custom_context_menu.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  final OverlayPortalController _calendarOverlayController = OverlayPortalController();
  final LayerLink _calendarLayerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(workoutProvider);
    final activeSession = workoutState.activeSession;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (_calendarOverlayController.isShowing) {
            setState(() {
              _calendarOverlayController.hide();
            });
          }
          return false;
        },
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
        slivers: [
          SliverToBoxAdapter(child: const Gap(48)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workouts',
                    style: GoogleFonts.sora(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: theme.textTheme.bodyLarge?.color,
                      letterSpacing: -1.5,
                    ),
                  ),
                  if (activeSession == null)
                    OverlayPortal(
                      controller: _calendarOverlayController,
                      overlayChildBuilder: (context) {
                        return Positioned(
                          left: 0,
                          top: 0,
                          child: CompositedTransformFollower(
                            link: _calendarLayerLink,
                            targetAnchor: Alignment.bottomRight,
                            followerAnchor: Alignment.topRight,
                            offset: const Offset(0, 8),
                            child: TapRegion(
                              onTapOutside: (_) {
                                setState(() {
                                  _calendarOverlayController.hide();
                                });
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: Transform.scale(
                                  scale: 0.8,
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    width: 340,
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: theme.dividerColor.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: const StreakCalendarWidget(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: CompositedTransformTarget(
                        link: _calendarLayerLink,
                        child: IconButton(
                          icon: Icon(
                            _calendarOverlayController.isShowing ? LucideIcons.calendarOff : LucideIcons.calendar,
                            color: theme.primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _calendarOverlayController.toggle();
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: const Gap(24)),
          _buildActiveWorkoutHook(theme, activeSession),
          SliverToBoxAdapter(child: const Gap(40)),
          ..._buildRoutinesSections(theme, workoutState.routines),
          SliverToBoxAdapter(child: const Gap(60)),
        ],
      ),
      ),
    );
  }


  Widget _buildActiveWorkoutHook(ThemeData theme, ActiveWorkoutSession? session) {
    if (session == null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BouncingCard(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(workoutProvider.notifier).startActiveSession();
            },
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.zap, color: theme.primaryColor, size: 32),
                  ),
                  const Gap(24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Start',
                          style: GoogleFonts.sora(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Start an empty workout session',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Active Tracker View
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      session.name,
                      style: GoogleFonts.sora(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(8),
                  if (session.startTime == null)
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        ref.read(workoutProvider.notifier).beginWorkoutTimer();
                      },
                      icon: const Icon(LucideIcons.play, size: 14),
                      label: Text('Start', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        String durationStr = '0m';
                        if (session.startTime != null) {
                          final duration = DateTime.now().difference(session.startTime!);
                          if (duration.inHours > 0) {
                            durationStr = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
                          } else if (duration.inMinutes > 0) {
                            durationStr = '${duration.inMinutes}m';
                          } else {
                            durationStr = '${duration.inSeconds}s';
                          }
                        }
                        ref.read(workoutProvider.notifier).addWorkoutLog(session.name, durationStr, session.exercises.length);
                        ref.read(workoutProvider.notifier).clearActiveSession();
                      },
                      icon: const Icon(LucideIcons.check, size: 14),
                      label: Text('Finish', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  const Gap(8),
                  if (session.name != 'Free Workout')
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(workoutProvider.notifier).clearActiveSession();
                      },
                      icon: const Icon(LucideIcons.x, size: 18),
                      tooltip: 'Close',
                      color: theme.textTheme.bodyMedium?.color,
                    )
                  else
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(workoutProvider.notifier).clearActiveSession();
                      },
                      icon: const Icon(LucideIcons.trash2, size: 14),
                      label: Text('Discard', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  const Gap(12),
                  if (session.startTime != null)
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, _) {
                        final duration = DateTime.now().difference(session.startTime!);
                        String twoDigits(int n) => n.toString().padLeft(2, "0");
                        final m = twoDigits(duration.inMinutes.remainder(60));
                        final s = twoDigits(duration.inSeconds.remainder(60));
                        final timeStr = duration.inHours > 0 ? '${duration.inHours}:$m:$s' : '$m:$s';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          constraints: const BoxConstraints(minHeight: 36),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                timeStr,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      constraints: const BoxConstraints(minHeight: 36),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '00:00',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(32),
              ...session.exercises.asMap().entries.map((e) {
                final idx = e.key;
                final ex = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
                      const Gap(12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double cardWidth = (constraints.maxWidth - (12 * 4)) / 5;
                          if (cardWidth < 100) cardWidth = 100;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: ex.sets.asMap().entries.map((se) {
                              final sIdx = se.key;
                              final set = se.value;
                              return Container(
                                width: cardWidth,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: set.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: set.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${sIdx + 1}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.3))),
                                        MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            final ns = List<WorkoutSet>.from(ex.sets);
                                            ns[sIdx] = set.copyWith(isCompleted: !set.isCompleted);
                                            final nEx = List<ActiveExercise>.from(session.exercises);
                                            nEx[idx] = ex.copyWith(sets: ns);
                                            ref.read(workoutProvider.notifier).updateActiveSessionExercises(nEx);
                                          },
                                          child: Icon(LucideIcons.checkCircle2, size: 22, color: set.isCompleted ? const Color(0xFF10B981) : theme.dividerColor.withValues(alpha: 0.3)),
                                        )),
                                      ],
                                    ),
                                    const Gap(16),
                                    TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: theme.textTheme.bodyLarge?.color),
                                      decoration: InputDecoration(
                                        hintText: 'Kgs',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintStyle: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.2)),
                                      ),
                                      onChanged: (v) {
                                        final ns = List<WorkoutSet>.from(ex.sets);
                                        ns[sIdx] = set.copyWith(weight: v);
                                        final nEx = List<ActiveExercise>.from(session.exercises);
                                        nEx[idx] = ex.copyWith(sets: ns);
                                        ref.read(workoutProvider.notifier).updateActiveSessionExercises(nEx);
                                      },
                                    ),
                                    const Gap(8),
                                    Container(height: 1, width: 30, color: theme.dividerColor.withValues(alpha: 0.2)),
                                    const Gap(8),
                                    TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: theme.textTheme.bodyLarge?.color),
                                      decoration: InputDecoration(
                                        hintText: 'Reps',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintStyle: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.2)),
                                      ),
                                      onChanged: (v) {
                                        final ns = List<WorkoutSet>.from(ex.sets);
                                        ns[sIdx] = set.copyWith(reps: v);
                                        final nEx = List<ActiveExercise>.from(session.exercises);
                                        nEx[idx] = ex.copyWith(sets: ns);
                                        ref.read(workoutProvider.notifier).updateActiveSessionExercises(nEx);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const Gap(8),
                      BouncingCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final ns = List<WorkoutSet>.from(ex.sets)..add(WorkoutSet());
                          final nEx = List<ActiveExercise>.from(session.exercises);
                          nEx[idx] = ex.copyWith(sets: ns);
                          ref.read(workoutProvider.notifier).updateActiveSessionExercises(nEx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.plus, size: 16, color: theme.primaryColor),
                              const Gap(8),
                              Text('Add Set', style: GoogleFonts.inter(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }),
              const Gap(12),
              Center(
                child: BouncingCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showAddExerciseModal(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.search, size: 18, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6)),
                        const Gap(12),
                        Text('Add Exercise', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoutinesSections(ThemeData theme, List<WorkoutRoutine> routines) {
    final pinnedRoutines = routines.where((r) => r.isPinned).toList();
    final customRoutines = routines.where((r) => r.isCustom).toList();
    final stdRoutines = routines.where((r) => !r.isCustom).toList();

    return [
      if (pinnedRoutines.isNotEmpty) ...[
        _buildCarouselSection(
          theme: theme,
          title: 'Pinned Routines',
          routines: pinnedRoutines,
          showCreateCard: false,
          forceStandalone: true,
        ),
        const SliverToBoxAdapter(child: Gap(40)),
      ],
      _buildCarouselSection(
        theme: theme,
        title: 'Your Custom Routines',
        routines: customRoutines,
        showCreateCard: true,
        forceStandalone: false,
      ),
      if (stdRoutines.isNotEmpty) ...[
        const SliverToBoxAdapter(child: Gap(40)),
        _buildCarouselSection(
          theme: theme,
          title: 'Standard Programs',
          routines: stdRoutines,
          showCreateCard: false,
        ),
      ]
    ];
  }

  Widget _buildCarouselSection({
    required ThemeData theme,
    required String title,
    required List<WorkoutRoutine> routines,
    required bool showCreateCard,
    bool forceStandalone = false,
  }) {
    final Map<String, List<WorkoutRoutine>> groupedRoutines = {};
    final List<WorkoutRoutine> standaloneRoutines = [];

    for (final routine in routines) {
      if (routine.isFolder) {
        groupedRoutines.putIfAbsent(routine.name, () => []);
      } else if (!forceStandalone && routine.name.contains(':')) {
        final parts = routine.name.split(':');
        final folderName = parts[0].trim();
        groupedRoutines.putIfAbsent(folderName, () => []).add(routine);
      } else {
        standaloneRoutines.add(routine);
      }
    }

    final folderKeys = groupedRoutines.keys.toList();
    final int totalItems = (showCreateCard ? 1 : 0) + folderKeys.length + standaloneRoutines.length;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Gap(20),
          SizedBox(
            height: 230,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: totalItems,
              separatorBuilder: (context, index) => const Gap(16),
              itemBuilder: (context, index) {
                if (showCreateCard && index == 0) {
                  return _buildCreateActionCard(context, theme);
                }

                final int adjustedIndex = showCreateCard ? index - 1 : index;

                if (adjustedIndex < folderKeys.length) {
                  final folderName = folderKeys[adjustedIndex];
                  final folderRoutines = groupedRoutines[folderName]!;
                  return DragTarget<WorkoutRoutine>(
                    onWillAcceptWithDetails: (details) => details.data != null && !details.data.isFolder,
                    onAcceptWithDetails: (details) {
                      ref.read(workoutProvider.notifier).moveRoutineToFolder(details.data.id, folderName);
                      HapticFeedback.mediumImpact();
                      SnackbarUtils.showCustomSnackBar(context, 'Moved to $folderName');
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovered = candidateData.isNotEmpty;
                      return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                        onSecondaryTapDown: (details) {
                          _showFolderContextMenu(context, details.globalPosition, ref, folderName, folderRoutines);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: isHovered ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
                          transformAlignment: Alignment.center,
                          child: FolderCard(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showFolderContents(context, theme, folderName, folderRoutines);
                      },
                    child: SizedBox(
                      width: 170 - 32, // Accounting for FolderCard internal padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor.withValues(alpha: 0.2),
                                  theme.primaryColor.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.folder, color: theme.primaryColor, size: 24),
                          ),
                          const Spacer(),
                          Text(
                            folderName,
                            style: GoogleFonts.sora(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${folderRoutines.length} routines',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ));
            },
          );
        }

                final routine = standaloneRoutines[adjustedIndex - folderKeys.length];
                final displayName = forceStandalone && routine.name.contains(':') ? routine.name.split(':')[1].trim() : routine.name;
                
                final cardChild = BouncingCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(workoutProvider.notifier).startActiveSession(
                      name: routine.name,
                      exercises: routine.exercises,
                    );
                  },
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor.withValues(alpha: 0.2),
                                theme.primaryColor.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.dumbbell, color: theme.primaryColor, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          displayName,
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${routine.exercises.length} exercises',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                return LongPressDraggable<WorkoutRoutine>(
                  data: routine,
                  delay: const Duration(milliseconds: 300),
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 170,
                      height: 230,
                      child: Transform.scale(
                        scale: 0.9,
                        child: Opacity(
                          opacity: 0.8,
                          child: cardChild,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: cardChild,
                  ),
                  child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                    onSecondaryTapDown: (details) {
                      _showRoutineContextMenu(context, details.globalPosition, ref, routine);
                    },
                    child: cardChild,
                  )),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showRoutineContextMenu(BuildContext context, Offset position, WidgetRef ref, WorkoutRoutine routine) {
    showCustomContextMenu(
      context: context,
      position: position,
      items: [
        if (!routine.isCustom)
          CustomContextMenuItem(
            icon: LucideIcons.edit2,
            label: 'Modify (Customize)',
            onTap: () {
              ref.read(workoutProvider.notifier).modifyStandardRoutine(routine);
              SnackbarUtils.showCustomSnackBar(context, 'Custom routine created');
            },
          ),
        if (routine.isCustom)
          CustomContextMenuItem(
            icon: LucideIcons.edit2,
            label: 'Edit Routine',
            onTap: () {
              _showRoutineDetailModal(context, Theme.of(context), routine, startInEditMode: true);
            },
          ),
        CustomContextMenuItem(
          icon: routine.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
          label: routine.isPinned ? 'Unpin Routine' : 'Pin Routine',
          onTap: () {
            ref.read(workoutProvider.notifier).togglePinRoutine(routine.id);
          },
        ),
        if (routine.isCustom)
          CustomContextMenuItem(
            icon: LucideIcons.trash2,
            label: 'Delete Routine',
            isDestructive: true,
            onTap: () {
              ref.read(workoutProvider.notifier).deleteRoutine(routine.id);
            },
          ),
      ],
    );
  }

  void _showFolderContextMenu(BuildContext context, Offset position, WidgetRef ref, String folderName, List<WorkoutRoutine> routines) {
    showCustomContextMenu(
      context: context,
      position: position,
      items: [
        CustomContextMenuItem(
          icon: LucideIcons.edit2,
          label: 'Modify All (Customize)',
          onTap: () {
            for (final routine in routines) {
              ref.read(workoutProvider.notifier).modifyStandardRoutine(routine);
            }
            SnackbarUtils.showCustomSnackBar(context, '${routines.length} routines copied to Custom');
          },
        ),
      ],
    );
  }

  Widget _buildCreateActionCard(BuildContext context, ThemeData theme) {
    return BouncingCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _showCreateActionModal(context, theme);
      },
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.plus, color: theme.primaryColor, size: 24),
            ),
            const Spacer(),
            Text(
              'Create\nNew',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateActionModal(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.list, color: theme.primaryColor),
                ),
                title: Text(
                  'Create Routine',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  'Build a custom workout routine',
                  style: GoogleFonts.inter(
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateRoutineModal(context, theme);
                },
              ),
              const Gap(16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.folderPlus, color: theme.primaryColor),
                ),
                title: Text(
                  'Create Folder',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  'Organize routines into a folder',
                  style: GoogleFonts.inter(
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateFolderModal(context, theme);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showCreateFolderModal(BuildContext context, ThemeData theme) {
    final TextEditingController folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Create Folder',
            style: GoogleFonts.sora(
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          content: TextField(
            controller: folderNameController,
            autofocus: true,
            style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Folder Name',
              hintStyle: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = folderNameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(workoutProvider.notifier).createFolder(name);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Create',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateRoutineModal(BuildContext context, ThemeData theme, {WorkoutRoutine? routine, String? initialFolderName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateRoutineModal(routine: routine, initialFolderName: initialFolderName),
    );
  }

  void _showRoutineDetailModal(BuildContext context, ThemeData theme, WorkoutRoutine routine, {bool startInEditMode = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoutineDetailModal(routine: routine, startInEditMode: startInEditMode),
    );
  }

  void _showFolderContents(BuildContext context, ThemeData theme, String folderName, List<WorkoutRoutine> routines) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  folderName,
                  style: GoogleFonts.sora(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const Gap(8),
                Text(
                  _getFolderDescription(folderName),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const Gap(16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routines.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      // Remove folder name prefix for cleaner display inside the folder
                      final displayName = routine.name.contains(':') ? routine.name.split(':')[1].trim() : routine.name;
                      
                      return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                        onSecondaryTapDown: (details) {
                          _showRoutineContextMenu(context, details.globalPosition, ref, routine);
                        },
                        child: ListTile(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context); // Close the bottom sheet
                            ref.read(workoutProvider.notifier).startActiveSession(
                              name: routine.name,
                              exercises: routine.exercises,
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          tileColor: theme.cardColor,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.dumbbell, color: theme.primaryColor, size: 20),
                          ),
                          title: Text(
                            displayName,
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Text(
                            '${routine.exercises.length} exercises\n${routine.exercises.join(', ')}',
                            style: GoogleFonts.inter(
                              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(LucideIcons.play, size: 20, color: theme.primaryColor),
                        ),
                      ));
                    },
                  ),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close the folder modal
                        _showCreateRoutineModal(context, theme, initialFolderName: folderName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                        foregroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(LucideIcons.plus),
                      label: Text(
                        'Add Routine to Folder',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFolderDescription(String folderName) {
    switch (folderName) {
      case 'PPL':
        return '6 days a week. Typical schedule: Push, Pull, Legs, Push, Pull, Legs, Rest. Great for optimal frequency and volume.';
      case 'Upper/Lower':
        return '4 days a week. Typical schedule: Upper, Lower, Rest, Upper, Lower, Rest, Rest. Perfect balance for strength and hypertrophy.';
      case 'Arnold':
        return '6 days a week. Typical schedule: Chest/Back, Shoulders/Arms, Legs, Repeat, Rest. Favored by golden era bodybuilders.';
      case 'Bro Split':
        return '5 days a week. Typical schedule: Chest, Back, Shoulders, Arms, Legs, Rest, Rest. Focuses on annihilating one muscle group per day.';
      case 'Full Body':
        return '3 days a week. Typical schedule: Workout A, Rest, Workout B, Rest, Workout A, Rest, Rest. Ideal for beginners and busy schedules.';
      default:
        return 'A collection of standard gym routines.';
    }
  }


  Widget _buildMuscleRecovery(ThemeData theme, List<MuscleRecovery> muscles) {
    final fatigued = List<MuscleRecovery>.from(muscles)..sort((a, b) => a.recoveryPercentage.compareTo(b.recoveryPercentage));
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fatigued Muscles',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
            const Gap(20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: fatigued.take(4).map((m) {
                final isRed = m.recoveryPercentage < 50;
                final baseColor = isRed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: baseColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: baseColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 8)
                          ]
                        ),
                      ),
                      const Gap(10),
                      Text(m.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
                      const Gap(10),
                      Text('${m.recoveryPercentage.toInt()}%', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: baseColor)),
                    ],
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  void _showAddExerciseModal(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.read(workoutProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String searchQuery = '';
        String selectedMuscle = 'All';
        final muscles = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];

        return StatefulBuilder(
          builder: (context, setState) {
            final filteredExercises = state.exercises.where((e) {
              final matchesSearch = e.name.toLowerCase().contains(searchQuery.toLowerCase()) || e.primaryMuscle.toLowerCase().contains(searchQuery.toLowerCase());
              if (!matchesSearch) return false;
              if (selectedMuscle == 'All') return true;
              
              final primary = e.primaryMuscle.toLowerCase();
              final sec = e.secondaryMuscles.map((m) => m.toLowerCase()).toList();
              
              bool matches(String target) => primary.contains(target) || sec.any((m) => m.contains(target));
              
              switch (selectedMuscle) {
                case 'Chest': return matches('chest');
                case 'Back': return matches('back') || matches('lats') || matches('traps');
                case 'Legs': return matches('quads') || matches('hamstrings') || matches('calves') || matches('glutes');
                case 'Shoulders': return matches('delts');
                case 'Arms': return matches('biceps') || matches('triceps') || matches('forearms');
                case 'Core': return matches('abs') || matches('obliques') || matches('core');
                default: return true;
              }
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  )
                ]
              ),
              child: Column(
                children: [
                  const Gap(16),
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(10))),
                  const Gap(24),
                  Text('Select Exercise', style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.5)),
                  const Gap(16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      style: GoogleFonts.inter(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search exercises...',
                        prefixIcon: Icon(LucideIcons.search, color: theme.dividerColor),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const Gap(16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: muscles.length,
                      separatorBuilder: (context, index) => const Gap(8),
                      itemBuilder: (context, index) {
                        final m = muscles[index];
                        final isSelected = m == selectedMuscle;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => selectedMuscle = m);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.primaryColor : theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                m,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredExercises.length,
                      separatorBuilder: (context, index) => const Gap(12),
                      itemBuilder: (context, index) {
                        final ex = filteredExercises[index];
                        return BouncingCard(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(workoutProvider.notifier).addExerciseToActiveSession(ex.name);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(LucideIcons.dumbbell, color: theme.primaryColor, size: 20),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ex.name, style: GoogleFonts.sora(fontSize: 18, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                                      Text(ex.primaryMuscle, style: GoogleFonts.inter(fontSize: 13, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                Icon(LucideIcons.plusCircle, color: theme.primaryColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}

class CreateRoutineModal extends ConsumerStatefulWidget {
  final WorkoutRoutine? routine;
  final String? initialFolderName;
  const CreateRoutineModal({super.key, this.routine, this.initialFolderName});

  @override
  ConsumerState<CreateRoutineModal> createState() => _CreateRoutineModalState();
}

class _CreateRoutineModalState extends ConsumerState<CreateRoutineModal> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedExercises = {};
  String _searchQuery = '';
  String _selectedMuscle = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameController.text = widget.routine!.name.replaceAll(' (Custom)', '');
      _selectedExercises.addAll(widget.routine!.exercises);
    } else if (widget.initialFolderName != null) {
      _nameController.text = '${widget.initialFolderName} : ';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(workoutProvider);
    final allExercises = workoutState.exercises;
    final muscles = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];
    final filteredExercises = allExercises.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) || e.primaryMuscle.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_selectedMuscle == 'All') return true;
      
      final primary = e.primaryMuscle.toLowerCase();
      final sec = e.secondaryMuscles.map((m) => m.toLowerCase()).toList();
      
      bool matches(String target) => primary.contains(target) || sec.any((m) => m.contains(target));
      
      switch (_selectedMuscle) {
        case 'Chest': return matches('chest');
        case 'Back': return matches('back') || matches('lats') || matches('traps');
        case 'Legs': return matches('quads') || matches('hamstrings') || matches('calves') || matches('glutes');
        case 'Shoulders': return matches('delts');
        case 'Arms': return matches('biceps') || matches('triceps') || matches('forearms');
        case 'Core': return matches('abs') || matches('obliques') || matches('core');
        default: return true;
      }
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  widget.routine != null ? 'Edit Routine' : 'Create Routine',
                  style: GoogleFonts.sora(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color,
                    letterSpacing: -1.0,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) {
                      SnackbarUtils.showCustomSnackBar(context, 'Please enter a routine name', isError: true);
                      return;
                    }
                    if (_selectedExercises.isEmpty) {
                      SnackbarUtils.showCustomSnackBar(context, 'Please select at least one exercise', isError: true);
                      return;
                    }
                    if (widget.routine == null) {
                      ref.read(workoutProvider.notifier).addRoutine(
                        _nameController.text.trim(),
                        _selectedExercises.toList(),
                      );
                    } else {
                      ref.read(workoutProvider.notifier).updateRoutine(
                        widget.routine!.id,
                        _nameController.text.trim(),
                        _selectedExercises.toList(),
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  child: const Text('Save'),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'e.g. Upper Body Power',
                hintStyle: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.3), fontSize: 18),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const Gap(24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Select Exercises',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.inter(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(LucideIcons.search, color: theme.dividerColor),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: muscles.length,
              separatorBuilder: (context, index) => const Gap(8),
              itemBuilder: (context, index) {
                final m = muscles[index];
                final isSelected = m == _selectedMuscle;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMuscle = m);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        m,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(12),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: filteredExercises.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final exercise = filteredExercises[index];
                final isSelected = _selectedExercises.contains(exercise.name);
                
                return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedExercises.remove(exercise.name);
                      } else {
                        _selectedExercises.add(exercise.name);
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? theme.primaryColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? theme.primaryColor : theme.dividerColor,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                exercise.primaryMuscle,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BouncingCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const BouncingCard({super.key, required this.child, required this.onTap});

  @override
  State<BouncingCard> createState() => _BouncingCardState();
}

class _BouncingCardState extends State<BouncingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    ));
  }
}

class RoutineDetailModal extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;
  final bool startInEditMode;
  const RoutineDetailModal({super.key, required this.routine, this.startInEditMode = false});

  @override
  ConsumerState<RoutineDetailModal> createState() => _RoutineDetailModalState();
}

class _RoutineDetailModalState extends ConsumerState<RoutineDetailModal> {
  late WorkoutRoutine _currentRoutine;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _currentRoutine = widget.routine;
    _isEditing = widget.startInEditMode;
  }

  void _addExercise(BuildContext context, ThemeData theme, WorkoutState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String searchQuery = '';
        String selectedMuscle = 'All';
        final muscles = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];

        return StatefulBuilder(
          builder: (context, setState) {
            final filteredExercises = state.exercises.where((e) {
              final matchesSearch = e.name.toLowerCase().contains(searchQuery.toLowerCase()) || e.primaryMuscle.toLowerCase().contains(searchQuery.toLowerCase());
              if (!matchesSearch) return false;
              if (selectedMuscle == 'All') return true;
              
              final primary = e.primaryMuscle.toLowerCase();
              final sec = e.secondaryMuscles.map((m) => m.toLowerCase()).toList();
              
              bool matches(String target) => primary.contains(target) || sec.any((m) => m.contains(target));
              
              switch (selectedMuscle) {
                case 'Chest': return matches('chest');
                case 'Back': return matches('back') || matches('lats') || matches('traps');
                case 'Legs': return matches('quads') || matches('hamstrings') || matches('calves') || matches('glutes');
                case 'Shoulders': return matches('delts');
                case 'Arms': return matches('biceps') || matches('triceps') || matches('forearms');
                case 'Core': return matches('abs') || matches('obliques') || matches('core');
                default: return true;
              }
            }).toList();
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const Gap(16),
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(10))),
                  const Gap(24),
                  Text('Add Exercise to Routine', style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.5)),
                  const Gap(16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      style: GoogleFonts.inter(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search exercises...',
                        prefixIcon: Icon(LucideIcons.search, color: theme.dividerColor),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const Gap(16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: muscles.length,
                      separatorBuilder: (context, index) => const Gap(8),
                      itemBuilder: (context, index) {
                        final m = muscles[index];
                        final isSelected = m == selectedMuscle;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => selectedMuscle = m);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.primaryColor : theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                m,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredExercises.length,
                      separatorBuilder: (context, index) => const Gap(12),
                      itemBuilder: (context, index) {
                        final ex = filteredExercises[index];
                        return BouncingCard(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final newExs = List<String>.from(_currentRoutine.exercises)..add(ex.name);
                            ref.read(workoutProvider.notifier).updateRoutine(_currentRoutine.id, _currentRoutine.name, newExs);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(LucideIcons.dumbbell, color: theme.primaryColor, size: 20),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ex.name, style: GoogleFonts.sora(fontSize: 18, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                                      Text(ex.primaryMuscle, style: GoogleFonts.inter(fontSize: 13, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                Icon(LucideIcons.plusCircle, color: theme.primaryColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(workoutProvider);
    
    // Keep local reference updated if it exists in state (so we see added exercises)
    final routineInState = workoutState.routines.where((r) => r.id == widget.routine.id).firstOrNull;
    if (routineInState != null) {
      _currentRoutine = routineInState;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentRoutine.name,
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyLarge?.color,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                if (_currentRoutine.isCustom) ...[
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: Icon(
                      _isEditing ? LucideIcons.check : LucideIcons.pencil,
                      color: theme.primaryColor,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: () {
                        _addExercise(context, theme, workoutState);
                      },
                      icon: Icon(LucideIcons.plus, color: theme.primaryColor),
                    ),
                ],
              ],
            ),
          ),
          Expanded(
            child: (_currentRoutine.isCustom && _isEditing)
                ? ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _currentRoutine.exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final exercises = List<String>.from(_currentRoutine.exercises);
                      final item = exercises.removeAt(oldIndex);
                      exercises.insert(newIndex, item);
                      ref.read(workoutProvider.notifier).updateRoutine(_currentRoutine.id, _currentRoutine.name, exercises);
                    },
                    itemBuilder: (context, index) {
                      final exName = _currentRoutine.exercises[index];
                      return Container(
                        key: ValueKey('${exName}_$index'),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.dumbbell, color: theme.primaryColor, size: 20),
                          ),
                          title: Text(exName, style: GoogleFonts.sora(fontSize: 18, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                                onPressed: () {
                                  final exercises = List<String>.from(_currentRoutine.exercises);
                                  exercises.removeAt(index);
                                  ref.read(workoutProvider.notifier).updateRoutine(_currentRoutine.id, _currentRoutine.name, exercises);
                                },
                              ),
                              const Gap(8),
                              Icon(LucideIcons.gripVertical, color: theme.dividerColor, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _currentRoutine.exercises.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      final exName = _currentRoutine.exercises[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(LucideIcons.dumbbell, color: theme.primaryColor, size: 20),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Text(exName, style: GoogleFonts.sora(fontSize: 18, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(workoutProvider.notifier).startActiveSession(
                    name: _currentRoutine.name,
                    exercises: _currentRoutine.exercises,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: Text('Start Workout', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
