# Feature Specification: Detalhe da notícia e notícias salvas

**Feature Branch**: `010-detalhe-noticia`

**Created**: 2026-10-09

**Status**: Draft

**Input**: User description: "A5 Detalhe da notícia (RF-014 a RF-019, CB-008) — ver .specify/memory/tasks.md, seção A5. Endpoints: GET /app/news/{id}, POST /app/news/{id}/read, POST /app/news/{id}/save, GET /users/me/news/saved. Ouvir a notícia com velocidade (ReadAloudController) e leitura automática se autoReadAloud; compartilhar (ShareService); abrir fonte no navegador externo; salvar (visitante → requireAccount); bloco de atividade relacionada só com suggestedModule → /activities/$moduleId. Cadastrado registra leitura sem bloquear a tela. Lista de salvas com cache offline. DECISÃO (2026-10-09, usuário): a leitura em voz alta da notícia segue o idioma do app (RF-042), mesmo com o app em inglês e a notícia em português — fecha o ponto em aberto do RF-042. Usar o nome de branch 010-detalhe-noticia, que já existe e está em uso (junta 008 e 009); não criar outra branch."

**Rastreabilidade**: tarefa A5 do [tasks do produto](../../.specify/memory/tasks.md) · RF-014 a
RF-018, RF-019 (salvar), RF-040 (leitura automática), RF-042 (idioma da voz), RN-003, RNF-002
(salvas offline), RNF-003, CB-002, CB-004, CB-005, CB-008, CB-011 da
[especificação do produto](../../.specify/memory/specification.md) · seção "Notícias e Reels" do
[contrato da API](../../.specify/memory/api-contract.md) · rota `/news/:id` e convite para
visitante da [feature 005](../005-shell-navegacao-base/spec.md) · cartões e data do
[feed](../006-feed-inicio/spec.md) · voz, compartilhar e abrir a fonte da
[feature 007](../007-servicos-plataforma-voz/spec.md) · salvar dos
[Reels](../008-reels-curtir-salvar/spec.md) · leitura automática e velocidade guardada da
[feature 009](../009-acessibilidade-global/spec.md).

## Clarifications

### Session 2026-10-09

- Q: Com o app em inglês, em que idioma a voz lê a notícia (que vem em português)? → A: No
  idioma do app, como o RF-042 já diz. Fecha o ponto em aberto do RF-042.
- Q: O módulo sugerido vem para o visitante? → A: Sim. Conferido no servidor (o openapi dizia
  "se autenticado"); o visitante também vê o bloco de atividade relacionada.
- Q: Como a A5 entrega a lista de notícias salvas? → A: Tela "Notícias salvas" numa rota nova
  `/news/saved`, do módulo news, com cópia offline. O atalho no Perfil fica para a B7 (trilha B);
  até lá, só a entrada de desenvolvimento abre a tela.

## Contexto

O feed, o carrossel e os Reels já abrem o detalhe de uma notícia (`/news/:id`), mas a tela ainda
é provisória ("Em breve"). Esta feature coloca ali a notícia completa e as ações em volta dela:
ouvir em voz alta, compartilhar, abrir a fonte original, salvar e seguir para uma atividade
sobre o tema. Também cria a lista de notícias salvas, para a pessoa reencontrar o que guardou,
inclusive sem internet.

Ficam fora: curtir no detalhe (o RF-019 pede curtir só nos Reels; o detalhe mostra o número de
curtidas), o atalho do Perfil para as salvas (B7), a tela da atividade (B2; o detalhe só abre a
rota) e os alertas (A6).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ler a notícia completa (Priority: P1)

A pessoa toca numa notícia do feed, do carrossel ou dos Reels e vê a notícia inteira: imagem,
categorias, título, fonte, data da publicação original, número de curtidas e o texto completo.
Quem tem conta tem a leitura registrada, sem esperar por isso.

**Why this priority**: é o destino de todas as listas de notícias do app (UC-03). Sem ele, as
outras ações não têm onde ficar.

**Independent Test**: com o servidor de desenvolvimento, abrir uma notícia pelo feed como
visitante e conferir todos os campos; repetir com conta e conferir no servidor que a leitura
foi registrada.

**Acceptance Scenarios**:

1. **Given** a pessoa tocou numa notícia, **When** o detalhe está chegando, **Then** vê o
   indicador de carregando, com a barra superior e o botão de voltar.
