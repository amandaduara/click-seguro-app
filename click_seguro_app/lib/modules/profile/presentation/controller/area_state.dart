import 'package:click_seguro_app/core/errors/failure.dart';

/// Estado de uma área do perfil que pode falhar sozinha (R2 de
/// specs/012-perfil).
sealed class AreaState<T> {
  const AreaState();
}

final class AreaLoading<T> extends AreaState<T> {
  const AreaLoading();
}

final class AreaLoaded<T> extends AreaState<T> {
  const AreaLoaded(this.value);

  final T value;
}

final class AreaFailed<T> extends AreaState<T> {
  const AreaFailed(this.failure);

  final Failure failure;
}
