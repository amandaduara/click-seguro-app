import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_image_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_text_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/send_chat_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _Repository implements AssistantRepository {
  int calls = 0;
  String? message;
  String? text;
  int? page;
  String? source;
  List<AiChatTurn>? history;

  @override
  Future<Either<Failure, AiAnalysisEntity>> analyzeImage(
    String path, {
    String? source,
  }) async {
    calls++;
    return Right(_analysis);
  }

  @override
  Future<Either<Failure, AiAnalysisEntity>> analyzeText(
    String text, {
    String? source,
  }) async {
    calls++;
    this.text = text;
    this.source = source;
    return Right(_analysis);
  }

  @override
  Future<Either<Failure, AiHistoryPageEntity>> getAiHistory({
    required int page,
    required int limit,
    AiHistoryFeature? feature,
  }) async {
    calls++;
    this.page = page;
    return const Right(_history);
  }

  @override
  Future<Either<Failure, String>> sendChatMessage(
    String message, {
    List<AiChatTurn> history = const [],
  }) async {
    calls++;
    this.message = message;
    this.history = history;
    return const Right('ok');
  }
}

final _analysis = AiAnalysisEntity(
  id: 'a1',
  feature: AiAnalysisFeature.analyze,
  threatType: AiThreatType.safe,
  riskScore: null,
  confidence: null,
  explanation: null,
  tips: [],
  source: null,
  status: AiAnalysisStatus.success,
  createdAt: DateTime.utc(2026),
);
const _history = AiHistoryPageEntity(items: [], page: 1, hasNextPage: false);

void main() {
  test(
    'rejects chat message and oversized history before repository',
    () async {
      final repository = _Repository();
      final useCase = SendChatMessageUseCase(repository);
      expect(
        (await useCase('nope')).getLeft().toNullable(),
        isA<AssistantInvalidInputFailure>(),
      );
      expect(
        (await useCase(
          'mensagem válida',
          history: List.filled(
            21,
            const AiChatTurn(role: AiChatRole.user, content: 'contexto'),
          ),
        )).isLeft(),
        isTrue,
      );
      expect(repository.calls, 0);
      expect((await useCase('  mensagem válida  ')).isRight(), isTrue);
      expect(repository.message, 'mensagem válida');
      final longAssistantReply = List.filled(2001, 'a').join();
      await useCase(
        'mensagem válida',
        history: [
          AiChatTurn(role: AiChatRole.model, content: longAssistantReply),
        ],
      );
      expect(repository.history!.single.content, hasLength(2000));
      final emojiReply = '${List.filled(1999, 'a').join()}😀tail';
      await useCase(
        'mensagem válida',
        history: [AiChatTurn(role: AiChatRole.model, content: emojiReply)],
      );
      expect(repository.history!.single.content, hasLength(1999));
      expect(repository.history!.single.content, List.filled(1999, 'a').join());
    },
  );

  test('validates text and optional source before forwarding', () async {
    final repository = _Repository();
    final useCase = AnalyzeTextUseCase(repository);
    expect((await useCase('curto')).isLeft(), isTrue);
    expect(
      (await useCase('texto longo o bastante', source: '')).isLeft(),
      isTrue,
    );
    expect(repository.calls, 0);
    expect(
      (await useCase('texto longo o bastante', source: ' WHATSAPP ')).isRight(),
      isTrue,
    );
    expect(repository.text, 'texto longo o bastante');
    expect(repository.source, 'WHATSAPP');
  });

  test(
    'validates image source and history pagination before forwarding',
    () async {
      final repository = _Repository();
      final analyzeImage = AnalyzeImageUseCase(repository);
      expect(
        (await analyzeImage(
          '/tmp/image.png',
          source: List.filled(51, 'x').join(),
        )).isLeft(),
        isTrue,
      );
      expect(
        (await analyzeImage('/tmp/image.png', source: 'SMS')).isRight(),
        isTrue,
      );
      final history = GetAiHistoryUseCase(repository);
      expect((await history(page: 0)).isLeft(), isTrue);
      expect((await history(page: 1, limit: 101)).isLeft(), isTrue);
      expect(repository.calls, 1);
      expect(
        (await history(
          page: 1,
          limit: 100,
          feature: AiHistoryFeature.chat,
        )).isRight(),
        isTrue,
      );
      expect(repository.page, 1);
    },
  );
}
