# Feature Specification: Shell de navegação e base das trilhas

**Feature Branch**: `005-shell-navegacao-base`

**Created**: 2026-10-04

**Status**: Draft

**Input**: User description: "F0.7 a F0.11 (Fase 0 necessária para a A3): esqueleto dos módulos news, notifications, activities, help, profile, settings e shell (module, barrel, presentation/routes, página placeholder, registro no main.dart na ordem do plan.md §1.4); blocos de i18n por módulo em AppStrings e chaves comuns (common_try_again, common_empty, common_offline_banner, common_account_required_*); shell com StatefulShellRoute.indexedStack e 4 abas conforme o BottomNav do wireframe, AppShell com TopBar e slot do NotificationBellButton placeholder, app_router compondo as rotas do plan.md §2, refreshListenable na sessão (unauthenticated → /login, CB-003), requireAccount + AccountRequiredSheet (RN-003/CB-011); estados comuns SafeLoadingState, SafeErrorState, SafeEmptyState e SafeOfflineBanner com 48 dp/16 sp (RNF-003) no style guide; smoke test que sobe o app com fakes e navega pelas 4 abas. Substitui a /home provisória das features 003/004. F0.5 e F0.6 ficam fora."

**Rastreabilidade**: tarefas F0.7, F0.8, F0.9, F0.10 e F0.11 do
[tasks do produto](../../.specify/memory/tasks.md) · RN-003, CB-003, CB-011, RNF-003, RNF-004,
RNF-006 da [especificação do produto](../../.specify/memory/specification.md) v2.1.0 · FR-012a e
SC-008 da [feature 001](../001-sessao-persistente-visitante/spec.md) (verificação adiada para a
F0.9) · rotas do [plano do produto](../../.specify/memory/plan.md) §2 e ordem dos módulos §1.4 ·
visual: `wireframe/src/components/BottomNav.tsx`, `TopBar.tsx` e `screens/ProfileScreen.tsx`.

## Contexto

Hoje, depois do splash ou do login, o app abre uma tela provisória de "Início" (features 003 e
004), sem abas. As trilhas A e B precisam de uma casca comum para começar: as abas, os caminhos
de todas as telas, o convite para criar conta e os estados de carregando/erro/vazio/offline.
Esta feature entrega essa casca com telas provisórias ("em breve") no lugar do conteúdo, para
que cada trilha só preencha o seu módulo, sem mexer nos arquivos compartilhados.

Ficam fora: serviços de plataforma e voz (F0.5) e acessibilidade global (F0.6).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navegar pelas abas do app (Priority: P1)

Depois de entrar (com conta ou como visitante), a pessoa vê a barra inferior com cinco abas,
como no wireframe: "Início", "Atividades", "Notícias" (botão central, redondo e maior), "Ajuda"
e "Perfil". Tocar numa aba mostra a tela dela; "Notícias" é a tela dos Reels, sem a barra
superior. Em Início, Atividades e Ajuda, uma barra superior cumprimenta pelo nome e tem os
botões de alertas e de configurações.

**Why this priority**: sem a casca de navegação, nenhuma tela das trilhas tem onde morar. É o
que destrava a A3 (Início) e o restante das duas trilhas.

**Independent Test**: entrar como visitante e tocar em cada uma das cinco abas; voltar à
aba anterior e conferir que ela continua onde estava; tocar em configurações e voltar.

**Acceptance Scenarios**:

1. **Given** a pessoa acabou de entrar (login, cadastro, visitante) ou reabriu o app com sessão,
   **When** a área principal aparece, **Then** ela está na aba "Início", com a barra inferior
   visível e "Início" destacada.
2. **Given** a pessoa está em qualquer aba, **When** toca em "Atividades", "Ajuda" ou "Perfil",
   **Then** a tela da aba aparece e a aba fica destacada.
3. **Given** a pessoa rolou ou avançou dentro de uma aba, **When** vai para outra aba e volta,
   **Then** a primeira aba continua como estava (nos Reels, no mesmo vídeo).
