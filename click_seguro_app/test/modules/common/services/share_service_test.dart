import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

/// Menu de compartilhamento falso, com resultado configurável.
class _FakeSharePlus extends Fake implements SharePlus {
  final List<ShareParams> received = [];
  ShareResultStatus status = ShareResultStatus.success;
  bool fail = false;

  @override
  Future<ShareResult> share(ShareParams params) async {
    received.add(params);
    if (fail) throw Exception('falha simulada');
    return ShareResult('', status);
  }
}

void main() {
  late _FakeSharePlus sharePlus;
  late SharePlusShareService service;

  setUp(() {
    sharePlus = _FakeSharePlus();
    service = SharePlusShareService(sharePlus);
  });

  test('abre o menu com o texto e o assunto', () async {
    await service.shareText('Golpe do Pix', subject: 'Click Seguro');

    expect(sharePlus.received.single.text, 'Golpe do Pix');
    expect(sharePlus.received.single.subject, 'Click Seguro');
  });

  test('escolheu um app → compartilhado', () async {
    expect(await service.shareText('texto'), ShareOutcome.shared);
  });

  test('menu abriu sem informar a escolha → compartilhado', () async {
    sharePlus.status = ShareResultStatus.unavailable;

    expect(await service.shareText('texto'), ShareOutcome.shared);
  });

  test('fechou o menu → cancelado', () async {
    sharePlus.status = ShareResultStatus.dismissed;

    expect(await service.shareText('texto'), ShareOutcome.cancelled);
  });

  test('falha do aparelho → falhou', () async {
    sharePlus.fail = true;

    expect(await service.shareText('texto'), ShareOutcome.failed);
  });

  test('texto vazio → falhou sem abrir o menu', () async {
    expect(await service.shareText(''), ShareOutcome.failed);
    expect(await service.shareText('  '), ShareOutcome.failed);

    expect(sharePlus.received, isEmpty);
  });
}
