import 'package:click_seguro_app/modules/profile/domain/achievements_calculator.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ModuleProgressEntity module(
    String id, {
    int order = 1,
    int lessons = 3,
    int completed = 0,
  }) => ModuleProgressEntity(
    id: id,
    title: 'Módulo $id',
    order: order,
    lessonsCount: lessons,
    completedCount: completed,
  );

  ActivityProgressEntity progress(
    List<ModuleProgressEntity> modules, {
    int? lessonsCompleted,
  }) => ActivityProgressEntity(
    modules: modules,
    lessonsCompleted:
        lessonsCompleted ??
        modules.fold(0, (sum, module) => sum + module.completedCount),
  );

  List<AchievementEntity> build({
    int readCount = 0,
    List<ModuleProgressEntity> modules = const [],
    int? lessonsCompleted,
  }) => AchievementsCalculator.build(
    readCount: readCount,
    progress: progress(modules, lessonsCompleted: lessonsCompleted),
  );

  AchievementEntity of(List<AchievementEntity> list, AchievementKind kind) =>
      list.firstWhere((a) => a.kind == kind);

  test('sem módulos: as 5 fixas, sem Mestre da segurança, todas pendentes', () {
    final achievements = build();

    expect(achievements.map((a) => a.kind), [
      AchievementKind.firstLesson,
      AchievementKind.firstModule,
      AchievementKind.dedicatedStudent,
      AchievementKind.attentiveReader,
      AchievementKind.dedicatedReader,
    ]);
    expect(achievements.any((a) => a.achieved), isFalse);
  });

  test('1 lição → Primeira lição alcançada', () {
    final achievements = build(modules: [module('m1', completed: 1)]);

    expect(of(achievements, AchievementKind.firstLesson).achieved, isTrue);
    expect(of(achievements, AchievementKind.dedicatedStudent).current, 1);
  });

  test('10 lições → Estudante dedicado', () {
    final achievements = build(
      modules: [module('m1', lessons: 12, completed: 10)],
    );

    final student = of(achievements, AchievementKind.dedicatedStudent);
    expect(student.achieved, isTrue);
    expect(student.target, AchievementsCalculator.dedicatedStudentLessons);
  });

  test('módulo concluído → Primeiro módulo e a do módulo', () {
    final achievements = build(
      modules: [module('m1', completed: 3), module('m2', order: 2)],
    );

    expect(of(achievements, AchievementKind.firstModule).achieved, isTrue);
    final moduleMedal = achievements.firstWhere((a) => a.moduleId == 'm1');
    expect(moduleMedal.kind, AchievementKind.module);
    expect(moduleMedal.moduleTitle, 'Módulo m1');
    expect(moduleMedal.achieved, isTrue);
    expect(
      achievements.firstWhere((a) => a.moduleId == 'm2').achieved,
      isFalse,
    );
  });

  test('todos os módulos com lições concluídos → Mestre da segurança', () {
    final achievements = build(
      modules: [
        module('m1', completed: 3),
        module('m2', order: 2, completed: 3),
      ],
    );

    final master = of(achievements, AchievementKind.securityMaster);
    expect(master.achieved, isTrue);
    expect((master.current, master.target), (2, 2));
  });

  test('módulo sem lições não gera conquista nem conta para o Mestre', () {
    final achievements = build(
      modules: [
        module('m1', completed: 3),
        module('vazio', order: 2, lessons: 0),
      ],
    );

    expect(achievements.where((a) => a.moduleId == 'vazio'), isEmpty);
    final master = of(achievements, AchievementKind.securityMaster);
    expect((master.current, master.target, master.achieved), (1, 1, true));
  });

  test('só módulos sem lições: sem Mestre da segurança', () {
    final achievements = build(modules: [module('vazio', lessons: 0)]);

    expect(
      achievements.where((a) => a.kind == AchievementKind.securityMaster),
      isEmpty,
    );
  });

  test('1 e 10 lidas → Leitor atento e Leitor dedicado', () {
    expect(
      of(build(readCount: 1), AchievementKind.attentiveReader).achieved,
      isTrue,
    );
    expect(
      of(build(readCount: 1), AchievementKind.dedicatedReader).achieved,
      isFalse,
    );
    expect(
      of(build(readCount: 10), AchievementKind.dedicatedReader).achieved,
      isTrue,
    );
  });

  test('progress é limitado a 1', () {
    final reader = of(build(readCount: 40), AchievementKind.dedicatedReader);

    expect(reader.progress, 1);
  });

  group('ordem', () {
    test('alcançadas primeiro, depois maior progresso', () {
      final achievements = build(
        readCount: 4,
        modules: [module('m1', lessons: 10, completed: 8)],
      );

      expect(achievements.map((a) => a.kind).take(4), [
        AchievementKind.firstLesson,
        AchievementKind.attentiveReader,
        AchievementKind.dedicatedStudent,
        AchievementKind.module,
      ]);
    });

    test('empate pela ordem do enum', () {
      final achievements = build(readCount: 1, lessonsCompleted: 1);

      expect(achievements.map((a) => a.kind).take(2), [
        AchievementKind.firstLesson,
        AchievementKind.attentiveReader,
      ]);
    });

    test('entre módulos, pelo order do serviço', () {
      final achievements = build(
        modules: [
          module('b', order: 2, completed: 1),
          module('a', order: 1, completed: 1),
        ],
      );

      final modules = achievements
          .where((a) => a.kind == AchievementKind.module)
          .map((a) => a.moduleId);
      expect(modules, ['a', 'b']);
    });
  });
}
