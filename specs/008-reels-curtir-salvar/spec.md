# Feature Specification: Reels com curtir, salvar e abrir a fonte

**Feature Branch**: `008-reels-curtir-salvar`

**Created**: 2026-10-08

**Status**: Draft

**Input**: User description: "A4 Reels (RF-013, RF-019 curtir) — Trilha A, módulo news. Tela de reels com PageView vertical (swipe) e botões de navegação, consumindo GET /app/news/reels (paginação por cursor). Curtir (POST /app/news/{id}/like) e salvar (POST /app/news/{id}/save), ambos alternam; o reel não traz isLiked, o estado vem do retorno do toggle. Visitante que tenta curtir/salvar → requireAccount. Abrir a fonte no navegador externo via ExternalLauncherService (F0.5). ReelEntity com content, likesCount, isSaved + model; GetReelsUseCase, ToggleLikeUseCase, ToggleSaveUseCase; ReelsController; ReelsPage com widget test. Seguir api-contract.md e openapi.json; TDD com fakes."

**Rastreabilidade**: tarefa A4 do [tasks do produto](../../.specify/memory/tasks.md) · RF-013,
RF-019 (curtir e salvar no Reel), RN-003, RNF-003, CB-002, CB-003, CB-004, CB-005, CB-007, CB-011
da [especificação do produto](../../.specify/memory/specification.md) v2.1.0 · seção "Notícias e
Reels" do [contrato da API](../../.specify/memory/api-contract.md) · rota `/reels?start=`, aba
central e convite para visitante da [feature 005](../005-shell-navegacao-base/spec.md) · carrossel
"Novidades" da [feature 006](../006-feed-inicio/spec.md) · abrir a fonte da
[feature 007](../007-servicos-plataforma-voz/spec.md) · visual:
[design system](../../.specify/memory/design-system.md) §7.10.

## Contexto

A aba central (Notícias) hoje mostra uma tela provisória ("Em breve"), e o carrossel "Novidades"
do Início já abre essa aba numa notícia específica. Esta feature coloca ali os Reels: notícias
curtas, uma por tela, que a pessoa passa arrastando para cima ou para baixo, como nas redes
sociais que o público já conhece. Em cada Reel, quem tem conta pode curtir e salvar; qualquer
pessoa pode abrir a fonte original ou a notícia completa.

Ficam fora: o detalhe da notícia (A5, a tela continua provisória; os Reels só a **abrem**), a
lista de notícias salvas (A5), a leitura em voz alta nos Reels (o RF-013 não pede) e os alertas
(A6).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Passar pelos Reels (Priority: P1)

A pessoa toca na aba Notícias (ou num cartão do carrossel "Novidades") e vê uma notícia por vez,
em tela cheia: imagem ao fundo, título, um trecho do texto e a fonte. Arrastando para cima, vai
para a próxima; para baixo, volta para a anterior. Também pode usar os botões de seta, para quem
tem dificuldade com o gesto. Ao chegar perto do fim do que foi carregado, mais Reels chegam, sem
repetir.

**Why this priority**: é o formato de consumo rápido do produto (UC-04) e a aba central do app.
Sem ele, as ações de curtir e salvar não têm onde existir.

**Independent Test**: com o servidor de desenvolvimento, abrir a aba Notícias como visitante,
passar por vários Reels arrastando e pelos botões, até carregar a parte seguinte; voltar ao
Início, tocar num cartão do carrossel e conferir que os Reels abrem naquela notícia.

**Acceptance Scenarios**:

1. **Given** a pessoa abre a aba Notícias, **When** os Reels estão chegando, **Then** vê o
   indicador de carregando sobre o fundo escuro.
2. **Given** os Reels chegaram, **When** a tela aparece, **Then** mostra o primeiro Reel em tela
   cheia: imagem ao fundo com gradiente escuro, as categorias da notícia, o título (até 4 linhas),
   um trecho do texto (até 4 linhas), a fonte e a data da publicação original em linguagem
   simples, sem barra superior e com a barra inferior visível.
3. **Given** um Reel está na tela, **When** a pessoa arrasta para cima, **Then** o próximo Reel
   aparece; **When** arrasta para baixo, **Then** o anterior aparece.
