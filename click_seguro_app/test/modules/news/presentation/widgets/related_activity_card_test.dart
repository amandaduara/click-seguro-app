import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/related_activity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  const module = SuggestedModuleEntity(
    id: 'm1',
    title: 'Golpes no WhatsApp',
    description: 'Aprenda a reconhecer golpes.',
    lessonsCount: 3,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    SuggestedModuleEntity entity = module,
    Future<void> Function()? onTap,
  }) => pumpLocalized(
    tester,
    child: Scaffold(
      body: SingleChildScrollView(
        child: RelatedActivityCard(module: entity, onTap: onTap ?? () async {}),
      ),
    ),
  );

  testWidgets('título do bloco, módulo, descrição e "3 perguntas"', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Pratique o que aprendeu'), findsOneWidget);
    expect(find.text('Golpes no WhatsApp'), findsOneWidget);
    expect(find.text('Aprenda a reconhecer golpes.'), findsOneWidget);
    expect(find.text('3 perguntas'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('descrição vazia não deixa buraco', (tester) async {
    await pumpCard(
      tester,
      entity: const SuggestedModuleEntity(
        id: 'm1',
        title: 'Golpes no WhatsApp',
        description: '  ',
        lessonsCount: 1,
      ),
    );

    expect(find.text('Golpes no WhatsApp'), findsOneWidget);
    expect(find.text('1 perguntas'), findsOneWidget);
    expect(find.byKey(RelatedActivityCard.descriptionKey), findsNothing);
  });

  testWidgets('toque duplo chama uma vez só até terminar', (tester) async {
    var calls = 0;
    final gate = Future<void>.delayed(const Duration(seconds: 1));
    await pumpCard(
      tester,
      onTap: () {
        calls++;
        return gate;
      },
    );

    await tester.tap(find.byKey(RelatedActivityCard.cardKey));
    await tester.tap(find.byKey(RelatedActivityCard.cardKey));
    await tester.pump(const Duration(seconds: 2));

    expect(calls, 1);

    await tester.tap(find.byKey(RelatedActivityCard.cardKey));
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('rótulo de acessibilidade e área de 48 dp', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCard(tester);

    expect(
      find.bySemanticsLabel(
        'Pratique o que aprendeu, Golpes no WhatsApp, '
        'Aprenda a reconhecer golpes., 3 perguntas',
      ),
      findsOneWidget,
    );
    final size = tester.getSize(find.byKey(RelatedActivityCard.cardKey));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  testWidgets('fonte em 200% não estoura', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpCard(tester);

    expect(tester.takeException(), isNull);
  });
}
