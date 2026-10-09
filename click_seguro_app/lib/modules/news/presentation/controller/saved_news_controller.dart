import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_saved_news_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:flutter/foundation.dart';

/// Estado da tela de notícias salvas, um por abertura (data-model de
/// specs/010-detalhe-noticia). Lista vazia = [FeedStatus.loaded] com
/// [items] vazio.
class SavedNewsController extends ChangeNotifier {
  SavedNewsController({required GetSavedNewsUseCase getSavedNews})
    : _getSavedNews = getSavedNews;

  final GetSavedNewsUseCase _getSavedNews;

  FeedStatus _status = FeedStatus.loading;
  FeedStatus get status => _status;

  Failure? _failure;
  Failure? get failure => _failure;

  List<NewsItemEntity> _items = const [];

  /// Salvas da mais recente para a mais antiga, sem repetir.
  List<NewsItemEntity> get items => _items;

  int _page = 1;
  int get page => _page;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  Failure? _loadMoreFailure;
  Failure? get loadMoreFailure => _loadMoreFailure;

  bool _isFromCache = false;

  /// Lista vinda da cópia do aparelho (sem internet): a tela avisa.
  bool get isFromCache => _isFromCache;

  /// A lista chegou ao fim de verdade (não é a cópia do aparelho).
  bool get isEnd =>
      _status == FeedStatus.loaded &&
      !_hasMore &&
      !_isFromCache &&
      _items.isNotEmpty;

  /// Numera as cargas da página 1: respostas antigas são ignoradas.
  int _requestId = 0;

  bool _disposed = false;

  /// Carga inicial (ou "Tentar novamente"), com o carregando na tela.
  Future<void> load() => _loadFirst(silent: false);

  /// Volta à página 1 e substitui a lista (ao voltar do detalhe). Com a
  /// lista na tela, não mostra o carregando e, se falhar, a mantém.
  Future<void> refresh() => _loadFirst(silent: _status == FeedStatus.loaded);

  /// Próxima página. Não faz nada sem mais páginas ou durante outra carga.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _status != FeedStatus.loaded) return;
    final int requestId = _requestId;
    _isLoadingMore = true;
    _loadMoreFailure = null;
    _notify();

    final result = await _getSavedNews(_page + 1);
    if (requestId != _requestId || _disposed) return;

    result.fold((failure) => _loadMoreFailure = failure, (loaded) {
      final (merged, added) = _items.appendUnique(loaded.page.items);
      _items = merged;
      _page = loaded.page.page;
      // Página sem nada novo também encerra: o servidor pode repetir (CB-007).
      _hasMore = loaded.page.hasMore && added > 0;
    });
    _isLoadingMore = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadFirst({required bool silent}) async {
    final int requestId = ++_requestId;
    _isLoadingMore = false;
    _loadMoreFailure = null;
    if (!silent) {
      _status = FeedStatus.loading;
      _failure = null;
      _notify();
    }

    final result = await _getSavedNews(1);
    if (requestId != _requestId || _disposed) return;

    result.fold(
      (failure) {
        if (silent) return;
        _failure = failure;
        _status = FeedStatus.error;
      },
      (loaded) {
        _items = const <NewsItemEntity>[].appendUnique(loaded.page.items).$1;
        _page = loaded.page.page;
        _isFromCache = loaded.isFromCache;
        // A cópia do aparelho não pagina.
        _hasMore = loaded.page.hasMore && !loaded.isFromCache;
        _status = FeedStatus.loaded;
      },
    );
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
