import 'dart:async';

import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/feed_controller_factory.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    NewsItemEntity item, {
    bool compact = true,
    Future<void> Function()? onTap,
  }) => pumpLocalized(
    tester,
    child: Scaffold(
      body: ListView(
        children: [
          NewsCard(
            item: item,
            compact: compact,
            now: feedNow,
            onTap: onTap ?? () async {},
          ),
        ],
      ),
    ),
  );

  NewsCategoryEntity category(String name) =>
      NewsCategoryEntity(id: name, name: name, slug: name);

  testWidgets('compacto: título, fonte, data e categorias', (tester) async {
    await pumpCard(
      tester,
      newsItem(
        'n1',
        originalPublishedAt: DateTime(2026, 10, 3),
        categories: [
          category('Phishing'),
          category('Pix'),
          category('WhatsApp'),
        ],
      ),
    );

    expect(find.text('Notícia n1'), findsOneWidget);
    expect(find.textContaining('Folha de Teste'), findsOneWidget);
    expect(find.textContaining('Há 2 dias'), findsOneWidget);
    expect(find.text('Phishing'), findsOneWidget);
    expect(find.text('Pix'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNothing);
  });

  testWidgets('sem categoria, sem rótulo', (tester) async {
    await pumpCard(tester, newsItem('n1', categories: const []));

    expect(find.text('Phishing'), findsNothing);
  });

  testWidgets('sem imagem mostra o quadro neutro', (tester) async {
    await pumpCard(tester, newsItem('n1'));

    expect(find.byKey(NewsCard.imagePlaceholderKey), findsOneWidget);
  });

  testWidgets('lida e salva aparecem só quando verdadeiras', (tester) async {
    await pumpCard(
      tester,
      newsItem(
        'n1',
        interaction: const NewsInteraction(isRead: true, isSaved: true),
      ),
    );
    expect(find.byTooltip('Lida'), findsOneWidget);
    expect(find.byTooltip('Salva'), findsOneWidget);

    await pumpCard(tester, newsItem('n2'));
    expect(find.byTooltip('Lida'), findsNothing);
    expect(find.byTooltip('Salva'), findsNothing);
  });

  testWidgets('completo mostra a imagem grande', (tester) async {
    await pumpCard(tester, newsItem('n1'), compact: false);

    final placeholder = tester.getSize(
      find.byKey(NewsCard.imagePlaceholderKey),
    );
    expect(placeholder.height, 176);
  });

  testWidgets('dois toques rápidos abrem uma vez', (tester) async {
    var taps = 0;
    final pending = Completer<void>();
    await pumpCard(
      tester,
      newsItem('n1'),
      onTap: () {
        taps++;
        return pending.future;
      },
    );

    await tester.tap(find.byType(NewsCard));
    await tester.tap(find.byType(NewsCard));
    await tester.pump();

    expect(taps, 1);
    pending.complete();
  });

  testWidgets('rótulo acessível e área de toque', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(
      tester,
      newsItem('n1', originalPublishedAt: DateTime(2026, 10, 5)),
    );

    expect(
      find.bySemanticsLabel('Notícia n1, Folha de Teste, Hoje, Phishing'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(NewsCard)).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  testWidgets('fonte em 200% não estoura', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpCard(tester, newsItem('n1'));
    await pumpCard(tester, newsItem('n2'), compact: false);

    expect(tester.takeException(), isNull);
  });
}
