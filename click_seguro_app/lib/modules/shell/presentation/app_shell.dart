import 'package:click_seguro_app/modules/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Casca da área principal: as cinco abas e a barra inferior.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    // Tocar na aba ativa volta à raiz dela.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final bool atHome = navigationShell.currentIndex == AppTab.home.index;
    return PopScope(
      // Em outra aba, "voltar" leva ao Início; no Início, fecha o app (FR-008).
      canPop: atHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(AppTab.home.index);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomNav(
          currentIndex: navigationShell.currentIndex,
          onSelected: _select,
        ),
      ),
    );
  }
}
