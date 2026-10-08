import 'package:click_seguro_app/modules/news/presentation/extensions/reel_presentation_extension.dart';
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

        expect(reel('r1', likesCount: count).formattedLikes, expected);
      });
    });
  });

  testWidgets('semanticLabel: título, fonte e data', (tester) async {
    await localized(tester);

    final label = reel('r1').semanticLabel(feedNow);

    expect(label, contains('Notícia r1'));
    expect(label, contains('Folha de Teste'));
    expect(label, contains('20 de set.'));
  });

  testWidgets('rótulos de curtir e salvar com o estado', (tester) async {
    await localized(tester);

    expect(reel('r1', likesCount: 3).likeSemanticLabel, 'Curtir, 3 curtidas');
    expect(
      reel('r1', likesCount: 4, isLiked: true).likeSemanticLabel,
      'Curtido, 4 curtidas',
    );
    expect(saveSemanticLabel(isSaved: false), 'Salvar');
    expect(saveSemanticLabel(isSaved: true), 'Salvo');
  });
}
