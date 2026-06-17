import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

import '../../../providers/workout_provider.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

class ExerciseBottomSheet extends ConsumerStatefulWidget {
  final String muscleName;

  const ExerciseBottomSheet({super.key, required this.muscleName});

  @override
  ConsumerState<ExerciseBottomSheet> createState() => _ExerciseBottomSheetState();
}

class _ExerciseBottomSheetState extends ConsumerState<ExerciseBottomSheet> {
  String selectedFilter = 'Exercises';
  final List<String> filters = ['Exercises', 'Stretches', 'Bodyweight', 'Kettlebell'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(workoutProvider);
    
    // In a real app, you would filter workoutState.exercises based on the muscleName and category.
    // For now, we'll just show some mock exercises or filter basic ones.
    final List<ExerciseStats> availableExercises = workoutState.exercises.where((ex) => 
      ex.primaryMuscle == widget.muscleName || ex.secondaryMuscles.contains(widget.muscleName)
    ).toList();
    
    // Fallback if none match exactly in our mock data
    if (availableExercises.isEmpty) {
      availableExercises.addAll(workoutState.exercises.take(3));
    }

    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle and Title
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.muscleName.toUpperCase(),
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Gap(16),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: filters.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                    onTap: () => setState(() => selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  )),
                );
              }).toList(),
            ),
          ),
          const Gap(24),

          // Exercises List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: availableExercises.length,
              itemBuilder: (context, index) {
                final exercise = availableExercises[index];
                return _buildExerciseCard(context, exercise, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseStats exercise, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Video Placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80'),
                fit: BoxFit.cover,
                opacity: 0.5,
              ),
            ),
            child: const Center(
              child: Icon(LucideIcons.playCircle, size: 48, color: Colors.white),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    Text(
                      'Primary: ${exercise.primaryMuscle}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (exercise.secondaryMuscles.isNotEmpty) ...[
                      const Gap(12),
                      Text(
                        'Secondary: ${exercise.secondaryMuscles.first}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(16),
                
                // Steps (Mocked for now since not in original model)
                _buildStep(theme, 'Plant feet flat on floor'),
                _buildStep(theme, 'Brace core and squeeze glutes'),
                _buildStep(theme, 'Execute motion with control'),
                
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                      foregroundColor: theme.primaryColor,
                      elevation: 0,
                    ),
                    onPressed: () {
                      ref.read(workoutProvider.notifier).addExerciseToActiveSession(exercise.name);
                      SnackbarUtils.showCustomSnackBar(context, '${exercise.name} added to Tracker');
                      Navigator.pop(context);
                    },
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Add to Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
