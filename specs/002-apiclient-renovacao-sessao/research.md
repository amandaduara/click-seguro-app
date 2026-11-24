# Research: Comunicação com a API real e renovação da sessão

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

Decisões técnicas da feature 002. Cada item cita os requisitos que resolve.

## R1 — Onde mora a renovação: dentro do `ApiClient`, sem interceptor (FR-002, FR-003)

- **Decisão:** a renovação fica num método privado do `ApiClient`. Cada método público (`get`,
  `post`, `put`, `delete`, `postMultipart`) passa ao `_send` uma **função que monta e dispara o
  request**. Essa função lê o token da sessão **no momento em que é chamada**. Se a resposta
  for um 401 renovável, o `_send` renova e chama a mesma função de novo, uma única vez, e o
  request repetido já sai com o token novo.
- **Racional:** o `_safeRequest` já recebe uma função (`requestCall`), então a mudança é
  pequena e fica num ponto só (constituição V, "mapeamento centralizado"). O controle de "no
  máximo uma repetição" é uma variável local, fácil de testar.
- **Alternativas consideradas:**
  - `QueuedInterceptor` do Dio com `dio.fetch(options)` para repetir. Rejeitado: exige um
    segundo `Dio` para a renovação (para não reentrar no interceptor) e espalha a regra entre
    interceptor e `_mapBadResponse`. Mais peças para o mesmo resultado (KISS).
  - Renovação preventiva lendo o `exp` do JWT. Rejeitado na spec (Assumptions): a renovação é
    reativa.

## R2 — Uma renovação para vários pedidos (FR-005, SC-002)

- **Decisão:**
  1. O `ApiClient` guarda um `Future<bool>? _renewal`. O primeiro 401 renovável cria a
     renovação, e os seguintes **esperam o mesmo Future**. Quando ele termina, o campo volta a
     `null`.
  2. Antes de renovar, o `_send` compara o token **enviado** no request com o token **atual**
     da sessão. Se forem diferentes, outra renovação já trocou o token enquanto este request
     voava: o pedido só é repetido, sem renovar de novo.
- **Racional:** cobre os dois casos de concorrência, com pedidos recusados durante a renovação
  e pedidos recusados logo depois dela. Sem o item 2, um pedido lento dispararia uma segunda
  renovação com o refresh token já trocado, e o SC-002 falharia.
- **Alternativas consideradas:** `Completer` + fila manual de requests pendentes. Rejeitado
  porque o `Future` compartilhado faz o mesmo com menos código.

## R3 — Quem chama `POST /auth/app/refresh` (FR-002, FR-004)

- **Decisão:** o próprio `ApiClient`, pelo mesmo `_dio`, num caminho **direto** (fora do
  `_send`), sem `Authorization` e sem possibilidade de renovar de novo. O caminho fica numa
  constante nomeada `ApiClient.refreshPath = '/auth/app/refresh'`. Resultado da renovação:
  - 200 → grava o novo par e devolve `true`.
  - 401 → `expire()` e devolve `false`.
  - Erro de conexão, tempo esgotado, 5xx ou corpo inválido → **não** mexe na sessão e devolve
    o erro, que vira o erro do pedido original (FR-004).
- **Racional:** a regra do 401 já é do `ApiClient` (constituição V). Criar um
  `TokenRefresher`/repository para uma chamada só, com uma implementação só, seria abstração
  para caso hipotético (constituição II).
- **Alternativas consideradas:** o módulo `authentication` registrar um callback de renovação
  no `common`. Rejeitado: inverte a dependência (o `common` passaria a depender de quem
  registra) e a A2 ainda não existe.

## R4 — Quais recusas disparam renovação (FR-002, FR-006, FR-007; Clarification 2)

- **Decisão:** renova quando **todas** as condições valem:
  1. status 401;
  2. o request **enviou** um token (visitante e rotas `requiresAuth: false` nunca enviam);
  3. o `code` do corpo é diferente de `INVALID_CREDENTIALS` (lista de exceções, conforme a
     clarificação). Sem `code` ou com `code` desconhecido também renova.

  Se o request não enviou token, o 401 só vira `ApiException(unauthorized)`, sem tocar na
  sessão. Hoje o `expire()` é chamado em todo 401; isso muda.
