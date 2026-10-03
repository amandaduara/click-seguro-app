---

description: "Task list for feature 002: comunicação com a API real e renovação da sessão"
---

# Tasks: Comunicação com a API real e renovação da sessão

**Input**: Design documents from `/specs/002-apiclient-renovacao-sessao/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/api-client-and-session.md](contracts/api-client-and-session.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** A constituição (Seção III, TDD não negociável) exige que todo teste
seja escrito e **falhe** antes da implementação correspondente. Os testes usam Fakes à mão (sem
Mockito/mocktail), rodam offline e resetam o `GetIt` no `tearDown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Caminhos relativos à raiz do repositório. O app fica em `click_seguro_app/`, e os comandos
  `flutter` rodam dentro dessa pasta.
- Valores de token nos testes são fictícios (`'acesso-1'`, `'renovacao-1'`), nunca reais.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: confirmar a base antes de mudar contratos usados pelos testes da 001.

- [X] T001 Dentro de `click_seguro_app/`, rodar `flutter analyze` e `flutter test` e anotar a contagem de testes verdes (linha de base). Nenhum arquivo muda nesta tarefa. Se algo já estiver vermelho, parar e reportar antes de seguir

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: sessão v2, leitura de `code`, `CancelToken`, o `_send` re-executável e o adapter
falso por roteiro. Todas as histórias dependem disto ([R1](research.md), [R6](research.md),
[R9](research.md), [R10](research.md), [R13](research.md)).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 Em `click_seguro_app/test/modules/common/services/user_session_service_test.dart`, migrar todos os testes para o contrato v2 ([data-model](data-model.md)):
  - `saveSession(accessToken:, refreshToken:, email:, userName:)` no lugar de `saveSession(token:, userId:, userName:)`;
  - `session.accessToken`, `session.refreshToken` e `session.email` no lugar de `session.token` e `session.userId`;
  - registro esperado `{"status":"authenticated","accessToken":…,"refreshToken":…,"email":…,"userName":…}`;
  - o teste "rejeita vazios" cobre `accessToken`, `refreshToken` e `email` vazios (`ArgumentError`).

  Novos casos na lista de registros inválidos: `authenticated` sem `refreshToken`, sem `email`, e
  o **formato da 001** `{"status":"authenticated","token":"t","userId":"u"}`. Os três são
  apagados e deixam desconectado (FR-011). Mais um caso: `guest` com `refreshToken` → inválido.
- [X] T003 [P] Em `click_seguro_app/test/modules/common/api_client/fake_http_client_adapter.dart`, adicionar o modo por roteiro sem quebrar o modo atual:
  - `class FakeResponse { final int statusCode; final Object? body; final Duration delay; }`;
  - campo `FakeResponse Function(RequestOptions options)? responder`: quando definido, tem
    precedência sobre `statusCode`/`body`;
  - lista `final List<RequestOptions> requests` com todos os requests recebidos;
  - com `delay > Duration.zero`, esperar o atraso **ou** o `cancelFuture`, o que vier primeiro.
    Se o cancelamento vier antes, lançar
    `DioException.requestCancelled(requestOptions: options, reason: 'cancelado')`.
