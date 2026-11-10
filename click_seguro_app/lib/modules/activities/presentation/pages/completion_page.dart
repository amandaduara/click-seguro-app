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
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
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
    final String? scoreText = completion.scoreText;
    final ModuleScoreEntity? score = completion.score;
    // Redesign 2.0 (Figma, quadro 09): troféu com confete, título, o placar
    // em destaque contando de 0 até o resultado e os botões da feature 020.
    return Scaffold(
      appBar: AppBar(title: Text(completion.title)),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s6,
                AppSpacing.s2,
                AppSpacing.s6,
                AppSpacing.s6,
              ),
              children: [
                const _SpringIn(
                  child: SafeIllustration(
                    AppIllustration.stateTrophy,
                    height: 190,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Semantics(
                  liveRegion: true,
                  header: true,
                  child: Text(
                    AppStrings.activitiesCompletionTitle.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.display.copyWith(
                      color: colors.textForeground,
                    ),
                  ),
                ),
                if (score != null && scoreText != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  _CountUp(value: score.score),
                  Text(
                    scoreText,
                    textAlign: TextAlign.center,
                    style: AppTypography.title3.copyWith(
                      color: colors.textMutedForeground,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                Text(
                  completion.messageKey.tr(),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 19,
                    color: colors.textForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Center(
                  child: ListenableBuilder(
                    listenable: _readAloud,
                    builder: (context, _) => _readAloud.isAvailable
                        ? ListenButton(
                            isSpeaking: _readAloud.isSpeaking,
                            onPressed: () =>
                                _toggleListen(completion.spokenText),
                          )
                        : const SizedBox.shrink(),
                  ),
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
            // Confete por cima, sem bloquear toques nem o leitor de tela.
            const Positioned.fill(child: IgnorePointer(child: _Confetti())),
          ],
        ),
      ),
    );
  }
}

/// Entra com uma mola leve (FR-020); direto com reduzir animações.
class _SpringIn extends StatelessWidget {
  const _SpringIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: AppMotion.emphasis,
      curve: AppMotion.spring,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

/// Placar em destaque contando de 0 até [value] em 1,2 s (FR-020). O leitor
/// de tela lê o texto completo logo abaixo, então o número é decorativo.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.score.copyWith(
      color: context.colors.textForeground,
    );
    final Widget number = context.reduceMotion
        ? Text('$value', textAlign: TextAlign.center, style: style)
        : TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: AppMotion.celebration,
            curve: AppMotion.enter,
            builder: (context, current, _) =>
                Text('$current', textAlign: TextAlign.center, style: style),
          );
    return ExcludeSemantics(child: number);
  }
}

/// Confete que cai uma vez, por 1,2 s (FR-020). Não aparece com reduzir
/// animações (FR-021).
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !context.reduceMotion) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return const SizedBox.shrink();
    final AppPalette colors = context.colors;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _controller.isCompleted
            ? const SizedBox.shrink()
            : CustomPaint(
                painter: _ConfettiPainter(
                  progress: _controller.value,
                  colors: [
                    colors.primary,
                    colors.success,
                    colors.info,
                    colors.warning,
                  ],
                ),
              ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static const int _pieces = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (int i = 0; i < _pieces; i++) {
      // Posições fixas por índice: o mesmo confete em toda execução.
      final double x = ((i * 37) % 100) / 100 * size.width;
      final double start = -20.0 - (i % 5) * 30;
      final double y = start + progress * (size.height * 0.6 + (i % 7) * 20);
      final double angle = progress * 6 + i;
      paint.color = colors[i % colors.length].withValues(
        alpha: (1 - progress).clamp(0, 1),
      );
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(angle)
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5, -2.5, 10, 5),
            const Radius.circular(2),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