4. **Given** um Reel está na tela, **When** a pessoa toca no botão "Próxima notícia" ou "Notícia
   anterior", **Then** o Reel muda como no gesto; no primeiro Reel, "Notícia anterior" fica
   desabilitado.
5. **Given** a pessoa chegou perto do último Reel carregado (faltando 3 ou menos), **When** há
   mais Reels no serviço, **Then** a próxima parte é pedida e acrescentada ao fim, sem repetir
   nenhum Reel (CB-007).
6. **Given** o serviço indicou que não há mais Reels, **When** a pessoa chega ao último, **Then**
   nada mais é pedido, "Próxima notícia" fica desabilitado e um aviso discreto "Você viu todas as
   notícias" aparece no último Reel.
7. **Given** a pessoa tocou num cartão do carrossel "Novidades" (`/reels?start=<id>`), **When** a
   tela abre, **Then** o Reel daquela notícia é o primeiro mostrado, e arrastar para baixo leva
   aos Reels anteriores a ele na ordem do serviço.
8. **Given** a pessoa toca em "Ler notícia completa", **When** o toque acontece, **Then** o
   detalhe daquela notícia abre por cima das abas; ao voltar, o mesmo Reel continua na tela.
9. **Given** a pessoa troca de aba e volta para Notícias, **When** a aba reaparece, **Then** o
   mesmo Reel continua na tela (sem recarregar).

---

### User Story 2 - Curtir um Reel (Priority: P1)

A pessoa com conta toca no coração do Reel. O coração fica preenchido e o número de curtidas
aumenta. Tocar de novo desfaz a curtida. O visitante que toca no coração vê o convite para entrar
ou criar conta, e nada é enviado ao serviço.

**Why this priority**: é a interação principal do Reel (RF-019) e a primeira ação de escrita do
app em conteúdo; valida o padrão de ação restrita para visitante (RN-003) que A5 vai reusar.

**Independent Test**: entrar com uma conta de teste, curtir um Reel e ver o coração preenchido e a
contagem +1; tocar de novo e ver voltar; sair, entrar como visitante, tocar no coração e ver o
convite, sem pedido ao serviço.

**Acceptance Scenarios**:

1. **Given** um Reel na tela, **When** ele aparece, **Then** mostra o coração vazio e o número de
   curtidas vindo do serviço (o serviço não informa se a pessoa já curtiu; ver Assumptions).
2. **Given** a pessoa tem conta, **When** toca no coração, **Then** o coração preenche e a
   contagem sobe 1 na hora; quando o serviço responde, coração e contagem passam a mostrar
   exatamente o que o serviço devolveu.
3. **Given** a pessoa tem conta e o coração está preenchido, **When** toca de novo, **Then** o
   coração esvazia e a contagem desce 1 na hora, e depois reflete a resposta do serviço.
4. **Given** a pessoa já tinha curtido aquela notícia antes (em outra sessão) e o coração aparece
   vazio, **When** toca no coração, **Then** o serviço desfaz a curtida e o app mostra o coração
   vazio com a contagem devolvida pelo serviço, sem erro.
5. **Given** a pessoa é visitante, **When** toca no coração, **Then** aparece o convite para entrar
   ou criar conta (CB-011) e nenhum pedido é feito ao serviço; o coração não muda.
6. **Given** o pedido de curtir falhou (sem internet, erro do serviço), **When** a falha chega,
   **Then** coração e contagem voltam ao estado anterior e aparece um aviso curto com a mensagem
   do erro (CB-002, CB-004).
7. **Given** a pessoa toca várias vezes seguidas no coração, **When** um pedido ainda está em
   andamento, **Then** os toques extras são ignorados até a resposta chegar.
8. **Given** a pessoa curtiu um Reel, **When** passa para outros e volta a ele, **Then** o coração
   e a contagem continuam como ficaram.

---

### User Story 3 - Salvar um Reel para ler depois (Priority: P2)

A pessoa com conta toca no marcador do Reel para salvar a notícia; tocar de novo remove dos
salvos. O visitante vê o convite.

**Why this priority**: RF-019 pede salvar; o serviço já informa o estado de salvo nos Reels, então
o valor é imediato. A lista de salvas (onde a pessoa reencontra a notícia) é da A5, por isso P2.

