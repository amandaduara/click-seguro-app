# Feature Specification: Configurações

**Feature Branch**: `013-configuracoes`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "B8 Configurações (RF-037, RF-042, CB-013) — tarefa B8 da Trilha B em .specify/memory/tasks.md. Tela de configurações do app: dados pessoais (leva à edição de perfil /profile/edit da B7), receber alertas (receiveNotifications via PATCH /users/me), segurança (trocar senha), sair da conta, sobre o app. Seguir o redesign do Figma "SafeNews — Perfil e Configurações (redesign)". A B9 (tela de acessibilidade) fica para a próxima feature."

**Rastreabilidade**: tarefa B8 do [tasks do produto](../../.specify/memory/tasks.md) · RF-037,
RF-042, RN-001, RN-003, RN-007, RNF-003, RNF-004, CB-011, CB-013 da
[especificação do produto](../../.specify/memory/specification.md) · seção "Perfil e conta" do
[contrato da API](../../.specify/memory/api-contract.md) · edição de dados e convite do visitante
da [feature 012](../012-perfil/spec.md) · aviso de alertas desligados da
[feature 011](../011-alertas-locais/spec.md) · sessão e saída da
[feature 001](../001-sessao-persistente-visitante/spec.md) · senha errada sem encerrar a sessão da
[feature 002](../002-apiclient-renovacao-sessao/spec.md) · regra de senha da
[feature 003](../003-login-cadastro-visitante/spec.md) · visual: arquivo do Figma
"SafeNews — Perfil e Configurações (redesign)", quadro **Configurações** (redesign de
2026-10-12, junto com a B7), captura enviada pela usuária em 2026-10-14.

## Clarifications

### Session 2026-10-14

- Captura do quadro "Configurações" (Figma) recebida: seções **Conta** (Dados pessoais, Alterar
  senha), **Alertas**, **Leitura e aparência** (Acessibilidade, Idioma) e **Sobre** (Privacidade,
  Sobre o SafeNews); cada linha com uma frase de apoio; o idioma atual à direita da linha; a
  versão na linha "Sobre o SafeNews"; botão "Sair da conta" com a frase sobre os contatos de
  emergência logo abaixo. Não há seção "Segurança".
- Q: Ao tocar em "Sair da conta", o app pede confirmação ou sai direto? → A: Sai direto (opção B); a frase embaixo do botão é o lembrete. Uma folha de confirmação fica para uma melhoria futura, fora desta feature.
- Q: A escolha de idioma tem a opção de voltar ao idioma do celular? → A: Sim (opção A): três opções, "Idioma do celular" (padrão), "Português" e "English".
- Q: O que o visitante vê nas Configurações? → A: O visitante não chega às Configurações: a engrenagem fica escondida para quem não tem conta (no Perfil e na barra do topo das abas). Quem abrir `/settings` sem conta por link direto vê o convite para entrar.
- Q: Quais créditos aparecem em "Sobre o SafeNews"? → A: Genéricos: "Trabalho de Conclusão de Curso", sem nomes nem instituição.

## Contexto

A engrenagem do Início e do Perfil leva a `/settings`, que hoje é uma página provisória. Também
não há, em lugar nenhum do app, como sair da conta. Esta feature entrega a tela de configurações
com todas as linhas do quadro do Figma, a troca de senha, a chave de alertas (que saiu da edição
de perfil na B7) e a escolha de idioma. A tela de acessibilidade (tamanho da fonte, alto contraste
e leitura automática) é a B9, a próxima feature; aqui só existe a linha que leva a ela.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver as configurações e sair da conta (Priority: P1)

A pessoa toca na engrenagem e vê as configurações organizadas em seções: o cartão da própria
conta, Conta, Alertas, Leitura e aparência e Sobre. No fim, o botão "Sair da conta", com a frase
lembrando que os contatos de emergência continuam no celular.

**Why this priority**: sem isso a engrenagem leva a uma tela vazia e não existe como sair da
conta (RF-037). É o mínimo para a tela fazer sentido.

