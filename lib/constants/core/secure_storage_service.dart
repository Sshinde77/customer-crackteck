import 'dart:async';

/// Lightweight token storage abstraction.
///
/// NOTE: This implementation currently keeps tokens in memory only.
/// You can later swap the internals to use `flutter_secure_storage` or
/// another secure persistence mechanism without changing call sites.
class SecureStorageService {
  static String? _accessToken;
  static String? _refreshToken;
  static int? _userId;
  static int? _roleId;

  /// Get the currently stored access token (if any).
  static Future<String?> getAccessToken() async {
    return _accessToken;
  }

  /// Persist a new access token.
  static Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  /// Get the currently stored refresh token (if any).
  static Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  /// Persist a new refresh token.
  static Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }
  /// Get the currently stored user id (if any).
  static Future<int?> getUserId() async {
    return _userId;
  }

  /// Persist the current user id.
  static Future<void> saveUserId(int userId) async {
    _userId = userId;
  }

  static Future<int?> getRoleId() async {
    return _roleId;
  }
  static Future<void> saveRoleId(int roleId) async {
    _roleId = roleId;
  }

  /// Clear all stored tokens and role metadata.
  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
  }
}
