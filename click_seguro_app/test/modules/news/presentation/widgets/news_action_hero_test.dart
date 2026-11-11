import 'package:click_seguro_app/modules/news/presentation/widgets/news_action_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O botão redondo do Reel voa até o curtir do detalhe, que é uma pílula
/// mais larga com o número: no voo nada pode estourar (erro visto no
/// aparelho, specs/023).
void main() {
  const String tag = 'reel-like-n1';

  Widget round() =>
      const SizedBox.square(dimension: 48, child: Icon(Icons.favorite_border));

  // Pílula sem encolher: num quadro de 48, a linha estoura.
  Widget pill() => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.favorite),
      SizedBox(width: 8),
      Text('1.234 curtidas'),
    ],
  );

  testWidgets('ida e volta sem estouro, cruzando os dois botões', (
    tester,
  ) async {
    final GlobalKey<NavigatorState> navigator = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: NewsActionHero(tag: tag, child: round()),
          ),
        ),
      ),
    );

    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: NewsActionHero(tag: tag, child: pill()),
          ),
        ),
      ),
    );
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(find.text('1.234 curtidas'), findsOneWidget);

    navigator.currentState!.pop();
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('sem tag, é só o botão', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: NewsActionHero(tag: null, child: round())),
    );

    expect(find.byType(Hero), findsNothing);
  });
}
