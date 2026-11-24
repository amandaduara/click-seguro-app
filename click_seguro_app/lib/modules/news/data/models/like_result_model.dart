import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';

/// `POST /app/news/{id}/like`: `{liked, likesCount}`.
class LikeResultModel {
  const LikeResultModel({required this.liked, required this.likesCount});

  factory LikeResultModel.fromJson(Map<String, dynamic> json) =>
      LikeResultModel(
        liked: json['liked'] as bool,
        likesCount: (json['likesCount'] as num).toInt(),
      );

  final bool liked;
  final int likesCount;

  LikeResultEntity toEntity() =>
      LikeResultEntity(liked: liked, likesCount: likesCount);
}
