# Contrato: alertas locais

A API **não tem** endpoints de notificação (decisão de 2026-10-03, [contrato da
API](../../../.specify/memory/api-contract.md) "Alertas — A6"). O módulo `notifications` usa dois
endpoints existentes, com datasource próprio, mais um registro local. Formato dos endpoints
conforme o `openapi.json` do projeto (`.specify/memory/openapi.json`); o que ele não diz foi
conferido no servidor de desenvolvimento em 2026-10-09 e está em [research.md](../research.md) R0 (✅). Caminhos relativos a
`API_URL` (`.../api/v1`). Toda chamada passa pelo `ApiClient`.

## `GET /app/news` — notícias publicadas desde a última verificação

- **Quem chama**: só com conta (o app não chama como visitante, FR-007). Com token a resposta traz
  `interaction`; o alerta não usa.
- **Query** (✅ conferida no servidor de desenvolvimento, T002):

| Parâmetro | Valor | Observação |
|---|---|---|
| `startDate` | `since` em ISO-8601 UTC (`2026-10-09T15:00:00.000Z`) | `since = max(lastCheckAt, agora − 30 dias)`. ✅ Filtra por **`publishedAt`** (não pela original), "maior ou igual", precisão de ms; formato inválido → 400 `VALIDATION_ERROR` |
| `sortBy` | `publishedAt` | |
| `sortOrder` | `desc` | |
| `limit` | `50` | igual ao teto de alertas (R6); o contrato anterior dizia 20; máximo aceito 100 (101 → 400) |
| `page` | `1` | sem paginar |

- **200** `PaginatedNewsAppResponseDto`:

```json
{
  "data": [{
    "id": "cmuywlly30007fo1sdm9bb843",
    "title": "…", "source": "…", "sourceUrl": "https://…",
    "publishedAt": "2026-10-09T14:10:00.000Z", "originalPublishedAt": "2026-10-01T00:00:00.000Z",
    "createdAt": "…", "isHighlight": false, "categories": [], "interaction": {}
  }],
  "meta": { "page": 1, "limit": 50, "total": 1, "totalPages": 1, "hasNextPage": false, "hasPreviousPage": false }
}
```

- ✅ `publishedAt` veio em todas as 12 notícias do servidor; o fallback `originalPublishedAt`
  fica como rede de segurança. Só `id`, `title`, `source` e `publishedAt` (ou `originalPublishedAt`) interessam. Item sem
  algum deles é **ignorado** (R9). `data` ausente ou que não é lista → `ServerFailure`.
- **Conexão/timeout** → `ConnectionFailure` (a conferência falha em silêncio, FR-005). **401** →
  tratado pelo `ApiClient` (renova uma vez; recusada → `expire()`).
- O app **sempre** filtra de novo (`publishedAt > lastCheckAt`) e remove repetidos por `newsId`
  (R0). ✅ O servidor usa ≥: a notícia com `publishedAt == lastCheckAt` volta na resposta e o app a descarta.

## `GET /users/me` — "Receber alertas"

- **Quem chama**: só com conta, uma vez por conferência (depois da primeira), antes das notícias.
- **200** (✅ conferido): `{ name, email, phone, avatarUrl, role, receiveNotifications }`. O app lê só
  `receiveNotifications`; ausente → `true`.
- `false` → nenhum alerta novo, mas `lastCheckAt` avança (FR-006). Falha → a conferência falha
  inteira (sem gravar).
- **Não** altera a chave: `PATCH /users/me {receiveNotifications}` é da B7
  (`SetReceiveAlertsUseCase`). ✅ Conferido: o `PATCH` responde 204 e o `GET` seguinte mostra o novo valor.

## Registro local

`notifications_alerts_v1` no `LocalCacheService` (`shared_preferences`), um por aparelho, com o
dono dentro. Formato e regras em [data-model.md](../data-model.md). Apagado ao sair da conta ou
quando a sessão vence; ignorado se o dono for outro.

## Rotas do app

| Caminho | Tela | Observação |
|---|---|---|
| `/notifications` | Alertas | já existia (F0.9, provisória); sobre as abas; também aberta pela linha "Alertas" de Configurações (B8) |
| `/news/:id` | Detalhe da notícia | já existia (feature 010); o alerta abre por caminho (`context.push('/news/<newsId>')`), sem importar `news` |
| `/profile/edit` | Editar perfil | da B7; o botão "Ligar em Editar perfil" só abre a rota |

## Contrato visual do sino

| Situação | Aparência | Rótulo para leitor de tela |
|---|---|---|
| 0 não lidos, ou visitante | só o sino (48 dp) | "Alertas" |
| N ≥ 1 não lidos | sino + círculo `primary` de pelo menos 24 dp no canto superior direito, número em branco e negrito | "Alertas, N novos" ("Alerts, N new") |
