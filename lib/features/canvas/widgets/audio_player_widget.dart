import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../core/services/audio_manager.dart';

class CanvasAudioPlayer extends StatefulWidget {
  final String source;
  final String label;
  final Color color;

  const CanvasAudioPlayer({
    super.key,
    required this.source,
    required this.label,
    required this.color,
  });

  @override
  State<CanvasAudioPlayer> createState() => _CanvasAudioPlayerState();
}

class _CanvasAudioPlayerState extends State<CanvasAudioPlayer> {
  final _audioManager = CanvasAudioManager();

  @override
  void initState() {
    super.initState();
    _audioManager.addListener(_onManagerUpdate);
  }

  @override
  void dispose() {
    _audioManager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = _audioManager.currentSource == widget.source;
    final isPlaying = isCurrent && _audioManager.isPlaying;
    final position = isCurrent ? _audioManager.position : Duration.zero;
    final duration = isCurrent ? _audioManager.duration : Duration.zero;

    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onTap: () {}, // Prevent selection
      onPanStart: (_) {}, // Prevent drag
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                if (isPlaying) {
                  _audioManager.pause();
                } else {
                  _audioManager.play(widget.source);
                }
              },
              icon: Icon(
                isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: widget.color,
                size: 18,
              ),
              style: IconButton.styleFrom(
                backgroundColor: widget.color.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: SliderComponentShape.noOverlay,
                      activeTrackColor: widget.color,
                      inactiveTrackColor: widget.color.withValues(alpha: 0.1),
                      thumbColor: widget.color,
                    ),
                    child: SizedBox(
                      height: 20,
                      child: Slider(
                        min: 0,
                        max: duration.inMilliseconds.toDouble() > 0 
                            ? duration.inMilliseconds.toDouble() 
                            : 1.0,
                        value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                        onChanged: isCurrent ? (value) {
                          _audioManager.seek(Duration(milliseconds: value.toInt()));
                        } : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