- [X] T004 Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`:
  - ajustar as chamadas existentes para `saveSession(accessToken: 'acesso-1', refreshToken: 'renovacao-1', email: 'maria@exemplo.com')`;
  - novo grupo `F0.2 código de erro`: corpo `{"code":"USER_EMAIL_ALREADY_EXISTS","message":"Email already registered"}` com 409 → `errorCode == 'USER_EMAIL_ALREADY_EXISTS'`; corpo antigo `{"error":"X"}` → `errorCode == null`;
  - novo grupo `F0.2 cancelamento`: `get('/app/news', cancelToken: token)` com o adapter
    atrasando 1 s e `token.cancel()` logo depois → `ApiException(cancelled)`. Com sessão
    conectada, conferir também que nenhum request para `/auth/app/refresh` foi feito e que a
    sessão continua `authenticated`.

### Implementação

- [X] T005 Em `click_seguro_app/lib/modules/common/services/user_session_service.dart`, aplicar o registro v2 (faz T002 passar):
  - renomear o campo `token` para `accessToken`;
  - adicionar `String? refreshToken` e `String? email`;
  - remover `userId`;
  - `saveSession({required String accessToken, required String refreshToken, required String email, String? userName})`
    lança `ArgumentError` se algum dos três obrigatórios vier vazio e grava
    `{"status":"authenticated","accessToken":…,"refreshToken":…,"email":…,"userName"?:…}`;
  - `_parseRecord`: `authenticated` só é válido com `accessToken`, `refreshToken` e `email`
    strings não vazias e `userName` nulo ou string. `guest` é inválido se tiver `token`,
    `accessToken` ou `refreshToken`;
  - `_setUnauthenticated` e `startGuestSession` zeram os três campos novos.

  Manter as garantias da 001 (notifica depois de preencher, nunca lança por falha de storage).
- [X] T006 Criar `click_seguro_app/lib/modules/common/api_client/api_error_codes.dart` com `abstract final class ApiErrorCodes { static const String invalidCredentials = 'INVALID_CREDENTIALS'; static const String userNotFound = 'USER_NOT_FOUND'; }` e um comentário dizendo que ali ficam só os códigos usados pelo `common` ([R9](research.md))
- [X] T007 Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, refatorar sem mudar regra de sessão (faz T004 passar):
  - `_makeOptions` lê `session.accessToken`;
  - novo método privado `_send(Future<Response> Function(Options options) call, {required bool requiresAuth})`.
    Ele monta as `Options` **a cada chamada** (pelo `_makeOptions`), executa `call`, captura
    `DioException` e devolve `ApiException`, como o `_safeRequest` faz hoje. Os métodos
    `get`/`post`/`put`/`delete` passam a usar `_send`, e o `_safeRequest` antigo é removido;
  - `get` ganha `CancelToken? cancelToken`, repassado ao `_dio.get`;
  - `_mapBadResponse` lê `errorCode` de `json['code']` (era `json['error']`) e só aceita
    `String`;
  - atualizar o dartdoc de `ApiException.errorCode` ("campo `code` do corpo").

  O `if (statusCode == 401) expire()` continua como está até a US1.

**Checkpoint**: `flutter test` verde, com a mesma contagem da T001 mais os testes novos. Sessão v2 e `code` funcionando.

---

## Phase 3: User Story 1 - Continuar usando o app quando a credencial vence (Priority: P1) 🎯 MVP

**Goal**: um pedido recusado por credencial vencida é renovado e repetido sem o usuário perceber, com uma única renovação para pedidos simultâneos (FR-002 a FR-005, FR-012).

**Independent Test**: com sessão cujo access token é recusado e cujo refresh token vale, um `get` autenticado termina com 200, o novo par fica salvo (inclusive depois de `restoreSession` num novo `UserSessionService` com o mesmo storage) e só houve um request de renovação.

### Tests for User Story 1 ⚠️

- [X] T008 [P] [US1] Em `click_seguro_app/test/modules/common/services/user_session_service_test.dart`, grupo `US1 replaceTokens`:
  - com sessão `authenticated` e `refreshToken == 'renovacao-1'`,
    `replaceTokens(previousRefreshToken: 'renovacao-1', accessToken: 'acesso-2', refreshToken: 'renovacao-2')`
    devolve `true`, atualiza memória e registro e **não** notifica `sessionStatus` (contar
    notificações com um listener);
  - com `previousRefreshToken` diferente do atual → `false`, sem mudança;
  - depois de `logout()` → `false`, e a sessão continua desconectada;
  - como visitante → `false`;
  - falha de escrita (`failOnWrite`) → devolve `true` e mantém em memória, sem lançar.
- [X] T009 [P] [US1] Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, grupo `US1 renovação`, usando o `responder` (T003). O servidor falso aceita `Bearer acesso-2` e recusa `Bearer acesso-1` com 401 `{"code":"TOKEN_INVALID"}`; `/auth/app/refresh` responde conforme o caso:
  1. refresh 200 `{accessToken:'acesso-2', refreshToken:'renovacao-2'}` → o `get('/users/me/news/saved')` devolve 200; a sessão fica com `acesso-2`/`renovacao-2`; o request de refresh foi `POST` com corpo `{"refreshToken":"renovacao-1"}` e **sem** header `Authorization`;
  2. refresh 401 `{"code":"TOKEN_INVALID"}` → `ApiException(unauthorized)`, sessão `unauthenticated` com `endReason == expired`;
  3. refresh com erro de conexão → `ApiException(connection)`, sessão continua `authenticated` com `acesso-1` (FR-004);
  4. refresh 500 → `ApiException(server)`, sessão mantida;
  5. 401 também no pedido repetido (servidor recusa `acesso-2`) → `expire()`, e só 1 request de refresh e 2 do pedido (SC-004);
  6. **concorrência (SC-002):** 5 `get` diferentes via `Future.wait`, com o refresh atrasado
     50 ms → os 5 terminam com 200 e há exatamente 1 request para `/auth/app/refresh`;
  7. **token já trocado:** o pedido sai com `acesso-1`, e antes da resposta 401 a sessão já tem
     `acesso-2` (simular chamando `replaceTokens` dentro do `responder`) → repete com `acesso-2`
     sem chamar o refresh;
  8. **logout durante a renovação (FR-012):** o `responder` do refresh chama
     `session.logout()` antes de devolver 200 → o pedido termina com
     `ApiException(unauthorized)`, a sessão continua desconectada com `endReason == userLogout`,
     e o pedido **não** foi repetido;

### Implementation for User Story 1

- [X] T010 [US1] Em `click_seguro_app/lib/modules/common/services/user_session_service.dart`, implementar `Future<bool> replaceTokens({required String previousRefreshToken, required String accessToken, required String refreshToken})`: só aplica se `isAuthenticated && this.refreshToken == previousRefreshToken`, atualiza os campos, regrava o registro v2 com `_safely` e devolve `true`; senão devolve `false`. Não altera `sessionStatus` (faz T008 passar)
- [X] T011 [US1] Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, implementar a renovação no `_send` (faz T009 passar; regras em [data-model "Decisão do ApiClient"](data-model.md) e [R1–R3](research.md)):
  - `static const String refreshPath = '/auth/app/refresh';`;
  - o `_send` guarda o token que **enviou**. Em `DioException` do tipo `badResponse` com 401
    (nesta história, **qualquer** 401; as exceções de "sem token" e `INVALID_CREDENTIALS` entram
    na T013, para que a T012 falhe primeiro):
    - se o token atual da sessão já é outro → repete uma vez;
    - senão aguarda `_renew()` (que devolve um `Future<bool>`): com `true`, repete uma vez;
      com `false`, devolve `unauthorized`;
    - se a repetição também receber 401 → `expire()` e `unauthorized`, sem nova renovação;
  - `Future<bool>? _renewal` compartilhado. `_renew()` reaproveita o Future em andamento,
    senão cria um com `_refreshTokens()` e zera o campo num `whenComplete`;
  - `_refreshTokens()`:
    - lê o `refreshToken` da sessão; se nulo, devolve `false` sem request;
    - faz `_dio.post(refreshPath, data: {'refreshToken': …})` **sem** `Authorization` e fora
      do `_send`;
    - 200 → `replaceTokens(previousRefreshToken: <lido>, …)` e devolve o resultado (`false` =
      sessão mudou, não repete);
    - 401 → `expire()` e devolve `false`;
    - outros erros → lança o `ApiException` mapeado, que vira o erro do pedido original
      (FR-004);
  - remover o `expire()` incondicional do `_mapBadResponse`: o 401 passa a ser decidido só
    no `_send`.

**Checkpoint**: US1 completa. Credencial vencida não derruba mais o usuário.

---

## Phase 4: User Story 2 - Errar a senha atual não desconecta (Priority: P1)

**Goal**: 401 `INVALID_CREDENTIALS` e 401 de pedidos sem token nunca mexem na sessão (FR-006, FR-007, CB-013).

**Independent Test**: com sessão conectada, um `patch` que recebe 401 `INVALID_CREDENTIALS` devolve `ApiException(unauthorized, errorCode: 'INVALID_CREDENTIALS')`, a sessão continua `authenticated` e nenhum refresh foi chamado.

### Tests for User Story 2 ⚠️

- [ ] T012 [US2] Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, grupo `US2 credenciais inválidas`:
  - sessão conectada + 401 `{"code":"INVALID_CREDENTIALS","message":"Invalid email or password"}`
    em `post('/users/me/change-password')` (a API real usa `PATCH`, que só entra na US5; para esta
    regra o método não importa) → `ApiException(unauthorized)` com
    `errorCode == ApiErrorCodes.invalidCredentials`, sessão `authenticated`, 0 requests de
    refresh (SC-003);
  - desconectado + 401 `INVALID_CREDENTIALS` em `post('/auth/app/login', requiresAuth: false)`
    → `unauthorized`, `endReason == null`, 0 refresh;
  - visitante (`startGuestSession`) + 401 sem `code` em `get('/app/news')` → `unauthorized`,
    continua visitante, 0 refresh;
  - conectado + `requiresAuth: false` + 401 sem `code` → sessão mantida, 0 refresh;
  - substituir o teste antigo "401 com sessão conectada encerra a sessão como expirada" pelo
    caso 2 da T009 (o comportamento agora passa pela renovação).

### Implementation for User Story 2

- [ ] T013 [US2] Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, no `_send`, só renovar ou expirar quando o request **enviou** `Authorization` (token não nulo no `_makeOptions`) **e** `code != ApiErrorCodes.invalidCredentials`; nos outros casos, devolver o `ApiException(unauthorized)` sem tocar na sessão (faz T012 passar). Atualizar o dartdoc de `ApiErrorType.unauthorized` ("401; a sessão só é encerrada pelo `ApiClient` quando a renovação falha ou o pedido repetido é recusado")

**Checkpoint**: US1 + US2. A A2 (login) e a B8 (troca de senha) já podem confiar no `errorCode`.

---

## Phase 5: User Story 3 - Sessão confirmada ao abrir o app (Priority: P2)

**Goal**: `SessionValidationService` confere a conta com prazo de 3 s; conta desativada encerra a sessão em qualquer pedido (FR-008, FR-008a, FR-009, CB-014).

**Independent Test**: com sessão salva, `validateStoredSession()` atualiza o nome quando o serviço responde 200, deixa desconectado com 404 `USER_NOT_FOUND`, mantém a sessão sem rede e devolve em até ~prazo quando o serviço demora.

### Tests for User Story 3 ⚠️

- [ ] T014 [P] [US3] Em `click_seguro_app/test/modules/common/services/user_session_service_test.dart`, grupo `US3 updateProfile`: conectado → `updateProfile(name: 'Maria Silva', email: 'maria@novo.com')` atualiza memória e registro (`accessToken`/`refreshToken` preservados); visitante e desconectado → nada muda e nada é gravado (`writeCalls` igual); falha de escrita não lança
- [ ] T015 [P] [US3] Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, grupo `US3 conta desativada (FR-008a)`: conectado + 404 `{"code":"USER_NOT_FOUND"}` em `get('/users/me/news/saved')` → `ApiException(client, statusCode: 404)` e sessão `unauthenticated` com `endReason == expired`; conectado + 404 `{"code":"NEWS_NOT_FOUND"}` → sessão mantida; visitante + 404 `USER_NOT_FOUND` → continua visitante
- [ ] T016 [P] [US3] Criar `click_seguro_app/test/modules/common/services/session_validation_service_test.dart`, com `ApiClient` sobre `FakeHttpClientAdapter`, sessão com `FakeSecureStorageService` registrada no `GetIt` e `SessionValidationService(apiClient, session, timeout: const Duration(milliseconds: 100))`:
  1. 200 `{"name":"Maria Silva","email":"maria@novo.com","role":"USER","receiveNotifications":true}` → `userName == 'Maria Silva'`, `email == 'maria@novo.com'`, continua `authenticated`;
  2. 404 `USER_NOT_FOUND` → `unauthenticated`;
  3. 401 + refresh 401 → `unauthenticated`;
  4. 401 + refresh 200 + repetição 200 → `authenticated`, com os tokens novos e o nome atualizado (história 3, cenário 4);
  5. erro de conexão → continua `authenticated` com o nome antigo;
  6. 500 → mantido;
  7. corpo inválido (`{"foo":1}`) → mantido, sem lançar;
  8. **prazo:** adapter com `delay: 1 s` → o `Future` completa em menos de 500 ms, a sessão é
     mantida e há só 1 request (cancelado). Esperar mais 1,1 s e conferir que o nome **não**
     mudou (resposta tardia ignorada);
  9. visitante e desconectado → 0 requests.

### Implementation for User Story 3

- [ ] T017 [US3] Em `click_seguro_app/lib/modules/common/services/user_session_service.dart`, implementar `Future<void> updateProfile({required String name, required String email})`: só age se `isAuthenticated`, atualiza `userName`/`email` e regrava o registro v2 com `_safely`, sem notificar `sessionStatus` (faz T014 passar)
- [ ] T018 [US3] Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, no `_send`: resposta 404 com `code == ApiErrorCodes.userNotFound` a um request que enviou token → `unawaited(session.expire())` antes de devolver o `ApiException` (faz T015 passar; [R5](research.md))
- [ ] T019 [US3] Criar `click_seguro_app/lib/modules/common/services/session_validation_service.dart` com `class SessionValidationService` conforme o [contrato](contracts/api-client-and-session.md) (faz T016 passar):
  - construtor `(ApiClient apiClient, UserSessionService session, {Duration timeout = const Duration(seconds: 3)})`;
  - `validateStoredSession()`:
    - retorna se `!session.isAuthenticated`;
    - cria um `CancelToken` e chama `apiClient.get('/users/me', cancelToken: …)` com
      `.timeout(timeout)`. No `TimeoutException`, chama `cancelToken.cancel()` e retorna;
    - com 200, lê `name` e `email` como `String` direto do `response.data` (sem model:
      `data is Map && data['name'] is String && data['email'] is String`) e chama
      `session.updateProfile`;
    - `ApiException` de qualquer tipo → retorna (o `ApiClient` já encerrou a sessão quando
      era o caso);
    - nunca lança. Constante `static const String mePath = '/users/me';`
- [ ] T020 [US3] Em `click_seguro_app/lib/modules/common/common_module.dart`, registrar `injector.registerLazySingleton(() => SessionValidationService(injector<ApiClient>(), injector<UserSessionService>()))` depois do `ApiClient`

**Checkpoint**: US3 pronta para a A1 ligar no `SplashController` (não ligar aqui; ver [R8](research.md)).

---

## Phase 6: User Story 4 - Mensagens de erro específicas do serviço (Priority: P3)

**Goal**: qualquer formato de erro vira um `ApiException` coerente, sem travar (FR-013, FR-014, FR-018).

**Independent Test**: os três formatos de corpo de erro (padrão `{code, message}`, Zod e HTML) produzem o `type`/`errorCode`/`message` esperados.

### Tests for User Story 4 ⚠️

- [ ] T021 [US4] Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, grupo `US4 formatos de erro`:
  - 400 Zod `{"statusCode":400,"message":"Validation failed","errors":[{"code":"custom","message":"…","path":["options"]}]}`
    → `type == client`, `errorCode == null`, `message == 'Validation failed'`;
  - 400 com `message` em lista (`{"message":["a","b"]}`) → não lança, `message` não vazia;
  - 502 com corpo HTML → `type == server`, `errorCode == null`;
  - 409 com `code` numérico (`{"code":409}`) → `errorCode == null`.

### Implementation for User Story 4

- [ ] T022 [US4] Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, no `_mapBadResponse`: `message` = `json['message']` se for `String`, senão `json['message']?.toString()`, senão `'Erro HTTP $statusCode'`; `errorCode` só quando `json['code'] is String` (faz T021 passar)
- [ ] T023 [P] [US4] Atualizar `click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md` (FR-018):
  - §4.1: `errorCode` vem de `code`; exemplo de corpo `{ "code": "...", "message": "..." }`;
    "401 já chama `logout()`" vira a regra de renovação e expiração do
    [contrato](contracts/api-client-and-session.md); repositories testam
    `ApiErrorCodes.invalidCredentials` antes do `toFailure()`;
  - novos métodos `patch`, `postMultipart` e `get(cancelToken:)`;
  - Passo 0: exemplo de erro com `code`;
  - caminhos com base `/api/v1` no `API_URL`.

---

## Phase 7: User Story 5 - Base para busca e envio de foto (Priority: P3)

**Goal**: `patch` e `postMultipart` disponíveis, com as mesmas regras de erro e renovação (FR-016, [R11](research.md), [R14](research.md)). O cancelamento já entrou na Phase 2.

**Independent Test**: `postMultipart` envia `multipart/form-data` com o arquivo no campo e tipo pedidos, e um 401 renovável repete o envio com sucesso; `patch` envia `PATCH` com o corpo JSON.

### Tests for User Story 5 ⚠️

- [ ] T024 [US5] Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, grupo `US5 patch e multipart`:
  - `patch('/users/me', data: {'name':'Maria Silva'})` → método `PATCH`, corpo JSON, `Authorization` com o token atual;
  - `postMultipart('/users/me/avatar', fieldName: 'avatar', filePath: <arquivo temporário criado com Directory.systemTemp.createTemp e 10 bytes>, contentType: 'image/png')` → método `POST`, `contentType` do request começa com `multipart/form-data`, `data` é `FormData` com um arquivo no campo `avatar` e `contentType` `image/png`;
  - `postMultipart` com 401 `TOKEN_INVALID` + refresh 200 → o segundo request também é multipart com o arquivo (um `FormData` **novo**, com instância diferente da primeira) e termina 200;
  - apagar o diretório temporário no `tearDown`.

### Implementation for User Story 5

- [ ] T025 [US5] Em `click_seguro_app/lib/modules/common/api_client/api_client.dart` (faz T024 passar):
  - `patch(String path, {dynamic data, bool requiresAuth = true})` via `_send`;
  - `postMultipart(String path, {required String fieldName, required String filePath, required String contentType, bool requiresAuth = true})`
    via `_send`. A função passada ao `_send` cria
    `FormData.fromMap({fieldName: await MultipartFile.fromFile(filePath, contentType: DioMediaType.parse(contentType))})`
    a cada execução e chama `_dio.post` com
    `options.copyWith(contentType: Headers.multipartFormDataContentType)`.

**Checkpoint**: as 5 histórias funcionando.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: credenciais fora do log (FR-017, SC-008), docs e validação final.

- [ ] T026 [P] Criar `click_seguro_app/test/modules/common/api_client/redacting_log_interceptor_test.dart`, com um `logPrint` falso que acumula as linhas:
  - request `POST /auth/app/refresh` com corpo `{"refreshToken":"renovacao-1"}` e resposta
    `{"accessToken":"acesso-2","refreshToken":"renovacao-2"}` → nenhuma linha contém
    `renovacao-1`, `acesso-2` ou `renovacao-2`, mas há uma linha com o caminho e o status;
  - `POST /auth/app/login` com `{"password":"Senha@123"}` → a senha não aparece;
  - `PATCH /users/me/change-password` → corpo omitido;
  - `GET /app/news` → o corpo da resposta aparece;
  - nenhum header `Authorization` em nenhuma linha.
- [ ] T027 Criar `click_seguro_app/lib/modules/common/api_client/redacting_log_interceptor.dart`: `class RedactingLogInterceptor extends LogInterceptor`, com construtor `({required List<String> sensitivePathPrefixes, void Function(Object) logPrint = print})`, que chama `super(requestHeader: false, requestBody: true, responseBody: true, error: true, logPrint: logPrint)`. Para requests cujo `options.path` começa com um prefixo sensível, sobrescrever `onRequest`/`onResponse`/`onError` para registrar só método, caminho e status, sem corpo. No `ApiClient`, adicionar `static const List<String> sensitivePathPrefixes = ['/auth/', '/users/me/change-password'];` e trocar o `LogInterceptor` por `RedactingLogInterceptor(sensitivePathPrefixes: sensitivePathPrefixes)` (faz T026 passar)
- [ ] T028 [P] Em `.specify/memory/tasks.md`, marcar `[x] **F0.2 …** (specs/002-apiclient-renovacao-sessao)` e `[x] **F0.13 …** (specs/002-apiclient-renovacao-sessao)`. Em `.specify/memory/constitution.md` **não** mexer: nenhuma regra mudou
- [ ] T029 Dentro de `click_seguro_app/`, rodar `flutter analyze` (sem erro nem warning novo) e `flutter test` (tudo verde) e conferir os cenários da tabela da seção 1 do [quickstart](quickstart.md). Reportar a contagem de testes em relação à linha de base da T001

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências.
- **Foundational (Phase 2)**: depende da T001. T002 → T005; T003 ∥ T002; T004 depende de T003 e T005 (usa o novo `saveSession`); T006 → T007; T007 depende de T004.
- **US1 (Phase 3)**: depende da Phase 2. T008 → T010; T009 → T011; T011 depende de T010.
- **US2 (Phase 4)**: depende da US1 (o `_send` com renovação é onde entra a condição). Fazer
  logo depois da US1: entre as duas, um 401 de senha errada tentaria renovar. Sem dano real,
  porque `_refreshTokens()` devolve `false` sem request quando não há `refreshToken` e o
  `expire()` não age fora de `authenticated`, mas a US2 não deve ficar para depois.
- **US3 (Phase 5)**: depende da Phase 2 (`CancelToken`) e da US1 (cenários 3 e 4 da T016 usam a renovação). T014 → T017; T015 → T018; T016 → T019 → T020.
- **US4 (Phase 6)**: depende só da Phase 2. T023 pode ir em paralelo com tudo.
- **US5 (Phase 7)**: depende da US1 (o caso de repetição do multipart).
- **Polish (Phase 8)**: T026/T027 dependem só da Phase 2; T028/T029 no final.

### User Story Dependencies

- **US1 (P1)**: base das demais regras de 401.
- **US2 (P1)**: depois da US1, porque é o mesmo trecho do `_send`.
- **US3 (P2)**: depois da US1.
- **US4 (P3)**: independente depois da Phase 2.
- **US5 (P3)**: depois da US1.

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- `UserSessionService` antes do `ApiClient` quando os dois mudam.
- Commit ao fim de cada história (`/speckit-git-commit`).

### Parallel Opportunities

- **Phase 2:** T002 e T003, porque são arquivos diferentes.
- **US1:** T008 (teste da sessão) e T009 (teste do `ApiClient`).
- **US3:** T014, T015 e T016, que estão em três arquivos.
- **US4:** T023 (documentação) a qualquer momento.
- **Polish:** T026 e T028.
- Quase tudo passa por `api_client.dart`, então as **implementações** das histórias vão em
  sequência. É uma feature pensada para uma pessoa.

---

## Parallel Example: User Story 3

```bash
Task: "Testes de updateProfile em click_seguro_app/test/modules/common/services/user_session_service_test.dart"
Task: "Teste de 404 USER_NOT_FOUND em click_seguro_app/test/modules/common/api_client/api_client_test.dart"
Task: "Testes do SessionValidationService em click_seguro_app/test/modules/common/services/session_validation_service_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2 (sessão v2, `code`, `CancelToken`).
2. Phase 3 (US1): renovação transparente.
3. **PARAR e VALIDAR**: `flutter test` verde. Neste ponto, o app real já sobrevive à
   credencial vencida.

### Incremental Delivery

1. Foundational → contratos novos estáveis para as trilhas (A2 já pode usar `saveSession` v2).
2. US1 + US2 → regras de 401 completas (desbloqueia A2 e B8).
3. US3 → conferência na abertura (desbloqueia A1).
4. US4 + US5 → erros robustos, `patch`, multipart (desbloqueia A3, B7, B8).
5. Polish → log seguro, docs e PR para `develop` (depois do PR da branch `docs/alinhamento-api-real`).

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- [USn] mapeia a tarefa para a história da [spec](spec.md).
- Verifique que o teste falha antes de implementar.
- **Não** mexer em `splash`, `authentication` nem `main.dart`: o uso do
  `SessionValidationService` é da A1, e o login é da A2.
- Se o `flutter analyze` acusar `userId` ou `token` em outro lugar além dos arquivos citados,
  ajuste para `email`/`accessToken` na mesma tarefa em que o campo mudou (hoje só há uso no
  `ApiClient` e nos testes).
