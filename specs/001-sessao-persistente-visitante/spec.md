# Feature Specification: Sessão persistente com modo visitante

**Feature Branch**: `001-sessao-persistente-visitante`

**Created**: 2026-09-26

**Status**: Draft

**Input**: User description: "Sessão persistente com modo visitante (tarefas F0.1, F0.3 e F0.4 do .specify/memory/tasks.md). O token deve sobreviver ao fechamento do app, deve existir o status "visitante" e a sessão deve ser restaurada ao abrir. Siga RF-005, RF-007 e RNF-007 de .specify/memory/specification.md."

**Rastreabilidade**: tarefas F0.1, F0.3 e F0.4 · RF-005, RF-007, RF-008, RNF-007 e RN-007 da
[especificação do produto](../../.specify/memory/specification.md) v2.0.0 · CB-003.

## Clarifications

### Session 2026-09-26

- Q: Quando a credencial de acesso vencer, o app deve tentar renová-la sozinho antes de mandar o usuário ao login? → A: Ainda não se sabe se a API oferece renovação. Fica registrado como pendência no contrato da API e, até a confirmação, credencial vencida ou recusada sempre encerra a sessão, sem renovação automática (o que acontece na tela segue a resposta seguinte).
- Q: Se a sessão for recusada enquanto a pessoa está no meio de algo, o app deve levá-la ao login na hora ou depois? → A: Não interromper: a sessão é encerrada, aparece um aviso de sessão expirada e o login só é pedido na próxima ação que exigir conta (ou na próxima abertura do app).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Continuar conectado depois de fechar o app (Priority: P1)

Uma pessoa idosa entra no SafeNews com e-mail e senha. Dias depois, abre o app de novo e cai
direto no conteúdo, sem precisar lembrar a senha nem digitar nada.

**Why this priority**: para o público idoso, pedir login a cada abertura é a principal causa de
abandono. Sem sessão persistente, nenhuma função personalizada (salvos, progresso, perfil) é
usável no dia a dia.

**Independent Test**: fazer login, fechar o app completamente (inclusive tirar da lista de apps
recentes), reabrir e verificar que o app abre já conectado com o mesmo usuário. Até a tela de
login (A2) existir, pode ser verificado pelos testes automatizados da sessão, simulando o
fechamento e a reabertura.

**Acceptance Scenarios**:

1. **Given** o usuário entrou com sua conta, **When** fecha e reabre o app, **Then** o app abre
   conectado, com o mesmo nome de usuário, sem pedir login.
2. **Given** o usuário entrou com sua conta, **When** o aparelho é reiniciado e o app é aberto,
   **Then** o app abre conectado.
3. **Given** existe uma sessão salva, **When** o app é aberto, **Then** a verificação acontece
   durante a tela de abertura, antes de qualquer tela de conteúdo ou de login aparecer.
4. *(Quando o FR-008 for ativado)* **Given** existe uma sessão salva **e** o serviço informa que ela não vale mais, **When** o
   app é aberto, **Then** o usuário vai para o login com a mensagem "Sua sessão expirou, faça
   login novamente."

---

### User Story 2 - Usar o app como visitante (Priority: P2)

Alguém quer conhecer o app antes de criar conta, ou prefere não se cadastrar. Escolhe "Entrar
como visitante" e usa o app normalmente, dentro dos limites do visitante. Ao reabrir, continua
como visitante, sem ter que escolher de novo.

**Why this priority**: o modo visitante reduz a barreira de entrada (RF-005). Ele depende da
mesma base de sessão da história 1, por isso vem logo depois.

**Independent Test**: escolher o modo visitante, verificar que o app reconhece o estado
"visitante" (diferente de "conectado" e de "desconectado"), fechar e reabrir e verificar que
continua visitante.

**Acceptance Scenarios**:

1. **Given** o usuário está desconectado, **When** escolhe entrar como visitante, **Then** o
   estado da sessão passa a ser "visitante" e nenhuma conta ou credencial é criada.
2. **Given** o usuário é visitante, **When** fecha e reabre o app, **Then** continua visitante.
3. **Given** o usuário é visitante, **When** entra com uma conta ou se cadastra, **Then** o
   estado passa a ser "conectado" e a marca de visitante deixa de existir.
4. **Given** o usuário é visitante, **When** sai do modo visitante, **Then** o estado passa a
   ser "desconectado" e a próxima abertura leva ao login.

---

### User Story 3 - Encerrar a sessão com segurança (Priority: P3)

O usuário sai da conta (por exemplo, antes de emprestar o celular) ou a sessão expira enquanto
ele usa o app. Em ambos os casos, a credencial é apagada do aparelho, mas os dados que pertencem
ao aparelho continuam lá.

**Why this priority**: complementa as histórias 1 e 2. O botão de sair fica nas Configurações
(tarefa B8), mas a regra do que é apagado e do que é mantido pertence à sessão.

