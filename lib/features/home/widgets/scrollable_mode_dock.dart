import 'package:flutter/material.dart';

/// Shows actionable edge hints only where dock items remain off screen.
class ScrollableModeDock extends StatefulWidget {
  const ScrollableModeDock({
    super.key,
    required this.child,
    this.selectedItemKey,
  });

  final Widget child;
  final GlobalKey? selectedItemKey;

  @override
  State<ScrollableModeDock> createState() => _ScrollableModeDockState();
}

class _ScrollableModeDockState extends State<ScrollableModeDock>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  late final AnimationController _hintMotion;
  late final Animation<double> _nudge;
  bool _before = false;
  bool _after = false;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _hintMotion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    _nudge = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 3.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 18),
      TweenSequenceItem(
          tween: Tween(begin: 3.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 18),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 18),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 3.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 18),
      TweenSequenceItem(
          tween: Tween(begin: 3.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 18),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
    ]).animate(_hintMotion);
    _controller.addListener(_refresh);
    _scheduleRefresh();
    _scheduleSelectedVisibility();
  }

  @override
  void didUpdateWidget(covariant ScrollableModeDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItemKey != widget.selectedItemKey) {
      _scheduleSelectedVisibility();
    }
  }

  void _scheduleRefresh() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (mounted) _refresh();
    });
  }

  void _scheduleSelectedVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final targetContext = widget.selectedItemKey?.currentContext;
      if (targetContext == null) return;
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      if (mounted) _refresh();
    });
  }

  void _refresh() {
    if (!_controller.hasClients || !_controller.position.hasContentDimensions)
      return;
    final position = _controller.position;
    final before = position.extentBefore > 1;
    final after = position.extentAfter > 1;
    if (before != _before || after != _after) {
      setState(() {
        _before = before;
        _after = after;
      });
      if ((before || after) && !MediaQuery.disableAnimationsOf(context)) {
        _hintMotion.forward(from: 0);
      } else {
        _hintMotion.reset();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _hintMotion.reset();
  }

  void _move(bool forward) {
    final position = _controller.position;
    final target = (position.pixels +
            (forward ? 1 : -1) * position.viewportDimension * 0.7)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
    } else {
      _controller.animateTo(target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    }
  }

  Widget _hint(bool forward) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final pointsRight = forward != rtl;
    final surface = Theme.of(context).colorScheme.surfaceContainerHigh;
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return PositionedDirectional(
      start: forward ? null : 1,
      end: forward ? 1 : null,
      top: 1,
      bottom: 1,
      width: 46,
      child: _DockHintTab(
        pointsRight: pointsRight,
        surface: surface,
        outline: outline,
        child: Tooltip(
          message: forward
              ? MaterialLocalizations.of(context).nextPageTooltip
              : MaterialLocalizations.of(context).previousPageTooltip,
          child: InkWell(
            key: ValueKey(forward ? 'dock-more-next' : 'dock-more-previous'),
            onTap: () => _move(forward),
            child: Center(
              child: AnimatedBuilder(
                animation: _nudge,
                builder: (context, child) => Transform.translate(
                  offset: Offset((pointsRight ? 1 : -1) * _nudge.value, 0),
                  child: child,
                ),
                child: Icon(
                    pointsRight ? Icons.chevron_right : Icons.chevron_left,
                    size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _scheduleRefresh();
        return false;
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            key: const ValueKey('sign-mode-bar'),
            padding: const EdgeInsets.all(6),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
          if (_before) _hint(false),
          if (_after) _hint(true),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hintMotion.dispose();
    _controller.dispose();
    super.dispose();
  }
}

/// A dock-edge tab whose inner border has a shallow concave arc. The arc
/// exposes the mode underneath while pointing in the direction of travel.
class _DockHintTab extends StatelessWidget {
  const _DockHintTab({
    required this.pointsRight,
    required this.surface,
    required this.outline,
    required this.child,
  });

  final bool pointsRight;
  final Color surface;
  final Color outline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DockHintTabBorderPainter(pointsRight, outline),
      child: ClipPath(
        clipper: _DockHintTabClipper(pointsRight),
        child: Material(color: surface, child: child),
      ),
    );
  }
}

Path _dockHintTabPath(Size size, bool pointsRight) {
  final width = size.width;
  final height = size.height;
  final radius = (height / 2).clamp(0.0, 22.0);
  final scoop = (width * 0.30).clamp(8.0, 14.0);
  final path = Path();

  if (pointsRight) {
    path
      ..moveTo(0, 0)
      ..lineTo(width - radius, 0)
      ..quadraticBezierTo(width, 0, width, radius)
      ..lineTo(width, height - radius)
      ..quadraticBezierTo(width, height, width - radius, height)
      ..lineTo(0, height)
      ..cubicTo(scoop, height * .74, scoop, height * .26, 0, 0);
  } else {
    path
      ..moveTo(radius, 0)
      ..lineTo(width, 0)
      ..cubicTo(width - scoop, height * .26, width - scoop, height * .74, width,
          height)
      ..lineTo(radius, height)
      ..quadraticBezierTo(0, height, 0, height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0);
  }
  return path..close();
}

class _DockHintTabClipper extends CustomClipper<Path> {
  const _DockHintTabClipper(this.pointsRight);
  final bool pointsRight;

  @override
  Path getClip(Size size) => _dockHintTabPath(size, pointsRight);

  @override
  bool shouldReclip(_DockHintTabClipper oldClipper) =>
      oldClipper.pointsRight != pointsRight;
}

class _DockHintTabBorderPainter extends CustomPainter {
  const _DockHintTabBorderPainter(this.pointsRight, this.color);
  final bool pointsRight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _dockHintTabPath(size, pointsRight),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DockHintTabBorderPainter oldDelegate) =>
      oldDelegate.pointsRight != pointsRight || oldDelegate.color != color;
}
