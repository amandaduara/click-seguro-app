---

description: "Task list for feature 014: tela de acessibilidade"
---

# Tasks: Tela de Acessibilidade

**Input**: Design documents from `/specs/014-acessibilidade/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/accessibility-ui.md](contracts/accessibility-ui.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** Constituição Seção III (TDD): cada teste é escrito e **rodado sozinho
para ver falhar** antes da implementação. Offline: `FakeLocalCacheService`
(`app/test/fakes/fake_local_cache_service.dart`) por baixo de um `AccessibilityController` **real**
na tela (pedido da tarefa B9, [R9](research.md#r9-testes)); widget tests das Configurações com
`pumpLocalized` (`app/test/helpers/localized_app.dart`) e `registerSettingsDependencies`
(`app/test/helpers/settings_dependencies.dart`); `GetIt.instance.reset()` no `tearDown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Caminhos relativos à raiz do repositório. `app/` = `click_seguro_app/`; `set/` =
  `click_seguro_app/lib/modules/settings/`; `tset/` = `click_seguro_app/test/modules/settings/`.
- Chaves e textos exatos no [data-model §3–§4](data-model.md#3-apresentação-novos-settingspresentation);
  ordem e conteúdo da tela no [contrato §4](contracts/accessibility-ui.md#4-tela-de-acessibilidade-ordem-de-cima-para-baixo);
  o porquê de cada decisão no [research](research.md).
- Visual: o mesmo das Configurações da B8: `SettingsSection` (título 18/700, cartão branco com
  borda, raio 20, divisórias) e linhas no padrão do `SettingsTile` (ícone em quadrado 44, título
  16/700, subtítulo 14 muted, altura mínima 64). Cores sempre por `context.colors`.
- Chave do armazenamento: `accessibility_preferences_v1`
  (`AccessibilityLocalDataSourceImpl.storageKey`). Níveis: `standard` 1,0 · `large` 1,15 ·
  `larger` 1,3 · `largest` 1,5; teto da escala total 2,0.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Dentro de `app/`, `git fetch` e conferir se a `develop` tem algo novo (se tiver, parar e avisar: o outro desenvolvedor pode mexer em `shell`, `profile` ou `settings`); rodar `flutter analyze` e `flutter test` e anotar a linha de base (testes, erros, warnings, infos) no fim desta tarefa. **Linha de base (2026-10-15):** `develop` sem novidades e nenhum PR aberto; `flutter test` 1312 verdes; `flutter analyze` 28 issues, todos `info`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: textos, rótulos e os widgets de linha que a tela usa; a rota passa a abrir a página
nova (por ora só com o título), e a provisória sai.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T002 [P] Criar `tset/presentation/extensions/accessibility_presentation_test.dart`: `FontScaleLevel.percentLabel` → `'100%'`, `'115%'`, `'130%'`, `'150%'`; cada `FontScaleLevel` e cada `ReadingSpeed` tem chave de rótulo própria (`settings_accessibility_font_standard`… `settings_accessibility_speed_fast`) e nenhuma se repete
- [X] T003 [P] Criar `tset/presentation/widgets/settings_option_tile_test.dart` (com `pumpLocalized` ou `MaterialApp` simples): três `SettingsOptionTile<int>` dentro de um `RadioGroup<int>`; a do valor do grupo aparece marcada; tocar na **linha** (no título, não no círculo) chama `onChanged` com o valor dela; semântica com o título, o texto à direita e `isChecked`/`isInMutuallyExclusiveGroup`; altura ≥ 64
- [X] T004 [P] Criar `tset/presentation/widgets/settings_switch_tile_test.dart`: título, subtítulo e a chave com `value`; tocar na linha e na chave chamam `onChanged(!value)`; `onChanged` nulo → chave desabilitada e toque sem efeito; semântica com `isToggled`; altura ≥ 64

### Implementação

- [X] T005 Chaves de i18n: em `app/lib/core/i18n/app_strings.dart`, bloco `// --- settings ---`, as constantes da tabela do [data-model §4](data-model.md#4-textos-novos-e-alterados-i18n) e as sete de rótulo do §3 (`settingsAccessibilitySectionFont`, `settingsAccessibilityPreviewTitle`, `settingsAccessibilityPreviewBody`, `settingsAccessibilityFontStandard`/`Large`/`Larger`/`Largest`, `settingsAccessibilitySectionAppearance`, `settingsAccessibilityHighContrast`, `settingsAccessibilityHighContrastSub`, `settingsAccessibilitySectionVoice`, `settingsAccessibilityAutoRead`, `settingsAccessibilityAutoReadSub`, `settingsAccessibilitySpeed`, `settingsAccessibilitySpeedSlow`/`Normal`/`Fast`), com os textos pt-BR e en-US do data-model em `app/assets/translations/pt-BR.json` e `en-US.json`. Já cobertas por `app/test/modules/shell/i18n_keys_test.dart` (prefixo `settings_`)
- [X] T006 [P] Criar `set/presentation/extensions/accessibility_presentation.dart`: `extension FontScaleLevelPresentation on FontScaleLevel` (`label` já traduzido, como o `LanguageChoicePresentation.label`; `labelKey` por `switch` no plano original, `percentLabel` = `"${(factor * 100).round()}%"`) e `extension ReadingSpeedPresentation on ReadingSpeed` (`labelKey`). Faz a T002 passar
- [X] T007 [P] Criar `set/presentation/widgets/settings_option_tile.dart`: `SettingsOptionTile<T>` (`value`, `title`, `trailingText?`) no visual do `SettingsTile` **sem** o quadrado do ícone (padding horizontal `AppSpacing.s4`, título 16/700, texto à direita 14 muted), com `Radio<T>(value: value)` à direita, lendo o grupo do `RadioGroup<T>` ancestral (sem `groupValue`/`onChanged` no `Radio`, obsoletos desde o 3.32); a linha chama `RadioGroup.maybeOf<T>(context)?.onChanged(value)` ao toque; `MergeSemantics` em volta. Faz a T003 passar
- [X] T008 [P] Criar `set/presentation/widgets/settings_switch_tile.dart`: `SettingsSwitchTile` (`icon`, `title`, `subtitle?`, `value`, `onChanged?`) = `SettingsTile` com `onTap: onChanged == null ? null : () => onChanged!(!value)` e `trailing: Switch(value, activeThumbColor: colors.card, activeTrackColor: colors.success, onChanged)`, como na `AlertsSwitchTile`. Faz a T004 passar
- [X] T009 [P] Extrair do `set/presentation/widgets/settings_section.dart` duas peças públicas no mesmo arquivo, sem mudar o visual da B8: `SettingsSectionTitle` (o título 18/700 `colors.secondary` com `Semantics(header: true)` e o padding `fromLTRB(s1, s5, s1, s2)`) e `SettingsCard` (o `Material` `colors.card` com borda, raio `radius2xl`, `Clip.antiAlias` e divisórias entre os filhos); o `SettingsSection` passa a ser `Column(SettingsSectionTitle, SettingsCard)`. A tela de Acessibilidade usa as duas peças para pôr a prévia e o rótulo da velocidade fora do cartão (análise de 2026-10-15, I1). Os testes de `tset/presentation/settings_page_test.dart` continuam verdes sem mudança
- [X] T010 Refatorar `set/presentation/widgets/alerts_switch_tile.dart` para usar o `SettingsSwitchTile` (ela continua escolhendo o subtítulo de erro e mostrando "Tentar novamente"); o grupo "alertas" de `tset/presentation/settings_page_test.dart` continua verde sem mudança
- [X] T011 Criar `set/presentation/pages/accessibility_page.dart` com `Scaffold`, `AppBar` com `AppStrings.settingsAccessibilityTitle.tr()` e `SafeArea` + `ListView` vazio (padding como o da `SettingsPage`: `fromLTRB(s5, s4, s5, s6)`), lendo `context.watch<AccessibilityController>()`. Em `set/presentation/routes/settings_routes.dart`, `accessibility` passa a construir `const AccessibilityPage()`; apagar `set/presentation/pages/settings_section_page.dart` e o import. Em `app/test/core/routing/app_router_test.dart`, linha 93, trocar `SettingsSectionPage` por `AccessibilityPage`; o teste **monta** cada rota com a própria lista de providers (`open()`, linhas 46–66), então criar `fakeAccessibilityProvider()` em `app/test/helpers/` (como os outros `fake*Provider`: `ChangeNotifierProvider.value` de um `AccessibilityController` real sobre `FakeLocalCacheService` e um `AccessibilityPreferencesNotifier` novo) e acrescentá-lo à lista do `open()`

**Checkpoint**: `flutter analyze` limpo; testes de rótulos e widgets verdes; grupo de alertas da B8 verde.

---

## Phase 3: User Story 1 - Escolher o tamanho da letra vendo como fica (Priority: P1) 🎯 MVP

**Goal**: seção "Tamanho da letra" com prévia e quatro níveis; efeito na hora e na próxima
abertura (FR-001 a FR-003, FR-007 a FR-012, FR-017).

**Independent Test**: passos 1–3 e 7–11 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [X] T012 [US1] Criar `tset/presentation/accessibility_page_test.dart`, com helper local `pumpAccessibility(tester, {FakeLocalCacheService? cache, double systemScale = 1.0, Locale locale = pt-BR})` que monta, como em `app/test/accessibility_app_test.dart`, `EasyLocalization` + `ClickSeguroApp(moduleManager: ModuleManager(), router, accessibility: notifier)` com um `GoRouter` de rota única `/settings/accessibility` → `ChangeNotifierProvider.value(value: controller, child: AccessibilityPage())`, e guarda o `BuildContext` da página; `controller` = `AccessibilityController` real (`GetAccessibilityPreferencesUseCase`/`SaveAccessibilityPreferencesUseCase` → `AccessibilityRepositoryImpl` → `AccessibilityLocalDataSourceImpl(cache)`), com `await controller.load()` antes de montar. Casos:
  - abre com o título "Tamanho da letra", o cartão de prévia ("Golpe do falso parente" e a frase) e as quatro linhas "Padrão 100%", "Grande 115%", "Maior 130%", "Muito grande 150%", com "Padrão" marcada;
  - tocar em "Muito grande" → marcada, `MediaQuery.textScalerOf(page).scale(10) / 10` ≈ 1,5 e `cache.values['accessibility_preferences_v1']` com o nível `largest` (formato do `AccessibilityPreferencesModel`);
  - **próxima abertura**: depois de escolher "Maior", um controller novo sobre o mesmo `cache` faz `load()` e a página montada de novo mostra "Maior" marcada e escala ≈ 1,3;
  - tocar em "Padrão" volta a escala para 1,0;
  - tocar na opção já marcada não grava de novo (`cache.writeCalls` igual);
  - `cache.throwOnWrite = true` → tocar em "Grande" aplica (escala ≈ 1,15), nenhum `SnackBar`/erro e `tester.takeException()` nulo;
  - `systemScale: 2.0` + "Muito grande" num celular (1080×2340, dpr 3) → sem estouro, todas as linhas alcançáveis rolando e com altura ≥ 48;
  - semântica: a linha marcada anuncia "selecionado" (`isChecked`) e as outras não;
  - com `locale: en-US` → "Text size", "Default", "Extra large"

### Implementação

- [X] T013 [P] [US1] Criar `set/presentation/widgets/font_preview_card.dart`: cartão (`colors.card`, borda `colors.border`, raio `AppSpacing.radius2xl`, padding `s4`) com `settingsAccessibilityPreviewTitle` em `titleMedium` 18/700 `colors.secondary` e `settingsAccessibilityPreviewBody` em `bodyLarge` 16 `colors.textForeground`; tamanhos fixos multiplicados pelo `textScaler` do app (sem escala própria, [R2](research.md#r2-tamanho-da-letra-e-prévia-ao-vivo))
- [X] T014 [US1] Em `set/presentation/pages/accessibility_page.dart`, a seção "Tamanho da letra": em sequência: `SettingsSectionTitle(settingsAccessibilitySectionFont)`, o `FontPreviewCard`, `SizedBox(height: AppSpacing.s3)` e um `RadioGroup<FontScaleLevel>(groupValue: controller.preferences.fontScale, onChanged: (level) => controller.setFontScale(level!))` envolvendo um `SettingsCard` com um `SettingsOptionTile` por `FontScaleLevel.values` (`title: level.labelKey.tr()`, `trailingText: level.percentLabel`). Faz a T012 passar

**Checkpoint**: `flutter test tset/presentation/accessibility_page_test.dart` verde. Commit da Base + US1.

---

## Phase 4: User Story 2 - Ligar o alto contraste (Priority: P2)

**Goal**: chave "Alto contraste" com efeito no app inteiro (FR-004, FR-007, FR-008).

**Independent Test**: passos 4 e 7 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T015 [US2] Em `tset/presentation/accessibility_page_test.dart`, grupo "alto contraste": seção "Aparência" com "Alto contraste" e "Cores mais fortes para ler melhor", chave desligada; tocar → chave ligada, `page.colors == AppPalette.highContrast` e gravado com `highContrast: true`; tocar de novo → `AppPalette.light`; próxima abertura com contraste salvo → chave ligada e tema de alto contraste; alto contraste + "Muito grande" + `systemScale: 2.0` → sem estouro

### Implementação

- [ ] T016 [US2] Em `set/presentation/pages/accessibility_page.dart`, depois da seção de tamanho: `SettingsSection(title: settingsAccessibilitySectionAppearance)` com `SettingsSwitchTile(icon: LucideIcons.contrast, title: settingsAccessibilityHighContrast, subtitle: settingsAccessibilityHighContrastSub, value: preferences.highContrast, onChanged: controller.setHighContrast)`. Faz a T015 passar

**Checkpoint**: arquivo de teste da página verde. Commit da US2.

---

## Phase 5: User Story 3 - Ligar a leitura automática e escolher a velocidade da voz (Priority: P3)

**Goal**: chave "Ler automaticamente" e as três velocidades (FR-005 a FR-008).

**Independent Test**: passos 5–7 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T017 [US3] Em `tset/presentation/accessibility_page_test.dart`, grupo "leitura em voz alta": seção "Leitura em voz alta" com "Ler automaticamente" e "Ao abrir uma notícia, o app começa a ler sozinho" (desligada), o subtítulo "Velocidade da voz" e "Lenta", "Normal" (marcada), "Rápida"; ligar a chave → `notifier.value.autoReadAloud == true` e gravado; escolher "Lenta" → marcada, `notifier.value.readingSpeed == ReadingSpeed.slow` e gravado; velocidade escolhível com a leitura automática desligada; próxima abertura → as duas escolhas aparecem

### Implementação

- [ ] T018 [US3] Em `set/presentation/pages/accessibility_page.dart`, depois de Aparência: `SettingsSection(title: settingsAccessibilitySectionVoice)` com `SettingsSwitchTile(icon: LucideIcons.volume2, title: settingsAccessibilityAutoRead, subtitle: settingsAccessibilityAutoReadSub, value: preferences.autoReadAloud, onChanged: controller.setAutoReadAloud)`; abaixo dela, `SettingsSectionTitle(settingsAccessibilitySpeed)` e um `RadioGroup<ReadingSpeed>` (`groupValue: preferences.readingSpeed`, `onChanged: (s) => controller.setReadingSpeed(s!)`) envolvendo um `SettingsCard` com um `SettingsOptionTile` por `ReadingSpeed.values` (`title: speed.labelKey.tr()`). Faz a T017 passar

**Checkpoint**: arquivo de teste da página verde. Commit da US3.

---

## Phase 6: User Story 4 - Visitante chega às Configurações sem conta (Priority: P2)

**Goal**: engrenagem para todos; Configurações do visitante só com itens sem conta e sem pedido ao
serviço (FR-013 a FR-016, [R6](research.md#r6-visitante-nas-configurações)).

**Independent Test**: passos 12–17 do [quickstart](quickstart.md).

### Testes (escrever primeiro e ver falhar)

- [ ] T019 [P] [US4] Em `tset/presentation/settings_controller_test.dart`: `loadDeviceSettings()` → `appVersion == '1.0.0'` e `language` lida, **sem** chamar o `FakeAccountRepository` (`totalCalls == 0`) e com `account` ainda `AccountLoading`; `load()` continua carregando conta, versão e idioma
- [ ] T020 [P] [US4] Em `tset/presentation/settings_page_test.dart`, reescrever o grupo "sem conta":
  - visitante abrindo `/settings` → "Leitura e aparência" com "Acessibilidade" e "Idioma", "Sobre" com "Privacidade" e "Sobre o SafeNews" ("Versão 1.0.0"); **sem** "Maria da Silva"/cartão, "Conta", "Dados pessoais", "Alterar senha", "Alertas", "Sair da conta", "Entre na sua conta" e "Entrar ou criar conta"; `repository.totalCalls == 0`;
  - visitante: "Acessibilidade" → `/settings/accessibility`, "Privacidade" → `/settings/privacy`, "Sobre o SafeNews" → `/settings/about`;
  - visitante escolhe English na folha de idioma → app em inglês e escolha guardada (como o caso de idioma com conta);
  - sessão expira com a tela aberta → lista do visitante (sem "Sair da conta", com "Acessibilidade"), sem erro;
  - visitante com fonte 2× num celular → sem estouro
- [ ] T021 [P] [US4] Em `app/test/modules/shell/presentation/app_top_bar_test.dart`, trocar o laço "`$label`: sem a engrenagem" por "`$label`: com a engrenagem, que abre /settings" (visitante e desconectada) e remover "a engrenagem aparece ao entrar na conta". Em `app/test/modules/profile/presentation/pages/profile_page_test.dart`, grupo "visitante": trocar "não vê a engrenagem" por "vê a engrenagem e ela abre /settings" (o `GoRouter` do teste precisa de `/settings` identificado)
- [ ] T022 [P] [US4] Em `tset/presentation/change_password_page_test.dart`, acrescentar: visitante abrindo `/settings/security` → "Entre na sua conta", "Para trocar a senha, entre na sua conta." e "Entrar ou criar conta" → `/login`

### Implementação

- [ ] T023 [US4] Em `set/presentation/controller/settings_controller.dart`, `Future<void> loadDeviceSettings() => Future.wait([_loadVersion(), _loadLanguage()]);` e `load()` passa a `Future.wait([_loadAccount(), loadDeviceSettings()])`; atualizar o comentário da classe. Faz a T019 passar
- [ ] T024 [US4] Em `set/presentation/pages/settings_page.dart`: o `ChangeNotifierProvider<SettingsController>` sobe para cima do `ValueListenableBuilder` da sessão, com um `create:` de corpo: `final SettingsController controller = GetIt.instance<SettingsController>(); unawaited(session.isAuthenticated ? controller.load() : controller.loadDeviceSettings()); return controller;`; o ramo sem conta passa a ser `_GuestSettingsList` (`ListView` com o mesmo padding, só `_ReadingSection` e `_AboutSection`); extrair da `_SettingsList` as seções "Leitura e aparência" (Acessibilidade, Idioma com `_chooseLanguage`) e "Sobre" (Privacidade, Sobre o SafeNews com a versão) para `_ReadingSection` e `_AboutSection`, usados pelas duas listas; `_chooseLanguage` sai da `_SettingsList` para ser usado pela `_ReadingSection`. Remover o import e o uso do `SettingsGuestInvite` desta página; atualizar o comentário da classe ("com conta, a lista inteira; sem conta, só o que não precisa de conta"). Faz a T020 passar
- [ ] T025 [US4] Engrenagem para todos: em `app/lib/modules/shell/presentation/widgets/app_top_bar.dart`, trocar o `ValueListenableBuilder` em volta do `_SettingsButton` por `Padding(left: s2, child: _SettingsButton(...))` direto e atualizar o comentário (`specs/014`, R6); em `app/lib/modules/profile/presentation/pages/profile_page.dart`, o `_Header` mostra a engrenagem sem o `if (isAuthenticated)` e o comentário passa a citar a feature 014; remover imports que ficarem sem uso. Faz a T021 passar
- [ ] T026 [US4] Texto do convite: `settings_guest_body` → "Para trocar a senha, entre na sua conta." em `app/assets/translations/pt-BR.json` e "Sign in to your account to change your password." em `en-US.json`; atualizar o comentário do `set/presentation/widgets/settings_guest_invite.dart` (agora só a `ChangePasswordPage` o usa). Faz a T022 passar

**Checkpoint**: `flutter test` verde. Commit da US4.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T027 Limpar `app/lib/dev/accessibility_playground.dart` ([R8](research.md#r8-atalhos-de-desenvolvimento)): remover o botão e o painel de acessibilidade (`_toggle`, `_panel`, o `AccessibilityController`, o estado `_open`) e o atalho "Notícias salvas" (`_savedNews`); manter os atalhos dos alertas; renomear a classe do overlay para refletir o que sobrou e reescrever o comentário do topo; remover imports sem uso. Conferir `flutter run -t lib/dev/accessibility_playground.dart` compilando (`flutter analyze` basta)
- [ ] T028 Revisão de código sem uso e de código só para teste (prática do projeto): procurar em `set/`, `app/lib/modules/shell/` e `app/lib/modules/profile/` widgets, parâmetros, chaves de i18n ou imports que ficaram sem uso (ex.: `settings_guest_title`/`action` continuam usados pela `ChangePasswordPage`; `ComingSoonView` continua usado por outras abas); remover o que sobrar e ajustar testes
- [ ] T029 `flutter analyze` sem novos avisos em relação à linha de base da T001 e `flutter test` inteiro verde; anotar os números aqui
- [ ] T030 Validação no aparelho: rodar os 17 passos do [quickstart](quickstart.md) (a usuária valida); anotar o que falhar como tarefa nova
- [ ] T031 Fechar a feature: marcar a B9 em `.specify/memory/tasks.md` e anotar ali que a engrenagem passou a aparecer para o visitante (revê a B8); marcar as tarefas deste arquivo; commit de docs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências.
- **Foundational (Phase 2)**: depende da T001; bloqueia todas as histórias.
- **US1 (Phase 3)**: depende da Phase 2. É o MVP.
- **US2 (Phase 4)** e **US3 (Phase 5)**: dependem da Phase 2 e do arquivo de teste criado na T012
  (helper `pumpAccessibility`); mexem no mesmo arquivo de página da US1, então seguem em sequência
  depois dela.
- **US4 (Phase 6)**: depende só da Phase 2 (a linha "Acessibilidade" já abre a página nova); é
  independente das US1–US3 e pode ser feita antes ou em paralelo, em arquivos diferentes.
- **Polish (Phase 7)**: depois de todas as histórias.

### Within Each User Story

- Teste escrito e visto falhar antes da implementação.
- Widgets antes da página; controller antes da página (US4).
- Um commit ao fim de cada história.

### Parallel Opportunities

- Phase 2: T002, T003 e T004 juntos; depois T006, T007, T008 e T009 juntos (arquivos
  diferentes). T010 depende da T008; T011 é independente delas.
- US1: T013 (prévia) em paralelo com a escrita da T012.
- US4: T019, T020, T021 e T022 juntos (quatro arquivos de teste); depois T023 → T024 e, em
  paralelo, T025 e T026.
- US4 inteira pode andar em paralelo com US1–US3 (só `settings_page.dart`, `settings_controller.dart`,
  `app_top_bar.dart`, `profile_page.dart` e traduções; a página de acessibilidade não é tocada).

## Parallel Example: User Story 4

```bash
# Testes, em arquivos diferentes:
Task: "T019 loadDeviceSettings() em tset/presentation/settings_controller_test.dart"
Task: "T020 lista do visitante em tset/presentation/settings_page_test.dart"
Task: "T021 engrenagem no app_top_bar_test.dart e no profile_page_test.dart"
Task: "T022 convite da senha em tset/presentation/change_password_page_test.dart"

# Depois da T023, em paralelo:
Task: "T025 engrenagem em app_top_bar.dart e profile_page.dart"
Task: "T026 texto do convite em pt-BR.json/en-US.json"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 e Phase 2.
2. Phase 3 (US1): tamanho da letra com prévia, gravação e próxima abertura.
3. **Parar e validar**: passos 1–3 e 7–11 do quickstart. Commit da Base + US1.

### Incremental Delivery

1. Base + US1 → letra maior escolhida pela pessoa (MVP).
2. US2 → alto contraste.
3. US3 → leitura automática e velocidade.
4. US4 → visitante com engrenagem e Configurações reduzidas.
5. Polish → limpeza, suíte, aparelho, B9 marcada.

Cada história é um commit; o PR para a `develop` sai depois da validação no aparelho (T030).
