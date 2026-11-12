# Implementation Plan: Splash animada e logo na paleta do app

**Branch**: `023-splash-animada` | **Date**: 2026-11-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/023-splash-animada/spec.md`

## Summary

Trocar a splash (esmaecimento + mínimo fixo de 2 s) pela animação aprovada "V4-2 — Mancha e
onda", comprimida para 1,8 s, desenhada em `CustomPainter` com os paths oficiais da marca; a
navegação passa a esperar a animação **e** a validação. O logo oficial vira `primary` em todo
lugar: SVG/PNG regenerados pelo script do projeto, ícones Android/iOS/web, e o `AppLogo` passa a
ser desenhado em código na cor do tema (segue o alto contraste). A abertura nativa fica só com o
fundo `#FFFDFB`. Detalhes em [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (stable)

**Primary Dependencies**: as atuais (provider, go_router, easy_localization). Nenhuma nova.

**Storage**: N/A

**Testing**: flutter_test (widget e unidade), relógio falso do `tester.pump`

**Target Platform**: Android (inclui 12+ com SplashScreen do sistema), iOS, web

**Project Type**: mobile-app (Flutter, módulos por feature)

**Performance Goals**: 60 fps na splash em aparelho de entrada; um único `AnimationController`

**Constraints**: animação ≤ 1 800 ms; navegação = max(animação, validação); zero movimento com
"Reduzir animações"; só tokens de `context.colors`

**Scale/Scope**: 1 tela (splash), 1 widget compartilhado (`AppLogo`), recursos nativos de marca

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Situação | Como |
|---|---|---|
| I. Módulos e camadas | ✅ | Marca em `lib/core/widgets/` (usada por splash, login e Sobre). Cena e animação em `modules/splash/presentation/widgets/`. O controlador continua só com a regra de destino (UseCases inalterados). |
| II. SOLID/DRY/KISS | ✅ | Um `BrandMarkPainter` para todo desenho da marca; um controlador de animação; remove-se o mínimo fixo do controlador em vez de duplicar a duração. |
| III. TDD | ✅ | Testes da regra "animação e validação", do movimento reduzido, da respiração, da cor da marca no tema e da ausência de `#C0503E` escritos antes da implementação. |
| IV. Stack oficial | ✅ | Sem dependência nova (R3 rejeita `flutter_svg`). Strings existentes (`app_title`, `splash_tagline`). |
| V. Erros tipados | ✅ | Sem erro novo; falhas de leitura seguem as regras da feature 004. |
| Segurança | ✅ | Nada sensível. |

**Pós-design**: reavaliado depois de data-model e contracts; sem violações. Complexity Tracking
vazia.

## Project Structure

### Documentation (this feature)

```text
specs/023-splash-animada/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/splash-ui.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code

```text
click_seguro_app/
├── assets/branding/click_seguro_logo.svg|.png      # cor #FE3152
├── tools/generate_brand_assets.py                   # deixa de gerar launch_logo/LaunchImage
├── lib/core/widgets/
│   ├── brand_mark.dart                              # NOVO: paths oficiais + BrandMarkPainter
│   └── app_logo.dart                                # passa a usar BrandMark em primary
├── lib/modules/splash/
│   ├── presentation/controller/splash_controller.dart   # sem minimumDisplayDuration
│   ├── presentation/pages/splash_page.dart              # espera animação E destino
│   └── presentation/widgets/
│       ├── splash_animation.dart                    # NOVO: controller 1 800 ms + respiração
│       └── splash_scene_painter.dart                # NOVO: toque, mancha, onda, marca
├── android/app/src/main/res/
│   ├── drawable/launch_background.xml, drawable-v21/launch_background.xml  # só a cor
│   ├── drawable/splash_icon_transparent.xml         # NOVO
│   ├── values-v31/styles.xml, values-night-v31/styles.xml
│   └── drawable-*/launch_logo.png                   # removidos
├── ios/Runner/Base.lproj/LaunchScreen.storyboard    # fundo #FFFDFB, sem imagem
├── ios/Runner/Assets.xcassets/LaunchImage.imageset  # removido
├── web/manifest.json                                # theme_color #FE3152
└── test/
    ├── core/widgets/brand_mark_test.dart            # NOVO
    ├── core/widgets/app_logo_test.dart
    ├── core/branding/brand_assets_test.dart         # NOVO: sem #C0503E, nativos sem logo
    └── modules/splash/presentation/{controller,pages,widgets}/...
```

**Structure Decision**: app Flutter único (`click_seguro_app/`), módulos por feature; a marca é
transversal (`core`), a cena é do módulo `splash`. Documentação: design system §5 (cor da marca)
e §6 (splash) atualizados.

## Complexity Tracking

Sem violações.
