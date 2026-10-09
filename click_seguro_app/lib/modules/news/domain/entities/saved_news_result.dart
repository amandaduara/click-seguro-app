import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';

/// Uma página das notícias salvas. [isFromCache] só na página 1 sem conexão.
class SavedNewsResult {
  const SavedNewsResult({required this.page, required this.isFromCache});

  final NewsPageEntity page;
  final bool isFromCache;
}
