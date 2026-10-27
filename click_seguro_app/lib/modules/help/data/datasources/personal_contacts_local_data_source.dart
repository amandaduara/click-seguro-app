import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';

class PersonalContactsLocalDataSource {
  PersonalContactsLocalDataSource(this._cache, this._images);

  static const String cacheKey = 'help_personal_contacts_v1';

  final LocalCacheService _cache;
  final ImageStorageService _images;

  Future<List<ContactModel>> read() async {
    final record = await _cache.readJson(cacheKey);
    if (record == null) return [];
    final items = record['contacts'];
    if (items is! List) throw const FormatException('Invalid contacts cache');
    return [
      for (final value in items)
        if (value is Map<String, dynamic>) ContactModel.fromJson(value),
    ];
  }

  Future<void> save(ContactModel contact) async {
    final contacts = await read();
    final oldIndex = contacts.indexWhere((item) => item.id == contact.id);
    final previous = oldIndex < 0 ? null : contacts[oldIndex];
    final updated = [...contacts];
    if (oldIndex < 0) {
      updated.add(contact);
    } else {
      updated[oldIndex] = contact;
    }

    await _write(updated);
    final oldPath = previous?.photoPath;
    if (oldPath != null && oldPath != contact.photoPath) {
      await _deleteImage(oldPath);
    }
  }

  Future<void> delete(String id) async {
    final contacts = await read();
    ContactModel? removed;
    for (final contact in contacts) {
      if (contact.id == id) {
        removed = contact;
        break;
      }
    }
    if (removed == null) return;
    await _write(contacts.where((contact) => contact.id != id).toList());
    final photoPath = removed.photoPath;
    if (photoPath != null) await _deleteImage(photoPath);
  }

  Future<void> _write(List<ContactModel> contacts) async {
    final record = {
      'contacts': [for (final contact in contacts) contact.toJson()],
    };
    await _cache.writeJson(cacheKey, record);
  }

  Future<void> _deleteImage(String path) async {
    await _images.delete(path);
  }
}
