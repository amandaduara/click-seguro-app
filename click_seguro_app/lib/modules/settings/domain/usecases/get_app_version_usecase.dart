import 'package:click_seguro_app/modules/common/services/app_info_service.dart';

class GetAppVersionUseCase {
  GetAppVersionUseCase(this._appInfo);

  final AppInfoService _appInfo;

  /// Ex.: `1.0.0`; vazio quando não dá para ler.
  Future<String> call() => _appInfo.version();
}
