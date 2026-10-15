import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_account_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_app_version_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/set_receive_alerts_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/account_state.dart';
import 'package:flutter/foundation.dart';

/// Estado da tela de Configurações, um por abertura (data-model de
/// specs/013-configuracoes).
class SettingsController extends ChangeNotifier {
  SettingsController({
    required GetAccountUseCase getAccount,
    required GetAppVersionUseCase getAppVersion,
    required LogoutUseCase logout,
    required SetReceiveAlertsUseCase setReceiveAlerts,
  }) : _getAccount = getAccount,
       _getAppVersion = getAppVersion,
       _logout = logout,
       _setReceiveAlerts = setReceiveAlerts;

  final GetAccountUseCase _getAccount;
  final GetAppVersionUseCase _getAppVersion;
  final LogoutUseCase _logout;
  final SetReceiveAlertsUseCase _setReceiveAlerts;

  AccountState _account = const AccountLoading();
  AccountState get account => _account;

  String? _appVersion;

  /// Versão instalada; `null` até carregar.
  String? get appVersion => _appVersion;

  bool _isSavingAlerts = false;

  /// A chave de alertas fica parada até a resposta.
  bool get isSavingAlerts => _isSavingAlerts;

  bool _loggingOut = false;
  bool _disposed = false;

  Future<void> load() async {
    await Future.wait([_loadAccount(), _loadVersion()]);
  }

  /// Também ao voltar da edição de dados: nome e foto podem ter mudado.
  Future<void> retryAccount() => _loadAccount();

  /// Muda a chave na hora e salva; em falha, volta ao valor anterior e
  /// devolve a falha (FR-016). Durante o envio, novos toques são ignorados.
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
    _notify();
    return failure;
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
