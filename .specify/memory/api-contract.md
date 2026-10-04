# SafeNews — Contrato da API

**Versão**: 1.0.1 | **Criado em**: 2026-09-26 | **Última alteração**: 2026-10-03

**Fonte da verdade**: [openapi.json](openapi.json) (OpenAPI 3.0 exportado da Click Seguro API,
recebido em 2026-10-03). Este arquivo é o **resumo do que o app usa**, com as decisões de
produto tomadas em cima da API real. Em caso de dúvida sobre campo ou código de erro, vale o
`openapi.json`. Antes de implementar a camada `data/` de uma feature, confira a linha aqui e o
schema lá (Passo 0 do [guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md)).

Legenda: ✅ confirmado no OpenAPI · 🧪 confirmado no OpenAPI, falta testar contra o servidor
real · ❌ não existe na API (ver alternativa) · ⏸️ existe na API, fora da v1

> O OpenAPI descreve a API, mas ainda não chamamos o servidor de verdade. Por isso tudo começa
> como 🧪. A pessoa dona da tarefa troca para ✅ depois do primeiro request real que funcionar.

## Convenções gerais

- **URL base**: `--dart-define=API_URL=https://clickseguro-api.onrender.com/api/v1` (servidor de
  desenvolvimento no Render, plano gratuito: depois de parado, a 1ª resposta leva ~40 s; por isso o
  `ApiClient` espera até 60 s pela resposta e as telas mostram "Conectando ao servidor…" após 5 s). Os caminhos abaixo são relativos a
  `/api/v1` (o datasource chama `/auth/app/login`, não `/api/v1/auth/app/login`).
- **Autenticação**: `Authorization: Bearer <accessToken>`.
- **Endpoints de auth opcional** (marcados "opcional"): funcionam sem token. Com token, trazem o
  estado do usuário (curtido, salvo, lido, progresso). Visitante MUST chamar **sem** token. Um
  token inválido enviado gera 401 `TOKEN_INVALID`.
- **Corpo de erro**: `{ "code": "CODIGO_DE_NEGOCIO", "message": "..." }`. O `ApiClient` MUST ler
  `code` em `ApiException.errorCode`. Hoje ele lê `error` (correção na tarefa F0.2).
  - Erro de validação (400), confirmado em 2026-10-03: `{ code, message, statusCode, errors, path,
    timestamp }`, com `errors: [{code, message, path}]`. Tem `code` no topo, então chega como
    `errorCode`; o app valida antes e não depende disso.
- **Datas**: ISO-8601 UTC.
- **Paginação por página**: `?page=1&limit=20` (limit ≤ 100). Resposta `{ data: [], meta }`, com
  `meta = { page, limit, total, totalPages, hasNextPage, hasPreviousPage }`. Fim da lista =
  `meta.hasNextPage == false`.
- **Paginação por cursor** (feed e reels): `?cursor=<opaco>&limit=N`. Resposta com `nextCursor`;
  `null` = fim. Cursor inválido → 400 `INVALID_CURSOR`.
- **IDs** são CUID (strings). Não fazer suposição de formato no app.

## Sessão e tokens

- Login devolve **dois tokens**: `accessToken` e `refreshToken`. Os dois MUST ser guardados no
  `SecureStorageService` (RNF-007).
- **Renovação existe**: `POST /auth/app/refresh` `{refreshToken}` → novo par de tokens.
  Confirmado: o refresh token **muda a cada renovação e o anterior passa a ser recusado** (401
  `TOKEN_INVALID`), por isso a renovação é única e compartilhada (feature 002).
- Regra do `ApiClient` para 401 em request **com** token (tarefa F0.2):
  1. `errorCode` = `INVALID_CREDENTIALS` (senha atual errada no alterar senha) → **não** mexe na
     sessão, só devolve o erro.
  2. Outros 401 → tenta **uma** renovação. Deu certo → salva o novo par e repete o request
     original uma vez. Falhou → `expire()` (CB-003).
- 401 em request **sem** token (login, cadastro) nunca mexe na sessão.

## Endpoints usados na v1

### Autenticação — A2 (módulo `authentication`)

