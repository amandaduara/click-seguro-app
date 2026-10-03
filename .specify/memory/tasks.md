# SafeNews — Tarefas de Implementação

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 2.0.0

**Criado em**: 2026-09-07

**Insumos**: [constitution.md](constitution.md) v1.1.0 · [specification.md](specification.md)
v2.0.0 · [plan.md](plan.md) v2.0.0 · [api-contract.md](api-contract.md) ·
[guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md) · divisão em trilhas
do wireframe do Lovable

## Como ler

- **Fase 0** é a base comum: precisa estar pronta antes das trilhas. Pode ser feita a quatro
  mãos ou por uma pessoa, com revisão da outra.
- **Trilha A** (Dev 1: conteúdo e notícias) e **Trilha B** (Dev 2: educação, ajuda e conta) rodam
  em paralelo. Uma trilha não edita módulo da outra (ver [plan.md §6](plan.md)).
- **Fase C** é a integração, feita pelas duas pessoas no final.
- Cada tarefa lista **sub-passos na ordem do guia** (contrato → model → datasource → repository →
  usecase → controller → extension → widget/página → rotas/i18n). Em todo sub-passo com código,
  o teste vem antes (Red → Green → Refactor, Seção III da constituição), com Fakes à mão.
- **Portão de API:** antes da camada `data/` de uma feature remota, a linha correspondente em
  [api-contract.md](api-contract.md) MUST estar ✅ confirmada com a API real.
- Caminhos relativos a `click_seguro_app/`.
- **Cada tarefa vira uma feature do Spec Kit** ([plan.md §6](plan.md)): `/speckit-specify` (cria a
  branch `NNN-slug` e `specs/NNN-slug/spec.md`) → `/speckit-clarify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement`. No prompt do specify, cite o ID
  da tarefa (ex.: F0.4) e os RF/RN correspondentes. Ao terminar, marque a tarefa aqui com `[x]`
  e o número da feature (ex.: `[x] F0.4 … (specs/001-sessao-persistente)`).

## Já concluído

- [x] Camada de erro HTTP padronizada: `ApiErrorType`, `errorCode`, parse seguro, `Failure`
  genéricas, `ApiException.toFailure()`, testes em `test/modules/common/api_client/`.
- [x] Camada de UI renomeada para `presentation/` em todos os módulos.
- [x] Splash e onboarding com flag local de "visto" (RN-004).
- [x] Design system inicial (`SafeButton`, `SafeCard`, `SafeTextField`, `SafeBadge`) e style guide.

---

## Fase 0 — Base comum

**Objetivo:** depois desta fase, nenhuma trilha precisa tocar em `main.dart`, `app_router.dart`,
`pubspec.yaml`, `common/` ou `shell/`.

