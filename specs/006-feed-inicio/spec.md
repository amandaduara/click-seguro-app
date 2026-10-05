# Feature Specification: Feed da aba Início

**Feature Branch**: `006-feed-inicio`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "A3 Feed da aba Início (RF-009 a RF-012, RN-002, RNF-002, RNF-005, CB-001, CB-006, CB-007): substitui a página provisória do Início (NewsHomePage) pelo feed real do wireframe FeedScreen.tsx — AppTopBar com subtítulo "N notícias novas para você", busca com debounce e cancelamento, chips de categoria (troca de endpoint), carrossel "Novidades" de Reels (abre /reels?start=id), lista "Tudo recente" com NewsCard compacto (abre /news/:id) e paginação sem duplicar; endpoints /app/news/feed (cursor), /app/news (categoria/busca, por página), /categories e /app/news/reels; cache da 1ª carga do feed para uso offline com SafeOfflineBanner; estados SafeLoadingState/SafeErrorState/SafeEmptyState; visitante lê sem token. Curtir/salvar ficam para A4/A5 (o card só mostra o estado). Confirmar os schemas no api-contract.md/openapi.json antes da camada data/."

**Rastreabilidade**: tarefa A3 do [tasks do produto](../../.specify/memory/tasks.md) · RF-009,
RF-010, RF-011, RF-012, RN-002, RN-003, RNF-002, RNF-003, RNF-005, CB-001, CB-002, CB-006, CB-007
da [especificação do produto](../../.specify/memory/specification.md) v2.1.0 · seção "Notícias e
Reels" do [contrato da API](../../.specify/memory/api-contract.md) · casca, barra superior e
estados comuns da [feature 005](../005-shell-navegacao-base/spec.md) · visual:
`wireframe/src/components/screens/FeedScreen.tsx` e `NewsCard.tsx`;
[design system](../../.specify/memory/design-system.md) §7.4, §7.6, §7.8, §7.9 e §7.16.

## Clarifications

### Session 2026-10-05

- Q: O que conta como "notícia nova" no subtítulo? → A: Notícias publicadas nas últimas 24 horas (data da publicação original), entre as carregadas; vale igual para visitante e para quem tem conta.

## Contexto

A aba Início hoje mostra uma tela provisória ("Em breve"). Esta feature coloca nela o feed de
notícias: o que a pessoa vê toda vez que abre o app. É a primeira tela do SafeNews que busca dados
no serviço.

Ficam fora: a tela de Reels (A4), o detalhe da notícia (A5), curtir e salvar (A4/A5) e os
alertas (A6). O feed só **abre** essas telas.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver as notícias mais recentes ao abrir o app (Priority: P1)

A pessoa abre o app e, na aba Início, vê a saudação, quantas notícias novas há, um carrossel de
Novidades em formato de Reels, os destaques e a lista "Tudo recente", da mais nova para a mais
antiga. Ao rolar até o fim, mais notícias aparecem, sem repetir nenhuma. Tocar numa notícia abre
o detalhe; tocar num cartão do carrossel abre os Reels naquela notícia.

**Why this priority**: é o coração do produto. Sem o feed, a pessoa não tem o que ler e o app não
cumpre o objetivo de informar sobre golpes.

**Independent Test**: com o servidor de desenvolvimento, abrir o app como visitante e ver as
notícias; rolar até carregar a segunda parte; tocar numa notícia e chegar ao detalhe provisório;
tocar num cartão do carrossel e chegar à aba de Reels.

**Acceptance Scenarios**:

1. **Given** a pessoa abre a aba Início, **When** as notícias estão chegando, **Then** vê o
   indicador de carregando no lugar do conteúdo.
2. **Given** as notícias chegaram, **When** a tela aparece, **Then** mostra, nesta ordem: barra
   superior com o título "Notícias seguras" e a saudação; campo de busca; filtros de categoria;
   carrossel "Novidades"; seção "Destaques" (se houver); seção "Recomendadas para você" (só para
   quem tem conta e se houver); e "Tudo recente".
3. **Given** a lista "Tudo recente", **When** a pessoa olha um cartão, **Then** vê imagem
   (quando houver), título (até duas linhas), fonte, data da publicação original em linguagem
   simples ("Hoje", "Ontem", "Há 3 dias", ou a data) e as categorias da notícia.
4. **Given** uma notícia sem categoria, **When** o cartão aparece, **Then** ele é exibido
   normalmente, sem rótulo de categoria (RN-002).
