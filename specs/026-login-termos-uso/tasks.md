# Tasks: Login que continua a splash, aceite dos termos e Termos de uso

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/ui-contract.md](contracts/ui-contract.md),
[quickstart.md](quickstart.md)

**Testes**: obrigatórios (Princípio III da constituição, TDD). Em cada história, o teste vem
antes do código e precisa falhar primeiro.

**Commits**: um por fase (Base, US1, US2, US3, US4) e um de documentos no fim. Os arquivos
entram por nome. Nunca entram `assets/images/`, `click-seguro.html`, `demo*`, `test_visual/`
nem `devtools_options.yaml`.

Todos os caminhos partem de `click_seguro_app/`, salvo quando indicado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem depender de tarefa aberta)
- **[Story]**: história da spec (US1 a US4)

---

## Phase 1: Setup

**Purpose**: textos novos nos dois idiomas, usados por todas as histórias.

- [X] T001 Adicionar as chaves novas de [contracts/ui-contract.md](contracts/ui-contract.md) ("Novas") em `lib/core/i18n/app_strings.dart` (`authWelcomeTitle`, `authTermsPrefix`, `authTermsLink`, `authTermsAnd`, `authPrivacyLink`, `settingsTerms`, `settingsTermsSub`, `settingsTermsUpdated`, `settingsTerms{About,Limits,Account,Use,Data}{Title,Body}`, `settingsTermsSeePrivacy`) e os textos exatos do contrato em `assets/translations/pt-BR.json` e `assets/translations/en-US.json`

---

## Phase 2: Foundational (Base)

**Purpose**: peças compartilhadas que a US1 e a US3/US4 usam. A splash e a Privacidade não podem mudar de aparência.

**⚠️ CRITICAL**: termine esta fase antes das histórias.

- [X] T002 [P] Escrever `test/core/widgets/brand_scene_test.dart`:
  - `BrandScene.logoRectFor` devolve os mesmos retângulos que o `SplashScenePainter.logoRectFor` de hoje (largura 390/360, telas alta e baixa, `topInset`);
  - `BrandScene.titleTopFor(logoRect)` dá a posição do nome que a `SplashAnimation` usa hoje (`logo.bottom + s7`), e `BrandScene.taglineGap` (8) o espaço até o slogan (o slogan depende da altura do nome, que muda com a fonte);
  - `BrandScene.wavePath(progress: 1)` fica dentro da caixa do rodapé;
  - `BrandWave` pinta com `primary`/`primaryGlow` e no alto contraste.
- [X] T003 Criar `lib/core/widgets/brand_scene.dart` (research R2):
  - mover do `splash_scene_painter.dart` as larguras de referência, `footerHeight` (110), a altura da onda de brilho (136), `_frontEdge`/`_glowEdge`, `logoRectFor` e a montagem do caminho da onda (`wavePath(size, edge, top, progress, below)`);
  - criar `titleTopFor(logoRect)` e `taglineGap`, a posição do nome e o espaço até o slogan no fim da splash, fonte única para a splash e para a abertura do login (analyze I1);
  - criar o widget `BrandWave`: as duas ondas paradas, altura 136, cores de `context.colors`, decorativo (`ExcludeSemantics`).
- [X] T004 Fazer `lib/modules/splash/presentation/widgets/splash_scene_painter.dart` usar o `BrandScene` sem mudar o desenho, e `splash_animation.dart` posicionar o nome e o slogan com `BrandScene.titleTopFor`/`taglineGap`. Manter `SplashScenePainter.logoRectFor`/`footerHeight` só se ainda tiverem uso; senão, trocar as chamadas em `splash_animation.dart` e no teste. Rodar `test/modules/splash` e `test/core/widgets/brand_scene_test.dart`: tudo verde.
- [X] T005 [P] Extrair o `_Paragraph` de `lib/modules/settings/presentation/pages/privacy_page.dart` para `lib/modules/settings/presentation/widgets/settings_topic_card.dart` (`SettingsTopicCard`: ícone, título, texto e um `child` opcional abaixo do texto). Usar na Privacidade e rodar `test/modules/settings/presentation/privacy_and_about_pages_test.dart` sem mudar o teste.

**Checkpoint**: splash e Privacidade iguais; `BrandScene`, `BrandWave` e `SettingsTopicCard` prontos. **Commit**: `refactor(026): onda e posição da marca no core, cartão de assunto das Configurações`.

