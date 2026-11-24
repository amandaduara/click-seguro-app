# Research: Reels com curtir, salvar e abrir a fonte

**Feature**: [spec.md](spec.md) · **Data**: 2026-10-08

## R0 — Formato real de `GET /app/news/reels` (conferido no servidor)

- **Decision**: usar o formato devolvido pelo servidor de desenvolvimento em 2026-10-08:
  `{ data: [reelItem], nextCursor: string | null }`. Cada item traz `id, title, source, sourceUrl,
  isHighlight, content, imageUrl, originalPublishedAt, publishedAt, createdAt, likesCount,
  categories[], interaction: { isSaved }` — **sem `isLiked`**, como diz o contrato.
- **Rationale**: pedido real `?limit=10` → 10 itens + cursor; com o cursor → 2 itens e
  `nextCursor: null`; 12 Reels únicos no total. O cursor dos Reels funciona (ao contrário do
  cursor do feed, R1 de specs/006). `likesCount` chega como número inteiro.
- **Observado**: cursor inválido (`?cursor=lixo`) devolve **200 com a primeira parte**, não o 400
  `INVALID_CURSOR` do openapi. Consequência: a deduplicação por `id` (CB-007) protege também
  contra esse caso.
- **Alternatives considered**: reaproveitar `getReels()` do carrossel — rejeitado: ele devolve o
  JSON cru sem cursor, para a cópia offline do feed; a tela de Reels precisa do cursor e do
  `content`/`likesCount`.

## R1 — `POST /app/news/{id}/like` e `/save`

- **Decision**: seguir o openapi: like → `{ liked: bool, likesCount: number }`, save →
  `{ saved: bool }`, ambos alternam. 404 `NEWS_NOT_FOUND` → `NewsNotFoundFailure`.
- **Rationale**: sem token o servidor devolve 401 `TOKEN_NOT_PROVIDED` (conferido), então o app
  nunca chama como visitante (RN-003). Não há conta de teste disponível nesta sessão: as linhas
  ficam 🧪 no contrato e a resposta real é conferida no aparelho (quickstart, passo 4), quando
  viram ✅.
- **Alternatives considered**: criar uma conta no servidor compartilhado só para testar —
  adiado para o teste no aparelho, com a conta de teste do time.

## R2 — Estado de curtida sem `isLiked`

- **Decision**: `ReelEntity.isLiked` começa `false`; depois de um toggle, passa a ser o `liked`
  devolvido. A contagem passa a ser o `likesCount` devolvido.
- **Rationale**: é o que o contrato prescreve. Buscar `/users/me/news/liked` para pré-marcar
  está fora da v1 (api-contract, "sem tela na v1").

## R3 — Atualização otimista com reversão

- **Decision**: o controller aplica o novo estado na hora (curtida ±1, salvo invertido), guarda o
  estado anterior e, na resposta: sucesso → aplica o estado do servidor; falha → restaura o
  anterior e expõe a mensagem. Um `Set<String>` de ids com pedido em andamento por ação ignora
  toques repetidos (FR-014).
- **Rationale**: SC-003 (retorno < 100 ms) e público idoso; a regra "estado do servidor vence"
  corrige o caso de quem já tinha curtido (cenário 2.4).
- **Alternatives considered**: esperar a resposta com indicador no botão — rejeitado pelo SC-003
  e pelo servidor que pode demorar ~40 s para acordar.

## R4 — Onde vive o estado da tela

- **Decision**: `ReelsController` (ChangeNotifier) registrado em `NewsModule.providers`, como o
  `FeedController`, **sem** carga no `create`: a página chama `open(startNewsId)` ao aparecer
  (a aba central só é montada na primeira visita, `StatefulShellRoute.indexedStack`).
- **Rationale**: FR-006 (manter posição ao trocar de aba) já é garantido pelo `indexedStack`;
  manter o controller acima do app também cobre voltar do detalhe e a troca de `start` vinda do
  carrossel. Evita pedir Reels para quem nunca abre a aba.
- **`start`**: `open(startId)` — se ainda não carregou, carrega a 1ª parte e posiciona no Reel
  com aquele `id` (ou no primeiro); se já carregou, só posiciona se o `id` estiver entre os
  carregados (FR-004).

## R5 — Mudança de sessão

- **Decision**: o controller observa `UserSessionService.sessionStatus` (um
  `ValueListenable<UserSessionStatus>` injetado) e, quando o status muda depois de uma carga,
  marca os Reels como desatualizados; o próximo `open` recarrega do início.
- **Rationale**: visitante que entra pelo convite precisa ver o `isSaved` da conta (caso de
  borda); quem sai não deve ver estado da conta anterior. Recarregar no `open` evita pedir na
  hora em que a aba não está visível.

## R6 — Ação restrita para visitante

- **Decision**: a página chama `requireAccount(context)` (shell, feature 005) antes de
  `controller.toggleLike/toggleSave`. O controller não conhece sessão para essa regra.
- **Rationale**: é o padrão definido na 005 (`AppTopBar` já usa); `news` já importa `shell`.
  O widget test com sessão de visitante confere que o fake do repository não recebe chamada
  (SC-004).

## R7 — UI: `PageView` vertical e botões

- **Decision**: `PageView.builder(scrollDirection: Axis.vertical)` com `PageController`
  (`initialPage` = índice atual do controller); `onPageChanged` → `controller.setIndex`, que pede
  a próxima parte quando faltam ≤ 3 (`ReelsController.prefetchThreshold`). Botões de seta
  chamam `animateToPage`. Imagem com `Image.network` + `errorBuilder` (como o carrossel), sem
  pacote novo. Trecho do texto: `Text(maxLines: 4, overflow: ellipsis)`.
- **Rationale**: tudo no Flutter padrão; mantém as regras de paginação testáveis no controller.
  Botões visuais de 40 px dentro de área de toque de 48 dp (FR-021, `BoxConstraints`).

## R8 — Reel malformado

- **Decision**: `ReelsPageModel.fromJson` converte item a item e descarta o que lançar
  (`TypeError`/`FormatException`); corpo sem `data` lista continua virando
  `invalidResponse` → `ServerFailure` (CB-005).
- **Rationale**: caso de borda da spec ("um Reel isolado com campos faltando é descartado").

## Dependências

Nenhuma nova. Usa `dio` (via `ApiClient`), `fpdart`, `provider`, `get_it`, `go_router`,
`easy_localization`, `lucide_icons_flutter` e o `ExternalLauncherService` da feature 007.
