# SafeNews — Tarefas de Implementação

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 1.0.0

**Criado em**: 2026-09-07

**Insumos**: [constitution.md](constitution.md) v1.0.1 · [specification.md](specification.md)
v1.0.0 · [plan.md](plan.md) v1.0.1

**Testes**: obrigatórios (Seção III da constituição — TDD não-negociável). Toda tarefa `[T]`
(teste) MUST ser escrita e MUST falhar antes da tarefa `[I]` (implementação) correspondente.

## Formato

`[ID] [P?] [Fase] Descrição — arquivo(s)`

- **[P]**: pode ser feita em paralelo (arquivo diferente, sem dependência de outra tarefa em
  aberto).
- **[Fase]**: Fase 1–5, na mesma numeração do `plan.md` — nenhuma tarefa de uma fase começa
  antes do Checkpoint da fase anterior.
- Caminhos são relativos a `click_seguro_app/` (`lib/...`, `test/...`).
- Toda tarefa de teste que usa `GetIt` MUST resetar o container em `setUp`/`tearDown`
  (`GetIt.instance.reset()`), nunca compartilhar estado entre testes (Seção III).

---

## Fase 1 — Setup da Infraestrutura Base

**Objetivo**: infraestrutura (`ApiClient`, `UserSessionService`, storages, `AuthGate`) pronta
e testada. Nenhuma tela de negócio existe ainda — isso é esperado, chega na Fase 2.

- [ ] T001 [P] Adicionar `flutter_secure_storage` e `shared_preferences` ao
  `pubspec.yaml`; rodar `flutter pub get`
- [ ] T002 [P] Criar `.env.example` na raiz de `click_seguro_app/` documentando as chaves
  `API_URL=`, `ENVIRONMENT=`, `DEBUG_MODE=` sem valores reais
- [ ] T003 [P] Escrever teste (deve falhar) para `SecureStorageService` (`readToken`/
  `writeToken`/`clear`) — `test/modules/common/services/secure_storage_service_test.dart`
- [ ] T004 Implementar `SecureStorageService` sobre `flutter_secure_storage` —
  `lib/modules/common/services/secure_storage_service.dart` (depende de T001, T003)
- [ ] T005 [P] Escrever teste (deve falhar) para `LocalCacheService` (salvar/ler blob JSON por
  chave, limpar) — `test/modules/common/services/local_cache_service_test.dart`
- [ ] T006 Implementar `LocalCacheService` sobre `shared_preferences` —
  `lib/modules/common/services/local_cache_service.dart` (depende de T001, T005)
- [ ] T007 [P] Escrever teste (deve falhar) para suporte a `CancelToken` em `ApiClient.get`
  (hoje sem nenhum teste) — `test/modules/common/api_client/api_client_test.dart`
- [ ] T008 Estender `ApiClient.get` com parâmetro opcional `CancelToken? cancelToken`,
  repassado ao `Dio` — `lib/modules/common/api_client/api_client.dart` (depende de T007)
- [ ] T009 [P] Escrever teste (deve falhar) para `UserSessionService.restoreSession()`
  (restaura sessão do storage) e para `saveSession`/`logout` persistindo/limpando o storage —
  `test/modules/common/services/user_session_service_test.dart`
- [ ] T010 Estender `UserSessionService` para receber `SecureStorageService` no construtor e
  implementar `restoreSession()` — `lib/modules/common/services/user_session_service.dart`
  (depende de T004, T009)
- [ ] T011 Atualizar `CommonModule.registerServices` para registrar `SecureStorageService`,
  `LocalCacheService` e passar `SecureStorageService` na construção de `UserSessionService` —
  `lib/modules/common/common_module.dart` (depende de T004, T006, T010)
- [ ] T012 [P] Criar `AuthGate` recebendo `authenticatedChild`/`unauthenticatedChild` e
  reagindo a `UserSessionService.sessionStatus` via `ValueListenableBuilder` —
  `lib/core/widgets/auth_gate.dart`
- [ ] T013 [P] Escrever widget test para `AuthGate` alternando de filho quando
  `sessionStatus` muda — `test/core/widgets/auth_gate_test.dart`
- [ ] T014 Chamar `UserSessionService.restoreSession()` em `_setup()`, antes de `runApp` —
  `lib/main.dart` (depende de T010)
- [ ] T015 [P] Limpar `test/widget_test.dart` (template padrão do Flutter, hoje com imports
  não usados) e substituir por um smoke test mínimo que sobe `ClickSeguroApp`

