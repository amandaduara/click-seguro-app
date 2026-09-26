# SafeNews — Plano Técnico de Arquitetura

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 2.0.0

**Criado em**: 2026-09-07

**Status**: Rascunho (Draft)

**Alinhado a**: [constitution.md](constitution.md) v1.1.0 (o COMO), [specification.md](specification.md)
v2.0.0 (o QUE, com IDs `RF-/RNF-/RN-/CB-`) e [api-contract.md](api-contract.md) (endpoints
esperados, a confirmar). Como escrever cada camada está no
[guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md). Este plano diz **o
que** existe e **onde**; o guia diz **como** escrever.

## Nota de alinhamento

**v2.0.0 (2026-09-26)**: o plano passa a seguir o wireframe do Lovable e a divisão em duas
trilhas (A: conteúdo e notícias; B: educação, ajuda e conta). O módulo `fact_check` saiu da v1
(ver §8 da especificação). A camada de dados já definida na v1.1.0 continua valendo:
`Either<Failure, T>`, `ApiClient` injetado por construtor, `ApiErrorType`, `presentation/`.

**Já existe no código:** `common` (ApiClient, ApiException/ApiErrorType, toFailure,
UserSessionService em memória, EnvironmentConfig, ModuleManager), `core/errors` (Failures),
`core/theme`, `core/widgets` (SafeButton, SafeCard, SafeTextField, SafeBadge), `splash` e
`onboarding` completos (flag local de onboarding visto = RN-004), `authentication` com página
placeholder e style guide (`lib/style_guide/`, publicado no GitHub Pages).

### Dependências novas (Seção IV da constituição)

| Pacote | Uso | Por que não dá com o que já existe |
|---|---|---|
| `flutter_secure_storage` | token de sessão (RNF-007) | `shared_preferences` não criptografa |
| `flutter_tts` | leitura em voz alta (RF-015, RF-024, RF-040) | Flutter não tem TTS nativo |
| `url_launcher` | ligar (RF-032) e abrir fonte no navegador (RF-017) | exige integração com a plataforma |
| `share_plus` | compartilhar notícia/conquista (RF-016, RF-029) | menu nativo de compartilhamento |
| `image_picker` | foto do contato e do perfil (RF-033, RF-036) | câmera/galeria nativas |
| `path_provider` | salvar fotos no diretório do app (RN-007) | caminho de documentos da plataforma |

`shared_preferences` já é dependência direta. Cada pacote de plataforma MUST ficar atrás de um
serviço com interface em `common/services/`, para que os testes usem fakes (Seção III).

---

## 1. Módulos

### 1.1 Mapa de módulos

| Módulo | Trilha | Camadas | Conteúdo |
|---|---|---|---|
| `common` | Fase 0 | infra | ApiClient, sessão, storages, serviços de plataforma, voz, ModuleManager |
| `shell` | Fase 0 | presentation | `AppShell` (TopBar + BottomNav), `requireAccount`/`AccountRequiredSheet` |
| `splash` | A1 | presentation | já existe. Passa a decidir entre onboarding, login e home |
| `onboarding` | A1 | data/domain/presentation | já existe |
| `authentication` | A2 | data/domain/presentation | login, cadastro, visitante, recuperar senha |
| `news` | A3, A4, A5 | data/domain/presentation | feed, busca, Reels, detalhe, favoritos, curtidas |
| `notifications` | A6 | data/domain/presentation | lista, não lidas, `NotificationBellButton` |
| `activities` | B1–B4 | data/domain/presentation | painel, lições, exercícios, conclusão |
| `help` | B6 | data/domain/presentation | contatos oficiais (asset) e pessoais (local) |
| `profile` | B7 | data/domain/presentation | perfil, estatísticas, conquistas, edição |
| `settings` | B8, B9 | data/domain/presentation | configurações, alterar senha, acessibilidade |

B5 do wireframe ("tela antiga de atividades") não tem equivalente no Flutter: só o fluxo novo
(B1–B4) é implementado.

### 1.2 Estrutura interna de cada módulo

Segue o §3 do guia de integração:

