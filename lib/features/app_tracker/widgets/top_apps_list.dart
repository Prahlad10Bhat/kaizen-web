import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/app_tracker_provider.dart';
import 'app_icon_widget.dart';
import '../../../models/tracked_app.dart';

class TopAppsList extends ConsumerStatefulWidget {
  const TopAppsList({super.key});

  @override
  ConsumerState<TopAppsList> createState() => _TopAppsListState();
}

class _TopAppsListState extends ConsumerState<TopAppsList> {
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

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appTrackerProvider);
    final theme = Theme.of(context);
    
    int totalDaySecs = 0;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    for (var app in state.apps) {
      totalDaySecs += app.getTodayDurationSeconds();
      if (app.id == state.activeAppId && state.currentSessionStartTime != null) {
        DateTime visibleStart = state.currentSessionStartTime!.isBefore(startOfDay) ? startOfDay : state.currentSessionStartTime!;
        totalDaySecs += now.difference(visibleStart).inSeconds;
      }
    }

    final apps = List<TrackedApp>.from(state.apps)
      ..sort((a, b) {
        int durA = a.getTodayDurationSeconds();
        int durB = b.getTodayDurationSeconds();
        if (a.id == state.activeAppId && state.currentSessionStartTime != null) {
          DateTime visibleStart = state.currentSessionStartTime!.isBefore(startOfDay) ? startOfDay : state.currentSessionStartTime!;
          durA += now.difference(visibleStart).inSeconds;
        }
        if (b.id == state.activeAppId && state.currentSessionStartTime != null) {
          DateTime visibleStart = state.currentSessionStartTime!.isBefore(startOfDay) ? startOfDay : state.currentSessionStartTime!;
          durB += now.difference(visibleStart).inSeconds;
        }
        return durB.compareTo(durA);
      });
      
    final displayApps = apps.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top Apps Today',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(16),
          if (displayApps.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No apps tracked yet today.', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
              ),
            )
          else
            ...displayApps.map((app) {
              int duration = app.getTodayDurationSeconds();
              if (app.id == state.activeAppId && state.currentSessionStartTime != null) {
                DateTime visibleStart = state.currentSessionStartTime!.isBefore(startOfDay) ? startOfDay : state.currentSessionStartTime!;
                duration += now.difference(visibleStart).inSeconds;
              }
              final percent = totalDaySecs > 0 ? (duration / totalDaySecs) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    AppIconWidget(app: app, size: 24),
                    const Gap(12),
                    SizedBox(
                      width: 80,
                      child: Text(
                        app.name,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            widthFactor: percent.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: app.color,
                                ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    SizedBox(
                      width: 60,
                      child: Text(
                        _formatDuration(duration),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const Gap(8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(percent * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
