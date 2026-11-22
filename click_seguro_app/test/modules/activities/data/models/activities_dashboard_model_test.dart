import 'package:click_seguro_app/modules/activities/data/models/activities_dashboard_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/activities_fixtures.dart';

void main() {
  ActivitiesDashboardEntity parse(Map<String, dynamic> json) =>
      ActivitiesDashboardModel.fromJson(json).toEntity();

  test('JSON do serviço → painel com os módulos e os totais', () {
    final dashboard = parse(dashboardJson(modules: threeModulesJson(m2: 2)));

    expect([for (final m in dashboard.modules) m.id], ['m1', 'm2', 'm3']);
    final m2 = dashboard.modules[1];
    expect(m2.title, 'Golpes no WhatsApp');
    expect(m2.description, 'Entenda como criminosos clonam contas.');
    expect(m2.order, 2);
    expect(m2.iconUrl, 'https://img.test/m2.png');
    expect(m2.lessonsCount, 3);
    expect(m2.completedCount, 2);
    expect(dashboard.totalCompleted, 2);
    expect(dashboard.totalAvailable, 9);
  });

  test('ordena por order, mesmo vindo fora de ordem', () {
    final List<Map<String, dynamic>> modules = threeModulesJson().reversed
        .toList();

    expect(
      [for (final m in parse(dashboardJson(modules: modules)).modules) m.id],
      ['m1', 'm2', 'm3'],
    );
  });

  test('iconUrl vazio ou ausente → null', () {
    final dashboard = parse(
      dashboardJson(
        modules: [
          moduleJson(iconUrl: ''),
          moduleJson(id: 'm2', order: 2, iconUrl: null),
        ],
      ),
    );

    expect(dashboard.modules[0].iconUrl, isNull);
    expect(dashboard.modules[1].iconUrl, isNull);
  });

  test('contagens ausentes → 0; progressPercent é ignorado', () {
    final Map<String, dynamic> json = moduleJson()
      ..remove('lessonsCount')
      ..remove('completedCount')
      ..['progressPercent'] = 80;

    final module = parse(dashboardJson(modules: [json])).modules.single;

    expect(module.lessonsCount, 0);
    expect(module.completedCount, 0);
  });

  test('módulo sem id ou sem título é descartado', () {
    final dashboard = parse(
      dashboardJson(
        modules: [
          moduleJson()..remove('id'),
          moduleJson(id: 'm2', order: 2)..remove('title'),
          moduleJson(id: 'm3', order: 3),
        ],
      ),
    );

    expect([for (final m in dashboard.modules) m.id], ['m3']);
  });

  group('pontuação na lista (specs/025)', () {
    test('score/totalScore viram a pontuação do módulo', () {
      final Map<String, dynamic> json = moduleJson(completedCount: 3)
        ..['score'] = 1
        ..['totalScore'] = 3;

      final module = parse(dashboardJson(modules: [json])).modules.single;

      expect(module.score?.score, 1);
      expect(module.score?.total, 3);
      expect(module.status, ModuleStatus.retry);
    });

    test('ausentes ou totalScore 0 → sem pontuação (concluído)', () {
      final Map<String, dynamic> zero = moduleJson(completedCount: 3)
        ..['score'] = 0
        ..['totalScore'] = 0;
      final dashboard = parse(
        dashboardJson(
          modules: [
            moduleJson(completedCount: 3),
            {...zero, 'id': 'm2', 'order': 2},
          ],
        ),
      );

      expect([for (final m in dashboard.modules) m.score], [null, null]);
      expect(dashboard.modules.first.status, ModuleStatus.completed);
    });
  });
}
