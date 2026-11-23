import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LessonEntity lesson(String id, {bool completed = true}) => LessonEntity(
    id: id,
    order: 1,
    question: 'Pergunta $id',
    options: const [
      LessonOptionEntity(id: 'a', text: 'A'),
      LessonOptionEntity(id: 'b', text: 'B'),
    ],
    isCompleted: completed,
  );

  final ModuleDetailEntity answered = ModuleDetailEntity(
    title: 'Golpes Digitais',
    lessons: [lesson('l1'), lesson('l2'), lesson('l3')],
    score: const ModuleScoreEntity(score: 1, total: 3),
  );

  group('forRetake (specs/025)', () {
    test('as respostas antigas não contam no progresso', () {
      final ModuleDetailEntity retake = answered.forRetake();

      expect(
        [for (final l in retake.lessons) l.isCompleted],
        [false, false, false],
      );
      expect(retake.title, answered.title);
      expect(retake.score?.score, 1);
    });

    test('só as respondidas nesta tentativa ficam concluídas', () {
      final ModuleDetailEntity retake = answered.forRetake(
        answeredInAttempt: {'l1'},
      );

      expect(
        [for (final l in retake.lessons) l.isCompleted],
        [true, false, false],
      );
    });
  });

  group('isFullyCompleted (specs/025)', () {
    test('todas as lições respondidas', () {
      expect(answered.isFullyCompleted, isTrue);
    });

    test('alguma lição pendente', () {
      final ModuleDetailEntity partial = ModuleDetailEntity(
        title: 'Golpes Digitais',
        lessons: [lesson('l1'), lesson('l2', completed: false)],
      );

      expect(partial.isFullyCompleted, isFalse);
    });

    test('sem lições não é concluído', () {
      const ModuleDetailEntity empty = ModuleDetailEntity(
        title: 'Vazio',
        lessons: [],
      );

      expect(empty.isFullyCompleted, isFalse);
    });
  });

  group('startsNewAttempt (specs/025)', () {
    final ModuleDetailEntity partial = ModuleDetailEntity(
      title: 'Golpes Digitais',
      lessons: [lesson('l1'), lesson('l2', completed: false)],
    );

    test('módulo todo concluído: tentativa nova', () {
      expect(answered.startsNewAttempt(), isTrue);
    });

    test('feito pela metade: retoma de onde parou', () {
      expect(partial.startsNewAttempt(), isFalse);
    });

    test('refazer: sempre tentativa nova', () {
      expect(partial.startsNewAttempt(retake: true), isTrue);
    });
  });
}
