import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/change_password_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../fakes/fake_account_repository.dart';

void main() {
  late FakeAccountRepository repository;
  late ChangePasswordUseCase useCase;

  setUp(() {
    repository = FakeAccountRepository();
    useCase = ChangePasswordUseCase(repository);
  });

  test('nova senha fora da regra → WeakPasswordFailure, sem pedido', () async {
    final result = await useCase(
      currentPassword: 'Senha@123',
      newPassword: 'fraca',
    );

    expect(result.getLeft().toNullable(), isA<WeakPasswordFailure>());
    expect(repository.changeCalls, isEmpty);
  });

  test('válida → repassa as senhas sem trim', () async {
    final result = await useCase(
      currentPassword: ' Senha@123',
      newPassword: 'NovaSenha@456 ',
    );

    expect(result.isRight(), isTrue);
    expect(repository.changeCalls, [
      (current: ' Senha@123', newPassword: 'NovaSenha@456 '),
    ]);
  });

  test('falha do repository repassada', () async {
    repository.changeResults[0] = const Left(WrongCurrentPasswordFailure());

    final result = await useCase(
      currentPassword: 'Errada@123',
      newPassword: 'NovaSenha@456',
    );

    expect(result.getLeft().toNullable(), isA<WrongCurrentPasswordFailure>());
  });

  test('sem conexão repassada', () async {
    repository.changeResults[0] = const Left(ConnectionFailure());

    final result = await useCase(
      currentPassword: 'Senha@123',
      newPassword: 'NovaSenha@456',
    );

    expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
  });
}
