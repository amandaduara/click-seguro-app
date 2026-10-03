# Feature Specification: Comunicação com a API real e renovação da sessão

**Feature Branch**: `002-apiclient-renovacao-sessao`

**Created**: 2026-10-03

**Status**: Draft

**Input**: User description: "Tarefas F0.2 + F0.13 do .specify/memory/tasks.md: adequar o ApiClient à API real (código de erro lido de `code`, CancelToken no get, upload multipart) e renovação/validação de sessão com refreshToken (RF-007, CB-003, CB-013, CB-014), conforme .specify/memory/api-contract.md seção "Sessão e tokens" e o openapi.json."

**Rastreabilidade**: tarefas F0.2 e F0.13 · RF-007, RNF-005, RNF-007, CB-002, CB-003, CB-013 e
CB-014 da [especificação do produto](../../.specify/memory/specification.md) v2.1.0 · seção
"Sessão e tokens" do [contrato da API](../../.specify/memory/api-contract.md) v1.0.0 ·
completa as pendências da feature [001](../001-sessao-persistente-visitante/spec.md) (FR-008 e
FR-008a).

## Clarifications

### Session 2026-10-03

- Q: Ao abrir o app com uma sessão salva, a tela de abertura deve esperar a resposta do serviço (até 3 s) ou entrar logo e conferir em segundo plano? → A: Esperar na tela de abertura até 3 s. Com resposta, segue (conta confirmada) ou vai ao login (conta desativada ou renovação recusada); sem resposta no prazo, entra com a sessão guardada.
- Q: O app deve tentar renovar em qualquer recusa de pedido feito com credencial (exceto "credenciais inválidas") ou só quando o motivo for explicitamente de credencial vencida/inválida? → A: Em qualquer recusa de pedido com credencial, exceto o motivo "credenciais inválidas" (lista de exceções). Recusa sem motivo ou com motivo desconhecido também tenta renovar.
- Q: Se o serviço informar "usuário não encontrado" durante o uso, o app deve encerrar a sessão automaticamente ou deixar cada tela tratar como erro comum? → A: Encerrar automaticamente em qualquer pedido com credencial, como sessão expirada (usuário fica na tela, vê o aviso e faz login na próxima ação restrita). Na abertura, vale o FR-008 (vai direto ao login).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Continuar usando o app quando a credencial vence (Priority: P1)

Uma pessoa idosa está lendo notícias e toca em "salvar". Sem que ela perceba, a credencial de
acesso tinha vencido. O app consegue uma nova credencial com o serviço e conclui o salvamento,
sem mensagem de erro e sem pedir login.

**Why this priority**: a credencial de acesso vence em pouco tempo. Sem renovação, o usuário
seria mandado ao login várias vezes por semana, o que anula a sessão persistente da feature 001
e é a principal causa de abandono no público idoso.

**Independent Test**: com uma sessão cuja credencial de acesso já venceu (e a de renovação
ainda vale), fazer uma ação que exige conta e verificar que ela é concluída, que o usuário
continua conectado e que a nova credencial passa a ser usada, inclusive depois de fechar e
reabrir o app.

**Acceptance Scenarios**:

1. **Given** o usuário está conectado e a credencial de acesso venceu, **When** faz uma ação que
   exige conta, **Then** a ação é concluída sem aviso, e o usuário continua conectado.
2. **Given** a credencial foi renovada durante o uso, **When** o usuário fecha e reabre o app,
   **Then** o app abre conectado usando a credencial nova.
3. **Given** a credencial de acesso venceu e a de renovação também não vale mais, **When** o
   usuário faz uma ação que exige conta, **Then** a sessão é encerrada como expirada (CB-003):
   o usuário continua na tela e vê "Sua sessão expirou, faça login novamente."
4. **Given** várias partes da tela pedem dados ao mesmo tempo com a credencial vencida, **When**
   o serviço recusa todas, **Then** o app pede **uma única** renovação e todas as partes
   recebem seus dados.

