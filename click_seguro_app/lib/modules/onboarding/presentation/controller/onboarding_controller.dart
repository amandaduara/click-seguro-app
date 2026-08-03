import 'package:click_seguro_app/modules/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:flutter/foundation.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController(this._completeOnboardingUseCase);

  final CompleteOnboardingUseCase _completeOnboardingUseCase;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  bool get isLastPage =>
      _currentPage == OnboardingPageContent.pages.length - 1;

  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
  }

  Future<bool> next() async {
    if (!isLastPage) {
      _currentPage++;
      notifyListeners();
      return false;
    }

    await _finish();
    return true;
  }

  Future<bool> skip() async {
    await _finish();
    return true;
  }

  Future<void> _finish() async {
    final result = await _completeOnboardingUseCase();
    // Falha ao persistir é tratada como não-bloqueante: o usuário segue para o
    // login mesmo assim
    result.fold((failure) {}, (_) {});
  }
}
