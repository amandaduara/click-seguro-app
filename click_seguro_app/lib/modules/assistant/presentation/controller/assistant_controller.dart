import 'dart:async';
import 'dart:math' show max;

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
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

  final List<AiChatTurn> _chatMessages = [];
  List<AiChatTurn> get chatMessages => List.unmodifiable(_chatMessages);
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

  AssistantAnalysisMode _analysisMode = AssistantAnalysisMode.text;
  AssistantAnalysisMode get analysisMode => _analysisMode;
  String? _analysisSource;
  String? get analysisSource => _analysisSource;
  AssistantAnalysisMode? _lastAnalysisMode;
  String? _lastAnalysisText;
  String? _lastAnalysisSource;
  int _analysisRequestId = 0;

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
        .skip(max(0, _chatMessages.length - AssistantLimits.contextTurnMax))
        .toList();
    _pendingChatMessage = message;
    _pendingChatHistory = history;
    _chatMessages.add(AiChatTurn(role: AiChatRole.user, content: message));
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
        _chatMessages.add(AiChatTurn(role: AiChatRole.model, content: reply));
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

  Future<void> setAnalysisMode(AssistantAnalysisMode mode) async {
    if (_disposed || mode == _analysisMode || _isAnalyzing || _isPickingImage) {
      return;
    }
    _analysisMode = mode;
    _analysis = null;
    _analysisFailure = null;
    _analysisRequestId++;
    _lastAnalysisMode = null;
    _lastAnalysisText = null;
    _lastAnalysisSource = null;
    if (mode == AssistantAnalysisMode.text) await _removeSelectedImage();
    _notify();
  }

  void setAnalysisSource(String? source) {
    if (_disposed || source == _analysisSource) return;
    _analysisSource = source;
    _notify();
  }

  Future<void> analyzeText(String text, {String? source}) async {
    if (_disposed || _isAnalyzing || _isPickingImage) return;
    _analysisMode = AssistantAnalysisMode.text;
    _lastAnalysisMode = AssistantAnalysisMode.text;
    _lastAnalysisText = text;
    _lastAnalysisSource = source ?? _analysisSource;
    final int requestId = ++_analysisRequestId;
    _isAnalyzing = true;
    _analysis = null;
    _analysisFailure = null;
    _notify();
    final result = await _analyzeText(text, source: _lastAnalysisSource);
    if (_disposed || requestId != _analysisRequestId) return;
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
    _analysisMode = AssistantAnalysisMode.image;
    _lastAnalysisMode = AssistantAnalysisMode.image;
    _lastAnalysisText = null;
    _lastAnalysisSource = source ?? _analysisSource;
    final int requestId = ++_analysisRequestId;
    _isAnalyzing = true;
    _inFlightImagePath = path;
    _analysis = null;
    _analysisFailure = null;
    _notify();
    final result = await _analyzeImage(path, source: _lastAnalysisSource);
    final succeeded = result.isRight();
    final bool staleRequest = requestId != _analysisRequestId;
    if (!_disposed && !staleRequest) {
      _isAnalyzing = false;
      _applyAnalysisResult(result);
    }
    _inFlightImagePath = null;
    if (succeeded || _disposed || staleRequest) {
      if (_selectedImagePath == path) _selectedImagePath = null;
      await _imageStorage.delete(path);
      if (!_disposed) _notify();
    }
  }

  Future<void> retryAnalysis() async {
    if (_disposed || _isAnalyzing) return;
    switch (_lastAnalysisMode) {
      case AssistantAnalysisMode.text:
        final text = _lastAnalysisText;
        if (text != null && _analysisMode == AssistantAnalysisMode.text) {
          await analyzeText(text, source: _lastAnalysisSource);
        }
        return;
      case AssistantAnalysisMode.image:
        if (_analysisMode == AssistantAnalysisMode.image &&
            _selectedImagePath != null) {
          await analyzeSelectedImage(source: _lastAnalysisSource);
        }
        return;
      case null:
        break;
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
      limit: AssistantLimits.historyPageSize,
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
