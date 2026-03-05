import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight token storage abstraction.
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _roleIdKey = 'role_id';

  static SharedPreferences? _prefs;
  static bool _initialized = false;

  static String? _accessToken;
  static String? _refreshToken;
  static int? _userId;
  static int? _roleId;

  static Future<void> _ensureInitialized() async {
    if (_initialized && _prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _accessToken = _prefs!.getString(_accessTokenKey);
    _refreshToken = _prefs!.getString(_refreshTokenKey);
    _userId = _prefs!.getInt(_userIdKey);
    _roleId = _prefs!.getInt(_roleIdKey);
    _initialized = true;
  }

  /// Get the currently stored access token (if any).
  static Future<String?> getAccessToken() async {
    await _ensureInitialized();
    return _accessToken;
  }

  /// Persist a new access token.
  static Future<void> saveAccessToken(String token) async {
    await _ensureInitialized();
    _accessToken = token;
    await _prefs!.setString(_accessTokenKey, token);
  }

  /// Get the currently stored refresh token (if any).
  static Future<String?> getRefreshToken() async {
    await _ensureInitialized();
    return _refreshToken;
  }

  /// Persist a new refresh token.
  static Future<void> saveRefreshToken(String token) async {
    await _ensureInitialized();
    _refreshToken = token;
    await _prefs!.setString(_refreshTokenKey, token);
  }

  /// Get the currently stored user id (if any).
  static Future<int?> getUserId() async {
    await _ensureInitialized();
    return _userId;
  }

  /// Persist the current user id.
  static Future<void> saveUserId(int userId) async {
    await _ensureInitialized();
    _userId = userId;
    await _prefs!.setInt(_userIdKey, userId);
  }

  static Future<int?> getRoleId() async {
    await _ensureInitialized();
    return _roleId;
  }

  static Future<void> saveRoleId(int roleId) async {
    await _ensureInitialized();
    _roleId = roleId;
    await _prefs!.setInt(_roleIdKey, roleId);
  }

  /// Persist a full or partial auth session atomically.
  static Future<void> saveSession({
    String? accessToken,
    String? refreshToken,
    int? userId,
    int? roleId,
  }) async {
    await _ensureInitialized();

    final writes = <Future<bool>>[];
    if (accessToken != null && accessToken.isNotEmpty) {
      _accessToken = accessToken;
      writes.add(_prefs!.setString(_accessTokenKey, accessToken));
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
      writes.add(_prefs!.setString(_refreshTokenKey, refreshToken));
    }
    if (userId != null && userId > 0) {
      _userId = userId;
      writes.add(_prefs!.setInt(_userIdKey, userId));
    }
    if (roleId != null && roleId > 0) {
      _roleId = roleId;
      writes.add(_prefs!.setInt(_roleIdKey, roleId));
    }

    if (writes.isNotEmpty) {
      await Future.wait(writes);
    }
  }

  /// Clear all stored tokens and role metadata.
  static Future<void> clearTokens() async {
    await _ensureInitialized();
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _roleId = null;
    await Future.wait([
      _prefs!.remove(_accessTokenKey),
      _prefs!.remove(_refreshTokenKey),
      _prefs!.remove(_userIdKey),
      _prefs!.remove(_roleIdKey),
    ]);
  }
}