---

### User Story 2 - Errar a senha atual não desconecta (Priority: P1)

Ao trocar a senha nas Configurações, o usuário digita a senha atual errada. O app diz "Senha
atual incorreta" e deixa ele tentar de novo, ainda conectado.

**Why this priority**: o serviço responde a senha errada com o mesmo tipo de recusa usado para
sessão vencida. Sem essa distinção, um simples erro de digitação desconectaria a pessoa, que
teria de lembrar a senha para entrar de novo, justamente a senha que ela acabou de errar.

**Independent Test**: com uma sessão ativa, simular a recusa do serviço por senha atual errada
e verificar que a sessão continua ativa, que nenhuma renovação foi tentada e que o erro chega à
tela com um código que permite mostrar "Senha atual incorreta". (A tela de troca de senha é da
tarefa B8.)

**Acceptance Scenarios**:

1. **Given** o usuário está conectado, **When** o serviço recusa a troca de senha porque a senha
   atual está errada, **Then** a sessão continua ativa e a tela recebe o motivo "credenciais
   inválidas".
2. **Given** o usuário está desconectado, **When** erra a senha no login, **Then** o app recebe o
   motivo "credenciais inválidas", não tenta renovação e não mostra aviso de sessão expirada.

---

### User Story 3 - Sessão confirmada ao abrir o app (Priority: P2)

Ao abrir o app com uma sessão salva, o app confere com o serviço se a conta ainda existe e
atualiza o nome usado na saudação. Se a conta foi desativada, a pessoa vai para o login. Se
estiver sem internet, entra normalmente com a sessão guardada.

**Why this priority**: fecha a pendência FR-008 da feature 001. Evita que alguém com a conta
desativada fique "conectado" sem conseguir fazer nada, e mantém o nome da saudação atualizado
se ele foi trocado em outro aparelho.

**Independent Test**: com uma sessão salva, abrir o app em três situações (serviço confirma a
conta com outro nome, serviço informa que a conta não existe, sem internet) e verificar o
resultado de cada uma.

**Acceptance Scenarios**:

1. **Given** existe uma sessão salva e o serviço confirma a conta, **When** o app é aberto,
   **Then** o usuário segue conectado, e o nome exibido passa a ser o que o serviço informou.
2. **Given** existe uma sessão salva e o serviço informa que a conta não existe mais, **When** o
   app é aberto, **Then** a sessão é encerrada e o usuário vai direto para o login (CB-014).
3. **Given** existe uma sessão salva e não há internet (ou o serviço está fora do ar), **When** o
   app é aberto, **Then** o usuário segue conectado com os dados guardados.
4. **Given** a credencial de acesso salva venceu, **When** o app é aberto, **Then** a renovação
   da história 1 acontece durante a conferência, e o usuário segue conectado.
5. **Given** a credencial de acesso salva venceu e a renovação é recusada, **When** o app é
   aberto, **Then** a sessão é encerrada e o usuário vai direto para o login, sem passar pelo
   conteúdo (CB-003, regra da abertura).
6. **Given** existe uma sessão salva e o serviço não responde em 3 segundos, **When** o app é
   aberto, **Then** o usuário segue conectado com os dados guardados, sem esperar mais.
7. **Given** o usuário é visitante, **When** o app é aberto, **Then** nenhuma conferência com o
   serviço é feita.

---

### User Story 4 - Mensagens de erro específicas do serviço (Priority: P3)

Quando o serviço recusa um pedido por um motivo conhecido (e-mail já cadastrado, código de
recuperação inválido, notícia não encontrada), a tela recebe esse motivo e pode mostrar uma
mensagem clara, em vez de um "erro inesperado" genérico.

**Why this priority**: hoje o app não reconhece o formato de erro do serviço real, então todo
motivo se perde. As telas das trilhas A e B dependem disso, mas cada uma é entregue na sua
tarefa.

