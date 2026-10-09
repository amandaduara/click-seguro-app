# Data Model: Reels com curtir, salvar e abrir a fonte

**Feature**: [spec.md](spec.md) · **Research**: [research.md](research.md)

Caminhos relativos a `click_seguro_app/lib/modules/news/`.

## Domínio (`domain/`)

### `ReelEntity` — `entities/reel_entity.dart`

Reel = notícia + texto + curtidas. Composição com `NewsItemEntity` para reaproveitar as
extensions de data e categorias da feature 006.

| Campo | Tipo | Regra |
|---|---|---|
| `news` | `NewsItemEntity` | id, título, fonte, `sourceUrl`, imagem, datas, categorias, `interaction.isSaved` |
| `content` | `String` | texto completo; vazio → trecho oculto |
| `likesCount` | `int` | ≥ 0; vem do servidor |
| `isLiked` | `bool` | começa `false` (o servidor não envia, R2); depois, o `liked` do toggle |
| `isSaved` | `bool` | do `interaction.isSaved`; depois, o `saved` do toggle |

Getters: `id` (= `news.id`). `copyWith({likesCount, isLiked, isSaved})`.

### `ReelsPageEntity` — `entities/reels_page_entity.dart`

| Campo | Tipo | Regra |
|---|---|---|
| `items` | `List<ReelEntity>` | ordem do servidor |
| `nextCursor` | `String?` | `null` = fim |

Getter `hasMore => nextCursor != null`. Extension `appendUniqueReels` (mesma regra do
`appendUnique` de `NewsPageEntity`: sem repetir `id`, devolve quantos entraram).

### `LikeResultEntity` — `entities/like_result_entity.dart`

`{ bool liked, int likesCount }`. Salvar devolve só `bool` (sem entidade).

### `NewsNotFoundFailure` — `failures/news_failures.dart`

`Failure` com a chave `AppStrings.newsErrorNotFound` ("Notícia não encontrada"). Vem de 404 ou
`errorCode == 'NEWS_NOT_FOUND'` no like/save.

### `NewsRepository` (acréscimos)

```text
getReels({String? cursor})          → Either<Failure, ReelsPageEntity>
toggleLike(String newsId)           → Either<Failure, LikeResultEntity>
toggleSave(String newsId)           → Either<Failure, bool>
```

### Usecases — `usecases/`

`GetReelsUseCase(cursor)`, `ToggleLikeUseCase(newsId)`, `ToggleSaveUseCase(newsId)`; cada um
repassa ao repository (o `ToggleSaveUseCase` será reaproveitado pela A5).

## Dados (`data/`)

### Models — `models/`

- `ReelModel` (`reel_model.dart`): `NewsItemModel.fromJson(json)` + `content` (`String`, ausente →
  `''`) + `likesCount` (`num` → `int`, ausente → 0). `toEntity()`.
- `ReelsPageModel` (`reels_page_model.dart`): `data[]` convertidos item a item, descartando os
  malformados (R8); `nextCursor`. `toEntity()`.
- `LikeResultModel` (`like_result_model.dart`): `liked`, `likesCount` (`num` → `int`).
- Salvar: `json['saved'] as bool` direto no datasource.

### `NewsRemoteDataSource` (acréscimos)

| Método | Pedido | Retorno |
|---|---|---|
| `getReelsPage({String? cursor})` | `GET /app/news/reels?limit=10[&cursor=]` | `ReelsPageModel` |
| `toggleLike(String id)` | `POST /app/news/{id}/like` | `LikeResultModel` |
| `toggleSave(String id)` | `POST /app/news/{id}/save` | `bool` |

Constante `reelsPageSize = 10`. `getReels()` do carrossel continua igual.

### `NewsRepositoryImpl` (acréscimos)

`_guard` padrão; para like/save, antes do `toFailure()`: `statusCode == 404` ou
`errorCode == 'NEWS_NOT_FOUND'` → `NewsNotFoundFailure`.

## Apresentação (`presentation/`)

### `ReelsStatus` — `controller/reels_status.dart`