- **Racional:** é a regra do [api-contract](../../.specify/memory/api-contract.md#sessão-e-tokens).
  O item 2 resolve o login (401 de senha errada sem token) sem depender só do `code`.
- **Alternativas consideradas:** lista de permissões (`TOKEN_INVALID`, `UNAUTHORIZED`).
  Rejeitada na clarificação.

## R5 — Conta desativada durante o uso (FR-008a; Clarification 3)

- **Decisão:** no `_mapBadResponse`, a resposta 404 com `code == USER_NOT_FOUND` a um request
  que **enviou token** chama `expire()`. Outros 404 (`NEWS_NOT_FOUND` etc.) não mudam nada.
- **Racional:** mesmo ponto central do 401. As telas das trilhas não precisam conhecer o caso.

## R6 — Registro da sessão v2 e migração (FR-001, FR-010, FR-011)

- **Decisão:** o registro JSON (chave `session`) passa a ser:

  ```json
  { "status": "authenticated", "accessToken": "…", "refreshToken": "…", "email": "maria@x.com", "userName": "Maria" }
  ```

  - `token` → `accessToken`; entram `refreshToken` e `email`; sai `userId`.
  - Um registro `authenticated` sem `accessToken`, `refreshToken` ou `email` (inclusive o
    formato da 001) é **inválido**: é apagado, e a sessão começa desconectada (regra FR-014 da
    001, já implementada).
- **Racional:** a API não devolve id (ver [api-contract](../../.specify/memory/api-contract.md)).
  O e-mail é único por conta (409 `USER_EMAIL_ALREADY_EXISTS`). Renomear `token` deixa claro
  qual das duas credenciais é. A migração por "inválido → apaga" reaproveita um caminho já
  testado, e o app não foi publicado.
- **Alternativas consideradas:**
  - Manter `token` e `userId` (com o e-mail dentro). Rejeitado: nome enganoso.
  - Ler o registro antigo e manter só o access token até ele vencer. Rejeitado: sem refresh
    token, a sessão cairia logo depois, e criar um caminho de migração só para quem desenvolve
    não compensa.

## R7 — Corrida entre sair da conta e renovação (FR-012)

- **Decisão:** novo método
  `UserSessionService.replaceTokens({required String previousRefreshToken, required String accessToken, required String refreshToken})`,
  que devolve `bool`. Ele **só aplica** se a sessão ainda estiver `authenticated` **e** o
  `refreshToken` atual for igual a `previousRefreshToken`. Se não aplicar, o `ApiClient` trata
  como renovação sem efeito e **não** repete o pedido.
- **Racional:** cobre "saiu da conta durante a renovação" e "trocou de conta durante a
  renovação" com uma comparação, sem flags de geração.

## R8 — Conferência da conta na abertura (FR-008, FR-009; Clarification 1)

- **Decisão:** novo `SessionValidationService` em `common/services/`, com
  `Future<void> validateStoredSession()`. Comportamento:
  - Nunca lança; com visitante ou desconectado, não faz nada (história 3, cenário 7).
  - Faz `GET /users/me` com um `CancelToken` e um prazo (padrão 3 s, injetável no construtor
    para os testes). No fim do prazo, **cancela** o request e devolve, de modo que a resposta
    atrasada é descartada.
  - Com 200, chama `UserSessionService.updateProfile(name:, email:)`.
  - Com 404 `USER_NOT_FOUND` ou renovação recusada, o próprio `ApiClient` já chamou
    `expire()` (R3/R5): a sessão fica `unauthenticated`, e quem decide a rota vai ao login.
  - Com erro de conexão, 5xx ou corpo inválido, mantém a sessão.

  **Prazo e renovação:** o cancelamento no fim do prazo atinge só o `GET /users/me`. Uma
  renovação em andamento continua, porque é compartilhada com outros pedidos (R2) e não pode ser
  cancelada por um deles. Se ela for recusada depois do prazo, vale o CB-003 normal (aviso na
  tela), registrado nos Edge Cases da spec.

  **Quem chama:** o `SplashController` (tarefa A1), por meio de um `ValidateStoredSessionUseCase`
  do splash (constituição I: controller só fala com usecase), em paralelo com os 2 s mínimos do
  splash. A rota é escolhida depois dos dois terminarem. Esta feature entrega o serviço testado e
  registra o uso na A1 do [tasks.md do produto](../../.specify/memory/tasks.md).
- **Racional:** chamar no `_setup()` (antes do `runApp`) somaria até 3 s ao splash de 2 s,
  estourando o SC-005. Em paralelo no splash, o pior caso é max(2 s, 3 s) = 3 s. O
  `SplashController` hoje manda todos para `/login` (a decisão por sessão é da A1). Mexer nele
  aqui anteciparia a A1 e invadiria a trilha A.
- **Alternativas consideradas:**
  - `await` no `_setup()`. Rejeitado pelo SC-005.
  - Disparar no `_setup()` sem `await` e o splash esperar o mesmo Future via GetIt. Rejeitado:
    estado global solto e difícil de testar.
  - Usecase em `authentication`. Rejeitado: anteciparia a camada de dados da A2 (Dev 1).

## R9 — Código de erro em `code` e constantes nomeadas (FR-013, FR-014)

- **Decisão:**
  - `_mapBadResponse` lê `json['code']` (antes `json['error']`). O corpo do Zod
    (`{statusCode, message, errors}`) não tem `code`, então `errorCode` fica `null`. Se
    `message` não for string, usa `toString()`.
  - Novo arquivo `lib/modules/common/api_client/api_error_codes.dart`:
    `abstract final class ApiErrorCodes` com constantes só para os códigos que **o `common`
    usa**: `invalidCredentials = 'INVALID_CREDENTIALS'` e `userNotFound = 'USER_NOT_FOUND'`.
    Os códigos de cada feature (`USER_EMAIL_ALREADY_EXISTS`, `NEWS_NOT_FOUND`…) ficam nos
    repositories delas.
- **Racional:** a constituição V proíbe comparar literais no fluxo. Centralizar todos os
  códigos da API no `common` criaria um arquivo que as duas trilhas editariam (conflito,
  plan do produto §6).

## R10 — Cancelamento (FR-015)

- **Decisão:** parâmetro opcional `CancelToken? cancelToken` só em `get`. Cancelar →
  `ApiException(cancelled)`, o que já existe no `_mapDioException`. O pedido cancelado **não**
  dispara renovação.
- **Racional:** a spec fala em "consulta" (busca do feed, conferência na abertura). Ações de
  escrita não são canceladas pela UI.

## R11 — Upload multipart (FR-016)

- **Decisão:**

  ```dart
  Future<Response> postMultipart(String path, {
    required String fieldName,      // 'avatar'
    required String filePath,
    required String contentType,    // 'image/jpeg' | 'image/png' | 'image/webp'
    bool requiresAuth = true,
  })
  ```

  - O `FormData` (com `MultipartFile.fromFile(filePath, contentType: DioMediaType.parse(contentType))`)
    é **criado dentro da função** do R1. Assim, a repetição depois de renovar monta um
    `FormData` novo, porque o Dio não deixa reenviar o mesmo.
  - `Options(contentType: Headers.multipartFormDataContentType)` sobrescreve o
    `application/json` do `BaseOptions`.
- **Racional:** o `FormData` não vaza para os datasources (constituição: Dio encapsulado). O
  `contentType` explícito evita `application/octet-stream`, que a API pode recusar por
  formato. Quem escolhe a imagem (B7) sabe o tipo.
- **Alternativas consideradas:** receber bytes (`List<int>`). Rejeitado: copia até 5 MB na
  memória sem necessidade. Os testes usam um arquivo temporário.

## R12 — Credenciais fora do log (FR-017, SC-008)

- **Decisão:** trocar o `LogInterceptor` por um `RedactingLogInterceptor` (privado do
  `api_client`, subclasse de `LogInterceptor`). Ele continua sem headers e, para caminhos em
  `ApiClient.sensitivePathPrefixes` (`/auth/`, `/users/me/change-password`), **não** registra o
  corpo do request nem o da resposta, só método, caminho e status.
- **Racional:** hoje, em modo debug, o corpo do login (senha), da resposta do login (tokens) e
  da renovação iria para o log. Era o "risco herdado" anotado no plan da 001 para a A2, e a
  renovação torna isso inevitável aqui.
- **Alternativas consideradas:**
  - Desligar corpos para todos os requests. Rejeitado: perde o principal valor do log em
    debug.
  - Marcar `extra['sensitive']` request a request. Rejeitado: depende de cada datasource
    lembrar.

## R13 — Testes (constituição III)

- **Decisão:**
  - `FakeHttpClientAdapter` ganha um modo **por roteiro**: `responder: (RequestOptions) →
    FakeResponse` e a lista `requests` com todos os requests recebidos. O modo atual (um
    status e um corpo) continua funcionando para os testes existentes.
  - Concorrência (SC-002): disparar 5 `get` com `Future.wait`, com o adapter respondendo 401
    ao token velho e 200 ao novo, e contar os requests para `refreshPath` (esperado: 1).
  - Prazo da conferência: `SessionValidationService(timeout: Duration(milliseconds: 50))` com
    um adapter que demora mais que isso (`Future.delayed` dentro do `fetch`, respeitando o
    `cancelFuture`).
  - Log (SC-008): testar o `RedactingLogInterceptor` com uma função de log falsa (o
    `LogInterceptor` aceita `logPrint`) e verificar que nenhuma linha contém os tokens.
- **Racional:** tudo offline e determinístico, sem pacote novo. `fake_async` não é dependência
  direta, e o prazo injetável resolve.

## R14 — Método `patch` no `ApiClient` (FR-013, contrato da API)

- **Decisão:** adicionar `patch(path, {data, requiresAuth = true})`, no mesmo formato de `put`.
- **Racional:** a API real usa `PATCH` em `/users/me` (B7) e em `/users/me/change-password`
  (B8), e o `ApiClient` hoje só tem `get`/`post`/`put`/`delete`. Como o `common` fecha depois da
  Fase 0 (plan do produto §6), o método entra agora, já passando pelas regras de erro e de
  renovação desta feature.
- **Alternativas consideradas:** `put` no lugar de `patch`. Rejeitado: a API não aceita.
