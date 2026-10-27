import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/help_controller.dart';
import 'package:click_seguro_app/modules/help/presentation/routes/help_routes.dart';
import 'package:click_seguro_app/core/widgets/person_avatar.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => GetIt.instance<HelpController>()..load(),
    child: const _HelpPageContent(),
  );
}

class _HelpPageContent extends StatelessWidget {
  const _HelpPageContent();

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: AppStrings.helpTitle.tr()),
            TabBar(
              tabs: [
                Tab(text: AppStrings.helpTabOfficial.tr()),
                Tab(text: AppStrings.helpTabPersonal.tr()),
              ],
            ),
            Expanded(
              child: Consumer<HelpController>(
                builder: (context, controller, _) => TabBarView(
                  children: [
                    _contactList(context, controller, official: true),
                    _contactList(context, controller, official: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _contactList(
    BuildContext context,
    HelpController controller, {
    required bool official,
  }) {
    final failure = official
        ? controller.officialFailure
        : controller.personalFailure;
    if (controller.isLoading) return const SafeLoadingState();
    if (failure != null) {
      return SafeErrorState(
        message: failure.message.tr(),
        onRetry: controller.refresh,
      );
    }
    final contacts = official
        ? controller.officialContacts
        : controller.personalContacts;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (!official && contacts.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey('help_add_contact'),
                onPressed: () => _openForm(context, controller),
                icon: const Icon(Icons.add),
                label: Text(AppStrings.helpAddContact.tr()),
              ),
            ),
          if (contacts.isEmpty && official)
            SafeEmptyState(message: AppStrings.helpOfficialUnavailable.tr())
          else if (contacts.isEmpty)
            SafeEmptyState(
              message: AppStrings.helpPersonalEmpty.tr(),
              actionLabel: AppStrings.helpAddContact.tr(),
              onAction: () => _openForm(context, controller),
            )
          else
            for (final contact in contacts)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s3),
                child: _ContactCard(
                  contact: contact,
                  onCall: () => _call(context, controller, contact),
                  onEdit: official
                      ? null
                      : () => _openForm(
                          context,
                          controller,
                          contactId: contact.id,
                        ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    HelpController controller, {
    String? contactId,
  }) async {
    final saved = await context.push<bool>(
      helpContactPath(contactId: contactId),
    );
    if (saved == true && context.mounted) await controller.refresh();
  }

  Future<void> _call(
    BuildContext context,
    HelpController controller,
    ContactEntity contact,
  ) async {
    if (await controller.call(contact) || !context.mounted) return;
    final phone = contact.phone;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(AppStrings.helpPhoneFallback.tr()),
        content: SelectableText(
          phone,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.colors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.helpCancel.tr()),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: phone));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.helpCopied.tr())),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(AppStrings.helpCopyNumber.tr()),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onCall,
    this.onEdit,
  });

  final ContactEntity contact;
  final VoidCallback onCall;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => SafeCard(
    child: Column(
      children: [
        Row(
          children: [
            PersonAvatar(
              name: contact.name,
              size: 56,
              photoPath: contact.photoPath,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(contact.phone),
                  if (contact.relationship case final String relationship)
                    Text(relationship),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: AppStrings.helpCall.tr(args: [contact.name]),
              onPressed: onCall,
              icon: const Icon(Icons.call),
            ),
            if (onEdit != null)
              IconButton(
                tooltip: AppStrings.helpEditContact.tr(),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
      ],
    ),
  );
}
