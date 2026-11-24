# Contrato: fim do módulo, aviso e conclusão

**Feature**: [spec.md](../spec.md) · **Data model**: [data-model.md](../data-model.md)

Sem pedidos novos ao serviço (research R0). O contrato é o comportamento das telas e da rota de
login, que os widget tests verificam.

## 1. Rotas

| Rota | Quem abre | Parâmetros | Volta |
|---|---|---|---|
| `/activities/:moduleId/done` | `LessonPage` (`push`) | `extra: ModuleCompletion` | `CompletionAction?` |
| `/login?mode=register&next=/activities` | `LessonPage`, pelo aviso (`push`) | `mode`, `next` | entrou → `go(next)`; voltou → `null` |

`/activities/:moduleId/done` sem `extra` → volta às atividades. `/login` sem parâmetros: igual
a hoje (modo "Entrar", vai para `/home`). `next` que não começa com `/` (ou começa com `//`) é
ignorado.

## 2. Painel de feedback na última pergunta

| Situação | Botão | Ação |
|---|---|---|
| Nem todas respondidas | "Voltar às atividades" | `FeedbackAction.finish` (B3) |
| Todas respondidas | "Ver resultado" | `FeedbackAction.result` |

## 3. Aviso do visitante (`showGuestProgressAlert`)

- Só sem conta (`!isAuthenticated`), antes da conclusão; nunca com conta.
- Título `activities_guest_alert_title` (anunciado), texto `activities_guest_alert_body`.
- "Criar conta" → `createAccount`; "Continuar sem conta" → `continueWithoutAccount`; voltar →
  `null` (= continuar). Não lê sozinho; não chama a rede.

## 4. Conclusão (`CompletionPage`)

- `AppBar` com o título do módulo; troféu; `activities_completion_title` (`liveRegion`).
- `activities_completion_score` só com pontuação (`total > 0`).
- Mensagem da faixa (`perfect` / `good` / `retry`).
- `ListenButton` (some sem voz); leitura automática uma vez se ligada.
- "Voltar às atividades" (primário) → `finish`; "Compartilhar" → menu do aparelho (uma vez por
  toque, sem aviso de erro); "Refazer o módulo" → `redo`; voltar do aparelho → `null` (=
  `finish`).
