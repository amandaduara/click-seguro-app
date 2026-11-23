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
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
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

/// Texto visível ("Ouvir"/"Parar") do botão de ouvir com a [key].
String? _listenLabel(WidgetTester tester, String key) {
  final Finder text = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(text.first).data;
}

/// Rola até o botão de ouvir com a [key] e toca nele.
Future<void> _tapListen(WidgetTester tester, String key) async {
  final Finder button = find.byKey(ValueKey(key));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
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

  // Erro visto no aparelho: ao abrir o teclado, a área ficava baixa, a tela
  // trocava de layout e recriava o campo, que perdia o foco e fechava o
  // teclado.
  testWidgets('abrir o teclado não recria o campo nem tira o foco', (
    tester,
  ) async {
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester);
    final Finder input = find.byKey(const ValueKey('assistant-chat-input'));
    final Finder editable = find.descendant(
      of: input,
      matching: find.byType(EditableText),
    );

    await tester.tap(input);
    await tester.pump();
    final Element before = tester.element(editable);
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);

    // O teclado ocupa metade da tela.
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.element(editable), same(before));
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
  });

  // Leitura automática (validação da usuária, specs/024): como nas outras
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

    // Visto no aparelho: as boas-vindas não eram lidas ao abrir (specs/025).
    testWidgets('ligada: lê as boas-vindas ao abrir a conversa vazia', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await signIn();
      await open(tester);

      expect(tts.spoken.map((s) => s.text), [_greeting]);
      expect(_listenLabel(tester, 'assistant-listen-greeting'), 'Parar');
    });

    testWidgets('ligada: lê a resposta do assistente, não a da pessoa', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await signIn();
      await open(tester);

      await sendHello(tester);

      // As boas-vindas ao abrir; depois, só a resposta.
      expect(tts.spoken.map((s) => s.text), [_greeting, 'Resposta segura']);
    });

    // Visto no aparelho: com o app em inglês e só a voz em português, nada
    // era lido. As respostas da IA vêm em português e saem nessa voz
    // (specs/025).
    testWidgets('app em inglês, só voz em português: lê a resposta', (
      tester,
    ) async {
      tts.availableLanguages = {SpeechLanguage.ptBr};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await signIn();
      await pumpLocalized(
        tester,
        router: router,
        theme: AppTheme.lightTheme,
        locale: const Locale('en', 'US'),
      );

      await tester.enterText(
        find.byKey(const ValueKey('assistant-chat-input')),
        'Como saber se um link é seguro?',
      );
      await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
      await tester.pumpAndSettle();

      expect(tts.spoken.map((s) => s.text), ['Resposta segura']);
      expect(tts.spoken.single.language, SpeechLanguage.ptBr);
    });

    testWidgets('desligada: não lê nem as boas-vindas', (tester) async {
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

      // As boas-vindas ao abrir; depois o selo (app), e a explicação vem
      // em seguida (conteúdo).
      expect(tts.spoken.map((s) => s.text), [
        _greeting,
        'Alto risco de golpe.',
      ]);
    });

    testWidgets('a mensagem lida automaticamente mostra "Parar"', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await signIn();
      await open(tester);

      await sendHello(tester);

      expect(_listenLabel(tester, 'assistant-listen-1'), 'Parar');
      expect(_listenLabel(tester, 'assistant-listen-greeting'), 'Ouvir');
    });
  });

  // "Ouvir" embaixo de cada balão do assistente (validação da usuária,
  // specs/025): lê aquela mensagem na voz do idioma do app.
  group('ouvir cada mensagem', () {
    Future<void> signIn() => session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'ana@example.com',
    );

    Future<void> send(WidgetTester tester, String text) async {
      await tester.enterText(
        find.byKey(const ValueKey('assistant-chat-input')),
        text,
      );
      await tester.tap(find.byKey(const ValueKey('assistant-chat-send')));
      await tester.pumpAndSettle();
    }

    testWidgets('só os balões do assistente têm o botão, com 48 dp', (
      tester,
    ) async {
      await signIn();
      await open(tester);
      await send(tester, 'Como saber se um link é seguro?');

      // Boas-vindas e resposta; a mensagem da pessoa (índice 0) não tem.
      expect(find.byType(ListenButton), findsNWidgets(2));
      expect(
        find.byType(ListenButton),
        findsNWidgets(
          find
              .byKey(const ValueKey('assistant-bubble-assistant'))
              .evaluate()
              .length,
        ),
      );
      expect(find.byKey(const ValueKey('assistant-listen-0')), findsNothing);
      expect(
        find.byKey(const ValueKey('assistant-listen-greeting')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('assistant-listen-1')), findsOneWidget);
      final Size size = tester.getSize(
        find.byKey(const ValueKey('assistant-listen-1')),
      );
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('tocar lê aquela mensagem; ela mostra "Parar" e as outras '
        '"Ouvir"; tocar de novo para', (tester) async {
      await signIn();
      await open(tester);
      await send(tester, 'Como saber se um link é seguro?');

      await _tapListen(tester, 'assistant-listen-1');
      await tester.pump();

      expect(tts.spoken.map((s) => s.text), ['Resposta segura']);
      expect(tts.spoken.single.language, SpeechLanguage.ptBr);
      expect(_listenLabel(tester, 'assistant-listen-1'), 'Parar');
      expect(_listenLabel(tester, 'assistant-listen-greeting'), 'Ouvir');

      await _tapListen(tester, 'assistant-listen-1');
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThanOrEqualTo(1));
      expect(tts.spoken, hasLength(1));
      expect(_listenLabel(tester, 'assistant-listen-1'), 'Ouvir');
    });

    testWidgets('tocar em outra mensagem troca a leitura para ela', (
      tester,
    ) async {
      repository.chatResults
        ..clear()
        ..addAll(const [Right('Primeira resposta'), Right('Segunda resposta')]);
      await signIn();
      await open(tester);
      await send(tester, 'Como saber se um link é seguro?');
      await send(tester, 'E se pedirem um código?');

      await _tapListen(tester, 'assistant-listen-1');
      await tester.pump();
      await _tapListen(tester, 'assistant-listen-3');
      await tester.pump();

      expect(tts.spoken.map((s) => s.text), [
        'Primeira resposta',
        'Segunda resposta',
      ]);
      expect(_listenLabel(tester, 'assistant-listen-3'), 'Parar');
      expect(_listenLabel(tester, 'assistant-listen-1'), 'Ouvir');

      // Ao terminar, todas voltam a "Ouvir".
      tts.finishSpeaking();
      await tester.pumpAndSettle();
      expect(_listenLabel(tester, 'assistant-listen-3'), 'Ouvir');
    });

    testWidgets('o botão vem logo depois do balão, com rótulo "Ouvir"', (
      tester,
    ) async {
      await signIn();
      await open(tester);
      await send(tester, 'Como saber se um link é seguro?');
      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(find.byKey(const ValueKey('assistant-listen-1'))),
        isSemantics(label: 'Ouvir', isButton: true, hasTapAction: true),
      );
      final double bubbleBottom = tester
          .getBottomLeft(find.text('Resposta segura'))
          .dy;
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('assistant-listen-1'))).dy,
        greaterThan(bubbleBottom),
      );
      handle.dispose();
    });

    testWidgets('o resultado da verificação também pode ser ouvido', (
      tester,
    ) async {
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

      const listen = ValueKey('assistant-listen-analysis');
      await _scrollToVerificationTarget(tester, find.byKey(listen));
      await tester.tap(find.byKey(listen));
      await tester.pump();

      expect(tts.spoken.single.text, 'Alto risco de golpe.');
      expect(_listenLabel(tester, 'assistant-listen-analysis'), 'Parar');
    });

    testWidgets('sem voz no idioma do app, não há botões', (tester) async {
      tts.availableLanguages = {};
      await signIn();
      await open(tester);
      await send(tester, 'Como saber se um link é seguro?');

      expect(find.byType(ListenButton), findsNothing);
    });

    testWidgets('com letra 2×, o botão cabe sem estourar', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await signIn();
      await open(tester);
      await send(tester, 'Como saber se um link é seguro?');

      expect(find.byKey(const ValueKey('assistant-listen-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
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

const String _greeting =
    'Olá! Sou a assistente Click Seguro. Posso ajudar você a reconhecer golpes e se proteger online.';
