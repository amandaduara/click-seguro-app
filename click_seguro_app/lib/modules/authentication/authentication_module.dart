import 'dart:async';

import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class AuthenticationModule implements ModuleInterface {
  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [
      ChangeNotifierProvider(
        create: (_) => AuthenticationController(),
      ),
    ];
  }

  @override
  FutureOr<void> registerServices(GetIt injector) {}
}
