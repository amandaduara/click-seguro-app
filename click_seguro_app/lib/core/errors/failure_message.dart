import 'package:click_seguro_app/core/errors/connection_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';

/// Padrão de sem internet (specs/027): a falta de internet tem sempre a
/// mesma frase; as outras falhas ficam com o texto próprio da tela.
extension FailureMessageKey on Failure? {
  /// A chave de sem conexão para [ConnectionFailure]; senão, [fallbackKey].
  String messageKeyOr(String fallbackKey) {
    final Failure? failure = this;
    return failure is ConnectionFailure ? failure.message : fallbackKey;
  }
}
