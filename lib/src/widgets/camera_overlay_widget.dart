import 'package:flutter/material.dart';

/// Camera Overlay Widget
/// 
/// Provides visual guide for user positioning during avatar scanning.
/// Includes circular frame and foot markers to ensure proper placement.
class CameraOverlayWidget extends StatelessWidget {
  final bool isVisible;
  final Animation<double>? animation;
  final Color? color;

  const CameraOverlayWidget({
    super.key,
    required this.isVisible,
    this.animation,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: CustomPaint(
        painter: CameraOverlayPainter(
          color: color ?? Colors.white,
          animation: animation,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class CameraOverlayPainter extends CustomPainter {
  final Color color;
  final Animation<double>? animation;

  CameraOverlayPainter({
    required this.color,
    this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Circle radius (about 40% of the smaller dimension)
    final circleRadius = size.shortestSide * 0.25;
    
    // Apply animation scale if provided
    final scale = animation?.value ?? 1.0;
    final animatedRadius = circleRadius * scale;

    // Draw main positioning circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      animatedRadius,
      paint,
    );

    // Draw inner guide circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      animatedRadius * 0.7,
      paint,
    );

    // Draw crosshairs in the center
    final crosshairLength = animatedRadius * 0.1;
    canvas.drawLine(
      Offset(centerX - crosshairLength, centerY),
      Offset(centerX + crosshairLength, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crosshairLength),
      Offset(centerX, centerY + crosshairLength),
      paint,
    );

    // Draw foot markers
    _drawFootMarkers(canvas, centerX, centerY, animatedRadius);

    // Draw corner guides
    _drawCornerGuides(canvas, size, animatedRadius);
  }

  void _drawFootMarkers(Canvas canvas, double centerX, double centerY, double circleRadius) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Foot marker size and position
    final footMarkerWidth = circleRadius * 0.15;
    final footMarkerHeight = circleRadius * 0.08;
    final footOffsetY = circleRadius * 0.8;

    // Left foot marker
    _drawFootShape(
      canvas,
      Offset(centerX - circleRadius * 0.3, centerY + footOffsetY),
      footMarkerWidth,
      footMarkerHeight,
      paint,
      fillPaint,
    );

    // Right foot marker
    _drawFootShape(
      canvas,
      Offset(centerX + circleRadius * 0.3, centerY + footOffsetY),
      footMarkerWidth,
      footMarkerHeight,
      paint,
      fillPaint,
    );
  }

  void _drawFootShape(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final path = Path();
    
    // Draw a simple foot shape
    path.moveTo(center.dx - width * 0.5, center.dy + height * 0.5);
    path.lineTo(center.dx - width * 0.3, center.dy - height * 0.3);
    path.quadraticBezierTo(
      center.dx,
      center.dy - height * 0.5,
      center.dx + width * 0.3,
      center.dy - height * 0.3,
    );
    path.lineTo(center.dx + width * 0.5, center.dy + height * 0.5);
    path.close();

    // Fill and stroke
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawCornerGuides(Canvas canvas, Size size, double circleRadius) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cornerLength = circleRadius * 0.1;

    // Top-left corner
    canvas.drawLine(
      Offset(20, 20 + cornerLength),
      Offset(20, 20),
      paint,
    );
    canvas.drawLine(
      Offset(20, 20),
      Offset(20 + cornerLength, 20),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - 20, 20 + cornerLength),
      Offset(size.width - 20, 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 20, 20),
      Offset(size.width - 20 - cornerLength, 20),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(20, size.height - 20 - cornerLength),
      Offset(20, size.height - 20),
      paint,
    );
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(20 + cornerLength, size.height - 20),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20 - cornerLength),
      Offset(size.width - 20, size.height - 20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20),
      Offset(size.width - 20 - cornerLength, size.height - 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}