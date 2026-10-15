# Implementation Plan: Tela de Acessibilidade

**Branch**: `014-acessibilidade` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/014-acessibilidade/spec.md`

**Base**: tarefa B9 do [tasks do produto](../../.specify/memory/tasks.md),
[especificação do produto](../../.specify/memory/specification.md) (RF-038 a RF-041, RNF-003,
RNF-004, RN-003), [plano do produto](../../.specify/memory/plan.md) §3.2,
[constituição](../../.specify/memory/constitution.md), código das features 005, 007, 009, 010, 012
e 013.

## Summary

Trocar a tela provisória de `/settings/accessibility` pela tela de verdade e abrir as Configurações
para o visitante:

- **Tela** ([R1](research.md#r1-estado-da-tela-o-accessibilitycontroller-que-já-existe)): usa o
  `AccessibilityController` da feature 009 como está; nenhuma mudança em dados, gravação, tema ou
  carga no splash.
- **Tamanho da letra** ([R2](research.md#r2-tamanho-da-letra-e-prévia-ao-vivo),
  [R3](research.md#r3-linhas-de-escolha-única-no-flutter-347)): cartão de prévia + quatro linhas de
  escolha única com a porcentagem; widget novo `SettingsOptionTile<T>` sobre `RadioGroup`.
- **Chaves** ([R4](research.md#r4-chaves-alto-contraste-e-leitura-automática-settingsswitchtile)):
  alto contraste e leitura automática com um `SettingsSwitchTile` extraído da `AlertsSwitchTile`.
- **Velocidade** ([R5](research.md#r5-velocidade-da-voz)): lenta, normal, rápida.
- **Visitante** ([R6](research.md#r6-visitante-nas-configurações)): engrenagem sempre visível no
  `AppTopBar` e no Perfil; Configurações do visitante só com Leitura e aparência e Sobre, sem
  pedido ao serviço (`SettingsController.loadDeviceSettings()`).
- **Limpeza** ([R8](research.md#r8-atalhos-de-desenvolvimento)): sai a `SettingsSectionPage` e os
  atalhos obsoletos do playground de acessibilidade.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `provider`, `get_it`, `go_router`, `easy_localization`,
`lucide_icons_flutter`, `shared_preferences` (via `LocalCacheService`). Nenhuma dependência nova.

**Storage**: o mesmo da feature 009: `LocalCacheService`, chave `accessibility_preferences_v1`.
Nada novo é guardado.

**Testing**: `flutter_test`; `AccessibilityController` real sobre `FakeLocalCacheService` na tela;
`ClickSeguroApp` montado como no `accessibility_app_test.dart`; `pumpLocalized` e
`registerSettingsDependencies` nas Configurações; `GetIt` resetado. Offline.

**Target Platform**: Android e iOS.

**Project Type**: mobile-app

**Performance Goals**: escolha visível na tela e no app em menos de 1 s (SC-002), no mesmo quadro
do toque, porque o notifier muda antes da gravação.

**Constraints**: 48 dp/16 sp, rótulos e estados para o leitor de tela, fonte até o teto de 200%,
alto contraste (RNF-003/004); visitante nunca chama o serviço (RN-003); textos pt-BR/en-US; sem
importar outros módulos.

**Scale/Scope**: módulo `settings` com ~5 arquivos novos (página, 3 widgets, extensão de rótulos) e
ajustes na `SettingsPage`, `SettingsController`, `AlertsSwitchTile` e rotas; ~16 chaves de i18n;
ajustes pequenos em `shell` (`AppTopBar`) e `profile` (`ProfilePage`); 1 arquivo de teste novo e
5 ajustados.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | A tela fica em `settings/presentation` e fala só com o `AccessibilityController`, que fala com usecases. Nada importa outro módulo: as velocidades vêm do `ReadingSpeed` de `common`; os rótulos de velocidade são chaves próprias do `settings` (R5). `shell` e `profile` só deixam de esconder a engrenagem (rota por texto, como já é). | ✅ |
| II. SOLID, DRY, KISS | Controller reaproveitado (R1). `SettingsSwitchTile` extraído em vez de copiado (R4). Seções "Leitura e aparência" e "Sobre" extraídas para as duas listas (R6). Sem prévia simulada (R2). | ✅ |
| III. TDD | Testes antes do código: `loadDeviceSettings()`, página de acessibilidade (efeito, gravação, próxima abertura, falha, fonte 2×, semântica), lista do visitante, engrenagem no topo e no Perfil. | ✅ |
| IV. Stack e DI | Nenhuma dependência nova; o controller continua injetado pelo `SettingsModule` e entregue pelo `provider`. | ✅ |
| V. Erros tipados | Não há falha nova: a gravação falha em silêncio (FR-010, já tratado na 009). | ✅ |
| Regras globais | Textos por chave em `AppStrings`; nenhum segredo; UI não acessa infraestrutura. Mudanças em `shell` e `profile` justificadas por FR-013 e com teste. | ✅ |

**Pós-design (Phase 1)**: reavaliado depois do data-model e do contrato; sem desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/014-acessibilidade/
├── spec.md
├── plan.md                       # este arquivo
├── research.md                   # R1–R9
├── data-model.md                 # preferências (sem mudança), SettingsController, rótulos, i18n
├── quickstart.md                 # testes + 17 passos no aparelho
├── contracts/
│   └── accessibility-ui.md       # rotas, engrenagem, conteúdo por sessão, tela
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── core/i18n/app_strings.dart                                  # + settings_accessibility_*
├── dev/accessibility_playground.dart                           # − painel e "Notícias salvas" (R8)
├── modules/shell/presentation/widgets/app_top_bar.dart         # engrenagem sempre
├── modules/profile/presentation/pages/profile_page.dart        # engrenagem sempre
└── modules/settings/presentation/
    ├── controller/settings_controller.dart                     # + loadDeviceSettings()
    ├── extensions/accessibility_presentation.dart              # NOVO: rótulos de nível e velocidade
    ├── pages/accessibility_page.dart                           # NOVO
    ├── pages/settings_page.dart                                # lista do visitante, seções extraídas
    ├── pages/settings_section_page.dart                        # REMOVIDO
    ├── routes/settings_routes.dart                             # /settings/accessibility → AccessibilityPage
    └── widgets/
        ├── settings_option_tile.dart                           # NOVO (RadioGroup)
        ├── settings_switch_tile.dart                           # NOVO (extraído)
        ├── font_preview_card.dart                              # NOVO
        └── alerts_switch_tile.dart                             # usa SettingsSwitchTile
assets/translations/{pt-BR,en-US}.json                          # + chaves; settings_guest_body alterado

test/modules/settings/presentation/accessibility_page_test.dart # NOVO
test/modules/settings/presentation/{settings_page,settings_controller,change_password_page}_test.dart
test/modules/shell/presentation/app_top_bar_test.dart
test/modules/profile/presentation/pages/profile_page_test.dart
```

