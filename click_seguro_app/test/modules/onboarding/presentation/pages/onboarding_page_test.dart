import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/controller/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_onboarding_repository.dart';

void main() {
  late FakeOnboardingRepository repository;

  setUp(() => repository = FakeOnboardingRepository());

  GoRouter buildRouter() => GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) =>
              OnboardingController(CompleteOnboardingUseCase(repository)),
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('login')),
      ),
    ],
  );

  testWidgets('1º slide com "Pular" e "Continuar"', (tester) async {
    await pumpLocalized(tester, router: buildRouter());

    expect(find.text('Proteja-se de golpes'), findsOneWidget);
    expect(find.text('Pular'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('"Continuar" duas vezes leva ao último slide e a "Começar"', (
    tester,
  ) async {
    await pumpLocalized(tester, router: buildRouter());

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Aprenda na prática'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('deslizar até o último slide também mostra "Começar"', (
    tester,
  ) async {
    await pumpLocalized(tester, router: buildRouter());

    for (var i = 0; i < 2; i++) {
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
    }

    expect(find.text('Aprenda na prática'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('o indicador acompanha o arraste (specs/022 FR-024)', (
    tester,
  ) async {
    await pumpLocalized(tester, router: buildRouter());
    // Sem a margem de 8 à direita; pontos de 10, o ativo de 32 (redesign).
    double width(int index) =>
        tester.getSize(find.byKey(ValueKey('onboarding-dot-$index'))).width - 8;
    expect(width(0), 32);
    expect(width(1), 10);

    final double half = tester.getSize(find.byType(PageView)).width / 2;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(Offset(-half, 0));
    await tester.pump();

    expect(width(0), inExclusiveRange(10, 32));
    expect(width(1), inExclusiveRange(10, 32));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(width(1), 32);
  });

  testWidgets('"Começar" abre o login', (tester) async {
    await pumpLocalized(tester, router: buildRouter());

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(repository.seen, isTrue);
  });

  testWidgets('"Pular" é lido como botão, não como filtro', (tester) async {
    await pumpLocalized(tester, router: buildRouter());
    final SemanticsHandle semantics = tester.ensureSemantics();

    expect(
      tester.getSemantics(find.text('Pular')),
      isSemantics(
        label: 'Pular',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasSelectedState: false,
      ),
    );
    expect(
      tester.getSize(find.widgetWithText(SafeButton, 'Pular')).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  testWidgets('"Pular" no 1º slide abre o login', (tester) async {
    await pumpLocalized(tester, router: buildRouter());

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(repository.seen, isTrue);
  });

  testWidgets('falha ao gravar a marcação ainda abre o login', (tester) async {
    repository.failOnComplete = true;
    await pumpLocalized(tester, router: buildRouter());

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });
}
