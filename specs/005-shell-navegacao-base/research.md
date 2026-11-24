# Research: Shell de navegação e base das trilhas

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-04

Sem NEEDS CLARIFICATION no Technical Context. As decisões abaixo resolvem as escolhas de
desenho levantadas ao ler o código, o plano do produto e o wireframe.

## R1. Cinco branches no `StatefulShellRoute.indexedStack`

**Decision**: o shell tem cinco `StatefulShellBranch`, na ordem da barra inferior: `/home`
(news), `/activities` (activities), `/reels` (news), `/help` (help) e `/profile` (profile). O
`AppShell` recebe o `StatefulNavigationShell` e troca de aba com
`navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)`
(tocar na aba ativa volta à raiz dela).

**Rationale**: `indexedStack` mantém cada aba viva (FR-002, inclusive o reel atual); os caminhos
continuam os do plano do produto (§2). Reels como aba central foi decisão da usuária (spec,
Assumptions).

**Alternatives considered**: `ShellRoute` simples (perde o estado ao trocar de aba); Reels como
rota de tela cheia (rejeitado pela usuária).

## R2. Telas "sobre as abas" no navegador raiz

**Decision**: um `rootNavigatorKey` em `lib/core/routing/navigator_keys.dart`. As telas sobre
as abas usam `parentNavigatorKey: rootNavigatorKey`:
- **filhas da aba** (mantêm o caminho do plano): `/activities/:moduleId`, `/help/contact/new`,
  `/help/contact/:id`, `/profile/edit`;
- **de topo**: `/news/:id`, `/notifications`, `/settings`, `/settings/account`,
  `/settings/security`, `/settings/accessibility`.

**Rationale**: no navegador raiz, a tela cobre a barra inferior e "voltar" retorna à aba no
mesmo estado (spec US1 cenários 5 e 7). Declarar `/activities/:moduleId` como filha da rota
`/activities` evita conflito de caminho com a raiz da aba.

**Alternatives considered**: telas dentro do navegador da aba (a barra inferior ficaria visível
no detalhe, contra o wireframe).

## R3. Rotas por módulo

**Decision**: cada módulo exporta pelo barrel:
- módulos com aba: uma `GoRoute` da raiz da aba (`newsHomeRoute`, `newsReelsRoute`,
  `activitiesTabRoute`, `helpTabRoute`, `profileTabRoute`), já com as filhas sobre as abas;
- `List<RouteBase> {modulo}Routes` com as rotas de topo (`newsRoutes`, `notificationsRoutes`,
  `settingsRoutes`).

O `app_router.dart` só compõe: rotas de raiz (splash, onboarding, auth) + o
`StatefulShellRoute` com as raízes das abas + as listas de topo.

**Rationale**: o plano do produto (§2, §6) fecha o `app_router.dart` depois da Fase 0; com
isso, cada trilha só edita o `{modulo}_routes.dart` do seu módulo (SC-006).

## R4. Reação ao fim da sessão

**Decision**:
- **Saída** (`SessionEndReason.userLogout`): `redirect` do `GoRouter` com
  `refreshListenable: session.sessionStatus`. Se o estado é `unauthenticated`, o motivo é
  `userLogout` e o caminho não é público (`/`, `/onboarding`, `/login`, `/forgot-password`),
  redireciona para `/login` (FR-014).
- **Expiração** (`SessionEndReason.expired`): o `redirect` não age. Um
  `SessionExpiredListener` (widget do `shell`, em volta do `AppShell`) ouve `sessionStatus` e,
  na transição de `authenticated` para `unauthenticated` com motivo `expired`, mostra um
  `SnackBar` com a ação "Entrar" pelo `rootScaffoldMessengerKey` (em
  `lib/core/routing/navigator_keys.dart`, ligado ao `MaterialApp.router`). Um aviso por
  transição (FR-013).

**Rationale**: segue o CB-003 e o FR-012a da feature 001: a expiração não tira a pessoa da tela.
O `SnackBar` pelo messenger raiz aparece também sobre as telas do navegador raiz (o `AppShell`
continua montado por baixo). Como o aviso depende da **transição**, vários 401 seguidos geram
um aviso só (o segundo `expire()` não muda o estado, a sessão já está desconectada).

**Alternatives considered**: `unauthenticated → /login` para todos os casos (texto original da
F0.9), que viola o CB-003; `Dialog` em vez de `SnackBar` (interrompe a pessoa, que é o que o
CB-003 quer evitar).

## R5. `requireAccount` no `shell`, sem ciclo com `notifications`

**Decision**: `Future<bool> requireAccount(BuildContext context)` no `shell`: conectado →
`true`; senão abre o `AccountRequiredSheet` (bottom sheet modal) e devolve `false`, sem chamar
usecase nem rede. Lê o estado pelo `UserSessionService` (via GetIt). Um sinalizador privado
impede abrir dois convites com toque duplo.

O botão do sino **não** chama `requireAccount` sozinho: o `AppTopBar` (do `shell`) recebe o
toque e faz `requireAccount` → `context.push('/notifications')`. O `NotificationBellButton` do
`notifications` só desenha o botão (e, na A6, o contador) e recebe `onPressed`.

**Rationale**:
- O plano do produto (§2) põe o `requireAccount` no `shell` e permite `shell → notifications`.
  Se o sino chamasse `requireAccount`, `notifications → shell` fecharia um ciclo.
