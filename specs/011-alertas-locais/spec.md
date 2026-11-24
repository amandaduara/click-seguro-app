# Feature Specification: Alertas locais de notícias novas

**Feature Branch**: `011-alertas-locais`

**Created**: 2026-10-09

**Status**: Draft

**Input**: User description: "A6 Alertas locais (RF-020 a RF-022) — a API não tem notificações. `AlertEntity` `{newsId, title, source, publishedAt, isRead}` + model, com teste. `AlertsRemoteDataSource` próprio (`GET /app/news?startDate=...&sortBy=publishedAt`), sem importar o módulo `news`, com teste. `AlertsLocalDataSource` (alertas, lidos e última verificação no `LocalCacheService`), com teste. `NotificationsRepositoryImpl` com teste. `CheckNewAlertsUseCase` (sem duplicar por `newsId`; 1ª execução só marca o horário; limite de 50 alertas/30 dias; respeita `receiveNotifications`), `GetAlerts`, `GetUnreadCount`, `MarkAsRead`, `MarkAllAsRead`, e o agrupamento Hoje/Ontem/Anteriores numa extension testável. Com testes. `NotificationsController` com teste. `NotificationBellButton` real (contador; visitante → `requireAccount`) e `NotificationsPage` (grupos, "marcar todas como lidas", tocar → marcar lido e abrir `/news/:id`), com widget test. Usar o nome de branch 011-alertas-locais, que já existe e está em uso; não criar outra branch. O público final é idoso: preferir conteúdo fixo na tela em vez de popups, botões grandes com texto, poucos passos e nenhum gesto escondido."

**Rastreabilidade**: tarefa A6 do [tasks do produto](../../.specify/memory/tasks.md) · RF-020 a
RF-022, RN-003, RNF-002 (alertas guardados funcionam sem internet), RNF-003, RNF-004, RNF-006,
CB-002, CB-004, CB-005, CB-011 da
[especificação do produto](../../.specify/memory/specification.md) (§3.4, UC-07) · seção
"Alertas — A6" do [contrato da API](../../.specify/memory/api-contract.md) · barra superior,
sino, rota `/notifications` e convite para visitante da
[feature 005](../005-shell-navegacao-base/spec.md) · detalhe da notícia (`/news/:id`) da
[feature 010](../010-detalhe-noticia/spec.md) · alto contraste e letra maior da
[feature 009](../009-acessibilidade-global/spec.md).

## Clarifications

### Session 2026-10-09

- Q: Quando e como os alertas são gerados, se a API não tem notificações? → A: Decisão de
  produto de 2026-10-03: o próprio app consulta as notícias publicadas desde a última
  verificação e cria um alerta para cada uma. Não há envio com o app fechado (sem push, ver §1.3
  da especificação do produto).
- Q: Visitante vê alertas? → A: Não. Alertas exigem conta (RN-003): o sino mostra o convite
  para entrar ou criar conta, sem chamar o serviço.
- Q: Ao ligar "Receber alertas" de novo, a pessoa recebe alertas das notícias publicadas enquanto
  estava desligado? → A: Não, só das publicadas depois de ligar. Assim quem pediu para não ser
  avisado não recebe uma enxurrada de uma vez (público idoso: o mais simples).
- Q: Onde fica a chave "Receber alertas"? → A: No perfil, na tarefa B7 (editar dados). Esta
  feature só respeita o valor guardado no serviço; não cria a chave.

## Contexto

O sino da barra superior já existe (feature 005), mas é só um botão que leva a uma tela
provisória ("Em breve"). Esta feature dá vida a ele: o app percebe que saíram notícias novas,
guarda um alerta para cada uma, mostra no sino quantos ainda não foram vistos e, na tela de
Alertas, lista tudo agrupado por data, com um toque para ler a notícia.

Como o público é idoso, a tela é pensada para ser simples: tudo o que importa fica **fixo na
tela** (o resumo "Você tem N alertas novos" e o botão "Marcar todos como lidos" com texto), não
há menu escondido, popup nem gesto de arrastar obrigatório, e "novo" aparece escrito, não só em
cor ou ponto.

Ficam fora: aviso do sistema com o app fechado (push), o interruptor "Receber alertas" (B7), a
linha "Alertas" de Configurações (B8, que só abre esta tela) e qualquer mudança no feed ou no
detalhe da notícia.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Saber pelo sino que há notícias novas (Priority: P1)

