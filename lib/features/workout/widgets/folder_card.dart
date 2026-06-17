import 'package:flutter/material.dart';

class FolderCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const FolderCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
          child: CustomPaint(
            painter: _FolderPainter(
              color: theme.cardColor,
              borderColor: _isHovered ? theme.primaryColor.withValues(alpha: 0.5) : theme.dividerColor,
            ),
            child: ClipPath(
              clipper: _FolderClipper(),
              child: Container(
                color: Colors.transparent, // Background painted by CustomPaint
                padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return _createFolderPath(size);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FolderPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _FolderPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createFolderPath(size);
    
    // Flat color background
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(path, paint);

    // Thin crisp border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FolderPainter oldDelegate) => false;
}

Path _createFolderPath(Size size) {
  final path = Path();
  const double radius = 20.0;
  final double tabWidth = size.width * 0.45;
  const double tabHeight = 16.0;

  // Start from top-left, after the radius
  path.moveTo(0, radius + tabHeight);

  // Top-left corner
  path.quadraticBezierTo(0, tabHeight, radius, tabHeight);

  // Line to where the tab starts to go up
  path.lineTo(size.width - tabWidth - radius, tabHeight);

  // Curve going UP into the tab
  path.quadraticBezierTo(
    size.width - tabWidth, tabHeight,
    size.width - tabWidth + (radius / 2), tabHeight / 2,
  );
  path.quadraticBezierTo(
    size.width - tabWidth + radius, 0,
    size.width - tabWidth + radius * 1.5, 0,
  );

  // Top edge of the tab
  path.lineTo(size.width - radius, 0);

  // Top-right corner of the tab
  path.quadraticBezierTo(size.width, 0, size.width, radius);

  // Right edge
  path.lineTo(size.width, size.height - radius);

  // Bottom-right corner
  path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);

  // Bottom edge
  path.lineTo(radius, size.height);

  // Bottom-left corner
  path.quadraticBezierTo(0, size.height, 0, size.height - radius);

  path.close();
  return path;
}
