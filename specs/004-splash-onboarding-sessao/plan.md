# Implementation Plan: Splash com sessão e onboarding

**Branch**: `004-splash-onboarding-sessao` | **Date**: 2026-10-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-splash-onboarding-sessao/spec.md`

**Base**: tarefa A1 do [tasks do produto](../../.specify/memory/tasks.md),
[constituição](../../.specify/memory/constitution.md) v1.1.0, `SessionValidationService` da
[feature 002](../002-apiclient-renovacao-sessao/plan.md) (FR-008 de lá), sessão da
[feature 001](../001-sessao-persistente-visitante/plan.md), rota provisória `/home` da
[feature 003](../003-login-cadastro-visitante/plan.md), wireframe
`wireframe/src/components/screens/OnboardingScreen.tsx`.

## Summary

O splash passa a decidir o destino pela marcação do onboarding **e** pelo estado da sessão,
depois de conferir a conta salva no serviço. A conferência corre em paralelo com o tempo mínimo
de 2 s.

- **Novo** `ValidateStoredSessionUseCase` em `splash/domain/usecases/`: delega ao
  `SessionValidationService` e devolve o `UserSessionStatus` resultante, sem nunca lançar
  ([R1](research.md)).
- **`SplashController` ajustado**: `Future.wait` com o atraso mínimo, a leitura do onboarding e a
  validação; depois decide onboarding → home → login ([R2](research.md)) e expõe um enum
  `SplashDestination` em vez de uma string ([R3](research.md)).
- **Splash**: frase de apoio `splash_tagline`, como no wireframe ([R6](research.md)).
- **Onboarding**: sem mudança de comportamento; ganha testes de controller e de página
  ([R7](research.md)).
- **Pequena correção de fronteira**: o splash passa a importar o `CheckOnboardingSeenUseCase`
  pelo barrel `onboarding.dart` ([R4](research.md)). **Já aplicada** durante o planejamento
  (2026-10-04, a pedido do usuário); `flutter analyze` sem avisos novos e suíte verde.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `get_it`, `provider`, `go_router`, `fpdart`,
`easy_localization`, `shared_preferences`, `lucide_icons_flutter`. Nenhuma dependência nova.

**Storage**: nada novo. Lê a marcação `onboarding_seen` (SharedPreferences) e a sessão no
armazenamento seguro, já restaurada antes do `runApp`.

**Testing**: `flutter_test` (unitários de usecase e controller, widget tests de página com
`pumpLocalized` e `GoRouter` de teste); fakes à mão, sem rede.

**Target Platform**: Android e iOS (app Flutter)

**Project Type**: mobile-app

**Performance Goals**: splash por 2 s para visitante ou sem sessão; até cerca de 3 s para sessão
conectada (prazo da conferência). Limite do SC-003: 4 s.

**Constraints**: nunca prender o usuário no splash (falhas viram um destino); conferência sem
bloquear além do prazo da feature 002; textos traduzidos (pt-BR e en-US).

**Scale/Scope**: 2 módulos (`splash`, `onboarding`), cerca de 4 arquivos de produção alterados,
2 novos, e 5 arquivos de teste.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | O splash ganha `domain/usecases/` porque passa a ter regra (a constituição só dispensa `domain/` para módulos sem regra). Controller → usecases apenas; o usecase consome serviços do `common` via GetIt. A importação do usecase do onboarding pelo caminho interno (desvio existente) é corrigida para o barrel público ([R4](research.md)). | ✅ |
| II. SOLID, DRY, KISS | Um único usecase novo; reaproveita o `SessionValidationService` sem duplicar regra de sessão; sem abstrações extras. | ✅ |
| III. TDD | Testes antes do código: usecase (8 linhas da tabela), controller (decisão + paralelismo), widget tests do splash e do onboarding, teste de chaves i18n. Tudo offline com fakes. | ✅ |
| IV. Stack e DI | Só pacotes já adotados; registro no `SplashModule.registerServices`; controller via `ChangeNotifierProvider`; texto novo por `easy_localization`. | ✅ |
| V. Erros tipados, sem strings mágicas | Destino como enum; decisão sobre encerrar a sessão continua centralizada no `ApiClient`; o usecase não lança. Usecase sem `Either` justificado em [R1](research.md) (não existe `Failure` que a UI precise distinguir). | ✅ |

**Pós-design (Phase 1)**: reavaliado após o data-model e o contrato; nenhum desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/004-splash-onboarding-sessao/
├── spec.md
├── plan.md                       # este arquivo
├── research.md                   # R1–R7
├── data-model.md                 # entradas, transições e tabela de decisão
├── quickstart.md                 # validação automática e no aparelho
├── contracts/
│   └── splash-navigation.md      # rotas e interfaces internas
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks (ainda não criado)
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── core/i18n/app_strings.dart                    # + splashTagline
├── modules/
│   ├── onboarding/
│   │   └── onboarding.dart                       # + export do CheckOnboardingSeenUseCase
│   └── splash/
│       ├── domain/usecases/
│       │   └── validate_stored_session_usecase.dart   # NOVO
│       ├── presentation/
│       │   ├── controller/
│       │   │   ├── splash_controller.dart        # paralelismo + decisão por sessão
│       │   │   └── splash_destination.dart       # NOVO (enum com path)
│       │   └── pages/splash_page.dart            # frase de apoio; go(destination.path)
│       └── splash_module.dart                    # registra o usecase
assets/translations/{pt-BR,en-US}.json            # + splash_tagline

test/modules/
├── splash/
│   ├── domain/usecases/validate_stored_session_usecase_test.dart
│   ├── presentation/controller/splash_controller_test.dart
│   ├── presentation/pages/splash_page_test.dart
│   └── fakes/                                    # fakes dos dois usecases / do serviço
└── onboarding/
    ├── fakes/fake_onboarding_repository.dart
    ├── presentation/controller/onboarding_controller_test.dart
    ├── presentation/pages/onboarding_page_test.dart
    └── presentation/i18n_keys_test.dart          # chaves splash_/onboarding_
```

**Structure Decision**: segue os módulos existentes. O splash ganha a camada `domain/` só com o
usecase (sem `data/`: não acessa dados próprios). Nada muda em `common/`, `main.dart` ou
`app_router.dart`.

## Ordem sugerida (para o `/speckit-tasks`)

1. **US1 + US2 (P1)**, juntas por compartilharem o controller: teste e implementação do usecase →
   enum → testes e implementação do controller → registro no módulo → página → widget test do
   splash.
2. **US3 (P2)**: fake do repositório → testes do controller do onboarding → widget test da
   página → teste das chaves i18n (com `splash_tagline`).
3. **Polimento**: `flutter analyze`, suíte completa, quickstart no aparelho
   e marcar a A1 no tasks do produto.

## Complexity Tracking

Nenhuma violação a justificar.
