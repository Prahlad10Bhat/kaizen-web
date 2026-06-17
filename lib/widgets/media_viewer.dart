import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

enum MediaType { image, video, audio, unknown }

class MediaViewer extends StatefulWidget {
  final String path;
  final MediaType type;

  const MediaViewer({
    super.key,
    required this.path,
    required this.type,
  });

  static void show(BuildContext context, String path, MediaType type) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: MediaViewer(path: path, type: type),
        );
      },
    );
  }

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  void _initMedia() {
    if (widget.type == MediaType.video) {
      _videoController = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _position = _videoController!.value.position;
            _duration = _videoController!.value.duration;
            _isPlaying = _videoController!.value.isPlaying;
          });
        }
      });
    } else if (widget.type == MediaType.audio) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _audioPlayer!.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      });
      _audioPlayer!.play(DeviceFileSource(widget.path));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Close on background tap
          MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          )),

          // Main Content
          Center(
            child: Hero(
              tag: widget.path,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildMediaContent(),
                ),
              ),
            ),
          ),

          // Controls / Header
          Positioned(
            top: 40,
            right: 40,
            child: Row(
              children: [
                if (widget.type == MediaType.image)
                  IconButton(
                    onPressed: () async {
                      try {
                        await Pasteboard.writeFiles([widget.path]);
                        if (mounted) {
                          SnackbarUtils.showCustomSnackBar(context, 'Image copied to clipboard');
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackbarUtils.showCustomSnackBar(context, 'Failed to copy image', isError: true);
                        }
                      }
                    },
                    icon: const Icon(LucideIcons.copy, color: Colors.white, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black26,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                const Gap(12),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Footer Info
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(
                  widget.path.split(Platform.isWindows ? '\\' : '/').last,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (widget.type) {
      case MediaType.image:
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(widget.path), fit: BoxFit.contain),
        );
      case MediaType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              _buildVideoControls(),
            ],
          );
        }
        return const CircularProgressIndicator(color: Colors.white);
      case MediaType.audio:
        return Container(
          width: 400,
          height: 300,
          color: Colors.black87,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.music, size: 80, color: Colors.white70),
              const Gap(40),
              _buildAudioControls(),
            ],
          ),
        );
      default:
        return const Icon(LucideIcons.file, size: 100, color: Colors.white);
    }
  }

  Widget _buildVideoControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 0.01),
            max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 0.01,
            onChanged: (v) => _videoController!.seekTo(Duration(milliseconds: v.toInt())),
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 20),
                onPressed: () => _videoController!.seekTo(_position - const Duration(seconds: 5)),
              ),
              IconButton(
                icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play, color: Colors.white),
                onPressed: () => setState(() => _isPlaying ? _videoController!.pause() : _videoController!.play()),
              ),
              IconButton(
                icon: const Icon(LucideIcons.rotateCw, color: Colors.white, size: 20),
                onPressed: () => _videoController!.seekTo(_position + const Duration(seconds: 5)),
              ),
              const Spacer(),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 28),
                onPressed: () => _audioPlayer!.seek(_position - const Duration(seconds: 5)),
              ),
              const Gap(24),
              IconButton(
                icon: Icon(_isPlaying ? LucideIcons.pauseCircle : LucideIcons.playCircle, color: Colors.white, size: 56),
                onPressed: () => _isPlaying ? _audioPlayer!.pause() : _audioPlayer!.play(DeviceFileSource(widget.path)),
              ),
              const Gap(24),
              IconButton(
                icon: const Icon(LucideIcons.rotateCw, color: Colors.white, size: 28),
                onPressed: () => _audioPlayer!.seek(_position + const Duration(seconds: 5)),
              ),
            ],
          ),
          const Gap(24),
          Slider(
            value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 0.01),
            max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 0.01,
            onChanged: (v) => _audioPlayer!.seek(Duration(milliseconds: v.toInt())),
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
