import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/alerts_status.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';
import 'package:click_seguro_app/modules/notifications/presentation/extensions/alerts_grouping.dart';
import 'package:click_seguro_app/modules/notifications/presentation/widgets/alert_tile.dart';
import 'package:click_seguro_app/modules/notifications/presentation/widgets/alerts_notices.dart';
import 'package:click_seguro_app/modules/notifications/presentation/widgets/alerts_summary_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Alertas (RF-020 a RF-022, specs/011-alertas-locais): resumo e faixas fixos
/// no alto, alertas agrupados em Hoje, Ontem e Anteriores. Ao abrir, confere
/// as notícias novas na hora (R2). Tocar num alerta o marca como lido e abre
/// a notícia por caminho (`/news/:id`), sem importar o módulo `news`.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsController _controller;

  /// Evita abrir a mesma notícia duas vezes com toque duplo.
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<NotificationsController>();
    // Fora do build: a conferência avisa os ouvintes na hora.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.checkNew(force: true));
    });
  }

  Future<void> _openAlert(AlertEntity alert) async {
    if (_opening) return;
    _opening = true;
    unawaited(_controller.markAsRead(alert.newsId));
    try {
      await context.push<void>('/news/${alert.newsId}');
    } finally {
      if (mounted) _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.notificationsTitle.tr())),
      body: SafeArea(
        child: ValueListenableBuilder<UserSessionStatus>(
          valueListenable: GetIt.instance<UserSessionService>().sessionStatus,
          builder: (context, status, _) =>
              status == UserSessionStatus.authenticated
              ? _buildAlerts(context.watch<NotificationsController>())
              : const _GuestInvite(),
        ),
      ),
    );
  }

  Widget _buildAlerts(NotificationsController controller) {
    if (controller.status == AlertsStatus.loading) {
      return const SizedBox.shrink();
    }
    final Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.alerts.isNotEmpty)
          AlertsSummaryBar(
            unreadCount: controller.unreadCount,
            onMarkAll: () => unawaited(controller.markAllAsRead()),
          ),
        AlertsNotices(
          showOffline: controller.lastCheckFailure is ConnectionFailure,
          showDisabled: controller.receiveAlerts == false,
        ),
      ],
    );
    // Com letra grande o alto fixo tomaria a tela: entra na lista e há uma
    // única rolagem, sem gesto escondido (R12, specs/011-alertas-locais).
    final bool largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    if (largeText) {
      return controller.alerts.isEmpty
          ? ListView(children: [header, const _EmptyAlertsContent()])
          : _AlertsList(
              alerts: controller.alerts,
              now: controller.now,
              onOpen: _openAlert,
              header: header,
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: controller.alerts.isEmpty
              ? const _EmptyAlerts()
              : _AlertsList(
                  alerts: controller.alerts,
                  now: controller.now,
                  onOpen: _openAlert,
                ),
        ),
      ],
    );
  }
}

/// Convite dentro da tela: texto curto e um botão grande para o login, sem
/// pedido ao serviço (mesmo padrão das notícias salvas).
class _GuestInvite extends StatelessWidget {
  const _GuestInvite();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              LucideIcons.bell,
              size: 40,
              color: context.colors.textMutedForeground,
            ),
            const SizedBox(height: AppSpacing.s3),
            Semantics(
              header: true,
              child: Text(
                AppStrings.commonAccountRequiredTitle.tr(),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              AppStrings.notificationsGuestBody.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.s6),
            SafeButton(
              label: AppStrings.commonAccountRequiredAction.tr(),
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList({
    required this.alerts,
    required this.now,
    required this.onOpen,
    this.header,
  });

  final List<AlertEntity> alerts;
  final DateTime now;
  final ValueChanged<AlertEntity> onOpen;

  /// Resumo, botão e faixas como primeiros itens (letra grande); sem ele o
  /// alto fica fixo fora da lista.
  final Widget? header;

  static String _title(AlertGroup group) => switch (group) {
    AlertGroup.today => AppStrings.notificationsGroupToday.tr(),
    AlertGroup.yesterday => AppStrings.notificationsGroupYesterday.tr(),
    AlertGroup.earlier => AppStrings.notificationsGroupEarlier.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.only(
        top: header == null ? AppSpacing.s2 : 0,
        bottom: AppSpacing.s6,
      ),
      children: [
        ?header,
        for (final AlertSection section in alerts.sections(now)) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s5,
              right: AppSpacing.s5,
              top: AppSpacing.s4,
              bottom: AppSpacing.s3,
            ),
            child: Semantics(
              header: true,
              child: Text(
                _title(section.group),
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.secondary,
                ),
              ),
            ),
          ),
          for (final AlertEntity alert in section.alerts)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s5,
                right: AppSpacing.s5,
                bottom: AppSpacing.s3,
              ),
              child: AlertTile(
                key: ValueKey('alert-${alert.newsId}'),
                alert: alert,
                now: now,
                onTap: () => onOpen(alert),
              ),
            ),
        ],
      ],
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(child: _EmptyAlertsContent()),
    );
  }
}

class _EmptyAlertsContent extends StatelessWidget {
  const _EmptyAlertsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeEmptyState(
          icon: LucideIcons.bell,
          message: AppStrings.notificationsEmpty.tr(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
          child: Text(
            AppStrings.notificationsEmptyHint.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: context.colors.textMutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
