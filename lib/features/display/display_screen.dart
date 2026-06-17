// Path: lib/features/display/display_screen.dart
// Description: Fullscreen display for text/logo/colors.
// - Airport: text static (no motion)
// - Concert/Event: motionDirection + motionStyle(loop/bounce) + motionSpeed + colorShift
// - ColorWave: single/cycle colors with fade/slide
// - Logo: fullscreen
// - Text: auto-size to fit screen + optional manual fontScale
// - Exit: double tap anywhere

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/sign_config.dart';
import '../../models/sign_mode.dart';
import 'widgets/effect_sign.dart';

class DisplayScreen extends StatefulWidget {
  final SignConfig config;
  const DisplayScreen({super.key, required this.config});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen>
    with TickerProviderStateMixin {
  // ColorWave
  Timer? _timer;
  Timer? _logoTimer;
  int _colorIndex = 0;
  int _logoIndex = 0;
  Color _currentColor = Colors.black;

  // Rotate tip animation (portrait only)
  late final AnimationController _tipController;
  late final Animation<double> _tipFade;
  late final Animation<Offset> _tipSlide;
  late final AnimationController _wiggleController;
  late final Animation<double> _wiggleTurns;
  Orientation? _lastOrientation;

  // Motion
  AnimationController? _motionCtrl;
  Animation<Offset>? _motionOffset;

  // Color shift for Concert/Event text
  AnimationController? _colorCtrl;

  void _exit() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  void initState() {
    super.initState();
    _tipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _tipFade = CurvedAnimation(
      parent: _tipController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _tipSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tipController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _wiggleTurns = Tween<double>(
      begin: -45 / 360,
      end: 45 / 360,
    ).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );

    _initColorModeIfNeeded();
    _initLogoModeIfNeeded();
    _initMotionIfNeeded();
    _initTextColorShiftIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DisplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.config != widget.config) {
      _timer?.cancel();
      _colorIndex = 0;
      _currentColor = Colors.black;
      _initColorModeIfNeeded();

      _logoTimer?.cancel();
      _logoIndex = 0;
      _initLogoModeIfNeeded();

      _disposeMotion();
      _initMotionIfNeeded();

      _disposeColorShift();
      _initTextColorShiftIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoTimer?.cancel();
    _disposeMotion();
    _disposeColorShift();
    _tipController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  void _disposeMotion() {
    _motionCtrl?.stop();
    _motionCtrl?.dispose();
    _motionCtrl = null;
    _motionOffset = null;
  }

  void _disposeColorShift() {
    _colorCtrl?.stop();
    _colorCtrl?.dispose();
    _colorCtrl = null;
  }

  // ---------------------------
  // ColorWave
  // ---------------------------
  void _initColorModeIfNeeded() {
    final c = widget.config;
    if (!c.isColorOnly) return;

    if (c.singleColor != null) {
      _currentColor = c.singleColor!;
      return;
    }

    final colors = c.cycleColors;
    if (colors.isEmpty) {
      _currentColor = Colors.black;
      return;
    }

    _currentColor = colors.first;
    _colorIndex = 0;

    _timer?.cancel();
    _timer = Timer.periodic(c.colorHold + c.transitionDuration, (_) {
      if (!mounted) return;
      setState(() {
        _colorIndex = (_colorIndex + 1) % colors.length;
        _currentColor = colors[_colorIndex];
      });
    });
  }

  Widget _buildColorOnly(SignConfig c) {
    if (c.singleColor != null) return Container(color: c.singleColor);

    final duration = c.transitionDuration;

    if (c.colorTransition == ColorTransitionType.fade) {
      return AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOut,
        color: _currentColor,
      );
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, anim) {
        final offsetTween =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(anim);
        return SlideTransition(position: offsetTween, child: child);
      },
      child: Container(
        key: ValueKey(_currentColor.value),
        color: _currentColor,
      ),
    );
  }

  // ---------------------------
  // Logo fullscreen
  // ---------------------------
  void _initLogoModeIfNeeded() {
    final c = widget.config;
    if (!c.isLogoOnly) return;
    final paths = _logoPathsForConfig(c);
    if (!c.logoRotation || paths.length <= 1) return;

    _logoTimer?.cancel();
    _logoTimer = Timer.periodic(c.logoHold, (_) {
      if (!mounted) return;
      setState(() {
        _logoIndex = (_logoIndex + 1) % paths.length;
      });
    });
  }

  List<String> _logoPathsForConfig(SignConfig c) {
    if (c.logoPaths.isNotEmpty) return c.logoPaths;
    if (c.logoPath == null || c.logoPath!.isEmpty) return const <String>[];
    return [c.logoPath!];
  }

