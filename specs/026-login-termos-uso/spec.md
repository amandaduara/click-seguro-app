# Feature Specification: Login que continua a splash, aceite dos termos e Termos de uso

**Feature Branch**: `026-login-termos-uso`

**Created**: 2026-11-23

**Status**: Draft

**Input**: Versão A aprovada pela usuária no canvas de design
(https://claude.ai/artifact/Sninpo6jiADGa2r4YAgPRu: telas "A · Continuação da splash",
"A · Animação splash → login", "A · Cadastro com aceite dos termos" e "Termos de uso"), com as
correções que ela fez no próprio canvas em 2026-11-23.

**Rastreabilidade**: nova tarefa **R3 Login, aceite dos termos e Termos de uso** no
[tasks do produto](../../.specify/memory/tasks.md) · RF-001 (splash), RF-003 (cadastro), RF-004
(login), RF-005 (visitante), RF-037 (Configurações), RF-041 (leitura em voz alta), RN-001 (regras
do cadastro), RNF-003 e RNF-004 (idosos e acessibilidade), RNF-006 (textos traduzidos) e RNF-008
(privacidade) da [especificação do produto](../../.specify/memory/specification.md) ·
[feature 023](../023-splash-animada/spec.md) (splash) · [feature 024](../024-redesign-visual/spec.md)
(redesign 2.0).

## Contexto

A splash termina com a marca coral no centro, o nome e o slogan, e uma onda coral dupla no
rodapé. Logo depois, o login abre com outro desenho: a marca num selo à esquerda e nada da onda.
A passagem parece uma troca de app. A versão A aprovada mantém a onda no mesmo lugar e faz a
marca subir até o topo do login, para as duas telas parecerem uma só.

O app também não tem Termos de uso. As Configurações só têm "Privacidade" e "Sobre", e o
cadastro não pede aceite de nada. O padrão do mercado (e da LGPD para o consentimento) é uma
caixa desmarcada "Li e aceito…" com links para os documentos, sem a qual a conta não é criada.

## Clarifications

### Session 2026-11-23

- Q: Se a pessoa marca o aceite, troca para a aba "Entrar" e volta para "Criar conta", a caixa
  continua marcada? → A: Sim. Continua marcada enquanto a tela de login estiver aberta (como o
  e-mail e a senha); volta desmarcada só quando a tela é aberta de novo.
- Q: Que frase curta aparece embaixo de "Termos de uso" na lista das Configurações? → A: "O que
  vale ao usar o app".
- Validação no aparelho (2026-11-23): a onda presa ao pé da tela ficava por cima do texto. → A:
  a onda fica no fim do conteúdo, no pé da tela quando tudo cabe (como logo depois da splash) e,
  quando o conteúdo é maior que a tela, depois do último item, rolando junto; nunca cobre texto.
  Para o login caber num celular comum com a onda no pé, os espaços ficaram menores e o título
  passou a `title1` (24), numa linha só.
- Validação no aparelho (2026-11-23): a saída da splash para o onboarding e a passagem do
  onboarding para o login estavam secas (só um esmaecimento). → A: splash → onboarding com "onda
  desce, slide sobe"; onboarding → login com "onda sobe, login entra" (US5, FR-020 a FR-022).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ler os Termos de uso (Priority: P1)

Uma pessoa (com conta ou visitante) abre as Configurações, toca em "Termos de uso" e lê, em
linguagem simples, o que o app é, o que ele não faz, como cuidar da conta, o bom uso do app e
onde ver como os dados são tratados. Pode pedir para o app ler a tela em voz alta.

**Why this priority**: o aceite do cadastro (US2) só faz sentido se o documento existir e puder
ser lido. Sozinha, a tela já entrega valor: deixa claro que o app é educativo e não substitui o
banco nem a polícia.

**Independent Test**: abrir Configurações → Termos de uso, conferir os cinco assuntos, a data,
o "Ouvir" e o link "Ver Privacidade".

**Acceptance Scenarios**:

1. **Given** as Configurações abertas (com conta ou visitante), **When** a pessoa toca em
   "Termos de uso", **Then** abre a tela "Termos de uso" com o voltar e o título na mesma linha,
   o botão "Ouvir", a linha "Última atualização: 23/11/2026" e um cartão para cada assunto, na
   ordem: O que é o Click Seguro; O que o app não faz; Sua conta; Bom uso do app; Seus dados.
