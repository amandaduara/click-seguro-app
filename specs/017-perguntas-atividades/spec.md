# Feature Specification: Perguntas do módulo de atividades

**Feature Branch**: `017-perguntas-atividades`

**Created**: 2026-10-21

**Status**: Draft

**Input**: User description: "B2 Atividades: navegação pelas perguntas (RF-024, RF-040, CB-012) — tarefa B2 da Trilha B em .specify/memory/tasks.md. Tela das perguntas de um módulo, aberta pelo painel da B1 em /activities/:moduleId (hoje provisória): as lições na ordem da API, uma por vez, com enunciado, imagem opcional e alternativas; avançar e voltar; indicação das já concluídas; ouvir o enunciado e as alternativas; leitura automática ao abrir uma pergunta, se ligada na Acessibilidade (B9). Lição com menos de duas alternativas é pulada (CB-012). Responder, corrigir e pontuar é a B3; a conclusão é a B4."

**Rastreabilidade**: tarefa B2 do [tasks do produto](../../.specify/memory/tasks.md) · RF-024,
RF-040, CB-012, RN-006 (2.3.0), RNF-003, RNF-004 e RNF-006 da
[especificação do produto](../../.specify/memory/specification.md) · seção "Atividades" do
[contrato da API](../../.specify/memory/api-contract.md) 1.0.10 · painel e registro do visitante
da [feature 015](../015-painel-atividades/spec.md) · leitura em voz alta da
[feature 007](../007-servicos-plataforma-voz/spec.md) e da notícia
([feature 010](../010-detalhe-noticia/spec.md)) · leitura automática e velocidade da
[feature 014](../014-acessibilidade/spec.md).

## Clarifications

### Session 2026-10-21

- Q: A pessoa pode avançar para a próxima pergunta sem responder a atual? → A: Não. "Próxima"
  avança só até a primeira pergunta ainda não respondida; voltar é livre para qualquer pergunta
  anterior. A B3 libera o avanço quando a pessoa confirma a resposta.

## Contexto

O painel (B1) leva a pessoa a um módulo, mas a tela do módulo ainda diz "Em breve". Esta feature
entrega o **caminho pelas perguntas**: cada lição é uma pergunta de múltipla escolha, mostrada uma
por vez, na ordem do curso, com a imagem que a acompanha e a possibilidade de ouvir tudo em voz
alta. O público é, em boa parte, idoso: o texto precisa ser grande e legível, e ouvir a pergunta
sem tocar em nada (leitura automática) é um recurso central.

Esta feature **não corrige** respostas: escolher uma alternativa, confirmar, ver se acertou e a
explicação são da B3; a tela de conclusão e o aviso de login no fim são da B4.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver as perguntas do módulo, uma por vez (Priority: P1)

A pessoa toca num módulo no painel e vê a primeira pergunta que ainda não respondeu: o título do
módulo, em que pergunta está ("Pergunta 1 de 3"), a imagem, o enunciado e as alternativas.

**Why this priority**: é o que tira a tela do módulo do "Em breve" e o que a B3 e a B4 vão usar;
sem ela, as atividades não existem (RF-024).

**Independent Test**: com o serviço falso devolvendo um módulo de três lições, abrir a tela e
conferir título, posição, imagem, enunciado e alternativas na ordem do serviço.

**Acceptance Scenarios**:

1. **Given** um módulo com três lições e nenhuma respondida, **When** a pessoa abre o módulo,
   **Then** vê "Pergunta 1 de 3", a imagem, o enunciado e todas as alternativas da primeira lição.
2. **Given** a pessoa já respondeu a primeira lição, **When** abre o módulo, **Then** começa na
   primeira pergunta ainda não respondida.
3. **Given** todas as lições já respondidas, **When** a pessoa abre o módulo, **Then** começa na
   primeira pergunta, para revisar.
