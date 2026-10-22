import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';

/// `GET /app/educational/modules/{id}` (contrato da API 1.0.10). Só o que a
/// B2 usa: `explanation`, `progress`, `description` e `iconUrl` são
/// ignorados (R2 de specs/017-perguntas-atividades).
class ModuleDetailModel {
  const ModuleDetailModel({required this.title, required this.lessons});

  factory ModuleDetailModel.fromJson(Map<String, dynamic> json) =>
      ModuleDetailModel(
        title: json['title'] as String,
        lessons: [
          for (final Object? item in json['lessons'] as List? ?? const [])
            ?_lessonFromJson(item as Map<String, dynamic>),
        ]..sort((a, b) => a.order.compareTo(b.order)),
      );

  final String title;
  final List<LessonEntity> lessons;

  ModuleDetailEntity toEntity() =>
      ModuleDetailEntity(title: title, lessons: lessons);

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
