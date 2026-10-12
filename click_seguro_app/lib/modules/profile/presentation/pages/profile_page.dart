import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/area_state.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_controller.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_status.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/achievements_section.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/area_notice.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/guest_invite.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/profile_cta_card.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/profile_header_card.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/stat_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Aba Perfil (B7, specs/012-perfil): com conta, cartão, números,
/// conquistas e atalhos; visitante, o convite.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String path = '/profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<UserSessionStatus>(
          valueListenable: GetIt.instance<UserSessionService>().sessionStatus,
          builder: (context, status, _) =>
              status == UserSessionStatus.authenticated
              ? ChangeNotifierProvider<ProfileController>(
                  create: (_) => GetIt.instance<ProfileController>()..load(),
                  child: const _AccountProfile(),
                )
              : const _WithHeader(
                  child: SingleChildScrollView(
                    padding: _padding,
                    child: GuestInvite(),
                  ),
                ),
        ),
      ),
    );
  }
}

const EdgeInsets _padding = EdgeInsets.fromLTRB(
  AppSpacing.s5,
  AppSpacing.s2,
  AppSpacing.s5,
  AppSpacing.s6,
);

/// Título fixo no topo e o conteúdo da aba abaixo.
class _WithHeader extends StatelessWidget {
  const _WithHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s6,
            AppSpacing.s5,
            AppSpacing.s3,
          ),
          child: _Header(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Título "Perfil" e a engrenagem das configurações.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              AppStrings.profileTitle.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: colors.secondary,
              ),
            ),
          ),
        ),
        Tooltip(
          message: AppStrings.profileSettings.tr(),
          child: Material(
            color: colors.card,
            shape: CircleBorder(side: BorderSide(color: colors.border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/settings'),
              child: SizedBox.square(
                dimension: 48,
                child: Icon(
                  LucideIcons.settings,
                  size: 22,
                  color: colors.secondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountProfile extends StatefulWidget {
  const _AccountProfile();

  @override
  State<_AccountProfile> createState() => _AccountProfileState();
}

/// Atualiza ao voltar à aba (FR-007, R4): a aba fica viva no shell, então
/// ouve o roteador e recarrega quando o caminho volta a ser `/profile`
/// (troca de aba ou volta de uma tela aberta daqui).
class _AccountProfileState extends State<_AccountProfile> {
  GoRouterDelegate? _delegate;
  String? _lastPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GoRouterDelegate delegate = GoRouter.of(context).routerDelegate;
    if (delegate == _delegate) return;
    _delegate?.removeListener(_onRouteChanged);
    _delegate = delegate..addListener(_onRouteChanged);
    _lastPath = _currentPath;
  }

  String? get _currentPath => _delegate?.currentConfiguration.uri.path;

  void _onRouteChanged() {
    final String? path = _currentPath;
    final bool returned =
        path == ProfilePage.path && _lastPath != ProfilePage.path;
    _lastPath = path;
    if (returned && mounted) _refresh();
  }

  /// Quantas vezes a aba já atualizou: evita atualizar duas vezes na volta.
  int _refreshes = 0;

  void _refresh() {
    _refreshes++;
    unawaited(context.read<ProfileController>().refresh());
  }

  /// Abre uma tela sobre a aba e atualiza na volta. O `pop` não avisa o
  /// roteador; se um dia avisar, o ouvinte já atualizou e nada se repete.
  Future<void> _open(String location, {Object? extra}) async {
    final int before = _refreshes;
    await context.push<void>(location, extra: extra);
    if (!mounted || _refreshes != before) return;
    _lastPath = _currentPath;
    _refresh();
  }

  @override
  void dispose() {
    _delegate?.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = context.watch<ProfileController>();
    return _WithHeader(
      child: switch (controller.status) {
        ProfileStatus.loading => const SafeLoadingState(),
        ProfileStatus.error => SafeErrorState(
          message: (controller.failure?.message ?? AppStrings.errorGeneric)
              .tr(),
          onRetry: controller.load,
        ),
        ProfileStatus.loaded => _LoadedProfile(
          controller: controller,
          open: _open,
        ),
      },
    );
  }
}

class _LoadedProfile extends StatelessWidget {
  const _LoadedProfile({required this.controller, required this.open});

  final ProfileController controller;
  final Future<void> Function(String location, {Object? extra}) open;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return ListView(
      padding: _padding,
      children: [
        ProfileHeaderCard(
          profile: controller.profile!,
          onEdit: () => open('/profile/edit'),
          footer: _Stats(
            state: controller.counts,
            onRetry: controller.retryCounts,
            open: open,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        AchievementsSection(
          state: controller.achievements,
          achievedCount: controller.achievedCount,
          onSeeAll: (List<AchievementEntity> achievements) =>
              open('/profile/achievements', extra: achievements),
          onRetry: controller.retryAchievements,
        ),
        const SizedBox(height: AppSpacing.s4),
        ProfileCtaCard(
          icon: LucideIcons.newspaper,
          title: AppStrings.profileCtaNewsTitle.tr(),
          subtitle: AppStrings.profileCtaNewsSub.tr(),
          background: colors.secondary,
          onTap: () => context.go('/home'),
        ),
        const SizedBox(height: AppSpacing.s3),
        ProfileCtaCard(
          icon: LucideIcons.puzzle,
          title: AppStrings.profileCtaActivitiesTitle.tr(),
          subtitle: AppStrings.profileCtaActivitiesSub.tr(),
          background: colors.primary,
          onTap: () => context.go('/activities'),
        ),
      ],
    );
  }
}

/// Lidas, salvas e curtidas; cada uma abre a sua lista (US4).
class _Stats extends StatelessWidget {
  const _Stats({
    required this.state,
    required this.onRetry,
    required this.open,
  });

  final AreaState<NewsCountsEntity> state;
  final VoidCallback onRetry;
  final Future<void> Function(String location) open;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return switch (state) {
      AreaLoading() => Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Center(child: CircularProgressIndicator(color: colors.primary)),
      ),
      AreaFailed() => AreaNotice(
        message: AppStrings.profileStatsFailed.tr(),
        onRetry: onRetry,
      ),
      AreaLoaded(:final value) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, stat) in [
              (
                LucideIcons.bookOpenCheck,
                colors.secondary,
                value.read,
                AppStrings.profileStatRead,
                AppStrings.profileStatReadSemantic,
                '/news/read',
              ),
              (
                LucideIcons.bookmark,
                colors.warning,
                value.saved,
                AppStrings.profileStatSaved,
                AppStrings.profileStatSavedSemantic,
                '/news/saved',
              ),
              (
                LucideIcons.heart,
                colors.primary,
                value.liked,
                AppStrings.profileStatLiked,
                AppStrings.profileStatLikedSemantic,
                '/news/liked',
              ),
            ].indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: StatTile(
                  icon: stat.$1,
                  color: stat.$2,
                  count: stat.$3,
                  label: stat.$4.tr(),
                  semanticLabel: stat.$5.tr(args: ['${stat.$3}']),
                  onTap: () => open(stat.$6),
                ),
              ),
            ],
          ],
        ),
      ),
    };
  }
}
