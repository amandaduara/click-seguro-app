import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/presentation/extensions/auth_presentation_extension.dart';
import 'package:click_seguro_app/modules/common/presentation/extensions/password_rule_presentation.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada FieldError tem uma chave própria', () {
    final keys = FieldError.values.map((e) => e.messageKey).toList();

    expect(keys, everyElement(startsWith('auth_field_')));
    expect(keys.toSet(), hasLength(FieldError.values.length));
  });

  test('cada PasswordRule tem uma chave própria', () {
    final keys = PasswordRule.values.map((r) => r.labelKey).toList();

    expect(keys, everyElement(startsWith('auth_rule_')));
    expect(keys.toSet(), hasLength(PasswordRule.values.length));
  });
}
