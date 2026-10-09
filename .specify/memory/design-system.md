# SafeNews — Design System

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 1.1.0

**Criado em**: 2026-10-04

**Para quem**: quem vai reproduzir o visual do SafeNews em outra plataforma (em especial a
**versão web**), e quem cria telas novas no app Flutter.

**Fontes**:
- **Implementação de referência (canônica)**: o app Flutter, em
  `click_seguro_app/lib/core/theme/` (`app_colors.dart`, `app_spacing.dart`, `app_theme.dart`) e
  `click_seguro_app/lib/core/widgets/` (`safe_button.dart`, `safe_card.dart`,
  `safe_text_field.dart`, `safe_badge.dart`). É o que o usuário vê no celular.
- **Origem do visual**: o wireframe em `wireframe/` (React + Tailwind v4 + shadcn/ui, estilo
  "new-york"). Tokens em `wireframe/src/styles.css`; guia em
  `wireframe/src/components/screens/StyleGuideScreen.tsx`; telas em
  `wireframe/src/components/screens/`.
- **Regras de produto que afetam o visual**: RNF-003 (usabilidade para idosos) e RNF-004
  (acessibilidade) da [especificação](specification.md).

Quando o wireframe e o app divergem, **vale o app** (ver [§10](#10-divergências-entre-wireframe-e-app)).

---

## 1. Princípios

1. **Feito para pessoas idosas.** Textos grandes, alvos de toque grandes, linguagem simples,
   uma ação principal por tela. Na dúvida, maior e mais espaçado.
2. **Quente e confiável.** Fundo branco levemente quente, vermelho-coral como cor de ação e
   azul-marinho para títulos. Cantos bem arredondados e sombras suaves ("Airbnb-soft").
3. **Vermelho = ação, azul = leitura.** O `primary` marca o que se toca (botões, aba ativa,
   foco). O `secondary` marca o que se lê com destaque (títulos, chips selecionados).
4. **Conteúdo primeiro.** Notícias em cartões com imagem; Reels em tela escura com vídeo de
   fundo.
5. **Acessível por padrão.** Contraste WCAG 2.1 AA, rótulo para leitor de tela em todo elemento
   interativo e nada que dependa só de cor.

---

## 2. Cores

### 2.1 Tokens

Nomes no padrão do shadcn/Tailwind (use-os como variáveis CSS: `--primary`, `--muted-foreground`
etc.). A coluna "Flutter" é a constante em `AppColors`. Nos widgets, leia a cor do tema em uso
com `context.colors.<token>` (`AppPalette`, §2.4), nunca `AppColors` direto: assim o alto
contraste chega à tela.

| Token | Hex | Flutter | Uso |
|---|---|---|---|
| `primary` | `#FE3152` | `primary` | Botões principais, aba ativa, foco, links de ação ("Esqueci minha senha"), selo "Novo", ícone da marca |
| `primary-foreground` | `#FFFFFF` | `textPrimaryForeground` | Texto e ícone sobre `primary`, `secondary` e fundos escuros |
| `primary-glow` | `#FF6A7A` | `primaryGlow` | Fim do gradiente do botão "gradient" (`primary → primary-glow`) |
| `secondary` | `#182A4E` | `secondary` | Títulos, chip/filtro selecionado, botão secundário, texto do botão "ghost" |
| `secondary-foreground` | `#FFFFFF` | `textPrimaryForeground` | Texto sobre `secondary` |
| `background` | `#FFFDFB` | `background` | Fundo das telas (branco quente) e dos campos de texto |
| `foreground` | `#121932` | `textForeground` | Texto corrido principal |
| `card` | `#FFFFFF` | `card` | Fundo de cartões, convites e menus |
| `muted` | `#EFF2F5` | — (use `input`) | Fundo de controles neutros: filtros não selecionados, botões redondos da barra superior, seletor "Entrar/Criar conta" |
| `muted-foreground` | `#596475` | `textMutedForeground` | Texto secundário: subtítulos, legendas, metadados, ícones inativos, placeholder |
| `border` | `#E6E6EA` | `border` | Bordas de cartões, divisórias, borda da barra inferior |
| `input` | `#EDEDF1` | `input` | Borda de campo de texto em repouso |
| `destructive` | `#E5484D` | `destructive` | Erros de campo, ações destrutivas |
| `success` | `#10B981` | `success` | Selo "Seguro", "lida", resposta certa |
| `warning` | `#F59E0B` | `warning` | Selo "Atenção" |
| `accent` | `#DEE9F5` | — | Fundo de destaque leve (pouco usado) |
| `ring` | = `primary` | — | Anel de foco (teclado/web) |

### 2.2 Tons translúcidos (padrão "10%")

Selos, chips de categoria e fundos de ícone usam a **mesma cor do texto com 10% de opacidade**
no fundo:

| Uso | Fundo | Texto/ícone |
|---|---|---|
| Categoria "Golpe", selo primary, fundo de ícone em cartão | `primary` 10% | `primary` |
| Categoria "Fake news", selo secondary | `secondary` 10% | `secondary` |
| Selo "Seguro" | `success` 10% | `success` (no wireframe, `#059669`) |
| Selo "Atenção" | `warning` 10% | `warning` (no wireframe, `#D97706`) |
| Selo de erro | `destructive` 10% | `destructive` |

Outros usos de transparência: sombra do botão com sombra = `primary` 40%; anel da aba central
ativa = `primary` 30%; campo de busca = `muted` 40%; Reels = branco 20% com desfoque nos botões
sobre o vídeo.

### 2.3 Gradientes

| Nome | Definição | Onde |
|---|---|---|
| Botão "gradient" | linear, da esquerda para a direita, `primary → primary-glow` | Ações de destaque ("Premium") |
| Cartão de Reels (carrossel do Início) | de baixo para cima: preto 90% → preto 40% → preto 10% | Legibilidade do título sobre a imagem |
| Tela de Reels | de cima para baixo: preto 40% → preto 10% → preto | Legibilidade sobre o vídeo |

### 2.4 Tema escuro e alto contraste

- **Tema escuro**: não faz parte do produto. O bloco `.dark` do `styles.css` é o padrão do
  shadcn, sem as cores da marca: **não use**.
- **Alto contraste** (RF-039, feature 009): `AppPalette.highContrast` /
  `AppTheme.highContrastTheme`. Mesmos tokens, com contraste WCAG AAA medido sobre branco:

  | Token | Alto contraste | Razão |
  |---|---|---|
  | `foreground` | `#000000` | 21:1 |
  | `muted-foreground` | `#333333` | 12,6:1 |
  | `primary`, `primary-glow`, `destructive` | `#9E0019` | 8,5:1 (e branco sobre ele) |
  | `secondary` | `#0B1A3A` | 17,2:1 |
  | `background`, `card` | `#FFFFFF` | — |
  | `input` (preenchimento) | `#F2F2F2` | texto preto 18,8:1 |
  | `input-border` (contorno do campo) | `#000000` | 21:1 (no tema normal = `input`) |
  | `border` | `#000000` | 21:1 |
  | `success` | `#005A3C` | 8,3:1 |
  | `warning` | `#6E4200` | 8,6:1 |

  O gradiente vira cor sólida e as sombras somem (a borda preta separa os cartões). Na web,
  o mesmo conjunto como uma classe `.high-contrast` com as variáveis acima.
- **Tamanho da letra** (RF-038): 100/115/130/150% multiplicados pela escala do sistema, com teto
  de 200%. Componentes que podem passar da altura da tela (folhas, diálogos) MUST rolar.

---

## 3. Tipografia

- **Família**: **Montserrat** (Google Fonts), pesos 400, 500, 600, 700 e 800. Fallback:
  `ui-sans-serif, system-ui, sans-serif`. No wireframe também carregam 200 e 300, mas não são
  usados.
- **Títulos** ("display"): Montserrat com `letter-spacing: -0.02em`.
- **Suavização**: `-webkit-font-smoothing: antialiased`.

### 3.1 Escala

| Estilo (Flutter `textTheme`) | Tamanho | Peso | Cor padrão | Tracking | Uso |
|---|---|---|---|---|---|
| `displayLarge` | 30 px | 700 | `foreground` | −0.6 px | Título de tela grande (nome do app no splash, títulos do onboarding) |
| `titleLarge` | 24 px | 700 | `foreground` | −0.48 px | Título da barra superior, título de tela ("Bem-vindo ao SafeNews") |
| `titleMedium` | 18 px | 700 | `foreground` | 0 | Título de seção ("Novidades", "Tudo recente") e de cartão grande |
| `bodyLarge` | 16 px | 400 | `foreground` | 0 | Texto corrido, campos de texto, botão grande |
| `bodyMedium` | 14 px | 400 | `muted-foreground` | 0 | Texto de apoio, resumo de notícia, botão compacto |
| `bodySmall` | 12 px | 400 | `muted-foreground` | 0 | Legendas, metadados (fonte, data), rótulo de campo |

Equivalência com o Tailwind: 30 = `text-3xl`, 24 = `text-2xl`, 18 = `text-lg`, 16 =
`text-base`, 14 = `text-sm`, 12 = `text-xs`.

Na prática, os títulos das telas usam a cor `secondary` (azul-marinho), e não `foreground`.

### 3.2 Regras

- **Texto que a pessoa precisa ler para usar o app MUST ter no mínimo 16 px** (RNF-003). Os
  tamanhos 14 px e 12 px ficam para informação complementar (metadados, legendas, selos).
- Os tamanhos de 10–11 px do wireframe (rótulos das abas, selos "Novo") são o mínimo absoluto e
  só valem para texto curto e redundante (com ícone ao lado).
- A interface MUST continuar funcionando com a fonte do sistema/navegador aumentada (até 200%):
  textos quebram linha em vez de serem cortados.
- Títulos de notícia: no máximo 2 linhas na lista (`line-clamp-2`); resumo, 2 linhas; texto do
  Reels, 4 linhas.

---

## 4. Espaçamento, raios e sombras

### 4.1 Espaçamento (escala de 4 px)

| Token | px | Uso comum |
|---|---|---|
| `s1` | 4 | Entre rótulo e campo, entre ícone e texto de selo |
| `s2` | 8 | Entre ícone e rótulo de botão, entre chips |
| `s3` | 12 | Entre cartões numa lista, padding de cartão compacto |
| `s4` | 16 | Padding de cartão de notícia, padding horizontal de campo |
| `s5` | 20 | **Margem lateral das telas**, padding de cartão padrão |
| `s6` | 24 | Margem lateral do login/onboarding, espaço entre seções |
| `s7` | 32 | Espaço antes de títulos grandes, margens do onboarding |

### 4.2 Raios

O wireframe deriva os raios de `--radius = 14px` (Tailwind v4: `xl` = 18, `2xl` = 22,
`3xl` = 26). O app arredondou para valores redondos; **use os do app**.

| Nome | App (vale) | Wireframe | Uso |
|---|---|---|---|
| campo | 16 | `rounded-2xl` (22) | Campos de texto, imagem do cartão compacto, quadrado de ícone em cartão, menus de sugestão, avisos |
| `radius2xl` | 20 | `rounded-2xl` (22) | Cartão do tema Material (`cardTheme`) |
| `radius3xl` | 24 | `rounded-3xl` (26) | **Cartões** (SafeCard, NewsCard, cartão de Reels), ícone do onboarding, topo do convite |
| ícone grande do onboarding | 24 | `rounded-[2.5rem]` (40) | Quadro do ícone de cada slide |
| `radiusFull` | 999 | `rounded-full` | **Botões**, chips, selos, botões de ícone, campo de busca, seletor de modo |

### 4.3 Sombras

| Token | Valor | Uso |
|---|---|---|
| `shadow-sm` | `0 1px 2px rgba(0,0,0,.04), 0 2px 6px rgba(0,0,0,.04)` | Cartões em repouso |
| `shadow-md` | `0 4px 12px rgba(0,0,0,.06)` | Cartão interativo, cartões de Reels |
| `shadow-primary` | `0 10px 24px rgba(254,49,82,.40)` | Botão com sombra, aba central "Notícias" |
| `shadow-lg` | sombra padrão do Tailwind | Menu de sugestões da busca |

---

## 5. Ícones

- **Biblioteca**: [Lucide](https://lucide.dev) (`lucide-react` no web, `lucide_icons_flutter` no
  app). Não misturar com outra biblioteca.
- **Tamanhos**: 16 px (dentro de botões e selos), 20 px (barra superior, campos, abas), 24 px
  (marca no login), 28 px (aba central), 40–56 px (ilustração do onboarding), 64–80 px (splash).
- **Traço**: 1.8 inativo, 2.2–2.4 ativo/destaque.
- **Ícones de marca e de tela**:

| Onde | Ícone |
|---|---|
| Marca (splash, login, 1º slide) | `Shield` |
| Abas | `Home` (Início), `GraduationCap` (Atividades), `Newspaper` (Notícias/Reels), `LifeBuoy` (Ajuda), `User` (Perfil) |
| Barra superior | `Bell` (Notificações), `Settings` (Configurações) |
| Onboarding | `Shield`, `Newspaper`, `GraduationCap` |
| Cartão de notícia | `Heart` (curtir), `Bookmark` (salvar), `CircleCheck` (lida) |
| Busca | `Search`, `X` (limpar) |
| Carrossel de Reels | `Play`, `Sparkles` |
| Botões de avanço | `ChevronRight` |

- Botão só com ícone MUST ter rótulo acessível (`aria-label` no web, `Semantics`/`tooltip` no
  app).

---

## 6. Movimento

| Interação | Efeito | Duração |
|---|---|---|
| Pressionar botão | escala para 95% | 200 ms, ease-out |
| Pressionar cartão interativo | escala para 99% | 200 ms, ease-out |
| Hover no botão (web) | `primary` 90% (ou opacidade 90% no gradiente) | transição padrão |
| Foco em campo | borda de `input` para `primary` | transição padrão |
| Troca de slide do onboarding | deslizar | 300 ms, ease-out |
| Seletor "Entrar / Criar conta" | uma pílula branca desliza até a opção tocada | transição padrão |
| Indicador de página | o ponto ativo alonga (8 → 32 px) | transição padrão |

Respeitar "reduzir movimento" do sistema (`prefers-reduced-motion` no web): sem escalas nem
deslizes, só troca de estado.

---

## 7. Componentes

Medidas em px. "Ação" = `primary`; textos de interface vêm do i18n (`assets/translations/`).

### 7.1 Botão (`SafeButton`)

Sempre `rounded-full`, texto 700, ícone opcional à esquerda e/ou à direita (16 px, 8 px de
espaço).

| Tamanho | Padding | Fonte | Largura |
|---|---|---|---|
| `large` | 16 vertical | 16 px | 100% do contêiner |
| `compact` | 20 × 10 | 14 px | conteúdo |
| `pill` | 14 × 8 | 12 px | conteúdo |

| Tom | Fundo | Texto |
|---|---|---|
| `primary` (padrão) | `primary` | branco |
| `gradient` | `primary → primary-glow` | branco |
| `secondary` | `secondary` | branco |
| `ghost` | transparente, borda 1 px `border` | `secondary` (ex.: "Continuar sem login") |

Estados: desabilitado = opacidade 40% e sem toque; carregando = indicador circular de 16 px no
lugar do ícone; sombra opcional (`shadow-primary`). Com fonte grande, o rótulo quebra linha.

**Alvo de toque**: mínimo 48 × 48 px (RNF-003). Os tamanhos `compact` e `pill` MUST ter área de
toque de 48 px mesmo quando o desenho é menor.

### 7.2 Cartão (`SafeCard`)

- Fundo `card`, borda 1 px `border`, raio 24, padding 20.
- Elevação: `flat` (sem sombra), `sm` (padrão), `md`.
- Interativo: sombra `md` e escala 99% ao pressionar.
- Padrão de conteúdo: ícone em quadrado 44 × 44, raio 16, fundo `primary` 10%, ícone `primary`;
  título 14/700 `secondary`; descrição 12 `muted-foreground`.

### 7.3 Campo de texto (`SafeTextField`)

- Rótulo acima: 12/600, `secondary` (`destructive` com erro), 4 px até o campo.
- Caixa: fundo `background`, raio 16, borda **2 px**: `input` em repouso, `primary` no foco,
  `destructive` com erro. Padding 16 × 12. Texto 16 `foreground`; placeholder `muted-foreground`.
- Ícone opcional à esquerda (20 px, `muted-foreground`) e ação à direita (ex.: olho para
  mostrar/ocultar senha, com rótulo "Mostrar senha"/"Ocultar senha").
- Mensagem de erro abaixo, 12 px, `destructive`, aparece quando a pessoa sai do campo.
- Variante do login (wireframe): caixa `muted` 40%, borda 1 px `border`, raio 16, padding
  16 × 14, ícone à esquerda.

### 7.4 Campo de busca

Raio `full`, borda 1 px `border`, fundo `muted` 40%, padding 14 vertical, 48 à esquerda (ícone
`Search` 20 px) e 40 à direita (botão `X` redondo `muted` para limpar). Foco: borda `primary`.
Sugestões: menu `card`, raio 16, borda `border`, `shadow-lg`, itens 16 × 12.

### 7.5 Selo (`SafeBadge`)

Raio `full`, padding 12 × 4, texto 12/700 (wireframe: 11/700), fundo = cor do texto 10%
([§2.2](#22-tons-translúcidos-padrão-10)). Tons: `primary`, `secondary`, `success`, `warning`,
`destructive`, `neutral`. Ícone opcional de 12 px.

Variantes especiais:
- **"Novo"** (sobre a imagem do cartão): fundo `primary` sólido, texto branco 10/700, caixa alta.
- **"Reels"** (carrossel): fundo `primary` sólido, texto branco 10/800, caixa alta, ícone
  `Sparkles`.

### 7.6 Chip de filtro

Raio `full`, padding 16 × 8, texto 14/600. Selecionado: fundo `secondary`, texto branco. Não
selecionado: fundo `muted`, texto `muted-foreground`. Rolagem horizontal sem barra visível, 8 px
entre chips.

### 7.7 Seletor de modo ("Entrar" / "Criar conta")

Trilho `muted`, raio `full`, padding 4. Uma pílula branca com `shadow-sm` desliza até a opção
tocada; texto da opção ativa `secondary` 600, da inativa `muted-foreground`.

### 7.8 Cartão de notícia (`NewsCard`)

Fundo `card`, raio 24, `shadow-sm`, escala 99% ao tocar.

- **Completo**: imagem no topo (altura 176, cobre a largura), selo "Novo" no canto (12, 12) se
  não lida; corpo com padding 16: linha de categoria (selo de categoria 10/600 + subcategoria
  11 `muted-foreground`), título 16/600 `secondary` (2 linhas), resumo 14 `muted-foreground`
  (2 linhas), rodapé com a fonte (11 `muted-foreground`) e as ações.
- **Compacto** (listas): linha com imagem 80 × 80, raio 16, à esquerda e o texto à direita
  (padding 12, espaço 12); título 14/600 (2 linhas), sem resumo.
- **Ações**: botões redondos `Heart` e `Bookmark` (ícone 16). Curtido = coração preenchido
  `primary`; salvo = marcador preenchido `secondary`; lida = `CircleCheck` `success`. Área de
  toque de 48 px.

### 7.9 Cartão de Reels (carrossel do Início)

Proporção 9:16, largura 160 (180 em telas maiores), raio 24, `shadow-md`, imagem cobrindo,
gradiente escuro de baixo para cima, botão `Play` em círculo 32 (preto 40% com desfoque, borda
branca 20%) no canto superior direito, selo "Reels" no superior esquerdo, título 12/700 branco
(3 linhas) e fonte 10 branco 75% no rodapé. Carrossel com rolagem horizontal e encaixe
("snap"), 14 px entre cartões.

### 7.10 Tela de Reels

Fundo preto, vídeo/imagem cobrindo a tela com opacidade 70% e gradiente escuro; texto branco.
Botões redondos de 40 px (branco 20% + desfoque) para navegação e ações, empilhados à direita;
título 24/700 (até 4 linhas no resumo 14, opacidade 90%); botão "Ler notícia completa" branco,
raio `full`, texto `secondary` 14/600. **Sem barra superior**; a barra inferior continua visível
(é a aba central).

### 7.11 Barra superior (`TopBar`)

Padding 20 nas laterais, 24 em cima, 12 embaixo.

- À esquerda: subtítulo 14/500 `muted-foreground` (wireframe: 12) ("Olá, {nome}" conectado, "Bem-vindo"
  visitante, ou um texto da tela) e título 24/700 `secondary`.
- À direita: dois botões redondos de **48 px** (o wireframe usa 44; o app aumenta para o mínimo
  de toque do RNF-003), fundo `muted`, ícone 20 `secondary`: `Bell`
  (Notificações) com contador de não lidas (círculo `primary` mínimo 20 px, texto branco 10/700,
  no canto superior direito) e `Settings` (Configurações).
- Aparece em Início ("Notícias seguras"), Atividades ("Atividades") e Ajuda ("Central de
  ajuda"). **Não** aparece em Notícias (Reels) nem em Perfil.

### 7.12 Barra inferior (`BottomNav`)

Fundo `background` 95% com desfoque, borda superior 1 px `border`, padding 8 nas laterais, 8 em
cima e 12 embaixo. Cinco abas de mesma largura, nesta ordem:

| # | Rótulo | Ícone |
|---|---|---|
| 1 | Início | `Home` |
| 2 | Atividades | `GraduationCap` |
| 3 | **Notícias** (Reels) | `Newspaper` — botão central |
| 4 | Ajuda | `LifeBuoy` |
| 5 | Perfil | `User` |

- Aba comum: ícone 20 sobre o rótulo (11/500), 4 px entre eles, raio 18. Ativa: `primary`,
  traço 2.4. Inativa: `muted-foreground`, traço 1.8.
- **Aba central**: círculo de 64 px, fundo `primary`, ícone branco 28 (traço 2.2),
  `shadow-primary`, sobe 32 px acima da barra, sem rótulo visível (mas com rótulo acessível
  "Notícias"). Ativa: anel de 4 px `primary` 30%.
- Navegação acessível: `nav` com rótulo "Navegação principal".

### 7.13 Splash

Fundo `primary`; centralizados: escudo (`Shield`) branco de 64–80 px, nome "SafeNews" 30/700
branco e a frase "Sua segurança em primeiro lugar" 14 branco 80%. Mínimo de 2 s na tela.

### 7.14 Onboarding

Botão "Pular" no topo à direita (texto 14/600 `muted-foreground`). Centro: ícone num quadrado
de 96–128 px com raio 24–40 (fundos: `primary`, `secondary`, cinza-azulado), título 30/700
`secondary`, descrição 16 `muted-foreground` (largura máxima ~320). Rodapé: indicador de página
(pontos de 8 px, ativo alongado 32 px `primary`, inativos `muted`) e botão `large` "Continuar"
/ "Começar" com `ChevronRight`.

### 7.15 Login

Margens 24, topo 40. Cabeçalho: quadrado 48 `primary` raio 16 com `Shield` branco + "SafeNews"
24/700 `secondary`. Seletor de modo ([§7.7](#77-seletor-de-modo-entrar--criar-conta)), campos
com ícone ([§7.3](#73-campo-de-texto-safetextfield)), link "Esqueci minha senha" alinhado à
direita (12/600 `primary`), botão `large`, divisória "ou" (linha `border` + texto 12
`muted-foreground`) e "Continuar sem login" (botão `ghost` grande).

### 7.16 Estados comuns (definidos na feature 005; o wireframe não os desenha)

| Estado | Visual |
|---|---|
| Carregando | Indicador circular `primary` centralizado e texto opcional 16 `muted-foreground` |
| Erro | Mensagem 16 `foreground` centralizada e botão `compact` "Tentar novamente" |
| Vazio | Ícone 40 `muted-foreground`, mensagem 16 ("Nada por aqui ainda.") e ação opcional; na lista do Início, caixa `muted` 40% raio 16 com "Nenhuma notícia encontrada." |
| Sem internet | Faixa no topo do conteúdo, fundo `warning` 10%, texto 16 `foreground`: "Você está sem internet. Mostrando o conteúdo salvo." |
| Convite para criar conta | Painel `card` vindo de baixo, raio 24 em cima: título 18/700 `secondary`, explicação 16, botão `large` "Entrar ou criar conta" e botão `ghost` "Agora não" |

---

## 8. Layout

- **Mobile (referência)**: uma coluna; margem lateral 20 (24 no login/onboarding); conteúdo
  rola entre a barra superior fixa e a barra inferior fixa.
- **Web**: o wireframe é mobile-first (simula um celular). Sugestão para a versão web, sem
  mudar a identidade:
  - até 768 px: igual ao mobile, com a barra inferior;
  - acima de 768 px: conteúdo centralizado com largura máxima de ~720 px para leitura (feed em
    uma coluna) ou grade de 2–3 colunas de cartões; a navegação pode virar barra lateral ou
    barra superior com os mesmos 5 destinos, ícones e ordem.
- **Imagens**: `object-fit: cover`; carregamento preguiçoso; texto alternativo vazio quando a
  imagem é decorativa (o título já descreve a notícia).

---

## 9. Acessibilidade (obrigatório)

- **Alvos de toque**: mínimo 48 × 48 px (RNF-003).
- **Texto**: mínimo 16 px para o que precisa ser lido; nada cortado com fonte a 200%.
- **Contraste**: WCAG 2.1 AA.
  - Texto `muted-foreground` (`#596475`) sobre `background`: cerca de 6,0:1, passa AA.
  - `secondary` (`#182A4E`) sobre `background`: passa AAA.
  - Branco sobre `primary` (`#FE3152`): cerca de 3,6:1. Passa AA **só para texto grande**
    (≥ 18,7 px em negrito ou ≥ 24 px). Os botões de 16 px/700 ficam abaixo de 4,5:1: é uma
    limitação conhecida da cor da marca, a resolver no tema de alto contraste (F0.6/B9). Não use
    texto branco menor que 16 px/700 sobre `primary`.
- **Leitor de tela**: rótulo em todo elemento interativo, inclusive botões só com ícone, a aba
  central e o olho da senha; estados de carregando anunciados.
- **Foco visível** no web: anel `ring` (= `primary`).
- **Cor nunca sozinha**: "lida", "curtido", erro e aba ativa também mudam ícone, preenchimento
  ou texto.
- **Movimento**: respeitar "reduzir movimento".
- **Linguagem simples** em todos os textos (RNF-003); confirmação antes de ações destrutivas.

---

## 10. Divergências entre wireframe e app

Valores em que o app Flutter (canônico) difere do wireframe. Na versão web, use a coluna "App".

| Item | Wireframe | App (vale) | Observação |
|---|---|---|---|
| `primary` | `#FF2950` no comentário do CSS; `oklch(0.65 0.235 19)` = `#FE3152` | `#FE3152` | Mesmo valor; o comentário do CSS está desatualizado |
| `secondary` | `#192E51` no comentário; `oklch(0.29 0.07 263)` = `#182A4E` | `#182A4E` | Idem |
| `primary-glow` | `oklch(0.75 0.2 30)` = `#FF725C` (mais alaranjado) | `#FF6A7A` (mais rosado) | Gradiente do app é mais rosado |
| `destructive` | `oklch(0.6 0.25 25)` = `#F20024` | `#E5484D` | App menos saturado |
| `border` | `oklch(0.9 0.01 255)` = `#DADEE5` | `#E6E6EA` | App mais claro |
| `input` | `oklch(0.93 0.01 255)` = `#E3E8EF` | `#EDEDF1` | App mais claro |
| `muted`, `accent` | `#EFF2F5`, `#DEE9F5` | não têm constante | Use os do wireframe |
| Escala tipográfica | Style guide do wireframe: 28/18/14 | 30/24/18/16/14/12 | O app segue as classes Tailwind usadas nas telas (`text-3xl` etc.) |
| Nome no splash | "SafeNews" | "SafeNews" (desde a feature 004; antes "Click Seguro") | |
| Barra inferior | 5 itens, Reels no centro | 5 abas, Reels como aba central (feature 005) | Igual |
| Cor do 3º ícone do onboarding | `#607698` | `#596475` (`muted-foreground`) | Diferença pequena, sem token novo |
| Pulsação do escudo no splash | sim | não | Evita animação contínua para o público idoso |
| Botões da barra superior | 44 px | 48 px | Mínimo de toque do RNF-003 |
| Subtítulo da barra superior | 12 px | 14 px | Legibilidade para o público idoso |

---

## 11. Como usar este documento

- **Versão web**: copie os tokens das §2–§4 como variáveis CSS (ou tema do Tailwind) usando a
  coluna "App"/Hex; carregue Montserrat (400–800) e Lucide; implemente os componentes da §7 com
  os mesmos nomes (`SafeButton`, `SafeCard`, ...) para facilitar a comparação lado a lado com o
  app.
- **App Flutter**: componente novo no design system é combinado antes, feito em commit isolado e
  adicionado ao style guide (plano do produto §6) e **a este documento**.
- **Mudança de token**: altere primeiro o app (`lib/core/theme/`), depois este documento (com
  nova versão abaixo) e avise quem mantém a versão web.

## Histórico de versões

- **1.1.0 (2026-10-08)**: alto contraste (`AppPalette`), token `input-border`, regra de leitura
  das cores por `context.colors` e de rolagem com letra grande (feature 009).
- **1.0.1 (2026-10-04)**: barra superior com botões de 48 px e subtítulo de 14 px; faixa de sem
  internet com texto de 16 px (definidos na feature 005).
- **1.0.0 (2026-10-04)**: primeira versão, extraída do app Flutter e do wireframe para servir
  de referência à versão web do SafeNews.
