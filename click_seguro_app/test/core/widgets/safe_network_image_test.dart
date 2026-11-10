import 'dart:async';
import 'dart:ui' as ui;

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

const String _url = 'https://img.test/a.jpg';
const Key _placeholderKey = Key('placeholder');

/// Põe uma imagem no cache com a mesma chave que o widget pede (decodificada
/// com [decodeWidth]), pronta na hora ou quando [ready] completar.
Future<void> _cacheImage(
  WidgetTester tester, {
  required int decodeWidth,
  Completer<ImageInfo>? ready,
}) async {
  final ui.Image image =
      await tester.runAsync(() => createTestImage()) as ui.Image;
  final ImageProvider<Object> provider = ResizeImage(
    const NetworkImage(_url),
    width: decodeWidth,
  );
  final Object key = await provider.obtainKey(ImageConfiguration.empty);
  imageCache.putIfAbsent(
    key,
    () => OneFrameImageStreamCompleter(
      ready?.future ?? SynchronousFuture(ImageInfo(image: image)),
    ),
  );
}

void main() {
  setUp(() => imageCache.clear());

  Future<void> pump(WidgetTester tester, {String? url = _url}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      settle: false,
      child: Center(
        child: SafeNetworkImage(
          url: url,
          width: 100,
          height: 60,
          placeholder: const SizedBox(key: _placeholderKey),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sem endereço: só o placeholder, sem imagem', (tester) async {
    await pump(tester, url: null);

    expect(find.byKey(_placeholderKey), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('falha ao carregar: placeholder', (tester) async {
    await pump(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.byKey(_placeholderKey), findsOneWidget);
  });

  testWidgets('já no cache: aparece sem esmaecer', (tester) async {
    await _cacheImage(tester, decodeWidth: 100);

    await pump(tester);

    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    expect(find.byKey(_placeholderKey), findsNothing);
  });

  testWidgets('precache usa a mesma chave que o widget vai pedir', (
    tester,
  ) async {
    await pump(tester, url: null);
    final BuildContext context = tester.element(find.byKey(_placeholderKey));

    unawaited(SafeNetworkImage.precache(context, _url, width: 100, height: 60));
    final Object key = await const ResizeImage(
      NetworkImage(_url),
      width: 100,
    ).obtainKey(ImageConfiguration.empty);

    expect(imageCache.statusForKey(key).tracked, isTrue);
  });

  testWidgets('carregando: placeholder e, ao chegar, a imagem esmaece', (
    tester,
  ) async {
    final Completer<ImageInfo> ready = Completer<ImageInfo>();
    await _cacheImage(tester, decodeWidth: 100, ready: ready);

    await pump(tester);

    expect(find.byKey(_placeholderKey), findsOneWidget);
    final ui.Image image =
        await tester.runAsync(() => createTestImage()) as ui.Image;
    ready.complete(ImageInfo(image: image));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Opacity fade() => tester.widget(find.byType(Opacity));
    expect(fade().opacity, inExclusiveRange(0, 1));
    expect(find.byKey(_placeholderKey), findsNothing);
    await tester.pump(AppMotion.normal.medium);
    expect(fade().opacity, 1);
  });
}
