# Implementation Plan: Sessão persistente com modo visitante

**Branch**: `001-sessao-persistente-visitante` | **Date**: 2026-09-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-sessao-persistente-visitante/spec.md`

**Base**: [plan do produto](../../.specify/memory/plan.md) §3.1 (sessão) e §3.3 (serviços de
plataforma), [guia de integração](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md) e
[constituição](../../.specify/memory/constitution.md) v1.1.0.

## Summary

Tornar a sessão persistente e com três estados (conectado, visitante, desconectado), guardando
um único registro JSON no armazenamento seguro do aparelho. O `UserSessionService` passa a
receber um `SecureStorageService` (interface + implementação sobre `flutter_secure_storage` +
fake para teste), a restaurar a sessão no `_setup()` antes do `runApp` e a registrar o motivo do
encerramento (`userLogout` / `expired`). Com esse motivo, as próximas tarefas decidem entre ir ao
login ou mostrar o aviso de sessão expirada. Entram também:

- as dependências da v1 e a preparação de Android/iOS (F0.1);
- o `LocalCacheService` para as trilhas (F0.3);
- duas correções no `ApiClient`: 401 → `expire()`, e token fora do log.

## Technical Context

**Language/Version**: Dart ^3.11.3 · Flutter 3.47.5 (stable)

**Primary Dependencies**:
- já presentes: `get_it`, `dio`, `provider`, `shared_preferences`, `fpdart`;
- novas: `flutter_secure_storage ^11.2.0` (usada aqui). Também entram agora, para uso futuro das
  trilhas (F0.1): `flutter_tts ^4.2.5`, `url_launcher ^6.3.2`, `share_plus ^13.3.0`,
  `image_picker ^1.2.3` e `path_provider ^2.1.6` ([research R1](research.md)).

**Storage**: armazenamento seguro do aparelho (Keystore/Keychain via `flutter_secure_storage`)
para o registro da sessão; `shared_preferences` atrás do `LocalCacheService` (sem uso nesta
feature).

**Testing**: `flutter_test` com Fakes à mão em `test/fakes/`, `GetIt.instance.reset()` no
`tearDown`, e mocks oficiais dos pacotes para as implementações de plataforma
([research R12](research.md)).

**Target Platform**: Android (minSdk 24, padrão do Flutter 3.47) e iOS. O alvo principal de
teste é um Android físico.

**Project Type**: mobile-app (Flutter, módulos por feature: `lib/modules/<modulo>/`).

**Performance Goals**: restaurar a sessão em menos de 100 ms, dentro dos 2 s mínimos do splash.
Primeira tela útil em até 3 s (SC-002).

**Constraints**:
- funciona offline (a restauração não usa a rede, FR-009);
- a credencial nunca aparece no log (FR-010);
- `restoreSession()` nunca lança (FR-014);
- o encerramento não apaga dados do aparelho (FR-013).

**Scale/Scope**: uma sessão por aparelho. São 3 serviços em `common/services/`, 1 enum novo,
2 fakes, cerca de 5 arquivos de teste e ajustes em `ApiClient`, `CommonModule`, `main.dart`,
`pubspec.yaml`, `AndroidManifest.xml` e `Info.plist`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Como esta feature cumpre | Status |
|---|---|---|
| **I. Clean Architecture & Modularização** | Tudo fica em `lib/modules/common/services/` (infra transversal), registrado no `CommonModule.registerServices`. Não cria camada de UI. Nenhum controller acessa o storage | ✅ |
| **II. SOLID, DRY, KISS** | O storage de plataforma fica atrás de interface (DIP), porque tem duas implementações: real e fake. O `UserSessionService` continua concreto, porque só tem uma ([R4](research.md)). A validação na abertura não entra, porque o endpoint não está confirmado ([R7](research.md)) | ✅ |
| **III. TDD** | Todo serviço tem teste antes da implementação: caminho feliz, erro (falha de storage, dado corrompido) e borda (`expire` sem sessão, troca de conta). Testes offline e `GetIt` resetado | ✅ |
| **IV. Stack e DI** | As dependências novas estão justificadas no plan do produto e têm versão explícita. `GetIt` é o único DI. A configuração continua no `EnvironmentConfig` | ✅ |
| **V. Erros tipados, sem strings mágicas** | `SessionEndReason` e `UserSessionStatus` são enums. A chave do storage é uma constante nomeada. O 401 continua centralizado no `ApiClient` | ✅ |
| **Segurança: segredo fora do código e dos logs** | Credencial só no armazenamento seguro. `LogInterceptor(requestHeader: false)` ([R9](research.md)) | ✅ |
| **Segurança: `late`/`!` só com justificativa** | O desenho não precisa de `!`: o registro é validado antes de preencher os campos | ✅ |
| **Segurança: dependência nova justificada** | Ver plan do produto, "Dependências novas" | ✅ |

**Pós-design (Phase 1):** reavaliado depois de escrever [data-model.md](data-model.md) e
[contracts/](contracts/session-and-storage.md). Nenhuma violação. A única mudança em relação ao
plan do produto (contrato genérico do `SecureStorageService`, [R3](research.md)) foi refletida
no plan do produto §3.3.

## Project Structure

### Documentation (this feature)

```text
specs/001-sessao-persistente-visitante/
├── spec.md
├── plan.md                         # este arquivo
├── research.md                     # decisões R1–R12
├── data-model.md                   # estados, registro persistido, transições
├── quickstart.md                   # como validar
├── contracts/
│   └── session-and-storage.md      # APIs Dart públicas consumidas por A1, A2, F0.9, B8
├── checklists/
│   └── requirements.md
└── tasks.md                        # gerado por /speckit-tasks
```

### Source Code (repository root)

```text
click_seguro_app/
├── pubspec.yaml                                    # + 6 dependências (F0.1)
├── android/app/src/main/AndroidManifest.xml        # INTERNET, câmera, queries tel/https, allowBackup=false
├── ios/Runner/Info.plist                           # câmera, galeria, LSApplicationQueriesSchemes
├── lib/
│   ├── main.dart                                   # _setup(): await restoreSession()
│   └── modules/common/
│       ├── common_module.dart                      # registra storages e UserSessionService(storage)
│       ├── api_client/api_client.dart              # 401 → expire(); LogInterceptor sem headers
│       └── services/
│           ├── secure_storage_service.dart         # NOVO: interface + FlutterSecureStorageService
│           ├── local_cache_service.dart            # NOVO: interface + SharedPreferencesLocalCacheService
│           └── user_session_service.dart           # guest, persistência, restore, endReason, expire
├── lib/core/errors/unauthorized_failure.dart       # só o comentário (logout → expire)
└── test/
    ├── fakes/
    │   ├── fake_secure_storage_service.dart        # NOVO
    │   └── fake_local_cache_service.dart           # NOVO
    └── modules/common/
        ├── services/
        │   ├── secure_storage_service_test.dart    # NOVO
        │   ├── local_cache_service_test.dart       # NOVO
        │   └── user_session_service_test.dart      # NOVO
        └── api_client/api_client_test.dart         # ajuste: sessão com fake; 401 → expire
```

**Structure Decision**: projeto Flutter único (`click_seguro_app/`), no padrão de módulos da
constituição. Tudo desta feature é infraestrutura compartilhada, por isso fica em
`lib/modules/common/`. Os fakes ficam em `test/fakes/` (e não dentro de um módulo) porque as
duas trilhas vão reutilizá-los.

## Impacto nas próximas tarefas

- **A1 (splash):** lê `sessionStatus` já restaurado, com `authenticated`/`guest` → `/home`.
- **A2 (login):** chama `saveSession(...)` e `startGuestSession()` pelo repository/usecase.
  **Risco herdado:** o corpo da resposta de login contém o token e o `LogInterceptor` loga
  corpos de resposta em debug. A A2 MUST evitar esse log nessa rota ([R9](research.md)).
- **F0.9 (shell):** usa `endReason` para decidir entre `/login` (`userLogout`) e o aviso de sessão
  expirada (`expired`).
- **B8 (configurações):** "Sair" chama `logout()`.

## Complexity Tracking

Sem violações da constituição. Nada a justificar.
