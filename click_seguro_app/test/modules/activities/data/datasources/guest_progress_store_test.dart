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
      ..recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
        isCorrect: true,
      )
      ..recordAnswer(
        moduleId: 'm1',
        lessonId: 'l2',
        selectedOptionId: 'o5',
        isCorrect: true,
      )
      ..recordAnswer(
        moduleId: 'm2',
        lessonId: 'l4',
        selectedOptionId: 'o9',
        isCorrect: true,
      );

    expect(store.answeredCount('m1'), 2);
    expect(store.answeredCount('m2'), 1);
    expect(store.answeredCount('m3'), 0);
  });

  test('a mesma lição de novo substitui a resposta e conta uma vez', () {
    store
      ..recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
        isCorrect: true,
      )
      ..recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o2',
        isCorrect: true,
      );

    expect(store.answeredCount('m1'), 1);
  });

  test('sair do modo visitante apaga', () async {
    store.recordAnswer(
      moduleId: 'm1',
      lessonId: 'l1',
      selectedOptionId: 'o1',
      isCorrect: true,
    );

    await session.logout();

    expect(store.answeredCount('m1'), 0);
  });

  test('entrar numa conta que já existia apaga', () async {
    store.recordAnswer(
      moduleId: 'm1',
      lessonId: 'l1',
      selectedOptionId: 'o1',
      isCorrect: true,
    );

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
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l1',
          selectedOptionId: 'o1',
          isCorrect: true,
        )
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l2',
          selectedOptionId: 'o5',
          isCorrect: true,
        );

      await signUp();

      expect(store.answeredCount('m1'), 0);
      expect([for (final a in store.pendingTransfer) a.lessonId], ['l1', 'l2']);
      expect(store.pendingTransfer.first.selectedOptionId, 'o1');
      expect(signUps, 1);
    });

    test('removePending tira só aquela', () async {
      store
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l1',
          selectedOptionId: 'o1',
          isCorrect: true,
        )
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l2',
          selectedOptionId: 'o5',
          isCorrect: true,
        );
      await signUp();

      store.removePending(store.pendingTransfer.first);

      expect([for (final a in store.pendingTransfer) a.lessonId], ['l2']);
    });

    test('sair da conta apaga as pendentes', () async {
      store.recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
        isCorrect: true,
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
        isCorrect: true,
      );

      await signIn();

      expect(store.pendingTransfer, isEmpty);
    });
  });

  group('acertos (specs/018 R4)', () {
    test('correctCount conta só as certas do módulo', () {
      store
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l1',
          selectedOptionId: 'o1',
          isCorrect: true,
        )
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l2',
          selectedOptionId: 'o5',
          isCorrect: false,
        )
        ..recordAnswer(
          moduleId: 'm2',
          lessonId: 'l4',
          selectedOptionId: 'o9',
          isCorrect: true,
        );

      expect(store.correctCount('m1'), 1);
      expect(store.correctCount('m2'), 1);
      expect(store.correctCount('m3'), 0);
    });

    test('vale a resposta mais recente da lição', () {
      store.recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
        isCorrect: true,
      );
      expect(store.correctCount('m1'), 1);

      store.recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o2',
        isCorrect: false,
      );

      expect(store.correctCount('m1'), 0);
      expect(store.answeredCount('m1'), 1);
    });

    test('a transferência leva a alternativa escolhida', () async {
      store.recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o2',
        isCorrect: false,
      );

      await session.saveSession(
        accessToken: 'tk',
        refreshToken: 'rf',
        email: 'nova@exemplo.com',
        newAccount: true,
      );

      expect(store.pendingTransfer.single.selectedOptionId, 'o2');
    });
  });

  test('isAnswered por lição (specs/017 R3)', () async {
    expect(store.isAnswered('l1'), isFalse);

    store.recordAnswer(
      moduleId: 'm1',
      lessonId: 'l1',
      selectedOptionId: 'o1',
      isCorrect: true,
    );

    expect(store.isAnswered('l1'), isTrue);
    expect(store.isAnswered('l2'), isFalse);

    await session.logout();

    expect(store.isAnswered('l1'), isFalse);
  });
}