4. **Given** a imagem de uma lição não carrega (ou a lição não tem imagem), **When** a pergunta
   aparece, **Then** o enunciado e as alternativas aparecem normalmente, sem espaço vazio nem erro.
5. **Given** as alternativas vieram numa ordem do serviço, **When** a pergunta aparece, **Then**
   elas aparecem nessa mesma ordem (o app não reordena, RF-027).

---

### User Story 2 - Avançar, voltar e saber o que já fez (Priority: P1)

A pessoa passa para a próxima pergunta e volta para a anterior, e vê quais perguntas já respondeu.

**Why this priority**: o "passo a passo com avanço e retorno" é o próprio RF-024; a indicação das
concluídas mostra o progresso dentro do módulo.

**Independent Test**: abrir um módulo com três lições já respondidas, avançar até a última, voltar
até a primeira e conferir a posição e as marcas de concluída em cada passo; com a primeira lição
sem resposta, conferir que "Próxima" não avança.

**Acceptance Scenarios**:

1. **Given** a pergunta 1 de 3 já respondida, **When** a pessoa toca em "Próxima", **Then** vê a
   pergunta 2 de 3.
2. **Given** a pergunta 2 de 3, **When** a pessoa toca em "Anterior", **Then** volta à pergunta 1.
3. **Given** a primeira pergunta, **When** a tela aparece, **Then** não há "Anterior" ativo; na
   última, não há "Próxima" ativo.
4. **Given** algumas lições já respondidas, **When** a pessoa olha o indicador de progresso do
   módulo, **Then** vê quais perguntas estão concluídas e qual é a atual.
5. **Given** a pessoa ainda não respondeu a pergunta atual, **When** olha "Próxima", **Then** o
   botão está desativado (e anunciado assim pelo leitor de tela); responder é o que libera o
   avanço (B3).
6. **Given** a pessoa está na terceira pergunta, **When** toca em "Anterior" até a primeira,
   **Then** consegue revisar todas as anteriores, respondidas ou não.

---

### User Story 3 - Ouvir a pergunta e as alternativas (Priority: P2)

A pessoa toca em "Ouvir" e o app lê o enunciado e, em seguida, as alternativas, na velocidade
escolhida. Se a leitura automática estiver ligada na Acessibilidade, a leitura começa sozinha ao
abrir cada pergunta.

**Why this priority**: obrigatório pelo RF-024 e pelo RF-040, e central para o público com
dificuldade de leitura; vem depois de ver e navegar porque depende deles.

**Independent Test**: com o leitor de voz falso, tocar em "Ouvir" e conferir o texto lido
(enunciado + alternativas numeradas) e a velocidade; com a leitura automática ligada, abrir a
pergunta e conferir que a leitura começou sozinha.

**Acceptance Scenarios**:

1. **Given** uma pergunta aberta, **When** a pessoa toca em "Ouvir", **Then** o app lê o enunciado
   e depois cada alternativa, na ordem em que aparecem, e o botão passa a "Parar".
2. **Given** a leitura em andamento, **When** a pessoa toca em "Parar", **Then** a leitura para.
3. **Given** a leitura automática ligada, **When** a pessoa abre o módulo ou passa para outra
   pergunta, **Then** a leitura dessa pergunta começa sozinha, uma vez por pergunta.
4. **Given** a leitura em andamento, **When** a pessoa passa para outra pergunta ou sai da tela,
   **Then** a leitura anterior para.
5. **Given** o aparelho sem voz disponível no idioma do app, **When** a pergunta aparece, **Then** o
   botão "Ouvir" não aparece e a leitura automática não acontece, sem erro.
6. **Given** a velocidade "Lenta" escolhida na Acessibilidade, **When** a leitura começa, **Then**
   usa essa velocidade.

---

### User Story 4 - Carregando, erro e lições sem alternativas (Priority: P2)

A pessoa abre um módulo com internet lenta, sem internet, ou um módulo cujo conteúdo veio
incompleto do serviço. Ela sempre entende o que está acontecendo.

