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

  @override
  Widget build(BuildContext context) {
    final items = [
      _ModeItem(HomeMode.airport, Icons.flight_takeoff, airportLabel),
      _ModeItem(HomeMode.event, Icons.mic_none, eventLabel),
      _ModeItem(HomeMode.colorWave, Icons.palette_outlined, colorWaveLabel),
      _ModeItem(HomeMode.handwriting, Icons.draw_outlined, handwritingLabel),
      _ModeItem(HomeMode.logo, Icons.image_outlined, logoLabel),
    ];

    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 5 : 3;
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final pillHeight =
            76.0 + 32.0 * (textScale - 1).clamp(0.0, double.infinity);
        Widget row(List<_ModeItem> rowItems) => Row(
              children: [
                for (var i = 0; i < rowItems.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(
                    child: _ModePill(
                      selected: rowItems[i].mode == value,
                      icon: rowItems[i].icon,
                      label: rowItems[i].label,
                      height: pillHeight,
                      onTap: () => onChanged(rowItems[i].mode),
                    ),
                  ),
                ],
              ],
            );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(items.take(columns).toList()),
            if (columns < items.length) ...[
              const SizedBox(height: gap),
              row(items.skip(columns).toList()),
            ],
          ],
        );
      },
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
  final double height;
  final VoidCallback onTap;

  const _ModePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        height: height,
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.28)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.95)
                : Colors.white.withOpacity(0.12),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: accent.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.check_circle_outline : icon,
                    size: 20,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      height: 1.05,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
