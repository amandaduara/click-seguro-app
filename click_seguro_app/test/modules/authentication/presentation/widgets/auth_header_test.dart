import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/or_divider.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  testWidgets('AuthHeader mostra a saudação e a marca', (tester) async {
    await pumpLocalized(tester, child: const Scaffold(body: AuthHeader()));

    expect(find.text('Bem-vindo ao'), findsOneWidget);
    expect(find.text('Click Seguro'), findsOneWidget);
    expect(find.byType(AppLogo), findsOneWidget);
  });

  testWidgets('OrDivider mostra "ou"', (tester) async {
    await pumpLocalized(tester, child: const Scaffold(body: OrDivider()));

    expect(find.text('ou'), findsOneWidget);
  });
}
