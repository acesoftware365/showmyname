// Path: lib/models/sign_mode.dart
// Description: Shared enums for modes/types/motion/colors.

enum SignUsageMode {
  airport,
  concert,
}

enum SignType {
  textOnly, // airport: texto estático
  textMotion, // concert/event: texto con movimiento
  logoOnly, // logo fullscreen
  colorOnly, // ColorWave: colores fullscreen
  handwritingOnly, // handwritten name fullscreen
}

enum MotionDirection {
  none,
  rightToLeft,
  leftToRight,
  bottomToTop,
  topToBottom,
}

// ✅ NEW: Motion style for Concert/Event
enum MotionStyle {
  loop,
  bounce,
}

enum ColorTransitionType {
  fade,
  slide,
}

enum ConcertTextEffect {
  simple,
  ledDotMatrix,
  neonGlow,
  pulse,
  marquee,
  wave,
}

enum LedAnimation {
  none,
  pulse,
  scrollLeft,
  scrollRight,
}

enum LogoTransitionEffect {
  fade,
  slide,
  zoom,
}

enum HandwritingStrokeStyle {
  smooth,
  marker,
  neon,
  chalk,
}
