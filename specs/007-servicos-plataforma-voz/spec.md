# Feature Specification: Serviços de plataforma e voz

**Feature Branch**: `007-servicos-plataforma-voz`

**Created**: 2026-10-07

**Status**: Draft

**Input**: User description: "F0.5 Serviços de plataforma e voz (Fase 0, base para A4, A5, B2, B6 e B7): em lib/modules/common/services/, TextToSpeechService (flutter_tts), ExternalLauncherService (url_launcher: abrir link no navegador externo e ligar), ShareService (share_plus) e ImageStorageService (image_picker + path_provider: escolher foto e guardar cópia local), cada um com contrato abstrato, implementação, fake em test/fakes/ e registro no CommonModule; ReadAloudController em common (isAvailable, isSpeaking, rate, speak, stop) com teste usando o fake de TTS — voz indisponível → isAvailable = false e os botões de ouvir ficam ocultos (CB-008); falhas de plataforma nunca derrubam a tela (link que não abre, compartilhamento cancelado, aparelho sem telefonia → CB-009). Sem telas novas: as features que usam os serviços ficam para A4/A5/B2/B6/B7."

**Rastreabilidade**: tarefa F0.5 do [tasks do produto](../../.specify/memory/tasks.md) · base para
RF-013 (Reels: abrir fonte), RF-015 (ouvir), RF-016 (compartilhar), RF-017 (abrir fonte), RF-032
(ligar), RF-033/RF-034 (foto do contato), RF-036 (foto do perfil), RF-040 (leitura automática) e RF-042
(idioma) da
[especificação do produto](../../.specify/memory/specification.md) v2.2.0 · CB-008, CB-009,
CB-010, RN-007, RNF-002, RNF-004 · [plano do produto](../../.specify/memory/plan.md) §3.3 e §5 ·
permissões de plataforma da [feature 001](../001-sessao-persistente-visitante/research.md) (R10).

## Clarifications

### Session 2026-10-07

- Q: Em que idioma a voz lê? → A: No idioma atual do app: por padrão o do celular (português ou inglês), e a pessoa poderá trocar nas configurações (Português/English, RF-042 do produto, tarefa B8).
- Q: A velocidade escolhida fica guardada? → A: Não nesta feature; guardar a velocidade e a leitura automática é da acessibilidade (F0.6/B9).
- Q: A câmera precisa de permissão própria? → A: Não no Android (câmera do sistema, R10 da feature 001); no iOS os textos já estão configurados.

## Contexto

Várias telas das duas trilhas precisam de recursos do aparelho: ouvir uma notícia ou uma pergunta
em voz alta, abrir a notícia original no navegador, compartilhar, ligar para um contato e escolher
a foto de um contato ou do perfil. Esta feature entrega esses recursos prontos e testados, num
lugar só, para que cada trilha apenas os use. **Não há tela nova**: quem usa os recursos são as
tarefas A4 (Reels), A5 (detalhe da notícia), B2 (perguntas), B6 (central de ajuda) e B7 (perfil).

As "pessoas" das histórias abaixo são quem vai usar essas telas; os cenários descrevem o
comportamento que as telas vão receber pronto.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ouvir um texto em voz alta (Priority: P1)

Uma pessoa com dificuldade de leitura toca em "Ouvir" numa notícia (A5) ou numa pergunta (B2) e o
aparelho lê o texto no idioma do app (o do celular, ou o escolhido nas configurações), na
velocidade escolhida (lenta, normal ou rápida). Ela pode parar a qualquer momento. Se o aparelho
não tiver voz nesse idioma, o botão de ouvir simplesmente não aparece.

**Why this priority**: é o recurso de acessibilidade mais importante para o público idoso
(RF-015, RF-040) e o mais usado: aparece no detalhe da notícia e em todas as perguntas.

**Independent Test**: nos testes automatizados, com uma voz falsa: pedir para ler um texto e
conferir que a leitura começa, que o estado "lendo" muda, que parar interrompe e que, sem voz
disponível, o recurso se declara indisponível.

**Acceptance Scenarios**:

1. **Given** o aparelho tem voz no idioma atual do app, **When** a tela pergunta se dá para ouvir,
   **Then** a resposta é "sim" e o botão de ouvir pode aparecer.
2. **Given** o aparelho não tem voz no idioma atual do app (ou nenhuma voz), **When** a tela
   pergunta, **Then** a resposta é "não" e o botão de ouvir fica oculto, sem mensagem de erro
   (CB-008).
3. **Given** a voz está disponível, **When** a pessoa toca em "Ouvir", **Then** o texto é lido no
   idioma do app, na velocidade escolhida, e o estado passa a "lendo".
