---

description: "Task list for feature 022: redesign visual 2.0"
---

# Tasks: Redesign visual 2.0

**Input**: Design documents from `/specs/022-redesign-visual/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/ui-components.md](contracts/ui-components.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios** (constituição, Seção III, TDD).

- Cada teste novo é escrito e **rodado sozinho para ver falhar** antes da implementação.
- Nos testes atuais, só muda o que confere aparência ([R12](research.md#r12-testes)); o que confere
  comportamento não muda.
- Widget tests com `pumpLocalized` e `GetIt.instance.reset()` no `tearDown`.
- Para testar "reduzir animações", envolva o widget em
  `MediaQuery(data: MediaQueryData(disableAnimations: true))`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- **Prefixos de caminho**, relativos à raiz do repositório:

  | Prefixo | Pasta |
  |---|---|
  | `app/` | `click_seguro_app/` |
  | `core/` | `click_seguro_app/lib/core/` |
  | `mod/` | `click_seguro_app/lib/modules/` |
  | `tcore/` | `click_seguro_app/test/core/` |
  | `tmod/` | `click_seguro_app/test/modules/` |

- **Onde estão as decisões**: valores de cor, texto, canto, sombra e duração no
  [data-model](data-model.md) e no [research](research.md) (R1–R4, R8, R9); a API de cada
  componente no [contrato](contracts/ui-components.md).
- **Referência visual**: o quadro do Figma indicado em cada história. Fonte das medidas e dos SVGs:
  o gerador do Figma (`gen/parts.py` e `gen/build.py`, na pasta de rascunho da sessão de
  2026-11-08, que é temporária; as medidas também estão no Figma).
- **Proibido**: mudar textos (fora o T015 e o T061), rotas, controllers, casos de uso ou chamadas à
  API (FR-022).
- **Commits**: ao fim de cada história, com os arquivos pelo nome; `devtools_options.yaml` e
  `assets/images/` ficam de fora.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dependência, fonte e assets que todas as histórias usam.

- [X] T001 Adicionar `flutter_svg: 2.3.0` (versão fixada) em `app/pubspec.yaml` e rodar
  `flutter pub get`. Conferir na API da versão instalada se `SvgPicture.asset` aceita
  `colorMapper`. Anotar o resultado no [R5](research.md#r5-ilustrações-em-svg-com-flutter_svg).
- [X] T002 [P] Baixar os arquivos estáticos da Inter (Regular 400, Medium 500, SemiBold 600, Bold
  700, ExtraBold 800) e a licença `OFL.txt` para `app/assets/fonts/`. Declarar a família `Inter`
  em `fonts:` no `app/pubspec.yaml` ([R2](research.md#r2-fonte-inter-empacotada)).
- [X] T003 [P] Criar os 16 SVGs da tabela "Ilustração" do [data-model](data-model.md#ilustração)
  em `app/assets/illustrations/`, a partir do gerador do Figma:
  - sem `<text>`, sem `mask`/`clipPath` e sem fundo pastel, que vem do container;
  - cores só da paleta das ilustrações;
  - `onboarding_news.svg` (jornal, lupa e check) e `onboarding_practice.svg` (alternativas de quiz
    e troféu) são desenhos novos, no mesmo estilo de `onboarding_protect.svg`.

  Declarar `assets/illustrations/` em `app/pubspec.yaml`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: tokens, movimento, preferência de reduzir animações e ilustração. Toda história
depende desta fase.

**⚠️ CRITICAL**: nenhuma história começa antes desta fase acabar.

### Testes primeiro

- [X] T004 [P] Estender `tcore/theme/app_palette_test.dart`:
  - tema claro com os valores e campos novos do [data-model](data-model.md#apppalette);
  - contraste de 4,5:1 ou mais em todo par de texto e fundo dos componentes (`textForeground`,
    `textBody` e `textMutedForeground` sobre `background`/`surface`/`surfaceStrong`; branco sobre
    `primary`/`primaryPressed`; `success`/`warning`/`info`/`primary` sobre os seus "suaves");
  - 7:1 no `highContrast`;
  - os campos removidos (`primaryGlow`, `shadowPrimary`, `gradient`) não existem mais.

  Rodar e ver falhar.
- [X] T005 [P] Criar `tcore/illustrations/illustration_theme_test.dart` com uma tabela de casos
  para `IllustrationTheme.fromText` ([R7](research.md#r7-reconhecer-o-tema-do-módulo-e-da-notícia)):
  - um título por tema, em pt e em en;
  - com acento e maiúsculas ("LIGAÇÃO falsa" → `call`);
  - ordem da tabela (texto com "pix" e "whatsapp" → `whatsapp`);
  - `null`/vazio/sem palavra → `generic`;
  - `illustration` e `pastel(palette)` de cada tema, com branco no alto contraste.

  Rodar e ver falhar.
- [X] T006 [P] Estender `tmod/common/accessibility/accessibility_preferences_test.dart` e
  `tmod/settings/data/accessibility_preferences_model_test.dart`:
  - `reduceMotion` com padrão `false`;
  - `copyWith`;
  - salva e lê a chave nova;
  - JSON antigo sem a chave → `false`.

  Também `tmod/settings/data/accessibility_repository_impl_test.dart`: salva e lê com
  `reduceMotion`. Rodar e ver falhar.
- [X] T007 [P] Criar `tcore/theme/app_motion_test.dart`:
  - `context.reduceMotion` é `true` com `MediaQueryData(disableAnimations: true)` e `false` sem;
  - as durações valem 150/250/400/1200 ms.

  Criar também `app/test/main_motion_test.dart` (ou estender o `accessibility_app_test.dart`): com
  `reduceMotion: true` no notifier, o `MediaQuery` abaixo do `MaterialApp` tem
  `disableAnimations == true`. Rodar e ver falhar.
- [X] T008 [P] Criar `tcore/widgets/safe_illustration_test.dart`:
  - desenha um `SvgPicture` do asset da `AppIllustration`;
  - fica fora da semântica;
  - no `AppTheme.highContrastTheme`, usa o mapeador de cores.

  Rodar e ver falhar.

### Implementação

- [X] T009 Reescrever os tokens de cor:
  - `core/theme/app_colors.dart` com os valores novos;
  - `core/theme/app_palette.dart` com os campos novos e os removidos, conforme o
    [data-model](data-model.md#apppalette), nos temas `light` e `highContrast`, mais `copyWith` e
    `lerp`.

  Corrigir os usos de `primaryGlow`, `gradient`, `shadowPrimary` e `shadowSm`/`shadowMd` em `lib/`:
  `shadow` no lugar das sombras e `primary` no lugar do gradiente. T004 passa.
- [X] T010 [P] Criar os tokens restantes:
  - `core/theme/app_typography.dart` (estilos do [R3](research.md#r3-escala-de-texto) em Inter,
    cor pelo `AppPalette`);
  - a sombra única fica em `AppPalette.shadow` (vazia no alto contraste); no implement, o
    `app_shadows.dart` previsto foi dispensado para não duplicar a sombra;
  - em `core/theme/app_spacing.dart`, os cantos `radiusSm` 12, `radiusMd` 16, `radiusLg` 20,
    `radiusXl` 24, `radius2xl` 32, `radiusFull` e o espaço `s8` 48. Ajustar os usos dos nomes
    antigos `radius2xl` (20 → `radiusLg`) e `radius3xl` (24 → `radiusXl`) em `lib/`.
- [X] T011 [P] Criar `core/theme/app_motion.dart` ([R8](research.md#r8-reduzir-animações-um-sinal-só)):
  durações `fast`/`standard`/`emphasis`/`celebration`, curvas `enter`/`exit`/`spring` e a extensão
  `context.reduceMotion`. T007 (parte do motion) passa.
- [X] T012 Atualizar `core/theme/app_theme.dart`:
  - `fontFamily: 'Inter'` e `textTheme` a partir do `AppTypography`;
  - `inputDecorationTheme` (canto 16, borda `inputBorder`, foco tinta 2,5, erro);
  - `bottomSheetTheme` (canto 32 em cima, branco);
  - `snackBarTheme` (tinta, canto 16, texto 17/600, flutuante);
  - `pageTransitionsTheme` com um construtor próprio: aparece mais desliza 24 em 250 ms, curva
    `enter`, e troca direta com `context.reduceMotion`.

  Depende de T009 a T011.
- [X] T013 Adicionar `reduceMotion` (padrão `false`) de ponta a ponta:
  - `mod/common/accessibility/accessibility_preferences.dart`;
  - o modelo `mod/settings/data/models/accessibility_preferences_model.dart` (chave nova; ausente →
    `false`);
  - `mod/settings/data/datasources/accessibility_local_data_source_impl.dart`, se a chave for
    gravada lá.

  T006 passa.
- [X] T014 Em `app/lib/main.dart`, no `builder` que aplica a escala de fonte, somar
  `disableAnimations: media.disableAnimations || preferences.reduceMotion`. T007 passa.
- [X] T015 Criar o interruptor "Reduzir animações" ([FR-024](spec.md)):
  - chaves `accessibilityReduceMotion` e `accessibilityReduceMotionHint` em
    `core/i18n/app_strings.dart` e nos dois JSON de `app/assets/translations/`. pt-BR: "Reduzir
    animações" e "Mostra as telas sem movimento." en-US: "Reduce animations" e "Shows screens
    without motion.";
  - em `mod/settings/presentation/controller/accessibility_controller.dart`, um
    `setReduceMotion(bool)` igual aos outros interruptores;
  - em `mod/settings/presentation/pages/accessibility_page.dart`, um `SettingsSwitchTile` na seção
    "Aparência", logo depois do alto contraste (no implement: fica junto das opções visuais, não na
    de voz).

  O teste vem antes: em `tmod/settings/presentation/accessibility_controller_test.dart`, salva e
  publica; em `accessibility_page_test.dart`, o interruptor aparece, liga e tem rótulo de
  semântica. Rodar e ver falhar antes.
- [X] T016 Criar `core/illustrations/app_illustration.dart` (enum → caminho do asset) e
  `core/illustrations/illustration_theme.dart` (`fromText`, `illustration`, `pastel`). T005 passa.
- [X] T017 Criar `core/widgets/safe_illustration.dart` com `SvgPicture.asset` em
  `ExcludeSemantics` e o `ColorMapper` do alto contraste
  ([R5](research.md#r5-ilustrações-em-svg-com-flutter_svg)). T008 passa.
- [X] T018 Rodar `flutter analyze` e `flutter test` com tudo verde. Os testes que quebrarem só por
  cor ou nome de token são ajustados aqui. Os de comportamento não mudam.

**Checkpoint**: os tokens, o movimento, a preferência e a ilustração estão prontos. O app já mostra
as cores e a fonte novas.

---

## Phase 3: User Story 1 - Uma linguagem visual única em todo o app (Priority: P1) 🎯 MVP

**Goal**: componentes compartilhados e barra inferior novos; todas as telas herdam o visual, o
Perfil inclusive.

**Independent Test**: guia de estilo (`app/lib/style_guide/style_guide.dart`), Perfil e
Configurações conferidos com a prancha "Componentes" do Figma, no tema normal e no alto
contraste (spec, US1).

### Testes da US1

- [X] T019 [P] [US1] Estender `tcore/widgets/safe_button_test.dart`:
  - tons `primary`/`secondary`/`outline`/`link`;
  - `large` com altura mínima 60 e `compact` com 48;
  - ao pressionar, escala 0,98 (nenhuma com `disableAnimations`);
  - texto longo com escala 2,0 cresce sem estourar;
  - carregando mantém o rótulo de semântica.

  Remover os casos de `gradient`/`ghost`/`pill`. Rodar e ver falhar.
- [X] T020 [P] [US1] Estender `tcore/widgets/safe_badge_test.dart` para os tons `success`,
  `warning`, `neutral`, `alert` e `onImage`, com ícone opcional, e criar
  `tcore/widgets/safe_card_test.dart` (canto 20, sombra, variante `flat` sem sombra, toque com
  escala). Rodar e ver falhar.
- [X] T021 [P] [US1] Criar testes de widget para os componentes novos do
  [contrato](contracts/ui-components.md):
  - `tcore/widgets/safe_icon_button_test.dart`: rótulo obrigatório, alvo de 48 ou mais;
  - `safe_chip_test.dart`: semântica de selecionado, `onSelected`;
  - `safe_pill_tabs_test.dart`: aba selecionada na semântica, `onChanged`;
  - `safe_progress_test.dart`: barra, anel e segmentos; enchem em 400 ms ou aparecem direto com
    `disableAnimations`;
  - `safe_skeleton_test.dart`: fora da semântica, parado com `disableAnimations`;
  - `safe_sheet_test.dart`: alça e canto 32.

  Rodar e ver falhar.
- [X] T022 [P] [US1] Estender o teste do `SafeTextField` (criar `tcore/widgets/safe_text_field_test.dart`
  se não existir): rótulo acima, altura 60, borda tinta no foco e mensagem de erro com ícone. Rodar
  e ver falhar.
- [X] T023 [P] [US1] Em `tmod/shell/presentation/app_shell_test.dart`:
  - remover o caso do botão central;
  - novo caso: cinco itens de mesma largura, todos com rótulo, a aba atual com semântica de
    selecionada, "Notícias" abre os Reels como antes.

  Rodar e ver falhar.

### Implementação da US1

- [X] T024 [US1] Reescrever `core/widgets/safe_button.dart` conforme o
  [contrato](contracts/ui-components.md#mantidos-com-visual-novo-api-compatível) e migrar os usos
  de `SafeButtonTone.gradient`/`ghost`, `SafeButtonSize.pill` e `shadow:` em `lib/` (53 usos;
  `gradient` → `primary`, `ghost` → `link`, `pill` → `SafeChip` ou `compact`). T019 passa.
- [X] T025 [P] [US1] Reescrever `core/widgets/safe_card.dart` e `core/widgets/safe_badge.dart`
  (migrar os 7 usos de `SafeBadge` para os tons novos). T020 passa.
- [X] T026 [P] [US1] Reescrever `core/widgets/safe_text_field.dart` (rótulo acima, 60, canto 16,
  foco e erro). T022 passa.
- [X] T027 [P] [US1] Criar `core/widgets/safe_icon_button.dart`, `safe_chip.dart`,
  `safe_pill_tabs.dart`, `safe_progress.dart` (`SafeProgressBar`, `SafeProgressRing` e
  `SafeSegmentedProgress`, com arco em `CustomPainter`), `safe_skeleton.dart` (gradiente que corre
  em 1,4 s com um `AnimationController`, parado com `context.reduceMotion`) e `safe_sheet.dart`.
  T021 passa.
- [X] T028 [P] [US1] Atualizar `core/widgets/listen_button.dart`: pílula com borda e ícone coral;
  enquanto lê, um halo pulsa em ciclos de 2 s, e nada pulsa com `reduceMotion`. Ajustar
  `tcore/widgets/listen_button_test.dart` (o teste antes).
- [X] T029 [US1] Reescrever `mod/shell/presentation/widgets/app_bottom_nav.dart`:
  - sem `_CenterItem` nem `AppTab.isCenter`;
  - 5 itens iguais, cada um com pílula de 60×34, ícone 26 e rótulo 15 (mínimo do FR-003) que quebra em até 2 linhas;
  - aba atual: ícone `primary` sobre `primarySoft` e rótulo em negrito;
  - fundo branco com linha `border` em cima.

  T023 passa.
- [X] T030 [US1] Trocar as abas pelo `SafePillTabs`, mantendo rótulos, ordem e comportamento (no
  implement, o `AuthModeSwitch` ganhou o mesmo visual sem trocar o widget, para manter as chaves
  `auth-mode-*` e a pílula que desliza):
  - o `TabBar` de `mod/help/presentation/pages/help_page.dart` (Oficiais/Meus contatos, ainda
    controlado pelo `TabController`);
  - o `_Segment` próprio de `mod/authentication/presentation/widgets/auth_mode_switch.dart`
    (Entrar/Criar conta);
  - o `_AssistantTabs` de `mod/assistant/presentation/pages/assistant_page.dart`.

  O `SegmentedButton` de `app/lib/dev/platform_services_playground.dart` é de desenvolvimento e
  fica como está.
- [X] T031 [US1] Passar Perfil e telas sem desenho próprio para os componentes e o `AppTypography`,
  sem mudar layout nem textos ([FR-013](spec.md)):
  - `mod/profile/presentation/` (pages e widgets);
  - `mod/settings/presentation/` (pages e widgets);
  - `mod/authentication/presentation/pages/forgot_password_page.dart`;
  - `mod/notifications/presentation/pages/notifications_page.dart`;
  - `mod/news/presentation/pages/user_news_list_page.dart`;
  - `mod/help/presentation/pages/contact_form_page.dart`.

  Trocar os `fontSize:` soltos por estilos do `AppTypography`. Ajustar os testes dessas telas só
  onde conferem aparência.
- [X] T032 [US1] Atualizar `app/lib/style_guide/style_guide.dart` para mostrar os componentes
  novos (botões, chips, abas, selos, campos, progresso, avisos, ilustrações), na mesma ordem da
  prancha "Componentes".
- [X] T033 [US1] `flutter analyze` e `flutter test` com tudo verde. **Commit**:
  `feat(022): base e US1 — tokens, componentes e barra inferior`.

**Checkpoint**: o app inteiro com a linguagem nova. As histórias seguintes só ajustam o layout
das telas desenhadas.

---

## Phase 4: User Story 2 - Primeira impressão: splash, onboarding e login (Priority: P1)

**Goal**: quadros "01 Splash", "02 Onboarding" e "03 Entrar" do Figma.

**Independent Test**: apagar os dados do app e percorrer splash → 3 slides → login (quickstart,
passo 1).

- [ ] T034 [P] [US2] Testes antes:
  - em `tmod/onboarding/presentation/pages/onboarding_page_test.dart`, cada slide mostra uma
    `SafeIllustration` (`onboardingProtect`/`News`/`Practice`), o botão "Ouvir" e "Pular", o
    indicador com a página atual e o botão "Continuar"/"Começar";
  - em `tmod/splash/presentation/pages/splash_page_test.dart`, o `AppLogo` dentro do círculo e o
    nome "Click Seguro";
  - em `tmod/authentication/presentation/widgets/auth_header_test.dart`, o `AppLogo` e o nome.

  Rodar e ver falhar onde o visual muda.
- [ ] T035 [US2] Splash em `mod/splash/presentation/pages/splash_page.dart`: fundo `surface`,
  `AppLogo` 92 num círculo branco de 168 com a sombra única, nome em `display` 36 e slogan em
  `bodyLarge`. O círculo pulsa (desligado com `reduceMotion`). A lógica de tempo da splash não muda.
- [ ] T036 [US2] Onboarding:
  - `mod/onboarding/presentation/widgets/onboarding_slide.dart`: ilustração de 300 com flutuação
    suave, desligada com `reduceMotion`; título `display`; texto `bodyLarge`;
  - `onboarding_page_indicator.dart`: atual 32×10 coral, os outros 10×10 em `#D6D2CA`;
  - `mod/onboarding/presentation/pages/onboarding_page.dart`: "Ouvir" e "Pular" (`SafeChip` ou
    `compact`) no topo, botão primário com seta;
  - `mod/onboarding/presentation/models/onboarding_page_content.dart`: o slide aponta para a
    `AppIllustration`, e os textos não mudam.
