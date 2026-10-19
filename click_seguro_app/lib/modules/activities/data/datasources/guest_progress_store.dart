import 'package:click_seguro_app/modules/activities/domain/entities/guest_answer.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';

/// Progresso do visitante na sessão atual do app (RN-006, R3 de
/// specs/015-painel-atividades): só em memória, uma resposta por lição (a mais
/// recente). Quem grava é a B3; o painel lê.
///
/// Ouve a sessão: ao sair do modo visitante (ou de uma conta), tudo é apagado.
class GuestProgressStore {
  GuestProgressStore(this._session) : _status = _session.sessionStatus.value {
    _session.sessionStatus.addListener(_onSessionChanged);
  }

  final UserSessionService _session;
  UserSessionStatus _status;

  /// Por `lessonId`.
  final Map<String, GuestAnswer> _answers = {};

  /// Guarda a resposta; a mesma lição de novo substitui a anterior (o
  /// serviço também considera a mais recente).
  void recordAnswer({
    required String moduleId,
    required String lessonId,
    required String selectedOptionId,
  }) {
    _answers[lessonId] = GuestAnswer(
      moduleId: moduleId,
      lessonId: lessonId,
      selectedOptionId: selectedOptionId,
    );
  }

  /// Lições respondidas do módulo (respondida = concluída, R0).
  int answeredCount(String moduleId) =>
      _answers.values.where((answer) => answer.moduleId == moduleId).length;

  void _onSessionChanged() {
    final UserSessionStatus previous = _status;
    _status = _session.sessionStatus.value;
    if (previous == _status) return;
    if (previous == UserSessionStatus.guest ||
        previous == UserSessionStatus.authenticated) {
      _answers.clear();
    }
  }

  void dispose() => _session.sessionStatus.removeListener(_onSessionChanged);
}
