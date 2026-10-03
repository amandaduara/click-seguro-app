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
      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
        userName: 'Maria',
      );

      expect(stored(), {
        'status': 'authenticated',
        'accessToken': 't',
        'refreshToken': 'r-t',
        'email': 'u@exemplo.com',
        'userName': 'Maria',
      });
    });

    test('reabrir restaura a sessão conectada com os mesmos dados', () async {
      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
        userName: 'Maria',
      );

      final reopened = await reopen();

      expect(reopened.sessionStatus.value, UserSessionStatus.authenticated);
      expect(reopened.isAuthenticated, isTrue);
      expect(reopened.accessToken, 't');
      expect(reopened.refreshToken, 'r-t');
      expect(reopened.email, 'u@exemplo.com');
      expect(reopened.userName, 'Maria');
      expect(reopened.endReason, isNull);
    });

    test('sem registro, restoreSession deixa desconectado', () async {
      await session.restoreSession();

      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.accessToken, isNull);
    });

    for (final entry in {
      'JSON inválido': '{abc',
      'status desconhecido': '{"status":"admin"}',
      'authenticated sem accessToken':
          '{"status":"authenticated","refreshToken":"r","email":"u@x.com"}',
      'authenticated sem refreshToken':
          '{"status":"authenticated","accessToken":"t","email":"u@x.com"}',
      'authenticated sem email':
          '{"status":"authenticated","accessToken":"t","refreshToken":"r"}',
      'formato da feature 001':
          '{"status":"authenticated","token":"t","userId":"u"}',
    }.entries) {
      test(
        'registro inválido (${entry.key}) é apagado e fica desconectado',
        () async {
          storage.values[key] = entry.value;

          await session.restoreSession();

          expect(
            session.sessionStatus.value,
            UserSessionStatus.unauthenticated,
          );
          expect(session.accessToken, isNull);
          expect(storage.values.containsKey(key), isFalse);
          expect(storage.deleteCalls, 1);
          expect(session.endReason, isNull);
        },
      );
    }

    test('falha de leitura deixa desconectado sem lançar', () async {
      storage.failOnRead = true;

      await session.restoreSession();

      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
    });

    test('falha de escrita não lança e mantém o estado em memória', () async {
      storage.failOnWrite = true;

      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
      );

      expect(session.sessionStatus.value, UserSessionStatus.authenticated);
      expect(session.accessToken, 't');
    });

    test('quem escuta sessionStatus já lê os dados preenchidos', () async {
      String? tokenSeen;
      String? emailSeen;
      String? nameSeen;
      session.sessionStatus.addListener(() {
        tokenSeen = session.accessToken;
        emailSeen = session.email;
        nameSeen = session.userName;
      });

      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
        userName: 'Maria',
      );

      expect(tokenSeen, 't');
      expect(emailSeen, 'u@exemplo.com');
      expect(nameSeen, 'Maria');
    });

    test('saveSession rejeita accessToken, refreshToken ou email vazios', () {
      expect(
        () => session.saveSession(
          accessToken: '',
          refreshToken: 'r',
          email: 'u@exemplo.com',
        ),
        throwsArgumentError,
      );
      expect(
        () => session.saveSession(
          accessToken: 't',
          refreshToken: '',
          email: 'u@exemplo.com',
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            session.saveSession(accessToken: 't', refreshToken: 'r', email: ''),
        throwsArgumentError,
      );
    });

    test('troca de conta deixa só a conta nova', () async {
      await session.saveSession(
        accessToken: 'tA',
        refreshToken: 'r-tA',
        email: 'A@exemplo.com',
        userName: 'Ana',
      );
      await session.saveSession(
        accessToken: 'tB',
        refreshToken: 'r-tB',
        email: 'B@exemplo.com',
      );

      expect(stored(), {
        'status': 'authenticated',
        'accessToken': 'tB',
        'refreshToken': 'r-tB',
        'email': 'B@exemplo.com',
      });
      expect(session.email, 'B@exemplo.com');
      expect(session.userName, isNull);
    });
  });

  group('US2 visitante', () {
    test(
      'startGuestSession grava só o status e entra como visitante',
      () async {
        await session.startGuestSession();

        expect(stored(), {'status': 'guest'});
        expect(session.sessionStatus.value, UserSessionStatus.guest);
        expect(session.isGuest, isTrue);
        expect(session.isAuthenticated, isFalse);
        expect(session.accessToken, isNull);
      },
    );

    test('reabrir continua visitante', () async {
      await session.startGuestSession();

      final reopened = await reopen();

      expect(reopened.sessionStatus.value, UserSessionStatus.guest);
      expect(reopened.isGuest, isTrue);
    });

    test(
      'entrar com conta a partir do visitante remove a marca de visitante',
      () async {
        await session.startGuestSession();

        await session.saveSession(
          accessToken: 't',
          refreshToken: 'r-t',
          email: 'u@exemplo.com',
        );

        expect(session.sessionStatus.value, UserSessionStatus.authenticated);
        expect(session.isGuest, isFalse);
        expect(stored()['status'], 'authenticated');
      },
    );

    for (final field in ['token', 'accessToken', 'refreshToken']) {
      test('registro de visitante com $field é inválido', () async {
        storage.values[key] = '{"status":"guest","$field":"x"}';

        await session.restoreSession();

        expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
        expect(storage.values.containsKey(key), isFalse);
      });
    }

    test('falha de escrita não lança e fica visitante em memória', () async {
      storage.failOnWrite = true;

      await session.startGuestSession();

      expect(session.sessionStatus.value, UserSessionStatus.guest);
    });
  });

  group('US3 encerramento', () {
    void expectEnded(SessionEndReason reason) {
      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.accessToken, isNull);
      expect(session.refreshToken, isNull);
      expect(session.email, isNull);
      expect(session.userName, isNull);
      expect(session.endReason, reason);
      expect(storage.values.containsKey(key), isFalse);
    }

    test(
      'logout a partir de conectado apaga a sessão com motivo userLogout',
      () async {
        await session.saveSession(
          accessToken: 't',
          refreshToken: 'r-t',
          email: 'u@exemplo.com',
          userName: 'Maria',
        );

        await session.logout();

        expectEnded(SessionEndReason.userLogout);
        expect(storage.deleteCalls, 1);
      },
    );

    test('logout a partir de visitante', () async {
      await session.startGuestSession();

      await session.logout();

      expectEnded(SessionEndReason.userLogout);
    });

    test('expire a partir de conectado encerra com motivo expired', () async {
      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
      );

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
      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
      );
      await session.logout();
      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
      );
      await session.expire();

      expect(storage.values['outra'], 'valor');
    });

    test('nova sessão depois de expirar zera o motivo', () async {
      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
      );
      await session.expire();

      await session.saveSession(
        accessToken: 't2',
        refreshToken: 'r-t2',
        email: 'u@exemplo.com',
      );

      expect(session.endReason, isNull);
    });

    test('quem escuta sessionStatus já lê o motivo preenchido', () async {
      await session.saveSession(
        accessToken: 't',
        refreshToken: 'r-t',
        email: 'u@exemplo.com',
      );
      SessionEndReason? reasonSeen;
      session.sessionStatus.addListener(() => reasonSeen = session.endReason);

      await session.expire();

      expect(reasonSeen, SessionEndReason.expired);
    });

    test(
      'falha de escrita no logout não lança e desconecta em memória',
      () async {
        await session.saveSession(
          accessToken: 't',
          refreshToken: 'r-t',
          email: 'u@exemplo.com',
        );
        storage.failOnWrite = true;

        await session.logout();

        expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
        expect(session.endReason, SessionEndReason.userLogout);
      },
    );
  });

  group('US1 replaceTokens (feature 002)', () {
    Future<void> signIn() => session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
      userName: 'Maria',
    );

    test('aplica o novo par, regrava e não notifica sessionStatus', () async {
      await signIn();
      var notifications = 0;
      session.sessionStatus.addListener(() => notifications++);

      final applied = await session.replaceTokens(
        previousRefreshToken: 'renovacao-1',
        accessToken: 'acesso-2',
        refreshToken: 'renovacao-2',
      );

      expect(applied, isTrue);
      expect(session.accessToken, 'acesso-2');
      expect(session.refreshToken, 'renovacao-2');
      expect(stored(), {
        'status': 'authenticated',
        'accessToken': 'acesso-2',
        'refreshToken': 'renovacao-2',
        'email': 'maria@exemplo.com',
        'userName': 'Maria',
      });
      expect(notifications, 0);
    });

    test('refresh token anterior diferente do atual não aplica', () async {
      await signIn();

      final applied = await session.replaceTokens(
        previousRefreshToken: 'outro',
        accessToken: 'acesso-2',
        refreshToken: 'renovacao-2',
      );

      expect(applied, isFalse);
      expect(session.accessToken, 'acesso-1');
      expect(stored()['refreshToken'], 'renovacao-1');
    });

    test('depois do logout não aplica e continua desconectado', () async {
      await signIn();
      await session.logout();

      final applied = await session.replaceTokens(
        previousRefreshToken: 'renovacao-1',
        accessToken: 'acesso-2',
        refreshToken: 'renovacao-2',
      );

      expect(applied, isFalse);
      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.accessToken, isNull);
      expect(storage.values.containsKey(key), isFalse);
    });

    test('visitante não aplica', () async {
      await session.startGuestSession();

      final applied = await session.replaceTokens(
        previousRefreshToken: 'renovacao-1',
        accessToken: 'acesso-2',
        refreshToken: 'renovacao-2',
      );

      expect(applied, isFalse);
      expect(stored(), {'status': 'guest'});
    });

    test('falha de escrita não lança e mantém o par novo em memória', () async {
      await signIn();
      storage.failOnWrite = true;

      final applied = await session.replaceTokens(
        previousRefreshToken: 'renovacao-1',
        accessToken: 'acesso-2',
        refreshToken: 'renovacao-2',
      );

      expect(applied, isTrue);
      expect(session.accessToken, 'acesso-2');
    });
  });
}
