import 'package:click_seguro_app/modules/common/services/share_service.dart';

/// Compartilhamento sem abrir o menu do aparelho, para testes.
class FakeShareService implements ShareService {
  /// Resultado de [shareText].
  ShareOutcome outcome = ShareOutcome.shared;

  final List<({String text, String? subject})> shared = [];

  @override
  Future<ShareOutcome> shareText(String text, {String? subject}) async {
    shared.add((text: text, subject: subject));
    return outcome;
  }
}
