import 'package:click_seguro_app/modules/profile/domain/validators/profile_form_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProfileFieldErrors validate({
    String name = 'Maria da Silva',
    String email = 'maria@exemplo.com',
    String phone = '',
    bool hadPhone = false,
  }) => ProfileFormValidator.validate(
    name: name,
    email: email,
    phone: phone,
    hadPhone: hadPhone,
  );

  test('dados válidos → sem erros', () {
    expect(validate().isEmpty, isTrue);
    expect(validate(phone: '(11) 91234-5678').isEmpty, isTrue);
  });

  group('nome', () {
    test('5 e 151 caracteres (sem os espaços das pontas) → erro', () {
      expect(validate(name: '  Maria  ').name, ProfileFieldError.nameLength);
      expect(validate(name: 'a' * 151).name, ProfileFieldError.nameLength);
    });

    test('6 e 150 → ok', () {
      expect(validate(name: ' Marian ').name, isNull);
      expect(validate(name: 'a' * 150).name, isNull);
    });
  });

  group('e-mail', () {
    for (final email in ['maria', 'maria@', 'maria@exemplo', '@exemplo.com']) {
      test('"$email" → erro', () {
        expect(validate(email: email).email, ProfileFieldError.emailInvalid);
      });
    }

    test('espaços nas pontas e maiúsculas → ok', () {
      expect(validate(email: ' Maria@Exemplo.com ').email, isNull);
    });
  });

  group('normalizePhone', () {
    for (final (input, expected) in [
      ('(11) 91234-5678', '+5511912345678'),
      ('+55 11 3456-7890', '+551134567890'),
      ('11912345678', '+5511912345678'),
      ('5511912345678', '+5511912345678'),
      ('1234', null),
      ('', null),
      ('(11) 91234-56789', null),
    ]) {
      test('"$input" → $expected', () {
        expect(ProfileFormValidator.normalizePhone(input), expected);
      });
    }
  });

  group('telefone', () {
    test('vazio sem telefone salvo → ok', () {
      expect(validate(phone: '  ').phone, isNull);
    });

    test('vazio com telefone salvo → phoneRequired', () {
      expect(validate(hadPhone: true).phone, ProfileFieldError.phoneRequired);
    });

    test('inválido → phoneInvalid', () {
      expect(validate(phone: '1234').phone, ProfileFieldError.phoneInvalid);
    });
  });
}
