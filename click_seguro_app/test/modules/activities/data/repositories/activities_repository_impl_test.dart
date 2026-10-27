import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/data/repositories/activities_repository_impl.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/failures/activities_failures.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_remote_data_source.dart';

void main() {
  late UserSessionService session;
  late GuestProgressStore store;
  late FakeActivitiesRemoteDataSource remote;
  late ActivitiesRepositoryImpl repository;

  setUp(() {
    session = UserSessionService(FakeSecureStorageService());
    store = GuestProgressStore(session);
    remote = FakeActivitiesRemoteDataSource();
    repository = ActivitiesRepositoryImpl(remote, store, session);
  });

  tearDown(() => store.dispose());

  Future<void> signIn() => session.saveSession(
    accessToken: 'tk',
    refreshToken: 'rf',
    email: 'maria@exemplo.com',
  );

  Future<ActivitiesDashboardEntity> dashboardOrFail() async =>
      (await repository.getDashboard()).getOrElse(
        (failure) => throw StateError('falhou: $failure'),
      );

  group('conta', () {
    setUp(signIn);

    test('o painel do serviço', () async {
      remote.modules = dashboardJson(modules: threeModulesJson(m1: 2));

      final dashboard = await dashboardOrFail();

      expect(dashboard.modules.first.completedCount, 2);
      expect(dashboard.totalCompleted, 2);
      expect(dashboard.totalAvailable, 9);
    });

    test('sem internet → ConnectionFailure', () async {
      remote.modulesError = apiError(ApiErrorType.connection);

      final result = await repository.getDashboard();

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });

    test('erro do servidor → ServerFailure', () async {
      remote.modulesError = apiError(ApiErrorType.server, statusCode: 500);

      final result = await repository.getDashboard();

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('visitante', () {
    setUp(() => session.startGuestSession());

    test(
      'progresso do registro da sessão; totais disponíveis do serviço',
      () async {
        store
          ..recordAnswer(
            moduleId: 'm1',
            lessonId: 'l1',
            selectedOptionId: 'o1',
            isCorrect: true,
          )
          ..recordAnswer(
            moduleId: 'm1',
            lessonId: 'l2',
            selectedOptionId: 'o5',
            isCorrect: true,
          )
          ..recordAnswer(
            moduleId: 'm2',
            lessonId: 'l4',
            selectedOptionId: 'o9',
            isCorrect: true,
          );

        final dashboard = await dashboardOrFail();

        expect(
          [for (final m in dashboard.modules) m.completedCount],
          [2, 1, 0],
        );
        expect(dashboard.totalCompleted, 3);
        expect(dashboard.totalAvailable, 9);
        expect(remote.sent, isEmpty);
      },
    );

    test('mais respostas que lições → limitado às lições', () async {
      remote.modules = dashboardJson(modules: [moduleJson(lessonsCount: 2)]);
      for (final lesson in ['l1', 'l2', 'l3']) {
        store.recordAnswer(
          moduleId: 'm1',
          lessonId: lesson,
          selectedOptionId: 'o1',
          isCorrect: true,
        );
      }

      final dashboard = await dashboardOrFail();

      expect(dashboard.modules.single.completedCount, 2);
      expect(dashboard.totalCompleted, 2);
    });
  });

  test('sessão expirada: caminho sem conta, sem erro', () async {
    await signIn();
    await session.expire();

    final result = await repository.getDashboard();

    expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
    final dashboard = result.getOrElse((_) => throw StateError('falhou'));
    expect(dashboard.totalCompleted, 0);
  });

  group('transferência ao criar conta (FR-008a)', () {
    /// Visitante com respostas em l1 e l2 que cria uma conta.
    Future<void> guestThenSignUp() async {
      await session.startGuestSession();
      store
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l1',
          selectedOptionId: 'o1',
          isCorrect: true,
        )
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l2',
          selectedOptionId: 'o5',
          isCorrect: true,
        );
      await session.saveSession(
        accessToken: 'tk',
        refreshToken: 'rf',
        email: 'nova@exemplo.com',
        newAccount: true,
      );
    }

    test('envia as respostas antes de ler o painel e esvazia', () async {
      await guestThenSignUp();

      await dashboardOrFail();

      expect([for (final a in remote.sent) a.lessonId], ['l1', 'l2']);
      expect(remote.sent.first.moduleId, 'm1');
      expect(remote.sent.first.selectedOptionId, 'o1');
      expect(remote.calls, ['answer', 'answer', 'modules']);
      expect(store.pendingTransfer, isEmpty);
    });

    test('falha de conexão fica para a próxima carga, só ela', () async {
      await guestThenSignUp();
      remote.answerErrors['l2'] = apiError(ApiErrorType.connection);

      await dashboardOrFail();
      expect([for (final a in store.pendingTransfer) a.lessonId], ['l2']);

      remote
        ..sent.clear()
        ..answerErrors.clear();
      await dashboardOrFail();

      expect([for (final a in remote.sent) a.lessonId], ['l2']);
      expect(store.pendingTransfer, isEmpty);
    });

    test(
      'lição que sumiu (404) ou opção recusada (400) é descartada',
      () async {
        await guestThenSignUp();
        remote.answerErrors
          ..['l1'] = apiError(
            ApiErrorType.client,
            statusCode: 404,
            errorCode: 'EDUCATIONAL_LESSON_NOT_FOUND',
          )
          ..['l2'] = apiError(
            ApiErrorType.client,
            statusCode: 400,
            errorCode: 'VALIDATION_ERROR',
          );

        final result = await repository.getDashboard();

        expect(result.isRight(), isTrue);
        expect(store.pendingTransfer, isEmpty);
      },
    );

    test('dois envios ao mesmo tempo mandam cada resposta uma vez', () async {
      await guestThenSignUp();
      remote.answerGate = Completer<void>();

      final Future<void> first = repository.syncGuestAnswers();
      final Future<void> second = repository.syncGuestAnswers();
      remote.answerGate!.complete();
      await Future.wait([first, second]);

      expect([for (final a in remote.sent) a.lessonId], ['l1', 'l2']);
    });

    test('o cadastro dispara o envio sem abrir o painel', () async {
      await guestThenSignUp();
      await pumpEventQueue();

      expect([for (final a in remote.sent) a.lessonId], ['l1', 'l2']);
      expect(remote.modulesCalls, 0);
      expect(store.pendingTransfer, isEmpty);
    });

    test('sair da conta durante o envio para o resto', () async {
      remote.answerGate = Completer<void>();
      await guestThenSignUp();
      await pumpEventQueue();
      expect(remote.sent, hasLength(1));

      await session.logout();
      remote.answerGate!.complete();
      await pumpEventQueue();

      expect([for (final a in remote.sent) a.lessonId], ['l1']);
    });

    test('falha no envio não vira falha do painel', () async {
      await guestThenSignUp();
      remote.answerErrors['l1'] = apiError(ApiErrorType.server);

      final result = await repository.getDashboard();

      expect(result.isRight(), isTrue);
    });
  });

  group('detalhe do módulo (specs/017)', () {
    Future<ModuleDetailEntity> detailOrFail() async =>
        (await repository.getModuleDetail(
          'm1',
        )).getOrElse((failure) => throw StateError('falhou: $failure'));

    test('conta: concluídas do serviço', () async {
      await signIn();
      remote.moduleDetail = moduleDetailJson(answered: {'l2'});

      final module = await detailOrFail();

      expect(
        [for (final l in module.lessons) l.isCompleted],
        [false, true, false],
      );
    });

    test('visitante: concluídas do registro da sessão', () async {
      await session.startGuestSession();
      store.recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
        isCorrect: true,
      );

      final module = await detailOrFail();

      expect(
        [for (final l in module.lessons) l.isCompleted],
        [true, false, false],
      );
    });

    test('sessão expirada: como sem conta', () async {
      await signIn();
      remote.moduleDetail = moduleDetailJson(answered: {'l1'});
      await session.expire();

      final module = await detailOrFail();

      expect(module.lessons.first.isCompleted, isFalse);
    });

    test('404 do módulo → ModuleNotFoundFailure', () async {
      remote.moduleDetailError = apiError(
        ApiErrorType.client,
        statusCode: 404,
        errorCode: 'EDUCATIONAL_MODULE_NOT_FOUND',
      );

      final result = await repository.getModuleDetail('m9');

      expect(result.getLeft().toNullable(), isA<ModuleNotFoundFailure>());
    });

    test('sem internet → ConnectionFailure', () async {
      remote.moduleDetailError = apiError(ApiErrorType.connection);

      final result = await repository.getModuleDetail('m1');

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });

    group('pontuação (specs/018 R3)', () {
      test('conta: a do serviço', () async {
        await signIn();
        remote.moduleDetail = moduleDetailJson(score: 2, totalScore: 3);

        final module = await detailOrFail();

        expect(module.score?.score, 2);
        expect(module.score?.total, 3);
      });

      test('visitante sem respostas no módulo: nenhuma', () async {
        await session.startGuestSession();
        store.recordAnswer(
          moduleId: 'm2',
          lessonId: 'l4',
          selectedOptionId: 'o1',
          isCorrect: true,
        );

        expect((await detailOrFail()).score, isNull);
      });

      test('visitante: acertos do registro / lições válidas', () async {
        await session.startGuestSession();
        store
          ..recordAnswer(
            moduleId: 'm1',
            lessonId: 'l1',
            selectedOptionId: 'l1-o1',
            isCorrect: true,
          )
          ..recordAnswer(
            moduleId: 'm1',
            lessonId: 'l2',
            selectedOptionId: 'l2-o2',
            isCorrect: false,
          );

        final module = await detailOrFail();

        expect(module.score?.score, 1);
        expect(module.score?.total, 3);
      });
    });
  });

  group('responder (specs/018)', () {
    Future<Either<Failure, AnswerResultEntity>> answer({
      String lessonId = 'l1',
      String option = 'l1-o2',
    }) => repository.answerLesson(
      moduleId: 'm1',
      lessonId: lessonId,
      selectedOptionId: option,
    );

    test('conta: resultado do serviço e nada no registro', () async {
      await signIn();
      remote.answerResults['l1'] = answerJson(isCorrect: false);

      final result = (await answer()).getOrElse(
        (failure) => throw StateError('falhou: $failure'),
      );

      expect(result.isCorrect, isFalse);
      expect(result.correctOptionId, 'l1-o1');
      expect(remote.sent.single.selectedOptionId, 'l1-o2');
      expect(store.answeredCount('m1'), 0);
    });

    test('visitante: grava no registro com o acerto do serviço', () async {
      await session.startGuestSession();
      remote.answerResults['l1'] = answerJson();

      final result = await answer(option: 'l1-o1');

      expect(result.isRight(), isTrue);
      expect(store.isAnswered('l1'), isTrue);
      expect(store.correctCount('m1'), 1);
    });

    test('sessão expirada: grava como visitante', () async {
      await signIn();
      await session.expire();

      await answer();

      expect(store.isAnswered('l1'), isTrue);
    });

    for (final (int status, String code) in [
      (400, 'EDUCATIONAL_INVALID_OPTION'),
      (400, 'VALIDATION_ERROR'),
      (404, 'EDUCATIONAL_LESSON_NOT_FOUND'),
      (404, 'EDUCATIONAL_MODULE_NOT_FOUND'),
    ]) {
      test('$status $code → AnswerRejectedFailure e nada gravado', () async {
        await session.startGuestSession();
        remote.answerErrors['l1'] = apiError(
          ApiErrorType.client,
          statusCode: status,
          errorCode: code,
        );

        final result = await answer();

        expect(result.getLeft().toNullable(), isA<AnswerRejectedFailure>());
        expect(store.isAnswered('l1'), isFalse);
      });
    }

    test('sem internet → ConnectionFailure e nada gravado', () async {
      await session.startGuestSession();
      remote.answerErrors['l1'] = apiError(ApiErrorType.connection);

      final result = await answer();

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
      expect(store.isAnswered('l1'), isFalse);
    });
  });
}
