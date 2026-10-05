import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/widgets/coming_soon_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// TODO(trilha): página provisória da Fase 0 (specs/005-shell-navegacao-base).
class HelpContactPage extends StatelessWidget {
  const HelpContactPage({super.key, this.contactId});

  /// Contato em edição; nulo ao criar um novo.
  final String? contactId;

  @override
  Widget build(BuildContext context) {
    final String title = AppStrings.helpContactTitle.tr();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ComingSoonView(title: title),
    );
  }
}
