# Research: Redesign visual 2.0

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-11-08

As decisões de produto estão na seção Clarifications da spec. As de baixo saem do código atual:

- `lib/core/theme/` e `lib/core/widgets/`;
- `main.dart`;
- a barra inferior da feature 005, o Início da 006 e as atividades das 015 a 020;
- a acessibilidade das 009 e 014;
- a identidade da 021.

Saem também do HTML que gerou o Figma, `click-seguro-redesign.html`, que é a fonte das medidas e
dos SVGs.

## R0. Nada muda fora da aparência

**Decision**: nenhum controller, caso de uso, repositório, rota ou chamada à API muda, exceto as
duas exceções da spec. A primeira é o campo `reduceMotion`, de ponta a ponta no módulo settings. A
segunda é o cartão de emergência, que usa a ação de ligar que já existe.

**Rationale**: FR-022 e SC-005. Os testes de comportamento continuam valendo e servem de rede de
segurança para uma mudança que toca em quase todas as telas.

**Alternatives considered**: aproveitar para refatorar as telas, por exemplo extrair seções
grandes. Rejeitado, porque misturaria refatoração com visual num PR que já é grande e dificultaria a
revisão.

## R1. Paleta nova sem trocar o mecanismo

**Decision**: manter `AppPalette` (ThemeExtension lida por `context.colors`) e `AppColors`
(valores do tema claro).
- **Campos que mudam de valor**: `primary` #E31C3D, `secondary`/`textForeground` #1B2440,
  `textMutedForeground` #5E6577, `background` #FFFFFF, `border` #E4E1DA, `input` #F7F5F0,
  `inputBorder` #C9C5BD, `success` #0F7B4F, `warning` #8F5600, `destructive` #C4122F.
- **Campos novos**: `primaryPressed` #C2112F, `primarySoft` #FFE8EB, `textBody` #3D4457,
  `surface` #F7F5F0, `surfaceStrong` #EFEBE3, `info` #2554C7, `successSoft` #DFF3E8, `warningSoft`
  #FDF0D5, `infoSoft` #E4ECFB.
- **Pastéis das ilustrações**: `pastelPeach`, `pastelSage`, `pastelSky`, `pastelButter`,
  `pastelLilac`.
