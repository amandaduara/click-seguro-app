# Feature Specification: Painel de atividades

**Feature Branch**: `015-painel-atividades`

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "B1 Atividades: painel (RF-023, CB-012, RN-006) — tarefa B1 da Trilha B em .specify/memory/tasks.md. Substituir a página provisória da aba Atividades (/activities, hoje ComingSoonView) pelo painel de atividades: progresso geral (lições concluídas de todas as disponíveis), grade de módulos (título, descrição, ícone, progresso) e o status de cada módulo (não iniciado, em andamento, concluído; indisponível quando o módulo não tem lições, CB-012). Tocar num módulo disponível abre /activities/:moduleId (rota já existente; a tela de perguntas é a B2). Dados de GET /app/educational/modules (conferido em 2026-10-19: o visitante chama sem token e recebe 200 com progresso zerado; hoje há 3 módulos com 3 lições cada). Visitante: o progresso vale só para a sessão atual (RN-006), guardado em memória num GuestProgressStore que a B3 vai alimentar ao responder; o painel do visitante mostra esse progresso. Estados de carregando, erro com tentar de novo e sem módulos. Módulo activities ainda é só o esqueleto da Fase 0; não pode importar o profile (que tem a própria leitura desse endpoint para conquistas)."

**Rastreabilidade**: tarefa B1 do [tasks do produto](../../.specify/memory/tasks.md) · RF-023,
RN-006, CB-012, RNF-002 a RNF-004 e RNF-006 da
[especificação do produto](../../.specify/memory/specification.md) · seção "Atividades" do
[contrato da API](../../.specify/memory/api-contract.md) · aba e rota `/activities/:moduleId` da
[feature 005](../005-shell-navegacao-base/spec.md) · sessão de visitante da
[feature 001](../001-sessao-persistente-visitante/spec.md) · "atividades relacionadas" da notícia
da [feature 010](../010-detalhe-noticia/spec.md).

## Contexto

As atividades são a segunda metade do SafeNews, ao lado das notícias: módulos curtos de perguntas
que ensinam a reconhecer golpes. Hoje a aba Atividades mostra só "Em breve". Esta feature entrega a
**porta de entrada**: o painel com o progresso da pessoa e os módulos disponíveis. As perguntas
(B2), a correção (B3) e a conclusão (B4) vêm depois e abrem a partir daqui.

Quem tem conta tem o progresso guardado no serviço. O visitante pode fazer as atividades, mas o
progresso dele vale só enquanto o app estiver aberto (RN-006). O painel precisa mostrar o
progresso certo nos dois casos.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver os módulos e o próprio progresso (Priority: P1)

