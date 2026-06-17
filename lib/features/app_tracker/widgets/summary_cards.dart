import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../providers/app_tracker_provider.dart';

class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appTrackerProvider);
    final apps = state.apps;
    
    // Calculate Focus Time (for now, just sum of productive apps, or all apps if none productive)
    int focusTimeSeconds = 0;
    int totalTimeSeconds = 0;
    int sessionsCount = 0;
    String mostUsedAppName = '--';
    int maxDuration = -1;

    for (final app in apps) {
      // Calculate total time including active session
      int appDuration = app.totalDurationSeconds;
      if (app.id == state.activeAppId && state.currentSessionStartTime != null) {
        appDuration += DateTime.now().difference(state.currentSessionStartTime!).inSeconds;
      }
      
      totalTimeSeconds += appDuration;
      if (app.isProductive) {
        focusTimeSeconds += appDuration;
      }
      
      if (appDuration > maxDuration) {
        maxDuration = appDuration;
        mostUsedAppName = app.name;
      }

      sessionsCount += app.sessions.length;
      if (app.id == state.activeAppId) sessionsCount += 1;
    }

    // If no apps marked productive, use total time as a fallback for focus time
    if (focusTimeSeconds == 0 && apps.any((a) => !a.isProductive) == false) {
       focusTimeSeconds = totalTimeSeconds;
    }

    int productivityPercent = totalTimeSeconds > 0 
        ? ((focusTimeSeconds / totalTimeSeconds) * 100).round() 
        : 0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: LucideIcons.clock,
            iconColor: Colors.blueAccent,
            title: 'Focus Time',
            value: _formatDuration(focusTimeSeconds),
            subtitle: 'Total tracked today',
          ),
        ),
        const Gap(16),
        Expanded(
          child: _SummaryCard(
            icon: LucideIcons.star,
            iconColor: Colors.deepPurpleAccent,
            title: 'Most Used App',
            value: mostUsedAppName,
            subtitle: maxDuration >= 0 ? _formatDuration(maxDuration) : '--',
          ),
        ),
        const Gap(16),
        Expanded(
          child: _SummaryCard(
            icon: LucideIcons.activity,
            iconColor: Colors.indigoAccent,
            title: 'Productivity',
            value: '$productivityPercent%',
            subtitle: 'Based on productive apps',
          ),
        ),
        const Gap(16),
        Expanded(
          child: _SummaryCard(
            icon: LucideIcons.layoutGrid,
            iconColor: Colors.purpleAccent,
            title: 'Sessions',
            value: sessionsCount.toString(),
            subtitle: 'Total tracking sessions',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const Gap(4),
                    const Icon(LucideIcons.info, size: 12, color: Colors.white30),
                  ],
                ),
                const Gap(4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.greenAccent.withValues(alpha: 0.8), // Using green for positive trend look
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
