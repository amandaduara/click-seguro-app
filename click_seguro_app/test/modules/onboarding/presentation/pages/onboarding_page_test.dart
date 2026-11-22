import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/controller/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_onboarding_repository.dart';

void main() {
  late FakeOnboardingRepository repository;
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;

  setUp(() {
    repository = FakeOnboardingRepository();
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    GetIt.instance
      ..registerSingleton(preferences)
      ..registerFactory(
        () => ReadAloudController(tts, preferences: preferences),
      );
  });

  tearDown(() => GetIt.instance.reset());

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

  group('"Ouvir" do slide', () {
    const String slide1 =
        'Proteja-se de golpes\n'
        'Receba alertas sobre os golpes mais comuns e aprenda a se defender.';
    const String slide2 =
        'Notícias verificadas\n'
        'Acompanhe fake news desmentidas por fontes oficiais.';

    testWidgets('fica abaixo do título, antes da descrição, e lê os dois', (
      tester,
    ) async {
      await pumpLocalized(tester, router: buildRouter());

      final Rect title = tester.getRect(find.text('Proteja-se de golpes'));
      final Rect listen = tester.getRect(find.text('Ouvir'));
      final Rect description = tester.getRect(
        find.textContaining('Receba alertas'),
      );
      expect(listen.top, greaterThan(title.bottom));
      expect(listen.bottom, lessThan(description.top));

      await tester.tap(find.text('Ouvir'));
      await tester.pump();

      expect(tts.spoken.single.text, slide1);
      expect(find.text('Parar'), findsOneWidget);
    });

    testWidgets('trocar de slide para a leitura', (tester) async {
      await pumpLocalized(tester, router: buildRouter());
      await tester.tap(find.text('Ouvir'));
      await tester.pump();
      final int stopsBefore = tts.stopCalls;

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThan(stopsBefore));
      expect(find.text('Parar'), findsNothing);
      expect(find.text('Ouvir'), findsOneWidget);

      await tester.tap(find.text('Ouvir'));
      await tester.pump();
      expect(tts.spoken.last.text, slide2);
    });

    testWidgets('leitura automática: lê cada slide ao aparecer', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await pumpLocalized(tester, router: buildRouter());

      expect(tts.spoken.single.text, slide1);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(tts.spoken.map((s) => s.text), [slide1, slide2]);
    });

    testWidgets('sem voz no idioma: sem "Ouvir" e nada lido', (tester) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await pumpLocalized(tester, router: buildRouter());

      expect(find.text('Ouvir'), findsNothing);
      expect(tts.spoken, isEmpty);
    });
  });
}