```
lib/modules/{modulo}/
├── {modulo}.dart                 # barrel PÚBLICO: module, páginas e o que outros módulos podem usar
├── {modulo}_module.dart
├── data/{datasources,models,repositories}/
├── domain/{entities,enums,failures,repositories,usecases}/
└── presentation/
    ├── controller/  extensions/  pages/  widgets/
    └── routes/{modulo}_routes.dart   # List<RouteBase> do módulo (ver §2)
```

`test/` espelha `lib/` (Seção III da constituição).

### 1.3 Regras de dependência entre módulos

- Um módulo só importa outro pelo **barrel público** (`package:click_seguro_app/modules/x/x.dart`),
  nunca por arquivo interno. O que não está no barrel é privado do módulo.
- Dependências permitidas na v1 (e só estas):
  - `splash` → `onboarding` (usecase `CheckOnboardingSeenUseCase`, já existe) e `common` (sessão).
  - `shell` → `notifications` (`NotificationBellButton`).
  - `news` → nenhuma. Atividades relacionadas usam só a rota `/activities/:moduleId` (§2).
  - `profile` → nenhuma. As estatísticas vêm de `GET /me/profile`, não de outros módulos.
  - Todo módulo → `common` e `core`.
- `common` e `core` não dependem de nenhum módulo de feature.

### 1.4 Registro no `main.dart`

Na Fase 0 **todos** os módulos são criados como esqueleto e registrados de uma vez. Assim, as
trilhas não precisam mais tocar no `main.dart`:

```dart
await moduleManager.registerModules([
  CommonModule(),          // ApiClient, sessão, storages, serviços de plataforma
  SettingsModule(),        // AccessibilityController precisa existir antes do MaterialApp
  AuthenticationModule(),
  OnboardingModule(),
  SplashModule(),
  NewsModule(),
  NotificationsModule(),
  ActivitiesModule(),
  HelpModule(),
  ProfileModule(),
  ShellModule(),
]);
```

---

## 2. Navegação (go_router)

`lib/core/routing/app_router.dart` só **compõe** as listas de rotas dos módulos
(`...newsRoutes, ...activitiesRoutes`). Cada módulo é dono do seu `presentation/routes/`.

As abas usam `StatefulShellRoute.indexedStack` (o estado de cada aba é preservado), com o
`AppShell` como casca:

| Caminho | Tela | Módulo | Onde abre |
|---|---|---|---|
| `/` | Splash | splash | raiz |
| `/onboarding` | Onboarding | onboarding | raiz |
| `/login` | Login/Cadastro | authentication | raiz |
| `/forgot-password` | Recuperar senha | authentication | raiz |
| `/home` | Feed | news | **aba 1** |
| `/activities` | Painel de atividades | activities | **aba 2** |
| `/help` | Central de ajuda | help | **aba 3** |
| `/profile` | Perfil | profile | **aba 4** |
| `/reels?start=:newsId` | Reels | news | tela cheia, sem abas |
| `/news/:id` | Detalhe | news | sobre as abas |
| `/notifications` | Notificações | notifications | sobre as abas |
| `/activities/:moduleId` | Lições → exercícios → conclusão | activities | sobre as abas |
| `/help/contact/new`, `/help/contact/:id` | Formulário de contato | help | sobre as abas |
| `/profile/edit` | Editar dados e foto | profile | sobre as abas (também aberta por Configurações → Dados pessoais) |
| `/settings`, `/settings/account`, `/settings/security`, `/settings/accessibility` | Configurações | settings | sobre as abas |

As abas e seus ícones MUST ser conferidos com o `BottomNav` do wireframe na tarefa F0.9. Os
**caminhos** acima são o contrato entre as trilhas e MUST NOT mudar sem combinar.

**Decisão do splash** (A1): onboarding não visto → `/onboarding`; sessão restaurada
(`authenticated` ou `guest`) → `/home`; senão → `/login`.

**Ações restritas ao visitante** (RN-003): nada de `redirect` global. A ação chama
`requireAccount(context)` (em `shell`), que abre o `AccountRequiredSheet` (convite para entrar
ou se cadastrar) e devolve `false` para visitante, antes de qualquer usecase. A aba Perfil, para
visitante, mostra o mesmo convite no lugar do conteúdo.

