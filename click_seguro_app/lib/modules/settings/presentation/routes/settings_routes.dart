import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/settings_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/settings_section_page.dart';
import 'package:go_router/go_router.dart';

/// Telas do módulo sobre as abas.
final List<RouteBase> settingsRoutes = [
  GoRoute(
    path: '/settings',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const SettingsPage(),
    routes: [
      GoRoute(
        path: 'account',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsSectionPage(
          titleKey: AppStrings.settingsAccountTitle,
        ),
      ),
      GoRoute(
        path: 'security',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsSectionPage(
          titleKey: AppStrings.settingsSecurityTitle,
        ),
      ),
      GoRoute(
        path: 'accessibility',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsSectionPage(
          titleKey: AppStrings.settingsAccessibilityTitle,
        ),
      ),
    ],
  ),
];
