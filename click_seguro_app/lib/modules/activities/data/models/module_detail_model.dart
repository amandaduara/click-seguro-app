import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';

/// `GET /app/educational/modules/{id}` (contrato da API 1.0.10). Só o que é
/// usado: `explanation` (a mostrada vem da correção), `description`,
/// `iconUrl` e `progress.isCompleted` são ignorados (R2 de
/// specs/017-perguntas-atividades e de specs/018).
class ModuleDetailModel {
  const ModuleDetailModel({
    required this.title,
    required this.lessons,
    this.score,
  });

  factory ModuleDetailModel.fromJson(Map<String, dynamic> json) =>
      ModuleDetailModel(
        title: json['title'] as String,
        lessons: [
          for (final Object? item in json['lessons'] as List? ?? const [])
            ?_lessonFromJson(item as Map<String, dynamic>),
        ]..sort((a, b) => a.order.compareTo(b.order)),
        score: _scoreFromJson(json['progress']),
      );

  final String title;
  final List<LessonEntity> lessons;
  final ModuleScoreEntity? score;

  ModuleDetailEntity toEntity() =>
      ModuleDetailEntity(title: title, lessons: lessons, score: score);

  /// `totalScore` vem 0 até a primeira resposta da conta no módulo: sem
  /// pontuação, para nunca mostrar "0 de 0" (R0 de specs/015).
  static ModuleScoreEntity? _scoreFromJson(Object? progress) {
    if (progress is! Map<String, dynamic>) return null;
    final int total = (progress['totalScore'] as num?)?.toInt() ?? 0;
    if (total <= 0) return null;
    return ModuleScoreEntity(
      score: (progress['score'] as num?)?.toInt() ?? 0,
      total: total,
    );
  }

  /// Uma lição precisa de duas alternativas ou mais (CB-012).
  static const int minOptions = 2;

  /// `null` quando a lição não pode ser mostrada: sem `id`, sem enunciado ou
  /// com menos de [minOptions] alternativas válidas.
  static LessonEntity? _lessonFromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? question = json['question'];
    if (id is! String || id.isEmpty || question is! String) return null;
    if (question.isEmpty) return null;
    final List<LessonOptionEntity> options = [
      for (final Object? item in json['options'] as List? ?? const [])
        ?_optionFromJson(item as Map<String, dynamic>),
    ];
    if (options.length < minOptions) return null;
    final Object? image = json['imageUrl'];
    return LessonEntity(
      id: id,
      order: (json['order'] as num?)?.toInt() ?? 0,
      question: question,
      imageUrl: image is String && image.isNotEmpty ? image : null,
      options: options,
      isCompleted: json['isCompleted'] == true,
    );
  }

  static LessonOptionEntity? _optionFromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? text = json['text'];
    if (id is! String || id.isEmpty || text is! String || text.isEmpty) {
      return null;
    }
    return LessonOptionEntity(id: id, text: text);
  }
}
