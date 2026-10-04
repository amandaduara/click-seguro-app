import 'dart:async';

import 'package:click_seguro_app/modules/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:click_seguro_app/modules/authentication/data/datasources/auth_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/authentication/data/repositories/auth_repository_impl.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/enter_as_guest_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/evaluate_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/login_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/register_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/request_password_reset_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/reset_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/verify_reset_code_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/forgot_password_controller.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class AuthenticationModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(injector<ApiClient>()),
      )
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          injector<AuthRemoteDataSource>(),
          injector<UserSessionService>(),
        ),
      )
      ..registerLazySingleton(() => const CredentialsValidator())
      ..registerLazySingleton(
        () => LoginUseCase(
          injector<AuthRepository>(),
          injector<CredentialsValidator>(),
        ),
      )
      ..registerLazySingleton(
        () => RegisterUseCase(
          injector<AuthRepository>(),
          injector<CredentialsValidator>(),
        ),
      )
      ..registerLazySingleton(
        () => EvaluatePasswordUseCase(injector<CredentialsValidator>()),
      )
      ..registerLazySingleton(
        () => EnterAsGuestUseCase(injector<AuthRepository>()),
      )
      ..registerLazySingleton(
        () => RequestPasswordResetUseCase(
          injector<AuthRepository>(),
          injector<CredentialsValidator>(),
        ),
      )
      ..registerLazySingleton(
        () => VerifyResetCodeUseCase(
          injector<AuthRepository>(),
          injector<CredentialsValidator>(),
        ),
      )
      ..registerLazySingleton(
        () => ResetPasswordUseCase(
          injector<AuthRepository>(),
          injector<CredentialsValidator>(),
        ),
      );
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [
      ChangeNotifierProvider(
        create: (_) => AuthenticationController(
          login: injector<LoginUseCase>(),
          register: injector<RegisterUseCase>(),
          evaluatePassword: injector<EvaluatePasswordUseCase>(),
          enterAsGuest: injector<EnterAsGuestUseCase>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => ForgotPasswordController(
          requestReset: injector<RequestPasswordResetUseCase>(),
          verifyCode: injector<VerifyResetCodeUseCase>(),
          resetPassword: injector<ResetPasswordUseCase>(),
          evaluatePassword: injector<EvaluatePasswordUseCase>(),
        ),
      ),
    ];
  }
}
