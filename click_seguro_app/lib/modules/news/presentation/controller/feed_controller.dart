import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_categories_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_page_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

/// Estado do feed da aba Início (data-model de specs/006-feed-inicio).
class FeedController extends ChangeNotifier {
  FeedController({
    required GetFeedUseCase getFeed,
    required GetFeedPageUseCase getFeedPage,
    required GetNewsUseCase getNews,
    required GetCategoriesUseCase getCategories,
    DateTime Function()? now,
  }) : _getFeed = getFeed,
       _getFeedPage = getFeedPage,
       _getNews = getNews,
       _getCategories = getCategories,
       _now = now ?? DateTime.now;

  final GetFeedUseCase _getFeed;
  final GetFeedPageUseCase _getFeedPage;
  final GetNewsUseCase _getNews;
  final GetCategoriesUseCase _getCategories;
  final DateTime Function() _now;

  FeedStatus _status = FeedStatus.loading;
  FeedStatus get status => _status;

  Failure? _failure;
  Failure? get failure => _failure;

  NewsFilter _filter = const NewsFilter();
  NewsFilter get filter => _filter;

  List<NewsCategoryEntity> _categories = const [];
  List<NewsCategoryEntity> get categories => _categories;

  List<NewsItemEntity> _reels = const [];
  List<NewsItemEntity> get reels => _reels;

  List<NewsItemEntity> _highlights = const [];
  List<NewsItemEntity> get highlights => _highlights;

  List<NewsItemEntity> _recommended = const [];
  List<NewsItemEntity> get recommended => _recommended;

  List<NewsItemEntity> _items = const [];

  /// "Tudo recente" (ou a lista filtrada), sem notícias repetidas.
  List<NewsItemEntity> get items => _items;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  Failure? _loadMoreFailure;
  Failure? get loadMoreFailure => _loadMoreFailure;

  bool _isFromCache = false;

  /// Feed vindo da cópia guardada (sem internet).
  bool get isFromCache => _isFromCache;

  int _newCount = 0;

  /// Notícias das últimas 24 h no feed sem filtro (FR-011).
  int get newCount => _newCount;

  /// A lista chegou ao fim de verdade (não é a cópia guardada).
  bool get isEnd =>
      _status == FeedStatus.loaded &&
      !_hasMore &&
      !_isFromCache &&
      _items.isNotEmpty;

  int _page = 1;

  /// Numera as cargas iniciais: respostas de cargas anteriores são
  /// ignoradas (research R3).
  int _requestId = 0;

  /// Carga inicial (ou tentar de novo).
  Future<void> load() => _loadFirst();

  /// Puxar para atualizar: volta à página 1.
  Future<void> refresh() => _loadFirst();

  /// Próxima página da lista atual. Não faz nada sem mais páginas, durante
  /// outra carga ou com a cópia guardada.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _status != FeedStatus.loaded) return;
    final int requestId = _requestId;
    _isLoadingMore = true;
    _loadMoreFailure = null;
    notifyListeners();

    final bool isFeed = _filter.isEmpty;
    final result = isFeed
        ? await _getFeedPage(_page + 1)
        : await _getNews(_filter, _page + 1);
    if (requestId != _requestId) return;

    result.fold((failure) => _loadMoreFailure = failure, (page) {
      final (merged, added) = _items.appendUnique(page.items);
      _items = merged;
      _page = page.page;
      // Página sem nada novo também encerra: o servidor pode repetir (R1).
      _hasMore = page.hasMore && added > 0;
      if (isFeed) _updateNewCount();
    });
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _loadFirst() async {
    final int requestId = ++_requestId;
    _status = FeedStatus.loading;
    _failure = null;
    _loadMoreFailure = null;
    _isLoadingMore = false;
    notifyListeners();

    final bool isFeed = _filter.isEmpty;
    Either<Failure, Object> result = await _fetchFirst(isFeed);
    // Sessão recusada: o ApiClient já a encerrou; uma nova tentativa sai
    // sem token, como visitante (spec, casos de borda).
    if (requestId == _requestId &&
        result.getLeft().toNullable() is UnauthorizedFailure) {
      result = await _fetchFirst(isFeed);
    }
    if (requestId != _requestId) return;

    result.fold(
      (failure) {
        _failure = failure;
        _status = FeedStatus.error;
      },
      (data) {
        switch (data) {
          case NewsFeedEntity feed:
            _applyFeed(feed);
          case NewsPageEntity page:
            _applyList(page);
        }
        _status = FeedStatus.loaded;
      },
    );
    notifyListeners();
  }

  Future<Either<Failure, Object>> _fetchFirst(bool isFeed) async => isFeed
      ? (await _getFeed()).map<Object>((feed) => feed)
      : (await _getNews(_filter, 1)).map<Object>((page) => page);

  void _applyFeed(NewsFeedEntity feed) {
    _reels = feed.reels;
    _highlights = feed.highlights;
    _recommended = feed.recommended;
    _items = const <NewsItemEntity>[].appendUnique(feed.recent.items).$1;
    _page = feed.recent.page;
    _isFromCache = feed.isFromCache;
    // A cópia guardada não pagina (FR-021).
    _hasMore = feed.recent.hasMore && !feed.isFromCache;
    _updateNewCount();
  }

  void _applyList(NewsPageEntity page) {
    _reels = const [];
    _highlights = const [];
    _recommended = const [];
    _items = const <NewsItemEntity>[].appendUnique(page.items).$1;
    _page = page.page;
    _isFromCache = false;
    _hasMore = page.hasMore;
  }

  void _updateNewCount() {
    _newCount = [
      ..._reels,
      ..._highlights,
      ..._recommended,
      ..._items,
    ].newCount(_now());
  }
}
