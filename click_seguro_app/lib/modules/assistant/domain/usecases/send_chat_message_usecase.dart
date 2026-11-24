import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_chat_turn.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/assistant_constants.dart';
import 'package:click_seguro_app/modules/assistant/domain/failures/assistant_failures.dart';
import 'package:click_seguro_app/modules/assistant/domain/repositories/assistant_repository.dart';
import 'package:fpdart/fpdart.dart';

import 'assistant_validation.dart';

class SendChatMessageUseCase {
  SendChatMessageUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Either<Failure, String>> call(
    String message, {
    List<AiChatTurn> history = const [],
  }) {
    final invalid = validateBoundedText(
      message,
      min: AssistantLimits.chatMessageMin,
      max: AssistantLimits.chatMessageMax,
    );
    if (invalid != null ||
        history.length > AssistantLimits.contextTurnMax ||
        history.any(
          (turn) => turn.content.trim().length < AssistantLimits.contextTextMin,
        )) {
      return Future.value(
        Left(invalid ?? const AssistantInvalidInputFailure()),
      );
    }
    final boundedHistory = [
      for (final turn in history)
        AiChatTurn(
          role: turn.role,
          content: turn.content.length <= AssistantLimits.contextTextMax
              ? turn.content
              : _truncateContext(turn.content),
        ),
    ];
    return _repository.sendChatMessage(message.trim(), history: boundedHistory);
  }

  /// Evita deixar um par surrogate UTF-16 incompleto no fim do contexto.
  static String _truncateContext(String value) {
    const maxCodeUnits = AssistantLimits.contextTextMax;
    final int lastIncluded = value.codeUnitAt(maxCodeUnits - 1);
    final bool endsWithHighSurrogate =
        lastIncluded >= 0xD800 && lastIncluded <= 0xDBFF;
    return value.substring(
      0,
      endsWithHighSurrogate ? maxCodeUnits - 1 : maxCodeUnits,
    );
  }
}