- [ ] T037 [US2] Login: `mod/authentication/presentation/widgets/auth_header.dart` com o
  `AppLogo` 40 num quadrado `primarySoft` de 64 (canto 20), "Bem-vindo ao" em `caption` e "Click
  Seguro" em `title1`. Em `login_page.dart` e `or_divider.dart`, os componentes novos. Textos,
  campos e fluxo não mudam ([FR-011](spec.md)).
- [ ] T038 [US2] `flutter test` das pastas tocadas, com tudo verde. **Commit**:
  `feat(022): US2 — splash, onboarding e login`.

---

## Phase 5: User Story 3 - Atividades com ilustrações, feedback e celebração (Priority: P1)

**Goal**: quadros "06" a "09" do Figma.

**Independent Test**: com o serviço falso, painel → módulo → uma certa e uma errada → conclusão
(quickstart, passo 5).

### Testes da US3

- [ ] T039 [P] [US3] Em `tmod/activities/presentation/pages/activities_dashboard_page_test.dart`:
  - o painel mostra o `SafeProgressRing` com a porcentagem;
  - cada cartão tem a `SafeIllustration` do `IllustrationTheme.fromText(title)`;
  - o selo `SafeBadge.onImage` tem o texto do status;
  - há uma `SafeProgressBar`;
  - módulo sem lições sai com a ilustração apagada e sem abrir (CB-012).

  Rodar e ver falhar.
