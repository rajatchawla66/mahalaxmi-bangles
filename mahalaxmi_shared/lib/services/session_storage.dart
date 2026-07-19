import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_session.dart';

abstract class SessionStorage {
  Future<AppSession?> load();
  Future<void> save(AppSession session);
  Future<void> clear();
}

class InMemorySessionStorage implements SessionStorage {
  AppSession? _session;

  @override
  Future<AppSession?> load() async => _session;

  @override
  Future<void> save(AppSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

class SharedPreferencesSessionStorage implements SessionStorage {
  static const _key = 'app_session';

  @override
  Future<AppSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppSession.fromJson(map);
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  @override
  Future<void> save(AppSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
