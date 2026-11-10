import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/safe_state_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Troca animada entre carregando, conteúdo, vazio e erro (specs/022 R8).
void main() {
  Future<void> pumpState(
    WidgetTester tester,
    String state, {
    bool reduce = false,
    String? text,
  }) => tester.pumpWidget(
    MaterialApp(
      home: AppMotionScope(
        appReduceMotion: reduce,
        child: Scaffold(
          body: SafeStateSwitcher(stateKey: state, child: Text(text ?? state)),
        ),
      ),
    ),
  );

  testWidgets('a troca de estado esmaece em AppMotion.medium', (tester) async {
    await pumpState(tester, 'carregando');

    await pumpState(tester, 'conteúdo');
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('carregando'), findsOneWidget);
    expect(find.text('conteúdo'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('carregando'), findsNothing);
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('a mesma chave não anima', (tester) async {
    await pumpState(tester, 'conteúdo');
    await pumpState(tester, 'conteúdo', text: 'novo');
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('conteúdo'), findsNothing);
    expect(find.text('novo'), findsOneWidget);
  });

  testWidgets('o novo estado fica no topo, não centralizado', (tester) async {
    await pumpState(tester, 'conteúdo');

    expect(tester.getTopLeft(find.text('conteúdo')).dy, 0);
  });

  testWidgets('com movimento reduzido a troca é imediata', (tester) async {
    await pumpState(tester, 'carregando', reduce: true);

    await pumpState(tester, 'conteúdo', reduce: true);
    await tester.pump();

    expect(find.text('carregando'), findsNothing);
    expect(find.text('conteúdo'), findsOneWidget);
  });
}
