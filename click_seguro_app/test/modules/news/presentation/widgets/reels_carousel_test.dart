import 'package:click_seguro_app/modules/news/presentation/widgets/reels_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/hanging_http_client.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';

void main() {
  setUp(() => imageCache.clear());

  // Achado da T058 (specs/022 FR-019): pré-carregar só no toque não dava
  // tempo de baixar a imagem em tela cheia antes de os Reels chegarem.
  testWidgets('o cartão na tela já põe a imagem do Reel no cache', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;
    const String url = 'https://img.test/reel.png';

    await pumpLocalized(
      tester,
      settle: false,
      child: Scaffold(
        body: ReelsCarousel(
          reels: [newsItem('n1', imageUrl: url)],
          onOpen: (_) {},
        ),
      ),
    );
    await tester.pump();

    // A chave do `ReelView`: o maior lado da tela (780) em pixels.
    final Object key = await const ResizeImage(
      NetworkImage(url),
      width: 2340,
    ).obtainKey(ImageConfiguration.empty);
    expect(imageCache.statusForKey(key).tracked, isTrue);
    debugNetworkImageHttpClientProvider = null;
  });
}
