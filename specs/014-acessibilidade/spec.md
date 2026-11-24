# Feature Specification: Tela de Acessibilidade

**Feature Branch**: `014-acessibilidade`

**Created**: 2026-10-15

**Status**: Draft

**Input**: User description: "B9 Acessibilidade (RF-038 a RF-041): substituir o placeholder em /settings/accessibility (hoje um SettingsSectionPage) por uma AccessibilityPage real, com seletor de tamanho de fonte com prévia ao vivo (pelo menos 3 níveis acima do padrão, aplicado em todas as telas), alternância de tema de alto contraste e alternância de leitura automática em voz alta (ao abrir o detalhe de uma notícia ou uma pergunta de atividade). Reutiliza a infraestrutura da F0.6 (specs/009-acessibilidade-global) já existente no módulo settings: AccessibilityController, repositório e AccessibilityPreferencesNotifier. As preferências são salvas no aparelho e aplicadas já no splash da próxima abertura (RF-041). Rever se o visitante pode acessar a tela de acessibilidade, já que a B8 escondeu a engrenagem de configurações para visitantes. Widget test: mudar a opção reflete no app e persiste (fake do LocalCacheService)."

**Rastreabilidade**: tarefa B9 do [tasks do produto](../../.specify/memory/tasks.md) · RF-038 a
RF-041, RNF-003 e RNF-004 da [especificação do produto](../../.specify/memory/specification.md) ·
[plano do produto](../../.specify/memory/plan.md) §3.2 · infraestrutura (preferências, tema de alto
contraste, escala de fonte, carga no splash) da [feature 009](../009-acessibilidade-global/spec.md)
· leitura automática na notícia da [feature 010](../010-detalhe-noticia/spec.md) · velocidades da
voz da [feature 007](../007-servicos-plataforma-voz/spec.md) · entrada "Acessibilidade" e regra do
visitante nas Configurações da [feature 013](../013-configuracoes/spec.md).

## Clarifications

### Session 2026-10-15

- Q: O visitante (sem conta) pode abrir a tela de Acessibilidade, já que na B8 ele não chega às
  Configurações? → A: Sim. A engrenagem passa a aparecer também para o visitante, e as
  Configurações dele mostram só os itens que não precisam de conta. Isso revê a decisão da
  feature 013 (engrenagem escondida para o visitante).
- Q: As Configurações do visitante têm convite para entrar ou criar conta? → A: Não. Só os itens
  que não precisam de conta, sem convite.

## Contexto

A feature 009 já guarda no aparelho as quatro preferências de acessibilidade (tamanho da fonte,
alto contraste, leitura automática e velocidade da voz), aplica-as ao app inteiro na hora e já na
abertura seguinte. O que falta é o lugar onde a pessoa **escolhe** essas opções: hoje a entrada
"Acessibilidade" das Configurações abre uma tela provisória vazia. Esta feature entrega essa tela.

O público do SafeNews é, em boa parte, idoso. A tela precisa ser autoexplicativa: cada opção diz o
que faz, e a pessoa vê o efeito antes de sair dela.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escolher o tamanho da letra vendo como fica (Priority: P1)

Uma pessoa com vista cansada abre Configurações › Acessibilidade e vê os tamanhos de letra
disponíveis, com o atual marcado. Ao tocar num tamanho maior, um texto de exemplo na própria tela
cresce na hora, e o resto do app também. Ela volta e todas as telas estão com a letra nova.

**Why this priority**: letra maior é a necessidade mais comum do público (RF-038) e é o principal
motivo para alguém abrir esta tela. Sozinha, já entrega valor.

**Independent Test**: abrir a tela num teste de widget com o armazenamento falso, tocar num nível
maior e conferir que o texto de exemplo e um texto fora da tela crescem, que o nível fica marcado
e que o valor foi gravado.

**Acceptance Scenarios**:

1. **Given** a tela aberta com a letra "padrão", **When** a pessoa olha a seção de tamanho,
   **Then** vê os quatro níveis (padrão e três maiores), com "padrão" marcado, e um texto de
   exemplo no tamanho atual.
2. **Given** a tela aberta, **When** a pessoa toca num nível maior, **Then** o nível passa a ficar
   marcado, o texto de exemplo e a própria tela crescem na hora, sem botão "salvar".
