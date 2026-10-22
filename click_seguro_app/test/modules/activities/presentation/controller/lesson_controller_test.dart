import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/failures/activities_failures.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/answer_lesson_usecase.dart';
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
      answerLesson: AnswerLessonUseCase(repository),
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

  group('escolher e confirmar (specs/018 US1)', () {
    setUp(() => controller.load('m1'));

    test('sem escolha no início: não confirma', () {
      expect(controller.selectedOptionId, isNull);
      expect(controller.canSelect, isTrue);
      expect(controller.canConfirm, isFalse);
    });

    test('escolher marca; escolher outra troca', () {
      controller.select('l1-o2');
      expect(controller.selectedOptionId, 'l1-o2');
      expect(controller.canConfirm, isTrue);

      controller.select('l1-o3');
      expect(controller.selectedOptionId, 'l1-o3');
    });

    test('confirmar envia a escolhida, com envio em andamento', () async {
      controller.select('l1-o3');
      repository.answerGate = Completer<void>();

      final Future<AnswerAttempt> attempt = controller.confirm();
      expect(controller.isSubmitting, isTrue);
      expect(controller.canConfirm, isFalse);
      repository.answerGate!.complete();

      expect(await attempt, AnswerAttempt.answered);
      expect(controller.isSubmitting, isFalse);
      expect(repository.answerCalls.single, (
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'l1-o3',
      ));
    });

    test('dois toques seguidos: um envio só', () async {
      controller.select('l1-o2');
      repository.answerGate = Completer<void>();

      final Future<AnswerAttempt> first = controller.confirm();
      final AnswerAttempt second = await controller.confirm();
      repository.answerGate!.complete();
      await first;

      expect(second, AnswerAttempt.ignored);
      expect(repository.answerCalls, hasLength(1));
    });

    test('durante o envio, escolher não muda nada', () async {
      controller.select('l1-o2');
      repository.answerGate = Completer<void>();
      final Future<AnswerAttempt> attempt = controller.confirm();

      controller.select('l1-o4');

      expect(controller.selectedOptionId, 'l1-o2');
      repository.answerGate!.complete();
      await attempt;
    });

    test('sem escolha: confirmar é ignorado', () async {
      expect(await controller.confirm(), AnswerAttempt.ignored);
      expect(repository.answerCalls, isEmpty);
    });

    test('dispose durante o envio não lança', () async {
      controller.select('l1-o2');
      repository.answerGate = Completer<void>();
      final Future<AnswerAttempt> attempt = controller.confirm();

      controller.dispose();
      repository.answerGate!.complete();

      await expectLater(attempt, completes);
    });
  });

  group('resultado (specs/018 US2)', () {
    Future<void> answerCurrent(String option) async {
      controller.select(option);
      await controller.confirm();
    }

    setUp(() => controller.load('m1'));

    test('guarda o resultado e marca a lição como concluída', () async {
      final List<String> optionsBefore = [
        for (final o in controller.current!.options) o.id,
      ];
      repository.answerResults = [
        Right(
          AnswerResultModel.fromJson(answerJson(isCorrect: false)).toEntity(),
        ),
      ];

      await answerCurrent('l1-o2');

      expect(controller.currentResult?.isCorrect, isFalse);
      expect(controller.currentResult?.correctOptionId, 'l1-o1');
      expect(controller.current!.isCompleted, isTrue);
      expect([
        for (final o in controller.current!.options) o.id,
      ], optionsBefore);
      expect(controller.selectedOptionId, 'l1-o2');
      expect(controller.canSelect, isFalse);
      expect(controller.canConfirm, isFalse);
      expect(controller.canGoNext, isTrue);
    });

    test('próxima sem escolha; voltar mostra o resultado de novo', () async {
      await answerCurrent('l1-o1');

      controller.goNext();
      expect(controller.current!.id, 'l2');
      expect(controller.selectedOptionId, isNull);
      expect(controller.currentResult, isNull);
      expect(controller.canSelect, isTrue);

      controller.goPrevious();
      expect(controller.resultFor('l1')?.isCorrect, isTrue);
      expect(controller.currentResult, isNotNull);
    });

    test('isLastLesson só na última', () async {
      controller = build([
        Right(module(answered: {'l1', 'l2'})),
      ]);
      await controller.load('m1');

      expect(controller.isLastLesson, isTrue);
      controller.goPrevious();
      expect(controller.isLastLesson, isFalse);
    });

    test('pontuação: do módulo, depois a da resposta', () async {
      controller = build([
        Right(
          ModuleDetailModel.fromJson(
            moduleDetailJson(score: 1, totalScore: 3),
          ).toEntity(),
        ),
        Right(
          ModuleDetailModel.fromJson(
            moduleDetailJson(score: 2, totalScore: 3),
          ).toEntity(),
        ),
      ]);
      await controller.load('m1');
      expect(controller.score?.score, 1);

      await answerCurrent('l1-o1');

      expect(controller.score?.score, 2);
      expect(controller.score?.total, 3);
    });

    test('pontuação que não veio mantém a anterior', () async {
      controller = build([
        Right(
          ModuleDetailModel.fromJson(
            moduleDetailJson(score: 1, totalScore: 3),
          ).toEntity(),
        ),
        const Left(ConnectionFailure()),
      ]);
      await controller.load('m1');

      await answerCurrent('l1-o1');

      expect(controller.currentResult, isNotNull);
      expect(controller.score?.score, 1);
    });

    test(
      'responder de novo: limpa, continua concluída e envia outra vez',
      () async {
        await answerCurrent('l1-o2');

        controller.answerAgain();

        expect(controller.currentResult, isNull);
        expect(controller.selectedOptionId, isNull);
        expect(controller.current!.isCompleted, isTrue);
        expect(controller.canGoNext, isTrue);
        expect(controller.canSelect, isTrue);

        repository.answerResults = [
          Right(AnswerResultModel.fromJson(answerJson()).toEntity()),
        ];
        await answerCurrent('l1-o1');

        expect(repository.answerCalls, hasLength(2));
        expect(controller.currentResult?.isCorrect, isTrue);
      },
    );

    test(
      'respondida antes da visita: escolhe de novo, "Próxima" ativo',
      () async {
        controller = build([
          Right(module(answered: {'l1', 'l2', 'l3'})),
        ]);
        await controller.load('m1');

        expect(controller.current!.isCompleted, isTrue);
        expect(controller.currentResult, isNull);
        expect(controller.selectedOptionId, isNull);
        expect(controller.canSelect, isTrue);
        expect(controller.canGoNext, isTrue);
      },
    );

    test('na última, responder não libera "Próxima"', () async {
      controller = build([
        Right(module(answered: {'l1', 'l2'})),
      ]);
      await controller.load('m1');

      await answerCurrent('l3-o1');

      expect(controller.current!.isCompleted, isTrue);
      expect(controller.canGoNext, isFalse);
    });
  });

  group('erros ao responder (specs/018 US6)', () {
    setUp(() => controller.load('m1'));

    test('falha comum: mantém a escolha e não conclui', () async {
      repository.answerResults = [const Left(ConnectionFailure())];
      controller.select('l1-o2');

      expect(await controller.confirm(), AnswerAttempt.failed);

      expect(controller.selectedOptionId, 'l1-o2');
      expect(controller.current!.isCompleted, isFalse);
      expect(controller.currentResult, isNull);
      expect(controller.canConfirm, isTrue);
    });

    test('recusada: recarrega o módulo e esquece os resultados', () async {
      repository
        ..answerResults = [
          Right(AnswerResultModel.fromJson(answerJson()).toEntity()),
          const Left(AnswerRejectedFailure()),
        ]
        ..moduleDetailResults = [
          Right(module(answered: {'l1'})),
        ];
      controller.select('l1-o1');
      await controller.confirm();
      controller
        ..goNext()
        ..select('l2-o1');
      final int loadsBefore = repository.moduleDetailCalls;

      expect(await controller.confirm(), AnswerAttempt.rejected);

      expect(repository.moduleDetailCalls, greaterThan(loadsBefore));
      expect(controller.status, LessonStatus.loaded);
      expect(controller.current!.id, 'l2');
      expect(controller.resultFor('l1'), isNull);
      expect(controller.selectedOptionId, isNull);
    });

    test('recusada e o módulo sumiu: "sem atividades" (achado C1)', () async {
      repository
        ..answerResults = [const Left(AnswerRejectedFailure())]
        ..moduleDetailResults = [const Left(ModuleNotFoundFailure())];
      controller.select('l1-o1');

      await controller.confirm();

      expect(controller.status, LessonStatus.empty);
    });

    test('dispose durante o envio: nada notificado depois', () async {
      controller.select('l1-o1');
      repository.answerGate = Completer<void>();
      int notifications = 0;
      final Future<AnswerAttempt> attempt = controller.confirm();
      controller.addListener(() => notifications++);
      controller.dispose();

      repository.answerGate!.complete();
      await attempt;

      expect(notifications, 0);
    });
  });
}
