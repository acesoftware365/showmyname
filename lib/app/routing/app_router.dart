// Path: lib/routing/app_router.dart
// Description: GoRouter configuration used by MaterialApp.router (main.dart).
// Update:
// - Shows AdBanner on ALL normal screens using ShellRoute (Home/Settings/Privacy/Logo/Paywall).
// - Keeps DisplayScreen outside the shell for true fullscreen (no double banners, no UI issues).
// Routes:
// - name: home     path: /
// - name: display  path: /display (expects SignConfig in state.extra)
// - name: settings path: /settings
// - name: privacy  path: /privacy
// - name: logo     path: /logo
// - name: paywall  path: /paywall

import 'package:go_router/go_router.dart';
import '../../ads/ad_banner_shell.dart';
import '../../features/display/display_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/privacy/privacy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/terms/terms_screen.dart';
import '../../models/sign_config.dart';
import '../../services/logo/logo_screen.dart';

class AppRouter {
  // ✅ IMPORTANT: this must be a GoRouter instance (NOT a function)
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // ✅ All "normal" screens wrapped with banner
      ShellRoute(
        builder: (context, state, child) {
          return AdBannerShell(
            child: child,
          );
        },
        routes: [
          GoRoute(
            name: 'home',
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            name: 'settings',
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            name: 'privacy',
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            name: 'terms',
            path: '/terms',
            builder: (context, state) => const TermsScreen(),
          ),
          GoRoute(
            name: 'logo',
            path: '/logo',
            builder: (context, state) => const LogoScreen(),
          ),
          GoRoute(
            name: 'paywall',
            path: '/paywall',
            builder: (context, state) => const PaywallScreen(),
          ),
        ],
      ),

      // ✅ Fullscreen display OUTSIDE the banner shell
      GoRoute(
        name: 'display',
        path: '/display',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is SignConfig) {
            return DisplayScreen(config: extra);
          }
          // fallback -> home
          return const HomeScreen();
        },
      ),
    ],
  );
}
