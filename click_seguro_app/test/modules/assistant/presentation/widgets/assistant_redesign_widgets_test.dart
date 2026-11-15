import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_analysis_card.dart';
import 'package:click_seguro_app/modules/assistant/presentation/widgets/assistant_chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_assistant_repository.dart';

/// Balões da conversa e cartão do resultado no visual do quadro
/// "10 Assistente" (redesign 2.0, specs/024-redesign-visual T063).
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {ThemeData? theme}) =>
      pumpLocalized(
        tester,
        theme: theme ?? AppTheme.lightTheme,
        child: Scaffold(
          body: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      );

  BoxDecoration decorationOf(WidgetTester tester, String key) =>
      tester.widget<DecoratedBox>(find.byKey(ValueKey(key))).decoration
          as BoxDecoration;

  group('AssistantChatBubble', () {
    testWidgets('pessoa: balão em tinta, texto branco, à direita', (
      tester,
    ) async {
      await pump(
        tester,
        const AssistantChatBubble(text: 'É golpe?', fromUser: true),
      );
      const AppPalette colors = AppPalette.light;
      expect(
        decorationOf(tester, 'assistant-bubble-user').color,
        colors.secondary,
      );
      final text = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(text.style?.color, colors.textPrimaryForeground);
      expect(find.byType(AssistantAvatar), findsNothing);
      final double screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final Rect bubble = tester.getRect(
        find.byKey(const ValueKey('assistant-bubble-user')),
      );
      expect(bubble.right, closeTo(screen - 20, 0.5));
    });

    testWidgets('assistente: balão creme à esquerda, com avatar de brilho', (
      tester,
    ) async {
      await pump(
        tester,
        const AssistantChatBubble(text: 'Pode ser golpe.', fromUser: false),
      );
      const AppPalette colors = AppPalette.light;
      final BoxDecoration box = decorationOf(
        tester,
        'assistant-bubble-assistant',
      );
      expect(box.color, colors.surface);
      expect(box.border, isNull);
      expect(find.byType(AssistantAvatar), findsOneWidget);
      expect(
        tester.getRect(find.byType(AssistantAvatar)).left,
        closeTo(20, 0.5),
      );
    });

    testWidgets('alto contraste: o balão do assistente ganha borda', (
      tester,
    ) async {
      await pump(
        tester,
        const AssistantChatBubble(text: 'Oi', fromUser: false),
        theme: AppTheme.highContrastTheme,
      );
      expect(
        decorationOf(tester, 'assistant-bubble-assistant').border,
        isNotNull,
      );
    });
  });

  group('AssistantAnalysisCard', () {
    BoxDecoration cardDecoration(WidgetTester tester) =>
        tester
                .widget<Container>(
                  find.byKey(const ValueKey('assistant-analysis-result')),
                )
                .decoration!
            as BoxDecoration;

    testWidgets('risco alto: borda coral, selo "Alto risco de golpe" e '
        'cuidados com X', (tester) async {
      await pump(
        tester,
        SingleChildScrollView(
          child: AssistantAnalysisCard(analysis: analysisEntity()),
        ),
      );
      expect(find.text('Alto risco de golpe'), findsOneWidget);
      expect(
        tester.widget<SafeBadge>(find.byType(SafeBadge)).tone,
        SafeBadgeTone.destructive,
      );
      final Border border = cardDecoration(tester).border! as Border;
      expect(border.top.color, AppPalette.light.primary);
      expect(border.top.width, 2);
      expect(find.text('Phishing'), findsOneWidget);
      expect(find.text('Não abra o link'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsNWidgets(2));
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('sem ameaça: selo "Parece seguro", sem borda coral', (
      tester,
    ) async {
      await pump(
        tester,
        SingleChildScrollView(
          child: AssistantAnalysisCard(
            analysis: analysisEntity(type: AiThreatType.safe),
          ),
        ),
      );
      expect(find.text('Parece seguro'), findsOneWidget);
      // A borda fina padrão dos cartões (SafeCard), não a coral.
      expect((cardDecoration(tester).border! as Border).top.width, 1);
      expect(find.byIcon(LucideIcons.check), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.x), findsNothing);
    });

    testWidgets('inconclusivo: selo de atenção', (tester) async {
      await pump(
        tester,
        SingleChildScrollView(
          child: AssistantAnalysisCard(
            analysis: analysisEntity(type: AiThreatType.uncertain),
          ),
        ),
      );
      expect(find.text('Atenção: pode ser golpe'), findsOneWidget);
      expect(
        tester.widget<SafeBadge>(find.byType(SafeBadge)).tone,
        SafeBadgeTone.warning,
      );
    });
  });
}
