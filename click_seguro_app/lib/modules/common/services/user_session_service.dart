import 'dart:convert';

import 'package:click_seguro_app/modules/common/services/secure_storage_service.dart';
import 'package:flutter/foundation.dart';

enum UserSessionStatus { authenticated, guest, unauthenticated }

/// Motivo do último encerramento de sessão: decide entre levar ao login
/// ([userLogout]) ou mostrar o aviso de sessão expirada ([expired]).
enum SessionEndReason { userLogout, expired }

/// Sessão do aparelho: estado observável em memória + um único registro JSON
/// no armazenamento seguro (ver specs/001-sessao-persistente-visitante).
///
/// Toda transição atualiza os campos e notifica [sessionStatus] antes de
/// gravar no disco; falhas de armazenamento nunca sobem para quem chama.
class UserSessionService {
  UserSessionService(this._storage);

  /// Chave do registro da sessão no armazenamento seguro.
  static const String storageKey = 'session';

  static const String _statusAuthenticated = 'authenticated';
  static const String _statusGuest = 'guest';

  final SecureStorageService _storage;

  String? token;
  String? userId;
  String? userName;
  SessionEndReason? endReason;

  final ValueNotifier<UserSessionStatus> sessionStatus =
      ValueNotifier<UserSessionStatus>(UserSessionStatus.unauthenticated);

  bool get isAuthenticated =>
      sessionStatus.value == UserSessionStatus.authenticated;

  bool get isGuest => sessionStatus.value == UserSessionStatus.guest;

  /// Restaura a sessão guardada. Registro ausente, inválido ou ilegível
  /// resulta em desconectado. Nunca lança.
  Future<void> restoreSession() async {
    final String? raw;
    try {
      raw = await _storage.read(storageKey);
    } catch (_) {
      _setUnauthenticated();
      return;
    }
    if (raw == null) {
      _setUnauthenticated();
      return;
    }

    final record = _parseRecord(raw);
    if (record == null) {
      _setUnauthenticated();
      await _safely(() => _storage.delete(storageKey));
      return;
    }

    token = record['token'] as String?;
    userId = record['userId'] as String?;
    userName = record['userName'] as String?;
    endReason = null;
    sessionStatus.value = record['status'] == _statusGuest
        ? UserSessionStatus.guest
        : UserSessionStatus.authenticated;
  }

  /// Inicia (ou troca) a sessão conectada. Chamado pelo repository de
  /// autenticação após login ou cadastro.
  Future<void> saveSession({
    required String token,
    required String userId,
    String? userName,
  }) async {
    if (token.isEmpty) throw ArgumentError.value(token, 'token', 'vazio');
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId', 'vazio');

    this.token = token;
    this.userId = userId;
    this.userName = userName;
    endReason = null;
    sessionStatus.value = UserSessionStatus.authenticated;

    await _safely(
      () => _storage.write(
        storageKey,
        jsonEncode({
          'status': _statusAuthenticated,
          'token': token,
          'userId': userId,
          'userName': ?userName,
        }),
      ),
    );
  }

  /// Entra como visitante (RF-005): sem conta e sem credencial. O estado é
  /// lembrado entre aberturas até o login ou a saída do modo visitante.
  Future<void> startGuestSession() async {
    token = null;
    userId = null;
    userName = null;
    endReason = null;
    sessionStatus.value = UserSessionStatus.guest;

    await _safely(
      () => _storage.write(storageKey, jsonEncode({'status': _statusGuest})),
    );
  }

  /// Saída pedida pelo usuário (da conta ou do modo visitante): a navegação
  /// deve levar ao login. Não toca em dados do aparelho (FR-013).
  Future<void> logout() => _end(SessionEndReason.userLogout);

  /// Sessão recusada pelo serviço (401) durante o uso: o usuário fica na
  /// tela e vê o aviso de sessão expirada (FR-012a). Só age se conectado, para
  /// que um 401 de senha errada no login não gere o aviso.
  Future<void> expire() async {
    if (!isAuthenticated) return;
    await _end(SessionEndReason.expired);
  }

  Future<void> _end(SessionEndReason reason) async {
    endReason = reason;
    _setUnauthenticated();
    await _safely(() => _storage.delete(storageKey));
  }

  void _setUnauthenticated() {
    token = null;
    userId = null;
    userName = null;
    sessionStatus.value = UserSessionStatus.unauthenticated;
  }

  /// Devolve o registro se ele respeitar as regras do SessionRecord
  /// (data-model.md), ou null se for inválido.
  Map<String, dynamic>? _parseRecord(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    bool isFilled(Object? value) => value is String && value.isNotEmpty;

    switch (decoded['status']) {
      case _statusAuthenticated:
        final validName =
            decoded['userName'] == null || decoded['userName'] is String;
        return isFilled(decoded['token']) &&
                isFilled(decoded['userId']) &&
                validName
            ? decoded
            : null;
      case _statusGuest:
        return decoded.containsKey('token') ? null : decoded;
      default:
        return null;
    }
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // O estado em memória já vale para esta execução; o próximo
      // restoreSession trata registro ausente ou inválido (FR-014).
    }
  }
}