2. **Given** o detalhe chegou, **When** a tela aparece, **Then** mostra a imagem (quando houver),
   as categorias, o título, a fonte, a data da publicação original no mesmo formato do feed, o
   número de curtidas e o texto completo, com rolagem.
3. **Given** a pessoa tem conta, **When** o detalhe aparece, **Then** a leitura é registrada no
   serviço uma vez por abertura, sem indicador e sem atrasar a tela; se o registro falhar,
   nada aparece para a pessoa.
4. **Given** a pessoa é visitante, **When** o detalhe aparece, **Then** a leitura não é
   registrada e nenhum pedido de registro é feito.
5. **Given** o detalhe falhou (sem internet, erro do serviço), **When** a falha chega, **Then**
   aparece o estado de erro com a mensagem e "Tentar novamente" (CB-002, CB-004).
6. **Given** a notícia não existe mais no serviço, **When** o detalhe responde "não encontrada",
   **Then** aparece "Notícia não encontrada" com o botão de voltar, sem "Tentar novamente".
7. **Given** a pessoa toca em voltar, **When** volta, **Then** a tela anterior continua onde
   estava (feed na mesma rolagem, mesmo Reel).

---

### User Story 2 - Ouvir a notícia (Priority: P1)

A pessoa toca em "Ouvir" e o aparelho lê o título e o texto da notícia em voz alta, na
velocidade escolhida (lenta, normal ou rápida). Pode parar quando quiser. Quem ligou a leitura
automática na acessibilidade ouve a notícia assim que ela abre.

**Why this priority**: é o recurso de acessibilidade central para o público idoso (RF-015,
RF-040) e o motivo de a F0.5 e a F0.6 existirem.

**Independent Test**: num aparelho com voz em português, abrir uma notícia, tocar em "Ouvir",
trocar a velocidade e parar; ligar a leitura automática e reabrir; desligar a voz do aparelho e
conferir que o botão some.

**Acceptance Scenarios**:

1. **Given** o aparelho tem voz no idioma do app, **When** o detalhe aparece, **Then** mostra o
   botão "Ouvir" e o seletor de velocidade (lenta, normal, rápida), começando na velocidade
   guardada na acessibilidade.
2. **Given** a pessoa toca em "Ouvir", **When** a leitura começa, **Then** o aparelho lê o título
   e depois o texto, no idioma do app e na velocidade selecionada, e o botão passa a "Parar".
3. **Given** a leitura está em andamento, **When** a pessoa toca em "Parar", **Then** a voz para
   e o botão volta a "Ouvir".
4. **Given** a pessoa troca a velocidade, **When** toca em "Ouvir" de novo, **Then** a leitura
   usa a nova velocidade; a escolha vale só para aquela tela e não muda a preferência guardada.
5. **Given** a leitura automática está ligada e há voz, **When** o detalhe termina de carregar,
   **Then** a leitura começa sozinha, como se a pessoa tivesse tocado em "Ouvir" (RF-040).
6. **Given** a leitura está em andamento, **When** a pessoa sai do detalhe, **Then** a voz para.
7. **Given** o aparelho não tem voz no idioma do app (ou nenhuma voz), **When** o detalhe
   aparece, **Then** o botão "Ouvir" e o seletor não aparecem, sem erro, e a leitura automática
   não acontece (CB-008).
8. **Given** o app está em inglês e a notícia em português, **When** a pessoa toca em "Ouvir",
   **Then** a voz em inglês lê o texto (decisão de 2026-10-09; ver Clarifications).

---

### User Story 3 - Salvar a notícia e ver as salvas (Priority: P2)

A pessoa com conta toca no marcador do detalhe para salvar a notícia, e tocar de novo remove.
Na tela "Notícias salvas", ela vê o que guardou, do mais recente para o mais antigo, e abre
qualquer uma. Sem internet, a lista guardada continua aparecendo. O visitante que toca no
marcador vê o convite para entrar ou criar conta.

**Why this priority**: RF-019 pede salvar e o RNF-002 pede as salvas offline. A tela ainda não
tem entrada para quem usa o app (o atalho é da B7), por isso P2.

