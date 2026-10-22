import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/data/repositories/activities_repository_impl.dart';
import 'package:click_seguro_app/modules/activities/domain/failures/activities_failures.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/lesson_page.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/feedback_sheet.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/activities_dependencies.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_remote_data_source.dart';
import '../../fakes/fake_activities_repository.dart';

void main() {
  late UserSessionService session;
  late FakeActivitiesRepository repository;
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;
  late GoRouter router;

  void useModule({
    Set<String> answered = const {},
    List<Map<String, dynamic>>? lessons,
  }) => repository.moduleDetailResults = [
    Right(
      ModuleDetailModel.fromJson(
        moduleDetailJson(answered: answered, lessons: lessons),
      ).toEntity(),
    ),
  ];

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'maria@exemplo.com',
    );
    repository = FakeActivitiesRepository();
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    GetIt.instance
      ..registerSingleton<UserSessionService>(session)
      ..registerSingleton(preferences)
      ..registerFactory(
        () => ReadAloudController(tts, preferences: preferences),
      );
    registerActivitiesDependencies(GetIt.instance, repository: repository);
    router = GoRouter(
      initialLocation: '/activities/m1',
      routes: [
        GoRoute(
          path: '/activities',
          builder: (_, _) => const Scaffold(body: Text('page:/activities')),
          routes: [
            GoRoute(
              path: ':moduleId',
              builder: (_, state) =>
                  LessonPage(moduleId: state.pathParameters['moduleId']!),
            ),
          ],
        ),
      ],
    );
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('pt', 'BR'),
  }) => pumpLocalized(tester, router: router, locale: locale);

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('ver as perguntas (US1)', () {
    testWidgets('título, posição, enunciado e alternativas numeradas', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Golpes Digitais'), findsOneWidget);
      expect(find.text('Pergunta 1 de 3'), findsOneWidget);
      expect(
        find.text('Promessa de dinheiro em dobro pelo PIX. O que fazer?'),
        findsOneWidget,
      );
      for (final (index, text) in [
        'Ignorar e denunciar',
        'Enviar',
        'Pedir prova',
        'Repassar',
      ].indexed) {
        await reveal(tester, find.text(text));
        expect(find.text('${index + 1}'), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('Ignorar e denunciar')).dy,
        lessThan(tester.getTopLeft(find.text('Repassar')).dy),
      );
    });

    testWidgets('abre na primeira pergunta não respondida', (tester) async {
      useModule(answered: {'l1'});
      await open(tester);

      expect(find.text('Pergunta 2 de 3'), findsOneWidget);
      expect(
        find.text('E-mail do banco pede para clicar num link. E agora?'),
        findsOneWidget,
      );
    });

    testWidgets('imagem que falha ou sem imagem: sem erro', (tester) async {
      await open(tester);
      expect(tester.takeException(), isNull);

      useModule(
        lessons: [
          lessonJson(imageUrl: null),
          lessonJson(id: 'l2', order: 2),
        ],
      );
      router.go('/activities');
      await tester.pumpAndSettle();
      router.go('/activities/m1');
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a explicação nunca aparece (FR-016)', (tester) async {
      await open(tester);

      expect(
        find.textContaining('Explicação que só aparece depois da resposta'),
        findsNothing,
      );
    });

    testWidgets('celular com letra 2×: sem estouro', (tester) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await open(tester);
      await reveal(tester, find.text('Repassar'));

      expect(tester.takeException(), isNull);
    });

    testWidgets('em inglês', (tester) async {
      await open(tester, locale: const Locale('en', 'US'));

      expect(find.text('Question 1 of 3'), findsOneWidget);
    });
  });

  group('navegação (US2)', () {
    SafeButton button(WidgetTester tester, String label) =>
        tester.widget<SafeButton>(find.widgetWithText(SafeButton, label));

    testWidgets('anterior e próxima mudam a posição', (tester) async {
      useModule(answered: {'l1', 'l2', 'l3'});
      await open(tester);

      await tester.tap(find.text('Próxima'));
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 2 de 3'), findsOneWidget);

      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 1 de 3'), findsOneWidget);
    });

    testWidgets('"Próxima" desativado sem resposta; "Anterior" na primeira', (
      tester,
    ) async {
      await open(tester);

      expect(button(tester, 'Próxima').onPressed, isNull);
      expect(button(tester, 'Anterior').onPressed, isNull);
    });

    testWidgets('marcas: respondidas com check; leitura de tela resumida', (
      tester,
    ) async {
      useModule(answered: {'l1'});
      await open(tester);

      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pergunta 2 de 3, 1 concluídas'),
        findsOneWidget,
      );
    });

    testWidgets('sessão expira com a tela aberta: mesma pergunta, sem erro', (
      tester,
    ) async {
      await open(tester);

      await session.expire();
      await tester.pumpAndSettle();

      expect(find.text('Pergunta 1 de 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ouvir (US3)', () {
    const String spokenL1 =
        'Promessa de dinheiro em dobro pelo PIX. O que fazer?\n\n'
        'Alternativa 1: Ignorar e denunciar.\n'
        'Alternativa 2: Enviar.\n'
        'Alternativa 3: Pedir prova.\n'
        'Alternativa 4: Repassar.';

    Future<void> tapListen(WidgetTester tester) async {
      await reveal(tester, find.text('Ouvir'));
      await tester.tap(find.text('Ouvir'));
      await tester.pumpAndSettle();
    }

    testWidgets('"Ouvir" lê o enunciado e as alternativas, e vira "Parar"', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.slow,
      );
      await open(tester);

      await tapListen(tester);

      expect(tts.spoken.single.text, spokenL1);
      expect(tts.spoken.single.speed, ReadingSpeed.slow);
      expect(find.text('Parar'), findsOneWidget);

      await tester.tap(find.text('Parar'));
      await tester.pumpAndSettle();
      expect(tts.stopCalls, greaterThanOrEqualTo(1));
      expect(find.text('Ouvir'), findsOneWidget);
    });

    testWidgets('sem voz no idioma: sem "Ouvir" e nada lido sozinho', (
      tester,
    ) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);

      expect(find.text('Ouvir'), findsNothing);
      expect(tts.spoken, isEmpty);
    });

    testWidgets('leitura automática: lê a pergunta sozinha uma vez', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);

      expect(tts.spoken.single.text, spokenL1);

      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.fast,
      );
      await tester.pumpAndSettle();
      expect(tts.spoken, hasLength(1));
    });

    testWidgets('trocar de pergunta para a leitura e lê a nova', (
      tester,
    ) async {
      useModule(answered: {'l1', 'l2', 'l3'});
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);
      final int stopsBefore = tts.stopCalls;

      await tester.tap(find.text('Próxima'));
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThan(stopsBefore));
      expect(tts.spoken, hasLength(2));
      expect(tts.spoken.last.text, startsWith('E-mail do banco'));
      // A nova pergunta continua sendo lida: o parar não a cancela.
      await reveal(tester, find.text('Parar'));
      expect(find.text('Parar'), findsOneWidget);

      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(tts.spoken, hasLength(3));
      expect(tts.spoken.last.text, startsWith('Promessa de dinheiro'));
    });

    testWidgets(
      'voltar e avançar de novo lê a pergunta outra vez (relato do aparelho)',
      (tester) async {
        // Abre na 3 (1 e 2 respondidas), volta à 2 e avança de novo à 3.
        useModule(answered: {'l1', 'l2'});
        preferences.value = preferences.value.copyWith(autoReadAloud: true);
        await open(tester);
        expect(tts.spoken.single.text, startsWith('Técnico pede'));

        await tester.tap(find.text('Anterior'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Próxima'));
        await tester.pumpAndSettle();

        expect(
          [for (final s in tts.spoken) s.text.substring(0, 6)],
          ['Técnic', 'E-mail', 'Técnic'],
        );
        await reveal(tester, find.text('Parar'));
        expect(find.text('Parar'), findsOneWidget);
      },
    );

    testWidgets('a mesma pergunta na tela não é lida de novo sozinha', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);

      tts.finishSpeaking();
      await tester.pumpAndSettle();
      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.fast,
      );
      await tester.pumpAndSettle();

      expect(tts.spoken, hasLength(1));
    });

    testWidgets('sair da tela para a leitura', (tester) async {
      await open(tester);
      await tapListen(tester);
      final int stopsBefore = tts.stopCalls;

      router.go('/activities');
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThan(stopsBefore));
    });
  });

  group('responder (specs/018 US1)', () {
    SafeButton confirmButton(WidgetTester tester) => tester.widget<SafeButton>(
      find.widgetWithText(SafeButton, 'Confirmar resposta'),
    );

    Future<void> choose(WidgetTester tester, String text) async {
      await reveal(tester, find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('"Confirmar resposta" desativado sem escolha', (tester) async {
      await open(tester);

      expect(confirmButton(tester).onPressed, isNull);
    });

    testWidgets('escolher ativa; trocar muda; confirmar envia uma vez', (
      tester,
    ) async {
      await open(tester);

      await choose(tester, 'Enviar');
      expect(confirmButton(tester).onPressed, isNotNull);
      await choose(tester, 'Pedir prova');

      repository.answerGate = Completer<void>();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pump();
      expect(confirmButton(tester).loading, isTrue);
      await tester.tap(find.text('Confirmar resposta'), warnIfMissed: false);
      await tester.pump();
      repository.answerGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.answerCalls, hasLength(1));
      expect(repository.answerCalls.single.selectedOptionId, 'l1-o3');
    });

    testWidgets('durante o envio as alternativas não trocam', (tester) async {
      await open(tester);
      await choose(tester, 'Enviar');
      repository.answerGate = Completer<void>();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pump();

      await tester.tap(find.text('Repassar'), warnIfMissed: false);
      await tester.pump();
      repository.answerGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.answerCalls.single.selectedOptionId, 'l1-o2');
    });

    testWidgets('as alternativas ficam na ordem do serviço (RF-027)', (
      tester,
    ) async {
      await open(tester);
      await choose(tester, 'Repassar');
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();

      final List<String> texts = [
        for (final card in tester.widgetList<LessonOptionCard>(
          find.byType(LessonOptionCard, skipOffstage: false),
        ))
          card.text,
      ];
      expect(texts, [
        'Ignorar e denunciar',
        'Enviar',
        'Pedir prova',
        'Repassar',
      ]);
    });

    testWidgets('visitante também responde', (tester) async {
      await session.logout();
      await session.startGuestSession();
      await open(tester);

      await choose(tester, 'Enviar');
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();

      expect(repository.answerCalls, hasLength(1));
    });
  });

  group('feedback (specs/018 US2)', () {
    Future<void> answer(WidgetTester tester, String text) async {
      await reveal(tester, find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
    }

    LessonOptionCard card(WidgetTester tester, String text) =>
        tester.widget<LessonOptionCard>(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(LessonOptionCard),
          ),
        );

    testWidgets('a explicação só aparece depois de confirmar (FR-018)', (
      tester,
    ) async {
      await open(tester);
      expect(
        find.text('Promessas de dinheiro em dobro são golpe.'),
        findsNothing,
      );

      await answer(tester, 'Ignorar e denunciar');

      expect(
        find.text('Promessas de dinheiro em dobro são golpe.'),
        findsOneWidget,
      );
    });

    testWidgets('errada: painel; fechado pelo voltar, resultado nas '
        'alternativas e "Próxima" ativo', (tester) async {
      repository.answerResults = [
        Right(
          AnswerResultModel.fromJson(answerJson(isCorrect: false)).toEntity(),
        ),
      ];
      await open(tester);

      await answer(tester, 'Enviar');
      expect(find.text('Não foi dessa vez'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Não foi dessa vez'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Pergunta 1 de 3'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pergunta 1 de 3'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(card(tester, 'Enviar').state, LessonOptionState.wrong);
      expect(card(tester, 'Enviar').onTap, isNull);
      await reveal(tester, find.text('Ignorar e denunciar'));
      expect(
        card(tester, 'Ignorar e denunciar').state,
        LessonOptionState.correct,
      );
      expect(
        tester
            .widget<SafeButton>(find.widgetWithText(SafeButton, 'Próxima'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('certa: "Você acertou!"; "Próxima pergunta" vai à 2', (
      tester,
    ) async {
      await open(tester);

      await answer(tester, 'Ignorar e denunciar');
      expect(find.text('Você acertou!'), findsOneWidget);

      await tester.tap(find.text('Próxima pergunta'));
      await tester.pumpAndSettle();

      expect(find.text('Você acertou!'), findsNothing);
      expect(find.text('Pergunta 2 de 3'), findsOneWidget);
      expect(
        tester
            .widgetList<LessonOptionCard>(find.byType(LessonOptionCard))
            .every((c) => c.state == LessonOptionState.idle),
        isTrue,
      );
    });

    testWidgets('na última, "Voltar às atividades" volta ao painel', (
      tester,
    ) async {
      useModule(answered: {'l1', 'l2'});
      await open(tester);

      await answer(tester, 'Ignorar');
      await tester.tap(find.text('Voltar às atividades'));
      await tester.pumpAndSettle();

      expect(find.text('page:/activities'), findsOneWidget);
    });
  });

  group('responder de novo (specs/018 US4)', () {
    Future<void> choose(WidgetTester tester, String text) async {
      await reveal(tester, find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('"Responder de novo" limpa e permite outra resposta', (
      tester,
    ) async {
      await open(tester);
      await choose(tester, 'Enviar');
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Confirmar resposta'), findsNothing);
      await tester.tap(find.text('Responder de novo'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<LessonOptionCard>(find.byType(LessonOptionCard))
            .every((c) => c.state == LessonOptionState.idle && c.onTap != null),
        isTrue,
      );
      await choose(tester, 'Ignorar e denunciar');
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();

      expect(find.text('Você acertou!'), findsOneWidget);
      expect(repository.answerCalls, hasLength(2));
    });

    testWidgets(
      'respondida pelo serviço: alternativas tocáveis e "Confirmar"',
      (tester) async {
        useModule(answered: {'l1', 'l2', 'l3'});
        await open(tester);

        expect(find.text('Confirmar resposta'), findsOneWidget);
        expect(find.text('Responder de novo'), findsNothing);
        await choose(tester, 'Enviar');
        expect(
          tester
              .widget<SafeButton>(
                find.widgetWithText(SafeButton, 'Confirmar resposta'),
              )
              .onPressed,
          isNotNull,
        );
      },
    );
  });

  group('polimento (specs/018 T038)', () {
    testWidgets('celular, letra 2× e alto contraste: responder sem estouro', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      repository.answerResults = [
        Right(
          AnswerResultModel.fromJson(
            answerJson(
              isCorrect: false,
              explanation: 'Uma explicação bem comprida. ' * 20,
            ),
          ).toEntity(),
        ),
      ];
      await pumpLocalized(
        tester,
        router: router,
        theme: AppTheme.highContrastTheme,
      );

      await reveal(tester, find.text('Enviar'));
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Próxima pergunta'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await reveal(tester, find.text('sua resposta, errada'));
      expect(find.text('Responder de novo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('em inglês', (tester) async {
      await open(tester, locale: const Locale('en', 'US'));

      expect(find.text('Confirm answer'), findsOneWidget);
      await reveal(tester, find.text('Ignorar e denunciar'));
      await tester.tap(find.text('Ignorar e denunciar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm answer'));
      await tester.pumpAndSettle();

      expect(find.text('You got it right!'), findsOneWidget);
      expect(find.text('Correct answer: Ignorar e denunciar'), findsOneWidget);
      expect(find.text('Next question'), findsOneWidget);
    });
  });

  group('voz no feedback (specs/018 US5)', () {
    const String spokenFeedbackL1 =
        'Você acertou!\n'
        'Resposta correta: Ignorar e denunciar.\n'
        'Promessas de dinheiro em dobro são golpe.';

    Finder inSheet(Finder finder) =>
        find.descendant(of: find.byType(FeedbackSheet), matching: finder);

    Future<void> answerFirst(WidgetTester tester) async {
      await reveal(tester, find.text('Ignorar e denunciar'));
      await tester.tap(find.text('Ignorar e denunciar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
    }

    testWidgets('confirmar para a leitura da pergunta', (tester) async {
      await open(tester);
      await reveal(tester, find.text('Ouvir'));
      await tester.tap(find.text('Ouvir'));
      await tester.pumpAndSettle();
      final int stopsBefore = tts.stopCalls;

      await answerFirst(tester);

      expect(tts.stopCalls, greaterThan(stopsBefore));
    });

    testWidgets('"Ouvir" no painel lê o feedback e vira "Parar"', (
      tester,
    ) async {
      await open(tester);
      await answerFirst(tester);

      await tester.tap(inSheet(find.text('Ouvir')));
      await tester.pumpAndSettle();

      expect(tts.spoken.last.text, spokenFeedbackL1);
      expect(inSheet(find.text('Parar')), findsOneWidget);
    });

    testWidgets('leitura automática: o feedback uma vez, a pergunta não de '
        'novo; "Próxima pergunta" lê a 2', (tester) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);
      expect(tts.spoken, hasLength(1));

      await answerFirst(tester);

      expect(tts.spoken, hasLength(2));
      expect(tts.spoken.last.text, spokenFeedbackL1);

      final int stopsBefore = tts.stopCalls;
      await tester.tap(find.text('Próxima pergunta'));
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThan(stopsBefore));
      expect(tts.spoken, hasLength(3));
      expect(tts.spoken.last.text, startsWith('E-mail do banco'));
    });

    testWidgets('fechar pelo voltar para a leitura do feedback', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);
      await answerFirst(tester);
      final int stopsBefore = tts.stopCalls;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThan(stopsBefore));
      expect(tts.spoken, hasLength(2));
    });

    testWidgets('sem voz no idioma: sem "Ouvir" no painel e nada lido', (
      tester,
    ) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await open(tester);
      await answerFirst(tester);

      expect(find.byType(FeedbackSheet), findsOneWidget);
      expect(inSheet(find.text('Ouvir')), findsNothing);
      expect(tts.spoken, isEmpty);
    });
  });

  group('erros ao responder (specs/018 US6)', () {
    Future<void> chooseSecond(WidgetTester tester) async {
      await reveal(tester, find.text('Enviar'));
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
    }

    testWidgets('sem internet: mensagem e a escolha continua marcada', (
      tester,
    ) async {
      repository.answerResults = [const Left(ConnectionFailure())];
      await open(tester);
      await chooseSecond(tester);

      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível enviar sua resposta. Tente de novo.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<LessonOptionCard>(
              find.ancestor(
                of: find.text('Enviar'),
                matching: find.byType(LessonOptionCard),
              ),
            )
            .state,
        LessonOptionState.selected,
      );
      expect(find.text('Não foi dessa vez'), findsNothing);
    });

    testWidgets('recusada: mensagem e o módulo recarregado', (tester) async {
      repository.answerResults = [const Left(AnswerRejectedFailure())];
      await open(tester);
      final int loadsBefore = repository.moduleDetailCalls;
      await chooseSecond(tester);

      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Esta pergunta foi atualizada. Carregamos as atividades de novo.',
        ),
        findsOneWidget,
      );
      expect(repository.moduleDetailCalls, greaterThan(loadsBefore));
      await tester.scrollUntilVisible(
        find.text('Pergunta 1 de 3'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pergunta 1 de 3'), findsOneWidget);
    });

    testWidgets('envio demorado: aviso de serviço acordando', (tester) async {
      await open(tester);
      await chooseSecond(tester);
      repository.answerGate = Completer<void>();

      await tester.tap(find.text('Confirmar resposta'));
      await tester.pump();
      expect(find.textContaining('O serviço está acordando'), findsNothing);
      await tester.pump(SlowRequestNotice.delay);
      expect(find.textContaining('O serviço está acordando'), findsOneWidget);

      repository.answerGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('sair da tela no meio do envio: sem erro', (tester) async {
      await open(tester);
      await chooseSecond(tester);
      repository.answerGate = Completer<void>();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pump();

      router.go('/activities');
      await tester.pumpAndSettle();
      repository.answerGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('page:/activities'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('pontuação (specs/018 US3)', () {
    testWidgets('só no painel, nunca na tela das perguntas', (tester) async {
      repository.moduleDetailResults = [
        Right(
          ModuleDetailModel.fromJson(
            moduleDetailJson(score: 1, totalScore: 3),
          ).toEntity(),
        ),
      ];
      await open(tester);
      expect(find.textContaining('acertos'), findsNothing);

      await reveal(tester, find.text('Ignorar e denunciar'));
      await tester.tap(find.text('Ignorar e denunciar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      expect(find.text('Você está com 1 de 3 acertos'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.textContaining('acertos'), findsNothing);
    });

    testWidgets('visitante: registro da sessão e "1 de 3" no painel', (
      tester,
    ) async {
      await session.logout();
      await session.startGuestSession();
      final FakeActivitiesRemoteDataSource remote =
          FakeActivitiesRemoteDataSource();
      final GuestProgressStore store = GuestProgressStore(session);
      addTearDown(store.dispose);
      await GetIt.instance.reset();
      GetIt.instance
        ..registerSingleton<UserSessionService>(session)
        ..registerSingleton(preferences)
        ..registerFactory(
          () => ReadAloudController(tts, preferences: preferences),
        );
      registerActivitiesDependencies(
        GetIt.instance,
        repository: ActivitiesRepositoryImpl(remote, store, session),
      );
      await open(tester);

      await reveal(tester, find.text('Ignorar e denunciar'));
      await tester.tap(find.text('Ignorar e denunciar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();

      expect(find.text('Você está com 1 de 3 acertos'), findsOneWidget);
      expect(store.correctCount('m1'), 1);
      // O que a tela de atividades da B1 lê na volta (SC-007).
      expect(store.answeredCount('m1'), 1);
    });
  });

  group('estados (US4)', () {
    testWidgets('carregando e, depois de 5 s, o aviso de serviço acordando', (
      tester,
    ) async {
      repository.moduleDetailGate = Completer<void>();
      await pumpLocalized(tester, router: router, settle: false);

      expect(find.byType(SafeLoadingState), findsOneWidget);
      expect(find.textContaining('O serviço está acordando'), findsNothing);
      await tester.pump(SlowRequestNotice.delay);
      expect(find.textContaining('O serviço está acordando'), findsOneWidget);

      repository.moduleDetailGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Pergunta 1 de 3'), findsOneWidget);
    });

    testWidgets('erro com "Tentar novamente", que recarrega', (tester) async {
      repository.moduleDetailResults = [
        const Left(ConnectionFailure()),
        Right(ModuleDetailModel.fromJson(moduleDetailJson()).toEntity()),
      ];
      await open(tester);

      expect(
        find.text('Não foi possível carregar as atividades'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Pergunta 1 de 3'), findsOneWidget);
    });

    testWidgets('módulo que não existe: "sem atividades"', (tester) async {
      repository.moduleDetailResults = [const Left(ModuleNotFoundFailure())];
      await open(tester);

      expect(find.text('Este módulo ainda não tem atividades'), findsOneWidget);
    });

    testWidgets('módulo sem lições válidas: "sem atividades"', (tester) async {
      useModule(
        lessons: [
          lessonJson(options: const ['Só uma']),
        ],
      );
      await open(tester);

      expect(find.text('Este módulo ainda não tem atividades'), findsOneWidget);
    });

    testWidgets('lição com uma alternativa fica de fora da contagem', (
      tester,
    ) async {
      useModule(
        lessons: [
          lessonJson(options: const ['Só uma']),
          lessonJson(id: 'l2', order: 2),
          lessonJson(id: 'l3', order: 3),
        ],
      );
      await open(tester);

      expect(find.text('Pergunta 1 de 2'), findsOneWidget);
    });
  });
}
