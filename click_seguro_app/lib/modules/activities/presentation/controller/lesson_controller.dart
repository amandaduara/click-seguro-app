import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/failures/activities_failures.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/answer_lesson_usecase.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_module_detail_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_status.dart';
import 'package:flutter/foundation.dart';

/// O que aconteceu ao confirmar uma resposta (data-model de specs/018).
enum AnswerAttempt { answered, failed, rejected, ignored }

/// Perguntas de um módulo, uma por vez, e a resposta de cada uma
/// (data-model de specs/017-perguntas-atividades e de specs/018; R1: um
/// controller só, porque avançar depende de responder).
class LessonController extends ChangeNotifier {
  LessonController({
    required GetModuleDetailUseCase getModuleDetail,
    required AnswerLessonUseCase answerLesson,
  }) : _getModuleDetail = getModuleDetail,
       _answerLesson = answerLesson;

  final GetModuleDetailUseCase _getModuleDetail;
  final AnswerLessonUseCase _answerLesson;

  LessonStatus _status = LessonStatus.loading;
  LessonStatus get status => _status;

  ModuleDetailEntity? _module;
  ModuleDetailEntity? get module => _module;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  /// `null` antes da carga e num módulo sem lições válidas.
  LessonEntity? get current {
    final List<LessonEntity> lessons = _module?.lessons ?? const [];
    return lessons.isEmpty ? null : lessons[_currentIndex];
  }

  bool get canGoPrevious => _currentIndex > 0;

  /// Só depois de responder a atual, e nunca além da última (clarificação de
  /// 2026-10-21). A B3 é quem marca a resposta.
  bool get canGoNext {
    final LessonEntity? lesson = current;
    final int total = _module?.lessons.length ?? 0;
    return lesson != null && lesson.isCompleted && _currentIndex < total - 1;
  }

  void goPrevious() {
    if (!canGoPrevious) return;
    _currentIndex--;
    _notify();
  }

  void goNext() {
    if (!canGoNext) return;
    _currentIndex++;
    _notify();
  }

  String? _moduleId;

  /// Escolha e resultado de cada pergunta nesta visita, por `lessonId` (R6).
  final Map<String, _LessonAnswerState> _answers = {};

  _LessonAnswerState? get _currentAnswer {
    final LessonEntity? lesson = current;
    return lesson == null ? null : _answers[lesson.id];
  }

  /// A alternativa marcada na pergunta atual.
  String? get selectedOptionId => _currentAnswer?.selectedOptionId;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool get canSelect => current != null && !_isSubmitting;

  bool get canConfirm => canSelect && selectedOptionId != null;

  void select(String optionId) {
    final LessonEntity? lesson = current;
    if (!canSelect || lesson == null) return;
    _answers[lesson.id] = _LessonAnswerState(selectedOptionId: optionId);
    _notify();
  }

  /// Envia a escolha uma vez; toques durante o envio são ignorados.
  Future<AnswerAttempt> confirm() async {
    final LessonEntity? lesson = current;
    final String? moduleId = _moduleId;
    final String? optionId = selectedOptionId;
    if (!canConfirm || lesson == null || moduleId == null || optionId == null) {
      return AnswerAttempt.ignored;
    }
    _isSubmitting = true;
    _notify();
    final result = await _answerLesson(
      moduleId: moduleId,
      lessonId: lesson.id,
      selectedOptionId: optionId,
    );
    _isSubmitting = false;
    if (_disposed) return AnswerAttempt.ignored;
    final AnswerAttempt attempt = result.fold(
      (_) => AnswerAttempt.failed,
      (_) => AnswerAttempt.answered,
    );
    _notify();
    return attempt;
  }

  bool _disposed = false;

  /// Carrega e começa na primeira pergunta ainda não respondida (FR-004).
  Future<void> load(String moduleId) async {
    _moduleId = moduleId;
    _answers.clear();
    _status = LessonStatus.loading;
    _notify();
    final result = await _getModuleDetail(moduleId);
    if (_disposed) return;
    result.fold(
      (failure) {
        _status = failure is ModuleNotFoundFailure
            ? LessonStatus.empty
            : LessonStatus.error;
      },
      (module) {
        _module = module;
        final int firstOpen = module.lessons.indexWhere((l) => !l.isCompleted);
        _currentIndex = firstOpen < 0 ? 0 : firstOpen;
        _status = module.isEmpty ? LessonStatus.empty : LessonStatus.loaded;
      },
    );
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

/// A pergunta nesta visita: a alternativa marcada.
class _LessonAnswerState {
  const _LessonAnswerState({required this.selectedOptionId});

  final String selectedOptionId;
}
