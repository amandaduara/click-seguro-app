import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/widgets.dart';

/// Rolar respeitando "Reduzir animações": com a duração zero de
/// `AppMotion.of(context)`, pula direto; senão, anima com a curva padrão
/// (specs/022 FR-010).
extension MotionScroll on ScrollController {
  Future<void> moveTo(double offset, {required Duration duration}) async {
    if (duration == Duration.zero) {
      jumpTo(offset);
      return;
    }
    await animateTo(offset, duration: duration, curve: AppMotion.standard);
  }
}

/// Trocar de página respeitando "Reduzir animações", como [MotionScroll].
extension MotionPages on PageController {
  Future<void> moveToPage(int page, {required Duration duration}) async {
    if (duration == Duration.zero) {
      jumpToPage(page);
      return;
    }
    await animateToPage(page, duration: duration, curve: AppMotion.standard);
  }
}