**Checkpoint Fase 1**: `flutter test` e `flutter analyze` limpos; infraestrutura registrada no
`GetIt`; app ainda abre em branco (sem `home:` de negócio) — normal até a Fase 2.

---

## Fase 2 — Módulo de Autenticação e Sessão

**Objetivo**: usuário se cadastra, loga, recupera senha e permanece autenticado entre
reinícios do app (RF-001 a RF-007).

- [ ] T016 [P] Criar enum `UserRole` (`reader`, `validator`) —
  `lib/modules/authentication/domain/entities/user_role.dart`
- [ ] T017 [P] Criar `UserEntity` (`id`, `name`, `email`, `role`) —
  `lib/modules/authentication/domain/entities/user_entity.dart` (depende de T016)
- [ ] T018 [P] Escrever teste (deve falhar) para `UserModel.fromJson`/`toJson`, incluindo caso
  de campo ausente — `test/modules/authentication/data/models/user_model_test.dart`
- [ ] T019 Criar `UserModel` (estende `UserEntity`) —
  `lib/modules/authentication/data/models/user_model.dart` (depende de T017, T018)
- [ ] T020 Criar contrato `AuthRepository` (`login`, `register`, `requestPasswordReset`,
  `logout`) — `lib/modules/authentication/domain/repositories/auth_repository.dart`
- [ ] T021 [P] Escrever teste (deve falhar) para `AuthRemoteDataSource` (mock de `ApiClient`) —
  `test/modules/authentication/data/datasources/auth_remote_data_source_test.dart`
- [ ] T022 Criar `AuthRemoteDataSource` (contrato + implementação sobre `ApiClient`) —
  `lib/modules/authentication/data/datasources/auth_remote_data_source.dart` (depende de T019,
  T021)
- [ ] T023 [P] Escrever teste (deve falhar) para `AuthRepositoryImpl` (mock de
  `AuthRemoteDataSource`), incluindo propagação de `ApiException` —
  `test/modules/authentication/data/repositories/auth_repository_impl_test.dart`
- [ ] T024 Criar `AuthRepositoryImpl` —
  `lib/modules/authentication/data/repositories/auth_repository_impl.dart` (depende de T020,
  T022, T023)
- [ ] T025 [P] Criar validador puro de e-mail/senha (RN-001), com teste antes —
  `lib/modules/authentication/domain/validators/credentials_validator.dart` +
  `test/modules/authentication/domain/validators/credentials_validator_test.dart`
- [ ] T026 [P] Escrever teste (deve falhar) para `AuthenticationController`
  (login/registro/esqueci-senha: idle/loading/sucesso/erro; chama
  `UserSessionService.saveSession` no sucesso do login) —
  `test/modules/authentication/ui/controller/authentication_controller_test.dart`
- [ ] T027 Reescrever `AuthenticationController` (hoje um stub vazio) com campos
  `isLoading`/`error`/`user` e métodos `login`/`register`/`requestPasswordReset` —
  `lib/modules/authentication/ui/controller/authentication_controller.dart` (depende de T024,
  T025, T026)
- [ ] T028 [P] Implementar `LoginPage` com `SafeTextField`/`SafeButton`, validação RN-001, com
  widget test — `lib/modules/authentication/ui/pages/login_page.dart` +
  `test/modules/authentication/ui/pages/login_page_test.dart`
- [ ] T029 [P] Implementar `RegisterPage`, com widget test —
  `lib/modules/authentication/ui/pages/register_page.dart` + teste correspondente
- [ ] T030 [P] Implementar `ForgotPasswordPage`, com widget test —
  `lib/modules/authentication/ui/pages/forgot_password_page.dart` + teste correspondente
- [ ] T031 Atualizar `AuthenticationModule.registerServices` para registrar
  `AuthRemoteDataSource`, `AuthRepository` e `AuthenticationController` via `GetIt`, e
  `providers()` para resolver o controller via `GetIt.instance` —
  `lib/modules/authentication/authentication_module.dart` (depende de T022, T024, T027)
- [ ] T032 Ligar `AuthGate` em `main.dart`: `unauthenticatedChild: LoginPage()`,
  `authenticatedChild:` tela temporária (`Placeholder`, substituída na Fase 3) —
  `lib/main.dart` (depende de T012, T028)

**Checkpoint Fase 2**: cadastro, login, logout, recuperação de senha e persistência de sessão
entre reinícios funcionam fim-a-fim e são demonstráveis isoladamente (RF-001 a RF-007).

---

## Fase 3 — Módulo de Feed e Detalhamento de Notícias

