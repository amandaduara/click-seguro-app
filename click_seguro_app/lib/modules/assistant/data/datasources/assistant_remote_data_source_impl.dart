import 'dart:io';

import 'package:click_seguro_app/modules/assistant/data/models/ai_analysis_model.dart';
import 'package:click_seguro_app/modules/assistant/data/models/ai_history_model.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

import 'assistant_remote_data_source.dart';

class AssistantRemoteDataSourceImpl implements AssistantRemoteDataSource {
  AssistantRemoteDataSourceImpl(this._apiClient);

  static const chatPath = '/app/ai/chat';
  static const analyzePath = '/app/ai/analyze';
  static const analyzeImagePath = '/app/ai/analyze/image';
  static const historyPath = '/app/ai/history';
  static const imageField = 'image';

  final ApiClient _apiClient;

  @override
  Future<String> sendChatMessage(
    String message,
    List<AiChatTurn> history,
  ) async {
    final response = await _apiClient.post(
      chatPath,
      data: {
        'message': message,
        if (history.isNotEmpty)
          'history': [for (final turn in history) turn.toJson()],
      },
    );
    return response.toModel((json) => json['response'] as String);
  }

  @override
  Future<AiAnalysisModel> analyzeText(String text, String? source) async {
    final response = await _apiClient.post(
      analyzePath,
      data: {'text': text, 'source': ?source},
    );
    return response.toModel(AiAnalysisModel.fromJson);
  }

  @override
  Future<AiAnalysisModel> analyzeImage(String path, String? source) async {
    final (mimeType, length) = await _imageInfo(path);
    if (length > AssistantLimits.imageBytesMax) {
      throw _invalidImage('Arquivo excede 5 MB');
    }
    final uri = Uri(
      path: analyzeImagePath,
      queryParameters: {'source': ?source},
    );
    final response = await _apiClient.postMultipart(
      uri.toString(),
      fieldName: imageField,
      filePath: path,
      contentType: mimeType,
    );
    return response.toModel(AiAnalysisModel.fromJson);
  }

  @override
  Future<AiHistoryModel> getHistory(
    int page,
    int limit,
    AiHistoryFeature? feature,
  ) async {
    final response = await _apiClient.get(
      historyPath,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (feature != null) 'feature': feature.name.toUpperCase(),
      },
    );
    return response.toModel(AiHistoryModel.fromJson);
  }

  Future<(String, int)> _imageInfo(String path) async {
    try {
      final file = File(path);
      final length = await file.length();
      final bytes = await file
          .openRead(0, 12)
          .fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      final mimeType = _mimeType(bytes);
      if (mimeType == null || length == 0) {
        throw _invalidImage('Formato de imagem inválido');
      }
      return (mimeType, length);
    } on ApiException {
      rethrow;
    } on FileSystemException catch (error) {
      throw _invalidImage(error.message);
    }
  }

  String? _mimeType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length >= png.length &&
        Iterable<int>.generate(png.length).every((i) => bytes[i] == png[i])) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  ApiException _invalidImage(String message) => ApiException(
    type: ApiErrorType.client,
    statusCode: 400,
    errorCode: AssistantImageErrorCodes.invalidFormat,
    message: message,
  );
}
