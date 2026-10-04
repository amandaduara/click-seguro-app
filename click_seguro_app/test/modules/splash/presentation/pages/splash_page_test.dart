import 'dart:async';

import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:click_seguro_app/modules/splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_splash_usecases.dart';

void main() {
  late FakeCheckOnboardingSeenUseCase checkOnboarding;
  late FakeValidateStoredSessionUseCase validateSession;

  setUp(() {
    checkOnboarding = FakeCheckOnboardingSeenUseCase();
    validateSession = FakeValidateStoredSessionUseCase();
  });

  GoRouter buildRouter() {
    Widget stub(String name) => Scaffold(body: Text('tela $name'));
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => SplashController(
              checkOnboarding,
              validateSession,
              minimumDisplayDuration: Duration.zero,
            ),
            child: const SplashPage(),
          ),
        ),
        GoRoute(path: '/onboarding', builder: (_, _) => stub('onboarding')),
        GoRoute(path: '/home', builder: (_, _) => stub('home')),
        GoRoute(path: '/login', builder: (_, _) => stub('login')),
      ],
    );
  }

  testWidgets('mostra o nome e a frase de apoio enquanto decide', (
    tester,
  ) async {
    validateSession.completer = Completer<UserSessionStatus>();

    await pumpLocalized(tester, router: buildRouter());

    expect(find.text('SafeNews'), findsOneWidget);
    expect(find.text('Sua segurança em primeiro lugar'), findsOneWidget);

    validateSession.completer!.complete(UserSessionStatus.authenticated);
    await tester.pumpAndSettle();
  });

  testWidgets('visto + conectada abre a área principal e sai da pilha', (
    tester,
  ) async {
    final router = buildRouter();

    await pumpLocalized(tester, router: router);

    expect(find.text('tela home'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('visto + sem sessão abre o login', (tester) async {
    validateSession.status = UserSessionStatus.unauthenticated;

    await pumpLocalized(tester, router: buildRouter());

    expect(find.text('tela login'), findsOneWidget);
  });

  testWidgets('onboarding não visto abre o onboarding', (tester) async {
    checkOnboarding.result = const Right(false);

    await pumpLocalized(tester, router: buildRouter());

    expect(find.text('tela onboarding'), findsOneWidget);
  });
}
