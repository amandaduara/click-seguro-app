# Contrato: detalhe, leitura e salvas

Conferido no servidor em 2026-10-09 ([research.md](../research.md) R0). Caminhos relativos a
`API_URL` (`.../api/v1`). Toda chamada passa pelo `ApiClient` (token, renovação, erros tipados).

## `GET /app/news/{id}` — detalhe

- **Quem chama**: todos. Visitante sem token.
- **200**: `newsDetail`

```json
{
  "id": "cmuywlly30007fo1sdm9bb843",
  "title": "…", "content": "…", "source": "…", "sourceUrl": "https://…",
  "isHighlight": false, "imageUrl": "https://…" ,
  "likesCount": 0, "readsCount": 1,
  "publishedAt": "2026-10-08T02:16:03.253Z", "originalPublishedAt": "2026-09-27T00:13:16.345Z",
  "createdAt": "2026-10-08T02:13:17.687Z",
  "categories": [{ "id": "…", "name": "Golpes no WhatsApp", "slug": "golpes-no-whatsapp" }],
  "interaction": { "isLiked": false, "isSaved": false, "isRead": false },
  "suggestedModule": { "id": "…", "title": "Golpes no WhatsApp", "description": "…", "iconUrl": "https://…", "lessonsCount": 3 }
}
```

- `suggestedModule` pode ser `null` (vem também sem token). `interaction` sem token: tudo `false`.
- **404** `NEWS_NOT_FOUND` → `NewsNotFoundFailure` → "Notícia não encontrada" (sem "Tentar
  novamente").
- **Conexão/timeout** → cópia do aparelho, se houver (`isFromCache = true`); senão a falha.

## `POST /app/news/{id}/read` — registrar leitura

- **Quem chama**: só com conta, uma vez por abertura com detalhe vindo do servidor.
- **204** sem corpo; idempotente. Sem token → 401 `TOKEN_NOT_PROVIDED` (o app não chama).
- Resultado ignorado pela tela.

## `POST /app/news/{id}/save` — alternar salvar

- Já implementado na feature 008 (`ToggleSaveUseCase`). **200** `{ "saved": true | false }`.

## `GET /users/me/news/saved?page=<n>&limit=20` — notícias salvas

- **Quem chama**: só com conta. Sem token → 401 (o app não chama; mostra o convite).
- **200**:

```json
{
  "data": [{ "id": "…", "title": "…", "source": "…", "sourceUrl": "https://…", "imageUrl": "https://…",
             "publishedAt": "…", "originalPublishedAt": "…", "categories": [],
             "interaction": { "isLiked": false, "isSaved": true, "isRead": true } }],
  "meta": { "page": 1, "limit": 20, "total": 1, "totalPages": 1, "hasNextPage": false, "hasPreviousPage": false }
}
```

- Item sem `content`, `createdAt` e `isHighlight`. Fim da lista: `hasNextPage = false`.
- **Conexão/timeout na página 1** → cópia do aparelho, se houver.

## Rotas do app

| Caminho | Tela | Observação |
|---|---|---|
| `/news/saved` | Notícias salvas | **nova**; declarada antes de `/news/:id` (R1); entrada pelo Perfil na B7 |
| `/news/:id` | Detalhe | já existia (feature 005) |
| `/activities/:moduleId` | Módulo de atividades | já existia; o bloco de atividade relacionada só abre a rota |
