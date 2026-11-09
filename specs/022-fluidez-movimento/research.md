# Research: Fluidez, movimento e estados de carregamento

**Feature**: [spec.md](spec.md) · **Data**: 2026-11-08

Referência de implementação: `fuja_app` (`lib/ui/core/motion/motion.dart`,
`lib/ui/core/widgets/async_body.dart`, `fuja_skeleton.dart`, `TabBranchContainer` em
`lib/ui/navigation/shell/app_shell.dart`, `_MotionAwareTransitionsBuilder` em
`lib/ui/core/theme/app_theme.dart`).

## R1 — Fonte Montserrat (FR-001)

- **Decision**: embutir os TTF estáticos da Montserrat (Regular 400, Medium 500, SemiBold 600,
  Bold 700, ExtraBold 800) em `assets/fonts/montserrat/`, declarados em `flutter.fonts` do
  pubspec com o `weight` de cada arquivo, junto com `OFL.txt`.
- **Rationale**: o tema já pede `fontFamily: 'Montserrat'`, mas nenhuma fonte está declarada:
  o Flutter cai na Roboto sem aviso. Arquivos estáticos garantem que o `FontWeight` de cada
  estilo escolha o arquivo certo (a variável exigiria `FontVariation` em cada `TextStyle`).
- **Alternatives considered**: `google_fonts` (baixa da rede: falha sem internet e é uma
  dependência a mais); fonte variável (os pesos não seriam aplicados automaticamente).

## R2 — Bibliotecas novas (Constituição §IV)

- **Decision**: adicionar `animations` (pacote do time do Flutter: `FadeThroughTransition`,
  `SharedAxisTransition`) e `skeletonizer` (esqueleto gerado a partir do próprio widget, com
  dados de exemplo). Não adicionar cache de imagem em disco.
- **Rationale**: nenhuma das duas concorre com uma biblioteca da stack oficial (o §IV proíbe
  *concorrentes* sem emenda); as duas são as mesmas do `fuja_app`, já validadas. Escrever
  esqueletos à mão para seis telas duplicaria o layout de cada uma (contra o DRY do §II).
- **Alternatives considered**: `shimmer` (citado no README, mas exige desenhar cada esqueleto à
  mão); `cached_network_image` (cache em disco, fora do escopo pela spec; o `ImageCache` em memória
  basta para a sessão); fade-through feito à mão (reimplementar o que o pacote oficial já tem).

## R3 — Tokens de movimento e "Reduzir animações" (FR-008 a FR-010)

- **Decision**: criar `AppMotion` em `lib/core/theme/app_motion.dart` com `short` (150 ms),
  `medium` (250 ms) e `long` (350 ms), as curvas `enter` (`Easing.emphasizedDecelerate`),
  `exit` (`Easing.emphasizedAccelerate`) e `standard` (`Easing.standard`), e o `AppMotionScope`,
  um `InheritedWidget` que junta a preferência do app com `MediaQuery.disableAnimations`. Com o
  movimento reduzido, todas as durações valem zero. `AppMotion.of(context)` é a única fonte de
  duração para widgets.
- **Preferência**: novo campo `reduceMotion` em `AccessibilityPreferences` (o padrão é
  desligado), persistido no `AccessibilityLocalDataSource` como os demais, com um interruptor
  na `AccessibilityPage`. O `AppMotionScope` entra no `builder` do `MaterialApp`, ao lado da
  escala de texto.
- **Rationale**: é o padrão do `FujaMotion`/`MotionScope`. Zerar a duração mantém o código de
  cada animação igual nos dois modos. Os tokens ficam em `core/theme` porque são transversais
  (§I).
- **Alternatives considered**: checar `MediaQuery.disableAnimations` em cada widget (não cobre a
  opção do app e repete a regra); não oferecer a opção no app (a spec pede, e no Android a
  opção do sistema fica escondida nas opções do desenvolvedor ou em Acessibilidade).

## R4 — Transições de página (FR-015, FR-018)

