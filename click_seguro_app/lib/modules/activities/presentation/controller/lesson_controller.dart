import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/failures/activities_failures.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_module_detail_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_status.dart';
import 'package:flutter/foundation.dart';

/// Perguntas de um módulo, uma por vez (data-model de
/// specs/017-perguntas-atividades).
class LessonController extends ChangeNotifier {
  LessonController({required GetModuleDetailUseCase getModuleDetail})
    : _getModuleDetail = getModuleDetail;

  final GetModuleDetailUseCase _getModuleDetail;

  LessonStatus _status = LessonStatus.loading;
  LessonStatus get status => _status;

  ModuleDetailEntity? _module;
  ModuleDetailEntity? get module => _module;

  Failure? _failure;
  Failure? get failure => _failure;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  LessonEntity? get current => _module?.lessons[_currentIndex];

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

  bool _disposed = false;

  /// Carrega e começa na primeira pergunta ainda não respondida (FR-004).
  Future<void> load(String moduleId) async {
    _status = LessonStatus.loading;
    _failure = null;
    _notify();
    final result = await _getModuleDetail(moduleId);
    if (_disposed) return;
    result.fold(
      (failure) {
        _failure = failure;
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