A pessoa com conta abre o app (ou volta a ele) e, sem fazer nada, o sino da barra superior passa
a mostrar um número com os alertas ainda não vistos: cada notícia publicada desde a última vez
que o app conferiu vira um alerta, uma única vez.

**Why this priority**: é o coração de RF-020 e RF-021. Sem a geração e o contador, a tela de
alertas não tem o que mostrar.

**Independent Test**: com uma conta, voltar a "última verificação" do aparelho para alguns dias
atrás (entrada de desenvolvimento), abrir o app com as notícias do serviço de desenvolvimento e
conferir o número no sino; abrir de novo e conferir que o número não muda (nenhum alerta
repetido).

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta e é a primeira vez que o app confere as notícias nesta conta
   neste aparelho, **When** o app abre, **Then** guarda só o horário da conferência, não cria
   nenhum alerta (nem notícias antigas) e o sino aparece sem número.
2. **Given** já houve uma conferência e foram publicadas 3 notícias depois dela, **When** o app
   abre, volta do segundo plano ou a tela de alertas é aberta, **Then** o app cria 3 alertas
   novos e o sino mostra "3".
3. **Given** uma notícia já virou alerta, **When** o app confere de novo e o serviço devolve a
   mesma notícia, **Then** não é criado um segundo alerta para ela (nunca dois alertas da mesma
   notícia).
4. **Given** o sino mostra um número, **When** a pessoa lê ou marca alertas como lidos, **Then**
   o número diminui na hora; com zero não lidos, o sino fica sem número.
5. **Given** a conferência falhou (sem internet, erro do serviço, sessão vencida), **When** o app
   tenta conferir, **Then** nenhum aviso de erro aparece, os alertas guardados e o número do
   sino continuam como estavam e a última verificação não avança (as notícias não se perdem; a
   próxima tentativa as encontra).
6. **Given** a conferência está em andamento, **When** a pessoa usa o app, **Then** nenhuma tela
   fica esperando ou com indicador por causa dela.
7. **Given** passaram mais de 50 alertas ou 30 dias, **When** novos alertas entram, **Then** o
   app guarda no máximo 50 alertas, todos dos últimos 30 dias, mantendo os mais recentes.
8. **Given** o app foi fechado e aberto de novo, **When** a pessoa olha o sino, **Then** o número
   e os alertas continuam os mesmos (ficam guardados no aparelho).

---

### User Story 2 - Ver os alertas e abrir a notícia (Priority: P1)

A pessoa toca no sino e vê a tela "Alertas": no alto, uma frase fixa com quantos alertas novos
tem; abaixo, os alertas agrupados em "Hoje", "Ontem" e "Anteriores", dos mais novos para os mais
antigos. Cada alerta mostra o título da notícia, a fonte e a hora (ou a data) e, se ainda não foi
visto, a palavra "Novo". Tocar num alerta abre a notícia inteira e marca o alerta como lido.

**Why this priority**: RF-020 (lista agrupada, tocar abre a notícia) e RF-022 (marcar como lido
ao abrir). É o que leva a pessoa do aviso à leitura (UC-07).

**Independent Test**: com alguns alertas guardados, tocar no sino, conferir os grupos e a ordem,
tocar num alerta "Novo" e ver a notícia abrir; voltar e ver que o alerta deixou de ser "Novo" e
que o número do sino diminuiu.

**Acceptance Scenarios**:

1. **Given** a pessoa tem conta, **When** toca no sino, **Then** abre a tela "Alertas" por cima
   das abas, com botão de voltar.
2. **Given** há alertas de hoje, de ontem e mais antigos, **When** a tela aparece, **Then** os
   alertas estão agrupados em "Hoje", "Ontem" e "Anteriores" (o dia da publicação da notícia, no
   fuso do aparelho), dos mais novos para os mais antigos; grupo sem alertas não aparece.
3. **Given** a tela está aberta, **When** a pessoa olha cada alerta, **Then** vê o título, a
   fonte, a hora (para "Hoje" e "Ontem") ou a data (para "Anteriores") e, se não foi lido, o
   rótulo escrito "Novo"; o alerta lido não tem o rótulo e fica com aparência discreta, mas
   legível.
