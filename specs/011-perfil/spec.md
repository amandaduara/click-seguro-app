# Feature Specification: Perfil

**Feature Branch**: `011-perfil`

**Created**: 2026-10-09

**Status**: Draft

**Input**: User description: "B7 Perfil (RF-035, RF-036, RN-008), tarefa B7 do .specify/memory/tasks.md. Aba Perfil (/profile, hoje provisória): cartão com nome, e-mail, foto e selo de nível; estatísticas (módulos concluídos, lições concluídas, notícias salvas); conquistas; atalhos; visitante vê o convite para criar conta. Tela /profile/edit: nome (6–150), e-mail, telefone (+55), foto (galeria/câmera via ImageStorageService da F0.5, upload multipart POST/DELETE /users/me/avatar) e "Receber alertas". Endpoints: GET/PATCH /users/me, POST/DELETE /users/me/avatar, GET /app/educational/modules e GET /users/me/news/saved?limit=1 para as estatísticas. Faixas de nível e regras das conquistas são fixas no app (RN-008) e precisam ser definidas nesta spec. 409 USER_EMAIL_ALREADY_EXISTS no e-mail. Conferir os endpoints no servidor real no plano."

**Rastreabilidade**: tarefa B7 do [tasks do produto](../../.specify/memory/tasks.md) · RF-035,
RF-036, RN-003, RN-008, RNF-003, RNF-004, CB-002, CB-004, CB-010 da
[especificação do produto](../../.specify/memory/specification.md) · seção "Perfil e conta" do
[contrato da API](../../.specify/memory/api-contract.md) · fotos da
[feature 007](../007-servicos-plataforma-voz/spec.md) · convite para conta e estados comuns da
[feature 005](../005-shell-navegacao-base/spec.md) · tela de notícias salvas da
[feature 010](../010-detalhe-noticia/spec.md) · acessibilidade da
[feature 009](../009-acessibilidade-global/spec.md) · visual: arquivo do Figma
"SafeNews — Perfil e Configurações (redesign)", quadro **Perfil — com conta (v4)**, aprovado pela
usuária em 2026-10-12 (o wireframe `ProfileScreen.tsx` deixa de ser a referência).

## Clarifications

### Session 2026-10-09

- Q: Quais são as faixas de nível? → A: Não há nível. Como não existe limite de módulos, a usuária decidiu remover o selo de nível do perfil (RF-035 e RN-008 do produto atualizados).
- Q: Quais conquistas existem? → A: Conquistas fixas mais uma por módulo de atividades, mostradas em destaque com "Ver todas" para o resto (regras revistas em 2026-10-12).

### Session 2026-10-12 (redesign no Figma)

- Q: O que o cartão da pessoa mostra? → A: Foto (ou iniciais) e nome. Sem e-mail e sem botão "Editar perfil"; um lápis sobre a foto abre a edição.
- Q: Quais números o perfil mostra? → A: Notícias lidas, salvas e curtidas (opção A). Módulos e lições concluídos aparecem nas conquistas, não como número (RF-035 do produto atualizado).
- Q: Tocar num número faz algo? → A: Sim, abre a lista daquelas notícias. A de salvas já existe (feature 010); lidas e curtidas ganham uma lista nesta feature.
- Q: As conquistas de notícias contam o quê? → A: Notícias lidas (nunca diminuem); as de atividades contam lições e módulos concluídos.
- Q: Onde fica "Receber alertas"? → A: Nas Configurações (B8), com as linhas novas "Privacidade" e "Sobre o SafeNews". Sai desta feature.
- Q: Os atalhos? → A: Dois cartões coloridos, "Ler mais notícias" e "Fazer novas atividades", e a engrenagem das configurações no topo.

## Contexto

A aba Perfil hoje mostra uma tela provisória ("Em breve"). Esta feature coloca nela quem é a
pessoa, o quanto ela já leu e aprendeu (números e conquistas em forma de medalhas) e atalhos para
continuar. A tela de edição deixa a pessoa corrigir nome, e-mail e telefone e trocar ou remover a
foto. Tocar nos números de notícias lidas ou curtidas mostra essas notícias de novo.

As conquistas servem para motivar o público idoso a continuar lendo e aprendendo. O serviço não
as calcula: as regras ficam no app e são definidas aqui (RN-008).

Ficam fora: as configurações, incluindo "Receber alertas", trocar a senha e sair da conta (B8);
a tela de notícias salvas (já existe, feature 010; o perfil só leva até ela); as telas de
atividades (B1–B4; o perfil só lê o progresso); e a geração dos alertas (A6).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver o próprio perfil (Priority: P1)

