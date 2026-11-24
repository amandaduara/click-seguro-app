import 'package:provider/single_child_widget.dart';

import 'module_interface.dart';

abstract class ModuleManagerInterface {
  Future<void> registerModules(List<ModuleInterface> modules);
  List<SingleChildWidget> get providers;
}
