---

description: "Task list for feature 004: splash com sessão e onboarding"
---

# Tasks: Splash com sessão e onboarding

**Input**: Design documents from `/specs/004-splash-onboarding-sessao/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/splash-navigation.md](contracts/splash-navigation.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** A constituição (Seção III, TDD não negociável) exige que todo teste
seja escrito e **falhe** antes da implementação correspondente, e a spec pede testes (FR-013,
FR-014). Os testes usam Fakes à mão, rodam offline e resetam o `GetIt` no `tearDown` quando o
usam.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US3)
- Caminhos relativos à raiz do repositório. O app fica em `click_seguro_app/`; `splash/` abaixo
  abrevia `click_seguro_app/lib/modules/splash/`, `tsplash/` abrevia
  `click_seguro_app/test/modules/splash/`, `onb/` abrevia
  `click_seguro_app/lib/modules/onboarding/` e `tonb/` abrevia
  `click_seguro_app/test/modules/onboarding/`.
- Valores fictícios nos testes (`maria@exemplo.com`, nome `Maria`, tokens `acesso-1`/`renovacao-1`).
- A correção do import pelo barrel `onboarding.dart` ([R4](research.md)) **já foi feita** no
  commit `9a4bc54` e não aparece aqui.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: linha de base.

- [ ] T001 Dentro de `click_seguro_app/`, rodar `flutter analyze` e `flutter test` e anotar a linha de base (esperado: 219 testes verdes, 0 erros, 0 warnings, 28 infos existentes). Se algo estiver vermelho, parar e reportar

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: o enum de destino e os fakes usados pelas três histórias.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T002 [P] Criar `splash/presentation/controller/splash_destination.dart` com `enum SplashDestination { onboarding('/onboarding'), home('/home'), login('/login'); const SplashDestination(this.path); final String path; }` e dartdoc citando a [tabela de decisão](data-model.md) ([R3](research.md))
- [ ] T003 [P] Criar `tsplash/fakes/fake_session_validation_service.dart`: `FakeSessionValidationService implements SessionValidationService`, com `int calls`, um `Future<void> Function()? onValidate` (executado dentro de `validateStoredSession`, para simular o efeito na sessão: `session.expire()`, `session.updateProfile(...)`, lançar um erro ou esperar um `Completer`) e o `mePath` herdado do contrato. Não chama rede
- [ ] T004 [P] Criar o esqueleto `splash/domain/usecases/validate_stored_session_usecase.dart` (construtor `ValidateStoredSessionUseCase(SessionValidationService, UserSessionService)` e `Future<UserSessionStatus> call()` lançando `UnimplementedError()`, para os testes compilarem e falharem) e `tsplash/fakes/fake_splash_usecases.dart` com:
  - `FakeCheckOnboardingSeenUseCase implements CheckOnboardingSeenUseCase`: devolve um `Either<Failure, bool>` configurável (padrão `Right(true)`) ou espera um `Completer<Either<Failure, bool>>` opcional;
  - `FakeValidateStoredSessionUseCase implements ValidateStoredSessionUseCase`: devolve um `UserSessionStatus` configurável (padrão `authenticated`) ou espera um `Completer<UserSessionStatus>` opcional, e conta as chamadas (`calls`)
- [ ] T005 [P] Criar `tonb/fakes/fake_onboarding_repository.dart`: `FakeOnboardingRepository implements OnboardingRepository`, com `bool seen`, `bool failOnRead`, `bool failOnComplete` (→ `Left(CacheFailure())`) e `int completeCalls`

**Checkpoint**: enum e fakes prontos; `flutter analyze` limpo.

---

## Phase 3: User Story 1 - Reabrir o app já conectado (Priority: P1) 🎯 MVP

**Goal**: quem já viu o onboarding e tem sessão conectada ou de visitante vai direto à área principal; sem sessão, vai ao login (FR-001, FR-003, FR-011).

**Independent Test**: entrar com a conta de teste, fechar e reabrir → área principal; repetir como visitante → área principal; sair da conta e reabrir → login (linhas 4, 7 e 8 do [quickstart](quickstart.md)).

### Testes (escrever primeiro e ver falhar)

- [ ] T006 [P] [US1] Criar `tsplash/domain/usecases/validate_stored_session_usecase_test.dart` com `UserSessionService(FakeSecureStorageService())` real (de `click_seguro_app/test/fakes/`) e `FakeSessionValidationService`:
  - sessão conectada (`saveSession(accessToken: 'acesso-1', refreshToken: 'renovacao-1', email: 'maria@exemplo.com', userName: 'Maria')`) e conferência que não muda nada → devolve `UserSessionStatus.authenticated` e `calls == 1`;
  - visitante (`startGuestSession()`) → devolve `guest`;
  - sem sessão → devolve `unauthenticated`.
  (O serviço real já sai cedo para visitante e desconectado; aqui o usecase só delega e lê o estado depois.)
- [ ] T007 [P] [US1] Criar `tsplash/presentation/controller/splash_controller_test.dart` com `FakeCheckOnboardingSeenUseCase`, `FakeValidateStoredSessionUseCase` e `minimumDisplayDuration: Duration.zero`, cobrindo as linhas 1, 2, 3, 6 e 7 da [tabela de decisão](data-model.md):
  - onboarding não visto (`Right(false)`) com sessão `authenticated` → `destination == SplashDestination.onboarding`;
  - leitura com falha (`Left(CacheFailure())`) → `onboarding`;
  - visto + `authenticated` → `home`;
  - visto + `guest` → `home`;
  - visto + `unauthenticated` → `login`;
  - `destination` é `null` antes de `resolveDestination()` e o controller notifica os ouvintes exatamente uma vez ao decidir.
- [ ] T008 [P] [US1] Criar `tsplash/presentation/pages/splash_page_test.dart` com `pumpLocalized(router: ...)` (de `click_seguro_app/test/helpers/localized_app.dart`), um `GoRouter` de teste com `/` → `SplashPage` (dentro de `ChangeNotifierProvider<SplashController>` com os fakes e `Duration.zero`) e `/onboarding`, `/home`, `/login` → `Scaffold` com um `Text` identificador:
  - mostra "SafeNews" e "Sua segurança em primeiro lugar" enquanto decide (use um `Completer` no fake de validação para segurar a decisão);
  - visto + `authenticated` → abre a tela de `/home`;
  - visto + `unauthenticated` → abre a de `/login`;
  - não visto → abre a de `/onboarding`;
  - depois de navegar, `router.canPop()` é `false` (o splash saiu da pilha, FR-003).

### Implementação

- [ ] T009 [US1] Implementar `splash/domain/usecases/validate_stored_session_usecase.dart` (substituindo o esqueleto da T004): `ValidateStoredSessionUseCase(this._validation, this._session)` recebendo `SessionValidationService` e `UserSessionService` (de `click_seguro_app/lib/modules/common/services/`); `Future<UserSessionStatus> call() async { await _validation.validateStoredSession(); return _session.sessionStatus.value; }`. Dartdoc: delega à feature 002, devolve o estado **depois** da conferência e nunca lança ([R1](research.md)). Faz a T006 passar
- [ ] T010 [US1] Reescrever `splash/presentation/controller/splash_controller.dart`:
  - construtor `SplashController(this._checkOnboardingSeenUseCase, this._validateStoredSessionUseCase, {Duration minimumDisplayDuration = defaultMinimumDisplayDuration})`, com `static const Duration defaultMinimumDisplayDuration = Duration(seconds: 2)` ([R5](research.md));
  - trocar `String? destinationRoute` por `SplashDestination? destination`;
  - `resolveDestination()`: dispara juntos o `Future.delayed(minimumDisplayDuration)`, o `_checkOnboardingSeenUseCase()` e o `_validateStoredSessionUseCase()` e espera os três; onboarding não visto ou falha na leitura → `onboarding` (manter o comentário do fallback seguro); senão `authenticated`/`guest` → `home`; senão → `login` ([R2](research.md)); `notifyListeners()` uma vez.
  Faz a T007 passar
- [ ] T011 [US1] Em `splash/splash_module.dart`, registrar em `registerServices`: `injector.registerLazySingleton(() => ValidateStoredSessionUseCase(injector<SessionValidationService>(), injector<UserSessionService>()))`, e passar `injector<ValidateStoredSessionUseCase>()` ao `SplashController` em `providers`
- [ ] T012 [P] [US1] Adicionar a chave `splash_tagline` em `click_seguro_app/lib/core/i18n/app_strings.dart` (`static const String splashTagline = 'splash_tagline';`, logo abaixo de `appTitle`), em `click_seguro_app/assets/translations/pt-BR.json` ("Sua segurança em primeiro lugar") e em `click_seguro_app/assets/translations/en-US.json` ("Your safety comes first") ([R6](research.md))
- [ ] T013 [US1] Em `splash/presentation/pages/splash_page.dart`: navegar com `context.go(controller.destination!.path)` só quando `destination != null` e `mounted` (sem `!`: guardar em variável local); abaixo do título, `SizedBox(height: AppSpacing.s2)` + `Text(AppStrings.splashTagline.tr())` com `textTheme.bodyMedium` na cor `AppColors.textPrimaryForeground` com opacidade de 80% (`withValues(alpha: 0.8)`), como no wireframe. Faz a T008 passar

**Checkpoint**: `flutter test test/modules/splash` verde; no aparelho, reabrir conectado ou como visitante leva à área principal.

---

## Phase 4: User Story 2 - Conta conferida na abertura (Priority: P1)

**Goal**: a conferência da conta corre em paralelo com o tempo mínimo; conta recusada leva ao login, falhas de rede mantêm a sessão e nada prende o splash (FR-002, FR-004 a FR-008).

**Independent Test**: com uma conta desativada (ou sessão que o serviço recusa) → login; com modo avião e sessão válida → área principal em até ~3 s (linhas 5 e 6 do [quickstart](quickstart.md)).

### Testes (escrever primeiro e ver falhar)

- [ ] T014 [P] [US2] Em `tsplash/domain/usecases/validate_stored_session_usecase_test.dart`, acrescentar (linhas 3, 4, 5 e 8 da [tabela](data-model.md)):
  - conferência confirma e atualiza o perfil (`onValidate` chama `session.updateProfile(name: 'Maria Silva', email: 'maria@novo.com')`) → `authenticated` e `session.userName == 'Maria Silva'`;
  - conferência recusa (`onValidate` chama `session.expire()`) → `unauthenticated`;
  - conferência sem efeito (simula sem rede / prazo esgotado) → `authenticated`;
  - `onValidate` lança `StateError('inesperado')` → o usecase **não** lança e devolve o estado atual (`authenticated`) (FR-008).
- [ ] T015 [P] [US2] Em `tsplash/presentation/controller/splash_controller_test.dart`, grupo `paralelismo` ([R5](research.md)), com `minimumDisplayDuration: Duration(milliseconds: 50)` e o fake de validação preso num `Completer<UserSessionStatus>`:
  - validação liberada logo e o mínimo ainda correndo → `destination` continua `null` até o mínimo vencer (aguardar ~60 ms);
  - mínimo vencido e validação pendente → `destination` continua `null`; ao completar com `unauthenticated` → `login`;
  - a validação é chamada uma única vez e é iniciada **antes** do mínimo terminar (verificar `calls == 1` logo após chamar `resolveDestination()`, sem aguardar);
  - linha 4: visto + validação devolvendo `unauthenticated` → `login`.

### Implementação

- [ ] T016 [US2] Em `splash/domain/usecases/validate_stored_session_usecase.dart`, envolver a chamada ao serviço num `try { ... } catch (_) { }` de proteção e sempre devolver `_session.sessionStatus.value` no fim; comentário curto citando o FR-008 desta feature (o serviço já não lança; isto só impede que um erro inesperado prenda o splash). Faz a T014 passar
- [ ] T017 [US2] Revisar `splash/presentation/controller/splash_controller.dart` contra a T015: as três chamadas precisam ser **disparadas** antes do primeiro `await` (criar os futures em variáveis e depois `Future.wait`), e não em sequência. Ajustar se a T015 falhar

**Checkpoint**: `flutter test test/modules/splash` verde, com as 8 linhas da tabela de decisão cobertas entre usecase e controller.

---

## Phase 5: User Story 3 - Primeira abertura com onboarding (Priority: P2)

**Goal**: garantir com testes que o onboarding continua igual ao wireframe e ao RF-002/RN-004 (FR-009, FR-010, FR-012, FR-014). **Sem mudança de código de produção**, salvo se algum teste revelar um defeito.

**Independent Test**: reinstalar, passar pelos slides e tocar em "Começar" → login; reabrir → sem onboarding; repetir com "Pular" (linhas 1, 2, 3 e 9 do [quickstart](quickstart.md)).

### Testes

- [ ] T018 [P] [US3] Criar `tonb/presentation/controller/onboarding_controller_test.dart` com `CompleteOnboardingUseCase(FakeOnboardingRepository())`:
  - começa em `currentPage == 0` e `isLastPage == false`;
  - `next()` no 1º e no 2º slide devolve `false`, avança a página, notifica e não grava a marcação (`completeCalls == 0`);
  - `next()` no último slide devolve `true` e grava a marcação (`completeCalls == 1`);
  - `onPageChanged(2)` (deslizar) atualiza `currentPage`, faz `isLastPage == true` e notifica;
  - `skip()` em qualquer slide devolve `true` e grava a marcação;
  - com `failOnComplete = true`, `next()` no último slide e `skip()` ainda devolvem `true` (FR-010).
- [ ] T019 [P] [US3] Criar `tonb/presentation/pages/onboarding_page_test.dart` com `pumpLocalized(router: ...)`, `GoRouter` de teste (`/onboarding` → `OnboardingPage` dentro de `ChangeNotifierProvider<OnboardingController>`; `/login` → `Scaffold` com `Text('login')`):
  - 1º slide mostra "Proteja-se de golpes", "Pular" e o botão "Continuar";
  - tocar em "Continuar" duas vezes mostra "Aprenda na prática" e o botão "Começar";
  - deslizar (`tester.fling` no `PageView` para a esquerda) até o 3º slide também troca o botão para "Começar";
  - "Começar" abre `/login`;
  - "Pular" no 1º slide abre `/login`;
  - com `failOnComplete = true`, "Pular" ainda abre `/login`.
- [ ] T020 [P] [US3] Criar `tonb/presentation/i18n_keys_test.dart` no padrão de `click_seguro_app/test/modules/authentication/presentation/i18n_keys_test.dart`, com `RegExp(r"'((?:onboarding|splash)_[a-z0-9_]+)'")`: toda chave `onboarding_*`/`splash_*` de `AppStrings` existe em pt-BR e en-US com texto não vazio; e os textos pt-BR dos slides são exatamente os do wireframe (`onboarding_page1_title` = "Proteja-se de golpes", `onboarding_page2_title` = "Notícias verificadas", `onboarding_page3_title` = "Aprenda na prática", as três descrições, "Continuar", "Começar", "Pular" e `splash_tagline` = "Sua segurança em primeiro lugar") (FR-012)

### Implementação

- [ ] T021 [US3] Rodar `flutter test test/modules/onboarding`. Esperado: verde sem mexer em `onb/`. Se algum teste revelar defeito, corrigir o mínimo em `onb/presentation/` e registrar a mudança em [research.md](research.md) (R7)

**Checkpoint**: as três histórias verdes de forma independente.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T022 Formatar só os arquivos tocados (`dart format` com os caminhos de `splash/`, `tsplash/`, `tonb/` e `app_strings.dart`), depois `flutter analyze` (sem avisos novos além dos 28 infos da linha de base) e `flutter test` (todos verdes)
- [ ] T023 Validar no aparelho os 9 passos do [quickstart.md](quickstart.md) (servidor acordado, conta de teste). Anotar no fim desta tarefa o resultado de cada passo
- [ ] T024 Em `.specify/memory/tasks.md`, marcar a A1 como `[x] **A1 Splash + onboarding** (RF-001, RF-002, RN-004) (specs/004-splash-onboarding-sessao)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 primeiro.
- **Foundational (Phase 2)**: depende da Phase 1. T002, T003, T004 e T005 em paralelo (a T004 cria o esqueleto do usecase que a T009 implementa).
- **US1 (Phase 3)**: depende da Phase 2. Testes T006–T008 em paralelo; T009 → T010 → T011; T012 em paralelo; T013 depois de T010 e T012.
- **US2 (Phase 4)**: depende da US1 (mesmo usecase e controller).
- **US3 (Phase 5)**: depende só da T005 (e da T012 para o teste de chaves com `splash_tagline`). Pode andar em paralelo com a US1/US2.
- **Polish (Phase 6)**: depois de todas as histórias.

