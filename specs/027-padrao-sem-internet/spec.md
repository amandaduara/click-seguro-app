# Feature Specification: Padrão único para a falta de internet

**Feature Branch**: `027-padrao-sem-internet`

**Created**: 2026-11-23

**Status**: Implemented (validado pela usuária no aparelho em 2026-11-23)

**Input**: Revisão da usuária no aparelho (2026-11-23), com quatro capturas sem internet: o login
mostra um texto vermelho, o Início mostra a faixa azul com as notícias salvas, as Atividades
mostram a tomada com "Não foi possível carregar as atividades" e os Reels mostram a nuvem com o
texto quase invisível no fundo preto. Pedido: "Precisamos deixar padrão a informação de que está
sem internet. Cada tela mostra uma coisa." O padrão de três casos abaixo foi aprovado por ela.

**Rastreabilidade**: nova tarefa **R4 Padrão de sem internet** no
[tasks do produto](../../.specify/memory/tasks.md) · RNF-002 (offline), CB-001 (sem conexão ao
abrir), CB-002 (sem conexão durante ação), RNF-003 e RNF-004 (idosos e acessibilidade) e RNF-006
(textos traduzidos) da [especificação do produto](../../.specify/memory/specification.md) ·
[feature 024](../024-redesign-visual/spec.md) (estados de erro com ilustração e faixa de sem
internet).

## Contexto

O app já tem as peças: a faixa azul "Você está sem internet. Mostrando o conteúdo salvo.", o
estado de erro com a ilustração da nuvem sem sinal e a mensagem "Sem conexão com a internet.
Verifique sua rede.". O que falta é usá-las do mesmo jeito em todas as telas. Hoje:

- o estado de erro só mostra a nuvem quando o texto recebido é igual, letra por letra, à mensagem
  de sem conexão; as telas que passam um texto próprio (Atividades, Lição) caem sempre na tomada,
  que é o desenho de erro do servidor;
- nos Reels, o fundo é preto e o texto do estado de erro usa a cor de texto do fundo claro, por
  isso fica ilegível;
- várias ações que falham por falta de internet (responder questão, trocar senha, salvar o
  perfil, trocar a foto, mudar os alertas, carregar mais notícias) mostram um texto genérico
  ("Não foi possível…") e a pessoa não fica sabendo que o problema é a conexão;
- nos Alertas, a faixa diz "Mostrando o conteúdo salvo" mesmo quando não há nada salvo na lista.

Para quem é idoso, ver três desenhos e cinco frases diferentes para a mesma situação confunde:
parece que cada tela tem um defeito diferente, quando basta ligar a internet.

## Clarifications

### Session 2026-11-23

- Implementação: apagar e salvar contato na Central de ajuda usam só o armazenamento do aparelho
  (RNF-002) e nunca falham por falta de internet; ficam fora de FR-006, sem caso de teste de
  conexão.
- Implementação: o texto curto da faixa em inglês segue o estilo do texto longo: "You're
  offline." (em vez de "You are offline.").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tela sem nada para mostrar avisa sempre do mesmo jeito (Priority: P1)

Sem internet, a pessoa abre uma tela que precisa da rede e não tem cópia guardada (Atividades,
uma lição, Reels, Perfil, Conquistas, Central de ajuda, Editar perfil, Histórico do Assistente,
uma notícia nunca aberta). Em todas ela vê a mesma coisa: a ilustração da nuvem sem sinal, a
frase "Sem conexão com a internet. Verifique sua rede." e o botão "Tentar novamente", legíveis no
fundo claro e no fundo escuro.

**Why this priority**: é o caso das capturas (Atividades e Reels) e o que mais aparece quando a
rede cai. Sozinha, esta história já resolve a maior parte da confusão.

**Independent Test**: com o aparelho em modo avião, abrir Atividades, Reels e Perfil e comparar:
mesmo desenho, mesma frase, mesmo botão; ligar a internet e tocar em "Tentar novamente" carrega a
tela.

**Acceptance Scenarios**:

1. **Given** o aparelho sem internet, **When** a pessoa abre a aba Atividades, **Then** vê a nuvem
   sem sinal, "Sem conexão com a internet. Verifique sua rede." e "Tentar novamente" (e não a
   tomada com "Não foi possível carregar as atividades").
2. **Given** o aparelho sem internet, **When** a pessoa abre um módulo de atividades, **Then** a
   lição mostra o mesmo estado de sem internet.
3. **Given** o aparelho sem internet, **When** a pessoa abre a aba Reels, **Then** a frase aparece
   em cor clara, legível sobre o fundo preto, com o mesmo desenho e o mesmo botão.
4. **Given** o estado de sem internet na tela, **When** a internet volta e a pessoa toca em
   "Tentar novamente", **Then** a tela carrega normalmente.
5. **Given** a internet funcionando e o servidor com erro, **When** a pessoa abre uma dessas
   telas, **Then** vê a tomada com a mensagem de erro da própria tela (o desenho da nuvem fica só
   para a falta de internet).

---

### User Story 2 - Ação que falha diz que o problema é a internet (Priority: P2)