---

## Phase 3: User Story 1 - Ler os Termos de uso (Priority: P1) 🎯 MVP

**Goal**: tela Termos de uso nas Configurações, com e sem conta, abrindo também sem sessão.

**Independent Test**: Configurações → Termos de uso: cinco assuntos na ordem, data, "Ouvir" e "Ver Privacidade" (quickstart passos 1, 2 e 13).

### Tests for User Story 1 ⚠️

- [X] T006 [P] [US1] Escrever `test/modules/settings/presentation/terms_page_test.dart`:
  - título "Termos de uso" e a data;
  - cinco cartões na ordem O que é o Click Seguro / O que o app não faz / Sua conta / Bom uso do app / Seus dados;
  - "Ver Privacidade" empilha `/settings/privacy`;
  - `termsSpokenText()` = título, data e cada título e texto, nessa ordem;
  - textos em en-US.
- [X] T007 [P] [US1] Estender `test/modules/settings/presentation/settings_page_test.dart`: a linha "Termos de uso" com "O que vale ao usar o app" vem logo depois de "Privacidade", com conta e como visitante, e o toque empilha `/settings/terms`.
- [X] T008 [P] [US1] Estender `test/core/routing/app_router_test.dart`: depois de "Sair da conta" (`SessionEndReason.userLogout`), `/settings/terms` e `/settings/privacy` abrem sem voltar ao login; outra rota protegida continua indo para `/login`.

### Implementation for User Story 1

- [X] T009 [US1] Criar `lib/modules/settings/presentation/pages/terms_page.dart` (research R6):
  - `TermsPage` com `SettingsScaffold(title: settingsTerms)`, `SettingsListenButton(text: termsSpokenText())`, a data em legenda e cinco `SettingsTopicCard`;
  - ícones Lucide `info`, `triangleAlert`, `keyRound`, `circleCheck`, `shieldCheck`;
  - no último cartão, o link "Ver Privacidade" (coral, sublinhado, 48 de altura) com `context.push('/settings/privacy')`;
  - função pública `termsSpokenText()`.
- [X] T010 [US1] Registrar a rota `terms` sob `/settings` (`parentNavigatorKey: rootNavigatorKey`) em `lib/modules/settings/presentation/routes/settings_routes.dart`.
- [X] T011 [US1] Adicionar o `SettingsTile` "Termos de uso" (ícone `fileText`, subtítulo `settingsTermsSub`) logo depois de "Privacidade" em `_AboutSection` de `lib/modules/settings/presentation/pages/settings_page.dart`.
- [X] T012 [US1] Incluir `/settings/terms` e `/settings/privacy` em `_publicPaths` de `lib/core/routing/app_router.dart` (research R5).
- [X] T013 [US1] Rodar `test/modules/settings` e `test/core/routing`: tudo verde.

**Checkpoint**: Termos acessíveis nas Configurações e sem sessão. **Commit**: `feat(026): tela Termos de uso nas Configurações`.

---

## Phase 4: User Story 2 - Aceitar os termos ao criar a conta (Priority: P1)

**Goal**: caixa de aceite no cadastro; "Criar conta" só ativa com ela marcada; links para Termos e Privacidade sem perder o formulário.

**Independent Test**: aba "Criar conta" com dados válidos: botão desativado até marcar; links abrem e voltam com tudo intacto (quickstart passos 3 a 7).

### Tests for User Story 2 ⚠️

- [ ] T014 [P] [US2] Estender `test/modules/authentication/presentation/controller/authentication_controller_test.dart` com a tabela do [data-model.md](data-model.md) §1:
  - `termsAccepted` começa `false`;
  - no cadastro válido, `canSubmit` é `false` sem aceite e `true` com aceite;
  - no login, o aceite não importa;
  - `setMode` mantém o aceite e `reset()` o zera;
  - `submit` no cadastro sem aceite não chama o `RegisterUseCase`;
  - uma falha no cadastro mantém o aceite.
