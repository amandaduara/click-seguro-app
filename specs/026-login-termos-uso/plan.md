# Implementation Plan: Login que continua a splash, aceite dos termos e Termos de uso

**Branch**: `026-login-termos-uso` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/026-login-termos-uso/spec.md`

## Summary

O login e o cadastro ganham o visual da versão A: cabeçalho centralizado, onda coral dupla da
splash no rodapé e "Continuar sem login" como link. A splash passa a abrir o login com
`from=splash`, e o próprio login faz a abertura: a marca voa do centro até o cabeçalho e o
formulário entra em sequência. Com "Reduzir animações", não há movimento. O cadastro ganha a
caixa de aceite, um estado do `AuthenticationController` que trava "Criar conta". As
Configurações ganham a tela "Termos de uso", no molde da Privacidade. Termos e Privacidade
passam a abrir sem sessão. Nada muda no serviço. Decisões em [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (stable)

**Primary Dependencies**: as atuais (provider, go_router 17.3, easy_localization,
lucide_icons_flutter). Nenhuma nova.

**Storage**: N/A (o aceite vive só na tela; nada é guardado)

**Testing**: flutter_test (unidade e widget), relógio falso do `tester.pump` para a abertura

**Target Platform**: Android e iOS (a validação da usuária é num Android real)

**Project Type**: mobile-app (Flutter, módulos por feature)

**Performance Goals**: 60 fps na abertura, com um único `AnimationController` e só
transformações e opacidade (sem refazer o layout a cada quadro)

**Constraints**:

- A abertura leva no máximo 1,5 s (usa 1,25 s).
- Nenhum movimento com "Reduzir animações".
- Só tokens de `context.colors` (seguem o alto contraste).
- Alvos de toque de pelo menos 48 × 48.
- Textos em pt-BR e en-US.
- Nenhuma chamada nova ao serviço.

**Scale/Scope**:

- 3 telas: login/cadastro, Termos de uso e a linha nova nas Configurações.
- 1 widget novo no `core` (`BrandScene`/`BrandWave`) e 2 widgets de módulo (`TermsAcceptance`,
  `SettingsTopicCard`).
- 1 ajuste de rota (as telas que abrem sem sessão).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como o plano cumpre | Situação |
|---|---|---|
| I. Clean Architecture e módulos | A onda e a posição da marca, usadas pela splash e pelo login, vão para `core/widgets/brand_scene.dart`; nenhum módulo importa arquivo interno de outro. A tela de Termos fica no módulo `settings`; a caixa de aceite, no `authentication`. Sem dados novos, então sem camadas `data/` ou `domain/` novas. | OK |
| II. SOLID, DRY, KISS | O cartão de assunto da Privacidade vira `SettingsTopicCard`, usado pelas duas telas. Bordas da onda num lugar só. Data fixa em texto traduzido (sem `intl`). Nada de abstração para casos hipotéticos. | OK |
| III. TDD | Testes do controller (aceite), dos widgets novos, da abertura (relógio falso), da rota sem sessão e da linha nas Configurações, escritos junto de cada história (R9). | OK |
| IV. Stack oficial | Só Flutter, provider, go_router e easy_localization. Nenhuma biblioteca nova; todos os textos em `AppStrings` e nos dois JSON. | OK |
| V. Erros tipados | Nenhum fluxo de erro novo. As mensagens do login continuam as mesmas chaves de `Failure`. | OK |

**Re-check pós-design (Fase 1)**: o data-model não cria entidade persistida, e o contrato de
tela só usa rotas e chaves de texto. O gate continua passando.

## Project Structure

### Documentation (this feature)

```text
specs/026-login-termos-uso/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # decisões R1–R10
├── data-model.md        # estado do aceite e da abertura
├── quickstart.md        # roteiro de validação no aparelho
├── contracts/
│   └── ui-contract.md   # rotas, telas sem sessão e chaves de texto
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks (ainda não criado)
```

### Source Code (repository root)

```text
click_seguro_app/
├── lib/
│   ├── core/
│   │   ├── i18n/app_strings.dart                    # chaves novas; saem auth_or, auth_guest_note, auth_welcome, auth_brand
│   │   ├── routing/app_router.dart                  # _publicPaths + /settings/terms e /settings/privacy
│   │   └── widgets/brand_scene.dart                 # NOVO: BrandScene (logoRectFor, ondas) + BrandWave
│   └── modules/
│       ├── splash/presentation/
│       │   ├── controller/splash_destination.dart   # login → '/login?from=splash'
│       │   └── widgets/splash_scene_painter.dart    # passa a usar BrandScene (sem mudar o desenho)
│       ├── authentication/presentation/
│       │   ├── controller/authentication_controller.dart  # termsAccepted, setTermsAccepted, canSubmit
│       │   ├── routes/authentication_routes.dart    # from=splash → página sem transição + abertura
│       │   ├── pages/login_page.dart                # layout A, onda, aceite, abertura
│       │   └── widgets/
│       │       ├── auth_header.dart                 # cabeçalho centralizado com o slot da marca
│       │       ├── login_intro.dart                 # NOVO: coreografia da abertura (R1)
│       │       ├── terms_acceptance.dart            # NOVO: caixa de aceite (R7)
│       │       └── or_divider.dart                  # REMOVIDO
│       └── settings/presentation/
│           ├── pages/terms_page.dart                # NOVO: Termos de uso
│           ├── pages/privacy_page.dart              # usa SettingsTopicCard
│           ├── pages/settings_page.dart             # linha "Termos de uso"
│           ├── routes/settings_routes.dart          # rota terms
│           └── widgets/settings_topic_card.dart     # NOVO: cartão de assunto (ex-_Paragraph)
├── assets/translations/{pt-BR,en-US}.json           # textos novos nos dois idiomas
└── test/                                            # espelha lib/ (R9)
    ├── core/widgets/brand_scene_test.dart
    ├── core/routing/app_router_test.dart
    ├── modules/authentication/presentation/controller/authentication_controller_test.dart
    ├── modules/authentication/presentation/pages/login_page_test.dart
    ├── modules/authentication/presentation/widgets/{auth_header,login_intro,terms_acceptance}_test.dart
    ├── modules/splash/presentation/pages/splash_page_test.dart
    └── modules/settings/presentation/{settings_page,privacy_and_about_pages,terms_page}_test.dart
```

**Structure Decision**: app Flutter único em `click_seguro_app/`, com módulos por feature. A
feature toca três módulos (`authentication`, `settings`, `splash`) e o `core`. A única peça
compartilhada entre módulos (onda e posição da marca) vai para o `core`, conforme o Princípio I.

## Ordem das histórias

1. **Base**: `BrandScene`/`BrandWave` no `core`, com a splash migrada sem mudar o desenho;
   `SettingsTopicCard` extraído da Privacidade; chaves de texto novas.
2. **US1 (P1)**: tela Termos de uso, rota, linha nas Configurações e telas sem sessão.
3. **US2 (P1)**: aceite no controller e `TermsAcceptance` no cadastro, com os links.
4. **US3 (P2)**: layout A do login e do cadastro, com a onda, e remoção do código morto.
5. **US4 (P3)**: abertura `from=splash` e destino novo da splash.
6. **Polimento**: suíte completa, `flutter analyze`, documentos do produto (R3 em `tasks.md`,
   RF-003/RF-037 na especificação, design-system) e validação no aparelho.

## Complexity Tracking

Nenhuma violação a justificar.
