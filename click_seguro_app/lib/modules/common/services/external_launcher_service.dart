import 'package:url_launcher/url_launcher.dart';
import 'package:click_seguro_app/core/utils/phone_number.dart';

export 'package:click_seguro_app/core/utils/phone_number.dart' show normalizePhoneNumber;

const Set<String> _webSchemes = {'http', 'https'};
const String _phoneScheme = 'tel';

/// Endereço de página web completo (http/https com host). "www.site.com" sem
/// esquema não é aceito: as notícias trazem endereços completos da API.
bool isOpenableWebUrl(String url) {
  final Uri? uri = Uri.tryParse(url.trim());
  return uri != null && _webSchemes.contains(uri.scheme) && uri.host.isNotEmpty;
}

/// Abrir a notícia original no navegador e ligar pelo discador (RF-017,
/// RF-032).
///
/// Nenhum método lança: falhas viram `false` (CB-009, FR-017).
abstract class ExternalLauncherService {
  /// Abre http/https no navegador do aparelho. Vazio, malformado, outro
  /// esquema ou falha → false.
  Future<bool> openUrl(String url);

  /// Existe discador no aparelho. Erro → false (CB-009: a tela mostra o número
  /// para copiar).
  Future<bool> canCall();

  /// Abre o discador com o número já preenchido, sem completar a ligação.
  /// Sem dígitos ou falha → false.
  Future<bool> call(String phoneNumber);
}

/// Implementação com `url_launcher` (ver specs/007-servicos-plataforma-voz,
/// research R6).
class UrlLauncherExternalLauncherService implements ExternalLauncherService {
  UrlLauncherExternalLauncherService({
    Future<bool> Function(Uri url, {LaunchMode mode})? launch,
    Future<bool> Function(Uri url)? canLaunch,
  }) : _launch = launch ?? launchUrl,
       _canLaunch = canLaunch ?? canLaunchUrl;

  final Future<bool> Function(Uri url, {LaunchMode mode}) _launch;
  final Future<bool> Function(Uri url) _canLaunch;

  @override
  Future<bool> openUrl(String url) async {
    if (!isOpenableWebUrl(url)) return false;
    return _tryLaunch(Uri.parse(url.trim()), LaunchMode.externalApplication);
  }

  /// Um número qualquer: só importa se há quem abra `tel:`.
  @override
  Future<bool> canCall() async {
    try {
      return await _canLaunch(Uri(scheme: _phoneScheme, path: '0'));
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> call(String phoneNumber) async {
    final String? number = normalizePhoneNumber(phoneNumber);
    if (number == null) return false;
    return _tryLaunch(
      Uri(scheme: _phoneScheme, path: number),
      LaunchMode.platformDefault,
    );
  }

  Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await _launch(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}
