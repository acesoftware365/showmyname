// Path: lib/models/sign_config.dart
// Description: Configuration passed from Home -> Display.
// Supports text, motion (direction + style + speed), logo-only, and color-only presets.
// Update: Adds fontScale for auto-sized text + user manual size control.

import 'package:flutter/material.dart';
import 'sign_mode.dart';

class SignConfig {
  // Text
  final String? message;

  // Usage
  final SignUsageMode usageMode;

  // Type
  final SignType signType;

  // Concert/Event extras
  final bool colorShift;

  // Motion (Concert/Event)
  final MotionDirection motionDirection;
  final MotionStyle? motionStyle; // null => loop
  final double motionSpeed;

  // ✅ NEW: Manual font scaling (works with auto-size)
  // 1.0 = default, 0.8 smaller, 1.2 bigger, etc.
  final double fontScale;
  final Color textColor;
  final Color backgroundColor;
  final bool bold;
  final TextAlign textAlign;
  final bool showIcon;

  // Concert text effects
  final ConcertTextEffect concertTextEffect;
  final Color ledColor;
  final double ledGlowIntensity;
  final double ledBorderGlow;
  final double ledDotSize;
  final double ledDotSpacing;
  final double ledBrightness;
  final LedAnimation ledAnimation;
  final Color neonGlowColor;
  final double neonGlowIntensity;
  final double neonStrokeWidth;
  final double marqueeSpeed;
  final MotionDirection marqueeDirection;

  // Logo
  final bool showLogo;
  final String? logoPath;
  final List<String> logoPaths;
  final bool logoRotation;
  final LogoTransitionEffect logoEffect;
  final Duration logoHold;

  // Pro flag
  final bool isPro;

  // ColorWave (colorOnly)
  final Color? singleColor;
  final List<Color> cycleColors;
  final Duration colorHold; // time per color
  final ColorTransitionType colorTransition;
  final Duration transitionDuration;

  const SignConfig({
    this.message,
    required this.usageMode,
    required this.signType,

    // defaults
    this.colorShift = false,
    this.motionDirection = MotionDirection.none,
    this.motionStyle,
    this.motionSpeed = 60,

    // ✅ font scale default
    this.fontScale = 1.0,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.bold = true,
    this.textAlign = TextAlign.center,
    this.showIcon = false,
    this.concertTextEffect = ConcertTextEffect.simple,
    this.ledColor = const Color(0xFFB56CFF),
    this.ledGlowIntensity = 0.75,
    this.ledBorderGlow = 0.85,
    this.ledDotSize = 4,
    this.ledDotSpacing = 8,
    this.ledBrightness = 1,
    this.ledAnimation = LedAnimation.none,
    this.neonGlowColor = const Color(0xFFB56CFF),
    this.neonGlowIntensity = 0.8,
    this.neonStrokeWidth = 1.8,
    this.marqueeSpeed = 70,
    this.marqueeDirection = MotionDirection.rightToLeft,
    this.showLogo = false,
    this.logoPath,
    this.logoPaths = const <String>[],
    this.logoRotation = false,
    this.logoEffect = LogoTransitionEffect.fade,
    this.logoHold = const Duration(milliseconds: 1500),
    this.isPro = false,
    this.singleColor,
    this.cycleColors = const <Color>[],
    this.colorHold = const Duration(seconds: 3),
    this.colorTransition = ColorTransitionType.fade,
    this.transitionDuration = const Duration(milliseconds: 600),
  });

  bool get isColorOnly => signType == SignType.colorOnly;
  bool get isLogoOnly => signType == SignType.logoOnly;
}
