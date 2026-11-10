import 'package:animations/animations.dart';
import 'package:click_seguro_app/core/routing/tab_branch_container.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aba de teste: guarda um contador no estado e registra se os tickers dela
/// estão ligados.
class _Tab extends StatefulWidget {
  const _Tab(this.label);

  final String label;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${widget.label}: $taps'),
        Text('${widget.label} ticker ${TickerMode.valuesOf(context).enabled}'),
        TextButton(
          onPressed: () => setState(() => taps++),
          child: Text('+ ${widget.label}'),
        ),
      ],
    ),
  );
}

void main() {
  Future<void> pumpTabs(
    WidgetTester tester,
    int index, {
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: AppMotionScope(
        appReduceMotion: reduceMotion,
        child: TabBranchContainer(
          currentIndex: index,
          children: const [_Tab('A'), _Tab('B')],
        ),
      ),
    ),
  );

  double opacityOf(WidgetTester tester, String text) {
    final Finder fade = find.ancestor(
      of: find.text(text, skipOffstage: false),
      matching: find.byType(FadeThroughTransition),
    );
    final Finder opacity = find.descendant(
      of: fade.first,
      matching: find.byType(FadeTransition),
    );
    return tester.widget<FadeTransition>(opacity.first).opacity.value;
  }

  testWidgets('só a aba ativa aparece e tem os tickers ligados', (
    tester,
  ) async {
    await pumpTabs(tester, 0);

    expect(find.text('A: 0'), findsOneWidget);
    expect(find.text('B: 0'), findsNothing);
    expect(find.text('A ticker true'), findsOneWidget);
    expect(find.text('B ticker false', skipOffstage: false), findsOneWidget);
  });

  testWidgets('trocar de aba preserva o estado das outras', (tester) async {
    await pumpTabs(tester, 0);
    await tester.tap(find.text('+ A'));
    await tester.pump();

    await pumpTabs(tester, 1);
    await tester.pumpAndSettle();
    expect(find.text('B: 0'), findsOneWidget);
    expect(find.text('B ticker true'), findsOneWidget);
    expect(find.text('A ticker false', skipOffstage: false), findsOneWidget);

    await pumpTabs(tester, 0);
    await tester.pumpAndSettle();
    expect(find.text('A: 1'), findsOneWidget);
  });

  testWidgets('a aba que entra esmaece em AppMotion.medium', (tester) async {
    await pumpTabs(tester, 0);

    await pumpTabs(tester, 1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacityOf(tester, 'B: 0'), lessThan(1));

    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, 'B: 0'), 1);
  });

  testWidgets('com movimento reduzido a troca é imediata', (tester) async {
    await pumpTabs(tester, 0, reduceMotion: true);

    await pumpTabs(tester, 1, reduceMotion: true);
    await tester.pump();

    expect(opacityOf(tester, 'B: 0'), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
