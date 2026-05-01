class AuthSession {
  const AuthSession({
    required this.email,
    required this.displayName,
    required this.provider,
    required this.isLocalOnly,
    required this.createdAt,
  });

  final String email;
  final String displayName;
  final String provider;
  final bool isLocalOnly;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'provider': provider,
        'isLocalOnly': isLocalOnly,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Local user',
      provider: json['provider']?.toString() ?? 'local',
      isLocalOnly: json['isLocalOnly'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
