# Implementation Plan: Comunicação com a API real e renovação da sessão

**Branch**: `002-apiclient-renovacao-sessao` | **Date**: 2026-10-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-apiclient-renovacao-sessao/spec.md`

**Base**: [plan do produto](../../.specify/memory/plan.md) §3.1 (sessão), seção "Sessão e tokens"
do [api-contract](../../.specify/memory/api-contract.md) v1.0.0, [openapi.json](../../.specify/memory/openapi.json),
[guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md) e
[constituição](../../.specify/memory/constitution.md) v1.1.0. Continua a
[feature 001](../001-sessao-persistente-visitante/plan.md).

## Summary

Adequar a camada HTTP e a sessão à API real. O `ApiClient` passa a:

- ler o código de erro de `code`;
- aceitar `CancelToken` no `get`;
- ganhar `patch` e `postMultipart`;
- tirar credenciais e senhas do log em debug;
- e, no ponto central, decidir entre **renovar**, **repetir**, **manter** ou **expirar** a
  sessão a cada recusa.

A renovação acontece dentro do `ApiClient`: o pedido é uma função que pode ser executada de
novo, e uma renovação em andamento é compartilhada por todos os pedidos recusados
([R1](research.md), [R2](research.md)).

A sessão passa a guardar o par de tokens e o e-mail (sem `userId`, porque a API não tem id).
Ganha `replaceTokens` (condicional, contra corrida com logout) e `updateProfile`.

Um novo `SessionValidationService` confere a conta (`GET /users/me`) com prazo de 3 s. Ele é
entregue pronto e testado; quem o chama no splash é a tarefa A1 ([R8](research.md)).

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `dio ^5.8.0+1`, `get_it`, `fpdart`, `flutter_secure_storage`.
**Nenhuma dependência nova.**

**Storage**: armazenamento seguro (registro `session` v2, [data-model](data-model.md)). Nada
novo no `shared_preferences`.

**Testing**: `flutter_test`, `FakeHttpClientAdapter` estendido com roteiro por request,
`FakeSecureStorageService` da 001, prazo injetável no `SessionValidationService` (sem
`fake_async`) ([R13](research.md)).

**Target Platform**: Android (minSdk 24) e iOS.

**Project Type**: mobile-app (Flutter, módulos em `lib/modules/<modulo>/`).

**Performance Goals**: conferência na abertura em até 3 s, em paralelo com o splash mínimo de
2 s (SC-005). Renovação transparente: o pedido renovado custa 2 requests a mais (refresh +
repetição).

**Constraints**:
- no máximo 1 renovação simultânea e 1 repetição por pedido (FR-005, SC-004);
- credenciais nunca no log (FR-017);
- `validateStoredSession()` e `restoreSession()` nunca lançam;
- sessão mantida sem rede (FR-004, FR-008).

**Scale/Scope**:
- 2 arquivos novos em `lib/` (`api_error_codes.dart`, `session_validation_service.dart`), 1
  interceptor de log;
- mudanças em `api_client.dart`, `user_session_service.dart`, `common_module.dart`;
- 5 arquivos de teste novos ou alterados;
- documentação no guia de integração e no plan/tasks do produto.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como esta feature cumpre | Status |
|---|---|---|
| **I. Clean Architecture & Modularização** | Tudo é infraestrutura do `common` (`api_client/`, `services/`), registrada no `CommonModule`. Nenhum controller muda nesta feature. O `SplashController` (A1) vai consumir o `SessionValidationService` **por meio de um usecase** do splash (`ValidateStoredSessionUseCase`), mantendo "controller → usecase" | ✅ |
| **II. SOLID, DRY, KISS** | Renovação dentro do `ApiClient` em vez de interceptor + segundo `Dio` ([R1](research.md)). Sem `TokenRefresher` abstrato: uma implementação só ([R3](research.md)). `ApiErrorCodes` só com os códigos do `common` ([R9](research.md)) | ✅ |
| **III. TDD** | Cada regra da tabela de decisão do [data-model](data-model.md) tem teste antes da implementação, com caminho feliz, erro e borda (concorrência, corrida com logout, prazo). Testes offline com adapter falso e `GetIt.reset()` | ✅ |
| **IV. Stack e DI** | Só Dio, via `ApiClient`; datasources continuam sem `FormData` ([R11](research.md)). GetIt para o novo serviço. `CancelToken` é tipo do Dio, mas circula só na camada `data/` (datasources), que já usa `Response` do Dio | ✅ |
| **V. Erros tipados, sem strings mágicas** | Códigos em `ApiErrorCodes`, caminhos sensíveis e de renovação em constantes do `ApiClient`. A decisão sobre 401/404 continua num ponto só. `INVALID_CREDENTIALS` segue `ApiErrorType.unauthorized`, e a `Failure` específica é do repository de cada feature | ✅ |
| **Segurança: segredos fora de código e log** | `RedactingLogInterceptor` ([R12](research.md)); tokens só no armazenamento seguro; testes usam valores fictícios | ✅ |
| **Segurança: `late`/`!` com justificativa** | O desenho não precisa de `!`: `refreshToken` é lido e testado como nulo antes de renovar | ✅ |
| **Segurança: dependência nova justificada** | Nenhuma dependência nova | ✅ |

**Pós-design (Phase 1):** reavaliado depois de escrever [data-model.md](data-model.md),
[contracts/](contracts/api-client-and-session.md) e [quickstart.md](quickstart.md). Nenhuma
violação. Desvios do plan do produto, já refletidos nele:
- a API pública da sessão é `accessToken`/`refreshToken`/`email`/`userName` (antes
  `token`/`userId`);
- a conferência na abertura é chamada pelo splash (A1), não pelo `_setup()`;
- entra o método `patch`.

## Project Structure

### Documentation (this feature)

```text
specs/002-apiclient-renovacao-sessao/
├── spec.md
├── plan.md                              # este arquivo
├── research.md                          # decisões R1–R14
├── data-model.md                        # registro v2, operações novas, tabela de decisão do ApiClient
├── quickstart.md                        # como validar
├── contracts/
│   └── api-client-and-session.md        # ApiClient, ApiErrorCodes, UserSessionService, SessionValidationService
├── checklists/
│   └── requirements.md
└── tasks.md                             # gerado por /speckit-tasks
```

### Source Code (repository root)

```text
click_seguro_app/
├── ENDPOINT_INTEGRATION_CONTEXT.md                     # §4.1: `code`, renovação, patch, multipart, CancelToken (FR-018)
├── lib/modules/common/
│   ├── common_module.dart                              # registra SessionValidationService
│   ├── api_client/
│   │   ├── api_client.dart                             # _send com repetição, renovação compartilhada, code, patch,
│   │   │                                               # postMultipart, CancelToken, 404 USER_NOT_FOUND
│   │   ├── api_error_codes.dart                        # NOVO
│   │   └── redacting_log_interceptor.dart              # NOVO
│   └── services/
│       ├── user_session_service.dart                   # registro v2, replaceTokens, updateProfile
│       └── session_validation_service.dart             # NOVO
└── test/modules/common/
    ├── api_client/
    │   ├── fake_http_client_adapter.dart               # + modo roteiro e lista de requests
    │   ├── api_client_test.dart                        # + renovação, code, cancel, patch, multipart
    │   └── redacting_log_interceptor_test.dart         # NOVO
    └── services/
        ├── user_session_service_test.dart              # ajustado para v2 + operações novas
        └── session_validation_service_test.dart        # NOVO
