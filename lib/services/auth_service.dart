import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'session_manager.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final ApiService _apiService = ApiService.instance;

  Future<void> _persistAuthenticatedSession({
    required String? accessToken,
    required String? refreshToken,
    required int? userId,
    required int? roleId,
    Map<String, dynamic>? user,
  }) async {
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      await SecureStorageService.saveToken(accessToken);
    }

    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await SecureStorageService.saveRefreshToken(refreshToken);
    }

    if (userId != null && userId > 0 && roleId != null && roleId > 0) {
      await SecureStorageService.saveUserData(
        userId: userId,
        roleId: roleId,
        userData: user,
      );
    } else if (user != null && user.isNotEmpty) {
      await SecureStorageService.saveSession(userData: user);
    }
  }

  Future<ApiResponse> sendOtp({
    required int roleId,
    required String phoneNumber,
  }) {
    return _apiService.login(roleId: roleId, phoneNumber: phoneNumber);
  }

  Future<ApiResponse> verifyOtp({
    required int roleId,
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _apiService.verifyOtp(
      roleId: roleId,
      phoneNumber: phoneNumber,
      otp: otp,
    );

    if (!response.success) {
      return response;
    }

    final session = await SessionManager.getSession();
    if (!session.isAuthenticated) {
      return ApiResponse(
        success: false,
        message: 'Login succeeded but session setup failed. Please try again.',
      );
    }

    await syncLoggedInDeviceToken();

    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle(
    String accessToken, {
    int? roleId,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'accessToken': accessToken,
        if (roleId != null) 'role_id': roleId,
      };

      final response = await http
          .post(
            Uri.parse(ApiConstants.googlelogin),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('API Request: POST ${ApiConstants.googlelogin}');
      debugPrint('API Request Body: ${jsonEncode(requestBody)}');
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final Map<String, dynamic> jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final bool success = _readBool(
              jsonResponse['success'],
            ) ??
            _readBool(jsonResponse['status']) ??
            false;
        if (!success) {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: _messageFromResponse(
              jsonResponse,
              fallback: 'Google login failed',
            ),
            data: _extractPayload(jsonResponse),
            errors: jsonResponse['errors'],
          );
        }

        final payload = _extractPayload(jsonResponse);
        final user = _extractUserMap(jsonResponse);
        final token = _extractToken(jsonResponse);
        final refreshToken = _extractRefreshToken(jsonResponse);
        final userId = _extractUserId(jsonResponse);
        final resolvedRoleId = _extractRoleId(jsonResponse) ?? roleId;

        await _persistAuthenticatedSession(
          accessToken: token,
          refreshToken: refreshToken,
          userId: userId,
          roleId: resolvedRoleId,
          user: user,
        );

        final session = await SessionManager.getSession();
        if (!session.hasToken) {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'Google login succeeded but token storage failed.',
            data: payload,
          );
        }

        await syncLoggedInDeviceToken();

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: _messageFromResponse(
            jsonResponse,
            fallback: 'Google login successful',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _messageFromResponse(
          jsonResponse,
          fallback: isHtml
              ? 'Server returned HTML instead of JSON'
              : 'Failed to login with Google',
        ),
        data: _extractPayload(jsonResponse),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error in loginWithGoogle: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> loginWithEmailPassword({
    required String email,
    required String password,
    required int roleId,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'role_id': roleId,
      };

      final response = await http
          .post(
            Uri.parse(ApiConstants.emailPasswordLogin),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('API Request: POST ${ApiConstants.emailPasswordLogin}');
      debugPrint('API Request Body: ${jsonEncode(requestBody)}');
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final Map<String, dynamic> jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final bool success = _readBool(
              jsonResponse['success'],
            ) ??
            _readBool(jsonResponse['status']) ??
            true;

        if (!success) {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: _messageFromResponse(
              jsonResponse,
              fallback: 'Email login failed',
            ),
            data: _extractPayload(jsonResponse),
            errors: jsonResponse['errors'],
          );
        }

        final payload = _extractPayload(jsonResponse);
        final user = _extractUserMap(jsonResponse);
        final token = _extractToken(jsonResponse);
        final refreshToken = _extractRefreshToken(jsonResponse);
        final userId = _extractUserId(jsonResponse);
        final resolvedRoleId = _extractRoleId(jsonResponse) ?? roleId;

        await _persistAuthenticatedSession(
          accessToken: token,
          refreshToken: refreshToken,
          userId: userId,
          roleId: resolvedRoleId,
          user: user,
        );

        final session = await SessionManager.getSession();
        if (!session.isAuthenticated) {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'Login succeeded but session setup failed. Please try again.',
            data: payload,
          );
        }

        await syncLoggedInDeviceToken();

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: _messageFromResponse(
            jsonResponse,
            fallback: 'Login successful',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _messageFromResponse(
          jsonResponse,
          fallback: isHtml
              ? 'Server returned HTML instead of JSON'
              : 'Failed to login with email and password',
        ),
        data: _extractPayload(jsonResponse),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error in loginWithEmailPassword: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> sendForgotPasswordCode({
    required String email,
    required int roleId,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConstants.forgotPasswordSendCode,
      ).replace(
        queryParameters: <String, String>{
          'email': email.trim(),
          'role_id': roleId.toString(),
        },
      );

      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('API Request: POST $uri');
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final bool success = _readBool(jsonResponse['success']) ??
          _readBool(jsonResponse['status']) ??
          (response.statusCode == 200 || response.statusCode == 201);

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          success) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: _messageFromResponse(
            jsonResponse,
            fallback: 'Verification code sent successfully',
          ),
          data: _extractPayload(jsonResponse),
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _messageFromResponse(
          jsonResponse,
          fallback: isHtml
              ? 'Server returned HTML instead of JSON'
              : 'Failed to send verification code',
        ),
        data: _extractPayload(jsonResponse),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error in sendForgotPasswordCode: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyForgotPasswordCode({
    required String email,
    required int roleId,
    required String code,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConstants.forgotPasswordVerifyCode,
      ).replace(
        queryParameters: <String, String>{
          'email': email.trim(),
          'role_id': roleId.toString(),
          'code': code.trim(),
        },
      );

      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('API Request: POST $uri');
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final bool success = _readBool(jsonResponse['success']) ??
          _readBool(jsonResponse['status']) ??
          (response.statusCode == 200 || response.statusCode == 201);

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          success) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: _messageFromResponse(
            jsonResponse,
            fallback: 'Verification code verified successfully',
          ),
          data: _extractPayload(jsonResponse),
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _messageFromResponse(
          jsonResponse,
          fallback: isHtml
              ? 'Server returned HTML instead of JSON'
              : 'Failed to verify code',
        ),
        data: _extractPayload(jsonResponse),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error in verifyForgotPasswordCode: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> resetForgotPassword({
    required String email,
    required int roleId,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConstants.forgotPasswordReset,
      ).replace(
        queryParameters: <String, String>{
          'email': email.trim(),
          'role_id': roleId.toString(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('API Request: POST $uri');
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;
      final bool success = _readBool(jsonResponse['success']) ??
          _readBool(jsonResponse['status']) ??
          (response.statusCode == 200 || response.statusCode == 201);

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          success) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: _messageFromResponse(
            jsonResponse,
            fallback: 'Password reset successfully',
          ),
          data: _extractPayload(jsonResponse),
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _messageFromResponse(
          jsonResponse,
          fallback: isHtml
              ? 'Server returned HTML instead of JSON'
              : 'Failed to reset password',
        ),
        data: _extractPayload(jsonResponse),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error in resetForgotPassword: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<void> clearSession() {
    return SessionManager.clearSession();
  }

  Future<void> syncLoggedInDeviceToken() async {
    try {
      final session = await SessionManager.getSession();
      if (!session.isAuthenticated) {
        debugPrint('Skipping device token sync: session is incomplete.');
        return;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      final trimmedToken = fcmToken?.trim() ?? '';
      if (trimmedToken.isEmpty) {
        debugPrint('Skipping device token sync: FCM token is unavailable.');
        return;
      }

      final response = await _apiService.registerDeviceToken(
        userId: session.userId,
        roleId: session.roleId,
        fcmToken: trimmedToken,
        deviceType: _resolveDeviceType(),
        deviceId: trimmedToken,
      );

      debugPrint(
        'Device token sync result: success=${response.success}, message=${response.message}',
      );
    } catch (e) {
      debugPrint('Unexpected error while syncing device token: $e');
    }
  }

  String _resolveDeviceType() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return <String, dynamic>{'raw': decoded};
    } catch (_) {
      final trimmed = body.trimLeft();
      return <String, dynamic>{
        'message': trimmed.startsWith('<')
            ? 'Server returned HTML instead of JSON'
            : 'Unable to parse server response',
        'isHtml': trimmed.startsWith('<'),
      };
    }
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> response) {
    final dynamic data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return response;
  }

  Map<String, dynamic>? _extractUserMap(Map<String, dynamic> response) {
    final payload = _extractPayload(response);
    final dynamic user = payload['user'] ?? response['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }
    return null;
  }

  String? _extractToken(Map<String, dynamic> response) {
    final payload = _extractPayload(response);
    return _readString(
      payload['token'] ??
          payload['access_token'] ??
          payload['accessToken'] ??
          response['token'] ??
          response['access_token'] ??
          response['accessToken'],
    );
  }

  String? _extractRefreshToken(Map<String, dynamic> response) {
    final payload = _extractPayload(response);
    return _readString(
      payload['refresh_token'] ??
          payload['refreshToken'] ??
          response['refresh_token'] ??
          response['refreshToken'],
    );
  }

  int? _extractUserId(Map<String, dynamic> response) {
    final payload = _extractPayload(response);
    final user = _extractUserMap(response);
    return _readInt(
      payload['user_id'] ??
          payload['id'] ??
          response['user_id'] ??
          response['id'] ??
          user?['user_id'] ??
          user?['id'],
    );
  }

  int? _extractRoleId(Map<String, dynamic> response) {
    final payload = _extractPayload(response);
    final user = _extractUserMap(response);
    return _readInt(
      payload['role_id'] ??
          payload['roleId'] ??
          response['role_id'] ??
          response['roleId'] ??
          user?['role_id'] ??
          user?['roleId'],
    );
  }

  String _messageFromResponse(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = response['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return fallback;
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _readBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}
