import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta [AppMotionScope] e devolve o [AppMotion] lido abaixo dele.
Future<AppMotion> _motionUnder(
  WidgetTester tester, {
  required bool appReduceMotion,
  bool disableAnimations = false,
}) async {
  late AppMotion motion;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: AppMotionScope(
        appReduceMotion: appReduceMotion,
        child: Builder(
          builder: (context) {
            motion = AppMotion.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return motion;
}

void main() {
  testWidgets('com animações, usa as durações do design system', (
    tester,
  ) async {
    final motion = await _motionUnder(tester, appReduceMotion: false);

    expect(motion.reduced, isFalse);
    expect(motion.short, const Duration(milliseconds: 150));
    expect(motion.medium, const Duration(milliseconds: 250));
    expect(motion.long, const Duration(milliseconds: 350));
  });

  testWidgets('"Reduzir animações" do app zera as durações', (tester) async {
    final motion = await _motionUnder(tester, appReduceMotion: true);

    expect(motion.reduced, isTrue);
    expect(motion.short, Duration.zero);
    expect(motion.medium, Duration.zero);
    expect(motion.long, Duration.zero);
  });

  testWidgets('"remover animações" do sistema também zera', (tester) async {
    final motion = await _motionUnder(
      tester,
      appReduceMotion: false,
      disableAnimations: true,
    );

    expect(motion.reduced, isTrue);
    expect(motion.medium, Duration.zero);
  });

  testWidgets('sem escopo, segue a opção do sistema', (tester) async {
    late AppMotion motion;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            motion = AppMotion.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(motion.reduced, isTrue);
  });
}
