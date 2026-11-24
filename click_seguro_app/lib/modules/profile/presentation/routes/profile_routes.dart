import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/achievements_page.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/profile_edit_page.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/profile_page.dart';
import 'package:go_router/go_router.dart';

/// Raiz da aba Perfil, com a edição de dados e a lista de conquistas sobre
/// as abas.
final GoRoute profileTabRoute = GoRoute(
  path: ProfilePage.path,
  builder: (context, state) => const ProfilePage(),
  routes: [
    GoRoute(
      path: 'edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProfileEditPage(),
    ),
    // Vinda da aba, traz a lista no `extra`; por link direto, carrega.
    GoRoute(
      path: 'achievements',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => AchievementsPage(
        achievements: state.extra is List<AchievementEntity>
            ? state.extra as List<AchievementEntity>
            : null,
      ),
    ),
  ],
);