- [x] **F0.1 Dependências e configuração de plataforma** (specs/001-sessao-persistente-visitante)
  - Adicionar `flutter_secure_storage`, `flutter_tts`, `url_launcher`, `share_plus`,
    `image_picker` e `path_provider` ao `pubspec.yaml`, com versão explícita.
  - Android: permissão `INTERNET` no `AndroidManifest.xml` principal (hoje só existe em debug;
    sem ela o build de release não acessa a API), `<queries>` para `tel:` e `https:` e
    `allowBackup="false"`. **Sem** permissão de câmera (ver research R10 da feature 001).
  - iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` e
    `LSApplicationQueriesSchemes` (`tel`, `https`) no `Info.plist`.
- [ ] **F0.2 `ApiClient` com `CancelToken`**: parâmetro opcional em `get`, com teste em que o
  cancelamento vira `ApiErrorType.cancelled` — `lib/modules/common/api_client/api_client.dart`.
- [x] **F0.3 Storages** (specs/001-sessao-persistente-visitante): `SecureStorageService` e `LocalCacheService` (contrato + impl + fake), com
  testes — `lib/modules/common/services/`.
- [x] **F0.4 Sessão persistente com visitante** (RF-005, RF-007, RNF-007) (specs/001-sessao-persistente-visitante)
  - `UserSessionStatus.guest`, `userName`, `startGuestSession()`, `isGuest`, persistência do
    token e `restoreSession()` (só local; 401 durante o uso → `expire()` com motivo `expired`).
  - **Pendente do contrato da API:** validação da sessão na abertura (`GET /users/me`) e
    renovação de credencial. Entram numa feature própria quando confirmados.
  - Testes: restaurar, salvar, visitante, logout.
  - Registrar no `CommonModule` e chamar `restoreSession()` no `_setup()` do `main.dart`.
- [ ] **F0.5 Serviços de plataforma e voz**
  - `TextToSpeechService`, `ExternalLauncherService`, `ShareService` e `ImageStorageService`
    (contrato + impl + fake em `test/fakes/`).
  - `ReadAloudController` (`isAvailable`, `isSpeaking`, `rate`, `speak`, `stop`), com teste usando
    o fake de TTS (CB-008: indisponível → `isAvailable = false`).
- [ ] **F0.6 Acessibilidade global** (RF-038 a RF-041, infraestrutura)
  - Módulo `settings`: `AccessibilityPreferences` (entity), `AccessibilityRepository` (local),
    usecases get/save, `AccessibilityController`, com testes.
  - `AccessibilityPreferencesNotifier` em `common`, atualizado pelo controller.
  - `AppTheme.highContrast` e ligação no `ClickSeguroApp` (tema + `textScaler`). Carregar no
    `_setup()`.
- [ ] **F0.7 Esqueleto de todos os módulos**: `news`, `notifications`, `activities`, `help`,
  `profile`, `settings`, `shell`, cada um com `{modulo}_module.dart`, barrel, `presentation/routes/`
  e página placeholder. Registrar todos no `main.dart` na ordem do [plan.md §1.4](plan.md).
- [ ] **F0.8 Blocos de i18n**: em `AppStrings`, um bloco comentado por módulo; nos JSONs, uma chave
  inicial por prefixo (`news_title`, `activities_title`...); chaves comuns (`common_try_again`,
  `common_empty`, `common_offline_banner`, `common_account_required_*`).
- [ ] **F0.9 Shell de navegação**
  - `StatefulShellRoute.indexedStack` com as 4 abas (conferir rótulos e ícones com o `BottomNav`
    do wireframe) e `AppShell` (TopBar + BottomNav).
  - Slot do sino na TopBar com `NotificationBellButton` placeholder exportado pelo barrel de
    `notifications` (A6 implementa).
  - `app_router.dart` compondo `...{modulo}Routes` com todas as rotas do [plan.md §2](plan.md)
    apontando para placeholders.
  - `refreshListenable` na sessão: `unauthenticated` → `/login` (CB-003).
  - `requireAccount(context)` + `AccountRequiredSheet` (RN-003/CB-011), com widget test.
- [ ] **F0.10 Estados comuns no design system**: `SafeLoadingState`, `SafeErrorState` (mensagem +
  "Tentar novamente"), `SafeEmptyState` e `SafeOfflineBanner`. Garantir 48 dp/16 sp nos `Safe*`
  (RNF-003). Adicionar ao style guide.
- [ ] **F0.11 Testes base**: substituir `test/widget_test.dart` por um smoke test que sobe o app
  com fakes e navega pelas 4 abas.
- [ ] **F0.12 Contrato da API**: revisar [api-contract.md](api-contract.md) com a API real. As
  linhas que não puderem ser confirmadas agora ficam como ⚠️, e cada trilha confirma as suas no
  primeiro sub-passo da tarefa.

**Checkpoint Fase 0:** o app abre no aparelho, passa pelo splash, entra como visitante, navega
pelas 4 abas vazias, muda fonte/contraste pela infraestrutura, e `flutter analyze`/`flutter test`
estão limpos.

---

## Trilha A — Conteúdo e Notícias (Dev 1)

Módulos: `splash`, `onboarding`, `authentication`, `news`, `notifications`.

- [ ] **A1 Splash + onboarding** (RF-001, RF-002, RN-004)
  - Teste + ajuste do `SplashController`: onboarding não visto → `/onboarding`; sessão
    `authenticated`/`guest` → `/home`; senão `/login`.
  - Testes do `OnboardingController` (hoje sem teste).
  - Conferir textos e slides com o wireframe.
- [ ] **A2 Login / cadastro / visitante / recuperar senha** (RF-003 a RF-006, RN-001)
  - Confirmar os endpoints de auth no api-contract.
  - `UserEntity` + `UserModel` com teste.
  - `AuthRemoteDataSource` + impl com teste (`FakeHttpClientAdapter`).
  - `AuthRepositoryImpl`: chama `saveSession` no sucesso; 401 no login → `InvalidCredentialsFailure`;
    409 no cadastro → `EmailAlreadyExistsFailure`; demais → `toFailure()`. Com teste.
  - `CredentialsValidator` (RN-001) com teste.
  - `LoginUseCase`, `RegisterUseCase` (valida antes da rede), `EnterAsGuestUseCase`,
    `RequestPasswordResetUseCase`, com testes.
  - `AuthenticationController` (modo login/cadastro, mostrar senha, `isLoading`/`failure`) com
    teste.
  - `LoginPage` (alternância, ícones, olho da senha, "Entrar como visitante") e
    `ForgotPasswordPage`, com widget test. Remover `LoginPlaceholderPage`.
- [ ] **A3 Feed (Início)** (RF-009 a RF-012, RNF-002, RNF-005, CB-001, CB-006, CB-007)
  - Confirmar `/news` e `/news/categories`.
  - `VeracityStatus` com `fromJson` tolerante, `NewsEntity`, `CategoryEntity` e models, com teste.
  - `NewsRemoteDataSource` + impl (feed, categorias, busca com cancelamento), com teste.
  - `NewsLocalDataSource` (cache da 1ª página e favoritos) sobre `LocalCacheService`, com teste.
  - `NewsRepositoryImpl` com fallback offline e `cancelled` ignorado, com teste.
  - `GetNewsFeedUseCase` (ordenação), `GetCategoriesUseCase`, `SearchNewsUseCase`, com teste.
  - `FeedController`: categoria, paginação sem duplicar, fim da lista, busca com debounce,
    `isFromCache`. Com teste.
  - `NewsPresentationExtension` (rótulo/cor do selo, data relativa) com teste.
  - Widgets `NewsCardWidget`, `CategoryFilterBar`, `ReelsCarousel` e `FeedPage` (saudação,
    loading, erro, vazio, banner offline), com widget test.
- [ ] **A4 Reels** (RF-013, RF-019 curtir)
  - Confirmar `/reels` e `/news/{id}/like`.
  - `GetReelsUseCase` e `ToggleLikeUseCase`, com teste.
  - `ReelsController` com teste.
  - `ReelsPage` com `PageView` vertical (swipe), botões de navegação, curtir/salvar (visitante →
    `requireAccount`) e abrir fonte (`ExternalLauncherService`), com widget test.
- [ ] **A5 Detalhe da notícia** (RF-014 a RF-019, CB-008)
  - Confirmar `/news/{id}` e `/me/favorites`.
  - `GetNewsDetailUseCase`, `ToggleFavoriteUseCase` e `GetFavoritesUseCase` (cache offline), com
    teste.
  - `NewsDetailController` com teste.
  - `NewsDetailPage`:
    - ouvir com velocidade (`ReadAloudController`) e leitura automática se `autoReadAloud`;
    - compartilhar (`ShareService`);
    - abrir fonte no navegador externo;
    - salvar (visitante → `requireAccount`);
    - bloco de atividades relacionadas → `context.push('/activities/$moduleId')`.
    - Com widget test.
- [ ] **A6 Notificações** (RF-020 a RF-022)
  - Confirmar os endpoints `/me/notifications*`.
  - `NotificationEntity`/model, datasource e repository, com testes.
  - Usecases `GetNotifications`, `GetUnreadCount`, `MarkAsRead`, `MarkAllAsRead`, e o agrupamento
    Hoje/Ontem/Anteriores num usecase ou extension testável.
  - `NotificationsController` com teste.
  - `NotificationBellButton` real (contador; visitante → `requireAccount`) e `NotificationsPage`
    (grupos, "marcar todas como lidas", tocar → marcar lida e abrir a notícia se houver
    `newsId`), com widget test.

---

## Trilha B — Educação, Ajuda e Conta (Dev 2)

Módulos: `activities`, `help`, `profile`, `settings`.

- [ ] **B1 Atividades: painel** (RF-023)
  - Confirmar `/modules` e `/me/progress`.
  - `ModuleSummaryEntity`, `ModuleProgressEntity` e models, com teste.
  - `ActivitiesRemoteDataSource` + impl, com teste.
  - `ActivitiesRepositoryImpl` com progresso em memória para visitante (RN-006), com teste.
  - `GetActivitiesDashboardUseCase` (junta módulos + progresso, calcula progresso geral e status
    de cada módulo), com teste.
  - `ActivitiesDashboardController` com teste.
  - Extension de status (rótulo, cor, ícone) com teste.
  - `ModuleCardWidget` e `ActivitiesDashboardPage`, com widget test.
- [ ] **B2 Atividades: lições** (RF-024, RF-040)
  - Confirmar `/modules/{id}`.
  - `ModuleDetailEntity` e `LessonEntity` + models, com teste.
  - `GetModuleDetailUseCase` e `MarkLessonReadUseCase` (salva progresso), com teste.
  - `LessonController` (passo atual, avançar/voltar, lidas) com teste.
  - `LessonContentPage` com ouvir e leitura automática, com widget test.
- [ ] **B3 Atividades: exercícios e feedback** (RF-025 a RF-028, RN-005, CB-012)
  - `ExerciseEntity` como `sealed class` (5 tipos) + model com `switch` no `type` e tipo
    desconhecido descartado, com teste de cada tipo.
  - `EvaluateAnswerUseCase` (switch exaustivo) com teste por tipo.
  - `ShuffleExerciseUseCase` (recebe `Random` para ser testável).
  - `CalculateScoreUseCase` (acertos na 1ª tentativa; guarda a melhor), com teste.
  - `QuizController` (exercício atual, resposta, confirmar, feedback, avançar), com teste.
  - Widgets por tipo: `MultipleChoiceWidget`, `TrueFalseWidget`, `ChecklistWidget`,
    `ScenarioWidget` e `OrderingWidget` (arrastar para reordenar, com alternativa por botões
    para acessibilidade). Também `ConfirmAnswerFooter` e `FeedbackSheet`. Com widget tests.
- [ ] **B4 Atividades: conclusão e aviso de login** (RF-029, RF-030, RN-006)
  - `CompletionPage` (pontuação, compartilhar conquista via `ShareService`).
  - `GuestProgressAlert` antes da conclusão, para visitante, com botões "Criar conta" e "Continuar
    sem salvar".
  - Widget tests dos dois fluxos (cadastrado e visitante).
- [ ] **B6 Central de ajuda** (RF-031 a RF-034, RN-007, RNF-008, CB-009, CB-010)
  - Definir a lista de contatos oficiais com a orientação do TCC (ex.: 190, 197, Procon, canais
    de bancos) em `assets/data/official_contacts.json`.
  - `ContactEntity` (oficial/pessoal) + models, com teste.
  - `OfficialContactsLocalDataSource` (asset) e `PersonalContactsLocalDataSource`
    (`LocalCacheService` + `ImageStorageService`), com teste.
  - `HelpRepositoryImpl` com teste.
  - Usecases get oficiais/pessoais, salvar e remover (apaga a foto junto), com teste.
  - `HelpController` e `ContactFormController` (validação de nome/telefone), com teste.
  - `HelpPage` (abas "Oficiais" e "Meus contatos", ligar; sem telefonia → número com copiar) e
    `ContactFormPage` (foto circular de galeria/câmera; permissão negada → salva com iniciais;
    remover com confirmação), com widget test.
- [ ] **B7 Perfil** (RF-035, RF-036, RN-008)
  - Confirmar `/me/profile`, `PATCH /me/profile` e `/me/avatar`. Se `/me/avatar` não existir,
    a foto de perfil fica local via `ImageStorageService`: atualizar o api-contract.
  - `ProfileEntity`, `StatsEntity`, `AchievementEntity`, `LevelEntity` + models, com teste.
  - Datasource e repository, com teste.
  - `GetProfileUseCase` (calcula o nível, RN-008), `UpdateProfileUseCase`, `UpdateAvatarUseCase`,
    com teste.
  - `ProfileController` e `EditProfileController`, com teste.
  - Extension de nível/conquista com teste.
  - `ProfilePage` (cartão, selo, estatísticas, conquistas, atalhos; visitante → convite) e
    `EditProfilePage` (`/profile/edit`), com widget test.
- [ ] **B8 Configurações** (RF-037)
  - Confirmar `/me/change-password`.
  - `SettingsRepositoryImpl` com `changePassword` e `logout` (via `UserSessionService`, sem
    apagar contatos, RN-007), com teste.
  - `ChangePasswordUseCase` (RN-001 na nova senha) e `LogoutUseCase`, com teste.
  - `SettingsController` e `ChangePasswordController`, com teste.
  - `SettingsPage` com as linhas:
    - Dados pessoais → `/profile/edit`;
    - Notificações → `/notifications`;
    - Segurança → `/settings/security`;
    - Acessibilidade → `/settings/accessibility`;
    - Sair (com confirmação).
  - `ChangePasswordPage`. Widget tests.
- [ ] **B9 Acessibilidade** (RF-038 a RF-041)
  - `AccessibilityPage`: seletor de tamanho de fonte com prévia ao vivo, alto contraste e leitura
    automática. Usa a infraestrutura da F0.6.
  - Widget test: mudar a opção reflete no app e persiste (fake do `LocalCacheService`).

---

## Fase C — Integração (as duas pessoas)

- [ ] **C1 Persistência**: revisar, no aparelho, o que precisa sobreviver ao fechar o app: sessão,
  favoritos e último feed (offline), progresso de atividades (cadastrado), contatos com fotos,
  acessibilidade e flag de onboarding. Cada item tem teste. Lacuna encontrada vira tarefa.
- [ ] **C2 Style guide**: incluir os componentes novos das trilhas e os estados comuns; conferir o
  tema de alto contraste.
- [ ] **C3 Integração final**
  - Fluxos ponta a ponta:
    - visitante → atividade → aviso → cadastro;
    - notícia → atividade relacionada;
    - notificação → notícia;
    - 401 → login.
  - Revisão de textos pt-BR e en-US.
  - Auditoria de acessibilidade (RNF-003/RNF-004): `Semantics` em todo interativo, TalkBack, fonte
    em 1,5× sem overflow, contraste AA/AAA.
  - Teste em aparelho físico, com build de release.
- [ ] **C4 Auditoria de requisitos**: para cada RF/RNF/RN/CB da especificação v2.0.0, apontar o
  teste que o cobre (tabela de rastreabilidade do plan). Lacuna vira tarefa antes da entrega.

---

## Sugestão de ordem

| Semana | Base / Dev 1 | Dev 2 |
|---|---|---|
| 0 | Fase 0 (juntos) | Fase 0 (juntos) |
| 1 | A1, A2, A3 | B1, B2, B3 |
| 2 | A4, A5, A6 | B4, B6, B7 |
| 3 | apoio em C1 + revisão cruzada de PRs | B8, B9 |
| 4 | C1–C4 (juntos) | C1–C4 (juntos) |

Dependências entre trilhas (as únicas):
- A5 (atividades relacionadas) só precisa da **rota** `/activities/:moduleId`, criada na F0.9. Não
  espera B2 ficar pronta.
- B8 "Notificações" só precisa da **rota** `/notifications` (F0.9).
- B7 e B8 usam `/profile/edit`, que é da própria trilha B.

---

## Notas

- Tarefa que precisar de endpoint diferente do api-contract: atualize o contrato (e o plan, se
  mudar um repository) antes de marcar a tarefa como concluída.
- Evite PRs grandes: um PR por sub-bloco (ex.: "A3 data", "A3 presentation") facilita a revisão
  da outra pessoa.
- As tarefas da versão 1.x (checagem colaborativa) estão preservadas no histórico do Git e na §8
  da especificação, para a v2.

**Versão**: 2.0.0 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-09-26
