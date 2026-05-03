class AuthSession {
  const AuthSession({
    this.userId,
    this.username = '',
    required this.email,
    required this.displayName,
    required this.provider,
    required this.isLocalOnly,
    required this.createdAt,
    this.accessToken,
    this.apiBaseUrl,
  });

  final int? userId;
  final String username;
  final String email;
  final String displayName;
  final String provider;
  final bool isLocalOnly;
  final DateTime createdAt;
  final String? accessToken;
  final String? apiBaseUrl;

  bool get hasCloudToken => !isLocalOnly && accessToken != null;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'email': email,
        'displayName': displayName,
        'provider': provider,
        'isLocalOnly': isLocalOnly,
        'createdAt': createdAt.toIso8601String(),
        'accessToken': accessToken,
        'apiBaseUrl': apiBaseUrl,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: _parseInt(json['userId']),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Local user',
      provider: json['provider']?.toString() ?? 'local',
      isLocalOnly: json['isLocalOnly'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      accessToken: json['accessToken']?.toString(),
      apiBaseUrl: json['apiBaseUrl']?.toString(),
    );
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
