/// Aviso rápido do feed que não troca a tela (specs/022 FR-003): a lista
/// continua e a página mostra [failureKey] traduzida.
class FeedMessage {
  const FeedMessage(this.failureKey);

  /// Chave de tradução da `Failure` (Constituição §V).
  final String failureKey;
}