---

## 3. Estado global e serviços comuns

### 3.1 Sessão — `UserSessionService` (Fase 0)

- `UserSessionStatus` ganha o valor `guest` (RF-005/RF-007).
- Persistência do token no `SecureStorageService`; `restoreSession()` chamado no `_setup()`
  antes do `runApp`.
- API pública: `token`, `userId`, `userName` (saudação do feed, RF-009), `sessionStatus` (`ValueNotifier`), `saveSession`,
  `startGuestSession`, `logout`, `isAuthenticated`, `isGuest`.
- Quem chama `saveSession` é o `AuthRepositoryImpl`, depois de um login ou cadastro bem-sucedido.
  Controllers nunca falam com o serviço.
- O `go_router` escuta `sessionStatus` (`refreshListenable`): quando vira `unauthenticated`
  (logout ou 401, CB-003), vai para `/login`.

### 3.2 Acessibilidade — `AccessibilityController` (módulo `settings`, Fase 0 + B9)

- Estado: `fontScale` (1.0 / 1.15 / 1.3 / 1.5), `highContrast`, `autoReadAloud`.
- Persistido em `shared_preferences` pelo `AccessibilityRepository` (local).
- Consumido no `ClickSeguroApp`: `theme: highContrast ? AppTheme.highContrast : AppTheme.light`,
  e o `MediaQuery` recebe `textScaler` = escala do sistema × `fontScale` (RNF-004).
- Carregado no `_setup()`, antes do `runApp` (RF-041).
- Para que `news` e `activities` não dependam de `settings`, o valor em vigor também fica num
  `AccessibilityPreferencesNotifier` (`ValueNotifier<AccessibilityPreferences>`) em `common`.
  O `AccessibilityController` atualiza esse notifier, e as telas de conteúdo leem
  `autoReadAloud` dele (mesmo padrão do `UserSessionService.sessionStatus`).
- Na Fase 0 entram o controller, a persistência e a ligação no app, com a tela vazia. A tela
  de acessibilidade é a tarefa B9.

### 3.3 Serviços de plataforma (Fase 0, `common/services/`)

Cada um é um contrato abstrato + implementação + fake em `test/fakes/`:

| Serviço | Pacote | Métodos |
|---|---|---|
| `SecureStorageService` | flutter_secure_storage | `readToken`, `writeToken`, `clear` |
| `LocalCacheService` | shared_preferences | `readJson`, `writeJson`, `remove` |
| `TextToSpeechService` | flutter_tts | `isAvailable`, `speak(text, rate)`, `stop`, `isSpeaking` (stream) |
| `ExternalLauncherService` | url_launcher | `canCall`, `call(phone)`, `openUrl(url)` |
| `ShareService` | share_plus | `shareText(text)` |
| `ImageStorageService` | image_picker + path_provider | `pickFromGallery`, `pickFromCamera` → caminho salvo no diretório do app, `delete(path)` |

### 3.4 Tema

`AppTheme.highContrast` (Fase 0) com contraste AAA. O design system (`Safe*`) MUST garantir
alvo de toque ≥ 48 dp e fonte base ≥ 16 sp (RNF-003), para que as telas não precisem repetir
isso.

---

## 4. Camada de dados por feature

Todas seguem o guia: `RemoteDataSource` (ApiClient) e/ou `LocalDataSource` → `RepositoryImpl`
(→ `Either<Failure, T>`) → usecases → controller. Os endpoints estão em [api-contract.md](api-contract.md).

