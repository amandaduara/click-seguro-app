import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_error_codes.dart';
import 'package:click_seguro_app/modules/common/api_client/redacting_log_interceptor.dart';
import 'package:click_seguro_app/modules/common/config/environment_config.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

/// Categoria da falha de uma chamada HTTP. É o que o repository usa para
/// decidir qual `Failure` devolver — nunca compare `statusCode` com números
/// mágicos (ex.: `0` para "sem conexão").
enum ApiErrorType {
  /// Sem internet, DNS ou servidor inalcançável.
  connection,

  /// Tempo de conexão, envio ou recebimento esgotado.
  timeout,

  /// Requisição cancelada via `CancelToken`.
  cancelled,

  /// 401. A sessão só é encerrada pelo [ApiClient] quando a renovação é
  /// recusada ou o pedido repetido é recusado de novo; `INVALID_CREDENTIALS`
  /// nunca mexe na sessão.
  unauthorized,

  /// Demais 4xx (ex.: 400, 403, 404, 409, 422).
  client,

  /// 5xx.
  server,

  /// Corpo da resposta em formato inesperado (falha de parse no model).
  invalidResponse,

  /// Qualquer outra falha não prevista.
  unknown,
}

/// Erro técnico de uma chamada HTTP. Só circula na camada data: o repository
/// MUST convertê-lo em uma `Failure` antes de devolver o resultado.
class ApiException implements Exception {
  final ApiErrorType type;

  /// Status HTTP, quando houve resposta do servidor.
  final int? statusCode;

  /// Código de erro de negócio devolvido pela API no campo `code` do corpo
  /// (ex.: `INVALID_CREDENTIALS`). Nulo quando o corpo não segue o formato
  /// `{code, message}` (ex.: erro de validação do Zod, página HTML).
  final String? errorCode;

  /// Mensagem técnica, para log e debug. MUST NOT ser exibida ao usuário.
  final String message;

  ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() =>
      'ApiException(${type.name}, status: $statusCode, error: $errorCode): $message';
}

/// Converte a [Response] bruta do Dio em um modelo tipado, evitando que
/// chamadores lidem com `dynamic`/`Map` fora da camada de dados.
///
/// Se o corpo não tiver o formato esperado, lança
/// [ApiException] com [ApiErrorType.invalidResponse].
extension ApiResponseMapper on Response {
  T toModel<T>(T Function(Map<String, dynamic> json) fromJson) {
    return _parse(() => fromJson(data as Map<String, dynamic>));
  }

