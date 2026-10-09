import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_status.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_header.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/read_aloud_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Detalhe da notícia (RF-014, RF-015, specs/010-detalhe-noticia): notícia
/// completa e "Ouvir". O [NewsDetailController] vem da rota (um por
/// abertura).
class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({super.key, required this.newsId});

  final String newsId;

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late final NewsDetailController _controller;
  late final ReadAloudController _readAloud;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _controller = context.read<NewsDetailController>();
    _readAloud = GetIt.instance<ReadAloudController>();
    _controller.addListener(_maybeAutoRead);
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
    _controller.removeListener(_maybeAutoRead);
    _readAloud.removeListener(_maybeAutoRead);
    _readAloud.dispose();
    super.dispose();
  }

  /// Leitura automática (RF-040): quando a carga e o preparo da voz
  /// terminam, uma vez por abertura. Marca como feita ao começar.
  void _maybeAutoRead() {
    final NewsDetailEntity? detail = _controller.detail;
    if (!mounted ||
        _controller.status != NewsDetailStatus.loaded ||
        detail == null ||
        _controller.autoReadDone ||
        !_readAloud.isAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _controller.markAutoReadDone();
    unawaited(_readAloud.speak(detail.spokenText));
  }

  void _toggleListen(NewsDetailEntity detail) {
    if (_readAloud.isSpeaking) {
      _controller.markAutoReadDone();
      unawaited(_readAloud.stop());
    } else {
      unawaited(_readAloud.speak(detail.spokenText));
    }
  }

  @override
  Widget build(BuildContext context) {
    final NewsDetailController controller = context
        .watch<NewsDetailController>();
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.newsDetailTitle.tr())),
      body: SafeArea(child: _content(controller)),
    );
  }

  Widget _content(NewsDetailController controller) {
    switch (controller.status) {
      case NewsDetailStatus.loading:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SafeLoadingState(),
            SlowRequestNotice(
              active: true,
              message: AppStrings.newsSlowServer.tr(),
            ),
          ],
        );
      case NewsDetailStatus.error:
        final Failure? failure = controller.failure;
        return SafeErrorState(
          message: (failure?.message ?? AppStrings.errorGeneric).tr(),
          onRetry: controller.retry,
        );
      case NewsDetailStatus.notFound:
        return const _NotFound();
      case NewsDetailStatus.loaded:
        final NewsDetailEntity? detail = controller.detail;
        if (detail == null) return const SizedBox.shrink();
        return _loaded(controller, detail);
    }
  }

  Widget _loaded(NewsDetailController controller, NewsDetailEntity detail) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isFromCache) const SafeOfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NewsDetailHeader(detail: detail, now: DateTime.now()),
                ListenableBuilder(
                  listenable: _readAloud,
                  builder: (context, _) => ReadAloudBar(
                    isAvailable: _readAloud.isAvailable,
                    isSpeaking: _readAloud.isSpeaking,
                    speed: _readAloud.speed,
                    onToggle: () => _toggleListen(detail),
                    onSpeedChanged: _readAloud.setSpeed,
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                if (detail.hasContent)
                  Text(
                    detail.content.trim(),
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      height: 1.5,
                      color: context.colors.textForeground,
                    ),
                  )
                else
                  Text(
                    AppStrings.newsDetailNoContent.tr(),
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
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
}

/// "Notícia não encontrada": sem "Tentar novamente"; a barra superior leva
/// de volta.
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.newspaper,
            size: 40,
            color: context.colors.textMutedForeground,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            AppStrings.newsErrorNotFound.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: context.colors.textForeground,
            ),
          ),
        ],
      ),
    ),
  );
}
