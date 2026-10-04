import 'dart:async';

import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_destination.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_splash_usecases.dart';

void main() {
  late FakeCheckOnboardingSeenUseCase checkOnboarding;
  late FakeValidateStoredSessionUseCase validateSession;

  setUp(() {
    checkOnboarding = FakeCheckOnboardingSeenUseCase();
    validateSession = FakeValidateStoredSessionUseCase();
  });

  SplashController build({Duration minimum = Duration.zero}) =>
      SplashController(
        checkOnboarding,
        validateSession,
        minimumDisplayDuration: minimum,
      );

  Future<SplashDestination?> resolve() async {
    final controller = build();
    await controller.resolveDestination();
    return controller.destination;
  }

  group('decisão do destino', () {
    test('onboarding não visto, mesmo conectado → onboarding', () async {
      checkOnboarding.result = const Right(false);

      expect(await resolve(), SplashDestination.onboarding);
    });

    test('falha ao ler o onboarding → onboarding', () async {
      checkOnboarding.result = const Left(CacheFailure());

      expect(await resolve(), SplashDestination.onboarding);
    });

    test('visto + conectada → home', () async {
      expect(await resolve(), SplashDestination.home);
    });

    test('visto + visitante → home', () async {
      validateSession.status = UserSessionStatus.guest;

      expect(await resolve(), SplashDestination.home);
    });

    test('visto + sem sessão → login', () async {
      validateSession.status = UserSessionStatus.unauthenticated;

      expect(await resolve(), SplashDestination.login);
    });
  });

  group('notificação', () {
    test(
      'destino nulo antes de decidir e uma notificação ao decidir',
      () async {
        final controller = build();
        var notifications = 0;
        controller.addListener(() => notifications++);

        expect(controller.destination, isNull);
        await controller.resolveDestination();

        expect(notifications, 1);
      },
    );

    test('duas chamadas seguidas conferem e notificam uma única vez', () async {
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await Future.wait([
        controller.resolveDestination(),
        controller.resolveDestination(),
      ]);

      expect(validateSession.calls, 1);
      expect(checkOnboarding.calls, 1);
      expect(notifications, 1);
    });
  });

  // Relógio falso do testWidgets: tester.pump(Duration) avança o
  // Future.delayed do controller sem esperar tempo real.
  group('paralelismo', () {
    const minimum = Duration(seconds: 2);

    testWidgets('validação rápida espera o tempo mínimo', (tester) async {
      final controller = build(minimum: minimum);

      unawaited(controller.resolveDestination());
      await tester.pump(const Duration(milliseconds: 1999));
      expect(controller.destination, isNull);

      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.destination, SplashDestination.home);
    });

    testWidgets('mínimo vencido espera a validação', (tester) async {
      validateSession.completer = Completer<UserSessionStatus>();
      final controller = build(minimum: minimum);

      unawaited(controller.resolveDestination());
      await tester.pump(minimum);
      expect(controller.destination, isNull);

      validateSession.completer!.complete(UserSessionStatus.unauthenticated);
      await tester.pump();
      expect(controller.destination, SplashDestination.login);
    });

    testWidgets('a validação começa junto com o tempo mínimo', (tester) async {
      final controller = build(minimum: minimum);

      unawaited(controller.resolveDestination());
      expect(validateSession.calls, 1);
      expect(checkOnboarding.calls, 1);

      await tester.pump(minimum);
    });

    testWidgets('visto + conta recusada na conferência → login', (
      tester,
    ) async {
      validateSession.status = UserSessionStatus.unauthenticated;
      final controller = build(minimum: minimum);

      unawaited(controller.resolveDestination());
      await tester.pump(minimum);

      expect(controller.destination, SplashDestination.login);
    });
  });
}
