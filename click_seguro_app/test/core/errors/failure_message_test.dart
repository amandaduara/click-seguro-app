import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-006/FR-008 de specs/027-padrao-sem-internet: a falta de internet tem
/// sempre a mesma frase; as outras falhas ficam com o texto da tela.
void main() {
  const String fallback = 'texto_da_tela';

  test('falha de conexão dá a frase de sem internet', () {
    expect(
      const ConnectionFailure().messageKeyOr(fallback),
      AppStrings.errorConnection,
    );
  });

  test('outras falhas ficam com o texto da tela', () {
    expect(const ServerFailure().messageKeyOr(fallback), fallback);
    expect(const UnauthorizedFailure().messageKeyOr(fallback), fallback);
  });

  test('sem falha fica com o texto da tela', () {
    const Failure? none = null;
    expect(none.messageKeyOr(fallback), fallback);
  });
}