**Objetivo**: leitor autenticado navega pelo feed, filtra por categoria, busca, abre detalhe,
favorita e continua lendo offline (RF-008 a RF-013).

- [ ] T033 [P] Criar enum `VeracityStatus` (`unverified`, `underReview`, `verified`, `false`)
  — `lib/modules/news/domain/entities/veracity_status.dart`
- [ ] T034 [P] Criar `NewsEntity` — `lib/modules/news/domain/entities/news_entity.dart`
  (depende de T033)
- [ ] T035 [P] Escrever teste (deve falhar) para `NewsModel.fromJson`/`toJson`, incluindo caso
  de campo ausente lançando erro de parsing — `test/modules/news/data/models/news_model_test.dart`
- [ ] T036 Criar `NewsModel` — `lib/modules/news/data/models/news_model.dart` (depende de
  T034, T035)
- [ ] T037 Criar contrato `NewsRepository` (`getFeed`, `getById`, `search`, `toggleFavorite`,
  `getFavorites`, `applyVerdict`, `lastFetchWasFromCache`) —
  `lib/modules/news/domain/repositories/news_repository.dart`
- [ ] T038 [P] Escrever teste (deve falhar) para `NewsRemoteDataSource` (mock de `ApiClient`),
  incluindo captura de erro de parsing → `ApiException` (CB-005) —
  `test/modules/news/data/datasources/news_remote_data_source_test.dart`
- [ ] T039 Criar `NewsRemoteDataSource` (contrato + implementação) —
  `lib/modules/news/data/datasources/news_remote_data_source.dart` (depende de T036, T038)
- [ ] T040 [P] Escrever teste (deve falhar) para `NewsLocalDataSource` sobre
  `LocalCacheService` (cache de feed, favoritos) —
  `test/modules/news/data/datasources/news_local_data_source_test.dart`
- [ ] T041 Criar `NewsLocalDataSource` (contrato + implementação) —
  `lib/modules/news/data/datasources/news_local_data_source.dart` (depende de T006, T036, T040)
- [ ] T042 [P] Escrever teste (deve falhar) para `NewsRepositoryImpl`, incluindo fallback
  remote→local quando `ApiException.statusCode == 0` (RNF-002/CB-001) —
  `test/modules/news/data/repositories/news_repository_impl_test.dart`
- [ ] T043 Criar `NewsRepositoryImpl` —
  `lib/modules/news/data/repositories/news_repository_impl.dart` (depende de T037, T039, T041,
  T042)
- [ ] T044 [P] Escrever teste (deve falhar) para `FeedController` (paginação, filtro de
  categoria, busca com debounce cancelando requisição anterior via `CancelToken`) —
  `test/modules/news/ui/controller/feed_controller_test.dart`
- [ ] T045 Implementar `FeedController` —
  `lib/modules/news/ui/controller/feed_controller.dart` (depende de T008, T043, T044)
- [ ] T046 [P] Escrever teste (deve falhar) para `NewsDetailController` (parametrizado por
  `newsId`) — `test/modules/news/ui/controller/news_detail_controller_test.dart`
- [ ] T047 Implementar `NewsDetailController` —
  `lib/modules/news/ui/controller/news_detail_controller.dart` (depende de T043, T046)
- [ ] T048 [P] Implementar `FeedPage` (lista, filtro, busca, estado vazio CB-007, parar de
  paginar sem duplicar no fim da lista CB-008), com widget test —
  `lib/modules/news/ui/pages/feed_page.dart` + teste correspondente
- [ ] T049 [P] Implementar `NewsDetailPage` (selo de veracidade, favoritar), com widget test —
  `lib/modules/news/ui/pages/news_detail_page.dart` + teste correspondente
- [ ] T050 Atualizar `NewsModule.registerServices` (datasources, repositório, controllers via
  `GetIt`) — `lib/modules/news/news_module.dart` (depende de T039, T041, T043, T045, T047)
- [ ] T051 Substituir o `Placeholder` de `authenticatedChild` do `AuthGate` por `FeedPage` em
  `main.dart` e ligar navegação `FeedPage` → `NewsDetailPage` ao tocar um card —
  `lib/main.dart` (depende de T032, T048, T049)

**Checkpoint Fase 3**: feed, filtro, busca, detalhe, favoritos e leitura offline do último
feed carregado funcionam fim-a-fim (RF-008 a RF-013, RNF-002, RNF-005).

---

## Fase 4 — Módulo de Validação / Checagem de Fatos (Fact-Checking)

**Objetivo**: leitor denuncia notícia sem duplicar denúncia; validador revisa fila priorizada
e registra veredito auditável, refletido no selo de veracidade (RF-014 a RF-018).

