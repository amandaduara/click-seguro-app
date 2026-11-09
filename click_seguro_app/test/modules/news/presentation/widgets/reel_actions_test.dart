import 'package:click_seguro_app/modules/news/presentation/widgets/reel_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  Future<void> pump(WidgetTester tester) => pumpLocalized(
    tester,
    child: Center(
      child: ReelActions(
        onPrevious: null,
        onNext: () {},
        isLiked: false,
        likesText: '3',
        likeLabel: 'Curtir',
        onLike: () {},
        isSaved: false,
        saveLabel: 'Salvar',
        onSave: () {},
        onOpenSource: null,
      ),
    ),
  );

  Finder blurIn(Key key) => find.descendant(
    of: find.byKey(key),
    matching: find.byType(BackdropFilter),
  );

  // specs/022 T047: desabilitado é cor com alfa, sem desfoque nem camada de
  // opacidade (as duas pesam por cima da imagem).
  testWidgets('desabilitado sem desfoque e sem Opacity; habilitado com '
      'desfoque', (tester) async {
    await pump(tester);

    expect(blurIn(ReelActions.previousKey), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(ReelActions.previousKey),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(blurIn(ReelActions.nextKey), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(ReelActions.previousKey)),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
  });

  testWidgets('desabilitado mais apagado que o habilitado', (tester) async {
    await pump(tester);

    Color iconColor(Key key) => tester
        .widget<Icon>(
          find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
        )
        .color!;

    expect(
      iconColor(ReelActions.previousKey).a,
      lessThan(iconColor(ReelActions.nextKey).a),
    );
  });
}