**Independent Test**: com uma conta, tocar na engrenagem, ver as seções e o cartão com nome e
foto, tocar em "Sair da conta" e chegar ao login.

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta, **When** abre as configurações, **Then** vê o cartão com a foto
   (ou as iniciais), o nome e "Ver e editar seu perfil", seguido das seções Conta, Alertas,
   Leitura e aparência e Sobre, e o botão "Sair da conta" com a frase "Ao sair, seus contatos de
   emergência continuam guardados neste celular." logo abaixo.
2. **Given** as configurações abertas, **When** a pessoa toca no cartão da conta, **Then** vai
   para o Perfil.
3. **Given** as configurações abertas, **When** a pessoa toca em "Dados pessoais", **Then** abre
   a edição de dados (a mesma do lápis do Perfil).
4. **Given** as configurações abertas, **When** a pessoa toca em "Acessibilidade", **Then** abre
   a tela de acessibilidade.
5. **Given** a pessoa toca em "Sair da conta", **When** toca, **Then** sai na hora, sem aviso de
   confirmação, e chega ao login.
6. **Given** a pessoa saiu da conta, **When** volta a usar o app, **Then** os contatos de
   emergência e as preferências do aparelho (idioma e acessibilidade) continuam lá (RN-007).
7. **Given** a pessoa é visitante, **When** olha o topo do Perfil e das abas, **Then** não há
   engrenagem: o visitante não chega às Configurações. Se abrir as Configurações por um link
   direto, vê só o convite para entrar ou criar conta, sem chamada ao serviço (RN-003).
8. **Given** os dados da conta não puderam ser buscados (sem internet), **When** a tela abre,
   **Then** o cartão mostra o nome guardado na sessão e as iniciais, e as outras linhas funcionam.

---

### User Story 2 - Trocar a senha (Priority: P1)

Em "Alterar senha", a pessoa digita a senha atual, a nova e a confirmação da nova. As regras da
nova senha aparecem antes de enviar. Se a senha atual estiver errada, o aviso aparece no campo e
a pessoa continua conectada.

**Why this priority**: é o requisito de segurança da conta (RF-037, CB-013) e o único lugar em
que a pessoa pode trocar a senha sem sair do app.

**Independent Test**: abrir "Alterar senha", digitar a senha atual certa e uma nova válida,
salvar, ver "Senha alterada" e entrar de novo com a nova senha; repetir com a senha atual errada
e ver o aviso sem sair da conta.

**Acceptance Scenarios**:

1. **Given** a pessoa abre "Alterar senha", **When** a tela aparece, **Then** há três campos
   (senha atual, nova senha, confirmar nova senha), cada um com a opção de mostrar o que foi
   digitado, e a lista das regras da nova senha.
2. **Given** a nova senha não cumpre as regras (8 a 64 caracteres, maiúscula, minúscula, número e
   caractere especial), **When** a pessoa digita, **Then** cada regra mostra se foi cumprida, e
   "Salvar" não envia nada enquanto alguma faltar (RN-001).
3. **Given** a confirmação é diferente da nova senha, **When** a pessoa tenta salvar, **Then** o
   campo de confirmação mostra "As senhas não são iguais" e nada é enviado.
4. **Given** os campos estão certos, **When** a pessoa salva, **Then** a senha é trocada, aparece
   "Senha alterada" e a tela volta para as configurações.
5. **Given** a senha atual está errada, **When** o serviço recusa, **Then** o campo da senha
   atual mostra "Senha atual incorreta", a pessoa **continua conectada** e o que digitou na nova
   senha é mantido (CB-013).
6. **Given** a nova senha é igual à atual, **When** o serviço recusa, **Then** o campo da nova
   senha mostra "A nova senha precisa ser diferente da atual".
7. **Given** sem internet ou falha do serviço, **When** a troca falha, **Then** aparece uma
   mensagem simples e os campos continuam preenchidos.
8. **Given** a pessoa digitou algo e toca em voltar, **When** volta, **Then** o app pergunta se
   quer descartar o que digitou.

---

### User Story 3 - Ligar ou desligar os alertas (Priority: P2)

