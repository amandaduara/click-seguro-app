import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Textos, ícone e cores de uma medalha (R3 de specs/012-perfil).
extension AchievementPresentation on AchievementEntity {
  /// Quanto a segunda cor do gradiente clareia a primeira.
  static const double _lighten = 0.35;

  String get title => switch (kind) {
    AchievementKind.firstLesson => AppStrings.profileAchFirstLesson.tr(),
    AchievementKind.firstModule => AppStrings.profileAchFirstModule.tr(),
    AchievementKind.dedicatedStudent =>
      AppStrings.profileAchDedicatedStudent.tr(),
    AchievementKind.securityMaster => AppStrings.profileAchSecurityMaster.tr(),
    AchievementKind.attentiveReader =>
      AppStrings.profileAchAttentiveReader.tr(),
    AchievementKind.dedicatedReader =>
      AppStrings.profileAchDedicatedReader.tr(),
    AchievementKind.module => moduleTitle ?? '',
  };

  /// "8 de 10 lições"; o número nunca passa do alvo.
  String get progressLabel {
    final String key = switch (kind) {
      AchievementKind.firstLesson ||
      AchievementKind.dedicatedStudent ||
      AchievementKind.module => AppStrings.profileAchProgressLessons,
      AchievementKind.firstModule ||
      AchievementKind.securityMaster => AppStrings.profileAchProgressModules,
      AchievementKind.attentiveReader ||
      AchievementKind.dedicatedReader => AppStrings.profileAchProgressNews,
    };
    final int shown = current > target ? target : current;
    return key.tr(args: ['$shown', '$target']);
  }

  IconData get icon => switch (kind) {
    AchievementKind.firstLesson => LucideIcons.bookOpen,
    AchievementKind.firstModule => LucideIcons.award,
    AchievementKind.dedicatedStudent => LucideIcons.graduationCap,
    AchievementKind.securityMaster => LucideIcons.shieldCheck,
    AchievementKind.attentiveReader => LucideIcons.newspaper,
    AchievementKind.dedicatedReader => LucideIcons.bookMarked,
    AchievementKind.module => LucideIcons.medal,
  };

  /// As duas cores do disco da medalha. Fixas por tipo; as de módulo
  /// alternam pelo `order` do módulo.
  (Color, Color) medalColors(AppPalette palette) {
    final Color base = switch (kind) {
      AchievementKind.firstLesson => palette.primary,
      AchievementKind.firstModule => palette.success,
      AchievementKind.dedicatedStudent => palette.warning,
      AchievementKind.securityMaster => palette.secondary,
      AchievementKind.attentiveReader => palette.success,
      AchievementKind.dedicatedReader => palette.primary,
      AchievementKind.module => [
        palette.primary,
        palette.success,
        palette.warning,
        palette.secondary,
      ][((moduleOrder ?? 1) - 1) % 4],
    };
    return (base, Color.lerp(base, Colors.white, _lighten)!);
  }
}
