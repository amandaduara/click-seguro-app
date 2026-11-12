# Feature Specification: Splash animada e logo na paleta do app

**Feature Branch**: `023-splash-animada`

**Created**: 2026-11-12

**Status**: Draft

**Input**: User description: "Splash animada (023-splash-animada). Substituir a splash atual (fade + escala) pela animação aprovada pela equipe em 2026-11-12, \"V4-2 — Mancha e onda\" (protótipo: https://claude.ai/artifact/8jSCUzk27TCjAExjTCE5CX). Sequência: fundo #FFFDFB; um toque vermelho (primary) aparece e vira uma mancha líquida de bordas onduladas que cobre a tela; sobre o vermelho, um ponto claro pousa no topo do escudo e o escudo oficial se desenha em background #FFFDFB pelas duas laterais, e a silhueta do idoso entra recortada pelo escudo; o vermelho escorre para baixo em onda, revelando o fundo claro; o logo passa de claro para primary e sobra uma onda no rodapé (primary-glow); título \"Click Seguro\" em secondary e tagline em muted-foreground. Sem círculo/disco atrás do logo no estado final. Só tokens da paleta do app. Também: trocar a cor do logo oficial (assets/branding/click_seguro_logo.svg e .png, hoje terracota #C0503E) para primary #FE3152, valendo no app inteiro (login etc.). Duração, padrão de mercado: animação de assinatura com no máximo ~1,8 s (Android SplashScreen API recomenda ícone animado ≤1 s; splash não deve atrasar o usuário); a navegação acontece quando a animação E a validação da sessão terminam (o que vier por último); se a validação demorar, mantém o estado final com o logo respirando suavemente; com \"Reduzir animações\" (AppMotion), mostra direto o estado final e navega assim que a validação terminar; a splash nativa do sistema (launch screen) deve usar o fundo #FFFDFB para emendar sem piscar no primeiro quadro. A splash toca uma vez por abertura a frio do app."

**Rastreabilidade**: RNF-003 (usabilidade para idosos) e RNF-004 (acessibilidade) da
[especificação do produto](../../.specify/memory/specification.md) · §2 (cores), §5 (ícones e
marca) e §6 (movimento) do [design system](../../.specify/memory/design-system.md) · splash e
destino da [feature 004](../004-splash-onboarding-sessao/) · identidade visual da
[feature 021](../021-identidade-visual/tasks.md) · movimento e "Reduzir animações" da
[feature 022](../022-fluidez-movimento/spec.md) (FR-018 é substituído aqui).

## Contexto

A splash atual mostra o logo, o nome e a frase com um esmaecimento simples e espera no mínimo 2 s
fixos. Em 2026-11-12 a equipe escolheu, entre 12 protótipos, a animação **"V4-2 — Mancha e onda"**
(canvas de design no link acima): um toque vermelho vira uma mancha líquida que cobre a tela, o
escudo do logo se desenha em claro sobre o vermelho, o idoso entra no escudo e o vermelho escorre
em onda, deixando o logo vermelho sobre o fundo claro do app.

Na mesma rodada a equipe decidiu que **tudo deve seguir a paleta do app**, com o vermelho
`primary` como cor dominante da marca. O logo oficial é terracota (`#C0503E`), uma cor que não
existe no design system; a feature 021 o preservou como estava. Agora ele passa a ser `primary`
(`#FE3152`) em todo lugar: no app, no ícone do aparelho e nas aberturas nativas. A forma (paths
do escudo e do idoso) não muda.

Rejeitado pela equipe e, portanto, fora desta feature: círculo/disco atrás do logo, fundo vermelho
cheio e permanente, cores fora da paleta.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Abertura animada da marca (Priority: P1)

Ao abrir o app, a pessoa vê o fundo claro, um toque vermelho que se espalha pela tela, o escudo
do Click Seguro se desenhando com o idoso entrando nele, e o vermelho escorrendo para baixo até
sobrar o logo vermelho, o nome "Click Seguro" e a frase "Sua segurança em primeiro lugar". Em
seguida segue para a tela certa (onboarding, login ou Início), como hoje.

**Why this priority**: é o pedido principal e a primeira impressão do app, vista em toda abertura.

**Independent Test**: abrir o app a frio com sessão salva e conferir a sequência, a duração e a
chegada ao Início; repetir sem sessão (login) e na primeira vez (onboarding).

**Acceptance Scenarios**:

1. **Given** o app fechado, **When** a pessoa o abre, **Then** a sequência toca uma vez, na ordem
   toque → mancha cobre a tela → escudo se desenha e o idoso entra → o vermelho escorre em onda →
   logo vermelho, nome e frase sobre o fundo claro, com uma onda no rodapé.
2. **Given** a validação da sessão termina antes da animação, **When** a animação acaba,
   **Then** o app segue para o destino logo depois, sem espera extra.
