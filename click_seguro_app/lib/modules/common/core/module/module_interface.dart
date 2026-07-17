import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

abstract class ModuleInterface {
  List<SingleChildWidget>? providers(GetIt injector);
  FutureOr<void> registerServices(GetIt injector);
}
