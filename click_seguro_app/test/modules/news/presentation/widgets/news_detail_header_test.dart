import 'dart:ui' as ui;

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/hanging_http_client.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';

const String _url = 'https://img.test/n.jpg';
const String _tag = 'news-image-recent-n1';

void main() {
  setUp(() => imageCache.clear());

  Future<void> pumpHeader(
    WidgetTester tester, {
    String? heroTag = _tag,
    bool reduceMotion = false,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      settle: false,
      child: AppMotionScope(
        appReduceMotion: reduceMotion,
        child: Scaffold(
          body: ListView(
            children: [
              NewsDetailHeader(
                news: newsItem('n1', imageUrl: _url),
                now: DateTime(2026, 9, 21),
                heroTag: heroTag,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A capa do cartão já no cache, como depois do feed: decodificada pela
  /// largura da tela (360 dp × 3), a mesma chave que o detalhe pede.
  Future<void> cacheCardCover(WidgetTester tester) async {
    final ui.Image image =
        await tester.runAsync(() => createTestImage()) as ui.Image;
    final Object key = await const ResizeImage(
      NetworkImage(_url),
      width: 1080,
    ).obtainKey(ImageConfiguration.empty);
    imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: image)),
      ),
    );
  }

  Finder paintedImage() =>
      find.byWidgetPredicate((w) => w is RawImage && w.image != null);

  // specs/022 FR-017: o detalhe mostra na hora a imagem que o cartão já
  // tinha. A capa do redesign pede a mesma chave de cache do cartão.
  testWidgets('aberto por um cartão: a capa já aparece pronta', (tester) async {
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;
    await cacheCardCover(tester);

    await pumpHeader(tester);
    await tester.pump();

    expect(paintedImage(), findsOneWidget);
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets('sem a imagem no cache, a ilustração cobre a espera', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;

    await pumpHeader(tester, heroTag: null);
    await tester.pump();

    expect(paintedImage(), findsNothing);
    expect(find.byType(SafeIllustration), findsOneWidget);
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets('a imagem voa com o Hero do cartão', (tester) async {
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;

    await pumpHeader(tester);

    expect(
      find.byWidgetPredicate((w) => w is Hero && w.tag == _tag),
      findsOneWidget,
    );
    debugNetworkImageHttpClientProvider = null;
  });

  // specs/022 FR-010: com "Reduzir animações", a imagem não voa.
  testWidgets('movimento reduzido: sem Hero', (tester) async {
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;

    await pumpHeader(tester, reduceMotion: true);

    expect(find.byType(Hero), findsNothing);
    debugNetworkImageHttpClientProvider = null;
  });
}