**Independent Test**: com conta, salvar uma notícia no detalhe, abrir "Notícias salvas" pela
entrada de desenvolvimento e ver a notícia no topo; desligar a internet, reabrir a lista e ver
a cópia guardada; remover dos salvos e ver sumir; como visitante, ver o convite no marcador.

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta, **When** o detalhe aparece, **Then** o marcador mostra se a
   notícia já está salva, conforme o serviço; para o visitante, aparece sempre vazio.
2. **Given** a pessoa tem conta, **When** toca no marcador, **Then** ele alterna na hora, aparece
   "Notícia salva" ou "Removida dos salvos" e, com a resposta do serviço, o marcador mostra
   exatamente o estado devolvido.
3. **Given** a pessoa é visitante, **When** toca no marcador, **Then** aparece o convite (CB-011)
   e nenhum pedido é feito ao serviço.
4. **Given** o pedido de salvar falhou, **When** a falha chega, **Then** o marcador volta ao
   estado anterior e aparece um aviso com a mensagem do erro; toques durante um pedido em
   andamento são ignorados.
5. **Given** a pessoa tem conta, **When** abre "Notícias salvas", **Then** vê as notícias salvas
   como cartões do feed (imagem, categorias, título, fonte, data), da salva mais recente para a
   mais antiga, carregando mais ao chegar perto do fim, sem repetir.
6. **Given** a pessoa toca num cartão da lista, **When** o detalhe abre e ela remove dos salvos,
   **Then** ao voltar a notícia não aparece mais na lista.
7. **Given** a lista já foi carregada antes neste aparelho e a internet caiu, **When** a pessoa
   abre "Notícias salvas", **Then** vê a última cópia guardada com o aviso de offline (RNF-002).
8. **Given** a pessoa não tem nada salvo, **When** abre a lista, **Then** vê "Você ainda não
   salvou nenhuma notícia." com uma dica de usar o marcador.
9. **Given** a pessoa é visitante, **When** a tela "Notícias salvas" é aberta, **Then** aparece o
   convite para entrar ou criar conta no lugar da lista, sem pedido ao serviço.

---

### User Story 4 - Compartilhar e abrir a fonte (Priority: P2)

A pessoa toca em "Compartilhar" e escolhe pelo menu do aparelho para quem enviar a notícia
(título e endereço da fonte). Toca em "Abrir fonte" e a página original abre no navegador.

**Why this priority**: RF-016 e RF-017. Ajuda a conferir de onde veio a notícia e a avisar
família e amigos sobre um golpe, mas não depende de conta nem bloqueia a leitura.

**Independent Test**: abrir uma notícia, tocar em "Compartilhar" e ver o menu do aparelho com o
título e o endereço; tocar em "Abrir fonte" e ver o navegador abrir no endereço da notícia.

**Acceptance Scenarios**:

1. **Given** o detalhe está na tela, **When** a pessoa toca em "Compartilhar", **Then** abre o
   menu de compartilhar do aparelho com o título da notícia, a fonte e o endereço da fonte.
2. **Given** a pessoa fecha o menu sem escolher, **When** volta, **Then** continua no detalhe,
   sem aviso.
3. **Given** a notícia tem endereço de fonte válido, **When** a pessoa toca em "Abrir fonte",
   **Then** o navegador externo abre naquele endereço.
4. **Given** o aparelho não consegue abrir o endereço, **When** a pessoa toca, **Then** aparece
   "Não foi possível abrir a fonte" e o app continua no detalhe.
5. **Given** a notícia não tem endereço de fonte, **When** o detalhe aparece, **Then** "Abrir
   fonte" não aparece e o compartilhamento leva só o título e a fonte.

---

### User Story 5 - Seguir para uma atividade relacionada (Priority: P3)

Quando o serviço sugere um módulo de atividades sobre o tema da notícia, o detalhe mostra um
bloco "Pratique o que aprendeu" com o nome do módulo, a descrição e o número de perguntas.
Tocar no bloco abre esse módulo na trilha de atividades.

**Why this priority**: RF-018 liga a notícia ao aprendizado, mas depende do serviço sugerir um
módulo e da tela de atividades (B2) para ter valor completo.

**Independent Test**: como visitante, abrir uma notícia com módulo sugerido (ex.: categoria
"Golpes no WhatsApp"), ver o bloco e tocar para abrir `/activities/<id do módulo>`; abrir uma
notícia sem sugestão (ex.: só "Segurança Bancária") e ver que o bloco não aparece.