- [ ] T040 [P] [US3] Em `tmod/activities/presentation/widgets/lesson_option_card_test.dart`: as
  quatro aparências (padrão, selecionada com borda tinta, certa com check, errada com X), cada uma
  com semântica distinta além da cor. A errada balança, e não balança com `disableAnimations`.
  Rodar e ver falhar.
- [ ] T041 [P] [US3] Em `tmod/activities/presentation/widgets/feedback_sheet_test.dart`:
  - certa → `SafeIllustration(answerCorrect)`, título em `success`;
  - errada → `answerWrong` e a resposta correta;
  - dentro do `SafeSheet`.

  Rodar e ver falhar.
- [ ] T042 [P] [US3] Em `tmod/activities/presentation/pages/completion_page_test.dart`:
  - `stateTrophy`, título, nome do módulo, placar grande e mensagem;
  - os mesmos 3 botões da feature 020;
  - sem a linha de tempo/medalha;
  - com `disableAnimations`: placar já no valor final e sem confete;
  - o leitor de tela lê o placar final desde o início.

  Rodar e ver falhar.

### Implementação da US3

- [ ] T043 [P] [US3] `mod/activities/presentation/widgets/overall_progress_card.dart`: cartão
  `flat` com `SafeProgressRing`, título "Seu progresso" e o texto atual. O selo "1 módulo
  completo" do Figma **não** entra, porque seria texto novo (FR-022).
