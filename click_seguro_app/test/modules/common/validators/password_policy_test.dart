import 'package:click_seguro_app/modules/common/validators/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strong = 'Senha@123';

  group('rulesMet', () {
    test('só minúsculas atende só lowercase', () {
      expect(PasswordPolicy.rulesMet('abc'), {PasswordRule.lowercase});
    });

    test('senha forte atende todas', () {
      expect(PasswordPolicy.rulesMet(strong), PasswordRule.values.toSet());
    });

    test('8 e 64 caracteres atendem length; 7 e 65 não', () {
      expect(
        PasswordPolicy.rulesMet('Ab@1234'),
        isNot(contains(PasswordRule.length)),
      );
      expect(
        PasswordPolicy.rulesMet('Ab@12345'),
        contains(PasswordRule.length),
      );
      expect(
        PasswordPolicy.rulesMet('Ab@1${'x' * 60}'),
        contains(PasswordRule.length),
      );
      expect(
        PasswordPolicy.rulesMet('Ab@1${'x' * 61}'),
        isNot(contains(PasswordRule.length)),
      );
    });

    for (final (password, missing) in [
      ('senha@123', PasswordRule.uppercase),
      ('SENHA@123', PasswordRule.lowercase),
      ('Senha@abc', PasswordRule.digit),
      ('Senha1234', PasswordRule.special),
    ]) {
      test('"$password" não atende ${missing.name}', () {
        expect(PasswordPolicy.rulesMet(password), isNot(contains(missing)));
      });
    }

    test('espaço conta como caractere especial', () {
      expect(PasswordPolicy.rulesMet('a b'), contains(PasswordRule.special));
    });
  });

  group('isValid', () {
    test('todas as regras → true', () {
      expect(PasswordPolicy.isValid(strong), isTrue);
    });

    test('faltando uma → false', () {
      expect(PasswordPolicy.isValid('Senha1234'), isFalse);
      expect(PasswordPolicy.isValid(''), isFalse);
    });

    test('espaços nas pontas contam (sem trim)', () {
      expect(PasswordPolicy.isValid(' Senha12'), isTrue);
    });
  });
}
