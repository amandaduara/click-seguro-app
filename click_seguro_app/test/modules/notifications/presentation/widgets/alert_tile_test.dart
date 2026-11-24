import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:click_seguro_app/modules/notifications/presentation/widgets/alert_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/hanging_http_client.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/alerts_fixtures.dart';

/// Alerta no estilo dos cartões do Início: caixa com borda, capa na lateral
/// e o texto ao lado (validação da usuária, specs/024).
void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    String? imageUrl,
    bool isRead = false,
  }) async {
    // A rede nunca responde: a capa fica na espera (o teste devolve o valor
    // padrão no fim, antes da checagem do framework).
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;
    await pumpLocalized(
      tester,
      settle: false,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AlertTile(
            alert: alert(imageUrl: imageUrl, isRead: isRead),
            now: testNow,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('cartão padrão com a capa à esquerda do título', (tester) async {
    await pumpTile(tester, imageUrl: 'https://img.test/n1.jpg');

    expect(find.byType(SafeCard), findsOneWidget);
    final Finder image = find.byType(SafeNetworkImage);
    expect(image, findsOneWidget);
    expect(
      tester.getTopRight(image).dx,
      lessThan(tester.getTopLeft(find.text('Golpe do Pix')).dx),
    );
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets('sem imagem, a ilustração do tema ocupa a lateral', (
    tester,
  ) async {
    await pumpTile(tester);

    expect(find.byType(SafeIllustration), findsOneWidget);
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets('não lido mostra "Novo"; lido não', (tester) async {
    await pumpTile(tester);
    expect(find.text('Novo'), findsOneWidget);

    await pumpTile(tester, isRead: true);
    expect(find.text('Novo'), findsNothing);
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets('o cartão inteiro é um botão de 48 ou mais', (tester) async {
    await pumpTile(tester);

    final Size size = tester.getSize(find.byType(SafeCard));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(SafeCard));
    debugNetworkImageHttpClientProvider = null;
  });
}
