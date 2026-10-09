import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/feed_controller_factory.dart';

void main() {
  Future<void> localized(WidgetTester tester) =>
      pumpLocalized(tester, child: const SizedBox());

  group('formattedLikes', () {
    final cases = {0: '0', 999: '999', 1000: '1 mil', 1200: '1,2 mil'};
    cases.forEach((count, expected) {
      testWidgets('$count → $expected', (tester) async {
        await localized(tester);

        expect(newsDetail('n1', likesCount: count).formattedLikes, expected);
      });
    });
  });

  group('hasContent', () {
    test('texto com conteúdo', () {
      expect(newsDetail('n1', content: 'Texto').hasContent, isTrue);
    });

    test('vazio ou só com espaços → false', () {
      expect(newsDetail('n1', content: '').hasContent, isFalse);
      expect(newsDetail('n1', content: '  \n ').hasContent, isFalse);
    });
  });

  testWidgets('semanticLabel: título, fonte e data, nessa ordem', (
    tester,
  ) async {
    await localized(tester);

    final label = newsDetail('n1').semanticLabel(feedNow);

    expect(label, 'Notícia n1, Folha de Teste, 20 de set.');
  });

  group('spokenText', () {
    test('título, ponto e texto', () {
      expect(
        newsDetail('n1', content: 'Corpo').spokenText,
        'Notícia n1.\n\nCorpo',
      );
    });

    test('sem texto, só o título', () {
      expect(newsDetail('n1', content: ' ').spokenText, 'Notícia n1');
    });
  });

  testWidgets('rótulos de velocidade', (tester) async {
    await localized(tester);

    expect(readingSpeedName(ReadingSpeed.slow), 'lenta');
    expect(readingSpeedName(ReadingSpeed.normal), 'normal');
    expect(readingSpeedName(ReadingSpeed.fast), 'rápida');
    expect(speedSemanticLabel(ReadingSpeed.normal), 'Velocidade: normal');
  });
}