- [ ] T015 [P] [US2] Escrever `test/modules/authentication/presentation/widgets/terms_acceptance_test.dart`:
  - desmarcada: só o contorno, cartão claro;
  - tocar no quadrado ou em "Li e aceito os" chama `onChanged(true)`;
  - marcada: visto e cartão `primarySoft` com borda `primary`;
  - tocar em "Termos de uso" e em "Política de privacidade" chama `onOpenTerms` e `onOpenPrivacy`, sem chamar `onChanged`;
  - a área de toque tem pelo menos 48 × 48;
  - semântica com `checked` e o texto completo, e "Termos de uso" e "Política de privacidade" anunciados como links (analyze C1);
  - com fonte 2,0 numa tela de 360 de largura, o texto quebra em várias linhas sem estouro nem corte e a área de toque continua com pelo menos 48 × 48 (analyze C3);
  - textos em en-US.
- [ ] T016 [P] [US2] Estender `test/modules/authentication/presentation/pages/login_page_test.dart`:
  - a caixa aparece só em "Criar conta", abaixo das regras;
  - "Criar conta" desativado até marcar;
  - o aceite sobrevive a Entrar → Criar conta;
  - o link "Termos de uso" empilha `/settings/terms` e, ao voltar, nome, e-mail, senha e caixa continuam iguais (idem para "Política de privacidade" e `/settings/privacy`);
  - Termos → "Ver Privacidade" → voltar duas vezes chega ao cadastro com tudo preenchido e a caixa no mesmo estado (analyze C2);
  - reabrir a página zera a caixa.

### Implementation for User Story 2

- [ ] T017 [US2] Em `lib/modules/authentication/presentation/controller/authentication_controller.dart`:
  - `bool get termsAccepted` e `void setTermsAccepted(bool value)`;
  - `canSubmit = _formErrors.isEmpty && !_isSubmitting && (_mode == AuthMode.login || _termsAccepted)`;
  - `submit` retorna sem chamar o usecase se a condição falhar;
  - `reset()` zera o aceite e `setMode` não mexe nele.
- [ ] T018 [US2] Criar `lib/modules/authentication/presentation/widgets/terms_acceptance.dart` (research R7):
  - `StatefulWidget` com `accepted`, `onChanged`, `onOpenTerms` e `onOpenPrivacy`;
  - quadrado de 28 e canto 8 numa área de 48 × 48;
  - `Text.rich` com dois `TapGestureRecognizer` descartados no `dispose`;
  - cartão com canto 16, padding 14/16, cores de `context.colors` (FR-008);
  - `Semantics(checked:, onTap:, label:)`.
- [ ] T019 [US2] Em `lib/modules/authentication/presentation/pages/login_page.dart`:
  - no modo cadastro, `TermsAcceptance` depois das regras da senha, dentro do mesmo `AnimatedReveal`;
  - `onOpenTerms` → `context.push('/settings/terms')`, `onOpenPrivacy` → `context.push('/settings/privacy')`;
  - `disabled` do botão principal usa o `canSubmit` novo.
- [ ] T020 [US2] Rodar `test/modules/authentication`: tudo verde.

**Checkpoint**: cadastro com aceite funcionando sobre o visual atual. **Commit**: `feat(026): aceite dos Termos de uso e da Política de privacidade no cadastro`.

---

## Phase 5: User Story 3 - Login e cadastro no visual da splash (Priority: P2)

**Goal**: layout da versão A com a onda no rodapé; sai o código que fica sem uso.

**Independent Test**: login e cadastro iguais às telas "A · Continuação da splash" e "A · Cadastro com aceite dos termos" (quickstart passos 8, 9 e 14).

### Tests for User Story 3 ⚠️

- [ ] T021 [P] [US3] Reescrever `test/modules/authentication/presentation/widgets/auth_header_test.dart`: marca, "Bem-vindo ao Click Seguro" e "Sua segurança em primeiro lugar" centralizados; um único cabeçalho para o leitor de tela; en-US.
- [ ] T022 [P] [US3] Estender `test/modules/authentication/presentation/pages/login_page_test.dart`:
  - ordem marca → título → slogan → abas → E-mail → Senha → "Esqueci minha senha" (alinhado à direita) → "Entrar" (com `arrowRight`) → "Continuar sem login";
  - nenhum "ou" e nenhum aviso do visitante, no login e no cadastro;
  - `BrandWave` presente;
  - com fonte 2,0 e tela baixa, o último item rola até ficar acima da onda;
  - "Continuar sem login" chama `continueAsGuest`.
- [ ] T023 [P] [US3] Ajustar `test/modules/authentication/presentation/pages/accessibility_test.dart` ao layout novo (alvos de 48, rótulos) sem perder casos.