4. **Given** um texto está sendo lido, **When** a pessoa toca em "Parar", **Then** a leitura para
   e o estado volta a "parado".
5. **Given** a leitura chegou ao fim, **When** termina, **Then** o estado volta a "parado" sozinho.
6. **Given** um texto está sendo lido, **When** a pessoa pede para ouvir outro, **Then** o
   primeiro para e o novo começa (nunca dois ao mesmo tempo).
7. **Given** a pessoa muda a velocidade, **When** a próxima leitura começa, **Then** ela usa a
   nova velocidade.
8. **Given** a pessoa sai da tela durante a leitura, **When** a tela fecha, **Then** a leitura
   para.
9. **Given** o idioma do app muda (configurações), **When** a próxima leitura começa ou a tela
   pergunta de novo se dá para ouvir, **Then** a voz e a disponibilidade passam a valer para o novo
   idioma.
10. **Given** o mecanismo de voz falha no meio da leitura, **When** a falha acontece, **Then** o
   estado volta a "parado" e a tela continua funcionando.

---

### User Story 2 - Abrir a notícia original e ligar (Priority: P1)

Na notícia (A4, A5), a pessoa toca em "Ver na fonte" e a página original abre no navegador do
aparelho. Na central de ajuda (B6), ela toca em "Ligar" e o discador abre com o número. Num
aparelho sem discador (um tablet, por exemplo), a tela sabe que não dá para ligar e mostra o número
em destaque para copiar.

**Why this priority**: abrir a fonte é o que dá credibilidade à notícia (RF-017) e ligar é a
ação principal da central de ajuda em caso de golpe (RF-032).

**Independent Test**: nos testes automatizados, com o lançador falso: abrir um endereço válido
devolve "abriu"; um endereço inválido ou de esquema não permitido devolve "não abriu" sem erro;
ligar num aparelho sem telefonia devolve "não dá para ligar".

**Acceptance Scenarios**:

1. **Given** um endereço válido da notícia, **When** a pessoa toca em "Ver na fonte", **Then** a
   página abre no navegador do aparelho, fora do app, e a tela recebe "abriu".
2. **Given** um endereço vazio, malformado ou que não seja de página web (http/https), **When** a
   tela pede para abrir, **Then** nada é aberto e a tela recebe "não abriu", para mostrar uma
   mensagem simples.
3. **Given** o aparelho não consegue abrir o endereço (sem navegador, por exemplo), **When** a
   tela pede para abrir, **Then** a tela recebe "não abriu", sem fechar o app.
4. **Given** o aparelho tem telefonia, **When** a tela pergunta se dá para ligar, **Then** a
   resposta é "sim".
5. **Given** um aparelho sem discador (um tablet, por exemplo), **When** a tela pergunta se dá
   para ligar, **Then** a resposta é "não", e a tela mostra o número em destaque com opção de
   copiar (CB-009). Um celular sem chip tem discador e responde "sim": números de emergência
   (190, 188) ligam mesmo sem chip.
6. **Given** o aparelho tem telefonia, **When** a pessoa toca em "Ligar", **Then** o discador abre
   com o número já preenchido (a pessoa ainda confirma a ligação no discador) e a tela recebe
   "abriu".
7. **Given** um número com espaços, parênteses ou traços ("(11) 9 1234-5678"), **When** a tela
   pede para ligar, **Then** o discador recebe só os dígitos (e o "+" inicial, se houver).

---

### User Story 3 - Compartilhar uma notícia (Priority: P2)

A pessoa toca em "Compartilhar" na notícia (A5) e o menu de compartilhamento do aparelho abre com
o texto pronto, para mandar a um parente pelo aplicativo de mensagens.

**Why this priority**: ajuda a espalhar o alerta de golpe (RF-016), mas é usado menos que ouvir e
abrir a fonte.

**Independent Test**: nos testes automatizados, com o compartilhamento falso: o texto chega como
foi pedido; cancelar o menu não é tratado como erro.

**Acceptance Scenarios**:

1. **Given** um texto a compartilhar, **When** a pessoa toca em "Compartilhar", **Then** o menu
   nativo abre com esse texto.
2. **Given** o menu está aberto, **When** a pessoa fecha sem escolher nada, **Then** a tela recebe
   "cancelado", sem mensagem de erro.
3. **Given** o compartilhamento falha no aparelho, **When** a falha acontece, **Then** a tela
   recebe "não compartilhou" e continua funcionando.

---

### User Story 4 - Escolher a foto de um contato ou do perfil (Priority: P2)

Na central de ajuda (B6) ou no perfil (B7), a pessoa escolhe uma foto da galeria ou tira uma com
a câmera. O app guarda uma cópia própria da foto no aparelho, que continua lá mesmo que a
original seja apagada da galeria. Se a pessoa desistir ou negar o acesso, nada quebra.

