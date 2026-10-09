# Data Model: Detalhe da notícia e notícias salvas

Formatos do servidor em [research.md](research.md) R0 e no [contrato](contracts/news-detail.md).
Entidades existentes reaproveitadas: `NewsItemEntity`, `NewsInteraction`, `NewsCategoryEntity`,
`NewsPageEntity` (com `appendUnique`).

## Domínio

### `SuggestedModuleEntity` (novo)

| Campo | Tipo | Regra |
|---|---|---|
| `id` | `String` | usado em `/activities/<id>` |
| `title` | `String` | |
| `description` | `String` | pode ser vazio |
| `iconUrl` | `String?` | vazio → `null` |
| `lessonsCount` | `int` | número de perguntas mostrado no bloco |

### `NewsDetailEntity` (novo)

Compõe `NewsItemEntity` (como o `ReelEntity` da 008).

| Campo | Tipo | Regra |
|---|---|---|
| `news` | `NewsItemEntity` | id, título, fonte, `sourceUrl`, imagem, datas, categorias, `interaction` |
| `content` | `String` | pode ser vazio → aviso "texto não disponível" (edge case) |
| `likesCount` | `int` | `num` do servidor → `int`; ausente → 0 |
| `readsCount` | `int` | ausente → 0 (não aparece na tela) |
| `suggestedModule` | `SuggestedModuleEntity?` | `null` → sem bloco (FR-021) |

Derivados (extension, testáveis): `hasSource` (`sourceUrl` não vazio e `http(s)`), `isSaved`
(= `news.interaction.isSaved`), `copyWith(isSaved:)` para o otimismo.

### `NewsDetailResult` (novo)

| Campo | Tipo | Regra |
|---|---|---|
| `detail` | `NewsDetailEntity` | |
| `isFromCache` | `bool` | `true` → aviso de offline e **não** registra leitura (R4) |

### `SavedNewsResult` (novo)

| Campo | Tipo | Regra |
|---|---|---|
| `page` | `NewsPageEntity` | itens, `page`, `hasMore` (= `meta.hasNextPage`) |
| `isFromCache` | `bool` | só na página 1 sem conexão |

## Dados

### `NewsDetailModel` (novo)

`fromJson`: usa `NewsItemModel.fromJson` para a parte comum e lê `content` (`String`, ausente →
`''`), `likesCount`/`readsCount` (`num` → `int`, ausente → 0) e `suggestedModule` (objeto →
`SuggestedModuleModel`, `null`/ausente/sem `id` → `null`). Campo obrigatório faltando (`id`,
`title`, `source`, `sourceUrl`, `originalPublishedAt`) → exceção de parse → falha genérica
(CB-005).

### Lista de salvas

Sem model novo: `NewsListModel.fromJson` (`data` + `meta.page` + `meta.hasNextPage`). O item não
traz `content`, `createdAt` nem `isHighlight`; `NewsItemModel` já usa `false` para `isHighlight`.

## Cópias no aparelho (`LocalCacheService`)

### `news_detail_cache_v1`

```json
{
  "owner": "pessoa@exemplo.com",
  "items": [ { "savedAt": "2026-10-09T03:00:00.000Z", "json": { "...": "newsDetail cru" } } ]
}
```

- Mais recente primeiro; ao gravar, o id já existente sobe para o topo (sem repetir).
- Máximo `NewsLocalDataSourceImpl.maxCachedDetails = 30`; o excedente sai do fim.
- `owner`: e-mail da sessão; visitante → `"guest"`. Ler com outro dono → `null` (e a cópia é
  substituída na próxima gravação).

### `news_saved_cache_v1`

```json
{ "owner": "pessoa@exemplo.com", "savedAt": "2026-10-09T03:00:00.000Z", "page": { "data": [], "meta": {} } }
```

- Só a página 1, substituída a cada carga com sucesso. Visitante não grava nem lê.

### Limpeza

`clearAccountCopies()` remove as duas chaves. Chamado pelo `NewsModule` quando
`sessionStatus` vai para `unauthenticated` (sair ou sessão expirada) — FR-018, R3.

## Apresentação

### `NewsDetailController` (novo, um por página)

| Estado | Tipo | Notas |
|---|---|---|
| `status` | `NewsDetailStatus` | `loading`, `loaded`, `error`, `notFound` |
| `detail` | `NewsDetailEntity?` | |
| `isFromCache` | `bool` | aviso de offline |
| `failure` | `Failure?` | mensagem do erro |
| `isSaving` | `bool` | toques ignorados enquanto `true` |
| `message` | `NewsDetailMessage?` | `saved`, `removed`, `saveFailed`, `notFound`, `sourceFailed` (consumida pela página como aviso curto) |
| `autoReadDone` | `bool` | leitura automática no máximo uma vez por abertura (FR-008) |

Transições: `load()` → `loading` → (`loaded` | `error` | `notFound`); `loaded` com conta e sem
cópia → `markAsRead` sem esperar. `retry()` = `load()`. `toggleSave()` (só chamado com conta):
inverte `isSaved` na hora → resposta aplica o devolvido → falha volta ao anterior. Sessão vira
`authenticated` com a tela aberta → `load()` de novo (edge case do convite).

### `SavedNewsController` (novo, um por página)

| Estado | Tipo | Notas |
|---|---|---|
| `status` | `FeedStatus` (reuso) | carregando, pronto, erro, vazio |
| `items` | `List<NewsItemEntity>` | sem repetir (`appendUnique`) |
| `page`, `hasMore`, `isLoadingMore`, `loadMoreFailure` | | mesmo padrão do `FeedController` |
| `isFromCache` | `bool` | aviso de offline |

`load()` (página 1), `loadMore()` perto do fim (até `hasMore = false`), `refresh()` ao voltar do
detalhe.