**Independent Test**: com conta, salvar um Reel e ver o marcador preenchido; recarregar a aba e
conferir que continua salvo (estado vem do serviço); tocar de novo e ver desmarcar; como visitante,
ver o convite.

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta, **When** um Reel aparece, **Then** o marcador mostra se a notícia
   já está salva, conforme o serviço.
2. **Given** a pessoa tem conta, **When** toca no marcador, **Then** ele alterna na hora e, quando o
   serviço responde, passa a mostrar exatamente o estado devolvido; um aviso curto confirma
   ("Notícia salva" / "Removida dos salvos").
3. **Given** a pessoa é visitante, **When** toca no marcador, **Then** aparece o convite (CB-011),
   sem pedido ao serviço; para o visitante, o marcador aparece sempre vazio.
4. **Given** o pedido de salvar falhou, **When** a falha chega, **Then** o marcador volta ao estado
   anterior e aparece o aviso com a mensagem do erro.
5. **Given** toques repetidos durante um pedido em andamento, **When** acontecem, **Then** são
   ignorados até a resposta.

---

### User Story 4 - Abrir a fonte original (Priority: P2)

Em qualquer Reel, a pessoa toca em "Abrir fonte" e a página original da notícia abre no navegador
do aparelho, fora do app.

**Why this priority**: RF-013 pede a ação e ela ajuda a pessoa a conferir de onde veio a notícia,
hábito que o produto quer ensinar. Não depende de conta.

**Independent Test**: tocar em "Abrir fonte" num Reel e ver o navegador abrir no endereço da
notícia; repetir como visitante.

**Acceptance Scenarios**:

1. **Given** um Reel com endereço de fonte válido, **When** a pessoa toca em "Abrir fonte",
   **Then** o navegador externo abre naquele endereço (visitante ou com conta).
2. **Given** o aparelho não consegue abrir o endereço (sem navegador ou endereço inválido),
   **When** a pessoa toca, **Then** aparece o aviso "Não foi possível abrir a fonte" e o app
   continua no mesmo Reel.
3. **Given** um Reel sem endereço de fonte, **When** ele aparece, **Then** o botão "Abrir fonte"
   não é mostrado.

---

### Edge Cases

- **Serviço demorando a acordar** (servidor gratuito, ~40 s na primeira resposta): o indicador
  continua e, depois de alguns segundos, aparece "Conectando ao servidor…", como no feed.
- **Sem internet ou erro do serviço na primeira carga**: estado de erro sobre fundo escuro, com a
  mensagem do erro e "Tentar novamente" (CB-002, CB-004). Os Reels não têm cópia offline.
- **Falha ao carregar uma parte seguinte**: os Reels já carregados continuam; no último aparece
  "Não foi possível carregar mais" com "Tentar novamente"; não há pedido automático em laço.
- **Nenhum Reel no serviço**: estado vazio "Nenhuma notícia por aqui ainda." com "Atualizar".
- **`start` que não está entre os Reels carregados** (notícia antiga ou id inválido): a tela abre
  no primeiro Reel, sem erro e sem procurar em outras partes.
- **Resposta do serviço malformada**: vira erro genérico, sem travar a tela (CB-005); um Reel
  isolado com campos obrigatórios faltando é descartado e os demais aparecem.
- **Mesmo Reel em duas partes do serviço**: aparece uma vez só (CB-007).
- **Notícia removida no serviço** (404 `NEWS_NOT_FOUND` ao curtir/salvar): o estado volta e aparece
  "Notícia não encontrada".
- **Sessão expirada durante curtir/salvar** (401 e renovação recusada): o tratamento da feature
  002/005 encerra a sessão e mostra o aviso; o coração/marcador volta ao estado anterior.
- **Reel sem imagem ou imagem que não carrega**: fundo na cor `secondary` com o ícone de jornal,
  texto legível; sem erro.
- **Texto do Reel vazio**: o trecho não aparece; título, fonte e ações continuam.
- **Fonte do sistema grande**: título e trecho mantêm o limite de linhas com reticências; botões e
  textos não se sobrepõem; "Ler notícia completa" continua alcançável.
