import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/clear_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/get_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/alerts_fixtures.dart';
import '../fakes/fake_notifications_repository.dart';

void main() {
  group('AlertEntity', () {
    test('copyWith(isRead:) muda só a marcação', () {
      final original = alert(newsId: 'n1');

      final read = original.copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.newsId, 'n1');
      expect(read.title, original.title);
      expect(read.source, original.source);
      expect(read.publishedAt, original.publishedAt);
    });

    test('igualdade por newsId', () {
      expect(
        alert(newsId: 'n1'),
        alert(newsId: 'n1', title: 'Outro', isRead: true),
      );
      expect(
        alert(newsId: 'n1').hashCode,
        alert(newsId: 'n1', isRead: true).hashCode,
      );
      expect(alert(newsId: 'n1'), isNot(alert(newsId: 'n2')));
    });
  });

  group('AlertsSnapshot', () {
    test('constantes: 50 alertas, 30 dias', () {
      expect(AlertsSnapshot.maxAlerts, 50);
      expect(AlertsSnapshot.retentionDays, 30);
    });

    test('unreadCount e isEmpty', () {
      final data = snapshot(
        alerts: [
          alert(newsId: 'a'),
          alert(newsId: 'b', isRead: true),
          alert(newsId: 'c'),
        ],
      );

      expect(data.unreadCount, 2);
      expect(data.isEmpty, isFalse);
      expect(const AlertsSnapshot().isEmpty, isTrue);
      expect(const AlertsSnapshot().unreadCount, 0);
    });

    test('markRead marca um e deixa os outros', () {
      final data = snapshot(
        alerts: [
          alert(newsId: 'a'),
          alert(newsId: 'b'),
        ],
      );

      final marked = data.markRead('a');

      expect(marked.alerts.map((x) => (x.newsId, x.isRead)), [
        ('a', true),
        ('b', false),
      ]);
      expect(marked.lastCheckAt, data.lastCheckAt);
    });

    test('markRead de id inexistente: igual, sem erro', () {
      final data = snapshot(alerts: [alert(newsId: 'a')]);

      final marked = data.markRead('x');

      expect(marked.alerts.map((a) => (a.newsId, a.isRead)), [('a', false)]);
    });

    test('markAllRead marca todos', () {
      final data = snapshot(
        alerts: [
          alert(newsId: 'a'),
          alert(newsId: 'b'),
        ],
      );

      expect(data.markAllRead().unreadCount, 0);
      expect(data.markAllRead().alerts, hasLength(2));
    });

    test('merge: junta, tira os de mais de 30 dias, ordena e limita a 50', () {
      final data = snapshot(
        alerts: [
          alert(
            newsId: 'velho',
            publishedAt: testNow.subtract(const Duration(days: 31)),
          ),
          alert(
            newsId: 'meio',
            publishedAt: testNow.subtract(const Duration(days: 2)),
          ),
        ],
      );

      final merged = data.merge([
        alert(
          newsId: 'novo',
          publishedAt: testNow.subtract(const Duration(minutes: 1)),
        ),
        alert(newsId: 'meio'),
      ], testNow);

      expect(merged.alerts.map((a) => a.newsId), ['novo', 'meio']);
    });

    test('merge: alerta com exatamente 30 dias fica', () {
      final merged = const AlertsSnapshot().merge([
        alert(
          newsId: 'limite',
          publishedAt: testNow.subtract(const Duration(days: 30)),
        ),
      ], testNow);

      expect(merged.alerts.map((a) => a.newsId), ['limite']);
    });

    test('merge não mexe no horário nem na chave', () {
      final data = snapshot(receiveAlerts: true);

      final merged = data.merge([alert(newsId: 'a')], testNow);

      expect(merged.lastCheckAt, data.lastCheckAt);
      expect(merged.receiveAlerts, isTrue);
    });
  });

  group('use cases', () {
    late FakeNotificationsRepository repository;

    setUp(() {
      repository = FakeNotificationsRepository()
        ..stored = snapshot(
          alerts: [
            alert(newsId: 'a'),
            alert(newsId: 'b', isRead: true),
          ],
        );
    });

    test('GetAlertsUseCase devolve o registro', () async {
      final result = (await GetAlertsUseCase(repository)()).toNullable();

      expect(result!.alerts.map((a) => a.newsId), ['a', 'b']);
    });

    test('GetAlertsUseCase repassa a falha', () async {
      repository.getSnapshotError = const CacheFailure();

      final result = await GetAlertsUseCase(repository)();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('MarkAsReadUseCase grava o registro com o alerta lido', () async {
      final result = await MarkAsReadUseCase(repository)('a');

      expect(result.toNullable()!.unreadCount, 0);
      expect(repository.saves.single.alerts.first.isRead, isTrue);
    });

    test(
      'MarkAsReadUseCase com id inexistente: sem erro e sem gravar',
      () async {
        final result = await MarkAsReadUseCase(repository)('x');

        expect(result.isRight(), isTrue);
        expect(repository.saves, isEmpty);
      },
    );

    test('MarkAsReadUseCase repassa a falha ao gravar', () async {
      repository.saveError = const CacheFailure();

      final result = await MarkAsReadUseCase(repository)('a');

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('MarkAllAsReadUseCase grava tudo lido', () async {
      final result = await MarkAllAsReadUseCase(repository)();

      expect(result.toNullable()!.unreadCount, 0);
      expect(repository.saves.single.unreadCount, 0);
    });

    test('MarkAllAsReadUseCase sem não lidos: não grava', () async {
      repository.stored = snapshot(alerts: [alert(newsId: 'a', isRead: true)]);

      final result = await MarkAllAsReadUseCase(repository)();

      expect(result.isRight(), isTrue);
      expect(repository.saves, isEmpty);
    });

    test('ClearAlertsUseCase repassa ao repository', () async {
      final result = await ClearAlertsUseCase(repository)();

      expect(result.isRight(), isTrue);
      expect(repository.clearCalls, 1);
      expect(repository.stored.isEmpty, isTrue);
    });
  });
}
