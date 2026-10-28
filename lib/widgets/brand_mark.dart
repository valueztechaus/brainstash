import 'package:flutter/material.dart';

import '../theme.dart';

/// The app icon drawn in code (spark dropping into a tray), so the lock and
/// empty screens need no image assets.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Brainstash',
      image: true,
      child: CustomPaint(size: Size.square(size), painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 1024;
    canvas.scale(s);
    final tray = Paint()
      ..color = AppColors.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 56
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final trayPath = Path()
      ..moveTo(272, 560)
      ..lineTo(272, 760)
      ..quadraticBezierTo(272, 800, 312, 800)
      ..lineTo(712, 800)
      ..quadraticBezierTo(752, 800, 752, 760)
      ..lineTo(752, 560);
    canvas.drawPath(trayPath, tray);
    final lip = Path()
      ..moveTo(272, 620)
      ..lineTo(400, 620)
      ..lineTo(440, 680)
      ..lineTo(584, 680)
      ..lineTo(624, 620)
      ..lineTo(752, 620);
    canvas.drawPath(lip, tray..strokeWidth = 40);
    canvas.drawPath(_spark(512, 160, 580, 312, 712, 370), Paint()..color = AppColors.amber);
  }

  Path _spark(double cx, double top, double bottom, double left, double right, double cy) {
    return Path()
      ..moveTo(cx, top)
      ..cubicTo(cx + 18, cy - 50, cx + 48, cy - 20, right, cy)
      ..cubicTo(cx + 48, cy + 20, cx + 18, cy + 50, cx, bottom)
      ..cubicTo(cx - 18, cy + 50, cx - 48, cy + 20, left, cy)
      ..cubicTo(cx - 48, cy - 20, cx - 18, cy - 50, cx, top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
