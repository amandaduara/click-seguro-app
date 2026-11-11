import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  final NewsActionTags tags = NewsActionsPreview.tagsFor('r1');

  Future<void> pump(
    WidgetTester tester, {
    bool reduceMotion = false,
    NewsActionTags? heroTags,
    VoidCallback? onShare,
  }) => pumpLocalized(
    tester,
    child: AppMotionScope(
      appReduceMotion: reduceMotion,
      child: Center(
        child: ReelActions(
          heroTags: heroTags,
          isLiked: false,
          likesText: '3',
          likeLabel: 'Curtir, 3 curtidas',
          onLike: () {},
          isSaved: false,
          saveLabel: 'Salvar',
          onSave: () {},
          onShare: onShare ?? () {},
        ),
      ),
    ),
  );

  testWidgets('só curtir, salvar e compartilhar, com 48 dp e rótulo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var shares = 0;
    await pump(tester, onShare: () => shares++);

    for (final key in [
      ReelActions.likeKey,
      ReelActions.saveKey,
      ReelActions.shareKey,
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(48), reason: '$key');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$key');
    }
    expect(find.bySemanticsLabel('Curtir, 3 curtidas'), findsOneWidget);
    expect(find.bySemanticsLabel('Salvar'), findsOneWidget);
    expect(find.bySemanticsLabel('Compartilhar'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNWidgets(3));

    await tester.tap(find.byKey(ReelActions.shareKey));
    expect(shares, 1);
    handle.dispose();
  });

  testWidgets('com as tags, cada botão é origem de um Hero', (tester) async {
    await pump(tester, heroTags: tags);

    for (final String tag in [tags.like, tags.save, tags.share]) {
      expect(
        find.byWidgetPredicate((w) => w is Hero && w.tag == tag),
        findsOneWidget,
        reason: tag,
      );
    }
  });

  testWidgets('movimento reduzido ou sem tags: sem Hero', (tester) async {
    await pump(tester, heroTags: tags, reduceMotion: true);
    expect(find.byType(Hero), findsNothing);

    await pump(tester);
    expect(find.byType(Hero), findsNothing);
  });
}
