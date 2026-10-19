import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_secure_storage_service.dart';

/// Progresso do visitante só em memória, com a sessão de verdade (R3 de
/// specs/015-painel-atividades).
void main() {
  late UserSessionService session;
  late GuestProgressStore store;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    await session.startGuestSession();
    store = GuestProgressStore(session);
  });

  tearDown(() => store.dispose());

  Future<void> signIn() => session.saveSession(
    accessToken: 'tk',
    refreshToken: 'rf',
    email: 'maria@exemplo.com',
  );

  test('grava e conta por módulo', () {
    store
      ..recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1')
      ..recordAnswer(moduleId: 'm1', lessonId: 'l2', selectedOptionId: 'o5')
      ..recordAnswer(moduleId: 'm2', lessonId: 'l4', selectedOptionId: 'o9');

    expect(store.answeredCount('m1'), 2);
    expect(store.answeredCount('m2'), 1);
    expect(store.answeredCount('m3'), 0);
  });

  test('a mesma lição de novo substitui a resposta e conta uma vez', () {
    store
      ..recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1')
      ..recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o2');

    expect(store.answeredCount('m1'), 1);
  });

  test('sair do modo visitante apaga', () async {
    store.recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1');

    await session.logout();

    expect(store.answeredCount('m1'), 0);
  });

  test('entrar numa conta que já existia apaga', () async {
    store.recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1');

    await signIn();

    expect(store.answeredCount('m1'), 0);
  });

  group('cadastro (FR-008a)', () {
    Future<void> signUp() => session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'nova@exemplo.com',
      newAccount: true,
    );

    test('as respostas viram pendentes e o aviso sai uma vez', () async {
      int signUps = 0;
      store.onSignUp = () => signUps++;
      store
        ..recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1')
        ..recordAnswer(moduleId: 'm1', lessonId: 'l2', selectedOptionId: 'o5');

      await signUp();

      expect(store.answeredCount('m1'), 0);
      expect([for (final a in store.pendingTransfer) a.lessonId], ['l1', 'l2']);
      expect(store.pendingTransfer.first.selectedOptionId, 'o1');
      expect(signUps, 1);
    });

    test('removePending tira só aquela', () async {
      store
        ..recordAnswer(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'o1')
        ..recordAnswer(moduleId: 'm1', lessonId: 'l2', selectedOptionId: 'o5');
      await signUp();

      store.removePending(store.pendingTransfer.first);

      expect([for (final a in store.pendingTransfer) a.lessonId], ['l2']);
    });

    test('sair da conta apaga as pendentes', () async {
      store.recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
      );
      await signUp();

      await session.logout();

      expect(store.pendingTransfer, isEmpty);
    });

    test('login não gera pendentes', () async {
      store.recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
      );

      await signIn();

      expect(store.pendingTransfer, isEmpty);
    });
  });
}
