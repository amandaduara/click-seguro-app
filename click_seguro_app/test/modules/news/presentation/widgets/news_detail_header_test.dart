import 'dart:ui' as ui;

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
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

  /// A miniatura do cartão compacto já no cache, como depois do feed.
  Future<void> cacheThumbnail(WidgetTester tester) async {
    final ui.Image image =
        await tester.runAsync(() => createTestImage()) as ui.Image;
    final int width = (NewsCard.compactImageSize * 3).round();
    final Object key = await ResizeImage(
      const NetworkImage(_url),
      width: width,
    ).obtainKey(ImageConfiguration.empty);
    imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: image)),
      ),
    );
  }

  Finder imageWithDecodeWidth(int width) => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is ResizeImage &&
        (w.image as ResizeImage).width == width,
  );

  // Achado da T058 (specs/022 FR-017): vindo de um cartão compacto, a
  // imagem grande ainda não está no cache; a do cartão aparece no lugar.
  testWidgets('aberto por um cartão: a miniatura cobre a espera da imagem', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;
    await cacheThumbnail(tester);

    await pumpHeader(tester);
    await tester.pump();

    final int thumbnail = (NewsCard.compactImageSize * 3).round();
    expect(imageWithDecodeWidth(thumbnail), findsOneWidget);
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets('sem cartão de origem, nada de miniatura', (tester) async {
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;

    await pumpHeader(tester, heroTag: null);
    await tester.pump();

    final int thumbnail = (NewsCard.compactImageSize * 3).round();
    expect(imageWithDecodeWidth(thumbnail), findsNothing);
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
