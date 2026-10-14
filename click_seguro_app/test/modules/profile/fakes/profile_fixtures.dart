/// JSON no formato real do servidor (R0 de specs/012-perfil), com valores
/// fictícios.
Map<String, dynamic> profileJson({
  String name = 'Maria da Silva',
  String email = 'maria@exemplo.com',
  String? phone,
  String? avatarUrl,
  bool receiveNotifications = true,
}) => {
  'name': name,
  'email': email,
  'phone': phone,
  'role': 'USER',
  'receiveNotifications': receiveNotifications,
  'avatarUrl': avatarUrl,
};

/// `GET /users/me/news/{read,saved,liked}?limit=1`: só o `meta.total` importa.
Map<String, dynamic> newsCountJson(int total) => {
  'data': <Object>[],
  'meta': {
    'page': 1,
    'limit': 1,
    'total': total,
    'totalPages': total == 0 ? 0 : total,
    'hasNextPage': false,
    'hasPreviousPage': false,
  },
};

Map<String, dynamic> moduleJson({
  required String id,
  String title = 'Golpes Digitais',
  int order = 1,
  int lessonsCount = 3,
  int completedCount = 0,
}) => {
  'id': id,
  'title': title,
  'description': 'Aprenda a reconhecer golpes.',
  'order': order,
  'iconUrl': null,
  'lessonsCount': lessonsCount,
  'completedCount': completedCount,
  'progressPercent': lessonsCount == 0
      ? 0
      : (completedCount * 100 / lessonsCount).round(),
};

/// `GET /app/educational/modules`.
Map<String, dynamic> modulesJson({
  List<Map<String, dynamic>> modules = const [],
  int totalLessonsCompleted = 0,
}) => {
  'modules': modules,
  'totalLessonsCompleted': totalLessonsCompleted,
  'totalLessonsAvailable': modules.fold<int>(
    0,
    (sum, module) => sum + (module['lessonsCount'] as num).toInt(),
  ),
};
