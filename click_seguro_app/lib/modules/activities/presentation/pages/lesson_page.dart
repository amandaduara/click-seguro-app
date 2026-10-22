import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_status.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/lesson_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_progress_indicator.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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

  /// Perguntas já lidas sozinhas: voltar a uma delas não lê de novo.
  final Set<int> _autoRead = {};

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
      unawaited(_readAloud.stop());
    }
    _shownIndex = index;
    _maybeAutoRead();
  }

  void _maybeAutoRead() {
    final LessonEntity? lesson = _controller.current;
    final int index = _controller.currentIndex;
    if (!mounted ||
        _controller.status != LessonStatus.loaded ||
        lesson == null ||
        _autoRead.contains(index) ||
        !_readAloud.isAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _autoRead.add(index);
    unawaited(_readAloud.speak(lesson.spokenText));
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
              _NavigationBar(controller: controller),
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
    required this.listen,
  });

  /// Altura máxima da imagem: o enunciado aparece sem rolar muito.
  static const double maxImageHeight = 220;

  final LessonEntity lesson;
  final List<LessonEntity> lessons;
  final int currentIndex;

  /// "Ouvir"/"Parar" (some sem voz no idioma do app).
  final Widget listen;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? image = lesson.imageUrl;
    return ListView(
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
                child: Image.network(
                  image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s4),
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
            child: LessonOptionCard(number: index + 1, text: option.text),
          ),
        const SizedBox(height: AppSpacing.s2),
        listen,
      ],
    );
  }
}

/// Rodapé fixo: "Anterior" e "Próxima", desativados quando não podem
/// (FR-005).
class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.controller});

  final LessonController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          children: [
            Expanded(
              child: SafeButton(
                label: AppStrings.activitiesLessonPrevious.tr(),
                tone: SafeButtonTone.secondary,
                onPressed: controller.canGoPrevious
                    ? controller.goPrevious
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: SafeButton(
                label: AppStrings.activitiesLessonNext.tr(),
                onPressed: controller.canGoNext ? controller.goNext : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