| Feature | Fontes | Repository | Usecases principais | Regras nos usecases |
|---|---|---|---|---|
| Auth (A2) | remote | `AuthRepository` | `Login`, `Register`, `EnterAsGuest`, `RequestPasswordReset` | RN-001 (`CredentialsValidator`) |
| Feed/Busca (A3) | remote + local (cache) | `NewsRepository` | `GetNewsFeed`, `GetCategories`, `SearchNews` | ordenação (RF-010) |
| Reels (A4) | remote | `NewsRepository` | `GetReels`, `ToggleLike` | — |
| Detalhe (A5) | remote + local (favoritos) | `NewsRepository` | `GetNewsDetail`, `ToggleFavorite`, `GetFavorites` | — |
| Notificações (A6) | remote | `NotificationsRepository` | `GetNotifications`, `GetUnreadCount`, `MarkAsRead`, `MarkAllAsRead` | agrupamento por data (RF-020) |
| Atividades (B1–B4) | remote + memória (visitante) | `ActivitiesRepository` | `GetModules`, `GetModuleDetail`, `GetProgress`, `SaveProgress`, `EvaluateAnswer`, `CalculateScore` | RN-005, RN-006, embaralhar (RF-027) |
| Ajuda (B6) | asset + local | `HelpRepository` | `GetOfficialContacts`, `GetPersonalContacts`, `SavePersonalContact`, `DeletePersonalContact` | RN-007 |
| Perfil (B7) | remote | `ProfileRepository` | `GetProfile`, `UpdateProfile`, `UpdateAvatar` | nível (RN-008) |
| Configurações (B8) | remote + sessão | `SettingsRepository` | `ChangePassword`, `Logout` (limpa a sessão via `UserSessionService`; contatos ficam, RN-007) | RN-001 na senha nova |
| Acessibilidade (B9) | local | `AccessibilityRepository` | `GetAccessibilityPreferences`, `SaveAccessibilityPreferences` | — |

Pontos específicos:

- **Offline do feed (RNF-002/CB-001):** `NewsRepositoryImpl` guarda a 1ª página sem filtro e os
  favoritos no `LocalCacheService`. Com `ApiErrorType.connection`/`timeout` devolve o cache e
  marca `lastFetchWasFromCache`. Com cache vazio, `Left(ConnectionFailure())`.
- **Busca (RNF-005):** o debounce fica no `FeedController`, e o cancelamento via `CancelToken`
  fica dentro do `NewsRemoteDataSourceImpl` (exige o parâmetro `cancelToken` no `ApiClient.get`,
  tarefa F0.2). `ApiErrorType.cancelled` é ignorado pelo repository (não vira erro na tela).
- **Exercícios:** `ExerciseEntity` é uma `sealed class` com uma subclasse por tipo
  (`MultipleChoiceExercise`, `TrueFalseExercise`, `ChecklistExercise`, `ScenarioExercise`,
  `OrderingExercise`), e o model faz o `switch` no `type` do JSON. Tipo desconhecido é descartado,
  sem quebrar o módulo (CB-012). `EvaluateAnswerUseCase` usa `switch` exaustivo sobre a sealed class.
- **Progresso do visitante (RN-006):** `ActivitiesRepositoryImpl` recebe o `UserSessionService`.
  Para `guest`, guarda o progresso num mapa em memória e não chama a API.
- **Contatos pessoais (RN-007/RNF-008):** JSON no `LocalCacheService` e fotos pelo
  `ImageStorageService`. Nada vai para a API. O logout não apaga.
- **Contatos oficiais:** `assets/data/official_contacts.json` lido pelo
  `OfficialContactsLocalDataSource`.

---

## 5. Presentation

- Controllers seguem o §6 do guia: estado somente leitura, `isLoading`/`failure`/dados, falam só
  com usecases, sem `BuildContext`.
- Regras de exibição (selo, datas "Hoje/Ontem", rótulo de nível, cor de status do módulo) ficam
  em **extensions** com teste.
- Widgets de lista recebem valores prontos (strings/flags), nunca a entity.
- Voz: um `ReadAloudController` (em `common`, Fase 0) envolve o `TextToSpeechService` com estado
  `isAvailable`/`isSpeaking`/`rate`. É usado pelo detalhe da notícia (A5) e pelas lições (B2).
  Com `autoReadAloud` ligado, a página chama `speak(...)` ao abrir (RF-040). Se a voz não estiver
  disponível, os botões de ouvir ficam ocultos (CB-008).
- Todo texto em `AppStrings` + `pt-BR.json`/`en-US.json`.

---

## 6. Trabalho em dupla e conflitos

