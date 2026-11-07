import 'package:click_seguro_app/core/widgets/refresh_on_return.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Recarregar ao voltar para a aba ou de uma tela aberta dela (R6 de
/// specs/015-painel-atividades; técnica da B7).
void main() {
  late int returns;
  late GoRouter router;

  setUp(() {
    returns = 0;
    router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/a',
                  builder: (_, _) => _TabA(onReturn: () => returns++),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/b', builder: (_, _) => const Text('aba b')),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/x',
          builder: (_, _) => const Scaffold(body: Text('x')),
        ),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('a primeira montagem não chama', (tester) async {
    await pump(tester);

    expect(returns, 0);
  });

  testWidgets('trocar de aba e voltar chama uma vez', (tester) async {
    await pump(tester);

    router.go('/b');
    await tester.pumpAndSettle();
    expect(returns, 0);
    router.go('/a');
    await tester.pumpAndSettle();

    expect(returns, 1);
  });

  testWidgets('pushAndRefresh chama uma vez na volta', (tester) async {
    await pump(tester);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('x'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    expect(returns, 1);
  });
}

class _TabA extends StatefulWidget {
  const _TabA({required this.onReturn});

  final VoidCallback onReturn;

  @override
  State<_TabA> createState() => _TabAState();
}

class _TabAState extends State<_TabA> with RefreshOnReturnMixin<_TabA> {
  @override
  String get tabPath => '/a';

  @override
  void onReturn() => widget.onReturn();

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => pushAndRefresh('/x'),
    child: const Text('abrir'),
  );
}
