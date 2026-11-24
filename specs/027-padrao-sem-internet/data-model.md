# Data Model: Padrão único para a falta de internet

Nenhuma entidade persistida nem mudança na API. Só estado de tela.

## Falha de conexão (existente)

- `ConnectionFailure` (`core/errors`), mensagem `error_connection`.
- Origem: `ApiErrorType.connection` e `ApiErrorType.timeout` (R1).
- Regra: é o **tipo** que decide o aviso (FR-001), nunca o texto.

## Estado novo nos controllers

| Controller | Campo novo | Preenchido quando | Limpo quando |
|---|---|---|---|
| `LessonController` | `Failure? failure` | `_load` falha (exceto `ModuleNotFoundFailure`, que vira vazio) | nova carga começa |
| `LessonController` | `Failure? answerFailure` | `confirm()` devolve `AnswerAttempt.failed` | próxima confirmação começa |
| `SettingsController` | `Failure? alertsFailure` | salvar os alertas falha (a falha do salvar) ou a conta não carrega (`AccountFailed.failure`) | o salvar ou a carga seguinte dá certo |

## Escolha do aviso

```text
Falha?
├── ConnectionFailure ──► frase "Sem conexão…"  (tela inteira: + nuvem)
├── outra Failure ──────► texto da tela/ação    (tela inteira: + tomada)
└── nenhuma ────────────► errorGeneric          (tela inteira: + tomada)
```

## Faixa de sem internet

| Situação | Texto |
|---|---|
| Há conteúdo guardado na tela | `common_offline_banner` (atual) |
| Alertas sem nenhum alerta guardado | `common_offline_banner_short` (novo) |
