import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nome é trimado e exige conteúdo', () {
    expect(ContactValidation.validateName('  Ana  '), isNull);
    expect(ContactValidation.validateName('  '), ContactValidationError.name);
  });

  test('telefone aceita formatação e + inicial com 3 a 15 dígitos', () {
    expect(ContactValidation.normalizePhone('+55 (11) 99999-1234'), isNotNull);
    expect(ContactValidation.normalizePhone('123'), isNotNull);
    expect(ContactValidation.normalizePhone('12'), isNull);
    expect(ContactValidation.normalizePhone('1234567890123456'), isNull);
    expect(ContactValidation.normalizePhone('11abc222'), isNull);
    expect(ContactValidation.normalizePhone('11+222'), isNull);
  });
}
