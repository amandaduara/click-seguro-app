import 'package:click_seguro_app/core/utils/motion_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rolar e trocar de página com duração zero pula direto; com duração,
/// anima (specs/022, revisão do PR #28).
void main() {
  Future<ScrollController> pumpList(WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          controller: controller,
          children: [for (int i = 0; i < 50; i++) SizedBox(height: 100)],
        ),
      ),
    );
    return controller;
  }

  Future<PageController> pumpPages(WidgetTester tester) async {
    final PageController controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PageView(
          controller: controller,
          children: const [Text('1'), Text('2'), Text('3')],
        ),
      ),
    );
    return controller;
  }

  testWidgets('rolagem com duração zero chega na hora', (tester) async {
    final ScrollController controller = await pumpList(tester);

    await controller.moveTo(500, duration: Duration.zero);

    expect(controller.offset, 500);
  });

  testWidgets('rolagem com duração anima até o destino', (tester) async {
    final ScrollController controller = await pumpList(tester);

    final Future<void> moving = controller.moveTo(
      500,
      duration: const Duration(milliseconds: 300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset, inExclusiveRange(0, 500));
    await tester.pumpAndSettle();
    await moving;
    expect(controller.offset, 500);
  });

  testWidgets('página com duração zero troca na hora', (tester) async {
    final PageController controller = await pumpPages(tester);

    await controller.moveToPage(2, duration: Duration.zero);
    await tester.pump();

    expect(controller.page, 2);
  });

  testWidgets('página com duração anima até a página', (tester) async {
    final PageController controller = await pumpPages(tester);

    final Future<void> moving = controller.moveToPage(
      1,
      duration: const Duration(milliseconds: 300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.page, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    await moving;
    expect(controller.page, 1);
  });
}
