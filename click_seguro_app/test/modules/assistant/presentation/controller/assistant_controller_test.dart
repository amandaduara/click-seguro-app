import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller_status.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/core/errors/connection_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../fakes/fake_image_storage_service.dart';
import '../../../../helpers/assistant_dependencies.dart';
import '../../fakes/fake_assistant_repository.dart';

void main() {
  late FakeAssistantRepository repository;
  late FakeImageStorageService images;
  late AssistantController controller;

  setUp(() {
    repository = FakeAssistantRepository();
    images = FakeImageStorageService();
    controller = createAssistantController(repository, images);
  });

  tearDown(() => controller.dispose());

  test('não consulta conversa nem histórico antes de abrir cada área', () {
    expect(repository.totalCalls, 0);
    expect(controller.activeTab, AssistantTab.chat);
  });

  test('conversa valida, mantém falha e repete o envio sem duplicar', () async {
    repository.chatResults
      ..clear()
      ..addAll([
        const Left(ConnectionFailure()),
        const Right('Resposta recuperada'),
      ]);
    await controller.sendChatMessage('oi');
    expect(repository.chatCalls, isEmpty);
    await controller.sendChatMessage('Minha mensagem suspeita');
    expect(
      controller.chatMessages.where((message) => message.role.name == 'user'),
      hasLength(1),
    );
    expect(controller.chatFailure, isA<ConnectionFailure>());
    await controller.retryChatMessage();
    expect(repository.chatCalls, hasLength(2));
    expect(
      controller.chatMessages.where((message) => message.role.name == 'user'),
      hasLength(1),
    );
    expect(controller.chatMessages.last.content, 'Resposta recuperada');
    expect(controller.chatFailure, isNull);
  });

  test(
    'envios simultâneos da conversa fazem uma única chamada à API',
    () async {
      final gate = Completer<void>();
      repository.chatGate = gate;

      final first = controller.sendChatMessage('Mensagem enviada uma vez');
      await Future<void>.delayed(Duration.zero);
      await controller.sendChatMessage('Tentativa duplicada');

      expect(repository.chatCalls, hasLength(1));
      expect(controller.chatMessages, hasLength(1));
      expect(
        controller.chatMessages.single.content,
        'Mensagem enviada uma vez',
      );

      gate.complete();
      await first;
      expect(controller.chatMessages.map((message) => message.content), [
        'Mensagem enviada uma vez',
        'Resposta segura',
      ]);
    },
  );

  test(
    'histórico carrega sob demanda, pagina e remove IDs duplicados',
    () async {
      repository.historyResults
        ..clear()
        ..addAll([
          Right(
            historyPage(
              items: [
                analysisEntity(id: 'a'),
                analysisEntity(id: 'b'),
              ],
              hasNextPage: true,
            ),
          ),
          Right(
            historyPage(
              items: [
                analysisEntity(id: 'b'),
                analysisEntity(id: 'c'),
              ],
              page: 2,
              hasNextPage: false,
            ),
          ),
        ]);
      controller.activateTab(AssistantTab.history);
      await Future<void>.delayed(Duration.zero);
      expect(repository.historyCalls.single.feature, isNull);
      expect(controller.historyItems.map((item) => item.id), ['a', 'b']);
      await controller.loadNextHistoryPage();
      expect(controller.historyItems.map((item) => item.id), ['a', 'b', 'c']);
      expect(controller.historyHasNextPage, isFalse);
    },
  );

  test('nova tentativa após falha recarrega a primeira página', () async {
    repository.historyResults
      ..clear()
      ..addAll([
        Right(
          historyPage(items: [analysisEntity(id: 'old')], hasNextPage: true),
        ),
        const Left(ConnectionFailure()),
        Right(historyPage(items: [analysisEntity(id: 'refreshed')], page: 1)),
      ]);
    controller.activateTab(AssistantTab.history);
    await Future<void>.delayed(Duration.zero);
    await controller.refreshHistory();
    expect(controller.historyItems.single.id, 'old');
    expect(controller.historyFailure, isA<ConnectionFailure>());
    await controller.retryHistory();
    expect(repository.historyCalls.map((call) => call.page), [1, 1, 1]);
    expect(controller.historyItems.map((item) => item.id), ['refreshed']);
  });

  test('filtro ignora resposta atrasada de consulta anterior', () async {
    final first = Completer<Either<Failure, AiHistoryPageEntity>>();
    final second = Completer<Either<Failure, AiHistoryPageEntity>>();
    repository.historyGates.addAll([first, second]);
    controller.activateTab(AssistantTab.history);
    controller.setHistoryFilter(AssistantHistoryFilter.conversations);
    second.complete(
      Right(historyPage(items: [analysisEntity(id: 'chat-result')])),
    );
    await Future<void>.delayed(Duration.zero);
    first.complete(
      Right(historyPage(items: [analysisEntity(id: 'stale-result')])),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.historyCalls.last.feature, AiHistoryFeature.chat);
    expect(controller.historyItems.map((item) => item.id), ['chat-result']);
  });

  test(
    'análise durante carga mantém histórico desatualizado para próxima visita',
    () async {
      final historyGate = Completer<Either<Failure, AiHistoryPageEntity>>();
      repository.historyGates.add(historyGate);
      controller.activateTab(AssistantTab.history);
      await Future<void>.delayed(Duration.zero);

      controller.activateTab(AssistantTab.verify);
      await controller.analyzeText('Mensagem suspeita para análise');
      expect(controller.analysis, isNotNull);

      historyGate.complete(Right(historyPage(items: [analysisEntity()])));
      await Future<void>.delayed(Duration.zero);
      controller.activateTab(AssistantTab.history);
      await Future<void>.delayed(Duration.zero);

      expect(repository.historyCalls, hasLength(2));
    },
  );

  test('conversa durante carga mantém histórico desatualizado', () async {
    final historyGate = Completer<Either<Failure, AiHistoryPageEntity>>();
    repository.historyGates.add(historyGate);
    controller.activateTab(AssistantTab.history);
    await Future<void>.delayed(Duration.zero);

    await controller.sendChatMessage('Mensagem para a assistente');
    historyGate.complete(Right(historyPage()));
    await Future<void>.delayed(Duration.zero);
    controller.activateTab(AssistantTab.chat);
    controller.activateTab(AssistantTab.history);
    await Future<void>.delayed(Duration.zero);

    expect(repository.historyCalls, hasLength(2));
  });

  test('trocar modo limpa resultado e impede nova tentativa cruzada', () async {
    repository.analysisResults
      ..clear()
      ..add(const Left(AssistantProviderFailure()));
    await controller.analyzeText('Texto suspeito para análise');
    expect(controller.analysisFailure, isA<AssistantProviderFailure>());
    await controller.setAnalysisMode(AssistantAnalysisMode.image);
    await controller.retryAnalysis();

    expect(controller.analysisFailure, isNull);
    expect(repository.textCalls, hasLength(1));
    expect(repository.imageCalls, isEmpty);
  });

  test(
    'negação de permissão aparece e envio concluído remove imagem temporária',
    () async {
      images.nextResult = const PickImagePermissionDenied();
      await controller.pickImage(PhotoSource.gallery);
      expect(controller.imagePermissionDenied, isTrue);
      images.nextResult = const PickedImage('/tmp/assistant.png');
      await controller.pickImage(PhotoSource.gallery);
      expect(controller.selectedImagePath, '/tmp/assistant.png');
      repository.analysisResults
        ..clear()
        ..add(Right(analysisEntity()));
      await controller.analyzeSelectedImage(source: 'WHATSAPP');
      expect(repository.imageCalls.single.source, 'WHATSAPP');
      expect(images.deletedPaths, ['/tmp/assistant.png']);
      expect(controller.selectedImagePath, isNull);
    },
  );

  test('cancelar seleção preserva a imagem escolhida anteriormente', () async {
    images.nextResult = const PickedImage('/tmp/current.png');
    await controller.pickImage(PhotoSource.gallery);
    images.nextResult = const PickImageCancelled();
    await controller.pickImage(PhotoSource.camera);
    expect(controller.selectedImagePath, '/tmp/current.png');
    expect(images.deletedPaths, isEmpty);
  });

  test('cancelar, remover e descartar limpam imagens temporárias', () async {
    images.nextResult = const PickedImage('/tmp/first.png');
    await controller.pickImage(PhotoSource.camera);
    await controller.removeSelectedImage();
    expect(images.deletedPaths, ['/tmp/first.png']);
    images.nextResult = const PickedImage('/tmp/second.png');
    await controller.pickImage(PhotoSource.gallery);
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(images.deletedPaths, ['/tmp/first.png', '/tmp/second.png']);
  });

  test(
    'falha de análise permite nova tentativa com a imagem selecionada',
    () async {
      images.nextResult = const PickedImage('/tmp/retry.png');
      await controller.pickImage(PhotoSource.gallery);
      repository.analysisResults
        ..clear()
        ..addAll([
          const Left(AssistantProviderFailure()),
          Right(analysisEntity()),
        ]);
      await controller.analyzeSelectedImage();
      expect(controller.analysisFailure, isA<AssistantProviderFailure>());
      expect(controller.selectedImagePath, '/tmp/retry.png');
      await controller.retryAnalysis();
      expect(controller.analysisFailure, isNull);
      expect(images.deletedPaths, ['/tmp/retry.png']);
    },
  );
}