- **Sombras**: `shadowSm`/`shadowMd` viram a sombra única ([R4](#r4-cantos-sombra-e-espaçamento)).
- **Removidos**: `primaryGlow`, `shadowPrimary` e o `gradient`, que saem do design (só um botão
  usa o gradiente).
- **Alto contraste**: ganha os mesmos campos novos, com as cores AAA atuais. As superfícies são
  brancas com borda preta, e os "suaves" e pastéis são brancos.

**Rationale**: as 267 leituras de `context.colors` em 83 arquivos continuam funcionando. A troca de
tema por alto contraste (RF-039) já passa pelo `AppPalette`. O teste de contraste
(`app_palette_test.dart`) já existe e passa a cobrir os pares novos (SC-002).

**Alternatives considered**: migrar para `ColorScheme` puro do Material 3. Rejeitado, porque não tem
campos para creme, pastéis e "suaves", e trocaria 267 leituras.

## R2. Fonte Inter empacotada

**Decision**: arquivos estáticos da Inter (400, 500, 600, 700, 800), com a licença OFL, em
`assets/fonts/` e declarados em `fonts:` no `pubspec.yaml`. `ThemeData.fontFamily: 'Inter'`.

**Rationale**:
- Funciona offline (RNF-002) e não acrescenta dependência.
- Hoje o tema pede `'Montserrat'`, mas a fonte não está empacotada, e o app cai na fonte do
  sistema. O redesign corrige isso.
- A Inter é a substituta aberta recomendada para as fontes do Airbnb e do Pinterest.

**Alternatives considered**: o pacote `google_fonts`. Rejeitado, porque baixa a fonte em tempo de
uso (falha offline) e é mais uma dependência.

## R3. Escala de texto

**Decision**: `AppTypography` com os estilos do Figma, montados no `textTheme` para os widgets do
Material herdarem. O app já multiplica a escala do usuário (RF-038) pela do sistema no `main.dart`,
e isso continua igual.

| Estilo | Tamanho / peso | Uso |
|---|---|---|
| `display` | 32 / 700, −0,8 | título de tela |
| `title1` | 28 / 700, −0,5 | títulos fortes (conclusão, estados) |
| `title2` | 22 / 700 | seções |
| `title3` | 20 / 600 | cartões |
| `bodyLarge` | 20 / 400, altura 1,5 | textos de leitura longa |
| `body` | 18 / 400, altura 1,55 | **padrão** |
| `label` | 16 / 600 | rótulos, links, chips |
| `caption` | 15 / 500 | metadados (mínimo) |
| `score` | 72 / 800 | placar da conclusão |

Os `fontSize:` soltos nas telas (130 hoje) passam a usar esses estilos na história que toca cada
tela. As telas sem desenho próprio são revisadas na US1.

**Rationale**: FR-003 e RNF-003 (base de 16 ou mais). Com estilos nomeados não há números mágicos
(Princípio V).

## R4. Cantos, sombra e espaçamento

**Decision**: o `AppSpacing` ganha os cantos `radiusSm` 12, `radiusMd` 16, `radiusLg` 20,
`radiusXl` 24, `radius2xl` 32 e `radiusFull`, além do espaço `s8` 48. Os nomes atuais
`radius2xl`/`radius3xl` (20/24) são renomeados nas chamadas. `AppShadows.card` é a sombra única:

```
0 0 0 1 rgba(0,0,0,.02)
0 2 6   rgba(0,0,0,.04)
0 4 8   rgba(0,0,0,.10)
```

No alto contraste, ela vira lista vazia mais borda.

**Rationale**: FR-004. Os nomes indicam o papel, não o tamanho do Tailwind.

## R5. Ilustrações em SVG com flutter_svg

**Decision**:
- Os SVGs ficam em `assets/illustrations/`, um por ilustração (lista no
  [data-model](data-model.md#ilustração)). Eles vêm do gerador do Figma, ajustados para serem
  autocontidos: sem `<text>`, sem máscaras e cores só em `fill`/`stroke`.
- `SafeIllustration` desenha com `SvgPicture.asset`, dentro de `ExcludeSemantics`.
- No alto contraste, um `ColorMapper` troca cada cor da paleta da ilustração pela equivalente AAA:
  pastéis → branco, tinta → preto, coral → #9E0019, verde → #005A3C, dourado → #6E4200.
- Dependência: `flutter_svg: 2.3.0` (maio de 2026), com versão fixada. **Confirmado no T001**:
  `SvgPicture.asset` aceita `colorMapper` (classe `ColorMapper.substitute`) nessa versão.

**Rationale**: as ilustrações aprovadas são vetores (FR-017). Precisam ficar nítidas com a fonte
ampliada, recolorir no alto contraste (FR-002) e funcionar offline. Detalhes em Complexity
Tracking, no [plan](plan.md#complexity-tracking).

**Alternatives considered**:
- `CustomPainter`, como o `SafeStateIllustration` da 021: inviável para cerca de 17 desenhos.
- PNG: borra e não recolore.
- Ícone grande no lugar de ilustração: perde o que foi aprovado.

**Consequência para a 021**: `SafeStateIllustration` (pintado à mão) é removido. `SafeErrorState`
e `SafeEmptyState` passam a usar `SafeIllustration` com `error`/`empty`/`offline`. O `AppLogo`
(PNG oficial) continua igual.

## R6. Componentes: evoluir os Safe* sem trocar a API

**Decision**: manter os nomes e os parâmetros públicos dos widgets compartilhados. Os ajustes
pontuais estão no [contrato](contracts/ui-components.md).

- **`SafeButton`**:
  - os tons passam a ser `primary`, `secondary`, `outline` e `link`. O `gradient` (1 uso) vira
    `primary` e o `ghost` vira `link`;
  - o tamanho `large` mede 60 e o `compact` 48. O `pill` some e os usos viram `SafeChip` ou
    `compact`;
  - estados pressionado (`primaryPressed` e escala 0,98) e desativado;
  - a altura cresce quando o texto quebra.
- **`SafeCard`**: canto 20, sombra única, variante `flat` (creme, sem sombra).
- **`SafeBadge`**: tons `success`, `warning`, `neutral`, `alert` (coral suave) e `onImage` (branco
  com sombra), todos com ícone opcional.
- **`SafeTextField`**: rótulo acima, altura 60, canto 16, foco com borda tinta 2,5 e erro com
  borda e mensagem na cor de erro e ícone de alerta.
- **Novos**:
  - `SafeIconButton` (48 ou 56, creme ou branco com sombra);
  - `SafeChip` (filtro, ativo invertido);
  - `SafePillTabs` (abas em pílula, com rótulos acessíveis de aba selecionada);
  - `SafeProgressBar`, `SafeProgressRing` e `SafeSegmentedProgress`;
  - `SafeSkeleton` (bloco com brilho);
  - `SafeSheet` (moldura da folha inferior: alça e canto 32 em cima).
- **`ListenButton`**: vira pílula com borda e pulsa enquanto lê ([R9](#r9-animações-sem-pacote)).

**Rationale**: SC-005 (os testes de comportamento continuam valendo) e DRY. São 53 usos de
`SafeButton` em 30 arquivos, e trocar a API forçaria mexer em todos sem ganho.

**Alternatives considered**: um kit novo (`Cs*`) ao lado dos `Safe*`. Rejeitado: duplicação
(Princípio II) e dois visuais convivendo.

## R7. Reconhecer o tema do módulo e da notícia

**Decision**: `IllustrationTheme.fromText(String)` em `lib/core/illustrations/`. É uma função pura:
normaliza o texto (minúsculas, sem acentos) e procura palavras-chave em português e inglês, na
ordem da tabela. A primeira que bate decide.

| Tema | Palavras-chave (pt e en) | Ilustração / pastel |
|---|---|---|
| `whatsapp` | whatsapp, zap, mensagem de parente, falso parente | celular com balão / pêssego |
| `pix` | pix, boleto, transferencia, pagamento, bank slip, payment | cartão e QR / sálvia |
| `link` | link, phishing, e-mail, email, sms, mensagem suspeita | envelope e anzol / céu |
| `call` | ligacao, telefone, central falsa, call, phone | telefone / manteiga |
| `password` | senha, password, conta invadida, dois fatores, 2fa | cadeado / lavanda |
| `fakeNews` | fake, boato, desinformacao, noticia falsa, hoax | jornal e lupa / pêssego |
| `generic` | (nenhuma bateu) | escudo com check / creme |

Ela é usada no cartão de módulo (pelo título) e na capa ilustrada de notícia sem imagem (pela
primeira categoria, depois pelo título).

**Rationale**: decisão do clarify (FR-014). Ficar no `core` evita que activities e news importem
um ao outro (Princípio I). Por ser uma função pura, o teste é simples e completo.

## R8. Reduzir animações: um sinal só

**Decision**:
- `AccessibilityPreferences` ganha `reduceMotion` (padrão `false`). O modelo e o
  `AccessibilityLocalDataSource` salvam a chave nova. Sem a chave, o valor é `false`, então quem
  já usa o app não perde nada.
- A tela de Acessibilidade ganha o interruptor, com o mesmo controller e o mesmo salvamento das
  outras preferências.
- No `main.dart`, o `builder` que já aplica a escala de fonte passa a aplicar também:
  `disableAnimations: media.disableAnimations || preferences.reduceMotion`.
- `app_motion.dart` expõe `context.reduceMotion` (= `MediaQuery.disableAnimationsOf`) e as
  durações (`fast` 150, `standard` 250, `emphasis` 400, `celebration` 1200 ms) e curvas
  (`enter` (.2,0,0,1), `exit` (.4,0,1,1), `spring` (.34,1.56,.64,1)).

**Rationale**: FR-021 e FR-024. Um sinal só serve aos dois casos (celular ou app). Os widgets do
Flutter que já respeitam o `disableAnimations`, como algumas transições, entram de graça, e nenhum
widget do `core` precisa conhecer o módulo settings.

**Alternatives considered**: cada widget ler a preferência do notifier. Rejeitado, porque
acoplaria o `core` ao settings e duplicaria a soma com o sistema.

## R9. Animações sem pacote

**Decision**: tudo com o SDK, e cada animação confere `context.reduceMotion` e, se ele estiver
ligado, mostra direto o estado final.

| Animação | Como |
|---|---|
| Troca de tela | `PageTransitionsTheme` com um construtor próprio no `AppTheme`: aparece mais desliza 24 (250 ms). Com reduzir animações, troca sem transição. Vale para as rotas do go_router, que usam `MaterialPage` |
| Toque | `SafeButton`, `SafeCard` tocável e cartões: `AnimatedScale` 0,98 em 150 ms |
| Progresso | `TweenAnimationBuilder` de 0 até o valor em 400 ms |
| Folha inferior | `showModalBottomSheet` com `AnimationStyle` de 400 ms e curva `enter` |
| Resposta certa | check com `TweenAnimationBuilder` de escala e curva `spring` |
| Resposta errada | deslocamento horizontal ±6, duas vezes, num `AnimationController` de 500 ms |
| Confete | `CustomPainter` com cerca de 30 retângulos caindo por 1200 ms, sem repetir. Com reduzir animações, não aparece |
| Contagem do placar | `TweenAnimationBuilder<int>` de 0 ao placar em 1200 ms. O leitor de tela recebe o valor final desde o início |
| Brilho | `SafeSkeleton` com um gradiente que corre em 1,4 s. Com reduzir animações, bloco parado |
| Ouvir | `ListenButton` com halo pulsando enquanto lê, 2 s por ciclo |

Nenhuma pisca mais de 3 vezes por segundo (FR-021).

**Alternatives considered**: os pacotes `shimmer`, `confetti` e `flutter_animate`. Rejeitados: cada
um é uma dependência para poucas linhas de código (constituição, dependências novas).

## R10. Barra inferior

**Decision**: `AppBottomNav` perde o `_CenterItem` e o `AppTab.isCenter`. Cada aba vira o mesmo
item:
- pílula de 60×34 atrás do ícone (26);
- rótulo sempre visível (15, negrito na aba atual), com até duas linhas quando a fonte cresce.
  O Figma usou 14, mas vale o mínimo de 15 do FR-003;
- semântica de aba selecionada.

O destino de cada aba e o `StatefulShellRoute` não mudam.

**Rationale**: FR-009 e SC-007. Os testes atuais de troca de aba (`app_shell_test`) continuam. Só
sai o teste do botão central.

## R11. Cartão de emergência

**Decision**:
- Um widget `EmergencyCallCard` no `presentation/widgets/` do módulo help, no topo da Central de
  ajuda, acima das abas.
- O botão "Ligar para 190" usa a mesma ação de ligar dos contatos oficiais, com o mesmo aviso
  quando o discador não abre. Hoje o `HelpController.call(ContactEntity)` recebe um contato.
  Ele ganha `callNumber(String phone)`, e o `call(contact)` passa a delegar para ele. Assim não
  surge uma segunda regra de "pode ligar?".
- O número fica numa constante do módulo help (`EmergencyNumbers.police = '190'`), sem número
  mágico na tela.
- Textos novos em `AppStrings`: `helpEmergencyTitle`, `helpEmergencyBody` e
  `helpEmergencyCall`, em pt-BR e en-US.

**Rationale**: FR-016, com a mesma ação dos contatos (RF-032) e sem caminho novo de erro.

## R12. Testes

**Decision**:
- **TDD nas regras novas**:
  - `IllustrationTheme.fromText` (tabela de casos, pt e en, acentos);
  - contraste da paleta clara e da de alto contraste para todos os pares de texto e fundo
    (estende `app_palette_test`);
  - `reduceMotion` salvo, lido e com padrão `false`;
  - `main`/builder somando `disableAnimations`;
  - widgets que, com `disableAnimations`, mostram o estado final (progresso, contagem, confete
    ausente, brilho parado);
  - `EmergencyCallCard` chamando a ação com 190;
  - barra inferior com cinco itens iguais e semântica de selecionado.
- **Testes atuais**: só mudam os que conferem aparência, como tipo de widget de carregamento
  (`CircularProgressIndicator` → `SafeSkeleton`), cor ou `SafeButtonTone.gradient`. Os 12 que
  procuram `CircularProgressIndicator` ou `SafeLoadingState` passam a procurar o rótulo de
  carregamento, que é o comportamento real.
- **Sem testes golden**: a fonte e a plataforma tornam a comparação de pixels instável, e a
  conferência visual é feita pela usuária contra o Figma (quickstart, SC-001).

## R13. Documentação

**Decision**: no PR:
- `.specify/memory/design-system.md` 2.0.0, com tokens, componentes, ilustrações, movimento e
  divergências;
- `.specify/memory/specification.md` 2.5.0: a barra inferior na seção de navegação, o cartão de
  emergência junto do RF-031, o "reduzir animações" junto do RF-038 a RF-041 e o changelog;
- `.specify/memory/tasks.md`: tarefa R1 marcada, com o link para esta spec.

**Rationale**: FR-023. O design system é a fonte para quem for reproduzir o visual na web.