5. **Given** a pessoa rola até o fim da lista, **When** existem mais notícias, **Then** a próxima
   parte é carregada e acrescentada ao fim, com um indicador discreto enquanto carrega, sem
   repetir notícias já mostradas (CB-007).
6. **Given** a lista chegou ao fim de verdade, **When** a pessoa rola até o fim, **Then** nada
   mais é pedido ao serviço e aparece "Você viu todas as notícias".
7. **Given** a pessoa toca num cartão da lista, dos destaques ou das recomendações, **When** o
   toque acontece, **Then** o detalhe daquela notícia abre por cima das abas.
8. **Given** a pessoa toca num cartão do carrossel "Novidades", **When** o toque acontece,
   **Then** a aba Notícias (Reels) abre começando naquela notícia.
9. **Given** a pessoa puxa a lista para baixo, **When** solta, **Then** o feed é recarregado
   desde o início.
10. **Given** a pessoa tem conta e já leu ou salvou uma notícia, **When** o cartão aparece,
    **Then** mostra o sinal de "lida" e o de "salva"; para o visitante, esses sinais não aparecem.

---

### User Story 2 - Filtrar por categoria (Priority: P1)

A pessoa toca num filtro de categoria ("Phishing", "Golpes bancários"...) e passa a ver só as
notícias daquela categoria. Tocar em "Todas" volta ao feed completo.

**Why this priority**: o público quer achar rápido o tipo de golpe que o preocupa. RF-009 exige os
filtros.

**Independent Test**: tocar numa categoria e conferir que todas as notícias exibidas têm aquela
categoria; rolar até o fim e ver mais notícias da mesma categoria; voltar para "Todas".

**Acceptance Scenarios**:

1. **Given** a tela carregou, **When** a pessoa olha os filtros, **Then** vê "Todas" (selecionado)
   seguido das categorias ativas vindas do serviço, numa faixa que rola para o lado.
2. **Given** a pessoa toca numa categoria, **When** a lista atualiza, **Then** mostra só notícias
   daquela categoria, da mais recente para a mais antiga, e o filtro fica selecionado.
3. **Given** um filtro de categoria está ativo, **When** a pessoa rola até o fim, **Then** a lista
   continua paginando dentro da mesma categoria, sem repetir.
4. **Given** um filtro de categoria está ativo, **When** a lista aparece, **Then** o carrossel,
   os destaques e as recomendações ficam ocultos; só aparece a lista filtrada.
5. **Given** a categoria não tem notícias, **When** a lista volta vazia, **Then** aparece o estado
   vazio "Nenhuma notícia nesta categoria ainda." (CB-006).
6. **Given** a pessoa toca em "Todas", **When** a lista atualiza, **Then** o feed completo volta,
   com carrossel e seções.
7. **Given** a pessoa troca de filtro rapidamente várias vezes, **When** as respostas chegam,
   **Then** só a resposta do último filtro escolhido aparece.
8. **Given** as categorias não puderam ser carregadas, **When** a tela aparece, **Then** o feed é
   mostrado normalmente, só com "Todas", sem erro.

---

### User Story 3 - Buscar uma notícia (Priority: P2)

A pessoa digita no campo de busca ("Buscar notícia ou tipo de golpe") e vê as notícias que
combinam com o texto. Limpar a busca volta ao feed.

**Why this priority**: útil para quem ouviu falar de um golpe específico (RF-011), mas a maioria
navega pelo feed e pelos filtros.

**Independent Test**: digitar "pix", esperar o resultado e conferir as notícias; digitar algo sem
resultado e ver o estado vazio; tocar no "X" e voltar ao feed.

**Acceptance Scenarios**:

1. **Given** a pessoa digita no campo de busca, **When** para de digitar por um instante (cerca de
   meio segundo), **Then** a busca é feita e a lista mostra "Resultados" no lugar de "Tudo
   recente"; enquanto digita, nenhum pedido é feito a cada letra.
2. **Given** a pessoa continua digitando antes do resultado chegar, **When** a nova busca começa,
   **Then** a anterior é abandonada e só o resultado do texto final aparece (RNF-005).
3. **Given** a busca não encontrou nada, **When** a lista volta vazia, **Then** aparece o estado
   vazio "Nenhuma notícia encontrada para "{texto}". Tente outras palavras." (CB-006).
4. **Given** há um filtro de categoria ativo, **When** a pessoa busca, **Then** a busca vale
   dentro daquela categoria.
5. **Given** há texto no campo, **When** a pessoa toca no "X" (rótulo "Limpar busca"), **Then** o
   campo esvazia e o feed (ou a categoria ativa) volta.
