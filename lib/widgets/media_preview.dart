import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'media_viewer.dart';

class MediaPreview extends StatefulWidget {
  final String path;
  final double height;
  final double? width;
  final VoidCallback? onDelete;

  const MediaPreview({
    super.key,
    required this.path,
    this.height = 200,
    this.width = 160,
    this.onDelete,
  });

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  MediaType _type = MediaType.unknown;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  @override
  void didUpdateWidget(MediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      setState(() {
        _disposePlayers();
        _initMedia();
      });
    }
  }

  void _initMedia() {
    _identifyType();
    _initPlayer();
  }

  void _disposePlayers() {
    _videoController?.dispose();
    _videoController = null;
    _isPlaying = false;
  }

  void _identifyType() {
    final ext = widget.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      _type = MediaType.image;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      _type = MediaType.video;
    } else if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(ext)) {
      _type = MediaType.audio;
    } else {
      _type = MediaType.unknown;
    }
  }

  void _initPlayer() {
    if (_type == MediaType.video) {
      _videoController = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            onTap: () async {
              if (_type == MediaType.video && (_videoController?.value.isPlaying ?? false)) {
                await _videoController?.pause();
                setState(() {});
              }
              if (mounted) {
                MediaViewer.show(context, widget.path, _type);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildContent(context),
            ),
          ),
        ),
        if (widget.onDelete != null)
          Positioned(
            top: 8,
            right: 8,
            child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
              ),
            )),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (_type) {
      case MediaType.image:
        return Image.file(
          File(widget.path),
          height: widget.height,
          width: widget.width,
          fit: BoxFit.cover,
        );
      case MediaType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
            onTap: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
                if (!_videoController!.value.isPlaying)
                  const Icon(LucideIcons.play, size: 40, color: Colors.white70),
              ],
            ),
          ));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      case MediaType.audio:
        return Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.music, size: 40),
              const Gap(12),
              Text(
                widget.path.split(Platform.isWindows ? '\\' : '/').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.play),
                    onPressed: () => MediaViewer.show(context, widget.path, _type),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.file),
              const Gap(8),
              Text(
                widget.path.split(Platform.isWindows ? '\\' : '/').last,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
    }
  }
}
