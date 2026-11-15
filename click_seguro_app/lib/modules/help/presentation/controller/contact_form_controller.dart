import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/failures/contact_validation_failure.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/save_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:flutter/foundation.dart';

class ContactFormController extends ChangeNotifier {
  ContactFormController({
    required GetPersonalContactsUseCase getPersonalContacts,
    required SavePersonalContactUseCase savePersonalContact,
    required ImageStorageService images,
    String? contactId,
  }) : _contactId = contactId,
       _getPersonalContacts = getPersonalContacts,
       _savePersonalContact = savePersonalContact,
       _images = images,
       _id = contactId ?? _newId(),
       // Editando, o formulário só aparece com o contato carregado.
       _loading = contactId != null;

  static int _idSequence = 0;
  static String _newId() =>
      'contact_${DateTime.now().microsecondsSinceEpoch}_${_idSequence++}';

  final String? _contactId;
  final String _id;
  final GetPersonalContactsUseCase _getPersonalContacts;
  final SavePersonalContactUseCase _savePersonalContact;
  final ImageStorageService _images;
  bool _disposed = false;
  bool _loading;
  bool _saving = false;
  bool _photoLoading = false;
  bool _permissionDenied = false;
  bool _notFound = false;
  String _name = '';
  String _phone = '';
  String _relationship = '';
  String? _photoPath;
  String? _temporaryPhotoPath;
  Failure? _loadFailure;
  Failure? _saveFailure;

  bool get isEditing => _contactId != null;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  bool get isPhotoLoading => _photoLoading;
  bool get permissionDenied => _permissionDenied;
  bool get notFound => _notFound;
  String get name => _name;
  String get phone => _phone;
  String get relationship => _relationship;
  String? get photoPath => _photoPath;

  /// A pessoa já mexeu no campo (digitou, saiu dele ou tentou salvar): daí
  /// em diante o erro acompanha a digitação (validação da usuária,
  /// specs/024).
  bool _nameTouched = false;
  bool _phoneTouched = false;

  /// Erro do nome para mostrar agora; `null` antes de tocar no campo.
  ContactValidationError? get nameError =>
      _nameTouched ? ContactValidation.validateName(_name) : null;

  /// Erro do telefone para mostrar agora; `null` antes de tocar no campo.
  ContactValidationError? get phoneError =>
      _phoneTouched && ContactValidation.normalizePhone(_phone) == null
      ? ContactValidationError.phone
      : null;

  /// "Salvar contato" disponível só com nome e telefone válidos e nada em
  /// andamento, como na edição de perfil (validação da usuária, specs/024).
  bool get canSave =>
      !_saving &&
      !_photoLoading &&
      !_loading &&
      !_notFound &&
      _loadFailure == null &&
      ContactValidation.validateName(_name) == null &&
      ContactValidation.normalizePhone(_phone) != null;

  void touchName() {
    if (_nameTouched) return;
    _nameTouched = true;
    _notify();
  }

  void touchPhone() {
    if (_phoneTouched) return;
    _phoneTouched = true;
    _notify();
  }

  Failure? get loadFailure => _loadFailure;
  Failure? get saveFailure => _saveFailure;

  Future<void> load() async {
    if (!isEditing) return;
    _loading = true;
    _loadFailure = null;
    _notFound = false;
    _notify();
    final result = await _getPersonalContacts();
    if (_disposed) return;
    result.match((failure) => _loadFailure = failure, (contacts) {
      ContactEntity? contact;
      for (final item in contacts) {
        if (item.id == _contactId) {
          contact = item;
          break;
        }
      }
      if (contact == null) {
        _notFound = true;
      } else {
        _name = contact.name;
        _phone = contact.phone;
        _relationship = contact.relationship ?? '';
        _photoPath = contact.photoPath;
      }
    });
    _loading = false;
    _notify();
  }

  void setName(String value) {
    _name = value;
    // O erro acompanha a digitação (validação da usuária, specs/024).
    _nameTouched = true;
    _saveFailure = null;
    _notify();
  }

  void setPhone(String value) {
    _phone = value;
    _phoneTouched = true;
    _saveFailure = null;
    _notify();
  }

  void setRelationship(String value) {
    _relationship = value;
    _saveFailure = null;
    _notify();
  }

  Future<void> pickPhoto(PhotoSource source) async {
    if (_photoLoading || _saving) return;
    _photoLoading = true;
    _permissionDenied = false;
    _notify();
    final result = await _images.pickImage(source);
    if (_disposed) {
      if (result is PickedImage) await _deleteImage(result.path);
      return;
    }
    if (result is PickedImage) {
      final previousTemporary = _temporaryPhotoPath;
      _temporaryPhotoPath = result.path;
      _photoPath = result.path;
      if (previousTemporary != null && previousTemporary != result.path) {
        await _deleteImage(previousTemporary);
      }
    } else if (result is PickImagePermissionDenied) {
      _permissionDenied = true;
    }
    _photoLoading = false;
    _notify();
  }

  Future<void> removePhoto() async {
    if (_photoLoading || _saving) return;
    final temporary = _temporaryPhotoPath;
    _temporaryPhotoPath = null;
    _photoPath = null;
    if (temporary != null) await _deleteImage(temporary);
    _notify();
  }

  Future<bool> save() async {
    if (_saving ||
        _photoLoading ||
        _loading ||
        _notFound ||
        _loadFailure != null) {
      return false;
    }
    _saving = true;
    _saveFailure = null;
    _notify();
    final result = await _savePersonalContact(
      ContactEntity(
        id: _id,
        name: _name,
        phone: _phone,
        type: ContactType.personal,
        relationship: _relationship,
        photoPath: _photoPath,
      ),
    );
    final temporaryPhoto = _temporaryPhotoPath;
    if (result.isRight()) {
      _temporaryPhotoPath = null;
    } else {
      // Nome ou telefone inválido: o usecase valida, o campo mostra o erro.
      result.match((failure) {
        if (failure is ContactValidationFailure) {
          // Mostra todos os campos inválidos, não só o primeiro.
          _nameTouched = true;
          _phoneTouched = true;
        } else {
          _saveFailure = failure;
        }
      }, (_) {});
      if (_disposed && temporaryPhoto != null) {
        _temporaryPhotoPath = null;
        await _deleteImage(temporaryPhoto);
      }
    }
    if (_disposed) return result.isRight();
    _saving = false;
    _notify();
    return result.isRight();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _deleteImage(String path) async {
    await _images.delete(path);
  }

  @override
  void dispose() {
    _disposed = true;
    final temporary = _temporaryPhotoPath;
    if (!_saving) {
      _temporaryPhotoPath = null;
      if (temporary != null) unawaited(_deleteImage(temporary));
    }
    super.dispose();
  }
}
