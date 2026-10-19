import 'dart:ui' show VoidCallback;

import 'package:click_seguro_app/modules/activities/domain/entities/guest_answer.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';

/// Progresso do visitante na sessão atual do app (RN-006, R3 de
/// specs/015-painel-atividades): só em memória, uma resposta por lição (a mais
/// recente). Quem grava é a B3; o painel lê.
///
/// Ouve a sessão. Visitante que cria uma conta: as respostas viram pendentes
/// de envio para a conta nova (FR-008a). Qualquer outra saída do modo
/// visitante, ou de uma conta, apaga tudo.
class GuestProgressStore {
  GuestProgressStore(this._session) : _status = _session.sessionStatus.value {
    _session.sessionStatus.addListener(_onSessionChanged);
  }

  final UserSessionService _session;
  UserSessionStatus _status;

  /// Por `lessonId`.
  final Map<String, GuestAnswer> _answers = {};

  final List<GuestAnswer> _pending = [];

  /// Chamado logo depois de um cadastro que deixou respostas pendentes: o
  /// repositório começa a transferência sem esperar o painel.
  VoidCallback? onSignUp;

  /// Respostas do visitante a enviar para a conta recém-criada.
  List<GuestAnswer> get pendingTransfer => List.unmodifiable(_pending);

  /// Guarda a resposta; a mesma lição de novo substitui a anterior (o
  /// serviço também considera a mais recente). A B3 chama ao responder.
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

  /// Tira uma resposta já enviada (ou que não adianta reenviar).
  void removePending(GuestAnswer answer) => _pending.remove(answer);

  void _onSessionChanged() {
    final UserSessionStatus previous = _status;
    _status = _session.sessionStatus.value;
    if (previous == _status) return;
    if (previous == UserSessionStatus.authenticated) _pending.clear();
    if (previous != UserSessionStatus.guest) return;

    final bool signedUp =
        _status == UserSessionStatus.authenticated &&
        _session.startedFromSignUp;
    if (signedUp && _answers.isNotEmpty) {
      _pending.addAll(_answers.values);
      onSignUp?.call();
    }
    _answers.clear();
  }

  void dispose() => _session.sessionStatus.removeListener(_onSessionChanged);
}
