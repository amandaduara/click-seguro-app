# Data Model: Perguntas do módulo de atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Research**: [research.md](research.md)

## 1. Domínio (`activities/domain`)

| Entidade | Campos | Regras |
|---|---|---|
| `ModuleDetailEntity` | `id`, `title`, `lessons: List<LessonEntity>` | `lessons` só com as válidas, ordenadas por `order`; `isEmpty` |
| `LessonEntity` | `id`, `order`, `question`, `imageUrl?`, `options: List<LessonOptionEntity>`, `isCompleted` | `options.length >= 2` (as outras são descartadas no model, CB-012); `withCompleted(bool)` (visitante, R3) |
| `LessonOptionEntity` | `id`, `text` | na ordem recebida (RF-027) |

Ficam de fora (R2): `explanation`, `progress` (`score`, `totalScore`, `isCompleted`), `description`,
`iconUrl`. A B3/B4 acrescentam.

Falha nova: `ModuleNotFoundFailure` (`activities/domain/failures/activities_failures.dart`), 404
`EDUCATIONAL_MODULE_NOT_FOUND`, mensagem `activities_module_unavailable` (já existe na B1: "Este
módulo ainda não tem atividades").

Repositório: `Future<Either<Failure, ModuleDetailEntity>> getModuleDetail(String moduleId)`;
usecase `GetModuleDetailUseCase`.

## 2. Dados (`activities/data`)

`ActivitiesRemoteDataSource.getModuleDetail(moduleId)` → `GET /app/educational/modules/{id}`
(`moduleDetailPath(id)`), `ModuleDetailModel.fromJson`:

- lições ordenadas por `order`; sem `id`/`question` ou com menos de 2 alternativas → descartada;
- alternativa sem `id`/`text` → descartada antes da contagem;
- `imageUrl` vazio → `null`; `isCompleted` ausente → `false`; `explanation` e `progress` ignorados.

`GuestProgressStore` ganha `bool isAnswered(String lessonId)`.

`ActivitiesRepositoryImpl.getModuleDetail`: sem conta (`!isAuthenticated`) → cada lição
`withCompleted(store.isAnswered(id))`; com conta → como veio; 404 `EDUCATIONAL_MODULE_NOT_FOUND` →
`ModuleNotFoundFailure`; demais → `toFailure()`.

## 3. Apresentação (`activities/presentation`)

### `LessonController` (`ChangeNotifier`, factory)

| Membro | Regra |
|---|---|
| `status` | `LessonStatus { loading, loaded, empty, error }` |
| `module`, `failure` | |
| `currentIndex` | começa na 1ª lição com `isCompleted == false`; todas concluídas → 0 |
| `current` | lição atual |
| `canGoPrevious` | `currentIndex > 0` |
| `canGoNext` | `current.isCompleted && currentIndex < lessons.length - 1` |
| `load(moduleId)` | `empty` se sem lições ou `ModuleNotFoundFailure`; `error` nas demais falhas |
| `goPrevious()` / `goNext()` | só se puder; notifica |

### Widgets

| Widget | Papel |
|---|---|
| `LessonPage` | a tela (`/activities/:moduleId`) |
| `LessonProgressIndicator` | "Pergunta X de Y" + marcas por pergunta |
| `LessonOptionCard` | alternativa numerada (só leitura na B2) |
| `ListenButton` (`core/widgets`) | "Ouvir"/"Parar", extraído do `ReadAloudBar` (R5) |

## 4. Textos (i18n)

| Chave | pt-BR | en-US |
|---|---|---|
| `common_listen` | Ouvir | Listen |
| `common_stop` | Parar | Stop |
| `activities_lesson_position` | Pergunta {} de {} | Question {} of {} |
| `activities_lesson_progress_semantics` | Pergunta {} de {}, {} concluídas | Question {} of {}, {} completed |
| `activities_lesson_previous` | Anterior | Previous |
| `activities_lesson_next` | Próxima | Next |
| `activities_lesson_option_spoken` | Alternativa {}: {} | Option {}: {} |

Saem: `news_detail_listen`, `news_detail_stop` (substituídas por `common_listen`/`common_stop`).
O estado "sem atividades" e a `ModuleNotFoundFailure` reaproveitam `activities_module_unavailable`
(B1).
