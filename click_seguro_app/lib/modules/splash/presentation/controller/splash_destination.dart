/// Para onde o splash leva ao terminar (tabela de decisão em
/// specs/004-splash-onboarding-sessao/data-model.md).
enum SplashDestination {
  onboarding('/onboarding'),
  home('/home'),

  /// O login faz a passagem animada a partir da splash (specs/026 R1).
  login('/login?from=splash');

  const SplashDestination(this.path);

  /// Rota do go_router.
  final String path;
}
