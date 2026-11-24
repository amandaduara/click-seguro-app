import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/extensions/achievement_presentation_extension.dart';
import 'package:click_seguro_app/modules/profile/presentation/extensions/count_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  AchievementEntity achievement(
    AchievementKind kind, {
    int current = 0,
    int target = 1,
    int? moduleOrder,
  }) => AchievementEntity(
    kind: kind,
    current: current,
    target: target,
    moduleTitle: kind == AchievementKind.module ? 'Golpes Digitais' : null,
    moduleOrder: moduleOrder,
  );

  /// Roda [body] com as traduções pt-BR carregadas.
  Future<void> withStrings(WidgetTester tester, void Function() body) async {
    await pumpLocalized(tester, child: const SizedBox());
    body();
  }

  testWidgets('título de cada tipo; o de módulo é o nome do módulo', (
    tester,
  ) async {
    await withStrings(tester, () {
      expect(
        {
          for (final kind in AchievementKind.values)
            kind: achievement(kind, moduleOrder: 1).title,
        },
        {
          AchievementKind.firstLesson: 'Primeira lição',
          AchievementKind.firstModule: 'Primeiro módulo',
          AchievementKind.dedicatedStudent: 'Estudante dedicado',
          AchievementKind.securityMaster: 'Mestre da segurança',
          AchievementKind.attentiveReader: 'Leitor atento',
          AchievementKind.dedicatedReader: 'Leitor dedicado',
          AchievementKind.module: 'Golpes Digitais',
        },
      );
    });
  });

  testWidgets('progresso em lições, módulos ou notícias', (tester) async {
    await withStrings(tester, () {
      expect(
        achievement(
          AchievementKind.dedicatedStudent,
          current: 8,
          target: 10,
        ).progressLabel,
        '8 de 10 lições',
      );
      expect(
        achievement(
          AchievementKind.module,
          current: 2,
          target: 3,
          moduleOrder: 1,
        ).progressLabel,
        '2 de 3 lições',
      );
      expect(
        achievement(
          AchievementKind.securityMaster,
          current: 1,
          target: 3,
        ).progressLabel,
        '1 de 3 módulos',
      );
      expect(
        achievement(
          AchievementKind.dedicatedReader,
          current: 4,
          target: 10,
        ).progressLabel,
        '4 de 10 notícias',
      );
    });
  });

  testWidgets('progresso não passa do alvo', (tester) async {
    await withStrings(tester, () {
      expect(
        achievement(AchievementKind.attentiveReader, current: 30).progressLabel,
        '1 de 1 notícias',
      );
    });
  });

  test('ícone por tipo, todos diferentes', () {
    final icons = {
      for (final kind in AchievementKind.values)
        achievement(kind, moduleOrder: 1).icon,
    };

    expect(icons, hasLength(AchievementKind.values.length));
    expect(
      achievement(AchievementKind.module, moduleOrder: 1).icon,
      LucideIcons.medal,
    );
  });

  test('cores fixas por tipo', () {
    const palette = AppPalette.light;

    expect(
      achievement(AchievementKind.firstLesson).medalColors(palette).$1,
      palette.primary,
    );
    expect(
      achievement(AchievementKind.securityMaster).medalColors(palette).$1,
      palette.secondary,
    );
  });

  test('as de módulo alternam entre primary, success, warning e secondary', () {
    const palette = AppPalette.light;

    expect(
      [
        for (final order in [1, 2, 3, 4, 5])
          achievement(
            AchievementKind.module,
            moduleOrder: order,
          ).medalColors(palette).$1,
      ],
      [
        palette.primary,
        palette.success,
        palette.warning,
        palette.secondary,
        palette.primary,
      ],
    );
  });

  test('as duas cores da medalha são diferentes (gradiente)', () {
    final (Color start, Color end) = achievement(
      AchievementKind.firstModule,
    ).medalColors(AppPalette.light);

    expect(start, isNot(end));
  });

  testWidgets('formatCount', (tester) async {
    await withStrings(tester, () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
      expect(formatCount(1000), '1 mil');
      expect(formatCount(1200), '1,2 mil');
    });
  });
}
