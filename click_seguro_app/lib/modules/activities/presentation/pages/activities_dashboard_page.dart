import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_status.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/module_card.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/overall_progress_card.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

/// Aba Atividades: progresso geral e os módulos (B1, specs/015-painel-atividades).
class ActivitiesDashboardPage extends StatelessWidget {
  const ActivitiesDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: AppStrings.activitiesTitle.tr()),
            Expanded(
              child: ChangeNotifierProvider<ActivitiesDashboardController>(
                create: (_) =>
                    GetIt.instance<ActivitiesDashboardController>()..load(),
                child: const _DashboardBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final ActivitiesDashboardController controller = context
        .watch<ActivitiesDashboardController>();
    final ActivitiesDashboardEntity? dashboard = controller.dashboard;
    return switch (controller.status) {
      ActivitiesDashboardStatus.loading => const SafeLoadingState(),
      ActivitiesDashboardStatus.loaded when dashboard != null => _Dashboard(
        dashboard: dashboard,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.dashboard});

  final ActivitiesDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    // Escala total da letra (sistema × app, B9): duas colunas só no tamanho
    // normal (clarificação de 2026-10-19, R8).
    final bool twoColumns =
        MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s2,
        AppSpacing.s5,
        AppSpacing.s6,
      ),
      children: [
        if (dashboard.hasOverallProgress) ...[
          OverallProgressCard(dashboard: dashboard),
          const SizedBox(height: AppSpacing.s4),
        ],
        if (twoColumns)
          for (int i = 0; i < dashboard.modules.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _card(dashboard.modules[i], compact: true)),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: i + 1 < dashboard.modules.length
                          ? _card(dashboard.modules[i + 1], compact: true)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            )
        else
          for (final ModuleSummaryEntity module in dashboard.modules)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: _card(module, compact: false),
            ),
      ],
    );
  }

  Widget _card(ModuleSummaryEntity module, {required bool compact}) =>
      ModuleCard(module: module, compact: compact);
}
