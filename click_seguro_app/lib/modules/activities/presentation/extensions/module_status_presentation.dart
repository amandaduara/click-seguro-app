import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Selo de cada status: rótulo escrito, cor e ícone (FR-004).
extension ModuleStatusPresentation on ModuleStatus {
  String get label => switch (this) {
    ModuleStatus.notStarted => AppStrings.activitiesStatusNotStarted,
    ModuleStatus.inProgress => AppStrings.activitiesStatusInProgress,
    ModuleStatus.completed => AppStrings.activitiesStatusCompleted,
    ModuleStatus.unavailable => AppStrings.activitiesStatusUnavailable,
  }.tr();

  SafeBadgeTone get badgeTone => switch (this) {
    ModuleStatus.notStarted => SafeBadgeTone.neutral,
    ModuleStatus.inProgress => SafeBadgeTone.primary,
    ModuleStatus.completed => SafeBadgeTone.success,
    ModuleStatus.unavailable => SafeBadgeTone.neutral,
  };

  IconData get icon => switch (this) {
    ModuleStatus.notStarted => LucideIcons.circle,
    ModuleStatus.inProgress => LucideIcons.circleDashed,
    ModuleStatus.completed => LucideIcons.circleCheck,
    ModuleStatus.unavailable => LucideIcons.lock,
  };
}
