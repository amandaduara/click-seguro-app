import 'package:click_seguro_app/core/utils/phone_format.dart';
import 'package:flutter_test/flutter_test.dart';

String _type(PhoneInputFormatter formatter, String text) => formatter
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
    .text;

void main() {
  group('formatPhone (perfil)', () {
    test('celular, fixo e parcial', () {
      expect(formatPhone('11912345678'), '(11) 91234-5678');
      expect(formatPhone('1123456789'), '(11) 2345-6789');
      expect(formatPhone('119123'), '(11) 9123');
      expect(formatPhone('1'), '(1');
    });

    test('com +55, tira o código do país', () {
      expect(formatPhone('+5511912345678'), '(11) 91234-5678');
    });
  });

  // Contatos de confiança (validação da usuária, specs/024): números curtos
  // de emergência e 0800 também valem.
  group('formatPhone com números curtos (contatos)', () {
    test('até 3 dígitos fica como está: 190, 192', () {
      expect(formatPhone('190', shortCodes: true), '190');
      expect(formatPhone('19', shortCodes: true), '19');
    });

    test('0800 em blocos', () {
      expect(formatPhone('08007284567', shortCodes: true), '0800 728 4567');
      expect(formatPhone('080072', shortCodes: true), '0800 72');
    });

    test('a partir do 4º dígito, a máscara de sempre', () {
      expect(formatPhone('1191', shortCodes: true), '(11) 91');
      expect(formatPhone('11912345678', shortCodes: true), '(11) 91234-5678');
    });

    test('letras e símbolos saem; passa de 11 dígitos, corta', () {
      expect(
        formatPhone('11a9b1234-5678999', shortCodes: true),
        '(11) 91234-5678',
      );
    });
  });

  // A validação de contato aceita internacional (+ e 8 a 15 dígitos): o +
  // fica e o número não recebe a máscara do Brasil.
  group('formatPhone internacional (contatos)', () {
    test('contato salvo +14155550123 aparece inteiro, com o +', () {
      expect(formatPhone('+14155550123', shortCodes: true), '+14155550123');
    });

    test('limite de 15 dígitos', () {
      expect(
        formatPhone('+1234567890123456789', shortCodes: true),
        '+123456789012345',
      );
    });

    test('+55 continua com a máscara do Brasil', () {
      expect(
        formatPhone('+5511912345678', shortCodes: true),
        '(11) 91234-5678',
      );
    });

    test('só o +, ou + com poucos dígitos, fica como está', () {
      expect(formatPhone('+', shortCodes: true), '+');
      expect(formatPhone('+1', shortCodes: true), '+1');
      expect(formatPhone('+5', shortCodes: true), '+5');
    });

    test('sem números curtos (perfil), o + continua sumindo', () {
      expect(formatPhone('+14155550123'), '(14) 15555-0123');
    });
  });

  group('PhoneInputFormatter', () {
    test('formata enquanto digita e põe o cursor no fim', () {
      const formatter = PhoneInputFormatter(shortCodes: true);
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '11912345678'),
      );

      expect(value.text, '(11) 91234-5678');
      expect(value.selection.baseOffset, value.text.length);
      expect(_type(formatter, '190'), '190');
    });

    test('digitar +14155550123 mantém o + e todos os dígitos', () {
      const formatter = PhoneInputFormatter(shortCodes: true);
      expect(_type(formatter, '+14155550123'), '+14155550123');
      expect(_type(formatter, '+1 415-555'), '+1415555');
    });
  });
}
