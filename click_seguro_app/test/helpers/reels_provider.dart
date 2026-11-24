import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../modules/news/fakes/fake_news_repository.dart';
import '../modules/news/fakes/reels_controller_factory.dart';

/// Reels da aba central sem rede, para testes que montam o app ou as rotas
/// reais (o `ReelsController` vem do `NewsModule` no app).
SingleChildWidget fakeReelsProvider([FakeNewsRepository? repository]) =>
    ChangeNotifierProvider<ReelsController>(
      create: (_) => buildReelsController(
        repository ?? FakeNewsRepository(),
        ValueNotifier(UserSessionStatus.guest),
      ),
    );