| Status | Método e caminho | Auth | Uso | Erros que a UI distingue |
|---|---|---|---|---|
| ✅ | `POST /auth/app/register` `{name, email, password}` → 201 `{name, email}` | não | RF-003 | 409 `USER_EMAIL_ALREADY_EXISTS` |
| ✅ | `POST /auth/app/login` `{email, password}` → `{accessToken, refreshToken}` | não | RF-004 | 401 `INVALID_CREDENTIALS` |
| ✅ | `POST /auth/app/refresh` `{refreshToken}` → `{accessToken, refreshToken}` | não | RF-007 | 401 `TOKEN_INVALID` → `expire()` |
| ✅ | `GET /users/me` → `profile` | sim | RF-007, RF-009 (nome), RF-035 | 401, 404 `USER_NOT_FOUND` (conta desativada → tratar como sessão encerrada) |
| 🧪 | `POST /auth/forgot-password` `{email}` → 204 | não | RF-006 passo 1 | sempre 204 (não revela se o e-mail existe). ⚠️ 2026-10-04: com e-mail **cadastrado** levou 123 s (o servidor envia o e-mail antes de responder); sem conta, 2 s. Passa do tempo de espera do app (60 s) |
| ✅ | `POST /auth/forgot-password/verify` `{email, code}` → 204 | não | RF-006 passo 2 | 401 `INVALID_RECOVERY_CODE` |
| 🧪 | `POST /auth/forgot-password/reset` `{email, code, newPassword}` → 204 | não | RF-006 passo 3 | sempre 204, por isso o passo 2 é obrigatório antes |

- **Cadastro não devolve token.** Fluxo do `AuthRepositoryImpl.register`: `register` → `login`
  com as mesmas credenciais → `GET /users/me` → `saveSession`.
- **Login não devolve o usuário.** Fluxo do `login`: `login` → `GET /users/me` (com o token
  recém-recebido, via `ApiClient.get(authToken:)`, feature 003) → papel `USER`? → `saveSession`.
- O token não traz `id` utilizável no app. A sessão guarda `name`/`email` do `/users/me`.

`profile` (`GetProfileResponseDto`): `{ name, email, phone?, avatarUrl?, role, receiveNotifications }`.
`role` = `USER | PUBLISHER | ADMIN`. O app só aceita `USER`; outro papel no login → tratar como
credencial inválida (essas contas são do CMS).

Validação (RN-001, igual ao backend): `name` 6–150; `email` ≤ 255 e formato válido; `password`
8–64 com maiúscula, minúscula, número e caractere especial; `code` ≥ 6.

### Notícias e Reels — A3, A4, A5 (módulo `news`)

| Status | Método e caminho | Auth | Uso |
|---|---|---|---|
| 🧪 | `GET /app/news/feed?cursor&limit` → `{highlights[], recommended[], recent: {data[], nextCursor}}` | opcional | RF-009, RF-010 (feed sem filtro) |
| 🧪 | `GET /app/news?page&limit&category=<slug>&search&startDate&endDate&sortBy&sortOrder` → `{data[], meta}` | opcional | RF-009 filtro por categoria, RF-011 busca |
| 🧪 | `GET /categories` → `category[]` | não | chips de filtro do feed |
| 🧪 | `GET /app/news/reels?cursor&limit` (limit ≤ 50) → `{data[], nextCursor}` | opcional | RF-013 e carrossel do feed |
| 🧪 | `GET /app/news/{id}` → `newsDetail` | opcional | RF-014, RF-018 |
| 🧪 | `POST /app/news/{id}/like` → `{liked, likesCount}` (alterna) | sim | RF-019 curtir |
| 🧪 | `POST /app/news/{id}/save` → `{saved}` (alterna) | sim | RF-019 salvar |
| 🧪 | `POST /app/news/{id}/read` → 204 (idempotente) | sim | registra leitura ao abrir o detalhe (cadastrado) |
| 🧪 | `GET /users/me/news/saved?page&limit` → `{data[], meta}` | sim | lista de salvas, cache offline (RNF-002), contagem no perfil |

Erros: 404 `NEWS_NOT_FOUND` no detalhe/like/save → "Notícia não encontrada".

`newsItem` (feed, lista): `{ id, title, source, sourceUrl, imageUrl?, originalPublishedAt,
publishedAt?, createdAt, isHighlight, categories: [{id, name, slug}], interaction?: {isLiked,
isSaved, isRead} }`. **Não há `summary`**: o card mostra título, fonte, data e categorias.

