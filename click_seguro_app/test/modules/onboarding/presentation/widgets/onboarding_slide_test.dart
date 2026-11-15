import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  /// Posição da ilustração no começo e no meio de uma subida (750 ms).
  Future<(Offset, Offset)> floatPositions(
    WidgetTester tester, {
    required bool reduced,
  }) async {
    await pumpLocalized(
      tester,
      settle: false,
      child: AppMotionScope(
        appReduceMotion: reduced,
        child: Scaffold(
          body: OnboardingSlide(content: OnboardingPageContent.pages.first),
        ),
      ),
    );
    final Finder illustration = find.byType(SafeIllustration);
    final Offset start = tester.getTopLeft(illustration);
    await tester.pump(const Duration(milliseconds: 750));
    final Offset middle = tester.getTopLeft(illustration);
    await tester.pumpAndSettle();
    return (start, middle);
  }

  testWidgets('a ilustração flutua com o movimento normal', (tester) async {
    final (Offset start, Offset middle) = await floatPositions(
      tester,
      reduced: false,
    );

    expect(middle.dy, lessThan(start.dy));
  });

  testWidgets('com reduzir animações, a ilustração fica parada (R12)', (
    tester,
  ) async {
    final (Offset start, Offset middle) = await floatPositions(
      tester,
      reduced: true,
    );

    expect(middle, start);
  });
}
