---

description: "Task list for feature 012: perfil"
---

# Tasks: Perfil

**Input**: Design documents from `/specs/012-perfil/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/profile-api.md](contracts/profile-api.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): cada teste é escrito e **rodado sozinho
para ver falhar** antes da implementação. Offline: `FakeHttpClientAdapter`
(`app/test/modules/common/api_client/fake_http_client_adapter.dart`) no datasource; fakes de
repository e o `FakeImageStorageService` (`app/test/fakes/`); widget tests com `pumpLocalized`
(`app/test/helpers/localized_app.dart`) e `GetIt.instance.reset()` no `tearDown`. JSON de teste no
formato real da [R0](research.md#r0-conferência-no-servidor-real-portão-de-api).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `prof/` =
  `click_seguro_app/lib/modules/profile/`; `tprof/` = `click_seguro_app/test/modules/profile/`;
  `news/` = `click_seguro_app/lib/modules/news/`; `tnews/` = `click_seguro_app/test/modules/news/`.
- Campos, regras, falhas e chaves exatas no [data-model](data-model.md); endpoints e rotas no
  [contrato](contracts/profile-api.md); o porquê de cada decisão no [research](research.md).
- Visual: Figma "SafeNews — Perfil e Configurações (redesign)", quadros "Perfil — com conta (v4)"
  e "Perfil — visitante". Cores sempre por `context.colors` (F0.6), nunca `AppColors` direto;
  sombra só a `shadowSm` nos cartões grandes.
- Valores fictícios nos testes (`Maria da Silva`, `maria@exemplo.com`, `+5511912345678`).

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (testes, erros, warnings, infos) no fim desta tarefa. Antes, `git fetch` e conferir se a `develop` tem algo novo; se tiver, parar e avisar (o outro desenvolvedor pode estar mexendo nos mesmos arquivos). **Linha de base (2026-10-12, `HEAD` 21bf59b, develop sem novidades):** `flutter test` 1028 verdes; `flutter analyze` 28 issues, todos `info` (0 erros, 0 warnings)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos e a camada de dados do perfil, que todas as histórias usam.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 [P] Criar `tprof/fakes/profile_fixtures.dart` com `profileJson({String name = 'Maria da Silva', String email = 'maria@exemplo.com', String? phone, String? avatarUrl, bool receiveNotifications = true})` (formato do `GET /users/me` da R0, com `role: 'USER'`), `newsCountJson(int total)` (`{data: [], meta: {page:1, limit:1, total, totalPages, hasNextPage:false, hasPreviousPage:false}}`) e `modulesJson({List<Map> modules, int totalLessonsCompleted})` com `moduleJson({required String id, String title = 'Golpes Digitais', int order = 1, int lessonsCount = 3, int completedCount = 0})`
- [X] T003 [P] Criar `tprof/data/models/profile_models_test.dart`: `ProfileModel.fromJson(profileJson(phone: '+5511912345678', avatarUrl: 'https://img.test/a.png'))` → `ProfileEntity` com todos os campos; `phone`/`avatarUrl` `null` e `avatarUrl: ''` → `null`; `initials` de "Maria da Silva" = "MS", de "Ana" = "A", com espaços extras = "MS"; `ActivityProgressModel.fromJson(modulesJson(...))` → módulos com `id`, `title`, `order`, `lessonsCount`, `completedCount` (números `double` viram `int`), `lessonsCompleted` = `totalLessonsCompleted`; `isCompleted` só com `lessonsCount > 0 && completedCount >= lessonsCount`; `modulesCompleted` e `modulesWithLessons`
- [X] T004 [P] Criar `tprof/data/datasources/profile_remote_data_source_impl_test.dart` (padrão de `tnews/data/datasources/news_remote_data_source_impl_test.dart`, com `responder` do adapter quando houver vários pedidos): `getProfile` → `GET /users/me`; `getNewsCounts` faz os **três** `GET /users/me/news/{read,saved,liked}` com `{'limit': 1}` e devolve os `meta.total`; `getActivityProgress` → `GET /app/educational/modules`; `updateProfile(ProfileUpdate(name: 'Novo Nome'))` → `PATCH /users/me` com **só** `{'name': 'Novo Nome'}` (campos `null` não vão no corpo); `uploadAvatar('<tmp>/foto.png')` → `POST /users/me/avatar` multipart com o campo `avatar` e `image/png` (e `image/jpeg` para `.jpg`/`.jpeg`, `image/webp` para `.webp`), lendo `avatarUrl` da resposta 200; `removeAvatar` → `DELETE /users/me/avatar`; 409 `{code: 'USER_EMAIL_ALREADY_EXISTS'}` sobe como `ApiException` com esse `errorCode`
- [X] T005 [P] Criar `tprof/data/repositories/profile_repository_impl_test.dart` com um `FakeProfileRemoteDataSource` (T009): sucesso de cada método → `Right`; 409 `USER_EMAIL_ALREADY_EXISTS` → `EmailInUseFailure`; 400 `VALIDATION_ERROR` → `ServerFailure` (o app valida antes; a `ApiException` não traz o campo); 400 `INVALID_IMAGE_TYPE` no `uploadAvatar` → `AvatarTypeFailure`; 500 (o bug do e-mail, R0) → `ServerFailure`; conexão → `ConnectionFailure`; não autorizado → `UnauthorizedFailure`

### Implementação

- [X] T006 [P] Chaves de i18n: em `app/lib/core/i18n/app_strings.dart`, no bloco `// --- profile ---`, as constantes da tabela "Chaves de i18n" do [data-model](data-model.md#chaves-de-i18n-novas-prefixo-profile_-inglês-equivalente) (nomes em lowerCamelCase, ex.: `profileStatRead = 'profile_stat_read'`), e no bloco `// --- news ---` as `news_read_*`/`news_liked_*`; textos pt-BR da tabela em `app/assets/translations/pt-BR.json` e equivalentes em `en-US.json`. Os 4 itens do convite: "Guardar seu progresso nas atividades", "Salvar notícias para ler depois", "Receber alertas de golpes novos", "Ganhar conquistas enquanto aprende". As chaves novas já são cobertas por `app/test/modules/shell/i18n_keys_test.dart` (a expressão inclui `profile_` e `news_`)
- [X] T007 Criar as entidades em `prof/domain/entities/` (`profile_entity.dart` com `initials`, `news_counts_entity.dart`, `activity_progress_entity.dart` com `ModuleProgressEntity`, `achievement_entity.dart` com `AchievementKind`, `profile_update.dart` com `isEmpty`), as falhas em `prof/domain/failures/profile_failures.dart` (`EmailInUseFailure` e `AvatarTypeFailure`; mensagens = chaves do data-model) e os models em `prof/data/models/` (`profile_model.dart`, `activity_progress_model.dart`). Faz a T003 passar
- [X] T008 Criar `prof/data/datasources/profile_remote_data_source.dart` (contrato, dartdoc "erros sobem como `ApiException`") e `_impl.dart` com os caminhos em constantes (`mePath = '/users/me'`, `avatarPath = '/users/me/avatar'`, `newsListPath(String list) => '/users/me/news/$list'`, `modulesPath = '/app/educational/modules'`), os três totais com `Future.wait`, e o `contentType` da foto pela extensão. Faz a T004 passar
- [X] T009 Criar `prof/domain/repositories/profile_repository.dart` (interface do [contrato §3](contracts/profile-api.md#3-interface-do-módulo-profile)) e `prof/data/repositories/profile_repository_impl.dart` com um `_guard` e o mapeamento de falhas por `errorCode` (constantes `emailInUseCode = 'USER_EMAIL_ALREADY_EXISTS'` e `invalidImageCode = 'INVALID_IMAGE_TYPE'`) antes do `toFailure()` padrão. Criar `tprof/fakes/fake_profile_remote_data_source.dart` e `tprof/fakes/fake_profile_repository.dart` (filas de respostas e `Completer` opcional por método, como `FakeNewsRepository`). Registrar datasource e repository em `prof/profile_module.dart`. Faz a T005 passar

**Checkpoint**: `flutter analyze` limpo; testes de models, datasource e repository verdes.

---

## Phase 3: User Story 1 - Ver o próprio perfil (Priority: P1) 🎯 MVP

**Goal**: aba Perfil com cartão (foto/iniciais, nome, lápis), números lidas/salvas/curtidas, medalhas com "Ver todas", atalhos, convite do visitante, falha parcial e atualização ao voltar (FR-001 a FR-009, FR-021).

**Independent Test**: passos 1–4 e 14–16 do [quickstart](quickstart.md); `flutter test tprof` verde.

### Testes (escrever primeiro e ver falhar)

- [X] T010 [P] [US1] Criar `tprof/domain/achievements_calculator_test.dart` cobrindo a tabela "Regras das conquistas" do [data-model](data-model.md#regras-das-conquistas-achievementscalculator-r3): sem módulos → 5 fixas (sem `securityMaster`), todas pendentes; 1 lição → `firstLesson` alcançada; 10 lições → `dedicatedStudent`; módulo com `completedCount == lessonsCount` → `firstModule` e a do módulo alcançadas; todos os módulos com lições concluídos → `securityMaster`; módulo com `lessonsCount: 0` não gera conquista nem conta para `securityMaster`; 1 e 10 lidas → `attentiveReader`/`dedicatedReader`; `progress` limitado a 1; **ordem**: alcançadas primeiro, depois maior `progress`, empate pela ordem do enum e, entre módulos, pelo `order`
- [X] T011 [P] [US1] Criar `tprof/presentation/extensions/achievement_presentation_extension_test.dart` (com `pumpLocalized`): título de cada `AchievementKind` (o de módulo = `moduleTitle`); progresso "8 de 10 lições", "1 de 3 módulos", "4 de 10 notícias"; ícone e as duas cores da medalha por tipo (fixas por kind; as de módulo alternam entre primary, success, warning e secondary pela posição)
- [X] T012 [P] [US1] Criar `tprof/presentation/controller/profile_controller_test.dart` com `FakeProfileRepository`: `load()` → `loading` → `loaded` com perfil, `counts` e `achievements` carregados; os três pedidos saem juntos (segurar um com `Completer` e ver que os outros já foram chamados); perfil falha → `error`; perfil ok e totais falham → `counts` e `achievements` `failed`, `profile` preenchido; progresso falha → só `achievements` `failed`; `retryCounts()`/`retryAchievements()` recarregam só a área; `refresh()` não volta para `loading` e atualiza os números; `achievedCount`/`totalCount`; `dispose` durante a carga não lança
- [X] T013 [P] [US1] Criar `tprof/presentation/pages/profile_page_test.dart` com `GetIt` (sessão real com `FakeSecureStorageService`, `FakeProfileRepository` via usecases reais) e um `GoRouter` de teste com `/profile` (página real), `/profile/edit`, `/profile/achievements`, `/settings`, `/home`, `/activities`, `/news/saved`, `/news/read`, `/news/liked` e `/login` identificados:
  - visitante → título "Entre na sua conta", os 4 itens e "Entrar ou criar conta" → `/login`; nenhum pedido ao repository;
  - conta: iniciais "MS" (sem foto) e "Maria da Silva"; **o e-mail não aparece**; lápis com rótulo "Editar perfil" (≥ 48×48) → `/profile/edit`;
  - números "12/5/9" com "Lidas/Salvas/Curtidas"; cada um com rótulo "12 notícias lidas, abrir lista" e toque → `/news/read`, `/news/saved`, `/news/liked`;
  - "Conquistas (N)" e as medalhas na ordem do calculador; "Ver todas" → `/profile/achievements`;
  - "Ler mais notícias" → `/home`; "Fazer novas atividades" → `/activities`; engrenagem ("Configurações") → `/settings`;
  - perfil com erro → `SafeErrorState` e "Tentar novamente" recarrega; só totais com erro → aviso "Não foi possível carregar seus números." com "Tentar novamente" e o cartão visível;
  - voltar de `/news/read` chama `refresh` (o fake conta as chamadas); trocar de aba e voltar (`router.go('/home')` e depois `router.go('/profile')`, com a rota `/profile` dentro de um `StatefulShellRoute.indexedStack` de teste) também chama `refresh` e não mostra o carregando;
  - fonte 2× (`tester.platformDispatcher.textScaleFactorTestValue = 2`) → `tester.takeException()` nulo
- [X] T014 [P] [US1] Criar `tprof/presentation/pages/achievements_page_test.dart`: lista completa na ordem do calculador, medalhas alcançadas com "Conquistada" e pendentes com o progresso; voltar fecha

### Implementação

- [X] T015 [P] [US1] Criar `prof/domain/achievements_calculator.dart` conforme o [data-model](data-model.md#regras-das-conquistas-achievementscalculator-r3) (constantes `dedicatedStudentLessons = 10`, `dedicatedReaderNews = 10`). Faz a T010 passar
- [X] T016 [P] [US1] Criar `prof/presentation/extensions/achievement_presentation_extension.dart` (título, progresso, ícone Lucide e cores por tipo via `AppPalette`) e `prof/presentation/extensions/count_format.dart` com `formatCount(int)` (até 999 o número; de 1.000 em diante "1 mil", "1,2 mil", com a mesma regra do `formatLikesCount` do `news`, copiada porque o perfil não importa o `news`), usado pelo `StatTile`. Testes de `formatCount` na T011 (0, 999, 1000 → "1 mil", 1200 → "1,2 mil"). Faz a T011 passar
- [X] T017 [US1] Criar os usecases `prof/domain/usecases/get_profile_usecase.dart`, `get_news_counts_usecase.dart` e `get_activity_progress_usecase.dart`; `prof/presentation/controller/area_state.dart` (`sealed class AreaState<T>` com `AreaLoading`, `AreaLoaded(value)`, `AreaFailed(failure)`), `profile_status.dart` e `profile_controller.dart` conforme o [data-model](data-model.md#controllers). Registrar usecases e `registerFactory(ProfileController)` em `prof/profile_module.dart`. Faz a T012 passar
- [X] T018 [US1] Criar os widgets em `prof/presentation/widgets/`: `profile_header_card.dart` (cartão branco raio 24 com borda e `shadowSm`; avatar 96 com iniciais ou `Image.network`, lápis coral 36 com borda branca no canto inferior direito, `Semantics(button, label: Editar perfil)`, área de toque 48; nome 24/800 `secondary`, até 2 linhas), `stat_tile.dart` (borda, raio 20, quadrado de ícone 44 com fundo da cor a 12%, número 26/800, rótulo 15/600 muted; `InkWell` com rótulo semântico), `medal_card.dart` (cartão branco com borda, raio 20, largura 124; medalha com disco em gradiente das duas cores, aro branco 55%, fita em SVG/`CustomPaint`; pendente em cinza com `LucideIcons.lock`; título 15/700 e legenda 13/600 verde ou muted), `achievements_section.dart` (cartão com "Conquistas (N)", "Ver todas ›" 48 de altura e `ListView` horizontal), `profile_cta_card.dart` (navy e coral sólidos, raio 24, sem sombra, ícone em quadrado branco 16%, título 18/700, subtítulo 15, chevron) e `guest_invite.dart` (quadro "Perfil — visitante"). Cores por `context.colors`
- [X] T019 [US1] Reescrever `prof/presentation/pages/profile_page.dart`: `ValueListenableBuilder` em `sessionStatus` (visitante → `GuestInvite`); com conta, `ChangeNotifierProvider` do `ProfileController` (`load()` na criação), título "Perfil" 30/800 e a engrenagem branca com borda 48 (`context.push('/settings')`); estados `SafeLoadingState`/`SafeErrorState`; cartão, números (`context.push('/news/read'|'/news/saved'|'/news/liked')`), conquistas (aviso de falha no lugar, com "Tentar novamente"), CTAs (`context.go('/home')`, `context.go('/activities')`). Atualização ([R4](research.md#r4-atualizar-ao-voltar-à-aba-fr-007)): ouvir `GoRouter.of(context).routerDelegate` e chamar `refresh()` quando o caminho volta a ser `/profile`; também `await context.push(...)` seguido de `refresh()`. Faz a T013 passar
- [X] T020 [US1] Criar `prof/presentation/pages/achievements_page.dart` (`AppBar` "Conquistas", grade de 2 colunas com `MedalCard`, recebe a lista já calculada pelo `extra` da rota; sem `extra` — link direto —, cria o próprio `ProfileController` com os mesmos usecases e mostra carregando/erro como a aba) e a rota `achievements` (filha de `/profile`, `parentNavigatorKey: rootNavigatorKey`) em `prof/presentation/routes/profile_routes.dart`. Faz a T014 passar

- [X] T021 [US1] Criar `app/test/helpers/profile_dependencies.dart` com `registerProfileDependencies(GetIt injector, {FakeProfileRepository? repository})` (usecases do perfil sobre o `FakeProfileRepository` e as factories dos controllers, como `app/test/helpers/news_detail_dependencies.dart`) e chamá-lo no `setUp` de `app/test/core/routing/app_router_test.dart` (que já abre `/profile` e `/profile/edit`) e de `app/test/widget_test.dart`. A suíte inteira precisa continuar verde

**Checkpoint**: `flutter test` verde, incluindo `app_router_test.dart` e `widget_test.dart`. Commit da Base + US1.

---

## Phase 4: User Story 2 - Editar nome, e-mail e telefone (Priority: P1)

**Goal**: edição com validação local, envio só do que mudou, erros por campo, descarte com confirmação e saudação atualizada (FR-011 a FR-016, SC-002, SC-003).

**Independent Test**: passos 8–11 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T022 [P] [US2] Criar `tprof/domain/validators/profile_form_validator_test.dart`: nome com 5 e 151 caracteres (sem os espaços das pontas) → erro, 6 e 150 → ok; e-mail inválido → erro; `normalizePhone`: "(11) 91234-5678" → "+5511912345678", "+55 11 3456-7890" → "+551134567890", "1234" → `null`, "" → `null`; telefone vazio com `hadPhone: false` → ok, com `hadPhone: true` → `phoneRequired`; telefone inválido → `phoneInvalid`
- [X] T023 [P] [US2] Criar `tprof/domain/usecases/update_profile_usecase_test.dart` com `FakeProfileRepository` e `UserSessionService(FakeSecureStorageService())` com conta: envia **só** os campos diferentes do original (e-mail `trim().toLowerCase()`); nada mudou → não chama; sucesso → `session.updateProfile(name, email)` e `profileVersion` aumenta; falha → sessão intacta
- [X] T024 [P] [US2] Em `app/test/modules/common/services/user_session_service_test.dart`, acrescentar: `profileVersion` começa em 0 e aumenta a cada `updateProfile` com conta; sem conta não muda. Em `app/test/modules/shell/presentation/app_top_bar_test.dart`, acrescentar: conectada como "Maria", `updateProfile(name: 'Maria Souza', …)` → a barra mostra "Olá, Maria Souza" sem outra mudança de sessão
- [X] T025 [P] [US2] Criar `tprof/presentation/controller/edit_profile_controller_test.dart`: começa com os valores do perfil; `canSave` só com mudança; erros por campo sem chamar o usecase; `EmailInUseFailure` → erro no e-mail e rascunho mantido; `ServerFailure` → devolve a falha e mantém o rascunho; sucesso → `canSave` falso e originais atualizados; `hasChanges`
- [X] T026 [P] [US2] Criar `tprof/presentation/pages/profile_edit_page_test.dart`: campos preenchidos (nome, e-mail, telefone com máscara); "Salvar" desabilitado sem mudança; nome curto → erro no campo, sem pedido; salvar ok → `SnackBar` "Dados salvos"; e-mail em uso → "Este e-mail já está em uso." no campo; `ServerFailure` → `SnackBar` "Não foi possível salvar. Tente de novo mais tarde." e o texto continua; apagar telefone já salvo → "Informe um telefone com DDD."; voltar com mudança → diálogo "Descartar alterações?" ("Continuar editando" fica; "Descartar" sai); visitante que abre `/profile/edit` vê o convite para entrar, sem pedido ao repository; fonte 2× sem estouro; alvos ≥ 48

### Implementação

- [X] T027 [P] [US2] Criar `prof/domain/validators/profile_form_validator.dart` (`ProfileFieldErrors`; expressão de e-mail copiada de `app/lib/modules/authentication/domain/validators/credentials_validator.dart` com comentário citando a origem e o Princípio I; `normalizePhone`). Faz a T022 passar
- [X] T028 [US2] Em `app/lib/modules/common/services/user_session_service.dart`, acrescentar `ValueListenable<int> get profileVersion` (um `ValueNotifier<int>` interno incrementado no fim de `updateProfile` com conta). Em `app/lib/modules/shell/presentation/widgets/app_top_bar.dart`, trocar o `ValueListenableBuilder` da saudação por `ListenableBuilder(listenable: Listenable.merge([session.sessionStatus, session.profileVersion]))`. Faz a T024 passar
- [X] T029 [US2] Criar `prof/domain/usecases/update_profile_usecase.dart` (recebe `ProfileEntity original` e o rascunho normalizado; monta o `ProfileUpdate`; em sucesso chama `session.updateProfile`). Faz a T023 passar
- [X] T030 [US2] Criar `prof/presentation/controller/edit_profile_controller.dart` conforme o [data-model](data-model.md#controllers) (campos de texto, erros, `canSave`, `isSaving`, `save()`). Registrar `UpdateProfileUseCase` e a factory do controller em `prof/profile_module.dart`. Faz a T025 passar
- [X] T031 [US2] Reescrever `prof/presentation/pages/profile_edit_page.dart` (mantém a classe `ProfileEditPage`): visitante → o mesmo `GuestInvite` da aba, sem chamar o serviço; com conta, busca o perfil (`GetProfileUseCase`) com carregando/erro; `SafeTextField` para nome, e-mail (teclado de e-mail) e telefone (teclado de telefone, dica "(11) 91234-5678"); foto 96 no topo (o toque entra na US3); `SafeButton` "Salvar" grande; `PopScope` com o diálogo de descarte; `SnackBar`s. Faz a T026 passar

**Checkpoint**: testes da US2 e suíte verdes. Commit da US2.

---

## Phase 5: User Story 3 - Trocar ou remover a foto (Priority: P2)

**Goal**: galeria/câmera, envio otimista, remover com confirmação, sem permissão explicado (FR-017 a FR-020, SC-005).

**Independent Test**: passos 12–13 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T032 [P] [US3] Criar `tprof/domain/usecases/avatar_usecases_test.dart` com `FakeProfileRepository` e `FakeImageStorageService`: `UpdateAvatarUseCase(source)` → `PickedImage(path)` envia o caminho e, em sucesso **ou** falha, chama `delete(path)`; `PickImageCancelled` → nada enviado; `PickImagePermissionDenied` → resultado `permissionDenied` sem pedido; `PickImageFailed` → falha genérica; `RemoveAvatarUseCase` repassa
- [X] T033 [P] [US3] Em `tprof/presentation/controller/edit_profile_controller_test.dart`, acrescentar: `pickPhoto(gallery)` → `photoState` `uploading` com `localPhotoPath` antes da resposta, depois `idle` com a nova `avatarUrl`; falha → volta à foto anterior e devolve a falha; `removePhoto()` → `removing` → sem foto; falha → foto volta
- [X] T034 [P] [US3] Em `tprof/presentation/pages/profile_edit_page_test.dart`, acrescentar: tocar na foto abre a folha com "Galeria" e "Câmera" (e "Remover foto" só com foto); escolher → "Enviando foto…" e depois a foto; sem permissão → folha "Sem acesso às fotos" com a explicação; "Remover foto" → diálogo "Remover a foto?" → "Remover" chama o usecase; falha → `SnackBar` "Não foi possível trocar a foto."; imagem inválida → "Esta imagem não é aceita. Use uma foto JPG ou PNG."

### Implementação

- [X] T035 [US3] Criar `prof/domain/usecases/update_avatar_usecase.dart` (usa o `ImageStorageService` do `common` e `ProfileRepository.uploadAvatar`; resultado `AvatarUpdateOutcome` sealed: `updated(url)`, `cancelled`, `permissionDenied`, `failed(Failure)`) e `remove_avatar_usecase.dart`. Registrar em `prof/profile_module.dart`. Faz a T032 passar
- [X] T036 [US3] Em `prof/presentation/controller/edit_profile_controller.dart`, acrescentar `photoState`, `localPhotoPath`, `avatarUrl`, `pickPhoto(PhotoSource)` e `removePhoto()`. Faz a T033 passar
- [X] T037 [US3] Criar `prof/presentation/widgets/photo_sheet.dart` (folha com opções de 56 de altura, ícones `image`, `camera`, `trash-2`) e, na `profile_edit_page.dart`, o toque na foto, o indicador de envio sobre a foto local, o diálogo de remover e a folha de permissão negada. Faz a T034 passar

**Checkpoint**: testes da US3 e suíte verdes. Commit da US3.

---

## Phase 6: User Story 4 - Rever as notícias lidas, salvas e curtidas (Priority: P3)

**Goal**: listas de lidas e curtidas no mesmo visual da de salvas, abertas pelos números do perfil (FR-010, SC-006).

**Independent Test**: passos 5–7 do [quickstart](quickstart.md); testes de salvas da 010 verdes sem mudança de comportamento.

### Testes (escrever primeiro e ver falhar)

- [X] T038 [P] [US4] Em `tnews/data/datasources/news_remote_data_source_impl_test.dart` e `tnews/data/repositories/news_repository_impl_test.dart`, acrescentar `getUserNewsList(NewsListKind.read|liked, page)` → `GET /users/me/news/read|liked` com `page`/`limit` 20, **sem** gravar nem ler cópia (só `saved` guarda); os testes de `saved` existentes continuam passando
- [X] T039 [P] [US4] Renomear `tnews/presentation/controller/saved_news_controller_test.dart` para `user_news_list_controller_test.dart` (e `tnews/fakes/saved_news_controller_factory.dart` para `user_news_list_controller_factory.dart` com o parâmetro `kind`), mantendo todos os casos de salvas e acrescentando: com `kind: read` o controller chama o usecase com `read`
- [X] T040 [P] [US4] Em `tnews/presentation/pages/saved_news_page_test.dart` (renomear para `user_news_list_page_test.dart`), manter os casos de salvas e acrescentar: `/news/read` com título "Notícias lidas" e vazio "Você ainda não leu nenhuma notícia." com botão para o Início; `/news/liked` com "Notícias curtidas" e o vazio correspondente; tocar numa notícia abre `/news/:id`

### Implementação

- [X] T041 [US4] Criar `news/domain/entities/news_list_kind.dart` (`enum NewsListKind { saved, read, liked }` com o segmento do caminho, as chaves de título/vazio e `keepsCopy` só em `saved`); no datasource e no repository de `news`, generalizar `getSavedNews` para `getUserNewsList(kind, page)` (o caminho `saved` mantém a cópia e o comportamento atuais); `GetSavedNewsUseCase` → `GetUserNewsListUseCase` com `call(kind, page)`. Atualizar `tnews/fakes/fake_news_repository.dart`, `fake_news_data_sources.dart` e `app/test/helpers/news_detail_dependencies.dart`. Faz a T038 passar
- [X] T042 [US4] Renomear `SavedNewsController`/`SavedNewsPage` para `UserNewsListController`/`UserNewsListPage` (arquivos `user_news_list_controller.dart` e `user_news_list_page.dart`), com o `kind` no construtor para o usecase, o título e o vazio (o convite de visitante continua); em `news/presentation/routes/news_routes.dart`, as rotas `/news/saved`, `/news/read` e `/news/liked` (todas antes de `/news/:id`). Faz a T039 e a T040 passar

**Checkpoint**: testes da US4, da 010 e suíte verdes. Commit da US4.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T043 Formatar só os arquivos tocados (`dart format` com os caminhos, nunca pastas inteiras), `flutter analyze` (sem avisos novos em relação à T001) e `flutter test` (todos verdes). Revisar o código de produção em busca de código morto ou só de teste e anotar o resultado. **Resultado (2026-10-12):** `flutter test` 1205 verdes (base 1028 + 177 novos); `flutter analyze` 28 issues, todos `info`, iguais à base. Revisão: saíram `AchievementEntity.moduleId` e `ModuleProgressEntity.id` (só os testes liam) e um `ProfileEntity.copyWith` sem uso; data-model ajustado
- [X] T044 Validar no aparelho os 16 passos do [quickstart.md](quickstart.md#2-no-aparelho) com uma conta da usuária e anotar o resultado. **Resultado (2026-10-14):** validado pela usuária no aparelho; o cartão do perfil foi ajustado ao v4 (foto sobre a borda do cartão, números dentro dele, commit `4d9ba61`)
- [X] T045 Em `.specify/memory/tasks.md`, marcar B7 como `[x]` com `(specs/012-perfil)`. Commit de docs; antes da PR, `git fetch` e trazer a `develop` se tiver mudado. **Resultado (2026-10-14):** `develop` sem novidades

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → histórias.
- **US1 (Phase 3)**: depois da Foundational. Cria a página e o controller do perfil.
- **US2 (Phase 4)**: depois da Foundational; usa o `GetProfileUseCase` da US1 (T017).
- **US3 (Phase 5)**: depois da US2 (mesma página e controller de edição).
- **US4 (Phase 6)**: independente do perfil no código (`news`); os números da US1 só navegam para as rotas. Pode ser feita em paralelo com a US2/US3.
- **Polish (Phase 7)**: depois de todas.

### Within Each User Story

- Testes (falhando) → domínio → controller → widgets/página.

### Parallel Opportunities

- **Foundational:** T002 ∥ T003 ∥ T004 ∥ T005 ∥ T006; T007 → T008 → T009.
- **US1:** T010 ∥ T011 ∥ T012 ∥ T013 ∥ T014; T015 ∥ T016; T017 → T018 → T019 → T020 → T021.
- **US2:** T022 ∥ T023 ∥ T024 ∥ T025 ∥ T026; T027 ∥ T028; T029 → T030 → T031.
- **US3:** T032 ∥ T033 ∥ T034; T035 → T036 → T037.
- **US4:** T038 ∥ T039 ∥ T040; T041 → T042. A fase inteira ∥ US2/US3.

---

## Parallel Example: Foundational (testes)

```bash
Task: "Fixtures em click_seguro_app/test/modules/profile/fakes/profile_fixtures.dart"
Task: "Models em click_seguro_app/test/modules/profile/data/models/profile_models_test.dart"
Task: "Datasource em click_seguro_app/test/modules/profile/data/datasources/profile_remote_data_source_impl_test.dart"
Task: "Repository em click_seguro_app/test/modules/profile/data/repositories/profile_repository_impl_test.dart"
```

## Parallel Example: User Story 1 (testes)

```bash
Task: "Conquistas em click_seguro_app/test/modules/profile/domain/achievements_calculator_test.dart"
Task: "Extension em click_seguro_app/test/modules/profile/presentation/extensions/achievement_presentation_extension_test.dart"
Task: "Controller em click_seguro_app/test/modules/profile/presentation/controller/profile_controller_test.dart"
Task: "Página em click_seguro_app/test/modules/profile/presentation/pages/profile_page_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): a aba Perfil com números, medalhas e atalhos.
3. **PARAR e VALIDAR**: passos 1–4 do quickstart no aparelho.

### Incremental Delivery

1. Setup + Foundational → dados do perfil.
2. US1 → ver o perfil (MVP).
3. US2 → editar dados (saudação atualizada).
4. US3 → foto.
5. US4 → listas de lidas e curtidas (pode vir antes, em paralelo).
6. Polish → aparelho, marcar B7, PR para `develop`.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- Rode cada teste sozinho e veja falhar antes de implementar.
- Um commit por história (Base + US1, US2, US3, US4) e um de docs no fim; Conventional Commits em
  português com `Co-Authored-By`; `click_seguro_app/devtools_options.yaml` e `click-seguro.html`
  ficam de fora.
- `dart format` só nos arquivos tocados (formatar pastas inteiras já mexeu em arquivo de outra
  feature).
- A US4 e a T028 mexem em código do outro desenvolvedor (features 010 e 005): avisar antes e
  conferir a `develop` no início de cada fase.
- O 500 do e-mail é do servidor: não tentar contornar no app além da mensagem genérica.
