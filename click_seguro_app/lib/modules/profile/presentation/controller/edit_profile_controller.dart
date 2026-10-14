import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/avatar_update_outcome.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/remove_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/validators/profile_form_validator.dart';
import 'package:click_seguro_app/modules/profile/presentation/extensions/phone_format.dart';
import 'package:flutter/widgets.dart';

enum EditProfileStatus { loading, ready, error }

/// O que acontece com a foto agora.
enum PhotoState { idle, uploading, removing }

/// Resultado de "Salvar": [invalid] = erros nos campos (inclusive e-mail em
/// uso); [failed] = falha do serviço, em [EditProfileController.saveFailure].
enum EditSaveResult { saved, invalid, failed }

/// Rascunho da edição de dados (data-model de specs/012-perfil, R5): os
/// textos dos campos, os erros por campo e o envio só do que mudou.
class EditProfileController extends ChangeNotifier {
  EditProfileController({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
    required UpdateAvatarUseCase updateAvatar,
    required RemoveAvatarUseCase removeAvatar,
  }) : _getProfile = getProfile,
       _updateProfile = updateProfile,
       _updateAvatar = updateAvatar,
       _removeAvatar = removeAvatar {
    _watch(name, () => _errors = _without(name: true));
    _watch(email, () => _errors = _without(email: true));
    _watch(phone, () => _errors = _without(phone: true));
  }

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final UpdateAvatarUseCase _updateAvatar;
  final RemoveAvatarUseCase _removeAvatar;

  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();

  /// Com a máscara "(11) 91234-5678".
  final TextEditingController phone = TextEditingController();

  EditProfileStatus _status = EditProfileStatus.loading;
  EditProfileStatus get status => _status;

  Failure? _failure;

  /// Por que o perfil não carregou ([EditProfileStatus.error]).
  Failure? get failure => _failure;

  ProfileEntity? _original;

  /// Perfil como está salvo (foto e iniciais do topo).
  ProfileEntity? get profile => _original;

  ProfileFieldErrors _errors = const ProfileFieldErrors();
  ProfileFieldErrors get errors => _errors;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Failure? _saveFailure;
  Failure? get saveFailure => _saveFailure;

  PhotoState _photoState = PhotoState.idle;
  PhotoState get photoState => _photoState;

  String? _localPhotoPath;

  /// Cópia da foto escolhida, mostrada enquanto é enviada.
  String? get localPhotoPath => _localPhotoPath;

  /// Foto salva; some na hora ao remover e volta se a remoção falhar.
  String? get avatarUrl =>
      _photoState == PhotoState.removing ? null : _original?.avatarUrl;

  bool _disposed = false;

  /// Algum campo diferente do salvo, comparado já normalizado (espaços,
  /// maiúsculas do e-mail, máscara do telefone).
  bool get hasChanges {
    final ProfileEntity? original = _original;
    if (original == null) return false;
    final String phoneText = phone.text.trim();
    final String? phoneDraft = phoneText.isEmpty
        ? null
        : ProfileFormValidator.normalizePhone(phoneText) ?? phoneText;
    return name.text.trim() != original.name ||
        email.text.trim().toLowerCase() != original.email.toLowerCase() ||
        phoneDraft != original.phone;
  }

  bool get canSave => hasChanges && !_isSaving;

  Future<void> load() async {
    _status = EditProfileStatus.loading;
    _notify();
    final result = await _getProfile();
    if (_disposed) return;
    result.fold(
      (failure) {
        _failure = failure;
        _status = EditProfileStatus.error;
      },
      (loaded) {
        _fill(loaded);
        _status = EditProfileStatus.ready;
      },
    );
    _notify();
  }

  Future<EditSaveResult> save() async {
    final ProfileEntity? original = _original;
    if (original == null || _isSaving) return EditSaveResult.invalid;

    _errors = ProfileFormValidator.validate(
      name: name.text,
      email: email.text,
      phone: phone.text,
      hadPhone: original.phone != null,
    );
    if (!_errors.isEmpty) {
      _notify();
      return EditSaveResult.invalid;
    }

    _isSaving = true;
    _saveFailure = null;
    _notify();
    final result = await _updateProfile(
      original: original,
      name: name.text,
      email: email.text,
      phone: phone.text,
    );
    if (_disposed) return EditSaveResult.failed;
    _isSaving = false;
    final EditSaveResult outcome = result.fold(
      (failure) {
        if (failure is EmailInUseFailure) {
          _errors = const ProfileFieldErrors(
            email: ProfileFieldError.emailInUse,
          );
          return EditSaveResult.invalid;
        }
        _saveFailure = failure;
        return EditSaveResult.failed;
      },
      (saved) {
        _fill(saved);
        return EditSaveResult.saved;
      },
    );
    _notify();
    return outcome;
  }

  /// Troca a foto (R7): a cópia local aparece na hora; em falha, volta a
  /// anterior. A foto vai direto ao serviço, sem esperar "Salvar".
  Future<AvatarUpdateOutcome> pickPhoto(PhotoSource source) async {
    if (_photoState != PhotoState.idle) return const AvatarPickCancelled();
    final AvatarUpdateOutcome outcome = await _updateAvatar(
      source,
      onPicked: (path) {
        _localPhotoPath = path;
        _photoState = PhotoState.uploading;
        _notify();
      },
    );
    if (_disposed) return outcome;
    if (outcome case AvatarUpdated(:final avatarUrl)) {
      _original = _original?.withAvatarUrl(avatarUrl);
    }
    _localPhotoPath = null;
    _photoState = PhotoState.idle;
    _notify();
    return outcome;
  }

  /// Remove a foto; as iniciais aparecem na hora. `null` = removida.
  Future<Failure?> removePhoto() async {
    if (_photoState != PhotoState.idle) return null;
    _photoState = PhotoState.removing;
    _notify();
    final result = await _removeAvatar();
    if (_disposed) return null;
    _photoState = PhotoState.idle;
    final Failure? failure = result.fold((failure) => failure, (_) {
      _original = _original?.withAvatarUrl(null);
      return null;
    });
    _notify();
    return failure;
  }

  /// Os campos passam a mostrar [profile], que vira o original.
  void _fill(ProfileEntity profile) {
    _original = profile;
    name.text = profile.name;
    email.text = profile.email;
    phone.text = profile.phone == null ? '' : formatPhone(profile.phone!);
  }

  /// Ao mudar o texto de [field] (não só o cursor), tira o erro dele e
  /// recalcula [canSave].
  void _watch(TextEditingController field, VoidCallback clearError) {
    String last = field.text;
    field.addListener(() {
      if (field.text == last) return;
      last = field.text;
      clearError();
      _notify();
    });
  }

  ProfileFieldErrors _without({
    bool name = false,
    bool email = false,
    bool phone = false,
  }) => ProfileFieldErrors(
    name: name ? null : _errors.name,
    email: email ? null : _errors.email,
    phone: phone ? null : _errors.phone,
  );

  @override
  void dispose() {
    _disposed = true;
    name.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
