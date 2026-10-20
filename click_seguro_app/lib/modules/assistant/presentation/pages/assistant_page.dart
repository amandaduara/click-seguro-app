import 'dart:io';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller_status.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_analysis_card.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_history_tab.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.background,
    body: SafeArea(
      child: ValueListenableBuilder<UserSessionStatus>(
        valueListenable: GetIt.instance<UserSessionService>().sessionStatus,
        builder: (context, status, _) =>
            status == UserSessionStatus.authenticated
            ? ChangeNotifierProvider<AssistantController>(
                create: (_) => GetIt.instance<AssistantController>(),
                child: const _AssistantSignedInView(),
              )
            : const _AssistantGuestView(),
      ),
    ),
  );
}

class _AssistantGuestView extends StatelessWidget {
  const _AssistantGuestView();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _AssistantHeader(),
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: SafeCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AssistantShield(size: 64),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    AppStrings.assistantGuestTitle.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    AppStrings.assistantGuestBody.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textMutedForeground),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  SafeButton(
                    label: AppStrings.assistantGuestAction.tr(),
                    icon: const Icon(LucideIcons.logIn),
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const _PrivacyNote(),
    ],
  );
}

class _AssistantSignedInView extends StatefulWidget {
  const _AssistantSignedInView();

  @override
  State<_AssistantSignedInView> createState() => _AssistantSignedInViewState();
}

