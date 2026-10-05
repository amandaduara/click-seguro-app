import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/help/presentation/pages/help_contact_page.dart';
import 'package:click_seguro_app/modules/help/presentation/pages/help_page.dart';
import 'package:go_router/go_router.dart';

/// Raiz da aba Ajuda, com o formulário de contato sobre as abas.
final GoRoute helpTabRoute = GoRoute(
  path: '/help',
  builder: (context, state) => const HelpPage(),
  routes: [
    // `new` antes de `:id`, para não ser lido como identificador.
    GoRoute(
      path: 'contact/new',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const HelpContactPage(),
    ),
    GoRoute(
      path: 'contact/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          HelpContactPage(contactId: state.pathParameters['id']),
    ),
  ],
);