**Structure Decision**: tudo de novo fica na camada de apresentação do `settings`, onde a feature
009 já deixou o controller e o plano do produto (§3.2) põe a tela da B9. Nenhuma camada de dados ou
domínio muda.

## Fora do código

- **Avisar o outro desenvolvedor**: a engrenagem volta a aparecer para o visitante no `AppTopBar` e
  no Perfil (revê a B8), e a `AlertsSwitchTile` passa a usar o `SettingsSwitchTile`.
- **B2 (perguntas)**: quando existir, deve ler `autoReadAloud` como a notícia já faz e atualizar o
  subtítulo da chave para citar as atividades (R7).
- **Tasks do produto**: marcar a B9 e anotar a mudança da regra do visitante ao fechar a feature.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: chaves de i18n; extensão de rótulos; `SettingsOptionTile`, `SettingsSwitchTile` (com a
   `AlertsSwitchTile` usando-o, testes da B8 verdes) e `FontPreviewCard`; rota para a página nova e
   remoção da `SettingsSectionPage`.
2. **US1 (tamanho da letra)**: página com a seção de tamanho e prévia; teste de efeito, gravação,
   próxima abertura, falha de gravação, fonte 2× e semântica.
3. **US2 (alto contraste)**: seção Aparência; testes.
4. **US3 (leitura automática e velocidade)**: seção Leitura em voz alta; testes.
5. **US4 (visitante)**: `loadDeviceSettings()`; lista do visitante; engrenagem no `AppTopBar` e no
   Perfil; texto do convite da senha; testes.
6. **Polimento**: limpeza do playground (R8), revisão de código sem uso, analyze, suíte, quickstart
   no aparelho, marcar a B9.

Um commit por história.

## Complexity Tracking

Sem violações a justificar.
