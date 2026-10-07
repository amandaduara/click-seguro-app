# Research: Serviços de plataforma e voz

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-07

Sem NEEDS CLARIFICATION no Technical Context: as três dúvidas da spec foram respondidas na
sessão de clarificação. As decisões abaixo saem da leitura dos pacotes nas versões travadas no
`pubspec.lock` (`flutter_tts` 4.2.5, `url_launcher` 6.3.2, `share_plus` 13.3.0, `image_picker`
1.2.3, `path_provider` 2.1.6), do plano do produto §3.3 e §5 e do código de `common/`.

## R1. Formato dos contratos: resultados tipados, nunca exceção

**Decision**: os quatro serviços seguem o padrão de `common/services/` (contrato abstrato +
implementação `Flutter*`/`Platform*` no mesmo arquivo), mas, ao contrário do
`SecureStorageService`, **nunca lançam**. Toda falha vira um valor que a tela entende:

| Serviço | Retorno |
|---|---|
| `TextToSpeechService.isAvailable` | `bool` |
| `TextToSpeechService.speak` | `bool` (`true` = leu até o fim; `false` = parado ou falhou) |
| `ExternalLauncherService.openUrl` / `call` / `canCall` | `bool` |
| `ShareService.shareText` | enum `ShareOutcome { shared, cancelled, failed }` |
| `ImageStorageService.pickImage` | sealed `PickImageResult` (`PickedImage(path)`, `PickImageCancelled`, `PickImagePermissionDenied`, `PickImageFailed`) |
| `ImageStorageService.delete` | `void` (ignora arquivo inexistente) |

**Rationale**: FR-017 e SC-003 pedem que nenhuma falha derrube a tela. Esses serviços não falam
com a API, então não há `ApiException` → `Failure` aqui (Princípio V vale para dados remotos).
Um `bool` basta onde a spec só distingue "abriu/não abriu". Onde há três ou mais casos, um enum
ou uma sealed class evita strings mágicas e permite `switch` exaustivo nas telas.

**Alternatives considered**: `Either<Failure, T>`. Rejeitado porque não há usecase nem
repository entre a tela e o serviço, e "cancelado" não é falha. Lançar exceção e deixar a tela
tratar foi rejeitado porque repetiria o `try/catch` em cada uma das cinco telas (DRY).

## R2. Voz: `flutter_tts` sem stream de estado

**Decision**: `FlutterTextToSpeechService` recebe um `FlutterTts` pelo construtor (padrão
`FlutterSecureStorageService([storage])`) e:

- `isAvailable(SpeechLanguage)` → `isLanguageAvailable('pt-BR' | 'en-US')`. `null`, `false` ou
  exceção resultam em `false`. Isso cobre "sem voz no idioma" e "sem mecanismo de voz" (CB-008).
- `speak(text, language, speed)` → `stop()` de qualquer leitura anterior, `setLanguage`,
  `setSpeechRate`, `speak`. O `Future` só termina quando a leitura acaba: um `Completer` é
  completado pelos handlers `setCompletionHandler` (→ `true`) e `setCancelHandler`/`setErrorHandler`
  (→ `false`). Exceção do canal → `false`.
- `stop()` → `stop()` do plugin, sem lançar.
- **Eventos atrasados**: ao interromper uma leitura para começar outra, o aviso de cancelamento
  da antiga pode chegar depois que a nova já foi pedida. Por isso, os avisos de fim e de
  cancelamento só valem para a leitura atual depois do `setStartHandler` dela. O erro vale
  sempre. Se o `speak` do plugin devolver `0` (falha), o resultado é `false` na hora.

