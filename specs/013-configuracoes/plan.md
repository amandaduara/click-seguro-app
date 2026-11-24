# Implementation Plan: Configurações

**Branch**: `013-configuracoes` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/013-configuracoes/spec.md`

**Base**: tarefa B8 do [tasks do produto](../../.specify/memory/tasks.md),
[especificação do produto](../../.specify/memory/specification.md) (RF-037, RF-042, RN-001,
RN-003, RN-007, CB-013), [contrato da API](../../.specify/memory/api-contract.md) 1.0.8,
[constituição](../../.specify/memory/constitution.md), captura do quadro "Configurações" do Figma
(2026-10-14), código das features 001, 002, 003, 005, 007, 009, 011 e 012.

## Summary

Trocar a página provisória de `/settings` pela tela do quadro do Figma e entregar o que ela abre:

- **Tela** ([R1](research.md#r1-dados-da-conta-nas-configurações), [R8](research.md#r8-rotas)):
  cartão da conta, Conta, Alertas, Leitura e aparência, Sobre e "Sair da conta"; datasource
  próprio para `/users/me`.
- **Sair** ([R2](research.md#r2-sair-da-conta)): direto, sem confirmação; nada do aparelho é
  apagado.
- **Senha** ([R3](research.md#r3-troca-de-senha)): tela de troca com as regras ao vivo; a política
  de senha e a lista de regras saem do `authentication` para `common`/`core`, para serem
  compartilhadas sem cópia.
- **Alertas** ([R4](research.md#r4-chave-alertas-de-notícias-novas)): chave otimista; o aviso da
  tela de Alertas passa a abrir as Configurações.
- **Idioma** ([R5](research.md#r5-idioma)): Idioma do celular / Português / English, com a
  escolha guardada.
- **Visitante** ([R6](research.md#r6-visitante-e-engrenagem)): a engrenagem some no Perfil e na
  barra do topo; link direto mostra convite.
- **Sobre** ([R7](research.md#r7-versão-do-app)): versão lida com `package_info_plus`.
- **Servidor** ([R0](research.md#r0-conferência-no-servidor-real-portão-de-api), conferido em
  2026-10-14): a troca de senha revoga o `refreshToken`; o app entra de novo sozinho com a nova
  senha para a pessoa continuar conectada.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `dio` (via `ApiClient`), `fpdart`, `get_it`, `provider`,
`go_router`, `easy_localization` (troca e guarda do idioma), `lucide_icons_flutter`,
`shared_preferences` (via `LocalCacheService`). **Nova**: `package_info_plus` (versão do app, R7).

**Storage**: `LocalCacheService` para a escolha de idioma (`language_choice`); o
`easy_localization` guarda o idioma aplicado. Senhas nunca são guardadas.

**Testing**: `flutter_test`; `FakeHttpClientAdapter` no datasource; fakes de repository, de
`LocalCacheService` e de `AppInfoService`; widget tests com `pumpLocalized` e `GetIt` resetado.
Offline.

**Target Platform**: Android e iOS.

**Project Type**: mobile-app

**Performance Goals**: troca de idioma em até 1 s sem reiniciar (SC-003); chave de alertas muda no
mesmo quadro do toque (SC-004).

**Constraints**: 48 dp/16 sp, rótulos (a chave anuncia o estado), alto contraste e fonte até 200%
(RNF-003/004, F0.6); visitante nunca chama o serviço (RN-003); senha atual errada nunca encerra a
sessão (CB-013); textos pt-BR/en-US; sem importar outros módulos.

**Scale/Scope**: módulo `settings` com ~25 arquivos novos (data, domain, presentation) ao lado da
acessibilidade que já existe; ~50 chaves de i18n; política de senha e lista de regras movidas
(`authentication` → `common`/`core`); ajustes pequenos em `shell` (`AppTopBar`), `profile`
(`ProfilePage`) e `notifications` (`AlertsNotices`); ~12 arquivos de teste novos.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | `settings` ganha `data`→`domain`→`presentation` para conta, senha e idioma; controllers só falam com usecases (inclusive sair e versão). Nada importa `profile`, `authentication` ou `notifications`: datasource próprio para `/users/me`, convite próprio. A política de senha passa a ser do `common`, de onde o `authentication` e o `settings` a usam. | ✅ |
| II. SOLID, DRY, KISS | Regra e lista de senha movidas em vez de copiadas. Idioma: só um repositório local e a chamada do `easy_localization` na página. | ✅ |
| III. TDD | Testes antes do código para datasource, repository, usecases, política (testes da 003 continuam), controllers e páginas. | ✅ |
| IV. Stack e DI | Uma dependência nova (`package_info_plus`), justificada em R7 e usada só pelo `AppInfoService` do `common` (contrato + fake). | ✅ (justificado) |
| V. Erros tipados | `WrongCurrentPasswordFailure`, `SamePasswordFailure` a partir de códigos em constantes; resultados por enum; mensagens por chave. | ✅ |
| Regras globais | Senhas nunca guardadas nem logadas (rota sensível do `ApiClient`); mudanças em `common`, `core`, `shell`, `profile` e `notifications` justificadas (R3, R4, R6, R7) e com teste. | ✅ |

**Pós-design (Phase 1)**: reavaliado após o data-model e o contrato; sem desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/013-configuracoes/
├── spec.md
├── plan.md                       # este arquivo
├── research.md                   # R0–R9
├── data-model.md                 # entidades, falhas, controllers, i18n
├── quickstart.md                 # testes + 18 passos no aparelho
├── contracts/
│   └── settings-api.md           # endpoints, rotas e interface do módulo
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
pubspec.yaml                                            # + package_info_plus
lib/
├── core/i18n/app_strings.dart                          # + bloco settings_*
├── core/widgets/password_rules_list.dart               # movido de authentication
├── modules/common/
│   ├── validators/password_policy.dart                 # PasswordRule + PasswordPolicy (movidos)
│   ├── services/app_info_service.dart                  # NOVO
│   └── common_module.dart                              # registra AppInfoService
├── modules/authentication/                             # imports da política e da lista
├── modules/shell/presentation/widgets/app_top_bar.dart # engrenagem só com conta
├── modules/profile/presentation/pages/profile_page.dart# engrenagem só com conta
├── modules/notifications/presentation/widgets/alerts_notices.dart # → /settings, confere na volta
└── modules/settings/
    ├── settings_module.dart · settings.dart
    ├── data/
    │   ├── datasources/account_remote_data_source(_impl).dart · language_local_data_source(_impl).dart
    │   ├── models/account_summary_model.dart
    │   └── repositories/account_repository_impl.dart · language_repository_impl.dart
    ├── domain/
    │   ├── entities/ (account_summary, language_choice)
    │   ├── failures/settings_failures.dart
    │   ├── repositories/ (account, language)
    │   └── usecases/ (get_account, set_receive_alerts, change_password, logout, get_language, save_language, get_app_version)
    └── presentation/
        ├── controller/settings_controller.dart · account_state.dart · change_password_controller.dart
        ├── pages/settings_page.dart · change_password_page.dart · privacy_page.dart · about_page.dart
        ├── widgets/ settings_section · settings_tile · account_card · alerts_switch_tile · language_sheet · settings_guest_invite
        └── routes/settings_routes.dart
assets/translations/{pt-BR,en-US}.json

test/modules/settings/ (data, domain, presentation, fakes) · test/modules/common/validators/password_policy_test.dart ·
test/fakes/fake_app_info_service.dart · ajustes em test/modules/{authentication,shell,profile,notifications} e test/core/routing/app_router_test.dart
```