**Why this priority**: necessária para B6 e B7, que vêm depois na trilha B; a foto é opcional nos
dois casos.

**Independent Test**: nos testes automatizados, com a escolha de imagem falsa: escolher uma foto
devolve o caminho da cópia guardada; desistir devolve "nenhuma foto"; acesso negado devolve
"sem permissão"; apagar remove a cópia.

**Acceptance Scenarios**:

1. **Given** a pessoa escolhe uma foto da galeria, **When** confirma, **Then** o app guarda uma
   cópia na área própria do app e devolve o endereço dessa cópia.
2. **Given** a pessoa escolhe "Câmera", **When** tira e confirma a foto, **Then** o mesmo acontece.
3. **Given** a pessoa abre a galeria ou a câmera, **When** desiste, **Then** a tela recebe
   "nenhuma foto" e nada muda.
4. **Given** o acesso à galeria ou à câmera foi negado, **When** a pessoa tenta escolher, **Then**
   a tela recebe "sem permissão", para salvar o contato sem foto e explicar como liberar o acesso
   (CB-010).
5. **Given** uma foto guardada pelo app, **When** o contato (ou a foto do perfil) é removido,
   **Then** a cópia é apagada; apagar uma foto que já não existe não é erro.
6. **Given** a foto original é grande, **When** o app guarda a cópia, **Then** ela é reduzida a
   um tamanho adequado para avatar, para não ocupar espaço demais no aparelho.

---

### Edge Cases

- **Velocidade fora da faixa**: só existem três velocidades (lenta, normal, rápida); não há valor
  intermediário.
- **Texto vazio para ouvir**: nada é lido e o estado continua "parado".
- **Texto muito longo** (notícia inteira): é lido inteiro; parar funciona a qualquer momento.
- **Leitura começa enquanto o aparelho está no silencioso**: segue o comportamento do sistema;
  não é tratado como erro.
- **Pedir para ouvir antes de saber se há voz**: a disponibilidade é verificada uma vez e
  lembrada; enquanto não se sabe, o botão não aparece.
- **Endereço sem "https://"** (ex.: "www.site.com"): tratado como não abrível, porque o serviço só
  abre endereços completos vindos da API.
- **Número vazio ou só com símbolos**: "não dá para ligar".
- **Duas fotos com o mesmo nome de origem**: cada cópia ganha um nome único; uma não substitui a
  outra.
- **Foto guardada e depois o app é reinstalado**: as cópias somem junto com o app (sem backup em
  nuvem, R10 da feature 001); as telas tratam o arquivo ausente como "sem foto".
- **Sair da conta**: as fotos dos contatos ficam (RN-007); só as telas decidem o que apagar.

## Requirements *(mandatory)*

### Functional Requirements

**Voz (RF-015, RF-040, CB-008)**

- **FR-001**: O app MUST informar se a leitura em voz alta está disponível, considerando
  disponível só quando o aparelho tem voz no idioma atual do app (português do Brasil ou inglês
  dos EUA).
- **FR-002**: Sem voz disponível, o recurso MUST se declarar indisponível sem erro, para que as
  telas ocultem o botão de ouvir (CB-008).
- **FR-003**: O app MUST ler um texto no idioma atual do app, na velocidade escolhida entre três:
  lenta, normal e rápida (padrão: normal). Mudar o idioma do app MUST valer para a próxima
  leitura e para a próxima verificação de disponibilidade.
- **FR-004**: O app MUST informar a todo momento se está lendo ou parado, e voltar a "parado"
  sozinho ao terminar, ao parar ou em caso de falha.
- **FR-005**: Pedir uma nova leitura MUST interromper a anterior; nunca dois textos ao mesmo
  tempo.
- **FR-006**: Parar MUST interromper a leitura na hora; fechar a tela que leu MUST parar a
  leitura.
- **FR-007**: Texto vazio MUST NOT iniciar leitura.

**Abrir endereço e ligar (RF-013, RF-017, RF-032, CB-009)**

- **FR-008**: O app MUST abrir endereços de página web (http/https) no navegador do aparelho, fora
  do app, e informar se abriu.
- **FR-009**: Endereços vazios, malformados ou de outros tipos MUST NOT ser abertos; o resultado
  MUST ser "não abriu".
- **FR-010**: O app MUST informar se o aparelho consegue fazer ligações, ou seja, se tem
  discador.
- **FR-011**: Ligar MUST abrir o discador com o número já preenchido (só dígitos e "+" inicial),
  sem completar a ligação sozinho, e informar se abriu.

