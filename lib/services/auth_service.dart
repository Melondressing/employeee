import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

final bootstrapAuthSessionProvider = Provider<AuthSession?>((_) => null);
final authApiClientProvider = Provider((_) => const AuthApiClient());

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession?>((ref) {
  return AuthSessionNotifier(
    initialSession: ref.watch(bootstrapAuthSessionProvider),
    apiClient: ref.watch(authApiClientProvider),
  );
});

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier({
    AuthSession? initialSession,
    required AuthApiClient apiClient,
  })  : _apiClient = apiClient,
        super(initialSession) {
    _verifyCloudSession();
  }

  final AuthApiClient _apiClient;

  Future<void> continueLocally() async {
    final session = AuthSession(
      username: 'local',
      email: 'local@employeeee.app',
      displayName: 'Local workspace',
      provider: 'local',
      isLocalOnly: true,
      createdAt: DateTime.now(),
    );
    state = session;
    await AuthStorage.saveSession(session);
  }

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final session = await _apiClient.login(
      username: email.trim(),
      password: password.trim(),
    );
    state = session;
    await AuthStorage.saveSession(session);
    return session;
  }

  Future<AuthSession> registerSharedAccount({
    required String username,
    required String password,
    required String displayName,
    required String inviteCode,
  }) async {
    final session = await _apiClient.register(
      username: username.trim(),
      password: password.trim(),
      displayName: displayName.trim(),
      inviteCode: inviteCode.trim(),
    );
    state = session;
    await AuthStorage.saveSession(session);
    return session;
  }

  Future<void> signOut() async {
    final token = state?.accessToken;
    if (token != null) {
      await _apiClient.logout(token);
    }
    state = null;
    await AuthStorage.clearSession();
  }

  Future<void> deleteAccount() async {
    final session = state;
    if (session == null) return;

    if (session.isLocalOnly) {
      state = null;
      await AuthStorage.clearSession();
      return;
    }

    final token = session.accessToken;
    if (token == null || token.isEmpty) {
      throw const AuthException('계정 삭제에는 다시 로그인이 필요해요.');
    }

    await _apiClient.deleteAccount(token);
    state = null;
    await AuthStorage.clearSession();
  }

  Future<void> _verifyCloudSession() async {
    final session = state;
    if (session == null || !session.hasCloudToken) return;

    try {
      final verified = await _apiClient.me(session.accessToken!);
      state = verified;
      await AuthStorage.saveSession(verified);
    } catch (_) {
      state = null;
      await AuthStorage.clearSession();
    }
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

class AuthApiClient {
  const AuthApiClient();

  static const defaultBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'https://budget-lee.pages.dev',
  );

  Uri _uri(String path) {
    final base = defaultBaseUrl.endsWith('/')
        ? defaultBaseUrl.substring(0, defaultBaseUrl.length - 1)
        : defaultBaseUrl;
    return Uri.parse('$base$path');
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final body = await _postJson(
      '/api/auth/login',
      {
        'username': username,
        'password': password,
      },
    );
    return _sessionFromAuthPayload(
      payload: body,
      fallbackUsername: username,
      provider: 'budget-lee',
    );
  }

  Future<AuthSession> register({
    required String username,
    required String password,
    required String displayName,
    required String inviteCode,
  }) async {
    final body = await _postJson(
      '/api/auth/register',
      {
        'username': username,
        'password': password,
        'name': displayName,
        'inviteCode': inviteCode,
      },
    );
    return _sessionFromAuthPayload(
      payload: body,
      fallbackUsername: username,
      provider: 'budget-lee',
    );
  }

  Future<AuthSession> me(String token) async {
    final response = await http.get(
      _uri('/api/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 12));

    final body = _decodeResponse(response);
    final user = _jsonMap(body['user']);
    return _sessionFromUserPayload(
      user: user,
      token: token,
      provider: 'budget-lee',
    );
  }

  Future<void> logout(String token) async {
    try {
      await http
          .post(
            _uri('/api/auth/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Local sign-out should not be blocked by a transient network failure.
    }
  }

  Future<void> deleteAccount(String token) async {
    final response = await http.delete(
      _uri('/api/account/delete'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 12));
    _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(
          _uri(path),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('서버 응답을 이해하지 못했어요.');
    }

    final success = decoded['success'] == true;
    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      throw AuthException(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            '로그인 서버 요청에 실패했어요.',
      );
    }
    return decoded;
  }

  AuthSession _sessionFromAuthPayload({
    required Map<String, dynamic> payload,
    required String fallbackUsername,
    required String provider,
  }) {
    final token = payload['token']?.toString() ??
        payload['access']?.toString() ??
        payload['accessToken']?.toString();
    if (token == null || token.isEmpty) {
      throw const AuthException('로그인 토큰을 받지 못했어요.');
    }

    final user = _jsonMap(payload['user']);
    return _sessionFromUserPayload(
      user: user,
      token: token,
      fallbackUsername: fallbackUsername,
      provider: provider,
    );
  }

  AuthSession _sessionFromUserPayload({
    required Map<String, dynamic> user,
    required String token,
    String? fallbackUsername,
    required String provider,
  }) {
    final username =
        user['username']?.toString() ?? fallbackUsername?.trim() ?? '';
    final displayName = user['name']?.toString().trim().isNotEmpty == true
        ? user['name'].toString()
        : username;
    final email = user['email']?.toString() ??
        (username.contains('@') ? username : '$username@budget-lee.local');

    return AuthSession(
      userId: _parseInt(user['id']),
      username: username,
      email: email,
      displayName: displayName,
      provider: provider,
      isLocalOnly: false,
      createdAt: DateTime.now(),
      accessToken: token,
      apiBaseUrl: defaultBaseUrl,
    );
  }

  Map<String, dynamic> _jsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
