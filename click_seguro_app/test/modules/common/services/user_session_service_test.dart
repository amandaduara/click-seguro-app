import 'dart:convert';

import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_secure_storage_service.dart';

void main() {
  const key = UserSessionService.storageKey;

  late FakeSecureStorageService storage;
  late UserSessionService session;

  setUp(() {
    storage = FakeSecureStorageService();
    session = UserSessionService(storage);
  });

  /// Simula fechar e reabrir o app: novo serviço sobre o mesmo armazenamento.
  Future<UserSessionService> reopen() async {
    final reopened = UserSessionService(storage);
    await reopened.restoreSession();
    return reopened;
  }

  Map<String, dynamic> stored() =>
      jsonDecode(storage.values[key]!) as Map<String, dynamic>;

  group('US1 persistência e restauração', () {
    test('saveSession grava o registro authenticated', () async {
      await session.saveSession(token: 't', userId: 'u', userName: 'Maria');

      expect(stored(), {
        'status': 'authenticated',
        'token': 't',
        'userId': 'u',
        'userName': 'Maria',
      });
    });

    test('reabrir restaura a sessão conectada com os mesmos dados', () async {
      await session.saveSession(token: 't', userId: 'u', userName: 'Maria');

      final reopened = await reopen();

      expect(reopened.sessionStatus.value, UserSessionStatus.authenticated);
      expect(reopened.isAuthenticated, isTrue);
      expect(reopened.token, 't');
      expect(reopened.userId, 'u');
      expect(reopened.userName, 'Maria');
      expect(reopened.endReason, isNull);
    });

    test('sem registro, restoreSession deixa desconectado', () async {
      await session.restoreSession();

      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.token, isNull);
    });

    for (final entry in {
      'JSON inválido': '{abc',
      'status desconhecido': '{"status":"admin"}',
      'authenticated sem token': '{"status":"authenticated","userId":"u"}',
      'authenticated sem userId': '{"status":"authenticated","token":"t"}',
    }.entries) {
      test('registro inválido (${entry.key}) é apagado e fica desconectado',
          () async {
        storage.values[key] = entry.value;

        await session.restoreSession();

        expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
        expect(session.token, isNull);
        expect(storage.values.containsKey(key), isFalse);
        expect(storage.deleteCalls, 1);
        expect(session.endReason, isNull);
      });
    }

    test('falha de leitura deixa desconectado sem lançar', () async {
      storage.failOnRead = true;

      await session.restoreSession();

      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
    });

    test('falha de escrita não lança e mantém o estado em memória', () async {
      storage.failOnWrite = true;

      await session.saveSession(token: 't', userId: 'u');

      expect(session.sessionStatus.value, UserSessionStatus.authenticated);
      expect(session.token, 't');
    });

    test('quem escuta sessionStatus já lê os dados preenchidos', () async {
      String? tokenSeen;
      String? userIdSeen;
      String? nameSeen;
      session.sessionStatus.addListener(() {
        tokenSeen = session.token;
        userIdSeen = session.userId;
        nameSeen = session.userName;
      });

      await session.saveSession(token: 't', userId: 'u', userName: 'Maria');

      expect(tokenSeen, 't');
      expect(userIdSeen, 'u');
      expect(nameSeen, 'Maria');
    });

    test('saveSession rejeita token ou userId vazios', () {
      expect(
        () => session.saveSession(token: '', userId: 'u'),
        throwsArgumentError,
      );
      expect(
        () => session.saveSession(token: 't', userId: ''),
        throwsArgumentError,
      );
    });

    test('troca de conta deixa só a conta nova', () async {
      await session.saveSession(token: 'tA', userId: 'A', userName: 'Ana');
      await session.saveSession(token: 'tB', userId: 'B');

      expect(stored(), {
        'status': 'authenticated',
        'token': 'tB',
        'userId': 'B',
      });
      expect(session.userId, 'B');
      expect(session.userName, isNull);
    });
  });

  group('US2 visitante', () {
    test('startGuestSession grava só o status e entra como visitante',
        () async {
      await session.startGuestSession();

      expect(stored(), {'status': 'guest'});
      expect(session.sessionStatus.value, UserSessionStatus.guest);
      expect(session.isGuest, isTrue);
      expect(session.isAuthenticated, isFalse);
      expect(session.token, isNull);
    });

    test('reabrir continua visitante', () async {
      await session.startGuestSession();

      final reopened = await reopen();

      expect(reopened.sessionStatus.value, UserSessionStatus.guest);
      expect(reopened.isGuest, isTrue);
    });

    test('entrar com conta a partir do visitante remove a marca de visitante',
        () async {
      await session.startGuestSession();

      await session.saveSession(token: 't', userId: 'u');

      expect(session.sessionStatus.value, UserSessionStatus.authenticated);
      expect(session.isGuest, isFalse);
      expect(stored()['status'], 'authenticated');
    });

    test('registro de visitante com token é inválido', () async {
      storage.values[key] = '{"status":"guest","token":"x"}';

      await session.restoreSession();

      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(storage.values.containsKey(key), isFalse);
    });

    test('falha de escrita não lança e fica visitante em memória', () async {
      storage.failOnWrite = true;

      await session.startGuestSession();

      expect(session.sessionStatus.value, UserSessionStatus.guest);
    });
  });

  group('US3 encerramento', () {
    void expectEnded(SessionEndReason reason) {
      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.token, isNull);
      expect(session.userId, isNull);
      expect(session.userName, isNull);
      expect(session.endReason, reason);
      expect(storage.values.containsKey(key), isFalse);
    }

    test('logout a partir de conectado apaga a sessão com motivo userLogout',
        () async {
      await session.saveSession(token: 't', userId: 'u', userName: 'Maria');

      await session.logout();

      expectEnded(SessionEndReason.userLogout);
      expect(storage.deleteCalls, 1);
    });

    test('logout a partir de visitante', () async {
      await session.startGuestSession();

      await session.logout();

      expectEnded(SessionEndReason.userLogout);
    });

    test('expire a partir de conectado encerra com motivo expired', () async {
      await session.saveSession(token: 't', userId: 'u');

      await session.expire();

      expectEnded(SessionEndReason.expired);
    });

    test('expire sem sessão conectada não muda nada', () async {
      await session.startGuestSession();
      await session.expire();
      expect(session.sessionStatus.value, UserSessionStatus.guest);
      expect(session.endReason, isNull);
      expect(stored(), {'status': 'guest'});

      final other = UserSessionService(FakeSecureStorageService());
      await other.expire();
      expect(other.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(other.endReason, isNull);
    });

    test('encerrar não apaga outras chaves do armazenamento', () async {
      storage.values['outra'] = 'valor';
      await session.saveSession(token: 't', userId: 'u');
      await session.logout();
      await session.saveSession(token: 't', userId: 'u');
      await session.expire();

      expect(storage.values['outra'], 'valor');
    });

    test('nova sessão depois de expirar zera o motivo', () async {
      await session.saveSession(token: 't', userId: 'u');
      await session.expire();

      await session.saveSession(token: 't2', userId: 'u');

      expect(session.endReason, isNull);
    });

    test('quem escuta sessionStatus já lê o motivo preenchido', () async {
      await session.saveSession(token: 't', userId: 'u');
      SessionEndReason? reasonSeen;
      session.sessionStatus.addListener(() => reasonSeen = session.endReason);

      await session.expire();

      expect(reasonSeen, SessionEndReason.expired);
    });

    test('falha de escrita no logout não lança e desconecta em memória',
        () async {
      await session.saveSession(token: 't', userId: 'u');
      storage.failOnWrite = true;

      await session.logout();

      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.endReason, SessionEndReason.userLogout);
    });
  });
}
