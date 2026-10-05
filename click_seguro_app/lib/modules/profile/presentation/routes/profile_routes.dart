import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/profile_edit_page.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/profile_page.dart';
import 'package:go_router/go_router.dart';

/// Raiz da aba Perfil, com a edição de dados sobre as abas.
final GoRoute profileTabRoute = GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfilePage(),
  routes: [
    GoRoute(
      path: 'edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProfileEditPage(),
    ),
  ],
);
