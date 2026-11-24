import 'package:click_seguro_app/modules/news/domain/entities/news_interaction_change.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';

/// Leituras, curtidas e "salvar" confirmados, de qualquer tela (specs/022
/// FR-005).
class WatchNewsInteractionsUseCase {
  WatchNewsInteractionsUseCase(this._repository);

  final NewsRepository _repository;

  Stream<NewsInteractionChange> call() => _repository.interactionChanges;
}