4. **Given** a pessoa está em qualquer aba, **When** toca no botão central "Notícias", **Then**
   a tela dos Reels aparece com a barra inferior visível e sem a barra superior, e o botão
   central fica destacado.
5. **Given** a pessoa está nos Reels, **When** abre a notícia completa de um reel, **Then** o
   detalhe abre por cima das abas; ao voltar, ela está no mesmo reel.
6. **Given** a pessoa está numa aba com a barra superior, **When** olha o topo, **Then** vê "Olá,
   {nome}" (conectada) ou "Bem-vindo" (visitante), o título da aba e os botões "Notificações" e
   "Configurações".
7. **Given** a pessoa toca em "Configurações", **When** a tela abre, **Then** ela aparece sobre
   as abas e "voltar" leva de volta à aba.
8. **Given** a pessoa está numa aba diferente de "Início", **When** usa o "voltar" do aparelho,
   **Then** vai para "Início"; em "Início", o "voltar" fecha o app.
9. **Given** uma tela ainda não foi construída pela sua trilha, **When** a pessoa a abre,
   **Then** vê uma tela provisória com o título e o aviso "Em breve", sem erro.

---

### User Story 2 - Convite para criar conta em ações restritas (Priority: P1)

Uma pessoa que entrou como visitante tenta usar algo que exige conta, como os alertas. Em vez de
abrir a tela, o app mostra um convite explicando que é preciso entrar e oferecendo "Entrar ou
criar conta". Ela pode aceitar e ir ao login, ou fechar o convite e continuar onde estava.

**Why this priority**: RN-003 vale para várias telas das duas trilhas (salvar, curtir, alertas,
perfil, editar dados). Ter o convite pronto e testado na base evita que cada trilha faça o seu.

**Independent Test**: como visitante, tocar no botão de alertas: aparece o convite, e nada é
pedido ao servidor; fechar o convite e continuar na aba; repetir e tocar em "Entrar ou criar
conta": vai ao login. Conectado, o mesmo botão abre a tela de alertas.

**Acceptance Scenarios**:

1. **Given** a pessoa é visitante, **When** toca em "Notificações", **Then** aparece o convite
   com título, explicação e os botões "Entrar ou criar conta" e "Agora não", e a tela de alertas
   não abre.
2. **Given** o convite está aberto, **When** a pessoa toca em "Agora não" (ou fecha o convite),
   **Then** ele some e ela continua exatamente onde estava.
3. **Given** o convite está aberto, **When** a pessoa toca em "Entrar ou criar conta", **Then** o
   app vai à tela de login.
4. **Given** a pessoa está conectada, **When** toca em "Notificações", **Then** a tela de alertas
   abre direto, sem convite.
5. **Given** a sessão expirou durante o uso (a pessoa não é mais conectada nem visitante),
   **When** ela tenta uma ação que exige conta, **Then** vê o mesmo convite.
6. **Given** qualquer ação restrita, **When** o convite é mostrado, **Then** nenhum pedido é
   feito ao servidor (CB-011).

---

### User Story 3 - Sessão encerrada durante o uso (Priority: P2)

Se o servidor recusa a sessão enquanto a pessoa usa o app, ela continua na tela em que estava e
vê o aviso "Sua sessão expirou, faça login novamente.", com a opção de entrar. Se ela mesma sai
da conta, o app a leva ao login.

**Why this priority**: fecha a verificação que a feature 001 deixou para a F0.9 (FR-012a e
SC-008 de lá). Sem isso, uma sessão expirada deixaria a pessoa sem saber por que as ações
pararam de funcionar.

**Independent Test**: nos testes automatizados, encerrar a sessão por expiração com o app numa
aba: a tela não muda e o aviso aparece com "Entrar"; encerrar por saída do usuário: o app vai ao
login.

**Acceptance Scenarios**:

1. **Given** a pessoa está conectada numa aba (ou numa tela sobre as abas), **When** o servidor
   recusa a sessão, **Then** ela continua na mesma tela e vê o aviso de sessão expirada com o
   botão "Entrar".
