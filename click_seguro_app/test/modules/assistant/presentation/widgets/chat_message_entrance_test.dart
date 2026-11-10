import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/chat_message_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mensagem nova do chat entra subindo e esmaecendo; com movimento reduzido
/// ou já na tela, aparece direto (specs/022 FR-026, FR-010).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool animate,
    bool reduce = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: AppMotionScope(
        appReduceMotion: reduce,
        child: Scaffold(
          body: ChatMessageEntrance(animate: animate, child: const Text('Oi')),
        ),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Oi'),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('nova: começa transparente e entra animada', (tester) async {
    await pump(tester, animate: true);

    expect(opacity(tester), lessThan(1));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets('com movimento reduzido: aparece direto', (tester) async {
    await pump(tester, animate: true, reduce: true);
    await tester.pump();

    expect(opacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a que já estava na tela não anima', (tester) async {
    await pump(tester, animate: false);

    expect(opacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
