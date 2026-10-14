import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/area_state.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_controller.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_status.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/guest_invite.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/medal_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

/// Todas as conquistas, na ordem da aba (R9). Recebe a lista já calculada;
/// sem ela (link direto), carrega como a aba.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, this.achievements});

  final List<AchievementEntity>? achievements;

  @override
  Widget build(BuildContext context) {
    final List<AchievementEntity>? given = achievements;
    final bool hasAccount =
        GetIt.instance<UserSessionService>().isAuthenticated;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.profileAchievements.tr())),
      body: SafeArea(
        child: given != null
            ? _Grid(achievements: given)
            : hasAccount
            ? ChangeNotifierProvider<ProfileController>(
                create: (_) => GetIt.instance<ProfileController>()..load(),
                child: const _LoadingGrid(),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.s5),
                children: const [GuestInvite()],
              ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = context.watch<ProfileController>();
    if (controller.status == ProfileStatus.error) {
      return SafeErrorState(
        message: (controller.failure?.message ?? AppStrings.errorGeneric).tr(),
        onRetry: controller.load,
      );
    }
    return switch (controller.achievements) {
      AreaLoading() => const SafeLoadingState(),
      AreaFailed(:final failure) => SafeErrorState(
        message: failure.message.tr(),
        onRetry: controller.retryAchievements,
      ),
      AreaLoaded(:final value) => _Grid(achievements: value),
    };
  }
}

/// Duas colunas; cada linha tem a altura do cartão mais alto (fonte grande).
class _Grid extends StatelessWidget {
  const _Grid({required this.achievements});

  final List<AchievementEntity> achievements;

  @override
  Widget build(BuildContext context) {
    final int rows = (achievements.length + 1) ~/ 2;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s5),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (_, row) {
        final int first = row * 2;
        final bool hasSecond = first + 1 < achievements.length;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: MedalCard(achievement: achievements[first])),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: hasSecond
                    ? MedalCard(achievement: achievements[first + 1])
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }
}