A pessoa com conta toca na aba Perfil e vê sua foto (ou as iniciais) e o nome. Logo abaixo, três
números: quantas notícias leu, salvou e curtiu. Depois, as suas conquistas em forma de medalhas e
dois atalhos coloridos para ler mais notícias e fazer atividades.

**Why this priority**: é o que dá sentido à aba e mostra o progresso da pessoa (RF-035). Sem
isso, a aba continua vazia.

**Independent Test**: com uma conta no servidor de desenvolvimento, abrir a aba Perfil e ver
nome, os três números e as medalhas; tocar em "Ler mais notícias" e chegar ao Início.

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta, **When** abre a aba Perfil, **Then** vê o indicador de carregando
   e depois a foto (ou as iniciais do nome) e o nome.
2. **Given** o perfil carregou, **When** a pessoa olha os números, **Then** vê quantas notícias
   leu, salvou e curtiu, com os números do serviço, cada um com ícone e nome.
3. **Given** o perfil carregou, **When** a pessoa olha as conquistas, **Then** vê o total
   alcançado e as medalhas: as alcançadas primeiro, coloridas e com "Conquistada"; depois as mais
   perto de alcançar, em cinza, com cadeado e o progresso ("8 de 10 lições").
4. **Given** há mais conquistas do que cabem, **When** a pessoa desliza as medalhas ou toca em
   "Ver todas", **Then** vê as outras; "Ver todas" mostra a lista completa na mesma ordem.
5. **Given** o perfil carregou, **When** a pessoa toca em "Ler mais notícias" ou "Fazer novas
   atividades", **Then** chega à aba Início ou à aba Atividades.
6. **Given** o perfil carregou, **When** a pessoa toca na engrenagem, **Then** abre as
   configurações.
7. **Given** a pessoa é visitante, **When** abre a aba Perfil, **Then** vê o convite para entrar
   ou criar conta e o que ela ganha com uma conta, sem chamada ao serviço (RN-003).
8. **Given** sem internet ou com falha do serviço, **When** o perfil não pode ser buscado,
   **Then** a pessoa vê o estado de erro com "Tentar novamente".
9. **Given** só os números ou as conquistas falham (o perfil veio), **When** a tela aparece,
   **Then** mostra o cartão da pessoa e um aviso simples no lugar do que falhou, com "Tentar
   novamente".
10. **Given** a pessoa volta ao Perfil depois de ler, salvar ou curtir uma notícia ou de concluir
    uma atividade, **When** a aba aparece de novo, **Then** os números e as conquistas estão
    atualizados.

---

### User Story 2 - Editar nome, e-mail e telefone (Priority: P1)

A pessoa toca no lápis sobre a foto (ou em "Dados pessoais" nas configurações) e abre "Editar
perfil". Ela corrige o nome, o e-mail ou o telefone e toca em "Salvar". Erros aparecem no próprio
campo, em linguagem simples, antes de enviar. Se o e-mail já pertence a outra conta, o app avisa
no campo de e-mail.

**Why this priority**: manter os dados certos é o requisito central de edição (RF-036) e o nome
aparece em todo o app ("Olá, Maria").

**Independent Test**: tocar no lápis sobre a foto, trocar o nome, salvar, voltar e ver o nome novo
no perfil e na barra do Início; tentar um e-mail de outra conta e ver o aviso no campo.

**Acceptance Scenarios**:

1. **Given** a pessoa toca no lápis sobre a foto, **When** a tela abre, **Then** os campos vêm
   preenchidos com nome, e-mail e telefone atuais, e a foto aparece no topo.
2. **Given** a pessoa mudou um campo, **When** toca em "Salvar", **Then** os dados são enviados,
   aparece a confirmação "Dados salvos" e o perfil e a saudação do Início passam a mostrar o nome
   novo.
3. **Given** o nome tem menos de 6 ou mais de 150 caracteres, **When** a pessoa tenta salvar,
   **Then** o campo mostra o erro e nada é enviado.
4. **Given** o e-mail não tem formato válido, **When** a pessoa tenta salvar, **Then** o campo
   mostra o erro e nada é enviado.
5. **Given** o telefone não tem DDD e número válidos (10 ou 11 dígitos), **When** a pessoa tenta
   salvar, **Then** o campo mostra o erro e nada é enviado. O telefone é opcional: em branco, é
   aceito.
