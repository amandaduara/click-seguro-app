---
description: "Task list for feature 009: Acessibilidade global (F0.6)"
---

# Tasks: Acessibilidade global

**Input**: Design documents from `/specs/009-acessibilidade-global/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [quickstart.md](quickstart.md)

**Tests**: **obrigatórios** (constituição, Seção III): cada teste é escrito e **falha** antes da
implementação. Offline, com `FakeLocalCacheService` (`app/test/fakes/`) e fakes à mão.

## Format: `[ID] [P?] [Story] Description`

- Caminhos: `app/` = `click_seguro_app/`; `common/` = `app/lib/modules/common/`; `settings/` =
  `app/lib/modules/settings/`; `tset/` = `app/test/modules/settings/`.

---

## Phase 1: Setup

- [ ] T001 Em `app/`, `flutter analyze` e `flutter test`: anotar a linha de base

## Phase 2: Foundational

- [ ] T002 [P] Teste `app/test/modules/common/accessibility/accessibility_preferences_test.dart`: padrões, `copyWith`, igualdade, fatores do `FontScaleLevel`, teto 2.0
- [ ] T003 [P] Implementar `common/accessibility/accessibility_preferences.dart` e `accessibility_preferences_notifier.dart`; registrar o notifier no `CommonModule`. T002 verde
- [ ] T004 [P] Teste `tset/data/accessibility_preferences_model_test.dart`: ida e volta; campo ausente/tipo errado/nome desconhecido → padrão só do campo
- [ ] T005 Teste `tset/data/accessibility_local_data_source_impl_test.dart` e `accessibility_repository_impl_test.dart`: lê/grava na chave `accessibility_preferences_v1`; leitura com exceção → padrões; gravação com exceção → `Left(CacheFailure)` (fake ganha `throwOnRead`/`throwOnWrite`)
- [ ] T006 Implementar model, datasource, repository (contrato + impl) e os usecases Get/Save em `settings/`. T004/T005 verdes, com teste dos usecases em `tset/domain/accessibility_usecases_test.dart`

## Phase 3: US2 — Preferências lembradas (P1)

- [ ] T007 [US2] Teste `tset/presentation/accessibility_controller_test.dart`: `load()` publica o salvo no notifier; sem salvo → padrões; cada `set` muda o notifier na hora e grava; gravação com falha mantém o valor; sets seguidos → último gravado
- [ ] T008 [US2] Implementar `settings/presentation/controller/accessibility_controller.dart`; registrar no `SettingsModule` (singleton + `ChangeNotifierProvider.value`); `_setup()` → `setupApp()` público e chama `load()` antes do `runApp`. T007 verde

## Phase 4: US1 — Letra maior (P1) e US3 — Alto contraste (P2)

- [ ] T009 [P] [US3] Teste `app/test/core/theme/app_palette_test.dart`: light igual a `AppColors`; alto contraste com texto ≥ 7:1 sobre fundo/card, `textPrimaryForeground` sobre `primary`/`secondary` ≥ 7:1, `border` ≥ 3:1; `lerp`/`copyWith`
- [ ] T010 [US3] Implementar `app/lib/core/theme/app_palette.dart` (+ `context.colors`) e `AppTheme.highContrastTheme`, montando os dois temas pela paleta. T009 verde
- [ ] T011 [US1][US3] Teste `app/test/accessibility_app_test.dart`: `ClickSeguroApp` com notifier → tema light/alto contraste e `textScaler` = sistema × nível, teto 2×; mudar o notifier reconstrói na hora
- [ ] T012 [US1][US3] `ClickSeguroApp`: `ValueListenableBuilder` no notifier, `theme` conforme `highContrast`, `builder` com `MediaQuery` e `TextScaler`. T011 verde
- [ ] T013 [US3] Migrar todos os widgets de `AppColors.x` para `context.colors.x` (core/widgets, routing, shell, splash, onboarding, authentication, news, notifications); `flutter test` verde

## Phase 5: US4 — Leitura automática e velocidade (P3)

- [ ] T014 [US4] Teste em `app/test/modules/common/presentation/controller/read_aloud_controller_test.dart`: sem `setSpeed`, usa `readingSpeed` do notifier; mudar o notifier vale na próxima leitura; `setSpeed` da página sobrepõe
- [ ] T015 [US4] `ReadAloudController` recebe o notifier (opcional); `CommonModule` injeta. T014 verde

## Phase 6: Polish

- [ ] T016 `app/lib/dev/accessibility_playground.dart` (app real + painel de desenvolvimento)
- [ ] T017 Ajustar o teste de fumaça (`app/test/widget_test.dart`) se preciso; `dart format` nos arquivos tocados, `flutter analyze` sem avisos novos, `flutter test` verde
- [ ] T018 Validar no emulador os passos do [quickstart.md](quickstart.md); prints e relatório em `evidencias/`
- [ ] T019 Marcar a F0.6 em `.specify/memory/tasks.md` e atualizar o design system (`AppPalette`)

## Dependencies

- T002–T006 antes de T007. T009–T010 antes de T011–T013. T014 depois de T003.
- Commit por fase.
