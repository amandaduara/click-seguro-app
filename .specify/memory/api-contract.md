# SafeNews — Contrato esperado da API

**Versão**: 0.1.0 (rascunho) | **Criado em**: 2026-09-26

**Status**: ⚠️ **A CONFIRMAR COM A API REAL.** Este arquivo lista o que o app precisa, derivado
da [specification.md](specification.md) v2.0.0. Os caminhos, campos e códigos de erro abaixo são
uma **proposta**. Antes de implementar a camada `data/` de uma feature, a pessoa responsável MUST
confirmar o endpoint na API real e atualizar a linha correspondente (Passo 0 do
[guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md)).

Legenda de status: ⚠️ a confirmar · ✅ confirmado · ❌ não existe na API (ver alternativa)

## Convenções gerais (a confirmar)

- URL base via `--dart-define=API_URL=...`.
- Autenticação: `Authorization: Bearer <token>` (o `ApiClient` envia quando `requiresAuth: true`).
- Corpo de erro: `{ "statusCode": 409, "error": "CODIGO_DE_NEGOCIO", "message": "..." }`. O
  `ApiClient` lê `error` em `ApiException.errorCode`.
- Datas em ISO-8601 (UTC). Paginação por `?page=N&pageSize=M`. A resposta indica o fim da lista
  (`hasNext` ou lista menor que `pageSize`).

## Endpoints

### Autenticação — trilha A2 (módulo `authentication`)

| Status | Método e caminho | Auth | Uso | Erros que a UI distingue |
|---|---|---|---|---|
| ⚠️ | `POST /auth/register` `{name, email, password}` → `{token, user}` | não | RF-003 | 409 `EMAIL_ALREADY_EXISTS` |
| ⚠️ | `POST /auth/login` `{email, password}` → `{token, user}` | não | RF-004 | 401 `INVALID_CREDENTIALS` |
| ⚠️ | `POST /auth/forgot-password` `{email}` → 204 | não | RF-006 | 404 (tratar como sucesso, sem revelar se o e-mail existe) |
| ⚠️ | `GET /users/me` → `user` | sim | RF-007 (restaurar sessão) | 401 |

`user`: `{ id, name, email, avatarUrl?, level? }`

> Atenção: um 401 do `/auth/login` é credencial inválida, não sessão expirada. O
> `AuthRepositoryImpl` MUST tratar esse caso antes do `toFailure()` padrão (o `ApiClient` chama
> `logout()` em todo 401, o que é inofensivo aqui porque ainda não há sessão).

### Notícias e Reels — trilhas A3, A4, A5 (módulo `news`)

| Status | Método e caminho | Auth | Uso |
|---|---|---|---|
| ⚠️ | `GET /news?page&pageSize&category&q` → `news[]` | opcional | RF-009 a RF-012 |
| ⚠️ | `GET /news/categories` → `[{id, name}]` | não | filtros do feed |
| ⚠️ | `GET /news/{id}` → `newsDetail` | opcional | RF-014 |
| ⚠️ | `GET /reels?page` → `news[]` (ou reutilizar `/news?format=reel`) | opcional | RF-013 |
| ⚠️ | `GET /me/favorites` → `news[]` | sim | RF-019 e notícias salvas offline |
| ⚠️ | `PUT /me/favorites/{newsId}` / `DELETE /me/favorites/{newsId}` | sim | RF-019 |
| ⚠️ | `PUT /news/{id}/like` / `DELETE /news/{id}/like` | sim | RF-019 (curtir Reel) |

`news`: `{ id, title, summary, imageUrl, category, veracityStatus, publishedAt, isFavorite?, isLiked? }`
`newsDetail`: `news` + `{ body, sourceName, sourceUrl, author?, relatedModuleIds: [] }`
`veracityStatus`: `VERIFIED | UNVERIFIED | UNDER_REVIEW | FAKE` (valor desconhecido → `unverified`, RN-002)

### Notificações — trilha A6 (módulo `notifications`)

| Status | Método e caminho | Auth | Uso |
|---|---|---|---|
| ⚠️ | `GET /me/notifications?page` → `notification[]` | sim | RF-020 |
| ⚠️ | `GET /me/notifications/unread-count` → `{count}` | sim | RF-021 |
| ⚠️ | `PATCH /me/notifications/{id}/read` | sim | RF-022 |
| ⚠️ | `PATCH /me/notifications/read-all` | sim | RF-022 |

`notification`: `{ id, title, body, createdAt, isRead, newsId? }`

### Atividades — trilhas B1 a B4 (módulo `activities`)

| Status | Método e caminho | Auth | Uso |
|---|---|---|---|
| ⚠️ | `GET /modules` → `moduleSummary[]` | opcional | RF-023 |
| ⚠️ | `GET /modules/{id}` → `moduleDetail` (lições + exercícios) | opcional | RF-024, RF-025 |
| ⚠️ | `GET /me/progress` → `moduleProgress[]` | sim | RF-023, RF-035 |
| ⚠️ | `PUT /me/progress/{moduleId}` `{readLessonIds, bestScore, completed}` | sim | RF-024, RF-028 |

`moduleSummary`: `{ id, title, description, iconName, lessonCount, exerciseCount }`
`moduleDetail`: `moduleSummary` + `{ lessons: [{id, title, body}], exercises: [exercise] }`
`exercise`: `{ id, type, prompt, explanation, ... }`, em que `type` é
`MULTIPLE_CHOICE | TRUE_FALSE | CHECKLIST | SCENARIO | ORDERING`:
- `MULTIPLE_CHOICE` / `SCENARIO`: `options: [{id, text}]`, `correctOptionId`
- `TRUE_FALSE`: `statement`, `answer: bool`
- `CHECKLIST`: `items: [{id, text, isCorrect}]` (marcar todos os corretos)
- `ORDERING`: `steps: [{id, text}]` na ordem correta (o app embaralha)

`moduleProgress`: `{ moduleId, readLessonIds: [], bestScore: 0..1, completed }`

> Visitante: o progresso fica só em memória (RN-006), sem chamada a `/me/progress`.

### Perfil — trilhas B7 e B8 (módulo `profile`)

| Status | Método e caminho | Auth | Uso |
|---|---|---|---|
| ⚠️ | `GET /me/profile` → `{user, stats, achievements[], levels[]}` | sim | RF-035, RN-008 |
| ⚠️ | `PATCH /me/profile` `{name}` | sim | RF-036 |
| ⚠️ | `PUT /me/avatar` (multipart) → `{avatarUrl}` | sim | RF-036. Se não existir, a foto de perfil fica só local (como os contatos) |
| ⚠️ | `POST /me/change-password` `{currentPassword, newPassword}` | sim | RF-037 (Segurança) — 400 `WRONG_PASSWORD` |

`stats`: `{ completedModules, savedNews, totalScore }` ·
`achievement`: `{ id, title, description, iconName, unlockedAt? }`

### Sem API (local por decisão de produto)

| Dado | Onde fica | Motivo |
|---|---|---|
| Contatos oficiais da central de ajuda | `assets/data/official_contacts.json` | Precisa funcionar offline numa emergência (RNF-002) |
| Contatos pessoais e fotos | `shared_preferences` + diretório de documentos do app | LGPD, nunca saem do aparelho (RN-007, RNF-008) |
| Preferências de acessibilidade | `shared_preferences` | RF-041 |
| Flag de onboarding visto | `shared_preferences` (já implementado) | RN-004 |
| Token de sessão | `flutter_secure_storage` | RNF-007 |
