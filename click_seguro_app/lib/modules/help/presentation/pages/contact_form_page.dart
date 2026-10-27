import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/photo_sheet.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/contact_form_controller.dart';
import 'package:click_seguro_app/core/widgets/person_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ContactFormPage extends StatelessWidget {
  const ContactFormPage({super.key, this.contactId});

  final String? contactId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => GetIt.instance<ContactFormController>(param1: contactId),
    child: _ContactFormContent(contactId: contactId),
  );
}

class _ContactFormContent extends StatefulWidget {
  const _ContactFormContent({this.contactId});

  final String? contactId;

  @override
  State<_ContactFormContent> createState() => _ContactFormContentState();
}

class _ContactFormContentState extends State<_ContactFormContent> {
  late final ContactFormController _controller;
  bool _sheetOpen = false;

  /// Criados quando o formulário aparece, já com o contato carregado.
  TextEditingController? _nameField;
  TextEditingController? _phoneField;
  TextEditingController? _relationshipField;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ContactFormController>();
    if (widget.contactId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadContact();
      });
    }
  }

  Future<void> _loadContact() => _controller.load();

  @override
  void dispose() {
    _nameField?.dispose();
    _phoneField?.dispose();
    _relationshipField?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.contactId == null
                  ? AppStrings.helpAddContact
                  : AppStrings.helpEditContact)
              .tr(),
        ),
      ),
      body: SafeArea(
        child: Consumer<ContactFormController>(
          builder: (context, controller, _) {
            final failure = controller.loadFailure;
            if (failure != null) {
              return SafeErrorState(
                message: failure.message.tr(),
                onRetry: _loadContact,
              );
            }
            if (controller.notFound) {
              return SafeEmptyState(
                message: AppStrings.helpContactMissing.tr(),
              );
            }
            if (controller.isLoading) return const SafeLoadingState();
            return _form(context, controller);
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, ContactFormController controller) =>
      ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          Center(
            child: Semantics(
              button: true,
              label: AppStrings.helpPhoto.tr(),
              child: InkWell(
                onTap: _showPhotoOptions,
                customBorder: const CircleBorder(),
                child: PersonAvatar(
                  name: controller.name,
                  size: 104,
                  photoPath: controller.photoPath,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Center(
            child: TextButton.icon(
              onPressed: _showPhotoOptions,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(AppStrings.helpChoosePhoto.tr()),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          SafeTextField(
            label: AppStrings.helpName.tr(),
            controller: _nameField ??= TextEditingController(
              text: controller.name,
            ),
            error: controller.validationError == ContactValidationError.name
                ? AppStrings.helpNameRequired.tr()
                : null,
            textInputAction: TextInputAction.next,
            onChanged: _controller.setName,
          ),
          const SizedBox(height: AppSpacing.s4),
          SafeTextField(
            label: AppStrings.helpPhone.tr(),
            controller: _phoneField ??= TextEditingController(
              text: controller.phone,
            ),
            keyboardType: TextInputType.phone,
            error: controller.validationError == ContactValidationError.phone
                ? AppStrings.helpPhoneInvalid.tr()
                : null,
            textInputAction: TextInputAction.next,
            onChanged: _controller.setPhone,
          ),
          const SizedBox(height: AppSpacing.s4),
          SafeTextField(
            label: AppStrings.helpRelationship.tr(),
            controller: _relationshipField ??= TextEditingController(
              text: controller.relationship,
            ),
            textInputAction: TextInputAction.done,
            onChanged: _controller.setRelationship,
          ),
          if (controller.saveFailure case final saveFailure?) ...[
            const SizedBox(height: AppSpacing.s3),
            Text(
              saveFailure.message.tr(),
              style: TextStyle(color: context.colors.destructive),
            ),
          ],
          if (controller.deleteFailure case final deleteFailure?) ...[
            const SizedBox(height: AppSpacing.s3),
            Text(
              deleteFailure.message.tr(),
              style: TextStyle(color: context.colors.destructive),
            ),
          ],
          const SizedBox(height: AppSpacing.s6),
          SafeButton(
            label: AppStrings.helpSaveContact.tr(),
            loading: controller.isSaving,
            disabled: controller.isSaving || controller.isPhotoLoading,
            onPressed: _save,
          ),
          if (widget.contactId != null) ...[
            const SizedBox(height: AppSpacing.s3),
            SafeButton(
              label: AppStrings.helpDeleteContact.tr(),
              tone: SafeButtonTone.ghost,
              loading: controller.isDeleting,
              disabled: controller.isDeleting,
              onPressed: _confirmDelete,
            ),
          ],
        ],
      );

  Future<void> _save() async {
    if (await _controller.save() && mounted) context.pop(true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.helpDeleteContact.tr()),
        content: SingleChildScrollView(
          child: Text(AppStrings.helpDeleteConfirm.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.helpCancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppStrings.helpConfirm.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && await _controller.delete() && mounted) {
      context.pop(true);
    }
  }

  Future<void> _showPhotoOptions() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final PhotoAction? action = await showPhotoSheet(
      context,
      hasPhoto: _controller.photoPath != null,
    );
    _sheetOpen = false;
    if (action == null || !mounted) return;
    if (action == PhotoAction.remove) return _controller.removePhoto();
    await _controller.pickPhoto(
      action == PhotoAction.camera ? PhotoSource.camera : PhotoSource.gallery,
    );
    // Sem permissão o contato continua podendo ser salvo sem foto (CB-010).
    if (_controller.permissionDenied && mounted) {
      await showPhotoPermissionSheet(context);
    }
  }
}