Na seção Alertas, a chave "Alertas de notícias novas" mostra se a pessoa recebe alertas. Tocar
nela muda na hora e salva; se falhar, a chave volta e um aviso aparece.

**Why this priority**: a chave saiu da edição de perfil na B7 e hoje não existe em lugar nenhum;
o aviso "alertas desligados" da tela de Alertas leva a uma tela que não tem a chave.

**Independent Test**: desligar a chave, abrir os Alertas e ver o aviso de alertas desligados;
voltar e ligar de novo.

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta, **When** abre as configurações, **Then** a chave mostra o valor
   salvo na conta.
2. **Given** a chave ligada, **When** a pessoa toca nela, **Then** ela desliga na hora e o valor
   é salvo na conta.
3. **Given** a pessoa mudou a chave, **When** o salvamento falha, **Then** a chave volta ao
   valor anterior e aparece "Não foi possível mudar os alertas. Tente de novo."
4. **Given** um salvamento em andamento, **When** a pessoa toca de novo, **Then** nada acontece
   até o primeiro terminar.
5. **Given** os alertas estão desligados, **When** a pessoa vê o aviso na tela de Alertas e toca
   no botão dele, **Then** chega às configurações, onde está a chave.
6. **Given** o valor da conta não pôde ser buscado, **When** a tela abre, **Then** a chave
   aparece desabilitada com "Não foi possível carregar" e a opção de tentar de novo.

---

### User Story 4 - Escolher o idioma (Priority: P2)

Em "Idioma", a pessoa escolhe "Idioma do celular", Português ou English. O app troca na hora e
lembra da escolha nas próximas aberturas. "Idioma do celular" é o padrão e faz o app seguir o
idioma do aparelho.

**Why this priority**: é o RF-042; os textos já existem nos dois idiomas, falta só a escolha.

**Independent Test**: escolher English, ver as configurações em inglês, fechar e abrir o app e
continuar em inglês; voltar para Português.

**Acceptance Scenarios**:

1. **Given** a pessoa abre "Idioma", **When** a escolha aparece, **Then** há "Idioma do celular",
   "Português" e "English" (os dois últimos escritos no próprio idioma), com a escolha atual
   marcada; à direita da linha aparece o nome da escolha atual.
2. **Given** a pessoa escolhe outro idioma, **When** confirma, **Then** todos os textos do app
   mudam na hora, sem reiniciar, e a leitura em voz alta passa a usar esse idioma.
3. **Given** a pessoa escolheu um idioma, **When** fecha e abre o app, **Then** ele abre no
   idioma escolhido.
4. **Given** a pessoa nunca escolheu ou escolheu "Idioma do celular", **When** abre o app,
   **Then** ele usa o idioma do aparelho (português do Brasil ou inglês; outro idioma cai em
   português), inclusive se o idioma do celular mudar depois (vale a partir da próxima
   abertura do app).
5. **Given** a pessoa tinha escolhido English, **When** escolhe "Idioma do celular", **Then** o
   app volta a seguir o aparelho na hora.

---

### User Story 5 - Privacidade e Sobre (Priority: P3)

"Privacidade" explica, em linguagem simples, quais dados o app guarda e onde. "Sobre o SafeNews"
mostra o que é o app, a versão instalada e o crédito genérico do TCC.

**Why this priority**: completa as linhas do quadro (RF-037: nenhuma linha morta), mas não muda o
uso do app.

**Independent Test**: abrir "Privacidade" e "Sobre o SafeNews" e ler o conteúdo; conferir a
versão com a instalada.

**Acceptance Scenarios**:

1. **Given** a pessoa toca em "Privacidade", **When** a tela abre, **Then** explica que a conta
   (nome, e-mail, telefone, foto, leituras, curtidas, salvas e progresso) fica no serviço; que os
   contatos de emergência e as fotos deles ficam só no celular (RN-007); e que as preferências
   de idioma e acessibilidade ficam no aparelho.
2. **Given** a pessoa toca em "Sobre o SafeNews", **When** a tela abre, **Then** mostra o nome do
   app, uma frase sobre o objetivo, a versão instalada e o crédito genérico "Trabalho de
   Conclusão de Curso" (sem nomes nem instituição).

