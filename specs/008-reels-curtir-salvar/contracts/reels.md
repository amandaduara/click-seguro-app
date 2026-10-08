# Contrato: Reels, curtir e salvar

Base: `https://clickseguro-api.onrender.com/api/v1` (ver `EnvironmentConfig`). Linhas do
[api-contract.md](../../../.specify/memory/api-contract.md), seção "Notícias e Reels".

## `GET /app/news/reels` ✅ (conferido em 2026-10-08, research R0)

Token opcional (visitante chama sem).

| Parâmetro | Valor |
|---|---|
| `limit` | 10 |
| `cursor` | `nextCursor` da parte anterior; ausente na 1ª |

```json
{
  "data": [{
    "id": "cmuywjppz0001fo1slem3p1zr",
    "title": "Banco não pede senha, token ou código por telefone",
    "source": "Banco Central do Brasil",
    "sourceUrl": "https://www.bcb.gov.br/",
    "isHighlight": false,
    "content": "Nenhum banco liga pedindo senha…",
    "imageUrl": "https://res.cloudinary.com/…",
    "originalPublishedAt": "2026-09-27T00:13:16.345Z",
    "publishedAt": "2026-10-08T02:16:03.253Z",
    "createdAt": "2026-10-08T02:13:17.687Z",
    "likesCount": 0,
    "categories": [{ "id": "…", "name": "Segurança Bancária", "slug": "seguranca-bancaria" }],
    "interaction": { "isSaved": false }
  }],
  "nextCursor": "WyJjbXV5…" 
}
```

- `nextCursor: null` → fim.
- `interaction` pode faltar (tratar como `isSaved: false`); **não há `isLiked`**.
- Cursor inválido devolve 200 com a 1ª parte (não 400): a deduplicação por `id` cobre.

## `POST /app/news/{id}/like` 🧪 (token obrigatório)

Sem corpo. `200 → { "liked": true, "likesCount": 42 }` (alterna).

## `POST /app/news/{id}/save` 🧪 (token obrigatório)

Sem corpo. `200 → { "saved": true }` (alterna).

## Erros

| Situação | Resposta | App |
|---|---|---|
| Sem token | 401 `TOKEN_NOT_PROVIDED` (conferido) | nunca acontece: visitante vê o convite antes (RN-003) |
| Token vencido | 401 → renovação do `ApiClient` (feature 002) | se recusada, `UnauthorizedFailure`; estado revertido |
| Notícia removida | 404 `NEWS_NOT_FOUND` | `NewsNotFoundFailure` → "Notícia não encontrada" |
| Sem internet / timeout | — | `ConnectionFailure` (CB-002) |
| 5xx / corpo inválido | — | `ServerFailure` (CB-004, CB-005) |