**Acceptance Scenarios**:

1. **Given** o serviço enviou um módulo sugerido, **When** o detalhe aparece, **Then** depois do
   texto aparece o bloco com o título do módulo, a descrição e o número de perguntas.
2. **Given** o bloco está na tela, **When** a pessoa toca nele, **Then** abre a tela do módulo
   (`/activities/<id>`) por cima das abas; ao voltar, o detalhe continua igual.
3. **Given** o serviço não enviou módulo sugerido, **When** o detalhe aparece, **Then** o bloco
   não aparece e não sobra espaço vazio.

---

### Edge Cases

- **Serviço demorando a acordar** (~40 s na primeira resposta): o indicador continua e, depois
  de alguns segundos, aparece "Conectando ao servidor…", como no feed.
- **Detalhe sem internet de notícia salva já aberta neste aparelho**: aparece a cópia guardada
  do texto completo, com o aviso de offline, e as ações que precisam de rede (salvar) mostram o
  erro de conexão se tocadas.
- **Sem internet e sem cópia guardada**: estado de erro com "Tentar novamente".
- **Resposta malformada**: vira erro genérico, sem travar a tela (CB-005).
- **Notícia sem imagem ou imagem que não carrega**: o espaço da imagem não aparece (ou mostra o
  fundo neutro do feed); o resto da tela fica igual.
- **Texto vazio**: aparece "O texto completo desta notícia não está disponível." com "Abrir
  fonte"; "Ouvir" lê só o título.
- **Texto muito longo**: rola normalmente; a leitura em voz alta lê tudo, e "Parar" funciona a
  qualquer momento.
- **Leitura automática e pessoa que toca em "Parar" logo em seguida**: a voz para e não recomeça
  sozinha naquela abertura.
- **Pessoa abre outra notícia enquanto a voz lê** (ex.: pelo bloco de atividade e de volta):
  sair da tela para a voz; voltar não recomeça sozinho.
- **Sessão expirada ao salvar ou ao registrar leitura**: o tratamento da feature 002/005 encerra
  a sessão; no salvar, o marcador volta ao estado anterior.
- **Notícia removida do serviço ao salvar** (404): o marcador volta e aparece "Notícia não
  encontrada".
- **Remover dos salvos estando sem internet**: falha com aviso; o marcador volta; a lista
  guardada não muda.
- **Mesma notícia em duas páginas da lista de salvas**: aparece uma vez só (CB-007).
- **Visitante que entra pelo convite e volta ao detalhe**: o detalhe é recarregado para trazer o
  estado de salvo daquela conta.
- **Fonte do sistema grande (até 2×)**: título, botões e bloco de atividade não se sobrepõem; os
  botões de ação quebram para outra linha em vez de cortar o texto.
- **Leitor de tela (TalkBack)**: a ordem de leitura é título, fonte, data, ações, texto e bloco
  de atividade; cada botão anuncia o estado ("Salvar", "Salvo", "Ouvir", "Parar",
  "Velocidade: normal").
- **Toque duplo em "Abrir fonte", "Compartilhar" ou no bloco de atividade**: a ação acontece uma
  vez só.

## Requirements *(mandatory)*

### Functional Requirements

**Detalhe (RF-014)**

- **FR-001**: O detalhe MUST mostrar imagem (quando houver), categorias (RN-002), título, fonte,
  data da publicação original no formato do feed, número de curtidas e texto completo, com
  rolagem, por cima das abas e com botão de voltar.
- **FR-002**: O detalhe MUST mostrar os estados carregando (com "Conectando ao servidor…" após
  alguns segundos), erro com "Tentar novamente" e "Notícia não encontrada" sem "Tentar
  novamente".
- **FR-003**: O visitante MUST ver o detalhe sem credencial, inclusive o módulo sugerido; quem
  tem conta MUST receber também o estado de salvo.
- **FR-004**: Com conta, abrir o detalhe MUST registrar a leitura no serviço uma vez por
  abertura, sem bloquear nem atrasar a tela; a falha do registro MUST NOT aparecer para a
  pessoa. O visitante MUST NOT registrar leitura.

**Ouvir (RF-015, RF-040, RF-042, CB-008)**

