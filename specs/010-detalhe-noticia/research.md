# Research: Detalhe da notícia e notícias salvas

## R0 — Formato real dos endpoints da A5 (conferido no servidor)

- **Decision**: usar os formatos devolvidos pelo servidor de desenvolvimento em 2026-10-09
  (`https://clickseguro-api.onrender.com/api/v1`), conferidos com uma conta de teste criada só
  para isso (`teste-a5-20261009002536@example.com`, desativada no fim com
  `DELETE /users/me/deactivate`; a API não tem exclusão definitiva).
- **Resultados**:
  - `GET /app/news/{id}` → 200 `newsDetail`: `{ id, title, content, source, sourceUrl,
    isHighlight, imageUrl?, likesCount, readsCount, publishedAt?, originalPublishedAt,
    createdAt, categories: [{id, name, slug}], interaction: {isLiked, isSaved, isRead},
    suggestedModule: {id, title, description, iconUrl?, lessonsCount} | null }`.
  - **Sem token** o detalhe também responde 200, com `interaction` tudo `false` (como no feed) e
    **com `suggestedModule`** quando há módulo para as categorias. O openapi diz "se
    autenticado", mas o servidor envia para todos.
  - `suggestedModule` é `null` quando nenhuma categoria tem módulo (ex.: só
    `seguranca-bancaria` ou `protecao-de-dados` hoje). Em 8 de 12 notícias veio um módulo.
  - Id inexistente → 404 `{statusCode, code: "NEWS_NOT_FOUND", message, path, timestamp}`.
  - `POST /app/news/{id}/read` com token → 204 sem corpo; a 2ª chamada também → 204
    (idempotente). Sem token → 401 `TOKEN_NOT_PROVIDED`. Depois da leitura, `readsCount` subiu
    para 1 e a lista de salvas trouxe `isRead: true`.
  - `POST /app/news/{id}/save` → 200 `{saved: true}`; de novo → `{saved: false}` (alterna).
  - `GET /users/me/news/saved?page=1&limit=20` → 200 `{ data: [savedItem], meta: {page, limit,
    total, totalPages, hasNextPage, hasPreviousPage} }`. Sem token → 401 `TOKEN_NOT_PROVIDED`.
  - `savedItem` = `{ id, title, source, sourceUrl, imageUrl?, publishedAt?, originalPublishedAt,
    categories, interaction }`: **não traz `content`, `createdAt` nem `isHighlight`**. O model
    da lista não pode exigir esses campos.
- **Rationale**: o contrato tinha as três linhas como 🧪; agora estão ✅. A única diferença do
  openapi é o `suggestedModule` sem token, que muda a spec: o visitante também vê o bloco de
  atividade relacionada (ele pode fazer atividades como visitante, RN-006).
- **Conferido no aparelho (T049)**: a lista de salvas vem da salva mais recente para a mais antiga
  (não por `publishedAt`), com 3 notícias. O app usa a ordem do serviço (contrato 1.0.6).
- **Alternatives considered**: usar a conta pessoal do usuário — descartado para não mexer em
  dados reais; a conta de teste foi pedida pelo usuário.

## R1 — Rota `/news/saved` antes de `/news/:id`

- **Decision**: declarar `/news/saved` **antes** de `/news/:id` em `newsRoutes`, ambas no navegador
  raiz (por cima das abas).
- **Rationale**: o `go_router` casa as rotas na ordem; depois de `/news/:id`, "saved" viraria um
  id e abriria o detalhe de uma notícia inexistente. Um teste de rota cobre a ordem.
- **Alternatives considered**: `/saved-news` (fora do prefixo do módulo) ou `/news/:id` com
  checagem de "saved" — descartados: o caminho combinado com o usuário é `/news/saved` e uma
  checagem dentro da rota de detalhe esconde a regra.

## R2 — Cópia offline do detalhe: últimas notícias abertas, não só as salvas

- **Decision**: guardar o JSON cru das **últimas 30 notícias abertas** (mais recente primeiro)
  numa chave do `LocalCacheService`, marcado com o dono da cópia. Sem internet, o detalhe abre
  a cópia, se houver.
