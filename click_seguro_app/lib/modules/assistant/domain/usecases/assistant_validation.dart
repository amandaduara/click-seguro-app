import '../failures/assistant_failures.dart';

AssistantInvalidInputFailure? validateBoundedText(
  String value, {
  required int min,
  required int max,
}) => value.trim().length < min || value.trim().length > max
    ? const AssistantInvalidInputFailure()
    : null;

AssistantInvalidInputFailure? validateSource(String? source) =>
    source != null && (source.trim().isEmpty || source.trim().length > 50)
    ? const AssistantInvalidInputFailure()
    : null;
