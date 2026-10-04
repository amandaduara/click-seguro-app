import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/enter_as_guest_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/evaluate_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/login_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/register_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

enum AuthMode { login, register }

/// Estado da tela de login (data-model.md da feature 003).
class AuthenticationController extends ChangeNotifier {
  AuthenticationController({
    required LoginUseCase login,
    required RegisterUseCase register,
    required EvaluatePasswordUseCase evaluatePassword,
    required EnterAsGuestUseCase enterAsGuest,
  }) : _login = login,
       _register = register,
       _evaluatePassword = evaluatePassword,
       _enterAsGuest = enterAsGuest;

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final EvaluatePasswordUseCase _evaluatePassword;
  final EnterAsGuestUseCase _enterAsGuest;

  AuthMode _mode = AuthMode.login;
  AuthMode get mode => _mode;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Map<AuthField, FieldError> _fieldErrors = const {};
  Map<AuthField, FieldError> get fieldErrors => _fieldErrors;

  Failure? _failure;
  Failure? get failure => _failure;

  Set<PasswordRule> _passwordRules = const {};
  Set<PasswordRule> get passwordRules => _passwordRules;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  /// `true` depois de entrar; a página navega e chama [reset].
  bool _authenticated = false;
  bool get authenticated => _authenticated;

  /// Troca entre entrar e criar conta, limpando os erros do outro modo
  /// (FR-002). O texto digitado fica na página.
  void setMode(AuthMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _fieldErrors = const {};
    _failure = null;
    notifyListeners();
  }

  void onPasswordChanged(String password) {
    _passwordRules = Set.unmodifiable(_evaluatePassword(password));
    notifyListeners();
  }

  Future<void> submit({
    String name = '',
    required String email,
    required String password,
  }) => _run(
    () => _mode == AuthMode.login
        ? _login(email: email, password: password)
        : _register(name: name, email: email, password: password),
  );

  /// "Continuar sem login" (FR-010).
  Future<void> continueAsGuest() => _run(_enterAsGuest.call);

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void reset() {
    _mode = AuthMode.login;
    _isSubmitting = false;
    _fieldErrors = const {};
    _failure = null;
    _passwordRules = const {};
    _isPasswordVisible = false;
    _authenticated = false;
    notifyListeners();
  }

  /// Ignora toques enquanto um envio está em andamento (FR-006).
  Future<void> _run(Future<Either<Failure, Object>> Function() action) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    _fieldErrors = const {};
    _failure = null;
    notifyListeners();

    final result = await action();

    _isSubmitting = false;
    result.match(_applyFailure, (_) => _authenticated = true);
    notifyListeners();
  }

  void _applyFailure(Failure failure) {
    switch (failure) {
      case InvalidFormFailure(:final fieldErrors):
        _fieldErrors = fieldErrors;
      case AccountCreatedFailure():
        // A conta existe: volta ao "Entrar" com o aviso (FR-009).
        _mode = AuthMode.login;
        _failure = failure;
      default:
        _failure = failure;
    }
  }
}
