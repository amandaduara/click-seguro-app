import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/completion_page.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/localized_app.dart';

void main() {
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;
  late List<CompletionAction?> actions;

  const ModuleCompletion twoOfThree = ModuleCompletion(
    title: 'Golpes Digitais',
    score: ModuleScoreEntity(score: 2, total: 3),
  );

  setUp(() {
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    actions = [];
    GetIt.instance
      ..registerSingleton(preferences)
      ..registerFactory(
        () => ReadAloudController(tts, preferences: preferences),
      );
  });

  tearDown(() => GetIt.instance.reset());

  /// Uma tela que abre a conclusão por `push` e guarda a ação devolvida.
  Future<void> open(
    WidgetTester tester, {
    ModuleCompletion? completion = twoOfThree,
    Locale locale = const Locale('pt', 'BR'),
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => actions.add(
                await context.push<CompletionAction>(
                  '/done',
                  extra: completion,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'done',
              builder: (_, state) =>
                  CompletionPage(completion: state.extra as ModuleCompletion?),
            ),
          ],
        ),
      ],
    );
    await pumpLocalized(tester, router: router, locale: locale);
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('conteúdo (US1)', () {
    testWidgets('título do módulo, troféu, pontuação e mensagem', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Golpes Digitais'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trophy), findsOneWidget);
      expect(find.text('Módulo concluído!'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Módulo concluído!')),
        isSemantics(isLiveRegion: true),
      );
      expect(find.text('Você acertou 2 de 3'), findsOneWidget);
      expect(
        find.text('Muito bem! Você já sabe se proteger desses golpes.'),
        findsOneWidget,
      );
    });

    testWidgets('sem pontuação: sem a linha e nunca "0 de 0"', (tester) async {
      await open(
        tester,
        completion: const ModuleCompletion(title: 'Golpes Digitais'),
      );

      expect(find.textContaining('acertou'), findsNothing);
      expect(find.textContaining('0 de 0'), findsNothing);
      expect(find.text('Módulo concluído!'), findsOneWidget);
    });

    testWidgets('"Voltar às atividades" devolve finish', (tester) async {
      await open(tester);

      await tapButton(tester, 'Voltar às atividades');

      expect(actions, [CompletionAction.finish]);
    });

    testWidgets('voltar do aparelho devolve null (= finish)', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(actions, [null]);
    });

    testWidgets('"Refazer o módulo" devolve redo', (tester) async {
      await open(tester);

      await tapButton(tester, 'Refazer o módulo');

      expect(actions, [CompletionAction.redo]);
    });

    testWidgets('sem dados (rota aberta direto): volta sem erro', (
      tester,
    ) async {
      await open(tester, completion: null);

      expect(find.text('abrir'), findsOneWidget);
      expect(actions, [null]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('letra 2× num celular: sem estouro, botões alcançáveis', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await open(tester);
      await tapButton(tester, 'Refazer o módulo');

      expect(tester.takeException(), isNull);
      expect(actions, [CompletionAction.redo]);
    });

    testWidgets('em inglês', (tester) async {
      await open(tester, locale: const Locale('en', 'US'));

      expect(find.text('Module completed!'), findsOneWidget);
      expect(find.text('You got 2 of 3 right'), findsOneWidget);
      expect(find.text('Back to activities'), findsOneWidget);
    });
  });

  group('voz (clarificação 3)', () {
    const String spoken =
        'Módulo concluído!\n'
        'Você acertou 2 de 3.\n'
        'Muito bem! Você já sabe se proteger desses golpes.';

    testWidgets('leitura automática: lê uma vez ao abrir', (tester) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);

      expect(tts.spoken.single.text, spoken);

      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.fast,
      );
      await tester.pumpAndSettle();
      expect(tts.spoken, hasLength(1));
    });

    testWidgets('"Ouvir" lê e vira "Parar"; sair para a leitura', (
      tester,
    ) async {
      await open(tester);

      await tapButton(tester, 'Ouvir');
      expect(tts.spoken.single.text, spoken);
      expect(find.text('Parar'), findsOneWidget);
      final int stopsBefore = tts.stopCalls;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThan(stopsBefore));
    });

    testWidgets('sem voz no idioma: sem "Ouvir" e nada lido', (tester) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);

      expect(find.text('Ouvir'), findsNothing);
      expect(tts.spoken, isEmpty);
    });
  });
}
