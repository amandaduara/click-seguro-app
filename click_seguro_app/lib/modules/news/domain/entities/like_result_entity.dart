/// Estado da curtida depois do toggle, como o servidor devolveu.
class LikeResultEntity {
  const LikeResultEntity({required this.liked, required this.likesCount});

  final bool liked;
  final int likesCount;
}
