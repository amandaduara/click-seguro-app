import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/delete_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/save_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:flutter/foundation.dart';

class ContactFormController extends ChangeNotifier {
  ContactFormController({
    required this.getPersonalContacts,
    required this.savePersonalContact,
    required this.deletePersonalContact,
    required this.images,
    String? contactId,
  }) : contactId = contactId,
       id = contactId ?? _newId();

  static int _idSequence = 0;
  static String _newId() =>
      'contact_${DateTime.now().microsecondsSinceEpoch}_${_idSequence++}';

  final String? contactId;
  final String id;
  final GetPersonalContactsUseCase getPersonalContacts;
  final SavePersonalContactUseCase savePersonalContact;
  final DeletePersonalContactUseCase deletePersonalContact;
  final ImageStorageService images;
  bool _disposed = false;
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  bool _photoLoading = false;
  bool _permissionDenied = false;
  bool _notFound = false;
  bool _saveInFlight = false;
  String _name = '';
  String _phone = '';
  String _relationship = '';
  String? _photoPath;
  String? _temporaryPhotoPath;
  ContactValidationError? _validationError;
  Failure? _loadFailure;
  Failure? _saveFailure;
  Failure? _deleteFailure;

  bool get isEditing => contactId != null;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  bool get isDeleting => _deleting;
  bool get isPhotoLoading => _photoLoading;
  bool get permissionDenied => _permissionDenied;
  bool get notFound => _notFound;
  String get name => _name;
  String get phone => _phone;
  String get relationship => _relationship;
  String? get photoPath => _photoPath;
  ContactValidationError? get validationError => _validationError;
  Failure? get loadFailure => _loadFailure;
  Failure? get saveFailure => _saveFailure;
  Failure? get deleteFailure => _deleteFailure;

  Future<void> load() async {
    if (!isEditing || _loading) return;
    _loading = true;
    _loadFailure = null;
    _notFound = false;
    _notify();
    final result = await getPersonalContacts();
    if (_disposed) return;
    result.match((failure) => _loadFailure = failure, (contacts) {
      ContactEntity? contact;
      for (final item in contacts) {
        if (item.id == contactId) {
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
    _validationError = null;
    _saveFailure = null;
    _notify();
  }

  void setPhone(String value) {
    _phone = value;
    _validationError = null;
    _saveFailure = null;
    _notify();
  }

  void setRelationship(String value) {
    _relationship = value;
    _saveFailure = null;
    _notify();
  }

  Future<void> pickPhoto(PhotoSource source) async {
    if (_photoLoading || _saving || _deleting) return;
    _photoLoading = true;
    _permissionDenied = false;
    _notify();
    final result = await images.pickImage(source);
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
    if (_photoLoading || _saving || _deleting) return;
    final temporary = _temporaryPhotoPath;
    _temporaryPhotoPath = null;
    _photoPath = null;
    if (temporary != null) await _deleteImage(temporary);
    _notify();
  }

  Future<bool> save() async {
    if (_saving ||
        _photoLoading ||
        _deleting ||
        _loading ||
        _notFound ||
        _loadFailure != null) {
      return false;
    }
    final nameError = ContactValidation.validateName(_name);
    if (nameError != null) {
      _validationError = nameError;
      _notify();
      return false;
    }
    final phoneError = ContactValidation.validatePhone(_phone);
    if (phoneError != null) {
      _validationError = phoneError;
      _notify();
      return false;
    }
    _saving = true;
    _saveInFlight = true;
    _validationError = null;
    _saveFailure = null;
    _notify();
    final result = await savePersonalContact(
      ContactEntity(
        id: id,
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
      result.match((failure) => _saveFailure = failure, (_) {});
      if (_disposed && temporaryPhoto != null) {
        _temporaryPhotoPath = null;
        await _deleteImage(temporaryPhoto);
      }
    }
    _saveInFlight = false;
    if (_disposed) return result.isRight();
    _saving = false;
    _notify();
    return result.isRight();
  }

  Future<bool> delete() async {
    if (!isEditing ||
        _deleting ||
        _saving ||
        _photoLoading ||
        _loading ||
        _loadFailure != null ||
        _notFound) {
      return false;
    }
    final id = contactId;
    if (id == null) return false;
    _deleting = true;
    _deleteFailure = null;
    _notify();
    final result = await deletePersonalContact(id);
    if (_disposed) return false;
    result.match((failure) => _deleteFailure = failure, (_) {});
    _deleting = false;
    _notify();
    return result.isRight();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _deleteImage(String path) async {
    try {
      await images.delete(path);
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    final temporary = _temporaryPhotoPath;
    if (!_saveInFlight) {
      _temporaryPhotoPath = null;
      if (temporary != null) unawaited(_deleteImage(temporary));
    }
    super.dispose();
  }
}
