# Data Model: Alertas locais de notícias novas

Formato do serviço e do registro local em [contracts/alerts.md](contracts/alerts.md). Decisões em
[research.md](research.md). Nada daqui existe hoje no módulo `notifications` (só o esqueleto da
F0.7); o módulo **não importa** `news`, `shell`, `authentication` nem `profile`.

## Domínio

### `AlertEntity` (novo)

| Campo | Tipo | Regra |
|---|---|---|
| `newsId` | `String` | chave do alerta: no máximo um alerta por `newsId`; vira `/news/<newsId>` |
| `title` | `String` | não vazio |
| `source` | `String` | não vazio |
| `publishedAt` | `DateTime` | `publishedAt` do serviço; sem ela, `originalPublishedAt`; guardado em UTC |
| `isRead` | `bool` | `false` ao criar; `true` ao abrir ou marcar |

`copyWith(isRead:)`. Igualdade por `newsId` (dois alertas da mesma notícia são o mesmo).

### `AlertsSnapshot` (novo)

O que a conta tem guardado no aparelho.

| Campo | Tipo | Regra |
|---|---|---|
| `lastCheckAt` | `DateTime?` | `null` = nenhuma conferência ainda (próxima é a "primeira vez") |
| `receiveAlerts` | `bool?` | último valor de "Receber alertas" visto no serviço; `null` = desconhecido |
| `alerts` | `List<AlertEntity>` | do mais novo ao mais antigo (`publishedAt`), sem repetir `newsId`, no máximo `maxAlerts = 50`, todos dentro de `retentionDays = 30` |

Derivados (extension, testáveis): `unreadCount` (alertas com `isRead == false`), `isEmpty`,
`markRead(newsId)`, `markAllRead()`, `merge(candidates, now)` (ver abaixo).

### Constantes (domínio)

`maxAlerts = 50`, `retentionDays = 30`, `autoCheckInterval = 5 min` (no controller, não no
domínio).

### `CheckNewAlertsResult` (novo)

| Campo | Tipo | Regra |
|---|---|---|
| `snapshot` | `AlertsSnapshot` | estado depois da conferência |
| `outcome` | `CheckOutcome` | `firstRun`, `disabled`, `updated` (havendo ou não alertas novos) |

### Use cases (cada um repassa ao `NotificationsRepository`)

- **`CheckNewAlertsUseCase.call(now)`** → `Either<Failure, CheckNewAlertsResult>`. Passos:
  1. lê o registro; **sem `lastCheckAt`** (primeira vez, outro dono, ilegível) → grava
     `lastCheckAt = now`, devolve `firstRun`, sem pedir nada ao serviço (FR-003);
  2. consulta `receiveAlerts` no serviço; **falha → devolve a falha, sem gravar** (FR-005);
  3. `receiveAlerts == false` → grava `lastCheckAt = now` e `receiveAlerts = false`, devolve
     `disabled` (FR-006);
  4. pede as notícias com `since = max(lastCheckAt, now − 30 dias)` e `limit = 50`; **falha →
     devolve a falha, sem gravar**;
  5. **lê o registro de novo** (R5), descarta candidatos com `publishedAt <= lastCheckAt` (rede
     de segurança do R0) e com `newsId` já existente (e repetidos na própria resposta);
  6. `merge`: junta existentes + candidatos, remove `publishedAt < now − 30 dias`, ordena por
     `publishedAt` decrescente, mantém 50;
  7. grava `{ lastCheckAt = now (início da conferência), receiveAlerts = true, alerts }` numa
     escrita só e devolve `updated`.
- **`GetAlertsUseCase`** → `Either<Failure, AlertsSnapshot>` (registro do dono atual; vazio se
  não houver).
- **`MarkAsReadUseCase(newsId)`** → marca um (id inexistente → sem efeito, sem erro).
- **`MarkAllAsReadUseCase`** → marca todos.
- **`ClearAlertsUseCase`** → apaga o registro (sair da conta).

> **Divergência do backlog**: o backlog lista `GetUnreadCount`; aqui o contador é derivado do
> `AlertsSnapshot` (`unreadCount`), porque o controller já guarda a lista. Um use case só repetiria a
> conta. Registrar no plano do produto ao fechar a tarefa. `ClearAlertsUseCase` é novo (FR-019).

### `NotificationsRepository` (interface, domínio)

| Método | Retorno | Observação |
|---|---|---|
| `getSnapshot()` | `Either<Failure, AlertsSnapshot>` | só local; ilegível/outro dono → vazio |
| `saveSnapshot(AlertsSnapshot)` | `Either<Failure, Unit>` | só local; falha vira `CacheFailure` |
| `fetchNewAlerts({since, limit})` | `Either<Failure, List<AlertEntity>>` | rede; item inválido ignorado |
| `getReceiveAlerts()` | `Either<Failure, bool>` | rede (`GET /users/me`) |
| `clear()` | `Either<Failure, Unit>` | só local |

## Dados

### `AlertModel` (novo)

- `fromNewsJson(Map)`: lê `id`, `title`, `source` e `publishedAt` (ISO-8601) ou, sem ela,
  `originalPublishedAt`. Falta `id`/`title`/`source` ou nenhuma data → lança `FormatException`
  (o datasource captura e **ignora o item**, R9).
- `fromJson`/`toJson`: formato do registro local (`newsId`, `title`, `source`, `publishedAt`,
  `isRead`). `toEntity()` e `AlertModel.fromEntity`.