- [ ] T052 [P] Criar enum `ReportReason` (`misleadingTitle`, `fabricatedContent`,
  `outOfContext`, `unreliableSource`, `other`) —
  `lib/modules/fact_check/domain/entities/report_reason.dart`
- [ ] T053 [P] Criar `ReportEntity` e `VerdictEntity` —
  `lib/modules/fact_check/domain/entities/report_entity.dart` e `verdict_entity.dart`
  (depende de T033, T052)
- [ ] T054 [P] Escrever teste (deve falhar) para os Models de fact-check (`fromJson`/`toJson`)
  — `test/modules/fact_check/data/models/fact_check_model_test.dart`
- [ ] T055 Criar `FactCheckModel`(s) — `lib/modules/fact_check/data/models/fact_check_model.dart`
  (depende de T053, T054)
- [ ] T056 Criar contrato `FactCheckRepository` (`reportNews`, `hasUserReported`,
  `getPendingQueue`, `submitVerdict`) —
  `lib/modules/fact_check/domain/repositories/fact_check_repository.dart`
- [ ] T057 [P] Escrever teste (deve falhar) para `FactCheckRemoteDataSource` (mock de
  `ApiClient`) — `test/modules/fact_check/data/datasources/fact_check_remote_data_source_test.dart`
- [ ] T058 Criar `FactCheckRemoteDataSource` (contrato + implementação) —
  `lib/modules/fact_check/data/datasources/fact_check_remote_data_source.dart` (depende de
  T055, T057)
- [ ] T059 [P] Escrever teste (deve falhar) para `FactCheckRepositoryImpl`, incluindo chamada a
  `NewsRepository.applyVerdict` após veredito e priorização por volume de denúncias (RN-006) —
  `test/modules/fact_check/data/repositories/fact_check_repository_impl_test.dart`
- [ ] T060 Criar `FactCheckRepositoryImpl`, injetando `NewsRepository` via `GetIt` —
  `lib/modules/fact_check/data/repositories/fact_check_repository_impl.dart` (depende de T037,
  T043, T056, T058, T059)
- [ ] T061 [P] Escrever teste (deve falhar) para `ReportController`, incluindo bloqueio de
  denúncia duplicada (RN-003/CB-006) —
  `test/modules/fact_check/ui/controller/report_controller_test.dart`
- [ ] T062 Implementar `ReportController` —
  `lib/modules/fact_check/ui/controller/report_controller.dart` (depende de T060, T061)
- [ ] T063 [P] Escrever teste (deve falhar) para `ValidationQueueController`, incluindo guard
  de `UserRole` (RN-004/CB-009) e registro de veredito com histórico (RF-017) —
  `test/modules/fact_check/ui/controller/validation_queue_controller_test.dart`
- [ ] T064 Implementar `ValidationQueueController` —
  `lib/modules/fact_check/ui/controller/validation_queue_controller.dart` (depende de T016,
  T060, T063)
- [ ] T065 [P] Implementar `ReportNewsPage` (seletor de `ReportReason`, mensagem de denúncia
  duplicada), com widget test — `lib/modules/fact_check/ui/pages/report_news_page.dart` +
  teste correspondente
- [ ] T066 [P] Implementar `ValidationQueuePage` (fila priorizada, formulário de veredito,
  bloqueada para não-validadores), com widget test —
  `lib/modules/fact_check/ui/pages/validation_queue_page.dart` + teste correspondente
- [ ] T067 Atualizar `FactCheckModule.registerServices` —
  `lib/modules/fact_check/fact_check_module.dart` (depende de T058, T060, T062, T064)
- [ ] T068 Ligar navegação: botão "Denunciar" em `NewsDetailPage` → `ReportNewsPage`; entrada
  de "Fila de Validação" (visível somente para `UserRole.validator`) → `ValidationQueuePage` —
  `lib/modules/news/ui/pages/news_detail_page.dart` e ponto de entrada de navegação principal
  (depende de T049, T065, T066)

**Checkpoint Fase 4**: denúncia idempotente por usuário, fila priorizada por volume, veredito
com histórico auditável e reflexo imediato no selo de veracidade do feed (RF-014 a RF-018,
RN-002 a RN-006).

---

## Fase 5 — Tratamento Global de Erros, Estado Offline e Refinamento de Interface

**Objetivo**: mensagens de erro consistentes, indicação clara de modo offline, acessibilidade
e i18n revisadas, e auditoria final de cobertura contra a `specification.md`.

