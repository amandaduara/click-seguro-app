# Feature Specification: Conclusão do módulo e aviso de login

**Feature Branch**: `020-conclusao-modulo-atividades`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "B4 Atividades: conclusão e aviso de login (RF-029, RF-030, RN-005, RN-006) — tarefa B4 da Trilha B em .specify/memory/tasks.md. Ao terminar um módulo, a pessoa vê uma tela de conclusão com a pontuação (do serviço para quem tem conta; do registro da sessão para o visitante) e pode compartilhar a conquista. O visitante, antes da conclusão, vê um aviso convidando a criar conta: 'Criar conta' leva o progresso da sessão para a conta nova (RN-006 2.3.0) e 'Continuar sem conta' segue para a conclusão, com o progresso valendo até fechar o app. Hoje, depois da última pergunta, o painel de feedback da B3 mostra 'Voltar às atividades'; a B4 troca esse destino."

**Rastreabilidade**: tarefa B4 do [tasks do produto](../../.specify/memory/tasks.md) · RF-029,
RF-030, RN-005, RN-006 (2.3.0), RN-003, RNF-003, RNF-004 e RNF-006 da
[especificação do produto](../../.specify/memory/specification.md) 2.4.0 · seção "Atividades" do
[contrato da API](../../.specify/memory/api-contract.md) 1.1.2 · painel e transferência do
visitante da [feature 015](../015-painel-atividades/spec.md) · perguntas da
[feature 017](../017-perguntas-atividades/spec.md) · resposta, feedback e pontuação da
[feature 018](../018-resposta-feedback-atividades/spec.md) · compartilhar da
[feature 007](../007-servicos-plataforma-voz/spec.md) · cadastro da
[feature 003](../003-login-cadastro-visitante/spec.md).

## Contexto

Com a B3, a pessoa responde todas as perguntas de um módulo e, na última, volta direto ao painel
de atividades. Falta o **fechamento**: um momento que diga "você terminou", mostre quanto acertou
e permita contar isso a alguém, o que reforça o aprendizado e espalha o alerta sobre golpes.

Para o visitante, esse é também o melhor momento para convidar a criar uma conta: ele acabou de
investir tempo, e o progresso dele some quando fechar o app (RN-006). Se criar a conta sem fechar
o app, o progresso da sessão vai junto (comportamento da B1).

## Clarifications

### Session 2026-10-27

- Q: Depois que o visitante cria a conta pelo aviso do fim do módulo, para onde o app deve
  levá-lo? → A: Para a aba Atividades, com o módulo como concluído (não para o início do app nem
  de volta à tela de conclusão).
- Q: Quais botões a tela de conclusão deve ter? → A: "Compartilhar", "Refazer o módulo" e "Voltar
  às atividades" (este em destaque), para qualquer resultado.
- Q: Com a leitura automática ligada, a tela de conclusão deve ler o resultado em voz alta
  sozinha? → A: Sim: lê o título, a pontuação e a mensagem ao abrir, uma vez; e há o botão
  "Ouvir", como nas perguntas e no feedback.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver a conclusão ao terminar o módulo (Priority: P1)

Quem tem conta responde a última pergunta do módulo e, no painel de feedback, toca em "Ver
resultado". Aparece a tela de conclusão: o módulo concluído, a pontuação ("Você acertou X de Y")
e uma mensagem de acordo com o resultado.

**Why this priority**: é o RF-029 e o que dá sentido ao fim do módulo; sem ela, o módulo termina
sem retorno.

**Independent Test**: com o serviço falso, responder a última pergunta de um módulo como conta,
seguir pelo painel e conferir o título do módulo, a pontuação do serviço e a mensagem.

**Acceptance Scenarios**:

1. **Given** uma pessoa com conta na última pergunta, com todas as anteriores respondidas,
   **When** responde e toca em "Ver resultado" no painel, **Then** vê a tela de conclusão com o
   nome do módulo e "Você acertou X de Y", com a pontuação calculada pelo serviço (RN-005).
2. **Given** a tela de conclusão, **When** a pessoa olha a mensagem, **Then** ela muda com o
   resultado: todas certas, a maioria certa, ou menos da metade (com incentivo a refazer).
