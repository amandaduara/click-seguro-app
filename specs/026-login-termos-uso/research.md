# Research: Login que continua a splash, aceite dos termos e Termos de uso

**Feature**: [spec.md](spec.md) · **Plano**: [plan.md](plan.md) · **Data**: 2026-11-23

Cada item: decisão, por quê e o que foi descartado.

## R1. Passagem splash → login: a própria tela de login faz a abertura

**Decisão**: a splash vai para `/login?from=splash` sem transição de página (troca seca). O
primeiro quadro do login é igual ao último da splash: a marca no mesmo retângulo, o nome e o
slogan da splash e a onda no rodapé. A partir daí, o próprio login anima (um
`AnimationController` na página, ~1,3 s):

| Trecho (ms) | O que acontece | Curva |
|---|---|---|
| 0–300 | nome e slogan da splash somem subindo 10 px | `AppMotion.exit` |
| 150–750 | a marca vai do retângulo da splash ao do cabeçalho (`Rect.lerp`) | `Curves.fastOutSlowIn` (a da splash) |
| 450–750 | título e slogan do login entram subindo 14 px | `AppMotion.enter` |
| 550–850 | abas | idem |
| 650–950 | primeiro campo (no cadastro, o nome) | idem |
| 750–1050 | campos seguintes, regras e aceite | idem |
| 850–1150 | "Esqueci minha senha" e botão principal | idem |
| 950–1250 | "Continuar sem login" | idem |

Enquanto anima, a página ignora toques (`IgnorePointer`) e o leitor de tela não lê o nome e o
slogan da splash. Com "Reduzir animações" (`AppMotion.of(context).reduced`), o controller nasce
em 1 e o login aparece pronto (FR-017). Sem `from=splash`, a rota continua com o esmaecimento de
hoje (`appFadePage`) e sem abertura (FR-018).

**Por quê**: a splash desenha a marca num `CustomPainter`, e o login em outro widget. Um `Hero`
entre as duas rotas exigiria trocar a pintura da splash por widgets e depende de a troca por
`go` disparar o voo. Com a abertura dentro do login, a coreografia inteira fica num lugar só, e
é testável com o relógio falso do `tester.pump`.

**Detalhe aceito**: a marca da splash "respira" (escala até 1,035) enquanto espera o destino. No
corte, ela pode estar até 3,5% maior que no primeiro quadro do login. A diferença some no
começo do voo e não se nota.

**Descartado**: `Hero` com `go()` (frágil com `CustomPainter` e páginas trocadas); um overlay
global entre rotas (estado fora das telas, mais difícil de testar); animar na splash antes de
navegar (a splash teria que desenhar o formulário).

## R2. Onda e posição da marca vão para o `core`

**Decisão**: criar `lib/core/widgets/brand_scene.dart` com o que a splash e o login dividem:

- `BrandScene.logoRectFor(...)`: onde a marca fica no fim da splash (sai do `SplashScenePainter`);
- `BrandScene.titleTopFor(logoRect)` e `taglineGap`: onde fica o nome e o espaço até o slogan
  no fim da splash (hoje calculados dentro da `SplashAnimation`). A abertura do login os desenha
  saindo dali, sem copiar a conta (achado I1 do `/speckit-analyze`);
- as bordas das duas ondas, as alturas (110 e 136) e a função que monta o caminho da onda, com
  um progresso de 0 a 1 (a splash usa o progresso, e o login usa 1);
- o widget `BrandWave`: as duas ondas paradas no rodapé, nas cores `primaryGlow` e `primary`
  (no alto contraste, as duas ficam `#9E0019`).

O `SplashScenePainter` passa a usar essas funções e não muda de comportamento: o teste dele
continua igual.

**Por quê**: o módulo de autenticação não pode importar arquivos internos da splash
(Princípio I). O `core` é o lugar dos elementos visuais da marca (já tem o `BrandMarkPaths`), e
uma fonte única garante que a onda fique exatamente no mesmo lugar (FR-013).

**Descartado**: copiar as bordas para o login (duplicação, Princípio II); um serviço no GetIt
para a geometria (exagero para constantes de desenho).

## R3. Onda no rodapé com teclado e fonte grande

**Decisão**: o `Scaffold` do login usa `resizeToAvoidBottomInset: false`. O corpo é um `Stack`
com a `BrandWave` presa ao pé da tela e, por cima, a rolagem. O espaço livre no fim da rolagem é
o maior entre a altura da onda mais 16 (126) e o teclado mais 24. O conteúdo nunca fica atrás
da onda (FR-013), e com o teclado aberto a onda fica atrás dele, como diz a suposição da spec.

**Descartado**: deixar o `Scaffold` encolher com o teclado (a onda subiria e cobriria os campos);
esconder a onda com o teclado (pisca a cada foco).

## R4. Aceite dos termos no `AuthenticationController`

**Decisão**: `termsAccepted` (getter) e `setTermsAccepted(bool)`. `canSubmit` passa a exigir o
aceite no modo cadastro; `submit` também confere, como defesa. `setMode` não mexe no aceite
(esclarecimento de 2026-11-23); `reset()` o desmarca, e a página chama `reset()` ao abrir
(FR-005). Nada vai para o usecase nem para o serviço (FR-009).

**Por quê**: o aceite não é um campo enviado nem uma regra de validação do formulário
(`ValidateAuthFormUseCase` valida o que vai para a API). É estado de tela que libera o botão,
como `isPasswordVisible`.

**Descartado**: guardar no aparelho (a spec diz que o aceite só vale com a tela aberta); um
`AuthField.terms` no usecase (mistura um consentimento local com a validação dos dados).

## R5. Termos e Privacidade abrem sem sessão

