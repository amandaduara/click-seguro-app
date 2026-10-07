import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';

/// Abrir endereço e ligar sem tocar no aparelho, para testes.
class FakeExternalLauncherService implements ExternalLauncherService {
  /// Resposta de [canCall] (`false` simula tablet sem discador, CB-009).
  bool canCallResult = true;

  /// Resposta de [openUrl] e [call].
  bool openResult = true;

  final List<String> openedUrls = [];
  final List<String> calledNumbers = [];

  @override
  Future<bool> openUrl(String url) async {
    openedUrls.add(url);
    return openResult;
  }

  @override
  Future<bool> canCall() async => canCallResult;

  @override
  Future<bool> call(String phoneNumber) async {
    calledNumbers.add(phoneNumber);
    return openResult;
  }
}