4. **Given** a pessoa toca num alerta, **When** a notícia abre, **Then** o alerta já está marcado
   como lido, o número do sino já diminuiu e, ao voltar, a lista mostra o alerta sem "Novo".
5. **Given** a notícia do alerta não existe mais no serviço, **When** a pessoa toca no alerta,
   **Then** vê "Notícia não encontrada" (tela do detalhe) e o alerta continua na lista como lido.
6. **Given** não há nenhum alerta, **When** a tela aparece, **Then** vê "Você não tem alertas."
   com a explicação "Quando sair uma notícia nova, ela aparece aqui." e nenhum botão de marcar.
7. **Given** não há internet, **When** a pessoa abre a tela, **Then** vê os alertas guardados e
   uma faixa de "sem internet" fixa no alto; tocar num alerta abre o detalhe, que mostra a cópia
   da notícia se existir ou o erro com "Tentar novamente" (feature 010).
8. **Given** a pessoa toca duas vezes seguidas no mesmo alerta, **When** a notícia abre, **Then**
   ela abre uma vez só.

---

### User Story 3 - Marcar todos como lidos (Priority: P2)

Com vários alertas novos, a pessoa toca no botão grande "Marcar todos como lidos", sempre visível
no alto da tela, e todos passam a lidos de uma vez; o sino fica sem número.

**Why this priority**: RF-022 pede marcar todos. Poupa muitos toques, mas a lista funciona sem
ele (cada alerta pode ser aberto).

**Independent Test**: com 5 alertas novos, tocar no botão e ver os 5 sem "Novo", o resumo mudar
para "Você não tem alertas novos" e o sino sem número; reabrir o app e ver que continuam lidos.

**Acceptance Scenarios**:

1. **Given** há alertas novos, **When** a tela aparece, **Then** o botão "Marcar todos como
   lidos" aparece fixo no alto, com texto, com pelo menos 48 dp de altura.
2. **Given** a pessoa toca no botão, **When** a ação termina, **Then** todos os alertas ficam
   lidos na hora, o resumo mostra "Você não tem alertas novos" e o sino fica sem número; não há
   pedido de confirmação (a ação não apaga nada).
3. **Given** não há alertas novos (lista vazia ou tudo lido), **When** a tela aparece, **Then**
   o botão não aparece.
4. **Given** a pessoa marcou todos como lidos, **When** fecha e abre o app, **Then** os alertas
   continuam lidos.

---

### User Story 4 - Visitante e alertas desligados (Priority: P2)

O visitante que toca no sino vê o convite para entrar ou criar conta, e nada é pedido ao serviço.
Quem desligou "Receber alertas" no perfil não recebe alertas novos; a tela explica isso com um
aviso fixo e um botão que leva a "Editar perfil". Ao sair da conta, os alertas daquele aparelho
somem.

**Why this priority**: RN-003 e a última frase do RF-020. Protege o visitante de uma tela vazia
sem explicação e respeita a escolha de quem não quer alertas, mas não bloqueia a história principal.

**Independent Test**: como visitante, tocar no sino e ver o convite; com uma conta que tem
"Receber alertas" desligado, abrir o app com notícias novas no serviço e ver que o sino não muda
e a tela mostra o aviso; sair da conta, entrar com outra e ver que ela não vê os alertas da
primeira.

**Acceptance Scenarios**:

1. **Given** a pessoa é visitante, **When** toca no sino, **Then** aparece o convite para entrar
   ou criar conta (CB-011) e nenhum pedido é feito ao serviço; o sino do visitante nunca mostra
   número.
2. **Given** a tela de alertas é aberta sem conta (por exemplo, pela linha "Alertas" de
   Configurações), **When** ela aparece, **Then** mostra o convite dentro da tela, com um botão
   grande "Entrar ou criar conta", sem pedido ao serviço.
3. **Given** "Receber alertas" está desligado no perfil, **When** o app confere as notícias,
   **Then** nenhum alerta novo é criado e o sino não muda.
4. **Given** "Receber alertas" está desligado e a tela de alertas é aberta, **When** ela
   aparece, **Then** mostra, fixo no alto, o aviso "Os alertas novos estão desligados." com o
   botão "Ligar em Editar perfil", que abre `/profile/edit`; os alertas que já existiam continuam
   na lista.
