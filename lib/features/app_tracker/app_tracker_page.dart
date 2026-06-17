import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../providers/app_tracker_provider.dart';
import '../../models/tracked_app.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

// Widgets
import 'widgets/activity_timeline.dart';
import 'widgets/live_tracking_card.dart';
import 'widgets/top_apps_list.dart';
import 'widgets/tracked_apps_table.dart';

class AppTrackerPage extends ConsumerStatefulWidget {
  const AppTrackerPage({super.key});

  @override
  ConsumerState<AppTrackerPage> createState() => _AppTrackerPageState();
}

class _AppTrackerPageState extends ConsumerState<AppTrackerPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showEditAppDialog(TrackedApp app) {
    final nameController = TextEditingController(text: app.name);
    bool isProductive = app.isProductive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            title: const Text('Edit App', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'App Name',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Is Productive?', style: TextStyle(color: Colors.white70)),
                    Switch(
                      value: isProductive,
                      onChanged: (val) => setState(() => isProductive = val),
                      activeColor: Colors.indigoAccent,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(appTrackerProvider.notifier).updateApp(app.copyWith(
                      name: name,
                      isProductive: isProductive,
                    ));
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF635BFF)),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appTrackerProvider);
    final theme = Theme.of(context);

    // Calculate total time today to display in the header
    int totalDaySecs = 0;
    for (var app in state.apps) {
      totalDaySecs += app.getTodayDurationSeconds();
      if (app.id == state.activeAppId && state.currentSessionStartTime != null) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        DateTime visibleStart = state.currentSessionStartTime!.isBefore(startOfDay) ? startOfDay : state.currentSessionStartTime!;
        totalDaySecs += now.difference(visibleStart).inSeconds;
      }
    }
    
    final hours = totalDaySecs ~/ 3600;
    final minutes = (totalDaySecs % 3600) ~/ 60;
    final timeString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Screen Time',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const Gap(16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.clock, size: 16, color: theme.primaryColor),
                      const Gap(8),
                      Text(
                        'Total Today: $timeString',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(32),
            
            // Dashboard Grid
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView(
                  children: [
                    // Hero Section: Activity Timeline
                    const SizedBox(
                      height: 350,
                      child: ActivityTimeline(),
                    ),
                    const Gap(24),
                    
                    // Middle Row: Live Tracking and Top Apps
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(
                            flex: 1,
                            child: LiveTrackingCard(),
                          ),
                          const Gap(24),
                          const Expanded(
                            flex: 1,
                            child: TopAppsList(),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),
                    
                    // Bottom Section: Tracked Apps Table
                    TrackedAppsTable(
                      onEditApp: (app) => _showEditAppDialog(app),
                    ),
                    const Gap(32), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
