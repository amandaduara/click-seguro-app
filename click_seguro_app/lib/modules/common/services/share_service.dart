import 'package:share_plus/share_plus.dart';

/// Resultado de abrir o menu de compartilhamento. [cancelled] não é erro.
enum ShareOutcome { shared, cancelled, failed }

/// Compartilhar uma notícia pelo menu do aparelho (RF-016).
///
/// Não lança: falhas viram [ShareOutcome.failed] (FR-017).
abstract class ShareService {
  /// Abre o menu nativo com [text] (e [subject] opcional). Texto vazio →
  /// [ShareOutcome.failed] sem abrir.
  Future<ShareOutcome> shareText(String text, {String? subject});
}

/// Implementação com `share_plus` (ver specs/007-servicos-plataforma-voz,
/// research R7).
class SharePlusShareService implements ShareService {
  SharePlusShareService([SharePlus? sharePlus])
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<ShareOutcome> shareText(String text, {String? subject}) async {
    if (text.trim().isEmpty) return ShareOutcome.failed;
    try {
      final ShareResult result = await _sharePlus.share(
        ShareParams(text: text, subject: subject),
      );
      return switch (result.status) {
        ShareResultStatus.success => ShareOutcome.shared,
        // O menu abriu, mas o sistema não informa o que a pessoa escolheu.
        ShareResultStatus.unavailable => ShareOutcome.shared,
        ShareResultStatus.dismissed => ShareOutcome.cancelled,
      };
    } catch (_) {
      return ShareOutcome.failed;
    }
  }
}