- [ ] T069 [P] Escrever teste (deve falhar) para `ApiExceptionMessageMapper` (mapeamento de
  `statusCode` 0/401/403/404/5xx para mensagem amigável) —
  `test/modules/common/api_client/api_exception_message_mapper_test.dart`
- [ ] T070 Implementar `ApiExceptionMessageMapper` —
  `lib/modules/common/api_client/api_exception_message_mapper.dart` (depende de T069)
- [ ] T071 Adotar `ApiExceptionMessageMapper` em todo campo `error` já exposto
  (`AuthenticationController`, `FeedController`, `NewsDetailController`, `ReportController`,
  `ValidationQueueController`) (depende de T027, T045, T047, T062, T064, T070)
- [ ] T072 Expor `NewsRepository.lastFetchWasFromCache` e exibir banner "modo offline" em
  `FeedPage` quando verdadeiro (CB-001), com teste (depende de T043, T048)
- [ ] T073 [P] Auditoria de acessibilidade: adicionar `Semantics`/rótulos em `SafeButton`,
  `SafeCard`, `SafeTextField`, `SafeBadge` e nas páginas criadas nas Fases 2–4 (RNF-004)
- [ ] T074 [P] Checagem de contraste AA nos temas claro/escuro (`app_theme.dart`) e ajuste das
  cores reprovadas (RNF-004)
- [ ] T075 [P] Varredura final de i18n: localizar strings hardcoded introduzidas nas Fases 2–4
  e mover para `assets/translations` (RNF-006)
- [ ] T076 Auditoria cruzada final: para cada RF/RNF/RN/CB de `specification.md`, confirmar
  teste automatizado correspondente; toda lacuna encontrada vira uma nova tarefa de fechamento
  antes de considerar o TCC concluído

**Checkpoint Fase 5**: `specification.md` 100% coberta por teste automatizado; app funciona
offline com aviso visível; nenhuma tela sem rótulo de acessibilidade ou string hardcoded.

---

## Dependências entre Fases

- **Fase 1** não depende de nenhuma outra — pode começar imediatamente.
- **Fase 2** depende da Fase 1 completa (precisa de `ApiClient`, `UserSessionService`,
  `AuthGate` já testados).
- **Fase 3** depende da Fase 1 completa; depende da Fase 2 apenas para o `AuthGate` já estar
  ligado a uma tela de login real (T032) — o domínio/dados de `news` (T033–T050) pode ser
  desenvolvido em paralelo à Fase 2 se houver mais de uma pessoa trabalhando.
- **Fase 4** depende da Fase 3 completa (precisa de `NewsRepository` real, não um stub).
- **Fase 5** depende de Fases 2–4 completas (não há o que revisar globalmente antes disso).

## Oportunidades de Paralelização

- Todas as tarefas `[P]` de uma mesma fase podem ser feitas em paralelo entre si.
- Dentro de cada fase, todo teste `[P]` roda em paralelo com os demais testes `[P]`; a
  implementação correspondente só começa depois que o teste dela existe e falha.
- Com mais de um desenvolvedor: uma pessoa pode avançar o domínio/dados de `news` (Fase 3, até
  T043) em paralelo a outra fechando a Fase 2, desde que nenhuma das duas toque
  `lib/main.dart` ao mesmo tempo (T032 e T051 são pontos de sincronização, não paralelizáveis
  entre si).

## Estratégia de Execução (solo, incremental)

1. Fase 1 → app compila, infraestrutura testada, ainda sem tela de negócio.
2. Fase 2 → **primeiro incremento demonstrável**: cadastro/login/logout funcionando de ponta a
   ponta.
3. Fase 3 → incremento: leitor consome feed, busca, favorita, lê offline.
4. Fase 4 → incremento: denúncia e validação fecham o ciclo de confiabilidade do produto.
5. Fase 5 → hardening final antes da entrega/apresentação do TCC.

Pare ao final de cada Checkpoint para validar manualmente a fase antes de iniciar a próxima —
não acumule fases incompletas.

---

## Notas

- `[P]` = arquivos diferentes, sem dependência pendente entre si.
- Toda tarefa de teste MUST falhar antes da implementação correspondente ser escrita.
- Um contrato de repositório precisando de um método a mais durante a implementação MUST
  atualizar `plan.md` antes de a tarefa ser marcada concluída (regra já registrada na
  governança do `plan.md`).
- Evite: tarefas vagas, duas tarefas `[P]` tocando o mesmo arquivo, e tarefas de uma fase
  posterior começando antes do Checkpoint da fase anterior.

**Versão**: 1.0.0 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-09-07