Com uma tela já aberta, a pessoa faz algo que precisa da rede (responder uma questão, trocar a
senha, salvar o perfil, trocar a foto, ligar ou desligar os alertas, carregar mais notícias, salvar
ou denunciar uma notícia, entrar, criar conta, recuperar a senha) e a internet
caiu. Ela recebe sempre a mesma frase: "Sem conexão com a internet. Verifique sua rede.". Nos
formulários de entrada (login, criar conta, esqueci a senha) a frase aparece na própria tela, como
hoje; nas demais ações, num aviso rápido no rodapé. O que ela já tinha digitado ou escolhido
continua na tela.

**Why this priority**: hoje várias dessas ações dizem só "Não foi possível…", e a pessoa tenta de
novo sem saber que precisa ligar a internet.

**Independent Test**: com a tela aberta, desligar a internet, fazer cada ação e conferir que a
frase é sempre a de sem conexão e que nada do que foi preenchido se perdeu.

**Acceptance Scenarios**:

1. **Given** uma questão com resposta escolhida e sem internet, **When** a pessoa confirma,
   **Then** o aviso rápido diz "Sem conexão com a internet. Verifique sua rede." e a resposta
   escolhida continua marcada.
2. **Given** a tela Trocar senha preenchida e sem internet, **When** a pessoa salva, **Then** o
   aviso rápido diz a frase de sem conexão (e não "Não foi possível trocar a senha…") e os campos
   continuam preenchidos.
3. **Given** Editar perfil com mudanças e sem internet, **When** a pessoa salva ou troca a foto,
   **Then** o aviso rápido diz a frase de sem conexão.
4. **Given** as Configurações abertas e sem internet, **When** a pessoa mexe na chave dos alertas,
   **Then** a chave volta à posição anterior e a própria linha dos alertas diz a frase de sem
   conexão, com o botão de tentar de novo (a linha já mostra a falha assim hoje).
5. **Given** o feed ou os Reels na tela e a internet caindo, **When** a pessoa rola até o fim e o
   app tenta carregar mais, **Then** o fim da lista diz a frase de sem conexão, com a opção de
   tentar de novo.
6. **Given** o login preenchido e sem internet, **When** a pessoa toca em "Entrar", **Then** a
   frase aparece na própria tela, embaixo dos campos (comportamento de hoje, mantido).
