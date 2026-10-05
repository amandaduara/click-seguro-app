import 'package:flutter/material.dart';

/// Navegador raiz do app: as telas "sobre as abas" usam
/// `parentNavigatorKey: rootNavigatorKey` para cobrir a barra inferior
/// (R2 de specs/005-shell-navegacao-base/research.md).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Messenger do `MaterialApp`: avisos globais, como o de sessão expirada
/// (R4 de specs/005-shell-navegacao-base/research.md).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
