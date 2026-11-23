import 'package:click_seguro_app/core/utils/phone_format.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
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
/// lista é curta (validação da usuária, specs/024). As abas em pílula
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
      // "Adicionar contato" no canto de baixo à direita, ao alcance do
      // polegar, na aba dos contatos pessoais (validação da usuária,
      // specs/024).
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: official
          ? null
          : _AddContactButton(onPressed: () => _openForm(context, controller)),
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
    // o topo sumir (validação da usuária, specs/024).
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
              // Igual ao vazio dos "Oficiais": a ilustração e um texto
              // curto; o botão de adicionar fica no canto.
              : Padding(
                  padding: const EdgeInsets.only(
                    bottom: _AddContactButton.clearance,
                  ),
                  child: SafeEmptyState(
                    message: AppStrings.helpPersonalEmpty.tr(),
                  ),
                ),
        ),
      ];
    }
    return [
      SliverPadding(
        // Nos pessoais, espaço embaixo para o botão de adicionar não cobrir
        // o último contato.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          official ? AppSpacing.s5 : _AddContactButton.clearance,
        ),
        sliver: SliverList.list(
          children: [
            for (final contact in contacts)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s3),
                child: _ContactCard(
                  contact: contact,
                  onCall: () => _callNumber(context, controller, contact.phone),
                  // Pessoais: tocar no cartão edita; a lixeira remove.
                  onEdit: official
                      ? null
                      : () => _openForm(
                          context,
                          controller,
                          contactId: contact.id,
                        ),
                  onDelete: official
                      ? null
                      : () => _confirmDelete(context, controller, contact),
                  deleting: controller.isDeleting(contact.id),
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

  /// Confirma e remove o contato pela lixeira do cartão; a falha vira um
  /// aviso (validação da usuária, specs/024).
  Future<void> _confirmDelete(
    BuildContext context,
    HelpController controller,
    ContactEntity contact,
  ) async {
    final bool? confirmed = await showDialog<bool>(
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
    if (confirmed != true || !context.mounted) return;
    final Failure? failure = await controller.deleteContact(contact.id);
    if (failure == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message.tr())));
  }

  /// Liga; sem discador, mostra o número para copiar (CB-009). Vale para
  /// os contatos e para o "Ligar para 190" (FR-016 de specs/024).
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
    this.onDelete,
    this.deleting = false,
  });

  final ContactEntity contact;
  final VoidCallback onCall;

  /// Tocar no cartão abre a edição (só os pessoais).
  final VoidCallback? onEdit;

  /// A lixeira, ao lado de ligar (só os pessoais).
  final VoidCallback? onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final VoidCallback? edit = onEdit;
    final VoidCallback? delete = onDelete;
    return SafeCard(
      interactive: edit != null,
      onTap: edit,
      // O leitor de tela avisa que tocar no cartão abre a edição.
      child: Semantics(
        hint: edit != null ? AppStrings.helpEditContact.tr() : null,
        child: Row(
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
                    style: AppTypography.title3.copyWith(
                      color: colors.textForeground,
                    ),
                  ),
                  Text(
                    formatPhone(contact.phone, shortCodes: true),
                    style: AppTypography.body.copyWith(color: colors.textBody),
                  ),
                  if (contact.description case final String description)
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: colors.textMutedForeground,
                      ),
                    ),
                  if (contact.relationship case final String relationship)
                    Text(
                      relationship,
                      style: AppTypography.caption.copyWith(
                        color: colors.textMutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppStrings.helpCall.tr(args: [contact.name]),
              onPressed: onCall,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(LucideIcons.phone, color: colors.primary),
            ),
            if (delete != null)
              deleting
                  ? SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            semanticsLabel: AppStrings.commonLoading.tr(),
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: AppStrings.helpDeleteContact.tr(),
                      onPressed: delete,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(LucideIcons.trash2, color: colors.destructive),
                    ),
          ],
        ),
      ),
    );
  }
}

/// Botão "Adicionar contato" da aba dos pessoais: pílula coral no canto de
/// baixo à direita, ao alcance do polegar.
class _AddContactButton extends StatelessWidget {
  const _AddContactButton({required this.onPressed});

  /// Espaço que a lista deixa embaixo para o botão não cobrir nada.
  static const double clearance = 104;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return FloatingActionButton.extended(
      key: const ValueKey('help_add_contact'),
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: colors.primary,
      foregroundColor: colors.textPrimaryForeground,
      shape: const StadiumBorder(),
      extendedTextStyle: AppTypography.button,
      icon: const Icon(LucideIcons.userPlus),
      label: Text(AppStrings.helpAddContact.tr()),
    );
  }
}
