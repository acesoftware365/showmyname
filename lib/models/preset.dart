// Path: lib/models/preset.dart
// Description: Simple preset model for HomeScreen quick setup.

import 'sign_mode.dart';

enum PresetId { airportVip, eventVip }

class Preset {
  final PresetId id;
  final String defaultMessage;
  final SignUsageMode mode;

  final bool colorShift;
  final MotionDirection motionDirection;
  final MotionStyle motionStyle;
  final double motionSpeed;

  const Preset({
    required this.id,
    required this.defaultMessage,
    required this.mode,
    required this.colorShift,
    required this.motionDirection,
    required this.motionStyle,
    required this.motionSpeed,
  });

}
