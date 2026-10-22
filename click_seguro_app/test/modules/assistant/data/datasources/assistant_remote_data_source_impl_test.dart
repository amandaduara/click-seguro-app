import 'dart:io';

import 'package:click_seguro_app/modules/assistant/data/datasources/assistant_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../common/api_client/fake_http_client_adapter.dart';
import '../../fakes/ai_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late AssistantRemoteDataSourceImpl dataSource;
  late Directory tempDir;

  setUp(() async {
    adapter = FakeHttpClientAdapter();
    final session = UserSessionService(FakeSecureStorageService())
      ..accessToken = 'access-token';
    GetIt.instance.registerSingleton<UserSessionService>(session);
    dataSource = AssistantRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
    tempDir = await Directory.systemTemp.createTemp('assistant_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
    await GetIt.instance.reset();
  });

  test('chat envia mensagem e turnos limitados na rota autenticada', () async {
    adapter.body = {'response': 'Resposta do assistente'};
    final response = await dataSource.sendChatMessage('Isso é golpe?', [
      const AiChatTurn(role: AiChatRole.user, content: 'Recebi uma mensagem'),
      const AiChatTurn(role: AiChatRole.model, content: 'Pode enviar o texto?'),
    ]);
    final request = adapter.lastRequest!;
    expect(response, 'Resposta do assistente');
    expect(request.path, AssistantRemoteDataSourceImpl.chatPath);
    expect(request.headers['Authorization'], 'Bearer access-token');
    expect(request.data, {
      'message': 'Isso é golpe?',
      'history': [
        {'role': 'user', 'content': 'Recebi uma mensagem'},
        {'role': 'model', 'content': 'Pode enviar o texto?'},
      ],
    });
  });

  test('análise de texto preserva nulos, enums e metadados usados', () async {
    adapter.body = aiAnalysisJson(
      type: null,
      riskScore: null,
      confidence: null,
      status: 'RATE_LIMITED',
    );
    final model = await dataSource.analyzeText(
      'Mensagem suspeita longa',
      'EMAIL',
    );
    expect(
      adapter.lastRequest!.path,
      AssistantRemoteDataSourceImpl.analyzePath,
    );
    expect(adapter.lastRequest!.data, {
      'text': 'Mensagem suspeita longa',
      'source': 'EMAIL',
    });
    expect(model.entity.threatType, isNull);
    expect(model.entity.riskScore, isNull);
    expect(model.entity.confidence, isNull);
    expect(model.entity.status.name, 'rateLimited');
    expect(model.entity.tips, ['Não clique no link']);
  });

  test(
    'enum desconhecido vira unknown e resultado não é convertido em SAFE',
    () async {
      adapter.body = aiAnalysisJson(type: 'FUTURE_THREAT');
      final model = await dataSource.analyzeText(
        'Mensagem suspeita longa',
        null,
      );
      expect(model.entity.threatType?.name, 'unknown');
    },
  );

  test(
    'imagem segue o conteúdo magic bytes e repassa source na query',
    () async {
      adapter.body = aiAnalysisJson(inputType: 'IMAGE');
      final path = '${tempDir.path}/imagem.sem_extensao';
      await File(
        path,
      ).writeAsBytes([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2]);
      await dataSource.analyzeImage(path, 'WHATSAPP');
      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(Uri.parse(request.path).queryParameters, {'source': 'WHATSAPP'});
      final form = request.data as FormData;
      expect(form.files.single.key, 'image');
      expect(form.files.single.value.contentType.toString(), 'image/png');
    },
  );

  test(
    'arquivo inválido e imagem maior que 5 MB não chegam ao adapter',
    () async {
      final invalid = File('${tempDir.path}/arquivo.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      await expectLater(
        dataSource.analyzeImage(invalid.path, null),
        throwsA(isA<ApiException>()),
      );
      final huge = File('${tempDir.path}/grande.jpg')
        ..writeAsBytesSync([
          0xff,
          0xd8,
          0xff,
          ...List<int>.filled(5 * 1024 * 1024, 0),
        ]);
      await expectLater(
        dataSource.analyzeImage(huge.path, null),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
    },
  );

  test(
    'histórico envia paginação/filtro e respeita hasNextPage da API',
    () async {
      adapter.body = aiHistoryJson(hasNextPage: false);
      final result = await dataSource.getHistory(2, 10, AiHistoryFeature.chat);
      expect(
        adapter.lastRequest!.path,
        AssistantRemoteDataSourceImpl.historyPath,
      );
      expect(adapter.lastRequest!.queryParameters, {
        'page': 2,
        'limit': 10,
        'feature': 'CHAT',
      });
      expect(result.entity.page, 2);
      expect(result.entity.hasNextPage, isFalse);
      expect(result.entity.items.single.riskScore, 92);
    },
  );
}
