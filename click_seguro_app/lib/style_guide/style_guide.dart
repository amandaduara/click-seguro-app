import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_chip.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/safe_pill_tabs.dart';
import 'package:click_seguro_app/core/widgets/safe_progress.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Guia de estilo do redesign 2.0 (specs/024-redesign-visual), montado com
/// os componentes reais do `core`, na ordem da prancha "Componentes" do
/// Figma. Rodar com `flutter run -t lib/style_guide/style_guide.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: const StyleGuideApp(),
    ),
  );
}

class StyleGuideApp extends StatefulWidget {
  const StyleGuideApp({super.key});

  @override
  State<StyleGuideApp> createState() => _StyleGuideAppState();
}

class _StyleGuideAppState extends State<StyleGuideApp> {
  bool _highContrast = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Click Seguro Style Guide',
      theme: _highContrast ? AppTheme.highContrastTheme : AppTheme.lightTheme,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: _StyleGuideScreen(
        highContrast: _highContrast,
        onHighContrast: (value) => setState(() => _highContrast = value),
      ),
    );
  }
}

class _StyleGuideScreen extends StatefulWidget {
  const _StyleGuideScreen({
    required this.highContrast,
    required this.onHighContrast,
  });

  final bool highContrast;
  final ValueChanged<bool> onHighContrast;

  @override
  State<_StyleGuideScreen> createState() => _StyleGuideScreenState();
}

class _StyleGuideScreenState extends State<_StyleGuideScreen> {
  int _tab = 0;
  bool _chip = true;
  bool _speaking = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System 2.0'),
        actions: [
          Switch(value: widget.highContrast, onChanged: widget.onHighContrast),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          _section('Cores'),
          Wrap(
            spacing: AppSpacing.s3,
            runSpacing: AppSpacing.s3,
            children: [
              for (final (String name, Color color) in [
                ('primary', colors.primary),
                ('primarySoft', colors.primarySoft),
                ('textForeground', colors.textForeground),
                ('textBody', colors.textBody),
                ('surface', colors.surface),
                ('surfaceStrong', colors.surfaceStrong),
                ('success', colors.success),
                ('warning', colors.warning),
                ('info', colors.info),
                ('destructive', colors.destructive),
              ])
                _Swatch(name: name, color: color),
            ],
          ),
          _section('Tipografia · Inter'),
          for (final (String name, TextStyle style) in [
            ('display 32', AppTypography.display),
            ('title1 28', AppTypography.title1),
            ('title2 22', AppTypography.title2),
            ('title3 20', AppTypography.title3),
            ('bodyLarge 20', AppTypography.bodyLarge),
            ('body 18', AppTypography.body),
            ('label 16', AppTypography.label),
            ('caption 15', AppTypography.caption),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: Text(
                'Proteja-se de golpes · $name',
                style: style.copyWith(color: colors.textForeground),
              ),
            ),
          _section('Botões'),
          SafeButton(label: 'Continuar', onPressed: () {}),
          const SizedBox(height: AppSpacing.s3),
          SafeButton(
            label: 'Continuar sem login',
            tone: SafeButtonTone.secondary,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.s3),
          SafeButton(
            label: 'Editar perfil',
            tone: SafeButtonTone.ghost,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.s3),
          SafeButton(
            label: 'Confirmar resposta',
            disabled: true,
            onPressed: () {},
          ),
          SafeButton(
            label: 'Ver todas',
            tone: SafeButtonTone.link,
            onPressed: () {},
          ),
          _section('Botões redondos, Ouvir e chips'),
          Wrap(
            spacing: AppSpacing.s3,
            runSpacing: AppSpacing.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SafeIconButton(
                icon: LucideIcons.chevronLeft,
                semanticLabel: 'Voltar',
                onPressed: () {},
              ),
              SafeIconButton(
                icon: LucideIcons.bookmark,
                semanticLabel: 'Salvar',
                onImage: true,
                onPressed: () {},
              ),
              ListenButton(
                isSpeaking: _speaking,
                onPressed: () => setState(() => _speaking = !_speaking),
              ),
              SafeChip(
                label: 'Todas',
                selected: _chip,
                onTap: () => setState(() => _chip = !_chip),
              ),
              SafeChip(
                label: 'WhatsApp',
                selected: !_chip,
                onTap: () => setState(() => _chip = !_chip),
              ),
            ],
          ),
          _section('Selos'),
          const Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              SafeBadge(
                tone: SafeBadgeTone.warning,
                child: Text('Em andamento'),
              ),
              SafeBadge(tone: SafeBadgeTone.success, child: Text('Concluído')),
              SafeBadge(
                tone: SafeBadgeTone.neutral,
                child: Text('Não iniciado'),
              ),
              SafeBadge(child: Text('Golpe novo')),
              SafeBadge(
                tone: SafeBadgeTone.onImage,
                child: Text('Sobre imagem'),
              ),
            ],
          ),
          _section('Campos'),
          const SafeTextField(label: 'E-mail', placeholder: 'seu@email.com'),
          const SizedBox(height: AppSpacing.s4),
          const SafeTextField(
            label: 'E-mail',
            error: 'Digite um e-mail válido.',
          ),
          _section('Progresso e abas'),
          const SafeProgressBar(value: 0.6),
          const SizedBox(height: AppSpacing.s4),
          const Row(
            children: [
              SafeProgressRing(value: 0.4, label: '40%'),
              SizedBox(width: AppSpacing.s5),
              Expanded(
                child: SafeSegmentedProgress(
                  completed: [true, true, false, false, false],
                  current: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          SafePillTabs(
            tabs: const ['Oficiais', 'Meus contatos'],
            selectedIndex: _tab,
            onChanged: (index) => setState(() => _tab = index),
          ),
          _section('Cartões e avisos'),
          const SafeCard(child: Text('Cartão padrão')),
          const SizedBox(height: AppSpacing.s3),
          const SafeCard(
            elevation: SafeCardElevation.flat,
            child: Text('Cartão plano (creme)'),
          ),
          const SizedBox(height: AppSpacing.s3),
          const SafeOfflineBanner(),
          const SizedBox(height: AppSpacing.s3),
          const SafeSkeleton(
            enabled: true,
            child: SafeCard(child: Text('Cartão carregando')),
          ),
          _section('Ilustrações'),
          Wrap(
            spacing: AppSpacing.s3,
            runSpacing: AppSpacing.s3,
            children: [
              for (final AppIllustration illustration in AppIllustration.values)
                SizedBox(
                  width: 150,
                  child: SafeIllustration(illustration, height: 100),
                ),
            ],
          ),
          _section('Estados'),
          // Sem internet: a nuvem e a frase padrão (specs/027).
          SizedBox(
            height: 420,
            child: SafeErrorState(
              failure: const ConnectionFailure(),
              onRetry: () {},
            ),
          ),
          SizedBox(
            height: 420,
            child: SafeErrorState(
              failure: const ServerFailure(),
              message: 'Não foi possível carregar.',
              onRetry: () {},
            ),
          ),
          const SizedBox(
            height: 360,
            child: SafeEmptyState(message: 'Nada por aqui.'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.s7, bottom: AppSpacing.s3),
    child: Text(
      title.toUpperCase(),
      style: AppTypography.caption.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppSpacing.radiusMd,
            border: Border.all(color: context.colors.border),
          ),
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(name, style: AppTypography.caption),
      ],
    ),
  );
}
