import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_remote_data_source.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/news/data/repositories/news_repository_impl.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_categories_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_page_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class NewsModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton<NewsRemoteDataSource>(
        () => NewsRemoteDataSourceImpl(injector<ApiClient>()),
      )
      ..registerLazySingleton<NewsLocalDataSource>(
        () => NewsLocalDataSourceImpl(injector<LocalCacheService>()),
      )
      ..registerLazySingleton<NewsRepository>(
        () => NewsRepositoryImpl(
          injector<NewsRemoteDataSource>(),
          injector<NewsLocalDataSource>(),
        ),
      )
      ..registerLazySingleton(() => GetFeedUseCase(injector<NewsRepository>()))
      ..registerLazySingleton(
        () => GetFeedPageUseCase(injector<NewsRepository>()),
      )
      ..registerLazySingleton(() => GetNewsUseCase(injector<NewsRepository>()))
      ..registerLazySingleton(
        () => GetCategoriesUseCase(injector<NewsRepository>()),
      );
  }

  /// Acima do app: o estado do feed sobrevive à troca de aba e a abrir um
  /// detalhe (FR-025).
  @override
  List<SingleChildWidget> providers(GetIt injector) => [
    ChangeNotifierProvider(
      create: (_) => FeedController(
        getFeed: injector<GetFeedUseCase>(),
        getFeedPage: injector<GetFeedPageUseCase>(),
        getNews: injector<GetNewsUseCase>(),
        getCategories: injector<GetCategoriesUseCase>(),
      )..load(),
    ),
  ];
}
