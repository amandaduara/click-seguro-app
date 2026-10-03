# Feature Specification: Login, cadastro, visitante e recuperação de senha

**Feature Branch**: `003-login-cadastro-visitante`

**Created**: 2026-10-03

**Status**: Draft

**Input**: User description: "Tarefa A2 do .specify/memory/tasks.md: tela de login, cadastro, entrada como visitante e recuperação de senha (RF-003 a RF-006, RN-001, RN-003, CB-002, CB-013), seguindo o visual do wireframe em wireframe/src/components/screens/LoginScreen.tsx (alternância Entrar/Criar conta, campos com ícone, mostrar/ocultar senha, "Esqueci minha senha", "Continuar sem login") e os endpoints de autenticação do .specify/memory/api-contract.md (cadastro não devolve token: cadastro → login → GET /users/me → salvar sessão; recuperação em 3 passos: e-mail → código → nova senha). Usa a sessão v2 da feature 002. A Fase 0 (shell, i18n por módulo, estados comuns) ainda não está pronta: a A2 traz as próprias rotas e chaves de tradução no módulo authentication."

**Rastreabilidade**: tarefa A2 · RF-003, RF-004, RF-005, RF-006, RN-001, RN-003, RNF-003,
RNF-004, RNF-006, CB-002, CB-004 da [especificação do produto](../../.specify/memory/specification.md)
v2.1.0 · seção "Autenticação" do [contrato da API](../../.specify/memory/api-contract.md) ·
usa a sessão das features [001](../001-sessao-persistente-visitante/spec.md) e
[002](../002-apiclient-renovacao-sessao/spec.md) · visual: `wireframe/src/components/screens/LoginScreen.tsx`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Entrar com e-mail e senha (Priority: P1)

Uma pessoa que já tem conta abre o app, vê a tela "Bem-vindo ao SafeNews" no modo "Entrar",
digita e-mail e senha e toca em "Entrar". O app confirma a conta e a leva para a área principal,
já cumprimentando pelo nome.

**Why this priority**: sem login, nenhuma função personalizada existe (salvar, curtir,
progresso, perfil). É a porta de entrada de todo usuário cadastrado.

**Independent Test**: com uma conta de teste, abrir a tela, entrar com e-mail e senha corretos e
verificar que o app sai da tela de login, guarda a sessão (sobrevive a fechar e reabrir) e conhece
o nome do usuário. Repetir com a senha errada e ver a mensagem de erro, sem sair da tela.

**Acceptance Scenarios**:

1. **Given** o usuário está na tela de login no modo "Entrar", **When** informa e-mail e senha
   corretos e toca em "Entrar", **Then** o app mostra que está processando, desabilita o botão até
   terminar e, ao concluir, leva à área principal com a sessão conectada e o nome do usuário.
2. **Given** o usuário informa e-mail ou senha incorretos, **When** toca em "Entrar", **Then**
   permanece na tela, os campos continuam preenchidos (a senha também) e aparece "E-mail ou senha
   incorretos."
3. **Given** o aparelho está sem internet, **When** o usuário toca em "Entrar", **Then** aparece
   "Sem conexão com a internet. Verifique sua rede." e ele continua na tela (CB-002).
4. **Given** o campo de senha está preenchido, **When** o usuário toca no ícone do olho, **Then**
   a senha fica visível; tocando de novo, fica oculta. O ícone tem rótulo para leitor de tela
   ("Mostrar senha" / "Ocultar senha").
5. **Given** o e-mail está vazio ou sem formato válido, **When** o usuário toca em "Entrar",
   **Then** o app mostra o erro no próprio campo e não envia nada ao serviço.

---

### User Story 2 - Criar conta (Priority: P1)

Uma pessoa sem conta toca em "Criar conta" no seletor do topo, preenche nome, e-mail e senha e
toca em "Criar conta". O app cria a conta e já entra com ela, sem pedir para digitar tudo de novo.

**Why this priority**: sem cadastro não há usuários novos. Tem a mesma prioridade do login,
porque um não serve sem o outro na primeira entrega.

**Independent Test**: criar uma conta com dados válidos e verificar que o app entra direto na área
principal com a sessão conectada. Tentar com um e-mail já cadastrado e com uma senha fraca e ver as
mensagens certas.

**Acceptance Scenarios**:

