import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/sign_config.dart';
import '../../../models/sign_mode.dart';

class EffectSign extends StatefulWidget {
  final SignConfig config;
  final bool preview;

  const EffectSign({
    super.key,
    required this.config,
    this.preview = false,
  });

  @override
  State<EffectSign> createState() => _EffectSignState();
}

class _EffectSignState extends State<EffectSign>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _fitFontSize({
    required BoxConstraints constraints,
    required String text,
    required double scale,
    required FontWeight weight,
    int maxLines = 3,
  }) {
    if (text.trim().isEmpty) return 40;
    final maxW = constraints.maxWidth * 0.9;
    final maxH = constraints.maxHeight * 0.72;
    double low = 12;
    double high = widget.preview ? 96 : 230;
    double best = 36;

    while ((high - low) > 1) {
      final mid = (low + high) / 2;
      final size = mid * scale.clamp(0.55, 1.7);
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: weight, height: 1.1),
        ),
        textAlign: TextAlign.center,
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxW);

      if (painter.size.width <= maxW && painter.size.height <= maxH) {
        best = size;
        low = mid;
      } else {
        high = mid;
      }
    }

    return best;
  }

  TextAlign _alignForConfig(SignConfig c) {
    if (c.usageMode == SignUsageMode.concert &&
        c.concertTextEffect != ConcertTextEffect.simple) {
      return TextAlign.center;
    }
    return c.textAlign;
  }

  Alignment _alignmentForText(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.center:
      case TextAlign.justify:
        return Alignment.center;
    }
  }

  Widget _plainText(SignConfig c, double fontSize, {List<Shadow>? shadows}) {
    final text = c.showIcon ? '✈ ${c.message ?? ''}' : c.message ?? '';
    final align = _alignForConfig(c);
    return Align(
      alignment: _alignmentForText(align),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          text,
          textAlign: align,
          maxLines: 3,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: c.textColor,
            fontSize: fontSize,
            fontWeight: c.bold ? FontWeight.w800 : FontWeight.w400,
            height: 1.08,
            shadows: shadows,
          ),
        ),
      ),
    );
  }

  Widget _neonText(SignConfig c, double fontSize) {
    final glow = c.neonGlowIntensity.clamp(0.0, 1.0);
    final glowColor = c.neonGlowColor;
    final shadows = [
      Shadow(color: glowColor.withOpacity(0.55 * glow), blurRadius: 10),
      Shadow(color: glowColor.withOpacity(0.45 * glow), blurRadius: 24),
      Shadow(color: glowColor.withOpacity(0.25 * glow), blurRadius: 42),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          c.message ?? '',
          textAlign: TextAlign.center,
          maxLines: 3,
          style: TextStyle(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = c.neonStrokeWidth.clamp(0.0, 6.0)
              ..color = glowColor.withOpacity(0.9),
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.08,
            shadows: shadows,
          ),
        ),
        Text(
          c.message ?? '',
          textAlign: TextAlign.center,
          maxLines: 3,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.08,
            shadows: shadows,
          ),
        ),
      ],
    );
  }

  Widget _pulseText(SignConfig c, double fontSize) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.75 + math.sin(_controller.value * math.pi * 2) * 0.25;
        return Transform.scale(
          scale: 0.98 + pulse * 0.04,
          child: Opacity(opacity: pulse.clamp(0.45, 1.0), child: child),
        );
      },
      child: _plainText(
        c,
        fontSize,
        shadows: [
          Shadow(color: c.textColor.withOpacity(0.8), blurRadius: 18),
          Shadow(color: c.textColor.withOpacity(0.35), blurRadius: 34),
        ],
      ),
    );
  }

  Widget _waveText(SignConfig c, double fontSize) {
    final chars = (c.message ?? '').characters.toList();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < chars.length; i++)
              Transform.translate(
                offset: Offset(
                  0,
                  math.sin((_controller.value * math.pi * 2) + i * 0.55) * 10,
                ),
                child: Text(
                  chars[i],
                  style: TextStyle(
                    color: c.textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: c.textColor.withOpacity(0.45),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _marqueeText(SignConfig c, double fontSize) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final left = c.marqueeDirection != MotionDirection.leftToRight;
          final speed = c.marqueeSpeed.clamp(20.0, 200.0);
          final travel = (_controller.value * (speed / 70)) % 1.0;
          final x = left ? 1.2 - travel * 2.4 : -1.2 + travel * 2.4;
          return FractionalTranslation(
            translation: Offset(x, 0),
            child: Center(
              child: Text(
                c.message ?? '',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: c.textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                        color: c.textColor.withOpacity(0.55), blurRadius: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ledSign(SignConfig c, double fontSize) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        double dx = 0;
        final dotPitch = c.ledDotSpacing.clamp(5.0, 14.0);
        if (c.ledAnimation == LedAnimation.scrollLeft) {
          dx = -_controller.value * dotPitch;
        } else if (c.ledAnimation == LedAnimation.scrollRight) {
          dx = _controller.value * dotPitch;
        }
        final pulse = c.ledAnimation == LedAnimation.pulse
            ? 0.72 + math.sin(_controller.value * math.pi * 2) * 0.22
            : 1.0;

        return Padding(
          padding: EdgeInsets.all(widget.preview ? 0 : 20),
          child: CustomPaint(
            painter: _LedMatrixPainter(
              message: c.message ?? '',
              color: c.ledColor,
              fontSize: fontSize,
              dotSize: c.ledDotSize,
              dotSpacing: c.ledDotSpacing,
              brightness: c.ledBrightness * pulse,
              glowIntensity: c.ledGlowIntensity,
              borderGlow: c.ledBorderGlow,
              scrollOffset: dx,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  Widget _concertContent(SignConfig c, BoxConstraints constraints) {
    final fontSize = _fitFontSize(
      constraints: constraints,
      text: c.message ?? '',
      scale: c.fontScale,
      weight: FontWeight.w800,
      maxLines: c.concertTextEffect == ConcertTextEffect.marquee ? 1 : 3,
    );

    switch (c.concertTextEffect) {
      case ConcertTextEffect.ledDotMatrix:
        return _ledSign(c, fontSize);
      case ConcertTextEffect.neonGlow:
        return _neonText(c, fontSize);
      case ConcertTextEffect.pulse:
        return _pulseText(c, fontSize);
      case ConcertTextEffect.marquee:
        return _marqueeText(c, fontSize);
      case ConcertTextEffect.wave:
        return Center(child: _waveText(c, fontSize * 0.85));
      case ConcertTextEffect.simple:
        return _plainText(c, fontSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (c.usageMode == SignUsageMode.concert) {
          return _concertContent(c, constraints);
        }

        final fontSize = _fitFontSize(
          constraints: constraints,
          text: c.message ?? '',
          scale: c.fontScale,
          weight: c.bold ? FontWeight.w800 : FontWeight.w400,
        );
        return _plainText(c, fontSize);
      },
    );
  }
}

class _LedMatrixPainter extends CustomPainter {
  final String message;
  final Color color;
  final double fontSize;
  final double dotSize;
  final double dotSpacing;
  final double brightness;
  final double glowIntensity;
  final double borderGlow;
  final double scrollOffset;

  const _LedMatrixPainter({
    required this.message,
    required this.color,
    required this.fontSize,
    required this.dotSize,
    required this.dotSpacing,
    required this.brightness,
    required this.glowIntensity,
    required this.borderGlow,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final panel = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    final glow = borderGlow.clamp(0.0, 1.0);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF05030B), Color(0xFF10091D), Color(0xFF020105)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(panel, bgPaint);

    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withOpacity(0.55 + 0.35 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 16 * glow),
    );
    canvas.drawRRect(
      panel.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.lerp(Colors.white, color, 0.42)!.withOpacity(0.55),
    );

    canvas.save();
    canvas.clipRRect(panel);
    _drawBackgroundDots(canvas, size);

    final painter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          height: 1.05,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.88);

    final textOffset = Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    painter.paint(canvas, textOffset);
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..blendMode = BlendMode.srcIn,
    );
    _drawLitDots(canvas, size);
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  void _drawBackgroundDots(Canvas canvas, Size size) {
    final pitch = dotSpacing.clamp(5.0, 14.0);
    final radius = (dotSize.clamp(2.0, 10.0) / 2).clamp(1.0, pitch / 2.8);
    final paint = Paint()..color = Colors.white.withOpacity(0.055);
    for (double y = pitch / 2; y < size.height; y += pitch) {
      for (double x = pitch / 2; x < size.width; x += pitch) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  void _drawLitDots(Canvas canvas, Size size) {
    final pitch = dotSpacing.clamp(5.0, 14.0);
    final radius = (dotSize.clamp(2.0, 10.0) / 2).clamp(1.0, pitch / 2.3);
    final b = brightness.clamp(0.15, 1.35);
    final lit = color.withOpacity((0.72 * b).clamp(0.15, 1.0));
    final hot = Color.lerp(Colors.white, color, 0.45)!
        .withOpacity((0.92 * b).clamp(0.2, 1.0));
    final glowPaint = Paint()
      ..color = color.withOpacity(0.22 * glowIntensity.clamp(0.0, 1.0) * b)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        7 * glowIntensity.clamp(0.0, 1.0),
      );
    final dotPaint = Paint()..color = lit;
    final hotPaint = Paint()..color = hot;
    final startX = (scrollOffset % pitch) - pitch;
    for (double y = pitch / 2; y < size.height; y += pitch) {
      for (double x = startX + pitch / 2; x < size.width + pitch; x += pitch) {
        final p = Offset(x, y);
        canvas.drawCircle(p, radius * 1.65, glowPaint);
        canvas.drawCircle(p, radius, dotPaint);
        canvas.drawCircle(p.translate(-radius * 0.25, -radius * 0.25),
            radius * 0.38, hotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LedMatrixPainter oldDelegate) {
    return oldDelegate.message != message ||
        oldDelegate.color != color ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.dotSize != dotSize ||
        oldDelegate.dotSpacing != dotSpacing ||
        oldDelegate.brightness != brightness ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.borderGlow != borderGlow ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}