### User Story Dependencies

- **US1 (P1)**: base; entrega a decisão por sessão.
- **US2 (P1)**: estende os mesmos arquivos da US1 com os casos de conferência e o paralelismo.
- **US3 (P2)**: independente (só testes do onboarding).

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Usecase → controller → registro no módulo → página (ordem do guia).
- Commit ao fim de cada história.

### Parallel Opportunities

- **Phase 2:** T002 ∥ T003 ∥ T004 ∥ T005.
- **US1:** T006 ∥ T007 ∥ T008; T012 ∥ T009–T011.
- **US2:** T014 ∥ T015.
- **US3:** T018 ∥ T019 ∥ T020, e a fase inteira ∥ US1/US2.

---

## Parallel Example: User Story 1

```bash
Task: "Teste do ValidateStoredSessionUseCase em click_seguro_app/test/modules/splash/domain/usecases/validate_stored_session_usecase_test.dart"
Task: "Teste do SplashController (decisão) em click_seguro_app/test/modules/splash/presentation/controller/splash_controller_test.dart"
Task: "Widget test da SplashPage em click_seguro_app/test/modules/splash/presentation/pages/splash_page_test.dart"
```

## Parallel Example: User Story 3

```bash
Task: "Teste do OnboardingController em click_seguro_app/test/modules/onboarding/presentation/controller/onboarding_controller_test.dart"
Task: "Widget test da OnboardingPage em click_seguro_app/test/modules/onboarding/presentation/pages/onboarding_page_test.dart"
Task: "Teste das chaves i18n em click_seguro_app/test/modules/onboarding/presentation/i18n_keys_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 → Phase 2.
2. Phase 3 (US1): reabrir conectado/visitante leva à área principal.
3. **PARAR e VALIDAR**: `flutter test` verde e, no aparelho, os passos 4, 7 e 8 do quickstart.

### Incremental Delivery

1. Setup + Foundational → enum e fakes.
2. US1 → splash decide pela sessão (MVP).
3. US2 → conta conferida, paralelismo e proteção contra erro inesperado.
4. US3 → testes do onboarding.
5. Polish → formatação, aparelho, marcar a A1.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- [USn] mapeia a tarefa para a história da [spec](spec.md).
- Verifique que o teste falha antes de implementar.
- **Não** mexer em `common/`, `main.dart`, `app_router.dart` nem no shell (F0.9). O destino
  `/home` continua provisório.
- O `dart format` em pastas inteiras reformata arquivos fora do escopo: formate só os arquivos
  tocados pela tarefa.