- **Decision**:
  - `pageTransitionsTheme` no `AppTheme`: no Android, `PredictiveBackPageTransitionsBuilder`
    envolvido por um `_MotionAwareTransitionsBuilder` que corta a transição quando o movimento
    está reduzido; no iOS, `CupertinoPageTransitionsBuilder`. Isso cobre todas as telas
    empilhadas com `push` (detalhe, configurações, notificações, lição etc.), sem mudar as rotas.
  - As rotas que **substituem** a pilha com `go` (`/onboarding`, `/login` e o shell) usam
    `pageBuilder` com um `CustomTransitionPage` de esmaecimento (`AppFadePage`), já que deslizar
    sugeriria que dá para voltar. Isso cobre a saída da splash (FR-018).
- **Rationale**: a volta preditiva é a transição nativa do Android 14+. A troca de "contexto"
  (splash → início, sair → login) é semanticamente um esmaecimento.
- **Alternatives considered**: um `CustomTransitionPage` em cada rota (repetitivo, perde o volta
  preditivo); `ZoomPageTransitionsBuilder` (não tem prévia do gesto de voltar).

## R5 — Troca de abas (FR-016)

- **Decision**: trocar `StatefulShellRoute.indexedStack` por `StatefulShellRoute` com um
  `navigatorContainerBuilder` que monta um `TabBranchContainer`: um `Stack` com todas as
  branches em `Offstage` + `TickerMode(enabled: ativa)`, e na branch ativa um
  `FadeThroughTransition` disparado a cada troca de índice (duração `AppMotion.medium`).
- **Rationale**: mantém a semântica do `indexedStack` (estado e rolagem de cada aba preservados)
  e pausa as animações das abas escondidas (o brilho do esqueleto não roda fora da tela). É a
  mesma técnica do `fuja_app`.
- **Alternatives considered**: `PageView` com as branches (o deslize lateral entre abas não é o
  padrão do Material para barra inferior e confunde com o gesto de voltar).

## R6 — Feed estável ao atualizar (FR-002, FR-003)

- **Decision**: o `FeedController` separa a **primeira carga** (`status = loading`, sem lista)
  da **recarga** (`isRefreshing = true`, a lista continua, e o `status` fica em `loaded`). Uma
  falha na recarga mantém a lista e publica um `FeedMessage` (fluxo de mensagens, como o
  `ReelsController.messages` já faz), que a página mostra num aviso rápido. A troca de categoria
  e a busca usam a recarga: a lista fica esmaecida (`AnimatedOpacity`) com uma barra de
  progresso fina no topo até a resposta chegar. O `_requestId` atual continua descartando as
  respostas antigas.
- **Rationale**: corrige a lista que some e o indicador duplo no puxar-para-atualizar sem mudar
  os usecases.
- **Alternatives considered**: guardar a lista antiga na página (a regra de estado sairia do
  controller).

## R7 — Feed acompanha a conta e a leitura (FR-004, FR-005)

- **Decision**:
  - **Conta**: o `FeedController` recebe `sessionStatus` (`ValueListenable<UserSessionStatus>`,
    como o `ReelsController` já recebe) e faz uma recarga silenciosa a cada mudança de valor.
  - **Leitura e salvos**: o `NewsRepositoryImpl` passa a publicar, num `Stream` de difusão, cada
    mudança de interação confirmada (`markAsRead`, `toggleSave`, `toggleLike`), exposta pelo novo
    `WatchNewsInteractionsUseCase`. O `FeedController` assina e corrige só o item afetado, com
    `copyWith` da interação, sem chamar o servidor. O `ReelsController` também assina, porque
    salvar no detalhe precisa aparecer no Reel.
- **Rationale**: respeita a direção Controller → UseCase → Repository (§I); não recarrega a lista
  inteira ao voltar do detalhe, o que perderia as páginas já carregadas e a posição. Há dois
  consumidores reais (feed e Reels), então a abstração não é especulativa (§II).
- **Alternatives considered**: recarregar o feed ao voltar do detalhe (uma requisição a cada
  notícia aberta, com o servidor lento, e perda da paginação); devolver o resultado no `pop` (o
  gesto de voltar do sistema não devolve valor).

## R8 — Estados com esqueleto (FR-011 a FR-014)

