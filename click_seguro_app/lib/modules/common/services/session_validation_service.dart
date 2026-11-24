import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';

/// Confere com o serviço a conta da sessão salva, na abertura do app
/// (FR-008, specs/002-apiclient-renovacao-sessao).
///
/// Quem chama é o splash (tarefa A1), em paralelo com o tempo mínimo da tela.
class SessionValidationService {
  SessionValidationService(
    this._apiClient,
    this._session, {
    Duration timeout = const Duration(seconds: 3),
  }) : _timeout = timeout;

  static const String mePath = '/users/me';

  final ApiClient _apiClient;
  final UserSessionService _session;
  final Duration _timeout;

  /// Nunca lança. Conta confirmada → atualiza nome e e-mail. Conta desativada
  /// ou renovação recusada → o [ApiClient] já encerrou a sessão. Sem rede,
  /// erro do servidor, corpo inválido ou prazo esgotado → sessão mantida.
  ///
  /// No fim do prazo o pedido é cancelado e a resposta tardia, descartada.
  /// Uma renovação em andamento continua (é compartilhada com outros pedidos).
  Future<void> validateStoredSession() async {
    if (!_session.isAuthenticated) return;

    final cancelToken = CancelToken();
    try {
      final response = await _apiClient
          .get(mePath, cancelToken: cancelToken)
          .timeout(_timeout);
      final data = response.data;
      if (data is Map && data['name'] is String && data['email'] is String) {
        await _session.updateProfile(
          name: data['name'] as String,
          email: data['email'] as String,
        );
      }
    } on TimeoutException {
      cancelToken.cancel();
    } on ApiException {
      // Decisão sobre a sessão já tomada pelo ApiClient (ou sessão mantida).
    }
  }
}
