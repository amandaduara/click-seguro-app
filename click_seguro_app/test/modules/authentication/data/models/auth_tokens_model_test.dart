import 'package:click_seguro_app/modules/authentication/data/models/auth_tokens_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê o par de tokens', () {
    final tokens = AuthTokensModel.fromJson({
      'accessToken': 'acesso-1',
      'refreshToken': 'renovacao-1',
    });

    expect(tokens.accessToken, 'acesso-1');
    expect(tokens.refreshToken, 'renovacao-1');
  });

  test('token vazio ou ausente lança', () {
    expect(
      () => AuthTokensModel.fromJson({
        'accessToken': '',
        'refreshToken': 'renovacao-1',
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => AuthTokensModel.fromJson({'accessToken': 'acesso-1'}),
      throwsA(isA<TypeError>()),
    );
  });
}
