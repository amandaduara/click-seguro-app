import 'package:package_info_plus/package_info_plus.dart';

/// Dados do app instalado (versão em "Sobre o Click Seguro", specs/013 R7).
abstract class AppInfoService {
  /// Ex.: `1.0.0`. Não lança: sem a informação, devolve `''`.
  Future<String> version();
}

/// Implementação com `package_info_plus`.
class PackageInfoAppInfoService implements AppInfoService {
  PackageInfoAppInfoService({Future<PackageInfo> Function()? load})
    : _load = load ?? PackageInfo.fromPlatform;

  final Future<PackageInfo> Function() _load;

  @override
  Future<String> version() async {
    try {
      return (await _load()).version;
    } catch (_) {
      return '';
    }
  }
}
