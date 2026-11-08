# Feature Specification: Fluidez, movimento e estados de carregamento

**Feature Branch**: `022-fluidez-movimento`

**Created**: 2026-11-08

**Status**: Draft

**Input**: User description: "Fluidez e movimento do app (motion, transições, estados de carregamento) + correções de UX encontradas na revisão: (1) fonte Montserrat não empacotada; (2) feed some/vira spinner no puxar-para-atualizar, na troca de categoria e na busca; (3) feed global não recarrega ao trocar de conta nem ao voltar do detalhe; (4) topo do botão central de Reels fora da área de toque; (5) SafeButton/SafeCard sem semântica de botão; (6) imagens sem cacheWidth/fade/pré-carregamento; (7) base de motion com tokens e 'reduzir animações' (sistema + opção do app), transições de página com volta preditiva, fade-through entre abas, troca animada entre carregando/erro/vazio/conteúdo com esqueletos; (8) polimento por tela: splash, feed, reels (curtir animado), login, onboarding, lição, assistente, barra inferior, botão. Público idoso: animações curtas e suaves. Inclui atualizar o toolchain Android para compilar com o JDK atual. Referência: fuja_app."

**Rastreabilidade**: RNF-003 (usabilidade para idosos) e RNF-004 (acessibilidade) da
[especificação do produto](../../.specify/memory/specification.md) · §3 (tipografia), §6
(movimento) e §7 (componentes) do [design system](../../.specify/memory/design-system.md) ·
feed da [feature 006](../006-feed-inicio/spec.md) · Reels da
[feature 008](../008-reels-curtir-salvar/spec.md) · acessibilidade das features
[009](../009-acessibilidade-global/spec.md) e [014](../014-acessibilidade/spec.md) · shell da
[feature 005](../005-shell-navegacao-base/spec.md).

## Contexto

As funcionalidades do app estão prontas e testadas, mas a experiência ainda parece "dura": as
telas trocam sem transição, as abas mudam de uma vez, todo carregamento é um círculo girando no
meio de uma tela vazia e nada na interface responde ao toque além da troca de estado. O servidor
gratuito pode levar até ~40 s para acordar, então a pessoa passa um bom tempo olhando para esses
círculos.

A revisão do código também achou problemas que a pessoa sente no uso: a fonte da marca nunca é
usada (o app inteiro sai na fonte padrão do sistema), o feed some ao puxar para atualizar ou trocar
de categoria, e o feed não acompanha a troca de conta nem a leitura de uma notícia.

O público é idoso (RNF-003): o movimento deve **orientar** (de onde a tela veio, o que mudou), ser
curto e suave, nunca chamar atenção para si, e poder ser desligado. O design system §6 já pede
respeito ao "reduzir movimento" do sistema; hoje nada o respeita.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Corrigir o que quebra a experiência hoje (Priority: P1)

A pessoa vê o app na fonte da marca; puxa o feed para atualizar e as notícias continuam na tela
enquanto a nova lista chega; troca de categoria ou busca sem a lista sumir de vez; ao voltar de uma
notícia, o cartão já aparece como "lida"; quando outra pessoa entra no mesmo aparelho, o feed é o
dela; o botão central de Reels responde ao toque no círculo inteiro; o leitor de tela anuncia
botões e cartões tocáveis como botões.

**Why this priority**: são defeitos visíveis no uso diário, independentes de animação, e os itens
seguintes dependem deles (não adianta animar um feed que some).

**Independent Test**: com o serviço falso, puxar para atualizar e conferir que os cartões
continuam na tela; trocar de conta e conferir que o feed recarrega; tocar o topo do botão central
e conferir que abre os Reels; conferir no leitor de tela que botões são anunciados como botão;
conferir que o texto usa a fonte da marca.

**Acceptance Scenarios**:

1. **Given** o feed carregado, **When** a pessoa puxa para atualizar, **Then** os cartões
   continuam na tela e na mesma posição até a lista nova chegar, com um único indicador de
   atualização.
2. **Given** o feed carregado, **When** a pessoa troca de categoria ou digita uma busca, **Then**
   a lista anterior continua visível (esmaecida ou com indicador discreto) até a nova chegar; se
   der erro, a lista anterior continua e um aviso explica o erro.