**Decisão**: incluir `/settings/terms` e `/settings/privacy` em `_publicPaths` do
`app_router.dart`. Os links do cadastro usam `context.push`.

**Verificado** (teste descartável com go_router 17.3, em 2026-11-23): `push('/settings/privacy')`
saindo de `/login` empilha só a tela da Privacidade, sem a tela das Configurações, e o voltar
retorna ao login com a página intacta. O formulário e o aceite sobrevivem porque a página do
login continua montada embaixo (SC-003).

**Descartado**: rotas novas `/terms` e `/privacy` fora das Configurações (duas rotas para a
mesma tela).

## R6. Tela Termos de uso no módulo `settings`

**Decisão**: `TermsPage` em `settings/presentation/pages/terms_page.dart`, rota `terms` sob
`/settings`. Ela usa `SettingsScaffold`, `SettingsListenButton` e o cartão de assunto da
Privacidade. O `_Paragraph` privado da `privacy_page.dart` vira o widget
`SettingsTopicCard` (em `settings/presentation/widgets/`), usado pelas duas telas. A função
`termsSpokenText()` monta o que o "Ouvir" lê (título, data, cada assunto), como a
`privacySpokenText()`. O cartão "Seus dados" recebe um filho extra: o link "Ver Privacidade"
(`context.push('/settings/privacy')`).

A data é texto traduzido fixo: "Última atualização: 23/11/2026" e "Last updated: 11/23/2026".

**Por quê**: mesma cara da Privacidade sem copiar código (FR-001, Princípio II). Data fixa é o
mais simples para um documento que muda raramente: quem mudar o texto muda a data no mesmo
arquivo.

**Descartado**: formatar a data com `DateFormat` do `intl` (adiciona dependência direta para um
texto fixo).

## R7. Caixa de aceite: widget do módulo de autenticação

**Decisão**: `TermsAcceptance` em `authentication/presentation/widgets/`. É um
`StatefulWidget` porque os dois links usam `TapGestureRecognizer`, que precisa ser descartado.

- Quadrado de 28 com canto 8 dentro de uma área de toque de 48 × 48 (FR-007, RNF-003).
- Texto em `Text.rich`: "Li e aceito os " + link + " e a " + link + "." Tocar no texto fora dos
  links também marca a caixa.
- Marcada: quadrado `primary` com visto branco, cartão `primarySoft` com borda `primary`.
  Desmarcada: contorno `inputBorder`, cartão `card` com borda `border` (FR-008).
- Semântica: `Semantics(checked:, onTap:, label: texto completo)`. Os links, como `TextSpan` com
  `recognizer`, viram nós de link para o leitor de tela (FR-010).

**Por quê**: só o cadastro usa este componente. Ele não é do design system geral, então não vai
para o `core` (KISS). Se outra tela precisar, ele é promovido.

## R8. Cabeçalho e rodapé do login

**Decisão**:

- `AuthHeader` vira coluna centralizada: `AppLogo` de 68, o título "Bem-vindo ao Click Seguro"
  (uma chave nova, `auth_welcome_title`, no lugar de juntar `auth_welcome` + `auth_brand`) e o
  slogan (`splash_tagline`, o mesmo da splash). O espaço da marca recebe uma `GlobalKey`, que a
  abertura usa como destino do voo.
- "Esqueci minha senha" alinhado à direita.
- `SafeButton` principal com `iconRight: Icon(LucideIcons.arrowRight)`.
- "Continuar sem login" como `TextButton` coral (`primaryPressed`, 16/600, altura mínima 48).

**Código que sai** (fica morto): `OrDivider` e o teste dele, as chaves `auth_or`,
`auth_guest_note`, `auth_welcome` e `auth_brand` (nos dois idiomas), e o botão secundário do
visitante.

## R9. Estratégia de testes

Como a suíte completa leva cerca de 30 min (registro de 2026-11-22), cada história roda os testes
do que tocou, e a suíte inteira roda uma vez, no polimento.

- **Unidade**: `AuthenticationController` (aceite libera e trava `canSubmit`, sobrevive a
  `setMode`, some no `reset`, `submit` sem aceite não chama o usecase); `BrandScene`
  (`logoRectFor` igual ao de antes; caminho da onda com progresso 1 dentro da caixa).
- **Widget**:
  - `TermsAcceptance`: marca pelo quadrado e pelo texto; links chamam os callbacks; área de 48;
    semântica de caixa marcada.
  - `TermsPage`: cinco assuntos na ordem; data; "Ver Privacidade" navega; texto do "Ouvir".
  - `SettingsPage`: linha "Termos de uso" depois de "Privacidade", com e sem conta.
  - `LoginPage`: ordem e textos do login; sem divisor nem aviso; cadastro só ativa com aceite;
    links empilham as telas e, na volta, o formulário continua; aceite sobrevive à troca de aba.
  - Abertura: com `from=splash`, a marca parte do retângulo da splash e termina no slot do
    cabeçalho em 1 250 ms; com movimento reduzido, nasce pronta; sem `from=splash`, não há
    abertura.
  - `SplashPage`: o destino login navega para `/login?from=splash`.
  - `app_router`: `/settings/terms` e `/settings/privacy` abrem depois de "Sair da conta".
- **Regressão**: `splash_scene_painter_test` e os testes de login existentes, ajustados só onde a
  tela mudou de propósito.

## R10. Onboarding, avisos e "Sair da conta" continuam iguais

**Decisão**: só a splash passa `from=splash`. Onboarding, avisos do visitante, "Entrar ou criar
conta" das Configurações e o redirecionamento de "Sair da conta" continuam indo para `/login`
(ou `/login?mode=register…`) com o esmaecimento de hoje (FR-018).
