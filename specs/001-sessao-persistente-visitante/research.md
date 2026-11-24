# Research: Sessão persistente com modo visitante

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-09-26

Todas as incógnitas do Technical Context foram resolvidas abaixo. Não resta nenhum
NEEDS CLARIFICATION.

## R1. Versões das dependências (F0.1)

- **Decision**: adicionar agora as seis dependências da v1, com as versões que o
  `flutter pub add --dry-run` resolveu para Flutter 3.47.5 / Dart ^3.11.3:
  `flutter_secure_storage: ^11.2.0`, `flutter_tts: ^4.2.5`, `url_launcher: ^6.3.2`,
  `share_plus: ^13.3.0`, `image_picker: ^1.2.3`, `path_provider: ^2.1.6`. O `pubspec.lock`
  versionado trava as versões exatas.
- **Rationale**: o [plan do produto §6](../../.specify/memory/plan.md) decidiu que todas as
  dependências entram na Fase 0, para que as trilhas A e B não disputem o `pubspec.yaml`. A
  justificativa de cada pacote (Seção IV da constituição) já está no plan do produto.
- **Alternatives considered**: adicionar só o `flutter_secure_storage` agora. Rejeitado porque
  obrigaria as trilhas a mexer no `pubspec.yaml` depois, que é o maior ponto de conflito.

## R2. Formato da sessão guardada

- **Decision**: um único registro JSON (`SessionRecord`) sob a chave `session` no armazenamento
  seguro, com `status` (`authenticated` | `guest`), `token`, `userId` e `userName`. O estado
  "desconectado" é a **ausência** do registro. Ver [data-model.md](data-model.md).
- **Rationale**: uma escrita por mudança de estado é atômica. Não existe o caso de ter o token
  salvo sem o nome, ou a marca de visitante junto com um token (FR-003, FR-012). Com um único
  valor, a detecção de dado corrompido (FR-014) também fica trivial: não parseou, apaga.
- **Alternatives considered**:
  - Chaves separadas (`token`, `userId`, `userName`, `isGuest`): gera estados parciais se o app
    morrer no meio das escritas.
  - Marca de visitante no `shared_preferences`: separa num lugar diferente algo que é da sessão
    e cria duas fontes de verdade.

## R3. Contrato do `SecureStorageService`

- **Decision**: contrato genérico por chave (`read(key)`, `write(key, value)`, `delete(key)`),
  com uma implementação sobre `flutter_secure_storage`. Quem conhece o formato da sessão é o
  `UserSessionService`, não o storage.
- **Rationale**: o plan do produto previa `readToken`/`writeToken`/`clear`. Com o registro único
  (R2), um contrato genérico por chave é mais simples e reaproveitável. O plan do produto §3.3
  foi atualizado com essa mudança.
- **Alternatives considered**: métodos específicos de token. Rejeitado porque acopla o storage
  ao formato da sessão e teria de mudar a cada campo novo.

## R4. `UserSessionService`: interface ou classe concreta

- **Decision**: continua **classe concreta**, recebendo `SecureStorageService` pelo construtor.
  Nos testes, usa-se a classe real com `FakeSecureStorageService`.
- **Rationale**: a constituição (Seção II) pede interface quando há mais de uma implementação
  possível. Aqui só existe uma, e quem precisa ser trocado nos testes é o storage de plataforma,
  que já está atrás de uma interface. KISS.
- **Alternatives considered**: `UserSessionServiceInterface` + `Impl`. Rejeitado porque seria
  uma abstração sem segundo caso de uso.

## R5. Ordem "memória primeiro, disco depois"

- **Decision**: toda transição atualiza os campos em memória e o `sessionStatus` **antes** de
  aguardar a escrita no storage. Se a escrita falhar, o estado em memória vale para a sessão
  atual e o erro não sobe para a UI. O próximo `restoreSession` corrige, porque um registro
  ausente ou corrompido vira desconectado.
- **Rationale**: o `ApiClient` chama o encerramento por 401 de dentro de um fluxo síncrono de
  erro. A UI precisa reagir na hora (FR-004), sem depender do disco.
- **Alternatives considered**: persistir e só então notificar. Rejeitado porque atrasa a UI e,
  se o disco falhar, deixa o app num estado indefinido.

## R6. Motivo do encerramento e 401 durante o login

- **Decision**: enum `SessionEndReason { userLogout, expired }`, exposto em
  `UserSessionService.endReason` e atribuído **antes** de o `sessionStatus` notificar. Dois
  métodos públicos: `logout()` (motivo `userLogout`) e `expire()` (motivo `expired`). O
  `expire()` só age se o status atual for `authenticated`; em qualquer outro estado não faz
  nada. O `ApiClient` passa a chamar `expire()` num 401, no lugar de `logout()`.
- **Rationale**: FR-012a exige comportamentos diferentes conforme o motivo. A regra do
  `expire()` evita que um 401 de **senha errada** no login (quando ainda não há sessão) mostre o
  aviso de "sessão expirada".
- **Alternatives considered**:
  - Um estado extra `expired` no enum de status: rejeitado porque a spec fixa três estados
    (FR-003) e o motivo é um atributo do encerramento, não um estado.
  - Um stream de eventos separado: rejeitado porque o `ValueNotifier` já existente, mais um
    getter, basta.

## R7. Validação da sessão na abertura (FR-008)