- [ ] T044 [US3] `mod/activities/presentation/widgets/module_card.dart`: `SafeCard` com capa de
  150 (canto 16, fundo `theme.pastel`, `SafeIllustration(theme.illustration)`), selo sobre a capa,
  título `title3` em negrito, "X de Y lições", `SafeIconButton` de seta e `SafeProgressBar`
  (`success` quando concluído). Módulo indisponível (CB-012): capa com opacidade 0,5 e sem toque.
  `module_icon.dart` deixa de ser usado no cartão: remover o arquivo se ficar sem uso.
- [ ] T045 [US3] `mod/activities/presentation/pages/activities_dashboard_page.dart`: título
  `display` e a lista com espaçamento de 20. Aviso do visitante e estados como hoje. O botão
  "Ouvir" do Figma **não** entra, porque o painel não tem leitura em voz alta hoje (FR-022).
- [ ] T046 [P] [US3] Na pergunta:
  - `lesson_progress_indicator.dart` vira `SafeSegmentedProgress`;
  - `lesson_option_card.dart` com as quatro aparências e o balanço (`AnimationController` de
    500 ms, ±6, duas vezes);
  - `confirm_answer_footer.dart` com linha em cima e o botão primário;
  - `mod/activities/presentation/pages/lesson_page.dart`: "Pergunta X de Y" em `caption` coral
    maiúsculo e o enunciado em `title1` 25.

  T040 passa.
