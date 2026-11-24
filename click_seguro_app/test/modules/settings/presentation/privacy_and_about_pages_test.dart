import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/app_info_service.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/about_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../fakes/fake_app_info_service.dart';
import '../../../fakes/fake_text_to_speech_service.dart';
import '../../../helpers/localized_app.dart';

void main() {
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;

  setUp(() {
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    GetIt.instance
      ..registerSingleton<AppInfoService>(FakeAppInfoService())
      ..registerSingleton(preferences)
      ..registerFactory(
        () => ReadAloudController(tts, preferences: preferences),
      );
  });

  tearDown(() => GetIt.instance.reset());

  void useBigFont(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  group('Privacidade', () {
    testWidgets('título e o que fica no serviço e no celular', (tester) async {
      await pumpLocalized(tester, child: const PrivacyPage());

      expect(find.text('Privacidade'), findsOneWidget);
      expect(find.text('Sua conta'), findsOneWidget);
      expect(find.text('Neste celular'), findsOneWidget);
      expect(
        find.textContaining('contatos de emergência e as fotos deles ficam só'),
        findsOneWidget,
      );
    });

    testWidgets('fonte 2×: rola sem estouro', (tester) async {
      useBigFont(tester);

      await pumpLocalized(tester, child: const PrivacyPage());
      await tester.scrollUntilVisible(
        find.text('Como usamos'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Sobre', () {
    testWidgets('nome, objetivo, versão e crédito genérico', (tester) async {
      await pumpLocalized(tester, child: const AboutPage());

      expect(find.text('Sobre o Click Seguro'), findsOneWidget);
      expect(find.text('Click Seguro'), findsOneWidget);
      expect(
        find.text(
          'O Click Seguro ajuda você a reconhecer golpes digitais com notícias e '
          'atividades.',
        ),
        findsOneWidget,
      );
      expect(find.text('Versão 1.0.0'), findsOneWidget);
      expect(find.text('Trabalho de Conclusão de Curso'), findsOneWidget);
    });

    testWidgets('fonte 2× sem estouro', (tester) async {
      useBigFont(tester);

      await pumpLocalized(tester, child: const AboutPage());

      expect(tester.takeException(), isNull);
    });
  });

  group('"Ouvir" (abaixo do título, antes do texto)', () {
    Future<void> tapListen(WidgetTester tester) async {
      await tester.tap(find.text('Ouvir'));
      await tester.pump();
    }

    void expectRightBelowTitle(WidgetTester tester, String title, String text) {
      final Rect titleRect = tester.getRect(find.text(title));
      final Rect listen = tester.getRect(find.text('Ouvir'));
      expect(listen.top, greaterThan(titleRect.bottom));
      expect(listen.bottom, lessThan(tester.getRect(find.text(text)).top));
    }

    testWidgets('Privacidade: lê o título e cada assunto', (tester) async {
      await pumpLocalized(tester, child: const PrivacyPage());

      expectRightBelowTitle(tester, 'Privacidade', 'Sua conta');
      await tapListen(tester);

      final String spoken = tts.spoken.single.text;
      expect(spoken, startsWith('Privacidade\nSua conta\n'));
      expect(spoken, contains('Neste celular'));
      expect(spoken, contains('Como usamos'));
      expect(find.text('Parar'), findsOneWidget);
    });

    testWidgets('Sobre: lê título, nome, versão, objetivo e crédito', (
      tester,
    ) async {
      await pumpLocalized(tester, child: const AboutPage());

      expectRightBelowTitle(tester, 'Sobre o Click Seguro', 'Click Seguro');
      await tapListen(tester);

      expect(
        tts.spoken.single.text,
        'Sobre o Click Seguro\n'
        'Click Seguro\n'
        'Versão 1.0.0\n'
        'O Click Seguro ajuda você a reconhecer golpes digitais com notícias '
        'e atividades.\n'
        'Trabalho de Conclusão de Curso',
      );
    });

    testWidgets('leitura automática: lê uma vez ao abrir', (tester) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await pumpLocalized(tester, child: const PrivacyPage());

      expect(tts.spoken.single.text, startsWith('Privacidade\n'));
    });

    testWidgets('sem leitura automática: nada é lido ao abrir', (tester) async {
      await pumpLocalized(tester, child: const AboutPage());

      expect(tts.spoken, isEmpty);
    });

    testWidgets('sem voz no idioma: sem "Ouvir" e nada lido', (tester) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await pumpLocalized(tester, child: const PrivacyPage());

      expect(find.text('Ouvir'), findsNothing);
      expect(tts.spoken, isEmpty);
    });
  });
}
