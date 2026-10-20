import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_history_feature.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_image_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/analyze_text_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:click_seguro_app/modules/assistant/domain/usecases/send_chat_message_usecase.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller_status.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

class AssistantChatMessage {
  const AssistantChatMessage({required this.role, required this.content});

  final AiChatRole role;
  final String content;
}

class AssistantController extends ChangeNotifier {
  AssistantController({
    required SendChatMessageUseCase sendChatMessage,
    required AnalyzeTextUseCase analyzeText,
    required AnalyzeImageUseCase analyzeImage,
    required GetAiHistoryUseCase getAiHistory,
    required ImageStorageService imageStorage,
  }) : _sendChatMessage = sendChatMessage,
       _analyzeText = analyzeText,
       _analyzeImage = analyzeImage,
       _getAiHistory = getAiHistory,
       _imageStorage = imageStorage;

  final SendChatMessageUseCase _sendChatMessage;
  final AnalyzeTextUseCase _analyzeText;
  final AnalyzeImageUseCase _analyzeImage;
  final GetAiHistoryUseCase _getAiHistory;
  final ImageStorageService _imageStorage;

  AssistantTab _activeTab = AssistantTab.chat;
  AssistantTab get activeTab => _activeTab;

  final List<AssistantChatMessage> _chatMessages = [];
  List<AssistantChatMessage> get chatMessages =>
      List.unmodifiable(_chatMessages);
  bool _isSendingChat = false;
  bool get isSendingChat => _isSendingChat;
  Failure? _chatFailure;
  Failure? get chatFailure => _chatFailure;
  String? _pendingChatMessage;
  List<AiChatTurn> _pendingChatHistory = const [];

  AiAnalysisEntity? _analysis;
  AiAnalysisEntity? get analysis => _analysis;
  Failure? _analysisFailure;
  Failure? get analysisFailure => _analysisFailure;
  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  String? _selectedImagePath;
  String? get selectedImagePath => _selectedImagePath;
  bool _isPickingImage = false;
  bool get isPickingImage => _isPickingImage;
  bool _imagePermissionDenied = false;
  bool get imagePermissionDenied => _imagePermissionDenied;
  bool _imagePickFailed = false;
  bool get imagePickFailed => _imagePickFailed;
  String? _inFlightImagePath;

  AssistantHistoryFilter _historyFilter = AssistantHistoryFilter.all;
  AssistantHistoryFilter get historyFilter => _historyFilter;
  final List<AiAnalysisEntity> _historyItems = [];
  List<AiAnalysisEntity> get historyItems => List.unmodifiable(_historyItems);
  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;
  Failure? _historyFailure;
  Failure? get historyFailure => _historyFailure;
  bool _historyHasNextPage = false;
  bool get historyHasNextPage => _historyHasNextPage;
  bool _historyLoaded = false;
  bool _historyStale = true;
  int _historyMutationRevision = 0;
  int _historyPage = 1;
  int _historyRequestId = 0;
  int _failedHistoryPage = 1;
  bool _failedHistoryReplace = true;

  bool _disposed = false;

  void activateTab(AssistantTab tab) {
    if (_disposed) return;
    _activeTab = tab;
    _notify();
    if (tab == AssistantTab.history && (!_historyLoaded || _historyStale)) {
      unawaited(refreshHistory());
    }
  }

  Future<void> sendChatMessage(String message) async {
    if (_disposed || _isSendingChat || _pendingChatMessage != null) return;
    final history = _chatMessages
        .take(_chatMessages.length)
        .toList()
        .reversed
        .take(20)
        .toList()
        .reversed
        .map((entry) => AiChatTurn(role: entry.role, content: entry.content))
        .toList();
    _pendingChatMessage = message;
    _pendingChatHistory = history;
    _chatMessages.add(
      AssistantChatMessage(role: AiChatRole.user, content: message),
    );
    _chatFailure = null;
    await _submitPendingChat();
  }

  Future<void> retryChatMessage() async {
    if (_disposed || _pendingChatMessage == null || _isSendingChat) return;
    _chatFailure = null;
    _notify();
    await _submitPendingChat();
  }

  Future<void> _submitPendingChat() async {
    final message = _pendingChatMessage;
    if (message == null) return;
    _isSendingChat = true;
    _notify();
    final result = await _sendChatMessage(
      message,
      history: _pendingChatHistory,
    );
    if (_disposed) return;
    _isSendingChat = false;
    result.fold(
      (failure) {
        _chatFailure = failure;
        if (failure is AssistantInvalidInputFailure) {
          if (_chatMessages.isNotEmpty &&
              _chatMessages.last.role == AiChatRole.user) {
            _chatMessages.removeLast();
          }
          _pendingChatMessage = null;
          _pendingChatHistory = const [];
        }
      },
      (reply) {
        _chatMessages.add(
          AssistantChatMessage(role: AiChatRole.model, content: reply),
        );
        _pendingChatMessage = null;
        _pendingChatHistory = const [];
        _chatFailure = null;
        _markHistoryStale();
      },
    );
    _notify();
  }

  void startNewConversation() {
    if (_disposed || _isSendingChat) return;
    _chatMessages.clear();
    _pendingChatMessage = null;
    _pendingChatHistory = const [];
    _chatFailure = null;
    _notify();
  }

