import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/modules/notifications/presentation/widgets/alerts_notices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  const String noticeText = 'Os alertas novos estão desligados.';
  final Finder action = find.text('Ligar nas Configurações');

  Future<void> pumpNotices(
    WidgetTester tester, {
    bool showOffline = false,
    bool showDisabled = true,
    VoidCallback? onOpenSettings,
    ThemeData? theme,
  }) => pumpLocalized(
    tester,
    theme: theme,
    child: Scaffold(
      body: AlertsNotices(
        showOffline: showOffline,
        showDisabled: showDisabled,
        onOpenSettings: onOpenSettings ?? () {},
      ),
    ),
  );

  /// A caixa do cartão em volta do aviso.
  Finder card() => find
      .ancestor(of: find.text(noticeText), matching: find.byType(Container))
      .last;

  testWidgets('desligado: cartão do app com margem lateral, não faixa', (
    tester,
  ) async {
    await pumpNotices(tester);

    final BuildContext context = tester.element(find.text(noticeText));
    final Container box = tester.widget<Container>(card());
    expect(box.decoration, SafeCard.decoration(context.colors));
    final Rect rect = tester.getRect(card());
    final double width = tester.getSize(find.byType(Scaffold)).width;
    expect(rect.left, AppSpacing.s5);
    expect(width - rect.right, AppSpacing.s5);
  });

  testWidgets('sino cortado num círculo suave na cor de atenção', (
    tester,
  ) async {
    await pumpNotices(tester);

    final AppPalette colors = tester.element(find.text(noticeText)).colors;
    final Icon icon = tester.widget<Icon>(find.byIcon(LucideIcons.bellOff));
    expect(icon.color, colors.warning);
    final Container circle = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(LucideIcons.bellOff),
            matching: find.byType(Container),
          )
          .first,
    );
    final BoxDecoration decoration = circle.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, colors.warningSoft);
    // O ícone vem antes do texto, na mesma linha.
    expect(
      tester.getCenter(find.byIcon(LucideIcons.bellOff)).dx,
      lessThan(tester.getTopLeft(find.text(noticeText)).dx),
    );
  });

  testWidgets('botão principal (não cinza), ≥ 48 dp, abre as Configurações', (
    tester,
  ) async {
    int opened = 0;
    await pumpNotices(tester, onOpenSettings: () => opened++);

    final Finder button = find.ancestor(
      of: action,
      matching: find.byType(SafeButton),
    );
    expect(tester.widget<SafeButton>(button).tone, SafeButtonTone.primary);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(
      tester.getTopLeft(button).dy,
      greaterThan(tester.getBottomLeft(find.text(noticeText)).dy),
    );

    await tester.tap(action);
    expect(opened, 1);
  });

  testWidgets('o aviso é anunciado (liveRegion)', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpNotices(tester);

    final Finder live = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && (widget.properties.liveRegion ?? false),
    );
    expect(
      find.descendant(of: live, matching: find.text(noticeText)),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('alto contraste: círculo com contorno, texto na cor forte', (
    tester,
  ) async {
    await pumpNotices(tester, theme: AppTheme.highContrastTheme);

    final AppPalette colors = tester.element(find.text(noticeText)).colors;
    expect(colors, AppPalette.highContrast);
    final Container circle = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(LucideIcons.bellOff),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((circle.decoration! as BoxDecoration).border, isNotNull);
    expect(
      tester.widget<Text>(find.text(noticeText)).style!.color,
      colors.textForeground,
    );
  });

  testWidgets('sem internet e desligado: a faixa de offline e o cartão', (
    tester,
  ) async {
    await pumpNotices(tester, showOffline: true);

    expect(find.byType(SafeOfflineBanner), findsOneWidget);
    expect(find.text(noticeText), findsOneWidget);
  });

  testWidgets('nada a avisar: não ocupa espaço', (tester) async {
    await pumpNotices(tester, showDisabled: false);

    expect(find.text(noticeText), findsNothing);
    expect(find.byType(SafeOfflineBanner), findsNothing);
  });
}
