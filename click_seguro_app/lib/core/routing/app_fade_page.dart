import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_page_transitions.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Página com esmaecimento, para as rotas que substituem a pilha com `go`
/// (splash → início, sair → login): deslizar sugeriria que dá para voltar
/// (specs/022 R4, FR-018). Com o movimento reduzido, troca seca.
CustomTransitionPage<void> appFadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      arguments: <String, String>{
        ...state.pathParameters,
        ...state.uri.queryParameters,
      },
      restorationId: state.pageKey.value,
      // A rota fixa a duração ao ser criada, antes de ter contexto; o corte
      // abaixo cuida do movimento reduzido.
      transitionDuration: AppMotion.normal.medium,
      reverseTransitionDuration: AppMotion.normal.medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          AppMotion.of(context).reduced
          ? MotionCut(animation: animation, child: child)
          : FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AppMotion.enter,
                reverseCurve: AppMotion.exit,
              ),
              child: child,
            ),
      child: child,
    );
