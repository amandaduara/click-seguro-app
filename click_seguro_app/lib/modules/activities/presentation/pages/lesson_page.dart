import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_status.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/answer_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/lesson_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/confirm_answer_footer.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/feedback_sheet.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_progress_indicator.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Perguntas de um módulo, uma por vez (B2, specs/017-perguntas-atividades).
class LessonPage extends StatelessWidget {
  const LessonPage({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LessonController>(
      create: (_) => GetIt.instance<LessonController>()..load(moduleId),
      child: _LessonScaffold(moduleId: moduleId),
    );
  }
}

/// Também cuida da voz: "Ouvir", leitura automática uma vez por pergunta e
/// parar ao trocar de pergunta ou sair (R5, R6), como no detalhe da notícia.
class _LessonScaffold extends StatefulWidget {
  const _LessonScaffold({required this.moduleId});

  final String moduleId;

  @override
  State<_LessonScaffold> createState() => _LessonScaffoldState();
}

class _LessonScaffoldState extends State<_LessonScaffold> {
  late final LessonController _controller;
  late final ReadAloudController _readAloud;
  Locale? _locale;
  int? _shownIndex;

  /// A pergunta na tela já foi lida sozinha. Volta a `false` a cada troca de
  /// pergunta: voltar ou avançar para uma pergunta lê de novo (relato do
  /// aparelho, 2026-10-22); a mesma pergunta na tela não repete.
  bool _autoReadDone = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<LessonController>();
    _readAloud = GetIt.instance<ReadAloudController>();
    _controller.addListener(_onLessonChanged);
    _readAloud.addListener(_maybeAutoRead);
  }

