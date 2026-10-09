import 'package:click_seguro_app/modules/news/domain/usecases/get_saved_news_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/saved_news_controller.dart';

import 'fake_news_repository.dart';

/// Controller com o usecase real sobre o [FakeNewsRepository].
SavedNewsController buildSavedNewsController(FakeNewsRepository repository) =>
    SavedNewsController(getSavedNews: GetSavedNewsUseCase(repository));