**Independent Test**: simular respostas de erro do serviço com motivos conhecidos e verificar
que o motivo chega intacto a quem fez o pedido. Simular uma resposta de erro sem motivo (ou fora
do formato esperado) e verificar que o app trata como erro genérico, sem travar.

**Acceptance Scenarios**:

1. **Given** o serviço recusa um cadastro porque o e-mail já existe, **When** a resposta chega,
   **Then** o motivo "e-mail já cadastrado" chega a quem pediu.
2. **Given** o serviço devolve um erro de validação em formato diferente (lista de campos
   inválidos, sem motivo no topo), **When** a resposta chega, **Then** o app trata como dados
   inválidos genéricos, sem travar.
3. **Given** o serviço devolve uma página de erro que não é um dado estruturado, **When** a
   resposta chega, **Then** o app trata como erro do servidor, sem travar.

---

### User Story 5 - Base para busca e envio de foto (Priority: P3)

O app passa a conseguir (a) descartar uma busca antiga quando a pessoa digita de novo, para que
resultados velhos nunca apareçam por cima dos novos, e (b) enviar uma imagem ao serviço, como a
foto de perfil.

**Why this priority**: são capacidades de comunicação que as tarefas A3 (busca) e B7 (foto de
perfil) usam. Ficam aqui porque a parte comum do app é fechada depois da Fase 0.

**Independent Test**: (a) iniciar um pedido, descartá-lo antes da resposta e verificar que
quem pediu recebe "cancelado", e não um erro; (b) enviar um arquivo de imagem e verificar que o
serviço o recebe no campo esperado, com a credencial do usuário.

**Acceptance Scenarios**:

1. **Given** um pedido de busca está em andamento, **When** ele é descartado, **Then** quem pediu
   recebe o motivo "cancelado", que as telas ignoram (sem mensagem de erro).
2. **Given** o usuário está conectado, **When** o app envia uma imagem, **Then** o serviço recebe
   o arquivo no campo combinado, e a resposta segue o mesmo tratamento de erro dos demais
   pedidos (inclusive a renovação da história 1).

---

### Edge Cases

- **Renovação sem internet:** se a renovação falhar por falta de conexão ou erro do servidor, a
  sessão **não** é encerrada; a ação original termina com "Sem conexão com a internet" (CB-002)
  ou erro do servidor (CB-004), e a próxima ação tenta de novo.
- **Pedido recusado de novo logo após renovar:** a renovação acontece no máximo uma vez por
  pedido. Se o pedido repetido for recusado outra vez, a sessão é encerrada como expirada, sem
  ciclo infinito.
- **Usuário sai da conta enquanto uma renovação está em andamento:** o resultado da renovação é
  descartado, e o usuário continua desconectado.
- **Conta desativada durante o uso:** o próximo pedido com credencial que receber "usuário não
  encontrado" encerra a sessão como expirada (FR-008a); o usuário continua na tela e vê o
  aviso.
- **Visitante:** pedidos de visitante nunca enviam credencial e nunca disparam renovação, nem
  encerramento de sessão.
- **Sessão salva por uma versão anterior do app** (sem credencial de renovação): o app trata como
  sessão encerrada e abre no login. O app ainda não foi publicado, então só as pessoas que
  desenvolvem são afetadas.
- **Credencial ou credencial de renovação em registros de diagnóstico:** nenhuma das duas pode
  aparecer, nem no pedido de renovação, nem com o modo de desenvolvimento ligado (RNF-007).
- **Conferência na abertura demorando:** a abertura não pode ficar presa esperando o serviço;
  passados 3 segundos, o app segue com a sessão guardada, e uma resposta que chegue depois é
  ignorada nessa abertura (a validade volta a ser conferida na próxima ação que usar o serviço).
- **Conta com papel diferente de usuário do app** (conta do painel administrativo): fica para a
  tarefa A2, que trata o login. Esta entrega não decide nada sobre papéis.

