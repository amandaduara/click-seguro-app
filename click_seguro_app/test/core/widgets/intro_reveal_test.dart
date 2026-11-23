import 'package:click_seguro_app/core/widgets/intro_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Interval interval = Interval(0.5, 1);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );

  testWidgets('sem IntroScope, mostra o filho como está', (tester) async {
    await pump(
      tester,
      const IntroReveal(interval: interval, child: Text('item')),
    );

    expect(find.byType(Opacity), findsNothing);
    expect(tester.getTopLeft(find.text('item')), Offset.zero);
  });

  testWidgets('antes do intervalo: invisível e 14 abaixo; no fim: no lugar', (
    tester,
  ) async {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    addTearDown(controller.dispose);
    Widget tree() => IntroScope(
      animation: controller,
      child: const IntroReveal(interval: interval, child: Text('item')),
    );

    await pump(tester, tree());
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(tester.getTopLeft(find.text('item')).dy, 14);

    controller.value = 1;
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(tester.getTopLeft(find.text('item')).dy, 0);
  });

  testWidgets('scaleFrom cresce até o tamanho certo', (tester) async {
    final AnimationController controller = AnimationController(
      vsync: const TestVSync(),
    );
    addTearDown(controller.dispose);

    await pump(
      tester,
      IntroScope(
        animation: controller,
        child: const IntroReveal(
          interval: interval,
          rise: 0,
          scaleFrom: 0.5,
          child: SizedBox.square(dimension: 100),
        ),
      ),
    );
    // O layout não muda; só a pintura cresce.
    expect(tester.getSize(find.byType(SizedBox)).width, 100);
    // A menor escala em x entre os Transform do IntroReveal (o da escala).
    double scale() => tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(IntroReveal),
            matching: find.byType(Transform),
          ),
        )
        .map((widget) => widget.transform.storage[0])
        .reduce((a, b) => a < b ? a : b);
    expect(scale(), closeTo(0.5, 1e-6));

    controller.value = 1;
    await tester.pump();
    expect(scale(), closeTo(1, 1e-6));
  });
}
