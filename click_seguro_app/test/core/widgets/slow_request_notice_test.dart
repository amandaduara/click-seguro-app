import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool active}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlowRequestNotice(active: active, message: 'Acordando'),
          ),
        ),
      );

  testWidgets('aparece só depois do atraso enquanto ativo', (tester) async {
    await pump(tester, active: true);
    expect(find.text('Acordando'), findsNothing);

    await tester.pump(SlowRequestNotice.delay - const Duration(seconds: 1));
    expect(find.text('Acordando'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Acordando'), findsOneWidget);
  });

  testWidgets('some quando deixa de estar ativo', (tester) async {
    await pump(tester, active: true);
    await tester.pump(SlowRequestNotice.delay);

    await pump(tester, active: false);

    expect(find.text('Acordando'), findsNothing);
  });

  testWidgets('inativo nunca aparece', (tester) async {
    await pump(tester, active: false);
    await tester.pump(SlowRequestNotice.delay * 2);

    expect(find.text('Acordando'), findsNothing);
  });

  testWidgets('o texto tem margem lateral (specs/022 T062)', (tester) async {
    await pump(tester, active: true);
    await tester.pump(SlowRequestNotice.delay);

    final double left = tester.getTopLeft(find.text('Acordando')).dx;
    final double right =
        tester.view.physicalSize.width / tester.view.devicePixelRatio -
        tester.getTopRight(find.text('Acordando')).dx;
    expect(left, greaterThanOrEqualTo(AppSpacing.s5));
    expect(right, greaterThanOrEqualTo(AppSpacing.s5));
  });
}
