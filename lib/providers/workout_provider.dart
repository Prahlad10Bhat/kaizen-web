import 'package:flutter_riverpod/flutter_riverpod.dart';

class MuscleRecovery {
  final String name;
  final double recoveryPercentage;
  final String lastTrained;
  final int weeklyVolume;
  final int monthlyVolume;
  final List<double> recoveryTrend; // 7 values for recovery trend graph
  final List<String> primaryExercises;

  MuscleRecovery({
    required this.name,
    required this.recoveryPercentage,
    required this.lastTrained,
    required this.weeklyVolume,
    required this.monthlyVolume,
    required this.recoveryTrend,
    required this.primaryExercises,
  });

  MuscleRecovery copyWith({
    String? name,
    double? recoveryPercentage,
    String? lastTrained,
    int? weeklyVolume,
    int? monthlyVolume,
    List<double>? recoveryTrend,
    List<String>? primaryExercises,
  }) {
    return MuscleRecovery(
      name: name ?? this.name,
      recoveryPercentage: recoveryPercentage ?? this.recoveryPercentage,
      lastTrained: lastTrained ?? this.lastTrained,
      weeklyVolume: weeklyVolume ?? this.weeklyVolume,
      monthlyVolume: monthlyVolume ?? this.monthlyVolume,
      recoveryTrend: recoveryTrend ?? this.recoveryTrend,
      primaryExercises: primaryExercises ?? this.primaryExercises,
    );
  }
}

class ExerciseLog {
  final String date;
  final String setsReps;
  final String weight;

  ExerciseLog({
    required this.date,
    required this.setsReps,
    required this.weight,
  });
}

class ExerciseStats {
  final String name;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String pr;
  final String est1RM;
  final List<ExerciseLog> history;
  final List<double> volumeHistory; // 5 values for history graph

  ExerciseStats({
    required this.name,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.pr,
    required this.est1RM,
    required this.history,
    required this.volumeHistory,
  });
}

class WorkoutLog {
  final String date; // YYYY-MM-DD
  final String splitName;
  final String duration;
  final int exercisesCount;

  WorkoutLog({
    required this.date,
    required this.splitName,
    required this.duration,
    required this.exercisesCount,
  });
}

class WorkoutRoutine {
  final String id;
  final String name;
  final List<String> exercises;
  final bool isCustom;
  final bool isPinned;
  final bool isFolder;

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exercises,
    this.isCustom = false,
    this.isPinned = false,
    this.isFolder = false,
  });

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    List<String>? exercises,
    bool? isCustom,
    bool? isPinned,
    bool? isFolder,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      isCustom: isCustom ?? this.isCustom,
      isPinned: isPinned ?? this.isPinned,
      isFolder: isFolder ?? this.isFolder,
    );
  }
}

class WorkoutSet {
  String weight;
  String reps;
  bool isCompleted;

  WorkoutSet({this.weight = '', this.reps = '', this.isCompleted = false});

  WorkoutSet copyWith({String? weight, String? reps, bool? isCompleted}) {
    return WorkoutSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ActiveExercise {
  final String name;
  final List<WorkoutSet> sets;

  ActiveExercise({required this.name, required this.sets});

  ActiveExercise copyWith({String? name, List<WorkoutSet>? sets}) {
    return ActiveExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
    );
  }
}

class ActiveWorkoutSession {
  final String name;
  final DateTime? startTime;
  final List<ActiveExercise> exercises;

  ActiveWorkoutSession({
    required this.name,
    this.startTime,
    required this.exercises,
  });

  ActiveWorkoutSession copyWith({
    String? name,
    DateTime? startTime,
    List<ActiveExercise>? exercises,
    bool clearStartTime = false,
  }) {
    return ActiveWorkoutSession(
      name: name ?? this.name,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      exercises: exercises ?? this.exercises,
    );
  }
}

class WorkoutState {
  final List<MuscleRecovery> muscles;
  final List<ExerciseStats> exercises;
  final List<WorkoutLog> logs;
  final List<WorkoutRoutine> routines;
  final int currentStreak;
  final int longestStreak;
  final double monthlyCompletionRate;
  final ActiveWorkoutSession? activeSession;

