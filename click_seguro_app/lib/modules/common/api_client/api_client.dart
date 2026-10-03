import 'dart:async';

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

  /// 401 — a sessão já foi encerrada pelo [ApiClient].
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

  /// Código de erro de negócio devolvido pela API no campo `error`
  /// (ex.: `INVALID_CREDENTIALS`).
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
  final Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ??
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
        LogInterceptor(
          // Headers fora do log: o Authorization carrega o token (FR-010).
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  // Gera as opções com o token de autenticação se necessário
  Options _makeOptions({bool requiresAuth = true}) {
    final headers = <String, dynamic>{};

    if (requiresAuth) {
      final token = GetIt.instance<UserSessionService>().token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return Options(headers: headers);
  }

  // ---------------------------------------------------------------------------
  // Métodos HTTP diretos
  // ---------------------------------------------------------------------------

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _safeRequest(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: _makeOptions(requiresAuth: requiresAuth),
      ),
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _safeRequest(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _makeOptions(requiresAuth: requiresAuth),
      ),
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    bool requiresAuth = true,
  }) {
    return _safeRequest(
      () => _dio.put(
        path,
        data: data,
        options: _makeOptions(requiresAuth: requiresAuth),
      ),
    );
  }

  Future<Response> delete(
    String path, {
    bool requiresAuth = true,
  }) {
    return _safeRequest(
      () => _dio.delete(
        path,
        options: _makeOptions(requiresAuth: requiresAuth),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interceptador e tratamento centralizado de erros
  // ---------------------------------------------------------------------------

  Future<Response> _safeRequest(Future<Response> Function() requestCall) async {
    try {
      return await requestCall();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ApiException(
        type: ApiErrorType.unknown,
        message: 'Erro desconhecido: $e',
      );
    }
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

    // Token expirado ou não autorizado (401) -> encerra a sessão como expirada.
    // Sem await: a memória muda na hora e a exceção segue para o repository.
    if (statusCode == 401) {
      unawaited(GetIt.instance<UserSessionService>().expire());
    }

    return ApiException(
      type: switch (statusCode) {
        401 => ApiErrorType.unauthorized,
        final code? when code >= 500 => ApiErrorType.server,
        final code? when code >= 400 => ApiErrorType.client,
        _ => ApiErrorType.unknown,
      },
      statusCode: statusCode,
      errorCode: json['error']?.toString(),
      message: json['message']?.toString() ?? 'Erro HTTP $statusCode',
    );
  }
}