7. **Given** a internet funcionando e o servidor recusando a ação, **When** a ação falha,
   **Then** a pessoa vê a mensagem própria da ação (por exemplo, "Não foi possível trocar a
   senha. Tente de novo mais tarde."), e não a de sem conexão.

---

### User Story 3 - Conteúdo guardado com a faixa azul, sem prometer o que não há (Priority: P3)

Sem internet, a pessoa abre uma tela que tem cópia guardada (Início, uma notícia já lida, Salvas,
Alertas). A faixa azul no topo avisa que ela está sem internet e o conteúdo guardado aparece
embaixo. Quando a lista está vazia, a faixa não fala em "conteúdo salvo".

**Why this priority**: o Início, o detalhe e as Salvas já seguem esse padrão; só os Alertas
destoam, num caso menos frequente.

**Independent Test**: em modo avião, abrir Início e Alertas com e sem alertas guardados e
conferir o texto da faixa.

**Acceptance Scenarios**:

1. **Given** sem internet e com notícias guardadas, **When** a pessoa abre o Início, **Then** vê a
   faixa "Você está sem internet. Mostrando o conteúdo salvo." e as notícias guardadas (como hoje).
2. **Given** sem internet e com alertas guardados, **When** a pessoa abre os Alertas, **Then** vê a
   mesma faixa, com o mesmo texto, e os alertas guardados.
3. **Given** sem internet e sem nenhum alerta guardado, **When** a pessoa abre os Alertas, **Then**
   a faixa diz só "Você está sem internet." e não promete conteúdo salvo.

---

### Edge Cases

- **A internet cai depois que a tela carregou**: o conteúdo na tela continua; só a próxima ação
  ou o próximo carregamento mostram o aviso (US2), sem trocar a tela inteira pelo estado de erro.
- **Falta de internet e tempo esgotado**: as duas contam como "sem internet" (é o que já acontece
  na camada de dados hoje).
- **Sessão expirada sem internet**: a regra de sessão expirada continua como está; esta feature
  não muda o que acontece quando o servidor recusa a sessão.
- **Visitante respondendo questão**: a resposta do visitante fica no aparelho e não precisa da
  rede, então não mostra aviso de sem internet.
- **Letra grande e telas curtas**: o estado de sem internet continua rolando e a ilustração
  encolhe, como já faz o estado de erro.
- **App em inglês**: todas as frases saem traduzidas, inclusive a nova frase curta da faixa.
- **Leitor de tela**: a frase de sem internet é anunciada quando aparece, no estado de erro, na
  faixa e no aviso rápido.

## Requirements *(mandatory)*

### Functional Requirements

**Estado de tela sem conteúdo (US1)**

- **FR-001**: O estado de erro de tela inteira MUST escolher o desenho pelo tipo da falha: falta
  de internet (inclui tempo esgotado) mostra a nuvem sem sinal; qualquer outra falha mostra a
  tomada. A escolha MUST NOT depender de comparar o texto da mensagem.
- **FR-002**: Na falta de internet, o estado de erro de tela inteira MUST mostrar a frase "Sem
  conexão com a internet. Verifique sua rede." e o botão "Tentar novamente", qualquer que seja a
  tela.
- **FR-003**: As telas Atividades e Lição MUST mostrar o estado de sem internet (FR-001, FR-002)
  quando a falha for de conexão, mantendo "Não foi possível carregar as atividades" com a tomada
  para as outras falhas.
- **FR-004**: Sobre fundo escuro (Reels), a ilustração, a frase e o botão do estado de erro MUST
  ter contraste legível (mesmo critério de contraste do resto do app).
- **FR-005**: As telas que já mostram o estado de sem internet corretamente (Início sem cópia,
  Perfil, Editar perfil, Conquistas, Central de ajuda, Formulário de contato, Histórico do
  Assistente, Salvas e Detalhe da notícia) MUST continuar iguais.

**Ação que falha com a tela aberta (US2)**

- **FR-006**: Toda ação que precisa da rede e falha por falta de internet MUST mostrar a frase
  "Sem conexão com a internet. Verifique sua rede.", e não um texto genérico da ação. Isso vale
  pelo menos para: responder questão, trocar senha, salvar o perfil, trocar a foto, mudar os
  alertas, carregar a conta nas Configurações, carregar mais notícias (feed e Reels), números e
  conquistas no Perfil, salvar, curtir ou denunciar notícia e as ações do Assistente.
- **FR-007**: Nos formulários de entrada (login, criar conta, esqueci a senha) e no envio do
  Assistente a frase MUST aparecer na própria tela, como já acontece hoje; nas demais ações, MUST aparecer num aviso rápido
  no rodapé; nos blocos parciais de uma tela já carregada (números e conquistas no Perfil, fim da
  lista, linha dos alertas nas Configurações) MUST aparecer no próprio bloco, com a opção de tentar de novo que o bloco já tem.
- **FR-008**: Quando a ação falha por outro motivo (servidor, recusa), a tela MUST manter a
  mensagem própria da ação que existe hoje.
- **FR-009**: Uma ação que falha por falta de internet MUST NOT apagar o que a pessoa digitou ou
  escolheu; uma chave (alertas) MUST voltar à posição anterior.

**Conteúdo guardado (US3)**

- **FR-010**: Telas com cópia guardada (Início, Detalhe da notícia, Salvas, Alertas) MUST mostrar
  a faixa azul de sem internet no topo, com a mesma aparência e o mesmo texto quando há conteúdo
  guardado.
- **FR-011**: Nos Alertas sem nenhum alerta guardado, a faixa MUST dizer só "Você está sem
  internet." (sem "Mostrando o conteúdo salvo").

**Geral**

- **FR-012**: Todas as frases MUST existir em português e inglês, e MUST ser anunciadas pelo
  leitor de tela quando aparecem.
- **FR-013**: Telas que não usam a internet (Configurações, Acessibilidade, Privacidade, Termos
  de uso, Sobre) MUST NOT ganhar aviso de sem internet.
- **FR-014**: O guia de design do app MUST registrar o padrão dos três casos (tela sem conteúdo,
  ação que falha, conteúdo guardado) para as próximas telas seguirem.

### Key Entities

- **Falha de conexão**: o tipo de falha que o app já usa para "sem internet" e "tempo esgotado";
  é ela, e não o texto, que decide o aviso.
- **Faixa de sem internet**: aviso no topo de telas com conteúdo guardado; duas variações de
  texto (com e sem conteúdo guardado).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em modo avião, 100% das telas que precisam da rede e não têm cópia mostram o mesmo
  desenho, a mesma frase e o mesmo botão (conferido nas 11 telas de FR-003 e FR-005 e nos Reels).
- **SC-002**: Em modo avião, 100% das ações listadas em FR-006 mostram a frase de sem conexão;
  nenhuma mostra "Não foi possível…".
- **SC-003**: A frase do estado de erro nos Reels atinge pelo menos o contraste mínimo de texto
  do app (4,5:1) sobre o fundo preto.
- **SC-004**: Com a internet ligada e o servidor com erro, 100% das telas e ações continuam com as
  mensagens próprias de hoje (nenhuma passa a dizer "sem conexão" sem estar sem conexão).
- **SC-005**: Na validação no aparelho, a usuária percorre as telas em modo avião e confirma que
  "toda tela avisa do mesmo jeito".

## Assumptions

- A frase "Sem conexão com a internet. Verifique sua rede." e a faixa azul atuais continuam como
  estão; esta feature não cria um desenho novo, só usa os existentes em todo lugar.
- Não há detecção contínua da rede: o aviso aparece quando uma carga ou ação falha por falta de
  internet, como hoje. Detectar a rede em tempo real fica fora do escopo.
- O texto curto da faixa sem conteúdo guardado é "Você está sem internet." (inglês: "You are
  offline.").
- As mensagens de erro do servidor e as de validação dos formulários não mudam.
- Sem mudanças na API.