## Requirements *(mandatory)*

### Functional Requirements

**Renovação e encerramento (F0.13)**

- **FR-001**: A sessão conectada MUST guardar duas credenciais: a de acesso e a de renovação,
  ambas apenas no armazenamento protegido do aparelho (RNF-007).
- **FR-002**: Quando um pedido feito com credencial receber recusa de autorização, com
  **qualquer motivo exceto "credenciais inválidas"** (inclusive sem motivo ou com motivo
  desconhecido), o app MUST pedir ao serviço uma nova credencial usando a de renovação e, se
  conseguir, MUST guardar as novas credenciais e repetir o pedido original uma única vez.
- **FR-003**: Se a renovação for recusada pelo serviço, o app MUST encerrar a sessão como
  expirada, com o comportamento já definido na feature 001 (usuário fica na tela e vê o aviso).
- **FR-004**: Se a renovação falhar por falta de conexão, tempo esgotado ou erro do servidor, o
  app MUST manter a sessão e devolver a falha correspondente à ação original.
- **FR-005**: Pedidos recusados ao mesmo tempo MUST compartilhar uma única renovação; nenhum
  pedido MUST disparar uma segunda renovação enquanto a primeira estiver em andamento.
- **FR-006**: Uma recusa com o motivo "credenciais inválidas" MUST NOT encerrar a sessão nem
  disparar renovação. Ela MUST chegar a quem fez o pedido com esse motivo (CB-013).
- **FR-007**: Recusas em pedidos feitos sem credencial (login, cadastro, recuperação de senha,
  pedidos de visitante) MUST NOT encerrar a sessão nem disparar renovação.
- **FR-008**: Ao abrir o app com uma sessão conectada salva, o app MUST conferir a conta com o
  serviço **durante a tela de abertura, antes de mostrar a primeira tela**, e atualizar nome e
  e-mail guardados com a resposta. Se o serviço informar que a conta não existe (CB-014) ou
  recusar a renovação (CB-003), MUST encerrar a sessão e levar direto ao login. Se não houver
  resposta por falta de conexão, erro do servidor ou tempo esgotado, MUST manter a sessão
  guardada.
- **FR-008a**: Em qualquer pedido feito com credencial durante o uso, a resposta "usuário não
  encontrado" (conta desativada) MUST encerrar a sessão como expirada, com o mesmo
  comportamento de FR-003, sem que cada tela precise tratar o caso (CB-014). Na abertura do
  app vale o FR-008.
- **FR-009**: A conferência da abertura, incluindo uma eventual renovação, MUST esperar no
  máximo 3 segundos (limite do SC-002 da feature 001). Passado o prazo, o app MUST seguir com a
  sessão guardada e ignorar a resposta atrasada nessa abertura.
- **FR-010**: A sessão MUST identificar o usuário pelo e-mail (e guardar o nome de exibição), já
  que o serviço não fornece um identificador numérico. Substitui o "identificador do usuário"
  da feature 001 (FR-011 de lá).
- **FR-011**: Uma sessão salva sem credencial de renovação MUST ser tratada como inválida:
  descartada, com o app abrindo no login.
- **FR-012**: Se o usuário encerrar a sessão enquanto uma renovação está em andamento, o
  resultado da renovação MUST ser descartado.

**Comunicação com o serviço (F0.2)**

- **FR-013**: O app MUST ler o motivo das recusas do serviço no formato real da API (campo de
  código de negócio), deixando-o disponível para quem fez o pedido.
- **FR-014**: Respostas de erro sem código de negócio, em outro formato estruturado ou que não
  sejam dados estruturados MUST ser tratadas pelas regras genéricas já existentes (dados
  inválidos, erro do servidor), sem travar o app (CB-004, CB-005).
- **FR-015**: Quem faz uma consulta MUST poder descartá-la antes da resposta. Um pedido
  descartado MUST terminar com o motivo "cancelado", distinto de qualquer erro (RNF-005).
