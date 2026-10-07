# SafeNews — Tarefas de Implementação

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 2.1.0

**Criado em**: 2026-09-07

**Insumos**: [constitution.md](constitution.md) v1.1.0 · [specification.md](specification.md)
v2.1.0 · [plan.md](plan.md) v2.1.0 · [api-contract.md](api-contract.md) v1.0.0 ·
[openapi.json](openapi.json) · wireframe em `wireframe/` (React, referência visual) ·
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
- **Portão de API:** antes da camada `data/` de uma feature remota, confira a linha em
  [api-contract.md](api-contract.md) e o schema no [openapi.json](openapi.json). Depois do
  primeiro request real que funcionar, troque 🧪 por ✅ no contrato.
- **Wireframe:** o React em `wireframe/src/components/screens/` é a referência visual (layout,
  textos, ícones). Os dados mockados dele (`mockData.ts`, `types.ts`) **não** são contrato: vale
  a API.
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
- [x] **F0.2 Ajustes do `ApiClient` à API real** (specs/002-apiclient-renovacao-sessao) — `lib/modules/common/api_client/api_client.dart`
  - Ler o código de erro de `code` (hoje lê `error`), com teste para o corpo `{code, message}` e
    para o corpo de validação do Zod (`{statusCode, message, errors}`).
  - `CancelToken` opcional em `get`, com teste em que o cancelamento vira `ApiErrorType.cancelled`.
  - `postMultipart` (upload do avatar, campo `avatar`), com teste.
  - Atualizar o §4.1 do guia de integração (`code` no lugar de `error`).
- [x] **F0.3 Storages** (specs/001-sessao-persistente-visitante): `SecureStorageService` e `LocalCacheService` (contrato + impl + fake), com
  testes — `lib/modules/common/services/`.
- [x] **F0.4 Sessão persistente com visitante** (RF-005, RF-007, RNF-007) (specs/001-sessao-persistente-visitante)
  - `UserSessionStatus.guest`, `userName`, `startGuestSession()`, `isGuest`, persistência do
    token e `restoreSession()` (só local; 401 durante o uso → `expire()` com motivo `expired`).
  - **Pendente do contrato da API:** validação da sessão na abertura (`GET /users/me`) e
    renovação de credencial. Entram numa feature própria quando confirmados.
  - Testes: restaurar, salvar, visitante, logout.
  - Registrar no `CommonModule` e chamar `restoreSession()` no `_setup()` do `main.dart`.
- [x] **F0.13 Renovação e validação da sessão** (RF-007, CB-003, CB-013, CB-014) (specs/002-apiclient-renovacao-sessao)
  - Sessão passa a guardar `accessToken` + `refreshToken` (migração do registro salvo pela
    feature 001: registro antigo sem `refreshToken` → sessão encerrada, vai ao login).
  - `ApiClient`: em 401 de request autenticado, `INVALID_CREDENTIALS` não mexe na sessão; outros
    401 tentam `POST /auth/app/refresh` uma vez (requests simultâneos esperam a mesma
    renovação) e repetem o request; falhou → `expire()`. Com testes.
  - Na abertura, depois do `restoreSession()`: `GET /users/me` atualiza o nome; 404
    `USER_NOT_FOUND` encerra a sessão; sem rede mantém a sessão local. Com testes.
  - Fecha a pendência registrada na F0.4.
- [x] **F0.5 Serviços de plataforma e voz** (specs/007-servicos-plataforma-voz)
  - `TextToSpeechService`, `ExternalLauncherService`, `ShareService` e `ImageStorageService`
    (contrato + impl + fake em `test/fakes/`).
  - `ReadAloudController` (`isAvailable`, `isSpeaking`, `speed`, `speak`, `stop`), com teste usando
    o fake de TTS (CB-008: indisponível → `isAvailable = false`).
- [ ] **F0.6 Acessibilidade global** (RF-038 a RF-041, infraestrutura)
  - Módulo `settings`: `AccessibilityPreferences` (entity), `AccessibilityRepository` (local),
    usecases get/save, `AccessibilityController`, com testes.
  - `AccessibilityPreferencesNotifier` em `common`, atualizado pelo controller.
  - `AppTheme.highContrast` e ligação no `ClickSeguroApp` (tema + `textScaler`). Carregar no
    `_setup()`.
