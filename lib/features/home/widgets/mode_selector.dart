// Path: lib/features/home/widgets/mode_selector.dart
// Description: 4-button selector for Airport vs Event vs ColorWave vs Logo preset.
// UI Fix:
// - On small portrait screens, show icon TOP + text BOTTOM (vertical)
// - On normal/landscape/tablet, keep the current horizontal layout
// - ✅ Remove the checkmark icon entirely (no ✓)
// - ✅ Selection is indicated ONLY by color (Material handles it)
// - Logic unchanged (HomeMode + onChanged)

import 'package:flutter/material.dart';

enum HomeMode {
  airport,
  event,
  colorWave,
  logo,
}

class ModeSelector extends StatelessWidget {
  final HomeMode value;
  final ValueChanged<HomeMode> onChanged;

  final String airportLabel;
  final String eventLabel;
  final String colorWaveLabel;
  final String logoLabel;

  const ModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.airportLabel,
    required this.eventLabel,
    required this.colorWaveLabel,
    required this.logoLabel,
  });

  bool _useVerticalLayout(BuildContext context) {
    final mq = MediaQuery.of(context);

    // ✅ iPhone 13 mini / SE / 16e portrait widths are around 375–393 logical px.
    // Safer threshold so it actually triggers.
    final isPortrait = mq.orientation == Orientation.portrait;
    final isNarrow = mq.size.width <= 600; // 430
    return isPortrait && isNarrow;
  }

  bool _isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 700;
  }

  Widget _verticalLabel(IconData icon, String text, {required bool tablet}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tablet ? 6 : 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: tablet ? 24 : 16),
          SizedBox(height: tablet ? 6 : 3),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: tablet ? 16 : 11, height: 1.05),
          ),
        ],
      ),
    );
  }

  Widget _horizontalText(String text, {required bool tablet}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: tablet ? 16 : null,
        fontWeight: tablet ? FontWeight.w700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vertical = _useVerticalLayout(context);
    final tablet = _isTablet(context);
    final iconSize = tablet ? 24.0 : null;

    return SegmentedButton<HomeMode>(
      // ✅ Remove the default selected check icon
      showSelectedIcon: false,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.fromHeight(tablet ? 64 : 48)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: tablet ? 20 : 10,
            vertical: tablet ? 16 : 10,
          ),
        ),
      ),

      segments: [
        ButtonSegment(
          value: HomeMode.airport,
          // In vertical mode, put icon INSIDE label (top), so icon param must be null.
          icon: vertical ? null : Icon(Icons.flight_takeoff, size: iconSize),
          label: vertical
              ? _verticalLabel(Icons.flight_takeoff, airportLabel,
                  tablet: tablet)
              : _horizontalText(airportLabel, tablet: tablet),
        ),
        ButtonSegment(
          value: HomeMode.event,
          icon: vertical ? null : Icon(Icons.mic_none, size: iconSize),
          label: vertical
              ? _verticalLabel(Icons.mic_none, eventLabel, tablet: tablet)
              : _horizontalText(eventLabel, tablet: tablet),
        ),
        ButtonSegment(
          value: HomeMode.colorWave,
          icon: vertical ? null : Icon(Icons.palette_outlined, size: iconSize),
          label: vertical
              ? _verticalLabel(Icons.palette_outlined, colorWaveLabel,
                  tablet: tablet)
              : _horizontalText(colorWaveLabel, tablet: tablet),
        ),
        ButtonSegment(
          value: HomeMode.logo,
          icon: vertical ? null : Icon(Icons.image_outlined, size: iconSize),
          label: vertical
              ? _verticalLabel(Icons.image_outlined, logoLabel, tablet: tablet)
              : _horizontalText(logoLabel, tablet: tablet),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