3. **Given** a validação da sessão ainda não terminou quando a animação acaba, **When** a pessoa
   espera, **Then** a tela fica no estado final com o logo "respirando" devagar até o destino ser
   decidido, e então segue para ele.
4. **Given** o estado final, **When** o app segue para o destino, **Then** a passagem é um
   esmaecimento para a primeira tela.
5. **Given** um leitor de tela ativo, **When** a splash aparece, **Then** é anunciado "Click
   Seguro" e a frase uma única vez; formas animadas não são anunciadas.

---

### User Story 2 - Logo na paleta do app em todo lugar (Priority: P1)

A pessoa vê o mesmo logo vermelho do app no ícone do aparelho, na abertura nativa, na splash, no
login e na tela "Sobre", na cor dos botões e destaques.

**Why this priority**: a equipe só aprova a splash com o logo seguindo a paleta; um logo terracota
no ícone ou no login contradiz a splash.

**Independent Test**: instalar o app e conferir o ícone na tela inicial do aparelho; abrir login e
"Sobre" e conferir que o logo está na cor `primary`.

**Acceptance Scenarios**:

1. **Given** o app instalado, **When** a pessoa olha o ícone na tela inicial (Android, iOS e web),
   **Then** o logo aparece em `primary` sobre o fundo claro do app.
2. **Given** as telas de login e "Sobre", **When** são abertas, **Then** o logo aparece em
   `primary`, com a mesma forma de antes.
3. **Given** o modo alto contraste ligado, **When** o logo é desenhado pelo app (splash, login,
   Sobre), **Then** segue a cor `primary` do alto contraste.

---

### User Story 3 - Sem movimento para quem pede (Priority: P2)

Quem ligou "Reduzir animações" no app ou no aparelho vê a splash já pronta, sem movimento, e o app
segue assim que a sessão for validada.

**Why this priority**: obrigação de acessibilidade (design system §6.2, RNF-004), mas depende da
splash existir.

**Independent Test**: ligar "Reduzir animações" e abrir o app: o estado final aparece de imediato
e nada se move, nem a respiração do logo.

**Acceptance Scenarios**:

1. **Given** "Reduzir animações" ligado, **When** o app abre, **Then** aparece direto o estado
   final (logo vermelho, nome, frase e onda do rodapé), sem toque, mancha nem traço.
2. **Given** "Reduzir animações" ligado e a validação demorando, **When** a pessoa espera,
   **Then** nada se move na tela.
3. **Given** "Reduzir animações" ligado, **When** a validação termina, **Then** o app segue para o
   destino sem esperar duração de animação.

---

### User Story 4 - Abertura sem piscar (Priority: P3)

Entre tocar no ícone e a splash animada começar, a pessoa vê só o fundo claro do app, sem um logo
estático que some e reaparece nem um clarão de outra cor.

**Why this priority**: acabamento; percebido em aparelhos lentos ou na primeira abertura.

**Independent Test**: abrir o app a frio num aparelho Android 12+ e num anterior, gravar a tela e
conferir que o primeiro quadro da splash animada emenda com a abertura nativa.

**Acceptance Scenarios**:

1. **Given** o app fechado, **When** a pessoa o abre, **Then** a abertura nativa mostra só o fundo
   `#FFFDFB`, igual ao primeiro quadro da splash animada.
2. **Given** a passagem da abertura nativa para a splash animada, **When** ela acontece, **Then**
   não há troca de cor de fundo nem um logo que aparece e some antes do toque vermelho.

---

### Edge Cases

- **Tela pequena ou fonte ampliada (até 200%)**: nome e frase quebram linha sem cortar; o logo
  diminui para caber; a tela rola se preciso (como a splash atual).
- **App volta do segundo plano**: não toca a splash de novo (só na abertura a frio).
- **Falha na leitura do onboarding ou da sessão**: segue as regras atuais da feature 004 (trata
  como "não visto"), sem travar a animação.
- **"Reduzir animações" muda durante a splash**: a splash pula para o estado final.
- **Alto contraste**: mancha, logo e onda usam as cores do alto contraste; o texto continua
  legível (secondary e muted-foreground do alto contraste).
- **Aparelho lento**: a animação pode perder quadros, mas não pode durar mais do que o previsto
  nem segurar a navegação além do fim previsto.

## Requirements *(mandatory)*

### Functional Requirements

**Splash animada (US1)**

- **FR-001**: A splash MUST tocar a sequência aprovada (V4-2) uma vez por abertura a frio:
  (1) toque `primary` no centro; (2) mancha `primary` de bordas onduladas que cobre a tela;
  (3) escudo oficial se desenhando em `background` pelas duas laterais, a partir do topo, e a
  silhueta do idoso entrando recortada pelo escudo; (4) o `primary` escorrendo para baixo em onda,
  revelando o fundo `background`, enquanto o logo passa de `background` para `primary`;
  (5) estado final: logo `primary`, nome em `secondary`, frase em `muted-foreground` e uma onda
  `primary-glow` no rodapé.