6. **Given** o texto tem menos de 2 caracteres (ou só espaços), **When** a pessoa para de digitar,
   **Then** nenhuma busca é feita e a lista sem busca continua.
7. **Given** os resultados têm várias partes, **When** a pessoa rola até o fim, **Then** a próxima
   parte dos resultados é carregada, sem repetir.

---

### User Story 4 - Ler o feed sem internet (Priority: P2)

Sem internet, a pessoa ainda vê o último feed carregado, com um aviso de que está sem conexão.
Se nunca carregou nada, vê um erro com "Tentar novamente".

**Why this priority**: RNF-002 e CB-001. O público usa o celular em lugares com sinal ruim, e o
feed é o conteúdo principal.

**Independent Test**: abrir o feed com internet; fechar o app; ligar o modo avião; abrir de novo e
ver as notícias com a faixa "Você está sem internet. Mostrando o conteúdo salvo."; desligar o modo
avião e puxar para atualizar.

**Acceptance Scenarios**:

1. **Given** o feed já foi carregado alguma vez no aparelho, **When** a pessoa abre o Início sem
   internet, **Then** vê o último feed guardado (carrossel, seções e a primeira parte de "Tudo
   recente") com a faixa de sem internet no topo (CB-001).
2. **Given** o feed nunca foi carregado no aparelho, **When** a pessoa abre o Início sem
   internet, **Then** vê o estado de erro "Sem conexão com a internet. Verifique sua rede." com
   "Tentar novamente" (CB-001, CB-002).
3. **Given** a pessoa está vendo o feed guardado, **When** a internet volta e ela puxa para
   atualizar (ou toca em "Tentar novamente"), **Then** o feed novo substitui o guardado e a faixa
   some.
4. **Given** a pessoa está vendo o feed guardado, **When** chega ao fim da primeira parte,
   **Then** nada mais é pedido e aparece o aviso de que é preciso internet para ver mais.
5. **Given** a pessoa está sem internet, **When** escolhe uma categoria ou busca, **Then** vê o
   estado de erro de conexão com "Tentar novamente", e pode voltar a "Todas" para o feed guardado.
6. **Given** o feed carregou com sucesso, **When** a carga termina, **Then** ele é guardado no
   aparelho, substituindo o anterior.
7. **Given** a internet cai no meio da rolagem, **When** a próxima parte falha, **Then** a lista
   já mostrada continua e, no fim dela, aparece "Não foi possível carregar mais." com "Tentar
   novamente".

---

### Edge Cases

- **Serviço demorando a acordar** (servidor gratuito, cerca de 40 s na primeira resposta): o
  indicador de carregando continua e, depois de alguns segundos, aparece "Conectando ao
  servidor…", como no login (feature 003).
- **Erro do serviço (5xx) sem cache**: estado de erro com mensagem genérica e "Tentar novamente"
  (CB-004).
- **Erro do serviço com cache**: mostra o feed guardado com a faixa de aviso, como no modo sem
  internet.
- **Sessão expirada durante a carga** (conta conectada): a sessão é encerrada e o aviso da
  feature 005 aparece; o feed é recarregado como visitante na próxima atualização, sem prender a
  pessoa num erro.
- **Notícia sem imagem**: o cartão mostra um quadro neutro com o ícone de jornal no lugar da
  imagem; o cartão do carrossel usa a cor `secondary` de fundo.
- **Imagem que não carrega**: mesmo quadro neutro, sem erro.
- **Título muito longo**: cortado em duas linhas (três no carrossel), com reticências.
- **Muitas categorias numa notícia**: o cartão mostra até duas e "+N" para as demais.
- **Mesma notícia em "Destaques" e em "Tudo recente"**: pode aparecer nas duas seções (são listas
  diferentes do serviço); dentro de "Tudo recente", nunca repete.
- **Carrossel sem Reels** (ou falha só nele): a seção "Novidades" fica oculta; o restante do feed
  aparece normalmente.
- **Toque duplo num cartão**: abre uma única vez.
- **Fonte do sistema grande**: cartões crescem em altura; nada é cortado além das linhas de
  título previstas.
- **Voltar à aba Início depois de abrir um detalhe ou trocar de aba**: a lista continua na mesma
  posição, com o mesmo filtro e busca.

## Requirements *(mandatory)*

### Functional Requirements

**Feed (RF-009, RF-010, RF-012, RN-002)**

- **FR-001**: A aba Início MUST mostrar, de cima para baixo: barra superior "Notícias seguras" com
  saudação e contagem de notícias novas (FR-011), busca, filtros de categoria, carrossel
  "Novidades", "Destaques" (se houver), "Recomendadas para você" (só com conta e se houver) e
  "Tudo recente".
- **FR-002**: "Tudo recente" MUST listar as notícias da mais recente para a mais antiga e carregar
  a próxima parte ao chegar perto do fim, até o serviço indicar que acabou (RF-010).
- **FR-003**: A lista MUST NOT exibir a mesma notícia duas vezes e MUST parar de pedir partes
  quando o serviço indicar o fim (CB-007), mostrando "Você viu todas as notícias".
- **FR-004**: O carrossel "Novidades" MUST mostrar os primeiros Reels do serviço em cartões
  verticais (imagem, selo "Reels", título e fonte); tocar num cartão MUST abrir a aba de Reels
  começando naquela notícia.
- **FR-005**: Tocar num cartão de notícia MUST abrir o detalhe dela; um toque duplo MUST abrir uma
  vez só.
- **FR-006**: Todo cartão MUST mostrar as categorias da notícia vindas do serviço (até duas, mais
  "+N"), e uma notícia sem categoria MUST aparecer sem rótulo (RF-012, RN-002).
- **FR-007**: A data mostrada MUST ser a da publicação original, em linguagem simples ("Hoje",
  "Ontem", "Há N dias" até 6 dias; depois, a data por extenso curta, ex.: "12 de set.").
- **FR-008**: Para quem tem conta, o cartão MUST mostrar os sinais de "lida" e de "salva" vindos do
  serviço; para o visitante, MUST NOT mostrar. Curtir e salvar pelo cartão ficam fora desta
  feature.
- **FR-009**: Puxar a lista para baixo MUST recarregar o feed (ou a categoria/busca ativa) desde o
  início.
- **FR-010**: O visitante MUST ver o feed sem nenhuma credencial; quem tem conta MUST ver também
  as recomendações e os sinais de interação.

**Saudação e contagem (RF-009)**

- **FR-011**: A barra superior MUST mostrar "Olá, {nome}!" (com conta) ou "Bem-vindo!"
  (visitante), seguido da contagem "{N} notícias novas para você" quando N > 0, onde N é o número de notícias carregadas (carrossel, seções e "Tudo recente", sem
  repetir) cuja publicação original foi nas últimas 24 horas.

**Filtros de categoria (RF-009, CB-006)**

- **FR-012**: Os filtros MUST mostrar "Todas" seguido das categorias ativas do serviço; falha ao
  carregar as categorias MUST deixar só "Todas", sem erro.
- **FR-013**: Com uma categoria escolhida, a lista MUST mostrar só notícias dela, paginando dentro
  da categoria, e MUST ocultar carrossel, destaques e recomendações.
- **FR-014**: Trocar de filtro (ou de busca) MUST descartar respostas antigas: só o resultado da
  última escolha aparece.
- **FR-015**: Categoria sem notícias MUST mostrar o estado vazio com mensagem própria (CB-006).

**Busca (RF-011, RNF-005, CB-006)**

- **FR-016**: A busca MUST esperar a pessoa parar de digitar (cerca de meio segundo) antes de
  pedir ao serviço, e MUST abandonar a busca anterior quando uma nova começar.
- **FR-017**: Textos com menos de 2 caracteres úteis MUST NOT disparar busca.
- **FR-018**: A busca MUST valer dentro da categoria ativa, e o resultado MUST paginar sem repetir.
- **FR-019**: Busca sem resultado MUST mostrar o estado vazio com o texto buscado e uma sugestão
  (CB-006); o "X" MUST limpar a busca e voltar à lista anterior.

**Sem internet (RNF-002, CB-001, CB-002)**

- **FR-020**: A primeira parte do feed sem filtro (carrossel, seções e "Tudo recente"), quando
  carregada com sucesso, MUST ficar guardada no aparelho. Sem internet (ou com o serviço fora), o
  Início MUST abrir dessa cópia com a faixa de sem internet; sem cópia, MUST mostrar o erro de
  conexão com "Tentar novamente".
- **FR-021**: Na cópia guardada, chegar ao fim MUST NOT pedir mais partes; MUST avisar que é
  preciso internet para ver mais. Filtro ou busca sem internet MUST mostrar o erro de conexão.
- **FR-022**: Falha ao carregar a próxima parte MUST manter a lista já mostrada e oferecer
  "Tentar novamente" no fim dela.

**Estados e acessibilidade (RNF-003, RNF-004)**

- **FR-023**: Carregando, erro, vazio e sem internet MUST usar os estados comuns do design system
  (feature 005), com as mensagens desta spec.
- **FR-024**: Cartões, filtros, campo de busca e botão de limpar MUST ter área de toque de pelo
  menos 48×48 dp e rótulo para leitor de tela (o cartão lê título, fonte, data e categorias);
  textos de leitura MUST ter pelo menos 16 sp, exceto metadados (fonte, data, categorias), que
  seguem o design system com piso de 12 sp.
- **FR-025**: Ao voltar à aba Início (de outra aba ou de um detalhe), a lista MUST estar na mesma
  posição, com o mesmo filtro e busca.

### Key Entities

- **Notícia (item do feed)**: identificador, título, fonte, endereço da fonte, imagem opcional,
  data da publicação original, data de entrada no app, se é destaque, categorias (nome e
  identificador curto) e, só com conta, se foi lida e se foi salva.
- **Reel (cartão do carrossel)**: notícia com o texto completo e o número de curtidas; aqui só
  usa imagem, título e fonte.
- **Categoria**: identificador, nome e identificador curto usado no filtro; só as ativas aparecem.
- **Feed**: destaques, recomendações (vazias para o visitante), a primeira parte de "Tudo recente"
  e a marca de onde continuar.
- **Feed guardado**: cópia da última primeira carga do feed sem filtro, com o momento em que foi
  guardada.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com o serviço acordado e internet comum, a pessoa vê as primeiras notícias em até 3
  segundos depois de abrir a aba Início.
- **SC-002**: Rolando até o fim de um feed com várias partes, nenhuma notícia aparece duas vezes
  em "Tudo recente" e nenhum pedido é feito depois do fim (100% dos casos testados).
- **SC-003**: Digitando uma palavra de 6 letras normalmente, o app faz no máximo um pedido de
  busca ao serviço.
- **SC-004**: Sem internet, com feed já carregado antes, a pessoa vê notícias em 100% das
  aberturas, com o aviso de sem internet; sem feed guardado, vê o erro com "Tentar novamente".
- **SC-005**: Trocando de filtro várias vezes seguidas, a lista final corresponde sempre ao último
  filtro escolhido.
- **SC-006**: Todos os cartões, filtros e botões medem pelo menos 48×48 dp e têm rótulo para leitor
  de tela.

## Assumptions

- **Contagem do subtítulo**: notícias publicadas nas últimas 24 horas, entre as carregadas (FR-011,
  decidido na Q1). Com o feed guardado (sem internet), a conta usa o momento atual. O formato combina saudação e
  contagem, para atender ao RF-009 (saudação) e ao wireframe (contagem): "Olá, Maria! 3 notícias
  novas para você".
- **Seções além do wireframe**: o RF-009 pede destaques e recomendações, que o wireframe não
  desenha. "Destaques" usa o cartão completo (imagem grande) do design system §7.8, em lista
  vertical; "Recomendadas para você" usa cartões compactos. Ambas só aparecem na primeira carga do
  feed sem filtro, como o serviço devolve.
- **Sem resumo no cartão**: o serviço não envia resumo; o cartão mostra título, fonte, data e
  categorias (diferente do wireframe, que tem um resumo).
- **Selo "Novo"**: o wireframe marca notícias não lidas com "Novo". Como só quem tem conta tem a
  informação de leitura, o selo aparece só para quem tem conta, em notícias não lidas do cartão
  completo (destaques).
- **Curtir e salvar no cartão**: os botões do wireframe ficam para A4/A5 (que trazem as ações com o
  convite para visitante). Nesta feature, o cartão só mostra os sinais de lida/salva.
- **Tamanho das partes**: 20 notícias por parte; carrossel com até 10 Reels.
- **Categorias**: carregadas a cada abertura do Início; não ficam guardadas para uso offline (sem
  internet, só "Todas").
- **Busca mínima de 2 caracteres e espera de ~0,5 s**: valores comuns que evitam pedidos
  desnecessários; podem ser ajustados no plano.
- **Contrato da API**: as linhas de notícias estão como 🧪 no contrato; os formatos serão
  conferidos no servidor real antes da camada de dados (plano), e o contrato atualizado.
- **Dependências**: features 002 (cliente de API, cancelamento), 005 (aba Início, barra superior,
  rotas `/news/:id` e `/reels?start=`, estados comuns) e o armazenamento local da feature 001.
