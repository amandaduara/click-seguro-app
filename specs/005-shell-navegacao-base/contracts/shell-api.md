# Contrato: API pública do shell e do design system

**Feature**: [spec.md](../spec.md) · **Date**: 2026-10-04

O que as trilhas podem usar a partir desta feature. Assinaturas em Dart (resumidas).

## `shell` (barrel `package:click_seguro_app/modules/shell/shell.dart`)

```text
ShellModule                              registrado por último no main.dart

Future<bool> requireAccount(BuildContext context)
  conectado → true; visitante/sem sessão → abre AccountRequiredSheet e devolve false.
  Nunca chama rede. Use ANTES de qualquer usecase de ação restrita (RN-003).

AppTopBar({required String title, String? subtitle})
  título 24/700 secondary; subtítulo padrão "Olá, {nome}" / "Bem-vindo";
  botões Notificações (requireAccount → push /notifications) e Configurações (push /settings).
  Use no topo das páginas de Início, Atividades e Ajuda.

AppShell / SessionExpiredListener / AccountRequiredSheet   internos (usados pelo app_router)
```

## `notifications` (barrel)

```text
NotificationBellButton({required VoidCallback onPressed})
  botão redondo 48, ícone Bell, rótulo "Notificações". A6 acrescenta o contador.
  NÃO chama requireAccount (quem decide é o AppTopBar).
```

## `core/widgets`

```text
SafeLoadingState({String? message})
SafeErrorState({required String message, required VoidCallback onRetry})
SafeEmptyState({IconData icon = LucideIcons.inbox, String? message,
                String? actionLabel, VoidCallback? onAction})
SafeOfflineBanner()
ComingSoonView({required String title})       corpo das telas provisórias
```

Textos recebidos já traduzidos; padrões vêm das chaves `common_*`. Botões com área ≥ 48 dp.

## `core/routing`

```text
rootNavigatorKey             GlobalKey<NavigatorState> — parentNavigatorKey das telas sobre as abas
rootScaffoldMessengerKey     GlobalKey<ScaffoldMessengerState> — avisos globais
GoRouter buildAppRouter(UserSessionService session)
NotFoundPage                 errorBuilder
```
