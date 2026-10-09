# Implementation Plan: Acessibilidade global

**Branch**: `009-acessibilidade-global` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-acessibilidade-global/spec.md`

**Base**: tarefa F0.6 do [tasks do produto](../../.specify/memory/tasks.md),
[plano do produto](../../.specify/memory/plan.md) §3.2 e §3.4,
[constituição](../../.specify/memory/constitution.md) v1.1.0, `LocalCacheService` da
[feature 001](../001-sessao-persistente-visitante/plan.md), `ReadAloudController` da
[feature 007](../007-servicos-plataforma-voz/plan.md).

## Summary

- **common**: `FontScaleLevel`, `AccessibilityPreferences` e `AccessibilityPreferencesNotifier`
  ([R1](research.md)); `ReadAloudController` passa a usar a velocidade guardada ([R5](research.md)).
- **settings** (data/domain/presentation): `AccessibilityPreferencesModel`,
  `AccessibilityLocalDataSource` sobre o `LocalCacheService`, `AccessibilityRepository`,
  `GetAccessibilityPreferencesUseCase`, `SaveAccessibilityPreferencesUseCase` e
  `AccessibilityController` ([R4](research.md)).
- **core/theme**: `AppPalette` (`ThemeExtension`, light e alto contraste), `context.colors`,
  `AppTheme.highContrastTheme`; widgets migram de `AppColors.x` para `context.colors.x`
  ([R2](research.md)).
- **app**: `ClickSeguroApp` escolhe o tema e aplica a escala com teto ([R3](research.md));
  `_setup()` carrega as preferências antes do `runApp`.
- **dev**: `lib/dev/accessibility_playground.dart` para validar no emulador ([R6](research.md)).

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.6 (stable)

**Primary Dependencies**: já presentes (`shared_preferences` via `LocalCacheService`, `fpdart`,
`provider`, `get_it`). Nenhuma nova.

**Storage**: `LocalCacheService`, chave `accessibility_preferences_v1`.

**Testing**: `flutter_test`; `FakeLocalCacheService` (ganha modo de falha), fakes de repository
à mão; widget test do `ClickSeguroApp`/árvore com tema e `textScaler`; teste de contraste da
paleta.

**Target Platform**: Android e iOS · **Project Type**: mobile-app

**Performance Goals**: mudança visível em < 1 s (SC-002); carga antes do splash sem atraso
perceptível.

**Constraints**: preferências do aparelho, não da conta (FR-010); falhas de armazenamento nunca
derrubam o app (FR-009); AAA no alto contraste (FR-005).

**Scale/Scope**: ~10 arquivos de produção novos, ~35 alterados pela migração de cores, ~8 de teste.

## Constitution Check

| Princípio | Situação |
|---|---|
| I. Módulos e camadas | ✅ `settings` com data/domain/presentation; `common` não importa `settings`; `news`/`activities` leem do notifier em `common` |
| II. SOLID/DRY/KISS | ✅ uma paleta, sem `if (highContrast)` nos widgets |
| III. TDD | ✅ testes antes de cada camada; offline com fakes |
| IV. Stack | ✅ Provider + ChangeNotifier, GetIt, sem dependência nova |
| V. Erros tipados | ✅ gravação devolve `Either<CacheFailure, Unit>`; sem strings mágicas (chave e nomes em constantes) |

## Project Structure

```text
click_seguro_app/lib/
├── core/theme/app_palette.dart                       # novo
├── core/theme/app_theme.dart                         # lightTheme + highContrastTheme
├── dev/accessibility_playground.dart                 # novo (dev)
├── main.dart                                         # setupApp() público, tema e escala
└── modules/
    ├── common/accessibility/
    │   ├── accessibility_preferences.dart            # entity + FontScaleLevel
    │   └── accessibility_preferences_notifier.dart
    ├── common/presentation/controller/read_aloud_controller.dart
    └── settings/
        ├── data/datasources/accessibility_local_data_source{,_impl}.dart
        ├── data/models/accessibility_preferences_model.dart
        ├── data/repositories/accessibility_repository_impl.dart
        ├── domain/repositories/accessibility_repository.dart
        ├── domain/usecases/{get,save}_accessibility_preferences_usecase.dart
        └── presentation/controller/accessibility_controller.dart

click_seguro_app/test/
├── core/theme/app_palette_test.dart
├── accessibility_app_test.dart                       # tema e escala no app real
└── modules/settings/…                                # model, datasource, repository, usecases, controller
```

## Riscos

- **Conflito com a PR #12 (Reels)**: a migração de cores toca widgets de `news`; os widgets
  novos dos Reels também usam `AppColors`. Depois do merge da #12, rebasear e migrar
  `reel_view.dart`/`reel_actions.dart` (tarefa própria).
- **Telas com texto grande**: SC-004 é conferido no emulador; overflow encontrado vira ajuste
  pontual (ex.: `Flexible`/rolagem).