3. **Given** a pessoa abriu uma notícia a partir do feed, **When** volta ao feed, **Then** o
   cartão dessa notícia mostra o sinal de "lida" (e de "salva", se ela salvou).
4. **Given** uma sessão terminada (sair ou expirar), **When** outra conta entra ou a pessoa segue
   como visitante, **Then** o feed recarrega e não mostra marcas da conta anterior.
5. **Given** a barra inferior, **When** a pessoa toca em qualquer ponto do círculo do botão
   central, inclusive a parte acima da barra, **Then** os Reels abrem.
6. **Given** o leitor de tela ligado, **When** o foco chega a um botão ou cartão tocável do design
   system, **Then** ele é anunciado como botão, com seu rótulo, e desabilitado quando estiver.
7. **Given** qualquer tela, **Then** os textos aparecem na fonte da marca (Montserrat), nos pesos
   do design system, inclusive sem internet.

---

### User Story 2 - Movimento coerente que respeita "reduzir animações" (Priority: P1)

Todas as animações do app seguem as mesmas durações e curvas. Se o aparelho estiver com
"remover animações" ligado, ou se a pessoa ligar "Reduzir animações" em Acessibilidade, o app
troca de estado sem deslizar, aumentar ou esmaecer.

**Why this priority**: é a base de todas as outras histórias e uma exigência do design system
(§6) e de acessibilidade; sem ela, cada animação nova seria uma barreira para quem sente tontura
ou se confunde com movimento.

**Independent Test**: ligar "Reduzir animações" em Acessibilidade, navegar por telas, abas,
carregamentos e botões e conferir que nada desliza nem aumenta; desligar e conferir que as
animações voltam; repetir com a opção do sistema.

**Acceptance Scenarios**:

1. **Given** a tela de Acessibilidade, **Then** existe a opção "Reduzir animações", desligada por
   padrão, que vale na hora e continua valendo ao reabrir o app.
2. **Given** "Reduzir animações" ligado no app **ou** "remover animações" ligado no aparelho,
   **When** a pessoa abre ou fecha uma tela, troca de aba, carrega conteúdo ou toca num botão,
   **Then** a troca é imediata (sem deslize, zoom, esmaecimento ou brilho em movimento).
3. **Given** animações ligadas, **Then** nenhuma animação de interface dura mais que 400 ms, e
   nenhuma repete em loop, exceto indicadores de carregamento.
4. **Given** o visitante, **Then** a opção também está disponível (como as demais de
   Acessibilidade).

---

### User Story 3 - Carregamento no formato do conteúdo (Priority: P2)

Enquanto o feed, os Reels, as atividades, o perfil, as notificações e o detalhe da notícia
carregam, a pessoa vê o "esqueleto" da tela (blocos cinza no lugar de cartões, títulos e imagens)
em vez de um círculo girando; quando os dados chegam, o conteúdo aparece no lugar, esmaecendo
suavemente. Erro e vazio também aparecem com uma troca suave.

**Why this priority**: o servidor demora a acordar; o esqueleto mostra que algo está vindo e onde,
o que reduz a ansiedade e a sensação de app travado.

**Independent Test**: com o serviço falso atrasado, abrir cada tela listada e conferir o
esqueleto; liberar a resposta e conferir a troca suave para o conteúdo; forçar erro e vazio.

**Acceptance Scenarios**:

1. **Given** a primeira carga de uma tela listada, **Then** aparece um esqueleto com o formato
   aproximado do conteúdo, anunciado ao leitor de tela como "Carregando" (sem ler textos de
   exemplo).
2. **Given** o esqueleto na tela, **When** os dados chegam, **Then** o conteúdo substitui o
   esqueleto no mesmo lugar, sem pulo de layout perceptível.
3. **Given** uma carga que passa de 5 s, **Then** o aviso de "servidor acordando" continua
   aparecendo junto do esqueleto.
4. **Given** "Reduzir animações", **Then** o esqueleto é estático (sem brilho em movimento) e a
   troca é imediata.

---

### User Story 4 - Navegação que mostra de onde a tela veio (Priority: P2)

