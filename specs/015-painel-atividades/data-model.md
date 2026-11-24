# Data Model: Painel de atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Research**: [research.md](research.md)

## 1. Domínio (`activities/domain`)

### `ModuleSummaryEntity`

| Campo | Tipo | Regra |
|---|---|---|
| `id` | `String` | não vazio |
| `title` | `String` | do serviço, sem tradução |
| `description` | `String` | pode ser vazio |
| `order` | `int` | ordenação do painel |
| `iconUrl` | `String?` | vazio → `null` |
| `lessonsCount` | `int` | ≥ 0 |
| `completedCount` | `int` | limitado a `0…lessonsCount` |
| `status` | `ModuleStatus` (derivado) | ver abaixo |
| `isAvailable` | `bool` (derivado) | `status != unavailable` |
| `progress` | `double` (derivado) | `completedCount / lessonsCount`; 0 sem lições |

`ModuleStatus` (R2):

```text
lessonsCount == 0                → unavailable
completedCount == 0              → notStarted
completedCount >= lessonsCount   → completed
caso contrário                   → inProgress
```

`withCompletedCount(int)` devolve uma cópia (usado no painel do visitante).

### `ActivitiesDashboardEntity`

| Campo | Tipo | Regra |
|---|---|---|
| `modules` | `List<ModuleSummaryEntity>` | ordenados por `order` |
| `totalCompleted` | `int` | limitado a `0…totalAvailable` |
| `totalAvailable` | `int` | do serviço (já exclui módulos sem lições) |
| `isEmpty` | `bool` (derivado) | `modules.isEmpty` |
| `hasOverallProgress` | `bool` (derivado) | `totalAvailable > 0` |
| `overallProgress` | `double` (derivado) | `totalCompleted / totalAvailable` |

### `GuestAnswer`

| Campo | Tipo |
|---|---|
| `moduleId` | `String` |
| `lessonId` | `String` (chave: uma resposta por lição, a mais recente) |
| `selectedOptionId` | `String` |

### Repositório e usecase

```dart
abstract class ActivitiesRepository {
  Future<Either<Failure, ActivitiesDashboardEntity>> getDashboard();
}

class GetActivitiesDashboardUseCase // call() → repository.getDashboard()
```

Falhas: as genéricas do `core/errors` (`ConnectionFailure`, `ServerFailure`…) pelo
`api_failure_mapper`; nenhuma falha nova.

## 2. Dados (`activities/data`)

### JSON de `GET /app/educational/modules` (R0)

```json
{
  "modules": [
    { "id": "cmuy…", "title": "Golpes Digitais", "description": "…", "order": 1,
      "iconUrl": "https://res.cloudinary.com/…", "lessonsCount": 3,
      "completedCount": 0, "progressPercent": 0 }
  ],
  "totalLessonsCompleted": 0,
  "totalLessonsAvailable": 9
}
```

`ModuleSummaryModel.fromJson` / `ActivitiesDashboardModel.fromJson` → entidades. Campos ausentes:
`lessonsCount`/`completedCount` → 0; `progressPercent` ignorado (o app calcula). Módulo sem `id`
ou `title` → descartado. Lista ordenada por `order`.

### `ActivitiesRemoteDataSource`

| Método | Pedido |
|---|---|
| `getModules()` | `GET /app/educational/modules` (`requiresAuth: true`: o `ApiClient` só põe o token se houver; visitante vai sem) |
| `answerLesson({moduleId, lessonId, selectedOptionId})` | `POST /app/educational/modules/{moduleId}/lessons/{lessonId}/answer` `{selectedOptionId}` (só na transferência; o resultado é ignorado) |

### `GuestProgressStore` (singleton, só memória)

| Membro | Uso |
|---|---|
| `recordAnswer({moduleId, lessonId, selectedOptionId})` | B3; substitui a resposta da mesma lição |
| (sem lista pública das respostas) | os testes verificam por `answeredCount` e `pendingTransfer`; nada além disso é exposto |
| `answeredCount(String moduleId)` | painel do visitante |
| `pendingTransfer` | respostas a reenviar depois do cadastro |
| `removePending(GuestAnswer)` | depois de um envio com sucesso ou descartável |
| `onSignUp` (callback) | o repositório começa a transferência (R5) |

Transições (escuta `sessionStatus`, R3):

