import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/utils/phone_format.dart';
import 'package:click_seguro_app/core/widgets/photo_sheet.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/contact_form_controller.dart';
import 'package:click_seguro_app/core/widgets/editable_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Ao sair de um campo, o erro dele passa a aparecer enquanto digita.
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = context.read<ContactFormController>();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _controller.touchName();
    });
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) _controller.touchPhone();
    });
    if (widget.contactId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadContact();
      });
    }
  }

  Future<void> _loadContact() => _controller.load();

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
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
            // O botão principal fica no fim da tela; o formulário rola acima
            // dele (validação da usuária, specs/024).
            return Column(
              children: [
                Expanded(child: _form(context, controller)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s5,
                    AppSpacing.s3,
                    AppSpacing.s5,
                    AppSpacing.s5,
                  ),
                  child: SafeButton(
                    label: AppStrings.helpSaveContact.tr(),
                    loading: controller.isSaving,
                    // Só com nome e telefone válidos, como na edição de
                    // perfil.
                    disabled: !controller.canSave,
                    onPressed: _save,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, ContactFormController controller) =>
      ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          // A mesma foto da edição de perfil: círculo com o selo da câmera.
          Center(
            child: EditableAvatar(
              name: controller.name,
              photoPath: controller.photoPath,
              size: 104,
              busy: controller.isPhotoLoading,
              semanticLabel: AppStrings.helpPhoto.tr(),
              onTap: _showPhotoOptions,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          SafeTextField(
            label: AppStrings.helpName.tr(),
            controller: _nameField ??= TextEditingController(
              text: controller.name,
            ),
            focusNode: _nameFocus,
            error: controller.nameError == ContactValidationError.name
                ? AppStrings.helpNameRequired.tr()
                : null,
            textInputAction: TextInputAction.next,
            // Sem espaço no começo e com um limite de tamanho.
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'^\s+')),
              LengthLimitingTextInputFormatter(ContactValidation.nameMaxLength),
            ],
            onChanged: _controller.setName,
          ),
          const SizedBox(height: AppSpacing.s4),
          SafeTextField(
            label: AppStrings.helpPhone.tr(),
            controller: _phoneField ??= TextEditingController(
              text: formatPhone(controller.phone, shortCodes: true),
            ),
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            // Máscara enquanto digita: (11) 91234-5678, 190, 0800 728 4567.
            inputFormatters: const [PhoneInputFormatter(shortCodes: true)],
            error: controller.phoneError == ContactValidationError.phone
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
        ],
      );

  Future<void> _save() async {
    if (await _controller.save() && mounted) context.pop(true);
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
