import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/password_rules_list.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/modules/common/presentation/extensions/password_rule_presentation.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/change_password_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_guest_invite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// "Alterar senha" (US2 de specs/013-configuracoes).
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasAccount =
        GetIt.instance<UserSessionService>().isAuthenticated;
    if (!hasAccount) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.settingsChangePassword.tr())),
        body: const SafeArea(child: SettingsGuestInvite()),
      );
    }
    return ChangeNotifierProvider<ChangePasswordController>(
      create: (_) => GetIt.instance<ChangePasswordController>(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatelessWidget {
  const _ChangePasswordView();

  Future<void> _confirmDiscard(BuildContext context) async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.settingsPasswordDiscardTitle.tr()),
        content: Text(AppStrings.settingsPasswordDiscardBody.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.settingsPasswordDiscardCancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.settingsPasswordDiscardConfirm.tr()),
          ),
        ],
      ),
    );
    if (discard == true && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ChangePasswordController controller = context
        .watch<ChangePasswordController>();
    return PopScope(
      canPop: !controller.hasInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.settingsChangePassword.tr())),
        body: SafeArea(child: _Form(controller: controller)),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller});

  final ChangePasswordController controller;

  static String? _message(PasswordFieldError? error) => switch (error) {
    null => null,
    PasswordFieldError.required =>
      AppStrings.settingsPasswordErrorRequired.tr(),
    PasswordFieldError.rulesNotMet =>
      AppStrings.settingsPasswordErrorRules.tr(),
    PasswordFieldError.mismatch =>
      AppStrings.settingsPasswordErrorMismatch.tr(),
    PasswordFieldError.wrongCurrent =>
      AppStrings.settingsPasswordErrorCurrent.tr(),
    PasswordFieldError.samePassword =>
      AppStrings.settingsPasswordErrorSame.tr(),
  };

  Future<void> _save(BuildContext context) async {
    FocusScope.of(context).unfocus();
    // Guardado antes: no novo login que falha, a tela some (vai ao login).
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ChangePasswordResult result = await controller.save();
    final Failure? failure = controller.saveFailure;
    final String? message = switch (result) {
      ChangePasswordResult.invalid => null,
      ChangePasswordResult.saved => AppStrings.settingsPasswordSaved.tr(),
      ChangePasswordResult.failed => switch (failure) {
        PasswordChangedReloginFailure() ||
        UnauthorizedFailure() => failure!.message.tr(),
        _ => AppStrings.settingsPasswordFailed.tr(),
      },
    };
    if (message == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (result == ChangePasswordResult.saved && context.mounted) {
      context.pop();
    }
  }

  Widget _field(
    BuildContext context,
    PasswordField field,
    String label,
    TextEditingController text, {
    required List<String> autofill,
    TextInputAction action = TextInputAction.next,
  }) {
    final bool visible = controller.isVisible(field);
    return SafeTextField(
      label: label,
      controller: text,
      obscureText: !visible,
      error: _message(controller.errors[field]),
      textInputAction: action,
      autofillHints: autofill,
      onSubmitted: action == TextInputAction.done
          ? (_) => _save(context)
          : null,
      rightIcon: IconButton(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: () => controller.toggleVisibility(field),
        tooltip: visible
            ? AppStrings.settingsPasswordHide.tr()
            : AppStrings.settingsPasswordShow.tr(),
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<PasswordRule> met = controller.rulesMet;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s5),
      children: [
        _field(
          context,
          PasswordField.current,
          AppStrings.settingsPasswordCurrent.tr(),
          controller.current,
          autofill: const [AutofillHints.password],
        ),
        const SizedBox(height: AppSpacing.s4),
        _field(
          context,
          PasswordField.newPassword,
          AppStrings.settingsPasswordNew.tr(),
          controller.newPassword,
          autofill: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          AppStrings.settingsPasswordRulesTitle.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.textMutedForeground,
          ),
        ),
        PasswordRulesList(
          rules: [
            for (final rule in PasswordRule.values)
              (label: rule.labelKey.tr(), met: met.contains(rule)),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        _field(
          context,
          PasswordField.confirmation,
          AppStrings.settingsPasswordConfirm.tr(),
          controller.confirmation,
          autofill: const [AutofillHints.newPassword],
          action: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.s6),
        SafeButton(
          label: AppStrings.settingsPasswordSave.tr(),
          disabled: !controller.canSave,
          loading: controller.isSaving,
          onPressed: () => _save(context),
        ),
      ],
    );
  }
}