**Compartilhar (RF-016)**

- **FR-012**: O app MUST abrir o menu de compartilhamento do aparelho com o texto informado (e um
  assunto opcional) e informar se foi compartilhado, cancelado ou se falhou.

**Fotos (RF-033, RF-034, RF-036, CB-010, RN-007)**

- **FR-013**: O app MUST permitir escolher uma foto da galeria ou tirar uma com a câmera e MUST
  guardar uma cópia na área própria do app, devolvendo o endereço da cópia.
- **FR-014**: A cópia MUST ser reduzida para no máximo 1024 pixels no lado maior e MUST ter nome
  único.
- **FR-015**: Desistir MUST resultar em "nenhuma foto"; acesso negado MUST resultar em "sem
  permissão", distinguível de desistir.
- **FR-016**: O app MUST apagar uma cópia guardada quando pedido; apagar uma cópia inexistente MUST
  NOT ser erro.

**Robustez e base para as trilhas**

- **FR-017**: Nenhuma falha desses recursos MUST derrubar a tela que os usa: toda falha MUST virar
  um resultado que a tela entende ("não abriu", "falhou", "sem permissão").
- **FR-018**: Cada recurso MUST ter uma versão falsa para testes, usada pelas trilhas nos testes
  das telas, e MUST estar disponível para todas as trilhas sem que elas mexam na base comum.

### Key Entities

- **Velocidade de leitura**: lenta, normal ou rápida.
- **Idioma da leitura**: o idioma atual do app (português do Brasil ou inglês dos EUA).
- **Estado da leitura**: disponível ou não; lendo ou parado; velocidade atual.
- **Resultado de abrir/ligar**: abriu ou não abriu.
- **Resultado de compartilhar**: compartilhado, cancelado ou falhou.
- **Resultado de escolher foto**: endereço da cópia guardada, nenhuma foto, sem permissão ou
  falhou.
- **Origem da foto**: galeria ou câmera.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em aparelhos sem voz no idioma do app, o botão de ouvir não aparece em 100% dos casos e
  nenhuma mensagem de erro é mostrada.
- **SC-002**: A leitura começa em até 1 segundo depois do toque em "Ouvir" e para em até 1 segundo
  depois do toque em "Parar".
- **SC-003**: Em 100% das falhas simuladas (endereço inválido, aparelho sem telefonia,
  compartilhamento cancelado, permissão negada, voz falhando), a tela continua aberta e recebe um
  resultado que permite mostrar uma mensagem simples.
- **SC-004**: Fotos guardadas ocupam no máximo 1024 pixels no lado maior.
- **SC-005**: As trilhas conseguem testar telas que usam esses recursos sem acessar o aparelho
  real (todas as versões falsas disponíveis).

## Assumptions

- **Velocidades**: os valores exatos de "lenta", "normal" e "rápida" são escolhidos no plano para
  soar natural ao público idoso; "normal" é a velocidade padrão do aparelho.
- **Preferências de voz**: guardar a velocidade escolhida e a leitura automática (RF-040) é da
  acessibilidade (F0.6/B9). Nesta feature a velocidade vive enquanto o app está aberto, com padrão
  "normal".
- **Idioma da voz**: o mesmo do app. O app já segue o idioma do celular (português ou inglês; outro
  idioma cai em português) desde a F0.1; escolher o idioma nas configurações é o novo RF-042 do
  produto, construído na B8. Sem voz no idioma atual, o recurso fica indisponível (CB-008).
- **Conteúdo das notícias** ⚠️ **ponto em aberto (2026-10-07)**: os textos vêm da API em
  português. Com o app em inglês, a voz em inglês lê esse texto com pronúncia estranha. Por ora
  vale a regra "voz no idioma do app"; a usuária vai avaliar se a leitura da **notícia** deve usar
  sempre a voz em português (mantendo o inglês só na interface). Traduzir o conteúdo está fora do
  escopo. Decidir antes da A5 (detalhe da notícia), que é quem lê notícias.
- **Câmera sem permissão própria no Android**: a câmera do sistema é usada pelo próprio sistema
  (R10 da feature 001); no iOS, os textos de permissão já estão configurados desde a F0.1.
- **Compartilhar só texto**: imagem anexada fica fora; o texto (título e endereço da notícia) é
  montado pela tela que compartilha (A5).
- **Sem telas novas**: botões, mensagens ("não foi possível abrir", número em destaque com
  "copiar", explicação de permissão) e textos traduzidos ficam com as telas de A4, A5, B2, B6 e B7.
- **Dependências**: os pacotes e as permissões de plataforma já foram adicionados na F0.1
  (feature 001); `common/` ainda é da Fase 0, então esta feature pode mexer nele.
