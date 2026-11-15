import 'package:click_seguro_app/modules/news/presentation/widgets/feed_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  late List<String> changes;
  late int clears;

  Future<void> pumpField(WidgetTester tester) {
    changes = [];
    clears = 0;
    return pumpLocalized(
      tester,
      child: Scaffold(
        body: FeedSearchField(
          onChanged: changes.add,
          onCleared: () => clears++,
        ),
      ),
    );
  }

  testWidgets('mostra a dica e avisa o texto digitado', (tester) async {
    await pumpField(tester);

    expect(find.text('Buscar notícia ou tipo de golpe'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pix');

    expect(changes, ['pix']);
  });

  testWidgets('o "X" só aparece com texto e limpa o campo', (tester) async {
    await pumpField(tester);
    expect(find.byTooltip('Limpar busca'), findsNothing);

    await tester.enterText(find.byType(TextField), 'pix');
    await tester.pump();
    final clear = find.byTooltip('Limpar busca');
    expect(clear, findsOneWidget);
    final size = tester.getSize(clear);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(clear);
    await tester.pump();

    expect(clears, 1);
    expect(find.text('pix'), findsNothing);
  });

  // Validação da usuária (specs/024): espaço em branco não é busca; o
  // campo avisa num toast curto.
  group('busca inválida', () {
    testWidgets('só espaços: o campo fica vazio e avisa', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(changes, isEmpty);
      expect(
        find.text('Digite pelo menos 2 letras para buscar.'),
        findsOneWidget,
      );
    });

    testWidgets('espaço no começo sai; o resto fica', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), '  pix');

      expect(changes, ['pix']);
    });

    testWidgets('buscar com uma letra só avisa', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'p');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(
        find.text('Digite pelo menos 2 letras para buscar.'),
        findsOneWidget,
      );
    });

    testWidgets('buscar com texto válido não avisa', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), 'pix');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('o aviso some sozinho', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), ' ');
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
