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
}
