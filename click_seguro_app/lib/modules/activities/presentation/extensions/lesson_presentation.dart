import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:easy_localization/easy_localization.dart';

extension LessonPresentation on LessonEntity {
  /// O que "Ouvir" lê: o enunciado e cada alternativa numerada (FR-008). O
  /// enunciado e as alternativas vêm do banco (voz em português); o número
  /// da alternativa é texto do app, no idioma do app (specs/025).
  List<SpeechPart> get spokenParts => [
    SpeechPart(_sentence(question), content: true),
    for (final (index, option) in options.indexed) ...[
      SpeechPart(
        _sentence(
          AppStrings.activitiesLessonOptionNumber.tr(args: ['${index + 1}']),
        ),
      ),
      SpeechPart(_sentence(option.text), content: true),
    ],
  ];
}

/// Cada parte termina com pontuação, para a voz fazer a pausa.
String _sentence(String text) {
  final String trimmed = text.trim();
  return RegExp(r'[.!?]$').hasMatch(trimmed) ? trimmed : '$trimmed.';
}
