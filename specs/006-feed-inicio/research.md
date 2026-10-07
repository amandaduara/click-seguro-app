# Research: Feed da aba Início

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-05

## R0. Conferência no servidor real (portão de API)

Feita em 2026-10-05 contra `https://clickseguro-api.onrender.com/api/v1`, sem credencial (como o
visitante). O servidor tem só **2 notícias** e 4 categorias de teste.

| Endpoint | Resultado |
|---|---|
| `GET /categories` | ✅ lista de `{id, name, slug, description?, isActive, createdAt}` |
| `GET /app/news/feed?page&limit` | ✅ `{highlights[], recommended[], recent: {data[], nextCursor}}`. Paginação por **`page`** funciona (página 2 traz a próxima notícia; a 3, `data: []` e `nextCursor: null`) |
| `GET /app/news/feed?cursor` | ⚠️ **cursor ignorado**: com o `nextCursor` devolvido (ou com um cursor inválido), o servidor devolve de novo a **primeira** página e o mesmo `nextCursor`. Não há o 400 `INVALID_CURSOR` do contrato |
| `GET /app/news?page&limit&category&search` | ✅ `{data[], meta}` com `hasNextPage` correto; categoria sem notícias → `data: []`; `limit > 100` → 400 `VALIDATION_ERROR` |
| `GET /app/news/reels?cursor&limit` | ✅ cursor funciona (limit 1: 1ª notícia → 2ª → `nextCursor: null`); item traz `content` e `likesCount` |
| Token inválido | 401 `TOKEN_INVALID` (como o contrato diz) |

Outros pontos observados:
- `interaction: {isLiked, isSaved, isRead}` vem **também sem token**, com tudo `false`.
- O `nextCursor` do feed por página só fica `null` na página vazia: na última página com itens ele
  ainda vem preenchido.
- Ordem: `publishedAt` decrescente (data de entrada no app). A data mostrada no cartão é a
  `originalPublishedAt` (spec FR-007), que pode não seguir a mesma ordem.

**Ação**: atualizar o [contrato da API](../../.specify/memory/api-contract.md) (✅ nas linhas
conferidas, ⚠️ no cursor do feed) e avisar o backend do cursor do feed.

## R1. Paginação do feed por página, com defesa contra repetição

**Decision**: "Tudo recente" sem filtro usa `GET /app/news/feed?page=N&limit=20`. O fim é
detectado quando `recent.nextCursor == null` **ou** a página traz menos de 20 itens. A lista
descarta itens cujo `id` já está nela; uma página que não acrescenta nenhum item novo também é
tratada como fim (proteção contra laço infinito se o servidor repetir).

**Rationale**: o cursor está quebrado no servidor (R0), mas `page` funciona e é aceito pelo
mesmo endpoint (está no openapi). A deduplicação atende ao FR-003/CB-007 mesmo com o servidor
instável. Se o backend corrigir o cursor, nada muda no app.

**Alternatives considered**:
- Usar o cursor como o contrato descreve: repetiria a primeira página para sempre.
- Usar `/app/news` para "Tudo recente": perderia as seções (destaques/recomendados) ou exigiria
  dois pedidos na primeira carga e duas ordenações diferentes.

## R2. Qual endpoint para cada estado da lista

**Decision**:
- Sem filtro e sem busca → `/app/news/feed?page` (1ª página traz destaques e recomendados).
- Com categoria e/ou busca → `/app/news?page&limit=20&category=<slug>&search=<texto>&sortBy=publishedAt&sortOrder=desc`;
  fim por `meta.hasNextPage == false`.
- Carrossel → `/app/news/reels?limit=10`, só na 1ª carga sem filtro, em paralelo com o feed.

**Rationale**: é o mapeamento do contrato; os parâmetros e a ordenação estão no openapi.

## R3. Busca: espera, cancelamento e respostas antigas

**Decision**:
- **Espera** de 500 ms no `FeedController` (um `Timer` reiniciado a cada letra), com mínimo de 2
  caracteres úteis (regra no domínio, `NewsFilter`).
- **Cancelamento**: o datasource guarda o `CancelToken` da última consulta de lista
  (`/app/news`) e cancela a anterior ao começar outra (RNF-005).
- **Respostas antigas**: o controller numera cada consulta (`_requestId`) e ignora respostas que
  não sejam da última. Vale também para troca rápida de categoria (FR-014).

