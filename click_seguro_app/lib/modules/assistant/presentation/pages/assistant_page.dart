import 'dart:async';

import 'dart:io';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_chip.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/core/widgets/safe_pill_tabs.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller.dart';
import 'package:click_seguro_app/modules/assistant/presentation/controller/assistant_controller_status.dart';
import 'package:click_seguro_app/modules/assistant/presentation/extensions/ai_analysis_presentation_extension.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_analysis_card.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_chat_bubble.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_history_tab.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_typing_bubble.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/chat_message_entrance.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/utils/motion_scroll.dart';
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
        child: SafeEmptyState(
          message: AppStrings.assistantGuestTitle.tr(),
          actionLabel: AppStrings.assistantGuestAction.tr(),
          onAction: () => requireAccount(context),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5),
        child: _PrivacyNote(),
      ),
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

  /// Quantas mensagens já estavam na tela: só as seguintes entram animadas.
  int? _shownMessages;

  /// Leitura em voz alta das respostas, como nas outras telas (validação da
  /// usuária, specs/024): com a leitura automática ligada na
  /// Acessibilidade, a resposta nova e o resultado da verificação são lidos.
  final ReadAloudController _readAloud = GetIt.instance<ReadAloudController>();
  Locale? _locale;

  /// Mensagens da conversa já vistas: só as novas do assistente são lidas.
  int _readMessages = 0;

  /// O resultado já lido (cada análise nova é lida uma vez).
  AiAnalysisEntity? _readAnalysis;

  /// O que está sendo lido: a mensagem ([AiChatTurn]), o resultado
  /// ([AiAnalysisEntity]) ou as boas-vindas ([_greetingId]). Só ele mostra
  /// "Parar"; ao terminar ou parar, volta a nulo (specs/025).
  Object? _speakingId;
  static const Object _greetingId = 'assistant-greeting';

  @override
  void initState() {
    super.initState();
    _readAloud.addListener(_onReadAloudChanged);
  }

  /// Voz verificada, leitura começou ou acabou: os botões se atualizam.
  void _onReadAloudChanged() {
    if (!mounted) return;
    setState(() {
      if (!_readAloud.isSpeaking) _speakingId = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = context.locale;
    if (locale != _locale) {
      _locale = locale;
      unawaited(_readAloud.prepare(locale));
    }
    final next = context.read<AssistantController>();
    if (identical(next, _controller)) return;
    _controller
      ?..removeListener(_scrollChatToEnd)
      ..removeListener(_autoRead);
    _controller = next
      ..addListener(_scrollChatToEnd)
      ..addListener(_autoRead);
    _readMessages = next.chatMessages.length;
    _readAnalysis = next.analysis;
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_scrollChatToEnd)
      ..removeListener(_autoRead);
    _readAloud
      ..removeListener(_onReadAloudChanged)
      ..dispose();
    _chatInput.dispose();
    _analysisInput.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  /// Lê o que chegou de novo: a resposta do assistente ou o resultado.
  void _autoRead() {
    final AssistantController? controller = _controller;
    if (!mounted || controller == null) return;
    final List<AiChatTurn> messages = controller.chatMessages;
    final bool newReply =
        messages.length > _readMessages &&
        messages.last.role == AiChatRole.model;
    _readMessages = messages.length;
    final AiAnalysisEntity? analysis = controller.analysis;
    final bool newAnalysis =
        analysis != null && !identical(analysis, _readAnalysis);
    _readAnalysis = analysis;
    if (!newReply && !newAnalysis) return;
    if (!_canListen ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    if (newAnalysis) {
      _read(analysis, analysis.spokenParts);
    } else {
      _read(messages.last, [SpeechPart(messages.last.content, content: true)]);
    }
  }

  /// Há voz para o idioma do app ou para o português das respostas.
  bool get _canListen =>
      _readAloud.isAvailable || _readAloud.isContentAvailable;

  /// Lê [parts] e marca [id] como o que está tocando. As respostas da IA
  /// vêm em português (assistente de segurança digital brasileira) e saem
  /// na voz em português; os textos do app, no idioma do app (specs/025).
  void _read(Object id, List<SpeechPart> parts) {
    setState(() => _speakingId = id);
    unawaited(_readAloud.speakParts(parts));
  }

  /// "Ouvir" embaixo de uma mensagem ou do resultado: lê [text]; se [id] já
  /// está tocando, para. Sem voz no idioma do app, não aparece.
  Widget? _listenButton(
    Object id,
    String key,
    List<SpeechPart> Function() parts,
  ) {
    if (!_canListen) return null;
    final bool speaking = _readAloud.isSpeaking && identical(_speakingId, id);
    return ListenButton(
      key: ValueKey(key),
      isSpeaking: speaking,
      onPressed: () =>
          speaking ? unawaited(_readAloud.stop()) : _read(id, parts()),
    );
  }

  void _scrollChatToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScroll.hasClients) return;
      unawaited(
        _chatScroll.moveTo(
          _chatScroll.position.maxScrollExtent,
          duration: AppMotion.of(context).medium,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AssistantController controller = context.watch<AssistantController>();
    return Column(
      children: [
        _AssistantHeader(
          onHistory: () => controller.activateTab(AssistantTab.history),
          // "Nova conversa" só faz sentido com mensagens na tela.
          showNewConversation:
              controller.activeTab == AssistantTab.chat &&
              controller.chatMessages.isNotEmpty,
          onNewConversation: controller.isSendingChat ? null : _newConversation,
        ),
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
      final int count = controller.chatMessages.length;
      final int animateFrom = _shownMessages ?? count;
      _shownMessages = count;
      final messages = ListView(
        controller: _chatScroll,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s3,
        ),
        children: [
          // Boas-vindas como o primeiro balão do assistente (redesign 2.0).
          AssistantChatBubble(
            text: _greeting,
            fromUser: false,
            footer: _listenButton(
              _greetingId,
              'assistant-listen-greeting',
              () => [SpeechPart(_greeting)],
            ),
          ),
          // Conversa vazia: um aviso curto e duas sugestões. Depois da
          // primeira mensagem, só os balões.
          if (controller.chatMessages.isEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            const _PrivacyNote(),
            const SizedBox(height: AppSpacing.s4),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final suggestion in [
                  AppStrings.assistantSuggestionLink,
                  AppStrings.assistantSuggestionPrize,
                ])
                  SafeChip(
                    label: suggestion.tr(),
                    selected: false,
                    onTap: () => _fillSuggestion(suggestion.tr()),
                  ),
              ],
            ),
          ],
          for (final (index, message) in controller.chatMessages.indexed)
            ChatMessageEntrance(
              key: ObjectKey(message),
              animate: index >= animateFrom,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s4),
                child: AssistantChatBubble(
                  text: message.content,
                  fromUser: message.role == AiChatRole.user,
                  footer: message.role == AiChatRole.user
                      ? null
                      : _listenButton(
                          message,
                          'assistant-listen-$index',
                          () => [SpeechPart(message.content, content: true)],
                        ),
                ),
              ),
            ),
          if (controller.isSendingChat)
            const ChatMessageEntrance(
              key: ValueKey('assistant-typing'),
              animate: true,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.s4),
                child: AssistantTypingBubble(),
              ),
            ),
          if (controller.chatFailure != null) ...[
            const SizedBox(height: AppSpacing.s4),
            _FailureMessage(
              message: controller.chatFailure!.message.tr(),
              retryLabel: AppStrings.assistantChatRetry.tr(),
              showRetry:
                  controller.chatFailure is! AssistantInvalidInputFailure,
              onRetry: controller.isSendingChat
                  ? null
                  : controller.retryChatMessage,
            ),
          ],
        ],
      );
      final composer = _ChatComposer(
        controller: controller,
        textController: _chatInput,
        onSubmit: _submitChat,
        onCamera: _openCamera,
      );
      // A mesma estrutura em qualquer altura: trocar de layout quando o
      // teclado abria recriava o campo, que perdia o foco e fechava o
      // teclado. Com pouca altura ou letra grande, o rodapé fica limitado à
      // metade da área e rola.
      return Column(
        children: [
          Expanded(child: messages),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
            child: SingleChildScrollView(child: composer),
          ),
        ],
      );
    },
  );

  String get _greeting =>
      '${AppStrings.assistantGreeting.tr()} '
      '${AppStrings.assistantChatIntro.tr()}';

  void _fillSuggestion(String text) {
    _chatInput.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _submitChat() async {
    final text = _chatInput.text;
    if (text.trim().length >= AssistantLimits.chatMessageMin &&
        text.trim().length <= AssistantLimits.chatMessageMax) {
      final pending = context.read<AssistantController>().sendChatMessage(text);
      _chatInput.clear();
      await pending;
    } else {
      await context.read<AssistantController>().sendChatMessage(text);
    }
  }

  /// Câmera do rodapé (redesign 2.0): leva à verificação de imagem, que é
  /// onde a foto é analisada, e já abre a câmera.
  Future<void> _openCamera() async {
    final AssistantController controller = context.read<AssistantController>();
    controller.activateTab(AssistantTab.verify);
    await controller.setAnalysisMode(AssistantAnalysisMode.image);
    await controller.pickImage(PhotoSource.camera);
  }

  /// Ícone do topo, que só aparece quando já há mensagens na conversa.
  Future<void> _newConversation() async {
    final AssistantController controller = context.read<AssistantController>();
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
    imageMode: controller.analysisMode == AssistantAnalysisMode.image,
    source: controller.analysisSource,
    textController: _analysisInput,
    controller: controller,
    onModeChanged: (imageMode) => controller.setAnalysisMode(
      imageMode ? AssistantAnalysisMode.image : AssistantAnalysisMode.text,
    ),
    onSourceChanged: controller.setAnalysisSource,
    onAnalyzeText: _runTextAnalysis,
    onRetry: controller.retryAnalysis,
    listenButton: switch (controller.analysis) {
      final AiAnalysisEntity analysis => _listenButton(
        analysis,
        'assistant-listen-analysis',
        () => analysis.spokenParts,
      ),
      null => null,
    },
  );

  Future<void> _runTextAnalysis() =>
      context.read<AssistantController>().analyzeText(_analysisInput.text);
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    this.onHistory,
    this.showNewConversation = false,
    this.onNewConversation,
  });

  /// Abre o histórico; sem ele (visitante), o botão de relógio não aparece.
  final VoidCallback? onHistory;

  /// Mostra o ícone de "Nova conversa"; [onNewConversation] nulo o desativa.
  final bool showNewConversation;
  final VoidCallback? onNewConversation;

  // Topo do redesign 2.0: voltar redondo, título e o histórico à direita.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s5,
      AppSpacing.s3,
      AppSpacing.s5,
      AppSpacing.s3,
    ),
    child: Row(
      children: [
        SafeIconButton(
          key: const ValueKey('assistant-back'),
          icon: LucideIcons.chevronLeft,
          semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        const SizedBox(width: AppSpacing.s4),
        Expanded(
          child: Semantics(
            header: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                AppStrings.assistantTitle.tr(),
                maxLines: 1,
                style: AppTypography.title1.copyWith(
                  color: context.colors.textForeground,
                ),
              ),
            ),
          ),
        ),
        if (showNewConversation) ...[
          const SizedBox(width: AppSpacing.s3),
          SafeIconButton(
            key: const ValueKey('assistant-new-conversation'),
            icon: LucideIcons.messageSquarePlus,
            semanticLabel: AppStrings.assistantNewConversation.tr(),
            onPressed: onNewConversation,
          ),
        ],
        if (onHistory case final VoidCallback open) ...[
          const SizedBox(width: AppSpacing.s3),
          SafeIconButton(
            key: const ValueKey('assistant-history-button'),
            icon: LucideIcons.history,
            semanticLabel: AppStrings.assistantTabHistory.tr(),
            onPressed: open,
          ),
        ],
      ],
    ),
  );
}

