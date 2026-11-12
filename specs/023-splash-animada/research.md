# Research — 023 Splash animada e logo na paleta do app

Referência visual: protótipo "V4-2 — Mancha e onda" no canvas
https://claude.ai/artifact/8jSCUzk27TCjAExjTCE5CX (`project/V4-2-Mancha-e-onda.dc.html`).

## R1. Duração e linha do tempo (≤ 1,8 s)

**Decision**: comprimir a V4-2 (≈ 2,7 s no protótipo) para **1 800 ms** com um único
`AnimationController` e `Interval`s, mantendo a ordem das fases:

| Fase | Protótipo (ms) | App (ms) | Curva |
|---|---|---|---|
| Toque aparece e pressiona (escala 0,4 → 1 → 0,78 → 1) | 0–620 | 0–400 | `standard` |
| Mancha cresce ondulando até cobrir a tela | 364–1 000 | 200–700 | `enter` |
| Ponto claro pousa no topo do escudo | 780–1 080 | 500–700 | `emphasis` |
| Escudo se desenha pelas duas laterais | 880–1 500 | 560–1 000 | `standard` |
| Idoso sobe para dentro do escudo | 1 320–1 770 | 850–1 150 | `enter` |
| Vermelho escorre em onda para baixo (com onda `primary-glow` 60 ms atrás) | 1 750–2 400 | 1 100–1 550 | `standard` |
| Título sobe e aparece | 2 200–2 550 | 1 400–1 650 | `enter` |
| Frase sobe e aparece | 2 350–2 700 | 1 550–1 800 | `enter` |
| Respiração do logo (se a validação demorar) | 3 200+, 2 600 ms ida e volta | após 1 800, 2 600 ms ida e volta, escala 1 → 1,035 | `easeInOut` |

**Rationale**: o guia de splash do Android recomenda ícone animado curto e splash que não atrase
o uso; 1,8 s fica abaixo do mínimo fixo atual (2 s), então a abertura fica mais rápida que hoje
mesmo com animação. Um controlador só garante que nenhuma fase passe do total.

**Alternatives considered**: manter 2,7 s (rejeitado: mais lento que hoje, contra o padrão de
mercado); ≤ 1 s (rejeitado: as 5 fases ficariam corridas demais para o público idoso).

## R2. Cor do logo "por baixo da onda"

**Decision**: em vez do crossfade do protótipo (claro → vermelho em 140 ms), desenhar o logo duas
vezes: em `background` recortado pela área vermelha e em `primary` recortado pela área já
revelada. A borda da onda passa pelo logo e a cor troca exatamente onde ela passa.

**Rationale**: é o que o protótipo tenta imitar; com recorte não há instante em que o logo some
(risco apontado no protótipo) e não depende de acertar o tempo do crossfade.

**Alternatives considered**: crossfade por cor (rejeitado: some parcialmente se a onda e o
crossfade desalinham).

## R3. Desenho da marca em código

**Decision**: um `BrandMarkPainter` em `core/widgets/` com os paths oficiais transcritos do SVG
(escudo, silhueta, máscara de detalhes) em coordenadas do `viewBox` `88 440 444 492`, com
parâmetros de cor, progresso do traço (0–1, duas metades a partir do topo) e progresso do idoso.
O `AppLogo` passa a usar esse painter com `context.colors.primary` em vez do PNG.

**Rationale**: a splash precisa animar o traço e a cor, o que um PNG não permite; usar o mesmo
painter no `AppLogo` faz o logo seguir o alto contraste (FR-011) e evita duas fontes da marca no
app. O SVG continua a fonte da verdade e um teste compara a contagem/ordem de comandos dos paths.
Recorte da silhueta pelo escudo via `clipPath`; detalhes recortados com `saveLayer` +
`BlendMode.clear`.

**Alternatives considered**: `flutter_svg` (rejeitado: dependência nova, a constituição pede
justificativa e o SVG não anima o traço); manter PNG no `AppLogo` (rejeitado: não segue o alto
contraste).

## R4. Mancha líquida e onda

**Decision**: mancha = `Path` fechado com 8 pontos em volta do centro do toque, raio crescente e
deslocamento senoidal por ponto (bordas onduladas), desenhado com curvas cúbicas suaves; cobre a
tela quando o raio passa da diagonal. Onda = retângulo `primary` acima de uma borda cúbica (a
mesma curva do protótipo, escalada à largura) que desce da tela toda até sobrar no rodapé; uma
segunda onda `primary-glow` 60 ms atrás. Tudo num `CustomPainter` da cena.

**Rationale**: só `Path`, `Canvas` e `AnimationController`, sem dependência nova; mesma forma do
protótipo.

## R5. Navegação: animação E validação

**Decision**: remover o `minimumDisplayDuration` (2 s) do `SplashController`; a página espera
`Future.wait([controller.resolveDestination(), animaçãoTerminou])`. Com movimento reduzido, a
animação começa no fim (`value = 1`) e o futuro da animação já está completo.

**Rationale**: a regra "o que vier por último" fica num lugar só (a página, que conhece a
animação); o controlador volta a ser só regra de destino, testável sem relógio.

**Alternatives considered**: manter o mínimo no controlador com 1,8 s (rejeitado: duplica a
duração da animação em dois lugares e não respeita "Reduzir animações").

## R6. Abertura nativa sem logo

**Decision**: Android — `launch_background.xml` (drawable e drawable-v21) só com a cor
`@color/launcher_background` (`#FFFDFB`); em `values-v31` e `values-night-v31`,
`windowSplashScreenAnimatedIcon` aponta para um drawable transparente. iOS — `LaunchScreen` com
fundo `#FFFDFB` e sem a imagem. As imagens `launch_logo`/`LaunchImage` deixam de ser geradas e
são removidas.

**Rationale**: o primeiro quadro da splash animada é só o fundo; um logo estático antes dele
apareceria, sumiria e voltaria (SC-005). Padrão de apps com splash animada própria.

## R7. Gerar as imagens com o logo novo

**Decision**: trocar `#C0503E` por `#FE3152` no SVG oficial e rodar
`tools/generate_brand_assets.py` no WSL (Ubuntu já tem `libcairo` e `librsvg`; Pillow num venv
temporário), sem mudar o script além de deixar de gerar as imagens da abertura nativa. Atualizar
`web/manifest.json` (`theme_color`) para `#FE3152`.

**Rationale**: o script do projeto já gera todas as densidades a partir do SVG; reaproveitá-lo
mantém a reprodutibilidade da feature 021.

## R8. Contraste

`#FE3152` sobre `#FFFDFB` ≈ 3,6:1 — atende 3:1 para elemento gráfico (logo, SC-004).
Título `#182A4E` ≈ 14:1 e frase `#596475` ≈ 5,9:1 sobre `#FFFDFB` (≥ 4,5:1). No alto contraste,
`#9E0019` sobre branco ≈ 8,5:1.
