import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

abstract final class AssistantFailureKeys {
  static const invalidInput = AppStrings.assistantInvalidInput;
  static const invalidImage = AppStrings.assistantInvalidImage;
  static const providerFailed = AppStrings.assistantProviderFailed;
  static const parseFailed = AppStrings.assistantParseFailed;
  static const rateLimited = AppStrings.assistantRateLimited;
}

abstract class AssistantFailure extends Failure {
  const AssistantFailure(super.message);
}

class AssistantInvalidInputFailure extends AssistantFailure {
  const AssistantInvalidInputFailure()
    : super(AssistantFailureKeys.invalidInput);
}

class AssistantInvalidImageFailure extends AssistantFailure {
  const AssistantInvalidImageFailure()
    : super(AssistantFailureKeys.invalidImage);
}

class AssistantProviderFailure extends AssistantFailure {
  const AssistantProviderFailure() : super(AssistantFailureKeys.providerFailed);
}

class AssistantParseFailure extends AssistantFailure {
  const AssistantParseFailure() : super(AssistantFailureKeys.parseFailed);
}

class AssistantRateLimitedFailure extends AssistantFailure {
  const AssistantRateLimitedFailure() : super(AssistantFailureKeys.rateLimited);
}
