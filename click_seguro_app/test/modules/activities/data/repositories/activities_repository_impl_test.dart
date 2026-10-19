import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/data/repositories/activities_repository_impl.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
          ..recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1')
          ..recordAnswer(moduleId: 'm1', lessonId: 'l2', selectedOptionId: 'o5')
          ..recordAnswer(
            moduleId: 'm2',
            lessonId: 'l4',
            selectedOptionId: 'o9',
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
        ..recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1')
        ..recordAnswer(moduleId: 'm1', lessonId: 'l2', selectedOptionId: 'o5');
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

    test('falha no envio não vira falha do painel', () async {
      await guestThenSignUp();
      remote.answerErrors['l1'] = apiError(ApiErrorType.server);

      final result = await repository.getDashboard();

      expect(result.isRight(), isTrue);
    });
  });
}