2. **Given** a tela Termos de uso, **When** a pessoa toca em "Ver Privacidade" no cartão
   "Seus dados", **Then** abre a tela Privacidade que já existe.
3. **Given** a tela Termos de uso, **When** a pessoa toca em "Ouvir", **Then** o app lê o título,
   a data e cada assunto (título e texto) na ordem da tela, no idioma do app.
4. **Given** o app em inglês, **When** a tela abre, **Then** todos os textos aparecem em inglês.

---

### User Story 2 - Aceitar os termos ao criar a conta (Priority: P1)

Ao criar a conta, abaixo das regras da senha, a pessoa vê a caixa "Li e aceito os Termos de uso
e a Política de privacidade.", desmarcada. Pode tocar nos nomes para ler cada documento e
voltar. "Criar conta" só fica ativo quando a caixa está marcada e os campos estão corretos.

**Why this priority**: é o requisito novo de produto (consentimento antes de criar a conta).

**Independent Test**: na aba "Criar conta", preencher nome, e-mail e uma senha que cumpra as
cinco regras e conferir que "Criar conta" só ativa depois de marcar a caixa.

**Acceptance Scenarios**:

1. **Given** a aba "Criar conta" aberta, **When** ela aparece, **Then** a caixa de aceite vem
   desmarcada, abaixo das regras da senha e acima de "Criar conta".
2. **Given** nome, e-mail e senha válidos e a caixa desmarcada, **When** a pessoa olha o botão,
   **Then** "Criar conta" está desativado.
3. **Given** os campos válidos, **When** a pessoa marca a caixa (tocando no quadrado ou no texto
   "Li e aceito os"), **Then** a caixa aparece marcada, o cartão do aceite fica coral claro com
   borda coral e "Criar conta" fica ativo.
4. **Given** a caixa marcada, **When** a pessoa desmarca, **Then** "Criar conta" volta a ficar
   desativado.
5. **Given** a aba "Criar conta", **When** a pessoa toca em "Termos de uso", **Then** abre a tela
   Termos de uso; ao voltar, o que ela digitou e o estado da caixa continuam iguais.
6. **Given** a aba "Criar conta", **When** a pessoa toca em "Política de privacidade", **Then**
   abre a tela Privacidade; ao voltar, nada do formulário se perde.
7. **Given** a caixa marcada, **When** a pessoa troca para a aba "Entrar" e volta para "Criar
   conta", **Then** a caixa continua marcada.
8. **Given** a caixa marcada, **When** a pessoa sai da tela de login e ela é aberta de novo,
   **Then** a caixa volta desmarcada.

---

### User Story 3 - Login e cadastro no visual da splash (Priority: P2)

A pessoa vê o login com a marca coral pequena e centralizada no topo, "Bem-vindo ao Click
Seguro" e "Sua segurança em primeiro lugar" centralizados, as abas, os campos, "Esqueci minha
senha" à direita, o botão "Entrar" com seta, "Continuar sem login" como link coral e a onda coral
dupla da splash no rodapé. O cadastro usa o mesmo cabeçalho e a mesma onda.

**Why this priority**: muda só a aparência; todo o comportamento do login já existe.

**Independent Test**: abrir o login direto (por exemplo, saindo da conta) e comparar com a tela
"A · Continuação da splash" e o cadastro com "A · Cadastro com aceite dos termos".

**Acceptance Scenarios**:

1. **Given** o login aberto, **When** a tela aparece, **Then** a ordem de cima para baixo é:
   marca, título, slogan, abas Entrar/Criar conta, E-mail, Senha, "Esqueci minha senha" (à
   direita), "Entrar" (com seta) e "Continuar sem login"; a onda coral dupla fica no rodapé.
2. **Given** o login num celular comum, **When** a tela abre, **Then** a onda fica no pé da tela,
   abaixo do último item; **When** a fonte está grande e o conteúdo passa da altura da tela,
   **Then** a onda vem depois do último item e rola junto, sem cobrir texto.
3. **Given** o tema de alto contraste ligado, **When** o login abre, **Then** a onda e a marca
   usam as cores do alto contraste e os textos mantêm o contraste exigido.
4. **Given** o login, **When** a pessoa usa "Entrar", "Esqueci minha senha", "Continuar sem
   login" ou troca de aba, **Then** tudo funciona como hoje (mesmas validações, mensagens e
   destinos).