`enum ReelsStatus { initial, loading, loaded, error }`.

### `ReelsController` — `controller/reels_controller.dart`

| Estado | Tipo | Observação |
|---|---|---|
| `status` | `ReelsStatus` | `initial` até o 1º `open` |
| `failure` | `Failure?` | erro da 1ª carga |
| `reels` | `List<ReelEntity>` | sem repetir |
| `currentIndex` | `int` | Reel na tela |
| `hasMore` / `isLoadingMore` / `loadMoreFailure` | | paginação por cursor |
| `isEnd` | `bool` | carregou e `!hasMore` |
| `canGoPrevious` / `canGoNext` | `bool` | para os botões (FR-002) |
| `isLikePending(id)` / `isSavePending(id)` | `bool` | toques ignorados (FR-014) |
| `messages` | `Stream<ReelsMessage>` | avisos curtos: erro (chave do `Failure`), salvo, removido |

| Ação | Comportamento |
|---|---|
| `open([String? startId])` | `initial`/desatualizado → `_loadFirst(startId)`; carregado → posiciona em `startId` se estiver em `reels` |
| `retry()` / `refresh()` | 1ª carga de novo, índice 0 |
| `setIndex(int)` | atualiza `currentIndex`; se `reels.length - 1 - index <= prefetchThreshold (3)` → `loadMore()` |
| `loadMore()` | só com `hasMore`, sem outra carga e `loaded`; junta sem repetir; página sem nada novo encerra (CB-007) |
| `toggleLike(id)` | otimista ±1 → resposta do servidor ou reversão + mensagem (R3) |
| `toggleSave(id)` | otimista → resposta; sucesso emite `saved`/`removed`; falha reverte + mensagem |

Dependências: `GetReelsUseCase`, `ToggleLikeUseCase`, `ToggleSaveUseCase`,
`ValueListenable<UserSessionStatus>` (R5). Respostas de cargas antigas ignoradas por
`_requestId` (como no `FeedController`).

Transições de `status`: `initial → loading → loaded | error`; `error → loading` (retry);
`loaded → loading` (refresh ou sessão mudou + `open`).

### `ReelsMessage` — no mesmo arquivo do controller

`enum ReelsMessageType { error, saved, removed }` + `String? failureKey`.

### Extension — `extensions/reel_presentation_extension.dart`

- `likeSemanticLabel` ("Curtir, 12 curtidas" / "Curtido, 13 curtidas"),
  `saveSemanticLabel` ("Salvar" / "Salvo"), `formattedLikes` (ex.: "1,2 mil" a partir de 1000).
- `semanticLabel(now)`: título, fonte e data (reaproveita `NewsItemPresentation`).

### Widgets e página

- `pages/reels_page.dart` — `ReelsPage(startNewsId)`: estados (carregando + `SlowRequestNotice`,
  erro, vazio) em fundo escuro; `PageView` vertical; mensagens em `SnackBar`.
- `widgets/reel_view.dart` — um Reel em tela cheia (imagem/fundo, gradiente, categorias,
  título, trecho, fonte·data, "Ler notícia completa", aviso de fim/erro de parte seguinte).
- `widgets/reel_actions.dart` — coluna de botões redondos: anterior, próxima, curtir (+contagem),
  salvar, abrir fonte (oculto sem `sourceUrl` válido, `isOpenableWebUrl`).

## i18n (`AppStrings` + `pt-BR.json`/`en-US.json`, bloco news)

`newsReelsPrevious`, `newsReelsNext`, `newsReelsLike`, `newsReelsLiked`, `newsReelsLikesCount`,
`newsReelsSave`, `newsReelsSaved`, `newsReelsSavedToast`, `newsReelsRemovedToast`,
`newsReelsOpenSource`, `newsReelsOpenSourceFailed`, `newsReelsReadFull`, `newsReelsEmpty`,
`newsReelsRefresh`, `newsReelsEnd`, `newsReelsLoadMoreFailed`, `newsErrorNotFound`,
`newsReelsThousand`.
