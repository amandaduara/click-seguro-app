---

description: "Task list for feature 001: sessão persistente com modo visitante"
---

# Tasks: Sessão persistente com modo visitante

**Input**: Design documents from `/specs/001-sessao-persistente-visitante/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/session-and-storage.md](contracts/session-and-storage.md),
[quickstart.md](quickstart.md)

**Tests**: **obrigatórios.** A constituição (Seção III, TDD não negociável) exige que todo teste
seja escrito e **falhe** antes da implementação correspondente. Os testes usam Fakes à mão (sem
Mockito/mocktail), rodam offline e resetam o `GetIt` no `tearDown`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Caminhos relativos à raiz do repositório. O app fica em `click_seguro_app/`, e os comandos
  `flutter` rodam dentro dessa pasta.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dependências e preparação de plataforma (tarefa F0.1 do produto, FR-015,
[research R1/R9/R10](research.md)).

- [X] T001 Adicionar ao `click_seguro_app/pubspec.yaml`, em `dependencies`, com estas restrições exatas: `flutter_secure_storage: ^11.2.0`, `flutter_tts: ^4.2.5`, `url_launcher: ^6.3.2`, `share_plus: ^13.3.0`, `image_picker: ^1.2.3`, `path_provider: ^2.1.6`. Rodar `flutter pub get` dentro de `click_seguro_app/` e versionar o `pubspec.lock` atualizado
- [X] T002 [P] Em `click_seguro_app/android/app/src/main/AndroidManifest.xml`:
  - adicionar `<uses-permission android:name="android.permission.INTERNET"/>` antes de `<application>`. **Não** declarar `CAMERA`: o `image_picker` usa a câmera do sistema via intent, e declarar a permissão sem pedi-la em tempo de execução faz a captura falhar (research R10);
  - adicionar `android:allowBackup="false"` na tag `<application>`;
  - dentro do `<queries>` existente, adicionar `<intent>` com `ACTION_DIAL`/`data android:scheme="tel"` e `<intent>` com `ACTION_VIEW`/`data android:scheme="https"`;
  - não alterar o `minSdk` (Flutter 3.47 já usa 24, exigido pelo `flutter_secure_storage` 11).
- [X] T003 [P] Em `click_seguro_app/ios/Runner/Info.plist`, adicionar `NSCameraUsageDescription` ("Usamos a câmera para tirar a foto dos seus contatos de confiança."), `NSPhotoLibraryUsageDescription` ("Usamos suas fotos para a imagem dos seus contatos de confiança.") e `LSApplicationQueriesSchemes` com os itens `tel` e `https`
- [X] T004 [P] Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, trocar `requestHeader: true` por `requestHeader: false` no `LogInterceptor`, para o header `Authorization: Bearer ...` nunca ir para o log (FR-010, research R9). Não alterar mais nada nesta tarefa

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: storages de plataforma atrás de interface, os fakes e o esqueleto do
`UserSessionService` injetável (F0.3, [contracts](contracts/session-and-storage.md)).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Testes (escrever primeiro e ver falhar)

- [X] T005 [P] Criar `click_seguro_app/test/modules/common/services/secure_storage_service_test.dart` testando o `FlutterSecureStorageService` com `FlutterSecureStorage.setMockInitialValues({})`: `write` seguido de `read` devolve o valor; `read` de chave inexistente devolve `null`; `delete` remove só a chave pedida (outra chave continua)
- [X] T006 [P] Criar `click_seguro_app/test/modules/common/services/local_cache_service_test.dart` testando o `SharedPreferencesLocalCacheService` com `SharedPreferences.setMockInitialValues({})`:
  - `writeJson` seguido de `readJson` devolve o mesmo `Map`;
  - chave inexistente → `null`;
  - valor que não é objeto JSON (ex.: string `"abc"` gravada direto) → `null`, sem exceção;
  - `remove` apaga a chave.

### Implementação

- [X] T007 [P] Criar `click_seguro_app/lib/modules/common/services/secure_storage_service.dart` com `abstract class SecureStorageService { Future<String?> read(String key); Future<void> write(String key, String value); Future<void> delete(String key); }` e `class FlutterSecureStorageService implements SecureStorageService`, que recebe um `FlutterSecureStorage` opcional pelo construtor (padrão `const FlutterSecureStorage()`) e delega a ele (faz T005 passar)
- [X] T008 [P] Criar `click_seguro_app/lib/modules/common/services/local_cache_service.dart` com `abstract class LocalCacheService { Future<Map<String, dynamic>?> readJson(String key); Future<void> writeJson(String key, Map<String, dynamic> value); Future<void> remove(String key); }` e `class SharedPreferencesLocalCacheService implements LocalCacheService`, que recebe `SharedPreferences` pelo construtor, grava com `jsonEncode` e lê com `jsonDecode`, devolvendo `null` quando o valor não existe ou não é um objeto JSON (faz T006 passar)
- [X] T009 [P] Criar `click_seguro_app/test/fakes/fake_secure_storage_service.dart`: `class FakeSecureStorageService implements SecureStorageService`, com `final Map<String, String> values`, flags `bool failOnRead = false` e `bool failOnWrite = false` (lançam `Exception` em `read` e em `write`/`delete`, respectivamente), e contadores `readCalls`, `writeCalls` e `deleteCalls`
- [X] T010 [P] Criar `click_seguro_app/test/fakes/fake_local_cache_service.dart`: `class FakeLocalCacheService implements LocalCacheService`, com um `Map<String, Map<String, dynamic>>` em memória e o contador `writeCalls`
- [X] T011 Em `click_seguro_app/lib/modules/common/services/user_session_service.dart`:
  - adicionar `enum SessionEndReason { userLogout, expired }`;
  - adicionar o valor `guest` ao `UserSessionStatus` (fica `authenticated, guest, unauthenticated`);
  - o construtor passa a receber `SecureStorageService` (`UserSessionService(this._storage)`);
  - adicionar `static const String storageKey = 'session';` e os campos `String? userName` e `SessionEndReason? endReason`.

  Manter por enquanto os métodos atuais (`saveSession`, `logout`) funcionando em memória, para
  não quebrar a compilação.
- [X] T012 Em `click_seguro_app/lib/modules/common/common_module.dart`, tornar `registerServices` `async` e registrar:
  - `registerLazySingleton<SecureStorageService>(() => FlutterSecureStorageService())`;
  - `final prefs = await SharedPreferences.getInstance();`;
  - `registerLazySingleton<LocalCacheService>(() => SharedPreferencesLocalCacheService(prefs))`;
  - `registerLazySingleton(() => UserSessionService(injector<SecureStorageService>()))`, mantendo o `ApiClient`.
- [X] T013 Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, trocar `UserSessionService()` por `UserSessionService(FakeSecureStorageService())` no `setUp` e ajustar o que for preciso para compilar. Rodar `flutter test` e confirmar que os 13 testes existentes continuam verdes

**Checkpoint**: `flutter analyze` sem erros e `flutter test` verde. Storages e fakes prontos.

---

## Phase 3: User Story 1 - Continuar conectado depois de fechar o app (Priority: P1) 🎯 MVP

**Goal**: a sessão conectada é gravada no armazenamento seguro e restaurada na abertura, antes da
primeira tela (FR-001, FR-002, FR-011, FR-014).

**Independent Test**: em `user_session_service_test.dart`, criar um `UserSessionService` com um
`FakeSecureStorageService`, chamar `saveSession`, criar um **segundo** `UserSessionService` com
o **mesmo** fake (simula fechar e reabrir), chamar `restoreSession()` e verificar o estado
`authenticated` com o mesmo `token`, `userId` e `userName`.

### Tests for User Story 1 ⚠️

> **Escrever primeiro e garantir que FALHEM antes da T015**

- [X] T014 [US1] Criar `click_seguro_app/test/modules/common/services/user_session_service_test.dart`, com `group('US1 persistência e restauração')` e os casos abaixo:
  - **(a) Grava o registro:** `saveSession(token: 't', userId: 'u', userName: 'Maria')` grava em `storageKey` o JSON `{"status":"authenticated","token":"t","userId":"u","userName":"Maria"}`.
  - **(b) Restaura:** um novo serviço com o mesmo fake, após `restoreSession()`, fica `authenticated` com os mesmos campos e `endReason == null`.
  - **(c) Sem registro:** `restoreSession()` → `unauthenticated`, sem exceção.
  - **(d) Registro inválido é apagado:** cada caso a seguir resulta em `unauthenticated` e em `delete(storageKey)` chamado:
    - JSON inválido (`'{abc'`);
    - `status` desconhecido (`{"status":"admin"}`);
    - `authenticated` sem `token`;
    - `authenticated` sem `userId`.
  - **(e) Falha de leitura:** com `failOnRead = true`, `restoreSession()` → `unauthenticated` e não lança (FR-014).
  - **(f) Falha de escrita:** com `failOnWrite = true`, `saveSession` não lança e o estado em memória fica `authenticated` (research R5).
  - **(g) Ordem da notificação:** um listener em `sessionStatus` lê `token`, `userId` e `userName` já preenchidos no momento da notificação (FR-004).
  - **(h) Argumento vazio:** `saveSession` com `token: ''` ou `userId: ''` lança `ArgumentError`.
  - **(i) Troca de conta:** `saveSession` da conta A seguido de `saveSession` da conta B deixa gravado e em memória só a B.

### Implementation for User Story 1

- [X] T015 [US1] Em `click_seguro_app/lib/modules/common/services/user_session_service.dart`, implementar conforme o [data-model.md](data-model.md):
  - `Future<void> saveSession({required String token, required String userId, String? userName})`:
    1. valida os argumentos não vazios (`ArgumentError`);
    2. atualiza os campos e `endReason = null`;
    3. muda `sessionStatus` para `authenticated`;
    4. grava o registro com `jsonEncode` num `try/catch` que engole a falha.
  - `Future<void> restoreSession()`:
    - lê `storageKey` num `try/catch`;
    - valida as regras do SessionRecord: `status` ∈ {`authenticated`, `guest`}; `authenticated` exige `token` e `userId` não vazios; `guest` não pode ter `token`;
    - registro inválido → `delete` (num `try/catch`) e `unauthenticated`;
    - **nunca lança**.
  - Getter `isAuthenticated` baseado em `sessionStatus`.

  Faz T014 passar.
- [X] T016 [US1] Em `click_seguro_app/lib/main.dart`, dentro de `_setup()`, depois de `registerModules(...)` e antes do `return`, adicionar `await GetIt.instance<UserSessionService>().restoreSession();`, com os imports correspondentes (FR-002, research R8)

**Checkpoint**: US1 funcional e testada de forma independente (MVP da feature).

---

## Phase 4: User Story 2 - Usar o app como visitante (Priority: P2)

**Goal**: estado "visitante" persistido e lembrado entre aberturas, e substituído ao entrar com
uma conta (FR-003, FR-005, FR-006, FR-007).

**Independent Test**: chamar `startGuestSession()`, criar um segundo serviço com o mesmo fake,
chamar `restoreSession()` e verificar `guest`/`isGuest == true`.

### Tests for User Story 2 ⚠️

- [X] T017 [US2] Em `click_seguro_app/test/modules/common/services/user_session_service_test.dart`, adicionar `group('US2 visitante')` com os casos:
  - **(a)** `startGuestSession()` grava exatamente `{"status":"guest"}` e deixa `sessionStatus == guest`, `isGuest == true`, `token == null`.
  - **(b)** Um novo serviço com o mesmo fake, após `restoreSession()`, fica `guest`.
  - **(c)** `saveSession(...)` a partir de `guest` → `authenticated`, com o registro gravado sem `"status":"guest"` e `isGuest == false` (FR-007).
  - **(d)** Registro `{"status":"guest","token":"x"}` é inválido: apaga e fica `unauthenticated`.
  - **(e)** Com `failOnWrite = true`, `startGuestSession()` não lança e fica `guest` em memória.

### Implementation for User Story 2

- [X] T018 [US2] Em `click_seguro_app/lib/modules/common/services/user_session_service.dart`, implementar `Future<void> startGuestSession()`: zera `token`/`userId`/`userName`, faz `endReason = null`, muda `sessionStatus` para `guest` e grava `{"status":"guest"}` (falha engolida). Adicionar o getter `bool get isGuest => sessionStatus.value == UserSessionStatus.guest`. Garantir que o `restoreSession` da T015 aceita o registro `guest` (faz T017 passar)

**Checkpoint**: US1 e US2 funcionam de forma independente.

---

## Phase 5: User Story 3 - Encerrar a sessão com segurança (Priority: P3)

**Goal**: encerrar pelo usuário (`logout`) ou por recusa do serviço (`expire`), com o motivo
registrado e sem apagar dados do aparelho (FR-008a, FR-012, FR-012a, FR-013).

**Independent Test**: com a sessão ativa, chamar `logout()` e verificar o registro apagado,
os campos nulos, `unauthenticated` e `endReason == userLogout`, e que outra chave do fake
continua intacta. Repetir com `expire()` esperando `expired`.

### Tests for User Story 3 ⚠️

- [X] T019 [P] [US3] Em `click_seguro_app/test/modules/common/services/user_session_service_test.dart`, adicionar `group('US3 encerramento')` com os casos:
  - **(a)** `logout()` a partir de `authenticated` → `unauthenticated`, `token`/`userId`/`userName` nulos, `endReason == SessionEndReason.userLogout` e `delete(storageKey)` chamado.
  - **(b)** `logout()` a partir de `guest` → `unauthenticated` e `userLogout`.
  - **(c)** `expire()` a partir de `authenticated` → `unauthenticated` e `endReason == SessionEndReason.expired`.
  - **(d)** `expire()` a partir de `guest` e de `unauthenticated` não muda nada (nem estado, nem `endReason`, nem storage).
  - **(e)** Com uma chave extra `'outra'` no fake, `logout()` e `expire()` a mantêm (FR-013).
  - **(f)** Após `expire()`, um novo `saveSession` volta `endReason` a `null`.
  - **(g)** Listener de `sessionStatus` já lê o `endReason` preenchido na notificação.
  - **(h)** Com `failOnWrite = true`, `logout()` não lança e o estado em memória fica `unauthenticated`.
- [X] T020 [P] [US3] Em `click_seguro_app/test/modules/common/api_client/api_client_test.dart`, ajustar o teste de 401:
  - com a sessão `authenticated` (via `saveSession`), um 401 deixa `unauthenticated` e `endReason == SessionEndReason.expired`;
  - novo teste: um 401 **sem** sessão (`unauthenticated`, como num login com senha errada) mantém `endReason == null`.

### Implementation for User Story 3

- [X] T021 [US3] Em `click_seguro_app/lib/modules/common/services/user_session_service.dart`, implementar:
  - `Future<void> logout()`: zera os campos, `endReason = SessionEndReason.userLogout`, `sessionStatus` → `unauthenticated` e `delete(storageKey)` num `try/catch`;
  - `Future<void> expire()`: só age se `sessionStatus.value == authenticated`, com o mesmo efeito, mas `endReason = SessionEndReason.expired`;
  - em ambos, os campos e o `endReason` são atribuídos **antes** de mudar o `sessionStatus`;
  - nenhum dos dois toca em outra chave.

  Faz T019 passar.
- [X] T022 [US3] Em `click_seguro_app/lib/modules/common/api_client/api_client.dart`, no `_mapBadResponse`, trocar `GetIt.instance<UserSessionService>().logout();` por `unawaited(GetIt.instance<UserSessionService>().expire());` (import `dart:async`). Em `click_seguro_app/lib/core/errors/unauthorized_failure.dart`, atualizar o comentário para citar `expire()` (faz T020 passar)

**Checkpoint**: as três histórias funcionam de forma independente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: validação final e documentação.

- [X] T023 Rodar `flutter analyze` e `flutter test` em `click_seguro_app/`. Resultado esperado: zero erros ou warnings novos e todos os testes verdes. Corrigir o que falhar antes de seguir
- [X] T024 [P] Em `.specify/memory/tasks.md` (mapa do produto), marcar F0.1, F0.3 e F0.4 como `[x]`, acrescentando `(specs/001-sessao-persistente-visitante)`. Na F0.4, registrar que a validação na abertura (`GET /users/me`) e a renovação de credencial ficaram pendentes do contrato da API
- [X] T025 Executar as seções 2 e 3 do [quickstart.md](quickstart.md) no aparelho físico:
  - auditoria do log com `DEBUG_MODE=true`: nenhuma ocorrência de `Bearer`/`Authorization` (SC-006);
  - `flutter build apk --release` + `flutter install`: o app abre sem erro (FR-015).

  Registrar o resultado no PR.

  **Resultado (2026-10-03, SM S921B / Android 16):**
  - Build de release (49 MB) instalado e aberto sem erro (sem `FATAL` no logcat).
  - `INTERNET: granted=true` e `ALLOW_BACKUP` ausente das flags do pacote.
  - Auditoria de log: estática, porque ainda não há `API_URL` para uma chamada autenticada real. O único logger de rede é o `LogInterceptor`, com `requestHeader: false`. Repetir a auditoria dinâmica com `DEBUG_MODE=true` quando a A2 fizer a primeira chamada autenticada.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências. T001 deve terminar antes de T007 (o pacote precisa estar instalado).
- **Foundational (Phase 2)**: depende de T001. **Bloqueia** todas as histórias.
  - T005/T006 (testes) antes de T007/T008 (implementação).
  - T011 depende de T007 e T009.
  - T012 depende de T007, T008 e T011.
  - T013 depende de T009 e T011.
- **US1 (Phase 3)**: depende da Phase 2. T014 → T015 → T016.
- **US2 (Phase 4)**: depende da Phase 2. Na prática, depois de T015, porque estende o mesmo `restoreSession` e o mesmo arquivo.
- **US3 (Phase 5)**: depende da Phase 2. T021 usa os campos da T011 e não depende da US2. T022 depende de T004 (mesmo arquivo) e de T021.
- **Polish (Phase 6)**: depende de todas as histórias.

### User Story Dependencies

- **US1 (P1)**: independente, depois da Phase 2.
- **US2 (P2)**: testável de forma independente, mas compartilha `user_session_service.dart` com a US1. Fazer em sequência, depois da US1.
- **US3 (P3)**: testável de forma independente. Compartilha arquivos com a US1/US2, então também vai em sequência.

### Within Each User Story

- Testes escritos e **falhando** antes da implementação (constituição, Seção III).
- Serviço antes da integração (`main.dart`, `ApiClient`).
- Commit ao fim de cada história. Com o hook do Spec Kit ligado, `/speckit-git-commit` gera a mensagem conventional.

### Parallel Opportunities

- **Phase 1:** T002, T003 e T004 em paralelo, depois da T001, porque são arquivos diferentes.
- **Phase 2:** T005 e T006 (testes) em paralelo; depois T007, T008, T009 e T010 em paralelo.
- **Phase 5:** T019 e T020 (testes em arquivos diferentes) em paralelo.
- As histórias **não** rodam em paralelo entre si, porque todas mexem em `user_session_service.dart`. É uma feature pequena, pensada para uma pessoa.

---

## Parallel Example: Phase 2

```bash
# Testes dos storages, juntos:
Task: "Teste do FlutterSecureStorageService em click_seguro_app/test/modules/common/services/secure_storage_service_test.dart"
Task: "Teste do SharedPreferencesLocalCacheService em click_seguro_app/test/modules/common/services/local_cache_service_test.dart"

