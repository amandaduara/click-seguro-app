# Click Seguro — Design System

**Projeto**: Click Seguro (TCC) — Aplicativo **Click Seguro** (antes "SafeNews")

**Versão**: 2.1.0

**Criado em**: 2026-10-04 · **Última alteração**: 2026-11-23

**Para quem**: quem vai reproduzir o visual do Click Seguro em outra plataforma (em especial a
**versão web**), e quem cria telas novas no app Flutter.

**Fontes**:
- **Implementação de referência (canônica)**: o app Flutter, em
  `click_seguro_app/lib/core/theme/` (`app_colors.dart`, `app_palette.dart`,
  `app_typography.dart`, `app_spacing.dart`, `app_motion.dart`, `app_theme.dart`),
  `click_seguro_app/lib/core/widgets/` (os `Safe*`, `EditableAvatar`, `PersonAvatar`,
  `ListenButton`) e `click_seguro_app/lib/core/illustrations/`. É o que o usuário vê no celular.
- **Origem do visual 2.0**: o Figma "Redesign 2.0" (16 quadros), gerado a partir de
  `click-seguro-redesign.html`, fonte das medidas e dos SVGs das ilustrações. Decisões e ajustes
  da validação da usuária em [specs/024-redesign-visual](../../specs/024-redesign-visual/)
  (spec, research R1–R20).
- **Origem do visual 1.x** (só histórico): o wireframe em `wireframe/` (React + Tailwind v4 +
  shadcn/ui). Não é mais referência de tokens: a paleta, a fonte e a barra inferior mudaram.
- **Regras de produto que afetam o visual**: RNF-003 (usabilidade para idosos) e RNF-004
  (acessibilidade) da [especificação](specification.md).

