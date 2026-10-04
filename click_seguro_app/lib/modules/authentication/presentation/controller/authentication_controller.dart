import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/enter_as_guest_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/evaluate_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/login_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/register_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/validate_auth_form_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

enum AuthMode { login, register }

/// Estado da tela de login (data-model.md da feature 003).
class AuthenticationController extends ChangeNotifier {
  AuthenticationController({
    required LoginUseCase login,
    required RegisterUseCase register,
    required EvaluatePasswordUseCase evaluatePassword,
    required ValidateAuthFormUseCase validateForm,
    required EnterAsGuestUseCase enterAsGuest,
  }) : _login = login,
       _register = register,
       _evaluatePassword = evaluatePassword,
       _validateForm = validateForm,
       _enterAsGuest = enterAsGuest;

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final EvaluatePasswordUseCase _evaluatePassword;
  final ValidateAuthFormUseCase _validateForm;
  final EnterAsGuestUseCase _enterAsGuest;

  AuthMode _mode = AuthMode.login;
  AuthMode get mode => _mode;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  // Valores atuais do formulário e erros calculados enquanto a pessoa digita.
  String _name = '';
  String _email = '';
  String _password = '';
  Map<AuthField, FieldError> _formErrors = _initialErrors;
  Set<AuthField> _touched = const {};

  static const Map<AuthField, FieldError> _initialErrors = {
    AuthField.email: FieldError.required,
    AuthField.password: FieldError.required,
  };

  /// Erros dos campos que a pessoa já deixou (ou de todos, depois de tentar
  /// enviar). Enquanto digita pela primeira vez, nada é marcado.
  Map<AuthField, FieldError> get fieldErrors => Map.unmodifiable({
    for (final MapEntry(:key, :value) in _formErrors.entries)
      if (_touched.contains(key)) key: value,
  });

  /// Botão principal habilitado só com tudo válido (no cadastro, a senha
  /// cumprindo as 5 regras) e fora de um envio.
  bool get canSubmit => _formErrors.isEmpty && !_isSubmitting;

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
  /// (FR-002). O texto digitado fica na página; o formulário é reavaliado.
  void setMode(AuthMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _touched = const {};
    _failure = null;
    _revalidate();
    notifyListeners();
  }

  /// Chamado a cada digitação.
  void updateForm({
    String name = '',
    required String email,
    required String password,
  }) {
    _setForm(name, email, password);
    notifyListeners();
  }

  void _setForm(String name, String email, String password) {
    _name = name;
    _email = email;
    _password = password;
    _passwordRules = Set.unmodifiable(_evaluatePassword(password));
    _revalidate();
  }

  /// A pessoa saiu do campo: passa a mostrar o erro dele, se houver.
  void markTouched(AuthField field) {
    if (_touched.contains(field)) return;
    _touched = Set.unmodifiable({..._touched, field});
    notifyListeners();
  }

  /// Envia com os valores informados. Com o formulário inválido (ex.: "OK"
  /// no teclado), não chama o serviço e marca todos os campos (SC-004).
  Future<void> submit({
    String name = '',
    required String email,
    required String password,
  }) {
    _setForm(name, email, password);
    if (_formErrors.isNotEmpty) {
      _touched = Set.unmodifiable(_formErrors.keys);
      notifyListeners();
      return Future.value();
    }
    return _run(
      () => _mode == AuthMode.login
          ? _login(email: _email, password: _password)
          : _register(name: _name, email: _email, password: _password),
    );
  }

  /// "Continuar sem login" (FR-010).
  Future<void> continueAsGuest() => _run(_enterAsGuest.call);

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void reset() {
    _mode = AuthMode.login;
    _isSubmitting = false;
    _name = '';
    _email = '';
    _password = '';
    _formErrors = _initialErrors;
    _touched = const {};
    _failure = null;
    _passwordRules = const {};
    _isPasswordVisible = false;
    _authenticated = false;
    notifyListeners();
  }

  void _revalidate() {
    _formErrors = _validateForm(
      registration: _mode == AuthMode.register,
      name: _name,
      email: _email,
      password: _password,
    );
  }

  /// Ignora toques enquanto um envio está em andamento (FR-006).
  Future<void> _run(Future<Either<Failure, Object>> Function() action) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
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
        // Não deveria ocorrer (o formulário já foi validado), mas se o
        // usecase recusar, os campos ficam marcados.
        _formErrors = fieldErrors;
        _touched = Set.unmodifiable(fieldErrors.keys);
      case AccountCreatedFailure():
        // A conta existe: volta ao "Entrar" com o aviso (FR-009).
        _mode = AuthMode.login;
        _failure = failure;
        _revalidate();
      default:
        _failure = failure;
    }
  }
}