# Depois, implementações e fakes, juntos:
Task: "SecureStorageService em click_seguro_app/lib/modules/common/services/secure_storage_service.dart"
Task: "LocalCacheService em click_seguro_app/lib/modules/common/services/local_cache_service.dart"
Task: "FakeSecureStorageService em click_seguro_app/test/fakes/fake_secure_storage_service.dart"
Task: "FakeLocalCacheService em click_seguro_app/test/fakes/fake_local_cache_service.dart"
```

## Parallel Example: User Story 3

```bash
Task: "Testes de logout/expire em click_seguro_app/test/modules/common/services/user_session_service_test.dart"
Task: "Teste de 401 → expire em click_seguro_app/test/modules/common/api_client/api_client_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 (Setup) → Phase 2 (Foundational).
2. Phase 3 (US1): a sessão conectada sobrevive ao fechamento.
3. **PARAR e VALIDAR**: `flutter test` verde. A A2 (login) já pode começar a usar `saveSession`.

### Incremental Delivery

1. Setup + Foundational → base pronta (os storages já servem às trilhas).
2. US1 → sessão persistente (desbloqueia A1/A2).
3. US2 → visitante (desbloqueia "Entrar como visitante" na A2).
4. US3 → encerramento e 401 (desbloqueia F0.9 e B8).
5. Polish → PR para `develop`.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- [USn] mapeia a tarefa para a história da [spec](spec.md).
- Verifique que o teste falha antes de implementar.
- Não implemente a validação na abertura nem a renovação de credencial: estão fora desta feature ([research R7](research.md), esclarecimento Q1).
- Evite mexer em `OnboardingModule`, `splash` ou `authentication`: pertencem às tarefas A1/A2.
