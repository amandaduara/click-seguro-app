import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// A notícia não existe mais no serviço (404 `NEWS_NOT_FOUND`).
class NewsNotFoundFailure extends Failure {
  const NewsNotFoundFailure() : super(AppStrings.newsErrorNotFound);
}
