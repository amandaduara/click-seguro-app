import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_reels_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_like_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_save_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_status.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

enum ReelsMessageType { error, saved, removed }

/// Aviso curto para a tela mostrar (falha de curtir/salvar, salvo, removido).
class ReelsMessage {
  const ReelsMessage(this.type, [this.failureKey]);

  final ReelsMessageType type;

  /// Chave de tradução da falha, só em [ReelsMessageType.error].
  final String? failureKey;
}

/// Estado da tela de Reels (data-model de specs/008-reels-curtir-salvar).
class ReelsController extends ChangeNotifier {
  ReelsController({
    required GetReelsUseCase getReels,
    required ToggleLikeUseCase toggleLike,
    required ToggleSaveUseCase toggleSave,
    required ValueListenable<UserSessionStatus> sessionStatus,
  }) : _getReels = getReels,
       _toggleLike = toggleLike,
       _toggleSave = toggleSave,
       _sessionStatus = sessionStatus {
    _sessionStatus.addListener(_onSessionChanged);
  }

  final GetReelsUseCase _getReels;
  final ToggleLikeUseCase _toggleLike;
  final ToggleSaveUseCase _toggleSave;
  final ValueListenable<UserSessionStatus> _sessionStatus;

  /// Pede a próxima parte quando faltam este tanto de Reels à frente.
  static const int prefetchThreshold = 3;

  final StreamController<ReelsMessage> _messages =
      StreamController<ReelsMessage>.broadcast();

  /// Avisos curtos; a página mostra em `SnackBar`.
  Stream<ReelsMessage> get messages => _messages.stream;

  ReelsStatus _status = ReelsStatus.initial;
  ReelsStatus get status => _status;

  Failure? _failure;
  Failure? get failure => _failure;

  List<ReelEntity> _reels = const [];

  /// Reels carregados, sem repetir.
  List<ReelEntity> get reels => _reels;

  int _currentIndex = 0;

  /// Reel na tela.
  int get currentIndex => _currentIndex;

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  Failure? _loadMoreFailure;
  Failure? get loadMoreFailure => _loadMoreFailure;

  /// A lista acabou de verdade.
  bool get isEnd =>
      _status == ReelsStatus.loaded && !hasMore && _reels.isNotEmpty;

  bool get canGoPrevious => _currentIndex > 0;
  bool get canGoNext => _currentIndex < _reels.length - 1;

  /// A sessão mudou depois da carga: o próximo [open] recarrega (R5).
  bool _isStale = false;

  /// Notícia de início pedida durante a carga.
  String? _startId;

  /// Numera as cargas iniciais: respostas antigas são ignoradas.
  int _requestId = 0;

  /// Reels com pedido de curtir/salvar em andamento (FR-014).
  final Set<String> _likePending = {};
  final Set<String> _savePending = {};

  bool isLikePending(String id) => _likePending.contains(id);
  bool isSavePending(String id) => _savePending.contains(id);

  /// A aba apareceu (ou o carrossel pediu [startId]). Carrega na primeira
  /// vez; depois só posiciona, se [startId] estiver entre os carregados.
  Future<void> open([String? startId]) async {
    if (_status == ReelsStatus.initial || _isStale) {
      await _loadFirst(startId);
      return;
    }
    if (_status == ReelsStatus.loading) {
      _startId = startId ?? _startId;
      return;
    }
    if (startId == null) return;
    final int index = _indexOf(startId);
    if (index >= 0) setIndex(index);
  }

  /// "Tentar novamente" do erro.
  Future<void> retry() => _loadFirst(null);

  /// "Atualizar": de volta ao início.
  Future<void> refresh() => _loadFirst(null);

  /// O Reel na tela mudou (gesto ou setas).
  void setIndex(int index) {
    if (index == _currentIndex || index < 0 || index >= _reels.length) return;
    _currentIndex = index;
    notifyListeners();
    _prefetchIfNear();
  }

