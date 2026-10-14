import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';

/// Uma página de uma lista da conta (salvas, lidas ou curtidas).
/// [isFromCache] só na página 1 das salvas sem conexão.
class UserNewsListResult {
  const UserNewsListResult({required this.page, required this.isFromCache});

  final NewsPageEntity page;
  final bool isFromCache;
}
