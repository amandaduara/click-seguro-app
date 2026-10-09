import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_detail_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/mark_news_as_read_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_status.dart';
import 'package:flutter/foundation.dart';

/// Estado da tela de detalhe, um por abertura (data-model de
/// specs/010-detalhe-noticia).
class NewsDetailController extends ChangeNotifier {
  NewsDetailController({
    required GetNewsDetailUseCase getNewsDetail,
    required MarkNewsAsReadUseCase markAsRead,
    required ValueListenable<UserSessionStatus> sessionStatus,
    required this.newsId,
  }) : _getNewsDetail = getNewsDetail,
       _markAsRead = markAsRead,
       _sessionStatus = sessionStatus,
       _lastSession = sessionStatus.value {
    _sessionStatus.addListener(_onSessionChanged);
  }

  final GetNewsDetailUseCase _getNewsDetail;
  final MarkNewsAsReadUseCase _markAsRead;
  final ValueListenable<UserSessionStatus> _sessionStatus;

  final String newsId;

  NewsDetailStatus _status = NewsDetailStatus.loading;
  NewsDetailStatus get status => _status;

  NewsDetailEntity? _detail;
  NewsDetailEntity? get detail => _detail;

  bool _isFromCache = false;

  /// O detalhe veio da cópia do aparelho: a tela avisa que está offline.
  bool get isFromCache => _isFromCache;

  Failure? _failure;
  Failure? get failure => _failure;

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

  /// A página iniciou ou parou a leitura automática: não volta a abrir.
  void markAutoReadDone() => _autoReadDone = true;

  @override
  void dispose() {
    _disposed = true;
    _sessionStatus.removeListener(_onSessionChanged);
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

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
