part of '../main.dart';

class _FirebaseAuthService {
  const _FirebaseAuthService();

  static const String _projectId = 'shubham-jewellers-1976';
  static const String _apiKey = 'AIzaSyCoR4bdnNAFxCPFxwNj6sTSsU6sc2m5e6o';
  static const String _adminEmail = 'jatinsoni.in@gmail.com';

  Future<_AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:signInWithPassword',
      {'key': _apiKey},
    );
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw StateError(_firebaseAuthErrorMessage(body));
    }
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected authentication response.');
    }

    final signedInEmail = (body['email'] as String? ?? email).trim();
    final uid = (body['localId'] as String? ?? '').trim();
    final idToken = (body['idToken'] as String? ?? '').trim();
    final refreshToken = (body['refreshToken'] as String? ?? '').trim();
    if (uid.isEmpty || idToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException('Authentication response is incomplete.');
    }

    final role = await _resolveRole(
      idToken: idToken,
      uid: uid,
      email: signedInEmail,
    );

    return _AuthSession(
      uid: uid,
      email: signedInEmail,
      idToken: idToken,
      refreshToken: refreshToken,
      role: role,
    );
  }

  Future<_AuthSession> refreshSession(_AuthSession session) async {
    final uri = Uri.https('securetoken.googleapis.com', '/v1/token', {
      'key': _apiKey,
    });
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': session.refreshToken,
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw StateError('Could not restore your login session.');
    }
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected refresh response.');
    }

    final idToken = (body['id_token'] as String? ?? '').trim();
    final refreshToken = (body['refresh_token'] as String? ?? '').trim();
    final uid = (body['user_id'] as String? ?? session.uid).trim();
    if (idToken.isEmpty || refreshToken.isEmpty || uid.isEmpty) {
      throw const FormatException('Refresh response is incomplete.');
    }

    final role = await _resolveRole(
      idToken: idToken,
      uid: uid,
      email: session.email,
    );

    return _AuthSession(
      uid: uid,
      email: session.email,
      idToken: idToken,
      refreshToken: refreshToken,
      role: role,
    );
  }

  Future<AppAccessRole> _resolveRole({
    required String idToken,
    required String uid,
    required String email,
  }) async {
    try {
      final uri = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$_projectId/databases/(default)/documents/users/$uid',
        {'key': _apiKey},
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $idToken'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final fields = body['fields'];
          if (fields is Map<String, dynamic>) {
            final roleField = fields['role'];
            if (roleField is Map<String, dynamic>) {
              final roleText = (roleField['stringValue'] as String? ?? '')
                  .trim()
                  .toLowerCase();
              if (roleText == 'admin') {
                return AppAccessRole.admin;
              }
              if (roleText == 'staff') {
                return AppAccessRole.staff;
              }
              if (roleText == 'user') {
                return AppAccessRole.user;
              }
            }
          }
        }
      }
    } catch (_) {}

    return email.trim().toLowerCase() == _adminEmail.toLowerCase()
        ? AppAccessRole.admin
        : AppAccessRole.user;
  }

  static String _firebaseAuthErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final message = (error['message'] as String? ?? '').trim();
        switch (message) {
          case 'INVALID_LOGIN_CREDENTIALS':
          case 'INVALID_PASSWORD':
          case 'EMAIL_NOT_FOUND':
            return 'Invalid email or password.';
          case 'USER_DISABLED':
            return 'This user account has been disabled.';
          case 'TOO_MANY_ATTEMPTS_TRY_LATER':
            return 'Too many attempts. Please try again later.';
        }
      }
    }
    return 'Could not sign in with Firebase.';
  }
}

class _AuthSession {
  const _AuthSession({
    required this.uid,
    required this.email,
    required this.idToken,
    required this.refreshToken,
    required this.role,
  });

  final String uid;
  final String email;
  final String idToken;
  final String refreshToken;
  final AppAccessRole role;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'role': role.name,
    };
  }

  factory _AuthSession.fromJson(Map<String, dynamic> json) {
    return _AuthSession(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      idToken: json['idToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      role: AppAccessRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => AppAccessRole.user,
      ),
    );
  }
}
