# Implementation Plan: Padrão único para a falta de internet

**Branch**: `027-padrao-sem-internet` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/027-padrao-sem-internet/spec.md`

## Summary

A falta de internet passa a ser decidida pelo **tipo** da falha (`ConnectionFailure`), não pelo
texto. O `SafeErrorState` recebe a `Failure` e escolhe sozinho a nuvem com "Sem conexão…" ou a
tomada com o texto da tela. Uma extensão `messageKeyOr` faz o mesmo para as ações e os blocos
parciais, que hoje escondem a falta de internet atrás de "Não foi possível…". A Lição e as
Configurações passam a guardar a falha que hoje jogam fora. Os Reels ganham a paleta clara na
moldura de erro e vazio. A faixa azul ganha a variação curta para os Alertas vazios. A camada de
dados e a API não mudam. Decisões em [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (stable)

**Primary Dependencies**: as atuais (provider, go_router, easy_localization, fpdart,
lucide_icons_flutter). Nenhuma nova.

**Storage**: N/A

**Testing**: flutter_test (unidade e widget), com fakes de repositório devolvendo
`ConnectionFailure` e `ServerFailure`

**Target Platform**: Android e iOS (validação num Android real)

**Project Type**: mobile-app (Flutter, módulos por feature)

**Performance Goals**: N/A (só troca de texto e ilustração)

**Constraints**:

- Só tokens de `context.colors` (seguem o alto contraste); contraste do texto ≥ 4,5:1 nos Reels.
- Textos em pt-BR e en-US; anúncio ao leitor de tela mantido.
- Nenhuma chamada nova ao serviço; mensagens de erro do servidor inalteradas.

**Scale/Scope**:

- 2 componentes do `core` alterados (`SafeErrorState`, `SafeOfflineBanner`) e 1 extensão nova
  (`messageKeyOr`).
- 2 controllers com falha guardada (`LessonController`, `SettingsController`).
- ~14 telas ou widgets trocando o texto/a chamada (tabela R4).
- 1 chave de texto nova.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Situação |
|---|---|---|
| I. Clean Architecture e módulos | A regra comum fica no `core` (`core/errors/failure_message.dart`, `core/widgets`). Os módulos só a consomem; nenhum importa arquivo interno de outro. Nenhuma camada `data/` ou `domain/` muda. | OK |
| II. SOLID, DRY, KISS | Uma regra (`ConnectionFailure` → frase) em dois pontos: `SafeErrorState` para tela inteira e `messageKeyOr` para o resto. Reels corrigido na própria moldura, sem modo escuro genérico. | OK |
| III. TDD | Testes de unidade (`messageKeyOr`, controllers) e de widget (estado de erro, telas, faixa) com conexão **e** servidor, por história (R8). | OK |
| IV. Stack oficial | Nada novo no `pubspec.yaml`; texto novo em `AppStrings` e nos dois JSON. | OK |
| V. Erros tipados | **Melhora**: remove a comparação de texto `message == errorConnection.tr()` do `SafeErrorState`; a decisão passa a ser `is ConnectionFailure`. A extensão devolve a chave e a tela faz `.tr()`, como manda a regra das mensagens. | OK |

**Re-check pós-design (Fase 1)**: data-model sem entidade persistida; contrato de UI só muda a
assinatura de dois widgets do `core`. O gate continua passando.

## Project Structure

### Documentation (this feature)

```text
specs/027-padrao-sem-internet/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # decisões R1–R8
├── data-model.md        # falhas guardadas e escolha do aviso
├── quickstart.md        # roteiro de validação no aparelho
├── contracts/
│   └── ui-contract.md   # widgets do core, chave nova, onde cada caso aparece
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks (ainda não criado)
```

### Source Code (repository root)

```text
click_seguro_app/
├── lib/
│   ├── core/
│   │   ├── errors/
│   │   │   ├── errors.dart                         # exporta failure_message.dart
│   │   │   └── failure_message.dart                # NOVO: messageKeyOr (R3)
│   │   ├── i18n/app_strings.dart                   # commonOfflineBannerShort
│   │   └── widgets/
│   │       ├── safe_error_state.dart               # failure + message, sem comparar texto (R2)
│   │       └── safe_offline_banner.dart            # showsSavedContent (R6)
│   ├── style_guide/style_guide.dart                # exemplos com a nova assinatura
│   └── modules/
│       ├── activities/presentation/
│       │   ├── controller/lesson_controller.dart   # failure, answerFailure
│       │   └── pages/{activities_dashboard,lesson}_page.dart
│       ├── news/presentation/
│       │   ├── pages/{news_home,news_detail,user_news_list,reels}_page.dart  # nova assinatura; _Dark com paleta (R5)
│       │   └── widgets/feed_list_footer.dart       # recebe a falha do carregar mais
│       ├── notifications/presentation/widgets/alerts_notices.dart  # showsSavedContent
│       ├── profile/presentation/
│       │   ├── pages/{profile,profile_edit,achievements}_page.dart
│       │   └── widgets/achievements_section.dart
│       ├── settings/presentation/
│       │   ├── controller/settings_controller.dart # alertsFailure
│       │   ├── pages/{settings,change_password}_page.dart
│       │   └── widgets/alerts_switch_tile.dart
│       ├── help/presentation/pages/{help,contact_form}_page.dart          # nova assinatura
│       └── assistant/presentation/widgets/assistant_history_tab.dart     # nova assinatura
├── assets/translations/{pt-BR,en-US}.json          # common_offline_banner_short
└── test/                                           # espelha lib/ (R8)
```

**Structure Decision**: app Flutter único em `click_seguro_app/`. A regra compartilhada vive no
`core`; cada módulo só troca a chamada (Princípio I).

## Ordem das histórias

1. **Base**: `messageKeyOr`, nova assinatura do `SafeErrorState` com todas as chamadas
   migradas (comportamento igual nas telas que já estavam certas), `SafeOfflineBanner` com a
   variação curta e a chave de texto.
2. **US1 (P1)**: Atividades e Lição passam a falha; Reels com a paleta clara.
3. **US2 (P2)**: falha guardada na Lição (responder) e nas Configurações (alertas); textos das
   ações e blocos via `messageKeyOr` (Trocar senha, Editar perfil, Perfil, rodapés).
4. **US3 (P3)**: Alertas com `showsSavedContent`.
5. **Polimento**: suíte completa, `flutter analyze`, design-system (padrão dos três casos,
   FR-014), R4 em `.specify/memory/tasks.md`, CB-001/CB-002 na especificação do produto,
   validação no aparelho.

## Complexity Tracking

Nenhuma violação a justificar.
