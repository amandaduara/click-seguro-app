import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;
  late UserSessionService session;
  late UpdateProfileUseCase useCase;

  const ProfileEntity original = ProfileEntity(
    name: 'Maria da Silva',
    email: 'maria@exemplo.com',
    phone: '+5511912345678',
  );

  setUp(() async {
    repository = FakeProfileRepository();
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'maria@exemplo.com',
      userName: 'Maria da Silva',
    );
    useCase = UpdateProfileUseCase(repository, session);
  });

  Future<Either<Failure, ProfileEntity>> save({
    String name = 'Maria da Silva',
    String email = 'maria@exemplo.com',
    String phone = '(11) 91234-5678',
  }) => useCase(original: original, name: name, email: email, phone: phone);

  test('envia só o nome quando só ele mudou', () async {
    await save(name: '  Maria Souza ');

    expect(repository.updateCalls, hasLength(1));
    final ProfileUpdate sent = repository.updateCalls.single;
    expect((sent.name, sent.email, sent.phone), ('Maria Souza', null, null));
  });

  test('e-mail vai sem espaços e em minúsculas', () async {
    await save(email: ' Maria@Novo.com ');

    expect(repository.updateCalls.single.email, 'maria@novo.com');
    expect(repository.updateCalls.single.name, isNull);
  });

  test('telefone normalizado com +55', () async {
    await save(phone: '(11) 3456-7890');

    expect(repository.updateCalls.single.phone, '+551134567890');
  });

  test('nada mudou → não chama o serviço e devolve o original', () async {
    final result = await save(email: 'MARIA@exemplo.com ');

    expect(repository.updateCalls, isEmpty);
    expect(result.getRight().toNullable(), original);
  });

  test('sucesso → sessão e profileVersion atualizados', () async {
    final int version = session.profileVersion.value;

    final result = await save(name: 'Maria Souza', email: 'maria@novo.com');

    expect(session.userName, 'Maria Souza');
    expect(session.email, 'maria@novo.com');
    expect(session.profileVersion.value, version + 1);
    final ProfileEntity saved = result.getRight().toNullable()!;
    expect(
      (saved.name, saved.email, saved.phone),
      ('Maria Souza', 'maria@novo.com', '+5511912345678'),
    );
  });

  test('falha → sessão intacta', () async {
    repository.updateResults[0] = const Left(ServerFailure());

    final result = await save(name: 'Maria Souza');

    expect(result.isLeft(), isTrue);
    expect(session.userName, 'Maria da Silva');
  });
}
