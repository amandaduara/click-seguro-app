import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Resposta roteirizada pelo [FakeHttpClientAdapter.responder].
class FakeResponse {
  const FakeResponse(this.statusCode, [this.body, this.delay = Duration.zero]);

  final int statusCode;
  final Object? body;

  /// Atraso antes de responder. Um cancelamento durante o atraso vence.
  final Duration delay;
}

/// Adapter do Dio que não acessa a rede: devolve [body]/[statusCode]
/// configurados (ou o que o [responder] decidir) ou lança [error], e guarda
/// todas as requisições recebidas.
class FakeHttpClientAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Object? body;
  DioException Function(RequestOptions options)? error;

  /// Quando definido, tem precedência sobre [statusCode]/[body].
  FutureOr<FakeResponse> Function(RequestOptions options)? responder;

  final List<RequestOptions> requests = [];

  RequestOptions? get lastRequest => requests.isEmpty ? null : requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (error != null) throw error!(options);

    final response = responder != null
        ? await responder!(options)
        : FakeResponse(statusCode, body);

    if (response.delay > Duration.zero) {
      var cancelled = false;
      await Future.any([
        Future<void>.delayed(response.delay),
        if (cancelFuture != null) cancelFuture.then((_) => cancelled = true),
      ]);
      if (cancelled) {
        throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'cancelado',
        );
      }
    }

    final responseBody = response.body;
    final isJson = responseBody is Map || responseBody is List;
    return ResponseBody.fromString(
      isJson ? jsonEncode(responseBody) : (responseBody?.toString() ?? ''),
      response.statusCode,
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
