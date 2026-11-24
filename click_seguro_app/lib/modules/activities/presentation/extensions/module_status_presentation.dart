import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Selo de cada status: rótulo escrito, cor e ícone (FR-004).
extension ModuleStatusPresentation on ModuleStatus {
  String get label => switch (this) {
    ModuleStatus.notStarted => AppStrings.activitiesStatusNotStarted,
    ModuleStatus.inProgress => AppStrings.activitiesStatusInProgress,
    ModuleStatus.completed => AppStrings.activitiesStatusCompleted,
    ModuleStatus.retry => AppStrings.activitiesStatusRetry,
    ModuleStatus.unavailable => AppStrings.activitiesStatusUnavailable,
  }.tr();

  /// Cor do ícone no selo sobre a capa do cartão (redesign 2.0).
  Color iconColor(AppPalette colors) => switch (this) {
    ModuleStatus.notStarted => colors.textMutedForeground,
    ModuleStatus.inProgress => colors.warning,
    ModuleStatus.completed => colors.success,
    // Atenção: concluído, mas vale refazer (specs/025).
    ModuleStatus.retry => colors.warning,
    ModuleStatus.unavailable => colors.textMutedForeground,
  };

  IconData get icon => switch (this) {
    ModuleStatus.notStarted => LucideIcons.circle,
    ModuleStatus.inProgress => LucideIcons.circleDashed,
    ModuleStatus.completed => LucideIcons.circleCheck,
    ModuleStatus.retry => LucideIcons.rotateCcw,
    ModuleStatus.unavailable => LucideIcons.lock,
  };
}
