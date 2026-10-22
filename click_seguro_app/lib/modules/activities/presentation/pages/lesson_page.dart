import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_status.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_progress_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

/// Perguntas de um módulo, uma por vez (B2, specs/017-perguntas-atividades).
class LessonPage extends StatelessWidget {
  const LessonPage({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LessonController>(
      create: (_) => GetIt.instance<LessonController>()..load(moduleId),
      child: const _LessonScaffold(),
    );
  }
}

class _LessonScaffold extends StatelessWidget {
  const _LessonScaffold();

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
          LessonStatus.loading => const SafeLoadingState(),
          LessonStatus.loaded when lesson != null => Column(
            children: [
              Expanded(
                child: _LessonBody(
                  lesson: lesson,
                  lessons: controller.module!.lessons,
                  currentIndex: controller.currentIndex,
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
  });

  /// Altura máxima da imagem: o enunciado aparece sem rolar muito.
  static const double maxImageHeight = 220;

  final LessonEntity lesson;
  final List<LessonEntity> lessons;
  final int currentIndex;

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
