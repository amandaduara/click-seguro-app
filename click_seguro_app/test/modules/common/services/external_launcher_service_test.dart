import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('isOpenableWebUrl', () {
    test('aceita endereços http e https completos', () {
      expect(isOpenableWebUrl('https://www.gov.br/noticia'), isTrue);
      expect(isOpenableWebUrl('http://exemplo.com'), isTrue);
    });

    test('recusa vazio, sem esquema, outros esquemas e sem host', () {
      for (final url in [
        '',
        '   ',
        'www.gov.br',
        'ftp://exemplo.com',
        'mailto:a@b.com',
        'javascript:alert(1)',
        'https://',
        '::nao é url',
      ]) {
        expect(isOpenableWebUrl(url), isFalse, reason: url);
      }
    });
  });

  group('normalizePhoneNumber', () {
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
  });

  group('UrlLauncherExternalLauncherService', () {
    late List<(Uri, LaunchMode)> launched;
    late List<Uri> checked;
    late bool launchResult;
    late bool canLaunchResult;
    late bool failLaunch;
    late bool failCanLaunch;
    late UrlLauncherExternalLauncherService service;

    setUp(() {
      launched = [];
      checked = [];
      launchResult = true;
      canLaunchResult = true;
      failLaunch = false;
      failCanLaunch = false;
      service = UrlLauncherExternalLauncherService(
        launch: (url, {mode = LaunchMode.platformDefault}) async {
          launched.add((url, mode));
          if (failLaunch) throw Exception('falha simulada');
          return launchResult;
        },
        canLaunch: (url) async {
          checked.add(url);
          if (failCanLaunch) throw Exception('falha simulada');
          return canLaunchResult;
        },
      );
    });

    group('openUrl', () {
      test('abre no navegador do aparelho, fora do app', () async {
        expect(await service.openUrl('https://www.gov.br'), isTrue);

        expect(launched.single.$1, Uri.parse('https://www.gov.br'));
        expect(launched.single.$2, LaunchMode.externalApplication);
      });

      test('endereço inválido → false sem tentar abrir', () async {
        expect(await service.openUrl('www.gov.br'), isFalse);
        expect(await service.openUrl(''), isFalse);

        expect(launched, isEmpty);
      });

      test('aparelho não abre ou lança → false', () async {
        launchResult = false;
        expect(await service.openUrl('https://www.gov.br'), isFalse);

        failLaunch = true;
        expect(await service.openUrl('https://www.gov.br'), isFalse);
      });
    });

    group('call', () {
      test('abre o discador só com os dígitos', () async {
        expect(await service.call('(11) 9 1234-5678'), isTrue);

        expect(launched.single.$1, Uri(scheme: 'tel', path: '11912345678'));
      });

      test('número sem dígitos → false sem tentar ligar', () async {
        expect(await service.call('()- '), isFalse);

        expect(launched, isEmpty);
      });

      test('falha ao abrir o discador → false', () async {
        failLaunch = true;

        expect(await service.call('190'), isFalse);
      });
    });

    group('canCall', () {
      test('repassa se existe discador', () async {
        expect(await service.canCall(), isTrue);
        expect(checked.single.scheme, 'tel');

        canLaunchResult = false;
        expect(await service.canCall(), isFalse);
      });

      test('exceção → false', () async {
        failCanLaunch = true;

        expect(await service.canCall(), isFalse);
      });
    });
  });
}