`reelItem`: `newsItem` + `{ content, likesCount, interaction?: {isSaved} }`. O resumo da tela de
Reels é um trecho de `content` cortado no app. O reel **não traz `isLiked`**: o ícone começa
desmarcado e passa a refletir o `liked` devolvido pelo toggle.

`newsDetail`: `newsItem` + `{ content, likesCount, readsCount, suggestedModule?: {id, title,
description, iconUrl?, lessonsCount} }`. A API diz que `suggestedModule` vem "se autenticado".
Para o visitante, o bloco de atividade relacionada (RF-018) fica oculto. ⚠️ Confirmar no
servidor se ele vem também sem token.

- **Selo de veracidade: ❌ não existe na API.** Decisão (2026-10-03): o app exibe as
  **categorias** da notícia no lugar do selo (RF-012 revisado).
- **Data exibida**: `originalPublishedAt` (data da fonte original). `publishedAt` é a data em
  que entrou no app.
- Feed com categoria ou busca usa `/app/news` (paginação por página). Sem filtro, usa
  `/app/news/feed` (cursor). As seções `highlights` e `recommended` só aparecem na 1ª carga.
  `recommended` vem vazio para o visitante.

`category`: `{ id, name, slug, description?, isActive, createdAt }`. O filtro usa o `slug`.

### Alertas — A6 (módulo `notifications`)

**❌ A API não tem endpoints de notificação.** Decisão (2026-10-03): **alertas locais**. O
próprio app gera os alertas a partir das notícias novas, sem backend:

| Status | Método e caminho | Auth | Uso |
|---|---|---|---|
| 🧪 | `GET /app/news?startDate=<última verificação>&sortBy=publishedAt&sortOrder=desc&limit=20` | opcional | buscar notícias publicadas desde a última verificação (RF-020) |

- O módulo `notifications` tem **datasource próprio** para essa chamada. Não importa o `news`
  (regra de dependência do plan §1.3).
- Os alertas, a flag de lido e o horário da última verificação ficam no `LocalCacheService`.
- O switch "Receber alertas" usa `receiveNotifications` do `PATCH /users/me`. Desligado →
  nenhum alerta novo é gerado.

### Atividades — B1 a B4 (módulo `activities`)

| Status | Método e caminho | Auth | Uso |
|---|---|---|---|
| 🧪 | `GET /app/educational/modules` → `{modules[], totalLessonsCompleted, totalLessonsAvailable}` | opcional | RF-023 |
| 🧪 | `GET /app/educational/modules/{moduleId}` → `moduleDetail` | opcional | RF-024, RF-025 |
| 🧪 | `POST /app/educational/modules/{moduleId}/lessons/{lessonId}/answer` `{selectedOptionId}` → `{isCorrect, correctOptionId, explanation?}` | opcional | RF-026, RF-028 |

Erros: 404 `EDUCATIONAL_MODULE_NOT_FOUND`, 404 `EDUCATIONAL_LESSON_NOT_FOUND`,
400 `EDUCATIONAL_INVALID_OPTION`.

`moduleSummary`: `{ id, title, description, order, iconUrl?, lessonsCount, completedCount,
progressPercent }` (ordenados por `order`; progresso zerado sem token).

`moduleDetail`: `{ id, title, description, order, iconUrl?, lessonsCount, lessons: [lesson],
progress: {completedCount, progressPercent, score, totalScore, isCompleted} }`.

`lesson`: `{ id, order, question, explanation?, imageUrl?, options: [{id, text}], isCompleted }`.

**Modelo de atividade da API (decisão 2026-10-03: adotado):**
- Cada **lição é uma pergunta de múltipla escolha** com exatamente uma opção correta. Não há
  lição teórica separada nem outros tipos de exercício.
- A **correção é do servidor**: o app não recebe `isCorrect` das opções, envia a escolha e
  recebe o resultado com a explicação.
- As opções **já vêm embaralhadas** a cada request (RF-027 atendido pela API).
- A **pontuação é do servidor**: `progress.score`/`totalScore`, considerando a resposta **mais
  recente** de cada lição (não a melhor).
- Sem token, `answer` corrige mas **não salva**. O progresso do visitante fica em memória
  (RN-006).

### Perfil e conta — B7, B8 (módulos `profile`, `settings`)

