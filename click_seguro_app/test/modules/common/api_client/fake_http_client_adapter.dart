import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adapter do Dio que não acessa a rede: devolve [body]/[statusCode]
/// configurados ou lança [error], e guarda a última requisição recebida.
class FakeHttpClientAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Object? body;
  DioException Function(RequestOptions options)? error;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (error != null) throw error!(options);

    final isJson = body is Map || body is List;
    return ResponseBody.fromString(
      isJson ? jsonEncode(body) : (body?.toString() ?? ''),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [
          isJson ? Headers.jsonContentType : 'text/html',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
