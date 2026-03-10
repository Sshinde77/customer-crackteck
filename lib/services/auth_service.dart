import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> loginWithGoogle(
    String accessToken, {
    int? roleId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.googlelogin),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'accessToken': accessToken,
            }),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('API Request: POST ${ApiConstants.googlelogin}');
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

        await SecureStorageService.saveSession(
          accessToken: token,
          refreshToken: refreshToken,
          userId: userId,
          roleId: resolvedRoleId,
          userData: user,
        );

        final session = await SessionManager.getSession();
        if (!session.hasToken) {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'Google login succeeded but token storage failed.',
            data: payload,
          );
        }

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

  Future<void> clearSession() {
    return SessionManager.clearSession();
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
