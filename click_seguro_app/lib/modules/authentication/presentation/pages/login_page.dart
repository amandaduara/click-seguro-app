import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/animated_reveal.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:click_seguro_app/core/widgets/password_rules_list.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_pill_tabs.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/extensions/auth_presentation_extension.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/login_intro.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/terms_acceptance.dart';
import 'package:click_seguro_app/modules/common/presentation/extensions/password_rule_presentation.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Login, cadastro e visitante na versão A (specs/026): o cabeçalho e a onda
/// do fim da splash, o formulário no meio e "Continuar sem login" como link.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.initialMode = AuthMode.login,
    this.next,
    this.fromSplash = false,
  });

  /// Modo ao abrir; o aviso das atividades abre em cadastro (specs/020).
  final AuthMode initialMode;

  /// Para onde ir ao entrar; sem ele, o Início.
  final String? next;

  /// Aberto pela splash: faz a passagem animada ([LoginIntro]).
  final bool fromSplash;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AuthenticationController _controller;

  /// Aviso de "senha alterada" ao voltar da recuperação (FR-016).
  bool _passwordWasReset = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<AuthenticationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller
        ..reset()
        ..setMode(widget.initialMode);
    });
    _controller.addListener(_onControllerChanged);
    // Ao sair de um campo, o erro dele (se houver) passa a aparecer.
    for (final (focus, field) in [
      (_nameFocus, AuthField.name),
      (_emailFocus, AuthField.email),
      (_passwordFocus, AuthField.password),
    ]) {
      focus.addListener(() {
        if (!focus.hasFocus) _controller.markTouched(field);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!_controller.authenticated || !mounted) return;
    _controller.reset();
    context.go(widget.next ?? '/home');
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _passwordWasReset = false);
    _controller.submit(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _openForgotPassword() async {
    final email = await context.push<String>(
      '/forgot-password',
      extra: _emailController.text.trim(),
    );
    if (email == null || !mounted) return;
    _controller.setMode(AuthMode.login);
    setState(() {
      _emailController.text = email;
      _passwordController.clear();
      _onFormChanged();
      _passwordWasReset = true;
    });
  }

  void _onFormChanged([String _ = '']) => _controller.updateForm(
    name: _nameController.text,
    email: _emailController.text,
    password: _passwordController.text,
  );

  String? _errorFor(AuthenticationController controller, AuthField field) =>
      controller.fieldErrors[field]?.messageKey.tr();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthenticationController>();
    final isRegister = controller.mode == AuthMode.register;
    final primaryLabel = isRegister
        ? AppStrings.authModeRegister.tr()
        : AppStrings.authModeLogin.tr();
    // A onda fica presa ao pé da tela (atrás do teclado); só a rolagem
    // encolhe com o teclado, para o campo com foco aparecer acima dele.
    // Sem teclado, o fim da rolagem deixa a onda livre (specs/026 R3).
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      AppSpacing.s6,
      AppSpacing.s6,
      AppSpacing.s6,
      keyboard > 0
          ? AppSpacing.s6
          : BrandScene.footerHeight +
                AppSpacing.s4 +
                MediaQuery.paddingOf(context).bottom,
    );

    final Widget body = Stack(
      children: [
        const Positioned(left: 0, right: 0, bottom: 0, child: BrandWave()),
        Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: SafeArea(
            bottom: false,
            child: AutofillGroup(
              child: SingleChildScrollView(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(),
                    const SizedBox(height: AppSpacing.s6),
                    LoginIntroReveal(
                      step: 1,
                      child: SafePillTabs(
                        tabs: [
                          AppStrings.authModeLogin.tr(),
                          AppStrings.authModeRegister.tr(),
                        ],
                        selectedIndex: isRegister ? 1 : 0,
                        onChanged: (index) {
                          final bool register = index == 1;
                          // Tocar na aba atual não muda nada.
                          if (register == isRegister) return;
                          setState(() => _passwordWasReset = false);
                          controller.setMode(
                            register ? AuthMode.register : AuthMode.login,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    LoginIntroReveal(
                      step: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _form(controller, isRegister),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    LoginIntroReveal(
                      step: 3,
                      child: SafeButton(
                        label: primaryLabel,
                        iconRight: const Icon(LucideIcons.arrowRight),
                        loading: controller.isSubmitting,
                        // Só com todos os campos corretos (no cadastro, a
                        // senha cumprindo as 5 regras e o aceite).
                        disabled:
                            !controller.canSubmit && !controller.isSubmitting,
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    LoginIntroReveal(
                      step: 4,
                      child: Center(
                        child: TextButton(
                          onPressed: controller.continueAsGuest,
                          style: TextButton.styleFrom(
                            foregroundColor: context.colors.primaryPressed,
                            minimumSize: const Size(48, 48),
                            textStyle: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(AppStrings.authContinueAsGuest.tr()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: widget.fromSplash ? LoginIntro(child: body) : body,
    );
  }

  /// Campos com o rótulo acima (redesign 2.0), regras da senha, "Esqueci
  /// minha senha" e as mensagens. Campos, regras e mensagens entram e saem
  /// crescendo e esmaecendo (specs/022 FR-023).
  List<Widget> _form(AuthenticationController controller, bool isRegister) => [
    AnimatedReveal(
      child: isRegister
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  onChanged: _onFormChanged,
                  label: AppStrings.authNameLabel.tr(),
                  semanticsLabel: AppStrings.authNameLabel.tr(),
                  placeholder: AppStrings.authNamePlaceholder.tr(),
                  leftIcon: const Icon(LucideIcons.user),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                  error: _errorFor(controller, AuthField.name),
                ),
                const SizedBox(height: AppSpacing.s5),
              ],
            )
          : null,
    ),
    SafeTextField(
      controller: _emailController,
      focusNode: _emailFocus,
      onChanged: _onFormChanged,
      label: AppStrings.authEmailLabel.tr(),
      semanticsLabel: AppStrings.authEmailLabel.tr(),
      placeholder: AppStrings.authEmailPlaceholder.tr(),
      leftIcon: const Icon(LucideIcons.mail),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      onSubmitted: (_) => _passwordFocus.requestFocus(),
      error: _errorFor(controller, AuthField.email),
    ),
    const SizedBox(height: AppSpacing.s5),
    SafeTextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      label: AppStrings.authPasswordLabel.tr(),
      semanticsLabel: AppStrings.authPasswordLabel.tr(),
      placeholder: AppStrings.authPasswordPlaceholder.tr(),
      leftIcon: const Icon(LucideIcons.lock),
      obscureText: !controller.isPasswordVisible,
      textInputAction: TextInputAction.done,
      autofillHints: [
        isRegister ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onChanged: _onFormChanged,
      onSubmitted: (_) => _submit(),
      error: _errorFor(controller, AuthField.password),
      rightIcon: IconButton(
        onPressed: controller.togglePasswordVisibility,
        tooltip: controller.isPasswordVisible
            ? AppStrings.authPasswordHide.tr()
            : AppStrings.authPasswordShow.tr(),
        icon: Icon(
          controller.isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
        ),
      ),
    ),
    AnimatedReveal(
      child: isRegister
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.s3),
                PasswordRulesList(
                  rules: [
                    for (final rule in PasswordRule.values)
                      (
                        label: rule.labelKey.tr(),
                        met: controller.passwordRules.contains(rule),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                TermsAcceptance(
                  accepted: controller.termsAccepted,
                  onChanged: controller.setTermsAccepted,
                  onOpenTerms: () => context.push('/settings/terms'),
                  onOpenPrivacy: () => context.push('/settings/privacy'),
                ),
              ],
            )
          : null,
    ),
    AnimatedReveal(
      child: isRegister
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s1),
              child: Align(
                // À direita, como na versão A (specs/026 FR-012).
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _openForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.textForeground,
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    textStyle: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(AppStrings.authForgotPassword.tr()),
                ),
              ),
            ),
    ),
    AnimatedReveal(
      child: _passwordWasReset
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.s2),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    AppStrings.authResetSuccess.tr(),
                    style: AppTypography.body.copyWith(
                      color: context.colors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : null,
    ),
    AnimatedReveal(child: _failureMessage(controller)),
  ];

  /// `null` sem falha. Uma mensagem dá lugar a outra esmaecendo.
  Widget? _failureMessage(AuthenticationController controller) {
    final failure = controller.failure;
    if (failure == null) return null;
    final isInfo = failure is AccountCreatedFailure;
    final AppMotion motion = AppMotion.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s4),
        AnimatedSwitcher(
          duration: motion.medium,
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [...previous, ?current],
          ),
          child: Semantics(
            key: ValueKey(failure.message),
            liveRegion: true,
            child: Text(
              failure.message.tr(),
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isInfo
                    ? context.colors.secondary
                    : context.colors.destructive,
              ),
            ),
          ),
        ),
        if (failure is EmailAlreadyExistsFailure) ...[
          const SizedBox(height: AppSpacing.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: SafeButton(
              label: AppStrings.authActionSignInWithEmail.tr(),
              size: SafeButtonSize.compact,
              tone: SafeButtonTone.ghost,
              onPressed: () => controller.setMode(AuthMode.login),
            ),
          ),
        ],
      ],
    );
  }
}
