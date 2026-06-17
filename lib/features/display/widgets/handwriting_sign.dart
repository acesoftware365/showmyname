import 'package:flutter/material.dart';

class HandwritingSign extends StatelessWidget {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;
  final bool preview;

  const HandwritingSign({
    super.key,
    required this.strokes,
    required this.color,
    required this.strokeWidth,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandwritingPainter(
        strokes: strokes,
        color: color,
        strokeWidth: strokeWidth,
        preview: preview,
      ),
      child: strokes.isEmpty
          ? Center(
              child: Text(
                'Write a name',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.34),
                  fontWeight: FontWeight.w800,
                  fontSize: preview ? 22 : 42,
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

class _HandwritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;
  final bool preview;

  const _HandwritingPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
    required this.preview,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    final bounds = _boundsFor(strokes);
    if (bounds == null || bounds.width <= 0 || bounds.height <= 0) return;

    final padding = preview ? 18.0 : 44.0;
    final scale = [
      (size.width - padding * 2) / bounds.width,
      (size.height - padding * 2) / bounds.height,
    ].reduce((a, b) => a < b ? a : b);
    final safeScale = scale.isFinite ? scale.clamp(0.2, 12.0) : 1.0;
    final fitted = Size(bounds.width * safeScale, bounds.height * safeScale);
    final offset = Offset(
      (size.width - fitted.width) / 2 - bounds.left * safeScale,
      (size.height - fitted.height) / 2 - bounds.top * safeScale,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * safeScale * 1.7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * safeScale;

    for (final stroke in strokes) {
      final path = _pathFor(stroke, safeScale, offset);
      canvas.drawPath(path, glowPaint);
    }

    for (final stroke in strokes) {
      final path = _pathFor(stroke, safeScale, offset);
      canvas.drawPath(path, mainPaint);
    }
  }

  Path _pathFor(List<Offset> stroke, double scale, Offset offset) {
    final path = Path();
    if (stroke.isEmpty) return path;
    path.moveTo(stroke.first.dx * scale + offset.dx,
        stroke.first.dy * scale + offset.dy);
    for (var i = 1; i < stroke.length; i++) {
      path.lineTo(
          stroke[i].dx * scale + offset.dx, stroke[i].dy * scale + offset.dy);
    }
    return path;
  }

  Rect? _boundsFor(List<List<Offset>> strokes) {
    Rect? rect;
    for (final stroke in strokes) {
      for (final point in stroke) {
        final pointRect = Rect.fromCircle(center: point, radius: 1);
        rect = rect == null ? pointRect : rect!.expandToInclude(pointRect);
      }
    }
    return rect;
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.preview != preview;
  }
}