- [x] **F0.7 Esqueleto de todos os módulos** (specs/005-shell-navegacao-base): `news`, `notifications`, `activities`, `help`,
  `profile`, `settings`, `shell`, cada um com `{modulo}_module.dart`, barrel, `presentation/routes/`
  e página placeholder. Registrar todos no `main.dart` na ordem do [plan.md §1.4](plan.md).
- [x] **F0.8 Blocos de i18n** (specs/005-shell-navegacao-base): em `AppStrings`, um bloco comentado por módulo; nos JSONs, uma chave
  inicial por prefixo (`news_title`, `activities_title`...); chaves comuns (`common_try_again`,
  `common_empty`, `common_offline_banner`, `common_account_required_*`).
- [x] **F0.9 Shell de navegação** (specs/005-shell-navegacao-base)
  - `StatefulShellRoute.indexedStack` com as 5 abas do `BottomNav` do wireframe (Reels é a aba
    central; decidido na feature 005) e `AppShell` (TopBar + BottomNav).
  - Slot do sino na TopBar com `NotificationBellButton` placeholder exportado pelo barrel de
    `notifications` (A6 implementa).
  - `app_router.dart` compondo `...{modulo}Routes` com todas as rotas do [plan.md §2](plan.md)
    apontando para placeholders.
  - `refreshListenable` na sessão: `unauthenticated` → `/login` (CB-003).
  - `requireAccount(context)` + `AccountRequiredSheet` (RN-003/CB-011), com widget test.
- [x] **F0.10 Estados comuns no design system** (specs/005-shell-navegacao-base): `SafeLoadingState`, `SafeErrorState` (mensagem +
  "Tentar novamente"), `SafeEmptyState` e `SafeOfflineBanner`. Garantir 48 dp/16 sp nos `Safe*`
  (RNF-003). Adicionar ao style guide.
- [x] **F0.11 Testes base** (specs/005-shell-navegacao-base): substituir `test/widget_test.dart` por um smoke test que sobe o app
  com fakes e navega pelas 5 abas.
- [x] **F0.12 Contrato da API** (2026-10-03): [api-contract.md](api-contract.md) v1.0.0 reescrito
  a partir do [openapi.json](openapi.json); especificação e plano ajustados (v2.1.0). As linhas
  ficam 🧪 até o primeiro request real de cada trilha.

**Checkpoint Fase 0:** o app abre no aparelho, passa pelo splash, entra como visitante, navega
pelas 5 abas vazias, muda fonte/contraste pela infraestrutura, e `flutter analyze`/`flutter test`
estão limpos.

---

## Trilha A — Conteúdo e Notícias (Dev 1)

Módulos: `splash`, `onboarding`, `authentication`, `news`, `notifications`.

- [x] **A1 Splash + onboarding** (RF-001, RF-002, RN-004) (specs/004-splash-onboarding-sessao)
  - Teste + ajuste do `SplashController`: onboarding não visto → `/onboarding`; sessão
    `authenticated`/`guest` → `/home`; senão `/login`.
  - Criar `ValidateStoredSessionUseCase` em `lib/modules/splash/domain/usecases/` (delega ao
    `SessionValidationService` do `common`, feature 002) e chamá-lo no `SplashController` em
    paralelo com o tempo mínimo do splash. A rota é decidida depois dos dois (conta desativada →
    `/login`).
  - Testes do `OnboardingController` (hoje sem teste).
  - Conferir textos e slides com o wireframe.
