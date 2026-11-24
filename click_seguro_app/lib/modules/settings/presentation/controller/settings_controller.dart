import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_account_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_app_version_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/set_receive_alerts_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/account_state.dart';
import 'package:flutter/foundation.dart';

/// Estado da tela de Configurações, um por abertura (data-model de
/// specs/013-configuracoes). Sem conta, só o que é do aparelho
/// ([loadDeviceSettings], R6 de specs/014-acessibilidade).
class SettingsController extends ChangeNotifier {
  SettingsController({
    required GetAccountUseCase getAccount,
    required GetAppVersionUseCase getAppVersion,
    required LogoutUseCase logout,
    required SetReceiveAlertsUseCase setReceiveAlerts,
    required GetLanguageUseCase getLanguage,
    required SaveLanguageUseCase saveLanguage,
  }) : _getAccount = getAccount,
       _getAppVersion = getAppVersion,
       _logout = logout,
       _setReceiveAlerts = setReceiveAlerts,
       _getLanguage = getLanguage,
       _saveLanguage = saveLanguage;

  final GetAccountUseCase _getAccount;
  final GetAppVersionUseCase _getAppVersion;
  final LogoutUseCase _logout;
  final SetReceiveAlertsUseCase _setReceiveAlerts;
  final GetLanguageUseCase _getLanguage;
  final SaveLanguageUseCase _saveLanguage;

  LanguageChoice _language = LanguageChoice.device;

  /// Escolha guardada; a página aplica no `easy_localization` (R5).
  LanguageChoice get language => _language;

  AccountState _account = const AccountLoading();
  AccountState get account => _account;

  String? _appVersion;

  /// Versão instalada; `null` até carregar.
  String? get appVersion => _appVersion;

  bool _isSavingAlerts = false;

  /// A chave de alertas fica parada até a resposta.
  bool get isSavingAlerts => _isSavingAlerts;

  /// Valor que a pessoa escolheu para os alertas e não foi salvo (falha);
  /// `null` = nada pendente. [retryAlerts] reenvia este valor.
  bool? _pendingAlertsValue;

  /// Salvar a escolha dos alertas falhou.
  bool get alertsSaveFailed => _pendingAlertsValue != null;

  Failure? _alertsSaveFailure;

  /// A falha que a linha dos alertas mostra (specs/027): a da conta que não
  /// carregou (a linha diz "não carregou") ou, sem ela, a do último salvar
  /// que falhou.
  Failure? get alertsFailure => switch (_account) {
    AccountFailed(:final failure) => failure,
    _ => _alertsSaveFailure,
  };

  bool _isRetryingAlerts = false;

  /// [retryAlerts] em andamento: a tela mostra o carregamento no lugar do
  /// botão de tentar de novo.
  bool get isRetryingAlerts => _isRetryingAlerts;

  /// A conta não carregou: a chave de alertas dá lugar ao tentar de novo.
  bool get alertsLoadFailed => _account is AccountFailed;

  /// A conta não carregou ou salvar os alertas falhou.
  bool get _alertsNeedRetry => alertsSaveFailed || alertsLoadFailed;

  bool _loggingOut = false;
  bool _disposed = false;

  Future<void> load() async {
    await Future.wait([_loadAccount(), loadDeviceSettings()]);
  }

  /// Versão e idioma, sem pedido ao serviço (RN-003): o que o visitante vê.
  Future<void> loadDeviceSettings() async {
    await Future.wait([_loadVersion(), _loadLanguage()]);
  }

  /// Também ao voltar da edição de dados: nome e foto podem ter mudado.
  Future<void> retryAccount() => _loadAccount();

  /// Muda a chave na hora e salva; em falha, volta ao valor anterior, guarda
  /// o valor pedido em [_pendingAlertsValue] e devolve a falha (FR-016).
  /// Durante o envio, novos toques são ignorados.
  Future<Failure?> setReceiveAlerts(bool value) async {
    final AccountState current = _account;
    if (current is! AccountLoaded || _isSavingAlerts) return null;
    _account = AccountLoaded(current.account.withReceiveNotifications(value));
    _isSavingAlerts = true;
    _notify();
    final result = await _setReceiveAlerts(value);
    if (_disposed) return null;
    _isSavingAlerts = false;
    final Failure? failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) _account = current;
    _pendingAlertsValue = failure == null ? null : value;
    _alertsSaveFailure = failure;
    _notify();
    return failure;
  }

  /// Refaz o que falhou nos alertas: recarrega a conta, se ela não veio, e
  /// reenvia o valor de [_pendingAlertsValue], se salvar falhou. Durante o
  /// pedido, [isRetryingAlerts] fica ligado.
  Future<void> retryAlerts() async {
    if (_isRetryingAlerts || _isSavingAlerts || !_alertsNeedRetry) return;
    _isRetryingAlerts = true;
    _notify();
    if (alertsLoadFailed) await _loadAccount();
    final bool? pending = _pendingAlertsValue;
    if (!_disposed && pending != null) await setReceiveAlerts(pending);
    if (_disposed) return;
    _isRetryingAlerts = false;
    _notify();
  }

  Future<void> setLanguage(LanguageChoice choice) async {
    _language = choice;
    _notify();
    await _saveLanguage(choice);
  }

  /// Sai da conta uma vez só, mesmo com toque duplo.
  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    await _logout();
  }

  Future<void> _loadAccount() async {
    final result = await _getAccount();
    if (_disposed) return;
    _account = result.fold(AccountFailed.new, AccountLoaded.new);
    _notify();
  }

  Future<void> _loadVersion() async {
    final String version = await _getAppVersion();
    if (_disposed) return;
    _appVersion = version;
    _notify();
  }

  Future<void> _loadLanguage() async {
    final LanguageChoice language = await _getLanguage();
    if (_disposed) return;
    _language = language;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