  Widget _buildLogoOnly(SignConfig c) {
    final paths = _logoPathsForConfig(c);
    if (paths.isEmpty) return const SizedBox.shrink();
    final activeIndex = _logoIndex.clamp(0, paths.length - 1).toInt();
    final activePath = paths[activeIndex];
    final file = File(activePath);
    if (!file.existsSync()) return const SizedBox.shrink();

    return Center(
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 6,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return switch (c.logoEffect) {
              LogoTransitionEffect.slide => SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(1.05, 0), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              LogoTransitionEffect.zoom => ScaleTransition(
                  scale: Tween<double>(begin: 0.55, end: 1).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
              LogoTransitionEffect.fade =>
                FadeTransition(opacity: anim, child: child),
            };
          },
          child: Image.file(
            file,
            key: ValueKey(activePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // Concert/Event Motion
  // ---------------------------
  void _initMotionIfNeeded() {
    final c = widget.config;

    // Airport rule: NO motion
    if (c.usageMode == SignUsageMode.airport) return;
    if (c.concertTextEffect != ConcertTextEffect.simple) return;

    if (c.motionDirection == MotionDirection.none) return;

    final style = c.motionStyle ?? MotionStyle.loop;
    final isBounce = style == MotionStyle.bounce;

    final speed = c.motionSpeed.clamp(20.0, 200.0);
    final durationMs = (14000 - (speed * 55)).clamp(3000, 14000).toInt();

    _motionCtrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: durationMs));

    // Travel distance: bounce looks better smaller
    final a = isBounce ? 0.65 : 1.2;

    Offset begin;
    Offset end;

    switch (c.motionDirection) {
      case MotionDirection.rightToLeft:
        begin = Offset(a, 0);
        end = Offset(-a, 0);
        break;
      case MotionDirection.leftToRight:
        begin = Offset(-a, 0);
        end = Offset(a, 0);
        break;
      case MotionDirection.bottomToTop:
        begin = Offset(0, a);
        end = Offset(0, -a);
        break;
      case MotionDirection.topToBottom:
        begin = Offset(0, -a);
        end = Offset(0, a);
        break;
      case MotionDirection.none:
        begin = Offset.zero;
        end = Offset.zero;
        break;
    }

    _motionOffset = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _motionCtrl!, curve: Curves.linear),
    );

    if (isBounce) {
      _motionCtrl!.repeat(reverse: true);
    } else {
      _motionCtrl!.repeat();
    }
  }

  // ---------------------------
  // Color Shift (Concert/Event only)
  // ---------------------------
  void _initTextColorShiftIfNeeded() {
    final c = widget.config;
    final shouldShift = c.usageMode != SignUsageMode.airport && c.colorShift;
    if (!shouldShift) return;

    _colorCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _colorCtrl!.repeat();
  }

  Color _shiftedTextColor() {
    final v = _colorCtrl?.value ?? 0.0; // 0..1
    return HSVColor.fromAHSV(1, v * 360.0, 1, 1).toColor();
  }

  // ---------------------------
  Widget _buildText(SignConfig c) {
    final shouldMove = c.usageMode != SignUsageMode.airport &&
        c.concertTextEffect == ConcertTextEffect.simple &&
        c.motionDirection != MotionDirection.none &&
        _motionCtrl != null &&
        _motionOffset != null;

    Widget text = AnimatedBuilder(
      animation: Listenable.merge([if (_colorCtrl != null) _colorCtrl!]),
      builder: (_, __) {
        final renderConfig = c.colorShift && _colorCtrl != null
            ? SignConfig(
                message: c.message,
                usageMode: c.usageMode,
                signType: c.signType,
                fontScale: c.fontScale,
                textColor: _shiftedTextColor(),
                backgroundColor: c.backgroundColor,
                bold: c.bold,
                textAlign: c.textAlign,
                showIcon: c.showIcon,
                concertTextEffect: c.concertTextEffect,
                ledColor: c.ledColor,
                ledGlowIntensity: c.ledGlowIntensity,
                ledBorderGlow: c.ledBorderGlow,
                ledDotSize: c.ledDotSize,
                ledDotSpacing: c.ledDotSpacing,
                ledBrightness: c.ledBrightness,
                ledAnimation: c.ledAnimation,
                neonGlowColor: c.neonGlowColor,
                neonGlowIntensity: c.neonGlowIntensity,
                neonStrokeWidth: c.neonStrokeWidth,
                marqueeSpeed: c.marqueeSpeed,
                marqueeDirection: c.marqueeDirection,
                colorShift: c.colorShift,
                motionDirection: c.motionDirection,
                motionStyle: c.motionStyle,
                motionSpeed: c.motionSpeed,
                isPro: c.isPro,
              )
            : c;
        return EffectSign(config: renderConfig);
      },
    );

    if (!shouldMove) {
      return text;
    }

    return ClipRect(
      child: AnimatedBuilder(
        animation: _motionCtrl!,
        builder: (_, __) {
          return FractionalTranslation(
            translation: _motionOffset!.value,
            child: Center(child: text),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = widget.config;
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      if (isPortrait) {
        _tipController.forward();
        if (!_wiggleController.isAnimating) {
          _wiggleController.repeat(reverse: true);
        }
      } else {
        _tipController.reverse();
        _wiggleController.stop();
      }
    }

    final Widget content = c.isColorOnly
        ? _buildColorOnly(c)
        : c.isLogoOnly
            ? _buildLogoOnly(c)
            : _buildText(c);

    return Scaffold(
      backgroundColor: c.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _exit,
        child: Stack(
          children: [
            Positioned.fill(child: content),
            if (isPortrait)
              Positioned(
                left: 16,
                right: 16,
                top: 18,
                child: SafeArea(
                  bottom: false,
                  child: FadeTransition(
                    opacity: _tipFade,
                    child: SlideTransition(
                      position: _tipSlide,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 16,
                              offset: Offset(0, 10),
                              color: Colors.black45,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            RotationTransition(
                              turns: _wiggleTurns,
                              child: const Icon(Icons.screen_rotation,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.rotateToLandscapeBubble,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: Text(
                  t.tapToExit,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
