# Implementation Plan: Perfil

**Branch**: `012-perfil` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/012-perfil/spec.md`

**Base**: tarefa B7 do [tasks do produto](../../.specify/memory/tasks.md),
[plano do produto](../../.specify/memory/plan.md) §1.3, §4 e §5,
[especificação do produto](../../.specify/memory/specification.md) (RF-035, RF-036, RN-008),
[contrato da API](../../.specify/memory/api-contract.md) 1.0.8,
[constituição](../../.specify/memory/constitution.md), Figma "SafeNews — Perfil e Configurações
(redesign)" (quadros "Perfil — com conta (v4)" e "Perfil — visitante"), código das features
005, 007, 009, 010 e 011.

## Summary

Trocar as páginas provisórias de `/profile` e `/profile/edit` pelo perfil do redesign:

- **API conferida** ([R0](research.md#r0-conferência-no-servidor-real-portão-de-api)): perfil,
  edição, foto, totais de lidas/salvas/curtidas e módulos ✅. ⚠️ Qualquer troca de e-mail dá 500
  (bug, backend avisado) e o telefone não pode ser apagado.
- **Dados** ([R1](research.md#r1-módulo-profile-e-de-onde-vêm-os-dados)): módulo `profile` com
  `data`/`domain` próprios e um datasource para `/users/me`, foto, totais e módulos.
- **Perfil** ([R2](research.md#r2-carga-do-perfil-com-falha-parcial)–[R4](research.md#r4-atualizar-ao-voltar-à-aba-fr-007)):
  carga com falha parcial por área, conquistas calculadas no domínio, atualização ao voltar à
  aba ouvindo o roteador.
- **Edição** ([R5](research.md#r5-editar-perfil)–[R7](research.md#r7-foto)): validação local,
  envio só do que mudou, erros por campo, descarte com confirmação, foto com envio otimista,
  saudação do Início atualizada (`profileVersion`).
- **Listas** ([R8](research.md#r8-listas-de-lidas-e-curtidas-us4)): a lista de salvas da 010
  generalizada para lidas e curtidas, com rotas `/news/read` e `/news/liked`.
- **Conquistas e visitante** ([R9](research.md#r9-conquistas-ver-todas-e-visitante)):
  `/profile/achievements` e o convite.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**: já presentes: `dio` (via `ApiClient`, inclusive `patch` e
`postMultipart`), `fpdart`, `get_it`, `provider`, `go_router`, `easy_localization`,
`lucide_icons_flutter`; `ImageStorageService` (F0.5); `AccessibilityPreferencesNotifier` e
`context.colors` (F0.6). Nenhuma dependência nova.

**Storage**: nada novo (a cópia local da foto é apagada depois do envio).

**Testing**: `flutter_test`; `FakeHttpClientAdapter` no datasource; fakes de repository e de
`ImageStorageService`; widget tests com `pumpLocalized` e `GetIt` resetado. Offline.

**Target Platform**: Android e iOS.

**Project Type**: mobile-app

**Performance Goals**: perfil com números e conquistas em até 3 s (SC-001): os quatro pedidos
saem em paralelo.

**Constraints**: 48 dp/16 sp, rótulos, alto contraste e fonte até 200% (RNF-003/004, F0.6);
visitante nunca chama o serviço (RN-003); textos pt-BR/en-US; sem importar outros módulos
(plano §1.3).

**Scale/Scope**: módulo `profile` com ~20 arquivos novos (data, domain, presentation), ~45 chaves
de i18n, ajuste em 3 arquivos de `news` (lista generalizada), 1 de `common` e 1 de `shell`;
~12 arquivos de teste novos e ajustes nos de salvas.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Clean Architecture e módulos | `profile` ganha `data`→`domain`→`presentation`; controllers falam com usecases (e com o `ImageStorageService`, serviço de plataforma do `common`, permitido). Nada importa `news`, `activities`, `authentication` ou `notifications`: o perfil tem datasource próprio e navega por caminho. As listas de lidas/curtidas ficam no `news`, dono de `/users/me/news/*`. | ✅ |
| II. SOLID, DRY, KISS | A lista de salvas é generalizada em vez de copiada. A expressão do e-mail é copiada do `CredentialsValidator` (uma linha, com comentário): importar o `authentication` violaria o Princípio I, e movê-la para `common` mexeria numa feature fechada sem necessidade. | ✅ (justificado) |
| III. TDD | Testes antes do código para models, datasource, repository, conquistas, validador, usecases, controllers e páginas; os testes de salvas da 010 continuam verdes. | ✅ |
| IV. Stack e DI | Só pacotes já adotados; usecases e controllers registrados no `ProfileModule`. | ✅ |
| V. Erros tipados | `EmailInUseFailure`, `ProfileFieldFailure`, `AvatarTypeFailure` a partir de códigos em constantes; status por enum; mensagens por chave. | ✅ |
| Regras globais | Sem segredo (as contas de teste não estão no código); UI usa GetIt só para obter controllers/serviços. Mudança em `common` (`profileVersion`) e `shell` (`AppTopBar`) justificada ([R6](research.md#r6-saudação-atualizada-sc-003)) e com teste. | ✅ |

**Pós-design (Phase 1)**: reavaliado após o data-model e o contrato; sem desvio novo.

## Project Structure

### Documentation (this feature)

```text
specs/012-perfil/
├── spec.md
├── plan.md                       # este arquivo
├── research.md                   # R0–R10
├── data-model.md                 # entidades, conquistas, falhas, controllers, i18n
├── quickstart.md                 # testes + 16 passos no aparelho
├── contracts/
│   └── profile-api.md            # endpoints, rotas e interface do módulo
├── checklists/requirements.md
└── tasks.md                      # /speckit-tasks
```

### Source Code (`click_seguro_app/`)

```text
lib/
├── core/i18n/app_strings.dart                         # + bloco profile_* e news_read/liked_*
├── modules/common/services/user_session_service.dart  # + profileVersion
├── modules/shell/presentation/widgets/app_top_bar.dart# ouve profileVersion
├── modules/news/                                      # lista de salvas → NewsListKind (saved/read/liked)
│   ├── data/datasources/news_remote_data_source(_impl).dart · repositories/news_repository_impl.dart
│   ├── domain/entities/news_list_kind.dart (NOVO) · usecases/get_user_news_list_usecase.dart
│   └── presentation/controller/…saved… → user_news_list_controller · pages/… · routes/news_routes.dart
└── modules/profile/
    ├── profile_module.dart · profile.dart
    ├── data/
    │   ├── datasources/profile_remote_data_source(_impl).dart
    │   ├── models/profile_model.dart · news_counts_model.dart · activity_progress_model.dart
    │   └── repositories/profile_repository_impl.dart
    ├── domain/
    │   ├── entities/ (profile, news_counts, activity_progress, achievement, profile_update)
    │   ├── failures/profile_failures.dart
    │   ├── achievements_calculator.dart · validators/profile_form_validator.dart
    │   ├── repositories/profile_repository.dart
    │   └── usecases/ (get_profile, get_news_counts, get_activity_progress, update_profile, update_avatar, remove_avatar)
    └── presentation/
        ├── controller/profile_controller.dart · edit_profile_controller.dart · area_state.dart
        ├── extensions/achievement_presentation_extension.dart
        ├── pages/profile_page.dart · edit_profile_page.dart · achievements_page.dart
        ├── widgets/ profile_header_card · stat_tile · medal_card · achievements_section · profile_cta_card · guest_invite · photo_sheet
        └── routes/profile_routes.dart                 # + achievements
assets/translations/{pt-BR,en-US}.json

test/modules/profile/ (data, domain, presentation, fakes) · test/modules/news/ (ajustes) ·
test/modules/shell/presentation/app_top_bar_test.dart · test/modules/common/services/user_session_service_test.dart
```

**Structure Decision**: o `profile` vira um módulo completo nas três camadas; as listas ficam no
`news` (dono dos dados de notícia); as duas mudanças pequenas em `common` e `shell` resolvem a
saudação (SC-003).

## Fora do código

- **Contrato da API → 1.0.8**: perfil conferido; bug do e-mail (500) e telefone sem apagar.
  Feito junto com este plano.
- **Avisar o backend**: (1) `PATCH /users/me` com `email` dá 500 para qualquer valor; (2) não há
  como apagar o telefone (`null`/`""` recusados).
- **Avisar o outro desenvolvedor**: a B7 generaliza a lista de salvas da feature 010
  ([R8](research.md#r8-listas-de-lidas-e-curtidas-us4)) e mexe no `AppTopBar`.
- **Renumeração**: a feature passou de `011` para `012` (a `011` da `develop` é a A6).

## Ordem sugerida (para o `/speckit-tasks`)

1. **Base**: i18n; entidades, models, falhas; datasource e repository do `profile`; fakes.
2. **US1 (perfil)**: conquistas, usecases de leitura, `ProfileController`, página com cartão,
   números, medalhas, CTAs, convite do visitante, `/profile/achievements`, refresh ao voltar.
3. **US2 (editar)**: validador, `UpdateProfileUseCase`, `profileVersion` + `AppTopBar`,
   `EditProfileController`, página de edição.
4. **US3 (foto)**: usecases de foto, folha de opções, envio otimista, remover, permissão negada.
5. **US4 (listas)**: `NewsListKind`, generalização da lista de salvas, rotas `/news/read` e
   `/news/liked`, números do perfil abrindo as listas.
6. **Polimento**: analyze, suíte, quickstart no aparelho, marcar B7.

Um commit por história.

## Complexity Tracking

Nenhuma violação. A expressão do e-mail copiada está justificada no Constitution Check.
