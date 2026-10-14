import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/achievements_calculator.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/achievements_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/profile_dependencies.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  setUp(() async {
    final session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    repository = registerProfileDependencies(GetIt.instance);
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'maria@exemplo.com',
    );
  });

  tearDown(() => GetIt.instance.reset());

  /// 12 lidas e um módulo não começado.
  final List<AchievementEntity> achievements = AchievementsCalculator.build(
    readCount: 12,
    progress: testProgress,
  );

  GoRouter buildRouter({Object? extra}) => GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/achievements', extra: extra),
            child: const Text('abrir'),
          ),
        ),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, state) => AchievementsPage(
          achievements: state.extra as List<AchievementEntity>?,
        ),
      ),
    ],
  );

  Future<void> openWith(WidgetTester tester, {Object? extra}) async {
    await pumpLocalized(tester, router: buildRouter(extra: extra));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista completa na ordem, alcançadas e pendentes', (
    tester,
  ) async {
    await openWith(tester, extra: achievements);

    expect(find.text('Conquistas'), findsOneWidget);
    expect(find.text('Conquistada'), findsNWidgets(2));
    expect(find.text('0 de 3 lições'), findsOneWidget);
    expect(find.text('Golpes Digitais'), findsOneWidget);
    // Alcançadas primeiro: "Leitor atento" acima de "Primeira lição".
    expect(
      tester.getTopLeft(find.text('Leitor atento')).dy,
      lessThan(tester.getTopLeft(find.text('Primeira lição')).dy),
    );
    expect(repository.totalCalls, 0);
  });

  testWidgets('voltar fecha a tela', (tester) async {
    await openWith(tester, extra: achievements);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('sem a lista (link direto) carrega sozinha', (tester) async {
    await openWith(tester);

    expect(find.text('Leitor atento'), findsOneWidget);
    expect(repository.profileCalls, 1);
  });

  testWidgets('sem a lista e com falha → erro', (tester) async {
    repository.progressResults[0] = const Left(ConnectionFailure());

    await openWith(tester);

    expect(find.byType(SafeErrorState), findsOneWidget);
  });

  testWidgets('fonte 2× sem estouro', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await openWith(tester, extra: achievements);

    expect(tester.takeException(), isNull);
  });
}