---

### User Story 4 - Passagem animada da splash para o login (Priority: P3)

Quando a splash termina e a pessoa não tem sessão, a onda fica parada no rodapé, a marca sobe e
encolhe até o lugar dela no login, o nome e o slogan da splash somem e o cabeçalho e o formulário
do login entram subindo, um depois do outro.

**Why this priority**: acabamento; as US1 a US3 funcionam sem ela.

**Independent Test**: abrir o app sem sessão (onboarding já visto) e comparar com a tela
"A · Animação splash → login"; repetir com "Reduzir animações" ligado.

**Acceptance Scenarios**:

1. **Given** o app aberto sem sessão e com o onboarding já visto, **When** a splash termina,
   **Then** a marca se move do centro até o topo do login sem sumir, a onda não se mexe, e o
   conteúdo do login aparece em sequência em cerca de 1,5 s no total.
2. **Given** "Reduzir animações" ligado, **When** a splash termina, **Then** o login aparece
   direto, sem a marca voar e sem os itens subirem.
3. **Given** uma sessão válida, **When** a splash termina, **Then** a passagem para o Início é a
   de hoje (esta animação só existe na ida para o login).
4. **Given** o login aberto por outro caminho (sair da conta, aviso das atividades, link de
   cadastro), **When** ele aparece, **Then** usa a transição normal entre telas, sem a marca voar.

---

### User Story 5 - Passagens splash → onboarding e onboarding → login (Priority: P3)

Na primeira abertura, a splash não corta seco para o onboarding: a marca, o nome e o slogan sobem
e somem, a onda coral desce e sai pelo pé da tela, e o primeiro slide entra (a ilustração cresce
de leve; título, texto, pontinhos e botão sobem em sequência). Ao tocar em "Começar" ou "Pular",
o onboarding desliza para a esquerda e some; no login, a onda coral sobe do pé da tela até o
lugar dela, a marca do cabeçalho cresce e os blocos entram subindo em sequência.

**Why this priority**: acabamento pedido na validação; nada muda no fluxo.

**Independent Test**: limpar os dados do app e abrir: splash → onboarding → login, conferindo as
duas passagens; repetir com "Reduzir animações".

**Acceptance Scenarios**:

1. **Given** a primeira abertura, **When** a splash termina, **Then** o primeiro quadro do
   onboarding é o último da splash (marca, nome, slogan e onda no mesmo lugar), a onda desce e
   sai, e o slide entra em sequência em cerca de 1 s.
2. **Given** o onboarding, **When** a pessoa toca em "Começar" ou "Pular", **Then** o onboarding
   desliza para a esquerda e some, e o login abre com a onda subindo e os blocos entrando.
3. **Given** "Reduzir animações" ligado, **When** a splash termina ou a pessoa sai do onboarding,
   **Then** as telas trocam direto, sem movimento.
4. **Given** qualquer passagem animada em curso, **When** a pessoa toca na tela, **Then** nada
   acontece até a tela terminar de entrar.

---

### Edge Cases

- A pessoa marca o aceite, abre os Termos e volta: a caixa continua marcada.
- A pessoa abre os Termos pelo cadastro e, de lá, abre a Privacidade: voltar duas vezes leva ao
  cadastro com tudo preenchido.
- O cadastro falha (e-mail já cadastrado, sem internet): a caixa continua marcada para tentar de
  novo.
- Leitor de tela: a caixa é anunciada como caixa de seleção, com o texto completo e o estado
  (marcada ou não); cada link é anunciado como link.
- Fonte "Muito grande": o texto do aceite quebra em várias linhas sem cortar e a área de toque da
  caixa continua com pelo menos 48 px.
- O aparelho não tem voz no idioma do app: o "Ouvir" dos Termos some, como nas outras telas.
- A splash leva mais tempo validando a sessão: a animação para o login só começa depois que o
  destino é conhecido.
- Tela muito baixa ou fonte grande durante a animação: a marca termina no lugar exato em que o
  login a desenha.

## Requirements *(mandatory)*

### Functional Requirements

#### Termos de uso

- **FR-001**: O app MUST ter a tela "Termos de uso" no molde da tela Privacidade: voltar redondo
  e título na mesma linha, "Ouvir" logo abaixo, a linha "Última atualização: 23/11/2026" e um
  cartão por assunto com ícone, título e texto.
