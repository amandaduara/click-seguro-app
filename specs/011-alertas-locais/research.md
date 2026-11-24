# Research: Alertas locais de notícias novas

## R0 — O que o `openapi.json` diz de `GET /app/news` (e o que falta conferir no serviço)

- **Decision**: usar `GET /app/news` com `startDate`, `sortBy=publishedAt`, `sortOrder=desc`,
  `limit=50` e `page=1`, **mas tratar `startDate` como dica, não como garantia**: o caso de uso
  sempre filtra de novo no aparelho (`publishedAt` maior que a última verificação) e remove
  repetidos por `newsId`. A primeira tarefa do `tasks.md` (T002) confere no serviço de
  desenvolvimento o que o `openapi.json` não diz, e este item é atualizado com o resultado.
- **O que o `openapi.json` confirma** (arquivo de `.specify/memory/openapi.json`; o
  `openapi.json` da raiz do repositório PI é de **outra API**, sem rotas de notícias, e não vale
  aqui): `GET /api/v1/app/news` aceita `page`, `limit` (máx. 100, padrão 20), `category`,
  `search`, `startDate` (string), `endDate` (string), `sortBy` (`publishedAt` | `likesCount` |
  `readsCount`) e `sortOrder` (`asc` | `desc`). Resposta: `PaginatedNewsAppResponseDto` (`data[]` +
  `meta`), com o mesmo item do feed. Não existe endpoint de notificação.
- **O que o `openapi.json` NÃO diz** (por isso T002 confere no serviço, com conta de teste):
  1. o **formato** de `startDate` (é `string` sem `format`; esperado ISO-8601 UTC);
  2. **qual data** o filtro usa: `publishedAt` (quando a notícia entrou no app) ou
     `originalPublishedAt` (data da fonte). Se for a original, notícia recém-publicada com
     data original antiga não apareceria; nesse caso o app **não envia `startDate`**, pede as
     50 mais recentes por `publishedAt` e filtra tudo no aparelho;
  3. se `publishedAt` (opcional no item) vem sempre; sem ela, o alerta usa
     `originalPublishedAt` (spec, Edge Cases);
  4. se `startDate` é "maior ou igual" ou "maior que" (o caso de uso filtra de novo e o
     `newsId` evita repetição; só precisa saber se a primeira notícia de uma conferência pode
     repetir);
  5. `GET /users/me` devolve `receiveNotifications` (o contrato diz que sim, `GetProfileResponseDto`)
     e `PATCH /users/me {receiveNotifications:false}` o desliga (usado só para preparar a
     conta de teste do passo "desligado").