  /// O idioma da voz é o do app: prepara de novo se ele mudar.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = context.locale;
    if (locale == _locale) return;
    _locale = locale;
    unawaited(_readAloud.prepare(locale));
  }

  @override
  void dispose() {
    _controller.removeListener(_onLessonChanged);
    _readAloud.removeListener(_maybeAutoRead);
    _readAloud.dispose();
    super.dispose();
  }

  void _onLessonChanged() {
    if (_controller.status != LessonStatus.loaded) return;
    final int index = _controller.currentIndex;
    if (_shownIndex != null && index != _shownIndex) {
      // Antes do parar: o aviso de "parado" já pode ler a pergunta nova.
      _shownIndex = index;
      _autoReadDone = false;
      unawaited(_readAloud.stop());
    }
    _shownIndex = index;
    _maybeAutoRead();
  }

  void _maybeAutoRead() {
    final LessonEntity? lesson = _controller.current;
    if (!mounted ||
        _controller.status != LessonStatus.loaded ||
        lesson == null ||
        _autoReadDone ||
        !_readAloud.isAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _autoReadDone = true;
    unawaited(_readAloud.speak(lesson.spokenText));
  }

  /// A leitura da pergunta para antes do envio (FR-017).
  Future<void> _confirm() async {
    unawaited(_readAloud.stop());
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AnswerAttempt attempt = await _controller.confirm();
    if (!mounted) return;
    final String? message = switch (attempt) {
      AnswerAttempt.failed => AppStrings.activitiesAnswerFailed.tr(),
      AnswerAttempt.rejected => AppStrings.activitiesAnswerRejected.tr(),
      AnswerAttempt.answered || AnswerAttempt.ignored => null,
    };
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    if (attempt == AnswerAttempt.answered) await _showFeedback();
  }

  /// Painel de feedback; seguir vai à próxima pergunta ou, na última, de
  /// volta às atividades (até a B4 trazer a conclusão).
  Future<void> _showFeedback() async {
    final LessonEntity? lesson = _controller.current;
    final AnswerResultEntity? result = _controller.currentResult;
    if (lesson == null || result == null) return;
    final FeedbackAction? action = await showFeedbackSheet(
      context,
      lesson: lesson,
      result: result,
      isLast: _controller.isLastLesson,
      score: _controller.score,
    );
    if (!mounted) return;
    switch (action) {
      case FeedbackAction.next:
        _controller.goNext();
      case FeedbackAction.finish:
        context.pop();
      case null:
        break;
    }
  }

  void _toggleListen(LessonEntity lesson) => unawaited(
    _readAloud.isSpeaking
        ? _readAloud.stop()
        : _readAloud.speak(lesson.spokenText),
  );

  @override
  Widget build(BuildContext context) {
    final LessonController controller = context.watch<LessonController>();
    final LessonEntity? lesson = controller.current;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.module?.title ?? AppStrings.activitiesModuleTitle.tr(),
        ),
      ),
      body: SafeArea(
        child: switch (controller.status) {
          // O servidor gratuito leva até ~40 s para acordar.
          LessonStatus.loading => Column(
            children: [
              SlowRequestNotice(
                active: true,
                message: AppStrings.activitiesSlow.tr(),
              ),
              const Expanded(child: SafeLoadingState()),
            ],
          ),
          LessonStatus.error => SafeErrorState(
            message: AppStrings.activitiesErrorTitle.tr(),
            onRetry: () => controller.load(widget.moduleId),
          ),
          LessonStatus.empty => SafeEmptyState(
            icon: LucideIcons.graduationCap,
            message: AppStrings.activitiesModuleUnavailable.tr(),
          ),
          LessonStatus.loaded when lesson != null => Column(
            children: [
              Expanded(
                child: _LessonBody(
                  lesson: lesson,
                  lessons: controller.module!.lessons,
                  currentIndex: controller.currentIndex,
                  selectedOptionId: controller.selectedOptionId,
                  result: controller.currentResult,
                  onSelect: controller.canSelect ? controller.select : null,
                  listen: ListenableBuilder(
                    listenable: _readAloud,
                    builder: (context, _) => _readAloud.isAvailable
                        ? ListenButton(
                            isSpeaking: _readAloud.isSpeaking,
                            onPressed: () => _toggleListen(lesson),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              // O envio também pode esperar o servidor acordar (FR-014).
              SlowRequestNotice(
                active: controller.isSubmitting,
                message: AppStrings.activitiesSlow.tr(),
              ),
              ConfirmAnswerFooter(controller: controller, onConfirm: _confirm),
            ],
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _LessonBody extends StatelessWidget {
  const _LessonBody({
    required this.lesson,
    required this.lessons,
    required this.currentIndex,
    required this.selectedOptionId,
    required this.result,
    required this.onSelect,
    required this.listen,
  });

  /// Altura máxima da imagem: o enunciado aparece sem rolar muito.
  static const double maxImageHeight = 220;

  final LessonEntity lesson;
  final List<LessonEntity> lessons;
  final int currentIndex;
  final String? selectedOptionId;

  /// A correção desta pergunta nesta visita: mostra a correta e a errada.
  final AnswerResultEntity? result;

  /// `null` quando não pode escolher (enviando ou já corrigida).
  final ValueChanged<String>? onSelect;

  /// "Ouvir"/"Parar" (some sem voz no idioma do app).
  final Widget listen;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? image = lesson.imageUrl;
    return ListView(
      // Cada pergunta que aparece começa no topo, com o enunciado.
      key: ValueKey(lesson.id),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s6,
      ),
      children: [
        LessonProgressIndicator(lessons: lessons, currentIndex: currentIndex),
        const SizedBox(height: AppSpacing.s4),
        if (image != null)
          ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: maxImageHeight),
              child: ClipRRect(
                borderRadius: AppSpacing.radius2xl,
                // O espaço depois da imagem só existe com ela: o errorBuilder
                // não passa pelo frameBuilder (FR-013).
                child: Image.network(
                  image,
                  fit: BoxFit.contain,
                  frameBuilder: (context, child, _, _) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                    child: child,
                  ),
                  errorBuilder: (context, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        Semantics(
          header: true,
          child: Text(
            lesson.question,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.secondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        for (final (index, option) in lesson.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
            child: LessonOptionCard(
              number: index + 1,
              text: option.text,
              state: lesson.optionState(
                option,
                selectedOptionId: selectedOptionId,
                result: result,
              ),
              onTap: onSelect == null ? null : () => onSelect!(option.id),
            ),
          ),
        const SizedBox(height: AppSpacing.s2),
        listen,
      ],
    );
  }
}
