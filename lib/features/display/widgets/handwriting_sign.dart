import 'package:flutter/material.dart';

import '../../../models/sign_config.dart';
import '../../../models/sign_mode.dart';

class HandwritingSign extends StatelessWidget {
  final List<List<Offset>> strokes;
  final List<HandwritingLayer> layers;
  final Color color;
  final double strokeWidth;
  final HandwritingStrokeStyle style;
  final bool preview;
  final String emptyLabel;
  final bool fitToContent;

  const HandwritingSign({
    super.key,
    this.strokes = const <List<Offset>>[],
    this.layers = const <HandwritingLayer>[],
    required this.color,
    required this.strokeWidth,
    this.style = HandwritingStrokeStyle.smooth,
    this.preview = false,
    this.emptyLabel = 'Write a name',
    this.fitToContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLayers = layers.isEmpty
        ? <HandwritingLayer>[
            HandwritingLayer(
              strokes: strokes,
              color: color,
              strokeWidth: strokeWidth,
              style: style,
            ),
          ]
        : layers;
    final isEmpty = effectiveLayers
        .where((layer) => layer.visible)
        .every((layer) => layer.isEmpty);

    return CustomPaint(
      painter: _HandwritingPainter(
        layers: effectiveLayers,
        preview: preview,
        fitToContent: fitToContent,
      ),
      child: isEmpty
          ? Center(
              child: Text(
                emptyLabel,
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
  final List<HandwritingLayer> layers;
  final bool preview;
  final bool fitToContent;

  const _HandwritingPainter({
    required this.layers,
    required this.preview,
    required this.fitToContent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleLayers = layers
        .where((layer) => layer.visible && !layer.isEmpty)
        .toList(growable: false);
    if (visibleLayers.isEmpty) return;

    final bounds = _boundsFor(visibleLayers);
    if (bounds == null || bounds.width <= 0 || bounds.height <= 0) return;

    final double safeScale;
    final Offset offset;
    if (fitToContent) {
      final padding = preview ? 18.0 : 44.0;
      final scale = [
        (size.width - padding * 2) / bounds.width,
        (size.height - padding * 2) / bounds.height,
      ].reduce((a, b) => a < b ? a : b);
      safeScale = scale.isFinite ? scale.clamp(0.2, 12.0) : 1.0;
      final fitted = Size(bounds.width * safeScale, bounds.height * safeScale);
      offset = Offset(
        (size.width - fitted.width) / 2 - bounds.left * safeScale,
        (size.height - fitted.height) / 2 - bounds.top * safeScale,
      );
    } else {
      safeScale = 1.0;
      offset = Offset.zero;
    }

    for (final layer in visibleLayers) {
      _paintLayer(canvas, layer, safeScale, offset);
    }
  }

  void _paintLayer(
    Canvas canvas,
    HandwritingLayer layer,
    double safeScale,
    Offset offset,
  ) {
    final glowOpacity = switch (layer.style) {
      HandwritingStrokeStyle.fire => 0.54,
      HandwritingStrokeStyle.neon => 0.48,
      HandwritingStrokeStyle.marker => 0.18,
      HandwritingStrokeStyle.chalk => 0.12,
      HandwritingStrokeStyle.smooth => 0.30,
    };
    final glowWidth = switch (layer.style) {
      HandwritingStrokeStyle.fire => 2.65,
      HandwritingStrokeStyle.neon => 2.25,
      HandwritingStrokeStyle.marker => 1.35,
      HandwritingStrokeStyle.chalk => 1.2,
      HandwritingStrokeStyle.smooth => 1.7,
    };
    final blur = switch (layer.style) {
      HandwritingStrokeStyle.fire => 18.0,
      HandwritingStrokeStyle.neon => 22.0,
      HandwritingStrokeStyle.marker => 9.0,
      HandwritingStrokeStyle.chalk => 5.0,
      HandwritingStrokeStyle.smooth => 16.0,
    };

    final glowPaint = Paint()
      ..color = layer.style == HandwritingStrokeStyle.fire
          ? const Color(0xFFFF4D00).withOpacity(glowOpacity)
          : layer.color.withOpacity(glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = layer.strokeWidth * safeScale * glowWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    final mainPaint = Paint()
      ..color = layer.style == HandwritingStrokeStyle.chalk
          ? layer.color.withOpacity(0.82)
          : layer.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = layer.strokeWidth *
          safeScale *
          (layer.style == HandwritingStrokeStyle.marker ? 1.28 : 1.0);

    for (final stroke in layer.strokes) {
      final path = _pathFor(stroke, safeScale, offset);
      canvas.drawPath(path, glowPaint);
    }

    if (layer.style == HandwritingStrokeStyle.fire) {
      final emberPaint = Paint()
        ..color = const Color(0xFFFFE066).withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = layer.strokeWidth * safeScale * 0.45;
      final heatPaint = Paint()
        ..color = const Color(0xFFFF2D55).withOpacity(0.32)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = layer.strokeWidth * safeScale * 1.65
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      for (final stroke in layer.strokes) {
        final path = _pathFor(stroke, safeScale, offset);
        canvas.drawPath(path, heatPaint);
        canvas.drawPath(path, mainPaint);
        canvas.drawPath(path, emberPaint);
      }
    } else {
      for (final stroke in layer.strokes) {
        final path = _pathFor(stroke, safeScale, offset);
        canvas.drawPath(path, mainPaint);
      }
    }

    if (layer.style == HandwritingStrokeStyle.chalk) {
      final dustPaint = Paint()
        ..color = layer.color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = layer.strokeWidth * safeScale * 0.38;
      for (final stroke in layer.strokes) {
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

  Rect? _boundsFor(List<HandwritingLayer> layers) {
    Rect? rect;
    for (final layer in layers) {
      for (final stroke in layer.strokes) {
        for (final point in stroke) {
          final pointRect = Rect.fromCircle(center: point, radius: 1);
          rect = rect == null ? pointRect : rect.expandToInclude(pointRect);
        }
      }
    }
    return rect;
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return oldDelegate.layers != layers ||
        oldDelegate.preview != preview ||
        oldDelegate.fitToContent != fitToContent;
  }
}
