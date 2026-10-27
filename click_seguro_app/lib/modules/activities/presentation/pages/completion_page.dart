import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/completion_presentation.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// O fim de um módulo: o que a conclusão mostra (data-model de specs/020).
class ModuleCompletion {
  const ModuleCompletion({required this.title, this.score});

  final String title;

  /// `null` quando a pontuação não veio (FR-004).
  final ModuleScoreEntity? score;
}

/// O que a pessoa escolheu na conclusão; `null` (voltar do aparelho) vale
/// como [finish].
enum CompletionAction { finish, redo }

/// Tela de conclusão do módulo (RF-029). Quem a abre (a página das perguntas)
/// decide o que fazer com a ação devolvida (R2 de specs/020).
class CompletionPage extends StatefulWidget {
  const CompletionPage({super.key, required this.completion});

  /// `null` quando a rota foi aberta sem dados: volta às atividades.
  final ModuleCompletion? completion;

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  final ReadAloudController _readAloud = GetIt.instance<ReadAloudController>();
  Locale? _locale;

  /// A leitura automática acontece uma vez, quando a voz fica pronta.
  bool _autoReadDone = false;

  /// Menu do aparelho abrindo: um toque por vez.
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    if (widget.completion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
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
    _readAloud.removeListener(_maybeAutoRead);
    _readAloud.dispose();
    super.dispose();
  }

  void _maybeAutoRead() {
    final ModuleCompletion? completion = widget.completion;
    if (!mounted ||
        completion == null ||
        _autoReadDone ||
        !_readAloud.isAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _autoReadDone = true;
    unawaited(_readAloud.speak(completion.spokenText));
  }

  /// Cancelar ou falhar não mostra aviso, como na notícia (FR-006).
  Future<void> _share(ModuleCompletion completion) async {
    if (_sharing) return;
    _sharing = true;
    try {
      await GetIt.instance<ShareService>().shareText(
        completion.shareText,
        subject: completion.title,
      );
    } finally {
      _sharing = false;
    }
  }

  void _toggleListen(String text) => unawaited(
    _readAloud.isSpeaking ? _readAloud.stop() : _readAloud.speak(text),
  );

  @override
  Widget build(BuildContext context) {
    final ModuleCompletion? completion = widget.completion;
    if (completion == null) return const Scaffold();
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? score = completion.scoreText;
    return Scaffold(
      appBar: AppBar(title: Text(completion.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          children: [
            ExcludeSemantics(
              child: Icon(LucideIcons.trophy, size: 64, color: colors.success),
            ),
            const SizedBox(height: AppSpacing.s4),
            Semantics(
              liveRegion: true,
              header: true,
              child: Text(
                AppStrings.activitiesCompletionTitle.tr(),
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.secondary,
                ),
              ),
            ),
            if (score != null) ...[
              const SizedBox(height: AppSpacing.s3),
              Text(
                score,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textForeground,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s3),
            Text(
              completion.messageKey.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: colors.textForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            ListenableBuilder(
              listenable: _readAloud,
              builder: (context, _) => _readAloud.isAvailable
                  ? ListenButton(
                      isSpeaking: _readAloud.isSpeaking,
                      onPressed: () => _toggleListen(completion.spokenText),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.s6),
            SafeButton(
              label: AppStrings.activitiesFeedbackFinish.tr(),
              onPressed: () => context.pop(CompletionAction.finish),
            ),
            const SizedBox(height: AppSpacing.s3),
            SafeButton(
              label: AppStrings.activitiesCompletionShare.tr(),
              tone: SafeButtonTone.secondary,
              icon: const Icon(LucideIcons.share2),
              onPressed: () => _share(completion),
            ),
            const SizedBox(height: AppSpacing.s3),
            SafeButton(
              label: AppStrings.activitiesCompletionRedo.tr(),
              tone: SafeButtonTone.secondary,
              icon: const Icon(LucideIcons.rotateCcw),
              onPressed: () => context.pop(CompletionAction.redo),
            ),
          ],
        ),
      ),
    );
  }
}
