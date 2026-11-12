# Tasks: Splash animada e logo na paleta do app

**Input**: Design documents from `specs/023-splash-animada/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/splash-ui.md](contracts/splash-ui.md)

**Tests**: obrigatórios pela Constituição §III (TDD) para lógica nova; widget tests para UI com
lógica condicional.

Caminhos relativos a `click_seguro_app/` salvo indicação. Ao fim de cada fase: `flutter analyze`
limpo e `flutter test` verde.

## Phase 1: Setup

- [X] T001 Confirmar a base: `flutter analyze` e `flutter test` verdes na branch recém-criada,
  antes de qualquer mudança.

---

## Phase 2: Foundational (bloqueia US1 e US2)

**Purpose**: a marca desenhada em código, usada pela splash e pelo `AppLogo`.

- [X] T002 [P] Testes em `test/core/widgets/brand_mark_test.dart`:
  - `BrandMarkPainter` com `strokeProgress: 1` e `elderProgress: 1` pinta sem exceção num
    `CustomPaint` 120×133 (proporção do `viewBox` `88 440 444 492`);
  - `shouldRepaint` é `true` só quando cor ou progressos mudam;
  - os paths de `BrandMarkPaths` têm os mesmos limites (bounds) do SVG oficial: escudo de
    (111,464) a (509,906) antes do traço;
  - `strokeProgress: 0` não desenha o escudo (só a silhueta, se `elderProgress > 0`).
- [X] T003 Criar `lib/core/widgets/brand_mark.dart` (research R3):
  - `BrandMarkPaths`: escudo, as duas metades do escudo a partir do topo (310,464) até a ponta
    (310,906), silhueta e os 5 traços de detalhe, transcritos exatamente de
    `assets/branding/click_seguro_logo.svg`;
  - `BrandMarkPainter({required Color color, double strokeProgress = 1, double elderProgress = 1})`:
    escala o `viewBox` ao tamanho; silhueta recortada pelo escudo, deslocada para baixo por
    `(1 - elderProgress) * 120` e com opacidade `elderProgress`; detalhes recortados com
    `saveLayer` + `BlendMode.clear`; escudo com traço 32, `StrokeJoin.round`, `StrokeCap.round`,
    as duas metades extraídas por `PathMetric.extractPath(0, length * strokeProgress)`;
  - `BrandMark({required double size, Color? color, ...})`: `CustomPaint` decorativo
    (`ExcludeSemantics`), cor padrão `context.colors.primary`.

**Checkpoint**: marca disponível; nada visível mudou ainda.

---

## Phase 3: User Story 1 — Abertura animada da marca (P1) 🎯 MVP

**Goal**: splash V4-2 em 1,8 s; navega quando animação e validação terminam; respira se demorar.
**Independent Test**: testes abaixo + quickstart "No aparelho" 1.

### Tests (US1)

- [X] T004 [P] [US1] Ajustar `test/modules/splash/presentation/controller/splash_controller_test.dart`
  e `test/helpers/splash_provider.dart`: remover o parâmetro `minimumDisplayDuration` e o teste de
  duração mínima; acrescentar teste "decide assim que onboarding e sessão respondem" (sem espera
  fixa, com `fakeAsync` sem avançar o relógio).
- [X] T005 [P] [US1] Reescrever `test/modules/splash/presentation/pages/splash_page_test.dart`
  (manter os testes de destino, nome/frase e tela 320×480 com fonte 200%):
  - destino pronto na hora → em 1 799 ms ainda na splash; depois de 1 800 ms + saída, na tela
    do destino;
  - validação demorando além de 1 800 ms → continua na splash, a marca respira (escala da
    `SplashPage.logoKey` muda entre dois `pump`s) e navega quando a validação completa;
  - navega uma única vez (`resolveDestination` concluído antes e depois da animação);
  - leitor de tela: um único nó com "Click Seguro" e "Sua segurança em primeiro lugar"; a cena
    não expõe semântica;
  - nenhum widget da cena usa cor fora de `AppPalette` (pintor recebe as cores do tema).
- [X] T006 [P] [US1] Testes do pintor em
  `test/modules/splash/presentation/widgets/splash_scene_painter_test.dart`: para `t` em
  {0; 0,3; 0,5; 0,75; 1} pinta sem exceção; em `t = 1` a onda fica no rodapé e a mancha não é
  desenhada (FR-006); `shouldRepaint` só quando `t`, `breath` ou cores mudam.

### Implementation (US1)

- [X] T007 [US1] Remover `minimumDisplayDuration`/`defaultMinimumDisplayDuration` de
  `lib/modules/splash/presentation/controller/splash_controller.dart` (research R5): espera só
  onboarding e sessão; ajustar `lib/modules/splash/splash_module.dart` se passar o parâmetro.
- [X] T008 [US1] Criar `lib/modules/splash/presentation/widgets/splash_scene_painter.dart`
  (research R1, R2, R4): `SplashScenePainter({required double t, required double breath,
  required AppPalette colors})` com as fases da tabela R1 (Intervals sobre `t`):
  - toque `primary` (escala 0,4 → 1 → 0,78 → 1, some ao fim) no centro do escudo;
  - mancha `primary` de 8 pontos com ondulação senoidal, raio até a diagonal da tela;
  - onda `primary-glow` (60 ms atrás) e onda `primary`, borda cúbica do protótipo escalada à
    largura, descendo da tela inteira até o rodapé;
  - marca via `BrandMarkPainter`: em `background` recortada pela área vermelha e em `primary`
    recortada pela área revelada; `strokeProgress` e `elderProgress` pelos Intervals; escala
    `1 + 0,035 * breath`.
- [X] T009 [US1] Criar `lib/modules/splash/presentation/widgets/splash_animation.dart`:
  `AnimationController` de 1 800 ms (`AppMotion.of(context).reduced` → `value = 1` sem tocar),
  chama `onCompleted` ao terminar; segundo controlador de respiração (2 600 ms, `reverse: true`,
  `Curves.easeInOut`) ligado só com `breathing: true` e movimento normal; título e frase entram
  (sobem 14 px e aparecem) nos Intervals 1 400–1 650 e 1 550–1 800 ms; título 34/700 `secondary`,
  frase `bodyLarge` `textMutedForeground`; layout rola em tela curta.
- [X] T010 [US1] Reescrever `lib/modules/splash/presentation/pages/splash_page.dart`: fundo
  `context.colors.background`; `SplashAnimation`; `Future.wait([controller.resolveDestination(),
  animaçãoTerminou.future])` e `context.go` uma vez; `breathing` = animação terminou e destino
  ainda nulo; `Semantics` único com nome e frase, cena em `ExcludeSemantics`; chaves
  `SplashPage.sceneKey` e `SplashPage.logoKey`; remover `_Entrance`.

**Checkpoint**: splash animada funcionando com o logo ainda vindo do painter (cor do tema).

---

## Phase 4: User Story 2 — Logo na paleta do app em todo lugar (P1)

**Goal**: logo `primary` no app, ícones e web; `AppLogo` segue o alto contraste.
**Independent Test**: testes abaixo + quickstart "No aparelho" 3 e 5.

### Tests (US2)

- [X] T011 [P] [US2] Reescrever `test/core/widgets/app_logo_test.dart`: `AppLogo(size: 96)` tem
  96×96 e usa `BrandMarkPainter` com `AppPalette.light.primary`; com o tema de alto contraste usa
  `AppPalette.highContrast.primary`; continua sem semântica própria (teste do nome único mantido).
- [X] T012 [P] [US2] Criar `test/core/branding/brand_assets_test.dart` (lê arquivos do projeto):
  `assets/branding/click_seguro_logo.svg` não contém `C0503E` e contém `FE3152` no `fill` e no
  `stroke`; `web/manifest.json` tem `theme_color` `#FE3152`.