- **Decision**: dois widgets em `lib/core/widgets/`:
  - `SafeSkeleton({enabled, child})`: um `Skeletonizer` com as cores do `AppPalette` (no alto
    contraste, cinzas de contraste adequado), brilho de 1,5 s, estático com o movimento reduzido,
    `Semantics(label: Carregando, liveRegion)` + `ExcludeSemantics` quando ligado.
  - `SafeStateSwitcher({stateKey, child})`: um `AnimatedSwitcher` com duração `AppMotion.medium`,
    alinhado no topo (`topAlignedSwitcherLayout`), que troca entre carregando, conteúdo, vazio e
    erro.
  - Cada tela monta o próprio conteúdo com dados de exemplo (`NewsItemEntity.placeholder()` etc.,
    em `presentation/extensions` do módulo) dentro do `SafeSkeleton` ligado. O
    `SlowRequestNotice` continua abaixo do esqueleto.
- **Rationale**: o esqueleto é o próprio layout, então não diverge da tela real; esse é o padrão
  `AsyncBody`/`FujaSkeleton`, adaptado ao Provider (sem `AsyncValue`).
- **Alternatives considered**: esqueletos desenhados à mão por tela (duplicação); manter o
  `SafeLoadingState` (o círculo continua só nos botões e em cargas de "mais itens").

## R9 — Detalhe com prévia (FR-017)

- **Decision**: a rota `/news/:id` aceita `extra: NewsItemEntity?` (a prévia). O `NewsDetailPage`
  mostra o `NewsDetailHeader` a partir da prévia enquanto `status == loading` e o esqueleto só do
  corpo. A imagem usa `Hero` com a tag `news-image-<seção>-<id>`, porque a mesma notícia pode
  aparecer em "Destaques" e em "Tudo recente", e tags repetidas na mesma tela quebram o `Hero`.
  Sem `extra` (link direto), mostra o esqueleto completo.
- **Rationale**: o título aparece na hora (SC-005), mesmo com o servidor dormindo.
- **Alternatives considered**: guardar a última lista num serviço compartilhado (estado global
  sem necessidade).

## R10 — Carrossel → Reels (FR-019)

- **Decision**: os Reels são uma aba, com outro `Navigator`, então o `Hero` não atravessa. Cada
  cartão do carrossel chama `precacheImage` da imagem do Reel em tela cheia quando aparece; o item
  tocado vai como `extra` de `/reels?start=`, e o esqueleto mostra a imagem dele enquanto a lista
  carrega. A aba entra com o fade-through de R5. (Pré-carregar só no toque não dava tempo de baixar
  a imagem: achados T063 e T069.)
- **Rationale**: garante "sem tela preta" com uma linha de código; a spec foi ajustada para isso.
- **Alternatives considered**: abrir os Reels como tela empilhada sobre o Início (muda a navegação
  aprovada na feature 005).

## R11 — Imagens (FR-029 a FR-031)

- **Decision**: o widget `SafeNetworkImage` (em `core/widgets`) substitui os `Image.network` do app:
  - `cacheWidth`/`cacheHeight` calculados a partir do tamanho mostrado × `devicePixelRatio`;
  - `frameBuilder` com `AnimatedOpacity` (`AppMotion.medium`) sobre o placeholder;
  - sem esmaecimento quando `wasSynchronouslyLoaded`;
  - `errorBuilder` para o placeholder.

  Nos Reels, `onPageChanged` faz `precacheImage` do item `index + 1`. A barra de status usa
  `AnnotatedRegion<SystemUiOverlayStyle>`: escura no `builder` do app e clara na `ReelsPage`.
- **Rationale**: decodificar no tamanho exibido reduz memória e travadas em aparelhos simples, e
  o pré-carregamento elimina a tela preta.
- **Alternatives considered**: `cached_network_image` (fora do escopo; ver R2).

## R12 — Botão central da barra inferior (FR-006)