Quando o Figma e o app divergem, **vale o app** (ver [§10](#10-divergências)).

---

## 1. Princípios

1. **Feito para pessoas idosas.** Corpo de 16, alvos de toque de 48 ou mais, linguagem simples,
   **uma ação principal (coral) por tela**. Na dúvida, maior e mais espaçado; quem precisa de
   letra maior aumenta em Acessibilidade.
2. **Calmo e confiável.** Fundo branco, creme para superfícies planas, tinta azul-escura para
   texto e coral só para o que se toca. Cantos arredondados e **uma sombra só**.
3. **Coral = ação, tinta = leitura.** O `primary` marca a ação principal, a aba ativa e o que
   está selecionado em destaque. Títulos e texto ficam em tinta (`textForeground`/`textBody`).
4. **Conteúdo primeiro, sem enfeite.** Toda notícia e todo módulo têm capa (imagem ou
   ilustração do tema). Textos de apoio fixos que não ajudam a decidir saem da tela.
5. **Acessível por padrão.** Contraste WCAG 2.1 AA no tema normal e AAA no alto contraste,
   rótulo para leitor de tela em todo elemento interativo, nada que dependa só de cor e
   "Reduzir animações" respeitado em todo movimento.

---

## 2. Cores

### 2.1 Tokens

Nos widgets, leia a cor do tema em uso com `context.colors.<token>` (`AppPalette`), **nunca**
`AppColors` direto: assim o alto contraste chega à tela. Na web, use os nomes como variáveis CSS
(`--primary`, `--surface`...).

| Token (`AppPalette`) | Hex | Uso |
|---|---|---|
| `primary` | `#E31C3D` | Botão principal, aba ativa da barra inferior, chave ligada, links de ação, cartão de emergência, logo |
| `primaryPressed` | `#C2112F` | Botão principal pressionado; texto coral sobre `primarySoft` |
| `primarySoft` | `#FFE8EB` | Fundo de selo de alerta/erro e de seleção leve |
| `primaryGlow` | `#F0566C` | Onda de trás da splash animada (alto contraste: `#9E0019`) |
| `secondary` | `#1B2440` | Tinta: chip selecionado, faixa sem internet, aviso curto (toast) |
| `textForeground` | `#1B2440` | Títulos, rótulos, ícones e texto de destaque |
| `textBody` | `#3D4457` | Texto corrido (parágrafos) |
| `textMutedForeground` | `#5E6577` | Apoio: metadados, dicas, ícones inativos, placeholder |
| `textPrimaryForeground` | `#FFFFFF` | Texto e ícone sobre `primary`, `secondary` e imagens escuras |
| `background` | `#FFFFFF` | Fundo das telas |
| `card` | `#FFFFFF` | Fundo de cartões, campos, folhas e diálogos |
| `surface` | `#F7F5F0` | Creme: cartão plano, chip e botão redondo em repouso, busca, splash |
| `surfaceStrong` | `#EFEBE3` | Creme forte: botão secundário, trilho das abas em pílula, trilho de progresso |
| `border` | `#E4E1DA` | Borda de cartões, divisórias, borda da barra inferior, alça da folha |
| `input` | `#F7F5F0` | Preenchimento neutro (base do esqueleto) |
| `inputBorder` | `#8A8F9C` | Contorno do campo sem foco (3:1 sobre o fundo, WCAG 1.4.11) |
| `success` / `successSoft` | `#0F7B4F` / `#DFF3E8` | Resposta certa, selo "Seguro", "lida" |
| `warning` / `warningSoft` | `#8F5600` / `#FDF0D5` | Selo de atenção |
| `info` / `infoSoft` | `#2554C7` / `#E4ECFB` | Avisos informativos |
| `destructive` | `#C4122F` | Erro de campo, ícone de tentar de novo, ações destrutivas (lixeira) |
| `pastelPeach`, `pastelSage`, `pastelSky`, `pastelButter`, `pastelLilac` | `#FFD9CE`, `#D3E8DA`, `#D8E6F7`, `#FCEBB6`, `#E6DFF6` | Fundo das capas ilustradas (§5.2) |

### 2.2 Pares "suave + forte"

Selos e avisos usam um fundo **suave** com o texto **forte** da mesma família (no lugar do
"10% de opacidade" da 1.x): `primarySoft` + `primaryPressed`, `successSoft` + `success`,
`warningSoft` + `warning`, `infoSoft` + `info`, `surfaceStrong` + `textForeground`. Todos os pares
de texto e fundo são conferidos no `app_palette_test.dart` (AA no normal, AAA no alto contraste).

### 2.3 Gradientes

O gradiente coral (botão "gradient") **saiu** no 2.0; o `primaryGlow` ficou só como a cor da onda
de trás da splash animada (§6.3, §7.13). Ficam só os gradientes
escuros de legibilidade sobre imagem: no cartão do carrossel de Reels e na tela de Reels.

### 2.4 Tema escuro e alto contraste

- **Tema escuro**: não faz parte do produto.
- **Alto contraste** (RF-039): `AppPalette.highContrast`. Mesmos tokens, com contraste AAA:

  | Token | Alto contraste |
  |---|---|
  | `textForeground`, `textBody`, `border`, `inputBorder` | `#000000` |
  | `textMutedForeground` | `#333333` |
  | `primary`, `destructive` | `#9E0019` (pressionado `#7A0013`) |
  | `secondary` | `#0B1A3A` |
  | `success` / `warning` / `info` | `#005A3C` / `#6E4200` / `#0B3A9E` |
  | `background`, `card`, `surface`, todos os "suaves" e pastéis | `#FFFFFF` |
  | `surfaceStrong`, `input` | `#F2F2F2` |
  | `shadow` | lista vazia |

  Sem sombra, os componentes ganham borda preta (o código testa `colors.shadow.isEmpty`). As
  ilustrações são recoloridas (§5.2). Na web, uma classe `.high-contrast` com as mesmas
  variáveis.
- **Tamanho da letra** (RF-038): níveis do app multiplicados pela escala do sistema, com teto de
  200%. Folhas, diálogos e estados MUST rolar quando passam da altura da tela.

---

## 3. Tipografia

- **Família**: **Inter** (SIL OFL 1.1), empacotada em `assets/fonts/` com os pesos 400, 500, 600,
  700 e 800 (funciona offline). `ThemeData.fontFamily = 'Inter'`. Fallback na web:
  `ui-sans-serif, system-ui, sans-serif`.
- Estilos nomeados em `AppTypography`, sem cor (a cor vem do `textTheme` ou de `context.colors`).
  Nada de `fontSize:` solto nas telas.

### 3.1 Escala (revista na validação da usuária, 2026-11-10)

| Estilo (`AppTypography`) | `textTheme` | Tamanho / peso | Tracking / altura | Uso |
|---|---|---|---|---|
| `display` | `displayLarge` | 28 / 700 | −0,8 / 1,15 | Título de tela (barra superior, Configurações, Perfil) |
| `title1` | `displayMedium` | 24 / 700 | −0,5 / 1,2 | Títulos fortes: conclusão, enunciado da pergunta |
| `title2` | `titleLarge` | 20 / 700 | −0,2 / 1,25 | Seções; título de diálogo |
| `title3` | `titleMedium` | 18 / 600 | — / 1,3 | Título de cartão; título da `AppBar` (em 700) |
| `bodyLarge` | `bodyLarge` | 17 / 400 | — / 1,5 | Leitura longa (texto da notícia, explicações) |
| `body` | `bodyMedium` | 16 / 400 | — / 1,55 | **Padrão** de todo texto |
| `label` | `labelLarge` | 15 / 600 | — / 1,3 | Rótulos de campo, links, chips, botão compacto, abas |
| `caption` | `bodySmall`, `labelMedium` | 14 / 500 | — / 1,35 | Metadados: **o menor tamanho do app** |
| `button` | — | 17 / 700 | — / 1,25 | Botão grande |
| `score` | — | 64 / 800 | −2 / 1 | Placar da conclusão do módulo |

Cores padrão no `textTheme`: títulos e rótulos em `textForeground`, corpo em `textBody`, legenda
em `textMutedForeground`.

### 3.2 Regras

- **Corpo 16, títulos de 18 a 28, nada abaixo de 14** (FR-003 da 024, RNF-003). O 14 fica para
  metadados, legendas e selos.
- A interface MUST continuar funcionando com a letra aumentada (até 200%): textos quebram linha
  em vez de serem cortados; a grade do Início vira uma coluna acima de 1,3×; os rótulos das abas
  em pílula encolhem numa linha só.
- Títulos de notícia: no máximo 2 linhas nos cartões; descrição do módulo, 3 linhas no modo
  compacto (o leitor de tela lê o texto inteiro).

---

## 4. Espaçamento, cantos e sombra

### 4.1 Espaçamento (escala de 4, `AppSpacing`)

| Token | px | Uso comum |
|---|---|---|
| `s1` | 4 | Entre ícone e texto de mensagem de erro |
| `s2` | 8 | Entre rótulo e campo, entre chips, entre botões da barra superior |
| `s3` | 12 | Entre cartões numa lista, entre ícone e texto do campo |
| `s4` | 16 | Topo e base da barra superior, espaço da alça ao conteúdo da folha |
| `s5` | 20 | **Margem lateral das telas**, padding do cartão padrão |
| `s6` | 24 | Margem das folhas e dos estados, espaço entre seções |
| `s7` | 32 | Espaços grandes (splash, onboarding) |
| `s8` | 48 | Respiros maiores |

### 4.2 Cantos

| Token | px | Uso |
|---|---|---|
| `radiusSm` | 12 | Peças internas pequenas |
| `radiusMd` | 16 | **Botão grande e campos**, aviso curto (toast) |
| `radiusLg` | 20 | **Cartões** (`SafeCard`, `cardTheme`, cartão "Ouvir notícia") |
| `radiusXl` | 24 | Destaques e capas grandes, diálogos, cartão do carrossel de Reels |
| `radius2xl` | 32 | **Folhas inferiores** (canto de cima) |
| `radiusFull` | 999 | Chips, selos, abas em pílula, busca, barras de progresso, botões redondos |

O botão compacto usa canto 14.

### 4.3 Sombra única

`AppColors.shadow` / `context.colors.shadow`, a **única** sombra do app:

```
0 0 0 1px rgba(0,0,0,.02)    (spread 1)
0 2px 6px rgba(0,0,0,.04)
0 4px 8px rgba(0,0,0,.10)
```

Usada em cartões, na aba ativa (pílula e barra inferior), no indicador das abas em pílula, nos
botões e selos sobre imagem e no círculo da splash. No alto contraste, vira lista vazia e o
componente ganha borda. Não existem mais `shadow-sm`, `shadow-md` nem `shadow-primary`.

---

## 5. Ícones e ilustrações

### 5.1 Ícones

- **Biblioteca**: [Lucide](https://lucide.dev) (`lucide_icons_flutter` no app, `lucide-react` na
  web), só de traço e **sem emojis** (FR-005). Voltar e fechar usam `arrowLeft` e `x` em todo o
  app (`actionIconTheme`).
- **Tamanhos**: 16 (selos, erro do campo), 20 (botões da barra superior), 22 (campo, botões com
  texto), 24 (padrão, barra inferior, botão redondo de 48), 26 (botão redondo de 56).
- **Ícones de tela**:

| Onde | Ícone |
|---|---|
| Marca (splash, login, Sobre) | logo oficial desenhado em código (`BrandMark`/`AppLogo`, paths de `assets/branding/click_seguro_logo.svg`) na cor `primary` do tema, sempre decorativo ao lado do nome |
| Barra inferior | `house` (Início), `graduationCap` (Atividades), `newspaper` (Notícias/Reels), `lifeBuoy` (Ajuda), `user` (Perfil) |
| Barra superior | `bell` (Alertas), `messageCircle` (Assistente) |
| Perfil | `settings` (Configurações; só aqui) |
| Contatos | ligar e lixeira (remover) lado a lado no cartão |

- Botão só com ícone MUST ter rótulo acessível (`semanticLabel`/`Tooltip` no app, `aria-label`
  na web).

### 5.2 Ilustrações

SVGs próprios em `assets/illustrations/`, desenhados com `SafeIllustration` (`flutter_svg`),
sempre **decorativos** (fora da árvore de semântica). Lista (`AppIllustration`):

| Grupo | Ilustrações |
|---|---|
| Onboarding | `onboardingProtect`, `onboardingNews`, `onboardingPractice` |
| Capas por tema | `themeWhatsapp`, `themePix`, `themeLink`, `themeCall`, `themePassword`, `themeFakeNews`, `themeGeneric` |
| Estados | `stateOffline`, `stateError`, `stateEmpty`, `stateTrophy` (conclusão) |
| Resposta | `answerCorrect`, `answerWrong` (lâmpada) |

- **Tema da capa**: `IllustrationTheme.fromText` reconhece o tema no título do módulo ou na
  categoria/título da notícia (pt e en, sem maiúsculas e acentos): WhatsApp (pêssego), Pix/boleto
  (sálvia), link/phishing (céu), ligação (manteiga), senha (lavanda), fake news (pêssego);
  nenhum → escudo genérico sobre creme.
- **Alto contraste**: um `ColorMapper` troca as cores do desenho pelas da paleta AAA (pastéis e
  claros → branco, tinta → preto, coral → `#9E0019`, verde → `#005A3C`, dourado → `#6E4200`).
- **Carregando não tem ilustração**: no esqueleto, a capa ilustrada vira bloco cinza
  (`SafeSkeleton.leaf`), igual ao resto do cartão.

---

## 6. Movimento

Movimento curto e suave, para quem usa o app com calma (RNF-003). Toda animação de interface lê
as durações e curvas de `AppMotion.of(context)` (`core/theme/app_motion.dart`), nunca de um
`Duration` literal. Assim a opção "Reduzir animações" cobre o app inteiro.

### 6.1 Tokens

| Token | Duração | Uso |
|---|---|---|
| `short` | 150 ms | pressão de botão e cartão, cor e círculo da aba ativa |
| `medium` | 250 ms | troca de estado, de aba, indicador das abas em pílula, entrada de mensagens e campos |
| `long` | 350 ms | entrada de tela, troca de pergunta, pulso do curtir (teto: 400 ms) |

| Curva | Uso |
|---|---|
| `AppMotion.enter` (*emphasized decelerate*) | o que entra na tela |
| `AppMotion.exit` (*emphasized accelerate*) | o que sai da tela |
| `AppMotion.standard` | troca no lugar (cor, opacidade, tamanho) |
| `AppMotion.emphasis` (*ease out back*) | ênfase curta, com um leve passar do ponto |

Exceção registrada: a comemoração da conclusão (confete e contagem do placar, 1200 ms) usa uma
constante local, porque toca uma vez e passa do teto de 400 ms. Nenhuma animação pisca mais de 3
vezes por segundo.

### 6.2 "Reduzir animações"

Em Configurações → Acessibilidade, "Reduzir animações" (ou "remover animações" do aparelho)
zera todas as durações: o código é o mesmo e a troca fica imediata. `AppMotionScope`, no
`builder` do `MaterialApp`, junta as duas fontes. Com ela ligada: brilho do esqueleto parado,
sem confete, placar e progresso já no valor final, sem pulso do "Ouvir", sem `Hero` e troca de
tela sem transição.

### 6.3 Padrões

| Situação | Efeito |
|---|---|
| Abrir e fechar telas | transição do sistema com voltar preditivo no Android (`PredictiveBackPageTransitionsBuilder`), deslize no iOS (`MotionAwareTransitionsBuilder`); `appFadePage` (esmaecer) nas rotas que trocam a pilha, como a saída da splash |
| Troca de abas | *fade-through* na aba que entra (`TabBranchContainer`), mantendo estado e rolagem |
| Carregando | esqueleto cinza no formato do conteúdo (`SafeSkeleton`), lido como "Carregando"; troca de estado com `SafeStateSwitcher` (esmaecer) |
| Detalhe da notícia | `Hero` da capa só com o detalhe carregado; carregando, só o esqueleto |
| Reel → detalhe | curtir, salvar e compartilhar voam (`Hero`) até o topo do detalhe |
| Pressionar botão / cartão | escala para 98% (`PressScale`); o botão principal também escurece (`primaryPressed`) |
| Ícone ⇄ carregando no botão | `AnimatedSwitcher` |
| Campos, regras e mensagens que aparecem e somem | crescer e esmaecer (`AnimatedReveal`) |
| Abas em pílula | um indicador branco só, que desliza até a aba tocada |
| Barra inferior | o círculo coral e a cor do ícone mudam em `short` |
| Progresso | enche de 0 ao valor ao aparecer; nas Atividades, de novo a cada volta à aba |
| Troca de pergunta da lição | deslizar lateral (`SharedAxisTransition`), voltar no sentido oposto |
| Resultado da resposta | certa com mola, errada com balanço suave; vibração leve no acerto, forte no erro |
| Conclusão | confete e contagem do placar (1200 ms, uma vez) |
| "Ouvir" | halo pulsa 3 vezes (2 s cada) e fica como anel parado enquanto lê |
| Curtir | pulso no coração (1 → 1,3 → 1) e vibração leve; dois toques na imagem do Reel curtem |
| Abertura do app (splash) | "Mancha e onda" em 1,8 s (feature 023): toque `primary` → mancha ondulada cobre a tela → escudo se desenha em `background` e o idoso entra → o vermelho escorre em onda (com uma onda `primaryGlow` 60 ms atrás) → logo `primary`, nome e frase; só toca na abertura a frio. Navega quando a animação **e** a validação terminam; se a validação demorar, a marca respira (1 → 1,035, 2,6 s). Com "Reduzir animações": estado final direto, sem respirar. Exceção ao teto de 400 ms: é animação de assinatura, com tempos próprios em `SplashTimeline`, e a saída continua um esmaecimento |
| Foco em campo | borda de `inputBorder` para tinta (2,5) |

Vibrações passam por `AppHaptics` (`core/utils`): no máximo uma por ação. Na web, respeitar
`prefers-reduced-motion` do mesmo jeito.

---

## 7. Componentes

Medidas em px. Textos de interface vêm do i18n (`assets/translations/`). Use sempre o componente
do `core/widgets` em vez de redesenhar.

### 7.1 Botão (`SafeButton`)

| Tamanho | Altura mínima | Canto | Texto | Largura |
|---|---|---|---|---|
| `large` (padrão) | 60 | 16 | `button` 17/700 | 100% do contêiner |
| `compact` | 48 | 14 | `label` 15/700 | conteúdo |

| Tom | Fundo | Texto | Quando usar |
|---|---|---|---|
| `primary` | `primary` (pressionado `primaryPressed`) | branco | **a** ação principal da tela (uma só) |
| `secondary` | `surfaceStrong` | `textForeground` | ação alternativa ao lado da principal |
| `ghost` | `card` com contorno tinta 1,5 | `textForeground` | ação neutra ("Continuar sem login") |
| `link` | transparente | `textForeground` sublinhado | ação de texto ("Esqueci minha senha") |

- Ícone opcional à esquerda e/ou à direita (22, 10 de espaço). Carregando: o ícone dá lugar a um
  indicador de 20 e o botão fica desativado para toque e leitor de tela. Desativado: opacidade
  45%.
- Cresce em altura quando o rótulo quebra (letra grande).
- **Botão principal no fim da tela** nos formulários (edição de perfil, troca de senha,
  recuperar senha, formulário de contato), desativado até o formulário ficar válido.

### 7.2 Cartão (`SafeCard`) — o padrão único

- **Branco, borda 1 px `border`, canto 20, sombra única, padding 20.** É o cartão de todo o app:
  notícias, Perfil, Configurações, alertas, resultado do Assistente.
- `elevation: flat` = creme (`surface`), sem sombra (ex.: aviso de "Meus contatos" vazio).
- `interactive` + `onTap`: lido como botão e encolhe para 98% ao tocar.
- Quem precisa desenhar a própria caixa (capa no topo, `Hero`, layout próprio) usa
  **`SafeCard.decoration(colors, flat: ...)`**, nunca uma `BoxDecoration` nova.

### 7.3 Campo de texto (`SafeTextField`)

- **Rótulo sempre visível acima** (`label` 15/600, tinta; `destructive` com erro), 8 até a
  caixa. O rótulo visível é o nome do campo no leitor de tela, lido uma vez só.
- Caixa: fundo `card`, canto 16, borda `inputBorder` 1,5 em repouso, **tinta 2,5 no foco**,
  `destructive` 2 com erro. Texto `body` 16 tinta; placeholder `textMutedForeground`.
- Ícone opcional à esquerda (22, `textMutedForeground`) e ação à direita (24; ex.: olho da senha).
- Abaixo: dica (`caption` 14, apoio) ou erro (`caption` 14 `destructive` com ícone de alerta de
  16, para não depender só da cor). Desativado: opacidade 40%.
- **Validação em tempo real**: o erro aparece enquanto a pessoa digita, só nos campos já
  alterados (ou depois de tentar salvar). Telefone usa a máscara `PhoneInputFormatter`
  (`core/utils/phone_format.dart`, aceita 190 e 0800).

### 7.4 Campo de busca

Pílula (`radiusFull`) com lupa à esquerda e "X" para limpar quando há texto; foco com borda tinta
2,5. Espaço no começo é descartado com um aviso curto; buscar com menos de 2 letras também avisa.

### 7.5 Selo (`SafeBadge`)

Pílula de altura mínima 32, padding 12 × 5, texto `caption` 14/700, ícone opcional de 16. Tons
(fundo suave + texto forte, §2.2): `primary` (`primarySoft`/`primaryPressed`), `secondary`,
`success`, `warning`, `destructive`, `neutral` e `onImage` (branco com a sombra única, sobre capa).
Com letra grande, o texto quebra: o selo precisa de largura limitada. No alto contraste, borda
na cor do texto.

### 7.6 Chip de filtro (`SafeChip`)

Pílula creme (`surface`) de altura mínima 48, padding 18 × 8, texto `label` 15 tinta.
**Selecionado: invertido** (fundo `secondary`, texto branco), com a seleção anunciada ao leitor de
tela. Nos filtros do Início, "Todas" primeiro e rolagem horizontal.

### 7.7 Abas em pílula (`SafePillTabs`)

Trilho `surfaceStrong` em pílula (altura mínima 56, padding 5); a aba atual é um indicador
branco com a sombra única que **desliza** (`medium`). Rótulo `label` 15 (700 tinta na atual, 600
apoio nas outras), numa linha só, encolhendo com letra muito grande; cada aba anuncia se está
selecionada. Usada na Central de ajuda (Oficiais / Meus contatos) e no Assistente. O seletor
"Entrar / Criar conta" (`AuthModeSwitch`) tem o mesmo visual.

### 7.8 Cartão de notícia (`NewsCard`)

Caixa do cartão padrão (`SafeCard.decoration`): a **capa ocupa o topo** (`NewsCover`: imagem da
notícia ou ilustração do tema sobre pastel, selo da categoria em `onImage` no canto) e, abaixo,
título (`title3`, até 2 linhas) e fonte. Sinais de "lida" e "salva" em círculos brancos sobre a
capa; desligados (`showSignals: false`) nas listas do Perfil, onde o título da lista já diz isso.
- **Completo**: largura total ("Destaques").
- **Compacto**: grade de 2 colunas com alturas de capa variadas, estilo Pinterest ("Recomendadas",
  "Tudo recente"), na ordem da API lida da esquerda para a direita; vira uma coluna com letra
  acima de 1,3×.

### 7.9 Cartão de Reels (carrossel "Novidades")

Cartão vertical, canto 24, imagem cobrindo, gradiente escuro de baixo para cima, selo e título
brancos; 14 entre cartões, rolagem horizontal. Tocar abre a aba de Reels naquela notícia.

### 7.10 Tela de Reels

Fundo preto, imagem cobrindo com gradiente escuro, texto branco (categorias, título, trecho,
fonte e data). **À direita, só curtir, salvar e compartilhar** (círculos de 40 com branco 20% e
desfoque, área de toque de 48). Trocar de Reel é arrastando; tocar no texto ou na imagem abre a
notícia; dois toques na imagem curtem. Sem barra superior.

### 7.11 Barra superior (`AppTopBar`)

Usada no topo de Início, Atividades e Ajuda; **rola junto com o conteúdo** (só o Início prende
algo no topo: os filtros). Padding 20 nas laterais e 16 em cima e embaixo.

- **Saudação só no Início**: subtítulo (16/500, apoio) na linha dos botões e o título (`display`
  28 tinta) embaixo, inteiro. Nas outras abas, sem subtítulo: o título divide a linha com os
  botões.
- À direita, dois botões redondos de **48** (fundo `input`, ícone 20): `bell` (Alertas, com
  contador de não lidos: círculo `primary` de no mínimo 24, texto branco 14/700, "99+" acima de
  99) e `messageCircle` (Assistente). Os dois pedem conta ao visitante (convite).
- A engrenagem de Configurações **não** fica aqui: só no Perfil (também para o visitante).

### 7.12 Barra inferior (`AppBottomNav`)

Fundo `card`, borda superior 1 px `border`, padding 8. **Cinco abas iguais, só ícones** (24),
nesta ordem: Início (`house`), Atividades (`graduationCap`), Notícias/Reels (`newspaper`), Ajuda
(`lifeBuoy`), Perfil (`user`).

- **Aba ativa: círculo coral de 44** (`primary`, sombra única) com o ícone branco; inativas:
  ícone `textMutedForeground` sem fundo. Círculo e cor mudam em `short`.
- Altura do item 56. O nome de cada aba fica no `Semantics` (botão, selecionado) e no `Tooltip`
  (toque longo). Navegação acessível com rótulo "Navegação principal".
- Não há mais botão central elevado: todas as abas têm o mesmo tamanho.

### 7.13 Splash

Fundo `background`, sem círculo atrás do logo. A animação "Mancha e onda" (§6.3, feature
023) termina com: logo oficial em `primary` (164 px, 96–164 conforme a altura da tela), nome
"Click Seguro" em `display` (`textForeground`), frase "Sua segurança em primeiro lugar" em
`bodyLarge` (`textBody`) e uma onda `primaryGlow`/`primary` no rodapé. Dura 1,8 s e só sai
quando a validação da sessão também terminou (sem mínimo fixo). A abertura nativa (Android e
iOS) mostra só o fundo `background` (`#FFFFFF`), para emendar sem piscar; os ícones do app e
o SVG da marca usam o `primary` da 2.0 (`#E31C3D`).

A posição da marca, do nome e da onda no fim da splash fica em `BrandScene`
(`core/widgets/brand_scene.dart`), e a onda parada é o widget `BrandWave`. O login usa as duas
para começar exatamente onde a splash parou (feature 026).

### 7.14 Onboarding

Três slides com as ilustrações de boas-vindas (`onboarding*`), título, descrição, botão "Ouvir",
indicador de página (ponto ativo alongado em `primary`), "Pular" e o botão `large` "Continuar" /
"Começar".

### 7.15 Login e recuperar senha

Versão A (feature 026), que continua a splash:

- **Cabeçalho centralizado**: marca em `primary` (68), "Bem-vindo ao Click Seguro" em `display`
  e o slogan da splash em `body` (`textBody`).
- **Formulário**: seletor em pílula "Entrar / Criar conta" (§7.7); campos `SafeTextField` com
  rótulo acima; "Esqueci minha senha" como `link`, alinhado à direita; botão `large` com a seta à
  direita; "Continuar sem login" como link coral (`primaryPressed`, 16/600, 48 de altura).
- **Rodapé**: a `BrandWave` fica presa ao pé da tela, e a rolagem termina acima dela.
- **Aceite do cadastro**: abaixo das regras da senha, um cartão com canto 16 e a caixa de 28 com
  canto 8, numa área de 48. Desmarcado, o cartão é `card` com borda `border`; marcado, é
  `primarySoft` com borda `primary`, e a caixa fica `primary` com o visto branco. "Termos de uso"
  e "Política de privacidade" aparecem em `primaryPressed`, negrito e sublinhado.
- **Abertura**: vindo da splash, a marca voa até o cabeçalho e os blocos entram subindo 14 px em
  sequência (1,25 s).

Na recuperação, o botão principal de cada passo fica fixo no fim da tela.

As telas de texto das Configurações (Privacidade, Termos de uso) usam um cartão por assunto
(`SettingsTopicCard`): ícone no círculo `surface`, título 18/800 em `secondary` e texto 16.

### 7.16 Estados comuns

| Estado | Visual |
|---|---|
| Carregando | **Esqueleto cinza, sem ilustração**: `SafeSkeleton` com os widgets da tela e dados de exemplo, ou `SafeLoadingState` com blocos nos formatos `cards`, `list` e `detail`. Lido como "Carregando"; brilho parado com movimento reduzido. Botões que salvam mostram o carregando no lugar do ícone. **Sem aviso de servidor lento** |
| Vazio e erro | `SafeStateLayout` (via `SafeEmptyState` e `SafeErrorState`): ilustração de até 180 (encolhe até 96 em telas curtas), **texto 16 seminegrito** tinta centralizado, dica opcional 16 em apoio e as ações da tela (erro: "Tentar novamente"). Rola com letra grande. Ilustração: `stateEmpty`, `stateError` ou `stateOffline` (falha de conexão) |
| Sem internet | `SafeOfflineBanner`: faixa `secondary` com ícone e texto brancos (`label`), no topo do conteúdo salvo |
| Aviso curto | `SnackBar` flutuante `secondary`, canto 16, texto 16 branco |
| Falha numa chave | O switch dá lugar a um ícone vermelho (`destructive`) de tentar de novo (48), e a mensagem vira subtítulo da linha, sem SnackBar; carregando no lugar da chave enquanto salva |
| Convite para criar conta | folha inferior (§7.18) com título, explicação, botão `large` e "Agora não" |

### 7.17 Botão redondo de ícone (`SafeIconButton`)

Círculo de 48 (padrão) ou 56, nunca menos. Creme (`surface`) na tela; branco com a sombra única
sobre imagem (`onImage`). Ícone tinta 24/26. `semanticLabel` obrigatório e ação de toque exposta
ao leitor de tela. Usado em voltar, ações do detalhe e topo das telas de configuração.

### 7.18 Folha inferior (`SafeSheet`)

Fundo `card`, canto 32 em cima (`bottomSheetTheme`), alça de 44 × 5 em `border`, margens 24.
Feedback da resposta, convite de conta, escolha de foto e idioma.

### 7.19 Progresso

`SafeProgressBar` (10 de altura, trilho `surfaceStrong`, cheio `primary` ou `success`),
`SafeProgressRing` (104, rótulo no centro, painel de atividades) e `SafeSegmentedProgress` (um
segmento por pergunta: respondidas coral, atual coral claro, próximas creme). Enchem ao aparecer.

### 7.20 Avatares

- `PersonAvatar`: foto circular com iniciais de reserva (perfil e contatos), decorativa (o nome
  aparece ao lado).
- `EditableAvatar`: o mesmo círculo (96) com selo coral de câmera no canto; tocar abre a escolha
  da foto; com envio em andamento, carregando por cima e sem toque. Usado na edição de perfil e no
  formulário de contato.

### 7.21 Ouvir (`ListenButton`)

Pílula com borda e ícone coral ("Ouvir"/"Parar"); com `round`, o círculo coral de 56 do cartão
"Ouvir notícia". No detalhe, o cartão tem ainda uma pílula branca de velocidade ("0,5x", "1x",
"2x") que passa para a próxima. Some sem voz no idioma do app.

### 7.22 Cartões das telas

| Cartão | Visual |
|---|---|
| Módulo (Atividades) | capa ilustrada pelo tema do título no topo, título, descrição e barra de progresso; carregando, a capa vira bloco cinza |
| Emergência (Ajuda) | `EmergencyCallCard` no topo da Central de ajuda: cartão `primary` com "Caiu em um golpe?", texto e botão branco "Ligar para 190" |
| Contato | cartão padrão; tocar edita; à direita, ligar e a lixeira (remover, com confirmação); "Adicionar contato" é um botão flutuante no canto de baixo à direita, só em "Meus contatos" |
| Alerta | cartão padrão com a capa da notícia à esquerda (ou a ilustração do tema), "Novo" escrito quando não lido, título e "fonte · hora/data" |
| Linha de configuração | `SettingsScaffold`: voltar redondo, título grande que rola, linhas com ícone em círculo |

---

## 8. Layout

- **Mobile (referência)**: uma coluna, margem lateral 20; conteúdo entre a barra superior (que
  rola) e a barra inferior fixa. Telas empilhadas (detalhe, configurações, formulários) não têm
  barra inferior e respeitam a área da barra de navegação do Android no fim do conteúdo.
- **Web**: até 768 px, igual ao mobile; acima, conteúdo centralizado (~720 px) ou grade de 2–3
  colunas de cartões, com os mesmos 5 destinos, ícones e ordem numa barra lateral ou superior.
- **Imagens**: cobrir (`cover`), carregamento preguiçoso, capa ilustrada quando não há imagem ou
  ela falha.

---

## 9. Acessibilidade (obrigatório)

- **Alvos de toque**: mínimo 48 × 48 (RNF-003): botões, chips, botões redondos, ícone de tentar
  de novo, ações do Reel (área de 48 em volta do círculo de 40).
- **Texto**: corpo 16, mínimo 14 para metadados; nada cortado com letra a 200%.
- **Contraste**: AA para todos os pares de texto e fundo do tema normal (branco sobre `primary`
  `#E31C3D` passa AA também no texto de 16/700, o que a 1.x não conseguia); AAA no alto
  contraste. Conferido no `app_palette_test.dart`.
- **Leitor de tela**: rótulo em todo elemento interativo, inclusive abas da barra inferior (só
  ícone), botões redondos e o olho da senha; seleção anunciada em chips e abas; carregamento
  anunciado (esqueleto e botões carregando); ilustrações e avatares decorativos.
- **Foco visível** na web: borda tinta, como o foco do campo.
- **Cor nunca sozinha**: "Novo" escrito no alerta, ícone no erro do campo, check/X nas respostas,
  ícone cheio no curtido e salvo, círculo na aba ativa.
- **Movimento**: "Reduzir animações" do app ou do aparelho (§6.2); nada pisca mais de 3 vezes por
  segundo.
- **Linguagem simples** (RNF-003); confirmação antes de ações destrutivas (remover contato,
  sair).

---

## 10. Divergências

### 10.1 Figma × app (vale o app)

| Item | Figma | App | Motivo |
|---|---|---|---|
| Escala de texto | corpo 18, títulos 20–32, legenda 15 | corpo 16, títulos 18–28, legenda 14 | Validação da usuária: a de 18 ficou grande demais (FR-003 revisto) |
| Barra inferior | ícone + rótulo, pílula atrás da aba atual | só ícones, círculo coral de 44 na ativa | Validação da usuária (FR-009 revisto) |
| Engrenagem | topo das abas | só no Perfil | Validação da usuária (R15) |
| Topo das abas | saudação em todas | saudação só no Início; Atividades e Ajuda rolam o topo | R16, R18 |
| Assistente | abas de chat e histórico, textos de apoio | histórico num botão do topo, "Nova conversa" em ícone, sem textos fixos | R15, R16 |
| Aviso de servidor lento | previsto (FR-007/FR-018 originais) | removido | R16 |
| Estados vazio/erro | ilustração de 200, título `title1` (plano original) | ilustração até 180, texto 16 seminegrito | Estado único (R19) |
| Perfil | layout novo | layout da feature 012 com os componentes novos | Clarificação da 024 (FR-013) |
| Placar | 72 | 64 | Ajuste da implementação |

### 10.2 O que saiu da 1.x

Paleta `#FE3152`/`#182A4E` e fundo `#FFFDFB`; botão `gradient` e tamanho `pill`;
`shadow-sm`/`shadow-md`/`shadow-primary`; Montserrat (nunca empacotada); escala 30/24/18/16/14/12;
botão central elevado da barra inferior; indicador circular girando nos carregamentos;
`SafeStateIllustration` pintado à mão (feature 021); `SlowRequestNotice`; botões de navegação e
de abrir a fonte na coluna do Reel.

---

## 11. Como usar este documento

- **Versão web**: copie os tokens das §2–§4 como variáveis CSS (ou tema do Tailwind); carregue
  Inter (400–800) e Lucide; implemente os componentes da §7 com os mesmos nomes (`SafeButton`,
  `SafeCard`, ...) para comparar lado a lado com o app.
- **App Flutter**: componente novo é combinado antes, feito em commit isolado e adicionado ao
  style guide e **a este documento**. Cor por `context.colors`, texto por `AppTypography`, canto
  e espaço por `AppSpacing`, movimento por `AppMotion.of(context)`: sem números mágicos.
- **Mudança de token**: altere primeiro o app (`lib/core/theme/`), depois este documento (com
  nova versão abaixo) e avise quem mantém a versão web.

## Histórico de versões

- **2.1.0 (2026-11-23)**: §7.13 e §7.15 com a versão A do login (feature 026): cabeçalho
  centralizado, `BrandWave` no rodapé, link do visitante, aceite dos termos e a abertura que
  continua a splash; `BrandScene` como fonte única da posição da marca e da onda;
  `SettingsTopicCard` nas telas de texto das Configurações.

- **2.0.0 (2026-11-15)**: MAJOR, redesign visual 2.0 (feature 024, validado pela usuária). Nome
  "Click Seguro" no lugar de "SafeNews". Paleta nova (coral `#E31C3D`, tinta `#1B2440`, creme,
  pares suave + forte, pastéis) e alto contraste estendido; Inter empacotada com a escala revista
  (corpo 16, títulos 18–28, mínimo 14); cantos 12/16/20/24/32/pílula e sombra única; cartão
  padrão único com `SafeCard.decoration`; componentes novos (`SafeIconButton`, `SafeChip`,
  `SafePillTabs`, `SafeSheet`, progresso, `SafeStateLayout`, `EditableAvatar`) e ilustrações SVG
  com recoloração no alto contraste; barra inferior só com ícones e aba ativa em círculo coral de
  44; topo com saudação só no Início e engrenagem só no Perfil; carregando só com esqueleto cinza,
  vazio/erro com texto 16 seminegrito e ilustração até 180, sem aviso de servidor lento; §6
  atualizada com os padrões do redesign. Removidos gradiente, sombras múltiplas, Montserrat e o
  botão central.
- **1.2.0 (2026-11-08)**: §6 Movimento reescrita com os tokens de `AppMotion`, a opção
  "Reduzir animações" e os padrões de transição, esqueleto e microinterações (feature 022).
- **1.1.1 (2026-10-09)**: contador do sino com círculo mínimo de 24 px e texto 14/700, no lugar
  de 20 px e 10/700 (feature 011, RNF-003).
- **1.1.0 (2026-10-08)**: alto contraste (`AppPalette`), token `input-border`, regra de leitura
  das cores por `context.colors` e de rolagem com letra grande (feature 009).
- **1.0.1 (2026-10-04)**: barra superior com botões de 48 px e subtítulo de 14 px; faixa de sem
  internet com texto de 16 px (definidos na feature 005).
- **1.0.0 (2026-10-04)**: primeira versão, extraída do app Flutter e do wireframe para servir
  de referência à versão web do SafeNews.