- [ ] T047 [US3] `mod/activities/presentation/widgets/feedback_sheet.dart` dentro do `SafeSheet`.
  - Certa: `answerCorrect` 84, com escala de mola ao entrar.
  - Errada: `answerWrong`.
  - Título em `title1`, "Por quê?" num bloco `surface`, `ListenButton` e botão primário.
  - O `showModalBottomSheet` chamador usa o `AnimationStyle` de 400 ms.

  T041 passa.
- [ ] T048 [US3] `mod/activities/presentation/pages/completion_page.dart`:
  - `stateTrophy` 300×190, com escala de mola;
  - um confete desenhado (`CustomPainter`, cerca de 30 retângulos, 1200 ms, uma vez, fora da
    semântica, ausente com `reduceMotion`);
  - placar em `score` 72, contando de 0 com `TweenAnimationBuilder<int>`, com `Semantics(label:)`
    no valor final;
  - mensagem em `bodyLarge`;
  - "Voltar às atividades" primário e "Compartilhar"/"Refazer o módulo" secundários lado a lado.

  T042 passa.
- [ ] T049 [US3] `guest_progress_alert.dart` e `guest_progress_notice.dart` com os componentes
  novos, sem mudar texto. Depois, `flutter test tmod/activities` com tudo verde. **Commit**:
  `feat(022): US3 — atividades`.

