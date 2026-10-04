# Contrato: rotas do app

**Feature**: [spec.md](../spec.md) · **Date**: 2026-10-04

Caminhos do [plano do produto](../../../.specify/memory/plan.md) §2 (contrato entre as trilhas;
não mudam sem combinar). "Navegador": `raiz` = cobre a barra inferior; `aba N` = dentro da aba.

| Caminho | Tela provisória | Módulo (arquivo de rotas) | Navegador | Declarada como |
|---|---|---|---|---|
| `/` | Splash (real) | splash | raiz | rota de raiz no `app_router` |
| `/onboarding` | Onboarding (real) | onboarding | raiz | rota de raiz no `app_router` |
| `/login` | Login (real) | authentication | raiz | `authenticationRoutes` |
| `/forgot-password` | Recuperar senha (real) | authentication | raiz | `authenticationRoutes` |
| `/home` | Início — "Notícias seguras" | news (`news_routes.dart`) | aba 0 | `newsHomeRoute` |
| `/activities` | Atividades | activities | aba 1 | `activitiesTabRoute` |
| `/activities/:moduleId` | Atividade | activities | raiz | filha de `activitiesTabRoute` |
| `/reels?start=:newsId` | Reels | news | aba 2 | `newsReelsRoute` (lê `start`, opcional) |
| `/help` | Central de ajuda | help | aba 3 | `helpTabRoute` |
| `/help/contact/new` | Contato | help | raiz | filha de `helpTabRoute` |
| `/help/contact/:id` | Contato | help | raiz | filha de `helpTabRoute` |
| `/profile` | Perfil | profile | aba 4 | `profileTabRoute` |
| `/profile/edit` | Editar dados | profile | raiz | filha de `profileTabRoute` |
| `/news/:id` | Notícia | news | raiz | `newsRoutes` |
| `/notifications` | Alertas | notifications | raiz | `notificationsRoutes` |
| `/settings` | Configurações | settings | raiz | `settingsRoutes` |
| `/settings/account` | Dados pessoais | settings | raiz | filha de `/settings` |
| `/settings/security` | Segurança | settings | raiz | filha de `/settings` |
| `/settings/accessibility` | Acessibilidade | settings | raiz | filha de `/settings` |
| qualquer outro | Página não encontrada | core | raiz | `errorBuilder` |

## Regras

- Trocar de aba: `navigationShell.goBranch(i)`; ir a uma aba de fora do shell: `context.go(caminho)`.
- Abrir tela sobre as abas: `context.push(caminho)` (o "voltar" retorna à aba no mesmo estado).
- Redirect: só `userLogout` + caminho não público → `/login` (ver [data-model](../data-model.md)).
- Depois desta feature, `app_router.dart` e `main.dart` ficam fechados (plano do produto §6):
  cada trilha edita só o `{modulo}_routes.dart`.