---

### Edge Cases

- **Sessão expira com a tela aberta**: o aviso de sessão expirada da feature 005 aparece; a tela
  passa a mostrar o convite para entrar, como no link direto do visitante.
- **Senha atual errada** (CB-013): só o aviso no campo; nunca encerra a sessão.
- **Toque duplo em "Sair da conta" ou em "Salvar"**: sai ou envia uma só vez.
- **Fonte 200% e alto contraste** (RNF-003/004): as linhas quebram o texto sem cortar; a chave
  e as setas continuam visíveis e com área de toque de 48.
- **Sair sem internet**: sair funciona sem rede (só o aparelho).
- **Senha nova com espaços nas pontas**: os espaços contam como caracteres (não são removidos),
  igual ao cadastro.

## Requirements *(mandatory)*

### Functional Requirements

**Tela de configurações**

- **FR-001**: A tela MUST mostrar, nesta ordem: o cartão da conta; a seção **Conta** com "Dados
  pessoais" ("Nome, e-mail, telefone e foto") e "Alterar senha" ("Troque a senha de entrada no
  app"); **Alertas** com a chave "Alertas de notícias novas" ("Avisamos quando sair uma notícia
  de golpe"); **Leitura e aparência** com "Acessibilidade" ("Tamanho da letra, contraste e
  leitura em voz alta") e "Idioma" (com o idioma atual à direita); **Sobre** com "Privacidade"
  ("Como cuidamos dos seus dados") e "Sobre o SafeNews" (com a versão instalada); e o botão
  "Sair da conta", com a frase sobre os contatos de emergência logo abaixo.
- **FR-002**: Toda linha MUST levar a uma tela ou ação que funciona (RF-037). "Acessibilidade"
  abre a tela de acessibilidade (conteúdo na B9).
- **FR-003**: O cartão da conta MUST mostrar a foto (ou as iniciais), o nome e "Ver e editar seu
  perfil"; tocar nele MUST levar ao Perfil.
- **FR-004**: "Dados pessoais" MUST abrir a edição de dados da B7.
- **FR-005**: As Configurações MUST ser só de quem tem conta: a engrenagem MUST ficar escondida
  para o visitante no Perfil e na barra do topo das abas (Início, Atividades, Ajuda), e quem
  abrir `/settings` sem conta MUST ver só o convite para entrar, sem chamada ao serviço (RN-003).

**Sair**

- **FR-006**: "Sair da conta" MUST encerrar a sessão no primeiro toque, sem aviso de confirmação;
  a frase embaixo do botão lembra que os contatos de emergência continuam no celular.
- **FR-007**: Ao sair, o app MUST ir ao login, sem apagar contatos de emergência, fotos deles nem
  preferências do aparelho (RN-007).

**Senha**

- **FR-008**: "Alterar senha" MUST pedir a senha atual, a nova e a confirmação, com opção de
  mostrar o texto de cada uma.
- **FR-009**: A nova senha MUST seguir a regra do RN-001 (8 a 64 caracteres, maiúscula,
  minúscula, número e caractere especial), mostrada como lista que se marca enquanto a pessoa
  digita, e MUST ser validada antes de qualquer envio.
- **FR-010**: A confirmação diferente da nova senha MUST bloquear o envio com aviso no campo.
- **FR-011**: A recusa da senha atual MUST mostrar "Senha atual incorreta" no campo e MUST NOT
  encerrar a sessão (CB-013).
- **FR-012**: A recusa por nova senha igual à atual MUST mostrar o aviso no campo da nova senha.
- **FR-013**: Em sucesso, o app MUST mostrar "Senha alterada" e voltar para as configurações; a
  pessoa continua conectada. Como o serviço invalida a renovação da sessão depois da troca
  (conferido em 2026-10-14), o app entra de novo com a nova senha; se não conseguir, encerra a
  sessão e mostra no login "Senha alterada. Entre de novo com a nova senha."
- **FR-014**: Outras falhas MUST mostrar uma mensagem simples e manter o que foi digitado.
- **FR-015**: Sair da troca de senha com algo digitado MUST pedir confirmação para descartar.

