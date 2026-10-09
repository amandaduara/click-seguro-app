import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/extensions/auth_presentation_extension.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_mode_switch.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/or_divider.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/password_rules_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Login, cadastro e visitante (wireframe: LoginScreen).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.reset());
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
    context.go('/home');
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

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s6,
              AppSpacing.s7,
              AppSpacing.s6,
              AppSpacing.s6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(),
                const SizedBox(height: AppSpacing.s7),
                AuthModeSwitch(
                  loginLabel: AppStrings.authModeLogin.tr(),
                  registerLabel: AppStrings.authModeRegister.tr(),
                  isRegister: isRegister,
                  onChanged: (register) {
                    setState(() => _passwordWasReset = false);
                    controller.setMode(
                      register ? AuthMode.register : AuthMode.login,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s6),
                if (isRegister) ...[
                  SafeTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    onChanged: _onFormChanged,
                    placeholder: AppStrings.authNamePlaceholder.tr(),
                    semanticsLabel: AppStrings.authNamePlaceholder.tr(),
                    leftIcon: const Icon(Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                    error: _errorFor(controller, AuthField.name),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                ],
                SafeTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  onChanged: _onFormChanged,
                  placeholder: AppStrings.authEmailPlaceholder.tr(),
                  semanticsLabel: AppStrings.authEmailPlaceholder.tr(),
                  leftIcon: const Icon(Icons.mail_outline),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  error: _errorFor(controller, AuthField.email),
                ),
                const SizedBox(height: AppSpacing.s3),
                SafeTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  placeholder: AppStrings.authPasswordPlaceholder.tr(),
                  semanticsLabel: AppStrings.authPasswordPlaceholder.tr(),
                  leftIcon: const Icon(Icons.lock_outline),
                  obscureText: !controller.isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  autofillHints: [
                    isRegister
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
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
                      controller.isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                if (isRegister) ...[
                  const SizedBox(height: AppSpacing.s2),
                  PasswordRulesList(
                    rules: [
                      for (final rule in PasswordRule.values)
                        (
                          label: rule.labelKey.tr(),
                          met: controller.passwordRules.contains(rule),
                        ),
                    ],
                  ),
                ],
                if (!isRegister)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.primary,
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(AppStrings.authForgotPassword.tr()),
                    ),
                  ),
                if (_passwordWasReset) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      AppStrings.authResetSuccess.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.success,
                      ),
                    ),
                  ),
                ],
                ..._failureMessage(controller),
                const SizedBox(height: AppSpacing.s5),
                SafeButton(
                  label: primaryLabel,
                  loading: controller.isSubmitting,
                  // Só com todos os campos corretos (no cadastro, a senha
                  // cumprindo as 5 regras).
                  disabled: !controller.canSubmit && !controller.isSubmitting,
                  shadow: controller.canSubmit,
                  onPressed: _submit,
                ),
                SlowRequestNotice(
                  active: controller.isSubmitting,
                  message: AppStrings.authSlowServer.tr(),
                ),
                const SizedBox(height: AppSpacing.s6),
                const OrDivider(),
                const SizedBox(height: AppSpacing.s6),
                SafeButton(
                  label: AppStrings.authContinueAsGuest.tr(),
                  tone: SafeButtonTone.ghost,
                  onPressed: controller.continueAsGuest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _failureMessage(AuthenticationController controller) {
    final failure = controller.failure;
    if (failure == null) return const [];
    final isInfo = failure is AccountCreatedFailure;
    return [
      const SizedBox(height: AppSpacing.s4),
      Semantics(
        liveRegion: true,
        child: Text(
          failure.message.tr(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isInfo
                ? context.colors.secondary
                : context.colors.destructive,
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
    ];
  }
}
