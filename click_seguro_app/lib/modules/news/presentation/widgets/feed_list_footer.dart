import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Rodapé de "Tudo recente": pede a próxima página ao aparecer na tela,
/// mostra o carregando, a falha com "Tentar novamente" ou o fim da lista.
class FeedListFooter extends StatefulWidget {
  const FeedListFooter({
    super.key,
    required this.hasMore,
    required this.isLoading,
    required this.failed,
    required this.isEnd,
    required this.offlineEnd,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoading;
  final bool failed;
  final bool isEnd;

  /// Fim da cópia guardada: é preciso internet para ver mais (FR-021).
  final bool offlineEnd;
  final VoidCallback onLoadMore;

  @override
  State<FeedListFooter> createState() => _FeedListFooterState();
}

class _FeedListFooterState extends State<FeedListFooter> {
  @override
  void initState() {
    super.initState();
    _requestIfVisible();
  }

  @override
  void didUpdateWidget(FeedListFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Terminada uma página, se ainda há mais e o rodapé continua visível
    // (lista curta), pede a seguinte.
    if (oldWidget.isLoading && !widget.isLoading) _requestIfVisible();
  }

  void _requestIfVisible() {
    if (!widget.hasMore || widget.isLoading || widget.failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Widget child;
    if (widget.failed) {
      child = Column(
        children: [
          Text(
            AppStrings.newsLoadMoreFailed.tr(),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.s3),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: SafeButton(
              label: AppStrings.commonTryAgain.tr(),
              size: SafeButtonSize.compact,
              onPressed: widget.onLoadMore,
            ),
          ),
        ],
      );
    } else if (widget.isLoading || widget.hasMore) {
      child = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.primary,
        ),
      );
    } else if (widget.offlineEnd) {
      child = _message(AppStrings.newsOfflineEnd.tr(), textTheme);
    } else if (widget.isEnd) {
      child = _message(AppStrings.newsEndOfList.tr(), textTheme);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(child: child),
    );
  }

  Widget _message(String text, TextTheme textTheme) => Text(
    text,
    textAlign: TextAlign.center,
    style: textTheme.bodyLarge?.copyWith(
      fontSize: 16,
      color: context.colors.textMutedForeground,
    ),
  );
}
