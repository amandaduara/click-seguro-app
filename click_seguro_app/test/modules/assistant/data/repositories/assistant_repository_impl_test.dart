import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_assistant_remote_data_source.dart';

void main() {
  late FakeAssistantRemoteDataSource remote;
  late AssistantRepositoryImpl repository;

  setUp(() {
    remote = FakeAssistantRemoteDataSource();
    repository = AssistantRepositoryImpl(remote);
  });

  ApiException apiError({
    ApiErrorType type = ApiErrorType.server,
    int? statusCode,
    String? code,
  }) => ApiException(
    type: type,
    statusCode: statusCode,
    errorCode: code,
    message: 'technical detail',
  );

  test('devolve resultado sem exceção no fluxo de sucesso', () async {
    final result = await repository.analyzeText('Texto sob análise');
    expect(result.isRight(), isTrue);
    expect(remote.calls, 1);
  });

  test(
    'mapeia códigos de provider, parse, arquivo inválido e rate limit',
    () async {
      remote.error = apiError(code: AssistantRepositoryImpl.providerFailedCode);
      expect(
        (await repository.analyzeText(
          'Texto sob análise',
        )).getLeft().toNullable(),
        isA<AssistantProviderFailure>(),
      );
      remote.error = apiError(code: AssistantRepositoryImpl.parseFailedCode);
      expect(
        (await repository.analyzeText(
          'Texto sob análise',
        )).getLeft().toNullable(),
        isA<AssistantParseFailure>(),
      );
      remote.error = apiError(code: AssistantRepositoryImpl.invalidImageCode);
      expect(
        (await repository.analyzeImage(
          '/tmp/image.png',
        )).getLeft().toNullable(),
        isA<AssistantInvalidImageFailure>(),
      );
      remote.error = apiError(type: ApiErrorType.client, statusCode: 429);
      expect(
        (await repository.sendChatMessage(
          'Mensagem válida',
        )).getLeft().toNullable(),
        isA<AssistantRateLimitedFailure>(),
      );
    },
  );

  test('mapeia erro de parse e usa mapper comum para rede', () async {
    remote.error = apiError(type: ApiErrorType.invalidResponse);
    expect(
      (await repository.getAiHistory(
        page: 1,
        limit: 20,
      )).getLeft().toNullable(),
      isA<AssistantParseFailure>(),
    );
    remote.error = apiError(type: ApiErrorType.connection);
    expect(
      (await repository.getAiHistory(
        page: 1,
        limit: 20,
      )).getLeft().toNullable(),
      isA<ConnectionFailure>(),
    );
  });
}
