import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/app_tracker_provider.dart';
import '../../../models/tracked_app.dart';
import 'app_icon_widget.dart';

class ActivityTimeline extends ConsumerStatefulWidget {
  const ActivityTimeline({super.key});

  @override
  ConsumerState<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends ConsumerState<ActivityTimeline> {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appTrackerProvider);
    final theme = Theme.of(context);
    
    // Sort apps by total duration to show top ones
    final apps = List<TrackedApp>.from(state.apps)
      ..sort((a, b) => b.totalDurationSeconds.compareTo(a.totalDurationSeconds));
    final displayApps = apps.take(5).toList(); // Show top 5 apps in timeline

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
                'Activity Timeline',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),
          const Gap(24),
          Expanded(
            child: Row(
              children: [
                // Y-Axis Labels
                SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Need to align labels with rows in custom painter
                      const SizedBox(height: 24), // Offset for X axis labels
                      ...displayApps.map((app) => Expanded(
                        child: Row(
                          children: [
                            AppIconWidget(app: app, size: 16),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                app.name,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
                // Timeline chart
                Expanded(
                  child: Column(
                    children: [
                      // X-Axis Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(25, (index) {
                          if (index == 0 || index == 24) return _XAxisLabel('12a', theme);
                          if (index == 12) return _XAxisLabel('12p', theme);
                          if (index < 12) return _XAxisLabel('${index}a', theme);
                          return _XAxisLabel('${index - 12}p', theme);
                        }),
                      ),
                      const Gap(16),
                      Expanded(
                        child: CustomPaint(
                          painter: _TimelinePainter(
                            apps: displayApps,
                            activeAppId: state.activeAppId,
                            currentSessionStartTime: state.currentSessionStartTime,
                            theme: theme,
                          ),
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _XAxisLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4), fontSize: 10),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<TrackedApp> apps;
  final String? activeAppId;
  final DateTime? currentSessionStartTime;
  final ThemeData theme;

  _TimelinePainter({
    required this.apps,
    required this.activeAppId,
    required this.currentSessionStartTime,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final gridPaint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw vertical grid lines
    final numColumns = 24;
    for (int i = 0; i <= numColumns; i++) {
      final x = (size.width / numColumns) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal grid lines
    final numRows = apps.length;
    if (numRows == 0) return;

    for (int i = 0; i <= numRows; i++) {
      final y = (size.height / numRows) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw sessions
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final totalDaySeconds = 86400; // 24 hours

    for (int i = 0; i < apps.length; i++) {
      final app = apps[i];
      final yTop = (size.height / numRows) * i;
      final yBottom = (size.height / numRows) * (i + 1);
      final yCenter = (yTop + yBottom) / 2;
      final barHeight = 8.0;

      paint.color = app.color;

      void drawSession(DateTime start, DateTime end) {
        if (end.isBefore(startOfDay)) return; // Before today
        
        DateTime visibleStart = start.isBefore(startOfDay) ? startOfDay : start;
        DateTime visibleEnd = end;

        final startSecs = visibleStart.difference(startOfDay).inSeconds;
        final endSecs = visibleEnd.difference(startOfDay).inSeconds;

        final xStart = (startSecs / totalDaySeconds) * size.width;
        final xEnd = (endSecs / totalDaySeconds) * size.width;

        double cXStart = xStart.clamp(0.0, size.width);
        double cXEnd = xEnd.clamp(0.0, size.width);
        if (cXEnd - cXStart < 2.0) {
          cXEnd = math.min(size.width, cXStart + 2.0);
          cXStart = math.max(0.0, cXEnd - 2.0);
        }

        final rect = RRect.fromLTRBR(
          cXStart,
          yCenter - barHeight / 2,
          cXEnd,
          yCenter + barHeight / 2,
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, paint);
      }

      // Draw historical sessions
      for (final session in app.sessions) {
        drawSession(session.startTime, session.endTime);
      }

      // Draw active session
      if (app.id == activeAppId && currentSessionStartTime != null) {
        drawSession(currentSessionStartTime!, now);
        
        // Draw current time indicator line
        final nowSecs = now.difference(startOfDay).inSeconds;
        final xNow = (nowSecs / totalDaySeconds) * size.width;
        
        final indicatorPaint = Paint()
          ..color = const Color(0xFF635BFF)
          ..strokeWidth = 2;
        canvas.drawLine(Offset(xNow, 0), Offset(xNow, size.height), indicatorPaint);
        canvas.drawCircle(Offset(xNow, yCenter), 4, paint..color = theme.textTheme.bodyLarge?.color ?? Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return true; // We want to repaint to animate current time
  }
}
