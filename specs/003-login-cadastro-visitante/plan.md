# Implementation Plan: Login, cadastro, visitante e recuperação de senha

**Branch**: `003-login-cadastro-visitante` | **Date**: 2026-10-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-login-cadastro-visitante/spec.md`

**Base**: [plan do produto](../../.specify/memory/plan.md) §2 (rotas) e §4 (Auth A2),
[api-contract](../../.specify/memory/api-contract.md) "Autenticação",
[guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md) (passos 0 a 9),
[constituição](../../.specify/memory/constitution.md) v1.1.0, wireframe
`wireframe/src/components/screens/LoginScreen.tsx`. Depende da
[feature 002](../002-apiclient-renovacao-sessao/plan.md) (sessão v2, `ApiErrorCodes`, log sem
corpos de `/auth/*`).

## Summary

Implementar o módulo `authentication` completo (data, domain e presentation), seguindo o guia de
integração:

- **Login:** `login` → `GET /users/me` com o token recém-recebido → checagem de papel →
  `saveSession`.
- **Cadastro:** `register` → o mesmo fluxo do login. Se a entrada automática falhar, o app trata
  como "conta criada".
- **Visitante:** `startGuestSession`.
- **Recuperação:** três passos com o código validado antes da troca.

A validação das regras do RN-001 fica em usecases, antes de qualquer rede
([R2](research.md)).

A UI segue o wireframe: seletor "Entrar"/"Criar conta", campos com ícone, olho, lista de regras da
senha e "Continuar sem login". Ajustes fora do módulo, todos aditivos:
- `ApiClient.get(authToken:)`, para o `/users/me` antes de existir sessão ([R1](research.md));
- parâmetros de teclado e acessibilidade no `SafeTextField` ([R9](research.md));
- rota provisória `/home` até a F0.9 ([R6](research.md)).

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `dio`, `get_it`, `provider`, `go_router ^17.3.0`,
`easy_localization ^3.0.7`, `fpdart`. **Nenhuma dependência nova.**

**Storage**: nenhum novo. A sessão é a da 002 (armazenamento seguro). A senha nunca é guardada.

**Testing**: `flutter_test`. Fakes à mão:
- `FakeAuthRemoteDataSource` e `FakeAuthRepository`, em `test/modules/authentication/fakes/`;
- `FakeHttpClientAdapter` e `FakeSecureStorageService`, da 002;
- relógio injetável no `ForgotPasswordController`;
- widget tests com `EasyLocalization` e as traduções reais ([R12](research.md)).

**Target Platform**: Android (minSdk 24) e iOS; validação no Samsung SM S921B.

**Project Type**: mobile-app (Flutter, módulos em `lib/modules/<modulo>/`).

**Performance Goals**: resposta visual ao toque imediata (botão em processamento); login
completo em até 30 s para a pessoa (SC-001). Rede: 2 requests no login e 3 no cadastro.

**Constraints**:
- nenhum envio com campos inválidos (SC-004);
- senha fora do log (garantido pela 002);
- alvos ≥ 48 dp e rolagem sem cortes com fonte 1,5× (FR-019);
- pt-BR e en-US (FR-018).

**Scale/Scope**:
- 1 módulo: cerca de 25 arquivos em `lib/modules/authentication/` e 20 de teste;
- 2 páginas (login e recuperação, com 3 passos);
- ajustes pequenos em `api_client.dart`, `safe_text_field.dart`, `app_router.dart`,
  `app_strings.dart` e nos dois JSONs.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como esta feature cumpre | Status |
|---|---|---|
| **I. Clean Architecture & Modularização** | `authentication` com `data/`, `domain/` e `presentation/`. Controllers falam só com usecases; a validação está nos usecases ([R2](research.md)). O barrel exporta só módulo, rotas e páginas | ✅ |
| **II. SOLID, DRY, KISS** | O fluxo `_signIn` é reaproveitado pelo cadastro ([R5](research.md)). Um validator para todas as regras. Uma rota e um controller para os três passos da recuperação ([R7](research.md)). Sem abstração para um segundo provedor de login | ✅ |
| **III. TDD** | Teste antes de cada model, datasource, repository, usecase e controller, com widget test de sucesso e erro nas duas páginas. Tudo offline | ✅ |
| **IV. Stack e DI** | Dio via `ApiClient` (`authToken` aditivo, sem `Dio` próprio), GetIt, `Provider`/`ChangeNotifier` registrados em `providers()` do módulo ([R8](research.md)), `go_router`, `easy_localization`. Sem dependência nova | ✅ |
| **V. Erros tipados, sem strings mágicas** | `Failure` específicas só onde a UI distingue ([R4](research.md)); códigos de erro como constantes; enums para campo, erro, regra, modo e passo; mensagens como chaves de `AppStrings` | ✅ |
| **Segurança** | Senha só em memória durante o envio; tokens só via `saveSession`; nenhum `!` especulativo | ✅ |
| **UI sem infraestrutura** | As páginas obtêm controllers via `Provider`. A `HomePlaceholderPage` lê `UserSessionService` via GetIt só para a saudação, o que a constituição permite | ✅ |

**Pós-design (Phase 1):** reavaliado depois de [data-model.md](data-model.md),
[contracts/](contracts/authentication.md) e [quickstart.md](quickstart.md). Nenhuma violação. Os
ajustes em `common` (`ApiClient`) e `core/widgets` são aditivos e vão em commits isolados, como
pede o plan do produto §6.

## Project Structure

### Documentation (this feature)

```text
specs/003-login-cadastro-visitante/
├── spec.md
├── plan.md                       # este arquivo
├── research.md                   # R1–R12
├── data-model.md                 # entidades, enums, failures, validator, estado dos controllers
├── quickstart.md
├── contracts/
│   └── authentication.md         # endpoints, ajustes aditivos, barrel, rotas
├── checklists/
│   └── requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (repository root)

```text
click_seguro_app/
├── assets/translations/{pt-BR,en-US}.json            # + chaves auth_*
├── lib/
│   ├── core/
│   │   ├── i18n/app_strings.dart                      # + bloco // --- authentication ---
│   │   ├── routing/app_router.dart                    # ...authenticationRoutes + /home provisória
│   │   ├── routing/home_placeholder_page.dart         # NOVO, TODO(F0.9)
│   │   └── widgets/safe_text_field.dart               # + parâmetros opcionais (R9)
│   └── modules/
│       ├── common/api_client/api_client.dart          # get(authToken:)
│       └── authentication/
│           ├── authentication.dart                    # barrel público
│           ├── authentication_module.dart             # registra datasource, repo, usecases, controllers
│           ├── data/
│           │   ├── datasources/auth_remote_data_source{,_impl}.dart
│           │   ├── models/{auth_tokens_model,user_model}.dart
│           │   └── repositories/auth_repository_impl.dart
│           ├── domain/
│           │   ├── entities/user_entity.dart
│           │   ├── enums/{user_role,auth_field,field_error,password_rule,reset_step}.dart
│           │   ├── failures/auth_failures.dart
│           │   ├── repositories/auth_repository.dart
│           │   ├── usecases/{login,register,enter_as_guest,request_password_reset,
│           │   │             verify_reset_code,reset_password,evaluate_password}_usecase.dart
│           │   └── validators/credentials_validator.dart
│           └── presentation/
│               ├── controller/{authentication,forgot_password}_controller.dart
│               ├── extensions/auth_presentation_extension.dart
│               ├── pages/{login,forgot_password}_page.dart   # remove login_placeholder_page.dart
│               ├── routes/authentication_routes.dart
│               └── widgets/{auth_header,auth_mode_switch,password_rules_list,
│                            or_divider,resend_code_button}.dart
└── test/modules/authentication/                       # espelha lib/, + fakes/
```

**Structure Decision**: módulo de feature padrão da constituição. A única coisa fora do módulo
são os ajustes aditivos em `common`/`core` e a rota provisória, que a F0.9 substitui.

## Impacto em outras tarefas e documentos

- **api-contract:** a linha `GET /users/me` passa a citar o uso com o token do login (`authToken`).
- **plan do produto §2:** registrar a rota provisória `/home` até a F0.9.
- **A1:** o splash continua indo para `/login`. A A1 decide ir direto para `/home` com sessão.
- **F0.8/F0.10:** quando vierem, reaproveitam o bloco de i18n e trocam os estados locais pelos
  comuns, se fizer sentido.
- **B7/B8:** `UserEntity`/`UserModel` ficam internos ao `authentication`. O perfil (B7) terá
  modelo próprio para `GET /users/me`, sem importar deste módulo.

## Complexity Tracking

Sem violações da constituição. Nada a justificar.
