import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../helpers/localized_app.dart';

/// Capa da notícia: sem imagem, a ilustração do tema; carregando, só o
/// cinza do esqueleto (validação da usuária, specs/023).
void main() {
  Widget cover() =>
      const NewsCover(imageUrl: null, themeText: 'Golpe do Pix', height: 150);

  testWidgets('sem imagem, mostra a ilustração do tema', (tester) async {
    await pumpLocalized(tester, child: Scaffold(body: cover()));

    expect(find.byType(SafeIllustration), findsOneWidget);
  });

  testWidgets('no esqueleto, a ilustração vira um bloco cinza', (tester) async {
    await pumpLocalized(
      tester,
      settle: false,
      child: Scaffold(body: SafeSkeleton(enabled: true, child: cover())),
    );

    // Marcada como folha: o esqueleto desenha um bloco no lugar dela.
    expect(
      find.ancestor(
        of: find.byType(SafeIllustration),
        matching: find.byWidgetPredicate((w) => w is Skeleton),
      ),
      findsOneWidget,
    );
  });
}
