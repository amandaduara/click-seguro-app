/// Ilustrações do redesign 2.0, em `assets/illustrations/` (FR-017; tabela
/// "Ilustração" do data-model de specs/023-redesign-visual).
enum AppIllustration {
  onboardingProtect('onboarding_protect'),
  onboardingNews('onboarding_news'),
  onboardingPractice('onboarding_practice'),
  themeWhatsapp('theme_whatsapp'),
  themePix('theme_pix'),
  themeLink('theme_link'),
  themeCall('theme_call'),
  themePassword('theme_password'),
  themeFakeNews('theme_fake_news'),
  themeGeneric('theme_generic'),
  stateOffline('state_offline'),
  stateError('state_error'),
  stateEmpty('state_empty'),
  stateTrophy('state_trophy'),
  answerCorrect('answer_correct'),
  answerWrong('answer_wrong');

  const AppIllustration(this._file);

  final String _file;

  String get asset => 'assets/illustrations/$_file.svg';
}