1. **Given** o usuário está no modo "Criar conta", **When** informa nome, e-mail e senha válidos e
   toca em "Criar conta", **Then** a conta é criada, o app entra com ela e leva à área principal
   com o nome informado.
2. **Given** o e-mail informado já tem conta, **When** o usuário toca em "Criar conta", **Then**
   aparece "Este e-mail já está cadastrado." com a opção de ir para "Entrar" mantendo o e-mail.
3. **Given** a senha não atende às regras (RN-001), **When** o usuário toca em "Criar conta",
   **Then** o app mostra no campo o que falta (ex.: "Inclua um caractere especial") sem enviar nada.
4. **Given** o nome tem menos de 6 caracteres, **When** o usuário toca em "Criar conta", **Then**
   o app pede o nome completo no próprio campo, sem enviar nada.
5. **Given** o usuário está digitando a senha no modo "Criar conta", **When** olha abaixo do
   campo, **Then** vê as regras da senha, e cada uma fica marcada à medida que é atendida.
6. **Given** o usuário alternou entre "Entrar" e "Criar conta", **When** volta ao modo anterior,
   **Then** o e-mail digitado continua lá, e as mensagens de erro do outro modo somem.

---

### User Story 3 - Continuar sem login (Priority: P2)

Alguém quer conhecer o app antes de criar conta. Toca em "Continuar sem login" e entra na área
principal como visitante, podendo ler e praticar (RN-003).

**Why this priority**: reduz a barreira de entrada (RF-005), mas depende só da sessão de
visitante, que já existe (feature 001). É uma ação simples.

**Independent Test**: tocar em "Continuar sem login" e verificar que o app vai para a área
principal com a sessão no estado visitante, sem chamar o serviço; fechar e reabrir e continuar
visitante.

**Acceptance Scenarios**:

1. **Given** o usuário está na tela de login, **When** toca em "Continuar sem login", **Then**
   entra na área principal como visitante, sem preencher nada e sem esperar o serviço.
2. **Given** o aparelho está sem internet, **When** o usuário toca em "Continuar sem login",
   **Then** entra normalmente como visitante.

---

### User Story 4 - Recuperar a senha (Priority: P2)

A pessoa esqueceu a senha. Toca em "Esqueci minha senha", informa o e-mail, recebe um código por
e-mail, digita o código e cria uma senha nova. Depois volta à tela de login com o e-mail já
preenchido e entra com a senha nova.

**Why this priority**: sem recuperação, quem esquece a senha perde a conta. Para o público idoso
isso é frequente, mas não bloqueia o primeiro uso.

**Independent Test**: com uma conta de teste, percorrer os três passos e entrar com a senha nova.
Errar o código e ver a mensagem, sem avançar.

**Acceptance Scenarios**:

1. **Given** o usuário tocou em "Esqueci minha senha", **When** informa o e-mail e toca em
   "Enviar código", **Then** vai para o passo do código com a mensagem "Se houver uma conta com
   este e-mail, enviamos um código." (o app nunca revela se o e-mail existe).
2. **Given** o usuário está no passo do código, **When** digita um código válido e toca em
   "Continuar", **Then** vai para o passo da nova senha.
3. **Given** o usuário digita um código errado ou vencido, **When** toca em "Continuar", **Then**
   aparece "Código inválido. Confira o e-mail ou peça um novo." e ele continua no passo do código.
4. **Given** o usuário está no passo do código, **When** toca em "Reenviar código", **Then** um
   novo código é pedido, e o botão fica indisponível por 60 segundos, com contagem visível.
5. **Given** o usuário está no passo da nova senha, **When** informa uma senha válida (RN-001),
   confirma a senha igual e toca em "Salvar nova senha", **Then** volta à tela de login, no modo
   "Entrar", com o e-mail preenchido e a mensagem "Senha alterada. Entre com a nova senha."
6. **Given** a confirmação é diferente da senha, **When** toca em "Salvar nova senha", **Then** o
   app mostra o erro no campo de confirmação, sem enviar nada.
7. **Given** o usuário está em qualquer passo, **When** toca em voltar, **Then** retorna ao passo
   anterior (ou à tela de login, a partir do primeiro passo).

---

### Edge Cases

- **Toque duplo no botão:** enquanto um envio está em andamento, o botão fica desabilitado e
  mostra que está processando; um segundo toque não gera outro pedido.
