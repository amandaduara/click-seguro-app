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
import 'package:click_seguro_app/core/widgets/safe_pill_tabs.dart';
import 'package:click_seguro_app/modules/help/presentation/widgets/emergency_call_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

/// Aba Ajuda: emergência e contatos oficiais/pessoais.
///
/// Uma rolagem só, que termina no fim da lista: o topo (barra, cartão de
/// emergência e abas) rola junto, e não sobra tela vazia embaixo quando a
/// lista é curta (validação da usuária, specs/023). As abas em pílula
/// (T030) trocam a lista; deslizar para o lado também troca.
class _HelpPageContent extends StatefulWidget {
  const _HelpPageContent();

  @override
  State<_HelpPageContent> createState() => _HelpPageContentState();
}

class _HelpPageContentState extends State<_HelpPageContent> {
  /// 0 = Oficiais, 1 = Meus contatos.
  int _tab = 0;

  void _select(int tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  /// Deslize rápido para o lado troca de aba, como antes no `TabBarView`.
  void _onSwipe(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) _select(1);
    if (velocity > 300) _select(0);
  }

  @override
  Widget build(BuildContext context) {
    final HelpController controller = context.watch<HelpController>();
    final bool official = _tab == 0;
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: _onSwipe,
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AppTopBar(title: AppStrings.helpTitle.tr()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s5,
                      0,
                      AppSpacing.s5,
                      AppSpacing.s2,
                    ),
                    child: EmergencyCallCard(
                      onCall: () => _callNumber(
                        context,
                        controller,
                        EmergencyNumbers.police,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s5,
                      AppSpacing.s2,
                      AppSpacing.s5,
                      AppSpacing.s2,
                    ),
                    child: SafePillTabs(
                      tabs: [
                        AppStrings.helpTabOfficial.tr(),
                        AppStrings.helpTabPersonal.tr(),
                      ],
                      selectedIndex: _tab,
                      onChanged: _select,
                    ),
                  ),
                ),
                ..._contactSlivers(context, controller, official: official),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A lista da aba, ou o estado dela (carregando, erro, vazio).
  List<Widget> _contactSlivers(
    BuildContext context,
    HelpController controller, {
    required bool official,
  }) {
    // Carregando, erro e vazio com a altura natural, como os cartões: a
    // rolagem termina no fim deles, igual nas duas abas. Ocupando o resto
    // da tela, o estado vazio de "Meus contatos" rolava sozinho e deixava
    // o topo sumir (validação da usuária, specs/023).
    Widget fill(Widget child) => SliverToBoxAdapter(child: child);

    final failure = official
        ? controller.officialFailure
        : controller.personalFailure;
    if (controller.isLoading) return [fill(const SafeLoadingState())];
    if (failure != null) {
      return [
        fill(
          SafeErrorState(
            message: failure.message.tr(),
            onRetry: controller.refresh,
          ),
        ),
      ];
    }
    final contacts = official
        ? controller.officialContacts
        : controller.personalContacts;
    if (contacts.isEmpty) {
      return [
        fill(
          official
              ? SafeEmptyState(message: AppStrings.helpOfficialUnavailable.tr())
              : SafeEmptyState(
                  message: AppStrings.helpPersonalEmpty.tr(),
                  actionLabel: AppStrings.helpAddContact.tr(),
                  onAction: () => _openForm(context, controller),
                ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        sliver: SliverList.list(
          children: [
            if (!official)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('help_add_contact'),
                  onPressed: () => _openForm(context, controller),
                  icon: const Icon(LucideIcons.plus),
                  label: Text(AppStrings.helpAddContact.tr()),
                ),
              ),
            for (final contact in contacts)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s3),
                child: _ContactCard(
                  contact: contact,
                  onCall: () => _callNumber(context, controller, contact.phone),
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
      ),
    ];
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

  /// Liga; sem discador, mostra o número para copiar (CB-009). Vale para
  /// os contatos e para o "Ligar para 190" (FR-016 de specs/023).
  Future<void> _callNumber(
    BuildContext context,
    HelpController controller,
    String phone,
  ) async {
    if (await controller.callNumber(phone) || !context.mounted) return;
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
            icon: const Icon(LucideIcons.copy),
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
              icon: const Icon(LucideIcons.phone),
            ),
            if (onEdit != null)
              IconButton(
                tooltip: AppStrings.helpEditContact.tr(),
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil),
              ),
          ],
        ),
      ],
    ),
  );
}
