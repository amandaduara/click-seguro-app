import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/lesson_presentation.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/activities_fixtures.dart';

void main() {
  final LessonEntity lesson = ModuleDetailModel.fromJson(
    moduleDetailJson(),
  ).toEntity().lessons.first;

  List<(String, bool)> parts(List<SpeechPart> parts) => [
    for (final part in parts) (part.text, part.content),
  ];

  group('trechos falados da pergunta (FR-008, specs/025)', () {
    testWidgets('enunciado e alternativas são conteúdo; o número é do app', (
      tester,
    ) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(parts(lesson.spokenParts), [
        ('Promessa de dinheiro em dobro pelo PIX. O que fazer?', true),
        ('Alternativa 1.', false),
        ('Ignorar e denunciar.', true),
        ('Alternativa 2.', false),
        ('Enviar.', true),
        ('Alternativa 3.', false),
        ('Pedir prova.', true),
        ('Alternativa 4.', false),
        ('Repassar.', true),
      ]);
    });

    testWidgets('com o app em inglês, só o número da alternativa muda', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        child: const SizedBox(),
        locale: const Locale('en', 'US'),
      );

      final List<(String, bool)> spoken = parts(lesson.spokenParts);
      expect(spoken.first, (
        'Promessa de dinheiro em dobro pelo PIX. O que fazer?',
        true,
      ));
      expect(spoken[1], ('Option 1.', false));
      expect(spoken[2], ('Ignorar e denunciar.', true));
    });
  });
}
