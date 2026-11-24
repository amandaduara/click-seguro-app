import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_interaction_change.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_categories_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_page_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/watch_news_interactions_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_message.dart';
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
    required WatchNewsInteractionsUseCase watchInteractions,
    required ValueListenable<UserSessionStatus> sessionStatus,
    DateTime Function()? now,
  }) : _getFeed = getFeed,
       _getFeedPage = getFeedPage,
       _getNews = getNews,
       _getCategories = getCategories,
       _sessionStatus = sessionStatus,
       _now = now ?? DateTime.now {
    _sessionStatus.addListener(_onSessionChanged);
    _interactions = watchInteractions().listen(_applyInteraction);
  }

  final GetFeedUseCase _getFeed;
  final GetFeedPageUseCase _getFeedPage;
  final GetNewsUseCase _getNews;
  final GetCategoriesUseCase _getCategories;
  final ValueListenable<UserSessionStatus> _sessionStatus;
  final DateTime Function() _now;
  late final StreamSubscription<NewsInteractionChange> _interactions;

  final StreamController<FeedMessage> _messages =
      StreamController<FeedMessage>.broadcast();

  /// Avisos que não trocam a tela (falha ao puxar para atualizar).
  Stream<FeedMessage> get messages => _messages.stream;

  /// Espera depois da última letra antes de buscar (FR-016).
  static const Duration searchDebounce = Duration(milliseconds: 500);

  Timer? _searchTimer;

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

  bool _isRefreshing = false;

  /// Recarga com a lista na tela: a lista continua até a nova chegar
  /// (specs/022 FR-002).
  bool get isRefreshing => _isRefreshing;

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

  /// Há busca ativa: a lista mostra "Resultados".
  bool get isSearching => _filter.hasSearch;

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

  /// Carga inicial (ou tentar de novo), com as categorias dos filtros.
  Future<void> load() async {
    await Future.wait([_loadFirst(), _loadCategories()]);
  }

  /// Troca a categoria (`null` = "Todas") e recarrega a lista (FR-013).
  Future<void> selectCategory(String? slug) async {
    if (slug == _filter.categorySlug) return;
    _filter = slug == null
        ? _filter.copyWith(clearCategory: true)
        : _filter.copyWith(categorySlug: slug);
    await _loadFirst(keepContent: true);
  }

  /// Puxar para atualizar: volta à página 1; a lista continua na tela e,
  /// se falhar, fica como estava (FR-003).
  Future<void> refresh() => _loadFirst(keepContent: true, keepOnFailure: true);

  /// Texto digitado na busca: busca depois de [searchDebounce] sem novas
  /// letras; texto curto demais volta à lista sem busca (FR-016, FR-017).
  void onSearchChanged(String text) {
    _searchTimer?.cancel();
    final bool wasSearching = _filter.hasSearch;
    _filter = _filter.copyWith(search: text);
    if (_filter.hasSearch) {
      _searchTimer = Timer(
        searchDebounce,
        () => unawaited(_loadFirst(keepContent: true)),
      );
    } else if (wasSearching) {
      unawaited(_loadFirst(keepContent: true));
    }
  }

  /// O "X" do campo: volta na hora à lista sem busca.
  void clearSearch() {
    _searchTimer?.cancel();
    final bool wasSearching = _filter.hasSearch;
    _filter = _filter.copyWith(search: '');
    if (wasSearching) unawaited(_loadFirst(keepContent: true));
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _sessionStatus.removeListener(_onSessionChanged);
    unawaited(_interactions.cancel());
    unawaited(_messages.close());
    super.dispose();
  }

  /// Outra conta (ou visitante): recarrega sem manter a lista, para não
  /// mostrar as marcas da conta anterior (FR-004). Ao sair da conta, não:
  /// a pessoa já está no login, e o pedido seria inútil para um servidor
  /// lento; quem entrar em seguida (conta ou visitante) recarrega.
  void _onSessionChanged() {
    if (_sessionStatus.value == UserSessionStatus.unauthenticated) return;
    unawaited(_loadFirst());
  }

  /// Leitura, curtida ou "salvar" confirmado em outra tela: corrige só o
  /// item, sem pedir ao servidor (FR-005).
  void _applyInteraction(NewsInteractionChange change) {
    List<NewsItemEntity> patch(List<NewsItemEntity> list) => [
      for (final item in list)
        item.id == change.newsId
            ? item.withInteraction(change.applyTo(item.interaction))
            : item,
    ];
    bool contains(List<NewsItemEntity> list) =>
        list.any((item) => item.id == change.newsId);
    if (![_reels, _highlights, _recommended, _items].any(contains)) return;
    _reels = patch(_reels);
    _highlights = patch(_highlights);
    _recommended = patch(_recommended);
    _items = patch(_items);
    notifyListeners();
  }

  /// Próxima página da lista atual. Não faz nada sem mais páginas, durante
  /// outra carga ou com a cópia guardada.
  Future<void> loadMore() async {
    if (!_hasMore ||
        _isLoadingMore ||
        _isRefreshing ||
        _status != FeedStatus.loaded) {
      return;
    }
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

  /// Página 1 da lista atual. Com [keepContent] e uma lista na tela, ela
  /// continua visível ([isRefreshing]) em vez de virar carregando. Com
  /// [keepOnFailure], uma falha mantém a lista e vira [FeedMessage]; sem
  /// ele, vira o estado de erro (troca de filtro: a lista antiga não
  /// corresponde mais).
  Future<void> _loadFirst({
    bool keepContent = false,
    bool keepOnFailure = false,
  }) async {
    final int requestId = ++_requestId;
    final bool refreshing = keepContent && _status == FeedStatus.loaded;
    if (refreshing) {
      _isRefreshing = true;
    } else {
      _status = FeedStatus.loading;
    }
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
    _isRefreshing = false;

    result.fold(
      (failure) {
        if (refreshing && keepOnFailure) {
          _messages.add(FeedMessage(failure.message));
          return;
        }
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

  /// Falha nas categorias deixa só "Todas" (FR-012).
  Future<void> _loadCategories() async {
    final result = await _getCategories();
    _categories = result.getOrElse((_) => const []);
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