class _AssistantTabs extends StatelessWidget {
  const _AssistantTabs({required this.activeTab, required this.onSelect});
  final AssistantTab activeTab;
  final ValueChanged<AssistantTab> onSelect;

  /// O histórico saiu das abas e foi para o botão do topo (redesign 2.0);
  /// enquanto ele está aberto, nenhuma das duas abas fica marcada.
  static const List<(AssistantTab, String)> _tabs = [
    (AssistantTab.chat, AppStrings.assistantTabChat),
    (AssistantTab.verify, AppStrings.assistantTabVerify),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
    child: SafePillTabs(
      tabs: [for (final (_, label) in _tabs) label.tr()],
      selectedIndex: _tabs.indexWhere((t) => t.$1 == activeTab),
      onChanged: (index) => onSelect(_tabs[index].$1),
    ),
  );
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.textController,
    required this.onSubmit,
    required this.onCamera,
  });
  final AssistantController controller;
  final TextEditingController textController;
  final VoidCallback onSubmit;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool canSend =
        !controller.isSendingChat &&
        (controller.chatFailure == null ||
            controller.chatFailure is AssistantInvalidInputFailure);
    final OutlineInputBorder pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: BorderSide(color: colors.inputBorder, width: 1.5),
    );
    // Rodapé do redesign 2.0: câmera, campo em pílula e o botão coral.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          AppSpacing.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SafeIconButton(
                key: const ValueKey('assistant-chat-camera'),
                icon: LucideIcons.camera,
                semanticLabel: AppStrings.assistantImageCamera.tr(),
                onPressed: controller.isAnalyzing || controller.isPickingImage
                    ? null
                    : onCamera,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: TextField(
                key: const ValueKey('assistant-chat-input'),
                controller: textController,
                minLines: 1,
                maxLines: 4,
                maxLength: AssistantLimits.chatMessageMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                buildCounter: _nearLimitCounter,
                textInputAction: TextInputAction.newline,
                style: AppTypography.bodyLarge.copyWith(
                  color: colors.textForeground,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.assistantChatPlaceholder.tr(),
                  hintStyle: AppTypography.bodyLarge.copyWith(
                    color: colors.textMutedForeground,
                  ),
                  filled: true,
                  fillColor: colors.card,
                  border: pill,
                  enabledBorder: pill,
                  focusedBorder: pill.copyWith(
                    borderSide: BorderSide(color: colors.secondary, width: 2.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            _SendButton(
              sending: controller.isSendingChat,
              onPressed: canSend ? onSubmit : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Contador de caracteres que só aparece perto do limite (a partir de 80%),
/// para não ocupar a tela enquanto a mensagem é curta.
Widget? _nearLimitCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) {
  if (maxLength == null || currentLength < maxLength * 0.8) return null;
  return Text(
    AppStrings.assistantCharacters.tr(
      namedArgs: {'count': '$currentLength', 'limit': '$maxLength'},
    ),
    style: AppTypography.caption.copyWith(
      color: currentLength >= maxLength
          ? context.colors.destructive
          : context.colors.textMutedForeground,
    ),
  );
}

/// Mensagem de erro sem caixa em volta, com o botão de tentar de novo.
class _FailureMessage extends StatelessWidget {
  const _FailureMessage({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.showRetry = true,
  });

  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final bool showRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        message,
        style: AppTypography.body.copyWith(color: context.colors.destructive),
      ),
      if (showRetry) ...[
        const SizedBox(height: AppSpacing.s2),
        SafeButton(
          label: retryLabel,
          size: SafeButtonSize.compact,
          tone: SafeButtonTone.ghost,
          icon: const Icon(LucideIcons.rotateCcw),
          onPressed: onRetry,
        ),
      ],
    ],
  );
}

/// Botão redondo coral de enviar (52 dp, acima do mínimo de 48). Enquanto a
/// resposta chega, mostra o progresso no lugar do ícone.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onPressed});

  final bool sending;
  final VoidCallback? onPressed;

  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool enabled = onPressed != null;
    return Semantics(
      key: const ValueKey('assistant-chat-send'),
      button: true,
      enabled: enabled,
      label: AppStrings.assistantChatSend.tr(),
      // O excludeSemantics tira a ação do InkWell: ela vem daqui.
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: enabled || sending ? colors.primary : colors.surfaceStrong,
              shape: BoxShape.circle,
              border: colors.shadow.isEmpty
                  ? Border.all(color: colors.border)
                  : null,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Center(
                child: sending
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.textPrimaryForeground,
                        ),
                      )
                    : Icon(
                        LucideIcons.send,
                        size: 22,
                        color: enabled
                            ? colors.textPrimaryForeground
                            : colors.textMutedForeground,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    this.listenButton,
  });
  final bool imageMode;
  final String? source;
  final TextEditingController textController;
  final AssistantController controller;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String?> onSourceChanged;
  final VoidCallback onAnalyzeText;
  final VoidCallback onRetry;

  /// "Ouvir" do resultado; nulo sem voz no idioma do app.
  final Widget? listenButton;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s5,
      AppSpacing.s5,
      AppSpacing.s5,
      AppSpacing.s5,
    ),
    children: [
      // Texto ou imagem: as mesmas abas em pílula do topo, sem troca enquanto
      // analisa ou escolhe a foto.
      SafePillTabs(
        tabs: [
          AppStrings.assistantVerifyText.tr(),
          AppStrings.assistantVerifyImage.tr(),
        ],
        selectedIndex: imageMode ? 1 : 0,
        onChanged: (index) {
          if (controller.isAnalyzing || controller.isPickingImage) return;
          onModeChanged(index == 1);
        },
      ),
      const SizedBox(height: AppSpacing.s5),
      if (imageMode)
        _ImagePicker(controller: controller)
      else
        _TextAnalysisField(controller: textController),
      const SizedBox(height: AppSpacing.s5),
      Text(
        AppStrings.assistantSource.tr(),
        style: AppTypography.label.copyWith(
          color: context.colors.textForeground,
        ),
      ),
      const SizedBox(height: AppSpacing.s2),
      Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s2,
        children: [
          for (final (value, key) in <(String?, String)>[
            (
              AssistantAnalysisSources.whatsapp,
              AppStrings.assistantSourceWhatsapp,
            ),
            (AssistantAnalysisSources.sms, AppStrings.assistantSourceSms),
            (AssistantAnalysisSources.email, AppStrings.assistantSourceEmail),
            (AssistantAnalysisSources.other, AppStrings.assistantSourceOther),
          ])
            SafeChip(
              label: key.tr(),
              selected: source == value,
              onTap: () => onSourceChanged(source == value ? null : value),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.s5),
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
                textController.text.trim().length <
                    AssistantLimits.analysisTextMin ||
                textController.text.trim().length >
                    AssistantLimits.analysisTextMax,
            icon: const Icon(LucideIcons.scanSearch),
            onPressed: onAnalyzeText,
          ),
        ),
      if (controller.analysisFailure != null) ...[
        const SizedBox(height: AppSpacing.s4),
        _FailureMessage(
          message: controller.analysisFailure!.message.tr(),
          retryLabel: AppStrings.commonTryAgain.tr(),
          onRetry: onRetry,
        ),
      ],
      if (controller.analysis != null) ...[
        const SizedBox(height: AppSpacing.s5),
        AssistantAnalysisCard(
          analysis: controller.analysis!,
          footer: listenButton,
        ),
      ],
      const SizedBox(height: AppSpacing.s5),
      const _PrivacyNote(),
    ],
  );
}

