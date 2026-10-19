/// Um módulo no formato de `GET /app/educational/modules` (R0 de
/// specs/015-painel-atividades).
Map<String, dynamic> moduleJson({
  String id = 'm1',
  String title = 'Golpes Digitais',
  String description = 'Aprenda a reconhecer as táticas mais comuns.',
  int order = 1,
  int lessonsCount = 3,
  int completedCount = 0,
  String? iconUrl = 'https://img.test/m1.png',
}) => {
  'id': id,
  'title': title,
  'description': description,
  'order': order,
  'iconUrl': ?iconUrl,
  'lessonsCount': lessonsCount,
  'completedCount': completedCount,
  'progressPercent': lessonsCount == 0
      ? 0
      : (completedCount * 100 / lessonsCount).round(),
};

/// Os três módulos de hoje no serviço, com o progresso pedido.
List<Map<String, dynamic>> threeModulesJson({
  int m1 = 0,
  int m2 = 0,
  int m3 = 0,
}) => [
  moduleJson(completedCount: m1),
  moduleJson(
    id: 'm2',
    title: 'Golpes no WhatsApp',
    description: 'Entenda como criminosos clonam contas.',
    order: 2,
    completedCount: m2,
    iconUrl: 'https://img.test/m2.png',
  ),
  moduleJson(
    id: 'm3',
    title: 'Fake News',
    description: 'Saiba identificar notícias falsas.',
    order: 3,
    completedCount: m3,
    iconUrl: 'https://img.test/m3.png',
  ),
];

Map<String, dynamic> dashboardJson({
  List<Map<String, dynamic>>? modules,
  int? totalLessonsCompleted,
  int? totalLessonsAvailable,
}) {
  final List<Map<String, dynamic>> list = modules ?? threeModulesJson();
  int sum(String key) =>
      list.fold(0, (total, module) => total + (module[key] as int? ?? 0));
  return {
    'modules': list,
    'totalLessonsCompleted': totalLessonsCompleted ?? sum('completedCount'),
    'totalLessonsAvailable': totalLessonsAvailable ?? sum('lessonsCount'),
  };
}
