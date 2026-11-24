import 'package:click_seguro_app/modules/notifications/presentation/extensions/alert_presentation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/alerts_fixtures.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 9, 15);

  group('timeLabel', () {
    test('hoje: HH:mm de 24 h, com zero à esquerda', () {
      expect(
        alert(publishedAt: DateTime(2026, 10, 9, 8, 5)).timeLabel(now),
        '08:05',
      );
      expect(
        alert(publishedAt: DateTime(2026, 10, 9, 14, 30)).timeLabel(now),
        '14:30',
      );
    });

    test('ontem: HH:mm', () {
      expect(
        alert(publishedAt: DateTime(2026, 10, 8, 23, 9)).timeLabel(now),
        '23:09',
      );
    });

    test('anteriores: dd/MM com zero à esquerda', () {
      expect(
        alert(publishedAt: DateTime(2026, 10, 1, 9)).timeLabel(now),
        '01/10',
      );
      expect(
        alert(publishedAt: DateTime(2026, 9, 21, 9)).timeLabel(now),
        '21/09',
      );
    });

    test('data futura: hora, como hoje', () {
      expect(
        alert(publishedAt: DateTime(2026, 10, 12, 9, 7)).timeLabel(now),
        '09:07',
      );
    });
  });

  group('textos traduzidos', () {
    String? semantic;
    final texts = <int, String>{};

    Future<void> pumpTexts(WidgetTester tester) async {
      await pumpLocalized(
        tester,
        child: Builder(
          builder: (_) {
            semantic = alert(
              title: 'Golpe do Pix',
              source: 'Folha de Teste',
              publishedAt: DateTime(2026, 10, 9, 8, 5),
            ).semanticLabel(now);
            for (final count in [0, 1, 4]) {
              texts[count] = summaryText(count);
            }
            return const SizedBox();
          },
        ),
      );
    }

    testWidgets('semanticLabel não lido: começa com "Novo"', (tester) async {
      await pumpTexts(tester);

      expect(semantic, 'Novo, Golpe do Pix, Folha de Teste, 08:05');
    });

    testWidgets('semanticLabel lido: sem o "Novo"', (tester) async {
      String? read;
      await pumpLocalized(
        tester,
        child: Builder(
          builder: (_) {
            read = alert(
              title: 'Golpe do Pix',
              source: 'Folha de Teste',
              publishedAt: DateTime(2026, 10, 1, 8),
              isRead: true,
            ).semanticLabel(now);
            return const SizedBox();
          },
        ),
      );

      expect(read, 'Golpe do Pix, Folha de Teste, 01/10');
    });

    testWidgets('summaryText: zero, um e vários', (tester) async {
      await pumpTexts(tester);

      expect(texts[0], 'Você não tem alertas novos');
      expect(texts[1], 'Você tem 1 alerta novo');
      expect(texts[4], 'Você tem 4 alertas novos');
    });
  });
}