class _AssistantSignedInViewState extends State<_AssistantSignedInView> {
  final TextEditingController _chatInput = TextEditingController();
  final TextEditingController _analysisInput = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  AssistantController? _controller;
  bool _imageMode = false;
  String? _source;
  String? _lastText;
  String? _lastTextSource;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AssistantController>();
    if (identical(next, _controller)) return;
    _controller?.removeListener(_scrollChatToEnd);
    _controller = next..addListener(_scrollChatToEnd);
  }

  @override
  void dispose() {
    _controller?.removeListener(_scrollChatToEnd);
    _chatInput.dispose();
    _analysisInput.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _scrollChatToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.watch<AssistantController>();
    return Column(
      children: [
        const _AssistantHeader(),
        _AssistantTabs(
          activeTab: controller.activeTab,
          onSelect: controller.activateTab,
        ),
        Expanded(
          child: switch (controller.activeTab) {
            AssistantTab.chat => _chatArea(controller),
            AssistantTab.verify => _verifyArea(controller),
            AssistantTab.history => const AssistantHistoryTab(),
          },
        ),
      ],
    );
  }

  Widget _chatArea(AssistantController controller) => LayoutBuilder(
    builder: (context, constraints) {
      final messages = ListView(
        controller: _chatScroll,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s3,
        ),
        children: [
          SafeCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AssistantShield(size: 44),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.assistantGreeting.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.colors.secondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        AppStrings.assistantChatIntro.tr(),
                        style: TextStyle(
                          color: context.colors.textMutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _PrivacyNote(),
          if (controller.chatMessages.isEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Text(
              AppStrings.assistantHeaderDescription.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                _SuggestionChip(
                  label: AppStrings.assistantSuggestionLink.tr(),
                  onTap: () =>
                      _fillSuggestion(AppStrings.assistantSuggestionLink.tr()),
                ),
                _SuggestionChip(
                  label: AppStrings.assistantSuggestionPrize.tr(),
                  onTap: () =>
                      _fillSuggestion(AppStrings.assistantSuggestionPrize.tr()),
                ),
                _SuggestionChip(
                  label: AppStrings.assistantSuggestionBank.tr(),
                  onTap: () =>
                      _fillSuggestion(AppStrings.assistantSuggestionBank.tr()),
                ),
              ],
            ),
          ],
          for (final message in controller.chatMessages) ...[
            const SizedBox(height: AppSpacing.s3),
            _ChatBubble(message: message),
          ],
          if (controller.chatFailure != null) ...[
            const SizedBox(height: AppSpacing.s3),
            SafeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.chatFailure!.message.tr(),
                    style: TextStyle(color: context.colors.destructive),
                  ),
                  if (controller.chatFailure
                      is! AssistantInvalidInputFailure) ...[
                    const SizedBox(height: AppSpacing.s2),
                    SafeButton(
                      label: AppStrings.assistantChatRetry.tr(),
                      size: SafeButtonSize.compact,
                      icon: const Icon(LucideIcons.rotateCcw),
                      onPressed: controller.isSendingChat
                          ? null
                          : controller.retryChatMessage,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
      final composer = _ChatComposer(
        controller: controller,
        textController: _chatInput,
        onSubmit: _submitChat,
        onNewConversation: _newConversation,
      );
      final compact =
          constraints.maxHeight < 480 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.5;
      if (compact) {
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        return Column(
          children: [
            Expanded(flex: keyboardOpen ? 1 : 2, child: messages),
            Expanded(
              flex: keyboardOpen ? 2 : 1,
              child: SingleChildScrollView(child: composer),
            ),
          ],
        );
      }
      return Column(
        children: [
          Expanded(child: messages),
          composer,
        ],
      );
    },
  );

  void _fillSuggestion(String text) {
    _chatInput.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _submitChat() async {
    final text = _chatInput.text;
    await context.read<AssistantController>().sendChatMessage(text);
    if (!mounted) return;
    if (context.read<AssistantController>().chatFailure
        is! AssistantInvalidInputFailure) {
      _chatInput.clear();
    }
  }

  Future<void> _newConversation() async {
    final AssistantController controller = context.read<AssistantController>();
    if (controller.chatMessages.isEmpty) {
      controller.startNewConversation();
      _chatInput.clear();
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(AppStrings.assistantNewConversationTitle.tr()),
        content: Text(AppStrings.assistantNewConversationBody.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.assistantCancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.assistantNewConversationConfirm.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      controller.startNewConversation();
      _chatInput.clear();
    }
  }

  Widget _verifyArea(AssistantController controller) => _VerifyArea(
    imageMode: _imageMode,
    source: _source,
    textController: _analysisInput,
    controller: controller,
    onModeChanged: (imageMode) async {
      if (_imageMode && !imageMode) await controller.removeSelectedImage();
      if (mounted) setState(() => _imageMode = imageMode);
    },
    onSourceChanged: (source) => setState(() => _source = source),
    onAnalyzeText: _runTextAnalysis,
    onRetry: () {
      if (_imageMode && controller.selectedImagePath != null) {
        controller.analyzeSelectedImage(source: _source);
      } else if (_lastText != null) {
        context.read<AssistantController>().analyzeText(
          _lastText!,
          source: _lastTextSource,
        );
      }
    },
  );

  Future<void> _runTextAnalysis() async {
    _lastText = _analysisInput.text;
    _lastTextSource = _source;
    await context.read<AssistantController>().analyzeText(
      _analysisInput.text,
      source: _source,
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s4,
      AppSpacing.s3,
      AppSpacing.s4,
      AppSpacing.s2,
    ),
    child: Row(
      children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: Material(
            color: context.colors.card,
            shape: CircleBorder(side: BorderSide(color: context.colors.border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              child: const SizedBox.square(
                dimension: 48,
                child: Icon(LucideIcons.arrowLeft),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        const _AssistantShield(size: 48),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SafeNews',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
              Text(
                AppStrings.assistantTitle.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colors.secondary,
                ),
              ),
              Text(
                AppStrings.assistantSubtitle.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textMutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AssistantShield extends StatelessWidget {
  const _AssistantShield({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(
      LucideIcons.shieldCheck,
      size: size * 0.5,
      color: context.colors.primary,
    ),
  );
}

class _AssistantTabs extends StatelessWidget {
  const _AssistantTabs({required this.activeTab, required this.onSelect});
  final AssistantTab activeTab;
  final ValueChanged<AssistantTab> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s5,
      vertical: AppSpacing.s2,
    ),
    child: Row(
      children: [
        for (final (tab, label, icon) in [
          (
            AssistantTab.chat,
            AppStrings.assistantTabChat,
            LucideIcons.messageCircle,
          ),
          (
            AssistantTab.verify,
            AppStrings.assistantTabVerify,
            LucideIcons.scanSearch,
          ),
          (
            AssistantTab.history,
            AppStrings.assistantTabHistory,
            LucideIcons.clock3,
          ),
        ]) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 18,
                color: activeTab == tab
                    ? context.colors.textPrimaryForeground
                    : context.colors.textMutedForeground,
              ),
              label: Text(label.tr()),
              selected: activeTab == tab,
              onSelected: (_) => onSelect(tab),
              labelStyle: TextStyle(
                color: activeTab == tab
                    ? context.colors.textPrimaryForeground
                    : context.colors.textMutedForeground,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: context.colors.secondary,
              backgroundColor: context.colors.card,
              side: BorderSide(color: context.colors.border),
              showCheckmark: false,
            ),
          ),
          if (tab != AssistantTab.history) const SizedBox(width: AppSpacing.s2),
        ],
      ],
    ),
  );
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width - AppSpacing.s5 * 2,
      minHeight: 48,
    ),
    child: Material(
      color: context.colors.card,
      shape: StadiumBorder(side: BorderSide(color: context.colors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Text(
            label,
            softWrap: true,
            style: TextStyle(color: context.colors.textForeground),
          ),
        ),
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool user = message.role == AiChatRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: user
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: AppSpacing.radius2xl,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      color: context.colors.textPrimaryForeground,
                    ),
                  ),
                ),
              )
            : SafeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _AssistantShield(size: 32),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          'SafeNews',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.colors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    SelectableText(
                      message.content,
                      style: TextStyle(color: context.colors.textForeground),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.textController,
    required this.onSubmit,
    required this.onNewConversation,
  });
  final AssistantController controller;
  final TextEditingController textController;
  final VoidCallback onSubmit;
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s4,
      AppSpacing.s2,
      AppSpacing.s4,
      AppSpacing.s2,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s2),
          decoration: BoxDecoration(
            color: context.colors.card,
            border: Border.all(color: context.colors.border),
            borderRadius: AppSpacing.radius2xl,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('assistant-chat-input'),
                  controller: textController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(color: context.colors.textForeground),
                  decoration: InputDecoration(
                    hintText: AppStrings.assistantChatPlaceholder.tr(),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2,
                      vertical: AppSpacing.s2,
                    ),
                  ),
                ),
              ),
              IconButton.filled(
                key: const ValueKey('assistant-chat-send'),
                tooltip: AppStrings.assistantChatSend.tr(),
                onPressed:
                    controller.isSendingChat ||
                        controller.chatFailure != null &&
                            controller.chatFailure
                                is! AssistantInvalidInputFailure
                    ? null
                    : onSubmit,
                icon: controller.isSendingChat
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.send),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s1),
        ListenableBuilder(
          listenable: textController,
          builder: (context, _) => Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppStrings.assistantCharacters.tr(
                namedArgs: {
                  'count': '${textController.text.length}',
                  'limit': '1000',
                },
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textMutedForeground,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: controller.isSendingChat ? null : onNewConversation,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(AppStrings.assistantNewConversation.tr()),
          ),
        ),
      ],
    ),
  );
}