---

## Phase 6: User Story 4 - Notícias com capas e leitura confortável (Priority: P2)

**Goal**: quadros "04" e "05" do Figma, com o Início no layout do [FR-025](spec.md).

**Independent Test**: Início com notícias com e sem imagem, busca e filtro, detalhe (quickstart,
passos 3 e 4).

### Testes da US4

- [ ] T050 [P] [US4] Criar `tmod/news/presentation/widgets/news_cover_test.dart`:
  - com `imageUrl`, usa a imagem;
  - sem imagem ou com erro de carga, usa a `SafeIllustration` do
    `IllustrationTheme.fromText(primeira categoria)` ou, se der `generic`, do título;
  - fundo pastel do tema.

  Rodar e ver falhar.
- [ ] T051 [P] [US4] Em `tmod/news/presentation/pages/news_home_page_test.dart`:
  - "Destaques" em largura total;
  - "Recomendadas" e "Tudo recente" em 2 colunas, mantendo a ordem da API (esquerda para direita,
    de cima para baixo);
  - com escala total de texto acima de 1,3, 1 coluna;
  - a mesma lista gera sempre as mesmas alturas de capa (regra determinística do T053);
  - paginação e rodapé como antes.

  Rodar e ver falhar.

### Implementação da US4

- [ ] T052 [P] [US4] Criar `mod/news/presentation/widgets/news_cover.dart`: capa com canto 20,
  `Image.network` com `errorBuilder` para a ilustração, `SafeBadge.onImage` da categoria no canto
  de cima à esquerda e `SafeIconButton.onImage` de salvar à direita, quando a tela já tem a ação de
  salvar. T050 passa.
- [ ] T053 [US4] `mod/news/presentation/widgets/news_card.dart`:
  - versão grande: capa de 190, título `title3` em negrito e metadados `caption`;
  - versão compacta para a grade: capa com altura variável, título 17/600 e data.

  A variação de altura sai de uma regra determinística pelo índice ou id, sem aleatório, para os
  testes ficarem estáveis.
- [ ] T054 [US4] `mod/news/presentation/pages/news_home_page.dart`:
  - "Recomendadas" e "Tudo recente" num sliver de 2 colunas que distribui os itens em ordem;
  - 1 coluna quando a escala de texto passar de 1,3;
  - busca em pílula (`feed_search_field.dart`) e chips (`category_filter_bar.dart` com
    `SafeChip`);
  - a saudação e o sino de alertas continuam no `AppTopBar` do shell
    (`mod/shell/presentation/widgets/app_top_bar.dart`), que só ganha os componentes novos. Sem
    avatar e sem mudar a saudação de lugar (FR-022);
  - `feed_section_title.dart` em `title2`.

  T051 passa.
- [ ] T055 [US4] Detalhe da notícia:
  - `mod/news/presentation/widgets/news_detail_header.dart`: capa de 270 até a borda e
    `SafeIconButton.onImage` de voltar, compartilhar e salvar flutuando;
  - conteúdo numa folha branca com canto 28 em cima, sobreposta à capa;
  - `read_aloud_bar.dart`: bloco `surface` com o botão de tocar coral de 56, que pulsa enquanto lê;
  - `news_detail_actions.dart` com os componentes novos;
  - `mod/news/presentation/pages/news_detail_page.dart`: texto em `bodyLarge`.
