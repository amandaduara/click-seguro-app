import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/widgets/coming_soon_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// TODO(trilha): página provisória da Fase 0 (specs/005-shell-navegacao-base).
class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String title = AppStrings.profileEditTitle.tr();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ComingSoonView(title: title),
    );
  }
}
