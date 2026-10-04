# Data Model: Shell de navegação e base das trilhas

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-04

Nenhum dado novo é persistido. A feature organiza navegação e reage a estados que já existem.

## Abas

| Índice | Rótulo (chave) | Ícone Lucide | Caminho raiz | Módulo | Barra superior (título) |
|---|---|---|---|---|---|
| 0 | Início (`shell_tab_home`) | `house` | `/home` | news | sim ("Notícias seguras", `news_title`) |
| 1 | Atividades (`shell_tab_activities`) | `graduationCap` | `/activities` | activities | sim ("Atividades", `activities_title`) |
| 2 | Notícias (`shell_tab_news`) | `newspaper` (botão central) | `/reels` | news | não |
| 3 | Ajuda (`shell_tab_help`) | `lifeBuoy` | `/help` | help | sim ("Central de ajuda", `help_title`) |
| 4 | Perfil (`shell_tab_profile`) | `user` | `/profile` | profile | não |

Estado de cada aba: preservado pelo `indexedStack` enquanto o shell estiver montado.

## Reação ao estado da sessão

Entrada: `UserSessionService.sessionStatus` (observável) e `endReason` (features 001/002).

| Transição | Motivo | Reação | Requisito |
|---|---|---|---|
| `authenticated` → `unauthenticated` | `expired` | Fica na tela; `SnackBar` "Sua sessão expirou, faça login novamente." com ação "Entrar" (`go('/login')`), uma vez | FR-013 |
| qualquer → `unauthenticated` | `userLogout` | `redirect` para `/login` se o caminho não for público | FR-014 |
| `unauthenticated` (início do app, motivo nulo) | — | Nenhuma (o splash decide) | — |
| → `authenticated` / `guest` | — | Nenhuma (quem entrou já navegou para `/home`) | — |

Caminhos públicos (sem redirect): `/`, `/onboarding`, `/login`, `/forgot-password`.

## Decisão do `requireAccount`

| Estado da sessão | Resultado | Efeito |
|---|---|---|
| `authenticated` | `true` | nenhum |
| `guest` | `false` | abre o convite |
| `unauthenticated` (ex.: depois de expirar) | `false` | abre o convite |
| convite já aberto | `false` | não abre outro |

Convite: "Entrar ou criar conta" → fecha e `go('/login')`; "Agora não" ou arrastar para baixo →
fecha, sem navegar. Nenhum caso chama rede.

## Chaves de i18n

Textos pt-BR (en-US em paralelo). Removidas: `home_placeholder_greeting`,
`home_placeholder_welcome`, `home_placeholder_body`.

| Bloco | Chave | pt-BR |
|---|---|---|
| common | `common_try_again` | Tentar novamente |
| common | `common_loading` | Carregando |
| common | `common_empty` | Nada por aqui ainda. |
| common | `common_offline_banner` | Você está sem internet. Mostrando o conteúdo salvo. |
| common | `common_coming_soon` | Em breve |
| common | `common_back_home` | Voltar ao Início |
| common | `common_not_found_title` | Página não encontrada |
| common | `common_account_required_title` | Entre na sua conta |
| common | `common_account_required_body` | Para usar esta função, entre ou crie uma conta. É rápido e gratuito. |
| common | `common_account_required_action` | Entrar ou criar conta |
| common | `common_account_required_dismiss` | Agora não |
| common | `common_session_expired_action` | Entrar |
| shell | `shell_tab_home` | Início |
| shell | `shell_tab_activities` | Atividades |
| shell | `shell_tab_news` | Notícias |
| shell | `shell_tab_help` | Ajuda |
| shell | `shell_tab_profile` | Perfil |
| shell | `shell_nav_label` | Navegação principal |
| shell | `shell_greeting` | Olá, {} |
| shell | `shell_welcome` | Bem-vindo |
| shell | `shell_notifications` | Notificações |
| shell | `shell_settings` | Configurações |
| news | `news_title` | Notícias seguras |
| news | `news_reels_title` | Reels |
| news | `news_detail_title` | Notícia |
| notifications | `notifications_title` | Alertas |
| activities | `activities_title` | Atividades |
| activities | `activities_module_title` | Atividade |
| help | `help_title` | Central de ajuda |
| help | `help_contact_title` | Contato |
| profile | `profile_title` | Perfil |
| profile | `profile_edit_title` | Editar dados |
| settings | `settings_title` | Configurações |
| settings | `settings_account_title` | Dados pessoais |
| settings | `settings_security_title` | Segurança |
| settings | `settings_accessibility_title` | Acessibilidade |

O aviso de sessão expirada reaproveita `error_session_expired` (já existe).
