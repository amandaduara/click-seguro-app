import 'dart:math' as math;

import 'dart:async';

import 'package:click_seguro_app/core/errors/connection_failure.dart';
import 'package:click_seguro_app/modules/assistant/presentation/pages/assistant_page.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_analysis_card.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_typing_bubble.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/chat_message_entrance.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_image_storage_service.dart';
import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/assistant_dependencies.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_assistant_repository.dart';

Finder _verificationScrollable() {
  final list = find.byType(ListView).first;
  return find.descendant(of: list, matching: find.byType(Scrollable)).first;
}

/// Rola a lista da aba Verificar pela posição, não por arrasto: com a fonte
/// ampliada o campo de texto fica no meio da tela e consumiria o arrasto.
Future<void> _scrollToVerificationTarget(
  WidgetTester tester,
  Finder target,
) async {
  final ScrollPosition position = tester
      .state<ScrollableState>(_verificationScrollable())
      .position;
  if (target.evaluate().isEmpty) {
    position.jumpTo(0);
    await tester.pump();
  }
  while (target.evaluate().isEmpty &&
      position.pixels < position.maxScrollExtent) {
    position.jumpTo(math.min(position.pixels + 120, position.maxScrollExtent));
    await tester.pump();
  }
  // No meio da tela: na borda, o botão pode ficar sob a barra inferior.
  await Scrollable.ensureVisible(tester.element(target.first), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _tapAnalyzeButton(WidgetTester tester) async {
  final label = find.text('Analisar mensagem');
  await _scrollToVerificationTarget(tester, label);
  final button = find
      .ancestor(of: label, matching: find.byType(SafeButton))
      .first;
  await tester.tap(button);
}

void main() {
  late UserSessionService session;
  late FakeAssistantRepository repository;
  late FakeImageStorageService imageStorage;
  late GoRouter router;
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;

  setUp(() {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    repository = FakeAssistantRepository();
    imageStorage = FakeImageStorageService();
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    registerAssistantDependencies(
      GetIt.instance,
      repository: repository,
      imageStorage: imageStorage,
      tts: tts,
      preferences: preferences,
    );
    router = GoRouter(
      initialLocation: '/assistant',
      routes: [
        GoRoute(path: '/assistant', builder: (_, _) => const AssistantPage()),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Tela de entrada')),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await GetIt.instance.reset();
  });

  Future<void> open(WidgetTester tester) =>
      pumpLocalized(tester, router: router, theme: AppTheme.lightTheme);

  // Leitura automática (validação da usuária, specs/023): como nas outras
  // telas, com a opção ligada a resposta e o resultado são lidos.
  group('leitura automática', () {
    Future<void> signIn() => session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );

    Future<void> sendHello(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const ValueKey('assistant-chat-input')),
        'Como saber se um link é seguro?',
      );
      await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
      await tester.pumpAndSettle();
    }

    testWidgets('ligada: lê a resposta do assistente, não a da pessoa', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await signIn();
      await open(tester);

      await sendHello(tester);

      expect(tts.spoken.map((s) => s.text), ['Resposta segura']);
    });

    testWidgets('desligada: não lê', (tester) async {
      await signIn();
      await open(tester);

      await sendHello(tester);

      expect(tts.spoken, isEmpty);
    });

    testWidgets('ligada: lê o resultado da verificação', (tester) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await signIn();
      await open(tester);
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('assistant-analysis-text')),
        'Recebi esta mensagem suspeita hoje',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await _tapAnalyzeButton(tester);
      await tester.pumpAndSettle();

      expect(tts.spoken, hasLength(1));
      expect(tts.spoken.single.text, startsWith('Alto risco de golpe.'));
    });
  });

  testWidgets('visitante vê convite e não chama API nem seletor de imagem', (
    tester,
  ) async {
    await session.startGuestSession();
    await open(tester);
    expect(find.text('Entre para conversar com a assistente'), findsOneWidget);
    await tester.tap(find.text('Entrar ou criar conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar ou criar conta').last);
    await tester.pumpAndSettle();
    expect(find.text('Tela de entrada'), findsOneWidget);
    expect(repository.totalCalls, 0);
    expect(imageStorage.pickedSources, isEmpty);
  });

  testWidgets('chat usa sugestão no campo e envia só após ação explícita', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    await open(tester);
    expect(repository.totalCalls, 0);
    await tester.tap(find.text('Como saber se um link é seguro?'));
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('assistant-chat-input')),
    );
    expect(field.controller!.text, 'Como saber se um link é seguro?');
    expect(repository.chatCalls, isEmpty);
    await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
    await tester.pumpAndSettle();
    expect(repository.chatCalls, hasLength(1));
    expect(find.text('Resposta segura'), findsOneWidget);
  });

  testWidgets('conversa vazia mostra aviso curto e duas sugestões; com '
      'mensagens, só os balões e "Nova conversa" no topo', (tester) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    await open(tester);
    const privacy =
        'O que você enviar é analisado pelo serviço. A conversa some ao sair.';
    const suggestions = [
      'Como saber se um link é seguro?',
      'Recebi um prêmio por mensagem. Pode ser golpe?',
    ];
    const newConversation = ValueKey('assistant-new-conversation');
    expect(find.text(privacy), findsOneWidget);
    for (final suggestion in suggestions) {
      expect(find.text(suggestion), findsOneWidget);
    }
    expect(find.byKey(newConversation), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('assistant-chat-input')),
      'Isso é golpe?',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('Resposta segura'), findsOneWidget);
    expect(find.text(privacy), findsNothing);
    expect(find.text(suggestions.first), findsNothing);

    final handle = tester.ensureSemantics();
    final Size size = tester.getSize(find.byKey(newConversation));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(find.byKey(newConversation)),
      isSemantics(label: 'Nova conversa', isButton: true),
    );
    handle.dispose();

    await tester.tap(find.byKey(newConversation));
    await tester.pumpAndSettle();
    expect(find.text('Começar uma nova conversa?'), findsOneWidget);
    await tester.tap(find.text('Começar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Resposta segura'), findsNothing);
    expect(find.text(suggestions.first), findsOneWidget);
    expect(find.byKey(newConversation), findsNothing);
  });

  testWidgets('contador de caracteres só aparece perto do limite', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    await open(tester);
    final chatInput = find.byKey(const ValueKey('assistant-chat-input'));
    await tester.enterText(chatInput, 'a' * 50);
    await tester.pump();
    expect(find.textContaining('caracteres'), findsNothing);
    await tester.enterText(chatInput, 'a' * 800);
    await tester.pump();
    expect(find.text('800/1000 caracteres'), findsOneWidget);

    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();
    final analysisInput = find.byKey(const ValueKey('assistant-analysis-text'));
    await tester.enterText(analysisInput, 'a' * 50);
    await tester.pump();
    expect(find.textContaining('caracteres'), findsNothing);
    await tester.enterText(analysisInput, 'a' * 4000);
    await tester.pump();
    expect(find.text('4000/5000 caracteres'), findsOneWidget);
  });

  testWidgets('erro do chat permite tentar de novo sem duplicar a mensagem', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    repository.chatResults
      ..clear()
      ..add(const Left(ConnectionFailure()))
      ..add(const Right('Resposta recuperada'));
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('assistant-chat-input')),
      'Mensagem suspeita para análise',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
    await tester.pumpAndSettle();
    expect(
      find.text('Sem conexão com a internet. Verifique sua rede.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(repository.chatCalls, hasLength(2));
    expect(
      find.text('Mensagem suspeita para análise', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Resposta recuperada'), findsOneWidget);
  });

  testWidgets('novo rascunho permanece no campo enquanto o chat responde', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    final gate = Completer<void>();
    repository.chatGate = gate;
    await open(tester);
    final input = find.byKey(const ValueKey('assistant-chat-input'));
    await tester.enterText(input, 'Primeira mensagem enviada');
    await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
    await tester.pump();
    await tester.enterText(input, 'Rascunho da próxima mensagem');
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(input).controller!.text,
      'Rascunho da próxima mensagem',
    );
  });

  testWidgets('balão "digitando" enquanto responde; a resposta entra animada '
      '(specs/022 FR-026)', (tester) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    final gate = Completer<void>();
    repository.chatGate = gate;
    await open(tester);
    final handle = tester.ensureSemantics();

    await tester.enterText(
      find.byKey(const ValueKey('assistant-chat-input')),
      'É golpe?',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AssistantTypingBubble), findsOneWidget);
    expect(
      find.bySemanticsLabel('O assistente está digitando'),
      findsOneWidget,
    );

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(AssistantTypingBubble), findsNothing);
    final reply = tester.widget<ChatMessageEntrance>(
      find.byType(ChatMessageEntrance).last,
    );
    expect(reply.animate, isTrue);
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('com "Reduzir animações", os pontos ficam parados', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppMotionScope(
          appReduceMotion: true,
          child: Scaffold(body: AssistantTypingBubble()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('topo: voltar e histórico redondos, com rótulo e 48 dp; '
      'abas só Conversar e Verificar', (tester) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    await open(tester);
    final handle = tester.ensureSemantics();
    for (final key in ['assistant-back', 'assistant-history-button']) {
      final Size size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('assistant-history-button')),
      ),
      isSemantics(label: 'Histórico', isButton: true),
    );
    expect(find.text('Conversar'), findsOneWidget);
    expect(find.text('Verificar'), findsOneWidget);
    expect(find.text('Histórico'), findsNothing);
    handle.dispose();
  });

  testWidgets('enviar: botão redondo coral com rótulo, 48 dp e desativado '
      'enquanto responde', (tester) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    final gate = Completer<void>();
    repository.chatGate = gate;
    await open(tester);
    final handle = tester.ensureSemantics();
    final send = find.byKey(const ValueKey('assistant-chat-send'));
    final Size size = tester.getSize(send);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(send),
      matchesSemantics(
        label: 'Enviar',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('assistant-chat-input')),
      'É golpe?',
    );
    await tester.tap(send);
    await tester.pump();
    expect(
      tester.getSemantics(send),
      matchesSemantics(label: 'Enviar', isButton: true, hasEnabledState: true),
    );
    gate.complete();
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('câmera do rodapé leva à verificação de imagem e abre a câmera', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    imageStorage.nextResult = const PickedImage('/tmp/assistant-camera.png');
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('assistant-chat-camera')));
    await tester.pumpAndSettle();
    expect(imageStorage.pickedSources, [PhotoSource.camera]);
    expect(find.text('Remover imagem'), findsOneWidget);
    expect(repository.imageCalls, isEmpty);
  });

  testWidgets('histórico carregando mostra os blocos em lista', (tester) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    final gate = Completer<Either<Failure, AiHistoryPageEntity>>();
    repository.historyGates.add(gate);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('assistant-history-button')));
    await tester.pump();
    final loading = tester.widget<SafeLoadingState>(
      find.byType(SafeLoadingState),
    );
    expect(loading.layout, SafeLoadingLayout.list);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    gate.complete(Right(historyPage()));
    await tester.pumpAndSettle();
    expect(find.text('Seu histórico aparecerá aqui.'), findsOneWidget);
  });

  testWidgets('verificação de texto só chama API após toque em analisar', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    await open(tester);
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('assistant-analysis-text')),
      'Recebi esta mensagem suspeita hoje',
    );
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(repository.totalCalls, 0);
    await _tapAnalyzeButton(tester);
    await tester.pumpAndSettle();
    expect(repository.textCalls, hasLength(1));
    await _scrollToVerificationTarget(tester, find.text('Phishing'));
    expect(find.text('Phishing'), findsOneWidget);
  });

  testWidgets('histórico carrega ao abrir a área e alterna filtros', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    await open(tester);
    expect(repository.historyCalls, isEmpty);
    await tester.tap(find.byKey(const ValueKey('assistant-history-button')));
    await tester.pumpAndSettle();
    expect(repository.historyCalls, hasLength(1));
    await tester.tap(find.text('Conversas'));
    await tester.pumpAndSettle();
    expect(repository.historyCalls.last.feature?.name, 'chat');
  });

  testWidgets('erro do histórico na página permite nova tentativa', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    repository.historyResults
      ..clear()
      ..add(const Left(ConnectionFailure()))
      ..add(Right(historyPage()));
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('assistant-history-button')));
    await tester.pumpAndSettle();
    expect(
      find.text('Sem conexão com a internet. Verifique sua rede.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(repository.historyCalls, hasLength(2));
    expect(find.text('Seu histórico aparecerá aqui.'), findsOneWidget);
  });

  testWidgets('página envia imagem após seleção e mostra resultado', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    imageStorage.nextResult = const PickedImage('/tmp/assistant-test.png');
    await open(tester);
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Imagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    expect(repository.imageCalls, isEmpty);
    await tester.tap(find.text('Analisar mensagem'));
    await tester.pumpAndSettle();
    expect(repository.imageCalls, hasLength(1));
    expect(imageStorage.deletedPaths, ['/tmp/assistant-test.png']);
    // O resultado fica abaixo do botão, que ficou mais alto: rola até ele.
    await _scrollToVerificationTarget(tester, find.text('Phishing'));
    expect(find.text('Phishing'), findsOneWidget);
  });

  testWidgets(
    'layout mantém abas e resultados em 320 px, fonte 200% e alto contraste',
    (tester) async {
      await session.saveSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        email: 'ana@example.com',
      );
      repository.analysisResults
        ..clear()
        ..addAll([
          Right(analysisEntity(type: AiThreatType.socialEngineering)),
          Right(analysisEntity(type: null, riskScore: null, confidence: null)),
          Right(
            analysisEntity(
              status: AiAnalysisStatus.error,
              type: null,
              riskScore: null,
              confidence: null,
            ),
          ),
        ]);
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpLocalized(
        tester,
        router: router,
        theme: AppTheme.highContrastTheme,
      );
      expect(tester.takeException(), isNull);
      for (final tab in ['Verificar', 'Histórico', 'Conversar']) {
        final Finder target = tab == 'Histórico'
            ? find.byKey(const ValueKey('assistant-history-button'))
            : find.text(tab);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
        if (tab == 'Verificar') {
          await _scrollToVerificationTarget(
            tester,
            find.byKey(const ValueKey('assistant-analysis-text')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('assistant-analysis-text')),
            'Mensagem de teste com dados suspeitos',
          );
          await tester.pumpAndSettle();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          for (final result in [
            'Engenharia social',
            'Indisponível',
            'A análise não foi concluída.',
          ]) {
            await _tapAnalyzeButton(tester);
            await tester.pumpAndSettle();
            await _scrollToVerificationTarget(
              tester,
              find.byType(AssistantAnalysisCard),
            );
            expect(find.text(result), findsWidgets);
            if (result == 'Indisponível') {
              expect(find.text('0%'), findsNothing);
              expect(find.text('Seguro'), findsNothing);
            }
            expect(tester.takeException(), isNull, reason: result);
          }
        }
      }
    },
  );
}