class _VerifyArea extends StatelessWidget {
  const _VerifyArea({
    required this.imageMode,
    required this.source,
    required this.textController,
    required this.controller,
    required this.onModeChanged,
    required this.onSourceChanged,
    required this.onAnalyzeText,
    required this.onRetry,
  });
  final bool imageMode;
  final String? source;
  final TextEditingController textController;
  final AssistantController controller;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String?> onSourceChanged;
  final VoidCallback onAnalyzeText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s5,
      AppSpacing.s2,
      AppSpacing.s5,
      AppSpacing.s5,
    ),
    children: [
      Text(
        AppStrings.assistantVerifyingTitle.tr(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.secondary,
        ),
      ),
      const SizedBox(height: AppSpacing.s3),
      Wrap(
        spacing: AppSpacing.s2,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: ChoiceChip(
              label: Text(AppStrings.assistantVerifyText.tr()),
              selected: !imageMode,
              onSelected: (_) => onModeChanged(false),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: ChoiceChip(
              label: Text(AppStrings.assistantVerifyImage.tr()),
              selected: imageMode,
              onSelected: (_) => onModeChanged(true),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.s4),
      if (imageMode)
        _ImagePickerCard(controller: controller)
      else
        _TextAnalysisField(controller: textController),
      const SizedBox(height: AppSpacing.s4),
      Text(
        AppStrings.assistantSource.tr(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.secondary,
        ),
      ),
      const SizedBox(height: AppSpacing.s2),
      Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s2,
        children: [
          for (final (value, key) in <(String?, String)>[
            ('WHATSAPP', AppStrings.assistantSourceWhatsapp),
            ('SMS', AppStrings.assistantSourceSms),
            ('EMAIL', AppStrings.assistantSourceEmail),
            ('OTHER', AppStrings.assistantSourceOther),
          ])
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: ChoiceChip(
                label: Text(key.tr()),
                selected: source == value,
                onSelected: (_) =>
                    onSourceChanged(source == value ? null : value),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.s4),
      if (imageMode)
        SafeButton(
          label: AppStrings.assistantAnalyze.tr(),
          loading: controller.isAnalyzing,
          disabled:
              controller.selectedImagePath == null || controller.isPickingImage,
          icon: const Icon(LucideIcons.scanSearch),
          onPressed: () => controller.analyzeSelectedImage(source: source),
        )
      else
        ListenableBuilder(
          listenable: textController,
          builder: (context, _) => SafeButton(
            label: AppStrings.assistantAnalyze.tr(),
            loading: controller.isAnalyzing,
            disabled:
                textController.text.trim().length < 10 ||
                textController.text.trim().length > 5000,
            icon: const Icon(LucideIcons.scanSearch),
            onPressed: onAnalyzeText,
          ),
        ),
      if (controller.analysisFailure != null) ...[
        const SizedBox(height: AppSpacing.s3),
        SafeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.analysisFailure!.message.tr(),
                style: TextStyle(color: context.colors.destructive),
              ),
              const SizedBox(height: AppSpacing.s2),
              SafeButton(
                label: AppStrings.commonTryAgain.tr(),
                size: SafeButtonSize.compact,
                icon: const Icon(LucideIcons.rotateCcw),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
      if (controller.analysis != null) ...[
        const SizedBox(height: AppSpacing.s4),
        AssistantAnalysisCard(analysis: controller.analysis!),
      ],
      const _PrivacyNote(),
    ],
  );
}

class _TextAnalysisField extends StatelessWidget {
  const _TextAnalysisField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => SafeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('assistant-analysis-text'),
          controller: controller,
          minLines: 5,
          maxLines: 9,
          maxLength: 5000,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          style: TextStyle(color: context.colors.textForeground),
          decoration: InputDecoration(
            hintText: AppStrings.assistantTextPlaceholder.tr(),
            alignLabelWithHint: true,
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppStrings.assistantCharacters.tr(
                namedArgs: {
                  'count': '${controller.text.length}',
                  'limit': '5000',
                },
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textMutedForeground,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) => SafeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.assistantImageLimit.tr(),
          style: TextStyle(color: context.colors.textMutedForeground),
        ),
        const SizedBox(height: AppSpacing.s3),
        if (controller.selectedImagePath case final path?) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 120,
                  child: Center(child: Icon(LucideIcons.imageOff)),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          SafeButton(
            label: AppStrings.assistantImageRemove.tr(),
            size: SafeButtonSize.compact,
            tone: SafeButtonTone.ghost,
            icon: const Icon(LucideIcons.trash2),
            disabled: controller.isAnalyzing,
            onPressed: controller.removeSelectedImage,
          ),
        ] else
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              SafeButton(
                label: AppStrings.assistantImageGallery.tr(),
                size: SafeButtonSize.compact,
                icon: const Icon(LucideIcons.images),
                loading: controller.isPickingImage,
                disabled: controller.isAnalyzing,
                onPressed: () => controller.pickImage(PhotoSource.gallery),
              ),
              SafeButton(
                label: AppStrings.assistantImageCamera.tr(),
                size: SafeButtonSize.compact,
                icon: const Icon(LucideIcons.camera),
                disabled: controller.isAnalyzing || controller.isPickingImage,
                onPressed: () => controller.pickImage(PhotoSource.camera),
              ),
            ],
          ),
        if (controller.imagePermissionDenied) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            AppStrings.assistantImagePermission.tr(),
            style: TextStyle(color: context.colors.warning),
          ),
        ],
        if (controller.imagePickFailed) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            AppStrings.assistantImagePickFailed.tr(),
            style: TextStyle(color: context.colors.destructive),
          ),
        ],
      ],
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s5,
      AppSpacing.s1,
      AppSpacing.s5,
      AppSpacing.s2,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.lockKeyhole,
          size: 16,
          color: context.colors.textMutedForeground,
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Text(
            AppStrings.assistantPrivacy.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textMutedForeground,
            ),
          ),
        ),
      ],
    ),
  );
}