**Independent Test**: com uma sessão ativa, encerrar a sessão e verificar que a credencial e a
identidade do usuário sumiram, que a próxima abertura leva ao login e que as preferências e os
contatos do aparelho continuam intactos.

**Acceptance Scenarios**:

1. **Given** o usuário está conectado, **When** encerra a sessão, **Then** a credencial, o
   identificador e o nome do usuário são removidos do aparelho e o estado passa a ser
   "desconectado".
2. **Given** a sessão foi encerrada, **When** o app é reaberto, **Then** abre na tela de login.
3. **Given** o usuário tem contatos pessoais e preferências de acessibilidade salvos, **When**
   encerra a sessão, **Then** esses dados continuam no aparelho (RN-007).
4. **Given** o usuário está usando o app, **When** o serviço recusa a sessão por expiração,
   **Then** a sessão é encerrada como no cenário 1, o usuário **continua na tela em que
   estava** e vê o aviso "Sua sessão expirou, faça login novamente." com a opção de entrar.
5. **Given** a sessão expirou durante o uso e o usuário continuou na tela, **When** ele tenta
   uma ação que exige conta (salvar, curtir, abrir notificações ou perfil), **Then** o app
   pede o login antes de executar a ação.

---

### Edge Cases

- **Sem internet ao abrir, com sessão salva:** o usuário continua conectado (não é deslogado por
  estar offline). A validade é conferida na próxima ação que usar a internet.
- **Dados de sessão ilegíveis ou corrompidos no aparelho:** o app trata como desconectado, apaga
  o que estiver inválido e abre normalmente, sem travar nem mostrar erro técnico.
- **Serviço fora do ar (erro do servidor) ao validar na abertura:** mantém a sessão salva, como
  no caso offline. Só uma recusa explícita da sessão desconecta.
- **App reinstalado ou dados do app apagados pelo sistema:** a sessão não existe mais e o app
  abre no login. É o comportamento esperado.
- **Visitante que já tinha passado pelo onboarding:** reabrir como visitante não mostra o
  onboarding de novo (RN-004 continua valendo).
- **Troca de conta no mesmo aparelho:** depois de encerrar a sessão da conta A e entrar com a
  conta B, nenhum dado de identidade da conta A permanece na sessão.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app MUST manter a sessão de um usuário conectado depois do fechamento do app e da
  reinicialização do aparelho, até que ela seja encerrada ou recusada pelo serviço.
- **FR-002**: O app MUST restaurar a sessão salva durante a tela de abertura, antes de decidir
  qual será a primeira tela exibida.
- **FR-003**: A sessão MUST estar sempre em exatamente um de três estados: **conectado**,
  **visitante** ou **desconectado**.
- **FR-004**: Toda mudança de estado da sessão MUST ser percebida imediatamente pelas partes do
  app que dependem dela (por exemplo, a navegação voltar ao login quando o usuário sai da
  conta, ou o aviso de sessão expirada aparecer quando o serviço recusa a sessão).
- **FR-005**: O usuário MUST poder entrar como visitante sem criar conta e sem gerar nenhuma
  credencial.
- **FR-006**: O estado "visitante" MUST ser lembrado entre aberturas do app até que o usuário
  entre com uma conta, se cadastre ou saia do modo visitante.
- **FR-007**: Quando um visitante entra com uma conta ou se cadastra, o estado MUST passar a
  "conectado" e a marca de visitante MUST ser removida.
- **FR-008** *(adiado, fora desta entrega)*: Quando o contrato da API confirmar o meio de
  validação, o app MUST confirmar com o serviço, na abertura, que a sessão salva ainda é válida,
  e encerrá-la se for recusada. **Nesta entrega**, a restauração é só local, e a sessão só é
  encerrada quando uma ação recebe recusa do serviço (FR-012a).
- **FR-008a**: O app MUST NOT tentar renovar uma credencial vencida ou recusada nesta versão:
  toda recusa encerra a sessão (FR-012), com o comportamento de tela de FR-012a. A renovação automática só será
  considerada depois que o contrato da API confirmar que ela existe.
- **FR-009**: Ao abrir o app sem acesso ao serviço (sem internet ou serviço indisponível), o app
  MUST manter a sessão salva, sem desconectar o usuário.
- **FR-010**: A credencial de acesso MUST ficar guardada apenas em armazenamento protegido
  (criptografado) do aparelho e MUST NOT aparecer em registros de diagnóstico, nem em modo de
  desenvolvimento (RNF-007).
- **FR-011**: A sessão MUST guardar, além da credencial, o identificador e o nome de exibição do
  usuário, para que o app possa cumprimentá-lo sem esperar o serviço.
- **FR-012**: Encerrar a sessão (pelo usuário ou por recusa do serviço) MUST remover do aparelho
  a credencial, o identificador, o nome do usuário e a marca de visitante.
