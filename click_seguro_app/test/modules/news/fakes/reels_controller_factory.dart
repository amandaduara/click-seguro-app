import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_reels_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_like_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_save_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_controller.dart';
import 'package:flutter/foundation.dart';

import 'fake_news_repository.dart';

/// Controller com os usecases reais sobre o [FakeNewsRepository].
ReelsController buildReelsController(
  FakeNewsRepository repository,
  ValueListenable<UserSessionStatus> sessionStatus,
) => ReelsController(
  getReels: GetReelsUseCase(repository),
  toggleLike: ToggleLikeUseCase(repository),
  toggleSave: ToggleSaveUseCase(repository),
  sessionStatus: sessionStatus,
);