- **Toque duplo em "Ler notícia completa"**: abre o detalhe uma vez só.
- **Visitante que entra pela tela de convite e volta**: ao reabrir a aba Notícias com conta, os
  Reels são recarregados para trazer o estado de salvo daquela conta.
- **Leitor de tela (TalkBack)**: cada Reel anuncia título, fonte e data; os botões de seta permitem
  navegar sem o gesto de arrastar (RNF-003).

## Requirements *(mandatory)*

### Functional Requirements

**Tela e navegação (RF-013)**

- **FR-001**: A aba Notícias MUST mostrar os Reels, um por vez em tela cheia, sem barra superior e
  com a barra inferior visível, com: imagem de fundo (ou fundo neutro), categorias da notícia
  (RN-002), título (até 4 linhas), trecho do texto (até 4 linhas, cortado no app a partir do texto
  completo), fonte e data da publicação original em linguagem simples (mesmo formato do feed).
- **FR-002**: A pessoa MUST poder ir para o próximo/anterior arrastando na vertical e também pelos
  botões "Próxima notícia"/"Notícia anterior"; os botões MUST ficar desabilitados quando não houver
  para onde ir.
- **FR-003**: Os Reels MUST seguir a ordem do serviço e MUST pedir a próxima parte quando faltarem 3
  ou menos Reels carregados à frente, até o serviço indicar o fim; MUST NOT repetir um Reel nem
  pedir partes depois do fim (CB-007).
- **FR-004**: Aberta com uma notícia de início, a tela MUST começar no Reel dessa notícia se ele
  estiver na primeira parte carregada; caso contrário, MUST começar no primeiro Reel, sem erro.
- **FR-005**: "Ler notícia completa" MUST abrir o detalhe da notícia por cima das abas, uma vez só
  por toque, e o Reel atual MUST continuar o mesmo ao voltar.
- **FR-006**: A posição atual e os Reels já carregados MUST ser mantidos ao trocar de aba e voltar.
- **FR-007**: A tela MUST mostrar os estados carregando (com "Conectando ao servidor…" após alguns
  segundos), erro com "Tentar novamente" e vazio com "Atualizar", no padrão escuro da tela.
- **FR-008**: Falha numa parte seguinte MUST manter os Reels já mostrados e oferecer "Tentar
  novamente" no último Reel, sem repetição automática.
- **FR-009**: O visitante MUST ver os Reels sem credencial; quem tem conta MUST receber o estado de
  salvo de cada Reel.

**Curtir (RF-019, RN-003)**

- **FR-010**: Cada Reel MUST mostrar o botão de curtir com o número de curtidas do serviço; o botão
  MUST começar desmarcado, porque o serviço não informa a curtida da pessoa nos Reels.
- **FR-011**: Com conta, tocar em curtir MUST alternar o estado na hora (coração e contagem ±1) e,
  com a resposta do serviço, MUST mostrar exatamente o estado e a contagem devolvidos.
- **FR-012**: Para visitante, curtir MUST abrir o convite para entrar ou criar conta e MUST NOT
  chamar o serviço (RN-003, CB-011).
- **FR-013**: Se o pedido falhar, coração e contagem MUST voltar ao estado anterior e a mensagem do
  erro MUST aparecer num aviso curto; 404 MUST mostrar "Notícia não encontrada".
- **FR-014**: Enquanto um pedido de curtir de um Reel está em andamento, novos toques nesse botão
  MUST ser ignorados.
- **FR-015**: O estado de curtida e a contagem MUST ser mantidos enquanto a pessoa navega pelos
  Reels carregados.

**Salvar (RF-019, RN-003)**

- **FR-016**: Com conta, o botão de salvar MUST refletir o estado de salvo vindo do serviço; para
  visitante, MUST aparecer sempre desmarcado.
- **FR-017**: Com conta, tocar em salvar MUST alternar na hora, mostrar "Notícia salva" ou
  "Removida dos salvos" e, com a resposta, MUST mostrar exatamente o estado devolvido.
- **FR-018**: Para visitante, salvar MUST abrir o convite e MUST NOT chamar o serviço.
- **FR-019**: Falha ao salvar e toques repetidos MUST seguir as mesmas regras de FR-013 e FR-014.

**Abrir a fonte (RF-013)**

