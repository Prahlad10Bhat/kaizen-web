import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

import '../../providers/workout_provider.dart';

class WorkoutListScreen extends ConsumerWidget {
  final Set<String> selectedMuscles;
  final VoidCallback onBack;

  const WorkoutListScreen({
    super.key, 
    required this.selectedMuscles,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final theme = Theme.of(context);

    // Filter exercises matching selected muscles
    final filteredExercises = workoutState.exercises.where((exercise) {
      bool matches = false;
      for (final m in selectedMuscles) {
        if (exercise.primaryMuscle.contains(m) || 
            exercise.secondaryMuscles.any((sec) => sec.contains(m))) {
          matches = true;
          break;
        }
        // Map specific tags to provider muscle groups
        if (m == 'Shoulder' && (exercise.primaryMuscle.contains('Delts') || exercise.secondaryMuscles.any((s) => s.contains('Delts')))) matches = true;
        if (m == 'Legs' && (exercise.primaryMuscle.contains('Quads') || exercise.secondaryMuscles.any((s) => s.contains('Quads')))) matches = true;
      }
      return matches;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.textTheme.bodyLarge?.color),
          onPressed: onBack,
        ),
        title: Text(
          'RECOMMENDED',
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: filteredExercises.isEmpty
          ? Center(
              child: Text(
                'No exercises found for selected muscles.',
                style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredExercises.length,
              itemBuilder: (context, index) {
                final ex = filteredExercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LucideIcons.dumbbell, color: theme.primaryColor),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'Target: ${ex.primaryMuscle}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                            const Gap(8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  ex.pr,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
