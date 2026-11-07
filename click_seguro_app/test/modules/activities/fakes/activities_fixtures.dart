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

/// Uma lição no formato de `GET /app/educational/modules/{id}` (R0 de
/// specs/017-perguntas-atividades). [options] são os textos; os ids viram
/// `<id>-o1`, `<id>-o2`…
Map<String, dynamic> lessonJson({
  String id = 'l1',
  int order = 1,
  String question = 'O que fazer com a mensagem?',
  String? imageUrl = 'https://img.test/l1.png',
  List<String> options = const ['Ignorar', 'Responder', 'Ligar'],
  bool isCompleted = false,
  String explanation = 'Explicação que só aparece depois da resposta.',
}) => {
  'id': id,
  'order': order,
  'question': question,
  'explanation': explanation,
  'imageUrl': ?imageUrl,
  'options': [
    for (final (index, text) in options.indexed)
      {'id': '$id-o${index + 1}', 'text': text},
  ],
  'isCompleted': isCompleted,
};

/// O módulo "Golpes Digitais" com três lições; [answered] marca as
/// concluídas (`isCompleted`); [score]/[totalScore] vão no `progress`
/// (`totalScore` 0 até a primeira resposta da conta, R0 de specs/015).
Map<String, dynamic> moduleDetailJson({
  String id = 'm1',
  String title = 'Golpes Digitais',
  List<Map<String, dynamic>>? lessons,
  Set<String> answered = const {},
  int score = 0,
  int totalScore = 0,
}) {
  final List<Map<String, dynamic>> list =
      lessons ??
      [
        lessonJson(
          question: 'Promessa de dinheiro em dobro pelo PIX. O que fazer?',
          options: const [
            'Ignorar e denunciar',
            'Enviar',
            'Pedir prova',
            'Repassar',
          ],
        ),
        lessonJson(
          id: 'l2',
          order: 2,
          question: 'E-mail do banco pede para clicar num link. E agora?',
          imageUrl: 'https://img.test/l2.png',
        ),
        lessonJson(
          id: 'l3',
          order: 3,
          question: 'Técnico pede para instalar um app de acesso remoto.',
          imageUrl: 'https://img.test/l3.png',
        ),
      ];
  return {
    'id': id,
    'title': title,
    'description': 'Aprenda a reconhecer golpes.',
    'order': 1,
    'iconUrl': 'https://img.test/m1.png',
    'lessonsCount': list.length,
    'lessons': [
      for (final lesson in list)
        {...lesson, 'isCompleted': answered.contains(lesson['id'])},
    ],
    'progress': {
      'completedCount': answered.length,
      'progressPercent': 0,
      'score': score,
      'totalScore': totalScore,
      'isCompleted': false,
    },
  };
}

/// O resultado de `POST …/lessons/{lessonId}/answer` (R0 de
/// specs/018-resposta-feedback-atividades). Na `l1`, a correta é a `l1-o1`.
Map<String, dynamic> answerJson({
  bool isCorrect = true,
  String correctOptionId = 'l1-o1',
  String? explanation = 'Promessas de dinheiro em dobro são golpe.',
}) => {
  'isCorrect': isCorrect,
  'correctOptionId': correctOptionId,
  'explanation': ?explanation,
};
