import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// Listas de notícias da conta em `/users/me/news/{segment}` (R8 de
/// specs/012-perfil). [name] é o segmento do caminho da API e da rota.
enum NewsListKind {
  saved(
    title: AppStrings.newsSavedTitle,
    empty: AppStrings.newsSavedEmpty,
    emptyHint: AppStrings.newsSavedEmptyHint,
    guestBody: AppStrings.newsSavedGuestBody,
  ),
  read(
    title: AppStrings.newsReadTitle,
    empty: AppStrings.newsReadEmpty,
    emptyHint: AppStrings.newsReadEmptyHint,
    guestBody: AppStrings.newsReadGuestBody,
  ),
  liked(
    title: AppStrings.newsLikedTitle,
    empty: AppStrings.newsLikedEmpty,
    emptyHint: AppStrings.newsLikedEmptyHint,
    guestBody: AppStrings.newsLikedGuestBody,
  );

  const NewsListKind({
    required this.title,
    required this.empty,
    required this.emptyHint,
    required this.guestBody,
  });

  /// Chaves de tradução da tela.
  final String title;
  final String empty;
  final String emptyHint;
  final String guestBody;

  /// Só as salvas guardam cópia para ler sem internet (RNF-002).
  bool get keepsCopy => this == saved;
}