- **Resultado da conferência (T002, 2026-10-09, servidor de desenvolvimento
  `https://clickseguro-api.onrender.com/api/v1`)**, com a conta de teste
  `teste-a6-20261009190945@example.com` (criada por `POST /auth/app/register` + login, **desativada
  no fim** com `DELETE /users/me/deactivate` → 204; depois disso `/users/me` → 403 `USER_INACTIVE`).
  Tudo **como o plano previa**, nenhuma mudança de implementação:
  1. **Formato de `startDate`**: ISO-8601 com `Z` (`2026-10-08T02:15:30.000Z`), sem milissegundos
     (`…30Z`) e com offset (`+00:00`, `-03:00`) são aceitos e respeitam o instante; data só com dia
     (`2026-10-08`) é aceita (vale 00:00 UTC). Texto inválido ou vazio → 400 `VALIDATION_ERROR`
     (`errors[0].field = "startDate"`). O app envia `since.toUtc().toIso8601String()`.
  2. **Qual data filtra: `publishedAt`** (não a original). Prova: as 12 notícias do servidor têm
     `publishedAt` entre 2026-10-08T02:14:32Z e 02:16:03Z e `originalPublishedAt` entre 09-27 e 10-08T00:14Z;
     `startDate=2026-10-08T02:15:30.000Z` devolveu 4 (as 4 com `publishedAt` posterior; pela data
     original seriam 0) e `startDate=2026-10-05T00:00:00.000Z` devolveu 12 (pela original seriam 4).
     `AlertsRemoteDataSource` **envia** `startDate`.
  3. **`publishedAt` vem sempre**: nas 12 notícias (lista de 100, com e sem token) nenhuma veio sem
     `publishedAt`. O fallback para `originalPublishedAt` continua só como rede de segurança.
  4. **Comparação "maior ou igual"**: `startDate=2026-10-08T02:16:03.253Z` (igual à `publishedAt` de uma
     notícia) devolveu essa notícia; `…03.254Z` devolveu 0. Precisão de milissegundos. Por isso a
     notícia com `publishedAt == lastCheckAt` volta na resposta e o caso de uso a descarta
     (`publishedAt <= lastCheckAt`, passo 5 do data-model).
  5. **`GET /users/me`** traz `receiveNotifications` (`true` na conta nova);
     `PATCH /users/me {"receiveNotifications": false}` → 204 e o `GET` seguinte mostra `false`;
     `true` volta o valor.
  Extras: `limit=101` → 400 (máximo 100, `limit=50` vale); sem token `/app/news` também responde 200
  (`interaction` tudo `false`); `meta` = `{page, limit, total, totalPages, hasNextPage, hasPreviousPage}`.
  Ordem com `sortBy=publishedAt&sortOrder=desc`: da mais nova para a mais antiga.
  Itens reais para os fixtures (T003): `cmuywjppz0001fo1slem3p1zr` (`publishedAt`
  `2026-10-08T02:16:03.253Z`, original `2026-09-27T00:13:16.345Z`, "Banco não pede senha, token ou
  código por telefone", fonte "Banco Central do Brasil") e `cmuywmr7p000nfo1sucepkjy5` (`publishedAt`
  `2026-10-08T02:15:44.732Z`, original `2026-10-08T00:14:29.869Z`, "Golpe do PIX \"em dobro\": promessa de
  devolver o dobro do valor é sempre falsa", fonte "Banco Central do Brasil").
- **Rationale**: o filtro do servidor só reduz tráfego; a regra de "nova" é do app. Assim nenhum
  comportamento do usuário depende do que o servidor entende por `startDate`.
- **Alternatives considered**: confiar só no `startDate` (um campo de data errado esconderia
  notícias novas sem ninguém perceber) — descartado.

## R1 — Onde o app lê `receiveNotifications`

- **Decision**: `AlertsRemoteDataSource.getReceiveAlerts()` faz `GET /users/me` (com token, via
  `ApiClient`) e lê só o campo `receiveNotifications` (ausente → `true`, o padrão da API). O
  `CheckNewAlertsUseCase` consulta isso **a cada conferência** (depois da primeira), antes de
  pedir as notícias. Falha na consulta → a conferência falha inteira (R3).
- **Rationale**: hoje o app **ignora** o campo: `UserModel`/`UserEntity` (`authentication`) e a
  sessão não o guardam (só `name`, `email`, `phone`, `avatarUrl`, `role`), e a chave só será
  alterada pela B7 (`SetReceiveAlertsUseCase`). Ler direto do serviço garante o valor atual sem
  acoplar `notifications` a `authentication`/`profile` nem esperar a B7, e cumpre a regra do
  plano §1.3 (datasource próprio). Custo: um `GET /users/me` por conferência (no máximo a cada 5
  minutos, R2).
- **Alternatives considered**: (a) guardar `receiveNotifications` na sessão (`common`) — mexe em
  três módulos e na B7; (b) espelho local da chave gravado pela B7 — a B7 passaria a depender da
  chave de cache de `notifications`; (c) pedir `receiveNotifications` junto com as notícias —
  o serviço não devolve isso em `/app/news`. Registrar a escolha no plano do produto (§ de
  Alertas) quando a tarefa fechar.

## R2 — Quando conferir: abrir, voltar ao app e abrir a tela de alertas

- **Decision**: `NotificationsController.checkNew({force})` é chamado por um observador do ciclo
  de vida do app (`AlertsLifecycleTrigger`, criado no `NotificationsModule.providers`):
  1. ao criar o módulo, se a sessão já estiver `authenticated` (a sessão é restaurada antes do
     `runApp`);
  2. quando `sessionStatus` vira `authenticated` (login no meio do uso);
  3. em `AppLifecycleState.resumed`;
  4. a `NotificationsPage` chama `checkNew(force: true)` ao abrir.
  As chamadas sem `force` são ignoradas se a última conferência (bem-sucedida ou não) começou
  há menos de 5 minutos (`autoCheckInterval`); nenhuma roda enquanto outra está em andamento.
  Visitante/desconectado: nenhuma conferência.
- **Rationale**: o plano do produto diz "ao abrir o app e ao voltar ao feed". Voltar ao feed
  exigiria `notifications` ouvir a navegação do `news` (acoplamento) ou o `news` chamar
  `notifications`. "Voltar ao app" tem o mesmo efeito para a pessoa e não acopla módulos. Abrir a
  tela de alertas confere de novo para quem quer ver "agora". O intervalo de 5 minutos poupa o
  servidor de desenvolvimento (plano gratuito) e a bateria. Sem pull-to-refresh nem botão
  "atualizar": a pessoa idosa não precisa descobrir gesto; abrir a tela já atualiza.
- **Alternatives considered**: conferência periódica com `Timer` — o app não roda em segundo plano
  e não há push (fora da v1); só gastaria dados com a tela ligada. Conferir ao trocar para a aba
  Início — exigiria ouvir o roteador do shell.

## R3 — Última verificação: primeira vez, falha e chave desligada

- **Decision**:
  - **Primeira conferência da conta no aparelho** (não há registro do dono atual): grava
    `lastCheckAt = agora` e termina. Nenhum pedido ao serviço (funciona offline).
  - **Sucesso**: `lastCheckAt` = o horário em que a conferência **começou** (relógio do aparelho),
    gravado junto com os alertas novos numa só escrita.
  - **Falha** (conexão, timeout, 5xx, resposta inválida, 401): nada é gravado, `lastCheckAt` não
    avança; a próxima tentativa pede a mesma janela.
  - **Chave "Receber alertas" desligada**: grava `lastCheckAt = agora` sem criar alertas
    (proposta do FR-006: ao religar, só as notícias publicadas depois entram).
- **Rationale**: `lastCheckAt` começar no início da conferência evita perder a notícia
  publicada durante o pedido; o `newsId` evita repetir. Gravar alertas e horário juntos evita
  "horário avançou, alertas não".
- **Risco aceito**: relógio do aparelho adiantado em relação ao do serviço pode deixar passar uma
  notícia publicada nesse intervalo; relógio atrasado só gera repetição, que o `newsId` descarta.
  Se o teste no aparelho mostrar deriva relevante, aplicar uma margem fixa para trás em
  `startDate` (a deduplicação já cobre o excesso).
- **Alternatives considered**: usar a maior `publishedAt` recebida como horário — não avança
  quando não há notícia e exige ordem garantida; descartado. Ao religar, gerar o período em que
  ficou desligado — gera enxurrada para quem pediu para não ser avisado (marcador do FR-006).

## R4 — Um registro por conta, dono e limpeza ao sair

- **Decision**: uma chave `notifications_alerts_v1` no `LocalCacheService` com
  `{ owner, lastCheckAt, receiveAlerts?, alerts[] }` ([data-model.md](data-model.md)). `owner` é o
  e-mail da sessão (`owner: () => session.email ?? 'guest'`, como a feature 010). Ler com dono
  diferente ou registro ilegível devolve "sem registro" (primeira conferência). Uma escrita só
  por operação. O `NotificationsController` ouve `UserSessionService.sessionStatus` e, ao ir para
  `unauthenticated` (sair ou sessão vencida), limpa o estado em memória e chama `ClearAlerts`
  (apaga a chave); ir para `guest` também zera o estado em memória.
- **Rationale**: `UserSessionService` não conhece `notifications` (constituição I); o padrão
  "módulo ouve a sessão" é o da feature 010 (R3). O `owner` cobre o app morto antes de limpar. Um
  só registro mantém alertas, marcações e horário consistentes (nenhuma meia-escrita).
- **Alternatives considered**: chaves separadas (alertas, lidos, horário) — três escritas por
  operação e estados incoerentes se uma falhar; o backlog pede "alertas, lidos e última
  verificação no `LocalCacheService`", e o registro único cumpre isso.

## R5 — Concorrência: conferência × marcar como lido

- **Decision**: o `NotificationsController` executa as operações que **gravam** (mesclar o
  resultado da conferência, marcar um, marcar todos, limpar) uma de cada vez, numa fila de
  `Future`s. A conferência faz o pedido de rede **fora** da fila e, ao receber a resposta,
  entra na fila, **lê o registro de novo** e só então mescla e grava. Marcações feitas durante o
  pedido de rede ficam preservadas.
- **Rationale**: sem isso, uma conferência que leu o registro antes do pedido e grava depois
  desfaria um "marcar como lido" feito no meio (perda de atualização). A fila evita também duas
  escritas intercaladas no mesmo registro.
- **Alternatives considered**: bloquear marcações durante a conferência — a pessoa toca e nada
  acontece; ruim para idosos.

## R6 — Limites: 50 alertas, 30 dias e `limit=50` (diverge do contrato)

- **Decision**: o pedido usa `limit=50` (igual ao teto de alertas), uma página só, sem paginar. Ao
  mesclar: remove alertas com `publishedAt` anterior a 30 dias, ordena por `publishedAt`
  (decrescente) e mantém os 50 primeiros. A janela mínima do pedido é `max(lastCheckAt, agora − 30
  dias)`. O contrato diz `limit=20`; será atualizado (T046) para `limit=50`.
- **Rationale**: uma pessoa que ficou semanas sem abrir teria mais de 20 notícias novas; com 50
  uma única chamada cobre o teto e evita paginar. `limit ≤ 100` (openapi). Os 50 mais recentes são
  exatamente os que ficariam depois do teto.
- **Alternatives considered**: manter `limit=20` e paginar até 50 — mais chamadas para o mesmo
  resultado.

## R7 — Sino real sem quebrar a barra superior

- **Decision**: o `NotificationsController` é criado em `NotificationsModule.providers` (acima do
  app, como o `FeedController`), e o `NotificationBellButton` o lê com `context.select` do número
  de não lidos. O `AppTopBar` continua decidindo se abre a tela ou o convite (`requireAccount`),
  como hoje. O contador é um `Positioned` no canto do círculo de 48 dp, com `Semantics` próprio
  no rótulo do botão ("Alertas, 3 novos"). Os testes que montam o `AppTopBar`, o app ou o
  roteador ganham um helper `fakeNotificationsProvider` (como `fakeFeedProvider`).
- **Rationale**: o estado do contador precisa viver além de uma tela (aparece em três abas) e
  sobreviver à troca de aba. Manter `requireAccount` no `AppTopBar` preserva a decisão da feature
  005 (R5): `notifications` não importa `shell`.
- **Alternatives considered**: um `ValueNotifier<int>` global no `common` — mais um ponto de
  estado fora do módulo; o provider do módulo basta.

## R8 — Agrupamento e data sem dependência nova

- **Decision**: `AlertsGrouping` (extension sobre `List<AlertEntity>`, testável com `now`
  injetado) devolve seções `Hoje`/`Ontem`/`Anteriores` pela data local de `publishedAt`, itens do
  mais novo ao mais antigo, e omite seção vazia. Texto de cada alerta: hora `HH:mm` (24 h) em
  Hoje/Ontem e `dd/MM` em Anteriores, montados com `padLeft`, sem `intl` e sem novas chaves de
  mês. Data futura (relógio errado) cai em "Hoje".
- **Rationale**: o app já usa "Hoje"/"Ontem" no feed, mas as chaves são do módulo `news` (que
  `notifications` não pode importar); chaves próprias `notifications_group_*` custam três textos.
  Evitar `intl` direto (não é dependência direta do `pubspec`).
- **Alternatives considered**: reaproveitar `news_date_*` — cria dependência entre módulos.

## R9 — Leitura tolerante dos itens

- **Decision**: o model do alerta lê `id`, `title`, `source` e `publishedAt` (ou
  `originalPublishedAt`); item sem `id`, `title`, `source` ou sem nenhuma das duas datas é
  **ignorado**, sem derrubar a conferência. Corpo que não tenha `data` como lista → falha de
  resposta inválida (`ServerFailure`, CB-005).
- **Rationale**: um item ruim não pode impedir todos os alertas de sempre (e, falhando, a
  janela nunca avançaria).

## R10 — Entrada de desenvolvimento para testar no emulador

- **Decision**: `lib/dev/accessibility_playground.dart` ganha três botões fixos de texto: "Alertas:
  voltar verificação 7 dias" (grava `lastCheckAt = agora − 7 dias` no registro da conta atual, ou
  cria o registro), "Alertas: apagar" (limpa o registro) e "Abrir Alertas" (abre `/notifications`,
  para ver a tela como visitante). Somem quando não forem mais úteis.