Uma pessoa com conta abre a aba Atividades. Ela vê quanto já avançou (por exemplo, "4 de 9 lições
concluídas") e, abaixo, um cartão por módulo, na ordem do curso, com ícone, título, descrição,
quantas lições já fez e em que situação o módulo está: não iniciado, em andamento ou concluído.

**Why this priority**: é o que tira a aba do "Em breve" e mostra à pessoa o que existe para
aprender e onde ela parou (RF-023). Sem o painel, nenhuma outra tarefa de atividades é
alcançável.

**Independent Test**: com o serviço falso devolvendo três módulos (um não iniciado, um em
andamento, um concluído), abrir a aba e conferir o progresso geral, a ordem dos cartões, os
textos, o progresso e o status de cada um.

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta e concluiu 4 das 9 lições, **When** abre a aba Atividades,
   **Then** vê o progresso geral "4 de 9 lições concluídas" com uma barra proporcional.
2. **Given** três módulos no serviço, **When** o painel carrega, **Then** aparece um cartão por
   módulo, na ordem definida pelo serviço, cada um com ícone, título, descrição e o progresso
   ("2 de 3 lições").
3. **Given** um módulo sem nenhuma lição feita, **When** o painel carrega, **Then** o cartão
   mostra o status "Não iniciado".
4. **Given** um módulo com parte das lições feitas, **When** o painel carrega, **Then** o cartão
   mostra "Em andamento".
5. **Given** um módulo com todas as lições feitas, **When** o painel carrega, **Then** o cartão
   mostra "Concluído".
6. **Given** o ícone de um módulo não carrega (ou o módulo não tem ícone), **When** o painel
   aparece, **Then** o cartão mostra um ícone padrão no lugar, sem espaço vazio nem erro.

---

### User Story 2 - Abrir um módulo (Priority: P1)

A pessoa toca no cartão de um módulo e vai para a tela das perguntas daquele módulo. Ao voltar, o
painel mostra o progresso atualizado.

**Why this priority**: o painel só tem valor se leva às atividades; é o caminho para B2–B4.

**Independent Test**: tocar num cartão e conferir que abre a tela do módulo certo; voltar com o
serviço falso devolvendo um progresso maior e conferir que o painel mudou.

**Acceptance Scenarios**:

1. **Given** o painel com módulos disponíveis, **When** a pessoa toca num cartão, **Then** abre a
   tela daquele módulo, sobre as abas.
2. **Given** a pessoa fez lições e volta ao painel, **When** o painel aparece de novo, **Then** o
   progresso geral e o dos cartões estão atualizados, sem a pessoa precisar puxar para recarregar.
3. **Given** um módulo indisponível (sem lições), **When** a pessoa toca no cartão, **Then** nada
   abre; o cartão já diz que o módulo ainda não tem atividades.
4. **Given** toques rápidos repetidos num cartão, **When** a tela do módulo abre, **Then** ela
   abre uma vez só.

---

### User Story 3 - Visitante vê o progresso desta sessão (Priority: P2)

Uma pessoa usa o app sem conta. Ela vê os mesmos módulos. O progresso mostrado é o que ela fez
desde que abriu o app; ao fechar o app, ele some. O painel avisa isso de forma curta.

**Why this priority**: o público pode usar o app sem conta (RN-006); sem esta regra o visitante
veria sempre zero, mesmo depois de responder, ou acharia que o progresso fica guardado.

**Independent Test**: como visitante, registrar lições concluídas no progresso da sessão e conferir
que o painel as mostra; trocar a sessão (entrar numa conta, sair, reabrir como visitante) e
conferir que o progresso de visitante foi descartado.

**Acceptance Scenarios**:

1. **Given** um visitante que ainda não respondeu nada, **When** abre o painel, **Then** vê os
   módulos com "0 de N" e "Não iniciado", e um aviso curto de que o progresso sem conta vale só
   até fechar o app.
2. **Given** um visitante que concluiu lições nesta sessão, **When** volta ao painel, **Then** o
   progresso geral, o de cada cartão e os status refletem essas lições.
3. **Given** um visitante com progresso nesta sessão, **When** entra numa conta, **Then** o painel
   passa a mostrar o progresso da conta (do serviço); o progresso de visitante é descartado.
4. **Given** um visitante com progresso, **When** o app é fechado e aberto de novo como visitante,
   **Then** o progresso volta a zero.

---

### User Story 4 - Carregando, erro e lista vazia (Priority: P2)

A pessoa abre o painel com internet lenta, sem internet ou num momento em que o serviço não tem
módulos. Ela sempre entende o que está acontecendo e sabe o que fazer.

**Why this priority**: o serviço de desenvolvimento leva até ~40 s para acordar e as atividades não
funcionam sem internet (RNF-002 não as inclui); sem esses estados a aba pareceria quebrada.

**Independent Test**: com o serviço falso atrasado, com erro e com lista vazia, conferir cada
estado e o "Tentar novamente".

**Acceptance Scenarios**:

1. **Given** o serviço demora, **When** a aba abre, **Then** aparece um indicador de carregamento
   no lugar dos cartões.
2. **Given** sem internet ou erro do serviço, **When** a carga falha, **Then** aparece uma mensagem
   de erro com "Tentar novamente"; tocar nele recarrega.
3. **Given** o serviço devolve zero módulos, **When** o painel carrega, **Then** aparece uma
   mensagem dizendo que ainda não há atividades, sem progresso geral.
4. **Given** o painel já carregado, **When** uma recarga ao voltar falha, **Then** os cartões já
   mostrados continuam visíveis (não troca pela tela de erro).

---

### Edge Cases

- **Módulo sem lições** (CB-012): aparece como "Indisponível", não abre e não conta no total de
  lições do progresso geral.
- **Todas as lições concluídas**: progresso geral cheio e todos os cartões "Concluído".
- **Nenhuma lição disponível no total** (todos os módulos sem lições): o progresso geral não é
  mostrado (não há "0 de 0").
- **Progresso do serviço inconsistente** (concluídas maior que o total): o cartão mostra no máximo
  o total e o status "Concluído".
- **Descrição longa ou letra no nível máximo**: o cartão cresce em altura; nada é cortado sem
  possibilidade de rolar.
- **Sessão expira** com o painel aberto: na próxima carga o painel passa a se comportar como o do
  visitante, sem erro.
- **Idioma em inglês**: os textos do app (status, progresso, mensagens) aparecem em inglês; títulos
  e descrições dos módulos vêm do serviço e não são traduzidos.
- **Leitor de tela**: cada cartão é lido como um item só, com título, status e progresso, e anuncia
  que pode ser aberto (exceto o indisponível).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A aba Atividades MUST mostrar o painel de atividades no lugar da tela provisória.
- **FR-002**: O painel MUST mostrar o progresso geral como "X de Y lições concluídas" e uma barra
  proporcional, onde Y soma as lições de todos os módulos disponíveis e X as concluídas pela pessoa
  (RF-023).
- **FR-003**: O painel MUST mostrar um cartão por módulo, na ordem definida pelo serviço, com
  ícone, título, descrição, progresso do módulo ("X de Y lições") e status.
- **FR-004**: O status de cada módulo MUST ser: **Não iniciado** (nenhuma lição concluída),
  **Em andamento** (parte concluída), **Concluído** (todas concluídas) ou **Indisponível** (o
  módulo não tem lições, CB-012). Cada status MUST ter rótulo escrito, além de cor ou ícone.
- **FR-005**: Tocar num módulo disponível MUST abrir a tela daquele módulo, uma única vez mesmo com
  toques repetidos. Um módulo indisponível MUST NOT abrir.
- **FR-006**: Ao voltar para o painel (de um módulo ou de outra aba), o progresso MUST ser
  atualizado sem ação da pessoa.
- **FR-007**: Para quem tem conta, o progresso MUST vir do serviço.
- **FR-008**: Para o visitante, o progresso MUST vir do registro de lições concluídas na sessão
  atual do app; o registro MUST ficar só na memória (não sobrevive ao fechar o app) e MUST ser
  descartado ao entrar numa conta, ao sair ou ao iniciar uma nova sessão de visitante (RN-006).
- **FR-009**: O registro de progresso do visitante MUST permitir que a resposta das perguntas (B3)
  marque uma lição como concluída e que o painel e as telas de atividades leiam esse progresso.
- **FR-010**: O painel do visitante MUST mostrar um aviso curto de que, sem conta, o progresso vale
  só até fechar o app.
- **FR-011**: O painel MUST ter os estados de carregando, erro com "Tentar novamente" e "sem
  atividades". Uma recarga que falha com conteúdo já mostrado MUST manter o conteúdo.
- **FR-012**: Ícone ausente ou que não carrega MUST dar lugar a um ícone padrão.
- **FR-013**: O painel MUST seguir o padrão de acessibilidade do app (RNF-003/RNF-004): alvos de
  toque ≥ 48 dp, texto base ≥ 16 sp, tamanho de letra e alto contraste da B9, cada cartão lido pelo
  leitor de tela como um item com título, status e progresso.
- **FR-014**: Todos os textos do app no painel MUST estar em português e inglês; títulos e
  descrições dos módulos vêm do serviço como estão.
- **FR-015**: O visitante MUST conseguir ver o painel e abrir módulos sem conta (a leitura dos
  módulos não exige login).

### Key Entities

- **Módulo de atividades**: identificador, título, descrição, ordem, ícone (opcional), número de
  lições, lições concluídas pela pessoa e porcentagem. O status (não iniciado, em andamento,
  concluído, indisponível) é derivado do número de lições e das concluídas.
- **Painel de atividades**: a lista de módulos e os totais gerais (lições concluídas e
  disponíveis).
- **Progresso do visitante na sessão**: quais lições de quais módulos o visitante concluiu desde
  que abriu o app; só em memória.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com o serviço já acordado, o painel aparece completo em até 2 segundos ao abrir a aba
  numa conexão típica.
- **SC-002**: A partir do painel, a pessoa chega às perguntas de um módulo em 1 toque.
- **SC-003**: Em 100% dos casos, o status mostrado em cada cartão corresponde às lições concluídas
  (nenhum módulo concluído aparecendo como "em andamento" e vice-versa).
- **SC-004**: Ao voltar de um módulo, o progresso atualizado aparece sem a pessoa precisar fazer
  nada.
- **SC-005**: Sem internet, a pessoa vê uma mensagem clara e consegue recarregar com 1 toque quando
  a conexão voltar.
- **SC-006**: Com a letra no nível máximo e o alto contraste ligado, todos os cartões ficam
  legíveis e tocáveis no aparelho.
- **SC-007**: O progresso do visitante nunca aparece depois de fechar o app ou de trocar de sessão.

## Assumptions

- **Formato dos dados**: os módulos e totais vêm do serviço como no contrato da API e como
  conferido em 2026-10-19 (visitante recebe 200 com progresso zerado). O app deriva o status; o
  serviço não manda um status pronto.
- **Totais com módulos indisponíveis**: o serviço manda os totais gerais prontos; como módulos sem
  lições não somam lições, os totais já os excluem.
- **Visitante**: os totais do serviço vêm zerados para ele; o app recalcula as concluídas a partir
  do registro da sessão e usa o número de lições de cada módulo vindo do serviço.
- **Layout**: os cartões ficam em uma coluna (um por linha), mais fácil de ler e tocar para o
  público idoso e com letra grande; "grade" no RF-023 é lida como a coleção de módulos, não como
  várias colunas.
- **Sem offline**: as atividades não estão entre o que precisa funcionar sem internet (RNF-002);
  sem conexão, vale o estado de erro.
- **Tela do módulo**: a rota `/activities/:moduleId` já existe e continua com a tela provisória
  até a B2; esta feature só leva até ela.
- **Visual**: segue o design system do app (cartões, cores e tipografia já usados no Início e nas
  Configurações); não há quadro do Figma específico para o painel.
- **Independência do Perfil**: o Perfil já lê esse mesmo serviço para as conquistas; o módulo de
  atividades terá a própria leitura, sem depender do Perfil (regra de módulos do projeto).
- **Fora desta feature**: perguntas (B2), correção e pontuação (B3), conclusão e aviso de login
  (B4); a gravação das respostas do visitante no registro da sessão é feita pela B3.
