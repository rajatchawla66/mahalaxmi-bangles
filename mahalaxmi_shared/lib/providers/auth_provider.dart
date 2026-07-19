import 'package:riverpod/riverpod.dart';

import '../models/app_session.dart';
import 'session_provider.dart';

sealed class AuthFailure {
  const AuthFailure();
}

class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

class NetworkError extends AuthFailure {
  final String message;
  const NetworkError(this.message);
}

const _adminPassword = 'admin123';
const _labourPassword = 'labour123';

class AuthController {
  final SessionNotifier _sessionNotifier;

  AuthController(this._sessionNotifier);

  Future<AuthFailure?> loginAdmin(String username, String password) async {
    if (password != _adminPassword) {
      return const InvalidCredentials();
    }
    await _sessionNotifier.login(AppSession.admin(username));
    return null;
  }

  Future<AuthFailure?> loginLabour(String username, String password) async {
    if (password != _labourPassword) {
      return const InvalidCredentials();
    }
    await _sessionNotifier.login(AppSession.labour(username));
    return null;
  }

  Future<void> logout() async {
    await _sessionNotifier.logout();
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final notifier = ref.read(appSessionProvider.notifier);
  return AuthController(notifier);
});