3. **Given** a tela de conclusão, **When** a pessoa toca em "Voltar às atividades", **Then**
   volta ao painel de atividades, com o módulo como concluído.
4. **Given** a tela de conclusão, **When** a pessoa usa o voltar do aparelho, **Then** também
   volta ao painel de atividades (não às perguntas).
5. **Given** a pontuação do serviço não pôde ser lida depois da última resposta, **When** a
   conclusão aparece, **Then** mostra o módulo concluído sem a linha da pontuação, sem erro.
6. **Given** a leitura automática ligada (B9), **When** a conclusão aparece, **Then** o app lê
   sozinho, uma vez, o título, a pontuação e a mensagem; "Ouvir"/"Parar" lê o mesmo texto; sair
   da tela para a leitura; sem voz no idioma do app, nada é lido e "Ouvir" não aparece.

---

### User Story 2 - Aviso para o visitante antes da conclusão (Priority: P1)

O visitante responde a última pergunta e toca em "Ver resultado". Antes da conclusão, aparece um
aviso: o progresso dele vale só até fechar o app; criando uma conta agora, ele não perde nada.
"Criar conta" leva ao cadastro; "Continuar sem conta" segue para a conclusão.

**Why this priority**: RF-030 e RN-006 exigem o aviso, e ele vem antes da conclusão; é o principal
convite para o visitante virar usuário.

**Independent Test**: como visitante, terminar o módulo e conferir o aviso; tocar em "Continuar
sem conta" e conferir a conclusão com a pontuação da sessão; repetir e tocar em "Criar conta" e
conferir que abre o cadastro.

**Acceptance Scenarios**:

1. **Given** um visitante na última pergunta, **When** responde e toca em "Ver resultado",
   **Then** vê o aviso de que o progresso vale só até fechar o app, com "Criar conta" e
   "Continuar sem conta".
2. **Given** o aviso aberto, **When** o visitante toca em "Continuar sem conta", **Then** vê a
   tela de conclusão com a pontuação da sessão: acertos na resposta mais recente de cada pergunta
   sobre o total de perguntas do módulo (RN-005).
3. **Given** o aviso aberto, **When** o visitante toca em "Criar conta", **Then** o app abre a
   tela de cadastro (já no modo de criar conta).
4. **Given** o visitante criou a conta a partir do aviso, sem fechar o app, **When** o cadastro
   termina, **Then** o app abre a aba Atividades (não o início), as respostas da sessão passam
   para a conta (RN-006 2.3.0) e o módulo aparece como concluído.
5. **Given** o aviso aberto, **When** o visitante o fecha pelo voltar do aparelho, **Then** segue
   para a conclusão, como em "Continuar sem conta" (o aviso não pode prender a pessoa).
6. **Given** uma pessoa com conta, **When** termina o módulo, **Then** o aviso não aparece.
7. **Given** o visitante abriu o cadastro pelo aviso, **When** desiste e volta sem criar a conta,
   **Then** continua como visitante, sem perder o progresso da sessão.

---

### User Story 3 - Compartilhar a conquista (Priority: P2)

Na tela de conclusão, a pessoa toca em "Compartilhar" e o app abre o menu de compartilhar do
aparelho com uma mensagem pronta: que ela concluiu o módulo no app e quantas acertou.

**Why this priority**: RF-029 pede a opção de compartilhar; vem depois de ver a conclusão porque
depende dela.

**Independent Test**: com o serviço de compartilhar falso, tocar em "Compartilhar" e conferir o
texto enviado.

**Acceptance Scenarios**:

1. **Given** a tela de conclusão, **When** a pessoa toca em "Compartilhar", **Then** o menu do
   aparelho abre com um texto como "Concluí o módulo Golpes Digitais no SafeNews e acertei 3 de 3
   perguntas! Aprenda a se proteger de golpes também." no idioma do app.
2. **Given** a pontuação não está disponível, **When** a pessoa compartilha, **Then** o texto diz
   só que concluiu o módulo, sem números.
3. **Given** a pessoa cancela o menu ou o aparelho não consegue compartilhar, **When** volta ao
   app, **Then** continua na conclusão, sem mensagem de erro (como na notícia).