- Ler o `UserSessionService` direto é permitido pela constituição (Seção "Regras Globais": UI
  pode obter um serviço registrado no GetIt) e segue o precedente da `HomePlaceholderPage`. Não
  há regra de negócio que justifique um usecase.

**Consequência no plano do produto (§1.3)**: as trilhas passam a importar o barrel do `shell`
(`requireAccount`, `AppTopBar`). Regra atualizada: "Todo módulo de feature → `shell`, exceto
`notifications`".

## R6. Barra superior colocada pela página, não pelo shell

**Decision**: o `AppTopBar(title, subtitle?)` é um widget público do `shell`. As páginas de
Início, Atividades e Ajuda o colocam no topo; Reels e Perfil não. Subtítulo padrão: "Olá,
{nome}" (conectado) ou "Bem-vindo" (visitante), reativo ao `sessionStatus`.

**Rationale**: a A3 precisa trocar o subtítulo ("3 notícias novas para você") sem editar o
`shell`, que fecha depois da Fase 0. O título também fica com a tela dona.

**Alternatives considered**: o `AppShell` desenhar a barra pelo índice da aba (exigiria mexer no
`shell` a cada mudança de subtítulo).

## R7. Telas provisórias e "não encontrada"

**Decision**:
- `ComingSoonView(title)` em `lib/core/widgets/coming_soon_view.dart`: corpo com ícone,
  título e "Em breve". Cada módulo tem a sua página placeholder (F0.7), que usa o
  `ComingSoonView` (e o `AppTopBar` nas abas que têm barra superior; `Scaffold` com `AppBar`
  de voltar nas telas sobre as abas).
- `NotFoundPage` em `lib/core/routing/not_found_page.dart`, ligada ao `errorBuilder` do
  `GoRouter`, com botão "Voltar ao Início" (`go('/home')`) (FR-007).
- `HomePlaceholderPage` e as chaves `home_placeholder_*` são removidas (FR-021).

## R8. Estados comuns no design system

**Decision**: quatro widgets em `lib/core/widgets/`, sem dependência de módulo:
- `SafeLoadingState({String? message})`: `CircularProgressIndicator` `primary` + texto 16
  opcional; `Semantics(liveRegion: true, label: "Carregando")`.
- `SafeErrorState({required String message, required VoidCallback onRetry})`: mensagem 16
  centralizada + `SafeButton` compacto "Tentar novamente" com área mínima de 48 dp.
- `SafeEmptyState({IconData icon, String? message, String? actionLabel, VoidCallback? onAction})`:
  ícone 40 `muted-foreground`, mensagem (padrão `common_empty`) e botão opcional.
- `SafeOfflineBanner()`: faixa `warning` 10% com ícone `WifiOff` e `common_offline_banner`.

Os textos recebidos já vêm traduzidos (a tela faz `failure.message.tr()`); os padrões usam as
chaves `common_*`. Entram no style guide (`lib/style_guide/style_guide.dart`) numa seção
"Estados", importando os widgets reais de `core/widgets` (com `show`, para não colidir com as
cópias locais do style guide).

**48 dp**: `ConstrainedBox(minWidth: 48, minHeight: 48)` em volta do botão compacto; teste mede
com `tester.getSize`.

## R9. Teste de fumaça sem plataforma

**Decision**: `test/widget_test.dart` passa a subir o app real:
- `SharedPreferences.setMockInitialValues({'onboarding_seen': true})`;
- módulos reais registrados por `ModuleManager`, com `SecureStorageService` trocado por
  `FakeSecureStorageService` já com o registro de visitante (`{"status":"guest"}`) **antes** da
  primeira resolução (os registros do `CommonModule` são lazy);
- `restoreSession()`, `buildAppRouter(...)` e `ClickSeguroApp`;
- relógio falso para os 2 s do splash; depois toca nas cinco abas e confere cada tela.

Visitante não faz nenhum pedido de rede (a conferência da conta só roda conectado).

Para isso, o `main.dart` passa a expor `ClickSeguroApp(router:)` e o `app_router.dart` uma
função `buildAppRouter(UserSessionService session)` (hoje é uma variável global), o que também
deixa cada teste com um roteador novo.

## R10. Blocos de i18n

**Decision**: em `AppStrings`, um bloco comentado por módulo, na ordem do §1.4 (`// --- common
---`, `// --- shell ---`, `// --- news ---`, `// --- notifications ---`, `// --- activities
---`, `// --- help ---`, `// --- profile ---`, `// --- settings ---`), com as chaves iniciais
listadas no [data-model.md](data-model.md#chaves-de-i18n). Nos JSONs, as chaves de cada prefixo
ficam juntas. Um teste confere que toda chave dos prefixos novos existe em pt-BR e en-US e que
não sobrou `home_placeholder_*`.

O `i18n_keys_test.dart` do `authentication` deixa de cobrir `home_placeholder_` (prefixo
removido).

## R11. "Voltar" do aparelho

**Decision**: no `AppShell`, `PopScope(canPop: navigationShell.currentIndex == 0, ...)`: em outra
aba, o "voltar" faz `goBranch(0)` (FR-008). Telas empilhadas dentro da aba ou no navegador raiz
são desempilhadas antes pelo próprio go_router.