  List<T> toModelList<T>(T Function(Map<String, dynamic> json) fromJson) {
    return _parse(
      () => (data as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  R _parse<R>(R Function() parser) {
    try {
      return parser();
    } on TypeError catch (e) {
      throw _invalidResponse(e);
    } on FormatException catch (e) {
      throw _invalidResponse(e);
    }
  }

  ApiException _invalidResponse(Object error) {
    return ApiException(
      type: ApiErrorType.invalidResponse,
      statusCode: statusCode,
      message: 'Resposta em formato inesperado: $error',
    );
  }
}

class ApiClient {
  /// Renova o par de tokens (`{refreshToken}` → `{accessToken, refreshToken}`).
  static const String refreshPath = '/auth/app/refresh';

  /// Rotas cujos corpos nunca vão para o log (senhas e tokens, FR-017).
  static const List<String> sensitivePathPrefixes = [
    '/auth/',
    '/users/me/change-password',
  ];

  final Dio _dio;

  /// Renovação em andamento, compartilhada pelos pedidos recusados ao mesmo
  /// tempo (FR-005).
  Future<bool>? _renewal;

  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: EnvironmentConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ),
          ) {
    // Ativa o LogInterceptor apenas se estiver em modo Debug
    if (EnvironmentConfig.debugMode) {
      _dio.interceptors.add(
        RedactingLogInterceptor(sensitivePathPrefixes: sensitivePathPrefixes),
      );
    }
  }

  UserSessionService get _session => GetIt.instance<UserSessionService>();

  // Gera as opções com o token de autenticação se necessário
  Options _makeOptions({bool requiresAuth = true, String? authToken}) {
    final headers = <String, dynamic>{};

    if (requiresAuth) {
      final token = authToken ?? _session.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return Options(headers: headers);
  }

  // ---------------------------------------------------------------------------
  // Métodos HTTP diretos
  // ---------------------------------------------------------------------------

  /// [cancelToken] permite descartar a consulta antes da resposta; o
  /// pedido cancelado termina com [ApiErrorType.cancelled].
  ///
  /// [authToken] usa este Bearer no lugar do da sessão (ex.: `/users/me`
  /// logo após o login, antes de a sessão existir). O pedido não renova nem
  /// expira a sessão.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    CancelToken? cancelToken,
    String? authToken,
  }) {
    return _send(
      (options) => _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      requiresAuth: requiresAuth,
      authToken: authToken,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _send(
      (options) => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<Response> put(String path, {dynamic data, bool requiresAuth = true}) {
    return _send(
      (options) => _dio.put(path, data: data, options: options),
      requiresAuth: requiresAuth,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    bool requiresAuth = true,
  }) {
    return _send(
      (options) => _dio.patch(path, data: data, options: options),
      requiresAuth: requiresAuth,
    );
  }

  /// Envia o arquivo em [filePath] como `multipart/form-data`, no campo
  /// [fieldName] e com o tipo [contentType] (ex.: `image/jpeg`). O `FormData`
  /// é montado a cada tentativa, porque o Dio não reenvia o mesmo depois de
  /// uma renovação.
  Future<Response> postMultipart(
    String path, {
    required String fieldName,
    required String filePath,
    required String contentType,
    bool requiresAuth = true,
  }) {
    return _send(
      (options) async => _dio.post(
        path,
        data: FormData.fromMap({
          fieldName: await MultipartFile.fromFile(
            filePath,
            contentType: DioMediaType.parse(contentType),
          ),
        }),
        options: options.copyWith(
          contentType: Headers.multipartFormDataContentType,
        ),
      ),
      requiresAuth: requiresAuth,
    );
  }

  Future<Response> delete(String path, {bool requiresAuth = true}) {
    return _send(
      (options) => _dio.delete(path, options: options),
      requiresAuth: requiresAuth,
    );
  }

  // ---------------------------------------------------------------------------
  // Envio e tratamento centralizado de erros
  // ---------------------------------------------------------------------------

  /// Executa [call] com as [Options] montadas na hora (com o token atual da
  /// sessão), aplica a regra de renovação e converte qualquer falha em
  /// [ApiException]. Regras: specs/002-apiclient-renovacao-sessao/data-model.md.
  Future<Response> _send(
    Future<Response> Function(Options options) call, {
    required bool requiresAuth,
    String? authToken,
  }) async {
    try {
      return await _sendWithRenewal(
        call,
        requiresAuth: requiresAuth,
        authToken: authToken,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ApiException(
        type: ApiErrorType.unknown,
        message: 'Erro desconhecido: $e',
      );
    }
  }

  /// Envia; num 401 renovável, renova (ou aproveita uma renovação que já
  /// trocou o token) e repete **uma** vez. Lança [DioException] ou
  /// [ApiException].
  Future<Response> _sendWithRenewal(
    Future<Response> Function(Options options) call, {
    required bool requiresAuth,
    String? authToken,
  }) async {
    // Token da sessão que vai no header; null = pedido sem credencial da
    // sessão (visitante, login, authToken explícito), que nunca renova nem
    // mexe na sessão (FR-007).
    final sentToken = requiresAuth && authToken == null
        ? _session.accessToken
        : null;
    try {
      return await call(
        _makeOptions(requiresAuth: requiresAuth, authToken: authToken),
      );
    } on DioException catch (e) {
      if (sentToken == null) rethrow;
      _expireIfAccountGone(e);
      if (!_shouldRenew(e)) rethrow;
      // Token igual ao enviado: precisa renovar. Diferente: outra renovação
      // já trocou o token enquanto este pedido voava, basta repetir.
      if (_session.accessToken == sentToken && !await _renew()) rethrow;
    }

    try {
      return await call(_makeOptions(requiresAuth: requiresAuth));
    } on DioException catch (e) {
      // Recusado de novo logo após renovar: sem nova renovação (SC-004).
      if (e.response?.statusCode == 401) unawaited(_session.expire());
      _expireIfAccountGone(e);
      rethrow;
    }
  }

  /// Conta desativada (404 `USER_NOT_FOUND`) num pedido com token encerra a
  /// sessão como expirada, sem cada tela tratar o caso (FR-008a).
  void _expireIfAccountGone(DioException e) {
    if (e.response?.statusCode == 404 &&
        _errorCodeOf(e.response) == ApiErrorCodes.userNotFound) {
      unawaited(_session.expire());
    }
  }

  /// 401 com qualquer código, exceto senha errada (CB-013), que só é
  /// repassado a quem pediu.
  bool _shouldRenew(DioException e) =>
      e.response?.statusCode == 401 &&
      _errorCodeOf(e.response) != ApiErrorCodes.invalidCredentials;

  String? _errorCodeOf(Response? response) {
    final body = response?.data;
    final code = body is Map ? body['code'] : null;
    return code is String ? code : null;
  }

  Future<bool> _renew() =>
      _renewal ??= _refreshTokens().whenComplete(() => _renewal = null);

  /// `true` = novo par salvo; `false` = renovação recusada (sessão expirada)
  /// ou sem efeito (sessão mudou durante a renovação). Falha de rede ou do
  /// servidor sobe como [ApiException] e vira o erro do pedido original.
  Future<bool> _refreshTokens() async {
    final session = _session;
    final refreshToken = session.refreshToken;
    if (refreshToken == null) return false;

    final Response response;
    try {
      response = await _dio.post(
        refreshPath,
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await session.expire();
        return false;
      }
      throw _mapDioException(e);
    }

    final data = response.data;
    final newAccessToken = data is Map ? data['accessToken'] : null;
    final newRefreshToken = data is Map ? data['refreshToken'] : null;
    if (newAccessToken is! String ||
        newAccessToken.isEmpty ||
        newRefreshToken is! String ||
        newRefreshToken.isEmpty) {
      throw ApiException(
        type: ApiErrorType.invalidResponse,
        statusCode: response.statusCode,
        message: 'Resposta de renovação sem o par de tokens',
      );
    }

    return session.replaceTokens(
      previousRefreshToken: refreshToken,
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );
  }

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return ApiException(
          type: ApiErrorType.connection,
          message: 'Sem conexão: ${e.message}',
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          type: ApiErrorType.timeout,
          message: 'Tempo esgotado (${e.type.name})',
        );
      case DioExceptionType.cancel:
        return ApiException(
          type: ApiErrorType.cancelled,
          message: 'Requisição cancelada',
        );
      case DioExceptionType.badResponse:
        return _mapBadResponse(e.response);
      default:
        // badCertificate, unknown e tipos que versões novas do Dio adicionarem
        return ApiException(
          type: ApiErrorType.unknown,
          message: 'Erro inesperado: ${e.message}',
        );
    }
  }

  ApiException _mapBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    // O corpo pode não ser JSON (ex.: página HTML de um 502 do proxy).
    final body = response?.data;
    final json = body is Map ? body : const <String, dynamic>{};

    return ApiException(
      type: switch (statusCode) {
        401 => ApiErrorType.unauthorized,
        final code? when code >= 500 => ApiErrorType.server,
        final code? when code >= 400 => ApiErrorType.client,
        _ => ApiErrorType.unknown,
      },
      statusCode: statusCode,
      errorCode: _errorCodeOf(response),
      message: json['message']?.toString() ?? 'Erro HTTP $statusCode',
    );
  }
}