- **Decision**: **desligada nesta feature**. O `restoreSession()` só lê o registro local. Não
  entra nenhum código de validação (nem flag) até o contrato da API confirmar o endpoint.
- **Rationale**: é a premissa registrada na spec. Uma flag para código que não existe viola o
  KISS (Seção II). A validação entra numa feature própria, junto com a possível renovação de
  credencial (esclarecimento Q1).
- **Alternatives considered**: implementar agora contra o endpoint proposto (`GET /users/me`).
  Rejeitado porque o contrato não está confirmado e o guia exige o Passo 0 antes da camada data.

## R8. Onde chamar `restoreSession()`

- **Decision**: no `_setup()` do `main.dart`, logo depois do `registerModules` e antes do
  `runApp`, com `await`. Qualquer exceção dentro dele resulta em desconectado (FR-014), nunca em
  crash.
- **Rationale**: é o que o plan do produto §3.1 define, e garante que a primeira tela (decidida
  pela tarefa A1) já encontre o estado certo (FR-002). O splash atual já espera pelo menos 2 s,
  então a leitura (milissegundos) cabe com folga no SC-002.
- **Alternatives considered**: restaurar dentro do `CommonModule.registerServices`. Rejeitado
  porque o registro de dependências não deveria executar lógica de negócio.

## R9. Token fora dos logs (FR-010 / SC-006)

- **Decision**: no `ApiClient`, o `LogInterceptor` passa a usar `requestHeader: false`. Os
  headers de request (onde está o `Authorization: Bearer ...`) deixam de ser impressos, mesmo
  com `DEBUG_MODE=true`. O corpo das respostas continua no log.
- **Rationale**: hoje, com `requestHeader: true`, o token aparece inteiro no console em debug, o
  que viola o RNF-007. É a correção mínima.
- **Alternatives considered**: um interceptor próprio que mascara só o `Authorization`.
  Rejeitado por ora porque é mais código sem necessidade demonstrada. Se alguém precisar ver
  os headers para depurar, vira melhoria à parte.
- **Observação**: o corpo da resposta de `/auth/login` conterá o token. A tarefa A2 MUST tratar
  isso (não logar o corpo dessa rota). Fica registrado como risco para a A2 no plan.

## R10. Android: backup automático e preparação de plataforma

- **Decision**: no `AndroidManifest.xml` principal:
  - `android:allowBackup="false"` no `<application>`;
  - `<uses-permission android:name="android.permission.INTERNET"/>`;
  - `<queries>` para `tel:` e `https:`;
  - **sem** permissão `CAMERA`: o `image_picker` abre a câmera do sistema via intent e não
    precisa dela. Se a permissão for declarada no manifest sem ser pedida em tempo de execução,
    o Android bloqueia a captura com `SecurityException`.

  No iOS (`Info.plist`): `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` e
  `LSApplicationQueriesSchemes` (`tel`, `https`). O `minSdk` fica como está: o
  `flutter_secure_storage` 11 exige 24, que já é o padrão do Flutter 3.47.
- **Rationale**: o README do `flutter_secure_storage` avisa que o backup do Android para o Google
  Drive causa `InvalidKeyException: Failed to unwrap key` ao restaurar. Desligar o backup
  resolve e é coerente com a privacidade do produto (RNF-008): contatos e fotos também não vão
  para a nuvem. A permissão de internet falta hoje no manifest principal (só existe em debug),
  e sem ela o build de release não acessa a API (FR-015).
- **Alternatives considered**: regras de backup que excluem só o arquivo do secure storage.
  Rejeitado porque é mais configuração e não traz ganho, já que o produto não quer backup de
  dados pessoais em nuvem. O FR-014 continua cobrindo qualquer leitura inválida.

## R11. `LocalCacheService` (F0.3)

- **Decision**: contrato `readJson(key)` / `writeJson(key, Map)` / `remove(key)` sobre
  `SharedPreferences`, registrado no `CommonModule`, que passa a obter a instância com
  `await SharedPreferences.getInstance()`. Esta feature não usa esse serviço. Ele entra por ser
  parte da F0.3 e será usado pelas trilhas (cache do feed, contatos, acessibilidade).
- **Rationale**: evita que cada trilha crie o seu wrapper de `shared_preferences`. O
  `OnboardingModule` continua como está, porque mexer nele não faz parte desta feature.
- **Alternatives considered**: adiar o `LocalCacheService` para a primeira feature que o usar.
  Rejeitado porque a Fase 0 existe para fechar o `common/` antes das trilhas.

## R12. Estratégia de testes

- **Decision**:
  - Fakes compartilhados em `test/fakes/`: `FakeSecureStorageService` (mapa em memória, com
    opção de falhar na leitura ou na escrita) e `FakeLocalCacheService`.
  - Testes do `UserSessionService` com a classe real e o fake.
  - Testes das implementações de plataforma com os mocks oficiais dos pacotes:
    `FlutterSecureStorage.setMockInitialValues` e `SharedPreferences.setMockInitialValues`.
  - Ajuste do `api_client_test.dart` (401 → `expire()`, e senha errada sem sessão não gera
    aviso).
- **Rationale**: é o padrão do guia de integração (Fakes à mão, sem Mockito) e da Seção III da
  constituição (testes determinísticos e offline, `GetIt` resetado por teste).
- **Alternatives considered**: mocktail. Rejeitado porque o guia proíbe explicitamente.
