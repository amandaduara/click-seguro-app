import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_categories_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_page_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/watch_news_interactions_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:flutter/foundation.dart';

import 'fake_news_repository.dart';

/// Agora fixo dos testes do feed: 5/10/2026, 15h (horário local).
final DateTime feedNow = DateTime(2026, 10, 5, 15);

/// Controller com os usecases reais sobre o [FakeNewsRepository]. Sem
/// [sessionStatus], uma sessão de visitante que não muda.
FeedController buildFeedController(
  FakeNewsRepository repository, {
  ValueListenable<UserSessionStatus>? sessionStatus,
}) => FeedController(
  getFeed: GetFeedUseCase(repository),
  getFeedPage: GetFeedPageUseCase(repository),
  getNews: GetNewsUseCase(repository),
  getCategories: GetCategoriesUseCase(repository),
  watchInteractions: WatchNewsInteractionsUseCase(repository),
  sessionStatus:
      sessionStatus ??
      ValueNotifier<UserSessionStatus>(UserSessionStatus.guest),
  now: () => feedNow,
);
