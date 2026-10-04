import 'dart:async';

import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Aviso que aparece quando um pedido demora mais que [delay] (ex.: o
/// servidor acordando depois de parado). Some quando [active] vira `false`.
class SlowRequestNotice extends StatefulWidget {
  const SlowRequestNotice({
    super.key,
    required this.active,
    required this.message,
  });

  static const Duration delay = Duration(seconds: 5);

  final bool active;
  final String message;

  @override
  State<SlowRequestNotice> createState() => _SlowRequestNoticeState();
}

class _SlowRequestNoticeState extends State<SlowRequestNotice> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SlowRequestNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sync() {
    _timer?.cancel();
    _visible = false;
    if (widget.active) {
      _timer = Timer(SlowRequestNotice.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Semantics(
        liveRegion: true,
        child: Text(
          widget.message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMutedForeground,
          ),
        ),
      ),
    );
  }
}