**Why this priority**: o servidor gratuito leva até ~40 s para acordar e as atividades não
funcionam sem internet (RNF-002); o CB-012 exige não travar com lição sem alternativas.

**Independent Test**: com o serviço falso atrasado, com erro, com uma lição de uma alternativa só
e com um módulo sem lições, conferir cada estado.

**Acceptance Scenarios**:

1. **Given** o serviço demora, **When** o módulo abre, **Then** aparece um indicador de carregamento
   e, depois de alguns segundos, um aviso de que o serviço está acordando.
2. **Given** sem internet ou erro do serviço, **When** a carga falha, **Then** aparece uma mensagem
   com "Tentar novamente", que recarrega.
3. **Given** uma lição com menos de duas alternativas, **When** o módulo carrega, **Then** essa
   lição não aparece e a contagem ("Pergunta X de Y") considera só as válidas (CB-012).
4. **Given** um módulo sem nenhuma lição válida (ou que não existe mais), **When** a pessoa o
   abre, **Then** vê uma mensagem de que o módulo ainda não tem atividades e pode voltar ao painel.

---

### Edge Cases

- **Visitante**: vê o módulo como quem tem conta; as perguntas que respondeu nesta sessão (registro
  da B1, RN-006) aparecem como concluídas. Responder ainda não existe nesta feature (B3).
- **Letra no nível máximo / alto contraste** (B9): enunciado e alternativas continuam legíveis e a
  tela rola; nada fica cortado; botões continuam alcançáveis.
- **Imagem grande ou muito alta**: ocupa no máximo uma altura razoável da tela, para o enunciado
  aparecer sem rolar muito.
- **Enunciado ou alternativa longos**: quebram linha; nada cortado.
- **Idioma em inglês**: os textos do app (botões, "Pergunta X de Y", mensagens) aparecem em inglês;
  enunciado e alternativas vêm do serviço em português e não são traduzidos; a voz segue o idioma
  do app, como na notícia (decisão de 2026-10-09).
- **Até a B3 existir**: como ainda não dá para responder, "Próxima" fica desativado na primeira
  pergunta não respondida; quem já tem respostas (conta) navega até ela.
- **Toques rápidos** em "Próxima"/"Anterior": a posição muda uma vez por toque, sem pular além do
  fim nem antes do começo.
- **Sessão expira** com a tela aberta: a pergunta atual continua visível; a próxima carga segue como
  sem conta.
- **Leitor de tela** (TalkBack): enunciado, cada alternativa, posição e botões são anunciados; o
  indicador de progresso diz quantas estão concluídas.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Tocar num módulo no painel MUST abrir a tela de perguntas desse módulo, no lugar da
  tela provisória.
- **FR-002**: A tela MUST mostrar as lições do módulo uma por vez, na ordem do serviço, com o
  título do módulo e a posição ("Pergunta X de Y").
- **FR-003**: Cada pergunta MUST mostrar o enunciado, a imagem (quando houver e carregar) e todas as
  alternativas, na ordem em que o serviço as enviou (RF-027).
- **FR-004**: A tela MUST abrir na primeira pergunta ainda não respondida; se todas estiverem
  respondidas, na primeira.
- **FR-005**: A pessoa MUST poder voltar para qualquer pergunta anterior e avançar para a próxima
  **só se a pergunta atual já estiver respondida**; sem passar do começo nem do fim. Assim,
  "Próxima" nunca leva além da primeira pergunta ainda não respondida (clarificação de
  2026-10-21).
- **FR-006**: A tela MUST indicar quais perguntas do módulo já foram respondidas e qual é a atual.
  Para quem tem conta, "respondida" vem do serviço; para o visitante, do registro da sessão (B1).
- **FR-007**: Lição com menos de duas alternativas MUST ser descartada; posição e total consideram
  só as válidas (CB-012).