- **Decision**: a barra inferior passa a ter uma faixa transparente de 16 dp no topo, que fica
  dentro dos limites do widget, e o círculo é desenhado nessa faixa sem `Transform.translate`. O
  `Scaffold` do shell usa `extendBody: true`, para o conteúdo aparecer por trás da faixa
  transparente; as páginas já usam `SafeArea`/padding inferior, então nada fica escondido. O
  fundo da barra ganha desfoque leve (`BackdropFilter`), aproveitando a transparência de 95%.
- **Rationale**: o hit test do Flutter não alcança o que é desenhado fora dos limites do pai; com
  o círculo dentro da área, o toque funciona em toda a área visível.
- **Alternatives considered**: aumentar a altura da barra (muda o visual aprovado); um
  `Overlay` para o botão (complexo e frágil).

## R13 — Microinterações e vibração (FR-020 a FR-028)

- **Decision**:
  - `SafeButton` e `SafeCard` passam a usar `Listener`/`GestureDetector` com tempo mínimo de
    pressão: a escala segue até o fim mesmo com toque curto (o "afundar" dura pelo menos
    `AppMotion.short`). Também ganham `Semantics(button: true, enabled:)` e `AnimatedSwitcher`
    entre o ícone e o spinner.
  - Vibração centralizada em `AppHaptics` (`core/utils`):
    - `selection` (`HapticFeedback.selectionClick`) para curtir;
    - `success` (`lightImpact`) para o acerto;
    - `error` (`heavyImpact`) para o erro.

    O Android já ignora a vibração quando o aparelho a desliga (FR-028).
  - Curtir: `ScaleTransition` com `TweenSequence` (1 → 1,3 → 1, `AppMotion.long`); dois toques na
    `ReelView` chamam o mesmo `_like` (só curte; se já curtiu, só anima).
  - Login: `AnimatedSize` + `AnimatedSwitcher` no campo de nome, nas regras de senha e nas
    mensagens.
  - Onboarding: o indicador escuta o `PageController` e interpola a largura pela página
    fracionária.
  - Barra inferior: `AnimatedSwitcher`/`TweenAnimationBuilder` de cor e escala no ícone ativo.
  - Lição: `PageTransitionSwitcher` + `SharedAxisTransition` horizontal, com o sentido dado pelo
    índice anterior.
  - Assistente: um balão "digitando" com três pontos animados (estáticos com o movimento
    reduzido) e `SizeTransition`/`FadeTransition` na entrada das mensagens.
- **Rationale**: cada animação usa os tokens de R3, então "Reduzir animações" cobre tudo.

## R14 — Toolchain Android (FR-032)

- **Decision**: alinhar com o `fuja_app`, que compila no mesmo ambiente: Gradle **9.3.1** no
  wrapper, AGP **9.1.0** e Kotlin **2.4.0** no `settings.gradle.kts`, com `jvmTarget` no bloco
  `kotlin { compilerOptions }`. Validar com `flutter run` no emulador `fuja_api36`.
- **Rationale**: o Gradle 8.14 não roda com o JDK 25 que o Android Studio distribui (o
  `flutter run` falha); o próprio Flutter já avisa que AGP 8.11 e Kotlin 2.2 estão perto do
  mínimo.
- **Alternatives considered**: `flutter config --jdk-dir` apontando para um JDK 21 (configuração
  da máquina, cada pessoa da equipe teria de repetir); `org.gradle.java.home` no
  `gradle.properties` (caminho de uma máquina específica no repositório).

## R15 — Testes

- **Decision**: os testes de widget que esperam o carregamento já usam `pumpLocalized(settle:
  false)` (o círculo também é infinito), então o brilho do esqueleto não muda isso. Novos testes:
  - unitários do `FeedController` (recarga mantém a lista, falha na recarga, recarga por sessão,
    correção por interação);
  - do `NewsRepositoryImpl` (o stream publica após sucesso e não publica após falha);
  - de `AccessibilityPreferences`/modelo (`reduceMotion` persistido);
  - de widget: o `AppMotionScope` zera durações, o `SafeButton` tem semântica de botão, o toque
    no topo do botão central abre os Reels, o `SafeSkeleton` anuncia "Carregando" e o detalhe
    mostra o título da prévia.
- **Rationale**: Princípio III; cada comportamento com lógica ganha teste e a suíte atual
  (1702 testes) continua verde.
