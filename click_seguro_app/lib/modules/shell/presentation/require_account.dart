import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/account_required_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Convite aberto no momento: impede abrir dois com toque duplo. Uma rota
/// fechada ou descartada deixa de estar ativa, então não há flag para limpar.
ModalBottomSheetRoute<bool>? _openSheet;

/// Diz se uma ação restrita pode continuar (RN-003, CB-011): conectado →
/// `true`; visitante ou sem sessão → mostra o convite e devolve `false`.
///
/// Use antes de qualquer usecase de ação restrita. Nunca chama a rede.
Future<bool> requireAccount(BuildContext context) async {
  if (GetIt.instance<UserSessionService>().isAuthenticated) return true;
  if (_openSheet?.isActive ?? false) return false;

  final route = ModalBottomSheetRoute<bool>(
    builder: (_) => const AccountRequiredSheet(),
    // Com a letra grande (feature 009), o convite pode passar de metade da
    // tela; ele rola em vez de cortar os botões.
    isScrollControlled: true,
    backgroundColor: context.colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );
  _openSheet = route;
  final bool? goToLogin = await Navigator.of(context).push(route);
  if (goToLogin == true && context.mounted) context.go('/login');
  return false;
}