- **FR-002**: Os assuntos e textos MUST ser os aprovados no canvas, nesta ordem:
  1. **O que é o Click Seguro**: "O Click Seguro ajuda você a reconhecer golpes digitais com
     notícias e atividades. É gratuito e foi feito como Trabalho de Conclusão de Curso."
  2. **O que o app não faz**: "O app ensina a desconfiar, mas não garante que uma mensagem ou
     ligação é segura. Ele não substitui o seu banco, a polícia nem um profissional. Caiu em um
     golpe? Ligue para o seu banco e registre um boletim de ocorrência."
  3. **Sua conta**: "Use um e-mail seu e guarde a senha só para você. Não passe a senha para
     ninguém, nem para quem diz ser do Click Seguro: nós nunca pedimos."
  4. **Bom uso do app**: "Use o Click Seguro para aprender e se proteger. Não tente copiar, mudar
     ou atrapalhar o funcionamento do serviço."
  5. **Seus dados**: "O que guardamos, onde e para quê está explicado na tela Privacidade.",
     seguido do link "Ver Privacidade", que abre a tela Privacidade.
- **FR-003**: O "Ouvir" dos Termos MUST ler o título, a data e cada assunto (título e texto), na
  ordem da tela e no idioma do app, seguindo as regras do "Ouvir" das outras telas das
  Configurações (inclusive a leitura automática).
- **FR-004**: As Configurações MUST ter a linha "Termos de uso", com a frase "O que vale ao usar
  o app" embaixo, logo depois de "Privacidade", para quem tem conta e para o visitante.

#### Aceite no cadastro

- **FR-005**: A aba "Criar conta" MUST mostrar, abaixo das regras da senha e acima de "Criar
  conta", um cartão com uma caixa de seleção e o texto "Li e aceito os Termos de uso e a Política
  de privacidade.". A caixa MUST vir desmarcada sempre que a tela de login é aberta e MUST manter
  o estado na troca entre as abas "Entrar" e "Criar conta" enquanto a tela continua aberta.
- **FR-006**: "Termos de uso" e "Política de privacidade" MUST ser links que abrem,
  respectivamente, a tela Termos de uso e a tela Privacidade, sem perder o que foi digitado nem o
  estado da caixa. As duas telas MUST abrir também sem sessão, inclusive logo depois de "Sair da
  conta" (hoje, sem sessão, o app só deixa abrir a splash, o onboarding, o login e a recuperação
  de senha).
- **FR-007**: Tocar no quadrado ou no texto fora dos links MUST marcar ou desmarcar a caixa. A
  área de toque da caixa MUST ter no mínimo 48 × 48.
- **FR-008**: Marcada, a caixa MUST aparecer preenchida em coral com o sinal de visto, e o cartão
  MUST ficar coral claro com borda coral. Desmarcada, a caixa tem só o contorno e o cartão fica
  branco com a borda clara.
- **FR-009**: "Criar conta" MUST ficar desativado enquanto a caixa estiver desmarcada, além das
  regras que já existem (RN-001). O aceite só libera o cadastro: nada novo é enviado ao serviço.
- **FR-010**: A caixa MUST ser anunciada pelo leitor de tela como caixa de seleção, com o texto
  completo e o estado, e cada link como link.

#### Visual do login e do cadastro

- **FR-011**: O login e o cadastro MUST ter, no topo, a marca coral pequena centralizada, o
  título "Bem-vindo ao Click Seguro" e o slogan "Sua segurança em primeiro lugar", centralizados.
- **FR-012**: "Esqueci minha senha" MUST ficar alinhado à direita; "Entrar" e "Criar conta"
  MUST ter a seta à direita do texto; "Continuar sem login" MUST ser um link coral centralizado,
  no lugar do botão secundário e do divisor "ou".
- **FR-013**: A onda coral dupla da splash MUST ficar no fim do login e do cadastro, com a
  mesma forma, altura e cores do fim da splash: no pé da tela quando o conteúdo cabe e, quando não
  cabe, depois do último item, rolando junto. A onda MUST NOT ficar por cima de nenhum texto
  (validação de 2026-11-23).