- [x] **A2 Login / cadastro / visitante / recuperar senha** (RF-003 a RF-006, RN-001) (specs/003-login-cadastro-visitante)
  - Depende da F0.13 (par de tokens na sessão).
  - `UserEntity` + `UserModel` (`GET /users/me`: name, email, phone, avatarUrl, role) e
    `AuthTokensModel`, com teste.
  - `AuthRemoteDataSource` + impl (`register`, `login`, `getMe`, `forgotPassword`, `verifyCode`,
    `resetPassword`) com teste (`FakeHttpClientAdapter`).
  - `AuthRepositoryImpl`: login = `login` → `getMe` → `saveSession`; cadastro = `register` →
    `login` → `getMe` → `saveSession` (a API não devolve token no cadastro). 401
    `INVALID_CREDENTIALS` → `InvalidCredentialsFailure`; `role` diferente de `USER` → idem; 409
    `USER_EMAIL_ALREADY_EXISTS` → `EmailAlreadyExistsFailure`; 401 `INVALID_RECOVERY_CODE` →
    `InvalidRecoveryCodeFailure`; demais → `toFailure()`. Com teste.
  - `CredentialsValidator` (RN-001: nome 6–150, e-mail, senha 8–64 com maiúscula, minúscula,
    número e especial) com teste.
  - `LoginUseCase`, `RegisterUseCase` (valida antes da rede), `EnterAsGuestUseCase`,
    `RequestPasswordResetUseCase`, `VerifyResetCodeUseCase`, `ResetPasswordUseCase`, com testes.
  - `AuthenticationController` (modo login/cadastro, mostrar senha, `isLoading`/`failure`) com
    teste.
  - `LoginPage` (alternância, ícones, olho da senha, "Entrar como visitante") e
    `ForgotPasswordPage` em 3 passos (e-mail → código → nova senha), com widget test. Remover
    `LoginPlaceholderPage`.
- [x] **A3 Feed (Início)** (RF-009 a RF-012, RN-002, RNF-002, RNF-005, CB-001, CB-006, CB-007) (specs/006-feed-inicio)
  - Endpoints: `/app/news/feed` (cursor), `/app/news` (categoria/busca, por página),
    `/categories`, `/app/news/reels` (carrossel).
  - `NewsEntity` (categorias, interação opcional), `CategoryEntity`, `NewsFeedEntity`
    (destaques, recomendados, recentes + cursor) e models, com teste.
  - `NewsRemoteDataSource` + impl (feed, lista filtrada, categorias, busca com cancelamento),
    com teste. Visitante chama sem token.
  - `NewsLocalDataSource` (cache da 1ª carga do feed) sobre `LocalCacheService`, com teste.
  - `NewsRepositoryImpl` com fallback offline e `cancelled` ignorado, com teste.
  - `GetNewsFeedUseCase`, `GetNewsByCategoryUseCase`, `GetCategoriesUseCase`,
    `SearchNewsUseCase`, com teste.
  - `FeedController`: categoria (troca de endpoint), paginação por cursor e por página sem
    duplicar, fim da lista, busca com debounce, `isFromCache`. Com teste.
  - `NewsPresentationExtension` (chips de categoria, data relativa de `originalPublishedAt`)
    com teste.
  - Widgets `NewsCardWidget`, `CategoryFilterBar`, `HighlightsSection`, `ReelsCarousel` e
    `FeedPage` (saudação, loading, erro, vazio, banner offline), com widget test.
- [ ] **A4 Reels** (RF-013, RF-019 curtir)
  - Endpoints: `/app/news/reels` (cursor), `POST /app/news/{id}/like` e `/save` (alternam).
  - `ReelEntity` (com `content`, `likesCount`, `isSaved`) + model, com teste. O reel não traz
    `isLiked`: o estado vem do retorno do toggle.
  - `GetReelsUseCase`, `ToggleLikeUseCase` e `ToggleSaveUseCase`, com teste.
  - `ReelsController` com teste.
  - `ReelsPage` com `PageView` vertical (swipe), botões de navegação, curtir/salvar (visitante →
    `requireAccount`) e abrir fonte (`ExternalLauncherService`), com widget test.
