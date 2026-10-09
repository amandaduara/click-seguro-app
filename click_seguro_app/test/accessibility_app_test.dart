import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/main.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema e tamanho da letra do app inteiro conforme as preferências de
/// acessibilidade (US1, US3, FR-003 a FR-006).
void main() {
  late AccessibilityPreferencesNotifier notifier;
  late BuildContext screen;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableBuildModes = [];
    notifier = AccessibilityPreferencesNotifier();
  });

  Future<void> pumpApp(WidgetTester tester, {double systemScale = 1.0}) async {
    tester.platformDispatcher.textScaleFactorTestValue = systemScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) {
            screen = context;
            return const Scaffold(body: Text('Tela'));
          },
        ),
      ],
    );
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          startLocale: const Locale('pt', 'BR'),
          child: ClickSeguroApp(
            moduleManager: ModuleManager(),
            router: router,
            accessibility: notifier,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  double textScale() => MediaQuery.textScalerOf(screen).scale(10) / 10;

  testWidgets('padrão: tema normal e letra do sistema', (tester) async {
    await pumpApp(tester);

    expect(screen.colors, AppPalette.light);
    expect(textScale(), 1.0);
  });

  testWidgets('cada nível aumenta a letra na hora (US1, FR-006)', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final FontScaleLevel level in FontScaleLevel.values) {
      notifier.value = notifier.value.copyWith(fontScale: level);
      await tester.pumpAndSettle();

      expect(textScale(), closeTo(level.factor, 0.0001));
    }
  });

  testWidgets('o nível multiplica a escala do sistema (FR-003)', (
    tester,
  ) async {
    notifier.value = notifier.value.copyWith(fontScale: FontScaleLevel.large);
    await pumpApp(tester, systemScale: 1.2);

    expect(textScale(), closeTo(1.38, 0.0001));
  });

  testWidgets('escala total limitada a 2× (FR-004)', (tester) async {
    notifier.value = notifier.value.copyWith(fontScale: FontScaleLevel.largest);
    await pumpApp(tester, systemScale: 2.0);

    expect(textScale(), 2.0);
  });

  testWidgets('alto contraste liga e desliga na hora (US3)', (tester) async {
    await pumpApp(tester);

    notifier.value = notifier.value.copyWith(highContrast: true);
    await tester.pumpAndSettle();
    expect(screen.colors, AppPalette.highContrast);
    expect(
      Theme.of(screen).scaffoldBackgroundColor,
      AppPalette.highContrast.background,
    );

    notifier.value = notifier.value.copyWith(highContrast: false);
    await tester.pumpAndSettle();
    expect(screen.colors, AppPalette.light);
  });
}
