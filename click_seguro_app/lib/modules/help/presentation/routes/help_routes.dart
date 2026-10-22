import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/help/presentation/pages/help_contact_page.dart';
import 'package:click_seguro_app/modules/help/presentation/pages/help_page.dart';
import 'package:go_router/go_router.dart';

String helpContactPath({String? contactId}) =>
    contactId == null ? '/help/contact/new' : '/help/contact/$contactId';

/// Raiz da aba Ajuda, com o formulário de contato sobre as abas.
final GoRoute helpTabRoute = GoRoute(
  path: '/help',
  builder: (context, state) => const HelpPage(),
  routes: [
    // `new` antes de `:id`, para não ser lido como identificador.
    GoRoute(
      path: 'contact/new',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ContactFormPage(),
    ),
    GoRoute(
      path: 'contact/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          ContactFormPage(contactId: state.pathParameters['id']),
    ),
  ],
);
