import 'dart:async';
import 'dart:io';

/// Cliente HTTP cujas requisições nunca terminam: com
/// `debugNetworkImageHttpClientProvider`, as imagens da rede ficam no
/// `imageCache` como pendentes, e o teste confere quais foram pedidas.
class HangingHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Completer<HttpClientRequest>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