- **Cadastro criado, mas a entrada automática falhou** (sem rede logo depois, por exemplo): a conta
  existe. O app volta ao modo "Entrar" com o e-mail preenchido e a mensagem "Conta criada. Entre
  com seu e-mail e senha."
- **Conta do painel administrativo** (papel diferente de usuário do app): tratada como e-mail ou
  senha incorretos, sem conectar.
- **Erro do servidor ou resposta inesperada:** "Não foi possível concluir agora. Tente novamente."
  (CB-004), sem travar a tela e sem detalhes técnicos.
- **E-mail com espaços ou letras maiúsculas:** espaços nas pontas são removidos antes de enviar; o
  restante vai como digitado.
- **Visitante que decide criar conta** (vindo depois do convite do RN-003): a mesma tela, no modo
  "Criar conta". Ao concluir, a marca de visitante some (feature 001).
- **Teclado:** o campo de e-mail abre o teclado de e-mail; "próximo" no teclado passa ao campo
  seguinte; no último campo, "concluir" envia o formulário.
- **Fonte ampliada (até 1,5×):** a tela rola, e nenhum texto ou botão fica cortado (RNF-003).

## Requirements *(mandatory)*

### Functional Requirements

**Tela de login e cadastro**

- **FR-001**: A tela MUST seguir o wireframe: marca e "Bem-vindo ao SafeNews" no topo, seletor
  "Entrar" / "Criar conta", campos com ícone (nome só no cadastro, e-mail, senha), "Esqueci minha
  senha" só no modo "Entrar", botão principal, separador "ou" e o botão "Continuar sem login".
- **FR-002**: O usuário MUST poder alternar entre "Entrar" e "Criar conta" sem perder o e-mail já
  digitado; as mensagens de erro do modo anterior MUST ser limpas.
- **FR-003**: O campo de senha MUST ter ação de mostrar/ocultar, com rótulo acessível.
- **FR-004**: Antes de qualquer envio, o app MUST validar os campos pelas regras do RN-001 (nome de
  6 a 150 caracteres; e-mail válido até 255; senha de 8 a 64 com maiúscula, minúscula, número e
  caractere especial) e mostrar o erro no próprio campo, sem chamar o serviço. No modo "Entrar", só
  o formato do e-mail e a senha não vazia são exigidos (quem já tem conta não é barrado por regras
  novas de senha).
- **FR-005**: No modo "Criar conta", o app MUST mostrar as regras da senha abaixo do campo e
  marcar cada uma quando atendida.
- **FR-006**: Durante um envio, o botão MUST ficar desabilitado e indicar processamento; um novo
  toque MUST NOT gerar outro pedido.

**Entrada, cadastro e visitante**

- **FR-007**: Ao entrar com sucesso, o app MUST guardar a sessão conectada (credenciais, e-mail e
  nome do usuário) e levar à área principal.
- **FR-008**: Ao criar a conta com sucesso, o app MUST entrar com ela automaticamente, guardar a
  sessão como no FR-007 e levar à área principal.
- **FR-009**: Se a conta foi criada mas a entrada automática falhar, o app MUST voltar ao modo
  "Entrar" com o e-mail preenchido e a mensagem "Conta criada. Entre com seu e-mail e senha."
- **FR-010**: "Continuar sem login" MUST iniciar a sessão de visitante e levar à área principal,
  sem chamar o serviço.
- **FR-011**: Uma conta que não é de usuário do app MUST ser tratada como credenciais incorretas,
  sem conectar.

**Recuperação de senha**

- **FR-012**: A recuperação MUST ter três passos (e-mail → código → nova senha), cada um com
  botão de voltar ao passo anterior.
- **FR-013**: O passo do e-mail MUST avançar sempre que o serviço aceitar o pedido, com uma
  mensagem que não revela se o e-mail tem conta.
- **FR-014**: O passo do código MUST validar o código com o serviço antes de permitir criar a nova
  senha, porque o serviço não avisa se o código está errado na redefinição.
- **FR-015**: O passo do código MUST oferecer "Reenviar código", indisponível por 60 segundos
  depois de cada envio, com a contagem visível.
- **FR-016**: O passo da nova senha MUST exigir a senha pelas regras do RN-001 e a confirmação
  igual. Ao concluir, o app MUST voltar ao login, no modo "Entrar", com o e-mail preenchido e a
  mensagem de senha alterada.