- **FR-016**: O app MUST conseguir enviar um arquivo de imagem ao serviço num campo nomeado,
  com a credencial do usuário, e esse envio MUST seguir as mesmas regras de erro e de renovação
  dos demais pedidos.
- **FR-017**: Nenhuma das credenciais MUST aparecer em registros de diagnóstico, incluindo o
  corpo do pedido e da resposta de renovação, mesmo com o modo de desenvolvimento ligado.
- **FR-018**: O guia de integração do projeto MUST passar a descrever o formato real de erro do
  serviço, para que as próximas tarefas sigam o mesmo padrão.

### Key Entities

- **Sessão**: quem está usando o app no aparelho. Atributos (quando conectado): credencial de
  acesso, credencial de renovação, e-mail, nome de exibição; e o estado e o motivo do último
  encerramento, que já existiam. Deixa de ter o "identificador do usuário".
- **Recusa do serviço**: resposta de erro com um código de situação (ex.: não autorizado,
  conflito), um código de negócio opcional (ex.: "credenciais inválidas", "e-mail já
  cadastrado", "credencial inválida") e uma mensagem. O código de negócio é o que decide entre
  renovar, manter a sessão ou só repassar o erro.
- **Renovação em andamento**: pedido de nova credencial que pode estar em curso; os pedidos
  recusados no mesmo período esperam por ele em vez de iniciar outro.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% das ações feitas com a credencial de acesso vencida (e a de renovação
  válida), a ação é concluída sem mensagem de erro e sem pedido de login.
- **SC-002**: Com cinco pedidos recusados ao mesmo tempo por credencial vencida, o serviço recebe
  exatamente um pedido de renovação, e os cinco pedidos terminam com sucesso.
- **SC-003**: Em 100% dos casos de senha atual errada na troca de senha, o usuário continua
  conectado.
- **SC-004**: Nenhum pedido é repetido mais de uma vez por renovação: em 100% dos testes com
  recusa repetida, o fluxo termina com a sessão expirada, sem ciclo.
- **SC-005**: Na abertura com sessão salva, a primeira tela útil aparece em até 3 segundos, com
  ou sem resposta do serviço.
- **SC-006**: Em 100% das aberturas sem internet com sessão salva, o usuário continua conectado.
- **SC-007**: 100% dos códigos de negócio listados no contrato da API chegam intactos a quem fez
  o pedido, e 0 respostas fora do formato causam fechamento inesperado do app.
- **SC-008**: Nenhuma ocorrência de credencial (de acesso ou de renovação) é encontrada em
  registros de diagnóstico numa auditoria com o modo de desenvolvimento ligado.

## Assumptions

- **Fora do escopo:** telas de login, cadastro e recuperação de senha (A2), tela de troca de
  senha (B8), busca do feed (A3) e foto de perfil (B7). Esta entrega fornece as capacidades que
  essas telas usam, verificadas por testes automatizados. O aviso de sessão expirada na tela
  continua sendo da tarefa F0.9.
- O comportamento do serviço é o descrito no [openapi.json](../../.specify/memory/openapi.json):
  renovação devolve um novo par de credenciais, recusa da renovação vem com o motivo
  "credencial inválida", e a conferência da conta informa "usuário não encontrado" para conta
  desativada. Se o servidor real divergir, o contrato da API é corrigido antes de concluir.
- A renovação é **reativa** (acontece quando o serviço recusa), não preventiva. Não é preciso
  saber a validade da credencial com antecedência.
- O login e o cadastro em si (que passam a gravar as duas credenciais, o nome e o e-mail) são
  da tarefa A2. Esta entrega prepara a sessão para recebê-los.
- O app ainda não foi publicado: descartar sessões salvas no formato antigo só afeta quem
  desenvolve.
- O limite de 3 segundos vem da feature 001 (SC-002) e vale para a abertura inteira, incluindo a
  conferência e uma eventual renovação.
