import 'package:click_seguro_app/modules/settings/domain/usecases/get_account_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_app_version_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/account_state.dart';
import 'package:flutter/foundation.dart';

/// Estado da tela de Configurações, um por abertura (data-model de
/// specs/013-configuracoes).
class SettingsController extends ChangeNotifier {
  SettingsController({
    required GetAccountUseCase getAccount,
    required GetAppVersionUseCase getAppVersion,
    required LogoutUseCase logout,
  }) : _getAccount = getAccount,
       _getAppVersion = getAppVersion,
       _logout = logout;

  final GetAccountUseCase _getAccount;
  final GetAppVersionUseCase _getAppVersion;
  final LogoutUseCase _logout;

  AccountState _account = const AccountLoading();
  AccountState get account => _account;

  String? _appVersion;

  /// Versão instalada; `null` até carregar.
  String? get appVersion => _appVersion;

  bool _loggingOut = false;
  bool _disposed = false;

  Future<void> load() async {
    await Future.wait([_loadAccount(), _loadVersion()]);
  }

  /// Também ao voltar da edição de dados: nome e foto podem ter mudado.
  Future<void> retryAccount() => _loadAccount();

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