- [ ] **A5 Detalhe da notícia** (RF-014 a RF-019, CB-008)
  - ⚠️ Antes de começar: decidir o idioma da voz na leitura da notícia (ponto em aberto do RF-042;
    app em inglês + notícia em português).
  - Endpoints: `/app/news/{id}`, `POST /app/news/{id}/read`, `/save`,
    `GET /users/me/news/saved`.
  - `NewsDetailEntity` (+ `suggestedModule` opcional) + model, com teste.
  - `GetNewsDetailUseCase` (cadastrado: registra leitura sem bloquear a tela),
    `ToggleSaveUseCase` e `GetSavedNewsUseCase` (cache offline), com teste.
  - `NewsDetailController` com teste.
  - `NewsDetailPage`:
    - ouvir com velocidade (`ReadAloudController`) e leitura automática se `autoReadAloud`;
    - compartilhar (`ShareService`);
    - abrir fonte no navegador externo;
    - salvar (visitante → `requireAccount`);
    - bloco de atividade relacionada (só com `suggestedModule`) →
      `context.push('/activities/$moduleId')`.
    - Com widget test.
- [ ] **A6 Alertas locais** (RF-020 a RF-022) — a API não tem notificações
  - `AlertEntity` `{newsId, title, source, publishedAt, isRead}` + model, com teste.
  - `AlertsRemoteDataSource` próprio (`GET /app/news?startDate=...&sortBy=publishedAt`), sem
    importar o módulo `news`, com teste.
  - `AlertsLocalDataSource` (alertas, lidos e última verificação no `LocalCacheService`), com
    teste.
  - `NotificationsRepositoryImpl` com teste.
  - `CheckNewAlertsUseCase` (sem duplicar por `newsId`; 1ª execução só marca o horário; limite
    de 50 alertas/30 dias; respeita `receiveNotifications`), `GetAlerts`, `GetUnreadCount`,
    `MarkAsRead`, `MarkAllAsRead`, e o agrupamento Hoje/Ontem/Anteriores numa extension
    testável. Com testes.
  - `NotificationsController` com teste.
  - `NotificationBellButton` real (contador; visitante → `requireAccount`) e `NotificationsPage`
    (grupos, "marcar todas como lidas", tocar → marcar lido e abrir `/news/:id`), com widget
    test.

---

## Trilha B — Educação, Ajuda e Conta (Dev 2)

Módulos: `activities`, `help`, `profile`, `settings`.

- [ ] **B1 Atividades: painel** (RF-023, CB-012)
  - Endpoint: `GET /app/educational/modules` (o progresso já vem junto).
  - `ModuleSummaryEntity` (`completedCount`, `progressPercent`) e `ActivitiesDashboardEntity`
    (totais) + models, com teste.
  - `ActivitiesRemoteDataSource` + impl, com teste. Visitante chama sem token.
  - `ActivitiesRepositoryImpl` com `GuestProgressStore` em memória para visitante (RN-006), com
    teste.
  - `GetActivitiesDashboardUseCase` (status de cada módulo: não iniciado / em andamento /
    concluído / indisponível sem lições), com teste.
  - `ActivitiesDashboardController` com teste.
  - Extension de status (rótulo, cor, ícone) com teste.
  - `ModuleCardWidget` e `ActivitiesDashboardPage`, com widget test.
- [ ] **B2 Atividades: navegação pelas perguntas** (RF-024, RF-040, CB-012)
  - Endpoint: `GET /app/educational/modules/{moduleId}`.
  - `ModuleDetailEntity`, `LessonEntity` (pergunta, imagem, opções, concluída) e
    `ModuleProgressEntity` + models, com teste (lição com < 2 opções descartada).
  - `GetModuleDetailUseCase`, com teste.
  - `LessonController` (pergunta atual, avançar/voltar, concluídas) com teste.
  - `LessonPage` (enunciado, imagem, alternativas, ouvir enunciado + alternativas e leitura
    automática), com widget test.
- [ ] **B3 Atividades: resposta e feedback** (RF-025 a RF-028, RN-005)
  - Endpoint: `POST /app/educational/modules/{moduleId}/lessons/{lessonId}/answer`.
  - `AnswerResultEntity` `{isCorrect, correctOptionId, explanation}` + model, com teste.
  - `AnswerLessonUseCase` (cadastrado: depois recarrega o `progress`; visitante: registra no
    `GuestProgressStore`), com teste. 400 `EDUCATIONAL_INVALID_OPTION` → recarregar o módulo.
  - `QuizController` (seleção, confirmar, feedback, avançar, pontuação), com teste.
  - `MultipleChoiceWidget` (sem reordenar as opções), `ConfirmAnswerFooter` e `FeedbackSheet`
    (acerto/erro, correta destacada, explicação). Com widget tests.