2. **Given** o aviso de sessão expirada está visível, **When** a pessoa toca em "Entrar",
   **Then** vai ao login.
3. **Given** a pessoa ignorou o aviso, **When** tenta uma ação que exige conta, **Then** vê o
   convite da US2.
4. **Given** a pessoa está conectada, **When** sai da conta (pelo próprio app), **Then** vai à
   tela de login.
5. **Given** a pessoa é visitante, **When** a sessão de visitante é encerrada pela saída,
   **Then** vai à tela de login.

---

### User Story 4 - Estados de carregando, erro, vazio e sem internet (Priority: P2)

As telas das trilhas que buscam dados mostram sempre os mesmos estados, com o mesmo visual e
textos simples: carregando, erro com "Tentar novamente", lista vazia e o aviso de sem internet.

**Why this priority**: a A3 (Início) é a primeira tela com dados e já precisa dos quatro estados.
Fazê-los uma vez, no padrão do design system, garante consistência e tamanhos adequados ao
público idoso.

**Independent Test**: abrir o style guide e ver os quatro estados; nos testes, tocar em "Tentar
novamente" chama a ação de repetir; conferir tamanhos de toque e de texto.

**Acceptance Scenarios**:

1. **Given** uma tela está buscando dados, **When** usa o estado de carregando, **Then** aparece
   um indicador de progresso e, se informado, um texto curto; o leitor de tela anuncia
   "Carregando".
2. **Given** a busca falhou, **When** a tela usa o estado de erro, **Then** aparecem a mensagem
   do erro e o botão "Tentar novamente"; tocar nele repete a busca.
3. **Given** a busca não trouxe nada, **When** a tela usa o estado vazio, **Then** aparecem um
   ícone e uma mensagem ("Nada por aqui ainda." por padrão, ou a da tela) e, se a tela informar,
   um botão de ação.
4. **Given** o app está mostrando conteúdo guardado por falta de internet, **When** a tela usa o
   aviso de sem internet, **Then** aparece uma faixa "Você está sem internet. Mostrando o
   conteúdo salvo." no topo do conteúdo.
5. **Given** qualquer um dos quatro estados, **When** medido, **Then** os botões têm no mínimo
   48×48 dp e os textos no mínimo 16 sp (RNF-003), e todos têm rótulo para leitor de tela.
6. **Given** a pessoa abre o style guide, **When** procura os estados, **Then** encontra os
   quatro com exemplo de uso.

---

### Edge Cases

- **Abrir uma tela pelo caminho com um identificador inexistente** (ex.: notícia que não
  existe): nesta feature as telas são provisórias e só mostram "Em breve"; o tratamento de "não
  encontrado" é de cada trilha.
- **Caminho desconhecido**: o app mostra uma tela provisória de "Página não encontrada" com
  botão para voltar ao Início, em vez de quebrar.
- **Sessão expirada várias vezes seguidas** (vários pedidos recusados ao mesmo tempo): o aviso
  aparece uma única vez.
- **Visitante abrindo configurações**: permitido (configurações não exige conta pelo RN-003); as
  subtelas que exigirem conta (dados pessoais, segurança) usam o convite quando a trilha B as
  construir.
- **Aba Perfil para visitante**: nesta feature mostra a tela provisória; o convite no lugar do
  conteúdo é da B7, usando o mesmo convite da US2.
- **Toque duplo rápido no botão de alertas**: abre um único convite (ou uma única tela).
- **Fonte do sistema grande**: barra inferior, barra superior e estados não cortam texto nem
  sobrepõem botões.

## Requirements *(mandatory)*

### Functional Requirements

**Navegação (F0.9)**

- **FR-001**: A área principal MUST ter cinco abas, nesta ordem e com os ícones do wireframe:
  "Início", "Atividades", "Notícias" (Reels, em destaque como botão central), "Ajuda" e
  "Perfil".
- **FR-002**: Cada aba MUST preservar o seu estado (posição e telas abertas dentro dela) ao
  trocar de aba.
