import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/delete_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:flutter/foundation.dart';

class HelpController extends ChangeNotifier {
  HelpController({
    required GetOfficialContactsUseCase getOfficialContacts,
    required GetPersonalContactsUseCase getPersonalContacts,
    required DeletePersonalContactUseCase deletePersonalContact,
    required ExternalLauncherService launcher,
  }) : _getOfficialContacts = getOfficialContacts,
       _getPersonalContacts = getPersonalContacts,
       _deletePersonalContact = deletePersonalContact,
       _launcher = launcher;

  final GetOfficialContactsUseCase _getOfficialContacts;
  final GetPersonalContactsUseCase _getPersonalContacts;
  final DeletePersonalContactUseCase _deletePersonalContact;
  final ExternalLauncherService _launcher;
  bool _disposed = false;
  bool _isLoading = false;
  Failure? _officialFailure;
  Failure? _personalFailure;
  List<ContactEntity> _officialContacts = [];
  List<ContactEntity> _personalContacts = [];

  /// Contatos sendo removidos agora (a lixeira mostra o carregamento).
  final Set<String> _deleting = {};

  bool get isLoading => _isLoading;

  bool isDeleting(String id) => _deleting.contains(id);
  Failure? get officialFailure => _officialFailure;
  Failure? get personalFailure => _personalFailure;
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

  /// Remove um contato pessoal pela lixeira do cartão (validação da
  /// usuária, specs/024). Devolve a falha, ou `null` quando removeu.
  Future<Failure?> deleteContact(String id) async {
    if (_deleting.contains(id)) return null;
    _deleting.add(id);
    _notify();
    final result = await _deletePersonalContact(id);
    if (_disposed) return null;
    _deleting.remove(id);
    final Failure? failure = result.match((failure) => failure, (_) {
      _personalContacts = [
        for (final contact in _personalContacts)
          if (contact.id != id) contact,
      ];
      return null;
    });
    _notify();
    return failure;
  }

  Future<bool> call(ContactEntity contact) => callNumber(contact.phone);

  /// Liga para um número, como os contatos (FR-016 de specs/024: o cartão
  /// "Caiu em um golpe?"). `false` quando não há discador ou ele não abre.
  Future<bool> callNumber(String phone) async {
    return await _launcher.canCall() && await _launcher.call(phone);
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
