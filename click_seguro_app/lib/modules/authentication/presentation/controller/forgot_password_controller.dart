import 'dart:math' as math;

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/reset_step.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/evaluate_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/request_password_reset_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/reset_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/verify_reset_code_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

/// Recuperação de senha em três passos (RF-006, FR-012 a FR-016).
class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController({
    required RequestPasswordResetUseCase requestReset,
    required VerifyResetCodeUseCase verifyCode,
    required ResetPasswordUseCase resetPassword,
    required EvaluatePasswordUseCase evaluatePassword,
    DateTime Function()? now,
  }) : _requestReset = requestReset,
       _verifyCode = verifyCode,
       _resetPassword = resetPassword,
       _evaluatePassword = evaluatePassword,
       _now = now ?? DateTime.now;

  /// Espera entre dois envios do código (FR-015).
  static const Duration resendCooldown = Duration(seconds: 60);

  final RequestPasswordResetUseCase _requestReset;
  final VerifyResetCodeUseCase _verifyCode;
  final ResetPasswordUseCase _resetPassword;
  final EvaluatePasswordUseCase _evaluatePassword;
  final DateTime Function() _now;

  ResetStep _step = ResetStep.email;
  ResetStep get step => _step;

  String _email = '';
  String get email => _email;

  String _code = '';

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

  /// `true` depois de salvar a nova senha; a página volta ao login.
  bool _completed = false;
  bool get completed => _completed;

  DateTime? _lastCodeSentAt;

  /// Segundos até poder reenviar o código; 0 = já pode.
  int get secondsUntilResend {
    final sentAt = _lastCodeSentAt;
    if (sentAt == null) return 0;
    final elapsed = _now().difference(sentAt).inSeconds;
    return math.max(0, resendCooldown.inSeconds - elapsed);
  }

  void start(String? initialEmail) {
    _step = ResetStep.email;
    _email = initialEmail?.trim() ?? '';
    _code = '';
    _isSubmitting = false;
    _fieldErrors = const {};
    _failure = null;
    _passwordRules = const {};
    _isPasswordVisible = false;
    _completed = false;
    _lastCodeSentAt = null;
    notifyListeners();
  }

  Future<void> submitEmail(String email) => _run(
    () => _requestReset(email),
    onSuccess: () {
      _email = email.trim();
      _lastCodeSentAt = _now();
      _step = ResetStep.code;
    },
  );

  Future<void> resendCode() async {
    if (secondsUntilResend > 0) return;
    await _run(
      () => _requestReset(_email),
      onSuccess: () => _lastCodeSentAt = _now(),
    );
  }

  Future<void> submitCode(String code) => _run(
    () => _verifyCode(email: _email, code: code),
    onSuccess: () {
      _code = code.trim();
      _step = ResetStep.newPassword;
    },
  );

  Future<void> submitNewPassword({
    required String password,
    required String confirmation,
  }) => _run(
    () => _resetPassword(
      email: _email,
      code: _code,
      password: password,
      confirmation: confirmation,
    ),
    onSuccess: () => _completed = true,
  );

  void onPasswordChanged(String password) {
    _passwordRules = Set.unmodifiable(_evaluatePassword(password));
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  /// Volta um passo. Devolve `false` no primeiro, para a página fechar.
  bool back() {
    if (_step == ResetStep.email) return false;
    _step = ResetStep.values[_step.index - 1];
    _fieldErrors = const {};
    _failure = null;
    notifyListeners();
    return true;
  }

  Future<void> _run(
    Future<Either<Failure, Unit>> Function() action, {
    required VoidCallback onSuccess,
  }) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    _fieldErrors = const {};
    _failure = null;
    notifyListeners();

    final result = await action();

    _isSubmitting = false;
    result.match((failure) {
      if (failure is InvalidFormFailure) {
        _fieldErrors = failure.fieldErrors;
      } else {
        _failure = failure;
      }
    }, (_) => onSuccess());
    notifyListeners();
  }
}
