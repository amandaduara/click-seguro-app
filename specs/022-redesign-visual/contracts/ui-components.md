# Contrato: componentes compartilhados (lib/core/widgets)

**Feature**: [spec.md](../spec.md) · **Research**: [R6](../research.md#r6-componentes-evoluir-os-safe-sem-trocar-a-api)

A interface que esta feature expõe é a dos widgets compartilhados, que todos os módulos usam. O
contrato abaixo diz o que se mantém, o que muda e o que nasce, para que as telas e os testes saibam
com o que contar.

Regras para todos os widgets:
- Leem cores de `context.colors`, tamanhos de `AppTypography`/`AppSpacing` e movimento de
  `AppMotion`.
- Respeitam `context.reduceMotion`.
- Não cortam texto com a escala até 2,0.
- Todo widget tocável tem alvo de pelo menos 48×48 e rótulo de semântica.

## Mantidos, com visual novo (API compatível)

| Widget | API que se mantém | Mudança de API | Comportamento visual |
|---|---|---|---|
| `SafeButton` | `label`, `onPressed`, `icon`, `iconRight`, `loading`, `disabled`, `size`, `tone` | `SafeButtonTone`: `primary`, `secondary`, `outline`, `link` (`gradient` e `ghost` saem; os usos migram). `SafeButtonSize`: `large` (60), `compact` (48) (`pill` sai). `shadow` sai. | coral, creme, contorno tinta ou sublinhado; ao tocar, cor pressionada e escala 0,98; cresce em altura se o texto quebrar; carregando mostra indicador no lugar do texto, com o rótulo mantido para leitura |
| `SafeCard` | `child`, `onTap`, `padding` | `+ flat` (creme, sem sombra) | branco, canto 20, sombra única; tocável com escala 0,98 |
| `SafeBadge` | `label`, `icon` | tons: `success`, `warning`, `neutral`, `alert`, `onImage` | pílula de 30, texto 14/700 |
| `SafeTextField` | parâmetros atuais (rótulo, erro, obscure, teclado, etc.) | nenhuma | rótulo acima, 60 de altura, canto 16; foco: borda tinta 2,5; erro: borda e mensagem na cor de erro, com ícone |
| `SafeLoadingState` | `semanticsLabel`/mensagem atual | `+ layout` (`list`, `cards`, `detail`), padrão `cards` | blocos `SafeSkeleton` no formato do conteúdo; anuncia carregando como hoje |
| `SafeErrorState` | mensagem, `onRetry`, ação secundária | nenhuma | ilustração `stateError` (ou `stateOffline` quando a falha for de conexão), título, texto, "Tentar de novo" primário |
| `SafeEmptyState` | mensagem, dica, ação | nenhuma | ilustração `stateEmpty`, título, texto, ação secundária |
| `SafeOfflineBanner` | atual | nenhuma | faixa tinta, canto 14, ícone `wifiOff` branco |
| `SlowRequestNotice` | atual | nenhuma | caixa `infoSoft` com ícone de relógio na cor `info` |
| `ListenButton` | atual | nenhuma | pílula com borda, ícone coral; pulsa enquanto lê |
| `AppLogo` (021) | atual | nenhuma | sem mudança |

## Novos

| Widget | API | Comportamento |
|---|---|---|
| `SafeIllustration` | `SafeIllustration(AppIllustration, {double? height})` | SVG decorativo; recolore no alto contraste |
| `SafeIconButton` | `icon`, `semanticLabel` (obrigatório), `onPressed`, `size` (48/56), `onImage` | redondo, creme ou branco com sombra |
| `SafeChip` | `label`, `selected`, `onSelected` | pílula de 44; selecionado em tinta com texto branco; semântica de botão selecionado |
| `SafePillTabs` | `tabs: List<String>`, `selectedIndex`, `onChanged` | trilho creme forte de 56, aba atual branca com sombra; semântica de aba e selecionada |
| `SafeProgressBar` | `value` (0–1), `tone` (`primary`/`success`) | 10 de altura, enche em 400 ms |
| `SafeProgressRing` | `value`, `label`, `size` | anel de 104 com rótulo no centro, enche em 400 ms |
| `SafeSegmentedProgress` | `total`, `done`, `current` | segmentos: feitos em coral, atual em coral claro, futuros em creme |
| `SafeSkeleton` | `width`, `height`, `radius` | bloco com brilho de 1,4 s; parado com reduzir animações; fora da semântica |
| `SafeSheet` | `child` | moldura branca, canto 32 em cima, alça; usado nos `showModalBottomSheet` |

## Fora de `core`, mas compartilhado dentro do módulo

| Widget | Módulo | Contrato |
|---|---|---|
| `AppBottomNav` | shell | 5 itens iguais (`AppTab`), sem `isCenter`; aba atual: ícone coral, pílula coral suave, rótulo em negrito, semântica selecionada |
| `ModuleCard` | activities | ilustração `IllustrationTheme.fromText(title)` no topo (150, canto 16), `SafeBadge.onImage` com o status, título, "X de Y lições", `SafeProgressBar` |
| `NewsCover` | news | imagem da notícia ou, sem imagem ou com falha, ilustração do tema sobre o pastel; selo de categoria e botão salvar sobre a capa |
| `EmergencyCallCard` | help | cartão coral, título, texto e botão branco "Ligar para 190" que chama `HelpController.callNumber('190')` |
