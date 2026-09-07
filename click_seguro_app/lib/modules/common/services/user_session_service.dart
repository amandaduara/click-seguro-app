import 'package:flutter/foundation.dart';

enum UserSessionStatus { authenticated, unauthenticated }

class UserSessionService {
  String? token;
  String? userId;

  final ValueNotifier<UserSessionStatus> sessionStatus =
      ValueNotifier<UserSessionStatus>(UserSessionStatus.unauthenticated);

  void saveSession({
    required String newToken, 
    String? newUserId
  }) {
    token = newToken;
    userId = newUserId;
    sessionStatus.value = UserSessionStatus.authenticated;
  }

  void logout() {
    token = null;
    userId = null;
    sessionStatus.value = UserSessionStatus.unauthenticated;
  }

  bool get isAuthenticated => token != null;
}