```

Documentos do produto atualizados no plano: [plan.md §3.1](../../.specify/memory/plan.md) (API
pública da sessão e chamada da conferência) e a A1 do [tasks.md](../../.specify/memory/tasks.md).

**Structure Decision**: projeto Flutter único (`click_seguro_app/`). Tudo desta feature é
infraestrutura do `common`, que fecha depois da Fase 0. Por isso entram agora também o `patch`
e o `postMultipart`, usados só por B7/B8.

## Impacto nas próximas tarefas

- **A1 (splash):** criar `ValidateStoredSessionUseCase` em `splash/domain/usecases/` (delega ao
  `SessionValidationService`), chamar no `SplashController` em paralelo com o tempo mínimo e
  decidir a rota depois dos dois.
- **A2 (login/cadastro):** `saveSession(accessToken:, refreshToken:, email:, userName:)` após
  `login` + `GET /users/me`. Mapear `ApiErrorCodes.invalidCredentials` antes do `toFailure()`.
  O log de `/auth/*` já sai sem corpo, o que encerra o "risco herdado" da 001.
- **A3 (busca):** `get(..., cancelToken:)`.
- **B7 (perfil):** `patch('/users/me')` e `postMultipart('/users/me/avatar', fieldName: 'avatar', …)`.
- **B8 (troca de senha):** `patch('/users/me/change-password')`. `INVALID_CREDENTIALS` não
  desconecta. O repository devolve "Senha atual incorreta".
- **F0.9 (shell):** sem mudança. O aviso de sessão expirada continua vindo de
  `endReason == expired`.

## Complexity Tracking

Sem violações da constituição. Nada a justificar.
