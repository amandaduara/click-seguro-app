import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:flutter/foundation.dart';

class HelpController extends ChangeNotifier {
  HelpController({
    required GetOfficialContactsUseCase getOfficialContacts,
    required GetPersonalContactsUseCase getPersonalContacts,
    required ExternalLauncherService launcher,
  }) : _getOfficialContacts = getOfficialContacts,
       _getPersonalContacts = getPersonalContacts,
       _launcher = launcher;

  final GetOfficialContactsUseCase _getOfficialContacts;
  final GetPersonalContactsUseCase _getPersonalContacts;
  final ExternalLauncherService _launcher;
  bool _disposed = false;
  bool _isLoading = false;
  Failure? _officialFailure;
  Failure? _personalFailure;
  String? _fallbackPhone;
  List<ContactEntity> _officialContacts = [];
  List<ContactEntity> _personalContacts = [];

  bool get isLoading => _isLoading;
  Failure? get officialFailure => _officialFailure;
  Failure? get personalFailure => _personalFailure;
  String? get fallbackPhone => _fallbackPhone;
  List<ContactEntity> get officialContacts =>
      List.unmodifiable(_officialContacts);
  List<ContactEntity> get personalContacts =>
      List.unmodifiable(_personalContacts);

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _officialFailure = null;
    _personalFailure = null;
    _notify();
    final results = await Future.wait([
      _getOfficialContacts(),
      _getPersonalContacts(),
    ]);
    if (_disposed) return;
    final official = results[0];
    final personal = results[1];
    official.match(
      (failure) => _officialFailure = failure,
      (contacts) => _officialContacts = contacts,
    );
    personal.match(
      (failure) => _personalFailure = failure,
      (contacts) => _personalContacts = contacts,
    );
    _isLoading = false;
    _notify();
  }

  Future<void> refresh() => load();

  Future<bool> call(ContactEntity contact) async {
    _fallbackPhone = null;
    var opened = false;
    try {
      opened = await _launcher.canCall() && await _launcher.call(contact.phone);
    } catch (_) {
      opened = false;
    }
    if (!opened && !_disposed) {
      _fallbackPhone = contact.phone;
      _notify();
    }
    return opened;
  }

  void clearFallbackPhone() {
    _fallbackPhone = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