### Implementation for User Story 3

- [ ] T024 [US3] Reescrever `lib/modules/authentication/presentation/widgets/auth_header.dart` (research R8): coluna centralizada com `AppLogo(size: 68)` dentro de um slot com `logoKey` opcional (destino do voo na US4), `authWelcomeTitle` em `AppTypography.display` e `splashTagline` em `AppTypography.body`; `Semantics(header: true)`.
- [ ] T025 [US3] Reorganizar `lib/modules/authentication/presentation/pages/login_page.dart` (research R3/R8):
  - `Scaffold(resizeToAvoidBottomInset: false)` com `Stack` (`BrandWave` no pé, e a rolagem por cima);
  - espaço final da rolagem = `max(BrandScene.footerHeight + AppSpacing.s4, teclado + AppSpacing.s6)`;
  - "Esqueci minha senha" à direita;
  - `SafeButton(iconRight: Icon(LucideIcons.arrowRight))`;
  - "Continuar sem login" como `TextButton` coral (`primaryPressed`, 16/600, mínimo 48);
  - remover o `OrDivider`, o botão secundário e o aviso do visitante.
- [ ] T026 [US3] Apagar `lib/modules/authentication/presentation/widgets/or_divider.dart` e o teste dele, se existir. Remover `authOr`, `authGuestNote`, `authWelcome` e `authBrand` de `lib/core/i18n/app_strings.dart` e de `assets/translations/pt-BR.json`/`en-US.json`. Conferir com busca que nada mais as usa.
- [ ] T027 [US3] Rodar `test/modules/authentication` e `test/core`: tudo verde.

**Checkpoint**: login e cadastro com o visual aprovado. **Commit**: `feat(026): login e cadastro no visual da splash`.

---

## Phase 6: User Story 4 - Passagem animada da splash para o login (Priority: P3)

**Goal**: a splash abre `/login?from=splash` e o login faz a abertura; movimento reduzido mostra o login pronto.

**Independent Test**: abrir o app sem sessão e comparar com "A · Animação splash → login"; repetir com "Reduzir animações" (quickstart passos 10 a 12).

### Tests for User Story 4 ⚠️

- [ ] T028 [P] [US4] Escrever `test/modules/authentication/presentation/widgets/login_intro_test.dart` com o relógio falso:
  - no quadro 0, a marca está em `BrandScene.logoRectFor(...)` e o nome/slogan da splash estão visíveis;
  - em 750 ms, a marca está no slot do `AuthHeader`;
  - em 1 250 ms, todos os itens estão visíveis e opacos, e os toques passam;
  - antes disso, os toques são ignorados;
  - com movimento reduzido, tudo pronto no quadro 0;
  - o nome/slogan da splash ficam fora da semântica.
- [ ] T029 [P] [US4] Estender `test/modules/authentication/presentation/pages/login_page_test.dart` e o teste das rotas de autenticação: `loginPageFor(Uri.parse('/login?from=splash'))` liga a abertura e a página não tem transição; `/login` e `/login?mode=register` continuam sem abertura e com esmaecimento.
- [ ] T030 [P] [US4] Ajustar `test/modules/splash/presentation/pages/splash_page_test.dart` e `test/modules/splash/presentation/controller/splash_controller_test.dart`: o destino login navega para `/login?from=splash`; Início e Onboarding continuam iguais.

### Implementation for User Story 4

- [ ] T031 [US4] Trocar o caminho de `SplashDestination.login` para `'/login?from=splash'` em `lib/modules/splash/presentation/controller/splash_destination.dart`.
- [ ] T032 [US4] Em `lib/modules/authentication/presentation/routes/authentication_routes.dart`:
  - `loginPageFor` lê `from=splash` e passa `fromSplash: true` à `LoginPage`;
  - a rota usa uma página sem transição (`NoTransitionPage` com `key: state.pageKey`) nesse caso e `appFadePage` nos outros.
- [ ] T033 [US4] Criar `lib/modules/authentication/presentation/widgets/login_intro.dart` (research R1):
  - um `AnimationController` de 1 250 ms, iniciado no `didChangeDependencies`, que nasce em 1 com `AppMotion.of(context).reduced`;
  - expõe para a página a animação de cada item (`Interval`s da tabela R1) e um `IgnorePointer` enquanto anima;
  - desenha por cima a marca voando: `Rect.lerp` entre `BrandScene.logoRectFor` e o retângulo do slot `logoKey` (medido em coordenadas globais depois do primeiro layout), com `AppLogo`/`BrandMarkPainter` na cor `primary`;
  - desenha o nome e o slogan da splash saindo (`ExcludeSemantics`) nas posições de `BrandScene.titleTopFor`/`taglineGap`, as mesmas da splash (analyze I1).
