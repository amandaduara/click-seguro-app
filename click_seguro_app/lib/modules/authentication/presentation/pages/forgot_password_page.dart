import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/reset_step.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/forgot_password_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/extensions/auth_presentation_extension.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/password_rules_list.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/resend_code_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Recuperação de senha: e-mail → código → nova senha. Ao concluir, volta
/// à tela de login devolvendo o e-mail (`pop(email)`).
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});

  /// E-mail já digitado na tela de login, se houver.
  final String? initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _confirmationFocus = FocusNode();

  late final ForgotPasswordController _controller;

  /// Redesenha a contagem do reenvio; existe só no passo do código.
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
    _controller = context.read<ForgotPasswordController>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.start(widget.initialEmail),
    );
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _controller.removeListener(_onControllerChanged);
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _syncCountdown();
    if (_controller.completed) {
      final email = _controller.email;
      _controller.start(null);
      context.pop(email);
    }
  }

  void _syncCountdown() {
    final onCodeStep = _controller.step == ResetStep.code;
    if (onCodeStep && _countdown == null) {
      _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!onCodeStep) {
      _countdown?.cancel();
      _countdown = null;
    }
  }

  void _goBack() {
    if (!_controller.back()) context.pop();
  }

  String? _errorFor(ForgotPasswordController controller, AuthField field) =>
      controller.fieldErrors[field]?.messageKey.tr();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ForgotPasswordController>();
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            tooltip: AppStrings.authBack.tr(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(AppStrings.authResetTitle.tr()),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...switch (controller.step) {
                  ResetStep.email => _emailStep(controller, textTheme),
                  ResetStep.code => _codeStep(controller, textTheme),
                  ResetStep.newPassword => _newPasswordStep(controller),
                },
                SlowRequestNotice(
                  active: controller.isSubmitting,
                  message: AppStrings.authSlowServer.tr(),
                ),
                if (controller.failure != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.failure!.message.tr(),
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _emailStep(
    ForgotPasswordController controller,
    TextTheme textTheme,
  ) => [
    Text(
      AppStrings.authResetEmailDescription.tr(),
      style: textTheme.bodyLarge?.copyWith(color: AppColors.textForeground),
    ),
    const SizedBox(height: AppSpacing.s5),
    SafeTextField(
      controller: _emailController,
      placeholder: AppStrings.authEmailPlaceholder.tr(),
      semanticsLabel: AppStrings.authEmailPlaceholder.tr(),
      leftIcon: const Icon(Icons.mail_outline),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.email],
      onSubmitted: (_) => controller.submitEmail(_emailController.text),
      error: _errorFor(controller, AuthField.email),
    ),
    const SizedBox(height: AppSpacing.s5),
    SafeButton(
      label: AppStrings.authResetSendCode.tr(),
      loading: controller.isSubmitting,
      shadow: true,
      onPressed: () => controller.submitEmail(_emailController.text),
    ),
  ];

  List<Widget> _codeStep(
    ForgotPasswordController controller,
    TextTheme textTheme,
  ) => [
    Text(
      AppStrings.authResetCodeSent.tr(),
      style: textTheme.bodyLarge?.copyWith(color: AppColors.textForeground),
    ),
    const SizedBox(height: AppSpacing.s5),
    SafeTextField(
      controller: _codeController,
      placeholder: AppStrings.authResetCodePlaceholder.tr(),
      semanticsLabel: AppStrings.authResetCodePlaceholder.tr(),
      leftIcon: const Icon(Icons.pin_outlined),
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      onSubmitted: (_) => controller.submitCode(_codeController.text),
      error: _errorFor(controller, AuthField.code),
    ),
    const SizedBox(height: AppSpacing.s5),
    SafeButton(
      label: AppStrings.authResetContinue.tr(),
      loading: controller.isSubmitting,
      shadow: true,
      onPressed: () => controller.submitCode(_codeController.text),
    ),
    const SizedBox(height: AppSpacing.s3),
    Center(
      child: ResendCodeButton(
        secondsUntilResend: controller.secondsUntilResend,
        onPressed: controller.resendCode,
      ),
    ),
  ];

  List<Widget> _newPasswordStep(ForgotPasswordController controller) => [
    SafeTextField(
      controller: _passwordController,
      placeholder: AppStrings.authResetNewPasswordPlaceholder.tr(),
      semanticsLabel: AppStrings.authResetNewPasswordPlaceholder.tr(),
      leftIcon: const Icon(Icons.lock_outline),
      obscureText: !controller.isPasswordVisible,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      onChanged: controller.onPasswordChanged,
      onSubmitted: (_) => _confirmationFocus.requestFocus(),
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
    const SizedBox(height: AppSpacing.s3),
    SafeTextField(
      controller: _confirmationController,
      focusNode: _confirmationFocus,
      placeholder: AppStrings.authResetConfirmPasswordPlaceholder.tr(),
      semanticsLabel: AppStrings.authResetConfirmPasswordPlaceholder.tr(),
      leftIcon: const Icon(Icons.lock_outline),
      obscureText: !controller.isPasswordVisible,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _saveNewPassword(controller),
      error: _errorFor(controller, AuthField.passwordConfirmation),
    ),
    const SizedBox(height: AppSpacing.s5),
    SafeButton(
      label: AppStrings.authResetSave.tr(),
      loading: controller.isSubmitting,
      shadow: true,
      onPressed: () => _saveNewPassword(controller),
    ),
  ];

  void _saveNewPassword(ForgotPasswordController controller) =>
      controller.submitNewPassword(
        password: _passwordController.text,
        confirmation: _confirmationController.text,
      );
}
