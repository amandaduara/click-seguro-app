import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/module_status_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  testWidgets('rótulos em português', (tester) async {
    await pumpLocalized(tester, child: const SizedBox());

    expect(
      [for (final status in ModuleStatus.values) status.label],
      ['Não iniciado', 'Em andamento', 'Concluído', 'Indisponível'],
    );
  });

  testWidgets('rótulos em inglês', (tester) async {
    await pumpLocalized(
      tester,
      child: const SizedBox(),
      locale: const Locale('en', 'US'),
    );

    expect(
      [for (final status in ModuleStatus.values) status.label],
      ['Not started', 'In progress', 'Completed', 'Unavailable'],
    );
  });

  test('tom do selo e ícone', () {
    expect(
      [for (final status in ModuleStatus.values) status.badgeTone],
      [
        SafeBadgeTone.neutral,
        SafeBadgeTone.primary,
        SafeBadgeTone.success,
        SafeBadgeTone.neutral,
      ],
    );
    expect(
      [for (final status in ModuleStatus.values) status.icon],
      [
        LucideIcons.circle,
        LucideIcons.circleDashed,
        LucideIcons.circleCheck,
        LucideIcons.lock,
      ],
    );
  });
}