### Implementation (US2)

- [X] T013 [US2] Trocar `#C0503E` por `#FE3152` (fill e stroke) em
  `assets/branding/click_seguro_logo.svg`, sem mexer em paths, máscara ou `viewBox`.
- [X] T014 [US2] `lib/core/widgets/app_logo.dart`: `AppLogo` passa a ser `BrandMark(size: size)`
  (cor `context.colors.primary`); remover `AppLogo.asset` e conferir usos em
  `lib/modules/authentication/presentation/widgets/auth_header.dart`,
  `lib/modules/settings/presentation/pages/about_page.dart` e
  `test/modules/authentication/presentation/widgets/auth_header_test.dart`.
- [X] T015 [US2] `tools/generate_brand_assets.py`: parar de gerar `launch_logo.png` (Android) e
  `LaunchImage*.png` (iOS) (research R6); atualizar a docstring (cor agora é `primary`). Rodar no
  WSL conforme o [quickstart](quickstart.md#regenerar-as-imagens-da-marca) para regenerar
  `assets/branding/click_seguro_logo.png`, `mipmap-*/ic_launcher*.png`,
  `AppIcon.appiconset/*.png`, `web/icons/*.png` e `web/favicon.png`.
- [X] T016 [P] [US2] `web/manifest.json`: `theme_color` → `#FE3152`; conferir `web/index.html`.
- [X] T017 [US2] Se `assets/branding/click_seguro_logo.png` não for mais usado pelo app, mantê-lo
  só como arte exportada (fora do `pubspec` `assets` se não for referenciado) e registrar no
  `README.md` da raiz que o logo é `#FE3152`.

**Checkpoint**: nenhum `C0503E` no projeto (`git grep -i c0503e` vazio fora de `specs/`).

---

## Phase 5: User Story 3 — Sem movimento para quem pede (P2)

**Goal**: com "Reduzir animações", estado final direto, sem respirar, navega com a validação.
**Independent Test**: testes abaixo + quickstart "No aparelho" 2.

- [X] T018 [P] [US3] Testes em `test/modules/splash/presentation/pages/splash_page_test.dart`
  (substituem o teste de `Opacity` da 022):
  - movimento reduzido + destino pronto → navega no primeiro `pumpAndSettle`, sem esperar
    1 800 ms;
  - movimento reduzido + validação demorando → a escala da marca não muda entre `pump`s de
    3 s e o pintor está em `t = 1`;
  - movimento reduzido ligado durante a animação → pula para `t = 1`.
- [X] T019 [US3] Garantir em `lib/modules/splash/presentation/widgets/splash_animation.dart` que
  `didChangeDependencies` reaja à troca de `AppMotion` (pular para o fim e parar a respiração).

---

## Phase 6: User Story 4 — Abertura sem piscar (P3)

**Goal**: abertura nativa só com o fundo `#FFFDFB`.
**Independent Test**: teste abaixo + quickstart "No aparelho" 4.

- [X] T020 [P] [US4] Ampliar `test/core/branding/brand_assets_test.dart`: os dois
  `launch_background.xml` não têm `<bitmap`; `values-v31/styles.xml` e
  `values-night-v31/styles.xml` apontam `windowSplashScreenAnimatedIcon` para
  `@drawable/splash_icon_transparent`; `LaunchScreen.storyboard` não referencia `LaunchImage` e
  tem fundo `red="1" green="0.992" blue="0.984"`.
- [X] T021 [US4] Android: tirar o `<item><bitmap …launch_logo/></item>` de
  `android/app/src/main/res/drawable/launch_background.xml` e
  `android/app/src/main/res/drawable-v21/launch_background.xml`; criar
  `android/app/src/main/res/drawable/splash_icon_transparent.xml` (shape transparente); apontar
  `windowSplashScreenAnimatedIcon` para ele em `values-v31/styles.xml` e
  `values-night-v31/styles.xml`; apagar `drawable-*/launch_logo.png`.
- [X] T022 [US4] iOS: em `ios/Runner/Base.lproj/LaunchScreen.storyboard`, remover o `imageView`,
  suas constraints e o recurso `LaunchImage`, e mudar o fundo para `#FFFDFB`
  (`red="1" green="0.992" blue="0.984"`); apagar `ios/Runner/Assets.xcassets/LaunchImage.imageset`.

---

## Phase 7: Polish

- [X] T023 [P] Design system (`.specify/memory/design-system.md`): §2.1 registrar que a marca usa
  `primary`; §5 trocar "Marca (splash, login, 1º slide) = `Shield`" pelo logo oficial onde valer;
  §6 acrescentar a splash (1,8 s, fases, regra animação E validação, respiração).
- [X] T024 [P] Marcar o FR-018 da `specs/022-fluidez-movimento/spec.md` como mantido pela 023 (nota
  de rastreabilidade) e o item da `specs/021-identidade-visual/tasks.md` que preservava a cor do
  logo como substituído pela 023.
- [X] T025 `flutter analyze` sem novos avisos; `flutter test` verde; `git grep -i c0503e -- . ':!specs'`
  vazio.
- [ ] T026 Rodar no emulador `fuja_api36` o roteiro "No aparelho" do quickstart (1–5) e comparar
  com o protótipo V4-2 lado a lado (SC-006).
  - 2026-11-12, build profile no `fuja_api36` (Android 16), gravação da abertura a frio: itens 1 e
    4 conferidos — abertura nativa só com o fundo claro; toque → mancha → escudo em claro sobre o
    vermelho → idoso → onda escorre → logo `primary`, nome e frase → Início com esmaecimento.
  - Pendentes de conferência manual: 2 (reduzir animações), 3 (alto contraste), 5 (ícone, login e
    Sobre) — cobertos por testes automatizados; e a comparação final da equipe (SC-006).

---

## Dependencies & Execution Order

- Setup (T001) → Foundational (T002–T003) → US1 (T004–T010) e US2 (T011–T017) podem andar em
  paralelo depois da fundação (arquivos diferentes; T014 toca `app_logo.dart`, que a splash não
  usa mais).
- US3 (T018–T019) depende de US1 (mesmos arquivos da splash).
- US4 (T020–T022) independe das demais; T020 amplia o arquivo de teste criado em T012.
- Polish depois de todas.

### Parallel Example

```text
Fundação pronta →
  [US1] T004, T005, T006 (testes)      | [US2] T011, T012 (testes)
  [US1] T007 → T008 → T009 → T010      | [US2] T013 → T014, T015, T016 → T017
[US4] T020 → T021, T022 (a qualquer momento)
```

## Implementation Strategy

MVP = Fundação + US1 + US2 (as duas P1: sem o logo na paleta a equipe não aprova a splash).
Depois US3 (acessibilidade) e US4 (acabamento). Commit ao fim de cada fase, com os IDs das tarefas
na mensagem, como nas features anteriores.
