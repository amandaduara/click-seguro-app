import 'package:click_seguro_app/core/utils/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mantém só os dígitos e o + inicial', () {
    expect(normalizePhoneNumber('(11) 9 1234-5678'), '11912345678');
    expect(normalizePhoneNumber('+55 (11) 91234-5678'), '+5511912345678');
    expect(normalizePhoneNumber('190'), '190');
    expect(normalizePhoneNumber('1+2'), '12');
  });

  test('sem dígitos → null', () {
    expect(normalizePhoneNumber(''), isNull);
    expect(normalizePhoneNumber('()- '), isNull);
    expect(normalizePhoneNumber('+'), isNull);
  });
}