6. **Given** o e-mail já é de outra conta, **When** a pessoa salva, **Then** o campo de e-mail
   mostra "Este e-mail já está em uso" e os outros dados não são perdidos.
7. **Given** nada mudou, **When** a pessoa olha a tela, **Then** "Salvar" fica desabilitado.
8. **Given** sem internet ou falha do serviço ao salvar, **When** a falha acontece, **Then**
   aparece uma mensagem simples e o que a pessoa digitou continua nos campos.
9. **Given** a pessoa mudou algo e tenta sair sem salvar, **When** toca em voltar, **Then** o app
   pergunta se ela quer descartar as alterações.

---

### User Story 3 - Trocar ou remover a foto (Priority: P2)

Em "Editar perfil", a pessoa toca na foto e escolhe "Galeria" ou "Câmera". A nova foto aparece na
hora e é enviada. Ela também pode remover a foto, com confirmação, e voltar às iniciais.

**Why this priority**: personaliza o perfil (RF-036), mas a pessoa usa o app normalmente sem
foto.

**Independent Test**: em "Editar perfil", escolher uma foto da galeria, ver a foto nova no perfil;
remover a foto e ver as iniciais de novo.

**Acceptance Scenarios**:

1. **Given** a pessoa toca na foto, **When** o menu aparece, **Then** há "Galeria", "Câmera" e,
   se já houver foto, "Remover foto".
2. **Given** a pessoa escolhe uma foto, **When** confirma, **Then** a nova foto aparece na hora,
   com indicação de que está sendo enviada, e depois fica salva no serviço.
3. **Given** o envio falha, **When** a falha acontece, **Then** volta a foto anterior (ou as
   iniciais) e aparece uma mensagem simples.
4. **Given** a pessoa desiste da galeria ou da câmera, **When** volta, **Then** nada muda.
5. **Given** o acesso à galeria ou à câmera foi negado, **When** a pessoa tenta escolher,
   **Then** aparece uma explicação de como liberar o acesso nas configurações do aparelho
   (CB-010).
6. **Given** a pessoa escolhe "Remover foto", **When** confirma no aviso, **Then** a foto some e
   aparecem as iniciais; se a remoção falhar, a foto volta e aparece uma mensagem simples.

---

### User Story 4 - Rever as notícias lidas, salvas e curtidas (Priority: P3)

No perfil, a pessoa toca no número de notícias lidas, salvas ou curtidas e vê a lista dessas
notícias, da mais recente para a mais antiga. Tocar numa notícia abre o detalhe.

**Why this priority**: ajuda a pessoa a reencontrar um alerta de golpe que já viu, mas o perfil
cumpre seu papel sem isso.

**Independent Test**: com uma conta que já leu e curtiu notícias, tocar em "Lidas" e ver as
notícias lidas; tocar numa e abrir o detalhe; voltar e tocar em "Curtidas".

**Acceptance Scenarios**:

1. **Given** o perfil carregou, **When** a pessoa toca em "Salvas", **Then** abre a lista de
   notícias salvas que já existe no app.
2. **Given** o perfil carregou, **When** a pessoa toca em "Lidas" ou "Curtidas", **Then** abre a
   lista daquelas notícias, com o título "Notícias lidas" ou "Notícias curtidas", no mesmo visual
   da lista de salvas.
3. **Given** a lista tem mais notícias do que cabem, **When** a pessoa rola até o fim, **Then**
   mais notícias aparecem, sem repetir.
