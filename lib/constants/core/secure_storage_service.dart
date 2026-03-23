import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight token storage abstraction.
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _roleIdKey = 'role_id';
  static const String _userDataKey = 'user_data';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static bool _initialized = false;

  static String? _accessToken;
  static String? _refreshToken;
  static int? _userId;
  static int? _roleId;
  static Map<String, dynamic>? _userData;

  static Future<void> initialize() => _ensureInitialized();

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _migrateLegacySessionFromSharedPreferences();
    final values = await Future.wait<String?>([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
      _storage.read(key: _userIdKey),
      _storage.read(key: _roleIdKey),
      _storage.read(key: _userDataKey),
    ]);
    _accessToken = _normalizedString(values[0]);
    _refreshToken = _normalizedString(values[1]);
    _userId = _parsePositiveInt(values[2]);
    _roleId = _parsePositiveInt(values[3]);
    _userData = _decodeUserData(values[4]);
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
    final normalized = token.trim();
    _accessToken = normalized;
    await _storage.write(key: _accessTokenKey, value: normalized);
  }

  /// Get the currently stored refresh token (if any).
  static Future<String?> getRefreshToken() async {
    await _ensureInitialized();
    return _refreshToken;
  }

  /// Persist a new refresh token.
  static Future<void> saveRefreshToken(String token) async {
    await _ensureInitialized();
    final normalized = token.trim();
    _refreshToken = normalized;
    await _storage.write(key: _refreshTokenKey, value: normalized);
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
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  static Future<int?> getRoleId() async {
    await _ensureInitialized();
    return _roleId;
  }

  static Future<void> saveRoleId(int roleId) async {
    await _ensureInitialized();
    _roleId = roleId;
    await _storage.write(key: _roleIdKey, value: roleId.toString());
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    await _ensureInitialized();
    return _userData == null ? null : Map<String, dynamic>.from(_userData!);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _ensureInitialized();
    _userData = Map<String, dynamic>.from(userData);
    await _storage.write(key: _userDataKey, value: jsonEncode(_userData));
  }

  /// Persist a full or partial auth session atomically.
  static Future<void> saveSession({
    String? accessToken,
    String? refreshToken,
    int? userId,
    int? roleId,
    Map<String, dynamic>? userData,
  }) async {
    await _ensureInitialized();

    final writes = <Future<void>>[];
    if (accessToken != null && accessToken.isNotEmpty) {
      final normalized = accessToken.trim();
      _accessToken = normalized;
      writes.add(_storage.write(key: _accessTokenKey, value: normalized));
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      final normalized = refreshToken.trim();
      _refreshToken = normalized;
      writes.add(_storage.write(key: _refreshTokenKey, value: normalized));
    }
    if (userId != null && userId > 0) {
      _userId = userId;
      writes.add(_storage.write(key: _userIdKey, value: userId.toString()));
    }
    if (roleId != null && roleId > 0) {
      _roleId = roleId;
      writes.add(_storage.write(key: _roleIdKey, value: roleId.toString()));
    }
    if (userData != null && userData.isNotEmpty) {
      _userData = Map<String, dynamic>.from(userData);
      writes.add(
        _storage.write(key: _userDataKey, value: jsonEncode(_userData)),
      );
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
    _userData = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _roleIdKey),
      _storage.delete(key: _userDataKey),
    ]);
    await _clearLegacySharedPreferences();
  }

  static Future<void> _migrateLegacySessionFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final legacyAccessToken = _normalizedString(
      prefs.getString(_accessTokenKey),
    );
    final legacyRefreshToken = _normalizedString(
      prefs.getString(_refreshTokenKey),
    );
    final legacyUserId = prefs.getInt(_userIdKey);
    final legacyRoleId = prefs.getInt(_roleIdKey);
    final legacyUserData = _normalizedString(prefs.getString(_userDataKey));

    if (legacyAccessToken == null &&
        legacyRefreshToken == null &&
        legacyUserId == null &&
        legacyRoleId == null &&
        legacyUserData == null) {
      return;
    }

    final secureValues = await Future.wait<String?>([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
      _storage.read(key: _userIdKey),
      _storage.read(key: _roleIdKey),
      _storage.read(key: _userDataKey),
    ]);

    final writes = <Future<void>>[];
    if (_normalizedString(secureValues[0]) == null &&
        legacyAccessToken != null) {
      writes.add(
        _storage.write(key: _accessTokenKey, value: legacyAccessToken),
      );
    }
    if (_normalizedString(secureValues[1]) == null &&
        legacyRefreshToken != null) {
      writes.add(
        _storage.write(key: _refreshTokenKey, value: legacyRefreshToken),
      );
    }
    if (_parsePositiveInt(secureValues[2]) == null &&
        legacyUserId != null &&
        legacyUserId > 0) {
      writes.add(
        _storage.write(key: _userIdKey, value: legacyUserId.toString()),
      );
    }
    if (_parsePositiveInt(secureValues[3]) == null &&
        legacyRoleId != null &&
        legacyRoleId > 0) {
      writes.add(
        _storage.write(key: _roleIdKey, value: legacyRoleId.toString()),
      );
    }
    if (_normalizedString(secureValues[4]) == null && legacyUserData != null) {
      writes.add(_storage.write(key: _userDataKey, value: legacyUserData));
    }

    if (writes.isNotEmpty) {
      await Future.wait(writes);
    }

    await _clearLegacySharedPreferences(prefs);
  }

  static Future<void> _clearLegacySharedPreferences([
    SharedPreferences? prefs,
  ]) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await Future.wait([
      resolvedPrefs.remove(_accessTokenKey),
      resolvedPrefs.remove(_refreshTokenKey),
      resolvedPrefs.remove(_userIdKey),
      resolvedPrefs.remove(_roleIdKey),
      resolvedPrefs.remove(_userDataKey),
    ]);
  }

  static String? _normalizedString(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int? _parsePositiveInt(String? value) {
    final normalized = _normalizedString(value);
    if (normalized == null) return null;
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static Map<String, dynamic>? _decodeUserData(String? rawUserData) {
    final normalized = _normalizedString(rawUserData);
    if (normalized == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
