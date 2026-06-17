import 'package:flutter/material.dart';
import 'package:flutter_file_info/flutter_file_info.dart';
import '../../../models/tracked_app.dart';

class AppIconWidget extends StatelessWidget {
  final TrackedApp app;
  final double size;

  const AppIconWidget({
    super.key,
    required this.app,
    this.size = 24.0,
  });

  static final Map<String, Future<IconInfo?>> _futureCache = {};

  Future<IconInfo?> _getIconFuture() {
    final path = app.processPath!;
    if (!_futureCache.containsKey(path)) {
      _futureCache[path] = FileInfo.instance.getFileIconInfo(path);
    }
    return _futureCache[path]!;
  }

  @override
  Widget build(BuildContext context) {
    if (app.processPath == null || app.processPath!.isEmpty) {
      return _buildFallback();
    }

    return FutureBuilder<IconInfo?>(
      future: _getIconFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            // Instead of CircularProgressIndicator which might flash, just return an empty box
            // since the icon will load very quickly from disk.
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.pixelData.isEmpty) {
          return _buildFallback();
        }

        return Image.memory(
          snapshot.data!.pixelData,
          width: size,
          height: size,
          fit: BoxFit.contain,
          // Use gaplessPlayback to avoid flashing if the image provider changes (though it shouldn't)
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      },
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: app.color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }
}
