import 'package:click_seguro_app/core/widgets/coming_soon_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// TODO(trilha): página provisória da Fase 0 (specs/005-shell-navegacao-base).
class SettingsSectionPage extends StatelessWidget {
  const SettingsSectionPage({super.key, required this.titleKey});

  /// Chave de tradução do título da subtela.
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final String title = titleKey.tr();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ComingSoonView(title: title),
    );
  }
}
