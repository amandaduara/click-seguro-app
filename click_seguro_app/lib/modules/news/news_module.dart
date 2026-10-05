import 'dart:async';

import 'package:click_seguro_app/modules/common/common.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

/// Esqueleto da Fase 0 (F0.7): a trilha registra aqui os seus serviços.
class NewsModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {}

  @override
  List<SingleChildWidget> providers(GetIt injector) => [];
}