5. **Given** a pessoa tem alertas guardados, **When** sai da conta ou a sessão vence, **Then** os
   alertas, as marcações e a última verificação daquela conta são apagados do aparelho, e o sino
   volta ao estado de visitante.
6. **Given** outra conta entra no mesmo aparelho, **When** ela abre o app, **Then** não vê
   nenhum alerta da conta anterior e a primeira conferência dela só marca o horário.
7. **Given** o aviso de "desligado" estava na tela, **When** a pessoa liga "Receber alertas" no
   perfil e volta, **Then** a tela, ao ser aberta de novo, confere o valor atual e o aviso some.

---

### Edge Cases

- **Primeira abertura da conta (ou conta nova no aparelho)**: só marca o horário; sem alertas,
  sem pedido de notícias (funciona até sem internet).
- **Muitas notícias novas de uma vez** (pessoa ficou semanas sem abrir): entram só as 50 mais
  recentes, todas dos últimos 30 dias; o resto é ignorado.
- **Notícia sem data de publicação no serviço**: usa a data da publicação original da notícia
  para agrupar e ordenar.
- **Notícia sem título ou sem fonte na resposta**: o item é ignorado; os demais entram.
- **Resposta malformada** (não é a lista esperada): conferência falha em silêncio, sem apagar nada
  (CB-005).
- **Duas conferências ao mesmo tempo** (abrir o app e a tela de alertas): roda uma e a outra
  espera ou é descartada; nunca cria alerta repetido.
- **Marcar como lido durante uma conferência**: a marcação não se perde quando a conferência
  termina.
- **Conferências automáticas muito seguidas** (ir e voltar ao app várias vezes): o app não pede ao
  serviço mais de uma vez a cada 5 minutos por conta própria; abrir a tela de alertas sempre
  confere.
- **Relógio do aparelho errado** (data no futuro ou no passado): o app não trava; a notícia com
  data futura aparece em "Hoje".
- **Dados guardados ilegíveis**: tratados como vazios; a próxima conferência só marca o horário.
- **Armazenamento do aparelho indisponível**: o app segue funcionando sem alertas, sem erro na
  tela.
- **Sessão vence durante a conferência**: o tratamento da feature 002 encerra a sessão; nada é
  mostrado nem guardado para a conta antiga.
- **Letra do sistema grande (até 2×)**: título, rótulo "Novo", botão e aviso não se sobrepõem; o
  botão "Marcar todos como lidos" quebra em mais linhas em vez de cortar o texto.
- **Leitor de tela (TalkBack)**: ordem título da tela, resumo, botão de marcar todos, grupos e
  alertas; cada alerta anuncia "Novo" (quando for), título, fonte e data; o sino anuncia "Alertas"
  e a quantidade ("Alertas, 3 novos").
- **Alto contraste**: o rótulo "Novo", o contador e o texto do alerta lido seguem o contraste
  AAA da feature 009.
- **Idioma do app inglês**: os textos fixos vêm em inglês; os títulos das notícias não são
  traduzidos.

## Requirements *(mandatory)*

### Functional Requirements

**Geração dos alertas (RF-020)**

- **FR-001**: Com conta, o app MUST conferir se há notícias novas ao abrir o app, ao voltar do
  segundo plano e ao abrir a tela de alertas, sem bloquear nem atrasar nenhuma tela e sem mostrar
  indicador por causa disso.
- **FR-002**: A conferência MUST criar um alerta para cada notícia publicada desde a última
  verificação e MUST NOT criar dois alertas para a mesma notícia.
- **FR-003**: Na primeira conferência de uma conta neste aparelho, o app MUST só guardar o horário
  e MUST NOT criar alertas nem pedir notícias ao serviço.
- **FR-004**: O app MUST guardar no máximo 50 alertas, todos dos últimos 30 dias (pela data de
  publicação da notícia), mantendo os mais recentes.
- **FR-005**: Quando a conferência falhar (sem internet, erro do serviço, resposta inválida,
  sessão vencida), o app MUST manter os alertas e o contador como estavam, MUST NOT avançar a
  última verificação e MUST NOT mostrar mensagem de erro; só na tela de alertas, falha por falta
  de internet MUST mostrar a faixa de "sem internet".
