// Path: lib/features/home/widgets/mode_selector.dart
// Description: Premium horizontal mode selector.

import 'package:flutter/material.dart';

enum HomeMode {
  airport,
  event,
  colorWave,
  handwriting,
  logo,
}

class ModeSelector extends StatelessWidget {
  final HomeMode value;
  final ValueChanged<HomeMode> onChanged;

  final String airportLabel;
  final String eventLabel;
  final String colorWaveLabel;
  final String handwritingLabel;
  final String logoLabel;

  const ModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.airportLabel,
    required this.eventLabel,
    required this.colorWaveLabel,
    required this.handwritingLabel,
    required this.logoLabel,
  });

  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 700;
  }

  @override
  Widget build(BuildContext context) {
    final tablet = _isTablet(context);
    final items = [
      _ModeItem(HomeMode.airport, Icons.flight_takeoff, airportLabel),
      _ModeItem(HomeMode.event, Icons.mic_none, eventLabel),
      _ModeItem(HomeMode.colorWave, Icons.palette_outlined, colorWaveLabel),
      _ModeItem(HomeMode.handwriting, Icons.draw_outlined, handwritingLabel),
      _ModeItem(HomeMode.logo, Icons.image_outlined, logoLabel),
    ];

    return SizedBox(
      height: tablet ? 92 : 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: tablet ? 12 : 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ModePill(
            selected: item.mode == value,
            icon: item.icon,
            label: item.label,
            tablet: tablet,
            onTap: () => onChanged(item.mode),
          );
        },
      ),
    );
  }
}

class _ModeItem {
  final HomeMode mode;
  final IconData icon;
  final String label;

  const _ModeItem(this.mode, this.icon, this.label);
}

class _ModePill extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final bool tablet;
  final VoidCallback onTap;

  const _ModePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.tablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final width = tablet ? 142.0 : 104.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      decoration: BoxDecoration(
        color: selected
            ? accent.withOpacity(0.28)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? accent.withOpacity(0.95)
              : Colors.white.withOpacity(0.12),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: accent.withOpacity(0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 12 : 8,
              vertical: tablet ? 12 : 9,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: tablet ? 26 : 20,
                  color: selected ? Colors.white : Colors.white70,
                ),
                SizedBox(height: tablet ? 7 : 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: tablet ? 15 : 11,
                    height: 1.05,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