**Dono por arquivo:** depois da Fase 0, cada módulo pertence a uma trilha (§1.1). Só o dono
edita.

**Arquivos compartilhados** (pontos de conflito) e a regra de cada um:

| Arquivo | Regra |
|---|---|
| `lib/main.dart` | Fechado depois da Fase 0 (todos os módulos já registrados). Mudança só combinada. |
| `lib/core/routing/app_router.dart` | Fechado depois da Fase 0. Cada módulo edita só o próprio `{modulo}_routes.dart`. |
| `lib/core/i18n/app_strings.dart` | Cada módulo tem um **bloco próprio** com comentário `// --- news ---` criado na Fase 0. Adicione só dentro do seu bloco. |
| `assets/translations/*.json` | Chaves prefixadas pelo módulo (`news_`, `activities_`...), inseridas logo depois da última chave do **seu** prefixo. Commits pequenos, com `pull --rebase` antes. |
| `pubspec.yaml` | Todas as dependências da v1 entram na Fase 0. Pacote novo depois disso: combinar antes. |
| `lib/core/widgets/`, `lib/core/theme/` | Componente novo no design system: combinar, fazer em commit isolado e adicionar ao style guide (C2). |
| `lib/modules/common/`, `lib/modules/shell/` | Fechados depois da Fase 0. Ajuste só combinado. |

**Branches:** `feature/<trilha>-<tarefa>` (ex.: `feature/a3-feed`) a partir de `develop`, com PR
pequeno por tarefa.

---

## 7. Fases

| Fase | Quem | Conteúdo | Pronto quando |
|---|---|---|---|
| **Fase 0 — Base comum** | as duas pessoas, juntas (ou uma, e a outra revisa) | dependências, serviços de plataforma, sessão persistente com visitante, acessibilidade global, tema alto contraste, esqueleto de todos os módulos, shell de navegação com rotas, blocos de i18n | app abre, navega entre as 4 abas vazias, `flutter test` verde |
| **Trilha A** | Dev 1 | A1–A6 | ver tasks |
| **Trilha B** | Dev 2 | B1–B4, B6–B9 | ver tasks |
| **Fase C — Integração** | as duas | C1 revisão de persistência, C2 style guide, C3 navegação/textos/acessibilidade, auditoria de requisitos | cada RF/RN/CB tem teste |

Critério de pronto de toda tarefa: teste antes (TDD), `flutter analyze` sem erro/warning novo,
`flutter test` verde e textos em i18n.

---

## Rastreabilidade

| Requisito | Módulo | Tarefa |
|---|---|---|
| RF-001, RF-002, RN-004 | splash, onboarding | A1 |
| RF-003 a RF-008, RN-001, CB-003 | authentication, common | F0, A2 |
| RF-009 a RF-012, RNF-002, RNF-005, CB-001, CB-006, CB-007 | news | A3 |
| RF-013, RF-019 (curtir) | news | A4 |
| RF-014 a RF-018, RF-019 (salvar), CB-008 | news | A5 |
| RF-020 a RF-022 | notifications, shell | A6 |
| RF-023 | activities | B1 |
| RF-024, RF-040 | activities | B2 |
| RF-025 a RF-028, RN-005, CB-012 | activities | B3 |
| RF-029, RF-030, RN-006 | activities | B4 |
| RF-031 a RF-034, RN-007, RNF-008, CB-009, CB-010 | help | B6 |
| RF-035, RF-036, RN-008 | profile | B7 |
| RF-037 | settings | B8 |
| RF-038 a RF-041, RNF-004 | settings, core/theme | F0, B9 |
| RN-003, CB-011 | shell (`requireAccount`) + cada tela restrita | F0 + A3–A6, B7 |
| RNF-003, RNF-004 | core/widgets + todas | F0, C3 |
| RNF-007 | common | F0 |

---

## Governança deste documento

Este plano é o insumo de [tasks.md](tasks.md). Desvio encontrado durante a implementação
(método a mais num contrato, rota nova, dependência nova) MUST atualizar este plano, e o
[api-contract.md](api-contract.md) quando for de API, antes de a tarefa ser marcada como concluída.

**Versão**: 2.0.0 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-09-26
