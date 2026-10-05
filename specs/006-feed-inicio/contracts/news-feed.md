# Contrato: dados e interfaces do feed

**Feature**: [spec.md](../spec.md) · **Date**: 2026-10-05

## Pedidos ao servidor (conferidos em 2026-10-05, [R0](../research.md))

Todos com auth opcional: o `ApiClient` envia o token só se houver sessão conectada.

| Uso | Pedido | Fim da lista |
|---|---|---|
| 1ª carga sem filtro | `GET /app/news/feed?page=1&limit=20` + `GET /app/news/reels?limit=10` (em paralelo) | `recent.nextCursor == null` ou `< 20` itens |
| Próximas páginas sem filtro | `GET /app/news/feed?page=N&limit=20` (só `recent`) | idem |
| Categoria e/ou busca | `GET /app/news?page=N&limit=20&category=<slug>&search=<texto>&sortBy=publishedAt&sortOrder=desc` | `meta.hasNextPage == false` |
| Filtros | `GET /categories` | — |

Não usar o `cursor` do feed (o servidor o ignora). `search` só com 2 caracteres ou mais (o
servidor aceita 1 a 100).

## Interfaces internas (Dart, resumidas)

```text
NewsRemoteDataSource                         data/datasources
  getFeed({required int page}) → Future<Map>        resposta crua (para a cópia)
  getReels({int limit = 10}) → Future<Map>
  getNews({required int page, String? category, String? search}) → Future<NewsListModel>
                                                    cancela a consulta getNews anterior
  getCategories() → Future<List<NewsCategoryModel>>

NewsLocalDataSource                          data/datasources
  readFeed() → Future<CachedFeed?>   writeFeed(feedJson, reelsJson)

NewsRepository (domain) → Either<Failure, T>, nunca lança
  getFeedFirstPage() → NewsFeedEntity          cópia em ConnectionFailure/ServerFailure
  getFeedPage(int page) → NewsPageEntity
  getNews(NewsFilter filter, int page) → NewsPageEntity
  getCategories() → List<NewsCategoryEntity>   só ativas

Usecases: GetFeedUseCase, GetFeedPageUseCase, GetNewsUseCase, GetCategoriesUseCase

FeedController (ChangeNotifier, NewsModule.providers)
  load()  refresh()  loadMore()  selectCategory(String? slug)
  onSearchChanged(String text)  clearSearch()
```

## Navegação

| Toque | Ação |
|---|---|
| Cartão (lista, destaques, recomendados) | `context.push('/news/<id>')` |
| Cartão do carrossel | `context.go('/reels?start=<id>')` |
