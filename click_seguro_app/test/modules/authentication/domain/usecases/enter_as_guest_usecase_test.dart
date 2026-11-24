import 'package:click_seguro_app/modules/authentication/domain/usecases/enter_as_guest_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  test('repassa ao repository', () async {
    final repository = FakeAuthRepository();

    final result = await EnterAsGuestUseCase(repository)();

    expect(result.isRight(), isTrue);
    expect(repository.guestCalls, 1);
  });
}
