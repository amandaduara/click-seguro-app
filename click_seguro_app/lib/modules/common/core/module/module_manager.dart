import 'package:click_seguro_app/modules/common/core/module/module_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

import 'module_manager_interface.dart';

class ModuleManager implements ModuleManagerInterface {
  List<SingleChildWidget>? _providers;

  ModuleManager() {
    _providers = [];
  }

  @override
  List<SingleChildWidget> get providers => _providers!;

  @override
  Future<void> registerModules(List<ModuleInterface> modules) async {
    for (final ModuleInterface module in modules) {
      await module.registerServices(GetIt.instance);
    }

    for (final ModuleInterface module in modules) {
      final moduleProviders = module.providers(GetIt.instance);
      if (moduleProviders != null) {
        _providers!.addAll(moduleProviders);
      }
    }
  }
}
