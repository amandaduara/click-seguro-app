import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/extensions/auth_presentation_extension.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  late final AuthenticationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<AuthenticationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.reset());
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _emailController.dispose();
    _passwordController.dispose();
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
    _controller.submit(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  String? _errorFor(AuthenticationController controller, AuthField field) =>
      controller.fieldErrors[field]?.messageKey.tr();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthenticationController>();
    final failure = controller.failure;

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
                SafeTextField(
                  controller: _emailController,
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
                  autofillHints: const [AutofillHints.password],
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
                if (failure != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      failure.message.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s5),
                SafeButton(
                  label: AppStrings.authModeLogin.tr(),
                  loading: controller.isSubmitting,
                  shadow: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