- [ ] **B4 Atividades: conclusão e aviso de login** (RF-029, RF-030, RN-005, RN-006)
  - `CompletionPage` (pontuação `score/totalScore` da API, ou do `GuestProgressStore` para
    visitante; compartilhar conquista via `ShareService`).
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
  - Endpoints: `GET`/`PATCH /users/me`, `POST`/`DELETE /users/me/avatar` (multipart, F0.2),
    e para as estatísticas `GET /app/educational/modules` e `GET /users/me/news/saved?limit=1`.
  - Definir na spec da feature as faixas de nível e as regras das conquistas (RN-008, fixas no
    app).
  - `ProfileEntity`, `StatsEntity`, `AchievementEntity`, `LevelEntity` + models, com teste.
  - `ProfileRemoteDataSource` (três fontes em paralelo) e repository, com teste. 409
    `USER_EMAIL_ALREADY_EXISTS` → `EmailAlreadyExistsFailure`.
  - `GetProfileUseCase` (estatísticas, nível e conquistas), `UpdateProfileUseCase` (nome 6–150,
    e-mail, telefone `+55`), `UpdateAvatarUseCase`, `RemoveAvatarUseCase`,
    `SetReceiveAlertsUseCase`, com teste.
  - `ProfileController` e `EditProfileController`, com teste.
  - Extension de nível/conquista com teste.
  - `ProfilePage` (cartão, selo, estatísticas, conquistas, atalhos; visitante → convite) e
    `EditProfilePage` (`/profile/edit`: nome, e-mail, telefone, foto, "Receber alertas"), com
    widget test.
- [ ] **B8 Configurações** (RF-037, RF-042, CB-013)
  - Endpoint: `PATCH /users/me/change-password`. 401 `INVALID_CREDENTIALS` → "Senha atual
    incorreta" sem sair da conta (depende da F0.13); 409 `USER_NEW_PASSWORD_EQUALS_OLD`.
  - `SettingsRepositoryImpl` com `changePassword` e `logout` (via `UserSessionService`, sem
    apagar contatos, RN-007), com teste.
  - `ChangePasswordUseCase` (RN-001 na nova senha) e `LogoutUseCase`, com teste.
  - `SettingsController` e `ChangePasswordController`, com teste.
  - `SettingsPage` com as linhas:
    - Dados pessoais → `/profile/edit`;
    - Alertas → `/notifications`;
    - Segurança → `/settings/security`;
    - Acessibilidade → `/settings/accessibility`;
    - Idioma (Português/English) → troca o idioma do app na hora e salva a escolha (RF-042;
      `context.setLocale` do easy_localization, que já guarda a escolha);
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
    - alerta → notícia;
    - token vencido → renovação transparente; renovação recusada → login.
  - Revisão de textos pt-BR e en-US.
  - Auditoria de acessibilidade (RNF-003/RNF-004): `Semantics` em todo interativo, TalkBack, fonte
    em 1,5× sem overflow, contraste AA/AAA.
  - Teste em aparelho físico, com build de release.
- [ ] **C4 Auditoria de requisitos**: para cada RF/RNF/RN/CB da especificação v2.1.0, apontar o
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

- **Fora da v1 (decisão 2026-10-03):** endpoints de IA (`/app/ai/*`), contatos oficiais pela
  API, desativar conta e os quatro tipos de exercício que a API não tem. Ver §8 da
  especificação.
- Tarefa que precisar de endpoint diferente do api-contract: atualize o contrato (e o plan, se
  mudar um repository) antes de marcar a tarefa como concluída.
- Evite PRs grandes: um PR por sub-bloco (ex.: "A3 data", "A3 presentation") facilita a revisão
  da outra pessoa.
- As tarefas da versão 1.x (checagem colaborativa) estão preservadas no histórico do Git e na §8
  da especificação, para a v2.

**Versão**: 2.1.0 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-10-03