**Rationale**: o cancelamento economiza rede; a numeração garante a regra mesmo quando a resposta
antiga chega antes do cancelamento valer. Um pedido cancelado vira `ServerFailure` pelo
mapeamento padrão e é descartado pela numeração, sem `Failure` nova (Princípio V: só se a UI
precisar distinguir).

**Alternatives considered**: `CancelToken` no domínio (vazaria `dio` para fora de `data/`).

## R4. Feed guardado para uso sem internet

**Decision**: `NewsLocalDataSource` sobre o `LocalCacheService` (feature 001), chave
`news_feed_cache_v1`, guardando o JSON cru da 1ª página do feed sem filtro + os Reels do carrossel
+ `savedAt`. É gravado a cada 1ª carga bem-sucedida. Quando a 1ª carga falha com
`ConnectionFailure` ou `ServerFailure` e há cópia, o repository devolve a cópia com
`isFromCache = true`; sem cópia, devolve a falha (CB-001).

Com `isFromCache`, a lista não pagina (FR-021) e mostra o aviso de que é preciso internet para
ver mais. Filtro e busca não usam cópia.

**Rationale**: guardar o JSON cru reaproveita os mesmos `fromJson` e evita um segundo formato.
`UnauthorizedFailure` não usa a cópia: a sessão já foi encerrada e o aviso da feature 005
aparece; a próxima carga sai como visitante.

## R5. Categorias

**Decision**: `GET /categories` a cada abertura do Início, em paralelo com o feed; só
`isActive == true`, na ordem do servidor. Falha → só "Todas", sem erro (FR-012). Não ficam
guardadas.

## R6. Contagem de "notícias novas" (Q1 da spec)

**Decision**: função pura numa extension (`NewsFeedPresentation.newCount(now)`): junta os itens
carregados (Reels, destaques, recomendados, recentes), remove repetidos por `id` e conta os de
`originalPublishedAt` nas últimas 24 h em relação a `now`. O `now` é injetável no controller
(`DateTime Function() now`) para teste.

## R7. Datas e categorias no cartão

**Decision**: `NewsPresentationExtension` em `presentation/extensions/`:
- data relativa por dia de calendário local: "Hoje", "Ontem", "Há N dias" (2 a 6) e, depois,
  "12 de set." com os nomes curtos dos meses em i18n (`news_month_short_1` … `_12`), sem
  depender de `intl` diretamente;
- categorias: até 2 nomes + "+N";
- rótulo para leitor de tela: "título, fonte, data, categorias".

**Rationale**: regras de exibição em extension testável (plano do produto §5). `intl` é só
dependência transitiva; usá-la direto exigiria declará-la no `pubspec` (Seção IV).

## R8. Imagens

**Decision**: `Image.network` com `fit: BoxFit.cover`, `errorBuilder` e `loadingBuilder`
mostrando um quadro neutro com o ícone de jornal. Sem pacote novo de cache de imagem.

**Rationale**: KISS; o cache de imagem do Flutter já evita baixar de novo durante a sessão.
Pacote de cache em disco fica para quando o offline de imagens for requisito.

## R9. Sinais de "lida" e "salva"; selo "Novo" fora

**Decision**: o cartão mostra os sinais quando `interaction.isRead`/`isSaved` são `true`. Como o
servidor manda tudo `false` para o visitante, nenhum sinal aparece para ele, sem lógica extra. O
selo "Novo" do wireframe **sai do escopo**: com o servidor mandando `isRead: false` também para o
visitante, distinguir exigiria o controller consultar a sessão só para isso.

**Spec**: a suposição sobre o selo "Novo" é atualizada (fora do escopo).

## R10. Estado preservado e navegação

**Decision**:
- `FeedController` registrado como `ChangeNotifierProvider` no `NewsModule` (acima do app), então
  o estado e a posição sobrevivem a troca de aba e a abrir um detalhe (FR-025; a aba já é mantida
  viva pelo `indexedStack`).
- Cartão → `context.push('/news/$id')`; cartão do carrossel → `context.go('/reels?start=$id')`
  (troca para a aba central). Toque duplo: o cartão ignora toques enquanto a navegação anterior não
  terminou.
- Carregando com o servidor dormindo: `SlowRequestNotice` (feature 003) abaixo do
  `SafeLoadingState`.

## R11. Testes de cada camada

Fakes à mão: `FakeHttpClientAdapter` (já existe, para o datasource), `FakeLocalCacheService`
(já existe), `FakeNewsRepository` (novo). Datas fixas com `now` injetado. Controller testado com
relógio falso do `testWidgets` para a espera da busca.