**Structure Decision**: o `settings` vira um módulo completo nas três camadas para conta, senha e
idioma, ao lado da acessibilidade (F0.6) que já mora nele; a política de senha vai para o `common`
porque passa a ter dois usuários reais (`authentication` e `settings`).

## Fora do código

- **Contrato da API → 1.0.9** (R0): a troca de senha revoga o `refreshToken`. Conta de teste
  `teste.claude.20261014@exemplo.com` criada com autorização (senha não guardada).
- **Avisar o outro desenvolvedor**: a B8 move a política de senha do `authentication`, mexe no
  `AppTopBar` e na `AlertsNotices` (feature 011).
- **Folha de confirmação ao sair**: melhoria futura (clarificação), fora desta feature.

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; `package_info_plus` + `AppInfoService`; política de senha e lista movidas (testes
   da 003 verdes); entidades, models, falhas, datasources e repositories do `settings`; fakes.
2. **US1 (tela e sair)**: usecases de conta, versão e logout; `SettingsController`; tela com cartão,
   seções e sair; convite do link direto; engrenagem escondida no `AppTopBar` e no Perfil; rotas.
3. **US2 (senha)**: `ChangePasswordUseCase`, `ChangePasswordController`, `ChangePasswordPage`.
4. **US3 (alertas)**: chave otimista; `AlertsNotices` → `/settings`.
5. **US4 (idioma)**: repositório local, usecases, folha e aplicação no `easy_localization`.
6. **US5 (privacidade e sobre)**: as duas telas.
7. **Polimento**: analyze, suíte, quickstart no aparelho, marcar B8.

Um commit por história.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Dependência nova `package_info_plus` | Mostrar a versão instalada (FR-023) sem ficar desatualizada | Constante no código fica diferente do `pubspec.yaml` a cada versão |
| Mover arquivos do `authentication` (feature fechada) | A regra de senha passa a ser usada por dois módulos | Copiar viola o Princípio II; importar o `authentication` viola o Princípio I |