**Mensagens e acessibilidade**

- **FR-017**: O app MUST mostrar mensagens distintas para: e-mail ou senha incorretos; e-mail já
  cadastrado (com atalho para "Entrar"); código inválido; sem conexão; erro genérico do servidor.
  Nenhuma mensagem MUST expor detalhes técnicos.
- **FR-018**: Todos os textos da tela MUST estar em português e inglês (RNF-006), com as chaves
  próprias do módulo de autenticação.
- **FR-019**: Todos os elementos interativos MUST ter rótulo para leitor de tela e alvo de toque
  de pelo menos 48×48; a tela MUST rolar sem cortes com fonte ampliada até 1,5× (RNF-003, RNF-004).
- **FR-020**: A senha MUST NOT aparecer em registros de diagnóstico (garantia já dada pela feature
  002 para as rotas de autenticação).

### Key Entities

- **Credenciais**: e-mail e senha informados pelo usuário. Existem só durante o envio; a senha
  nunca é guardada no aparelho.
- **Cadastro**: nome, e-mail e senha de uma conta nova.
- **Usuário**: o que o serviço devolve sobre a conta: nome, e-mail, telefone, foto e papel. O app
  só aceita o papel de usuário do app.
- **Pedido de recuperação**: e-mail, código recebido e nova senha. O código só vale se o serviço
  confirmar antes da troca.
- **Sessão**: a mesma das features 001 e 002, criada aqui como conectada ou visitante.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Uma pessoa com conta consegue entrar em até 30 segundos a partir da abertura da tela,
  com no máximo 3 toques além da digitação.
- **SC-002**: Criar conta leva no máximo um formulário: em 100% dos cadastros bem-sucedidos (com
  rede), o usuário chega à área principal sem digitar as credenciais de novo.
- **SC-003**: "Continuar sem login" leva à área principal com 1 toque, em 100% dos casos, com ou
  sem internet.
- **SC-004**: 100% dos envios com campos inválidos são barrados no próprio aparelho, sem pedido ao
  serviço.
- **SC-005**: A recuperação completa (os três passos) pode ser feita em até 3 minutos, sem contar
  a espera do e-mail.
- **SC-006**: Em 100% das falhas (senha errada, e-mail já usado, código inválido, sem rede, erro do
  servidor), o usuário vê uma mensagem em linguagem simples e continua na mesma tela com os dados
  preservados.
- **SC-007**: Com fonte em 1,5× e leitor de tela ligado, todos os campos e botões da tela de login
  e dos três passos são alcançáveis e anunciados com nome.

## Assumptions

- **Destino depois de entrar:** a "área principal" (aba Início) ainda não existe, porque o shell é
  da tarefa F0.9 e o feed, da A3. Até lá, esta entrega leva a uma tela de Início provisória, que
  será substituída sem mudar o comportamento descrito aqui.
- **Fora do escopo:** a decisão da tela inicial ao abrir o app (tarefa A1, inclusive ir direto à
  área principal com sessão salva), o botão "Sair" (B8), o convite para visitante em ações
  restritas (F0.9) e as telas de perfil e troca de senha (B7, B8).
- **Fase 0 incompleta:** por decisão de 2026-10-03, esta entrega começa antes do shell (F0.9), dos
  blocos de i18n por módulo (F0.8) e dos estados comuns (F0.10). As rotas e as chaves de tradução
  ficam no próprio módulo de autenticação, e os estados de carregamento e erro são resolvidos
  dentro desta tela. Quando a Fase 0 vier, ela reaproveita ou adapta o que for comum.
- **Serviço:** comportamento descrito no [contrato da API](../../.specify/memory/api-contract.md):
  o cadastro não devolve credencial (por isso o app entra logo em seguida), o login não devolve o
  usuário (por isso o app busca os dados da conta), e a redefinição sempre responde "ok", mesmo com
  código errado (por isso o código é validado antes).
- **Validade e formato do código:** definidos pelo serviço (mínimo de 6 caracteres). O app não
  limita o tipo de caractere.
- **Visual:** cores, tipografia, raios e componentes seguem o wireframe e o design system já
  existente (`Safe*`). O wireframe não tem as telas de recuperação, que seguem o mesmo padrão
  visual da tela de login.
