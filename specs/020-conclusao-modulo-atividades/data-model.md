# Data Model: Conclusão do módulo e aviso de login

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Research**: [research.md](research.md)

Sem entidades de domínio novas e sem dados novos do serviço (R0).

## 1. Apresentação (`activities/presentation`)

| Tipo | Campos / valores | Regras |
|---|---|---|
| `ModuleCompletion` (novo) | `title`, `score: ModuleScoreEntity?` | montado pela `LessonPage` com `module.title` e `controller.score` |
| `ModuleCompletionTier` (enum novo) | `perfect`, `good`, `retry` | `score == total` → `perfect`; `score * 2 >= total` → `good`; senão `retry`; sem pontuação → `good` |
| `CompletionAction` (enum novo) | `finish`, `redo` | devolvido pela `CompletionPage`; `null` (voltar do aparelho) = `finish` |
| `GuestAlertAction` (enum novo) | `createAccount`, `continueWithoutAccount` | devolvido pelo aviso; `null` (voltar) = continuar |
| `FeedbackAction` (B3) | + `result` | "Ver resultado" na última pergunta com o módulo concluído |

Onde ficam (padrão da B3, como o `FeedbackAction` no `feedback_sheet.dart`): `ModuleCompletion`
e `CompletionAction` em `pages/completion_page.dart`; `GuestAlertAction` em
`widgets/guest_progress_alert.dart`; `ModuleCompletionTier` e a extensão
`ModuleCompletionPresentation` (`tier`, `messageKey`, `spokenText`, `shareText`, R5) em
`extensions/completion_presentation.dart`.

### `LessonController` (B3, estendido)

| Membro | Regra |
|---|---|
| `isModuleCompleted` | módulo carregado, com lições, e todas `isCompleted` |

### `LessonPage` (B3, estendida) — fluxo do fim

```text
painel de feedback (última pergunta)
  ├─ isModuleCompleted = false → "Voltar às atividades" → pop (B3)
  └─ isModuleCompleted = true  → "Ver resultado"
        ├─ com conta → conclusão
        └─ sem conta → aviso
              ├─ criar conta → push /login?mode=register&next=/activities
              │     ├─ entrou → login vai para /activities (pilha sai)
              │     └─ voltou → conclusão
              └─ continuar / voltar → conclusão
conclusão → finish / voltar → pop para o painel · redo → load (primeira pergunta)
```

## 2. Autenticação (`authentication/presentation`, mudança mínima)

- Rota `/login`: `mode` (`register` → `AuthMode.register`; outro valor ou ausente → login) e
  `next` (só se começar com `/` e não com `//`).
- `LoginPage({AuthMode initialMode = AuthMode.login, String? next})`: aplica o modo depois do
  `reset()` do primeiro quadro; ao entrar, `context.go(next ?? '/home')`.

## 3. i18n (pt-BR / en-US)

| Chave | pt-BR |
|---|---|
| `activities_feedback_result` | Ver resultado |
| `activities_completion_title` | Módulo concluído! |
| `activities_completion_score` | Você acertou {} de {} |
| `activities_completion_perfect` | Parabéns! Você acertou todas e está pronto para reconhecer esses golpes. |
| `activities_completion_good` | Muito bem! Você já sabe se proteger desses golpes. |
| `activities_completion_retry` | Bom começo! Refaça o módulo para fixar o que aprendeu. |
| `activities_completion_share` | Compartilhar |
| `activities_completion_redo` | Refazer o módulo |
| `activities_completion_share_text` | Concluí o módulo {} no {} e acertei {} de {} perguntas! Aprenda a se proteger de golpes também. |
| `activities_completion_share_text_no_score` | Concluí o módulo {} no {}! Aprenda a se proteger de golpes também. |
| `activities_guest_alert_title` | Guarde seu progresso |
| `activities_guest_alert_body` | Sem conta, seu progresso vale só até fechar o app. Crie uma conta agora e ele fica guardado. |
| `activities_guest_alert_create` | Criar conta |
| `activities_guest_alert_continue` | Continuar sem conta |

`activities_feedback_finish` ("Voltar às atividades", B3) é reaproveitada na conclusão.
