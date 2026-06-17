import 'package:flutter/material.dart';

import '../../../models/sign_mode.dart';

class HandwritingSign extends StatelessWidget {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;
  final HandwritingStrokeStyle style;
  final bool preview;

  const HandwritingSign({
    super.key,
    required this.strokes,
    required this.color,
    required this.strokeWidth,
    this.style = HandwritingStrokeStyle.smooth,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandwritingPainter(
        strokes: strokes,
        color: color,
        strokeWidth: strokeWidth,
        style: style,
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
  final HandwritingStrokeStyle style;
  final bool preview;

  const _HandwritingPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
    required this.style,
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

    final glowOpacity = switch (style) {
      HandwritingStrokeStyle.neon => 0.48,
      HandwritingStrokeStyle.marker => 0.18,
      HandwritingStrokeStyle.chalk => 0.12,
      HandwritingStrokeStyle.smooth => 0.30,
    };
    final glowWidth = switch (style) {
      HandwritingStrokeStyle.neon => 2.25,
      HandwritingStrokeStyle.marker => 1.35,
      HandwritingStrokeStyle.chalk => 1.2,
      HandwritingStrokeStyle.smooth => 1.7,
    };
    final blur = switch (style) {
      HandwritingStrokeStyle.neon => 22.0,
      HandwritingStrokeStyle.marker => 9.0,
      HandwritingStrokeStyle.chalk => 5.0,
      HandwritingStrokeStyle.smooth => 16.0,
    };

    final glowPaint = Paint()
      ..color = color.withOpacity(glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * safeScale * glowWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    final mainPaint = Paint()
      ..color = style == HandwritingStrokeStyle.chalk
          ? color.withOpacity(0.82)
          : color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth *
          safeScale *
          (style == HandwritingStrokeStyle.marker ? 1.28 : 1.0);

    for (final stroke in strokes) {
      final path = _pathFor(stroke, safeScale, offset);
      canvas.drawPath(path, glowPaint);
    }

    for (final stroke in strokes) {
      final path = _pathFor(stroke, safeScale, offset);
      canvas.drawPath(path, mainPaint);
    }

    if (style == HandwritingStrokeStyle.chalk) {
      final dustPaint = Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth * safeScale * 0.38;
      for (final stroke in strokes) {
        final jittered = stroke
            .asMap()
            .entries
            .map(
              (entry) =>
                  entry.value +
                  Offset(
                    entry.key.isEven ? 1.2 : -1.2,
                    entry.key % 3 == 0 ? -1.1 : 1.1,
                  ),
            )
            .toList();
        canvas.drawPath(_pathFor(jittered, safeScale, offset), dustPaint);
      }
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
        oldDelegate.style != style ||
        oldDelegate.preview != preview;
  }
}
