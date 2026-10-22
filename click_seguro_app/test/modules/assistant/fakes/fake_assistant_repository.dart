import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_page_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:fpdart/fpdart.dart';

class FakeAssistantRepository implements AssistantRepository {
  final chatResults = <Either<Failure, String>>[const Right('Resposta segura')];
  final analysisResults = <Either<Failure, AiAnalysisEntity>>[_analysis];
  final historyResults = <Either<Failure, AiHistoryPageEntity>>[_history];
  final historyGates = <Completer<Either<Failure, AiHistoryPageEntity>>>[];
  Completer<void>? chatGate;

  final chatCalls = <({String message, List<AiChatTurn> history})>[];
  final textCalls = <({String text, String? source})>[];
  final imageCalls = <({String path, String? source})>[];
  final historyCalls = <({int page, int limit, AiHistoryFeature? feature})>[];

  int get totalCalls =>
      chatCalls.length +
      textCalls.length +
      imageCalls.length +
      historyCalls.length;

  T _next<T>(List<T> values) =>
      values.length > 1 ? values.removeAt(0) : values.first;

  @override
  Future<Either<Failure, String>> sendChatMessage(
    String message, {
    List<AiChatTurn> history = const [],
  }) async {
    chatCalls.add((message: message, history: List.of(history)));
    await chatGate?.future;
    return _next(chatResults);
  }

  @override
  Future<Either<Failure, AiAnalysisEntity>> analyzeText(
    String text, {
    String? source,
  }) async {
    textCalls.add((text: text, source: source));
    return _next(analysisResults);
  }

  @override
  Future<Either<Failure, AiAnalysisEntity>> analyzeImage(
    String path, {
    String? source,
  }) async {
    imageCalls.add((path: path, source: source));
    return _next(analysisResults);
  }

  @override
  Future<Either<Failure, AiHistoryPageEntity>> getAiHistory({
    required int page,
    required int limit,
    AiHistoryFeature? feature,
  }) async {
    historyCalls.add((page: page, limit: limit, feature: feature));
    if (historyGates.isNotEmpty) return historyGates.removeAt(0).future;
    return _next(historyResults);
  }
}

AiAnalysisEntity analysisEntity({
  AiThreatType? type = AiThreatType.phishing,
  double? riskScore = 90,
  double? confidence = 85,
  AiAnalysisStatus status = AiAnalysisStatus.success,
  String id = 'analysis-1',
}) => AiAnalysisEntity(
  id: id,
  feature: AiAnalysisFeature.analyze,
  threatType: type,
  riskScore: riskScore,
  confidence: confidence,
  explanation: 'O endereço não corresponde ao serviço informado.',
  tips: const ['Não abra o link', 'Confirme por um canal oficial'],
  source: 'WHATSAPP',
  status: status,
  createdAt: DateTime.utc(2026, 10, 20),
);

AiHistoryPageEntity historyPage({
  List<AiAnalysisEntity> items = const [],
  int page = 1,
  bool hasNextPage = false,
}) => AiHistoryPageEntity(items: items, page: page, hasNextPage: hasNextPage);

final _analysis = Right<Failure, AiAnalysisEntity>(analysisEntity());
final _history = Right<Failure, AiHistoryPageEntity>(historyPage());