- **FR-020**: "Abrir fonte" MUST abrir o endereço original da notícia no navegador externo do
  aparelho, para qualquer pessoa; sem endereço, o botão MUST NOT aparecer; se o aparelho não
  conseguir abrir, MUST mostrar "Não foi possível abrir a fonte".

**Acessibilidade e textos (RNF-003, RNF-004)**

- **FR-021**: Todos os botões da tela MUST ter área de toque de pelo menos 48×48 dp (mesmo com o
  visual de 40 px do design system) e rótulo para leitor de tela, incluindo o estado ("Curtir,
  12 curtidas", "Curtido", "Salvar", "Salvo").
- **FR-022**: Todos os textos fixos da tela MUST existir em português e inglês; o conteúdo das
  notícias vem do serviço e não é traduzido.

### Key Entities

- **Reel**: notícia em formato curto — identificador, título, fonte, endereço da fonte, imagem
  opcional, data da publicação original, categorias, texto completo (de onde sai o trecho),
  número de curtidas e, só com conta, se está salva. Não inclui se a pessoa curtiu.
- **Parte de Reels**: lista de Reels e a marca de onde continuar (vazia quando acabou).
- **Resultado de curtir**: se ficou curtido e o novo número de curtidas.
- **Resultado de salvar**: se ficou salvo.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com o serviço acordado e internet comum, a pessoa vê o primeiro Reel em até 3
  segundos depois de abrir a aba Notícias.
- **SC-002**: Passando por todos os Reels de um serviço com várias partes, nenhum Reel aparece duas
  vezes e nenhum pedido é feito depois do fim (100% dos casos testados).
- **SC-003**: Curtir ou salvar dá retorno visual em menos de 100 ms após o toque, antes da resposta
  do serviço.
- **SC-004**: Em 100% das tentativas de curtir ou salvar como visitante, o convite aparece e nenhum
  pedido é feito ao serviço.
- **SC-005**: Em 100% das falhas de curtir/salvar, o botão volta ao estado anterior e a pessoa vê
  uma mensagem.
- **SC-006**: Uma pessoa consegue passar por 5 Reels usando só os botões (sem gesto) e com o leitor
  de tela ligado.
- **SC-007**: Todos os botões medem pelo menos 48×48 dp e têm rótulo para leitor de tela.

## Assumptions

- **Curtida começa desmarcada**: o serviço não envia `isLiked` nos Reels (contrato da API). Quem já
  curtiu antes vê o coração vazio; tocar desfaz a curtida no serviço e o app mostra o que o serviço
  devolveu (cenário 2.4). Buscar as curtidas da pessoa (`/users/me/news/liked`) fica fora da v1,
  como no contrato.
- **Atualização otimista**: o app muda o botão na hora e corrige com a resposta, para dar retorno
  imediato ao público idoso; em falha, volta atrás.
- **Notícia de início**: só é procurada na primeira parte (o carrossel do Início usa os primeiros
  Reels do serviço, então ela quase sempre está lá). Os Reels anteriores a ela continuam
  acessíveis arrastando para baixo.
- **Tamanho das partes**: 10 Reels por parte; pedir a próxima quando faltarem 3.
- **Sem cópia offline**: os Reels não são guardados no aparelho (o RNF-002 cobre feed e salvos);
  sem internet, a tela mostra o erro com "Tentar novamente".
- **Imagem, não vídeo**: o serviço só envia imagem; o design system fala em "vídeo/imagem", e a v1
  usa imagem.
- **Ler notícia completa**: abre a rota de detalhe já existente (`/news/:id`), que continua
  provisória até a A5.
- **Estados compartilhados com A5**: curtir/salvar dos Reels não precisam sincronizar com o
  detalhe nem com o feed nesta feature; cada tela mostra o que o serviço devolveu na sua carga.
- **Contrato da API**: like e save estão como 🧪 no contrato; os formatos (`{liked, likesCount}` e
  `{saved}`) serão conferidos no servidor real antes da camada de dados, e o contrato atualizado
  para ✅.
- **Dependências**: features 002 (cliente de API, renovação de sessão), 005 (aba central, rotas
  `/reels?start=` e `/news/:id`, convite para visitante, estados comuns), 006 (formato de data e
  categorias, carrossel que abre os Reels) e 007 (abrir endereço no navegador externo).