3. **Given** um nível maior escolhido, **When** a pessoa volta para as Configurações ou para
   qualquer aba, **Then** essas telas também estão com a letra maior.
4. **Given** um nível maior escolhido, **When** a pessoa fecha e abre o app, **Then** o splash e as
   telas seguintes já aparecem com esse nível, e a tela de Acessibilidade mostra esse nível
   marcado.
5. **Given** o nível máximo do app, **When** a pessoa rola a tela de Acessibilidade, **Then** todas
   as opções continuam visíveis e tocáveis (nada cortado sem rolagem).

---

### User Story 2 - Ligar o alto contraste (Priority: P2)

Uma pessoa com baixa visão liga a opção "Alto contraste". A tela muda de cores na hora, e o app
inteiro também. Desligando, o visual normal volta.

**Why this priority**: necessário para parte do público (RF-039), mas menos comum que a letra
maior.

**Independent Test**: abrir a tela num teste de widget, ligar o alto contraste e conferir que o
tema em uso passou a ser o de alto contraste, que a chave aparece ligada e que o valor foi gravado.

**Acceptance Scenarios**:

1. **Given** contraste normal, **When** a pessoa liga "Alto contraste", **Then** a tela e o app
   passam a usar o tema de alto contraste na hora, e a chave mostra "ligado".
2. **Given** alto contraste ligado, **When** a pessoa desliga, **Then** o tema normal volta.
3. **Given** alto contraste ligado, **When** o app é aberto de novo, **Then** já abre com o tema de
   alto contraste e a chave aparece ligada.

---

### User Story 3 - Ligar a leitura automática e escolher a velocidade da voz (Priority: P3)

A pessoa liga "Ler em voz alta automaticamente". A partir daí, ao abrir uma notícia o app começa a
ler sozinho, sem tocar em "Ouvir". Na mesma seção, ela escolhe a velocidade da voz (lenta, normal
ou rápida), que vale para toda leitura em voz alta.

**Why this priority**: a leitura automática (RF-040) já funciona na notícia, só falta como ligá-la;
o efeito depende de outras telas e atinge menos pessoas que as opções visuais.

**Independent Test**: abrir a tela num teste de widget, ligar a leitura automática e escolher
"lenta", conferir que os valores em vigor e gravados mudaram e que a tela mostra a escolha.

**Acceptance Scenarios**:

1. **Given** leitura automática desligada, **When** a pessoa liga a chave, **Then** a chave mostra
   "ligado" e, ao abrir uma notícia em seguida, a leitura começa sozinha.
2. **Given** leitura automática ligada, **When** a pessoa desliga, **Then** ao abrir uma notícia a
   leitura não começa sozinha.
3. **Given** a velocidade "normal", **When** a pessoa escolhe "lenta", **Then** "lenta" fica
   marcada e a próxima leitura em voz alta, em qualquer tela, usa essa velocidade.
4. **Given** as opções de voz escolhidas, **When** o app é aberto de novo, **Then** a tela mostra as
   mesmas escolhas.

---

### User Story 4 - Visitante chega às Configurações sem conta (Priority: P2)

Uma pessoa idosa usa o app como visitante. Ela vê a engrenagem no topo, como quem tem conta, e
abre as Configurações. Lá encontra só o que funciona sem conta: Acessibilidade, Idioma,
Privacidade e Sobre o SafeNews. Ela aumenta a letra
sem precisar se cadastrar.

**Why this priority**: as preferências são do aparelho, não da conta, e o público idoso costuma
usar o app sem conta; sem esse caminho, o visitante não tem como aumentar a letra no app. Vem
depois da letra maior porque depende da tela da User Story 1.

**Independent Test**: entrar como visitante num teste de widget, conferir que a engrenagem
aparece, abrir as Configurações, conferir que só os itens sem conta aparecem e que nenhum pedido
é feito ao serviço, e abrir a Acessibilidade.

**Acceptance Scenarios**:

1. **Given** a pessoa é visitante, **When** olha o topo das abas (Início, Atividades, Ajuda) e do
   Perfil, **Then** vê a engrenagem das Configurações, como quem tem conta.
