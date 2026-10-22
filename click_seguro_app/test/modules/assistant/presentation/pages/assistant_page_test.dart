import 'dart:async';

import 'package:click_seguro_app/core/errors/connection_failure.dart';
import 'package:click_seguro_app/modules/assistant/presentation/pages/assistant_page.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_analysis_card.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_image_storage_service.dart';
import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/assistant_dependencies.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_assistant_repository.dart';

Finder _verificationScrollable() {
  final list = find.byType(ListView).first;
  return find.descendant(of: list, matching: find.byType(Scrollable)).first;
}

Future<void> _scrollToVerificationTarget(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(
      target,
      120,
      scrollable: _verificationScrollable(),
    );

Future<void> _tapAnalyzeButton(WidgetTester tester) async {
  final label = find.text('Analisar mensagem');
  await _scrollToVerificationTarget(tester, label);
  final button = find
      .ancestor(of: label, matching: find.byType(SafeButton))
      .first;
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  late UserSessionService session;
  late FakeAssistantRepository repository;
  late FakeImageStorageService imageStorage;
  late GoRouter router;

  setUp(() {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    repository = FakeAssistantRepository();
    imageStorage = FakeImageStorageService();
    registerAssistantDependencies(
      GetIt.instance,
      repository: repository,
      imageStorage: imageStorage,
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
    await tester.tap(find.text('Histórico'));
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
    await tester.tap(find.text('Histórico'));
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
        await tester.ensureVisible(find.text(tab));
        await tester.tap(find.text(tab));
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
