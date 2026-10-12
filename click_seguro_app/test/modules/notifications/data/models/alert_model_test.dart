import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/alerts_fixtures.dart';

void main() {
  group('AlertModel.fromNewsJson', () {
    test('item real: id, título, fonte e publishedAt em UTC, não lido', () {
      final model = AlertModel.fromNewsJson(realBankNewsJson);

      expect(model.newsId, 'cmuywjppz0001fo1slem3p1zr');
      expect(model.title, 'Banco não pede senha, token ou código por telefone');
      expect(model.source, 'Banco Central do Brasil');
      expect(model.publishedAt, DateTime.utc(2026, 10, 8, 2, 16, 3, 253));
      expect(model.publishedAt.isUtc, isTrue);
      expect(model.isRead, isFalse);
    });

    test('sem publishedAt usa originalPublishedAt', () {
      final model = AlertModel.fromNewsJson(
        newsItemJson(
          id: 'n1',
          publishedAt: null,
          originalPublishedAt: '2026-09-20T08:30:00.000Z',
        ),
      );

      expect(model.publishedAt, DateTime.utc(2026, 9, 20, 8, 30));
    });

    test('data com offset vira UTC', () {
      final model = AlertModel.fromNewsJson(
        newsItemJson(id: 'n1', publishedAt: '2026-10-09T11:00:00.000-03:00'),
      );

      expect(model.publishedAt, DateTime.utc(2026, 10, 9, 14));
      expect(model.publishedAt.isUtc, isTrue);
    });

    test('sem id, título ou fonte: FormatException', () {
      for (final key in ['id', 'title', 'source']) {
        final json = newsItemJson(id: 'n1')..remove(key);

        expect(
          () => AlertModel.fromNewsJson(json),
          throwsFormatException,
          reason: 'sem $key',
        );
      }
    });

    test('título ou fonte vazios: FormatException', () {
      expect(
        () => AlertModel.fromNewsJson(newsItemJson(id: 'n1', title: '  ')),
        throwsFormatException,
      );
      expect(
        () => AlertModel.fromNewsJson(newsItemJson(id: 'n1', source: '')),
        throwsFormatException,
      );
    });

    test('sem nenhuma das duas datas: FormatException', () {
      final json = newsItemJson(id: 'n1', publishedAt: null)
        ..remove('originalPublishedAt');

      expect(() => AlertModel.fromNewsJson(json), throwsFormatException);
    });

    test('data ilegível: FormatException', () {
      expect(
        () => AlertModel.fromNewsJson(
          newsItemJson(id: 'n1', publishedAt: 'ontem'),
        ),
        throwsFormatException,
      );
    });
  });

  group('AlertModel registro', () {
    test('toJson e fromJson fazem a ida e a volta', () {
      final model = AlertModel.fromEntity(
        alert(
          newsId: 'n7',
          title: 'Título',
          source: 'Fonte',
          publishedAt: DateTime.utc(2026, 10, 9, 14, 10),
          isRead: true,
        ),
      );

      final json = model.toJson();
      final back = AlertModel.fromJson(json);

      expect(json, {
        'newsId': 'n7',
        'title': 'Título',
        'source': 'Fonte',
        'publishedAt': '2026-10-09T14:10:00.000Z',
        'isRead': true,
      });
      expect(back.toEntity(), model.toEntity());
      expect(back.isRead, isTrue);
      expect(back.publishedAt, DateTime.utc(2026, 10, 9, 14, 10));
    });

    test('isRead ausente: não lido', () {
      final json = AlertModel.fromEntity(alert()).toJson()..remove('isRead');

      expect(AlertModel.fromJson(json).isRead, isFalse);
    });

    test('toEntity mantém todos os campos', () {
      final entity = alert(newsId: 'x', isRead: true);

      final back = AlertModel.fromEntity(entity).toEntity();

      expect(back.newsId, 'x');
      expect(back.title, entity.title);
      expect(back.source, entity.source);
      expect(back.publishedAt, entity.publishedAt);
      expect(back.isRead, isTrue);
    });

    test('registro sem campo obrigatório: FormatException', () {
      for (final key in ['newsId', 'title', 'source', 'publishedAt']) {
        final json = AlertModel.fromEntity(alert()).toJson()..remove(key);

        expect(
          () => AlertModel.fromJson(json),
          throwsFormatException,
          reason: 'sem $key',
        );
      }
    });
  });

  group('AlertsSnapshotModel', () {
    test('ida e volta com horário, chave e alertas', () {
      final snapshot = AlertsSnapshotModel(
        lastCheckAt: DateTime.utc(2026, 10, 9, 15),
        receiveAlerts: false,
        alerts: [AlertModel.fromEntity(alert(newsId: 'a'))],
      );

      final back = AlertsSnapshotModel.fromJson(snapshot.toJson());

      expect(back.lastCheckAt, DateTime.utc(2026, 10, 9, 15));
      expect(back.receiveAlerts, isFalse);
      expect(back.alerts.single.newsId, 'a');
    });

    test('lastCheckAt e receiveAlerts ausentes: null', () {
      final model = AlertsSnapshotModel.fromJson({'alerts': <Object>[]});

      expect(model.lastCheckAt, isNull);
      expect(model.receiveAlerts, isNull);
    });

    test('lastCheckAt ilegível: null', () {
      final model = AlertsSnapshotModel.fromJson({'lastCheckAt': 'ontem'});

      expect(model.lastCheckAt, isNull);
    });

    test('alerts ausente: lista vazia', () {
      expect(AlertsSnapshotModel.fromJson(const {}).alerts, isEmpty);
    });

    test('item ilegível é descartado, os outros ficam', () {
      final model = AlertsSnapshotModel.fromJson({
        'alerts': [
          AlertModel.fromEntity(alert(newsId: 'bom')).toJson(),
          {'newsId': 'sem-titulo'},
          'texto solto',
          AlertModel.fromEntity(alert(newsId: 'bom2')).toJson(),
        ],
      });

      expect(model.alerts.map((a) => a.newsId), ['bom', 'bom2']);
    });

    test('toEntity e fromEntity', () {
      final entity = snapshot(
        receiveAlerts: true,
        alerts: [
          alert(newsId: 'a'),
          alert(newsId: 'b', isRead: true),
        ],
      );

      final back = AlertsSnapshotModel.fromEntity(entity).toEntity();

      expect(back.lastCheckAt, entity.lastCheckAt);
      expect(back.receiveAlerts, isTrue);
      expect(back.alerts.map((a) => (a.newsId, a.isRead)), [
        ('a', false),
        ('b', true),
      ]);
    });
  });
}
