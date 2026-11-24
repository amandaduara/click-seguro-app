# Implementation Plan: Painel de atividades

**Branch**: `015-painel-atividades` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/015-painel-atividades/spec.md`

**Base**: tarefa B1 do [tasks do produto](../../.specify/memory/tasks.md),
[especificação do produto](../../.specify/memory/specification.md) (RF-023, RN-006, CB-012,
RNF-002 a RNF-006), [contrato da API](../../.specify/memory/api-contract.md) 1.0.9,
[constituição](../../.specify/memory/constitution.md), conferência no servidor de 2026-10-19 (R0),
código das features 001, 003, 005, 006, 009, 012 e 014.

## Summary

Trocar a página provisória da aba Atividades pelo painel e criar o módulo `activities` de verdade:

- **Dados** ([R0](research.md#r0-conferência-no-servidor-real-portão-de-api),
  [R1](research.md#r1-camadas-e-independência-do-perfil)): `GET /app/educational/modules` com e
  sem token, em `data`/`domain`/`presentation` próprios, sem depender do Perfil.
- **Status** ([R2](research.md#r2-status-do-módulo)): não iniciado / em andamento / concluído /
  indisponível, derivado na entidade; "concluída" = respondida, como no servidor.
- **Visitante** ([R3](research.md#r3-progresso-do-visitante-guestprogressstore),
  [R10](research.md#r10-aviso-do-visitante)): `GuestProgressStore` em memória, que ouve a sessão;
  aviso com "Entrar ou criar conta".
- **Transferência** ([R4](research.md#r4-saber-que-a-conta-acabou-de-ser-criada),
  [R5](research.md#r5-transferência-reenvio-das-respostas)): a sessão passa a saber que nasceu de
  um cadastro (`saveSession(newAccount: true)`); as respostas do visitante são reenviadas à conta
  nova, uma a uma, sem atrasar a entrada.
- **Tela** ([R6](research.md#r6-atualizar-ao-voltar-para-a-aba-ou-de-um-módulo)–[R9](research.md#r9-ícone-do-módulo)):
  progresso geral, cartões em duas colunas com letra 100% e uma coluna com letra maior, estados de
  carregando/erro/vazio, recarga ao voltar (mixin extraído do Perfil).

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `dio` (via `ApiClient`), `fpdart`, `get_it`, `provider`,
`go_router`, `easy_localization`, `lucide_icons_flutter`. Nenhuma dependência nova.

**Storage**: nenhum armazenamento novo. O progresso do visitante fica só em memória
(`GuestProgressStore`, RN-006); o da conta, no serviço.

**Testing**: `flutter_test`; `FakeHttpClientAdapter` no datasource; `UserSessionService` real
sobre `FakeSecureStorageService` no registro do visitante; fakes de datasource e repositório;
widget tests com `pumpLocalized`, `GetIt` resetado e escala de letra de teste. Offline.

**Target Platform**: Android e iOS.

**Project Type**: mobile-app

**Performance Goals**: painel em até 2 s com o servidor acordado (SC-001); recarga ao voltar sem
"carregando".

**Constraints**: 48 dp/16 sp, semântica por cartão, alto contraste e letra até o teto de 200% da
B9 (RNF-003/004); visitante sem token (RN-003); progresso do visitante nunca gravado no aparelho
(RN-006); textos pt-BR/en-US; módulos não se importam.

**Scale/Scope**: módulo `activities` com ~20 arquivos novos (data, domain, presentation);
`ActivitiesPage` substituída; mudanças pequenas em `common` (`UserSessionService`),
`authentication` (cadastro passa `newAccount`), `core/widgets` (mixin novo) e `profile` (passa a
usar o mixin); ~17 chaves de i18n; ~12 arquivos de teste novos e 3 ajustados.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | `activities` ganha `data`→`domain`→`presentation`; o controller só fala com o usecase; o repositório converte `ApiException` em `Failure`. Nada importa `profile` ou `authentication`: a transição "conta criada" chega pela `UserSessionService` do `common` (R4). | ✅ |
| II. SOLID, DRY, KISS | Status numa regra só (entidade). Técnica de recarregar ao voltar extraída do Perfil para um mixin em vez de copiada (R6). Transferência num método com um único envio em andamento. | ✅ |
| III. TDD | Testes antes do código para models, datasource, registro do visitante com sessão real, sessão (`startedFromSignUp`), cadastro, repositório (inclusive transferência), usecase, controller, extensão e página. | ✅ |
| IV. Stack e DI | Nenhuma dependência nova; datasource, registro (singleton), repositório, usecase e controller (factory) registrados no `ActivitiesModule`. | ✅ |
| V. Erros tipados | Falhas genéricas do `core/errors`; códigos `EDUCATIONAL_*` em constantes; status por enum; mensagens por chave. | ✅ |
| Regras globais | Nada novo gravado no aparelho; mudanças em `common`, `authentication`, `core` e `profile` justificadas (R4, R6) e com teste. | ✅ |

**Pós-design (Phase 1)**: reavaliado depois do data-model e do contrato; sem desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/015-painel-atividades/
├── spec.md
├── plan.md                         # este arquivo
├── research.md                     # R0–R11
├── data-model.md                   # entidades, store, transições, sessão, i18n
├── quickstart.md                   # testes + 12 passos no aparelho
├── contracts/
│   └── activities-dashboard.md     # endpoints, rotas, sessão, interface para a B3, tela
├── checklists/requirements.md
└── tasks.md                        # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── core/i18n/app_strings.dart                                   # + activities_*
├── core/widgets/refresh_on_return.dart                          # NOVO: RefreshOnReturnMixin (R6)
├── modules/common/services/user_session_service.dart            # + newAccount / startedFromSignUp (R4)
├── modules/authentication/data/repositories/auth_repository_impl.dart  # cadastro → newAccount: true
├── modules/profile/presentation/pages/profile_page.dart         # usa o RefreshOnReturnMixin
└── modules/activities/
    ├── activities_module.dart · activities.dart
    ├── data/
    │   ├── datasources/activities_remote_data_source(_impl).dart
    │   ├── datasources/guest_progress_store.dart
    │   ├── models/module_summary_model.dart · activities_dashboard_model.dart
    │   └── repositories/activities_repository_impl.dart
    ├── domain/
    │   ├── entities/module_summary_entity.dart · module_status.dart · activities_dashboard_entity.dart · guest_answer.dart
    │   ├── repositories/activities_repository.dart
    │   └── usecases/get_activities_dashboard_usecase.dart
    └── presentation/
        ├── controller/activities_dashboard_controller.dart · activities_dashboard_status.dart
        ├── extensions/module_status_presentation.dart
        ├── pages/activities_dashboard_page.dart                # substitui activities_page.dart
        ├── widgets/overall_progress_card.dart · module_card.dart · module_icon.dart · guest_progress_notice.dart
        └── routes/activities_routes.dart
assets/translations/{pt-BR,en-US}.json

test/modules/activities/ (data, domain, presentation, fakes) · test/helpers/activities_dependencies.dart ·
ajustes em test/modules/common/services/user_session_service_test.dart,
test/modules/authentication/data/repositories/auth_repository_impl_test.dart, test/core/routing/app_router_test.dart,
test/widget_test.dart
```

