# Implementation Plan: Conclusão do módulo e aviso de login

**Branch**: `020-conclusao-modulo-atividades` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/020-conclusao-modulo-atividades/spec.md`

**Base**: tarefa B4 do [tasks do produto](../../.specify/memory/tasks.md),
[especificação do produto](../../.specify/memory/specification.md) 2.4.0 (RF-029, RF-030, RN-005,
RN-006), [contrato da API](../../.specify/memory/api-contract.md) 1.1.2,
[constituição](../../.specify/memory/constitution.md), código das features 003, 007, 015, 017 e
018.

## Summary

Dar um fim ao módulo:

- **Quando** ([R1](research.md#r1-quando-o-módulo-está-concluído)): na última pergunta, com todas
  respondidas, o painel de feedback da B3 mostra "Ver resultado".
- **Conclusão** ([R2](research.md#r2-tela-de-conclusão-como-rota-empilhada-sobre-as-perguntas),
  [R5](research.md#r5-resultado-e-mensagem)–[R8](research.md#r8-layout)): `CompletionPage` em
  `/activities/:moduleId/done`, com a pontuação que a B3 já tem (sem pedido novo, R0), mensagem
  por faixa, compartilhar, refazer, voltar e voz.
- **Visitante** ([R3](research.md#r3-aviso-do-visitante)): aviso antes da conclusão; "Criar conta"
  abre o login em modo cadastro e, ao entrar, vai para Atividades
  ([R4](research.md#r4-login-que-abre-em-criar-conta-e-volta-para-atividades)); o progresso vai
  para a conta nova pela transferência da B1.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes (`go_router`, `provider`, `get_it`, `easy_localization`,
`lucide_icons_flutter`, `share_plus` via `ShareService`, `flutter_tts` via
`TextToSpeechService`). Nenhuma nova.

**Storage**: nenhum.

**Testing**: `flutter_test`; `FakeShareService`, `FakeTextToSpeechService` (`test/fakes/`); fakes
do `activities`; `UserSessionService` real; widget tests com `pumpLocalized` e `GoRouter` de teste.

**Target Platform**: Android e iOS · **Project Type**: mobile-app

**Performance Goals**: conclusão (ou aviso) em até 1 s depois de "Ver resultado", sem rede
(SC-001).

**Constraints**: aviso só sem conta e sempre antes da conclusão (RN-006); nunca "0 de 0";
48 dp/16 sp, semântica, letra e alto contraste da B9; textos pt-BR/en-US; o `activities` não
importa `authentication` nem `shell` (só o texto da rota `/login`).

**Scale/Scope**: no `activities`, ~3 arquivos novos (página da conclusão, aviso, extensão) e ajustes no controller, painel de feedback, página das perguntas e rotas; no
`authentication`, a rota e a `LoginPage` (dois parâmetros opcionais); ~14 chaves de i18n;
~4 arquivos de teste novos e ~4 ajustados.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | Tudo de atividades fica no `activities`; o `authentication` só ganha parâmetros opcionais na própria rota; nenhum módulo importa outro (o caminho `/login` é texto, como o `guest_progress_notice` já faz). Controller só com usecases; voz e compartilhar pelos serviços do `common`, como na notícia e nas perguntas. | ✅ |
| II. SOLID, DRY, KISS | Sem pedido novo (R0); `ListenButton`, `ShareService`, `ReadAloudController` e a transferência da B1 reaproveitados; a `LessonPage` continua dona da navegação (R2). | ✅ |
| III. TDD | Testes antes do código para controller, extensão, login, painel, aviso, conclusão e fluxo da página. | ✅ |
| IV. Stack e DI | Sem dependência nova; nada novo no `GetIt` além do que já existe. | ✅ |
| V. Erros tipados | Ações e faixas por `enum`; textos por chave. Não há falha nova (sem rede). | ✅ |
| Regras globais | Mudança no `authentication` (feature 003) justificada pela clarificação 1 e coberta pelos testes do login. | ✅ |

**Pós-design (Phase 1)**: reavaliado; sem desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/020-conclusao-modulo-atividades/
├── spec.md · plan.md · research.md (R0–R9) · data-model.md · quickstart.md
├── contracts/completion-flow.md
├── checklists/requirements.md
└── tasks.md                     # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── core/i18n/app_strings.dart                         # + activities_completion_*, activities_guest_alert_*, activities_feedback_result
├── modules/authentication/presentation/
│   ├── routes/authentication_routes.dart              # /login lê mode e next
│   └── pages/login_page.dart                          # initialMode, next
└── modules/activities/presentation/
    ├── controller/lesson_controller.dart              # + isModuleCompleted
    ├── extensions/completion_presentation.dart        # NOVO: ModuleCompletionTier, faixa, texto falado, texto de compartilhar
    ├── pages/lesson_page.dart                         # fim do módulo: aviso → conclusão → finish/redo
    ├── pages/completion_page.dart                     # NOVO: ModuleCompletion, CompletionAction
    ├── widgets/feedback_sheet.dart                    # + FeedbackAction.result ("Ver resultado")
    ├── widgets/guest_progress_alert.dart              # NOVO: GuestAlertAction
    └── routes/activities_routes.dart                  # + :moduleId/done
assets/translations/{pt-BR,en-US}.json

test/modules/activities/presentation/{controller,extensions,pages,widgets} ·
test/modules/authentication/presentation/pages/login_page_test.dart ·
test/core/routing/app_router_test.dart (+ /activities/m1/done)
```

**Structure Decision**: continua no `activities`; o `authentication` recebe só o necessário para
abrir em "Criar conta" e voltar para Atividades.

## Fora do código

- **Avisar o outro desenvolvedor**: `/login` passa a aceitar `?mode=register&next=…` (opcionais;
  sem eles, nada muda).
- **Tasks do produto**: ao fechar, marcar a B4 e a Trilha B de atividades (B1–B4) como completa.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; tipos e extensão; `isModuleCompleted`; `FeedbackAction.result`.
2. **US1 (conclusão)**: `CompletionPage` (conteúdo, faixas, voltar), rota, fluxo da `LessonPage`
   para quem tem conta.
3. **US2 (aviso)**: `GuestProgressAlert`; login com `mode`/`next`; fluxo do visitante.
4. **US3 (compartilhar)**.
5. **US4 (refazer)**.
6. **Voz na conclusão** (clarificação 3, dentro da US1 ou no polimento).
7. **Polimento**: letra 2× e inglês, `/revisar-pr` na branch, suíte, quickstart no aparelho,
   marcar a B4.

Um commit por história.

## Complexity Tracking

Sem violações da constituição.
