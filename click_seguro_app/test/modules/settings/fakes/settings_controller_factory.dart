import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_account_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_app_version_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/set_receive_alerts_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/settings_controller.dart';

import '../../../fakes/fake_app_info_service.dart';
import 'fake_account_repository.dart';
import 'fake_language_repository.dart';

/// `SettingsController` com os usecases reais sobre os fakes.
SettingsController buildSettingsController(
  FakeAccountRepository repository,
  UserSessionService session, {
  FakeAppInfoService? appInfo,
  FakeLanguageRepository? languages,
}) => SettingsController(
  getAccount: GetAccountUseCase(repository),
  getAppVersion: GetAppVersionUseCase(appInfo ?? FakeAppInfoService()),
  logout: LogoutUseCase(session),
  setReceiveAlerts: SetReceiveAlertsUseCase(repository),
  getLanguage: GetLanguageUseCase(languages ?? FakeLanguageRepository()),
  saveLanguage: SaveLanguageUseCase(languages ?? FakeLanguageRepository()),
);
