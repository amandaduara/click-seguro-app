import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_local_cache_service.dart';
import '../../fakes/alerts_fixtures.dart';

void main() {
  late FakeLocalCacheService cache;
  late String owner;
  late AlertsLocalDataSourceImpl dataSource;

  AlertsSnapshotModel model({List<String> ids = const ['a', 'b']}) =>
      AlertsSnapshotModel(
        lastCheckAt: DateTime.utc(2026, 10, 9, 15),
        receiveAlerts: true,
        alerts: [
          for (final id in ids) AlertModel.fromEntity(alert(newsId: id)),
        ],
      );

  setUp(() {
    cache = FakeLocalCacheService();
    owner = 'maria@example.com';
    dataSource = AlertsLocalDataSourceImpl(cache, owner: () => owner);
  });

  Map<String, dynamic> stored() =>
      cache.values[AlertsLocalDataSourceImpl.cacheKey]!;

  test('a chave é notifications_alerts_v1', () {
    expect(AlertsLocalDataSourceImpl.cacheKey, 'notifications_alerts_v1');
  });

  test('write grava dono, horário, chave e alertas', () async {
    await dataSource.write(model());

    expect(cache.values.keys, ['notifications_alerts_v1']);
    expect(stored()['owner'], 'maria@example.com');
    expect(stored()['lastCheckAt'], '2026-10-09T15:00:00.000Z');
    expect(stored()['receiveAlerts'], isTrue);
    expect((stored()['alerts'] as List).length, 2);
  });

  test('write é uma escrita só', () async {
    await dataSource.write(model());

    expect(cache.writeCalls, 1);
  });

  test('read devolve o registro do mesmo dono', () async {
    await dataSource.write(model());

    final read = await dataSource.read();

    expect(read!.lastCheckAt, DateTime.utc(2026, 10, 9, 15));
    expect(read.receiveAlerts, isTrue);
    expect(read.alerts.map((a) => a.newsId), ['a', 'b']);
  });

  test('nada guardado: null', () async {
    expect(await dataSource.read(), isNull);
  });

  test('dono diferente: null', () async {
    await dataSource.write(model());
    owner = 'outra@example.com';

    expect(await dataSource.read(), isNull);
  });

  test('registro sem dono: null', () async {
    await dataSource.write(model());
    stored().remove('owner');

    expect(await dataSource.read(), isNull);
  });

  test(
    'registro ilegível (alerts que não é lista): só o horário fica',
    () async {
      cache.values[AlertsLocalDataSourceImpl.cacheKey] = {
        'owner': owner,
        'lastCheckAt': '2026-10-09T15:00:00.000Z',
        'alerts': 'quebrado',
      };

      final read = await dataSource.read();

      expect(read!.alerts, isEmpty);
      expect(read.lastCheckAt, DateTime.utc(2026, 10, 9, 15));
    },
  );

  test(
    'registro sem nenhum campo útil além do dono: ainda é um registro',
    () async {
      cache.values[AlertsLocalDataSourceImpl.cacheKey] = {'owner': owner};

      final read = await dataSource.read();

      expect(read!.lastCheckAt, isNull);
      expect(read.alerts, isEmpty);
    },
  );

  test('sem owner injetado, o dono é guest', () async {
    final guest = AlertsLocalDataSourceImpl(cache);

    await guest.write(model());

    expect(stored()['owner'], 'guest');
  });

  test('clear remove a chave', () async {
    await dataSource.write(model());

    await dataSource.clear();

    expect(cache.values, isEmpty);
    expect(await dataSource.read(), isNull);
  });

  test('armazenamento que lança na leitura: a exceção sobe', () async {
    cache.throwOnRead = true;

    await expectLater(dataSource.read(), throwsStateError);
  });

  test('armazenamento que lança na escrita: a exceção sobe', () async {
    cache.throwOnWrite = true;

    await expectLater(dataSource.write(model()), throwsStateError);
  });
}
