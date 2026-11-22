import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_page_header.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/completion_page.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
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

      expect(
        find.descendant(
          of: find.byType(SafePageHeader),
          matching: find.text('Golpes Digitais'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SafeIllustration>(find.byType(SafeIllustration))
            .illustration,
        AppIllustration.stateTrophy,
      );
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

    testWidgets('voltar do cabeçalho devolve null (= finish)', (tester) async {
      await open(tester);

      await tester.tap(find.byKey(SafePageHeader.defaultBackKey));
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

  group('movimento reduzido (R12 de specs/024)', () {
    /// O confete é um `CustomPaint` com o pintor privado da tela.
    final Finder confetti = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter.runtimeType.toString() == '_ConfettiPainter',
    );

    /// Abre a conclusão direto, sem esperar as animações.
    Future<void> openFirstFrame(WidgetTester tester, {required bool reduced}) =>
        pumpLocalized(
          tester,
          settle: false,
          child: AppMotionScope(
            appReduceMotion: reduced,
            child: const CompletionPage(completion: twoOfThree),
          ),
        );

    testWidgets('movimento normal: confete e placar contando a partir de 0', (
      tester,
    ) async {
      await openFirstFrame(tester, reduced: false);
      await tester.pump();

      expect(confetti, findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      await tester.pumpAndSettle();
      expect(confetti, findsNothing);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('reduzir animações: sem confete e placar final já no 1º '
        'quadro', (tester) async {
      await openFirstFrame(tester, reduced: true);

      expect(confetti, findsNothing);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      await tester.pump();
      expect(confetti, findsNothing);
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

    testWidgets('"Ouvir" logo abaixo do título, antes do placar e da '
        'mensagem (specs/025)', (tester) async {
      await open(tester);

      final double title = tester
          .getBottomLeft(find.text('Módulo concluído!'))
          .dy;
      final double listen = tester.getTopLeft(find.text('Ouvir')).dy;
      final double score = tester
          .getTopLeft(find.text('Você acertou 2 de 3'))
          .dy;

      expect(listen, greaterThan(title));
      expect(listen, lessThan(score));
    });

    testWidgets('sem voz no idioma: sem "Ouvir" e nada lido', (tester) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);

      expect(find.text('Ouvir'), findsNothing);
      expect(tts.spoken, isEmpty);
    });
  });

  group('botões (specs/025)', () {
    const String finish = 'Voltar às atividades';
    const String redo = 'Refazer o módulo';

    SafeButton buttonOf(WidgetTester tester, String label) =>
        tester.widget<SafeButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(SafeButton),
          ),
        );

    double topOf(WidgetTester tester, String label) =>
        tester.getTopLeft(find.text(label)).dy;

    /// Tela alta: os dois botões cabem sem rolar.
    void useTallScreen(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('errou a maioria: "Refazer" primeiro e em destaque', (
      tester,
    ) async {
      useTallScreen(tester);
      await open(
        tester,
        completion: const ModuleCompletion(
          title: 'Golpes Digitais',
          score: ModuleScoreEntity(score: 1, total: 3),
        ),
      );

      expect(topOf(tester, redo), lessThan(topOf(tester, finish)));
      expect(buttonOf(tester, redo).tone, SafeButtonTone.primary);
      expect(buttonOf(tester, finish).tone, SafeButtonTone.secondary);
    });

    for (final (String name, ModuleCompletion completion) in [
      ('acertou metade ou mais', twoOfThree),
      ('sem pontuação', const ModuleCompletion(title: 'Golpes Digitais')),
    ]) {
      testWidgets('$name: "Voltar" principal primeiro e "Refazer" depois', (
        tester,
      ) async {
        useTallScreen(tester);
        await open(tester, completion: completion);

        expect(topOf(tester, finish), lessThan(topOf(tester, redo)));
        expect(buttonOf(tester, finish).tone, SafeButtonTone.primary);
        expect(buttonOf(tester, redo).tone, SafeButtonTone.secondary);
      });
    }

    testWidgets('sem "Compartilhar"', (tester) async {
      useTallScreen(tester);
      await open(tester);

      expect(find.text('Refazer o módulo'), findsOneWidget);

      expect(find.text('Compartilhar'), findsNothing);
      expect(find.byIcon(LucideIcons.share2), findsNothing);
    });
  });
}