| Status | Método e caminho | Auth | Uso | Erros |
|---|---|---|---|---|
| 🧪 | `GET /users/me` → `profile` | sim | RF-035 | 404 `USER_NOT_FOUND` |
| 🧪 | `PATCH /users/me` `{name?, email?, phone?, receiveNotifications?}` → 204 | sim | RF-036, switch de alertas | 409 `USER_EMAIL_ALREADY_EXISTS` |
| 🧪 | `POST /users/me/avatar` multipart, campo `avatar` (JPEG/PNG/WebP ≤ 5 MB) → `{avatarUrl}` | sim | RF-036 | 400 arquivo inválido, 500 `UPLOAD_FAILED` |
| 🧪 | `DELETE /users/me/avatar` → 204 | sim | RF-036 remover foto | 500 `DELETE_FAILED` |
| ✅ | `PATCH /users/me/change-password` `{currentPassword, newPassword}` → 204 | sim | RF-037 | 401 `INVALID_CREDENTIALS` (senha atual errada, **não** expira a sessão), 409 `USER_NEW_PASSWORD_EQUALS_OLD` |
| 🧪 | `GET /app/educational/modules` | sim | estatísticas do perfil (módulos concluídos, lições) | — |
| 🧪 | `GET /users/me/news/saved?limit=1` → `meta.total` | sim | estatística "notícias salvas" | — |

- `phone` no formato `+55` + 10 ou 11 dígitos (`^\+55\d{10,11}$`).
- **❌ Não há endpoint de estatísticas, conquistas ou níveis.** Decisão: o `profile` monta as
  estatísticas com as duas últimas chamadas acima (datasource próprio, sem importar outros
  módulos), e as **faixas de nível (RN-008) e as conquistas são regras fixas no app**.

### Sem API (local por decisão de produto)

| Dado | Onde fica | Motivo |
|---|---|---|
| Contatos oficiais da central de ajuda | `assets/data/official_contacts.json` | Decisão (2026-10-03): ficam no front. Funcionam offline numa emergência (RNF-002) |
| Contatos pessoais e fotos | `shared_preferences` + diretório de documentos do app | LGPD, nunca saem do aparelho (RN-007, RNF-008) |
| Alertas, flag de lido e última verificação | `shared_preferences` | não há API de notificações |
| Preferências de acessibilidade | `shared_preferences` | RF-041 |
| Flag de onboarding visto | `shared_preferences` (já implementado) | RN-004 |
| `accessToken` + `refreshToken` | `flutter_secure_storage` | RNF-007 |

## Existe na API, fora da v1 (⏸️)

| Endpoint | Motivo |
|---|---|
| `GET /app/official-contacts?type` | contatos oficiais ficam no asset na v1. Pode alimentar o asset ou uma sincronização na v2 |
| `POST /app/ai/analyze`, `POST /app/ai/analyze/image`, `POST /app/ai/chat`, `GET /app/ai/history` | IA (análise de mensagem suspeita e chat) adiada para a v2 |
| `DELETE /users/me/deactivate` | desativar conta: v2 |
| `GET /users/me/news/liked`, `GET /users/me/news/read` | sem tela na v1 |
| Tudo em `/cms/*`, `/auth/cms/*`, `/users/cms/*` | painel administrativo (outro projeto) |

## Changelog

- **1.0.1 (2026-10-03)**: autenticação confirmada no servidor real (cadastro, login, `/users/me`,
  renovação com rotação, código de recuperação inválido, senha atual errada); URL do servidor;
  formato real do 400; tempo de inicialização do Render. Envio do código e redefinição de senha
  seguem 🧪 (exigem um e-mail real).

- **1.0.0 (2026-10-03)**: contrato reescrito a partir do OpenAPI real. Caminhos com
  `/api/v1` e `/app/`; erro em `code`; par de tokens com renovação; recuperação de senha em 3
  passos; curtir/salvar como alternância; feed com destaques/recomendados/recentes por cursor.
  Removidos veracidade (sem campo na API) e notificações remotas (viraram alertas locais).
  Atividades no modelo da API (pergunta única por lição, correção no servidor). Perfil sem
  estatísticas na API (montadas no app). Contatos oficiais continuam locais; IA fora da v1.
- **0.1.0 (2026-09-26)**: rascunho derivado da especificação v2.0.0.