- **FR-003**: Depois do splash com sessão e depois de login, cadastro ou entrada como visitante,
  o app MUST abrir a aba "Início" da área principal, no lugar da tela provisória atual.
- **FR-004**: As abas "Início", "Atividades" e "Ajuda" MUST ter barra superior com saudação
  ("Olá, {nome}" ou "Bem-vindo"), título da aba e os botões "Notificações" e "Configurações"; "Notícias" e "Perfil" não têm
  barra superior, como no wireframe. O botão de notificações MUST ficar num espaço reservado para o componente real da trilha A (A6).
- **FR-005**: Todas as telas do plano do produto (§2) MUST ter caminho próprio, com os caminhos
  exatamente como lá definidos. As telas sobre as abas (detalhe, alertas, configurações etc.)
  MUST abrir por cima da barra inferior; os Reels são a aba central.
- **FR-006**: Enquanto a trilha não construir a tela, ela MUST mostrar uma tela provisória com
  título e o aviso "Em breve".
- **FR-007**: Um caminho desconhecido MUST mostrar "Página não encontrada" com botão para voltar
  ao Início.
- **FR-008**: O "voltar" do aparelho numa aba diferente de "Início" MUST levar a "Início".

**Convite para criar conta (F0.9, RN-003, CB-011)**

- **FR-009**: MUST existir uma verificação única, reutilizável pelas trilhas, que diz se a ação
  pode continuar: conectado → continua; visitante ou sem sessão → mostra o convite e não
  continua.
- **FR-010**: O convite MUST ter título, explicação em linguagem simples, "Entrar ou criar conta"
  (vai ao login) e "Agora não" (fecha e mantém a pessoa onde estava).
- **FR-011**: Mostrar o convite MUST NOT fazer nenhum pedido ao servidor.
- **FR-012**: O botão "Notificações" da barra superior MUST usar essa verificação antes de abrir
  os alertas.

**Sessão encerrada (F0.9, CB-003, FR-012a da 001)**

- **FR-013**: Quando a sessão é encerrada por recusa do servidor durante o uso, o app MUST NOT
  mudar de tela e MUST mostrar, uma única vez, o aviso "Sua sessão expirou, faça login
  novamente." com a ação "Entrar" (vai ao login).
- **FR-014**: Quando a pessoa sai da conta (ou da sessão de visitante), o app MUST levá-la à tela
  de login.

**Estados comuns (F0.10, RNF-003, RNF-004)**

- **FR-015**: O design system MUST oferecer quatro estados reutilizáveis: carregando (com texto
  opcional), erro (mensagem + "Tentar novamente"), vazio (ícone, mensagem e ação opcional) e
  aviso de sem internet.
- **FR-016**: Botões dos estados, da barra inferior, da barra superior e do convite MUST ter no
  mínimo 48×48 dp. Textos de leitura (mensagens dos estados, explicação e botões do convite,
  aviso de sessão expirada) MUST ter no mínimo 16 sp. Textos complementares seguem o design
  system com piso de 12 sp: subtítulo da barra superior 14 sp e rótulos das abas 12 sp. Nenhum
  texto pode ser cortado com fonte grande.
- **FR-017**: Todo elemento interativo desta feature MUST ter rótulo para leitor de tela
  (inclusive o botão central, as abas e os botões só com ícone).
- **FR-018**: Os quatro estados MUST aparecer no style guide com exemplo.

**Base para as trilhas (F0.7, F0.8)**

- **FR-019**: Os módulos `news`, `notifications`, `activities`, `help`, `profile`, `settings` e
  `shell` MUST existir e estar registrados no app, na ordem do plano do produto (§1.4), de modo
  que as trilhas não precisem mais mexer no registro de módulos nem na composição de rotas.
- **FR-020**: Cada módulo MUST ter o seu bloco próprio de textos traduzidos, com ao menos uma
  chave inicial, e os textos comuns ("Tentar novamente", vazio, sem internet, convite) MUST
  existir em pt-BR e en-US.
- **FR-021**: Os textos e a tela provisória de "Início" das features 003/004 MUST ser removidos,
  sem deixar chaves órfãs.

