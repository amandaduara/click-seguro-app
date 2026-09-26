/// Base de toda falha devolvida por repositories e usecases no lado `Left`
/// de um `Either<Failure, T>`.
///
/// [message] é uma chave de tradução (ver `AppStrings`), não um texto pronto:
/// a camada presentation exibe com `failure.message.tr()`. Assim o domain não
/// depende de `easy_localization`.
abstract class Failure {
  const Failure(this.message);

  final String message;
}