- **FR-008**: A tela MUST oferecer "Ouvir", que lê o enunciado e em seguida as alternativas
  numeradas, na velocidade da Acessibilidade, e vira "Parar" durante a leitura (RF-024).
- **FR-009**: Com a leitura automática ligada (B9), a leitura MUST começar sozinha ao aparecer cada
  pergunta, uma vez por pergunta (RF-040).
- **FR-010**: Trocar de pergunta ou sair da tela MUST parar a leitura em andamento.
- **FR-011**: Sem voz no idioma do app, "Ouvir" MUST NOT aparecer e a leitura automática MUST NOT
  acontecer, sem mensagem de erro.
- **FR-012**: A tela MUST ter os estados de carregando (com aviso de serviço acordando), erro com
  "Tentar novamente" e "módulo sem atividades" (sem lições válidas ou módulo inexistente).
- **FR-013**: A imagem que não carrega MUST NOT deixar espaço vazio nem mostrar erro.
- **FR-014**: A tela MUST seguir o padrão de acessibilidade do app (RNF-003/RNF-004): alvos ≥ 48
  dp, texto base ≥ 16 sp, letra e alto contraste da B9, e anúncio de enunciado, alternativas,
  posição e botões pelo leitor de tela.
- **FR-015**: Os textos do app na tela MUST estar em português e inglês; enunciado e alternativas
  vêm do serviço como estão.
- **FR-016**: A explicação de cada lição, mesmo que o serviço a envie junto, MUST NOT aparecer
  nesta tela antes de a pessoa responder (ela é parte do feedback da B3).
- **FR-017**: O visitante MUST conseguir ver as perguntas sem conta.

### Key Entities

- **Módulo com lições**: identificador, título e lições (na ordem). Descrição e pontuação do módulo
  vêm do serviço, mas só serão usadas pela B3/B4 (não fazem parte desta feature).
- **Lição (pergunta)**: identificador, ordem, enunciado, imagem (opcional), alternativas (cada uma
  com identificador e texto) e se a pessoa já respondeu.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com o serviço acordado, a primeira pergunta aparece em até 2 segundos depois de tocar
  no módulo.
- **SC-002**: A pessoa chega da última à primeira pergunta (e vice-versa) só com "Anterior" e
  "Próxima", e a posição mostrada está sempre certa.
- **SC-003**: Com a leitura automática ligada, 100% das perguntas abertas começam a ser lidas sem
  toque, e nenhuma é lida duas vezes sozinha.
- **SC-004**: Nenhuma lição sem alternativas suficientes trava ou aparece na tela.
- **SC-005**: Com a letra no nível máximo e o alto contraste, enunciado, alternativas e botões ficam
  legíveis e tocáveis no aparelho.
- **SC-006**: A explicação de nenhuma lição aparece antes da resposta.

## Assumptions

- **Formato dos dados**: conferido em 2026-10-19/21 (contrato 1.0.10): o detalhe do módulo traz as
  lições com enunciado, imagem, alternativas `{id, text}` (sem a correta) e `isCompleted`, e o
  progresso; para o visitante, `isCompleted` vem falso e o progresso zerado. O detalhe também traz
  a `explanation` de cada lição, que esta tela não mostra (FR-016).
- **Responder é da B3**: nesta feature as alternativas aparecem, mas escolher, confirmar e ver o
  resultado são da B3; a B3 também grava a resposta do visitante no registro da sessão
  (`recordAnswer`, B1).
- **Início no ponto onde parou**: a tela abre na primeira pergunta não respondida (FR-004), para a
  pessoa retomar sem procurar.
- **Leitura em voz alta**: o motor de voz, a velocidade e o "Ouvir" da notícia (features 007, 010 e
  014) são reaproveitados; a voz segue o idioma do app.
- **Sem offline**: como o painel, as perguntas não funcionam sem internet (RNF-002 não as inclui).
- **Fora desta feature**: escolher e confirmar a resposta, feedback e explicação (B3); pontuação e
  conclusão, compartilhar e aviso de login (B4).