- [ ] T034 [US4] Em `lib/modules/authentication/presentation/pages/login_page.dart`:
  - novo parâmetro `fromSplash` (padrão `false`);
  - com ele, envolver o conteúdo no `LoginIntro`: o slot da marca do cabeçalho fica vazio até o voo terminar, e cada bloco (cabeçalho, abas, campos, regras/aceite, "Esqueci"/botão, "Continuar sem login") recebe o seu intervalo de subida de 14 px com esmaecimento;
  - sem o parâmetro, nada muda.
- [ ] T035 [US4] Rodar `test/modules/authentication`, `test/modules/splash` e `test/core`: tudo verde.

**Checkpoint**: passagem contínua da splash para o login. **Commit**: `feat(026): passagem animada da splash para o login`.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T036 Revisar o código de produção da feature atrás de código morto ou que só existe para testes (chave pública só para teste, parâmetro sem uso) e remover, ajustando os testes.
- [ ] T037 `flutter analyze` sem avisos novos e `flutter test` completo verde (~30 min). Registrar as contagens.
- [ ] T038 [P] Documentos do produto (raiz do repositório):
  - em `.specify/memory/tasks.md`, a tarefa **R3 Login, aceite dos termos e Termos de uso** (aberta até a validação);
  - em `.specify/memory/specification.md`: RF-003 com o aceite, RF-037 com a linha "Termos de uso", nota da passagem splash → login no RF-001 e entrada no histórico de versões;
  - em `.specify/memory/design-system.md`: `BrandWave`/`BrandScene` e `SettingsTopicCard`.
- [ ] T039 Validação da usuária no aparelho seguindo [quickstart.md](quickstart.md) (passos 1 a 14; o 14 cria conta só com permissão). Ajustes vindos da validação viram esclarecimentos na spec.
- [ ] T040 Marcar as tarefas concluídas aqui e a R3 em `.specify/memory/tasks.md` e rodar o `/revisar-pr` na branch (diff `origin/develop...026-login-termos-uso`). Corrigir os achados altos e médios, fazer push e abrir o PR para `develop` (O que entra / Como validar / Fora do escopo).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001)** → **Base (T002–T005)** → histórias.
- **US1 (T006–T013)**: depende da Base (`SettingsTopicCard`).
- **US2 (T014–T020)**: depende do Setup. Os links da US2 abrem as telas da US1, então a US1 vem antes para o teste de navegação e a validação.
- **US3 (T021–T027)**: depende da Base (`BrandWave`). Mexe na mesma página que a US2: faça depois dela.
- **US4 (T028–T035)**: depende da US3 (slot `logoKey` no cabeçalho e o layout final).
- **Polish (T036–T040)**: depois de todas.

### Within Each User Story

- Testes primeiro, falhando. Depois o controller ou widget, depois a página, depois a rodada dos testes da história.
- Commit ao fim de cada fase.

### Parallel Opportunities

- Base: T002 e T005 (arquivos diferentes).
- US1: T006, T007 e T008.
- US2: T014, T015 e T016.
- US3: T021, T022 e T023.
- US4: T028, T029 e T030.
- Polish: T038 em paralelo com T037 (a suíte demora).

## Parallel Example: User Story 2

```text
Juntos (arquivos diferentes):
  T014 authentication_controller_test.dart (aceite)
  T015 terms_acceptance_test.dart
  T016 login_page_test.dart (fluxo do aceite)
Depois, em ordem: T017 controller → T018 TermsAcceptance → T019 LoginPage → T020 testes
```

## Implementation Strategy

### MVP

1. Setup e Base.
2. US1 (Termos de uso): o documento existe e pode ser lido.
3. US2 (aceite): o requisito de consentimento fica completo. **Para e valida**: aqui a feature
   já pode ser entregue no visual atual do login.

### Incremental

4. US3: visual da versão A.
5. US4: passagem animada.
6. Polimento, validação no aparelho, `/revisar-pr` e PR.