Abrir e fechar telas tem uma transição curta e consistente, com o gesto de voltar preditivo do
Android; trocar de aba esmaece uma aba na outra; tocar num cartão de Reels do Início leva aos
Reels com a imagem "crescendo" até a tela cheia; abrir uma notícia mostra na hora o título e a
imagem que já estavam no cartão enquanto o resto carrega; a splash leva à primeira tela com um
esmaecimento.

**Why this priority**: a troca seca de telas e abas é a principal reclamação ("trocas de tela são
duras"); para idosos, ver de onde a tela veio ajuda a não se perder.

**Independent Test**: navegar entre abas, abrir/fechar telas, abrir um Reel pelo carrossel e uma
notícia pelo feed, e conferir cada transição; com o gesto de voltar, conferir a prévia da tela
anterior.

**Acceptance Scenarios**:

1. **Given** qualquer tela aberta sobre outra, **When** a pessoa volta com o gesto do Android,
   **Then** vê a prévia da tela anterior durante o gesto e pode desistir.
2. **Given** uma aba, **When** a pessoa toca em outra, **Then** o conteúdo troca com um
   esmaecimento curto, a aba nova mantém a posição de rolagem que tinha, e a aba que saiu não
   continua animando por baixo.
3. **Given** o feed com uma notícia, **When** a pessoa a abre, **Then** o título e a imagem
   aparecem imediatamente no detalhe e o restante (texto, ações) entra quando carregar; se o
   carregamento falhar, o erro aparece abaixo do que já estava na tela.
4. **Given** a splash, **When** o destino é decidido, **Then** a primeira tela entra com um
   esmaecimento, sem tela em branco no meio.
5. **Given** o carrossel de Reels no Início, **When** a pessoa toca um cartão, **Then** a imagem
   do cartão leva visualmente ao Reel correspondente.

---

### User Story 5 - Toques que respondem (Priority: P3)

Botões e cartões afundam levemente ao toque; curtir um Reel faz o coração "pulsar" e vibrar de
leve, e dois toques na imagem do Reel também curtem; ao responder uma pergunta, certo e errado
têm uma resposta visual curta e uma vibração diferente; trocar entre "Entrar" e "Criar conta" faz
o campo de nome e as regras de senha aparecerem e sumirem suavemente; mensagens de erro entram
suavemente; o indicador do onboarding acompanha o dedo; a aba ativa da barra inferior troca de
cor e ícone suavemente; no assistente, um balão "digitando" aparece enquanto a resposta não chega
e as mensagens novas entram suavemente; a pergunta seguinte de uma lição entra de lado.

**Why this priority**: refina a sensação de qualidade; depende das histórias 2 a 4.

**Independent Test**: em cada tela listada, executar a interação e conferir a resposta visual,
a vibração (onde houver) e que, com "Reduzir animações", só a troca de estado acontece.

**Acceptance Scenarios**:

1. **Given** um botão do design system, **When** a pessoa toca rápido (toque curto), **Then** o
   afundamento é visível mesmo assim.
2. **Given** um Reel, **When** a pessoa curte (pelo botão ou com dois toques na imagem), **Then**
   o coração pulsa uma vez e o aparelho vibra de leve; o visitante continua vendo o convite de
   conta (RN-003) em vez de curtir.
3. **Given** uma resposta enviada, **When** o resultado chega, **Then** a opção certa e a errada
   são destacadas com um movimento curto e a vibração indica acerto ou erro.
4. **Given** a vibração desligada no aparelho, **Then** o app não vibra.

---

### User Story 6 - Imagens leves e sem "piscar" (Priority: P3)

As imagens das notícias e dos Reels aparecem esmaecendo sobre o quadro neutro, sem piscar; as
miniaturas carregam no tamanho em que são mostradas; o próximo Reel já está pronto quando a
pessoa desliza; imagens já vistas não são baixadas de novo enquanto o app está aberto.

**Why this priority**: o público usa aparelhos mais simples; imagens grandes demais causam
travadas e consumo de dados.

**Independent Test**: rolar o feed e os Reels com a rede lenta e conferir o esmaecimento, a
ausência de tela preta ao deslizar para o próximo Reel e o uso de memória estável.

**Acceptance Scenarios**:

1. **Given** um cartão do feed, **When** a imagem chega, **Then** ela esmaece sobre o quadro
   neutro (sem troca brusca); com falha, o quadro neutro continua.
2. **Given** a pessoa num Reel, **When** desliza para o próximo, **Then** a imagem do próximo já
   está visível (sem tela preta) se a rede permitiu baixá-la antes.
3. **Given** a barra de status sobre os Reels (fundo escuro), **Then** os ícones da barra de
   status ficam claros e legíveis; nas outras telas, escuros.

---

### Edge Cases

- Toque duplo rápido num cartão durante a transição de abertura não abre a tela duas vezes (o
  comportamento atual de ignorar o segundo toque continua).
- Trocar de aba no meio de uma transição de aba não deixa duas abas visíveis.
- Puxar para atualizar sem internet: a lista atual continua e aparece o aviso de erro (ou de cópia
  guardada, como hoje).
- Trocar de categoria várias vezes rápido: só a resposta da última escolha aparece (regra atual
  do feed) e a lista não pisca entre respostas antigas.
- Letra em 200% e alto contraste: esqueletos, transições e o balão "digitando" continuam legíveis
  e sem cortar texto; no alto contraste, o esqueleto usa cores de contraste adequadas.
- Abrir uma notícia por um link direto (sem vir de um cartão): o detalhe mostra o esqueleto
  completo, sem título prévio.
- Sessão expira durante a transição de uma tela: o aviso de sessão expirada continua aparecendo
  uma vez só.
- Leitura em voz alta automática ligada: as transições não atrasam nem duplicam a leitura.

## Requirements *(mandatory)*

### Functional Requirements

**Correções (US1)**

- **FR-001**: O app MUST exibir todo o texto na fonte da marca (Montserrat), nos pesos 400 a 800,
  embutida no app (funciona sem internet).
- **FR-002**: Atualizar o feed (puxar, trocar de categoria, buscar) MUST manter a lista atual
  visível até a nova chegar; a lista só é trocada pela tela de carregamento quando ainda não há
  nenhuma lista.
- **FR-003**: Uma falha ao atualizar com lista na tela MUST manter a lista e avisar o erro sem
  apagá-la.
- **FR-004**: O feed MUST recarregar quando a sessão muda de conta (sair, expirar, entrar, seguir
  como visitante).
- **FR-005**: Ao voltar do detalhe de uma notícia, o feed MUST refletir as marcas de lida e salva
  dessa notícia.
- **FR-006**: Toda a área visível do botão central da barra inferior MUST responder ao toque.
- **FR-007**: Botões e cartões tocáveis do design system MUST ser anunciados ao leitor de tela
  como botões, com rótulo e estado (habilitado/desabilitado).

**Base de movimento (US2)**

- **FR-008**: O app MUST usar um conjunto único de durações (curta, média, longa, no máximo
  400 ms) e curvas para toda animação de interface.
- **FR-009**: A tela de Acessibilidade MUST oferecer "Reduzir animações", desligada por padrão,
  guardada no aparelho como as demais preferências, valendo também para o visitante.
- **FR-010**: Com "Reduzir animações" ligado no app ou "remover animações" no sistema, todas as
  animações de interface MUST ser substituídas pela troca imediata de estado, e os esqueletos
  ficam estáticos.

**Estados de carregamento (US3)**

- **FR-011**: A primeira carga do feed, dos Reels, do painel de atividades, do perfil, das
  notificações e do detalhe da notícia MUST mostrar um esqueleto no formato do conteúdo.
- **FR-012**: A troca entre carregando, conteúdo, vazio e erro MUST ser animada (esmaecimento
  curto), alinhada no topo, sem pulo de layout.
- **FR-013**: O esqueleto MUST ser anunciado como "Carregando" e não expor textos de exemplo ao
  leitor de tela.
- **FR-014**: O aviso de servidor lento (após 5 s) MUST continuar funcionando com o esqueleto.

**Navegação (US4)**

- **FR-015**: Abrir e fechar telas MUST usar uma transição única no app, com o voltar preditivo
  no Android.
- **FR-016**: A troca de abas MUST esmaecer a aba antiga na nova, mantendo o estado e a rolagem
  de cada aba, e pausar animações das abas fora da tela.
- **FR-017**: O detalhe da notícia aberto a partir de um cartão MUST mostrar imediatamente o
  título, a fonte, a data e a imagem que o cartão já tinha.
- **FR-018**: A saída da splash MUST ser um esmaecimento para a primeira tela.
- **FR-019**: Abrir um Reel pelo carrossel do Início MUST ter continuidade visual da imagem do
  cartão para o Reel.

**Microinterações (US5)**

- **FR-020**: Botões e cartões tocáveis MUST ter retorno visual de pressão perceptível mesmo em
  toque curto.
- **FR-021**: Curtir um Reel MUST ter animação de pulso e vibração leve; dois toques na imagem do
  Reel MUST curtir (sem descurtir), respeitando a regra de visitante (RN-003).
- **FR-022**: O resultado de uma resposta MUST ter retorno visual curto e vibração distinta para
  acerto e erro.
- **FR-023**: Elementos que aparecem e somem na mesma tela (campos do cadastro, regras de senha,
  mensagens de erro e aviso) MUST entrar e sair com animação de tamanho e opacidade.
- **FR-024**: O indicador de página do onboarding MUST acompanhar o arraste.
- **FR-025**: A aba ativa da barra inferior MUST trocar cor e ícone com animação curta.
- **FR-026**: O assistente MUST mostrar um balão "digitando" enquanto espera a resposta, anunciado
  ao leitor de tela, e as mensagens novas MUST entrar com animação.
- **FR-027**: A troca de pergunta numa lição MUST ter transição lateral (avançar e voltar em
  sentidos opostos).
- **FR-028**: Vibrações MUST seguir a configuração do aparelho e ser no máximo uma por ação.

**Imagens (US6)**

- **FR-029**: Imagens de rede MUST ser decodificadas no tamanho em que aparecem e esmaecer ao
  chegar.
- **FR-030**: O app MUST baixar com antecedência a imagem do Reel seguinte.
- **FR-031**: A barra de status MUST ter ícones claros sobre os Reels e escuros nas demais telas.

**Engenharia**

- **FR-032**: O projeto Android MUST compilar e rodar no emulador com o JDK distribuído pelo
  Android Studio atual, sem configuração manual da máquina.
- **FR-033**: Todos os testes existentes MUST continuar passando; cada comportamento novo com
  lógica (feed estável, recarga por sessão, preferência de animações) MUST ter teste.

### Key Entities

- **Preferências de acessibilidade**: ganha o campo "reduzir animações" (sim/não), guardado e
  restaurado como os demais.
- **Prévia da notícia**: os dados que o cartão já tem (título, fonte, data, imagem, categorias),
  usados pelo detalhe antes da carga completa.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das trocas de tela e de aba têm transição (ou troca imediata com "Reduzir
  animações"); nenhuma troca seca com animações ligadas.
- **SC-002**: Nenhuma das telas de primeira carga listadas mostra mais o círculo girando sozinho
  no meio da tela.
- **SC-003**: Ao atualizar o feed, a lista visível nunca fica vazia quando já havia conteúdo.
- **SC-004**: Com "Reduzir animações" ligado, nenhuma animação de deslize, zoom ou brilho é
  percebida em um roteiro que passa por todas as abas e telas principais.
- **SC-005**: Ao abrir uma notícia pelo feed, o título aparece em menos de 0,3 s, mesmo com o
  servidor demorando.
- **SC-006**: Rolar o feed e deslizar 20 Reels num aparelho de entrada (emulador de referência)
  não tem travadas perceptíveis nem tela preta entre Reels com rede normal.
- **SC-007**: Em teste com o leitor de tela, 100% dos botões do design system são anunciados como
  botão.

## Assumptions

- "Reduzir animações" do app entra na tela de Acessibilidade existente (features 009/014), ao lado
  das opções atuais; o padrão é desligado porque a animação curta ajuda a orientar.
- A referência de comportamento é o fuja_app (tokens de movimento, esqueletos, troca de abas e
  transições); a escolha de bibliotecas fica para o plano, respeitando a Constituição §IV.
- A fonte Montserrat (licença OFL) pode ser embutida no app.
- Cache de imagens em disco entre sessões fica fora do escopo; vale o cache em memória da sessão.
- Telas não listadas (ajuda, configurações, edição de perfil, troca de senha) recebem as
  transições globais e os componentes atualizados, sem trabalho específico.
- O "toque duplo para curtir" não descurte, para evitar descurtir sem querer.
- Vídeo nos Reels continua fora do escopo (hoje são imagens).
