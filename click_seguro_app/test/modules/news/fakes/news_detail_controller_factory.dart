import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_detail_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/mark_news_as_read_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_save_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_controller.dart';
import 'package:flutter/foundation.dart';

import 'fake_news_repository.dart';

/// Controller com os usecases reais sobre o [FakeNewsRepository].
NewsDetailController buildNewsDetailController(
  FakeNewsRepository repository,
  ValueListenable<UserSessionStatus> sessionStatus, {
  String newsId = 'n1',
}) => NewsDetailController(
  getNewsDetail: GetNewsDetailUseCase(repository),
  markAsRead: MarkNewsAsReadUseCase(repository),
  toggleSave: ToggleSaveUseCase(repository),
  sessionStatus: sessionStatus,
  newsId: newsId,
);