- **FR-012a**: Quando o encerramento é causado por recusa do serviço durante o uso, o app MUST
  NOT tirar o usuário da tela atual: MUST exibir o aviso de sessão expirada, com opção de
  entrar, e pedir o login só na próxima ação que exigir conta ou na próxima abertura do app.
  Quando o encerramento é pedido pelo próprio usuário (sair), o app MUST levá-lo ao login.
- **FR-013**: Encerrar a sessão MUST NOT apagar dados que pertencem ao aparelho: contatos
  pessoais, preferências de acessibilidade e o registro de que o onboarding já foi visto
  (RN-007, RN-004).
- **FR-014**: Se os dados de sessão guardados não puderem ser lidos, o app MUST tratar a sessão
  como desconectada, descartar os dados inválidos e continuar funcionando.
- **FR-015**: A versão instalada do app (não só a de desenvolvimento) MUST conseguir guardar a
  sessão com segurança e acessar o serviço (preparação de plataforma da tarefa F0.1).

### Key Entities

- **Sessão**: representa quem está usando o app naquele aparelho. Atributos: estado
  (conectado, visitante ou desconectado), credencial de acesso (só quando conectado),
  identificador do usuário e nome de exibição (só quando conectado) e o motivo do último
  encerramento (saída pelo usuário ou expiração), que decide entre levar ao login ou mostrar o
  aviso de sessão expirada (FR-012a). Existe no máximo uma por aparelho.
- **Estado da sessão**: conjunto fechado de três valores (conectado, visitante, desconectado).
  É o que o restante do app consulta para decidir o que mostrar e o que liberar (RN-003).
- **Dados do aparelho**: contatos pessoais, preferências de acessibilidade e o registro de
  onboarding visto. Não fazem parte da sessão e sobrevivem ao seu encerramento.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% das reaberturas com uma sessão válida, o usuário chega ao conteúdo sem
  ver a tela de login.
- **SC-002**: A decisão sobre a primeira tela acontece dentro da própria tela de abertura: o
  usuário vê a primeira tela útil em até 3 segundos após tocar no ícone, num aparelho
  intermediário com internet.
- **SC-003**: Em 100% das reaberturas sem internet com sessão salva, o usuário continua
  conectado.
- **SC-004**: Entrar como visitante é uma única ação, sem nenhum dado a preencher: o estado
  "visitante" passa a valer imediatamente após ela. (O "1 toque na tela de login" é verificado
  na tarefa A2.)
- **SC-005**: Depois de encerrar a sessão, 100% das reaberturas levam ao login, e 100% dos
  contatos pessoais e preferências continuam disponíveis.
- **SC-006**: Nenhuma ocorrência da credencial de acesso é encontrada em registros de
  diagnóstico numa auditoria feita com o modo de desenvolvimento ligado.
- **SC-007**: Dados de sessão corrompidos nunca resultam em fechamento inesperado do app: nos
  testes com dados inválidos, o app abre no login em 100% dos casos.
- **SC-008**: Em 100% das recusas de sessão durante o uso, o usuário permanece na tela em que
  estava e vê o aviso de sessão expirada. (Verificado na tarefa F0.9; aqui se verifica que o
  motivo "expirado" é registrado.)

## Assumptions

- **Fora do escopo desta entrega:** as telas de login, cadastro e o botão "Entrar como
  visitante" (tarefa A2), a escolha da primeira tela pela abertura do app (tarefa A1) e o botão
  "Sair" das Configurações (tarefa B8), e o **aviso de sessão expirada na tela e o pedido de
  login na próxima ação restrita** (tarefa F0.9, shell). Esta entrega fornece a capacidade de
  sessão que essas telas vão usar, verificada por testes automatizados, incluindo o **motivo**
  do encerramento (FR-012a) que a F0.9 usa para decidir entre o aviso e ir ao login.
- O serviço oferece uma forma de confirmar se uma sessão ainda é válida (proposta na seção de
  autenticação do [contrato da API](../../.specify/memory/api-contract.md), ainda a confirmar). Enquanto ela não estiver confirmada, a validação na abertura (FR-008) fica
  desligada, e a sessão só é encerrada quando uma ação recebe recusa do serviço. O restante
  desta entrega não depende desse endpoint.
- A sessão não expira por inatividade no aparelho. Quem define a validade é o serviço, que
  pode recusar a credencial a qualquer momento.
- A renovação automática de credencial está pendente de confirmação no contrato da API. Se a
  API oferecer esse recurso, a mudança entra numa feature própria, sem alterar os estados da
  sessão definidos aqui.
- O progresso feito como visitante não é guardado entre sessões (RN-006). Esta entrega só
  lembra o **estado** de visitante, não os dados dele.
- A preparação de plataforma (dependências, permissão de internet na versão instalada e
  armazenamento protegido) faz parte desta entrega (tarefa F0.1), junto com a base de
  armazenamento local reutilizável pelas próximas tarefas (F0.3).
