import 'package:click_seguro_app/modules/common/config/environment_config.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Converte a [Response] bruta do Dio em um modelo tipado, evitando que
/// chamadores lidem com `dynamic`/`Map` fora da camada de dados.
extension ApiResponseMapper on Response {
  T toModel<T>(T Function(Map<String, dynamic> json) fromJson) {
    return fromJson(data as Map<String, dynamic>);
  }

  List<T> toModelList<T>(T Function(Map<String, dynamic> json) fromJson) {
    return (data as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
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
          requestHeader: true,
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
      // 1. Falha de conexão/internet
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw ApiException(
          message: 'Sem conexão com a internet. Verifique sua rede.',
          statusCode: 0,
        );
      }

      final statusCode = e.response?.statusCode ?? 0;
      final message = e.response?.data?['message'] ?? 'Erro inesperado na API.';

      // 2. Token expirado ou não autorizado (401) -> Desloga automaticamente
      if (statusCode == 401) {
        GetIt.instance<UserSessionService>().logout();
      }

      throw ApiException(message: message, statusCode: statusCode);
    } catch (e) {
      throw ApiException(message: 'Erro desconhecido: $e', statusCode: 0);
    }
  }
}