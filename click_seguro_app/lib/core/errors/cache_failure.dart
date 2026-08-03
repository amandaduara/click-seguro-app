import 'package:click_seguro_app/core/errors/failure.dart';

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Falha ao acessar o armazenamento local']);
}
