import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';

class FramePainter extends CustomPainter {
  final ui.Image frame;
  FramePainter(this.frame);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final side = frame.width < frame.height ? frame.width : frame.height;
    final src = Rect.fromLTWH(
      (frame.width - side) / 2.0,
      (frame.height - side) / 2.0,
      side.toDouble(),
      side.toDouble(),
    );
    final length = size.shortestSide;
    final dx = (size.width - length) / 2.0;
    final dy = (size.height - length) / 2.0;
    final dst = Rect.fromLTWH(dx, dy, length, length);
    canvas.drawImageRect(frame, src, dst, paint);
  }
  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) {
    return oldDelegate.frame != frame;
  }
}
