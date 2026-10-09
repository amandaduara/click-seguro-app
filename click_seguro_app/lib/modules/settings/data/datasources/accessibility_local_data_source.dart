/// Registro das preferências de acessibilidade no aparelho.
abstract class AccessibilityLocalDataSource {
  /// `null` se não houver registro.
  Future<Map<String, dynamic>?> read();

  Future<void> write(Map<String, dynamic> json);
}
