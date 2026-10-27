# Contrato: responder uma pergunta

**Feature**: [spec.md](../spec.md) · **Data model**: [data-model.md](../data-model.md)

Dois contratos: o pedido ao serviço (externo, já no contrato da API 1.0.10) e o comportamento da
tela de perguntas (o que os widget tests verificam).

## 1. Serviço

`POST /app/educational/modules/{moduleId}/lessons/{lessonId}/answer` · token opcional

```json
{ "selectedOptionId": "cmuywocjo000tfo1smccbiz88" }
```

| Resposta | Corpo | No app |
|---|---|---|
| 200 | `{isCorrect, correctOptionId, explanation?}` | `AnswerResultEntity`; sem token, também `recordAnswer` |
| 400 `EDUCATIONAL_INVALID_OPTION` | `{statusCode, code, message}` | `AnswerRejectedFailure` → recarrega |
| 400 `VALIDATION_ERROR` | idem | `AnswerRejectedFailure` → recarrega |
| 404 `EDUCATIONAL_LESSON_NOT_FOUND` / `EDUCATIONAL_MODULE_NOT_FOUND` | idem | `AnswerRejectedFailure` → recarrega |
| rede, 5xx, 401 | — | falha comum → mantém a escolha |

Sem token o serviço corrige e **não salva** (R0). Depois de um 200, o app pede
`GET /app/educational/modules/{moduleId}` só para a pontuação (`progress.score/totalScore`), sem
trocar as lições da tela (R3).

## 2. Tela de perguntas

| Situação | Alternativas | Rodapé | Painel |
|---|---|---|---|
| Sem escolha | tocáveis, nenhuma marcada | "Confirmar resposta" desativado | — |
| Com escolha | a escolhida `selected` | "Confirmar resposta" ativo | — |
| Enviando | não tocáveis | `loading`; aviso de serviço acordando se demorar | — |
| Falha comum | escolha mantida | ativo de novo; `SnackBar` `activities_answer_failed` | — |
| Rejeitada | módulo recarregado | — | `SnackBar` `activities_answer_rejected` |
| Respondida (agora) | correta `correct`; escolhida errada `wrong`; demais `idle` não tocáveis | "Responder de novo"; "Próxima" ativo | abre (abaixo) |
| Respondida antes da visita | tocáveis, nenhuma marcada | "Confirmar resposta"; "Próxima" ativo | — |

Painel (`FeedbackSheet`):

- não fecha com toque fora nem arrastando; o voltar do aparelho fecha e deixa a pergunta com o
  resultado;
- título com ícone: `activities_feedback_correct` ou `activities_feedback_wrong`;
- `activities_feedback_correct_option` com o texto da correta (some se a correta não estiver entre
  as alternativas);
- explicação sob `activities_feedback_explanation`, só se houver;
- `activities_feedback_score` só se houver pontuação (`total > 0`);
- `ListenButton` (some sem voz); leitura automática do mesmo texto, uma vez, se ligada;
- botão: `activities_feedback_next` → `goNext()`; na última, `activities_feedback_finish` → volta
  ao painel de atividades.

Leitor de tela: alternativa anuncia o texto e "selecionada" (estado `checked`); depois do
resultado, "correta" ou "sua resposta, errada"; o título do painel é anunciado ao abrir
(`liveRegion`).
