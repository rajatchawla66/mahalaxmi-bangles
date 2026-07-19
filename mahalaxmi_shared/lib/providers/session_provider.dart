import 'package:riverpod/riverpod.dart';

import '../models/app_session.dart';
import '../services/session_storage.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SharedPreferencesSessionStorage();
});

class SessionNotifier extends StateNotifier<AppSession> {
  final SessionStorage _storage;

  SessionNotifier(this._storage) : super(AppSession.loggedOut);

  Future<void> restore() async {
    final saved = await _storage.load();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> login(AppSession session) async {
    state = session;
    await _storage.save(session);
  }

  Future<void> logout() async {
    state = AppSession.loggedOut;
    await _storage.clear();
  }
}

final appSessionProvider =
    StateNotifierProvider<SessionNotifier, AppSession>((ref) {
  return SessionNotifier(ref.read(sessionStorageProvider));
});