**Alertas**

- **FR-016**: A chave MUST mostrar o valor "receber alertas" da conta e MUST salvar a mudança na
  hora, voltando ao valor anterior em falha, com aviso.
- **FR-017**: Enquanto um salvamento da chave estiver em andamento, novos toques MUST ser
  ignorados.
- **FR-018**: O botão do aviso "alertas desligados" da tela de Alertas MUST levar às
  configurações (hoje leva à edição de dados, que não tem mais a chave).

**Idioma**

- **FR-019**: "Idioma" MUST oferecer "Idioma do celular", Português e English, com a escolha
  atual marcada e o nome dela à direita da linha, e trocar todos os textos do app na hora
  (RF-042).
- **FR-020**: A escolha MUST ser lembrada no aparelho. "Idioma do celular" é o padrão: o app MUST
  seguir o idioma do aparelho (pt-BR ou en-US; outro cai em pt-BR), também quando ele mudar
  (a partir da próxima abertura do app).
- **FR-021**: A leitura em voz alta MUST seguir o idioma escolhido (RF-042).

**Privacidade e Sobre**

- **FR-022**: "Privacidade" MUST explicar, em linguagem simples, o que fica no serviço e o que fica
  só no celular (RN-007, RNF-008).
- **FR-023**: "Sobre o SafeNews" MUST mostrar o nome do app, o objetivo, a versão instalada e o
  crédito genérico "Trabalho de Conclusão de Curso", sem nomes nem instituição.

**Acessibilidade e textos**

- **FR-024**: Todas as telas MUST seguir a acessibilidade global (F0.6): textos de pelo menos 16,
  áreas de toque de pelo menos 48, rótulos para leitor de tela (a chave anuncia o estado), fonte
  até 200% sem cortar e alto contraste.
- **FR-025**: Todos os textos MUST existir em pt-BR e en-US.

### Key Entities

- **Configuração de alertas**: o valor "receber alertas" da conta, lido e salvo no serviço.
- **Troca de senha**: senha atual, nova senha e confirmação (nunca guardadas no aparelho).
- **Idioma escolhido**: "Idioma do celular", Português ou English, guardado no aparelho; ausente =
  "Idioma do celular".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Todas as 8 linhas e o botão de sair das configurações levam a uma tela ou ação que
  funciona (zero linhas "em breve" além do conteúdo da Acessibilidade, que é a B9).
- **SC-002**: A pessoa troca a senha em até 1 minuto, e com a senha atual errada continua
  conectada em 100% das tentativas.
- **SC-003**: A troca de idioma muda todos os textos visíveis em até 1 segundo, sem reiniciar o
  app, e a escolha continua valendo depois de fechar e abrir.
- **SC-004**: A chave de alertas reflete a mudança na hora; em falha volta ao valor anterior em
  100% dos casos.
- **SC-005**: Depois de sair da conta, os contatos de emergência e as preferências do aparelho
  continuam iguais.
- **SC-006**: Com fonte em 200% e alto contraste, nenhuma linha corta texto nem fica sem área de
  toque de 48.

## Assumptions

- Visitante: como não chega às Configurações, não escolhe idioma nem abre a acessibilidade nesta
  feature (segue o idioma do celular). A B9 pode rever o acesso do visitante à acessibilidade.
- Fora do escopo: folha de confirmação ao sair da conta (melhoria futura, decisão de 2026-10-14).

- O conteúdo da tela de acessibilidade é a B9 (próxima feature). Nesta feature a linha
  "Acessibilidade" leva à rota que já existe, e a B9 substitui o conteúdo antes da integração (C3).
- Os textos de Privacidade e Sobre são fixos no app, escritos nesta feature; não há endpoint.
- A versão mostrada é a do app instalado.
- O cartão da conta lê `GET /users/me` pelo próprio módulo de configurações (os mesmos dados do
  perfil da B7), que traz também o valor de
  "receber alertas"; sem rede, usa o nome guardado na sessão.
- Visual: o quadro "Configurações" do Figma, pela captura enviada em 2026-10-14 (a ferramenta do
  Figma está sem cota).
