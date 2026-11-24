import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/check_new_alerts_result.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/check_new_alerts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../fakes/alerts_fixtures.dart';
import '../fakes/fake_notifications_repository.dart';

void main() {
  late FakeNotificationsRepository repository;
  late CheckNewAlertsUseCase useCase;

  final lastCheckAt = testNow.subtract(const Duration(hours: 1));

  DateTime ago(Duration duration) => testNow.subtract(duration);

  CheckNewAlertsResult unwrap(Either<Failure, CheckNewAlertsResult> result) =>
      result.getOrElse((_) => throw StateError('esperava Right'));

  setUp(() {
    repository = FakeNotificationsRepository()
      ..stored = snapshot(lastCheckAt: lastCheckAt);
    useCase = CheckNewAlertsUseCase(repository);
  });

  group('primeira conferência (FR-003)', () {
    test('só grava o horário e não chama o serviço', () async {
      repository.stored = const AlertsSnapshot();

      final result = unwrap(await useCase(testNow));

      expect(result.outcome, CheckOutcome.firstRun);
      expect(result.snapshot.lastCheckAt, testNow);
      expect(result.snapshot.alerts, isEmpty);
      expect(repository.saves.single.lastCheckAt, testNow);
      expect(repository.receiveCalls, 0);
      expect(repository.fetchCalls, isEmpty);
    });

    test(
      'falha ao ler o registro: devolve a falha, sem chamar o serviço',
      () async {
        repository.getSnapshotError = const CacheFailure();

        final result = await useCase(testNow);

        expect(result.getLeft().toNullable(), isA<CacheFailure>());
        expect(repository.receiveCalls, 0);
        expect(repository.fetchCalls, isEmpty);
        expect(repository.saves, isEmpty);
      },
    );
  });

  group('"Receber alertas" desligado (FR-006)', () {
    test('avança o horário, guarda a chave e não pede notícias', () async {
      repository
        ..stored = snapshot(
          lastCheckAt: lastCheckAt,
          alerts: [alert(newsId: 'velho')],
        )
        ..receiveAlerts = false
        ..newAlerts = [alert(newsId: 'novo')];

      final result = unwrap(await useCase(testNow));

      expect(result.outcome, CheckOutcome.disabled);
      expect(repository.fetchCalls, isEmpty);
      final saved = repository.saves.single;
      expect(saved.lastCheckAt, testNow);
      expect(saved.receiveAlerts, isFalse);
      expect(saved.alerts.map((a) => a.newsId), ['velho']);
      expect(result.snapshot.receiveAlerts, isFalse);
    });
  });

  group('falhas (FR-005)', () {
    test('falha em getReceiveAlerts: Left e nada gravado', () async {
      repository.receiveAlertsError = const ConnectionFailure();

      final result = await useCase(testNow);

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
      expect(repository.saves, isEmpty);
      expect(repository.fetchCalls, isEmpty);
    });

    test('falha em fetchNewAlerts: Left e nada gravado', () async {
      repository.newAlertsError = const ServerFailure();

      final result = await useCase(testNow);

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(repository.saves, isEmpty);
    });

    test('falha ao gravar: Left', () async {
      repository
        ..newAlerts = [alert(newsId: 'n1')]
        ..saveError = const CacheFailure();

      final result = await useCase(testNow);

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('sucesso', () {
    test('alertas novos não lidos, horário e chave numa só gravação', () async {
      repository.newAlerts = [
        alert(newsId: 'n1', publishedAt: ago(const Duration(minutes: 10))),
        alert(newsId: 'n2', publishedAt: ago(const Duration(minutes: 20))),
      ];

      final result = unwrap(await useCase(testNow));

      expect(result.outcome, CheckOutcome.updated);
      expect(repository.saves, hasLength(1));
      final saved = repository.saves.single;
      expect(saved.lastCheckAt, testNow);
      expect(saved.receiveAlerts, isTrue);
      expect(saved.alerts.map((a) => (a.newsId, a.isRead)), [
        ('n1', false),
        ('n2', false),
      ]);
      expect(result.snapshot.unreadCount, 2);
    });

    test('sem notícias novas: updated, horário avança', () async {
      final result = unwrap(await useCase(testNow));

      expect(result.outcome, CheckOutcome.updated);
      expect(repository.saves.single.lastCheckAt, testNow);
      expect(result.snapshot.alerts, isEmpty);
    });

    test('since é o último horário e o limite é 50', () async {
      await useCase(testNow);

      expect(repository.fetchCalls.single, (since: lastCheckAt, limit: 50));
    });

    test(
      'última verificação com mais de 30 dias: since = agora − 30 dias',
      () async {
        repository.stored = snapshot(
          lastCheckAt: ago(const Duration(days: 40)),
        );

        await useCase(testNow);

        expect(
          repository.fetchCalls.single.since,
          ago(const Duration(days: 30)),
        );
      },
    );

    test('candidato publicado até o último horário é descartado', () async {
      repository.newAlerts = [
        alert(newsId: 'igual', publishedAt: lastCheckAt),
        alert(newsId: 'antes', publishedAt: ago(const Duration(hours: 2))),
        alert(newsId: 'depois', publishedAt: ago(const Duration(minutes: 5))),
      ];

      final result = unwrap(await useCase(testNow));

      expect(result.snapshot.alerts.map((a) => a.newsId), ['depois']);
    });

    test('newsId já existente não duplica e preserva isRead', () async {
      repository
        ..stored = snapshot(
          lastCheckAt: lastCheckAt,
          alerts: [
            alert(
              newsId: 'n1',
              isRead: true,
              publishedAt: ago(const Duration(hours: 5)),
            ),
          ],
        )
        ..newAlerts = [
          alert(newsId: 'n1', publishedAt: ago(const Duration(minutes: 5))),
          alert(newsId: 'n2', publishedAt: ago(const Duration(minutes: 6))),
        ];

      final result = unwrap(await useCase(testNow));

      expect(result.snapshot.alerts.map((a) => (a.newsId, a.isRead)), [
        ('n2', false),
        ('n1', true),
      ]);
    });

    test('repetido na própria resposta entra uma vez', () async {
      repository.newAlerts = [
        alert(newsId: 'n1', publishedAt: ago(const Duration(minutes: 5))),
        alert(newsId: 'n1', publishedAt: ago(const Duration(minutes: 5))),
      ];

      final result = unwrap(await useCase(testNow));

      expect(result.snapshot.alerts, hasLength(1));
    });

    test(
      'mais de 50: ficam os 50 mais recentes, do mais novo ao mais antigo',
      () async {
        repository
          ..stored = snapshot(lastCheckAt: ago(const Duration(days: 3)))
          ..newAlerts = [
            for (var i = 1; i <= 60; i++)
              alert(
                newsId: 'n$i',
                publishedAt: ago(Duration(minutes: i)),
              ),
          ];

        final result = unwrap(await useCase(testNow));

        final ids = result.snapshot.alerts.map((a) => a.newsId).toList();
        expect(ids, hasLength(50));
        expect(ids.first, 'n1');
        expect(ids.last, 'n50');
      },
    );

    test('alerta com mais de 30 dias é removido', () async {
      repository.stored = snapshot(
        lastCheckAt: lastCheckAt,
        alerts: [
          alert(
            newsId: 'antigo',
            isRead: true,
            publishedAt: ago(const Duration(days: 31)),
          ),
          alert(newsId: 'recente', publishedAt: ago(const Duration(days: 29))),
        ],
      );

      final result = unwrap(await useCase(testNow));

      expect(result.snapshot.alerts.map((a) => a.newsId), ['recente']);
      expect(repository.saves.single.alerts.map((a) => a.newsId), ['recente']);
    });

    test('marcação feita durante o pedido é preservada (R5)', () async {
      repository
        ..stored = snapshot(
          lastCheckAt: lastCheckAt,
          alerts: [
            alert(newsId: 'n1', publishedAt: ago(const Duration(hours: 3))),
          ],
        )
        ..newAlerts = [
          alert(newsId: 'n2', publishedAt: ago(const Duration(minutes: 5))),
        ]
        ..fetchGate = Completer<void>();

      final pending = useCase(testNow);
      await Future<void>.delayed(Duration.zero);
      expect(repository.fetchCalls, hasLength(1));
      // A pessoa marca n1 como lido enquanto o serviço não responde.
      repository.stored = repository.stored.markRead('n1');
      repository.fetchGate!.complete();
      final result = unwrap(await pending);

      expect(result.snapshot.alerts.map((a) => (a.newsId, a.isRead)), [
        ('n2', false),
        ('n1', true),
      ]);
      expect(
        repository.saves.single.alerts
            .firstWhere((a) => a.newsId == 'n1')
            .isRead,
        isTrue,
      );
    });
  });
}
