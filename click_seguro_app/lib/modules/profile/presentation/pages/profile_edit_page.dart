import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/core/widgets/person_avatar.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/avatar_update_outcome.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/domain/validators/profile_form_validator.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/edit_profile_controller.dart';
import 'package:click_seguro_app/modules/profile/presentation/extensions/phone_format.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/guest_invite.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/photo_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Editar nome, e-mail e telefone (US2 de specs/012-perfil). O visitante vê
/// o convite, sem pedido ao serviço.
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserSessionStatus>(
      valueListenable: GetIt.instance<UserSessionService>().sessionStatus,
      builder: (context, status, _) => status == UserSessionStatus.authenticated
          ? ChangeNotifierProvider<EditProfileController>(
              create: (_) => GetIt.instance<EditProfileController>()..load(),
              child: const _EditView(),
            )
          : Scaffold(
              appBar: AppBar(title: Text(AppStrings.profileEditTitle.tr())),
              body: const SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.s5),
                  child: GuestInvite(),
                ),
              ),
            ),
    );
  }
}

class _EditView extends StatelessWidget {
  const _EditView();

  /// Sair com alterações pede confirmação (FR-016).
  Future<void> _confirmDiscard(BuildContext context) async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.profileEditDiscardTitle.tr()),
        content: Text(AppStrings.profileEditDiscardBody.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.profileEditDiscardCancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.profileEditDiscardConfirm.tr()),
          ),
        ],
      ),
    );
    if (discard == true && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final EditProfileController controller = context
        .watch<EditProfileController>();
    return PopScope(
      canPop: !controller.hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.profileEditTitle.tr())),
        body: SafeArea(
          child: switch (controller.status) {
            EditProfileStatus.loading => const SafeLoadingState(),
            EditProfileStatus.error => SafeErrorState(
              message: (controller.failure?.message ?? AppStrings.errorGeneric)
                  .tr(),
              onRetry: controller.load,
            ),
            EditProfileStatus.ready => _Form(
              controller: controller,
              profile: controller.profile!,
            ),
          },
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller, required this.profile});

  final EditProfileController controller;
  final ProfileEntity profile;

  static String? _message(ProfileFieldError? error) => switch (error) {
    null => null,
    ProfileFieldError.nameLength => AppStrings.profileEditErrorName.tr(),
    ProfileFieldError.emailInvalid => AppStrings.profileEditErrorEmail.tr(),
    ProfileFieldError.emailInUse => AppStrings.profileEditErrorEmailInUse.tr(),
    ProfileFieldError.phoneInvalid => AppStrings.profileEditErrorPhone.tr(),
    ProfileFieldError.phoneRequired =>
      AppStrings.profileEditErrorPhoneRequired.tr(),
  };

  Future<void> _save(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final EditSaveResult result = await controller.save();
    if (!context.mounted || result == EditSaveResult.invalid) return;
    final Failure? failure = controller.saveFailure;
    final String message = switch (result) {
      EditSaveResult.saved => AppStrings.profileEditSaved.tr(),
      _ when failure is UnauthorizedFailure => failure.message.tr(),
      _ => AppStrings.profileEditSaveFailed.tr(),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ProfileFieldErrors errors = controller.errors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s5),
      children: [
        _PhotoButton(controller: controller, initials: profile.initials),
        const SizedBox(height: AppSpacing.s6),
        SafeTextField(
          label: AppStrings.profileEditName.tr(),
          controller: controller.name,
          error: _message(errors.name),
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: AppSpacing.s4),
        SafeTextField(
          label: AppStrings.profileEditEmail.tr(),
          controller: controller.email,
          error: _message(errors.email),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: AppSpacing.s4),
        SafeTextField(
          label: AppStrings.profileEditPhone.tr(),
          controller: controller.phone,
          error: _message(errors.phone),
          placeholder: AppStrings.profileEditPhoneHint.tr(),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: const [PhoneInputFormatter()],
          onSubmitted: (_) {
            if (controller.canSave) _save(context);
          },
        ),
        const SizedBox(height: AppSpacing.s6),
        SafeButton(
          label: AppStrings.profileEditSave.tr(),
          disabled: !controller.canSave,
          loading: controller.isSaving,
          onPressed: () => _save(context),
        ),
      ],
    );
  }
}

/// Foto no topo: tocar abre a folha (US3). Durante o envio, mostra a cópia
/// local com o indicador e "Enviando foto…".
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.controller, required this.initials});

  static const double _size = 96;

  final EditProfileController controller;
  final String initials;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _change(BuildContext context) async {
    final PhotoAction? action = await showPhotoSheet(
      context,
      hasPhoto: controller.avatarUrl != null,
    );
    if (action == null || !context.mounted) return;
    if (action == PhotoAction.remove) return _remove(context);

    final AvatarUpdateOutcome outcome = await controller.pickPhoto(
      action == PhotoAction.camera ? PhotoSource.camera : PhotoSource.gallery,
    );
    if (!context.mounted) return;
    switch (outcome) {
      case AvatarPermissionDenied():
        await showPhotoPermissionSheet(context);
      case AvatarUpdateFailed(:final failure):
        _showMessage(
          context,
          failure is AvatarTypeFailure
              ? failure.message.tr()
              : AppStrings.profilePhotoFailed.tr(),
        );
      case AvatarUpdated() || AvatarPickCancelled():
        break;
    }
  }

  Future<void> _remove(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.profilePhotoRemoveConfirmTitle.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.profilePhotoRemoveCancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.profilePhotoRemoveConfirm.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final Failure? failure = await controller.removePhoto();
    if (failure != null && context.mounted) {
      _showMessage(context, AppStrings.profilePhotoFailed.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool uploading = controller.photoState == PhotoState.uploading;
    return Column(
      children: [
        Semantics(
          container: true,
          button: true,
          label: AppStrings.profilePhotoChange.tr(),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: controller.photoState == PhotoState.idle
                ? () => _change(context)
                : null,
            child: SizedBox.square(
              dimension: _size,
              child: Stack(
                children: [
                  PersonAvatar(
                    initials: initials,
                    imageUrl: controller.avatarUrl,
                    photoPath: controller.localPhotoPath,
                    size: _size,
                  ),
                  if (uploading)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.secondary.withValues(alpha: 0.45),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colors.textPrimaryForeground,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.card, width: 3),
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: colors.textPrimaryForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (uploading) ...[
          const SizedBox(height: AppSpacing.s2),
          Semantics(
            liveRegion: true,
            child: Text(
              AppStrings.profilePhotoUploading.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textMutedForeground,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
