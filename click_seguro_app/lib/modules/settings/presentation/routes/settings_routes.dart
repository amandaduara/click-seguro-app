import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/about_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/change_password_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/privacy_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/settings_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/settings_section_page.dart';
import 'package:go_router/go_router.dart';

/// Telas do módulo sobre as abas. "Dados pessoais" abre `/profile/edit`
/// (feature 012), por isso não há `/settings/account`.
final List<RouteBase> settingsRoutes = [
  GoRoute(
    path: '/settings',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const SettingsPage(),
    routes: [
      GoRoute(
        path: 'security',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: 'accessibility',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsSectionPage(
          titleKey: AppStrings.settingsAccessibilityTitle,
        ),
      ),
      GoRoute(
        path: 'privacy',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: 'about',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutPage(),
      ),
    ],
  ),
];
