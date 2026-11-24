import 'package:click_seguro_app/modules/assistant/presentation/pages/assistant_page.dart';
import 'package:go_router/go_router.dart';

const String assistantPath = '/assistant';

final List<RouteBase> assistantRoutes = [
  GoRoute(
    path: assistantPath,
    builder: (context, state) => const AssistantPage(),
  ),
];
