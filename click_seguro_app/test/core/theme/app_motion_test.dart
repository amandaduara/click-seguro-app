import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Durações e o sinal único de "reduzir animações" (R8 de
/// specs/022-redesign-visual).
void main() {
  test('durações do redesign', () {
    expect(AppMotion.fast, const Duration(milliseconds: 150));
    expect(AppMotion.standard, const Duration(milliseconds: 250));
    expect(AppMotion.emphasis, const Duration(milliseconds: 400));
    expect(AppMotion.celebration, const Duration(milliseconds: 1200));
  });

  Future<bool> readReduceMotion(
    WidgetTester tester, {
    required bool disable,
  }) async {
    late bool value;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disable),
        child: Builder(
          builder: (context) {
            value = context.reduceMotion;
            return const SizedBox();
          },
        ),
      ),
    );
    return value;
  }

  testWidgets('context.reduceMotion segue o MediaQuery', (tester) async {
    expect(await readReduceMotion(tester, disable: true), isTrue);
    expect(await readReduceMotion(tester, disable: false), isFalse);
  });

  test('duração efetiva: zero com reduzir animações', () {
    expect(AppMotion.duration(AppMotion.standard, reduce: true), Duration.zero);
    expect(
      AppMotion.duration(AppMotion.standard, reduce: false),
      AppMotion.standard,
    );
  });
}
