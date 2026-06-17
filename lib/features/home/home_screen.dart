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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sign_config.dart';
import '../../models/sign_mode.dart';
import '../display/widgets/effect_sign.dart';
import '../../services/logo/logo_storage_service.dart';
import '../../services/subscription/subscription_manager.dart';
import 'widgets/mode_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _airportController = TextEditingController(text: 'Welcome 😊 VIP ⭐ 👉');
  final _eventController = TextEditingController(text: 'LIVE TONIGHT 🎤 VIP');
  final GlobalKey _shareKey = GlobalKey();

  static const String _appleUrl =
      'https://apps.apple.com/us/app/showmyname-display/id6758596742';
  static const String _googleUrl =
      'https://play.google.com/store/apps/details?id=com.liisgo.showmyname&utm_source=na_Med';
  static const String _liisgoWebsite = 'https://liisgo.com';

  // ✅ Presets
  HomeMode _homeMode = HomeMode.airport;

  // Map to your existing enums
  SignUsageMode _mode = SignUsageMode.airport;
  SignType _type = SignType.textOnly;

  // Airport options
  double _airportFontScale = 1.0;
  bool _airportBold = true;
  TextAlign _airportTextAlign = TextAlign.center;
  bool _airportShowIcon = false;

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

  // Pro
  bool _loading = false;
  bool _isPro = false;
  StreamSubscription<bool>? _proSub;

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
  late final AnimationController _wiggleController;
  late final Animation<double> _wiggleTurns; // rotation turns
  late final AnimationController _colorWavePreviewController;

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

    _colorWavePreviewController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _loadState();
    _proSub = SubscriptionManager.proStream.listen((isPro) {
      if (!mounted) return;
      setState(() => _isPro = isPro);
    });
    _applyHomeMode(HomeMode.airport);

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRotateTip());
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

  void _applyHomeMode(HomeMode m) {
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

      // ColorWave preset
      _mode = SignUsageMode.concert;
      _type = SignType.colorOnly;
    });
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
        message: null,
        usageMode: _mode,
        signType: SignType.colorOnly,
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
      textAlign:
          _homeMode == HomeMode.airport ? _airportTextAlign : TextAlign.center,
      showIcon: _homeMode == HomeMode.airport ? _airportShowIcon : false,
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
        usageMode: SignUsageMode.concert,
        signType: SignType.colorOnly,
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

    return SignConfig(
      message: _currentTextController.text,
      usageMode: _homeMode == HomeMode.event
          ? SignUsageMode.concert
          : SignUsageMode.airport,
      signType:
          _homeMode == HomeMode.event ? SignType.textMotion : SignType.textOnly,
      fontScale: _currentFontScale,
      textColor: _currentTextColor,
      backgroundColor: _currentBackgroundColor,
      bold: _homeMode == HomeMode.airport ? _airportBold : true,
      textAlign:
          _homeMode == HomeMode.airport ? _airportTextAlign : TextAlign.center,
      showIcon: _homeMode == HomeMode.airport ? _airportShowIcon : false,
      colorShift: false,
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
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.35),
                  child: Icon(icon, size: 19, color: const Color(0xFFE9D5FF)),
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

  Widget _colorSwatch(Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 14,
          ),
        ],
      ),
    );
  }

  Color _currentColorWavePreviewColor() {
    if (!_colorCycle || _cycleColors.isEmpty) return _singleColor;
    if (_cycleColors.length == 1) return _cycleColors.first;

    final holdMs = (_holdSeconds * 1000).round().clamp(250, 30000);
    final transitionMs = _transitionMs.round().clamp(100, 10000);
    final stepMs = holdMs + transitionMs;
    final totalMs = stepMs * _cycleColors.length;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch.remainder(totalMs);
    final index = (elapsedMs ~/ stepMs) % _cycleColors.length;
    final nextIndex = (index + 1) % _cycleColors.length;
    final stepElapsed = elapsedMs % stepMs;

    if (stepElapsed < holdMs) return _cycleColors[index];

    final localT = ((stepElapsed - holdMs) / transitionMs).clamp(0.0, 1.0);

    if (_transitionType == ColorTransitionType.fade) {
      return Color.lerp(_cycleColors[index], _cycleColors[nextIndex], localT) ??
          _cycleColors[index];
    }

    return localT < 0.5 ? _cycleColors[index] : _cycleColors[nextIndex];
  }

  Widget _buildLivePreview(AppLocalizations t, {double height = 190}) {
    final config = _previewConfig();
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB56CFF).withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.35),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (config.isColorOnly)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _colorWavePreviewController,
                builder: (context, _) {
                  return AnimatedContainer(
                    duration: config.transitionDuration,
                    curve: Curves.easeInOut,
                    color: _currentColorWavePreviewColor(),
                  );
                },
              ),
            )
          else if (config.isLogoOnly)
            Positioned.fill(
              child: Center(
                child: (_logoPath == null || !_logoExistsSync)
                    ? Text(t.noLogoSaved,
                        style: const TextStyle(color: Colors.white70))
                    : Padding(
                        padding: const EdgeInsets.all(22),
                        child:
                            Image.file(File(_logoPath!), fit: BoxFit.contain),
                      ),
              ),
            )
          else
            Positioned.fill(child: EffectSign(config: config, preview: true)),
        ],
      ),
    );
  }

  Widget _buildDialogPreview() {
    return _buildLivePreview(AppLocalizations.of(context), height: 170);
  }

  Future<void> _openTextEditor(AppLocalizations t) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Text',
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: _currentTextController,
                    minLines: 1,
                    maxLines: 2,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (_) {
                      setState(() {});
                      modalSetState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: t.messageHint,
                      prefixIcon: const Icon(Icons.edit_outlined),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_homeMode == HomeMode.airport)
                    _buildAirportStyleControls(t, update),
                  if (_homeMode == HomeMode.airport) const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openConcertPreviewPopup() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                        const Icon(Icons.visibility_outlined,
                            color: Color(0xFFE9D5FF)),
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

  Future<void> _openColorWaveStylePopup(AppLocalizations t) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
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
                        Text('ColorWave',
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
                    _buildColorWaveControls(t, update),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ),
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _colorCycle,
          onChanged: (v) => update(() => _colorCycle = v),
          title: Text(t.colorCycle),
          subtitle: Text(_colorCycle ? t.multiColors : t.singleColor),
        ),
        const SizedBox(height: 8),
        Row(
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
                icon: const Icon(Icons.palette_outlined),
                label: Text(t.addColor),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => update(() {
                _cycleColors
                  ..clear()
                  ..addAll([Colors.blue, Colors.purple, Colors.red]);
              }),
              child: Text(t.resetColors),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
                width: 38,
                height: 38,
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
        const SizedBox(height: 16),
        _labeledSlider(t.holdTime, _holdSeconds, 1, 15,
            (v) => update(() => _holdSeconds = v)),
        const SizedBox(height: 6),
        Text(t.transition, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ColorTransitionType>(
          segments: [
            ButtonSegment(value: ColorTransitionType.fade, label: Text(t.fade)),
            ButtonSegment(
                value: ColorTransitionType.slide, label: Text(t.slide)),
          ],
          selected: {_transitionType},
          onSelectionChanged: (s) => update(() => _transitionType = s.first),
        ),
        const SizedBox(height: 12),
        _labeledSlider(t.transitionDuration, _transitionMs, 200, 2000,
            (v) => update(() => _transitionMs = v)),
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
    ];
  }

  Widget _buildColorButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          _colorSwatch(color),
        ],
      ),
    );
  }

  Widget _buildAirportStyleControls(
    AppLocalizations t,
    void Function(VoidCallback) update,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.textSize, style: Theme.of(context).textTheme.titleSmall),
        Slider(
          value: _airportFontScale,
          min: 0.7,
          max: 1.5,
          divisions: 8,
          label: _airportFontScale.toStringAsFixed(2),
          onChanged: (v) => update(() => _airportFontScale = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildColorButton(
                label: t.textColor,
                color: _airportTextColor,
                onPressed: () async {
                  final selected = await _pickColorDialog(context);
                  if (selected != null) {
                    update(() => _airportTextColor = selected);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildColorButton(
                label: t.backgroundColor,
                color: _airportBackgroundColor,
                onPressed: () async {
                  final selected = await _pickColorDialog(context);
                  if (selected != null) {
                    update(() => _airportBackgroundColor = selected);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _airportBold,
          onChanged: (v) => update(() => _airportBold = v),
          title: const Text('Bold'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _airportShowIcon,
          onChanged: (v) => update(() => _airportShowIcon = v),
          title: const Text('Airport icon'),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TextAlign>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
                value: TextAlign.left, icon: Icon(Icons.format_align_left)),
            ButtonSegment(
                value: TextAlign.center, icon: Icon(Icons.format_align_center)),
            ButtonSegment(
                value: TextAlign.right, icon: Icon(Icons.format_align_right)),
          ],
          selected: {_airportTextAlign},
          onSelectionChanged: (s) => update(() => _airportTextAlign = s.first),
        ),
      ],
    );
  }

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
        Container(
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
      ],
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

  @override
  void dispose() {
    _tipController.dispose();
    _wiggleController.dispose();
    _colorWavePreviewController.dispose();
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

    final isTextMode =
        _homeMode == HomeMode.airport || _homeMode == HomeMode.event;
    final isLogoMode = _homeMode == HomeMode.logo;

    return Scaffold(
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(),
                        ),
                      _buildLivePreview(t),
                      const SizedBox(height: 14),
                      Card(
                        color: const Color(0xFF11131C).withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: ModeSelector(
                            value: _homeMode,
                            onChanged: _applyHomeMode,
                            airportLabel: t.airportPickup,
                            eventLabel: t.concertEvent,
                            colorWaveLabel: t.colorWave,
                            logoLabel: t.logo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                                    style:
                                        const TextStyle(color: Colors.white70)),
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
                                        icon: const Icon(Icons.delete_outline),
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
                                  child: (_logoPath == null || !_logoExistsSync)
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
                                                  errorBuilder: (_, __, ___) =>
                                                      Text(
                                                    t.logoLoadError,
                                                    style: const TextStyle(
                                                        color: Colors.white70),
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
                                  onChanged: (v) => setState(() => _logoEffect =
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
                      const SizedBox(height: 24),
                      if (isTextMode) ...[
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () => _openTextEditor(t),
                            child: const Text('Enter New Text'),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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
                      if (_homeMode == HomeMode.colorWave) ...[
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () => _openColorWaveStylePopup(t),
                            child: const Text('Edit ColorWave Style'),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _showSign,
                          icon: const Icon(Icons.fullscreen),
                          label: Text(t.show),
                        ),
                      ),
                      if (isPortrait && _persistentRotateHint)
                        _buildPersistentRotateHint(t),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_tipVisible) Positioned.fill(child: _buildRotateBubble(t)),
        ],
      ),
    );
  }
}
