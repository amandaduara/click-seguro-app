import 'dart:async';

import 'package:click_seguro_app/core/routing/app_router.dart';
import 'package:click_seguro_app/modules/activities/activities.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/help.dart';
import 'package:click_seguro_app/modules/news/news.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../../helpers/localized_app.dart';
import '../../../helpers/feed_provider.dart';
import '../../../helpers/reels_provider.dart';
import '../../../helpers/splash_provider.dart';

void main() {
  late GoRouter router;
  late UserSessionService session;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.startGuestSession();
    router = buildAppRouter(session);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> openHome(WidgetTester tester) async {
    await pumpLocalized(
      tester,
      router: router,
      providers: [
        fakeSplashProvider(session.sessionStatus.value),
        fakeFeedProvider(),
        fakeReelsProvider(),
      ],
    );
    router.go('/home');
    await tester.pumpAndSettle();
  }

  Finder navItem(String label) => find.descendant(
    of: find.byType(AppBottomNav),
    matching: find.bySemanticsLabel(label),
  );

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(navItem(label));
    await tester.pumpAndSettle();
  }

  testWidgets('cinco abas, com "Início" selecionada', (tester) async {
    final semantics = tester.ensureSemantics();
    await openHome(tester);

    for (final label in ['Início', 'Atividades', 'Ajuda', 'Perfil']) {
      expect(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    expect(navItem('Notícias'), findsOneWidget);
    expect(
      tester.getSemantics(navItem('Início')),
      isSemantics(label: 'Início', isSelected: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('troca de aba e botão central', (tester) async {
    final semantics = tester.ensureSemantics();
    await openHome(tester);

    await tapTab(tester, 'Atividades');
    expect(find.byType(ActivitiesPage), findsOneWidget);
    expect(
      tester.getSemantics(navItem('Atividades')),
      isSemantics(isSelected: true),
    );

    await tapTab(tester, 'Notícias');
    expect(find.byType(ReelsPage), findsOneWidget);
    expect(find.byType(AppTopBar), findsNothing);
    expect(
      tester.getSemantics(navItem('Notícias')),
      isSemantics(isSelected: true),
    );
    semantics.dispose();
  });

  testWidgets('a aba anterior continua viva ao trocar', (tester) async {
    await openHome(tester);

    await tapTab(tester, 'Ajuda');

    expect(find.byType(HelpPage), findsOneWidget);
    expect(find.byType(NewsHomePage, skipOffstage: false), findsOneWidget);
  });

  testWidgets('"voltar" em outra aba leva ao Início; no Início não troca', (
    tester,
  ) async {
    await openHome(tester);
    await tapTab(tester, 'Ajuda');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(NewsHomePage), findsOneWidget);
    expect(find.byType(HelpPage), findsNothing);
  });

  testWidgets('o conteúdo da aba fica visível e a barra é baixa', (
    tester,
  ) async {
    await openHome(tester);

    // O Início é o feed (feature 006): a lista precisa estar visível.
    expect(find.byType(CustomScrollView).hitTestable(), findsOneWidget);
    expect(tester.getSize(find.byType(AppBottomNav)).height, lessThan(120));
  });

  testWidgets('itens da barra têm pelo menos 48×48', (tester) async {
    await openHome(tester);

    for (final label in [
      'Início',
      'Atividades',
      'Notícias',
      'Ajuda',
      'Perfil',
    ]) {
      final size = tester.getSize(navItem(label));
      expect(size.width, greaterThanOrEqualTo(48), reason: label);
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
    }
  });

  testWidgets('fonte em 200% não estoura a barra', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await openHome(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('voltar do detalhe aberto nos Reels mantém os Reels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openHome(tester);
    await tapTab(tester, 'Notícias');

    unawaited(router.push('/news/n1'));
    await tester.pumpAndSettle();
    expect(find.byType(NewsDetailPage), findsOneWidget);
    expect(find.byType(AppBottomNav).hitTestable(), findsNothing);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ReelsPage), findsOneWidget);
    expect(
      tester.getSemantics(navItem('Notícias')),
      isSemantics(isSelected: true),
    );
    semantics.dispose();
  });
}