- **Rationale**: a primeira conferência não gera alertas (FR-003) e o serviço de desenvolvimento não
  publica notícias a pedido; sem isso não dá para ver o contador no emulador. Segue o padrão
  da R8 de specs/010.
- **Alternatives considered**: publicar notícia pelo CMS no serviço — fora do escopo do app e
  depende de outra API.

## R11 — Textos: "Alertas" em tudo

- **Decision**: o rótulo do sino (`shell_notifications`, hoje "Notificações") passa a "Alertas"
  / "Alerts", igual ao título da tela (`notifications_title`). O produto fala "alertas" em
  RF-020 a RF-022, UC-07 e no switch "Receber alertas".
- **Rationale**: uma palavra só para o mesmo conceito reduz confusão para quem lê com leitor de
  tela e para o idoso.

## R12 — Decisões de UX para o público idoso

- **Decision**: (1) resumo "Você tem N alertas novos" e botão "Marcar todos como lidos" **fixos**
  no alto da tela, fora da lista que rola; (2) "Novo" escrito em cada alerta não lido, além de
  destaque visual (não depender só de cor); (3) sem menu de três pontos, sem deslizar para
  apagar ou marcar, sem pull-to-refresh obrigatório; (4) nenhuma confirmação em "Marcar todos"
  (ação reversível); (5) avisos (sem internet, alertas desligados) como faixas fixas no alto, não
  como `SnackBar` que some; (6) contador do sino maior que o do design system.
- **Rationale**: pedido do usuário e RNF-003/RNF-004; menos descoberta, menos erro, nada some
  sozinho. Com letra ≥ 1,5×, o alto entra na lista (uma rolagem só), para não criar uma segunda área de rolagem (decisão de 2026-10-09, público idoso).
- **Alternatives considered**: contador discreto de 10 sp do design system — ilegível para o
  público; `SnackBar` para "sem internet" — some antes de ser lido.

## Decisões do usuário

- **FR-006 / R3**: confirmado — religar "Receber alertas" **não** gera alertas do período
  desligado (a última verificação avança com a chave desligada).
- **R1**: confirmado — `receiveNotifications` é lido por `GET /users/me` no datasource de
  `notifications`.
