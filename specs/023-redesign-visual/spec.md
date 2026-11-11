# Feature Specification: Redesign visual 2.0

**Feature Branch**: `023-redesign-visual`

**Created**: 2026-11-08

**Status**: Draft

**Input**: User description: "Redesign visual 2.0 do app Click Seguro (design system e todas as telas), aprovado pela usuária no Figma 'Click Seguro · Redesign 2.0', inspirado em Pinterest e Airbnb e pensado para pessoas idosas. Muda SOMENTE o visual: comportamento, textos, rotas, fluxos, regras e acessibilidade continuam os das specs 004 a 021. Splash e onboarding exatamente como no Figma; login igual ao Figma, mas só com a logo oficial e o nome Click Seguro; Perfil mantém o layout atual e só passa a usar os componentes novos. Decisões que mudam specs anteriores: a barra inferior perde o botão central redondo e a Central de ajuda ganha o cartão 'Caiu em um golpe?'."

**Rastreabilidade**: tarefa nova **R1 Redesign visual 2.0**, a registrar no
[tasks do produto](../../.specify/memory/tasks.md) · RNF-003 e RNF-004 (idosos e
acessibilidade), RF-038 a RF-041 (fonte, alto contraste, leitura em voz alta), RF-001, RF-002,
RF-009, RF-014, RF-018, RF-023 a RF-032 e RF-035 da
[especificação do produto](../../.specify/memory/specification.md) 2.4.0 ·
[design system](../../.specify/memory/design-system.md) 1.1.1 (vira 2.0.0 com esta feature) ·
barra inferior da [feature 005](../005-shell-navegacao-base/spec.md) · Central de ajuda da
[feature 019](../019-central-ajuda/spec.md) · logo oficial e estados ilustrados da
[feature 021](../021-identidade-visual/) (PR #26) · referência visual: Figma
[Click Seguro · Redesign 2.0](https://www.figma.com/design/jr3QeiIsXvuWqJirZFFdYf).

## Contexto

O app cresceu feature a feature, e cada tela foi ganhando o seu jeito: tamanhos de texto,
botões, cartões e estados de erro não seguem um padrão só. Para o público do Click Seguro, que são
pessoas idosas, essa variação custa caro. Cada tela diferente é uma tela nova a aprender.

A usuária aprovou no Figma um redesign com uma linguagem única. A interface fica calma, em tons
creme, e a imagem ou ilustração vem na frente (Pinterest). Os cartões trazem a imagem no topo, com
um só nível de sombra (Airbnb). Há um vermelho-coral para a ação principal, textos maiores,
botões mais altos, ícones de traço no lugar de emojis, ilustrações próprias e animações curtas que
mostram o que aconteceu.

Esta feature troca **apenas a aparência**. O que cada tela faz, os textos, as rotas, as regras de
negócio e a acessibilidade continuam os já especificados. Há duas exceções, decididas pela
usuária, que mudam specs anteriores. A primeira é a barra inferior sem o botão central (muda a
feature 005). A segunda é o cartão de emergência na Central de ajuda (amplia a feature 019).

## Clarifications

### Session 2026-11-08 (antes do specify, na aprovação do Figma)

- Q: O que muda na tela de login? → A: Só a logo oficial do app e o nome "Click Seguro". O
  resto segue o Figma sem mudar conteúdo.
- Q: O Perfil segue o mockup novo? → A: Não. Mantém o layout de hoje (feature 012) e só passa a
  usar os mesmos componentes das outras telas.
- Q: Qual é o nome do app? → A: "Click Seguro", separado, como no logo e na feature 021.
- Q: A barra inferior mantém o botão central redondo de "Notícias"? → A: Não. As cinco abas ficam
  iguais, com rótulo sempre visível e indicador em pílula na aba atual, porque o botão central
  confundia a pessoa sobre em qual aba ela estava.
- Q: A Central de ajuda ganha o cartão "Caiu em um golpe?"? → A: Sim, no topo da tela.
- Q: Itens do mockup que não existem nas specs (linha de tempo de estudo e medalha na conclusão,
  link "Ver lições baixadas", botão "Praticar" na notícia, só 2 abas no Assistente) entram?
  → A: Não. Vale o que as specs atuais definem. O mockup é referência de aparência, não de
  conteúdo.

### Session 2026-11-08 (specify)

- Q: Os módulos vêm da API só com título e um ícone opcional. Como escolher a ilustração de cada
  módulo? → A: Pelo tema reconhecido no título (WhatsApp, Pix, link, ligação, senha, fake news),
  com uma ilustração genérica de proteção quando nenhum tema bater (FR-014).

### Session 2026-11-08 (clarify)

- Q: Além de seguir o "reduzir movimento" do celular, a tela de Acessibilidade deve ganhar um
  interruptor próprio "Reduzir animações"? → A: Sim, desligado por padrão e salvo no aparelho
  como as outras preferências; as animações param se o do app ou o do celular estiver ligado
  (FR-021, FR-024).
- Q: No Início, quais seções usam a grade de duas colunas com alturas variadas? → A: "Novidades"
  continua carrossel, "Destaques" em cartões grandes de largura total, "Recomendadas" e "Tudo
  recente" em grade de 2 colunas com alturas variadas (FR-025).
- Q: O redesign vai para o `develop` num PR só ou em PRs menores? → A: Um PR só no fim, com um
  commit por história, como nas features anteriores.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Uma linguagem visual única em todo o app (Priority: P1)

A pessoa usa qualquer tela e encontra sempre os mesmos elementos. O botão principal é coral, com
texto grande e branco. O botão secundário é creme. Os cartões têm cantos arredondados, os campos
têm rótulo sempre visível, os selos de status mantêm as mesmas cores e os ícones são de traço. A
barra inferior tem cinco abas iguais, e a aba atual fica marcada com uma pílula.

**Why this priority**: é a base do redesign. Quando os componentes compartilhados mudam, todas as
telas herdam o visual novo, inclusive as que não têm uma história própria (Perfil,
Configurações, notícias salvas). As outras histórias só ajustam o layout das telas.

**Independent Test**: abrir o guia de estilo do app e as telas de Perfil e Configurações e
conferir botões, cartões, campos, selos, chips e barra inferior com os do Figma, no tema normal e
no de alto contraste.

**Acceptance Scenarios**:

1. **Given** qualquer tela com uma ação principal, **When** ela aparece, **Then** a ação
   principal é um botão coral de 60 de altura, com texto em negrito, e há no máximo um botão
   coral visível por vez.
2. **Given** a barra inferior, **When** a pessoa está em uma aba, **Then** as cinco abas têm o
   mesmo tamanho, todas mostram o rótulo, e a aba atual tem o ícone coral sobre uma pílula
   coral-suave e o rótulo em negrito.
3. **Given** a pessoa está na aba "Notícias", **When** olha a barra, **Then** essa aba é marcada
   como as outras (sem botão central maior), e tocar nela continua abrindo os Reels.
4. **Given** um campo de texto, **When** recebe o foco, **Then** a borda fica tinta e mais grossa;
   **When** tem erro, **Then** a borda e a mensagem ficam na cor de erro, com o ícone de alerta.
5. **Given** o tema de alto contraste ligado (RF-039), **When** qualquer componente aparece,
   **Then** ele usa a paleta de alto contraste, sem sombras e com bordas visíveis, como hoje.
6. **Given** a fonte no maior nível (RF-038) ou a fonte do sistema ampliada, **When** qualquer
   tela aparece, **Then** nenhum texto fica cortado ou sobreposto e a tela rola quando precisa.
7. **Given** a tela de Perfil, **When** aparece, **Then** a disposição é a mesma de hoje (feature
   012), mas com os botões, cartões, selos e listas novos.

---

### User Story 2 - Primeira impressão: splash, onboarding e login (Priority: P1)

Ao abrir o app, a pessoa vê o splash com a logo oficial numa base creme e o nome "Click Seguro".
Na primeira vez, passa pelo onboarding com ilustrações grandes, título, texto e botão
"Continuar". Depois chega ao login, com a logo oficial e o nome "Click Seguro" no topo.

**Why this priority**: é o primeiro contato com o app, e a usuária aprovou essas telas
exatamente como estão no Figma.

**Independent Test**: limpar os dados do app, abrir e percorrer splash, os três slides do
onboarding e o login, comparando com os quadros "01 Splash", "02 Onboarding" e "03 Entrar" do
Figma.

**Acceptance Scenarios**:

1. **Given** o app abrindo, **When** o splash aparece, **Then** mostra a logo oficial num círculo
   branco sobre o fundo creme, o nome "Click Seguro" e o slogan atual, como no Figma.
2. **Given** o onboarding na primeira abertura (RF-002, RN-004), **When** cada slide aparece,
   **Then** ele mostra o botão "Ouvir" e "Pular" no topo, uma ilustração própria do tema do slide,
   o título, o texto, o indicador de página (o atual alongado e coral) e o botão
   "Continuar"/"Começar". Os textos e o comportamento são os de hoje.
3. **Given** a tela de login, **When** aparece, **Then** mostra a logo oficial e o nome "Click
   Seguro" no topo, a troca Entrar/Criar conta em pílula e os campos e botões com o visual novo,
   sem mudar textos, campos nem fluxo (features 003 e 021).

---

### User Story 3 - Atividades com ilustrações, feedback e celebração (Priority: P1)

No painel de atividades, a pessoa vê o anel de progresso geral e os módulos em cartões grandes,
com a ilustração no topo, um selo de status sobre ela, o título, o número de lições e uma barra
de progresso. Na pergunta, as alternativas são cartões grandes com a letra num círculo, e a
escolhida fica marcada com borda tinta. Ao confirmar, o feedback sobe numa folha inferior. Se
acertou, aparece o check verde com uma animação de mola. Se errou, a alternativa balança de leve,
a certa fica destacada e aparece a ilustração da lâmpada. Ao terminar o módulo, a conclusão mostra
o troféu com confete e o placar em destaque.

**Why this priority**: Atividades é onde a pessoa aprende. O feedback claro e a celebração são o
que motivam a continuar, e é aí que o redesign mais muda a experiência.

**Independent Test**: com o serviço falso, abrir o painel, entrar num módulo, responder uma
pergunta certa e uma errada e terminar o módulo, comparando com os quadros "06" a "09" do Figma.

**Acceptance Scenarios**:

1. **Given** o painel (RF-023), **When** carrega, **Then** mostra o anel com a porcentagem de
   lições concluídas, o texto atual de progresso e um cartão por módulo, com ilustração, selo
   ("Não iniciado", "Em andamento", "Concluído" ou "Indisponível"), título, lições e barra.
2. **Given** um módulo, **When** o cartão é montado, **Then** a ilustração do topo segue a regra de
   escolha de ilustração (FR-014).
3. **Given** uma pergunta (RF-024 a RF-027), **When** aparece, **Then** mostra o progresso
   segmentado, a posição ("Pergunta X de Y"), o enunciado grande, as alternativas em cartões com
   letra e o rodapé fixo com "Confirmar resposta".
4. **Given** a resposta confirmada e certa, **When** o feedback aparece, **Then** a alternativa
   fica verde com check, o check do feedback entra com animação de mola e a folha inferior mostra
   "Você acertou!", a pontuação e o "Por quê?".
5. **Given** a resposta confirmada e errada, **When** o feedback aparece, **Then** a alternativa
   escolhida fica coral com X e balança de leve duas vezes, a certa fica verde, e a folha mostra a
   ilustração da lâmpada com "Não foi dessa vez" e a resposta correta.
6. **Given** a conclusão (RF-029), **When** aparece, **Then** mostra o troféu com confete, "Módulo
   concluído!", o nome do módulo, o placar grande que conta de 0 até o resultado, a mensagem de
   acordo com o resultado e os botões já definidos na feature 020, sem a linha de tempo e medalha
   do mockup.
7. **Given** "reduzir movimento" ligado no aparelho, **When** qualquer uma dessas telas aparece,
   **Then** nada se mexe: confete, mola, balanço, contagem e enchimento aparecem já no estado
   final.

---

### User Story 4 - Notícias com capas e leitura confortável (Priority: P2)

No Início, a pessoa vê a saudação, a busca em pílula, os filtros em chips e as notícias em cartões
com capa de cantos arredondados. A categoria fica num selo sobre a imagem e há o botão de salvar.
No detalhe, a capa ocupa o topo com os botões de voltar, compartilhar e salvar flutuando, o texto é
grande e há o reprodutor "Ouvir notícia". A seção "Pratique o que aprendeu" usa o cartão de módulo
novo.

**Why this priority**: notícias são a porta de entrada do app. O visual muda bastante, mas o
conteúdo e as seções continuam os mesmos.

**Independent Test**: com o serviço falso, abrir o Início, buscar, filtrar, abrir uma notícia com
imagem e outra sem, e comparar com os quadros "04" e "05" do Figma.

**Acceptance Scenarios**:

1. **Given** o Início (RF-009 a RF-012), **When** carrega, **Then** mantém a saudação, o contador
   de novidades, a busca, os filtros por categoria e as seções da feature 006, com os cartões novos
   dispostos como no FR-025.
2. **Given** uma notícia com imagem, **When** o cartão é montado, **Then** a imagem da notícia é a
   capa; **Given** uma notícia sem imagem, **Then** a capa é uma ilustração própria sobre fundo
   pastel, nunca um espaço vazio.
3. **Given** o detalhe (RF-014 a RF-018), **When** aparece, **Then** mostra a capa com os botões
   flutuantes, os selos de categoria, o título, a fonte, o reprodutor de áudio, o texto e a seção
   "Pratique o que aprendeu", quando a API sugerir um módulo.
4. **Given** os Reels, **When** abertos, **Then** mantêm a tela escura em tela cheia, só com os
   botões e selos no estilo novo.

---

### User Story 5 - Assistente e Central de ajuda (Priority: P2)

No Assistente, as três abas (Conversar, Verificar, Histórico) ficam em pílula. As mensagens viram
balões e a análise aparece num cartão com selo de risco. Na Central de ajuda, um cartão coral no
topo pergunta "Caiu em um golpe?" e oferece "Ligar para 190". Abaixo dele ficam as abas e os
contatos com o botão de ligar.

**Why this priority**: são telas de apoio importantes. O cartão de emergência é a única novidade
de conteúdo e responde a um momento de aflição.

**Independent Test**: abrir o Assistente e trocar de aba. Abrir a Central de ajuda e tocar em
"Ligar para 190", conferindo que abre o discador com 190.

**Acceptance Scenarios**:

1. **Given** o Assistente (RF-043 a RF-045), **When** aparece, **Then** mostra as três abas em
   pílula, os balões da conversa e o cartão de análise com o selo de risco, com o mesmo
   comportamento de hoje.
2. **Given** a Central de ajuda (RF-031 a RF-034), **When** aparece, **Then** o topo mostra o
   cartão coral com o título "Caiu em um golpe?", o texto "Ligue agora para a polícia e para o seu
   banco." e o botão "Ligar para 190".
3. **Given** o cartão de emergência, **When** a pessoa toca em "Ligar para 190", **Then** o
   discador abre com o número 190, como os outros contatos (RF-032). Se o discador não abrir,
   vale o mesmo aviso que os contatos já usam.
4. **Given** o leitor de tela, **When** passa pelo cartão, **Then** lê o título, o texto e o botão
   "Ligar para 190".

---

### User Story 6 - Estados de carregamento, erro, vazio e sem internet (Priority: P2)

Enquanto algo carrega, a pessoa vê blocos com brilho passando, no formato do conteúdo que vai
chegar, no lugar do círculo girando. Se demora, aparece o aviso azul de servidor acordando. Erro,
lista vazia e falta de internet mostram uma ilustração própria, um título, uma explicação simples
e a ação para resolver.

**Why this priority**: esses estados aparecem em todas as telas com rede. O visual novo deixa
claro que o app está trabalhando ou o que fazer, sem assustar.

**Independent Test**: com o serviço falso, forçar carregamento lento, erro, lista vazia e falta de
conexão nas Atividades e nas notícias salvas, e comparar com os quadros "13" a "16" do Figma.

**Acceptance Scenarios**:

1. **Given** uma tela carregando, **When** os dados ainda não chegaram, **Then** aparecem blocos
   com brilho no formato do conteúdo (cartões, linhas), e o leitor de tela anuncia que está
   carregando, como hoje.
2. **Given** a demora do servidor, **When** o aviso de servidor lento é mostrado (regra atual),
   **Then** ele aparece no aviso azul com ícone de relógio.
3. **Given** um erro, **When** aparece, **Then** mostra a ilustração da tomada desconectada, o
   título e o texto atuais e o botão coral "Tentar de novo", mais a ação secundária quando a tela
   já tem uma.
4. **Given** uma lista vazia, **When** aparece, **Then** mostra a ilustração da caixa aberta, o
   texto atual e a ação atual, quando houver.
5. **Given** a falta de conexão, **When** é detectada, **Then** a faixa escura "sem conexão"
   aparece no topo do conteúdo e o estado mostra a ilustração da nuvem sem sinal com "Tentar de
   novo", sem o link "Ver lições baixadas" do mockup.

---

### Edge Cases

- **Alto contraste** (RF-039): as ilustrações, o anel, a barra, os selos e os cartões trocam para
  a paleta de alto contraste. Os fundos pastel das ilustrações viram branco com contorno preto,
  e nada depende só de cor.
- **Fonte ampliada**: botões de 60 crescem em altura quando o texto quebra em duas linhas, e não
  cortam o texto. A barra inferior mantém os rótulos legíveis e, se não couberem, quebram em duas
  linhas em vez de sumir.
- **Reduzir movimento**: com o do aparelho ou o interruptor do app ligado, todas as animações desta
  feature aparecem no estado final, inclusive o brilho do carregamento, que fica parado.
- **Imagem de notícia que falha ao carregar**: a capa volta para a ilustração pastel, como uma
  notícia sem imagem.
- **Módulo sem lições** (CB-012): o cartão aparece como hoje, "Indisponível" e sem abrir, com a
  ilustração em tons apagados.
- **Inglês dos EUA** (RF-042): textos mais longos não quebram os chips, selos e botões. O cartão
  de emergência mostra o texto traduzido, e o número continua 190, porque é o serviço brasileiro.
- **Discador indisponível** (tablet sem telefone): o "Ligar para 190" mostra o mesmo aviso dos
  contatos, com a opção de copiar o número.
- **Grade com fonte ampliada**: quando a escala total do texto (a do app vezes a do sistema)
  passar de 1,3, a grade de 2 colunas MUST passar para uma coluna, para o título dos cartões não
  ficar espremido.
- **Telas que o Figma não desenhou** (Configurações, Editar dados, Recuperar senha, Alertas,
  notícias salvas/lidas/curtidas, Sobre, Privacidade, Acessibilidade): mudam só por herdar os
  componentes novos, sem layout próprio.

## Requirements *(mandatory)*

### Functional Requirements

**Fundamentos**

- **FR-001**: O app MUST usar a paleta nova no tema normal: coral #E31C3D para ação (pressionado
  #C2112F, suave #FFE8EB), tinta #1B2440 para títulos, #3D4457 para o corpo, #5E6577 para apoio,
  superfícies branca, creme #F7F5F0 e creme forte #EFEBE3, linha #E4E1DA, e os estados sucesso
  #0F7B4F, atenção #8F5600, informação #2554C7 e erro #C4122F. Toda combinação de texto e fundo
  MUST atender WCAG 2.1 AA (RNF-004).
- **FR-002**: O tema de alto contraste (RF-039) MUST continuar existindo, com contraste AAA, sem
  sombras e com bordas visíveis, aplicado também aos componentes e às ilustrações novas.
- **FR-003**: O app MUST usar a fonte Inter em toda a interface, com corpo de 16 (o mínimo do
  RNF-003 para o texto base), nada abaixo de 14 e títulos entre 18 e 28, escalando com a
  preferência de fonte do app (RF-038) e com a do sistema (RNF-004). *Revisto na validação da
  usuária (2026-11-10): a escala de 18 ficou grande demais.*
- **FR-004**: Os cantos MUST seguir a escala 12, 16, 20, 24, 32 e pílula, e o app MUST ter um só
  nível de sombra, usado em cartões e botões sobre imagem.
- **FR-005**: Todo ícone da interface MUST ser de traço, da biblioteca de ícones já usada no app,
  sem emojis. Todo ícone que age sozinho MUST ter rótulo para o leitor de tela (RNF-004).

**Componentes**

- **FR-006**: Os botões MUST ter as variantes primário (coral), secundário (creme), contorno,
  link e desativado, com 60 de altura (menor só em barras e linhas, nunca abaixo de 48, RNF-003),
  cantos de 16 e estado pressionado visível.
- **FR-007**: MUST existir: botão redondo de ícone; chip de filtro (ativo invertido em tinta);
  botão "Ouvir"; selos de status nas cores de estado; campo com rótulo visível acima, foco com
  borda tinta e erro com borda e mensagem na cor de erro; abas em pílula; barra de progresso, anel
  e progresso segmentado; aviso curto (toast), faixa sem conexão e aviso de servidor lento.
- **FR-008**: As alternativas do quiz MUST ter quatro aparências distintas, padrão, selecionada
  (borda tinta), certa (verde com check) e errada (coral com X), que não dependam só de cor.
- **FR-009**: A barra inferior MUST ter cinco abas de mesmo tamanho ("Início", "Atividades",
  "Notícias", "Ajuda", "Perfil"), só com ícones (o nome de cada aba fica no leitor de tela e na
  dica do toque longo) e a aba atual marcada por um círculo coral de 44 com o ícone branco.
  *Revisto na validação da usuária (2026-11-10).* Ela substitui o botão central redondo da feature
  005, e o destino e o comportamento de cada aba continuam os mesmos.

**Telas**

- **FR-010**: O splash e o onboarding MUST seguir os quadros "01 Splash" e "02 Onboarding" do
  Figma, mantendo textos, ordem, regras de exibição (RF-001, RF-002, RN-004) e o botão "Ouvir".
- **FR-011**: O login MUST mostrar a logo oficial (feature 021) e o nome "Click Seguro" no topo,
  com os componentes novos, sem mudar campos, textos nem fluxo (features 003 e 021).
- **FR-012**: Início, detalhe da notícia, Reels, Atividades (painel, pergunta, feedback em folha
  inferior, conclusão), Assistente e Central de ajuda MUST seguir os quadros do Figma
  correspondentes, mantendo o conteúdo, as seções, os textos e o comportamento das specs atuais.
  Quando o mockup e a spec divergem no conteúdo, vale a spec.
- **FR-013**: O Perfil MUST manter o layout atual (feature 012) e usar os componentes novos.
- **FR-014**: Cada cartão de módulo MUST mostrar uma ilustração própria no topo, escolhida pelo
  tema reconhecido no título do módulo: WhatsApp, Pix ou boleto, link ou mensagem suspeita,
  ligação, senha e fake news, cada um com a sua ilustração e cor pastel. Quando nenhum tema bater,
  o cartão MUST usar uma ilustração genérica de proteção. O reconhecimento MUST ignorar
  maiúsculas e acentos e funcionar com os títulos em português e inglês.
- **FR-025**: No Início, "Novidades" MUST continuar como carrossel, "Destaques" MUST usar cartões
  grandes de largura total e "Recomendadas" e "Tudo recente" MUST usar uma grade de 2 colunas com
  alturas de capa variadas (estilo Pinterest), mantendo a ordem das notícias da API (lida da
  esquerda para a direita, de cima para baixo), a paginação e o rodapé atuais.
- **FR-015**: Toda notícia MUST ter capa: a imagem da notícia quando houver e carregar, senão uma
  ilustração própria sobre fundo pastel.
- **FR-016**: A Central de ajuda MUST mostrar no topo um cartão coral com o título "Caiu em um
  golpe?", o texto "Ligue agora para a polícia e para o seu banco." e o botão "Ligar para 190",
  que abre o discador com 190 como os outros contatos (RF-032), em português e inglês (RF-042).

**Ilustrações e estados**

- **FR-017**: O app MUST ter ilustrações vetoriais próprias, no estilo do Figma, para boas-vindas
  (os três slides do onboarding), sem internet, erro, vazio, conquista (conclusão), resposta certa
  e resposta errada (lâmpada), além das capas de módulo e de notícia. Elas substituem o desenho
  dos estados de erro e vazio da feature 021, mantendo a logo oficial dela. As
  ilustrações MUST ser decorativas para o leitor de tela.
- **FR-018**: O carregamento das telas com conteúdo em lista ou cartões MUST usar blocos com
  brilho no formato do conteúdo, no lugar do círculo girando, mantendo o anúncio de carregamento
  ao leitor de tela e o aviso de servidor lento atual.
- **FR-019**: Os estados de erro, vazio e sem internet MUST mostrar ilustração, título, texto e a
  ação atual de cada tela, sem incluir ações que a spec da tela não tem.

**Movimento**

- **FR-020**: O app MUST ter animações curtas: troca de tela (aparecer e deslizar, 250 ms), toque
  em botões e cartões (encolher para 98%, 150 ms), progresso enchendo (400 ms), folha inferior
  subindo (400 ms), resposta certa com mola, resposta errada com balanço suave duas vezes,
  conclusão com confete e contagem do placar (1200 ms), brilho do carregamento, pulso do botão
  "Ouvir" ao começar a ler (3 vezes, depois um anel parado enquanto lê; ajuste do implement para
  não ter movimento sem fim), pulso suave do círculo da logo no splash e flutuação suave da ilustração
  do onboarding.
- **FR-021**: Toda animação MUST respeitar "reduzir movimento": se o interruptor do app (FR-024)
  **ou** a opção do aparelho estiver ligado, o conteúdo aparece direto no estado final. Nenhuma
  animação MUST piscar mais de 3 vezes por segundo.
- **FR-024**: A tela de Acessibilidade MUST ganhar o interruptor "Reduzir animações", desligado
  por padrão, salvo no aparelho e aplicado já na abertura do app, como as outras preferências de
  acessibilidade (RF-041), com texto em português e inglês e rótulo para o leitor de tela.

**Escopo e documentação**

- **FR-022**: Esta feature MUST NOT mudar textos (exceto o novo cartão de emergência e o
  interruptor "Reduzir animações"), rotas,
  regras de negócio, chamadas à API nem o comportamento das telas.
- **FR-023**: O [design system](../../.specify/memory/design-system.md) MUST ser atualizado para a
  versão 2.0.0, descrevendo os tokens, componentes, ilustrações e animações novas, e a
  especificação do produto MUST registrar a barra inferior nova e o cartão de emergência.

### Key Entities

- **Tokens visuais**: cores, fonte, tamanhos de texto, cantos, espaçamento, sombra e durações de
  animação, nas versões normal e alto contraste.
- **Ilustração**: desenho decorativo identificado pelo uso (estado, slide, tema de módulo, capa de
  notícia), com a versão de alto contraste.
- **Preferência de movimento**: o interruptor "Reduzir animações" do app (nova preferência de
  acessibilidade, salva no aparelho) combinado com o "reduzir movimento" do sistema; se qualquer
  um estiver ligado, as animações não rodam.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: As 16 telas do Figma, quando reproduzidas no app com os mesmos dados, ficam
  visualmente equivalentes ao quadro na conferência lado a lado pela usuária (cores, textos,
  disposição e componentes), salvo os itens que a spec manda manter como estão.
- **SC-002**: 100% das combinações de texto e fundo do tema normal atingem contraste de pelo menos
  4,5:1 (3:1 para texto de 24 ou mais em negrito), e o tema de alto contraste segue em 7:1.
- **SC-003**: No maior nível de fonte, nenhuma das telas do app tem texto cortado ou sobreposto.
- **SC-004**: Com "reduzir movimento" ligado, nenhuma tela mostra animação.
- **SC-005**: Todos os testes automatizados que já existem continuam passando sem mudar o que eles
  verificam de comportamento. Só mudam os que conferem aparência.
- **SC-006**: Nenhum texto visível muda, exceto os três textos do cartão de emergência e os do
  interruptor "Reduzir animações".
- **SC-007**: Na validação no aparelho, a usuária identifica em qual aba está, só olhando a barra
  inferior, em todas as cinco abas.

## Assumptions

- O Figma "Click Seguro · Redesign 2.0" é a referência de aparência. Ele tem dados de exemplo
  (nomes, notícias, módulos) que não entram no app.
- A logo oficial, o `AppLogo` e o nome "Click Seguro" vêm da feature 021 (PR #26, já no
  `develop`), e esta feature não os altera.
- A fonte Inter é empacotada com o app (licença aberta), sem baixar nada em tempo de uso, para
  funcionar offline (RNF-002).
- O número 190 do cartão de emergência é fixo e brasileiro, como os contatos oficiais. Não há
  configuração por país.
- A ordem das seções do Início, as abas de cada tela e os textos são os das features 006, 010, 012,
  015 a 020, 016 (Assistente) e 019 (Ajuda).
- A tela dos Reels continua escura e em tela cheia. O Figma não a redesenha, e ela só herda os
  componentes novos.
- A entrega é um PR só para o `develop`, com um commit por história e validação no aparelho
  antes do PR. Antes de abrir o PR, a branch MUST ser atualizada com o `develop` para resolver
  conflitos com o trabalho em paralelo.
- O Figma desenhou só o primeiro slide do onboarding. Os slides 2 ("Notícias verificadas") e 3
  ("Aprenda na prática") ganham ilustrações próprias no mesmo estilo.
- A animação de troca de tela vale para as navegações dentro do app. Abrir o discador, o navegador
  ou o menu de compartilhar segue o padrão do sistema.