- [ ] T056 [US4] `mod/news/presentation/widgets/related_activity_card.dart` ("Pratique o que
  aprendeu") com a mesma capa ilustrada do cartão de módulo, pelo `IllustrationTheme` do título do
  módulo sugerido. Ajustar `related_activity_card_test.dart`.
- [ ] T057 [US4] Reels (`reel_view.dart`, `reel_actions.dart`, `reels_carousel.dart`): mesma tela
  escura, com botões e selos novos. Em seguida, `flutter test tmod/news` com tudo verde.
  **Commit**: `feat(022): US4 — notícias`.

---

## Phase 7: User Story 5 - Assistente e Central de ajuda (Priority: P2)

**Goal**: quadros "10" e "11" do Figma, mais o cartão de emergência ([FR-016](spec.md)).

**Independent Test**: trocar as abas do Assistente; na Ajuda, "Ligar para 190" chama a ação de
ligar com 190 (quickstart, passos 6 e 7).

- [ ] T058 [P] [US5] Testes antes, em `tmod/help/presentation/controller/help_controller_test.dart`:
  - `callNumber('190')` usa o launcher (pode ligar → liga; não pode → `false`);
  - `call(contact)` continua igual, delegando ao `callNumber`.

  Rodar e ver falhar.
- [ ] T059 [P] [US5] Criar `tmod/help/presentation/widgets/emergency_call_card_test.dart`:
  - título, texto e botão nos dois idiomas;
  - o toque chama `callNumber('190')`;
  - se a chamada falhar, mostra o mesmo aviso dos contatos;
  - o leitor de tela lê título, texto e botão.

  Rodar e ver falhar.
- [ ] T060 [US5] Em `mod/help/presentation/controller/help_controller.dart`, criar
  `Future<bool> callNumber(String phone)` e fazer `call(ContactEntity)` delegar. Criar a constante
  `EmergencyNumbers.police = '190'` em `mod/help/domain/entities/emergency_numbers.dart` (ou
  `presentation/`, se for só de tela). T058 passa.
- [ ] T061 [US5] Textos: `helpEmergencyTitle`, `helpEmergencyBody` e `helpEmergencyCall` em
  `core/i18n/app_strings.dart` e nos JSON.
  - pt-BR: "Caiu em um golpe?", "Ligue agora para a polícia e para o seu banco." e "Ligar para
    190".
  - en-US: "Fell for a scam?", "Call the police and your bank right now." e "Call 190".

  Atualizar os testes de chaves de i18n que conferem a lista.
- [ ] T062 [US5] Criar `mod/help/presentation/widgets/emergency_call_card.dart` (cartão coral,
  canto 24, ícone de alerta, título `title2` branco, texto 17 e botão branco com texto coral e
  ícone de telefone) e colocá-lo no topo de `mod/help/presentation/pages/help_page.dart`, acima
  das abas. A falha da chamada usa o mesmo aviso de `_call`. Os contatos viram linhas com ícone em
  quadrado pastel e o botão de ligar em `successSoft`. T059 passa.
- [ ] T063 [US5] Assistente:
  - `mod/assistant/presentation/pages/assistant_page.dart`: as 3 abas já em `SafePillTabs` (T030), balões
    (assistente em `surface` com avatar `primarySoft` de brilho, pessoa em tinta com texto branco)
    e barra de entrada com câmera, campo em pílula e botão coral;
  - `assistant_analysis_card.dart`: cartão com borda coral quando o risco é alto e
    `SafeBadge.alert` de risco;
  - `assistant_history_tab.dart`: os componentes novos.

  Comportamento igual. Ajustar os testes do assistente só onde conferem aparência.
- [ ] T064 [US5] `flutter test tmod/help tmod/assistant` com tudo verde. **Commit**:
  `feat(022): US5 — assistente e central de ajuda`.

---

## Phase 8: User Story 6 - Estados de carregamento, erro, vazio e sem internet (Priority: P2)

**Goal**: quadros "13" a "16" do Figma em todas as telas que usam os estados compartilhados.

**Independent Test**: forçar carregamento lento, erro, vazio e sem conexão nas Atividades e nas
notícias salvas (quickstart, passo 8).

- [ ] T065 [P] [US6] Testes antes, em `tcore/widgets/safe_states_test.dart` (da 021):
  - `SafeLoadingState` mostra `SafeSkeleton` (sem `CircularProgressIndicator`) no layout pedido,
    com o mesmo anúncio de carregamento;
  - `SafeErrorState` usa `stateError`, ou `stateOffline` quando é falha de conexão;
  - `SafeEmptyState` usa `stateEmpty`;
  - `SafeOfflineBanner` mostra a faixa tinta;
  - `SlowRequestNotice` mostra a caixa `infoSoft`.

  Remover os casos do `SafeStateIllustration`. Rodar e ver falhar.
- [ ] T066 [US6] Reescrever `core/widgets/safe_loading_state.dart` (layouts `list`/`cards`/`detail`
  com `SafeSkeleton`), `safe_error_state.dart` e `safe_empty_state.dart` (`SafeIllustration` de
  200, título `title1`, texto `bodyLarge` centralizado, ações como hoje, rolagem em telas curtas),
  `safe_offline_banner.dart` e `slow_request_notice.dart`. Apagar
  `core/widgets/safe_state_illustration.dart` e o teste dele.
- [ ] T067 [US6] Nas 14 telas que usam `SafeLoadingState`, escolher o `layout` que combina com o
  conteúdo:
  - `cards`: painel de atividades e Início;
  - `list`: listas de notícias, alertas e histórico do assistente;
  - `detail`: detalhe da notícia e pergunta.

  Trocar os 9 `CircularProgressIndicator` soltos de carregamento de tela por `SafeLoadingState`.
  Os de botão carregando ficam. Atualizar os 12 testes que procuram `CircularProgressIndicator` ou
  `SafeLoadingState` para procurar o rótulo de carregamento.
- [ ] T068 [US6] `flutter test` completo, com tudo verde. **Commit**:
  `feat(022): US6 — estados de carregamento, erro, vazio e sem internet`.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T069 [P] Rodar o app no aparelho com fonte no maior nível, alto contraste e inglês. Corrigir
  textos cortados ou sobrepostos (SC-003, edge cases da spec).
- [ ] T070 [P] Reescrever `.specify/memory/design-system.md` como 2.0.0 ([R13](research.md#r13-documentação)):
  - princípios, tokens claro e alto contraste, tipografia, cantos, sombra e movimento;
  - componentes (do [contrato](contracts/ui-components.md)), ilustrações e regra de tema;
  - barra inferior, divergências e changelog.

  Trocar "SafeNews" por "Click Seguro".
- [ ] T071 [P] `.specify/memory/specification.md` 2.5.0:
  - barra inferior com 5 abas iguais (navegação);
  - cartão de emergência junto do RF-031;
  - "Reduzir animações" junto do RF-038 a RF-041;
  - changelog.
- [ ] T072 Rodar o `/revisar-pr` na própria branch (diff `origin/develop...022-redesign-visual`,
  por subagente independente). Corrigir os achados Alto e Médio, sobretudo código morto: tokens
  sem uso, `module_icon.dart`, campos removidos.
- [ ] T073 Atualizar a branch com o `develop` (`git fetch` e merge) e resolver conflitos com o
  trabalho em paralelo. Rodar `flutter analyze` (infos no máximo iguais às do `develop`),
  `flutter test` e `flutter build web`.
- [ ] T074 Validação da usuária no aparelho, seguindo o [quickstart](quickstart.md) inteiro (passos
  1 a 11). Mudanças de comportamento achadas viram clarificação na spec.
- [ ] T075 Adicionar a tarefa R1 "Redesign visual 2.0" em `.specify/memory/tasks.md`, já marcada e
  com o link para `specs/022-redesign-visual`,
  marcar as tarefas deste arquivo e fazer o **commit** de docs:
  `docs(022): redesign validado no aparelho`. Push e PR para `develop` ("O que entra", "Como
  validar", "Fora do escopo").

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências. T002 e T003 em paralelo, depois de T001 ou junto.
- **Foundational (Phase 2)**: depende do Setup. Bloqueia todas as histórias.
- **US1 (Phase 3)**: depende da Foundational. As outras histórias usam os componentes dela.
- **US2 a US6 (Phases 4–8)**: dependem da US1 e não dependem entre si; a ordem acima é a sugerida.
- **Polish (Phase 9)**: depois das histórias. T074 antes de T075.

### Within Each User Story

- Testes antes, rodados para ver falhar. Depois, a implementação. No fim, a suíte verde e o
  commit.
- Tokens antes de componentes, e componentes antes de telas.

### Parallel Opportunities

- **Phase 2**: T004 a T008 juntos (arquivos de teste diferentes); T010 e T011 juntos; T016 e T017
  depois de T005 e T008.
- **US1**: T019 a T023 juntos; T025 a T028 juntos depois de T024.
- **US3**: T039 a T042 juntos; T043 e T046 em paralelo.
- **US4**: T050 e T051 juntos. **US5**: T058 e T059 juntos.
- **Polish**: T069 a T071 juntos.

## Parallel Example: Foundational

```bash
Task: "T004 contraste da paleta em tcore/theme/app_palette_test.dart"
Task: "T005 tabela de temas em tcore/illustrations/illustration_theme_test.dart"
Task: "T006 reduceMotion no modelo e no repositório"
Task: "T007 context.reduceMotion e MediaQuery do main"
Task: "T008 SafeIllustration"
```

## Parallel Example: User Story 1

```bash
Task: "T019 safe_button_test.dart"
Task: "T020 safe_badge_test.dart e safe_card_test.dart"
Task: "T021 testes dos componentes novos"
Task: "T022 safe_text_field_test.dart"
Task: "T023 barra inferior em app_shell_test.dart"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 e Phase 2.
2. Phase 3 (US1): o app inteiro com a linguagem nova.
3. **Parar e validar**: passos 2, 9 e 10 do quickstart. Commit da Base + US1.

### Incremental Delivery

1. Base + US1 → linguagem única (MVP).
2. US2 → primeira impressão.
3. US3 → atividades.
4. US4 → notícias.
5. US5 → assistente e ajuda.
6. US6 → estados.
7. Polish → design system, especificação, `/revisar-pr`, merge do `develop`, aparelho, PR.

Cada história é um commit. O PR para o `develop` só sai depois da validação no aparelho (T074).
