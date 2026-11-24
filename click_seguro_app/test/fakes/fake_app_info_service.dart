import 'package:click_seguro_app/modules/common/services/app_info_service.dart';

/// Versão do app sem plataforma, para testes.
class FakeAppInfoService implements AppInfoService {
  FakeAppInfoService([this.installedVersion = '1.0.0']);

  String installedVersion;

  @override
  Future<String> version() async => installedVersion;
}
