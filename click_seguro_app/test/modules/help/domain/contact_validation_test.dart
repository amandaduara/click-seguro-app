import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nome é trimado e exige conteúdo', () {
    expect(ContactValidation.validateName('  Ana  '), isNull);
    expect(ContactValidation.validateName('  '), ContactValidationError.name);
  });

  test('telefone aceita formatação e + inicial com 3 a 15 dígitos', () {
    expect(ContactValidation.validatePhone('+55 (11) 99999-1234'), isNull);
    expect(ContactValidation.validatePhone('123'), isNull);
    expect(ContactValidation.validatePhone('12'), ContactValidationError.phone);
    expect(
      ContactValidation.validatePhone('1234567890123456'),
      ContactValidationError.phone,
    );
    expect(
      ContactValidation.validatePhone('11abc222'),
      ContactValidationError.phone,
    );
    expect(
      ContactValidation.validatePhone('11+222'),
      ContactValidationError.phone,
    );
  });
}
