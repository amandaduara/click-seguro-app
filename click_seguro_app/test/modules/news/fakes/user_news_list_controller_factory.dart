import 'package:click_seguro_app/modules/news/domain/entities/news_list_kind.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_user_news_list_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/user_news_list_controller.dart';

import 'fake_news_repository.dart';

/// Controller com o usecase real sobre o [FakeNewsRepository].
UserNewsListController buildUserNewsListController(
  FakeNewsRepository repository, {
  NewsListKind kind = NewsListKind.saved,
}) => UserNewsListController(
  kind: kind,
  getUserNewsList: GetUserNewsListUseCase(repository),
);
