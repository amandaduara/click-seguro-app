import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/terms_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_topic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/fake_text_to_speech_service.dart';
import '../../../helpers/localized_app.dart';

const List<String> _titles = [
  'O que é o Click Seguro',
  'O que o app não faz',
  'Sua conta',
  'Bom uso do app',
  'Seus dados',
];

void main() {
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;

  setUp(() {
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    GetIt.instance
      ..registerSingleton(preferences)
      ..registerFactory(
        () => ReadAloudController(tts, preferences: preferences),
      );
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('título, data e os cinco assuntos na ordem', (tester) async {
    // Tela alta: a lista monta só o que aparece.
    tester.view
      ..physicalSize = const Size(390, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(tester, child: const TermsPage());

    expect(find.text('Termos de uso'), findsOneWidget);
    expect(find.text('Última atualização: 23/11/2026'), findsOneWidget);
    final List<String> titles = tester
        .widgetList<SettingsTopicCard>(find.byType(SettingsTopicCard))
        .map((card) => card.title)
        .toList();
    expect(titles, _titles);
    expect(
      find.textContaining(
        'não substitui o seu banco, a polícia',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Ver Privacidade" abre a tela Privacidade', (tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/settings/terms',
      routes: [
        GoRoute(
          path: '/settings/terms',
          builder: (context, state) => const TermsPage(),
        ),
        GoRoute(
          path: '/settings/privacy',
          builder: (context, state) => const Text('tela privacidade'),
        ),
      ],
    );
    await pumpLocalized(tester, router: router);

    await tester.scrollUntilVisible(
      find.text('Ver Privacidade'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Ver Privacidade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver Privacidade'));
    await tester.pumpAndSettle();

    expect(find.text('tela privacidade'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(TermsPage), findsOneWidget);
  });

  testWidgets('"Ver Privacidade" tem área de toque de 48', (tester) async {
    await pumpLocalized(tester, child: const TermsPage());
    await tester.scrollUntilVisible(
      find.text('Ver Privacidade'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final Size size = tester.getSize(
      find.ancestor(
        of: find.text('Ver Privacidade'),
        matching: find.byType(TextButton),
      ),
    );
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('"Ouvir" lê título, data e cada assunto, na ordem', (
    tester,
  ) async {
    await pumpLocalized(tester, child: const TermsPage());

    await tester.tap(find.text('Ouvir'));
    await tester.pump();

    final String spoken = tts.spoken.single.text;
    expect(
      spoken,
      startsWith('Termos de uso\nÚltima atualização: 23/11/2026\n'),
    );
    int last = -1;
    for (final String title in _titles) {
      final int at = spoken.indexOf(title);
      expect(at, greaterThan(last), reason: title);
      last = at;
    }
    expect(spoken, contains('nós nunca pedimos'));
    expect(spoken, endsWith('está explicado na tela Privacidade.'));
  });

  testWidgets('fonte 2×: rola até o fim sem estouro', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLocalized(tester, child: const TermsPage());
    await tester.scrollUntilVisible(
      find.text('Ver Privacidade'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('em inglês', (tester) async {
    await pumpLocalized(
      tester,
      child: const TermsPage(),
      locale: const Locale('en', 'US'),
    );

    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Last updated: 11/23/2026'), findsOneWidget);
    expect(find.text('What Click Seguro is'), findsOneWidget);
  });
}