  /// Próxima parte. Não faz nada sem mais partes ou durante outra carga.
  Future<void> loadMore() async {
    final String? cursor = _nextCursor;
    if (cursor == null || _isLoadingMore || _status != ReelsStatus.loaded) {
      return;
    }
    final int requestId = _requestId;
    _isLoadingMore = true;
    _loadMoreFailure = null;
    notifyListeners();

    final result = await _getReels(cursor: cursor);
    if (requestId != _requestId) return;

    result.fold((failure) => _loadMoreFailure = failure, (page) {
      final (merged, added) = _reels.appendUniqueReels(page.items);
      _reels = merged;
      // Parte sem nada novo também encerra (CB-007).
      _nextCursor = added > 0 ? page.nextCursor : null;
    });
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Curte ou descurte na hora (±1) e depois mostra o que o servidor
  /// devolveu; em falha, volta ao estado anterior e avisa (R3).
  Future<void> toggleLike(String id) async {
    final ReelEntity? before = _find(id);
    if (before == null || !_likePending.add(id)) return;
    _replace(
      before.copyWith(
        isLiked: !before.isLiked,
        likesCount: before.isLiked
            ? (before.likesCount - 1).clamp(0, before.likesCount)
            : before.likesCount + 1,
      ),
    );
    notifyListeners();

    final result = await _toggleLike(id);
    _likePending.remove(id);
    result.fold(
      (failure) {
        _update(
          id,
          (reel) => reel.copyWith(
            isLiked: before.isLiked,
            likesCount: before.likesCount,
          ),
        );
        _emit(ReelsMessage(ReelsMessageType.error, failure.message));
      },
      (like) => _update(
        id,
        (reel) =>
            reel.copyWith(isLiked: like.liked, likesCount: like.likesCount),
      ),
    );
    notifyListeners();
  }

  /// Salva ou remove dos salvos na hora e depois mostra o que o servidor
  /// devolveu, com o aviso; em falha, volta e avisa.
  Future<void> toggleSave(String id) async {
    final ReelEntity? before = _find(id);
    if (before == null || !_savePending.add(id)) return;
    _replace(before.copyWith(isSaved: !before.isSaved));
    notifyListeners();

    final result = await _toggleSave(id);
    _savePending.remove(id);
    result.fold(
      (failure) {
        _update(id, (reel) => reel.copyWith(isSaved: before.isSaved));
        _emit(ReelsMessage(ReelsMessageType.error, failure.message));
      },
      (saved) {
        _update(id, (reel) => reel.copyWith(isSaved: saved));
        _emit(
          ReelsMessage(
            saved ? ReelsMessageType.saved : ReelsMessageType.removed,
          ),
        );
      },
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionStatus.removeListener(_onSessionChanged);
    unawaited(_messages.close());
    super.dispose();
  }

  Future<void> _loadFirst(String? startId) async {
    final int requestId = ++_requestId;
    _startId = startId;
    _isStale = false;
    _status = ReelsStatus.loading;
    _failure = null;
    _loadMoreFailure = null;
    _isLoadingMore = false;
    notifyListeners();

    Either<Failure, ReelsPageEntity> result = await _getReels();
    // Sessão recusada: o ApiClient já a encerrou; de novo, como visitante.
    if (requestId == _requestId &&
        result.getLeft().toNullable() is UnauthorizedFailure) {
      result = await _getReels();
    }
    if (requestId != _requestId) return;

    result.fold(
      (failure) {
        _failure = failure;
        _status = ReelsStatus.error;
      },
      (page) {
        _reels = const <ReelEntity>[].appendUniqueReels(page.items).$1;
        _nextCursor = page.nextCursor;
        final String? start = _startId;
        final int index = start == null ? -1 : _indexOf(start);
        _currentIndex = index < 0 ? 0 : index;
        _status = ReelsStatus.loaded;
      },
    );
    _startId = null;
    notifyListeners();
    if (_status == ReelsStatus.loaded) _prefetchIfNear();
  }

  /// Depois de uma falha, só o "Tentar novamente" pede de novo (FR-008).
  void _prefetchIfNear() {
    if (_loadMoreFailure == null &&
        _reels.length - 1 - _currentIndex <= prefetchThreshold) {
      unawaited(loadMore());
    }
  }

  void _onSessionChanged() {
    if (_status != ReelsStatus.initial) _isStale = true;
  }

  int _indexOf(String id) => _reels.indexWhere((reel) => reel.id == id);

  ReelEntity? _find(String id) {
    final int index = _indexOf(id);
    return index < 0 ? null : _reels[index];
  }

  void _replace(ReelEntity reel) => _update(reel.id, (_) => reel);

  /// Troca o Reel [id], se ainda estiver na lista (uma recarga pode tê-lo
  /// tirado).
  void _update(String id, ReelEntity Function(ReelEntity reel) change) {
    final int index = _indexOf(id);
    if (index < 0) return;
    _reels = [..._reels]..[index] = change(_reels[index]);
  }

  void _emit(ReelsMessage message) {
    if (!_messages.isClosed) _messages.add(message);
  }
}
