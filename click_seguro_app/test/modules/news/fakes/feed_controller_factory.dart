import 'package:click_seguro_app/modules/news/domain/usecases/get_categories_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_page_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';

import 'fake_news_repository.dart';

/// Agora fixo dos testes do feed: 5/10/2026, 15h (horário local).
final DateTime feedNow = DateTime(2026, 10, 5, 15);

/// Controller com os usecases reais sobre o [FakeNewsRepository].
FeedController buildFeedController(FakeNewsRepository repository) =>
    FeedController(
      getFeed: GetFeedUseCase(repository),
      getFeedPage: GetFeedPageUseCase(repository),
      getNews: GetNewsUseCase(repository),
      getCategories: GetCategoriesUseCase(repository),
      now: () => feedNow,
    );