- **FR-014**: O aviso "Sem conta, seu progresso vale só até fechar o app." MUST sair do login e
  do cadastro; fica só o link "Continuar sem login" (decisão da usuária, 2026-11-23). Os outros
  avisos do visitante (RF-030, fim do módulo) continuam.
- **FR-015**: O comportamento atual do login e do cadastro MUST continuar igual: validações,
  mensagens, recuperação de senha, visitante e destino depois de entrar.

#### Passagem da splash para o login

- **FR-016**: Quando a splash leva ao login, a passagem MUST ser contínua: a onda fica parada; a
  marca sai do centro e termina, menor, no lugar exato do topo do login; o nome e o slogan da
  splash somem; o título, as abas, os campos, o botão e o link do login entram subindo, um depois
  do outro. Tudo leva cerca de 1,5 s.
- **FR-017**: Com "Reduzir animações" ligado, o login MUST aparecer direto, sem a marca voar e
  sem os itens subirem.
- **FR-018**: A passagem animada com a marca voando MUST existir só da splash para o login. A ida
  da splash para o Início e as outras aberturas do login (sair da conta, avisos, Configurações)
  usam a transição de hoje. A splash → onboarding e o onboarding → login seguem a US5.

#### Passagens da primeira abertura (validação de 2026-11-23)

- **FR-020**: Da splash para o onboarding, o primeiro quadro do onboarding MUST ser o último da
  splash; a marca, o nome e o slogan sobem e somem, a onda desce e sai pelo pé da tela, e o
  primeiro slide entra (ilustração crescendo de leve; título, "Ouvir", texto, pontinhos, botão e
  "Pular" subindo em sequência), em cerca de 1 s.
- **FR-021**: Ao sair do onboarding ("Começar" ou "Pular"), o onboarding MUST deslizar para a
  esquerda e sumir; o login abre com a onda subindo do pé da tela até o lugar dela, a marca do
  cabeçalho crescendo e os blocos entrando em sequência.
- **FR-022**: Com "Reduzir animações", as duas passagens MUST trocar de tela direto. Durante as
  passagens, os toques são ignorados.

#### Textos

- **FR-019**: Todos os textos novos MUST existir em português do Brasil e em inglês dos EUA.

### Key Entities

- **Aceite dos termos**: estado da caixa no cadastro (marcada ou não). Vive só enquanto a tela
  de login está aberta (sobrevive à troca de abas); não é guardado no aparelho nem enviado ao
  serviço.
- **Termos de uso**: documento fixo do app, com a data da última atualização e cinco assuntos
  (ícone, título, texto), traduzido nos dois idiomas.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% das tentativas, não é possível criar uma conta sem marcar o aceite.
- **SC-002**: Uma pessoa encontra e abre os Termos de uso em até 2 toques a partir das
  Configurações e em 1 toque a partir do cadastro.
- **SC-003**: Abrir os Termos ou a Privacidade pelo cadastro e voltar não apaga nenhum campo nem
  o estado da caixa (0 perdas nos testes).
- **SC-004**: Na validação no aparelho, a usuária reconhece a passagem da splash para o login
  como uma tela só, sem "piscar" nem pular a marca, e com "Reduzir animações" o login aparece em
  menos de meio segundo depois da splash.
- **SC-005**: Todos os elementos tocáveis novos têm pelo menos 48 × 48 e todos os textos novos
  passam no contraste exigido, nos temas normal e de alto contraste.
- **SC-006**: 100% dos textos novos aparecem traduzidos com o app em inglês.

## Assumptions

- O serviço não tem campo de aceite dos termos (conferido no contrato da API 1.1.x); por isso o
  aceite não é registrado nem enviado, e quem já tem conta não precisa aceitar de novo.
- A "Política de privacidade" do cadastro é a tela "Privacidade" que já existe; o nome da linha
  nas Configurações continua "Privacidade".
- O texto dos Termos é o aprovado pela usuária no canvas; mudanças futuras no texto atualizam a
  data. Em inglês, a data segue o formato dos EUA ("Last updated: 11/23/2026").
- O desenho do login com teclado aberto segue o de hoje (a tela encolhe e rola); a onda pode ficar coberta
  pelo teclado.
- A animação para o login reaproveita as cores e a forma da onda da splash (feature 023) e o
  "Reduzir animações" da feature 022.
- A troca entre as abas Entrar e Criar conta continua com a animação de hoje dos campos que
  entram e saem.
