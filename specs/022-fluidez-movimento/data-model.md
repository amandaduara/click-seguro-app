# Data Model: Fluidez, movimento e estados de carregamento

## AccessibilityPreferences (alterada)

`lib/modules/common/accessibility/accessibility_preferences.dart`

| Campo | Tipo | Padrão | Novo? |
|---|---|---|---|
| fontScale | FontScaleLevel | standard | — |
| highContrast | bool | false | — |
| autoReadAloud | bool | false | — |
| readingSpeed | ReadingSpeed | normal | — |
| **reduceMotion** | bool | **false** | ✅ |

- `copyWith`, `==` e `hashCode` incluem `reduceMotion`.
- O `AccessibilityPreferencesModel` lê e grava a chave nova. Uma preferência guardada antes desta
  versão (sem a chave) é lida como `false`.

## AppMotion (novo, só de apresentação)

`lib/core/theme/app_motion.dart`

| Membro | Normal | Reduzido |
|---|---|---|
| short | 150 ms | 0 |
| medium | 250 ms | 0 |
| long | 350 ms | 0 |
| reduced | false | true |

Curvas (constantes): `enter`, `exit`, `standard`, `emphasis`.

`reduced = preferências.reduceMotion || MediaQuery.disableAnimations`.

## FeedController (estado alterado)

| Estado | Antes | Depois |
|---|---|---|
| status | loading em toda carga | loading **só sem lista**; recargas mantêm `loaded` |
| isRefreshing | — | `true` durante uma recarga com lista na tela |
| messages | — | `Stream<FeedMessage>` (falha na recarga, com a chave da `Failure`) |

Transições:

```text
initial ──load──▶ loading ──ok──▶ loaded ◀──────────────┐
                     │                │ refresh/categoria/busca/sessão
                     └─falha─▶ error  ▼                  │
                                 loaded+isRefreshing ─ok─┘
                                       └─falha─▶ loaded (lista mantida) + FeedMessage
```

Recarga disparada também por:

- mudança de valor em `sessionStatus` (FR-004);
- `NewsInteractionChange` recebido: corrige só o item afetado, sem recarregar (FR-005).

## NewsInteractionChange (novo, domínio)

`lib/modules/news/domain/entities/news_interaction_change.dart`

| Campo | Tipo | Observação |
|---|---|---|
| newsId | String | notícia afetada |
| isRead | bool? | `true` depois de `markAsRead` com sucesso |
| isSaved | bool? | novo valor depois de `toggleSave` com sucesso |
| isLiked / likes | bool? / int? | depois de `toggleLike` com sucesso |

`null` = campo não mudou. Publicado só depois de sucesso, pelo `NewsRepository.interactionChanges`
(`Stream`, difusão) e lido via `WatchNewsInteractionsUseCase`.

## Prévia da notícia (rota)

`/news/:id` aceita `extra` do tipo `NewsDetailPreview`, com dois campos:

- `item` (`NewsItemEntity`);
- `heroTag` (`String`, no formato `news-image-<seção>-<id>`).

Sem `extra`, o detalhe abre sem prévia.