class _TextAnalysisField extends StatelessWidget {
  const _TextAnalysisField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('assistant-analysis-text'),
    controller: controller,
    minLines: 5,
    maxLines: 9,
    maxLength: AssistantLimits.analysisTextMax,
    maxLengthEnforcement: MaxLengthEnforcement.enforced,
    buildCounter: _nearLimitCounter,
    style: AppTypography.bodyLarge.copyWith(
      color: context.colors.textForeground,
    ),
    decoration: InputDecoration(
      hintText: AppStrings.assistantTextPlaceholder.tr(),
      alignLabelWithHint: true,
    ),
  );
}

/// Galeria ou câmera; com a foto escolhida, a prévia e o botão de remover.
/// Os formatos e o limite de 5 MB aparecem no erro, se a foto não servir.
class _ImagePicker extends StatelessWidget {
  const _ImagePicker({required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (controller.selectedImagePath case final path?) ...[
        ClipRRect(
          borderRadius: AppSpacing.radiusMd,
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
          style: AppTypography.body.copyWith(color: context.colors.warning),
        ),
      ],
      if (controller.imagePickFailed) ...[
        const SizedBox(height: AppSpacing.s2),
        Text(
          AppStrings.assistantImagePickFailed.tr(),
          style: AppTypography.body.copyWith(color: context.colors.destructive),
        ),
      ],
    ],
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
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
            style: AppTypography.caption.copyWith(
              color: context.colors.textMutedForeground,
            ),
          ),
        ),
      ],
    ),
  );
}
