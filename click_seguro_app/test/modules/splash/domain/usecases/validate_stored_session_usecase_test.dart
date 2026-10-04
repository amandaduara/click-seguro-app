import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/splash/domain/usecases/validate_stored_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/fake_session_validation_service.dart';

void main() {
  late UserSessionService session;
  late FakeSessionValidationService validation;
  late ValidateStoredSessionUseCase useCase;

  setUp(() {
    session = UserSessionService(FakeSecureStorageService());
    validation = FakeSessionValidationService();
    useCase = ValidateStoredSessionUseCase(validation, session);
  });

  Future<void> signIn() => session.saveSession(
    accessToken: 'acesso-1',
    refreshToken: 'renovacao-1',
    email: 'maria@exemplo.com',
    userName: 'Maria',
  );

  group('estado devolvido', () {
    test('conectada e conferência sem mudança → authenticated', () async {
      await signIn();

      expect(await useCase(), UserSessionStatus.authenticated);
      expect(validation.calls, 1);
    });

    test('visitante → guest', () async {
      await session.startGuestSession();

      expect(await useCase(), UserSessionStatus.guest);
    });

    test('sem sessão → unauthenticated', () async {
      expect(await useCase(), UserSessionStatus.unauthenticated);
    });
  });

  group('efeito da conferência', () {
    setUp(signIn);

    test('conta confirmada atualiza o perfil e mantém conectada', () async {
      validation.onValidate = () =>
          session.updateProfile(name: 'Maria Silva', email: 'maria@novo.com');

      expect(await useCase(), UserSessionStatus.authenticated);
      expect(session.userName, 'Maria Silva');
    });

    test('conta recusada encerra a sessão → unauthenticated', () async {
      validation.onValidate = session.expire;

      expect(await useCase(), UserSessionStatus.unauthenticated);
    });

    test('sem rede ou prazo esgotado mantém a sessão', () async {
      validation.onValidate = () async {};

      expect(await useCase(), UserSessionStatus.authenticated);
    });

    test('erro inesperado não sobe e devolve o estado atual (FR-008)', () async {
      validation.onValidate = () async => throw StateError('inesperado');

      expect(await useCase(), UserSessionStatus.authenticated);
    });
  });
}
