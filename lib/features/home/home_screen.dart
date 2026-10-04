// Path: lib/features/home/home_screen.dart
// Description: Main screen.
// - 4 presets: Airport / Event / ColorWave / Logo
// - Logo preset includes Upload/Remove/Preview card (moved from Settings)
// - Text Size only for Airport/Event
// - Show button opens Logo fullscreen when Logo preset is selected
// Update:
// - Center "Rotate to landscape" bubble (Option A: once per session, only in portrait) with longer on-screen time
// - After bubble hides, show a small persistent rotate hint under the Show button (portrait only) with a wiggle icon
// - ✅ Adds AdMob TEST Banner at the bottom (FREE only) using AdBanner widget

import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../ads/rewarded_ad_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sign_config.dart';
import '../../models/sign_mode.dart';
import '../display/widgets/handwriting_sign.dart';
import '../../services/logo/logo_storage_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/subscription/subscription_manager.dart';
import 'widgets/mode_selector.dart';
import 'widgets/scrollable_mode_dock.dart';
import '../display/display_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _UnlockLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _UnlockLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, height: 1.28),
          ),
        ),
      ],
    );
  }
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _airportController = TextEditingController(text: 'Welcome 😊 VIP ⭐ 👉');
  final _eventController = TextEditingController(text: 'LIVE TONIGHT 🎤 VIP');
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _createdImageKey = GlobalKey();
  final _modeItemKeys = {
    for (final mode in HomeMode.values) mode: GlobalKey(),
  };

  static const String _appleUrl =
      'https://apps.apple.com/us/app/showmyname-display/id6758596742';
  static const String _googleUrl =
      'https://play.google.com/store/apps/details?id=com.liisgo.showmyname&utm_source=na_Med';
  static const String _liisgoWebsite = 'https://liisgo.com';
  static const int _maxHandwritingLayers = 5;

  // ✅ Presets
  HomeMode _homeMode = HomeMode.airport;

  // Map to your existing enums
  SignUsageMode _mode = SignUsageMode.airport;
  SignType _type = SignType.textOnly;

  // Airport options
  double _airportFontScale = 1.0;
  bool _airportBold = true;
  bool _airportItalic = false;
  bool _airportUnderline = false;
  int _adjustmentTab = 0;
  bool _compactEditorOpen = false;
  TextAlign _airportTextAlign = TextAlign.center;
  bool _airportShowIcon = false;
  String _airportIconSymbol = '✈';

  // Event options
  MotionDirection _motionDirection = MotionDirection.none;
  MotionStyle _motionStyle = MotionStyle.loop;
  double _motionSpeed = 60;
  bool _colorShift = false;
  double _eventFontScale = 1.0;
  ConcertTextEffect _concertTextEffect = ConcertTextEffect.ledDotMatrix;
  Color _ledColor = const Color(0xFFB56CFF);
  double _ledGlowIntensity = 0.75;
  double _ledBorderGlow = 0.85;
  double _ledDotSize = 4;
  double _ledDotSpacing = 8;
  double _ledBrightness = 1.0;
  LedAnimation _ledAnimation = LedAnimation.none;
  Color _neonGlowColor = const Color(0xFFB56CFF);
  double _neonGlowIntensity = 0.8;
  double _neonStrokeWidth = 1.8;
  double _marqueeSpeed = 70;
  MotionDirection _marqueeDirection = MotionDirection.rightToLeft;

  Color _airportTextColor = Colors.white;
  Color _airportBackgroundColor = Colors.black;
  Color _eventTextColor = Colors.white;
  Color _eventBackgroundColor = Colors.black;

  // Logo
  final ImagePicker _picker = ImagePicker();
  String? _logoPath;
  List<String> _logoPaths = const <String>[];
  bool _logoRotation = false;
  LogoTransitionEffect _logoEffect = LogoTransitionEffect.fade;
  double _logoHoldSeconds = 1.5;

  // Handwriting
  final List<List<Offset>> _handwritingStrokes = <List<Offset>>[];
  Color _handwritingColor = Colors.white;
  Color _handwritingBackgroundColor = Colors.black;
  double _handwritingStrokeWidth = 10;
  HandwritingStrokeStyle _handwritingStyle = HandwritingStrokeStyle.smooth;
  final List<HandwritingLayer> _handwritingLayers = <HandwritingLayer>[
    HandwritingLayer(strokeWidth: 10),
    HandwritingLayer(
      color: Color(0xFF00D4FF),
      strokeWidth: 12,
      style: HandwritingStrokeStyle.neon,
    ),
    HandwritingLayer(
      color: Color(0xFFFF7A00),
      strokeWidth: 14,
      style: HandwritingStrokeStyle.fire,
    ),
  ];
  int _activeHandwritingLayer = 0;
  final List<List<HandwritingLayer>> _handwritingUndoStack =
      <List<HandwritingLayer>>[];
  final List<List<HandwritingLayer>> _handwritingRedoStack =
      <List<HandwritingLayer>>[];

  // Pro
  bool _loading = false;
  bool _isPro = false;
  StreamSubscription<bool>? _proSub;
  final Set<String> _rewardUnlockedFeatures = <String>{};
  bool _modeChangeInProgress = false;
  HomeMode? _queuedMode;

  // ✅ ColorWave options
  bool _colorCycle = true; // false = single, true = cycle
  Color _singleColor = const Color(0xFF7C3AED);
  final List<Color> _cycleColors = const [
    Color(0xFF7C3AED),
    Color(0xFFB56CFF),
    Color(0xFF2563EB),
    Color(0xFFEC4899),
  ].toList();
  double _holdSeconds = 3;
  ColorTransitionType _transitionType = ColorTransitionType.fade;
  double _transitionMs = 600;

  // ✅ Landscape tip bubble (Option A: once per session)
  static bool _rotateTipShownThisSession = false;
  late final AnimationController _tipController;
  late final Animation<double> _tipFade;
  late final Animation<Offset> _tipSlide;
  bool _tipVisible = false;

  // ✅ Persistent rotate hint (after bubble)
  bool _persistentRotateHint = false;
  bool _narrowHandwritingEditorOpen = false;
  bool _narrowHandwritingEditorCloseScheduled = false;
  late final AnimationController _wiggleController;
  late final Animation<double> _wiggleTurns; // rotation turns

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tipController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Wiggle icon for persistent hint
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // -45°..+45° approximately: turns = degrees/360
    _wiggleTurns = Tween<double>(
      begin: -45 / 360,
      end: 45 / 360,
    ).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );

    _loadState();
    _proSub = SubscriptionManager.proStream.listen((isPro) {
      if (!mounted) return;
      setState(() => _isPro = isPro);
    });
    _applyHomeMode(HomeMode.airport);

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRotateTip());
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!_narrowHandwritingEditorOpen ||
        _narrowHandwritingEditorCloseScheduled) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_narrowHandwritingEditorOpen ||
          _narrowHandwritingEditorCloseScheduled) {
        return;
      }

      final view = View.of(context);
      final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
      if (logicalWidth < 600) return;

      _narrowHandwritingEditorCloseScheduled = true;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  HandwritingLayer get _activeLayer =>
      _handwritingLayers[_activeHandwritingLayer];

  bool get _hasHandwriting =>
      _handwritingLayers.any((layer) => layer.visible && !layer.isEmpty);

  void _replaceActiveHandwritingLayer(HandwritingLayer layer) {
    _handwritingLayers[_activeHandwritingLayer] = layer;
    _handwritingStrokes
      ..clear()
      ..addAll(layer.strokes.map((stroke) => List<Offset>.from(stroke)));
    _handwritingColor = layer.color;
    _handwritingStrokeWidth = layer.strokeWidth;
    _handwritingStyle = layer.style;
  }

  void _selectHandwritingLayer(int index) {
    _activeHandwritingLayer = index;
    final layer = _activeLayer;
    _handwritingStrokes
      ..clear()
      ..addAll(layer.strokes.map((stroke) => List<Offset>.from(stroke)));
    _handwritingColor = layer.color;
    _handwritingStrokeWidth = layer.strokeWidth;
    _handwritingStyle = layer.style;
  }

  List<HandwritingLayer> _copyHandwritingLayers() {
    return _handwritingLayers.map((layer) {
      return layer.copyWith(
        strokes: layer.strokes
            .map((stroke) => List<Offset>.from(stroke))
            .toList(growable: false),
      );
    }).toList(growable: false);
  }

  List<List<Offset>> _flattenHandwritingStrokes() {
    return _handwritingLayers
        .where((layer) => layer.visible)
        .expand((layer) => layer.strokes)
        .map((stroke) => List<Offset>.from(stroke))
        .toList(growable: false);
  }

  void _recordHandwritingChange() {
    _handwritingUndoStack.add(_copyHandwritingLayers());
    if (_handwritingUndoStack.length > 30) {
      _handwritingUndoStack.removeAt(0);
    }
    _handwritingRedoStack.clear();
  }

  void _restoreHandwritingLayers(List<HandwritingLayer> layers) {
    _handwritingLayers
      ..clear()
      ..addAll(layers.map((layer) => layer.copyWith(
            strokes: layer.strokes
                .map((stroke) => List<Offset>.from(stroke))
                .toList(growable: false),
          )));
    _activeHandwritingLayer =
        _activeHandwritingLayer.clamp(0, _handwritingLayers.length - 1);
    _selectHandwritingLayer(_activeHandwritingLayer);
  }

  void _undoHandwriting() {
    if (_handwritingUndoStack.isEmpty) return;
    _handwritingRedoStack.add(_copyHandwritingLayers());
    _restoreHandwritingLayers(_handwritingUndoStack.removeLast());
  }

  void _redoHandwriting() {
    if (_handwritingRedoStack.isEmpty) return;
    _handwritingUndoStack.add(_copyHandwritingLayers());
    _restoreHandwritingLayers(_handwritingRedoStack.removeLast());
  }

  void _addHandwritingLayer() {
    if (_handwritingLayers.length >= _maxHandwritingLayers) return;
    _recordHandwritingChange();
    final source = _activeLayer;
    _handwritingLayers.add(
      HandwritingLayer(
        color: source.color,
        strokeWidth: source.strokeWidth,
        style: source.style,
      ),
    );
    _selectHandwritingLayer(_handwritingLayers.length - 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRotateTip());
  }

  void _maybeShowRotateTip() {
    if (!mounted) return;
    if (_rotateTipShownThisSession) return;

    final orientation = MediaQuery.of(context).orientation;
    if (orientation != Orientation.portrait) return;

    _rotateTipShownThisSession = true;

    setState(() => _tipVisible = true);
    _tipController.forward();

    // ✅ Longer on-screen time
    Future.delayed(const Duration(milliseconds: 4500), () async {
      if (!mounted) return;
      await _tipController.reverse();
      if (!mounted) return;
      setState(() {
        _tipVisible = false;
        _persistentRotateHint = true; // ✅ show persistent hint after bubble
      });

      if (!_wiggleController.isAnimating) {
        _wiggleController.repeat(reverse: true);
      }
    });
  }

  Future<void> _loadState() async {
    setState(() => _loading = true);

    final pro = await SubscriptionManager.isPro();
    final logoPaths = await LogoStorageService.getLogoPaths();
    final logo = logoPaths.isNotEmpty
        ? logoPaths.first
        : await LogoStorageService.getLogoPath();

    if (!mounted) return;
    setState(() {
      _isPro = pro;
      _logoPath = logo;
      _logoPaths = logoPaths;
      _loading = false;
    });

    if (!pro) {
      unawaited(RewardedAdService.instance.preload());
    }
  }

  bool get _logoExistsSync {
    final p = _logoPath;
    if (p == null || p.isEmpty) return false;
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickLogo() async {
    final t = AppLocalizations.of(context);

    setState(() => _loading = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (picked == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final saved = await LogoStorageService.saveLogoFromTempPath(picked.path);

      if (!mounted) return;
      setState(() {
        _logoPath = saved;
        _logoPaths = [saved];
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.logoSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.logoSaveError} $e')),
      );
    }
  }

  Future<void> _pickMultipleLogos() async {
    final t = AppLocalizations.of(context);

    setState(() => _loading = true);
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 95);

      if (picked.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final saved = await LogoStorageService.saveLogosFromPickedPaths(
        picked.map((file) => file.path).toList(),
      );

      if (!mounted) return;
      setState(() {
        _logoPaths = saved;
        _logoPath = saved.first;
        _logoRotation = saved.length > 1;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${saved.length} logos saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.logoSaveError} $e')),
      );
    }
  }

  Future<void> _removeLogo() async {
    final t = AppLocalizations.of(context);

    setState(() => _loading = true);
    await LogoStorageService.removeLogo();

    if (!mounted) return;
    setState(() {
      _logoPath = null;
      _logoPaths = const <String>[];
      _logoRotation = false;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.logoRemoved)),
    );
  }

  Future<void> _shareApp() async {
    const msg = '✨ ShowMyName ✨\n\n'
        'Turn your phone into a digital sign.\n'
        'Perfect for events, airports, and concerts.\n\n'
        'Convierte tu teléfono en un letrero digital.\n'
        'Ideal para eventos, aeropuertos y conciertos.\n\n'
        'Download / Descárgala:\n'
        'iOS: $_appleUrl\n'
        'Android: $_googleUrl\n\n\n'
        'Website: $_liisgoWebsite';

    final anchorContext = _shareKey.currentContext ?? context;
    final box = anchorContext.findRenderObject() as RenderBox?;

    if (box == null) {
      await Share.share(msg);
      return;
    }

    await Share.share(
      msg,
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _shareCreatedImage() async {
    final t = AppLocalizations.of(context);
    final boundary = _createdImageKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The image is still preparing.')),
      );
      return;
    }

    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('Unable to create image data.');

      final directory = await getTemporaryDirectory();
      final imageFile = File(
        '${directory.path}/showmyname-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await imageFile.writeAsBytes(byteData.buffer.asUint8List());
      if (!mounted) return;

      final anchorContext = _createdImageKey.currentContext ?? context;
      final box = anchorContext.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(imageFile.path, mimeType: 'image/png')],
        text: 'Made with ShowMyName',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.shareApp} failed. Please try again.')),
      );
    }
  }

  Future<void> _handleModeChanged(HomeMode mode) async {
    if (_modeChangeInProgress) {
      _queuedMode = mode;
      return;
    }

    _modeChangeInProgress = true;
    try {
      await _applyHomeMode(mode);
    } finally {
      _modeChangeInProgress = false;
    }

    final queued = _queuedMode;
    if (queued != null && queued != mode && mounted) {
      _queuedMode = null;
      await _handleModeChanged(queued);
    } else {
      _queuedMode = null;
    }
  }

  void _commitHomeMode(HomeMode m) {
    setState(() {
      _homeMode = m;

      if (m == HomeMode.airport) {
        _mode = SignUsageMode.airport;
        _type = SignType.textOnly;
        _motionDirection = MotionDirection.none;
        _motionStyle = MotionStyle.loop;
        _colorShift = false;
        return;
      }

      if (m == HomeMode.event) {
        _mode = SignUsageMode.concert;
        _type = SignType.textMotion;
        return;
      }

      if (m == HomeMode.logo) {
        _mode = SignUsageMode.concert; // not important here
        _type = SignType.logoOnly;
        _motionDirection = MotionDirection.none;
        _motionStyle = MotionStyle.loop;
        _colorShift = false;
        return;
      }

      if (m == HomeMode.handwriting) {
        _mode = SignUsageMode.concert;
        _type = SignType.handwritingOnly;
        _motionDirection = MotionDirection.none;
        _motionStyle = MotionStyle.loop;
        _colorShift = false;
        return;
      }

      // ColorWave preset
      _mode = SignUsageMode.concert;
      _type = SignType.colorOnly;
    });
  }

  Future<void> _applyHomeMode(HomeMode m) async {
    final gatedFeature = _gatedFeatureForMode(m);
    _rewardUnlockedFeatures.removeWhere((feature) => feature != gatedFeature);

    if (gatedFeature != null &&
        !_isPro &&
        !_rewardUnlockedFeatures.contains(gatedFeature)) {
      final unlocked = await _showRewardUnlockSheet(
        title: 'Unlock ${_featureNameForMode(m)}',
        featureName: _featureNameForMode(m),
        description: _featureDescriptionForMode(m),
      );
      if (!unlocked) return;
      _rewardUnlockedFeatures.add(gatedFeature);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_featureNameForMode(m)} unlocked once. Upgrade for unlimited use.',
          ),
        ),
      );
    }

    if (!mounted) return;

    _commitHomeMode(m);
    await AnalyticsService.logModeSelected(m.name, isPro: _isPro);
  }

  String? _gatedFeatureForMode(HomeMode mode) {
    return switch (mode) {
      HomeMode.event => 'concert',
      HomeMode.handwriting => 'handwriting',
      HomeMode.logo => 'logo',
      HomeMode.airport || HomeMode.colorWave => null,
    };
  }

  String _featureNameForMode(HomeMode mode) {
    return switch (mode) {
      HomeMode.event => 'Concert / Event',
      HomeMode.colorWave => 'ColorWave',
      HomeMode.handwriting => 'Handwriting',
      HomeMode.airport => 'Airport / Pickup',
      HomeMode.logo => 'Logo',
    };
  }

  String _featureDescriptionForMode(HomeMode mode) {
    return switch (mode) {
      HomeMode.event =>
        'Use concert styles like LED Dot Matrix, Neon Glow, Pulse, Marquee, and Wave.',
      HomeMode.colorWave =>
        'Show a fullscreen color effect for events, parties, and attention-grabbing signs.',
      HomeMode.handwriting =>
        'Write a name with your finger and show it large fullscreen.',
      HomeMode.airport => 'Create a clean readable pickup sign.',
      HomeMode.logo => 'Show a saved logo fullscreen.',
    };
  }

  Future<bool> _showRewardUnlockSheet({
    required String title,
    required String featureName,
    required String description,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0D1018),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final accent = Theme.of(ctx).colorScheme.primary;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.workspace_premium, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx, 'cancel'),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.055),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UnlockLine(
                        icon: Icons.play_circle_outline,
                        text: 'Watch one ad to use this feature once.',
                      ),
                      SizedBox(height: 10),
                      _UnlockLine(
                        icon: Icons.all_inclusive,
                        text: 'Go Pro for unlimited access and no ads.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'ad'),
                    icon: const Icon(Icons.ondemand_video_outlined),
                    label: Text('Watch ad to use $featureName once'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'pro'),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('See Pro plans'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return false;
    if (result == 'pro') {
      await AnalyticsService.logRewardChoice(featureName, 'pro');
      await AnalyticsService.logPaywallOpen(source: 'reward_$featureName');
      await context.push('/paywall');
      await _loadState();
      return await SubscriptionManager.isPro();
    }
    if (result != 'ad') return false;

    await AnalyticsService.logRewardChoice(featureName, 'ad');
    final unlocked = await RewardedAdService.instance.showOnce();
    if (!mounted) return false;

    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad was not completed. Try again.')),
      );
    }
    await AnalyticsService.logRewardResult(featureName, unlocked: unlocked);
    return unlocked;
  }

  Future<Color?> _pickColorDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);

    final colors = <Color>[
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.white,
      Colors.black,
    ];

    return showDialog<Color>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.addColor),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((c) {
              return InkWell(
                onTap: () => Navigator.pop(ctx, c),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color get _currentTextColor =>
      _homeMode == HomeMode.event ? _eventTextColor : _airportTextColor;

  Color get _currentBackgroundColor => _homeMode == HomeMode.event
      ? _eventBackgroundColor
      : _airportBackgroundColor;

  TextEditingController get _currentTextController =>
      _homeMode == HomeMode.event ? _eventController : _airportController;

  double get _currentFontScale =>
      _homeMode == HomeMode.event ? _eventFontScale : _airportFontScale;

  Future<void> _pickTextColor() async {
    final selected = await _pickColorDialog(context);
    if (selected == null) return;

    setState(() {
      if (_homeMode == HomeMode.event) {
        _eventTextColor = selected;
      } else {
        _airportTextColor = selected;
      }
    });
  }

  Future<void> _pickBackgroundColor() async {
    final selected = await _pickColorDialog(context);
    if (selected == null) return;

    setState(() {
      if (_homeMode == HomeMode.event) {
        _eventBackgroundColor = selected;
      } else {
        _airportBackgroundColor = selected;
      }
    });
  }

  // Kept for the fuller ColorWave editor path.
  // ignore: unused_element
  Future<void> _addColor() async {
    final selected = await _pickColorDialog(context);
    if (selected == null) return;

    setState(() {
      if (_colorCycle) {
        _cycleColors.add(selected);
      } else {
        _singleColor = selected;
      }
    });
  }

  // Kept for the fuller ColorWave editor path.
  // ignore: unused_element
  Future<void> _editColorAt(int index) async {
    final selected = await _pickColorDialog(context);
    if (selected == null) return;

    setState(() {
      if (_colorCycle) {
        if (index >= 0 && index < _cycleColors.length) {
          _cycleColors[index] = selected;
        }
      } else {
        _singleColor = selected;
      }
    });
  }

  void _showSign() {
    final t = AppLocalizations.of(context);

    // ColorWave
    if (_type == SignType.colorOnly) {
      final config = SignConfig(
        message: _currentTextController.text.trim().isEmpty
            ? _airportController.text
            : _currentTextController.text,
        usageMode: _mode,
        signType: SignType.colorOnly,
        backgroundColor: Colors.black,
        fontScale: _currentFontScale,
        bold: _airportBold,
        italic: _airportItalic,
        underline: _airportUnderline,
        textAlign: _airportTextAlign,
        showLogo: false,
        logoPath: null,
        isPro: _isPro,
        singleColor: _colorCycle ? null : _singleColor,
        cycleColors:
            _colorCycle ? List<Color>.from(_cycleColors) : const <Color>[],
        colorHold: Duration(milliseconds: (_holdSeconds * 1000).round()),
        colorTransition: _transitionType,
        transitionDuration: Duration(milliseconds: _transitionMs.round()),
      );
      AnalyticsService.logShowSign(_homeMode.name, _type.name);
      context.push('/display', extra: config);
      return;
    }

    // Logo-only
    if (_type == SignType.logoOnly) {
      if (_logoPath == null || _logoPath!.isEmpty || !_logoExistsSync) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.noLogoSaved)),
        );
        return;
      }

      final config = SignConfig(
        message: null,
        usageMode: _mode,
        signType: SignType.logoOnly,
        showLogo: true,
        logoPath: _logoPath,
        logoPaths: List<String>.from(_logoPaths),
        logoRotation: _logoRotation,
        logoEffect: _logoEffect,
        logoHold: Duration(milliseconds: (_logoHoldSeconds * 1000).round()),
        isPro: _isPro,
      );

      AnalyticsService.logShowSign(_homeMode.name, _type.name);
      context.push('/display', extra: config);
      return;
    }

    // Handwriting
    if (_type == SignType.handwritingOnly) {
      if (!_hasHandwriting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Write a name first.')),
        );
        return;
      }

      final config = SignConfig(
        message: null,
        usageMode: _mode,
        signType: SignType.handwritingOnly,
        backgroundColor: _handwritingBackgroundColor,
        handwritingStrokes: _flattenHandwritingStrokes(),
        handwritingColor: _handwritingColor,
        handwritingStrokeWidth: _handwritingStrokeWidth,
        handwritingStyle: _handwritingStyle,
        handwritingLayers: _copyHandwritingLayers(),
        isPro: _isPro,
      );

      AnalyticsService.logShowSign(_homeMode.name, _type.name);
      context.push('/display', extra: config);
      return;
    }

    // Text modes
    final msg = _currentTextController.text.trim();
    if (msg.isEmpty) return;

    final config = SignConfig(
      message: msg,
      usageMode: _mode,
      signType: _type,
      motionDirection: _motionDirection,
      motionStyle: _motionStyle,
      motionSpeed: _motionSpeed,
      colorShift: (_homeMode == HomeMode.event &&
              _concertTextEffect == ConcertTextEffect.simple)
          ? _colorShift
          : false,
      fontScale: _currentFontScale,
      textColor: _currentTextColor,
      backgroundColor: _currentBackgroundColor,
      bold: _homeMode == HomeMode.airport ? _airportBold : true,
      italic: _homeMode == HomeMode.airport && _airportItalic,
      underline: _homeMode == HomeMode.airport && _airportUnderline,
      textAlign:
          _homeMode == HomeMode.airport ? _airportTextAlign : TextAlign.center,
      showIcon: _homeMode == HomeMode.airport ? _airportShowIcon : false,
      iconSymbol: _airportIconSymbol,
      concertTextEffect: _homeMode == HomeMode.event
          ? _concertTextEffect
          : ConcertTextEffect.simple,
      ledColor: _ledColor,
      ledGlowIntensity: _ledGlowIntensity,
      ledBorderGlow: _ledBorderGlow,
      ledDotSize: _ledDotSize,
      ledDotSpacing: _ledDotSpacing,
      ledBrightness: _ledBrightness,
      ledAnimation: _ledAnimation,
      neonGlowColor: _neonGlowColor,
      neonGlowIntensity: _neonGlowIntensity,
      neonStrokeWidth: _neonStrokeWidth,
      marqueeSpeed: _marqueeSpeed,
      marqueeDirection: _marqueeDirection,
      isPro: _isPro,
    );

    AnalyticsService.logShowSign(_homeMode.name, _type.name);
    context.push('/display', extra: config);
  }

  Widget _buildRotateBubble(AppLocalizations t) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _tipFade,
        child: SlideTransition(
          position: _tipSlide,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    const Icon(Icons.screen_rotation, color: Colors.white),
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
    );
  }

  Widget _buildPersistentRotateHint(AppLocalizations t) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: _persistentRotateHint ? 1 : 0,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            RotationTransition(
              turns: _wiggleTurns,
              child: const Icon(Icons.screen_rotation, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.rotateToLandscapeHint,
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SignConfig _previewConfig() {
    if (_homeMode == HomeMode.colorWave) {
      return SignConfig(
        message: _currentTextController.text.trim().isEmpty
            ? _airportController.text
            : _currentTextController.text,
        usageMode: SignUsageMode.concert,
        signType: SignType.colorOnly,
        backgroundColor: Colors.black,
        fontScale: _currentFontScale,
        bold: _airportBold,
        italic: _airportItalic,
        underline: _airportUnderline,
        textAlign: _airportTextAlign,
        singleColor: _colorCycle ? null : _singleColor,
        cycleColors:
            _colorCycle ? List<Color>.from(_cycleColors) : const <Color>[],
        colorHold: Duration(milliseconds: (_holdSeconds * 1000).round()),
        colorTransition: _transitionType,
        transitionDuration: Duration(milliseconds: _transitionMs.round()),
      );
    }

    if (_homeMode == HomeMode.logo) {
      return SignConfig(
        usageMode: SignUsageMode.concert,
        signType: SignType.logoOnly,
        showLogo: true,
        logoPath: _logoPath,
        logoPaths: List<String>.from(_logoPaths),
        logoRotation: _logoRotation,
        logoEffect: _logoEffect,
        logoHold: Duration(milliseconds: (_logoHoldSeconds * 1000).round()),
      );
    }

    if (_homeMode == HomeMode.handwriting) {
      return SignConfig(
        usageMode: SignUsageMode.concert,
        signType: SignType.handwritingOnly,
        backgroundColor: _handwritingBackgroundColor,
        handwritingStrokes: _flattenHandwritingStrokes(),
        handwritingColor: _handwritingColor,
        handwritingStrokeWidth: _handwritingStrokeWidth,
        handwritingStyle: _handwritingStyle,
        handwritingLayers: _copyHandwritingLayers(),
      );
    }

    return SignConfig(
      message: _currentTextController.text.trim(),
      usageMode: _homeMode == HomeMode.event
          ? SignUsageMode.concert
          : SignUsageMode.airport,
      signType:
          _homeMode == HomeMode.event ? SignType.textMotion : SignType.textOnly,
      fontScale: _currentFontScale,
      textColor: _currentTextColor,
      backgroundColor: _currentBackgroundColor,
      bold: _homeMode == HomeMode.airport ? _airportBold : true,
      italic: _homeMode == HomeMode.airport && _airportItalic,
      underline: _homeMode == HomeMode.airport && _airportUnderline,
      textAlign:
          _homeMode == HomeMode.airport ? _airportTextAlign : TextAlign.center,
      showIcon: _homeMode == HomeMode.airport ? _airportShowIcon : false,
      iconSymbol: _airportIconSymbol,
      motionDirection: _motionDirection,
      motionStyle: _motionStyle,
      motionSpeed: _motionSpeed,
      colorShift: _homeMode == HomeMode.event &&
              _concertTextEffect == ConcertTextEffect.simple
          ? _colorShift
          : false,
      concertTextEffect: _homeMode == HomeMode.event
          ? _concertTextEffect
          : ConcertTextEffect.simple,
      ledColor: _ledColor,
      ledGlowIntensity: _ledGlowIntensity,
      ledBorderGlow: _ledBorderGlow,
      ledDotSize: _ledDotSize,
      ledDotSpacing: _ledDotSpacing,
      ledBrightness: _ledBrightness,
      ledAnimation: _ledAnimation,
      neonGlowColor: _neonGlowColor,
      neonGlowIntensity: _neonGlowIntensity,
      neonStrokeWidth: _neonStrokeWidth,
      marqueeSpeed: _marqueeSpeed,
      marqueeDirection: _marqueeDirection,
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      color: const Color(0xFF11131C).withOpacity(0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withOpacity(0.28),
                  child: Icon(
                    icon,
                    size: 19,
                    color: Color.lerp(Colors.white, accent, 0.28),
                  ),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview(
    AppLocalizations t, {
    double height = 190,
    Alignment alignment = Alignment.topLeft,
    GlobalKey? captureKey,
  }) {
    // Render at the final viewport size, then scale the whole scene uniformly.
    // Text layout, font limits and padding therefore match the fullscreen view.
    final media = MediaQuery.of(context);
    final viewport = media.size;
    final preview = SizedBox(
      key: const ValueKey('sign-preview'),
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: alignment,
        child: SizedBox(
          width: viewport.width,
          height: viewport.height,
          child: IgnorePointer(
            child: MediaQuery(
              data: media.copyWith(viewInsets: EdgeInsets.zero),
              child: DisplayScreen(config: _previewConfig(), preview: true),
            ),
          ),
        ),
      ),
    );
    if (captureKey == null) return preview;

    // The FittedBox may leave unused space around the sign. Keep that entire
    // export canvas opaque so sharing never turns those areas white.
    return RepaintBoundary(
      key: captureKey,
      child: ColoredBox(
        color: _previewConfig().backgroundColor,
        child: preview,
      ),
    );
  }

  Widget _buildDialogPreview() {
    return _buildLivePreview(AppLocalizations.of(context), height: 170);
  }

  Widget _buildFixedAdjustments(AppLocalizations t, {VoidCallback? onClose}) {
    final isColorWave = _homeMode == HomeMode.colorWave;
    return Material(
      key: const ValueKey('fixed-adjustments-panel'),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  initialIndex: _adjustmentTab,
                  child: TabBar(
                    onTap: (value) => setState(() => _adjustmentTab = value),
                    tabs: [Tab(text: t.textTab), Tab(text: t.appearance)],
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  key: const ValueKey('close-compact-editor'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey('adjustment-scroll-$_adjustmentTab'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_adjustmentTab == 0) ...[
                    TextField(
                      key: const ValueKey('sign-text-field'),
                      controller: _currentTextController,
                      minLines: 2,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: t.textEmojis,
                        hintText: t.messageHint,
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_homeMode == HomeMode.airport)
                      _buildAirportStyleControls(t, setState)
                    else if (isColorWave)
                      _buildColorWaveTextControls(t, setState),
                  ] else if (isColorWave) ...[
                    _buildColorWaveControls(t, setState),
                  ] else ...[
                    _buildColorButton(
                      label: t.backgroundColor,
                      color: _currentBackgroundColor,
                      onPressed: _pickBackgroundColor,
                    ),
                    if (_homeMode == HomeMode.airport)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(t.signIcon,
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                              ),
                              const SizedBox(width: 8),
                              Semantics(
                                label: t.signIcon,
                                child: Switch(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: _airportShowIcon,
                                  onChanged: (v) =>
                                      setState(() => _airportShowIcon = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_homeMode == HomeMode.airport)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final symbol in [
                            '✈',
                            '←',
                            '→',
                            '↑',
                            '↓',
                            '★',
                            '♥',
                            '✓',
                            '☀',
                            '♫',
                            '🚕',
                            '👋'
                          ])
                            ChoiceChip(
                              key: ValueKey('sign-icon-$symbol'),
                              label: SizedBox(
                                width: 32,
                                height: 32,
                                child: Center(
                                    child: Text(symbol,
                                        style: const TextStyle(fontSize: 24))),
                              ),
                              showCheckmark: false,
                              selected: _airportShowIcon &&
                                  _airportIconSymbol == symbol,
                              onSelected: (_) => setState(() {
                                _airportIconSymbol = symbol;
                                _airportShowIcon = true;
                              }),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTextLayout(
      AppLocalizations t, BoxConstraints constraints) {
    final editorBottom = (MediaQuery.viewInsetsOf(context).bottom - 120).clamp(
        76.0, (constraints.maxHeight - 100).clamp(76.0, double.infinity));
    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          bottom: 76,
          child: ColoredBox(
            color: _currentBackgroundColor,
            child: _buildLivePreview(t,
                alignment: Alignment.center,
                height:
                    (constraints.maxHeight - 84).clamp(1.0, double.infinity),
                captureKey: _createdImageKey),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('show-sign'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: _showSign,
                  icon: const Icon(Icons.fullscreen),
                  label: Text(t.show),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Share image',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: FilledButton.tonal(
                    key: const ValueKey('share-created-image'),
                    style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: _shareCreatedImage,
                    child: const Icon(Icons.ios_share),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('open-compact-editor'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () =>
                      setState(() => _compactEditorOpen = !_compactEditorOpen),
                  icon: const Icon(Icons.tune),
                  label: Text(t.editSign),
                ),
              ),
            ],
          ),
        ),
        if (_compactEditorOpen)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            bottom: editorBottom,
            child: _buildFixedAdjustments(t, onClose: () {
              FocusScope.of(context).unfocus();
              setState(() => _compactEditorOpen = false);
            }),
          ),
      ],
    );
  }

  Future<void> _openConcertPreviewPopup() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0D1018),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            void update(VoidCallback fn) {
              setState(fn);
              modalSetState(() {});
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              builder: (context, controller) {
                return ListView(
                  controller: controller,
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 18,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
                  ),
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text('Preview & tune',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _buildDialogPreview(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ConcertTextEffect>(
                      value: _concertTextEffect,
                      decoration:
                          const InputDecoration(labelText: 'Concert Style'),
                      items: const [
                        DropdownMenuItem(
                            value: ConcertTextEffect.simple,
                            child: Text('Simple Text')),
                        DropdownMenuItem(
                            value: ConcertTextEffect.ledDotMatrix,
                            child: Text('LED Dot Matrix')),
                        DropdownMenuItem(
                            value: ConcertTextEffect.neonGlow,
                            child: Text('Neon Glow')),
                        DropdownMenuItem(
                            value: ConcertTextEffect.pulse,
                            child: Text('Pulse')),
                        DropdownMenuItem(
                            value: ConcertTextEffect.marquee,
                            child: Text('Marquee')),
                        DropdownMenuItem(
                            value: ConcertTextEffect.wave, child: Text('Wave')),
                      ],
                      onChanged: (v) => update(() => _concertTextEffect =
                          v ?? ConcertTextEffect.ledDotMatrix),
                    ),
                    const SizedBox(height: 16),
                    if (_concertTextEffect == ConcertTextEffect.ledDotMatrix)
                      ..._buildLedPopupControls(update)
                    else if (_concertTextEffect == ConcertTextEffect.neonGlow)
                      ..._buildNeonPopupControls(update)
                    else if (_concertTextEffect == ConcertTextEffect.marquee)
                      ..._buildMarqueePopupControls(update)
                    else
                      _labeledSlider('Text size', _eventFontScale, 0.7, 1.5,
                          (v) => update(() => _eventFontScale = v)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildColorWaveControls(
    AppLocalizations t,
    void Function(VoidCallback) update,
  ) {
    final visibleColors = _colorCycle ? _cycleColors : [_singleColor];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.colorCycle,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    _colorCycle ? t.multiColors : t.singleColor,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Switch(
              value: _colorCycle,
              onChanged: (v) => update(() => _colorCycle = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final selected = await _pickColorDialog(context);
                    if (selected == null) return;
                    update(() {
                      if (_colorCycle) {
                        _cycleColors.add(selected);
                      } else {
                        _singleColor = selected;
                      }
                    });
                  },
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  label: Text(t.addColor),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  onPressed: () => update(() {
                    _cycleColors
                      ..clear()
                      ..addAll([Colors.blue, Colors.purple, Colors.red]);
                  }),
                  child: Text(t.resetColors),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: visibleColors.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            return InkWell(
              onTap: () async {
                final selected = await _pickColorDialog(context);
                if (selected == null) return;
                update(() {
                  if (_colorCycle) {
                    if (idx >= 0 && idx < _cycleColors.length) {
                      _cycleColors[idx] = selected;
                    }
                  } else {
                    _singleColor = selected;
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(color: c.withOpacity(0.35), blurRadius: 14),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildColorWaveSlider(
          label: t.holdTime,
          value: _holdSeconds,
          min: 1,
          max: 15,
          valueLabel: _holdSeconds.toStringAsFixed(2),
          onChanged: (v) => update(() => _holdSeconds = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(t.transition,
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            SizedBox(
              width: 166,
              child: SegmentedButton<ColorTransitionType>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: [
                  ButtonSegment(
                      value: ColorTransitionType.fade, label: Text(t.fade)),
                  ButtonSegment(
                      value: ColorTransitionType.slide, label: Text(t.slide)),
                ],
                selected: {_transitionType},
                onSelectionChanged: (s) =>
                    update(() => _transitionType = s.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildColorWaveSlider(
          label: t.transitionDuration,
          value: _transitionMs,
          min: 200,
          max: 2000,
          valueLabel: _transitionMs.toStringAsFixed(0),
          onChanged: (v) => update(() => _transitionMs = v),
        ),
      ],
    );
  }

  Widget _buildColorWaveSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text(valueLabel, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        SizedBox(
          height: 30,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLedPopupControls(void Function(VoidCallback) update) {
    return [
      _buildColorButton(
        label: 'LED color',
        color: _ledColor,
        onPressed: () async {
          final selected = await _pickColorDialog(context);
          if (selected != null) update(() => _ledColor = selected);
        },
      ),
      const SizedBox(height: 12),
      _labeledSlider('Text size', _eventFontScale, 0.7, 1.5,
          (v) => update(() => _eventFontScale = v)),
      _labeledSlider('Brightness', _ledBrightness, 0.3, 1.3,
          (v) => update(() => _ledBrightness = v)),
      _labeledSlider('Glow intensity', _ledGlowIntensity, 0, 1,
          (v) => update(() => _ledGlowIntensity = v)),
      _labeledSlider('Panel border glow', _ledBorderGlow, 0, 1,
          (v) => update(() => _ledBorderGlow = v)),
      _labeledSlider(
          'Dot size', _ledDotSize, 2, 8, (v) => update(() => _ledDotSize = v)),
      _labeledSlider('Dot spacing', _ledDotSpacing, 5, 12,
          (v) => update(() => _ledDotSpacing = v)),
      DropdownButtonFormField<LedAnimation>(
        value: _ledAnimation,
        decoration: const InputDecoration(labelText: 'Animation'),
        items: const [
          DropdownMenuItem(value: LedAnimation.none, child: Text('None')),
          DropdownMenuItem(value: LedAnimation.pulse, child: Text('Pulse')),
          DropdownMenuItem(
              value: LedAnimation.scrollLeft, child: Text('Scroll left')),
          DropdownMenuItem(
              value: LedAnimation.scrollRight, child: Text('Scroll right')),
        ],
        onChanged: (v) => update(() => _ledAnimation = v ?? LedAnimation.none),
      ),
    ];
  }

  List<Widget> _buildNeonPopupControls(void Function(VoidCallback) update) {
    return [
      _buildColorButton(
        label: 'Glow color',
        color: _neonGlowColor,
        onPressed: () async {
          final selected = await _pickColorDialog(context);
          if (selected != null) update(() => _neonGlowColor = selected);
        },
      ),
      const SizedBox(height: 12),
      _labeledSlider('Text size', _eventFontScale, 0.7, 1.5,
          (v) => update(() => _eventFontScale = v)),
      _labeledSlider('Glow intensity', _neonGlowIntensity, 0, 1,
          (v) => update(() => _neonGlowIntensity = v)),
      _labeledSlider('Stroke thickness', _neonStrokeWidth, 0, 5,
          (v) => update(() => _neonStrokeWidth = v)),
    ];
  }

  List<Widget> _buildMarqueePopupControls(void Function(VoidCallback) update) {
    return [
      _labeledSlider('Text size', _eventFontScale, 0.7, 1.5,
          (v) => update(() => _eventFontScale = v)),
      _labeledSlider('Speed', _marqueeSpeed, 20, 200,
          (v) => update(() => _marqueeSpeed = v)),
      const SizedBox(height: 8),
      Text('Direction', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      SegmentedButton<MotionDirection>(
        segments: const [
          ButtonSegment(
              value: MotionDirection.rightToLeft, label: Text('Left')),
          ButtonSegment(
              value: MotionDirection.leftToRight, label: Text('Right')),
        ],
        selected: {_marqueeDirection},
        onSelectionChanged: (s) => update(() => _marqueeDirection = s.first),
      ),
    ];
  }

  Widget _buildColorButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirportStyleControls(
    AppLocalizations t,
    void Function(VoidCallback) update,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.textSize, style: Theme.of(context).textTheme.titleSmall),
        Row(
          children: [
            IconButton.outlined(
              key: const ValueKey('text-size-less'),
              tooltip: '− ${t.textSize}',
              onPressed: _airportFontScale <= 0.7
                  ? null
                  : () => update(() => _airportFontScale =
                      (_airportFontScale - 0.05).clamp(0.7, 1.5)),
              icon: const Icon(Icons.remove),
            ),
            Expanded(
                child: Center(
                    child: Text('${(_airportFontScale * 100).round()} %'))),
            IconButton.outlined(
              key: const ValueKey('text-size-more'),
              tooltip: '+ ${t.textSize}',
              onPressed: _airportFontScale >= 1.5
                  ? null
                  : () => update(() => _airportFontScale =
                      (_airportFontScale + 0.05).clamp(0.7, 1.5)),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildColorButton(
          label: t.textColor,
          color: _airportTextColor,
          onPressed: () async {
            final selected = await _pickColorDialog(context);
            if (selected != null) {
              update(() => _airportTextColor = selected);
            }
          },
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          key: const ValueKey('text-formatting'),
          multiSelectionEnabled: true,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
                value: 'bold',
                tooltip: t.boldText,
                icon: const Icon(Icons.format_bold)),
            ButtonSegment(
                value: 'italic',
                tooltip: t.italicText,
                icon: const Icon(Icons.format_italic)),
            ButtonSegment(
                value: 'underline',
                tooltip: t.underlineText,
                icon: const Icon(Icons.format_underlined)),
          ],
          selected: {
            if (_airportBold) 'bold',
            if (_airportItalic) 'italic',
            if (_airportUnderline) 'underline',
          },
          onSelectionChanged: (values) => update(() {
            _airportBold = values.contains('bold');
            _airportItalic = values.contains('italic');
            _airportUnderline = values.contains('underline');
          }),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TextAlign>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
                value: TextAlign.left,
                tooltip: t.alignLeft,
                icon: const Icon(Icons.format_align_left)),
            ButtonSegment(
                value: TextAlign.center,
                tooltip: t.alignCenter,
                icon: const Icon(Icons.format_align_center)),
            ButtonSegment(
                value: TextAlign.right,
                tooltip: t.alignRight,
                icon: const Icon(Icons.format_align_right)),
          ],
          selected: {_airportTextAlign},
          onSelectionChanged: (s) => update(() => _airportTextAlign = s.first),
        ),
      ],
    );
  }

  Widget _buildColorWaveTextControls(
    AppLocalizations t,
    void Function(VoidCallback) update,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.textSize, style: Theme.of(context).textTheme.titleSmall),
        Row(
          children: [
            IconButton.outlined(
              key: const ValueKey('color-wave-text-size-less'),
              tooltip: '− ${t.textSize}',
              onPressed: _airportFontScale <= 0.7
                  ? null
                  : () => update(() => _airportFontScale =
                      (_airportFontScale - 0.05).clamp(0.7, 1.5)),
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Center(
                child: Text('${(_airportFontScale * 100).round()} %'),
              ),
            ),
            IconButton.outlined(
              key: const ValueKey('color-wave-text-size-more'),
              tooltip: '+ ${t.textSize}',
              onPressed: _airportFontScale >= 1.5
                  ? null
                  : () => update(() => _airportFontScale =
                      (_airportFontScale + 0.05).clamp(0.7, 1.5)),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          key: const ValueKey('color-wave-text-formatting'),
          multiSelectionEnabled: true,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
                value: 'bold',
                tooltip: t.boldText,
                icon: const Icon(Icons.format_bold)),
            ButtonSegment(
                value: 'italic',
                tooltip: t.italicText,
                icon: const Icon(Icons.format_italic)),
            ButtonSegment(
                value: 'underline',
                tooltip: t.underlineText,
                icon: const Icon(Icons.format_underlined)),
          ],
          selected: {
            if (_airportBold) 'bold',
            if (_airportItalic) 'italic',
            if (_airportUnderline) 'underline',
          },
          onSelectionChanged: (values) => update(() {
            _airportBold = values.contains('bold');
            _airportItalic = values.contains('italic');
            _airportUnderline = values.contains('underline');
          }),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TextAlign>(
          key: const ValueKey('color-wave-text-alignment'),
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
                value: TextAlign.left,
                tooltip: t.alignLeft,
                icon: const Icon(Icons.format_align_left)),
            ButtonSegment(
                value: TextAlign.center,
                tooltip: t.alignCenter,
                icon: const Icon(Icons.format_align_center)),
            ButtonSegment(
                value: TextAlign.right,
                tooltip: t.alignRight,
                icon: const Icon(Icons.format_align_right)),
          ],
          selected: {_airportTextAlign},
          onSelectionChanged: (s) => update(() => _airportTextAlign = s.first),
        ),
      ],
    );
  }

  // Kept for the expanded concert editor layout; the current UX uses the
  // simplified "Edit Concert Style" popup.
  // ignore: unused_element
  Widget _buildConcertOptions(AppLocalizations t) {
    return Column(
      children: [
        _sectionCard(
          icon: Icons.auto_awesome,
          title: 'Text Effect',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<ConcertTextEffect>(
                value: _concertTextEffect,
                decoration: const InputDecoration(labelText: 'Concert Style'),
                items: const [
                  DropdownMenuItem(
                      value: ConcertTextEffect.simple,
                      child: Text('Simple Text')),
                  DropdownMenuItem(
                      value: ConcertTextEffect.ledDotMatrix,
                      child: Text('LED Dot Matrix')),
                  DropdownMenuItem(
                      value: ConcertTextEffect.neonGlow,
                      child: Text('Neon Glow')),
                  DropdownMenuItem(
                      value: ConcertTextEffect.pulse, child: Text('Pulse')),
                  DropdownMenuItem(
                      value: ConcertTextEffect.marquee, child: Text('Marquee')),
                  DropdownMenuItem(
                      value: ConcertTextEffect.wave, child: Text('Wave')),
                ],
                onChanged: (v) => setState(() =>
                    _concertTextEffect = v ?? ConcertTextEffect.ledDotMatrix),
              ),
              const SizedBox(height: 14),
              Text(t.textSize, style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _eventFontScale,
                min: 0.7,
                max: 1.5,
                divisions: 8,
                label: _eventFontScale.toStringAsFixed(2),
                onChanged: (v) => setState(() => _eventFontScale = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildColorButton(
                      label: t.textColor,
                      color: _eventTextColor,
                      onPressed: _pickTextColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildColorButton(
                      label: t.backgroundColor,
                      color: _eventBackgroundColor,
                      onPressed: _pickBackgroundColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openConcertPreviewPopup,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview & tune'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_concertTextEffect == ConcertTextEffect.ledDotMatrix)
          _buildLedOptions()
        else if (_concertTextEffect == ConcertTextEffect.neonGlow)
          _buildNeonOptions()
        else if (_concertTextEffect == ConcertTextEffect.marquee)
          _buildMarqueeOptions()
        else if (_concertTextEffect == ConcertTextEffect.simple)
          _buildSimpleConcertMotion(t),
      ],
    );
  }

  Widget _buildLedOptions() {
    return _sectionCard(
      icon: Icons.grid_on,
      title: 'LED Dot Matrix',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColorButton(
            label: 'LED color',
            color: _ledColor,
            onPressed: () async {
              final selected = await _pickColorDialog(context);
              if (selected != null) setState(() => _ledColor = selected);
            },
          ),
          const SizedBox(height: 12),
          _labeledSlider('Brightness', _ledBrightness, 0.3, 1.3,
              (v) => setState(() => _ledBrightness = v)),
          _labeledSlider('Glow intensity', _ledGlowIntensity, 0, 1,
              (v) => setState(() => _ledGlowIntensity = v)),
          _labeledSlider('Panel border glow', _ledBorderGlow, 0, 1,
              (v) => setState(() => _ledBorderGlow = v)),
          _labeledSlider('Dot size', _ledDotSize, 2, 8,
              (v) => setState(() => _ledDotSize = v)),
          _labeledSlider('Dot spacing', _ledDotSpacing, 5, 12,
              (v) => setState(() => _ledDotSpacing = v)),
          const SizedBox(height: 8),
          DropdownButtonFormField<LedAnimation>(
            value: _ledAnimation,
            decoration: const InputDecoration(labelText: 'Animation'),
            items: const [
              DropdownMenuItem(value: LedAnimation.none, child: Text('None')),
              DropdownMenuItem(value: LedAnimation.pulse, child: Text('Pulse')),
              DropdownMenuItem(
                  value: LedAnimation.scrollLeft, child: Text('Scroll left')),
              DropdownMenuItem(
                  value: LedAnimation.scrollRight, child: Text('Scroll right')),
            ],
            onChanged: (v) =>
                setState(() => _ledAnimation = v ?? LedAnimation.none),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonOptions() {
    return _sectionCard(
      icon: Icons.light_mode_outlined,
      title: 'Neon Glow',
      child: Column(
        children: [
          _buildColorButton(
            label: 'Glow color',
            color: _neonGlowColor,
            onPressed: () async {
              final selected = await _pickColorDialog(context);
              if (selected != null) setState(() => _neonGlowColor = selected);
            },
          ),
          const SizedBox(height: 12),
          _labeledSlider('Glow intensity', _neonGlowIntensity, 0, 1,
              (v) => setState(() => _neonGlowIntensity = v)),
          _labeledSlider('Stroke thickness', _neonStrokeWidth, 0, 5,
              (v) => setState(() => _neonStrokeWidth = v)),
        ],
      ),
    );
  }

  Widget _buildMarqueeOptions() {
    return _sectionCard(
      icon: Icons.swap_horiz,
      title: 'Marquee',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledSlider('Speed', _marqueeSpeed, 20, 200,
              (v) => setState(() => _marqueeSpeed = v)),
          const SizedBox(height: 8),
          SegmentedButton<MotionDirection>(
            segments: const [
              ButtonSegment(
                  value: MotionDirection.rightToLeft, label: Text('Left')),
              ButtonSegment(
                  value: MotionDirection.leftToRight, label: Text('Right')),
            ],
            selected: {_marqueeDirection},
            onSelectionChanged: (s) =>
                setState(() => _marqueeDirection = s.first),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleConcertMotion(AppLocalizations t) {
    return _sectionCard(
      icon: Icons.motion_photos_on_outlined,
      title: t.motion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<MotionDirection>(
            value: _motionDirection,
            items: [
              DropdownMenuItem(
                  value: MotionDirection.none, child: Text(t.noMotion)),
              DropdownMenuItem(
                  value: MotionDirection.rightToLeft,
                  child: Text(t.rightToLeft)),
              DropdownMenuItem(
                  value: MotionDirection.leftToRight,
                  child: Text(t.leftToRight)),
              DropdownMenuItem(
                  value: MotionDirection.bottomToTop,
                  child: Text(t.bottomToTop)),
              DropdownMenuItem(
                  value: MotionDirection.topToBottom,
                  child: Text(t.topToBottom)),
            ],
            onChanged: (v) =>
                setState(() => _motionDirection = v ?? MotionDirection.none),
          ),
          const SizedBox(height: 12),
          SegmentedButton<MotionStyle>(
            segments: [
              ButtonSegment(value: MotionStyle.loop, label: Text(t.loop)),
              ButtonSegment(value: MotionStyle.bounce, label: Text(t.bounce)),
            ],
            selected: {_motionStyle},
            onSelectionChanged: (s) => setState(() => _motionStyle = s.first),
          ),
          const SizedBox(height: 12),
          _labeledSlider(t.speed, _motionSpeed, 20, 200,
              (v) => setState(() => _motionSpeed = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _colorShift,
            onChanged: (v) => setState(() => _colorShift = v),
            title: Text(t.colorShift),
            subtitle: Text(t.colorShiftHelp),
          ),
        ],
      ),
    );
  }

  Widget _labeledSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(value.toStringAsFixed(value >= 10 ? 0 : 2),
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildBrandTitle() {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: const [
                  Shadow(color: Colors.black87, blurRadius: 4),
                ],
              ),
              children: [
                const TextSpan(
                  text: 'ShowMy',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Name',
                  style: TextStyle(
                    color: accent,
                    shadows: [
                      Shadow(color: accent.withOpacity(0.65), blurRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () async {
              await AnalyticsService.logPaywallOpen(source: 'plan_badge');
              if (!mounted) return;
              await context.push('/paywall');
              await _loadState();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (_isPro ? accent : Colors.white).withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _isPro ? accent.withOpacity(0.75) : Colors.white24,
                ),
              ),
              child: Text(
                _isPro ? 'PRO' : 'FREE',
                style: TextStyle(
                  color: _isPro ? accent : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeDockItem(AppLocalizations t, HomeMode mode) {
    final label = switch (mode) {
      HomeMode.airport => t.airportPickup,
      HomeMode.event => t.concertEvent,
      HomeMode.colorWave => t.colorWave,
      HomeMode.handwriting => 'Handwriting',
      HomeMode.logo => t.logo,
    };
    final icon = switch (mode) {
      HomeMode.airport => Icons.flight,
      HomeMode.event => Icons.mic_none,
      HomeMode.colorWave => Icons.palette_outlined,
      HomeMode.handwriting => Icons.draw_outlined,
      HomeMode.logo => Icons.image_outlined,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        selected: _homeMode == mode,
        child: Material(
          color: _homeMode == mode
              ? Theme.of(context).colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: KeyedSubtree(
            key: _modeItemKeys[mode],
            child: InkWell(
              key: ValueKey('mode-${mode.name}'),
              borderRadius: BorderRadius.circular(18),
              onTap: () => _handleModeChanged(mode),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 24),
                    const SizedBox(height: 4),
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoDetails() async {
    final paths = _logoPaths.isNotEmpty
        ? _logoPaths
        : [if (_logoPath != null && _logoPath!.isNotEmpty) _logoPath!];

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Logo details'),
          content: SizedBox(
            width: 420,
            child: paths.isEmpty
                ? const Text('No logo saved.')
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            '${paths.length} image${paths.length == 1 ? '' : 's'} saved'),
                        const SizedBox(height: 12),
                        for (final path in paths)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SelectableText(
                              path,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandwritingPad({
    required VoidCallback refresh,
    double? aspectRatio = 2.4,
    Key? key,
    GlobalKey? captureKey,
  }) {
    final pad = LayoutBuilder(
      builder: (context, constraints) {
        final padSize = Size(constraints.maxWidth, constraints.maxHeight);

        Offset clampPoint(Offset point) {
          return Offset(
            point.dx.clamp(0.0, padSize.width),
            point.dy.clamp(0.0, padSize.height),
          );
        }

        void startStroke(Offset point) {
          setState(() {
            _recordHandwritingChange();
            final strokes = _activeLayer.strokes
                .map((stroke) => List<Offset>.from(stroke))
                .toList(growable: true);
            strokes.add([clampPoint(point)]);
            _replaceActiveHandwritingLayer(
              _activeLayer.copyWith(strokes: strokes),
            );
          });
          refresh();
        }

        void addPoint(Offset point) {
          if (_activeLayer.strokes.isEmpty) return;
          setState(() {
            final strokes = _activeLayer.strokes
                .map((stroke) => List<Offset>.from(stroke))
                .toList(growable: true);
            strokes.last.add(clampPoint(point));
            _replaceActiveHandwritingLayer(
              _activeLayer.copyWith(strokes: strokes),
            );
          });
          refresh();
        }

        return RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            EagerGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              () => EagerGestureRecognizer(),
              (recognizer) {},
            ),
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => startStroke(event.localPosition),
            onPointerMove: (event) => addPoint(event.localPosition),
            child: Container(
              key: key,
              decoration: BoxDecoration(
                color: _handwritingBackgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.22),
                    blurRadius: 22,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: captureKey == null
                  ? HandwritingSign(
                      layers: _copyHandwritingLayers(),
                      color: _handwritingColor,
                      strokeWidth: _handwritingStrokeWidth,
                      style: _handwritingStyle,
                      emptyLabel: 'Handwriting display',
                      preview: true,
                      fitToContent: false,
                    )
                  : RepaintBoundary(
                      key: captureKey,
                      child: ColoredBox(
                        color: _handwritingBackgroundColor,
                        child: HandwritingSign(
                          layers: _copyHandwritingLayers(),
                          color: _handwritingColor,
                          strokeWidth: _handwritingStrokeWidth,
                          style: _handwritingStyle,
                          emptyLabel: 'Handwriting display',
                          preview: true,
                          fitToContent: false,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
    return aspectRatio == null
        ? pad
        : AspectRatio(aspectRatio: aspectRatio, child: pad);
  }

  String _handwritingStyleLabel(HandwritingStrokeStyle style) {
    return switch (style) {
      HandwritingStrokeStyle.smooth => 'Smooth',
      HandwritingStrokeStyle.marker => 'Marker',
      HandwritingStrokeStyle.neon => 'Neon',
      HandwritingStrokeStyle.chalk => 'Chalk',
      HandwritingStrokeStyle.fire => 'Fire',
    };
  }

  Widget _buildHandwritingLayerSelector({
    required void Function(VoidCallback fn) update,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Layers',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          for (var i = 0; i < _handwritingLayers.length; i++) ...[
            SizedBox(
              width: 30,
              height: 34,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: i == _activeHandwritingLayer
                      ? accent.withOpacity(0.32)
                      : Colors.white.withOpacity(0.05),
                  side: BorderSide(
                    color: i == _activeHandwritingLayer
                        ? accent
                        : Colors.white.withOpacity(0.22),
                    width: i == _activeHandwritingLayer ? 1.7 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () => update(() => _selectHandwritingLayer(i)),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i == _activeHandwritingLayer
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (i != _handwritingLayers.length - 1) const SizedBox(width: 4),
          ],
          if (_handwritingLayers.length < _maxHandwritingLayers) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 30,
              height: 34,
              child: OutlinedButton(
                key: const ValueKey('add-handwriting-layer'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () => update(_addHandwritingLayer),
                child: const Icon(Icons.add_rounded, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHandwritingBackgroundButton({
    required void Function(VoidCallback fn) update,
    bool compact = false,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        key: const ValueKey('handwriting-background-color'),
        style: compact
            ? OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              )
            : null,
        onPressed: () async {
          final color = await _pickColorDialog(context);
          if (color == null) return;
          update(() => _handwritingBackgroundColor = color);
        },
        child: compact
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _handwritingBackgroundColor,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Background'),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _handwritingBackgroundColor,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Background'),
                ],
              ),
      ),
    );
  }

  Widget _buildHandwritingHistoryControls({
    required void Function(VoidCallback fn) update,
    bool iconOnly = false,
    bool includeClear = false,
  }) {
    if (iconOnly) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Undo',
            child: SizedBox(
              width: 52,
              height: 44,
              child: OutlinedButton(
                key: const ValueKey('handwriting-undo'),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _handwritingUndoStack.isEmpty
                    ? null
                    : () => update(_undoHandwriting),
                child: const Icon(Icons.undo_rounded, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Redo',
            child: SizedBox(
              width: 52,
              height: 44,
              child: OutlinedButton(
                key: const ValueKey('handwriting-redo'),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _handwritingRedoStack.isEmpty
                    ? null
                    : () => update(_redoHandwriting),
                child: const Icon(Icons.redo_rounded, size: 20),
              ),
            ),
          ),
          if (includeClear) ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('clear-handwriting-layer'),
                onPressed: _activeLayer.isEmpty
                    ? null
                    : () => update(() {
                          _recordHandwritingChange();
                          _replaceActiveHandwritingLayer(
                            _activeLayer.copyWith(
                              strokes: const <List<Offset>>[],
                            ),
                          );
                        }),
                icon: const Icon(Icons.backspace_outlined, size: 18),
                label: Text('Clear ${_activeHandwritingLayer + 1}'),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('handwriting-undo'),
            onPressed: _handwritingUndoStack.isEmpty
                ? null
                : () => update(_undoHandwriting),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Undo'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('handwriting-redo'),
            onPressed: _handwritingRedoStack.isEmpty
                ? null
                : () => update(_redoHandwriting),
            icon: const Icon(Icons.redo_rounded, size: 18),
            label: const Text('Redo'),
          ),
        ),
      ],
    );
  }

  Widget _buildHandwritingPreviewCanvas({
    Key? key,
    GlobalKey? captureKey,
  }) {
    final sign = HandwritingSign(
      layers: _copyHandwritingLayers(),
      color: _handwritingColor,
      strokeWidth: _handwritingStrokeWidth,
      style: _handwritingStyle,
      emptyLabel: 'Handwriting display',
      preview: true,
    );
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: _handwritingBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.22),
            blurRadius: 22,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: captureKey == null
          ? sign
          : RepaintBoundary(
              key: captureKey,
              child: ColoredBox(
                color: _handwritingBackgroundColor,
                child: sign,
              ),
            ),
    );
  }

  Widget _buildNarrowHandwritingLayout(
    AppLocalizations t,
    BoxConstraints constraints,
    bool showRotateHint,
  ) {
    final chromeHeight = showRotateHint ? 260.0 : 150.0;
    final previewHeight =
        (constraints.maxHeight - chromeHeight).clamp(140.0, 250.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: previewHeight,
            child: _buildHandwritingPreviewCanvas(
              key: const ValueKey('narrow-handwriting-preview'),
              captureKey: _createdImageKey,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              key: const ValueKey('edit-handwriting'),
              onPressed: _openHandwritingEditor,
              icon: const Icon(Icons.draw_outlined),
              label: const Text('Edit Handwriting'),
            ),
          ),
          if (showRotateHint) ...[
            const SizedBox(height: 10),
            _buildPersistentRotateHint(t),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('show-sign'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: _showSign,
                  icon: const Icon(Icons.fullscreen),
                  label: Text(t.show),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Share image',
                child: SizedBox(
                  width: 54,
                  height: 52,
                  child: FilledButton(
                    key: const ValueKey('share-created-image'),
                    style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: _hasHandwriting ? _shareCreatedImage : null,
                    child: const Icon(Icons.ios_share),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideHandwritingLayout(
    AppLocalizations t,
    BoxConstraints constraints,
  ) {
    final panelWidth = constraints.maxWidth < 750 ? 280.0 : 320.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildHandwritingPad(
                    key: const ValueKey('wide-handwriting-canvas'),
                    refresh: () {},
                    aspectRatio: null,
                    captureKey: _createdImageKey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('show-sign'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: _showSign,
                        icon: const Icon(Icons.fullscreen),
                        label: Text(t.show),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Share image',
                      child: SizedBox(
                        width: 54,
                        height: 52,
                        child: FilledButton(
                          key: const ValueKey('share-created-image'),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          onPressed:
                              _hasHandwriting ? _shareCreatedImage : null,
                          child: const Icon(Icons.ios_share),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: panelWidth,
            child: _buildWideHandwritingPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildWideHandwritingPanel() {
    return Material(
      key: const ValueKey('wide-handwriting-panel'),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: _buildHandwritingLayerSelector(update: setState),
                  ),
                  const SizedBox(height: 10),
                  _buildHandwritingHistoryControls(update: setState),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _activeLayer.isEmpty
                              ? null
                              : () => setState(
                                    () {
                                      _recordHandwritingChange();
                                      _replaceActiveHandwritingLayer(
                                        _activeLayer.copyWith(
                                          strokes: const <List<Offset>>[],
                                        ),
                                      );
                                    },
                                  ),
                          icon: const Icon(Icons.backspace_outlined, size: 18),
                          label: Text('Clear ${_activeHandwritingLayer + 1}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final color = await _pickColorDialog(context);
                            if (color == null) return;
                            setState(
                              () {
                                _recordHandwritingChange();
                                _replaceActiveHandwritingLayer(
                                  _activeLayer.copyWith(color: color),
                                );
                              },
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _handwritingColor,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Ink'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHandwritingBackgroundButton(update: setState),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<HandwritingStrokeStyle>(
                    value: _handwritingStyle,
                    decoration:
                        const InputDecoration(labelText: 'Scribble style'),
                    items: HandwritingStrokeStyle.values.map((style) {
                      return DropdownMenuItem(
                        value: style,
                        child: Text(_handwritingStyleLabel(style)),
                      );
                    }).toList(),
                    onChanged: (style) {
                      if (style == null) return;
                      setState(
                        () => _replaceActiveHandwritingLayer(
                          _activeLayer.copyWith(style: style),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _labeledSlider(
                    'Line size',
                    _handwritingStrokeWidth,
                    4,
                    22,
                    (v) => setState(
                      () => _replaceActiveHandwritingLayer(
                        _activeLayer.copyWith(strokeWidth: v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openHandwritingEditor() async {
    _narrowHandwritingEditorOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        enableDrag: false,
        backgroundColor: const Color(0xFF0D1018),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, modalSetState) {
              if (MediaQuery.sizeOf(ctx).width >= 600 &&
                  !_narrowHandwritingEditorCloseScheduled) {
                _narrowHandwritingEditorCloseScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _narrowHandwritingEditorOpen) {
                    Navigator.of(ctx, rootNavigator: true).pop();
                  }
                });
              }

              void update(VoidCallback fn) {
                setState(fn);
                modalSetState(() {});
              }

              return SizedBox(
                key: const ValueKey('narrow-handwriting-editor'),
                height: MediaQuery.sizeOf(ctx).height * 0.94,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.draw_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Handwriting',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        children: [
                          _buildHandwritingPad(
                            key: const ValueKey('narrow-handwriting-canvas'),
                            refresh: () => modalSetState(() {}),
                            aspectRatio: 1.35,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.center,
                            child:
                                _buildHandwritingLayerSelector(update: update),
                          ),
                          const SizedBox(height: 12),
                          _buildHandwritingHistoryControls(
                            update: update,
                            iconOnly: true,
                            includeClear: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const ValueKey('handwriting-ink-color'),
                                  onPressed: () async {
                                    final color =
                                        await _pickColorDialog(context);
                                    if (color == null) return;
                                    update(() {
                                      _recordHandwritingChange();
                                      _replaceActiveHandwritingLayer(
                                        _activeLayer.copyWith(color: color),
                                      );
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: _handwritingColor,
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Ink'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildHandwritingBackgroundButton(
                                  update: update,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<HandwritingStrokeStyle>(
                            value: _handwritingStyle,
                            decoration: const InputDecoration(
                                labelText: 'Scribble style'),
                            items: HandwritingStrokeStyle.values.map((style) {
                              return DropdownMenuItem(
                                value: style,
                                child: Text(_handwritingStyleLabel(style)),
                              );
                            }).toList(),
                            onChanged: (style) {
                              if (style == null) return;
                              update(
                                () => _replaceActiveHandwritingLayer(
                                  _activeLayer.copyWith(style: style),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _labeledSlider(
                            'Line size',
                            _handwritingStrokeWidth,
                            4,
                            22,
                            (v) => update(
                              () => _replaceActiveHandwritingLayer(
                                _activeLayer.copyWith(strokeWidth: v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      _narrowHandwritingEditorOpen = false;
      _narrowHandwritingEditorCloseScheduled = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tipController.dispose();
    _wiggleController.dispose();
    _proSub?.cancel();
    _airportController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    if (!isPortrait && _persistentRotateHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _persistentRotateHint = false);
      });
    }

    final usesInlineEditor =
        _homeMode == HomeMode.airport || _homeMode == HomeMode.colorWave;
    final isHandwritingMode = _homeMode == HomeMode.handwriting;
    final isLogoMode = _homeMode == HomeMode.logo;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: _buildBrandTitle(),
        actions: [
          IconButton(
            key: _shareKey,
            tooltip: t.shareApp,
            onPressed: _shareApp,
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: t.settings,
            onPressed: () =>
                context.push('/settings').then((_) => _loadState()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: !(usesInlineEditor &&
            _compactEditorOpen &&
            MediaQuery.sizeOf(context).width < 600),
        maintainState: true,
        child: SafeArea(
          top: false,
          bottom: _isPro,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Center(
              heightFactor: 1,
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  key: const ValueKey('mode-dock'),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, dockConstraints) {
                      final items = HomeMode.values;
                      // On an open Duo every mode gets the same clear tap area.
                      // On the closed phone we retain the scrollable dock and
                      // its animated edge guidance for the remaining modes.
                      if (dockConstraints.maxWidth >= 600) {
                        return Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            children: [
                              for (final mode in items)
                                Expanded(child: _buildModeDockItem(t, mode)),
                            ],
                          ),
                        );
                      }
                      return ScrollableModeDock(
                        key: const ValueKey('animated-mode-dock'),
                        selectedItemKey: _modeItemKeys[_homeMode],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final mode in items)
                              _buildModeDockItem(t, mode),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        if (isHandwritingMode) {
          if (constraints.maxWidth >= 600) {
            return _buildWideHandwritingLayout(t, constraints);
          }
          return _buildNarrowHandwritingLayout(
            t,
            constraints,
            isPortrait && _persistentRotateHint,
          );
        }
        final sidePanel = usesInlineEditor && constraints.maxWidth >= 600;
        if (usesInlineEditor && !sidePanel) {
          return _buildCompactTextLayout(t, constraints);
        }
        final panelWidth = constraints.maxWidth < 750 ? 280.0 : 320.0;
        final previewHeight = usesInlineEditor
            ? (constraints.maxHeight - 80).clamp(100.0, 650.0)
            : (constraints.maxHeight * 0.42).clamp(110.0, 240.0);
        final horizontalPadding = constraints.maxWidth > 992
            ? (constraints.maxWidth - 960) / 2
            : 16.0;
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 12,
                      sidePanel ? panelWidth + 32 : horizontalPadding, 80),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLivePreview(
                          t,
                          height: previewHeight,
                          captureKey: _createdImageKey,
                        ),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(),
                          ),
                        const SizedBox(height: 12),
                        if (isHandwritingMode) ...[
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _openHandwritingEditor,
                              icon: const Icon(Icons.draw_outlined),
                              label: const Text('Edit Handwriting'),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (isLogoMode)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.logoTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 6),
                                  Text(t.logoSubtitle,
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _pickLogo,
                                          icon: const Icon(Icons.upload_file),
                                          label: Text(t.uploadLogo),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _pickMultipleLogos,
                                          icon: const Icon(
                                              Icons.photo_library_outlined),
                                          label: const Text('Multiple images'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: (_logoPath == null)
                                              ? null
                                              : _removeLogo,
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          label: Text(t.removeLogo),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: (_logoPath == null)
                                              ? null
                                              : _showLogoDetails,
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text('View details'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: (_logoPath == null ||
                                            !_logoExistsSync)
                                        ? Text(t.noLogoSaved,
                                            style: const TextStyle(
                                                color: Colors.white70))
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(t.logoPreview,
                                                  style: const TextStyle(
                                                      color: Colors.white70)),
                                              const SizedBox(height: 10),
                                              Center(
                                                child: SizedBox(
                                                  height: 140,
                                                  child: Image.file(
                                                    File(_logoPath!),
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (_, __, ___) => Text(
                                                      t.logoLoadError,
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.white70),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _logoPaths.length <= 1
                                                    ? '1 image uploaded'
                                                    : '${_logoPaths.length} images uploaded',
                                                style: const TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: _logoRotation,
                                    onChanged: (_logoPaths.length <= 1)
                                        ? null
                                        : (v) =>
                                            setState(() => _logoRotation = v),
                                    title: const Text('Rotate images'),
                                    subtitle: const Text(
                                      'Cycles through multiple uploaded images.',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<LogoTransitionEffect>(
                                    value: _logoEffect,
                                    decoration: const InputDecoration(
                                      labelText: 'Logo effect',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: LogoTransitionEffect.fade,
                                        child: Text('Fade'),
                                      ),
                                      DropdownMenuItem(
                                        value: LogoTransitionEffect.slide,
                                        child: Text('Slide'),
                                      ),
                                      DropdownMenuItem(
                                        value: LogoTransitionEffect.zoom,
                                        child: Text('Zoom'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(() =>
                                        _logoEffect =
                                            v ?? LogoTransitionEffect.fade),
                                  ),
                                  const SizedBox(height: 12),
                                  _labeledSlider(
                                    'Time per image',
                                    _logoHoldSeconds,
                                    0.5,
                                    5,
                                    (v) => setState(() => _logoHoldSeconds = v),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_homeMode == HomeMode.event) ...[
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _openConcertPreviewPopup,
                              child: const Text('Edit Concert Style'),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (isPortrait && _persistentRotateHint)
                          _buildPersistentRotateHint(t),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('show-sign'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(180, 52),
                    ),
                    onPressed: _showSign,
                    icon: const Icon(Icons.fullscreen),
                    label: Text(t.show, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Share image',
                    child: SizedBox(
                      width: 54,
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey('share-created-image'),
                        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: _shareCreatedImage,
                        child: const Icon(Icons.ios_share),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (sidePanel)
              Positioned(
                top: 12,
                right: 16,
                bottom: (MediaQuery.viewInsetsOf(context).bottom - 64).clamp(
                    12.0,
                    (constraints.maxHeight - 140).clamp(12.0, double.infinity)),
                width: panelWidth,
                child: _buildFixedAdjustments(t),
              ),
            if (_tipVisible) Positioned.fill(child: _buildRotateBubble(t)),
          ],
        );
      }),
    );
  }
}
