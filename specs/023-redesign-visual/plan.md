# Implementation Plan: Redesign visual 2.0

**Branch**: `023-redesign-visual` | **Date**: 2026-11-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/023-redesign-visual/spec.md` · Figma
[Click Seguro · Redesign 2.0](https://www.figma.com/design/jr3QeiIsXvuWqJirZFFdYf) ·
[especificação do produto](../../.specify/memory/specification.md) 2.4.0 ·
[design system](../../.specify/memory/design-system.md) 1.1.1 ·
[constituição](../../.specify/memory/constitution.md) · código das features 005, 006, 010, 012,
014 a 021.

## Summary

Trocar só a aparência, em quatro camadas, de baixo para cima:

- **Tokens** ([R1](research.md#r1-paleta-nova-sem-trocar-o-mecanismo)–[R4](research.md#r4-cantos-sombra-e-espaçamento)),
  em `lib/core/theme/`:
  - a paleta clara ganha os valores novos e as cores que faltavam (cremes, informação, coral
    suave, pressionado, texto de corpo);
  - escala de texto em Inter, empacotada no app;
  - escala de cantos, uma sombra só e durações e curvas de animação.

  O alto contraste ganha os mesmos campos.
- **Componentes** ([R6](research.md#r6-componentes-evoluir-os-safe-sem-trocar-a-api)),
  em `lib/core/widgets/`:
  - os `Safe*` mantêm nome e API pública sempre que der, para as 80 e poucas telas herdarem o
    visual sem mexer em cada uso;
  - os que faltam nascem novos: chip, abas em pílula, barra/anel/segmentos de progresso, brilho
    de carregamento, ilustração e moldura de folha inferior.
- **Ilustrações** ([R5](research.md#r5-ilustrações-em-svg-com-flutter_svg)): SVGs desenhados para
  o Figma, desenhados com `flutter_svg` e recoloridos para o alto contraste.
- **Telas**: ajuste de layout das telas que o Figma desenhou, uma história por vez, sem tocar em
  comportamento, textos, rotas, controllers ou casos de uso (FR-022).

Os dois acréscimos de comportamento são pequenos e isolados:

- **"Reduzir animações"** ([R8](research.md#r8-reduzir-animações-um-sinal-só)): vira um campo de
  `AccessibilityPreferences`, salvo pelo repositório que o módulo settings já tem. O `main.dart`
  soma o interruptor ao `MediaQuery.disableAnimations`, e toda animação lê esse sinal só.
- **Cartão de emergência** ([R11](research.md#r11-cartão-de-emergência)): usa a ação de ligar que
  a Central de ajuda já tem.

## Technical Context

**Language/Version**: Dart (SDK travado no `pubspec.yaml`), Flutter 3.47.5 stable

**Primary Dependencies**: a stack atual (Provider + ChangeNotifier, GetIt, go_router,
easy_localization, lucide_icons_flutter, shared_preferences, url_launcher).
- **Nova**: `flutter_svg`, para as ilustrações ([R5](research.md#r5-ilustrações-em-svg-com-flutter_svg)).
- A fonte Inter vai como asset, sem pacote ([R2](research.md#r2-fonte-inter-empacotada)).

**Storage**: `shared_preferences`, pelo `AccessibilityLocalDataSource` atual, para o novo campo
`reduceMotion`

**Testing**: `flutter test`, com testes unitários e de widget
([R12](research.md#r12-testes)). Os testes atuais só mudam onde conferem aparência. Sem testes
golden.
- **Unitários**: contraste da paleta, reconhecimento de tema, modelo de preferências.
- **De widget**: componentes, barra inferior, cartão de emergência, comportamento com reduzir
  animações e rótulo do carregamento.

**Target Platform**: celulares Android e iOS (retrato). O build web continua compilando.

**Project Type**: app mobile (Flutter, Clean Architecture modular)

**Performance Goals**: 60 fps nas animações e na rolagem, inclusive no brilho do carregamento e na
grade de 2 colunas. Nenhuma animação atrasa o primeiro feed além do RNF-001 (2 s).

**Constraints**:
- Funciona offline, com fonte e ilustrações empacotadas (RNF-002).
- WCAG 2.1 AA no tema claro e AAA no alto contraste (RNF-004).
- Escala de texto até o teto atual de 2,0 (`FontScaleLevel.maxTotalScale`).
- Nenhum texto visível muda além de FR-016 e FR-024.
- Toda animação para quando `MediaQuery.disableAnimations` é verdadeiro.

**Scale/Scope**:
- Cerca de 30 arquivos de página e os 18 widgets compartilhados.
- 2 grupos de textos novos: cartão (título, texto, botão) e interruptor (rótulo, descrição).
- Cerca de 17 ilustrações SVG.
- 223 arquivos de teste hoje.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Status |
|---|---|---|
| I. Clean Architecture e módulos | Tokens, widgets, ilustrações e o reconhecimento de tema ficam em `lib/core/`, porque são transversais e usados por vários módulos. O `reduceMotion` segue o caminho que o módulo settings já tem (modelo → data source → repositório → caso de uso → controller). As telas mudam só em `presentation/`. Nenhum módulo importa outro. | Pass |
| II. SOLID, DRY, KISS | Os `Safe*` evoluem em vez de ganharem cópias. Um sinal no `MediaQuery` evita cada widget ler a preferência. Sem pacotes de animação ou de brilho: os widgets pequenos são escritos à mão ([R9](research.md#r9-animações-sem-pacote)). | Pass |
| III. TDD (inegociável) | Toda regra nova começa com teste falhando: reconhecimento de tema, contraste, salvar e somar o reduzir animações, ligação do cartão, aba selecionada. Os widgets alterados ganham teste antes da mudança. | Pass |
| IV. Stack oficial e DI | Provider, GetIt e easy_localization sem mudança. `flutter_svg` é o único pacote novo, justificado em [R5](research.md#r5-ilustrações-em-svg-com-flutter_svg), com versão fixada. | Pass (dependência justificada) |
| V. Erros tipados, sem strings mágicas | Nenhum caminho de erro novo. Chaves novas no `AppStrings`. Cores e tamanhos saem dos tokens, sem valor fixo nas telas: os 130 `fontSize:` soltos viram estilos de texto nas histórias que tocam cada tela. | Pass |
| Segurança e qualidade | Sem segredos, sem `dynamic`, sem `late` ou `!` novos. Versões fixadas. | Pass |

**Reavaliação depois do design (Phase 1)**: sem mudança, todos os portões passam. O único ponto a
registrar é o `flutter_svg`, em Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/023-redesign-visual/
├── plan.md              # Este arquivo
├── research.md          # Phase 0: decisões R0–R13
├── data-model.md        # Phase 1: tokens, preferência, ilustração e tema
├── quickstart.md        # Phase 1: como validar no aparelho contra o Figma
├── contracts/
│   └── ui-components.md # Phase 1: contrato público dos widgets compartilhados
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
click_seguro_app/
├── pubspec.yaml                         # + flutter_svg, + fonts: Inter, + assets/illustrations/
├── assets/
│   ├── fonts/Inter-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf + OFL.txt
│   ├── illustrations/                   # NOVO: *.svg (temas, estados, onboarding, capas)
│   └── translations/{pt-BR,en-US}.json  # + cartão de emergência, + reduzir animações
├── lib/
│   ├── main.dart                        # soma reduceMotion ao MediaQuery.disableAnimations
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart          # valores novos do tema claro
│   │   │   ├── app_palette.dart         # + campos semânticos, claro e alto contraste
│   │   │   ├── app_typography.dart      # NOVO: estilos de texto em Inter
│   │   │   ├── app_spacing.dart         # + cantos 12/16/20/24/32/pílula, + espaço 48
│   │   │   │                            # (sombra única: AppPalette.shadow, sem arquivo próprio)
│   │   │   ├── app_motion.dart          # NOVO: durações, curvas, context.reduceMotion
│   │   │   └── app_theme.dart           # Inter, textTheme, campos, folha, snackbar, transição
│   │   ├── illustrations/               # NOVO
│   │   │   ├── app_illustration.dart    # enum de cada ilustração → caminho do asset
│   │   │   └── illustration_theme.dart  # reconhece o tema num texto (título, categoria)
│   │   └── widgets/
│   │       ├── safe_button.dart         # primário/secundário/contorno/link; 60; escala ao tocar
│   │       ├── safe_card.dart, safe_badge.dart, safe_text_field.dart  # visual novo
│   │       ├── safe_empty_state.dart, safe_error_state.dart           # ilustrações novas
│   │       ├── safe_loading_state.dart  # brilho por padrão (mantém o rótulo de leitura)
│   │       ├── safe_offline_banner.dart, slow_request_notice.dart, listen_button.dart
│   │       ├── safe_state_illustration.dart  # SUBSTITUÍDO por safe_illustration.dart
│   │       ├── safe_illustration.dart   # NOVO: SVG + recolorir no alto contraste
│   │       ├── safe_icon_button.dart    # NOVO
│   │       ├── safe_chip.dart           # NOVO
│   │       ├── safe_pill_tabs.dart      # NOVO (no lugar do visual de TabBar/SegmentedButton)
│   │       ├── safe_progress.dart       # NOVO: barra, anel e segmentos (com enchimento)
│   │       ├── safe_skeleton.dart       # NOVO: blocos com brilho
│   │       └── safe_sheet.dart          # NOVO: moldura de folha inferior (alça, canto 32)
│   └── modules/
│       ├── shell/presentation/widgets/app_bottom_nav.dart   # 5 abas iguais, pílula
│       ├── splash/, onboarding/, authentication/            # US2
│       ├── activities/presentation/                         # US3
│       ├── news/presentation/                               # US4 (grade, capa, detalhe)
│       ├── assistant/presentation/, help/presentation/      # US5 (+ cartão de emergência)
│       ├── profile/presentation/                            # US1 (só componentes)
│       └── settings/                                        # reduceMotion de ponta a ponta
└── test/                                # espelha lib/; testes novos e ajustados (R12)
```