- **Rationale**: a lista de salvas não traz o texto (R0). Guardar ao abrir cobre o FR-016 (toda
  notícia salva aberta neste aparelho tem cópia) sem o repository precisar saber, no momento de
  salvar, o JSON de uma notícia que não buscou. Também cobre a notícia salva pelo Reel e aberta
  depois. 30 itens de ~1–3 KB ficam bem abaixo de 100 KB.
- **Consequência na spec**: a premissa "apagado ao remover dos salvos" vira "as 30 últimas
  notícias abertas ficam guardadas"; ajustada na spec (Assumptions). FR-016 continua valendo.
- **Alternatives considered**: guardar só quando `isSaved` (exige reagir ao toggle com o JSON
  em mãos e apagar ao remover; mais estado para pouco ganho) — descartado.

## R3 — Cópias por conta e limpeza ao sair

- **Decision**: os dois registros (1ª página das salvas e detalhes) guardam `owner` (o e-mail
  da sessão; `guest` para visitante, só nos detalhes). A leitura ignora cópia de outro dono. O
  `NewsModule` ouve `UserSessionService.sessionStatus` e, ao ir para `unauthenticated`, apaga as
  duas chaves (FR-018).
- **Rationale**: o listener cobre "sair" e "sessão expirada"; o `owner` cobre o caso em que o
  app morre antes de apagar e outra conta entra no mesmo aparelho. `UserSessionService` não
  conhece o módulo `news` (constituição I), por isso a limpeza fica no módulo.
- **Alternatives considered**: um "hook de logout" no `UserSessionService` chamando os módulos —
  inverteria a dependência (`common` → `news`).

## R4 — Registro de leitura sem bloquear a tela

- **Decision**: `NewsDetailController.load` chama `MarkNewsAsReadUseCase` sem `await`
  (`unawaited`), só se a sessão for `authenticated` e o detalhe tiver vindo do servidor (não da
  cópia). O resultado é ignorado.
- **Rationale**: FR-004 e SC-002; o serviço é idempotente (R0), então reabrir não conta duas
  vezes e não há motivo para tentar de novo.

## R5 — Voz: preparar antes de carregar e ler título + texto

- **Decision**: a página cria um `ReadAloudController` (factory do `CommonModule`), chama
  `prepare(context.locale)` em paralelo com a carga do detalhe e, quando os dois terminam,
  inicia a leitura automática se `AccessibilityPreferencesNotifier.value.autoReadAloud` e
  `isAvailable` (FR-008). O texto lido é `"<título>.\n\n<texto>"`. "Parar" logo depois marca a
  leitura automática como já feita naquela abertura.
- **Rationale**: o controller já resolve idioma do app (RF-042, decisão de 2026-10-09),
  velocidade da página × guardada (FR-007) e parada no `dispose` (FR-009). Nada novo no `common`.

## R6 — Salvar no detalhe e na lista

- **Decision**: reaproveitar `ToggleSaveUseCase` (feature 008) com o mesmo padrão otimista do
  `ReelsController`: muda na hora, aplica o estado devolvido, volta em falha, ignora toques com
  pedido pendente. Para visitante, `requireAccount` antes de qualquer chamada.
- A lista de salvas recarrega a 1ª página ao voltar do detalhe (`await context.push(...)`),
  para refletir uma remoção (FR-014).

## R7 — Lista de salvas por página

- **Decision**: `GET /users/me/news/saved?page&limit=20`, `hasMore = meta.hasNextPage`, reaproveitando
  `NewsListModel`/`NewsPageEntity` e `appendUnique` (dedup por `id`, CB-007). Itens sem
  `isHighlight`/`createdAt` já são aceitos pelo `NewsItemModel` (padrão `false`).
- **Rationale**: o formato é o mesmo de `/app/news` (R0); sem model novo.

## R8 — Entrada de desenvolvimento para a lista

- **Decision**: o `lib/dev/accessibility_playground.dart` ganha um botão "Notícias salvas" que faz
  `push('/news/saved')`. Some quando a B7 puser o atalho no Perfil.
- **Rationale**: permite o teste no emulador sem mexer em módulo da trilha B.