O contrato **não** expõe o `isSpeaking` como stream (ao contrário do plano do produto §3.3). O
estado "lendo" vive no `ReadAloudController` ([R3](#r3-readaloudcontroller)), derivado do início
e do fim do `Future` de `speak`.

**Rationale**: o motor de voz é um só no aparelho. Se ele expusesse o estado, uma tela veria
como "lendo" a leitura de outra. Com o `Future` de `speak`, cada controller sabe quando a
leitura **dele** terminou. Os handlers do plugin são a única forma confiável de saber o fim nas
duas plataformas. O `awaitSpeakCompletion` não completa de forma consistente quando a leitura é
interrompida por `stop()`.

**Alternatives considered**: `Stream<bool> isSpeaking` no serviço, como no plano do produto.
Rejeitado pelo motivo acima e por exigir gerenciar inscrição. O §3.3 do plano do produto é
atualizado junto com este plano.

## R3. `ReadAloudController`

**Decision**: `ChangeNotifier` em `lib/modules/common/presentation/controller/`, que fala direto
com o `TextToSpeechService` (sem usecase). É registrado como **factory** no `CommonModule`:
cada página cria o seu com `ChangeNotifierProvider` e o `dispose` para a leitura (FR-006).

- `prepare(Locale)`: converte o idioma do app em `SpeechLanguage` e verifica a disponibilidade.
  O resultado é lembrado por idioma no próprio controller. Chamar de novo com outro idioma
  (troca nas configurações, cenário 9) verifica o novo idioma.
- `isAvailable` é `false` até a verificação terminar, para que o botão não apareça antes da
  hora (edge case "antes de saber se há voz").
- `speak(text)` ignora texto vazio ou só com espaços (FR-007) e também ignora a chamada quando a
  voz está indisponível. Se já estiver lendo, para antes. Um contador de geração descarta o fim
  de uma leitura antiga, para que ela não marque "parado" por cima da leitura nova (FR-005).
- `setSpeed(ReadingSpeed)` vale para a próxima leitura (cenário 7). Não interrompe a atual.
- `stop()` marca "parado" na hora e chama o serviço.

**Rationale**: o plano do produto §5 põe o controller em `common` para A5 e B2 não dependerem uma
da outra. Um usecase que só repassasse a chamada seria abstração vazia (Princípio II, como o
`requireAccount` da feature 005). Como factory, cada página tem o seu estado e o seu `dispose`.

**Alternatives considered**: um singleton global (a leitura sobreviveria à tela que a iniciou,
contra FR-006). O controller ler o idioma do `BuildContext` foi rejeitado porque o plano do
produto §5 proíbe `BuildContext` em controller. Quem chama `prepare(context.locale)` é a página.

## R4. Velocidades

**Decision**: enum `ReadingSpeed { slow, normal, fast }`, padrão `normal`. A conversão para o
valor do plugin fica só na implementação: `slow` = 0.4, `normal` = 0.5, `fast` = 0.6.

**Rationale**: no `flutter_tts`, 0.5 é a velocidade padrão nas duas plataformas (o Android
multiplica por 2.0 e 1.0 é o normal do `TextToSpeech`; no iOS 0.5 é o
`AVSpeechUtteranceDefaultSpeechRate`). Passos de ±0.1 ficam perceptíveis sem ficar rápidos
demais para o público idoso. Os valores ficam numa constante nomeada, não espalhados.

**Alternatives considered**: um `double` livre (permitiria valores fora da faixa, contra o edge
case "só três velocidades").

## R5. Idioma da voz

**Decision**: enum `SpeechLanguage { ptBr('pt-BR'), enUs('en-US') }` com
`SpeechLanguage.fromLocale(Locale)`: `en` → `enUs`, qualquer outro → `ptBr`. Essa é a mesma regra
de fallback do `EasyLocalization` em `main.dart`.

**Rationale**: há uma só regra de idioma no app (RF-042). O `easy_localization` já resolve o
`Locale` atual, e a página o repassa ao controller. Quando a B8 permitir trocar o idioma, o
`context.locale` muda e a página chama `prepare` de novo. Esta feature não precisa saber de
onde veio a escolha.

**Ponto em aberto (da spec)**: ler a **notícia** sempre em português, mesmo com o app em inglês,
continua a decidir antes da A5. O contrato já permite isso: a A5 pode chamar `prepare` com
`Locale('pt', 'BR')` fixo sem mudar nada aqui.

## R6. Abrir endereço e ligar

**Decision**: `UrlLauncherExternalLauncherService` recebe por construtor as funções `launchUrl` e
`canLaunchUrl` do `url_launcher` (com elas como padrão), para poder ser testado sem o canal.

- `openUrl(String)`: só aceita `Uri.tryParse` com esquema `http`/`https` e host não vazio
  (FR-009; "www.site.com" sem esquema é recusado). Abre com `LaunchMode.externalApplication`
  (navegador do aparelho, fora do app, FR-008). `false` ou exceção → `false`.
- `call(String)`: `normalizePhoneNumber` mantém só os dígitos e o `+` inicial. Sem dígitos →
  `false`. Abre `tel:<número>` (o discador, sem completar a ligação, FR-011).
- `canCall()`: `canLaunchUrl(Uri(scheme: 'tel', path: '0'))`. Exceção → `false`.

`normalizePhoneNumber` e `isOpenableWebUrl` são funções puras no arquivo do serviço, com teste
próprio.

**Limitação aceita**: o Android não diz se há chip sem um pacote extra e permissão de leitura do
telefone. `canCall` responde "existe discador". Num tablet sem discador o resultado é `false`
(CB-009). Num celular sem chip o discador abre normalmente, o que é desejável: números de
emergência como 190 e 188 ligam mesmo sem chip.

**Alternatives considered**: um pacote de informação de telefonia (dependência nova e permissão
`READ_PHONE_STATE`, contra a Seção IV e a privacidade). `LaunchMode.platformDefault` foi rejeitado
porque no Android pode abrir uma Custom Tab dentro do app.

**Plataforma**: o manifest já tem `<queries>` para `DIAL tel:` e `VIEW https` (feature 001, R10).
Falta `VIEW http`, que é adicionado nesta feature.

## R7. Compartilhar

**Decision**: `SharePlusShareService` recebe um `SharePlus` pelo construtor (padrão
`SharePlus.instance`) e chama `share(ShareParams(text:, subject:))`. O resultado é convertido assim:

| `ShareResultStatus` | `ShareOutcome` |
|---|---|
| `success` | `shared` |
| `unavailable` (o sistema abriu o menu, mas não informa a escolha) | `shared` |
| `dismissed` | `cancelled` |
| exceção, ou texto vazio (nada é aberto) | `failed` |

**Rationale**: `unavailable` significa que o menu abriu e o sistema não diz o que a pessoa
escolheu. Tratar isso como falha mostraria um erro falso. Só texto (spec, Assumptions).

**Alternatives considered**: a função estática `Share.share`, descontinuada no `share_plus` 13.

## R8. Fotos: escolher, reduzir e guardar

**Decision**: `PlatformImageStorageService` recebe um `ImagePicker` e uma função que devolve a
pasta do app (padrão `getApplicationDocumentsDirectory`).

- `pickImage(PhotoSource)` → `pickImage(source:, maxWidth: 1024, maxHeight: 1024,
  imageQuality: 85, requestFullMetadata: false)`. O próprio `image_picker` reduz a imagem
  mantendo a proporção (FR-014, SC-004), sem pacote novo.
- `null` → `PickImageCancelled`.
- `PlatformException` com código `photo_access_denied` ou `camera_access_denied` (códigos do
  `image_picker_ios` e `image_picker_android`) → `PickImagePermissionDenied` (FR-015).
- O arquivo escolhido é copiado com `XFile.saveTo` para `<documentos do app>/images/` com nome
  `img_<microssegundos>.<extensão>` (`.jpg` quando não houver extensão). Se o nome já existir,
  acrescenta um sufixo. Devolve `PickedImage(path)`.
- Qualquer outra exceção (incluindo falha ao copiar) → `PickImageFailed`.
- `delete(path)`: apaga só arquivos dentro de `images/` do app. Ausente, fora da pasta ou erro →
  ignora (FR-016). Assim um caminho vindo de dado corrompido nunca apaga outro arquivo.

**Rationale**: a pasta de documentos não é limpa pelo sistema, ao contrário do cache onde o
picker põe o arquivo temporário. A cópia continua lá mesmo que a original seja apagada da
galeria. Sem backup em nuvem (`allowBackup="false"`, feature 001 R10).

**Alternatives considered**: o pacote `image` para reduzir a imagem (dependência nova e
desnecessária). Guardar no cache foi rejeitado porque o sistema pode apagar. Dois métodos
(`pickFromGallery`/`pickFromCamera`, como no plano do produto) foram rejeitados porque um método
com o enum evita duplicação e o §3.3 é atualizado.

**Fora do escopo**: `retrieveLostData` (o Android pode matar o app enquanto a câmera está
aberta). É raro, a foto é opcional e a pessoa escolhe de novo.

## R9. Permissões e manifest

**Decision**: no `AndroidManifest.xml`, acrescentar ao `<queries>`:
- `<intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>`: o README do
  `flutter_tts` exige isso para apps com alvo no Android 11+. Sem isso, o app não encontra o
  motor de voz e a voz pareceria indisponível em todo aparelho;
- `VIEW` com `http`, ao lado do `https` que já existe.

Nada de permissão de câmera no Android (clarificação; feature 001 R10). No iOS, os textos de
câmera e galeria já estão no `Info.plist`. A voz não precisa de permissão.

## R10. Registro e testes

**Decision**:

- `CommonModule.registerServices` registra os quatro serviços como `registerLazySingleton`
  (pelo tipo abstrato) e o `ReadAloudController` como `registerFactory`.
- Fakes compartilhados em `test/fakes/`: `FakeTextToSpeechService` (disponibilidade por idioma,
  textos lidos, `finishSpeaking()`/`failSpeaking()` para terminar a leitura pendente),
  `FakeExternalLauncherService`, `FakeShareService` e `FakeImageStorageService` (resultado
  configurável e caminhos apagados).
- Testes das implementações com dublês dos objetos dos pacotes (`Fake implements FlutterTts`,
  `ImagePicker`, `SharePlus` do `flutter_test`), as funções injetadas do `url_launcher` e uma
  pasta temporária (`Directory.systemTemp.createTemp`) no lugar da pasta do app. Não é preciso
  importar pacotes `*_platform_interface` transitivos, o que dispararia `depend_on_referenced_packages`.
- Testes do `ReadAloudController` com o `FakeTextToSpeechService`: os dez cenários da US1.

**Rationale**: o Princípio III exige teste de todo serviço e todo controller, e testes offline.
A injeção pelo construtor com valor padrão já é o padrão do repositório
(`FlutterSecureStorageService`). Ela não é código só para teste, porque o valor padrão é o uso
real.
