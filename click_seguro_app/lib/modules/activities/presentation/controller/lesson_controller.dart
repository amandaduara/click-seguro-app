import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/failures/activities_failures.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/answer_lesson_usecase.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_module_detail_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_status.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

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

  /// Durante o envio a pergunta não troca: o resultado é dela (revisão da
  /// branch de specs/018).
  bool get canGoPrevious => !_isSubmitting && _currentIndex > 0;

  /// Só depois de responder a atual, e nunca além da última (clarificação de
  /// 2026-10-21).
  bool get canGoNext {
    final LessonEntity? lesson = current;
    final int total = _module?.lessons.length ?? 0;
    return !_isSubmitting &&
        lesson != null &&
        lesson.isCompleted &&
        _currentIndex < total - 1;
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

  /// O resultado recebido nesta visita para a pergunta atual.
  AnswerResultEntity? get currentResult => _currentAnswer?.result;

  /// A última pontuação conhecida do módulo (do serviço com conta, do
  /// registro sem conta); `null` enquanto não há (FR-011).
  ModuleScoreEntity? get score => _module?.score;

  bool get isLastLesson {
    final int total = _module?.lessons.length ?? 0;
    return total > 0 && _currentIndex == total - 1;
  }

  /// Não troca a escolha durante o envio nem depois da correção.
  bool get canSelect =>
      current != null && !_isSubmitting && currentResult == null;

  bool get canConfirm => canSelect && selectedOptionId != null;

  void select(String optionId) {
    final LessonEntity? lesson = current;
    if (!canSelect || lesson == null) return;
    _answers[lesson.id] = _LessonAnswerState(selectedOptionId: optionId);
    _notify();
  }

  /// Apaga o resultado da pergunta atual para responder outra vez; ela
  /// continua concluída (clarificação Q1 de specs/018).
  void answerAgain() {
    final LessonEntity? lesson = current;
    if (lesson == null || _isSubmitting || currentResult == null) return;
    _answers.remove(lesson.id);
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
    switch (result) {
      // A pergunta mudou no serviço: recarrega (R5 de specs/018).
      case Left(value: AnswerRejectedFailure()):
        await load(moduleId);
        return AnswerAttempt.rejected;
      // A escolha continua marcada para tentar de novo (FR-013).
      case Left():
        _notify();
        return AnswerAttempt.failed;
      case Right(value: final outcome):
        _answers[lesson.id] = _LessonAnswerState(
          selectedOptionId: optionId,
          result: outcome.result,
        );
        _markCompleted(lesson.id, outcome.score);
        _notify();
        return AnswerAttempt.answered;
    }
  }

  /// Respondida, certa ou errada, conta como concluída (RN-006). A lista é
  /// a mesma, na mesma ordem: as alternativas não mudam de lugar (R3). A
  /// pontuação que não veio mantém a anterior (FR-009).
  void _markCompleted(String lessonId, ModuleScoreEntity? score) {
    final ModuleDetailEntity? module = _module;
    if (module == null) return;
    _module = ModuleDetailEntity(
      title: module.title,
      lessons: [
        for (final LessonEntity lesson in module.lessons)
          lesson.id == lessonId ? lesson.withCompleted(true) : lesson,
      ],
      score: score ?? module.score,
    );
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

/// A pergunta nesta visita: a alternativa marcada e, depois da correção, o
/// resultado.
class _LessonAnswerState {
  const _LessonAnswerState({required this.selectedOptionId, this.result});

  final String selectedOptionId;
  final AnswerResultEntity? result;
}