- **FR-005**: Com voz disponível no idioma do app, o detalhe MUST mostrar "Ouvir" e o seletor de
  velocidade (lenta, normal, rápida), começando na velocidade guardada na acessibilidade.
- **FR-006**: "Ouvir" MUST ler o título e depois o texto, no idioma do app (mesmo que a notícia
  esteja em outro idioma) e na velocidade selecionada; durante a leitura, o botão MUST virar
  "Parar", e tocar nele MUST parar a voz.
- **FR-007**: Trocar a velocidade no detalhe MUST valer para as próximas leituras daquela tela e
  MUST NOT mudar a preferência guardada.
- **FR-008**: Com a leitura automática ligada e voz disponível, a leitura MUST começar sozinha
  assim que o detalhe terminar de carregar, uma vez por abertura.
- **FR-009**: Sair do detalhe MUST parar a leitura em andamento.
- **FR-010**: Sem voz no idioma do app, "Ouvir", o seletor e a leitura automática MUST NOT
  aparecer nem acontecer, sem mensagem de erro.

**Salvar e notícias salvas (RF-019, RNF-002, RN-003)**

- **FR-011**: Com conta, o marcador do detalhe MUST refletir o estado de salvo do serviço;
  tocar MUST alternar na hora, mostrar "Notícia salva" ou "Removida dos salvos" e, com a
  resposta, mostrar exatamente o estado devolvido. Falha MUST voltar ao estado anterior com
  aviso; toques durante um pedido em andamento MUST ser ignorados.
- **FR-012**: Para visitante, o marcador MUST aparecer vazio e tocar MUST abrir o convite para
  entrar ou criar conta, sem chamar o serviço (RN-003, CB-011).
- **FR-013**: A tela "Notícias salvas" (rota `/news/saved`) MUST listar as notícias salvas da
  conta como cartões do feed, da salva mais recente para a mais antiga, carregando a página
  seguinte perto do fim, sem repetir e sem pedir depois da última (CB-007).
- **FR-014**: Tocar num cartão da lista MUST abrir o detalhe; ao voltar, a lista MUST refletir
  o que mudou no salvar (notícia removida some).
- **FR-015**: A primeira página da lista MUST ser guardada no aparelho a cada carga com
  sucesso; sem internet, a tela MUST mostrar essa cópia com o aviso de offline. Sem cópia,
  MUST mostrar o erro com "Tentar novamente".
- **FR-016**: O texto completo de uma notícia salva aberta neste aparelho MUST ser guardado, e,
  sem internet, o detalhe dessa notícia MUST abrir a cópia com o aviso de offline.
- **FR-017**: A lista vazia MUST mostrar "Você ainda não salvou nenhuma notícia." com a dica de
  usar o marcador; para visitante, a tela MUST mostrar o convite no lugar da lista, sem chamar
  o serviço.
- **FR-018**: Sair da conta MUST apagar a cópia guardada da lista e dos textos salvos.

**Compartilhar e abrir a fonte (RF-016, RF-017)**

- **FR-019**: "Compartilhar" MUST abrir o menu do aparelho com título, fonte e endereço da fonte
  (sem endereço, só título e fonte); cancelar MUST NOT mostrar aviso.
- **FR-020**: "Abrir fonte" MUST abrir o endereço no navegador externo; sem endereço, o botão
  MUST NOT aparecer; se o aparelho não conseguir abrir, MUST mostrar "Não foi possível abrir a
  fonte".

**Atividade relacionada (RF-018)**

- **FR-021**: Com módulo sugerido, o detalhe MUST mostrar, depois do texto, um bloco com título,
  descrição e número de perguntas do módulo, para visitante e para quem tem conta; tocar MUST
  abrir `/activities/<id do módulo>`. Sem sugestão, o bloco MUST NOT aparecer.

**Acessibilidade e textos (RNF-003, RNF-004)**

- **FR-022**: Todos os botões MUST ter área de toque de pelo menos 48×48 dp, rótulo para leitor
  de tela com o estado, e seguir o tema de alto contraste e a letra maior da feature 009.
- **FR-023**: Todos os textos fixos MUST existir em português e inglês; o conteúdo das notícias
  vem do serviço e não é traduzido.

### Key Entities

- **Detalhe da notícia**: o mesmo que a notícia do feed (identificador, título, fonte, endereço
  da fonte, imagem opcional, data da publicação original, categorias) mais o texto completo, o
  número de curtidas e de leituras, e, só com conta, se está salva e o módulo sugerido.
