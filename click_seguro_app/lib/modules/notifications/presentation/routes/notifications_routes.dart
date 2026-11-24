import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/notifications/presentation/pages/notifications_page.dart';
import 'package:go_router/go_router.dart';

/// Telas do módulo sobre as abas.
final List<RouteBase> notificationsRoutes = [
  GoRoute(
    path: '/notifications',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const NotificationsPage(),
  ),
];