4. **Given** a lista está vazia, **When** abre, **Then** aparece uma mensagem simples ("Você ainda
   não leu nenhuma notícia." / "Você ainda não curtiu nenhuma notícia.") e um botão para ir ao
   Início.
5. **Given** sem internet ou com falha do serviço, **When** a lista não pode ser buscada, **Then**
   aparece o estado de erro com "Tentar novamente".
6. **Given** a pessoa toca numa notícia da lista, **When** toca, **Then** abre o detalhe da
   notícia.

---

### Edge Cases

- **Nome com espaços nas pontas**: os espaços são ignorados na validação e no envio.
- **E-mail com maiúsculas ou espaços**: é enviado sem espaços nas pontas e em minúsculas.
- **Telefone digitado com máscara** ("(11) 91234-5678") ou com "+55": aceito; é enviado como
  "+55" seguido de 10 ou 11 dígitos.
- **Telefone apagado**: a pessoa pode deixar sem telefone.
- **Nenhum módulo de atividades no serviço**: só as conquistas fixas aparecem, nenhuma por módulo,
  sem erro. "Mestre da segurança" só pode ser alcançada quando houver ao menos um módulo.
- **Módulo sem lições**: não gera conquista própria (não há o que concluir).
- **Números muito grandes** (1.000 ou mais): aparecem abreviados ("1,2 mil"), sem quebrar o
  cartão.
- **Foto muito grande**: é reduzida antes do envio (até 1024 px no lado maior, F0.5), dentro do
  limite de 5 MB do serviço.
- **Sessão expira durante a edição**: segue a regra da feature 005 (aviso e pedido para entrar);
  o que foi digitado não é enviado.
- **Conta desativada** (o serviço diz que a pessoa não existe mais): segue a regra da sessão
  encerrada da feature 002.
- **Nome muito longo no cartão**: quebra em até duas linhas, sem cortar a tela.
- **Fonte do sistema no máximo e alto contraste** (feature 009): tudo legível e usável; os três
  números podem ficar em duas linhas sem cortar texto.

## Requirements *(mandatory)*

### Functional Requirements

**Perfil (RF-035, RN-003)**

- **FR-001**: Para quem tem conta, a aba Perfil MUST mostrar foto (ou iniciais) e nome, com um
  botão de lápis sobre a foto que abre "Editar perfil". O e-mail MUST NOT aparecer no cartão.
- **FR-002**: A aba MUST mostrar o número de notícias lidas, salvas e curtidas, com os números do
  serviço, cada um com ícone e nome.
- **FR-003**: A aba MUST mostrar quantas conquistas a pessoa alcançou e as medalhas conforme
  FR-009, com o progresso de cada uma ainda não alcançada.
- **FR-004**: A aba MUST ter os atalhos "Ler mais notícias" (aba Início) e "Fazer novas
  atividades" (aba Atividades) e o botão de configurações no topo.
- **FR-005**: Para o visitante, a aba MUST mostrar o convite para entrar ou criar conta, sem
  chamar o serviço.
- **FR-006**: A aba MUST mostrar carregando, erro com "Tentar novamente" quando o perfil não vem,
  e um aviso só na área que falhou (números ou conquistas) quando só ela falha.
- **FR-007**: Os números e as conquistas MUST ser atualizados ao voltar à aba.

**Conquistas (RN-008)**

- **FR-008**: As conquistas MUST ser as fixas abaixo mais uma por módulo de atividades com
  lições, alcançadas pelas regras:

  | Conquista | Alcança quando |
  |---|---|
  | Primeira lição | 1 lição concluída |
  | Primeiro módulo | 1 módulo concluído |
  | Estudante dedicado | 10 lições concluídas |
  | Mestre da segurança | todos os módulos disponíveis concluídos (exige ao menos 1 módulo) |
  | Leitor atento | 1 notícia lida |
  | Leitor dedicado | 10 notícias lidas |
  | *(uma por módulo)* "nome do módulo" | todas as lições daquele módulo concluídas |

  O progresso de cada uma é "N de M" (ex.: "8 de 10 lições", "4 de 10 notícias"). Como lições,
  módulos e leituras concluídos não se desfazem, uma conquista alcançada não volta a ficar
  pendente (exceto "Mestre da segurança" quando o serviço acrescenta um módulo novo).
- **FR-009**: A aba MUST mostrar as medalhas numa faixa que desliza para o lado: as alcançadas
  primeiro e, depois, as mais perto de alcançar (maior proporção de progresso); empates seguem a
  ordem da tabela, e as de módulo, a ordem do serviço. "Ver todas" MUST mostrar a lista completa
  na mesma ordem.

**Listas de notícias (US4)**

- **FR-010**: Tocar em "Salvas" MUST abrir a lista de notícias salvas existente; tocar em "Lidas"
  ou "Curtidas" MUST abrir a lista correspondente, no mesmo visual, com rolagem que carrega mais
  sem repetir, estado vazio com atalho para o Início e erro com "Tentar novamente". Tocar numa
  notícia MUST abrir o detalhe.

**Editar dados (RF-036)**

- **FR-011**: "Editar perfil" MUST abrir com nome, e-mail e telefone atuais e só habilitar
  "Salvar" quando algo mudou.
- **FR-012**: O app MUST validar antes de enviar: nome de 6 a 150 caracteres (sem os espaços das
  pontas), e-mail em formato válido e telefone vazio ou com DDD e número (10 ou 11 dígitos). Erros
  aparecem no campo.
- **FR-013**: Salvar MUST enviar só o que mudou, mostrar "Dados salvos" e atualizar o nome e o
  e-mail no perfil e na saudação do app.
- **FR-014**: E-mail já usado por outra conta MUST mostrar o aviso no campo de e-mail, sem perder
  o que foi digitado.
- **FR-015**: Falha ao salvar MUST mostrar mensagem simples e manter o que foi digitado.
- **FR-016**: Sair com alterações não salvas MUST pedir confirmação para descartar.

**Foto (RF-036, CB-010)**

- **FR-017**: Tocar na foto em "Editar perfil" MUST oferecer galeria, câmera e, se houver foto,
  remover.
- **FR-018**: A foto escolhida MUST aparecer na hora, ser enviada ao serviço e, em falha, voltar à
  anterior com mensagem simples.
- **FR-019**: Remover a foto MUST pedir confirmação; em falha, a foto volta com mensagem simples.
- **FR-020**: Acesso negado à galeria ou à câmera MUST mostrar como liberar o acesso.

**Acessibilidade e textos**

- **FR-021**: Todo botão e campo MUST ter alvo de pelo menos 48×48 e rótulo para leitor de tela
  (o lápis sobre a foto lê "Editar perfil"; cada número lê, por exemplo, "12 notícias lidas, abrir
  lista"), funcionar com fonte grande e alto contraste, e todos os textos MUST existir em
  português e inglês.

### Key Entities

- **Perfil**: nome, e-mail, telefone (opcional), foto (opcional).
- **Números de notícias**: lidas, salvas e curtidas.
- **Progresso das atividades**: lições concluídas, módulos concluídos e, por módulo, lições
  concluídas e total (usado nas conquistas).
- **Conquista**: nome, regra para alcançar, alcançada ou não, progresso ("N de M").

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O perfil com números e conquistas aparece em até 3 segundos depois de abrir a aba,
  em conexão típica de 4G ou Wi-Fi.
- **SC-002**: 100% dos erros de preenchimento são mostrados no campo antes de qualquer envio.
- **SC-003**: Depois de salvar o nome, a saudação do Início mostra o nome novo na próxima vez que
  a pessoa a vê, sem reabrir o app.
- **SC-004**: Em 100% das falhas simuladas (sem internet, e-mail em uso, envio de foto falhando,
  lista sem internet), a pessoa vê uma mensagem simples e nada do que digitou é perdido.
- **SC-005**: Uma pessoa idosa consegue trocar a foto em até 4 toques a partir da aba Perfil.
- **SC-006**: Uma pessoa idosa chega a uma notícia que já leu em até 2 toques a partir da aba
  Perfil.
- **SC-007**: Com a fonte do sistema no maior tamanho e alto contraste, todas as telas desta
  feature podem ser lidas e usadas sem textos cortados.

## Assumptions

- **Visual aprovado**: quadro "Perfil — com conta (v4)" do Figma (2026-10-12): fundo liso, cartão
  branco com foto e nome, três cartões de números com ícone colorido, medalhas em cartões brancos
  com borda, dois atalhos coloridos e a barra inferior. Sombra só a leve do design system.
- **Visitante**: convite com "Entrar ou criar conta" e a lista do que se ganha com uma conta
  (quadro "Perfil — visitante" do Figma).
- **Configurações (B8)**: "Receber alertas", "Privacidade" e "Sobre o SafeNews" ficam lá
  (quadro "Configurações" do Figma); "Dados pessoais" abre a mesma tela "Editar perfil" desta
  feature.
- **E-mail**: a troca não pede senha nem confirmação por e-mail; o serviço aceita direto.
- **Telefone**: opcional; só números do Brasil (+55), como o serviço exige.
- **Foto**: escolhida pelos recursos da feature 007 (já reduzida); não fica cópia guardada no
  aparelho depois do envio, a foto exibida é a do serviço.
- **Listas de lidas e curtidas**: reaproveitam o visual e o comportamento da lista de salvas da
  feature 010; o serviço tem os pedidos de notícias lidas e curtidas (conferidos em 2026-10-12:
  existem e exigem conta).
- **Sem cópia sem internet**: o perfil e as listas de lidas e curtidas precisam de conexão; sem
  ela, mostram o erro com "Tentar novamente" (RNF-002 cobre só as salvas).
- **Endpoints ainda não conferidos** (🧪 no contrato): perfil, edição, foto, progresso das
  atividades e as listas de lidas e curtidas são conferidos no servidor real no plano. O servidor
  ainda não tem módulos de atividades (pedido feito ao backend em 2026-10-08).