  WorkoutState({
    required this.muscles,
    required this.exercises,
    required this.logs,
    required this.routines,
    required this.currentStreak,
    required this.longestStreak,
    required this.monthlyCompletionRate,
    this.activeSession,
  });

  WorkoutState copyWith({
    List<MuscleRecovery>? muscles,
    List<ExerciseStats>? exercises,
    List<WorkoutLog>? logs,
    List<WorkoutRoutine>? routines,
    int? currentStreak,
    int? longestStreak,
    double? monthlyCompletionRate,
    ActiveWorkoutSession? activeSession,
    bool clearActiveSession = false,
  }) {
    return WorkoutState(
      muscles: muscles ?? this.muscles,
      exercises: exercises ?? this.exercises,
      logs: logs ?? this.logs,
      routines: routines ?? this.routines,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      monthlyCompletionRate: monthlyCompletionRate ?? this.monthlyCompletionRate,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
    );
  }
}

class WorkoutNotifier extends Notifier<WorkoutState> {
  @override
  WorkoutState build() {
    // Initial muscles state with varying recovery percentages to color code the anatomy map
    final initialMuscles = [
      MuscleRecovery(
        name: 'Chest',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Bench Press', 'Incline Bench Press', 'Cable Fly'],
      ),
      MuscleRecovery(
        name: 'Upper Chest',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Incline Bench Press'],
      ),
      MuscleRecovery(
        name: 'Back',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Pull Ups', 'Barbell Row'],
      ),
      MuscleRecovery(
        name: 'Lats',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Pull Ups', 'Barbell Row'],
      ),
      MuscleRecovery(
        name: 'Traps',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Barbell Row'],
      ),
      MuscleRecovery(
        name: 'Front Delts',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Bench Press', 'Overhead Press'],
      ),
      MuscleRecovery(
        name: 'Side Delts',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Lateral Raise', 'Overhead Press'],
      ),
      MuscleRecovery(
        name: 'Rear Delts',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Pull Ups'],
      ),
      MuscleRecovery(
        name: 'Biceps',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Dumbbell Curl', 'Pull Ups'],
      ),
      MuscleRecovery(
        name: 'Triceps',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Skull Crushers', 'Bench Press', 'Overhead Press'],
      ),
      MuscleRecovery(
        name: 'Forearms',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Dumbbell Curl', 'Pull Ups'],
      ),
      MuscleRecovery(
        name: 'Abs',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Cable Crunch', 'Squat'],
      ),
      MuscleRecovery(
        name: 'Obliques',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Cable Crunch'],
      ),
      MuscleRecovery(
        name: 'Glutes',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Squat', 'Romanian Deadlift'],
      ),
      MuscleRecovery(
        name: 'Quads',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Squat'],
      ),
      MuscleRecovery(
        name: 'Hamstrings',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Romanian Deadlift'],
      ),
      MuscleRecovery(
        name: 'Calves',
        recoveryPercentage: 100.0,
        lastTrained: 'Never',
        weeklyVolume: 0,
        monthlyVolume: 0,
        recoveryTrend: [100, 100, 100, 100, 100, 100, 100],
        primaryExercises: ['Calf Raises'],
      ),
    ];

    final initialExercises = [
      ExerciseStats(name: 'Bench Press', primaryMuscle: 'Chest', secondaryMuscles: ['Triceps', 'Front Delts'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Incline Bench Press', primaryMuscle: 'Upper Chest', secondaryMuscles: ['Triceps', 'Front Delts'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Dumbbell Bench Press', primaryMuscle: 'Chest', secondaryMuscles: ['Triceps', 'Front Delts'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Machine Chest Press', primaryMuscle: 'Chest', secondaryMuscles: ['Triceps', 'Front Delts'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Push Ups', primaryMuscle: 'Chest', secondaryMuscles: ['Triceps', 'Front Delts', 'Core'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Cable Fly', primaryMuscle: 'Chest', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Pec Deck', primaryMuscle: 'Chest', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Pull Ups', primaryMuscle: 'Lats', secondaryMuscles: ['Biceps', 'Rear Delts'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Barbell Row', primaryMuscle: 'Lats', secondaryMuscles: ['Traps', 'Biceps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Deadlift', primaryMuscle: 'Back', secondaryMuscles: ['Glutes', 'Hamstrings', 'Core'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'T-Bar Row', primaryMuscle: 'Back', secondaryMuscles: ['Lats', 'Biceps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Seated Cable Row', primaryMuscle: 'Back', secondaryMuscles: ['Lats', 'Biceps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Lat Pulldown', primaryMuscle: 'Lats', secondaryMuscles: ['Biceps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Straight Arm Pulldown', primaryMuscle: 'Lats', secondaryMuscles: ['Triceps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Squat', primaryMuscle: 'Quads', secondaryMuscles: ['Glutes', 'Abs'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Front Squat', primaryMuscle: 'Quads', secondaryMuscles: ['Glutes', 'Core'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Leg Press', primaryMuscle: 'Quads', secondaryMuscles: ['Glutes'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Lunges', primaryMuscle: 'Quads', secondaryMuscles: ['Glutes', 'Hamstrings'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Bulgarian Split Squat', primaryMuscle: 'Quads', secondaryMuscles: ['Glutes'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Romanian Deadlift', primaryMuscle: 'Hamstrings', secondaryMuscles: ['Glutes', 'Calves'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Leg Curl', primaryMuscle: 'Hamstrings', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Leg Extension', primaryMuscle: 'Quads', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Lateral Raise', primaryMuscle: 'Side Delts', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Overhead Press', primaryMuscle: 'Front Delts', secondaryMuscles: ['Side Delts', 'Triceps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Dumbbell Shoulder Press', primaryMuscle: 'Front Delts', secondaryMuscles: ['Side Delts', 'Triceps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Front Raise', primaryMuscle: 'Front Delts', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Face Pulls', primaryMuscle: 'Rear Delts', secondaryMuscles: ['Traps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Reverse Pec Deck', primaryMuscle: 'Rear Delts', secondaryMuscles: ['Traps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Upright Row', primaryMuscle: 'Side Delts', secondaryMuscles: ['Traps'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Cable Crunch', primaryMuscle: 'Abs', secondaryMuscles: ['Obliques'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Plank', primaryMuscle: 'Abs', secondaryMuscles: ['Core'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Hanging Leg Raise', primaryMuscle: 'Abs', secondaryMuscles: ['Hip Flexors'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Russian Twists', primaryMuscle: 'Obliques', secondaryMuscles: ['Abs'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Dumbbell Curl', primaryMuscle: 'Biceps', secondaryMuscles: ['Forearms'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Hammer Curl', primaryMuscle: 'Biceps', secondaryMuscles: ['Forearms'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Preacher Curl', primaryMuscle: 'Biceps', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Concentration Curl', primaryMuscle: 'Biceps', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Skull Crushers', primaryMuscle: 'Triceps', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Tricep Pushdown', primaryMuscle: 'Triceps', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Overhead Tricep Extension', primaryMuscle: 'Triceps', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Close Grip Bench Press', primaryMuscle: 'Triceps', secondaryMuscles: ['Chest', 'Front Delts'], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Calf Raises', primaryMuscle: 'Calves', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
      ExerciseStats(name: 'Seated Calf Raise', primaryMuscle: 'Calves', secondaryMuscles: [], pr: '', est1RM: '', history: [], volumeHistory: [0, 0, 0, 0, 0]),
    ];

    // Mock workout logs for consistency tracking heatmap
    final now = DateTime.now();
    final initialLogs = <WorkoutLog>[
      WorkoutLog(date: now.toIso8601String().substring(0, 10), splitName: 'PPL: Pull Day', duration: '1h 15m', exercisesCount: 6),
      WorkoutLog(date: now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10), splitName: 'PPL: Push Day', duration: '1h 05m', exercisesCount: 5),
      WorkoutLog(date: now.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10), splitName: 'PPL: Leg Day', duration: '1h 20m', exercisesCount: 6),
      WorkoutLog(date: now.subtract(const Duration(days: 4)).toIso8601String().substring(0, 10), splitName: 'PPL: Pull Day', duration: '1h 10m', exercisesCount: 5),
      WorkoutLog(date: now.subtract(const Duration(days: 5)).toIso8601String().substring(0, 10), splitName: 'PPL: Push Day', duration: '1h 00m', exercisesCount: 5),
      WorkoutLog(date: now.subtract(const Duration(days: 7)).toIso8601String().substring(0, 10), splitName: 'PPL: Leg Day', duration: '1h 15m', exercisesCount: 6),
      WorkoutLog(date: now.subtract(const Duration(days: 8)).toIso8601String().substring(0, 10), splitName: 'PPL: Pull Day', duration: '1h 05m', exercisesCount: 6),
      WorkoutLog(date: now.subtract(const Duration(days: 9)).toIso8601String().substring(0, 10), splitName: 'PPL: Push Day', duration: '55m', exercisesCount: 5),
      WorkoutLog(date: now.subtract(const Duration(days: 11)).toIso8601String().substring(0, 10), splitName: 'PPL: Leg Day', duration: '1h 25m', exercisesCount: 6),
      WorkoutLog(date: now.subtract(const Duration(days: 12)).toIso8601String().substring(0, 10), splitName: 'PPL: Pull Day', duration: '1h 12m', exercisesCount: 6),
      WorkoutLog(date: now.subtract(const Duration(days: 14)).toIso8601String().substring(0, 10), splitName: 'PPL: Push Day', duration: '1h 02m', exercisesCount: 5),
    ];
    final initialRoutines = <WorkoutRoutine>[
      // Push / Pull / Legs (PPL)
      WorkoutRoutine(
        id: 'ppl_push',
        name: 'PPL: Push Day',
        exercises: ['Bench Press (4x5-8)', 'Overhead Press (3x8-10)', 'Incline Bench Press (3x8-12)', 'Lateral Raise (4x12-15)', 'Tricep Pushdown (3x10-15)', 'Skull Crushers (3x10-12)'],
      ),
      WorkoutRoutine(
        id: 'ppl_pull',
        name: 'PPL: Pull Day',
        exercises: ['Pull Ups (3xAMRAP)', 'Barbell Row (3x8-10)', 'Lat Pulldown (3x10-12)', 'Face Pulls (3x15-20)', 'Dumbbell Curl (3x10-12)', 'Hammer Curl (3x10-12)'],
      ),
      WorkoutRoutine(
        id: 'ppl_legs',
        name: 'PPL: Leg Day',
        exercises: ['Squat (4x5-8)', 'Romanian Deadlift (3x8-10)', 'Leg Press (3x10-12)', 'Leg Curl (3x12-15)', 'Calf Raises (4x15-20)', 'Cable Crunch (3x15-20)'],
      ),
      
      // Upper / Lower Split
      WorkoutRoutine(
        id: 'ul_upper',
        name: 'Upper/Lower: Upper Body',
        exercises: ['Bench Press (4x5-8)', 'Barbell Row (4x5-8)', 'Overhead Press (3x8-10)', 'Lat Pulldown (3x8-12)', 'Lateral Raise (3x12-15)', 'Dumbbell Curl (3x10-12)', 'Tricep Pushdown (3x10-12)'],
      ),
      WorkoutRoutine(
        id: 'ul_lower',
        name: 'Upper/Lower: Lower Body',
        exercises: ['Squat (4x5-8)', 'Romanian Deadlift (4x5-8)', 'Leg Press (3x10-12)', 'Leg Curl (3x10-12)', 'Calf Raises (4x15-20)', 'Cable Crunch (3x15-20)'],
      ),

      // Arnold Split
      WorkoutRoutine(
        id: 'arnold_chest_back',
        name: 'Arnold: Chest & Back',
        exercises: ['Bench Press (4x5-8)', 'Pull Ups (4x8-10)', 'Incline Bench Press (3x8-12)', 'Barbell Row (3x8-12)', 'Cable Fly (3x12-15)', 'Lat Pulldown (3x10-15)'],
      ),
      WorkoutRoutine(
        id: 'arnold_shoulders_arms',
        name: 'Arnold: Shoulders & Arms',
        exercises: ['Overhead Press (4x5-8)', 'Lateral Raise (4x12-15)', 'Face Pulls (3x15-20)', 'Dumbbell Curl (3x10-12)', 'Skull Crushers (3x10-12)', 'Hammer Curl (3x10-12)', 'Tricep Pushdown (3x10-12)'],
      ),
      WorkoutRoutine(
        id: 'arnold_legs',
        name: 'Arnold: Legs',
        exercises: ['Squat (4x5-8)', 'Romanian Deadlift (3x8-10)', 'Leg Extension (3x12-15)', 'Leg Curl (3x12-15)', 'Calf Raises (4x15-20)', 'Cable Crunch (3x15-20)'],
      ),

      // Bro Split (Body Part Split)
      WorkoutRoutine(
        id: 'bro_chest',
        name: 'Bro Split: Chest Day',
        exercises: ['Bench Press (4x5-8)', 'Incline Bench Press (4x8-12)', 'Cable Fly (4x12-15)'],
      ),
      WorkoutRoutine(
        id: 'bro_back',
        name: 'Bro Split: Back Day',
        exercises: ['Pull Ups (4xAMRAP)', 'Barbell Row (4x8-10)', 'Lat Pulldown (4x10-12)'],
      ),
      WorkoutRoutine(
        id: 'bro_shoulders',
        name: 'Bro Split: Shoulder Day',
        exercises: ['Overhead Press (4x5-8)', 'Lateral Raise (4x12-15)', 'Face Pulls (4x15-20)'],
      ),
      WorkoutRoutine(
        id: 'bro_arms',
        name: 'Bro Split: Arm Day',
        exercises: ['Dumbbell Curl (4x10-12)', 'Hammer Curl (3x10-12)', 'Skull Crushers (4x10-12)', 'Tricep Pushdown (3x10-12)'],
      ),
      WorkoutRoutine(
        id: 'bro_legs',
        name: 'Bro Split: Leg Day',
        exercises: ['Squat (4x5-8)', 'Leg Press (3x10-12)', 'Romanian Deadlift (4x8-10)', 'Leg Extension (3x12-15)', 'Leg Curl (3x12-15)', 'Calf Raises (4x15-20)'],
      ),

      // Full Body
      WorkoutRoutine(
        id: 'full_body_a',
        name: 'Full Body: Workout A',
        exercises: ['Squat (3x5)', 'Bench Press (3x5)', 'Barbell Row (3x5)', 'Lateral Raise (3x10-12)', 'Calf Raises (3x15-20)'],
      ),
      WorkoutRoutine(
        id: 'full_body_b',
        name: 'Full Body: Workout B',
        exercises: ['Romanian Deadlift (3x5)', 'Overhead Press (3x5)', 'Lat Pulldown (3x8-10)', 'Dumbbell Curl (3x10-12)', 'Tricep Pushdown (3x10-12)'],
      ),
    ];

    return WorkoutState(
      muscles: initialMuscles,
      exercises: initialExercises,
      logs: initialLogs,
      routines: initialRoutines,
      currentStreak: 2,
      longestStreak: 5,
      monthlyCompletionRate: 0.72, // 72%
    );
  }

  void addWorkoutLog(String splitName, String duration, int exercisesCount) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    // Check if already logged today
    if (state.logs.any((l) => l.date == todayStr)) return;

    final newLog = WorkoutLog(
      date: todayStr,
      splitName: splitName,
      duration: duration,
      exercisesCount: exercisesCount,
    );

    // Update muscle recovery scores as a result of the logged workout
    final updatedMuscles = state.muscles.map((m) {
      if (splitName.toLowerCase().contains('push') && (m.name == 'Chest' || m.name == 'Upper Chest' || m.name == 'Triceps' || m.name == 'Front Delts')) {
        return _fatigueMuscle(m);
      } else if (splitName.toLowerCase().contains('pull') && (m.name == 'Back' || m.name == 'Lats' || m.name == 'Rear Delts' || m.name == 'Biceps' || m.name == 'Traps')) {
        return _fatigueMuscle(m);
      } else if (splitName.toLowerCase().contains('leg') && (m.name == 'Glutes' || m.name == 'Quads' || m.name == 'Hamstrings' || m.name == 'Calves')) {
        return _fatigueMuscle(m);
      } else if (splitName.toLowerCase().contains('shoulder') && (m.name == 'Side Delts' || m.name == 'Front Delts' || m.name == 'Rear Delts')) {
        return _fatigueMuscle(m);
      }
      return m;
    }).toList();

    state = state.copyWith(
      logs: [newLog, ...state.logs],
      muscles: updatedMuscles,
      currentStreak: state.currentStreak + 1,
      longestStreak: (state.currentStreak + 1) > state.longestStreak ? (state.currentStreak + 1) : state.longestStreak,
    );
  }

  MuscleRecovery _fatigueMuscle(MuscleRecovery m) {
    // Drop recovery percentage immediately to show fatigue effect
    final newPercentage = (m.recoveryPercentage - 50.0).clamp(10.0, 100.0);
    final trend = List<double>.from(m.recoveryTrend);
    trend.removeAt(0);
    trend.add(newPercentage);
    
    return m.copyWith(
      recoveryPercentage: newPercentage,
      lastTrained: 'Today',
      recoveryTrend: trend,
    );
  }

  void addRoutine(String name, List<String> exercises) {
    final newRoutine = WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      exercises: exercises,
      isCustom: true,
    );
    state = state.copyWith(
      routines: [...state.routines, newRoutine],
    );
  }

  void createFolder(String name) {
    final newFolder = WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      exercises: [],
      isCustom: true,
      isFolder: true,
    );
    state = state.copyWith(
      routines: [...state.routines, newFolder],
    );
  }

  void moveRoutineToFolder(String routineId, String folderName) {
    state = state.copyWith(
      routines: state.routines.map((r) {
        if (r.id == routineId && !r.isFolder) {
          final baseName = r.name.contains(':') ? r.name.split(':')[1].trim() : r.name;
          return r.copyWith(name: '$folderName : $baseName');
        }
        return r;
      }).toList(),
    );
  }

  void updateRoutine(String id, String name, List<String> exercises) {
    state = state.copyWith(
      routines: state.routines.map((r) {
        if (r.id == id) {
          return r.copyWith(name: name, exercises: exercises);
        }
        return r;
      }).toList(),
    );
  }

  void deleteRoutine(String id) {
    state = state.copyWith(
      routines: state.routines.where((r) => r.id != id).toList(),
    );
  }

  void togglePinRoutine(String id) {
    state = state.copyWith(
      routines: state.routines.map((r) => r.id == id ? r.copyWith(isPinned: !r.isPinned) : r).toList(),
    );
  }

  void modifyStandardRoutine(WorkoutRoutine routine) {
    final cleanName = routine.name.contains(':') ? routine.name.split(':')[1].trim() : routine.name;
    final newRoutine = WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '$cleanName (Custom)',
      exercises: List.from(routine.exercises),
      isCustom: true,
      isPinned: false,
    );
    state = state.copyWith(
      routines: [...state.routines, newRoutine],
    );
  }

  void startActiveSession({String? name, List<String>? exercises}) {
    final activeExercises = (exercises ?? []).map((e) {
      int setsCount = 1;
      final match = RegExp(r'\((\d+)[xX]').firstMatch(e);
      if (match != null) {
        setsCount = int.tryParse(match.group(1)!) ?? 1;
      }
      return ActiveExercise(name: e, sets: List.generate(setsCount, (_) => WorkoutSet()));
    }).toList();

    state = state.copyWith(
      activeSession: ActiveWorkoutSession(
        name: name ?? 'Free Workout',
        startTime: null,
        exercises: activeExercises,
      ),
    );
  }

  void beginWorkoutTimer() {
    if (state.activeSession != null && state.activeSession!.startTime == null) {
      state = state.copyWith(
        activeSession: state.activeSession!.copyWith(startTime: DateTime.now()),
      );
    }
  }

  void addExerciseToActiveSession(String exerciseName) {
    if (state.activeSession == null) {
      // Create one if none exists
      startActiveSession(name: 'Free Workout', exercises: [exerciseName]);
      return;
    }
    
    // Check if it exists
    final currentSession = state.activeSession!;
    if (currentSession.exercises.any((e) => e.name == exerciseName)) return;

    final updatedExercises = [...currentSession.exercises, ActiveExercise(name: exerciseName, sets: [WorkoutSet()])];
    state = state.copyWith(
      activeSession: currentSession.copyWith(exercises: updatedExercises),
    );
  }

  void updateActiveSessionExercises(List<ActiveExercise> updatedExercises) {
    if (state.activeSession == null) return;
    state = state.copyWith(
      activeSession: state.activeSession!.copyWith(exercises: updatedExercises),
    );
  }

  void clearActiveSession() {
    state = state.copyWith(clearActiveSession: true);
  }
}

final workoutProvider = NotifierProvider<WorkoutNotifier, WorkoutState>(() {
  return WorkoutNotifier();
});
