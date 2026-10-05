# Data Model: Feed da aba Início

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-05 · formatos conferidos no servidor
([research R0](research.md))

## Entidades de domínio (`lib/modules/news/domain/entities/`)

### `NewsCategoryEntity`
| Campo | Tipo | Origem |
|---|---|---|
| `id` | `String` | `id` |
| `name` | `String` | `name` |
| `slug` | `String` | `slug` (usado no filtro) |

### `NewsInteraction`
| Campo | Tipo | Regra |
|---|---|---|
| `isRead` | `bool` | ausente → `false` |
| `isSaved` | `bool` | ausente → `false` |
| `isLiked` | `bool` | ausente → `false` (não usado na A3) |

### `NewsItemEntity`
| Campo | Tipo | Regra |
|---|---|---|
| `id` | `String` | obrigatório; chave de deduplicação |
| `title` | `String` | obrigatório |
| `source` | `String` | obrigatório |
| `sourceUrl` | `String` | obrigatório |
| `imageUrl` | `String?` | vazio → `null` |
| `originalPublishedAt` | `DateTime` | obrigatório; data exibida e base da contagem de novas |
| `publishedAt` | `DateTime?` | entrada no app (ordem do servidor) |
| `isHighlight` | `bool` | ausente → `false` |
| `categories` | `List<NewsCategoryEntity>` | ausente → `[]` (RN-002: sem rótulo) |
| `interaction` | `NewsInteraction` | ausente → tudo `false` |

O item dos Reels usa o mesmo modelo (ignora `content` e `likesCount` na A3).

### `NewsPageEntity`
| Campo | Tipo | Regra |
|---|---|---|
| `items` | `List<NewsItemEntity>` | |
| `hasMore` | `bool` | feed: `nextCursor != null && items.length == limit`; lista: `meta.hasNextPage` |
| `page` | `int` | página desta resposta |

### `NewsFeedEntity` (1ª carga sem filtro)
| Campo | Tipo | Regra |
|---|---|---|
| `highlights` | `List<NewsItemEntity>` | até 5 |
| `recommended` | `List<NewsItemEntity>` | até 10; vazio para visitante |
| `recent` | `NewsPageEntity` | página 1 |
| `reels` | `List<NewsItemEntity>` | até 10; falha → `[]` |
| `isFromCache` | `bool` | `true` quando veio da cópia guardada |

### `NewsFilter` (valor)
| Campo | Tipo | Regra |
|---|---|---|
| `categorySlug` | `String?` | `null` = "Todas" |
| `search` | `String` | normalizado com `trim()` |
| `hasSearch` | `bool` (derivado) | `search.length >= 2` |
| `isEmpty` | `bool` (derivado) | sem categoria e sem busca → usa o feed |

## Modelos (`lib/modules/news/data/models/`)

`NewsItemModel.fromJson` / `toJson` (ida e volta, para a cópia guardada), `NewsCategoryModel`,
`NewsFeedModel.fromJson(feedJson, reelsJson)`, `NewsListModel.fromJson` (`{data, meta}`). Campo
obrigatório ausente → `TypeError`, convertido em `ApiException(invalidResponse)` pelo `toModel`.

## Cópia guardada (`LocalCacheService`, chave `news_feed_cache_v1`)

```json
{ "savedAt": "2026-10-05T12:00:00.000Z", "feed": { …resposta crua do feed p.1… }, "reels": { …resposta crua dos reels… } }
```

Ilegível ou sem `feed` → tratada como ausente. Substituída a cada 1ª carga bem-sucedida.

## Estado do `FeedController`

| Campo | Significado |
|---|---|
| `status` | `FeedStatus.loading` / `loaded` / `error` (carga inicial ou troca de filtro) |
| `failure` | `Failure?` da carga inicial |
| `filter` | `NewsFilter` atual |
| `categories` | `List<NewsCategoryEntity>` ("Todas" é da UI) |
| `reels`, `highlights`, `recommended` | só com `filter.isEmpty` e 1ª página |
| `items` | lista "Tudo recente"/"Resultados", sem repetidos |
| `hasMore` | ainda há páginas |
| `isLoadingMore` / `loadMoreFailure` | rodapé da lista |
| `isFromCache` | mostra a faixa de sem internet; bloqueia paginação |
| `newCount` | contagem de novas (R6) |

### Transições

```text
abrir/atualizar ──▶ loading ──(ok)──▶ loaded ──(fim da lista)──▶ loadMore ──▶ loaded (+itens)
                         └─(falha sem cópia)──▶ error ──("Tentar novamente")──▶ loading
                         └─(falha com cópia)──▶ loaded(isFromCache)
trocar filtro/busca ──▶ loading (descarta respostas antigas por _requestId)
```

## Chaves de i18n novas (bloco `news`)

`news_search_hint` ("Buscar notícia ou tipo de golpe"), `news_search_clear` ("Limpar busca"),
`news_filter_all` ("Todas"), `news_section_new` ("Novidades"), `news_section_highlights`
("Destaques"), `news_section_recommended` ("Recomendadas para você"), `news_section_recent`
("Tudo recente"), `news_section_results` ("Resultados"), `news_reels_badge` ("Reels"),
`news_greeting_named` ("Olá, {}!"), `news_greeting_guest` ("Bem-vindo!"), `news_new_count`
("{} notícias novas para você"; plural "1 notícia nova para você" em `news_new_count_one`),
`news_date_today`, `news_date_yesterday`, `news_date_days_ago` ("Há {} dias"),
`news_month_short_1` … `news_month_short_12`, `news_end_of_list` ("Você viu todas as
notícias"), `news_offline_end` ("Conecte-se à internet para ver mais notícias."),
`news_load_more_failed` ("Não foi possível carregar mais."), `news_empty_category` ("Nenhuma
notícia nesta categoria ainda."), `news_empty_search` ("Nenhuma notícia encontrada para "{}".
Tente outras palavras."), `news_card_read` ("Lida"), `news_card_saved` ("Salva"), `news_slow_server` ("Conectando ao
servidor. Isso pode levar até um minuto.").