- **Módulo sugerido**: identificador, título, descrição, ícone opcional e número de perguntas.
- **Página de notícias salvas**: lista de notícias (formato do feed), página atual e se há
  próxima.
- **Cópia offline**: a primeira página da lista de salvas e o texto completo das notícias salvas
  abertas, guardados no aparelho da conta atual. A lista do serviço não traz o texto completo,
  por isso ele vem do detalhe.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com o serviço acordado e internet comum, a pessoa vê a notícia completa em até 3
  segundos depois de tocar no cartão.
- **SC-002**: O registro de leitura nunca atrasa a tela: em 100% dos testes, o detalhe aparece
  mesmo quando o registro falha ou demora.
- **SC-003**: Com a leitura automática ligada e voz disponível, a voz começa em até 1 segundo
  depois de a notícia aparecer.
- **SC-004**: Em 100% das saídas do detalhe com a voz lendo, a voz para.
- **SC-005**: Sem voz no aparelho, nenhum botão de ouvir aparece e nenhuma mensagem de erro é
  mostrada (100% dos testes).
- **SC-006**: Em 100% das tentativas de salvar como visitante, o convite aparece e nenhum pedido
  é feito ao serviço.
- **SC-007**: Sem internet, uma pessoa que já abriu a lista de salvas neste aparelho consegue
  vê-la e ler uma notícia salva que abriu antes.
- **SC-008**: Todos os botões medem pelo menos 48×48 dp e têm rótulo para leitor de tela.

## Assumptions

- **Idioma da voz**: segue o idioma do app (RF-042). Com o app em inglês, a voz em inglês lê
  notícias escritas em português, com pronúncia ruim; a pessoa pode trocar o idioma do app
  para português (B8). Decisão do usuário em 2026-10-09.
- **Curtir fica fora do detalhe**: o RF-019 pede curtir nos Reels; o detalhe mostra só o número
  de curtidas, mesmo o serviço enviando se a pessoa curtiu.
- **Entrada da lista de salvas**: o atalho do Perfil é da B7 (trilha B); a rota `/news/saved` é
  nova e precisa ser combinada com a outra pessoa e registrada no plano do produto (§2). Até a
  B7, a tela só abre pela entrada de desenvolvimento.
- **Ordem da lista de salvas**: a que o serviço devolver (esperada da salva mais recente para a
  mais antiga); o app não reordena. 20 notícias por página.
- **Cópia offline**: a lista guarda só a primeira página; o texto completo das 30 últimas
  notícias abertas fica guardado (cobre toda notícia salva aberta neste aparelho; ver
  [research.md](research.md) R2). A cópia é por conta e é apagada ao sair.
- **Módulo sugerido para visitante**: o openapi diz que vem "se autenticado", mas o servidor
  envia também sem token (conferido em 2026-10-09, [research.md](research.md) R0). O visitante
  vê o bloco e pode fazer a atividade como visitante (RN-006).
- **Registro de leitura**: um pedido por abertura do detalhe com conta; o serviço é idempotente,
  então reabrir a mesma notícia não conta duas vezes.
- **Estado entre telas**: salvar no detalhe não precisa atualizar o feed nem os Reels já
  carregados; a lista de salvas recarrega ao voltar do detalhe.
- **Compartilhamento**: texto simples (título, fonte e endereço), sem imagem.
- **Contrato da API**: `GET /app/news/{id}`, `POST /read` e `GET /users/me/news/saved` foram
  conferidos no servidor real em 2026-10-09 ([research.md](research.md) R0) e estão ✅ no
  contrato. O item da lista de salvas não traz o texto completo. Falta conferir a ordem da lista
  com mais de uma notícia (teste no aparelho).
- **Dependências**: features 002 (cliente de API, renovação de sessão), 005 (rota `/news/:id`,
  rota `/activities/:moduleId`, convite para visitante, estados comuns), 006 (cartão de notícia,
  formato de data, categorias, aviso de offline), 007 (voz, compartilhar, abrir endereço), 008
  (salvar, já na branch) e 009 (leitura automática, velocidade guardada, alto contraste e letra
  maior, já na branch). As PRs #12 (008) e #13 (009) precisam entrar antes desta.
