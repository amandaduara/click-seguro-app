import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/entities/user_entity.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/login_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

/// Estado da tela de login (data-model.md da feature 003).
class AuthenticationController extends ChangeNotifier {
  AuthenticationController({required LoginUseCase login}) : _login = login;

  final LoginUseCase _login;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Map<AuthField, FieldError> _fieldErrors = const {};
  Map<AuthField, FieldError> get fieldErrors => _fieldErrors;

  Failure? _failure;
  Failure? get failure => _failure;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  /// `true` depois de entrar; a página navega e chama [reset].
  bool _authenticated = false;
  bool get authenticated => _authenticated;

  Future<void> submit({required String email, required String password}) =>
      _run(() => _login(email: email, password: password));

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void reset() {
    _isSubmitting = false;
    _fieldErrors = const {};
    _failure = null;
    _isPasswordVisible = false;
    _authenticated = false;
    notifyListeners();
  }

  /// Ignora toques enquanto um envio está em andamento (FR-006).
  Future<void> _run(
    Future<Either<Failure, UserEntity>> Function() action,
  ) async {
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
    if (failure is InvalidFormFailure) {
      _fieldErrors = failure.fieldErrors;
    } else {
      _failure = failure;
    }
  }
}