4. **Given** toques rápidos em "Compartilhar", **When** o menu está abrindo, **Then** abre uma vez
   só.
5. **Given** um visitante, **When** compartilha, **Then** funciona igual (não exige conta, RN-003).

---

### User Story 4 - Refazer o módulo (Priority: P3)

Na conclusão, a pessoa pode tocar em "Refazer o módulo" e voltar à primeira pergunta para
responder de novo e melhorar a pontuação.

**Why this priority**: a pontuação considera a resposta mais recente (RN-005) e responder de novo é
livre (B3); o atalho ajuda quem foi mal, mas o mesmo é possível pelo painel.

**Independent Test**: na conclusão, tocar em "Refazer o módulo" e conferir que abre a primeira
pergunta do mesmo módulo.

**Acceptance Scenarios**:

1. **Given** a tela de conclusão, **When** a pessoa toca em "Refazer o módulo", **Then** abre a
   primeira pergunta do mesmo módulo, sem alternativa marcada.
2. **Given** a pessoa refez e terminou de novo, **When** chega à conclusão, **Then** vê a
   pontuação nova (resposta mais recente de cada pergunta).

---

### Edge Cases

- **Módulo em que nem todas as perguntas foram respondidas** (ex.: a pessoa pulou do meio pelo
  voltar): a conclusão só aparece quando todas as perguntas válidas estão respondidas; até lá, a
  última pergunta continua levando ao painel de atividades, como na B3.
- **Refazer um módulo já concluído** (abre na primeira pergunta, B2): ao responder de novo a
  última, a conclusão aparece de novo (e, para o visitante, o aviso de novo).
- **Visitante que já viu o aviso e continuou sem conta**: em outro módulo, o aviso aparece de novo
  (cada conclusão é um convite); não há "não mostrar mais".
- **Sessão expira** durante as perguntas: quem fica sem conta segue o caminho do visitante (aviso
  antes da conclusão), como o resto das atividades faz.
- **Visitante cria conta, mas o envio de alguma resposta falha**: a resposta fica para o próximo
  carregamento do painel (comportamento da B1); a pessoa não vê erro.
- **Letra no nível máximo / alto contraste** (B9): aviso e conclusão legíveis e roláveis; botões
  alcançáveis.
- **Leitor de tela**: o título da conclusão e a pontuação são anunciados ao abrir; o aviso
  anuncia o título.
- **Idioma em inglês**: textos do app e da mensagem compartilhada em inglês; o nome do módulo
  vem do serviço como está.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Quando a pessoa responde a última pergunta e **todas** as perguntas válidas do módulo
  estão respondidas, o botão do painel de feedback MUST ser "Ver resultado" e levar ao fim do
  módulo; sem todas respondidas, continua "Voltar às atividades" (B3).
- **FR-002**: O fim do módulo MUST ser, para quem tem conta, a tela de conclusão; para quem está
  sem conta (visitante ou sessão expirada), o aviso de login e, depois, a conclusão (RN-006).
- **FR-003**: A tela de conclusão MUST mostrar o nome do módulo, que ele foi concluído, a
  pontuação "Você acertou X de Y" quando houver, e uma mensagem conforme o resultado (todas
  certas; pelo menos metade; menos da metade).
- **FR-004**: A pontuação MUST ser a do serviço para quem tem conta e a do registro da sessão para
  o visitante (RN-005); sem pontuação disponível, a linha não aparece e nada mostra "0 de 0".
- **FR-005**: A conclusão MUST oferecer, para qualquer resultado, "Compartilhar", "Refazer o
  módulo" e "Voltar às atividades" (este como ação principal); o voltar do aparelho MUST levar ao
  painel de atividades (clarificação de 2026-10-27).
- **FR-006**: "Compartilhar" MUST abrir o menu do aparelho com uma mensagem pronta, no idioma do
  app, com o nome do módulo, o nome do app e, se houver, a pontuação; cancelar ou falhar não
  mostra erro; toques repetidos abrem o menu uma vez.
- **FR-007**: O aviso do visitante MUST dizer que o progresso vale até fechar o app e que, criando
  uma conta, ele é guardado; com "Criar conta" e "Continuar sem conta".
