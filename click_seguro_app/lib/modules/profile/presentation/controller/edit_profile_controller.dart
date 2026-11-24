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
import 'package:click_seguro_app/core/utils/phone_format.dart';
import 'package:flutter/widgets.dart';

enum EditProfileStatus { loading, ready, error }

/// O que acontece com a foto agora.
enum PhotoState { idle, uploading, removing }

/// Resultado de "Salvar": [invalid] = erros nos campos (inclusive e-mail em
/// uso); [failed] = falha do serviço, em [EditProfileController.saveFailure].
enum EditSaveResult { saved, invalid, failed }

/// Campos de texto da edição.
enum ProfileField { name, email, phone }

/// Pré-carrega a foto nova no cache da imagem (precisa da tela).
typedef PrepareAvatarImage = Future<void> Function(String url);

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
    _watch(ProfileField.name, name);
    _watch(ProfileField.email, email);
    _watch(ProfileField.phone, phone);
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

  /// Campos já alterados (ou todos, depois de "Salvar"): só eles mostram
  /// erro, para a tela não abrir cheia de avisos.
  final Set<ProfileField> _touched = {};

  /// Erro que só o serviço sabe (e-mail em uso); some quando o e-mail muda.
  ProfileFieldError? _emailServerError;

  /// Os campos estão sendo preenchidos pelo perfil, não pela pessoa.
  bool _filling = false;

  /// Erros por campo, recalculados a cada letra digitada (como na troca de
  /// senha): aparecem depois de o campo ser alterado e somem quando ele fica
  /// válido.
  ProfileFieldErrors get errors {
    final ProfileEntity? original = _original;
    if (original == null) return const ProfileFieldErrors();
    final ProfileFieldErrors live = ProfileFormValidator.validate(
      name: name.text,
      email: email.text,
      phone: phone.text,
      hadPhone: original.phone != null,
    );
    ProfileFieldError? shown(ProfileField field, ProfileFieldError? error) =>
        _touched.contains(field) ? error : null;
    return ProfileFieldErrors(
      name: shown(ProfileField.name, live.name),
      email: _emailServerError ?? shown(ProfileField.email, live.email),
      phone: shown(ProfileField.phone, live.phone),
    );
  }

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

  /// Com mudança e sem erro à vista: o botão fica desativado até lá.
  bool get canSave => hasChanges && !_isSaving && errors.isEmpty;

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

    _touched.addAll(ProfileField.values);
    if (!errors.isEmpty) {
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
          _emailServerError = ProfileFieldError.emailInUse;
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
  ///
  /// Enviada a foto, ainda com o carregamento, busca o perfil de novo (o
  /// Perfil o mostra ao voltar, sem outra busca) e pré-carrega a imagem nova
  /// com [prepareImage]; o carregamento só sai quando tudo termina, e a
  /// foto do Perfil já está pronta.
  Future<AvatarUpdateOutcome> pickPhoto(
    PhotoSource source, {
    PrepareAvatarImage? prepareImage,
  }) async {
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
      await _refreshForProfile(avatarUrl, prepareImage);
      if (_disposed) return outcome;
      _original = _original?.withAvatarUrl(avatarUrl);
    }
    _localPhotoPath = null;
    _photoState = PhotoState.idle;
    _notify();
    return outcome;
  }

  /// Remove a foto; as iniciais aparecem na hora. `null` = removida. O
  /// repositório já tira a foto do perfil guardado: o Perfil volta sem ela.
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

  /// Busca o perfil (o Perfil passa a ter a foto nova) e, junto, pré-carrega
  /// [uploadedUrl]; se a busca trouxer outro endereço, pré-carrega também.
  /// Falhas não desfazem a troca: o Perfil busca de novo ao voltar.
  ///
  /// O repositório já guarda [uploadedUrl] no perfil, mas a busca continua:
  /// o servidor pode devolver a foto em outro endereço (ex.: outra versão),
  /// e é esse que o Perfil mostra; sem pré-carregá-lo, a foto piscaria.
  Future<void> _refreshForProfile(
    String uploadedUrl,
    PrepareAvatarImage? prepareImage,
  ) async {
    final (reloaded, _) = await (
      _getProfile(),
      prepareImage?.call(uploadedUrl) ?? Future<void>.value(),
    ).wait;
    final String? reloadedUrl = reloaded.getRight().toNullable()?.avatarUrl;
    if (_disposed || reloadedUrl == null || reloadedUrl == uploadedUrl) return;
    await prepareImage?.call(reloadedUrl);
  }

  /// Os campos passam a mostrar [profile], que vira o original; nenhum
  /// campo conta como alterado.
  void _fill(ProfileEntity profile) {
    _original = profile;
    _filling = true;
    name.text = profile.name;
    email.text = profile.email;
    phone.text = profile.phone == null ? '' : formatPhone(profile.phone!);
    _filling = false;
    _touched.clear();
    _emailServerError = null;
  }

  /// Ao mudar o texto (não só o cursor), marca o campo como alterado, tira o
  /// erro do serviço dele e atualiza erros e botão.
  void _watch(ProfileField field, TextEditingController text) {
    String last = text.text;
    text.addListener(() {
      if (text.text == last) return;
      last = text.text;
      if (_filling) return;
      _touched.add(field);
      if (field == ProfileField.email) _emailServerError = null;
      _notify();
    });
  }

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
