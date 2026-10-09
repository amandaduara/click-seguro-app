import 'package:click_seguro_app/core/routing/app_router.dart';
import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/activities/activities.dart';
import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/help.dart';
import 'package:click_seguro_app/modules/news/news.dart';
import 'package:click_seguro_app/modules/notifications/notifications.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/profile/profile.dart';
import 'package:click_seguro_app/modules/settings/settings.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:click_seguro_app/modules/splash/splash.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final (moduleManager, router) = await setupApp();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: ClickSeguroApp(moduleManager: moduleManager, router: router),
    ),
  );
}

/// Todos os módulos do app, na ordem do plano do produto §1.4. Também usada
/// pelo teste de fumaça.
List<ModuleInterface> appModules() => [
  CommonModule(),
  SettingsModule(),
  AuthenticationModule(),
  OnboardingModule(),
  SplashModule(),
  NewsModule(),
  NotificationsModule(),
  ActivitiesModule(),
  HelpModule(),
  ProfileModule(),
  ShellModule(),
];

/// Registra os módulos e prepara o estado que a primeira tela precisa. Também
/// usada pela entrada de desenvolvimento `lib/dev/accessibility_playground.dart`.
Future<(ModuleManagerInterface, GoRouter)> setupApp() async {
  final ModuleManagerInterface moduleManager = ModuleManager();
  await moduleManager.registerModules(appModules());
  // O splash já sai com a letra e o contraste escolhidos (RF-041).
  await GetIt.instance<AccessibilityController>().load();
  final UserSessionService session = GetIt.instance<UserSessionService>();
  // Antes do runApp: a primeira tela já encontra o estado da sessão (FR-002).
  await session.restoreSession();
  return (moduleManager, buildAppRouter(session));
}

class ClickSeguroApp extends StatelessWidget {
  const ClickSeguroApp({
    super.key,
    required this.moduleManager,
    required this.router,
  });

  final ModuleManagerInterface moduleManager;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: moduleManager.providers,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.lightTheme,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        routerConfig: router,
      ),
    );
  }
}
