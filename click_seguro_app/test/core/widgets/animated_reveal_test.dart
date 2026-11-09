import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/animated_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ValueNotifier<Widget?> content;

  setUp(() => content = ValueNotifier<Widget?>(null));
  tearDown(() => content.dispose());

  Future<void> pump(WidgetTester tester, {bool reduce = false}) =>
      tester.pumpWidget(
        MaterialApp(
          home: AppMotionScope(
            appReduceMotion: reduce,
            child: Scaffold(
              body: Column(
                children: [
                  ValueListenableBuilder<Widget?>(
                    valueListenable: content,
                    builder: (_, child, _) => AnimatedReveal(child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  double height(WidgetTester tester) =>
      tester.getSize(find.byType(AnimatedReveal)).height;

  testWidgets('entra crescendo e sai encolhendo, com o último conteúdo', (
    tester,
  ) async {
    await pump(tester);
    expect(height(tester), 0);

    content.value = const SizedBox(height: 100, child: Text('Aviso'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(height(tester), inExclusiveRange(0, 100));
    await tester.pumpAndSettle();
    expect(height(tester), 100);

    content.value = null;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Aviso'), findsOneWidget, reason: 'saindo');
    await tester.pumpAndSettle();
    expect(find.text('Aviso'), findsNothing);
    expect(height(tester), 0);
  });

  testWidgets('um campo nunca fica duas vezes na tela ao alternar rápido', (
    tester,
  ) async {
    final FocusNode focus = FocusNode();
    addTearDown(focus.dispose);
    final Widget field = TextField(focusNode: focus);
    content.value = field;
    await pump(tester);

    content.value = null;
    await tester.pump(const Duration(milliseconds: 50));
    content.value = field;
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('com "Reduzir animações", aparece e some na hora', (
    tester,
  ) async {
    await pump(tester, reduce: true);

    content.value = const SizedBox(height: 40);
    await tester.pump();
    expect(height(tester), 40);

    content.value = null;
    await tester.pump();
    expect(height(tester), 0);
  });
}
