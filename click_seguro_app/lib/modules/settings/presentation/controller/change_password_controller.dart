import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/change_password_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:flutter/widgets.dart';

enum PasswordField { current, newPassword, confirmation }

enum PasswordFieldError {
  required,
  rulesNotMet,
  mismatch,
  wrongCurrent,
  samePassword,
}

/// [invalid] = erros nos campos; [failed] = falha em
/// [ChangePasswordController.saveFailure].
enum ChangePasswordResult { saved, invalid, failed }

/// Troca de senha (US2 de specs/013-configuracoes). Senhas só nos campos de
/// texto: nunca guardadas.
class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController({
    required ChangePasswordUseCase changePassword,
    required LogoutUseCase logout,
  }) : _changePassword = changePassword,
       _logout = logout {
    for (final field in PasswordField.values) {
      _watch(field);
    }
  }

  final ChangePasswordUseCase _changePassword;
  final LogoutUseCase _logout;

  late final Map<PasswordField, TextEditingController> _texts = {
    for (final field in PasswordField.values) field: TextEditingController(),
  };

  TextEditingController get current => _texts[PasswordField.current]!;
  TextEditingController get newPassword => _texts[PasswordField.newPassword]!;
  TextEditingController get confirmation => _texts[PasswordField.confirmation]!;

  final Set<PasswordField> _visible = {};

  bool isVisible(PasswordField field) => _visible.contains(field);

  void toggleVisibility(PasswordField field) {
    if (!_visible.remove(field)) _visible.add(field);
    _notify();
  }

  /// Campos já alterados (ou todos, depois de "Salvar"): só eles mostram
  /// erro, para a tela não abrir cheia de avisos.
  final Set<PasswordField> _touched = {};

  /// Erros que só o serviço sabe (senha atual errada, nova igual à atual);
  /// somem quando o campo muda.
  Map<PasswordField, PasswordFieldError> _serverErrors = const {};

  /// Erros por campo, recalculados a cada letra digitada (como na edição de
  /// dados do Perfil): aparecem depois de o campo ser alterado e somem quando
  /// ele fica válido.
  Map<PasswordField, PasswordFieldError> get errors {
    final Map<PasswordField, PasswordFieldError> live = _validate();
    return {
      for (final field in PasswordField.values)
        if (_serverErrors[field] ??
                (_touched.contains(field) ? live[field] : null)
            case final PasswordFieldError error)
          field: error,
    };
  }

  Set<PasswordRule> get rulesMet => PasswordPolicy.rulesMet(newPassword.text);

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Failure? _saveFailure;
  Failure? get saveFailure => _saveFailure;

  /// Só com o formulário todo válido: o botão fica desativado até lá.
  bool get canSave =>
      !_isSaving && _serverErrors.isEmpty && _validate().isEmpty;

  /// Algo digitado: sair pede confirmação.
  bool get hasInput => _texts.values.any((text) => text.text.isNotEmpty);

  bool _disposed = false;

  Future<ChangePasswordResult> save() async {
    if (_isSaving) return ChangePasswordResult.invalid;
    _touched.addAll(PasswordField.values);
    if (_validate().isNotEmpty || _serverErrors.isNotEmpty) {
      _notify();
      return ChangePasswordResult.invalid;
    }

    _isSaving = true;
    _saveFailure = null;
    _notify();
    final result = await _changePassword(
      currentPassword: current.text,
      newPassword: newPassword.text,
    );
    if (_disposed) return ChangePasswordResult.failed;
    _isSaving = false;
    final ChangePasswordResult outcome = result.fold((failure) {
      switch (failure) {
        case WrongCurrentPasswordFailure():
          _serverErrors = {
            PasswordField.current: PasswordFieldError.wrongCurrent,
          };
          return ChangePasswordResult.invalid;
        case SamePasswordFailure():
          _serverErrors = {
            PasswordField.newPassword: PasswordFieldError.samePassword,
          };
          return ChangePasswordResult.invalid;
        default:
          _saveFailure = failure;
          return ChangePasswordResult.failed;
      }
    }, (_) => ChangePasswordResult.saved);
    _notify();
    // A senha mudou, mas não deu para entrar com ela: a pessoa entra de novo
    // pelo login (R0).
    if (_saveFailure is PasswordChangedReloginFailure) await _logout();
    return outcome;
  }

  Map<PasswordField, PasswordFieldError> _validate() {
    final Map<PasswordField, PasswordFieldError> errors = {
      for (final MapEntry(:key, :value) in _texts.entries)
        if (value.text.isEmpty) key: PasswordFieldError.required,
    };
    if (newPassword.text.isNotEmpty &&
        !PasswordPolicy.isValid(newPassword.text)) {
      errors[PasswordField.newPassword] = PasswordFieldError.rulesNotMet;
    }
    if (confirmation.text.isNotEmpty && confirmation.text != newPassword.text) {
      errors[PasswordField.confirmation] = PasswordFieldError.mismatch;
    }
    return errors;
  }

  /// Ao mudar o texto (não só o cursor), marca o campo como alterado, tira o
  /// erro do serviço dele e atualiza erros, regras e botão.
  void _watch(PasswordField field) {
    final TextEditingController text = _texts[field]!;
    String last = text.text;
    text.addListener(() {
      if (text.text == last) return;
      last = text.text;
      _touched.add(field);
      if (_serverErrors.containsKey(field)) {
        _serverErrors = {..._serverErrors}..remove(field);
      }
      _notify();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final text in _texts.values) {
      text.dispose();
    }
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
