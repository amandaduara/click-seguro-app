import 'dart:async';

import 'package:click_seguro_app/core/routing/app_router.dart';
import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/help.dart';
import 'package:click_seguro_app/modules/settings/settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../authentication/fakes/controller_factory.dart';
import '../../authentication/fakes/fake_auth_repository.dart';
import '../../../helpers/feed_provider.dart';
import '../../../helpers/splash_provider.dart';

/// FR-013 de specs/005-shell-navegacao-base e SC-008 da feature 001: a
/// expiração mantém a tela e avisa uma vez, pelo messenger raiz.
void main() {
  late UserSessionService session;
  late GoRouter router;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    router = buildAppRouter(session);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> signIn() => session.saveSession(
    accessToken: 'acesso-1',
    refreshToken: 'renovacao-1',
    email: 'maria@exemplo.com',
    userName: 'Maria',
  );

  /// Igual ao `pumpLocalized`, mas com o messenger raiz do app.
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableBuildModes = [];
    await EasyLocalization.ensureInitialized();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          startLocale: const Locale('pt', 'BR'),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) =>
                    buildAuthenticationController(FakeAuthRepository()),
              ),
              fakeSplashProvider(session.sessionStatus.value),
              fakeFeedProvider(),
            ],
            builder: (context, _) => MaterialApp.router(
              routerConfig: router,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    router.go('/help');
    await tester.pumpAndSettle();
  }

  const expiredText = 'Sua sessão expirou, faça login novamente.';

  testWidgets('expiração numa aba: fica na tela e mostra o aviso', (
    tester,
  ) async {
    await signIn();
    await pumpApp(tester);

    await session.expire();
    await tester.pumpAndSettle();

    expect(find.byType(HelpPage), findsOneWidget);
    expect(find.text(expiredText), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Entrar'), findsOneWidget);
  });

  testWidgets('"Entrar" no aviso leva ao login', (tester) async {
    await signIn();
    await pumpApp(tester);
    await session.expire();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SnackBarAction, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('duas recusas seguidas mostram um único aviso', (tester) async {
    await signIn();
    await pumpApp(tester);

    await session.expire();
    await session.expire();
    await tester.pumpAndSettle();

    expect(find.text(expiredText), findsOneWidget);
  });

  testWidgets('sobre as abas (configurações) também fica e avisa', (
    tester,
  ) async {
    await signIn();
    await pumpApp(tester);
    unawaited(router.push('/settings'));
    await tester.pumpAndSettle();

    await session.expire();
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text(expiredText), findsOneWidget);
  });

  testWidgets('saída de visitante não mostra o aviso de expiração', (
    tester,
  ) async {
    await session.startGuestSession();
    await pumpApp(tester);

    await session.logout();
    await tester.pumpAndSettle();

    expect(find.text(expiredText), findsNothing);
  });
}