2. **Given** a pessoa é visitante, **When** abre as Configurações, **Then** vê as seções
   "Leitura e aparência" (Acessibilidade e Idioma) e "Sobre" (Privacidade e Sobre o SafeNews), e nada mais:
   **não** vê o cartão da conta, Dados pessoais, Trocar senha, Alertas, "Sair da conta" nem
   convite para entrar ou criar conta.
3. **Given** as Configurações do visitante, **When** ele toca em "Acessibilidade", **Then** abre a
   mesma tela de quem tem conta, e as escolhas valem e ficam guardadas do mesmo jeito.
4. **Given** as Configurações do visitante, **When** ele escolhe um idioma, **Then** o app muda de
   idioma na hora, como para quem tem conta.
5. **Given** o visitante ajustou a acessibilidade, **When** entra numa conta (ou alguém sai da
   conta e volta como visitante), **Then** as preferências continuam as mesmas (são do aparelho).
6. **Given** a sessão de quem tem conta expira com as Configurações abertas, **When** a tela se
   atualiza, **Then** passa a mostrar a versão do visitante.

---

### Edge Cases

- **Falha ao gravar** (armazenamento indisponível): a escolha vale até o app fechar, a tela não
  trava e não mostra erro (comportamento da feature 009, FR-009 de lá).
- **Toques rápidos seguidos** em níveis diferentes: o nível marcado, o aplicado e o gravado são o
  último tocado.
- **Tocar no nível já marcado**: nada muda e nada é regravado.
- **Escala do sistema já alta** + nível máximo do app: a escala total respeita o teto de 200% da
  feature 009; a tela continua rolável e utilizável.
- **Alto contraste + nível máximo** juntos: a tela continua legível e tocável.
- **Leitura em andamento** quando a pessoa muda a velocidade: a leitura atual termina na
  velocidade antiga; a nova vale a partir da próxima.
- **Leitor de tela do celular** (TalkBack/VoiceOver) ligado: cada opção anuncia o nome, o estado
  (marcado/ligado) e o que faz.
- **Idioma do app em inglês**: todos os textos da tela aparecem em inglês.
- **Visitante sem internet**: as Configurações do visitante e a tela de Acessibilidade abrem
  normalmente, porque nada nelas depende do serviço.
- **Visitante abre por link direto** um item que exige conta (por exemplo, trocar senha): continua
  como na feature 013, com o convite para entrar no lugar do conteúdo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A entrada "Acessibilidade" das Configurações MUST abrir a tela de Acessibilidade, no
  lugar da tela provisória atual.
- **FR-002**: A tela MUST mostrar os quatro níveis de tamanho de fonte (padrão, 115%, 130% e 150%),
  com o nível em vigor marcado, e permitir escolher um deles (RF-038).
- **FR-003**: A tela MUST mostrar um texto de exemplo que reflete na hora o tamanho de fonte em
  vigor (prévia ao vivo).
- **FR-004**: A tela MUST ter uma chave de alto contraste que mostra o estado em vigor e o alterna
  (RF-039).
- **FR-005**: A tela MUST ter uma chave de leitura automática em voz alta que mostra o estado em
  vigor e o alterna (RF-040), com uma explicação curta de onde ela age.
- **FR-006**: A tela MUST permitir escolher a velocidade da voz entre lenta, normal e rápida, com a
  velocidade em vigor marcada.
- **FR-007**: Toda escolha MUST valer na hora, para a própria tela e para o app inteiro, sem botão
  de salvar e sem reiniciar o app.
- **FR-008**: Toda escolha MUST ser guardada no aparelho e valer já no splash da próxima abertura
  (RF-041), usando o armazenamento da feature 009.
- **FR-009**: Ao abrir, a tela MUST mostrar os valores em vigor (inclusive os carregados na
  abertura do app).
- **FR-010**: Falhas ao gravar MUST NOT travar a tela nem mostrar erro; a escolha vale até o app
  fechar.
- **FR-011**: A tela MUST seguir o padrão de acessibilidade do app (RNF-003/RNF-004): alvos de
  toque ≥ 48 dp, texto base ≥ 16 sp, respeito à escala de fonte do sistema, e cada opção com nome e
  estado anunciados pelo leitor de tela.