| De → para | Efeito |
|---|---|
| `guest` → `authenticated` com `startedFromSignUp` | respostas → `pendingTransfer`; `onSignUp()` |
| `guest` → `authenticated` (login) | apaga tudo |
| `guest` → `unauthenticated` | apaga tudo |
| `authenticated` → qualquer | apaga tudo (inclusive pendentes) |
| `guest` → `guest` (sem mudança de valor) | nada |

### `ActivitiesRepositoryImpl.getDashboard()`

```text
sem conta (visitante, ou sessão expirada/desconectada): GET (sem token) → troca completedCount de cada módulo por answeredCount
           → totalCompleted = soma; totalAvailable do serviço
conta:     await syncGuestAnswers() (se houver pendentes) → GET (com token) → como veio
```

`syncGuestAnswers()`: um envio por vez, um único `Future` em andamento; 2xx → remove; 404
(`EDUCATIONAL_MODULE_NOT_FOUND`/`EDUCATIONAL_LESSON_NOT_FOUND`) ou 400 → remove; outras falhas →
fica para a próxima carga. Nunca lança nem devolve falha.

## 3. Mudança no `common`: `UserSessionService` (R4)

| Membro | Antes | Depois |
|---|---|---|
| `saveSession(...)` | sem flag | `+ bool newAccount = false` |
| `startedFromSignUp` | — | `bool`, só memória; definido antes de `sessionStatus` mudar; `false` em `restoreSession`, `startGuestSession` e ao sair |

`authentication`: `AuthRepositoryImpl.register` → `_signIn(..., newAccount: true)` →
`saveSession(newAccount: true)`. O login não muda.

## 4. Apresentação (`activities/presentation`)

### `ActivitiesDashboardController`

| Membro | Regra |
|---|---|
| `status` | `ActivitiesDashboardStatus { loading, loaded, empty, error }` |
| `dashboard` | `ActivitiesDashboardEntity?` |
| `failure` | `Failure?` (no `error`) |
| `load()` | `loading` → `loaded`/`empty`/`error` |
| `refresh()` | sem `loading`; falha mantém o conteúdo; sem conteúdo → como `load()` |

### Extensão `ModuleStatusPresentation`

| Status | Chave | pt-BR | en-US | Tom do `SafeBadge` | Ícone |
|---|---|---|---|---|---|
| `notStarted` | `activities_status_not_started` | Não iniciado | Not started | `neutral` | `circle` |
| `inProgress` | `activities_status_in_progress` | Em andamento | In progress | `primary` | `circleDashed` |
| `completed` | `activities_status_completed` | Concluído | Completed | `success` | `circleCheck` |
| `unavailable` | `activities_status_unavailable` | Indisponível | Unavailable | `neutral` | `lock` |

### Widgets

| Widget | Papel |
|---|---|
| `ActivitiesDashboardPage` | a aba (substitui `ActivitiesPage`) |
| `OverallProgressCard` | "X de Y lições concluídas" + barra |
| `ModuleCard` | ícone, título, descrição, "X de Y lições", status; toque |
| `ModuleIcon` | `Image.network` com o ícone padrão |
| `GuestProgressNotice` | aviso + "Entrar ou criar conta" |

## 5. Textos novos (i18n, prefixo `activities_`)

| Chave | pt-BR | en-US |
|---|---|---|
| `activities_overall_title` | Seu progresso | Your progress |
| `activities_overall_count` | {} de {} lições concluídas | {} of {} lessons completed |
| `activities_module_count` | {} de {} lições | {} of {} lessons |
| `activities_module_unavailable` | Este módulo ainda não tem atividades | This module has no activities yet |
| `activities_status_*` (4) | ver §4 | ver §4 |
| `activities_guest_notice` | Sem conta, seu progresso vale até fechar o app. | Without an account, your progress lasts until you close the app. |
| `activities_guest_action` | Entrar ou criar conta | Sign in or create account |
| `activities_empty_title` | Ainda não há atividades | No activities yet |
| `activities_empty_body` | Volte mais tarde para aprender a se proteger de golpes. | Come back later to learn how to protect yourself from scams. |
| `activities_error_title` | Não foi possível carregar as atividades | Couldn't load the activities |
| `activities_slow` | O serviço está acordando. Isso pode levar alguns segundos. | The service is waking up. This may take a few seconds. |
| `activities_open_module` (semântica) | Abrir módulo | Open module |

"Tentar novamente" reaproveita `common_try_again`. `activities_title` e `activities_module_title`
já existem.