- **FR-006**: Com "Receber alertas" desligado no perfil, o app MUST NOT criar alertas novos; a
  última verificação MUST avançar normalmente, de modo que, ao ligar de novo, só as notícias
  publicadas depois disso gerem alertas.
- **FR-007**: O visitante MUST NOT gerar, ver nem contar alertas, e o app MUST NOT pedir nada ao
  serviço por causa de alertas enquanto não houver conta (RN-003).

**Contador no sino (RF-021)**

- **FR-008**: O sino da barra superior (Início, Atividades e Ajuda) MUST mostrar o número de
  alertas não lidos quando for maior que zero e MUST NOT mostrar número quando for zero; o número
  MUST atualizar na hora ao gerar, ler ou marcar alertas.
- **FR-009**: O número do sino MUST ser legível para o público idoso (círculo de pelo menos 24 dp,
  texto em negrito e maior que o do design system) e MUST ter rótulo para leitor de tela com a
  quantidade ("Alertas, 3 novos").
- **FR-010**: Tocar no sino com conta MUST abrir a tela de alertas; sem conta, MUST mostrar o
  convite para entrar ou criar conta sem chamar o serviço (RN-003, CB-011).

**Lista de alertas (RF-020, RF-022)**

- **FR-011**: A tela de alertas (rota `/notifications`) MUST listar os alertas agrupados em
  "Hoje", "Ontem" e "Anteriores", do mais novo para o mais antigo, pelo dia da publicação da
  notícia no fuso do aparelho; grupo vazio MUST NOT aparecer.
- **FR-012**: Cada alerta MUST mostrar título, fonte e hora (em "Hoje" e "Ontem") ou data (em
  "Anteriores"); alerta não lido MUST mostrar o rótulo escrito "Novo" (não só cor ou ponto).
- **FR-013**: Tocar num alerta MUST marcá-lo como lido na hora e abrir a notícia (`/news/:id`);
  ao voltar, a lista MUST refletir a marcação. Toque duplo MUST abrir uma vez só.
