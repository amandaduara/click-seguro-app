import 'package:click_seguro_app/modules/common/services/app_info_service.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/about_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../fakes/fake_app_info_service.dart';
import '../../../helpers/localized_app.dart';

void main() {
  setUp(() {
    GetIt.instance.registerSingleton<AppInfoService>(FakeAppInfoService());
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

      expect(find.text('Sobre o SafeNews'), findsOneWidget);
      expect(find.text('SafeNews'), findsOneWidget);
      expect(
        find.text(
          'O SafeNews ajuda você a reconhecer golpes digitais com notícias e '
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
}
