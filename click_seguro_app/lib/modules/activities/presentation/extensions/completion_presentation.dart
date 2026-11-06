import 'package:click_seguro_app/core/constants/app_identity.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/completion_page.dart';
import 'package:easy_localization/easy_localization.dart';

/// Faixa da mensagem da conclusão (FR-003).
enum ModuleCompletionTier { perfect, good, retry }

extension ModuleCompletionPresentation on ModuleCompletion {
  /// Todas certas; pelo menos metade; menos da metade. Sem pontuação, a
  /// mensagem neutra de parabéns.
  ModuleCompletionTier get tier {
    final ModuleScoreEntity? value = score;
    if (value == null) return ModuleCompletionTier.good;
    if (value.score == value.total) return ModuleCompletionTier.perfect;
    return value.score * 2 >= value.total
        ? ModuleCompletionTier.good
        : ModuleCompletionTier.retry;
  }

  String get messageKey => switch (tier) {
    ModuleCompletionTier.perfect => AppStrings.activitiesCompletionPerfect,
    ModuleCompletionTier.good => AppStrings.activitiesCompletionGood,
    ModuleCompletionTier.retry => AppStrings.activitiesCompletionRetry,
  };

  /// "Você acertou X de Y", ou `null` sem pontuação.
  String? get scoreText {
    final ModuleScoreEntity? value = score;
    return value == null
        ? null
        : AppStrings.activitiesCompletionScore.tr(
            args: ['${value.score}', '${value.total}'],
          );
  }

  /// O que "Ouvir" lê: título, pontuação e mensagem (FR-013).
  String get spokenText => [
    AppStrings.activitiesCompletionTitle.tr(),
    if (scoreText case final String text) '$text.',
    messageKey.tr(),
  ].join('\n');

  /// A mensagem pronta para compartilhar (FR-006).
  String get shareText {
    final ModuleScoreEntity? value = score;
    return value == null
        ? AppStrings.activitiesCompletionShareTextNoScore.tr(
            args: [title, AppIdentity.name],
          )
        : AppStrings.activitiesCompletionShareText.tr(
            args: [title, AppIdentity.name, '${value.score}', '${value.total}'],
          );
  }
}
