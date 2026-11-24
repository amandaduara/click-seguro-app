import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nome é trimado e exige conteúdo', () {
    expect(ContactValidation.validateName('  Ana  '), isNull);
    expect(ContactValidation.validateName('  '), ContactValidationError.name);
  });

  test('nome aceita até 60 caracteres e recusa mais', () {
    expect(ContactValidation.nameMaxLength, 60);
    expect(ContactValidation.validateName('a' * 60), isNull);
    expect(ContactValidation.validateName(' ${'a' * 60} '), isNull);
    expect(
      ContactValidation.validateName('a' * 61),
      ContactValidationError.name,
    );
  });

  test('telefone aceita formatação e + inicial', () {
    expect(ContactValidation.normalizePhone('+55 (11) 99999-1234'), isNotNull);
    expect(ContactValidation.normalizePhone('11abc222'), isNull);
    expect(ContactValidation.normalizePhone('11+222'), isNull);
  });

  // Número incompleto não passa (validação da usuária, specs/024): só
  // números curtos de 3 dígitos, 0800 completo, fixo/celular com DDD (10 ou
  // 11 dígitos) ou internacional com + (8 a 15 dígitos).
  test('telefone completo: curto, 0800, fixo, celular e internacional', () {
    expect(ContactValidation.normalizePhone('190'), '190');
    expect(ContactValidation.normalizePhone('0800 728 4567'), '08007284567');
    expect(ContactValidation.normalizePhone('(11) 2345-6789'), '1123456789');
    expect(ContactValidation.normalizePhone('(11) 91234-5678'), '11912345678');
    expect(ContactValidation.normalizePhone('+1 202 555 0143'), '+12025550143');
  });

  test('telefone incompleto ou longo demais: inválido', () {
    for (final String phone in [
      '12',
      '1234',
      '(12) 123',
      '(11) 9123-456',
      '0800 728',
      '119123456789',
      '+1234567',
      '+1234567890123456',
    ]) {
      expect(ContactValidation.normalizePhone(phone), isNull, reason: phone);
    }
  });
}
