import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/timer_provider.dart';

class RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  RangeTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    // Prevent starting with 0 entirely
    if (newValue.text.startsWith('0')) {
      return oldValue;
    }

    final intValue = int.tryParse(newValue.text);
    if (intValue == null) return oldValue;
    
    if (intValue > max) {
      return TextEditingValue(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    }
    
    if (intValue < min) {
      return oldValue;
    }

    return newValue;
  }
}

class FocusTimer extends ConsumerStatefulWidget {
  const FocusTimer({super.key});

  @override
  ConsumerState<FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends ConsumerState<FocusTimer> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final timerState = ref.read(timerProvider);
    if (timerState.isRunning && !timerState.isPaused) return;

    final h = timerState.totalDurationSeconds ~/ 3600;
    final m = (timerState.totalDurationSeconds % 3600) ~/ 60;
    final s = timerState.totalDurationSeconds % 60;

    final hController = TextEditingController(text: h == 0 ? '' : h.toString());
    final mController = TextEditingController(text: m == 0 ? '' : m.toString());
    final sController = TextEditingController(text: s == 0 ? '' : s.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Edit Timer', style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(
                      controller: hController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RangeTextInputFormatter(1, 24),
                      ],
                      style: GoogleFonts.sora(color: Colors.white),
                      onTap: () {
                        if (hController.text.isNotEmpty) {
                          hController.selection = TextSelection(baseOffset: 0, extentOffset: hController.text.length);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Hr',
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: mController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RangeTextInputFormatter(1, 59),
                      ],
                      style: GoogleFonts.sora(color: Colors.white),
                      onTap: () {
                        if (mController.text.isNotEmpty) {
                          mController.selection = TextSelection(baseOffset: 0, extentOffset: mController.text.length);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Min',
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: sController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RangeTextInputFormatter(1, 59),
                      ],
                      style: GoogleFonts.sora(color: Colors.white),
                      onTap: () {
                        if (sController.text.isNotEmpty) {
                          sController.selection = TextSelection(baseOffset: 0, extentOffset: sController.text.length);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Sec',
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildQuickPreset(context, ref, '5m', 5 * 60),
                  _buildQuickPreset(context, ref, '10m', 10 * 60),
                  _buildQuickPreset(context, ref, '15m', 15 * 60),
                  _buildQuickPreset(context, ref, '25m', 25 * 60),
                  _buildQuickPreset(context, ref, '60m', 60 * 60),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.sora(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final h = int.tryParse(hController.text) ?? 0;
                final m = int.tryParse(mController.text) ?? 0;
                final s = int.tryParse(sController.text) ?? 0;
                final totalSeconds = h * 3600 + m * 60 + s;
                if (totalSeconds > 0) {
                  ref.read(timerProvider.notifier).setDuration(totalSeconds);
                }
                Navigator.of(context).pop();
              },
              child: Text('Save', style: GoogleFonts.sora(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickPreset(BuildContext context, WidgetRef ref, String label, int totalSeconds) {
    return InkWell(
      onTap: () {
        ref.read(timerProvider.notifier).setDuration(totalSeconds);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    
    if (timerState.isRinging) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    final isExpanded = timerState.isExpanded;
    final width = isExpanded ? 240.0 : 120.0;
    final height = isExpanded ? 80.0 : 36.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) {
            if (timerState.isRinging) {
              ref.read(timerProvider.notifier).stopAlarm();
            }
          },
          child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!timerState.isRinging) {
                ref.read(timerProvider.notifier).toggleExpanded();
              }
            },
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(isExpanded ? 30.0 : 18.0),
          border: isExpanded 
            ? Border.all(color: Colors.white.withValues(alpha: 0.05), width: 3.0)
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            if (timerState.isRinging)
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.6 * _pulseAnimation.value),
                blurRadius: 30 * _pulseAnimation.value,
                spreadRadius: 10 * _pulseAnimation.value,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isExpanded ? 27.0 : 18.0),
          child: Stack(
            children: [
              // Progress Border (when expanded)
              if (isExpanded)
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: timerState.progress),
                    duration: const Duration(seconds: 1),
                    curve: Curves.linear,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: BorderProgressPainter(
                          progress: value,
                          borderRadius: 27.0,
                          color: Colors.orange,
                          strokeWidth: 3.0,
                        ),
                      );
                    },
                  ),
                ),

              // Collapsed View
              if (!isExpanded)
                Align(
                  alignment: Alignment.center,
                  child: OverflowBox(
                    minWidth: 120.0,
                    maxWidth: 120.0,
                    minHeight: 36.0,
                    maxHeight: 36.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: timerState.progress),
                            duration: const Duration(seconds: 1),
                            curve: Curves.linear,
                            builder: (context, value, _) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 2.5,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                color: Colors.orange,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatTime(timerState.remainingSeconds),
                          style: GoogleFonts.sora(
                            color: timerState.isRunning ? Colors.orange : Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Expanded View
              if (isExpanded)
                Align(
                  alignment: Alignment.center,
                  child: OverflowBox(
                    minWidth: 240.0,
                    maxWidth: 240.0,
                    minHeight: 80.0,
                    maxHeight: 80.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Play / Pause / Resume Button
                        GestureDetector(
                          onTap: () {
                            if (!timerState.isRunning) {
                              ref.read(timerProvider.notifier).startTimer();
                            } else if (timerState.isPaused) {
                              ref.read(timerProvider.notifier).resumeTimer();
                            } else {
                              ref.read(timerProvider.notifier).pauseTimer();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              (!timerState.isRunning || timerState.isPaused) ? LucideIcons.play : LucideIcons.pause,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                        // Time Display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.bell, size: 10, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(timerState.totalDurationSeconds),
                                  style: GoogleFonts.sora(
                                    color: Colors.grey.shade400,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(timerState.remainingSeconds),
                              style: GoogleFonts.sora(
                                color: timerState.isRunning ? Colors.white : Colors.grey,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: (!timerState.isRunning || timerState.isPaused)
                                      ? () => _showEditDialog(context, ref)
                                      : null,
                                  child: Icon(
                                    LucideIcons.edit2,
                                    size: 14,
                                    color: (!timerState.isRunning || timerState.isPaused)
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(timerProvider.notifier).toggleNotification();
                                    },
                                    child: Icon(
                                      timerState.isNotificationEnabled ? LucideIcons.bellRing : LucideIcons.bellOff,
                                      size: 14,
                                      color: timerState.isNotificationEnabled ? Colors.orange : Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Stop / Cancel Button
                        GestureDetector(
                          onTap: () {
                            final isActive = timerState.isRunning || timerState.remainingSeconds < timerState.totalDurationSeconds;
                            ref.read(timerProvider.notifier).stopTimer();
                            if (!isActive) {
                              ref.read(timerProvider.notifier).toggleExpanded();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (timerState.isRunning || timerState.remainingSeconds < timerState.totalDurationSeconds)
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.x,
                              color: (timerState.isRunning || timerState.remainingSeconds < timerState.totalDurationSeconds)
                                  ? Colors.redAccent
                                  : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    )));
  },
);
  }
}

class BorderProgressPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final Color color;
  final double strokeWidth;

  BorderProgressPainter({
    required this.progress,
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width / 2, strokeWidth / 2)
      ..lineTo(size.width - borderRadius, strokeWidth / 2)
      ..arcToPoint(
        Offset(size.width - strokeWidth / 2, borderRadius),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(size.width - strokeWidth / 2, size.height - borderRadius)
      ..arcToPoint(
        Offset(size.width - borderRadius, size.height - strokeWidth / 2),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(borderRadius, size.height - strokeWidth / 2)
      ..arcToPoint(
        Offset(strokeWidth / 2, size.height - borderRadius),
        radius: Radius.circular(borderRadius),
      )
      ..lineTo(strokeWidth / 2, borderRadius)
      ..arcToPoint(
        Offset(borderRadius, strokeWidth / 2),
        radius: Radius.circular(borderRadius),
      )
      ..close();

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(
      0.0,
      pathMetrics.length * progress,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant BorderProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