- **FR-014**: A tela MUST mostrar, fixo no alto, um resumo "Você tem N alertas novos" (ou "Você
  não tem alertas novos") e, havendo não lidos, o botão com texto "Marcar todos como lidos", que
  MUST marcar todos como lidos de uma vez, sem confirmação.
- **FR-015**: Sem alertas, a tela MUST mostrar "Você não tem alertas." com a explicação de que a
  notícia nova aparece ali; sem internet, MUST mostrar os alertas guardados e a faixa de "sem
  internet" (RNF-002).
- **FR-016**: Sem conta, a tela MUST mostrar o convite dentro dela (texto curto e botão grande
  "Entrar ou criar conta"), sem chamar o serviço.
- **FR-017**: Com "Receber alertas" desligado (valor conferido na última verificação), a tela MUST
  mostrar um aviso fixo "Os alertas novos estão desligados." com o botão "Ligar em Editar
  perfil" que abre `/profile/edit`, mantendo a lista dos alertas existentes.

**Persistência e conta (RF-022, RN-003)**

- **FR-018**: Alertas, marcações de lido e última verificação MUST ficar guardados no aparelho
  entre aberturas, separados por conta.
- **FR-019**: Sair da conta ou ter a sessão encerrada MUST apagar alertas, marcações e última
  verificação daquela conta; uma conta MUST NOT ver os alertas de outra.

**Acessibilidade e textos (RNF-003, RNF-004, RNF-006)**

- **FR-020**: Todos os botões e alertas tocáveis MUST ter área de toque de pelo menos 48×48 dp,
  rótulo para leitor de tela com o estado ("Novo"), e seguir o tema de alto contraste e a letra
  maior da feature 009, sem sobreposição com a fonte do sistema em 2×.
- **FR-021**: Todos os textos fixos MUST existir em português e inglês; o rótulo do sino e o
  título da tela usam a mesma palavra, "Alertas" ("Alerts"); o conteúdo das notícias vem do
  serviço e não é traduzido.

### Key Entities

- **Alerta**: representa uma notícia nova para a pessoa: identificador da notícia (chave, um
  alerta por notícia), título, fonte, data de publicação e se foi lido.
- **Última verificação**: o horário da última conferência bem-sucedida de notícias novas, por
  conta, neste aparelho.
- **Registro de alertas da conta**: os alertas (até 50, últimos 30 dias), a última verificação e
  o dono (a conta); é o que fica guardado no aparelho e é apagado ao sair.
- **Preferência "Receber alertas"**: escolha da pessoa no perfil, guardada no serviço; é só lida
  aqui.
- **Grupo de data**: "Hoje", "Ontem" ou "Anteriores", derivado da data de publicação da notícia.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com internet e o serviço acordado, o número do sino reflete as notícias novas em até
  5 segundos depois de o app abrir.
- **SC-002**: Em 100% dos testes, nenhuma notícia gera mais de um alerta, mesmo com abrir, voltar
  e abrir a tela de alertas em sequência.
- **SC-003**: Em 100% das primeiras conferências de uma conta, nenhum alerta é criado (só o
  horário é guardado).
- **SC-004**: Em 100% dos casos de visitante, nenhum pedido de alertas é feito ao serviço e o
  convite aparece.
- **SC-005**: Com "Receber alertas" desligado, em 100% dos testes nenhum alerta novo é criado.
- **SC-006**: Sem internet, a pessoa vê o número do sino e a lista de alertas que já estavam
  guardados (100% dos testes).
- **SC-007**: Do Início, a pessoa chega à notícia de um alerta em 2 toques (sino, alerta).
- **SC-008**: Todos os botões medem pelo menos 48×48 dp e têm rótulo para leitor de tela; a tela
  de alertas continua legível, sem textos cortados, com a letra em 2× e no alto contraste.
- **SC-009**: Com a conferência falhando, em 100% dos testes nenhuma mensagem de erro aparece nas
  telas fora de "Alertas".

## Assumptions

- **Origem dos alertas**: a API não tem notificações; os alertas são gerados no aparelho
  consultando as notícias publicadas desde a última verificação (decisão de 2026-10-03, contrato
  da API). O horário usado é o de **publicação no app**, não o da fonte original (ver
  [research.md](research.md) R0, que pede conferir isso no serviço antes de implementar).
- **Quando conferir**: ao abrir o app, ao voltar do segundo plano e ao abrir a tela de alertas
  (as duas primeiras no máximo uma vez a cada 5 minutos). O plano do produto diz "ao abrir o app
  e ao voltar ao feed"; esta feature entende "voltar ao feed" como voltar ao app, para não
  acoplar `notifications` ao módulo `news` (ver [research.md](research.md) R2).
- **Sem aviso com o app fechado**: não há push; a pessoa só vê os alertas quando abre o app
  (§1.3 da especificação do produto).
- **"Topo do app"** (RF-021): o sino fica na barra superior de Início, Atividades e Ajuda,
  como no design system (§7.11); Reels e Perfil não têm barra superior.
- **Contador legível**: o design system pede texto 10/700 no círculo; para o público idoso, o
  contador usa círculo de pelo menos 24 dp e texto maior (RNF-003). Ajuste a registrar no design
  system ao fim da tarefa.
- **Limites**: 50 alertas e 30 dias (backlog A6). Os 30 dias contam pela data de publicação da
  notícia.
- **Data mostrada**: hora ("14:30") para "Hoje" e "Ontem", e data curta ("12/09") para
  "Anteriores", pelo relógio do aparelho; formato de 24 horas nos dois idiomas.
- **Alerta lido continua na lista** até sair pelo limite de 50 alertas ou 30 dias; a pessoa não
  apaga alertas um a um nesta versão.
- **Marcar todos como lidos não pede confirmação**: não é ação destrutiva (RNF-003) e pode ser
  desfeita abrindo cada alerta de novo.
- **Quem desliga "Receber alertas"**: a chave está no perfil (B7); até ela existir na interface,
  o valor só muda pelo serviço. Esta feature só lê o valor guardado no serviço (research R1).
- **Visitante**: nunca tem alertas; RN-003 e CB-011 valem como no resto do app.
- **Dependências**: features 002 (cliente de API, renovação de sessão), 005 (sino, barra
  superior, rota `/notifications`, convite para visitante, estados comuns), 009 (alto contraste,
  letra maior) e 010 (rota `/news/:id` e o detalhe que abre a notícia).
- **Trilha A é da Amanda**: combinar antes de abrir a PR para a `develop` (esta tarefa também
  mexe no módulo `shell`, na barra superior, e na pasta `lib/dev`).