  Future<void> analyzeText(String text, {String? source}) async {
    if (_disposed || _isAnalyzing || _isPickingImage) return;
    _isAnalyzing = true;
    _analysis = null;
    _analysisFailure = null;
    _notify();
    final result = await _analyzeText(text, source: source);
    if (_disposed) return;
    _isAnalyzing = false;
    _applyAnalysisResult(result);
  }

  Future<void> pickImage(PhotoSource source) async {
    if (_disposed || _isPickingImage || _isAnalyzing) return;
    _isPickingImage = true;
    _imagePermissionDenied = false;
    _imagePickFailed = false;
    _notify();
    final PickImageResult result = await _imageStorage.pickImage(source);
    if (_disposed) {
      if (result case PickedImage(:final path)) {
        unawaited(_imageStorage.delete(path));
      }
      return;
    }
    switch (result) {
      case PickedImage(:final path):
        final String? previousPath = _selectedImagePath;
        if (previousPath != null &&
            previousPath != path &&
            previousPath != _inFlightImagePath) {
          await _imageStorage.delete(previousPath);
        }
        if (_disposed) {
          if (path != _inFlightImagePath) await _imageStorage.delete(path);
          return;
        }
        _selectedImagePath = path;
        _analysis = null;
        _analysisFailure = null;
      case PickImageCancelled():
        break;
      case PickImagePermissionDenied():
        _imagePermissionDenied = true;
      case PickImageFailed():
        _imagePickFailed = true;
    }
    _isPickingImage = false;
    _notify();
  }

  Future<void> removeSelectedImage() async {
    if (_disposed || _isAnalyzing || _isPickingImage) return;
    await _removeSelectedImage();
    _notify();
  }

  Future<void> _removeSelectedImage() async {
    final path = _selectedImagePath;
    _selectedImagePath = null;
    _analysis = null;
    _analysisFailure = null;
    if (path != null && path != _inFlightImagePath) {
      await _imageStorage.delete(path);
    }
  }

  Future<void> analyzeSelectedImage({String? source}) async {
    final path = _selectedImagePath;
    if (_disposed || _isAnalyzing || _isPickingImage || path == null) return;
    _isAnalyzing = true;
    _inFlightImagePath = path;
    _analysis = null;
    _analysisFailure = null;
    _notify();
    final result = await _analyzeImage(path, source: source);
    final succeeded = result.isRight();
    if (!_disposed) {
      _isAnalyzing = false;
      _applyAnalysisResult(result);
    }
    _inFlightImagePath = null;
    if (succeeded || _disposed) {
      if (_selectedImagePath == path) _selectedImagePath = null;
      await _imageStorage.delete(path);
      if (!_disposed) _notify();
    }
  }

  void _applyAnalysisResult(Either<Failure, AiAnalysisEntity> result) {
    result.fold((Failure failure) => _analysisFailure = failure, (
      AiAnalysisEntity analysis,
    ) {
      _analysis = analysis;
      _markHistoryStale();
    });
    _notify();
  }

  void setHistoryFilter(AssistantHistoryFilter filter) {
    if (_disposed || filter == _historyFilter) return;
    _historyFilter = filter;
    _historyItems.clear();
    _historyLoaded = false;
    _historyStale = true;
    _historyHasNextPage = false;
    _historyFailure = null;
    _historyPage = 1;
    _historyRequestId++;
    _isHistoryLoading = false;
    _notify();
    if (_activeTab == AssistantTab.history) unawaited(refreshHistory());
  }

  Future<void> refreshHistory() => _loadHistory(page: 1, replace: true);

  Future<void> loadNextHistoryPage() async {
    if (_disposed || _isHistoryLoading || !_historyHasNextPage) return;
    await _loadHistory(page: _historyPage + 1, replace: false);
  }

  Future<void> retryHistory() async {
    if (_disposed || _isHistoryLoading) return;
    await _loadHistory(
      page: _failedHistoryPage,
      replace: _failedHistoryReplace,
    );
  }

  Future<void> _loadHistory({required int page, required bool replace}) async {
    if (_disposed || _isHistoryLoading) return;
    final int requestId = ++_historyRequestId;
    final int mutationRevision = _historyMutationRevision;
    _isHistoryLoading = true;
    _historyFailure = null;
    _notify();
    final result = await _getAiHistory(
      page: page,
      limit: 20,
      feature: switch (_historyFilter) {
        AssistantHistoryFilter.all => null,
        AssistantHistoryFilter.analyses => AiHistoryFeature.analyze,
        AssistantHistoryFilter.conversations => AiHistoryFeature.chat,
      },
    );
    if (_disposed || requestId != _historyRequestId) return;
    _isHistoryLoading = false;
    result.fold(
      (failure) {
        _historyFailure = failure;
        _failedHistoryPage = page;
        _failedHistoryReplace = replace;
      },
      (loaded) {
        if (replace) _historyItems.clear();
        final existingIds = _historyItems.map((item) => item.id).toSet();
        for (final item in loaded.items) {
          if (existingIds.add(item.id)) _historyItems.add(item);
        }
        _historyPage = loaded.page;
        _historyHasNextPage = loaded.hasNextPage;
        _historyLoaded = true;
        _historyStale = mutationRevision != _historyMutationRevision;
        _failedHistoryPage = 1;
        _failedHistoryReplace = true;
      },
    );
    _notify();
  }

  void _markHistoryStale() {
    _historyMutationRevision++;
    _historyStale = true;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _historyRequestId++;
    final path = _selectedImagePath;
    _selectedImagePath = null;
    if (path != null && path != _inFlightImagePath) {
      unawaited(_imageStorage.delete(path));
    }
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
