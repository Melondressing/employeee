import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

final bootstrapAuthSessionProvider = Provider<AuthSession?>((_) => null);

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession?>((ref) {
  return AuthSessionNotifier(
    initialSession: ref.watch(bootstrapAuthSessionProvider),
  );
});

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier({AuthSession? initialSession}) : super(initialSession);

  Future<void> continueLocally() async {
    final session = AuthSession(
      email: 'local@employeeee.app',
      displayName: 'Local workspace',
      provider: 'local',
      isLocalOnly: true,
      createdAt: DateTime.now(),
    );
    state = session;
    await AuthStorage.saveSession(session);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final isPasswordReady = password.trim().isNotEmpty;
    final session = AuthSession(
      email: normalizedEmail,
      displayName: normalizedEmail.split('@').first,
      provider: isPasswordReady ? 'password-preview' : 'local',
      isLocalOnly: true,
      createdAt: DateTime.now(),
    );
    state = session;
    await AuthStorage.saveSession(session);
  }

  Future<void> signOut() async {
    state = null;
    await AuthStorage.clearSession();
  }
}

class AuthStorage {
  static const _sessionKey = 'auth_session';
  static Future<SharedPreferences>? _prefsFuture;

  static void resetCache() {
    _prefsFuture = null;
  }

  static Future<AuthSession?> loadSession() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AuthSession.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<void> saveSession(AuthSession session) async {
    final prefs = await _prefs;
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  static Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_sessionKey);
  }

  static Future<SharedPreferences> get _prefs {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }
}