- **FR-002**: A animação de assinatura MUST durar no máximo **1,8 s** do primeiro quadro ao estado
  final.
- **FR-003**: O app MUST seguir para o destino quando **a animação e a validação** tiverem
  terminado, o que vier por último. O mínimo fixo de 2 s deixa de existir.
- **FR-004**: Se a validação passar do fim da animação, o logo MUST "respirar" devagar (escala
  pequena, ciclo lento) até o destino ser decidido; nenhuma outra forma aparece.
- **FR-005**: A saída da splash MUST ser um esmaecimento para a primeira tela (mantém o FR-018 da
  feature 022).
- **FR-006**: No estado final MUST NOT haver círculo, disco ou mancha atrás do logo.
- **FR-007**: Todas as cores MUST vir da paleta do app em uso (tema normal ou alto contraste):
  `primary`, `primary-glow`, `background`, `secondary`, `muted-foreground`.
- **FR-008**: A splash MUST expor ao leitor de tela só o nome e a frase, uma vez; as formas
  animadas MUST ficar fora da árvore de acessibilidade.

**Logo na paleta (US2)**

- **FR-009**: O logo oficial MUST passar a ser `primary` (`#FE3152`), mantendo exatamente os
  paths do escudo e do idoso e a máscara dos detalhes.
- **FR-010**: A troca MUST valer em todos os lugares do logo: imagem usada no app (splash, login,
  Sobre), ícones do aparelho (Android, iOS e web), imagens da abertura nativa e a cor de tema da
  web.
- **FR-011**: Onde o app desenha o logo em código, ele MUST usar a cor `primary` do tema em uso,
  para respeitar o alto contraste.

**Reduzir animações (US3)**

- **FR-012**: Com "Reduzir animações" (do app ou do aparelho), a splash MUST mostrar direto o
  estado final, sem movimento algum (inclusive sem respirar), e seguir assim que a validação
  terminar.

**Abertura nativa (US4)**

- **FR-013**: A abertura nativa (Android em todas as versões e iOS) MUST mostrar só o fundo
  `#FFFDFB`, sem logo, para emendar com o primeiro quadro da splash animada.

### Key Entities

- **Destino da splash**: onboarding, login ou Início; regra inalterada da feature 004.
- **Logo oficial**: o SVG em `assets/branding`, fonte única das imagens geradas; muda só a cor.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com a validação mais rápida que a animação, a pessoa chega à primeira tela em até
  **2,1 s** depois de a splash aparecer (1,8 s de animação + saída), contra pelo menos 2 s fixos
  mais a saída hoje.
- **SC-002**: Com "Reduzir animações", a splash não acrescenta nenhuma espera além da validação.
- **SC-003**: 100% dos lugares onde o logo aparece (app, ícones Android/iOS/web, aberturas
  nativas) mostram a cor `primary`; nenhuma ocorrência de `#C0503E` sobra no projeto.
- **SC-004**: Nome e frase da splash têm contraste de pelo menos 4,5:1 sobre o fundo; o logo
  `primary` tem pelo menos 3:1 sobre o fundo (elemento gráfico).
- **SC-005**: Na gravação da abertura a frio, nenhum quadro mostra troca de cor de fundo ou logo
  estático entre a abertura nativa e o toque vermelho.
- **SC-006**: A equipe reconhece a splash implementada como a V4-2 aprovada, comparando lado a
  lado com o protótipo.

## Assumptions

- **Duração (padrão de mercado)**: o guia de splash do Android recomenda ícone animado curto
  (~1 s) e que a splash não atrase o uso; a V4-2 do protótipo dura ~2,7 s com a saída. A sequência
  é comprimida para até 1,8 s mantendo a ordem e o caráter das fases; a respiração cobre
  validações lentas sem aumentar a animação. A equipe pode pedir ajuste fino depois de ver no
  aparelho.
- **Abertura nativa sem logo**: no Android 12+ o sistema sempre mostra um ícone na abertura; ele
  passa a ser transparente, para que a primeira coisa com a marca seja o toque vermelho da splash
  animada. É o padrão de apps com splash animada própria.
- **Ícone do aparelho**: continua o logo sobre fundo claro (`#FFFDFB`), só com a cor nova; não há
  redesenho do ícone.
- **Abertura a frio**: a splash já só existe na abertura do app (rota inicial); voltar do segundo
  plano não passa por ela.
- **A validação lenta** (servidor acordando) continua sendo tratada como hoje; esta feature não
  muda tempos de rede nem mensagens de lentidão.
- O protótipo no canvas é a referência visual; tempos e curvas finais seguem os tokens e curvas
  de `AppMotion` (design system §6) quando couberem, e a sequência comprimida no plano.
