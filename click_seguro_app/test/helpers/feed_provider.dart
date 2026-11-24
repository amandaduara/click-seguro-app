import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../modules/news/fakes/fake_news_repository.dart';
import '../modules/news/fakes/feed_controller_factory.dart';

/// Feed do Início sem rede, para testes que montam o app ou as rotas reais
/// (o `FeedController` vem do `NewsModule` no app).
SingleChildWidget fakeFeedProvider([FakeNewsRepository? repository]) =>
    ChangeNotifierProvider<FeedController>(
      create: (_) =>
          buildFeedController(repository ?? FakeNewsRepository())..load(),
    );
