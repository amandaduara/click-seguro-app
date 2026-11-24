import '../failures/assistant_failures.dart';
import '../entities/assistant_constants.dart';

AssistantInvalidInputFailure? validateBoundedText(
  String value, {
  required int min,
  required int max,
}) => value.trim().length < min || value.trim().length > max
    ? const AssistantInvalidInputFailure()
    : null;

AssistantInvalidInputFailure? validateSource(String? source) =>
    source != null &&
        (source.trim().length < AssistantLimits.sourceMin ||
            source.trim().length > AssistantLimits.sourceMax)
    ? const AssistantInvalidInputFailure()
    : null;