**Testes (F0.11 e regras da constituição)**

- **FR-022**: Um teste de fumaça MUST subir o app inteiro com dependências falsas, entrar como
  visitante e navegar pelas cinco abas.
- **FR-023**: O convite, a reação à sessão encerrada (expirada e saída) e os quatro estados MUST
  ter testes automatizados, incluindo o caminho de sucesso e o de recusa.

### Key Entities

- **Aba**: destino principal da barra inferior (Início, Atividades, Notícias/Reels, Ajuda, Perfil), com rótulo,
  ícone, título da barra superior e estado preservado.
- **Rota**: caminho de uma tela do plano do produto, com onde ela abre (aba ou sobre as abas)
  e o módulo dono.
- **Convite de conta**: aviso mostrado a visitante ou sem sessão diante de ação restrita.
- **Motivo do encerramento da sessão**: "saída pelo usuário" (vai ao login) ou "expirada"
  (aviso, sem mudar de tela); já existe desde a feature 001.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A partir de qualquer aba, a pessoa chega a qualquer outra aba com um único toque,
  e volta à aba anterior encontrando-a no mesmo estado em 100% das trocas.
- **SC-002**: Em 100% das tentativas de ação restrita como visitante, o convite aparece e nenhum
  pedido é feito ao servidor.
- **SC-003**: Em 100% das recusas de sessão durante o uso, a pessoa permanece na tela e vê o
  aviso uma única vez (fecha o SC-008 da feature 001); em 100% das saídas, vai ao login.
- **SC-004**: Todos os caminhos do plano do produto abrem uma tela (provisória ou real) sem erro.
- **SC-005**: Todos os botões desta feature medem pelo menos 48×48 dp, os textos de leitura dos
  estados e do convite têm pelo menos 16 sp e nenhum texto fica abaixo de 12 sp.
- **SC-006**: A partir do fim desta feature, uma trilha consegue construir a sua primeira tela
  real mexendo só nos arquivos do seu módulo (e no seu bloco de textos).
- **SC-007**: O teste de fumaça e os demais testes passam, e a análise estática não ganha avisos
  novos.

## Assumptions

- **Reels como aba central** (decisão da usuária em 2026-10-04): como no wireframe, a barra
  inferior tem cinco abas e a do meio ("Notícias") é a tela dos Reels, com a barra inferior
  visível e sem a barra superior. Abrir os Reels por cima de tudo empilharia vídeos e detalhes
  de notícia. O plano do produto (§2), que dizia "tela cheia, sem abas", foi atualizado.
- **Barra superior por aba**: o Perfil do wireframe tem cabeçalho próprio (sem a barra
  superior). Fica assim: a barra superior aparece em Início, Atividades e Ajuda. Os títulos
  vêm do wireframe ("Notícias seguras", "Atividades", "Central de ajuda"); o subtítulo padrão é
  a saudação, e cada trilha pode trocá-lo depois (ex.: "3 notícias novas para você" na A3).
- **Configurações para visitante**: abre normalmente (RN-003 não restringe); o controle fino das
  subtelas é da trilha B.
- **Textos dos estados comuns**: o wireframe não os define; os textos propostos aqui ("Tentar
  novamente", "Nada por aqui ainda.", "Você está sem internet. Mostrando o conteúdo salvo.",
  convite "Entre na sua conta" / "Para usar esta função, entre ou crie uma conta. É rápido e
  gratuito.") seguem a linguagem simples do RNF-003 e podem ser ajustados nas trilhas.
- **Ordem dos módulos** com `settings` logo depois de `common`: mantida como no plano, mesmo que a
  acessibilidade (F0.6) ainda não exista; o módulo de configurações começa só com o esqueleto.
- **Saída da conta**: ainda não há botão de sair (é da B8). A reação à saída é verificada nos
  testes automatizados.
- **Dependências**: features 001 (sessão e motivo do encerramento), 002 (recusa de sessão pelo
  servidor), 003 (login) e 004 (splash com sessão).
