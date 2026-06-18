import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ShowMyName'**
  String get appName;

  /// No description provided for @freeActive.
  ///
  /// In en, this message translates to:
  /// **'Free mode'**
  String get freeActive;

  /// No description provided for @tapToExit.
  ///
  /// In en, this message translates to:
  /// **'Tap back to exit'**
  String get tapToExit;

  /// No description provided for @useToday.
  ///
  /// In en, this message translates to:
  /// **'Use today'**
  String get useToday;

  /// No description provided for @airportPickup.
  ///
  /// In en, this message translates to:
  /// **'Airport / Pickup'**
  String get airportPickup;

  /// No description provided for @concertEvent.
  ///
  /// In en, this message translates to:
  /// **'Concert / Event'**
  String get concertEvent;

  /// No description provided for @textEmojis.
  ///
  /// In en, this message translates to:
  /// **'Text + Emojis'**
  String get textEmojis;

  /// No description provided for @textBigIcon.
  ///
  /// In en, this message translates to:
  /// **'Text + Big Icon'**
  String get textBigIcon;

  /// No description provided for @bigIcon.
  ///
  /// In en, this message translates to:
  /// **'Big icon'**
  String get bigIcon;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @top.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get top;

  /// No description provided for @bottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get bottom;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'SHOW'**
  String get show;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @speedHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: lower is smoother, higher is faster.'**
  String get speedHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @presetAirportVip.
  ///
  /// In en, this message translates to:
  /// **'Airport VIP'**
  String get presetAirportVip;

  /// No description provided for @presetEventVip.
  ///
  /// In en, this message translates to:
  /// **'Concert VIP'**
  String get presetEventVip;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get goToSettings;

  /// No description provided for @showLogoButton.
  ///
  /// In en, this message translates to:
  /// **'SHOW LOGO'**
  String get showLogoButton;

  /// No description provided for @logoTitle.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logoTitle;

  /// No description provided for @logoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a logo to show it fullscreen.'**
  String get logoSubtitle;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload logo'**
  String get uploadLogo;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @proEnabled.
  ///
  /// In en, this message translates to:
  /// **'Pro enabled'**
  String get proEnabled;

  /// No description provided for @versionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Version unavailable'**
  String get versionUnknown;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Restore completed'**
  String get restoreDone;

  /// No description provided for @proRestored.
  ///
  /// In en, this message translates to:
  /// **'Pro restored successfully'**
  String get proRestored;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logoPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get logoPreview;

  /// No description provided for @logoSaved.
  ///
  /// In en, this message translates to:
  /// **'Logo saved.'**
  String get logoSaved;

  /// No description provided for @logoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Logo removed.'**
  String get logoRemoved;

  /// No description provided for @logoSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save logo.'**
  String get logoSaveError;

  /// No description provided for @logoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load logo. Upload again.'**
  String get logoLoadError;

  /// No description provided for @noLogoSaved.
  ///
  /// In en, this message translates to:
  /// **'No logo saved yet. Upload one in Settings first.'**
  String get noLogoSaved;

  /// No description provided for @motion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motion;

  /// No description provided for @noMotion.
  ///
  /// In en, this message translates to:
  /// **'No motion'**
  String get noMotion;

  /// No description provided for @rightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Right → Left'**
  String get rightToLeft;

  /// No description provided for @leftToRight.
  ///
  /// In en, this message translates to:
  /// **'Left → Right'**
  String get leftToRight;

  /// No description provided for @bottomToTop.
  ///
  /// In en, this message translates to:
  /// **'Bottom → Top'**
  String get bottomToTop;

  /// No description provided for @topToBottom.
  ///
  /// In en, this message translates to:
  /// **'Top → Bottom'**
  String get topToBottom;

  /// No description provided for @loop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get loop;

  /// No description provided for @bounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce'**
  String get bounce;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'If you change the language, reopen the app to apply everywhere.'**
  String get languageHint;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language saved.'**
  String get languageChanged;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'ShowMyName'**
  String get homeTitle;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message (emojis supported)'**
  String get messageHint;

  /// No description provided for @modeToday.
  ///
  /// In en, this message translates to:
  /// **'Use today'**
  String get modeToday;

  /// No description provided for @modeAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport / Pickup'**
  String get modeAirport;

  /// No description provided for @modeEvent.
  ///
  /// In en, this message translates to:
  /// **'Concert / Event'**
  String get modeEvent;

  /// No description provided for @signType.
  ///
  /// In en, this message translates to:
  /// **'Sign type'**
  String get signType;

  /// No description provided for @typeTextEmoji.
  ///
  /// In en, this message translates to:
  /// **'Text + Emojis'**
  String get typeTextEmoji;

  /// No description provided for @typeTextBigIcon.
  ///
  /// In en, this message translates to:
  /// **'Text + Big Icon'**
  String get typeTextBigIcon;

  /// No description provided for @colorShift.
  ///
  /// In en, this message translates to:
  /// **'Color shift (color only)'**
  String get colorShift;

  /// No description provided for @showLogo.
  ///
  /// In en, this message translates to:
  /// **'Show logo'**
  String get showLogo;

  /// No description provided for @showButton.
  ///
  /// In en, this message translates to:
  /// **'SHOW'**
  String get showButton;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get shareApp;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themePurpleNeon.
  ///
  /// In en, this message translates to:
  /// **'Purple Neon'**
  String get themePurpleNeon;

  /// No description provided for @themeElectricBlue.
  ///
  /// In en, this message translates to:
  /// **'Electric Blue'**
  String get themeElectricBlue;

  /// No description provided for @themeHotPink.
  ///
  /// In en, this message translates to:
  /// **'Hot Pink'**
  String get themeHotPink;

  /// No description provided for @themeLimeGlow.
  ///
  /// In en, this message translates to:
  /// **'Lime Glow'**
  String get themeLimeGlow;

  /// No description provided for @themeSunsetPop.
  ///
  /// In en, this message translates to:
  /// **'Sunset Pop'**
  String get themeSunsetPop;

  /// No description provided for @themeAquaVibe.
  ///
  /// In en, this message translates to:
  /// **'Aqua Vibe'**
  String get themeAquaVibe;

  /// No description provided for @themeCherryBomb.
  ///
  /// In en, this message translates to:
  /// **'Cherry Bomb'**
  String get themeCherryBomb;

  /// No description provided for @themeLemonFlash.
  ///
  /// In en, this message translates to:
  /// **'Lemon Flash'**
  String get themeLemonFlash;

  /// No description provided for @themeCyberLime.
  ///
  /// In en, this message translates to:
  /// **'Cyber Lime'**
  String get themeCyberLime;

  /// No description provided for @themeProHint.
  ///
  /// In en, this message translates to:
  /// **'Purple Neon is free. Extra themes are included with Pro.'**
  String get themeProHint;

  /// No description provided for @themeProRequired.
  ///
  /// In en, this message translates to:
  /// **'Themes are included with Pro.'**
  String get themeProRequired;

  /// No description provided for @themeSaved.
  ///
  /// In en, this message translates to:
  /// **'Theme saved.'**
  String get themeSaved;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro active'**
  String get proActive;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @addLogo.
  ///
  /// In en, this message translates to:
  /// **'Add logo'**
  String get addLogo;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get changeLogo;

  /// No description provided for @removeLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove logo'**
  String get removeLogo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @freeBanner.
  ///
  /// In en, this message translates to:
  /// **'ShowMyName FREE'**
  String get freeBanner;

  /// No description provided for @proBanner.
  ///
  /// In en, this message translates to:
  /// **'ShowMyName PRO'**
  String get proBanner;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @companyFooter.
  ///
  /// In en, this message translates to:
  /// **'Liisgo LLC • www.liisgo.com'**
  String get companyFooter;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'ShowMyName does not sell or share your personal data.\n\nAll messages you create and any optional logo are stored locally on your device and are never uploaded to our servers.\n\nIf you choose the Pro version, purchases are processed securely by Apple or Google. We only receive confirmation of your purchase status.\n\nWe may collect anonymous crash or performance data to improve app stability.\n\nFor support or questions, contact us at sales@liisgo.com.'**
  String get privacyBody;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @supportSubject.
  ///
  /// In en, this message translates to:
  /// **'ShowMyName Support'**
  String get supportSubject;

  /// No description provided for @supportBodyIntro.
  ///
  /// In en, this message translates to:
  /// **'Please describe your issue below:'**
  String get supportBodyIntro;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @preset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get preset;

  /// No description provided for @presetNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get presetNone;

  /// No description provided for @presetColorWave.
  ///
  /// In en, this message translates to:
  /// **'ColorWave (Colors Fullscreen)'**
  String get presetColorWave;

  /// No description provided for @colorCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle colors'**
  String get colorCycle;

  /// No description provided for @singleColor.
  ///
  /// In en, this message translates to:
  /// **'Single color'**
  String get singleColor;

  /// No description provided for @multiColors.
  ///
  /// In en, this message translates to:
  /// **'Multiple colors'**
  String get multiColors;

  /// No description provided for @addColor.
  ///
  /// In en, this message translates to:
  /// **'Add color'**
  String get addColor;

  /// No description provided for @resetColors.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetColors;

  /// No description provided for @holdTime.
  ///
  /// In en, this message translates to:
  /// **'Time per color'**
  String get holdTime;

  /// No description provided for @transition.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get transition;

  /// No description provided for @fade.
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get fade;

  /// No description provided for @slide.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get slide;

  /// No description provided for @transitionDuration.
  ///
  /// In en, this message translates to:
  /// **'Transition duration'**
  String get transitionDuration;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get seconds;

  /// No description provided for @colorWave.
  ///
  /// In en, this message translates to:
  /// **'ColorWave'**
  String get colorWave;

  /// No description provided for @motionStyle.
  ///
  /// In en, this message translates to:
  /// **'Motion style'**
  String get motionStyle;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeHelp.
  ///
  /// In en, this message translates to:
  /// **'Auto-fits the screen. Use this to make it smaller or bigger (emojis included).'**
  String get textSizeHelp;

  /// No description provided for @colorShiftHelp.
  ///
  /// In en, this message translates to:
  /// **'Smoothly changes text color while moving.'**
  String get colorShiftHelp;

  /// No description provided for @rotateToLandscapeBubble.
  ///
  /// In en, this message translates to:
  /// **'For best experience, rotate your device to landscape.'**
  String get rotateToLandscapeBubble;

  /// No description provided for @rotateToLandscapeHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: Rotate to landscape for a bigger sign.'**
  String get rotateToLandscapeHint;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get saved;

  /// No description provided for @proUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro Features'**
  String get proUnlockTitle;

  /// No description provided for @proUnlockBullets.
  ///
  /// In en, this message translates to:
  /// **'• Remove ads\n• Unlimited displays\n• Custom logos\n• Premium layouts\n• Priority updates'**
  String get proUnlockBullets;

  /// No description provided for @monthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyPlan;

  /// No description provided for @yearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly (Best Value)'**
  String get yearlyPlan;

  /// No description provided for @priceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get priceLoading;

  /// No description provided for @subLegal.
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your Apple ID or Google account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your account settings.'**
  String get subLegal;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageRussian;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @colorsSection.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colorsSection;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundColor;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'ja',
        'pt',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
