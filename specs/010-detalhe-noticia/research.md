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
- **Não conferido**: a ordem da lista de salvas com mais de uma notícia (a conta de teste tinha
  só uma). Fica para o teste no aparelho; o app usa a ordem do serviço.
- **Alternatives considered**: usar a conta pessoal do usuário — descartado para não mexer em
  dados reais; a conta de teste foi pedida pelo usuário.
