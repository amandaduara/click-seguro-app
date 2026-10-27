import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:easy_localization/easy_localization.dart';

extension LessonPresentation on LessonEntity {
  /// O que "Ouvir" lê: o enunciado e cada alternativa numerada (FR-008).
  String get spokenText => [
    question,
    '',
    for (final (index, option) in options.indexed)
      '${AppStrings.activitiesLessonOptionSpoken.tr(args: ['${index + 1}', option.text])}.',
  ].join('\n');
}
