import '../constants/core/secure_storage_service.dart';

class SessionSnapshot {
  final String? accessToken;
  final String? refreshToken;
  final int? userId;
  final int? roleId;

  const SessionSnapshot({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.roleId,
  });

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;
  bool get hasUserContext =>
      userId != null && userId! > 0 && roleId != null && roleId! > 0;
  bool get isAuthenticated => hasToken && hasUserContext;
}

class SessionManager {
  SessionManager._();

  static Future<void> saveAuthSession({
    String? accessToken,
    String? refreshToken,
    int? userId,
    int? roleId,
  }) async {
    await SecureStorageService.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      roleId: roleId,
    );
  }

  static Future<SessionSnapshot> getSession() async {
    final accessToken = await SecureStorageService.getAccessToken();
    final refreshToken = await SecureStorageService.getRefreshToken();
    final userId = await SecureStorageService.getUserId();
    final roleId = await SecureStorageService.getRoleId();
    return SessionSnapshot(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      roleId: roleId,
    );
  }

  static Future<void> clearSession() async {
    await SecureStorageService.clearTokens();
  }
}
