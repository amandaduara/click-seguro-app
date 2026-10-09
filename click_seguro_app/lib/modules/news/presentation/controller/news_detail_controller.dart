import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_detail_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/mark_news_as_read_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_save_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_status.dart';
import 'package:flutter/foundation.dart';

enum NewsDetailMessageType { saved, removed, saveFailed, notFound }

/// Aviso curto para a tela mostrar (salvo, removido, falha ao salvar).
class NewsDetailMessage {
  const NewsDetailMessage(this.type, [this.failureKey]);

  final NewsDetailMessageType type;

  /// Chave de tradução da falha, só em [NewsDetailMessageType.saveFailed].
  final String? failureKey;
}

/// Estado da tela de detalhe, um por abertura (data-model de
/// specs/010-detalhe-noticia).
class NewsDetailController extends ChangeNotifier {
  NewsDetailController({
    required GetNewsDetailUseCase getNewsDetail,
    required MarkNewsAsReadUseCase markAsRead,
    required ToggleSaveUseCase toggleSave,
    required ValueListenable<UserSessionStatus> sessionStatus,
    required this.newsId,
  }) : _getNewsDetail = getNewsDetail,
       _markAsRead = markAsRead,
       _toggleSave = toggleSave,
       _sessionStatus = sessionStatus,
       _lastSession = sessionStatus.value {
    _sessionStatus.addListener(_onSessionChanged);
  }

  final GetNewsDetailUseCase _getNewsDetail;
  final MarkNewsAsReadUseCase _markAsRead;
  final ToggleSaveUseCase _toggleSave;
  final ValueListenable<UserSessionStatus> _sessionStatus;

  final String newsId;

  final StreamController<NewsDetailMessage> _messages =
      StreamController<NewsDetailMessage>.broadcast();

  /// Avisos curtos; a página mostra em `SnackBar`.
  Stream<NewsDetailMessage> get messages => _messages.stream;

  NewsDetailStatus _status = NewsDetailStatus.loading;
  NewsDetailStatus get status => _status;

  NewsDetailEntity? _detail;
  NewsDetailEntity? get detail => _detail;

  bool _isFromCache = false;

  /// O detalhe veio da cópia do aparelho: a tela avisa que está offline.
  bool get isFromCache => _isFromCache;

  Failure? _failure;
  Failure? get failure => _failure;

  bool _isSaving = false;

  /// Há um pedido de salvar em andamento: novos toques são ignorados.
  bool get isSaving => _isSaving;

  bool _autoReadDone = false;

  /// A leitura automática já aconteceu (ou foi parada) nesta abertura
  /// (FR-008): recargas não a reabrem.
  bool get autoReadDone => _autoReadDone;

  /// A leitura já foi registrada nesta abertura (R4).
  bool _readSent = false;

  UserSessionStatus _lastSession;

  /// Numera as cargas: respostas antigas são ignoradas.
  int _requestId = 0;

  bool _disposed = false;

  /// Carrega o detalhe. Com conta e detalhe do servidor, registra a leitura
  /// sem esperar (SC-002).
  Future<void> load() async {
    final int requestId = ++_requestId;
    _status = NewsDetailStatus.loading;
    _failure = null;
    _notify();

    final result = await _getNewsDetail(newsId);
    if (requestId != _requestId || _disposed) return;

    result.fold(
      (failure) {
        _failure = failure;
        _status = failure is NewsNotFoundFailure
            ? NewsDetailStatus.notFound
            : NewsDetailStatus.error;
      },
      (loaded) {
        _detail = loaded.detail;
        _isFromCache = loaded.isFromCache;
        _status = NewsDetailStatus.loaded;
        _registerRead(loaded);
      },
    );
    _notify();
  }

  /// "Tentar novamente" do erro.
  Future<void> retry() => load();

  /// Salva ou remove dos salvos na hora e depois mostra o que o servidor
  /// devolveu, com o aviso; em falha, volta e avisa; 404 vira "não
  /// encontrada" (R6). Só a página com conta chama (`requireAccount`).
  Future<void> toggleSave() async {
    final NewsDetailEntity? before = _detail;
    if (before == null ||
        _status != NewsDetailStatus.loaded ||
        _isSaving ||
        _disposed) {
      return;
    }
    _isSaving = true;
    _detail = before.copyWith(isSaved: !before.isSaved);
    _notify();

    final result = await _toggleSave(newsId);
    _isSaving = false;
    if (_disposed) return;
    result.fold(
      (failure) {
        _detail = _detail?.copyWith(isSaved: before.isSaved);
        if (failure is NewsNotFoundFailure) {
          _status = NewsDetailStatus.notFound;
          _emit(const NewsDetailMessage(NewsDetailMessageType.notFound));
        } else {
          _emit(
            NewsDetailMessage(
              NewsDetailMessageType.saveFailed,
              failure.message,
            ),
          );
        }
      },
      (saved) {
        _detail = _detail?.copyWith(isSaved: saved);
        _emit(
          NewsDetailMessage(
            saved ? NewsDetailMessageType.saved : NewsDetailMessageType.removed,
          ),
        );
      },
    );
    _notify();
  }

  /// A página iniciou ou parou a leitura automática: não volta a abrir.
  void markAutoReadDone() => _autoReadDone = true;

  @override
  void dispose() {
    _disposed = true;
    _sessionStatus.removeListener(_onSessionChanged);
    unawaited(_messages.close());
    super.dispose();
  }

  /// Só com conta, só do servidor (a cópia é notícia já lida em outra
  /// abertura) e uma vez por abertura; o resultado é ignorado.
  void _registerRead(NewsDetailResult loaded) {
    if (_readSent ||
        loaded.isFromCache ||
        _sessionStatus.value != UserSessionStatus.authenticated) {
      return;
    }
    _readSent = true;
    unawaited(_markAsRead(newsId));
  }

  /// Visitante que entra pelo convite: recarrega para trazer o estado de
  /// salvo da conta (edge case do convite).
  void _onSessionChanged() {
    final UserSessionStatus now = _sessionStatus.value;
    final bool becameAuthenticated =
        now == UserSessionStatus.authenticated &&
        _lastSession != UserSessionStatus.authenticated;
    _lastSession = now;
    if (becameAuthenticated) unawaited(load());
  }

  void _emit(NewsDetailMessage message) {
    if (!_messages.isClosed) _messages.add(message);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
