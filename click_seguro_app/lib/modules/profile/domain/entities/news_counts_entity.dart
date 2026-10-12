/// Totais das listas de notícias da conta (`meta.total` de cada uma).
class NewsCountsEntity {
  const NewsCountsEntity({
    required this.read,
    required this.saved,
    required this.liked,
  });

  final int read;
  final int saved;
  final int liked;
}
