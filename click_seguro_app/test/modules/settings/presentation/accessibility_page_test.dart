import 'dart:ui' show CheckedState, Tristate;

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/main.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/models/accessibility_preferences_model.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/accessibility_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/accessibility_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fakes/fake_local_cache_service.dart';
import '../../../helpers/accessibility_provider.dart';

/// A tela de Acessibilidade no app de verdade (tema e escala do
/// `ClickSeguroApp`), com o `AccessibilityController` real sobre o
/// armazenamento falso: o que a pessoa escolhe muda o app e fica gravado
/// (tarefa B9, R9 de specs/014-acessibilidade).
void main() {
  const String key = AccessibilityLocalDataSourceImpl.storageKey;
  const List<String> levels = ['Padrão', 'Grande', 'Maior', 'Muito grande'];

  late FakeLocalCacheService cache;
  late AccessibilityPreferencesNotifier notifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableBuildModes = [];
    cache = FakeLocalCacheService();
  });

  /// Grava [preferences] como a feature 009 grava.
  void store(AccessibilityPreferences preferences) =>
      cache.values[key] = AccessibilityPreferencesModel.toJson(preferences);

  AccessibilityPreferences stored() =>
      AccessibilityPreferencesModel.fromJson(cache.values[key]!);

  /// Abre o app em `/settings/accessibility` como na abertura: um notifier e
  /// um controller novos, carregados do [cache] antes da primeira tela.
  Future<void> pumpAccessibility(
    WidgetTester tester, {
    double systemScale = 1.0,
    Locale locale = const Locale('pt', 'BR'),
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = systemScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    notifier = AccessibilityPreferencesNotifier();
    final AccessibilityController controller = buildAccessibilityController(
      cache: cache,
      notifier: notifier,
    );
    final router = GoRouter(
      initialLocation: '/settings/accessibility',
      routes: [
        GoRoute(
          path: '/settings/accessibility',
          builder: (_, _) => ChangeNotifierProvider.value(
            value: controller,
            child: const AccessibilityPage(),
          ),
        ),
      ],
    );
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      await controller.load();
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          startLocale: locale,
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

  BuildContext page(WidgetTester tester) =>
      tester.element(find.byType(AccessibilityPage));

  double textScale(WidgetTester tester) =>
      MediaQuery.textScalerOf(page(tester)).scale(10) / 10;

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapOption(WidgetTester tester, String label) async {
    await reveal(tester, find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Tristate toggled(WidgetTester tester, String label) => tester
      .getSemantics(find.text(label))
      .getSemanticsData()
      .flagsCollection
      .isToggled;

  CheckedState checked(WidgetTester tester, String label) => tester
      .getSemantics(find.text(label))
      .getSemanticsData()
      .flagsCollection
      .isChecked;

  group('tamanho da letra', () {
    testWidgets('título, prévia e os quatro níveis, com "Padrão" marcado', (
      tester,
    ) async {
      await pumpAccessibility(tester);

      expect(find.text('Acessibilidade'), findsOneWidget);
      expect(find.text('Tamanho da letra'), findsOneWidget);
      expect(find.text('Golpe do falso parente'), findsOneWidget);
      expect(
        find.text(
          'Desconfie de mensagem de número novo pedindo dinheiro com '
          'urgência.',
        ),
        findsOneWidget,
      );
      for (final (index, label) in levels.indexed) {
        await reveal(tester, find.text(label));
        expect(
          find.text(['100%', '115%', '130%', '150%'][index]),
          findsOneWidget,
        );
      }
      expect(checked(tester, 'Padrão'), CheckedState.isTrue);
      expect(checked(tester, 'Maior'), CheckedState.isFalse);
    });

    testWidgets('"Muito grande": marcada, o app cresce na hora e grava', (
      tester,
    ) async {
      await pumpAccessibility(tester);

      await tapOption(tester, 'Muito grande');

      expect(checked(tester, 'Muito grande'), CheckedState.isTrue);
      expect(checked(tester, 'Padrão'), CheckedState.isFalse);
      expect(textScale(tester), closeTo(1.5, 0.0001));
      expect(stored().fontScale, FontScaleLevel.largest);
    });

    testWidgets('na próxima abertura o nível escolhido já vale', (
      tester,
    ) async {
      await pumpAccessibility(tester);
      await tapOption(tester, 'Maior');

      await pumpAccessibility(tester);

      expect(textScale(tester), closeTo(1.3, 0.0001));
      await reveal(tester, find.text('Maior'));
      expect(checked(tester, 'Maior'), CheckedState.isTrue);
    });

    testWidgets('voltar a "Padrão" volta a letra ao normal', (tester) async {
      store(
        const AccessibilityPreferences.defaults().copyWith(
          fontScale: FontScaleLevel.large,
        ),
      );
      await pumpAccessibility(tester);
      expect(textScale(tester), closeTo(1.15, 0.0001));

      await tapOption(tester, 'Padrão');

      expect(textScale(tester), 1.0);
      expect(stored().fontScale, FontScaleLevel.standard);
    });

    testWidgets('tocar no nível já marcado não grava de novo', (tester) async {
      await pumpAccessibility(tester);

      await tapOption(tester, 'Padrão');

      expect(cache.writeCalls, 0);
    });

    testWidgets('falha ao gravar: vale na hora, sem erro', (tester) async {
      cache.throwOnWrite = true;
      await pumpAccessibility(tester);

      await tapOption(tester, 'Grande');

      expect(textScale(tester), closeTo(1.15, 0.0001));
      expect(checked(tester, 'Grande'), CheckedState.isTrue);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nível máximo com o celular em 2×: rola e tudo é tocável', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      store(
        const AccessibilityPreferences.defaults().copyWith(
          fontScale: FontScaleLevel.largest,
        ),
      );
      await pumpAccessibility(tester, systemScale: 2.0);

      expect(tester.takeException(), isNull);
      for (final label in levels) {
        await reveal(tester, find.text(label));
        final Finder row = find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('em inglês', (tester) async {
      await pumpAccessibility(tester, locale: const Locale('en', 'US'));

      expect(find.text('Accessibility'), findsOneWidget);
      expect(find.text('Text size'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      await reveal(tester, find.text('Extra large'));
      expect(find.text('Extra large'), findsOneWidget);
    });
  });

  group('alto contraste', () {
    const String label = 'Alto contraste';

    testWidgets('seção "Aparência" com a chave desligada', (tester) async {
      await pumpAccessibility(tester);
      await reveal(tester, find.text(label));

      expect(find.text('Aparência'), findsOneWidget);
      expect(find.text('Cores mais fortes para ler melhor'), findsOneWidget);
      expect(toggled(tester, label), Tristate.isFalse);
    });

    testWidgets('ligar muda o app na hora e grava; desligar volta', (
      tester,
    ) async {
      await pumpAccessibility(tester);

      await tapOption(tester, label);

      expect(toggled(tester, label), Tristate.isTrue);
      expect(page(tester).colors, AppPalette.highContrast);
      expect(stored().highContrast, isTrue);

      await tapOption(tester, label);

      expect(page(tester).colors, AppPalette.light);
      expect(stored().highContrast, isFalse);
    });

    testWidgets('na próxima abertura já abre em alto contraste', (
      tester,
    ) async {
      store(
        const AccessibilityPreferences.defaults().copyWith(highContrast: true),
      );
      await pumpAccessibility(tester);

      expect(page(tester).colors, AppPalette.highContrast);
      await reveal(tester, find.text(label));
      expect(toggled(tester, label), Tristate.isTrue);
    });

    testWidgets('alto contraste + letra máxima com o celular em 2×', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      store(
        const AccessibilityPreferences.defaults().copyWith(
          highContrast: true,
          fontScale: FontScaleLevel.largest,
        ),
      );
      await pumpAccessibility(tester, systemScale: 2.0);

      await reveal(tester, find.text(label));
      expect(tester.takeException(), isNull);
      expect(toggled(tester, label), Tristate.isTrue);
    });
  });

  group('leitura em voz alta', () {
    const String autoRead = 'Ler automaticamente';

    testWidgets('chave desligada, velocidades com "Normal" marcada', (
      tester,
    ) async {
      await pumpAccessibility(tester);
      await reveal(tester, find.text('Rápida'));

      expect(find.text('Leitura em voz alta'), findsOneWidget);
      expect(
        find.text(
          'Ao abrir uma notícia ou uma pergunta das atividades, o app começa a ler sozinho',
        ),
        findsOneWidget,
      );
      expect(toggled(tester, autoRead), Tristate.isFalse);
      expect(find.text('Velocidade da voz'), findsOneWidget);
      expect(checked(tester, 'Normal'), CheckedState.isTrue);
      expect(checked(tester, 'Lenta'), CheckedState.isFalse);
    });

    testWidgets('ligar a leitura automática vale na hora e grava', (
      tester,
    ) async {
      await pumpAccessibility(tester);

      await tapOption(tester, autoRead);

      expect(toggled(tester, autoRead), Tristate.isTrue);
      expect(notifier.value.autoReadAloud, isTrue);
      expect(stored().autoReadAloud, isTrue);
    });

    testWidgets('"Lenta" com a leitura automática desligada', (tester) async {
      await pumpAccessibility(tester);

      await tapOption(tester, 'Lenta');

      expect(checked(tester, 'Lenta'), CheckedState.isTrue);
      expect(notifier.value.readingSpeed, ReadingSpeed.slow);
      expect(notifier.value.autoReadAloud, isFalse);
      expect(stored().readingSpeed, ReadingSpeed.slow);
    });

    testWidgets('na próxima abertura as duas escolhas aparecem', (
      tester,
    ) async {
      store(
        const AccessibilityPreferences.defaults().copyWith(
          autoReadAloud: true,
          readingSpeed: ReadingSpeed.fast,
        ),
      );
      await pumpAccessibility(tester);
      await reveal(tester, find.text('Rápida'));

      expect(toggled(tester, autoRead), Tristate.isTrue);
      expect(checked(tester, 'Rápida'), CheckedState.isTrue);
    });
  });
}