**Structure Decision**: o projeto Flutter atual, `click_seguro_app/`, com a estrutura modular da
constituição. O que é visual e transversal vai para `lib/core/` (tema, ilustrações, widgets). O
layout próprio de cada tela fica no `presentation/` do módulo. O
`.specify/memory/design-system.md` é reescrito como 2.0.0, e o `specification.md` registra a
barra inferior e o cartão de emergência (FR-023).

## Ordem das histórias e commits

Um commit por história, como combinado no clarify, e um PR só no fim:

- Base + US1: tokens, tipografia, componentes, barra inferior, reduzir animações, Perfil e as
  telas sem desenho próprio herdando o visual.
- US2: splash, onboarding e login.
- US3: atividades.
- US4: notícias.
- US5: Assistente e Ajuda.
- US6: estados.
- Docs: design system 2.0.0, especificação e tasks.

US2 a US6 dependem só da US1 e podem ir em qualquer ordem depois dela.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Dependência nova `flutter_svg` | Cerca de 17 ilustrações vetoriais foram desenhadas em SVG para o Figma aprovado. Precisam ficar nítidas em qualquer tamanho, mudar de cor no alto contraste e funcionar offline. | `CustomPainter`, como a feature 021 fez com o seu desenho único, exigiria traduzir à mão centenas de comandos de caminho por desenho, sem como conferir com o Figma. PNG borra com a fonte ampliada e não muda de cor no alto contraste. O Flutter não desenha SVG sozinho. |