- **FR-008**: "Criar conta" MUST abrir a tela de cadastro já no modo de criar conta; o progresso da
  sessão MUST ir para a conta nova se ela for criada sem fechar o app (RN-006 2.3.0, mecanismo da
  B1); terminado o cadastro, o app MUST abrir a aba Atividades (clarificação de 2026-10-27).
  Se, nessa mesma tela, a pessoa trocar para "Entrar" numa conta que já existe, também vai para a
  aba Atividades (o progresso da sessão é descartado, RN-006). Voltar sem entrar segue para a
  conclusão, como visitante.
- **FR-009**: "Continuar sem conta" e o voltar do aparelho no aviso MUST seguir para a conclusão.
- **FR-010**: "Refazer o módulo" MUST abrir a primeira pergunta do mesmo módulo.
- **FR-011**: A tela de conclusão e o aviso MUST seguir o padrão de acessibilidade do app
  (RNF-003/RNF-004): alvos ≥ 48 dp, texto base ≥ 16 sp, letra e alto contraste da B9, título e
  pontuação anunciados pelo leitor de tela.
- **FR-012**: Os textos MUST estar em português e inglês (RNF-006).
- **FR-013**: A conclusão MUST oferecer "Ouvir" (título, pontuação e mensagem) na velocidade da
  Acessibilidade e, com a leitura automática ligada, ler esse texto sozinha uma vez ao abrir
  (RF-040; clarificação de 2026-10-27). A leitura para ao sair da tela.

### Key Entities

- **Resultado do módulo**: nome do módulo e a pontuação (acertos e total), quando houver; vem do
  que a tela de perguntas já tem ao terminar.
- **Mensagem de conquista**: texto pronto para compartilhar, montado do resultado e do nome do app.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Ao tocar em "Ver resultado", a conclusão (ou o aviso, para o visitante) aparece em
  até 1 segundo, sem esperar o serviço.
- **SC-002**: 100% dos módulos terminados por visitantes mostram o aviso antes da conclusão; 0%
  dos terminados por quem tem conta mostram o aviso.
- **SC-003**: A pontuação da conclusão é igual à do serviço (conta) ou à da sessão (visitante) em
  todos os casos, e nunca aparece "0 de 0".
- **SC-004**: Um visitante que cria a conta pelo aviso cai direto na aba Atividades e vê o módulo
  como concluído na conta nova, sem refazer nenhuma pergunta.
- **SC-005**: Com a letra no nível máximo e o alto contraste, aviso e conclusão ficam legíveis e
  todos os botões tocáveis no aparelho.

## Assumptions

- **Momento da conclusão**: o fim do módulo vem da última pergunta, no painel de feedback (B3),
  quando todas as perguntas válidas estão respondidas. Como a navegação é guiada (B2), chegar à
  última respondendo implica ter respondido as anteriores; quem refaz um módulo já concluído passa
  pela conclusão de novo.
- **Pontuação já disponível**: a B3 deixa na tela a pontuação depois de cada resposta (do serviço
  com conta, da sessão sem conta); a conclusão usa essa, sem novo pedido ao serviço (SC-001).
- **Cadastro**: a tela de login já tem o modo "Criar conta" (feature 003); esta feature abre a
  tela nesse modo e, quando o cadastro veio do aviso, leva à aba Atividades no lugar do início;
  a pessoa não volta à conclusão.
- **Transferência do progresso**: já existe desde a B1 (`startedFromSignUp`): esta feature não
  muda esse mecanismo, só leva o visitante até o cadastro.
- **Voz**: reaproveita o botão "Ouvir" e a leitura das perguntas e do feedback (features 014, 017 e
  018). O aviso do visitante não é lido sozinho (é uma escolha, não um resultado); o leitor de tela
  anuncia o título dele.
- **Compartilhar**: usa o mesmo serviço de compartilhar da notícia (feature 007), sem imagem; o
  nome do app é o do app (SafeNews).
- **Conquistas do Perfil** (B7) e medalhas: fora desta feature; a conclusão não cria registros
  novos.
- **Sem offline**: as atividades exigem internet (RNF-002 não as inclui), mas a conclusão em si não
  faz pedidos.
