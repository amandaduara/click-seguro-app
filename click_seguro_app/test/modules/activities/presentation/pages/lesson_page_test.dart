import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/lesson_page.dart';
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

    testWidgets(
      'trocar de pergunta para e lê a nova uma vez; voltar não repete',
      (tester) async {
        useModule(answered: {'l1', 'l2', 'l3'});
        preferences.value = preferences.value.copyWith(autoReadAloud: true);
        await open(tester);
        final int stopsBefore = tts.stopCalls;

        await tester.tap(find.text('Próxima'));
        await tester.pumpAndSettle();

        expect(tts.stopCalls, greaterThan(stopsBefore));
        expect(tts.spoken, hasLength(2));
        expect(tts.spoken.last.text, startsWith('E-mail do banco'));

        await tester.tap(find.text('Anterior'));
        await tester.pumpAndSettle();
        expect(tts.spoken, hasLength(2));
      },
    );

    testWidgets('sair da tela para a leitura', (tester) async {
      await open(tester);
      await tapListen(tester);
      final int stopsBefore = tts.stopCalls;

      router.go('/activities');
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThan(stopsBefore));
    });
  });
}
