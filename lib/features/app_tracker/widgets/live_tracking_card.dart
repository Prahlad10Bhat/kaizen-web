import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../providers/app_tracker_provider.dart';
import '../../../models/tracked_app.dart';
import 'app_icon_widget.dart';

class LiveTrackingCard extends ConsumerStatefulWidget {
  const LiveTrackingCard({super.key});

  @override
  ConsumerState<LiveTrackingCard> createState() => _LiveTrackingCardState();
}

class _LiveTrackingCardState extends ConsumerState<LiveTrackingCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '< 1m';
    
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

    TrackedApp? activeApp;
    int currentSessionSecs = 0;
    int totalAppSecs = 0;

    if (state.activeAppId != null) {
      try {
        activeApp = state.apps.firstWhere((a) => a.id == state.activeAppId);
        if (state.currentSessionStartTime != null) {
          currentSessionSecs = DateTime.now().difference(state.currentSessionStartTime!).inSeconds;
        }
        totalAppSecs = activeApp.totalDurationSeconds + currentSessionSecs;
      } catch (e) {
        // App might have been deleted
      }
    }

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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state.isTrackingEnabled ? theme.primaryColor : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const Gap(8),
              Text(
                'Live Tracking',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                state.isTrackingEnabled ? 'Tracking Active' : 'Tracking Paused',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: state.isTrackingEnabled ? theme.primaryColor : theme.textTheme.bodySmall?.color,
                ),
              ),
              const Gap(8),
              Switch(
                value: state.isTrackingEnabled,
                onChanged: (val) {
                  ref.read(appTrackerProvider.notifier).toggleGlobalTracking();
                },
                activeColor: theme.primaryColor,
              ),
            ],
          ),
          const Gap(24),
          Text(
            'Current App',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
          ),
          const Gap(8),
          Row(
            children: [
              if (activeApp == null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.block, size: 16, color: theme.textTheme.bodySmall?.color),
                )
              else
                AppIconWidget(app: activeApp, size: 32),
              const Gap(12),
              Expanded(
                child: Text(
                  activeApp?.name ?? 'None',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(24),
          Text(
            'Session Duration',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
          ),
          const Gap(4),
          Text(
            activeApp == null ? '--' : _formatDuration(currentSessionSecs),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
