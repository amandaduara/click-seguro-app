import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/failures/activities_failures.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_module_detail_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_repository.dart';

void main() {
  late FakeActivitiesRepository repository;
  late LessonController controller;

  ModuleDetailEntity module({
    Set<String> answered = const {},
    List<Map<String, dynamic>>? lessons,
  }) => ModuleDetailModel.fromJson(
    moduleDetailJson(answered: answered, lessons: lessons),
  ).toEntity();

  LessonController build(List<Either<Failure, ModuleDetailEntity>> results) {
    repository = FakeActivitiesRepository()..moduleDetailResults = results;
    return LessonController(
      getModuleDetail: GetModuleDetailUseCase(repository),
    );
  }

  setUp(() => controller = build([Right(module())]));

  test('começa carregando', () {
    expect(controller.status, LessonStatus.loading);
    expect(controller.module, isNull);
  });

  test('carrega o módulo e começa na primeira pergunta', () async {
    await controller.load('m1');

    expect(controller.status, LessonStatus.loaded);
    expect(controller.module!.title, 'Golpes Digitais');
    expect(controller.currentIndex, 0);
    expect(controller.current!.id, 'l1');
  });

  test('começa na primeira não respondida', () async {
    controller = build([
      Right(module(answered: {'l1'})),
    ]);

    await controller.load('m1');

    expect(controller.currentIndex, 1);
  });

  test('todas respondidas: começa na primeira', () async {
    controller = build([
      Right(module(answered: {'l1', 'l2', 'l3'})),
    ]);

    await controller.load('m1');

    expect(controller.currentIndex, 0);
  });

  test('sem lições → empty', () async {
    controller = build([Right(module(lessons: const []))]);

    await controller.load('m1');

    expect(controller.status, LessonStatus.empty);
  });

  test('módulo que não existe → empty', () async {
    controller = build([const Left(ModuleNotFoundFailure())]);

    await controller.load('m9');

    expect(controller.status, LessonStatus.empty);
  });

  test('falha → error; carregar de novo recupera', () async {
    controller = build([const Left(ConnectionFailure()), Right(module())]);

    await controller.load('m1');
    expect(controller.status, LessonStatus.error);
    expect(controller.failure, isA<ConnectionFailure>());

    final Future<void> retry = controller.load('m1');
    expect(controller.status, LessonStatus.loading);
    await retry;
    expect(controller.status, LessonStatus.loaded);
  });

  test('dispose durante a carga não lança', () async {
    repository.moduleDetailGate = Completer<void>();
    final Future<void> loading = controller.load('m1');

    controller.dispose();
    repository.moduleDetailGate!.complete();

    await expectLater(loading, completes);
  });

  group('navegação (US2)', () {
    test('com tudo respondido: vai e volta pelos limites', () async {
      controller = build([
        Right(module(answered: {'l1', 'l2', 'l3'})),
      ]);
      await controller.load('m1');

      expect(controller.canGoPrevious, isFalse);
      controller.goNext();
      controller.goNext();
      expect(controller.currentIndex, 2);
      expect(controller.canGoNext, isFalse);
      controller.goPrevious();
      controller.goPrevious();
      expect(controller.currentIndex, 0);
      controller.goPrevious();
      expect(controller.currentIndex, 0);
    });

    test('só avança com a atual respondida', () async {
      controller = build([
        Right(module(answered: {'l1', 'l3'})),
      ]);
      await controller.load('m1');
      controller.goPrevious();
      expect(controller.currentIndex, 0);

      expect(controller.canGoNext, isTrue);
      controller.goNext();
      expect(controller.currentIndex, 1);
      expect(controller.canGoNext, isFalse);
      controller.goNext();
      expect(controller.currentIndex, 1);
    });

    test('três "Próxima" seguidos param na última', () async {
      controller = build([
        Right(module(answered: {'l1', 'l2', 'l3'})),
      ]);
      await controller.load('m1');

      controller
        ..goNext()
        ..goNext()
        ..goNext();

      expect(controller.currentIndex, 2);
    });
  });
}