**Structure Decision**: o `activities` vira um módulo completo nas três camadas, como planejado no
produto (§ módulos: "B1–B4, data/domain/presentation"). O registro do visitante fica no `data` do
próprio módulo, porque a B3 (mesmo módulo) é quem grava nele.

## Fora do código

- **Contrato da API → 1.0.10** (R0): endpoints de atividades conferidos; resposta errada conta
  como concluída; `totalScore` 0 até a 1ª resposta; opção que não é CUID → 400 `VALIDATION_ERROR`.
- **Tasks do produto**: ao fechar, marcar a B1 e anotar que a RN-006 ganhou a transferência ao
  criar conta na mesma sessão, e que a B3 grava no `GuestProgressStore`.
- **Avisar o outro desenvolvedor**: `saveSession` ganhou `newAccount`; o Perfil passa a usar o
  `RefreshOnReturnMixin`.
- Conta de teste `teste.claude.20261019@exemplo.com` criada (memória do projeto).

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; entidades, `ModuleStatus`, models, datasource, `GuestProgressStore` (sem a
   transferência), repositório só com a leitura, usecase, `ActivitiesModule`; mixin
   `RefreshOnReturnMixin` com o Perfil migrado (testes da B7 verdes).
2. **US1 (ver módulos e progresso)**: controller, extensão de status, cartão de progresso,
   `ModuleCard`, `ModuleIcon`, página com os dois layouts; rota da aba.
3. **US2 (abrir módulo)**: toque com abertura única, indisponível não abre, recarga ao voltar.
4. **US3 (visitante)**: progresso do registro no painel, aviso com botão, `startedFromSignUp` na
   sessão e no cadastro, transições do registro, transferência no repositório.
5. **US4 (estados)**: carregando com aviso de servidor acordando, erro, vazio, recarga que mantém o
   conteúdo.
6. **Polimento**: contrato 1.0.10, revisão de código sem uso, analyze, suíte, quickstart no
   aparelho, marcar a B1.

Um commit por história.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Mudar o `authentication` (feature 003, fechada) e a `UserSessionService` (`common`) | Distinguir cadastro de login para transferir o progresso só ao criar conta (clarificação) | O `activities` não pode importar o `authentication`; adivinhar pela ordem dos eventos não é confiável |
| Mudar o `profile` (feature 012, fechada) | Usar o mixin extraído (R6) | Copiar a lógica no `activities` viola o Princípio II |
