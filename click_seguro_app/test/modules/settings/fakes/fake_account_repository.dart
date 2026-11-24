import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/account_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Conta de teste.
const AccountSummaryEntity testAccount = AccountSummaryEntity(
  name: 'Maria da Silva',
  receiveNotifications: true,
);

/// Repository em memória: cada método tem uma fila de respostas (a última se
/// repete) e um `Completer` opcional para segurar a resposta.
class FakeAccountRepository implements AccountRepository {
  final List<Either<Failure, AccountSummaryEntity>> accountResults = [
    const Right(testAccount),
  ];
  final List<Either<Failure, Unit>> alertsResults = [const Right(unit)];
  final List<Either<Failure, Unit>> changeResults = [const Right(unit)];

  Completer<void>? accountGate;
  Completer<void>? alertsGate;
  Completer<void>? changeGate;

  int accountCalls = 0;
  final List<bool> alertsCalls = [];
  final List<({String current, String newPassword})> changeCalls = [];

  int get totalCalls => accountCalls + alertsCalls.length + changeCalls.length;

  T _next<T>(List<T> queue) =>
      queue.length > 1 ? queue.removeAt(0) : queue.first;

  Future<T> _answer<T>(List<T> queue, Completer<void>? gate) async {
    final T result = _next(queue);
    await gate?.future;
    return result;
  }

  @override
  Future<Either<Failure, AccountSummaryEntity>> getAccount() {
    accountCalls++;
    return _answer(accountResults, accountGate);
  }

  @override
  Future<Either<Failure, Unit>> setReceiveAlerts(bool value) {
    alertsCalls.add(value);
    return _answer(alertsResults, alertsGate);
  }

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    changeCalls.add((current: currentPassword, newPassword: newPassword));
    return _answer(changeResults, changeGate);
  }
}