- **FR-012**: Todos os textos da tela MUST estar traduzidos em português e inglês.
- **FR-013**: A engrenagem das Configurações MUST aparecer para todos, com ou sem conta, no topo
  das abas e do Perfil (revê a feature 013).
- **FR-014**: Para o visitante, as Configurações MUST mostrar apenas os itens que não precisam de
  conta (Acessibilidade, Idioma, Privacidade e Sobre o SafeNews); MUST NOT mostrar o cartão da
  conta, Dados pessoais, Trocar senha, Alertas, "Sair da conta" nem convite para entrar ou criar
  conta.
- **FR-015**: As Configurações do visitante MUST NOT fazer pedidos ao serviço (RN-003).
- **FR-016**: A tela de Acessibilidade MUST ser a mesma para visitante e para quem tem conta, e as
  preferências MUST continuar as mesmas ao entrar, sair ou trocar de conta.
- **FR-017**: A tela de Acessibilidade MUST NOT exigir conexão com a internet nem chamar o
  serviço.

### Key Entities

- **Preferências de acessibilidade** (já existentes, feature 009): tamanho da fonte (um de quatro
  níveis), alto contraste (sim/não), leitura automática (sim/não) e velocidade da voz (lenta,
  normal ou rápida). Uma por aparelho, sem vínculo com a conta. Esta feature não muda o que é
  guardado, só dá à pessoa como mudar.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A partir das Configurações, a pessoa chega à opção de tamanho de letra em 1 toque e
  muda o tamanho em mais 1 toque.
- **SC-002**: Uma escolha feita na tela aparece na própria tela e nas demais em menos de 1 segundo.
- **SC-003**: Em 100% das aberturas seguintes, as escolhas feitas na tela já valem desde o splash.
- **SC-004**: No nível máximo de fonte, com e sem alto contraste, todas as opções da tela ficam
  visíveis (com rolagem) e tocáveis no aparelho.
- **SC-005**: Com o leitor de tela do celular, todas as opções da tela podem ser identificadas e
  alteradas sem enxergar a tela.
- **SC-006**: Um visitante chega da aba Início à opção de tamanho de letra em 2 toques
  (engrenagem › Acessibilidade), sem criar conta.
- **SC-007**: Nas Configurações do visitante, 0 itens que exigem conta aparecem e 0 pedidos são
  feitos ao serviço.

## Assumptions

- **Infraestrutura pronta**: preferências, gravação, tema de alto contraste, escala de fonte, teto
  de 200% e carga antes do splash são da feature 009 e não mudam aqui. Esta feature é a tela e a
  ligação dela com o que já existe.
- **Velocidade da voz na tela**: a tarefa B9 não cita a velocidade, mas a feature 009 a guarda e
  deixou a escolha para a B9; sem esta tela, não há como mudá-la. Por isso entra aqui.
- **Leitura automática nas perguntas de atividade**: começar a ler sozinho numa pergunta é da
  tarefa B2 (navegação pelas perguntas), que ainda não existe. A chave desta tela já vale para a
  notícia (feature 010) e passará a valer para as perguntas quando a B2 consultar a preferência.
- **Sem "salvar"**: as escolhas valem ao tocar, como nas Configurações da B8, para não exigir um
  passo extra do público idoso.
- **Sem "restaurar padrões"**: com quatro opções visíveis numa tela só, voltar ao padrão é um toque
  em cada uma; um botão a mais fica fora desta feature.
- **Configurações do visitante**: a lista começa direto na seção "Leitura e aparência", sem cartão nem
  convite (o convite para entrar continua no Perfil, feature 012). O
  idioma escolhido pelo visitante fica guardado no aparelho como o de quem tem conta (feature 013).
- **Visual**: segue o estilo das Configurações da B8 (seções com título, linhas com ícone e chave)
  do arquivo do Figma "SafeNews — Perfil e Configurações (redesign)". Se não houver quadro próprio
  para Acessibilidade, a tela é montada com esses mesmos componentes.
- **Atalho de desenvolvimento**: o atalho provisório usado para validar a feature 009 sem esta
  tela deixa de ser necessário; o que fazer com ele é decisão do plano.
