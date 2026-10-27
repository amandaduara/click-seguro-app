import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Recarrega uma aba quando a pessoa volta a ela: de outra aba (a aba fica
/// viva no shell e não remonta) ou de uma tela aberta a partir dela
/// ([pushAndRefresh]). Técnica da B7, extraída no R6 de
/// specs/015-painel-atividades.
mixin RefreshOnReturnMixin<T extends StatefulWidget> on State<T> {
  /// Caminho da aba (ex.: `/profile`).
  String get tabPath;

  /// Chamado na volta; nunca na primeira montagem.
  void onReturn();

  GoRouterDelegate? _delegate;
  String? _lastPath;

  /// Quantas vezes já recarregou: evita recarregar duas vezes na volta.
  int _returns = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GoRouterDelegate delegate = GoRouter.of(context).routerDelegate;
    if (delegate == _delegate) return;
    _delegate?.removeListener(_onRouteChanged);
    _delegate = delegate..addListener(_onRouteChanged);
    _lastPath = _currentPath;
  }

  String? get _currentPath => _delegate?.currentConfiguration.uri.path;

  void _onRouteChanged() {
    final String? path = _currentPath;
    final bool returned = path == tabPath && _lastPath != tabPath;
    _lastPath = path;
    if (returned && mounted) _notifyReturn();
  }

  void _notifyReturn() {
    _returns++;
    onReturn();
  }

  /// Abre uma tela sobre a aba e recarrega na volta. O `pop` não avisa o
  /// roteador; se um dia avisar, o ouvinte já recarregou e nada se repete.
  Future<void> pushAndRefresh(String location, {Object? extra}) async {
    final int before = _returns;
    await context.push<void>(location, extra: extra);
    if (!mounted || _returns != before) return;
    _lastPath = _currentPath;
    _notifyReturn();
  }

  @override
  void dispose() {
    _delegate?.removeListener(_onRouteChanged);
    super.dispose();
  }
}
