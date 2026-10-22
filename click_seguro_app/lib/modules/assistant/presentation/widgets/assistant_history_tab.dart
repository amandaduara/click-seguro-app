import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller_status.dart';
import 'package:click_seguro_app/modules/assistant/presentation/extensions/ai_threat_type_presentation_extension.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_analysis_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class AssistantHistoryTab extends StatelessWidget {
  const AssistantHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.watch<AssistantController>();
    return Column(
      children: [
        _HistoryFilters(controller: controller),
        Expanded(child: _HistoryContent(controller: controller)),
      ],
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s5,
      vertical: AppSpacing.s2,
    ),
    child: Row(
      children: [
        for (final (filter, label) in [
          (AssistantHistoryFilter.all, AppStrings.assistantHistoryAll),
          (
            AssistantHistoryFilter.analyses,
            AppStrings.assistantHistoryAnalyses,
          ),
          (
            AssistantHistoryFilter.conversations,
            AppStrings.assistantHistoryConversations,
          ),
        ]) ...[
          Semantics(
            button: true,
            selected: controller.historyFilter == filter,
            label: label.tr(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: ChoiceChip(
                label: Text(label.tr()),
                selected: controller.historyFilter == filter,
                onSelected: (_) => controller.setHistoryFilter(filter),
                labelStyle: TextStyle(
                  color: controller.historyFilter == filter
                      ? context.colors.textPrimaryForeground
                      : context.colors.textMutedForeground,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: context.colors.secondary,
                backgroundColor: context.colors.input,
                side: BorderSide(color: context.colors.border),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: AppSpacing.s1,
                ),
              ),
            ),
          ),
          if (filter != AssistantHistoryFilter.conversations)
            const SizedBox(width: AppSpacing.s2),
        ],
      ],
    ),
  );
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.historyItems;
    if (controller.isHistoryLoading && items.isEmpty) {
      return const SafeLoadingState();
    }
    if (controller.historyFailure != null && items.isEmpty) {
      return _scrollableState(
        controller,
        SafeErrorState(
          message: controller.historyFailure!.message.tr(),
          onRetry: controller.retryHistory,
        ),
      );
    }
    if (items.isEmpty) {
      return _scrollableState(
        controller,
        SafeEmptyState(
          icon: LucideIcons.clock3,
          message:
              (controller.historyFilter == AssistantHistoryFilter.all
                      ? AppStrings.assistantHistoryEmpty
                      : AppStrings.assistantHistoryEmptyFilter)
                  .tr(),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refreshHistory,
      child: ListView.separated(
        key: const ValueKey('assistant-history-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        itemCount:
            items.length +
            (controller.historyHasNextPage ||
                    controller.isHistoryLoading ||
                    controller.historyFailure != null
                ? 1
                : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _HistoryFooter(controller: controller);
          }
          return _HistoryItem(analysis: items[index]);
        },
      ),
    );
  }

  Widget _scrollableState(AssistantController controller, Widget child) =>
      RefreshIndicator(
        onRefresh: controller.refreshHistory,
        child: ListView(
          key: const ValueKey('assistant-history-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          children: [child],
        ),
      );
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isHistoryLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.s4),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.historyFailure != null) {
      return SafeCard(
        child: Column(
          children: [
            Text(
              controller.historyFailure!.message.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s2),
            SafeButton(
              label: AppStrings.commonTryAgain.tr(),
              size: SafeButtonSize.compact,
              onPressed: controller.retryHistory,
            ),
          ],
        ),
      );
    }
    return Center(
      child: SafeButton(
        label: AppStrings.assistantHistoryLoadMore.tr(),
        size: SafeButtonSize.compact,
        tone: SafeButtonTone.ghost,
        onPressed: controller.loadNextHistoryPage,
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.analysis});
  final AiAnalysisEntity analysis;

  @override
  Widget build(BuildContext context) {
    final bool chat = analysis.feature == AiAnalysisFeature.chat;
    final String date = _formatDate(context, analysis.createdAt);
    if (chat) {
      return SafeCard(
        padded: false,
        child: ListTile(
          minLeadingWidth: 44,
          leading: const _IconTile(icon: LucideIcons.messageCircle),
          title: Text(
            AppStrings.assistantHistoryConversationRecorded.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            date,
            style: TextStyle(color: context.colors.textMutedForeground),
          ),
        ),
      );
    }
    return SafeCard(
      padded: false,
      child: ExpansionTile(
        leading: const _IconTile(icon: LucideIcons.shieldCheck),
        title: Text(
          analysis.threatType.labelKey.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          date,
          style: TextStyle(color: context.colors.textMutedForeground),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.s3,
          0,
          AppSpacing.s3,
          AppSpacing.s3,
        ),
        children: [AssistantAnalysisCard(analysis: analysis)],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) =>
      DateFormat.yMd(context.locale.toString()).format(date.toLocal());
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: context.colors.primary),
  );
}
