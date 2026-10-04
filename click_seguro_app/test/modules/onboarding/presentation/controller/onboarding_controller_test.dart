import 'package:click_seguro_app/modules/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/controller/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_onboarding_repository.dart';

void main() {
  late FakeOnboardingRepository repository;
  late OnboardingController controller;
  late int notifications;

  setUp(() {
    repository = FakeOnboardingRepository();
    controller = OnboardingController(CompleteOnboardingUseCase(repository));
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  test('começa no 1º slide', () {
    expect(controller.currentPage, 0);
    expect(controller.isLastPage, isFalse);
  });

  test('"Continuar" nos dois primeiros slides avança sem gravar', () async {
    expect(await controller.next(), isFalse);
    expect(controller.currentPage, 1);
    expect(await controller.next(), isFalse);
    expect(controller.currentPage, 2);

    expect(controller.isLastPage, isTrue);
    expect(notifications, 2);
    expect(repository.completeCalls, 0);
  });

  test('"Começar" no último slide termina e grava a marcação', () async {
    controller.onPageChanged(2);

    expect(await controller.next(), isTrue);
    expect(repository.completeCalls, 1);
    expect(repository.seen, isTrue);
  });

  test('deslizar atualiza a página e notifica', () {
    controller.onPageChanged(2);

    expect(controller.currentPage, 2);
    expect(controller.isLastPage, isTrue);
    expect(notifications, 1);
  });

  test('"Pular" em qualquer slide termina e grava a marcação', () async {
    expect(await controller.skip(), isTrue);
    expect(repository.completeCalls, 1);
  });

  group('falha ao gravar a marcação não prende o usuário (FR-010)', () {
    setUp(() => repository.failOnComplete = true);

    test('"Começar" ainda termina', () async {
      controller.onPageChanged(2);

      expect(await controller.next(), isTrue);
    });

    test('"Pular" ainda termina', () async {
      expect(await controller.skip(), isTrue);
    });
  });
}
