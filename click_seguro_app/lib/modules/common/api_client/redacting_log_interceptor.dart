import 'package:dio/dio.dart';

/// Log de debug do [Dio] sem segredos: nunca registra headers (o
/// `Authorization` carrega o token) e, nas rotas que começam com um item de
/// [sensitivePathPrefixes] (login, renovação, troca de senha), registra só
/// método, caminho e status, sem os corpos (FR-017).
class RedactingLogInterceptor extends LogInterceptor {
  RedactingLogInterceptor({required this.sensitivePathPrefixes, super.logPrint})
    : super(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      );

  final List<String> sensitivePathPrefixes;

  bool _isSensitive(RequestOptions options) =>
      sensitivePathPrefixes.any(options.path.startsWith);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isSensitive(options)) return super.onRequest(options, handler);
    logPrint(
      '*** Request *** ${options.method} ${options.path} [corpo omitido]',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (!_isSensitive(options)) return super.onResponse(response, handler);
    logPrint(
      '*** Response *** ${options.method} ${options.path} '
      '${response.statusCode} [corpo omitido]',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    if (!_isSensitive(options)) return super.onError(err, handler);
    logPrint(
      '*** DioException *** ${options.method} ${options.path} '
      '${err.response?.statusCode ?? err.type.name} [corpo omitido]',
    );
    handler.next(err);
  }
}
