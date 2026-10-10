import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/presentation/extensions/alerts_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/alerts_fixtures.dart';

void main() {
  // Datas locais: o agrupamento usa o dia local de `publishedAt`.
  final DateTime now = DateTime(2026, 10, 9, 15);

  List<String> ids(AlertSection section) => [
    for (final alert in section.alerts) alert.newsId,
  ];

  test('lista vazia: sem seções', () {
    expect(<AlertEntity>[].sections(now), isEmpty);
  });

  test('hoje, ontem e anteriores, nessa ordem, sem seção vazia', () {
    final sections = ([
      alert(newsId: 'old', publishedAt: DateTime(2026, 10, 1, 9)),
      alert(newsId: 'today', publishedAt: DateTime(2026, 10, 9, 8)),
      alert(newsId: 'yest', publishedAt: DateTime(2026, 10, 8, 20)),
    ]).sections(now);

    expect(sections.map((s) => s.group), [
      AlertGroup.today,
      AlertGroup.yesterday,
      AlertGroup.earlier,
    ]);
    expect(ids(sections[0]), ['today']);
    expect(ids(sections[1]), ['yest']);
    expect(ids(sections[2]), ['old']);
  });

  test('só uma seção: as outras não aparecem', () {
    final sections = ([
      alert(newsId: 'old', publishedAt: DateTime(2026, 9, 20)),
    ]).sections(now);

    expect(sections.map((s) => s.group), [AlertGroup.earlier]);
  });

  test('dentro do grupo: do mais novo ao mais antigo', () {
    final sections = ([
      alert(newsId: 'a', publishedAt: DateTime(2026, 10, 9, 8)),
      alert(newsId: 'c', publishedAt: DateTime(2026, 10, 9, 14)),
      alert(newsId: 'b', publishedAt: DateTime(2026, 10, 9, 11)),
    ]).sections(now);

    expect(ids(sections.single), ['c', 'b', 'a']);
  });

  test('virada de dia: 23:59 de ontem é ontem, 00:00 é hoje', () {
    final sections = ([
      alert(newsId: 'midnight', publishedAt: DateTime(2026, 10, 9)),
      alert(newsId: 'before', publishedAt: DateTime(2026, 10, 8, 23, 59)),
      alert(newsId: 'two', publishedAt: DateTime(2026, 10, 7, 23, 59)),
    ]).sections(now);

    expect(sections.map((s) => s.group), [
      AlertGroup.today,
      AlertGroup.yesterday,
      AlertGroup.earlier,
    ]);
    expect(ids(sections[0]), ['midnight']);
    expect(ids(sections[1]), ['before']);
  });

  test('ontem vale também na virada do mês', () {
    final sections = ([
      alert(newsId: 'a', publishedAt: DateTime(2026, 9, 30, 10)),
    ]).sections(DateTime(2026, 10, 1, 9));

    expect(sections.single.group, AlertGroup.yesterday);
  });

  test('a data é a local, também para um horário em UTC', () {
    final DateTime utc = DateTime(2026, 10, 9, 8).toUtc();
    final sections = ([alert(newsId: 'a', publishedAt: utc)]).sections(now);

    expect(sections.single.group, AlertGroup.today);
  });

  test('data futura conta como hoje', () {
    final sections = ([
      alert(newsId: 'future', publishedAt: DateTime(2026, 10, 12, 10)),
    ]).sections(now);

    expect(sections.single.group, AlertGroup.today);
  });
}
