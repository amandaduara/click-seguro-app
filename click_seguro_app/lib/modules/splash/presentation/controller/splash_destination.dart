/// Para onde o splash leva ao terminar (tabela de decisão em
/// specs/004-splash-onboarding-sessao/data-model.md).
enum SplashDestination {
  onboarding('/onboarding'),
  home('/home'),
  login('/login');

  const SplashDestination(this.path);

  /// Rota do go_router.
  final String path;
}
