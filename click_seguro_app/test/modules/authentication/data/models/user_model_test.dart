import 'package:click_seguro_app/modules/authentication/data/models/user_model.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const json = {
    'name': 'Maria Silva',
    'email': 'maria@exemplo.com',
    'phone': null,
    'avatarUrl': null,
    'role': 'USER',
    'receiveNotifications': true,
  };

  test('converte o corpo do /users/me em entidade', () {
    final user = UserModel.fromJson(json).toEntity();

    expect(user.name, 'Maria Silva');
    expect(user.email, 'maria@exemplo.com');
    expect(user.phone, isNull);
    expect(user.avatarUrl, isNull);
    expect(user.role, UserRole.user);
  });

  test('papéis conhecidos e desconhecido', () {
    UserRole roleOf(String role) =>
        UserModel.fromJson({...json, 'role': role}).toEntity().role;

    expect(roleOf('PUBLISHER'), UserRole.publisher);
    expect(roleOf('ADMIN'), UserRole.admin);
    expect(roleOf('XYZ'), UserRole.unknown);
  });

  test('sem nome lança TypeError', () {
    expect(
      () => UserModel.fromJson({...json}..remove('name')),
      throwsA(isA<TypeError>()),
    );
  });
}