### `AlertsSnapshotModel` (novo)

`fromJson(record)` ↔ `toJson()` do registro abaixo; `lastCheckAt` e `receiveAlerts` opcionais;
`alerts` ausente ou item ilegível → item descartado.

### Registro local — `notifications_alerts_v1` (`LocalCacheService`)

```json
{
  "owner": "pessoa@exemplo.com",
  "lastCheckAt": "2026-10-09T15:00:00.000Z",
  "receiveAlerts": true,
  "alerts": [
    { "newsId": "cmuy…", "title": "…", "source": "…", "publishedAt": "2026-10-09T14:10:00.000Z", "isRead": false }
  ]
}
```

- `owner`: e-mail da sessão. Ler com dono diferente, sem registro ou ilegível → "sem registro".
  Visitante (`guest`) nunca grava nem lê.
- Ordem: do mais novo ao mais antigo; no máximo 50; nenhum com mais de 30 dias.
- Gravado **sempre inteiro** (uma escrita por operação). `clear()` remove a chave.

### Constantes (dados)

`AlertsLocalDataSourceImpl.cacheKey = 'notifications_alerts_v1'`;
`AlertsRemoteDataSourceImpl.newsPath = '/app/news'`, `mePath = '/users/me'`,
`checkLimit = 50` (igual a `maxAlerts`).

## Apresentação

### `NotificationsController` (novo, único, acima do app)

| Estado | Tipo | Notas |
|---|---|---|
| `status` | `AlertsStatus` | `loading` (lendo o registro no início), `ready` |
| `alerts` | `List<AlertEntity>` | do snapshot; vazio sem conta |
| `unreadCount` | `int` | derivado; `0` sem conta |
| `isChecking` | `bool` | só para impedir conferência dupla (nenhuma tela mostra indicador) |
| `lastCheckFailure` | `Failure?` | só `ConnectionFailure` conta para a faixa de "sem internet" da tela |
| `receiveAlerts` | `bool?` | do snapshot; `false` → aviso "alertas desligados" |
| `lastAutoCheckStartedAt` | `DateTime?` | controla o intervalo de 5 minutos |

Ações: `load()` (lê o registro; chamado na criação, se houver conta); `checkNew({force})`;
`markAsRead(newsId)`; `markAllAsRead()`; reação a `sessionStatus` (`authenticated` → `load` +
`checkNew`; `guest`/`unauthenticated` → zera estado e, em `unauthenticated`, `ClearAlerts`).
Operações que gravam passam por uma fila (R5). Visitante: nenhuma ação chega ao repositório.

Transições: criação com conta → `loading` → `ready` (alertas do registro) → `checkNew` em
segundo plano → `ready` com os alertas novos. `markAsRead`: atualiza a lista em memória **na
hora**, depois grava; falha ao gravar mantém o estado em memória (o app continua útil; o
registro se acerta na próxima gravação).

### `AlertsLifecycleTrigger` (novo, privado no módulo ou em `presentation/controller/`)

Observador do ciclo de vida: `resumed` → `controller.checkNew()`. Descarta o observador no
`dispose`.

### `AlertSection` e `AlertsGrouping` (extension, novo)

`AlertSection { AlertGroup group; List<AlertEntity> alerts }`, `AlertGroup { today, yesterday,
earlier }`. `List<AlertEntity>.sections(now)` agrupa pela data local de `publishedAt`, mais novos
primeiro, sem seção vazia; data futura → `today`.

### `AlertPresentation` (extension sobre `AlertEntity`, novo)

`timeLabel(now)`: `HH:mm` (hoje/ontem) ou `dd/MM` (anteriores); `semanticLabel(now)`: "Novo, título,
fonte, hora/data" (sem "Novo" se lido). `summaryText(unreadCount)`: chave i18n com plural
("Você tem 3 alertas novos", "Você tem 1 alerta novo", "Você não tem alertas novos").

### Widgets

- `NotificationBellButton` (alterado): círculo de 48 dp + contador (`unreadCount > 0`,
  círculo mínimo 24 dp, texto em negrito); rótulo "Alertas" ou "Alertas, N novos".
- `NotificationsPage` (alterada): `AppBar` com voltar; corpo por estado — convite (sem conta),
  resumo + botão + faixas + lista agrupada, ou vazio.
- `AlertTile` (novo): cartão tocável com "Novo", título, fonte e hora/data; ≥ 48 dp.
- `AlertsSummaryBar` (novo): resumo e botão "Marcar todos como lidos" (fixos).
- `AlertsNotices` (novo): faixas fixas "sem internet" e "alertas desligados" com botão.

## Regras → requisitos

| Regra | Onde | Requisito |
|---|---|---|
| Primeira conferência só marca o horário | `CheckNewAlertsUseCase` passo 1 | FR-003 |
| Um alerta por `newsId` | `merge` + passo 5 | FR-002, SC-002 |
| 50 alertas / 30 dias | `merge` | FR-004 |
| Falha não avança o horário | passos 2 e 4 | FR-005 |
| Chave desligada | passo 3 | FR-006, FR-017 |
| Visitante sem conferência | controller | FR-007 |
| Agrupamento | `AlertsGrouping` | FR-011 |
| Limpeza ao sair e por dono | controller + `owner` | FR-018, FR-019 |
