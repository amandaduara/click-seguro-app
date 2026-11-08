# Implementation Plan: Fluidez, movimento e estados de carregamento

**Branch**: `022-fluidez-movimento` | **Date**: 2026-11-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/022-fluidez-movimento/spec.md`

## Summary

Dar ao app uma camada de movimento única, que respeita "Reduzir animações", e corrigir os
defeitos de UX achados na revisão. O trabalho tem quatro partes:

1. **Fundação**:
   - toolchain Android atualizado;
   - fonte Montserrat embutida;
   - tokens `AppMotion` com a opção "Reduzir animações";
   - transições de página com volta preditiva;
   - fade-through entre abas.
2. **Correções**:
   - feed estável ao atualizar;
   - feed que acompanha a conta e as interações;
   - toque no botão central;
   - semântica de botão.
3. **Estados**: esqueletos (`skeletonizer`) e troca animada entre carregando, conteúdo, vazio e
   erro nas seis telas de primeira carga.
4. **Polimento**:
   - prévia no detalhe;
   - imagens leves;
   - curtir animado;
   - microinterações no login, onboarding, lição, assistente, barra inferior e botões.

A técnica segue o `fuja_app` (ver [research.md](research.md)).

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.47 (stable)
**Primary Dependencies**:
- já usadas: `go_router`, `provider`, `get_it`, `easy_localization`, `lucide_icons_flutter`;
- **novas**: `animations`, `skeletonizer` (R2).

**Storage**: `shared_preferences` (nova preferência `reduceMotion`, via
`AccessibilityLocalDataSource`)
**Testing**: `flutter_test` (unitários + widget, harness `pumpLocalized`); validação manual no
emulador `fuja_api36` (Android 16)
**Target Platform**: Android (principal), iOS e web (build do gh-pages)
**Project Type**: mobile-app (Flutter, módulos em `lib/modules/`)
**Performance Goals**: 60 fps nas transições e na rolagem do feed e dos Reels num aparelho de
entrada; título do detalhe em < 0,3 s (SC-005)
**Constraints**:
- público idoso: animações ≤ 400 ms, sem loops decorativos;
- tudo desligável (FR-010);
- WCAG AA e alto contraste preservados;
- letra até 200%.

**Scale/Scope**: cerca de 20 telas; seis com esqueleto de primeira carga

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Situação | Como |
|---|---|---|
| I. Módulos e camadas | ✅ | Tokens, esqueleto, imagem e vibração em `lib/core/` (transversais). O stream de interações nasce no `NewsRepositoryImpl` e chega aos controllers por `WatchNewsInteractionsUseCase` (Controller → UseCase → Repository). A preferência fica no módulo `settings`, como as demais. |
| II. SOLID/DRY/KISS | ✅ | Um `SafeStateSwitcher` e um `SafeSkeleton` para todas as telas, um `SafeNetworkImage` para todos os `Image.network`. O stream de interações tem dois consumidores reais (feed e Reels). |
| III. TDD | ✅ | Testes antes ou junto da lógica nova (R15). A suíte atual deve ficar verde a cada fase. |
| IV. Stack oficial | ✅ com registro | `animations` e `skeletonizer` não concorrem com nada da stack, então não exigem emenda. Ficam registradas em research R2 e no README. Strings novas no `easy_localization`. |
| V. Erros tipados | ✅ | Falha na recarga do feed vira `FeedMessage` com chave de `Failure`, sem string mágica. |
| Segurança | ✅ | Nada sensível. A fonte vem com licença OFL no repositório. |

**Pós-design**: reavaliado depois de data-model e contracts; sem violações. A Complexity
Tracking fica vazia.

## Project Structure

### Documentation (this feature)

```text
specs/022-fluidez-movimento/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-components.md
└── tasks.md            # /speckit-tasks
```

### Source Code (click_seguro_app/)

```text
android/                                   # R14: gradle-wrapper, settings.gradle.kts, app/build.gradle.kts
assets/fonts/montserrat/                   # R1: TTFs + OFL.txt
lib/
├── main.dart                              # AppMotionScope + AnnotatedRegion no builder
├── core/
│   ├── theme/app_motion.dart              # NOVO: tokens + AppMotionScope (R3)
│   ├── theme/app_theme.dart               # pageTransitionsTheme (R4), fonte
│   ├── routing/app_router.dart            # StatefulShellRoute + TabBranchContainer, AppFadePage (R4, R5)
│   ├── routing/app_fade_page.dart         # NOVO
│   ├── routing/tab_branch_container.dart  # NOVO
│   ├── utils/app_haptics.dart             # NOVO (R13)
│   └── widgets/
│       ├── safe_skeleton.dart             # NOVO (R8)
│       ├── safe_state_switcher.dart       # NOVO (R8)
│       ├── safe_network_image.dart        # NOVO (R11)
│       ├── safe_button.dart               # semântica, pressão mínima, switcher (R13)
│       └── safe_card.dart                 # idem
└── modules/
    ├── common/accessibility/              # reduceMotion na entidade
    ├── settings/                          # modelo, datasource, página de Acessibilidade
    ├── shell/presentation/                # app_shell (extendBody), app_bottom_nav (R12, FR-025)
    ├── news/
    │   ├── domain/usecases/watch_news_interactions_usecase.dart   # NOVO (R7)
    │   ├── data/repositories/news_repository_impl.dart            # stream de interações
    │   └── presentation/                  # feed (R6/R7), reels (R10/R11/R13), detalhe (R9)
    ├── activities/presentation/           # esqueleto do painel, lição (R13)
    ├── profile/ · notifications/          # esqueletos
    ├── authentication/presentation/       # login (AnimatedSize)
    ├── onboarding/presentation/           # indicador contínuo
    ├── splash/presentation/               # entrada do logo
    └── assistant/presentation/            # balão digitando, entrada das mensagens
test/                                      # espelha lib/ (R15)
```

**Structure Decision**: app Flutter único em `click_seguro_app/`, com a organização por
módulos da Constituição §I. Componentes transversais entram em `lib/core/`; o que é de uma
funcionalidade fica no módulo dela.

## Fases de implementação

| Fase | Conteúdo | Histórias | Depende de |
|---|---|---|---|
| 0 | Toolchain Android e roteiro de execução no emulador | FR-032 | — |
| 1 | Fonte Montserrat; `AppMotion` e preferência "Reduzir animações"; transições de página e abas | US2, FR-001 | 0 |
| 2 | Correções do feed (estável, sessão, interações), botão central, semântica do botão e do cartão | US1 | 1 |
| 3 | `SafeSkeleton` e `SafeStateSwitcher` nas seis telas | US3 | 1 |
| 4 | Prévia do detalhe e Hero, saída da splash, carrossel → Reels | US4 | 1, 3 |
| 5 | `SafeNetworkImage`, pré-carregamento, barra de status | US6 | 1 |
| 6 | Microinterações (curtir, lição, login, onboarding, barra, assistente, botão) | US5 | 1 |

Cada fase termina com `flutter analyze` limpo, a suíte verde e verificação no emulador.

## Complexity Tracking

Sem violações.
