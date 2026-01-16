import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../constants/core/navigation_service.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/api_response.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import '../models/aadhar_card_model.dart';
import '../models/pan_card_model.dart';
import '../models/company_model.dart';
import '../models/banner_model.dart';
import '../models/quick_service_model.dart';
import '../models/amc_plan_model.dart';

/// API Service for handling HTTP requests
class ApiService {
  ApiService._(); // Private constructor for singleton

  static final ApiService instance = ApiService._();

  // ---------------------------
  // Helper: safe JSON decode
  // ---------------------------
  Map<String, dynamic> _safeJsonDecode(String body) {
    final trimmed = body.trimLeft();

    // Detect HTML responses (e.g. when the backend redirects to a login page)
    if (_looksLikeHtml(trimmed)) {
      debugPrint(
        '🔴 HTML response detected instead of JSON. Body preview: '
        '${trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed}',
      );
      return {
        'message': 'Server returned HTML instead of JSON',
        'raw': body,
        'isHtml': true,
      };
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {
        'message': 'Server returned unexpected JSON format',
        'data': decoded,
      };
    } catch (_) {
      return {'message': 'Server returned non-JSON response', 'raw': body};
    }
  }

  // ---------------------------
  // Helper: common headers
  // ---------------------------
  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------------------
  // Helper: token persistence
  // ---------------------------
  Future<void> _persistTokensFromData(
    dynamic data, {
    required int roleId,
  }) async {
    if (data == null) {
      return;
    }

    String? accessToken;
    String? refreshToken;
    int? userId;

    if (data is Map<String, dynamic>) {
      accessToken = _extractStringField(data, const [
        'access_token',
        'token',
        'accessToken',
      ]);
      refreshToken = _extractStringField(data, const [
        'refresh_token',
        'refreshToken',
      ]);

      // Try to capture the authenticated user's id from common shapes:
      // - { user_id: 1, ... }
      // - { id: 1, ... }
      // - { user: { id: 1 } }
      dynamic rawUserId = data['user_id'] ?? data['id'];
      if (rawUserId == null && data['user'] is Map<String, dynamic>) {
        final user = data['user'] as Map<String, dynamic>;
        rawUserId = user['user_id'] ?? user['id'];
      }
      userId = _tryParseInt(rawUserId);
    } else if (data is String) {
      // Some APIs may return the token directly as a string.
      accessToken = data;
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      await SecureStorageService.saveAccessToken(accessToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorageService.saveRefreshToken(refreshToken);
    }

    // Persist role so that refresh-token calls know which role_id to send.
    await SecureStorageService.saveRoleId(roleId);

    // Persist user id when available so dashboard/refresh calls can send it.
    if (userId != null) {
      await SecureStorageService.saveUserId(userId);
    }
  }

  String? _extractStringField(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Login - Send OTP
  Future<ApiResponse> login({
    required int roleId,
    required String phoneNumber,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.login}');
      debugPrint(
        '🔵 Request Body: {"role_id": $roleId, "phone_number": "$phoneNumber"}',
      );

      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: _headers,
            body: jsonEncode({'role_id': roleId, 'phone_number': phoneNumber}),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      // Success
      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'OTP sent',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      // Common "user not found / invalid" status codes
      if (!isHtml &&
          (response.statusCode == 404 || response.statusCode == 422)) {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'User not found',
          errors: jsonResponse['errors'],
        );
      }

      // Other server errors
      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML instead of JSON'
                : 'Server error: ${response.statusCode}'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet / DNS Error: $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      debugPrint('🔴 ClientException: $e');
      return ApiResponse(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Verify OTP
  Future<ApiResponse> verifyOtp({
    required int roleId,
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.verifyOtp}');
      debugPrint(
        '🔵 Request Body: {"role_id": $roleId, "phone_number": "$phoneNumber", "otp": "$otp"}',
      );

      final response = await http
          .post(
            Uri.parse(ApiConstants.verifyOtp),
            headers: _headers,
            body: jsonEncode({
              'role_id': roleId,
              'phone_number': phoneNumber,
              'otp': otp,
            }),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Persist tokens (if present) for this role.
        await _persistTokensFromData(
          jsonResponse['data'] ?? jsonResponse,
          roleId: roleId,
        );
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'OTP verified',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      if (!isHtml &&
          (response.statusCode == 404 || response.statusCode == 422)) {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Invalid OTP / user not found',
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML instead of JSON'
                : 'Server error: ${response.statusCode}'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException catch (e) {
      debugPrint('🔴 No Internet / DNS Error: $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      debugPrint('🔴 ClientException: $e');
      return ApiResponse(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('🔴 Timeout: $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Refresh Token
  Future<ApiResponse> refreshToken({
    required int roleId,
    required int userId,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.refreshToken}');
      debugPrint('🔵 Request Query: {"user_id": $userId, "role_id": $roleId}');

      final currentAccessToken = await SecureStorageService.getAccessToken();
      final headers = Map<String, String>.from(_headers)
        ..addAll({
          if (currentAccessToken != null && currentAccessToken.isNotEmpty)
            'Authorization': 'Bearer $currentAccessToken',
        });

      final uri = Uri.parse(ApiConstants.refreshToken).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await http
          .post(
            uri,
            headers: headers,
            // Keep body for backward compatibility; backend primarily reads query.
            body: jsonEncode({'role_id': roleId}),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Persist any tokens contained in the refresh response.
        await _persistTokensFromData(jsonResponse, roleId: roleId);
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Token refreshed',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML instead of JSON'
                : 'Token refresh failed'),
        errors: jsonResponse['errors'],
      );
    } on HandshakeException catch (e) {
      debugPrint('🔴 SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Signup / Register
  Future<ApiResponse> signup({required Map<String, String> fields}) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.signup}');
      debugPrint('🔵 Request Fields: $fields');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.signup),
      );
      request.fields.addAll(fields);

      final streamedResponse = await request.send().timeout(
        ApiConstants.requestTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Signup successful',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Signup failed'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('🔴 Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Logout
  Future<ApiResponse> logout({required int userId, required int roleId}) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.logout}');
      debugPrint('🔵 Request Query: user_id=$userId&role_id=$roleId');

      final accessToken = await SecureStorageService.getAccessToken();
      final headers = {
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

      final uri = Uri.parse(ApiConstants.logout).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await http
          .post(uri, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Logged out',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Logout failed'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in logout: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Product List API
  // ========================================

  Future<ApiResponse<ProductModel>> getProducts({required int roleId}) async {
    try {
      debugPrint(
        '🔵 API Request: GET ${ApiConstants.productlist}?role_id=$roleId',
      );

      final url = Uri.parse(
        ApiConstants.productlist,
      ).replace(queryParameters: {'role_id': roleId.toString()});

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Based on the example, "products" is at the root.
        // We wrap it for ApiResponse if needed, or handle it here.
        return ApiResponse<ProductModel>(
          success: true,
          message: 'Products fetched successfully',
          data: ProductModel.fromJson(jsonResponse),
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch products'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in getProducts: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Profile API
  // ========================================

  Future<ApiResponse<UserModel>> getProfile({
    required int userId,
    required int roleId,
  }) async {
    try {
      debugPrint(
        '🔵 API Request: GET ${ApiConstants.profile}?user_id=$userId&role_id=$roleId',
      );

      final url = Uri.parse(ApiConstants.profile).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse<UserModel>(
          success: true,
          message: 'Profile fetched successfully',
          data: UserModel.fromJson(jsonResponse),
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch profile'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in getProfile: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse> updateProfile({
    required int userId,
    required int roleId,
    required String firstName,
    required String lastName,
    required String email,
    required String dob,
    required String gender,
  }) async {
    try {
      debugPrint('🔵 API Request: PUT ${ApiConstants.profile}');
      final body = {
        'user_id': userId,
        'role_id': roleId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'dob': dob,
        'gender': gender,
      };
      debugPrint('🔵 Request Body: $body');

      final response = await _performAuthenticatedPut(
        Uri.parse(ApiConstants.profile),
        body: body,
      );

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Profile updated successfully',
          data: jsonResponse['data'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to update profile'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in updateProfile: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Address API
  // ========================================

  Future<ApiResponse<List<AddressModel>>> getAddresses({
    required int userId,
    required int roleId,
  }) async {
    try {
      debugPrint(
        '🔵 API Request: GET ${ApiConstants.addresses}?user_id=$userId&role_id=$roleId',
      );

      final url = Uri.parse(ApiConstants.addresses).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final List<dynamic> addressList = jsonResponse['addresses'] ?? [];
        return ApiResponse<List<AddressModel>>(
          success: true,
          message: 'Addresses fetched successfully',
          data: addressList.map((e) => AddressModel.fromJson(e)).toList(),
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch addresses'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in getAddresses: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<AddressModel>> storeAddress({
    required int userId,
    required int roleId,
    required String branchName,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required bool isPrimary,
  }) async {
    try {
      debugPrint('🔵 API Request: POST ${ApiConstants.address}');

      final url = Uri.parse(ApiConstants.address).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
          'branch_name': branchName,
          'address1': address1,
          'address2': address2,
          'city': city,
          'state': state,
          'country': country,
          'pincode': pincode,
          'is_primary': isPrimary ? 'yes' : 'no',
        },
      );

      // Perform an authenticated POST.
      final response = await _performAuthenticatedPost(url, body: {});

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse<AddressModel>(
          success: true,
          message: jsonResponse['message'] ?? 'Address stored successfully',
          data: AddressModel.fromJson(jsonResponse['address'] ?? jsonResponse),
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to store address'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in storeAddress: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse> updateAddress({
    required int addressId,
    required int userId,
    required int roleId,
    required String branchName,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required bool isPrimary,
  }) async {
    try {
      debugPrint('🔵 API Request: PUT ${ApiConstants.address}/$addressId');

      final url = Uri.parse('${ApiConstants.address}/$addressId').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final body = {
        'branch_name': branchName,
        'address1': address1,
        'address2': address2,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'is_primary': isPrimary ? 'yes' : 'no',
      };

      final response = await _performAuthenticatedPut(url, body: body);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Address updated successfully',
          data: jsonResponse['data'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to update address'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in updateAddress: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Document API
  // ========================================

  Future<ApiResponse<AadharCard>> getAadharDetails({
    required int userId,
    required int roleId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.aadharCard).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<AadharCard>(
          success: true,
          message: 'Aadhar fetched',
          data: AadharCardResponse.fromJson(jsonResponse).aadharCard,
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to fetch Aadhar',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<PanCard>> getPanDetails({
    required int userId,
    required int roleId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.panCard).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<PanCard>(
          success: true,
          message: 'PAN fetched',
          data: PanCardResponse.fromJson(jsonResponse).panCard,
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to fetch PAN',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse> uploadAadhar({
    required int userId,
    required int roleId,
    required String aadharNumber,
    File? frontImage,
    File? backImage,
    int? documentId,
  }) async {
    try {
      Uri url;
      if (documentId != null) {
        url = Uri.parse("${ApiConstants.aadharCard}/$documentId");
      } else {
        url = Uri.parse(ApiConstants.aadharCard);
      }

      final request = http.MultipartRequest('POST', url);
      final token = await SecureStorageService.getAccessToken();

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['user_id'] = userId.toString();
      request.fields['role_id'] = roleId.toString();
      request.fields['aadhar_number'] = aadharNumber;

      if (documentId != null) {
        request.fields['_method'] = 'PUT';
      }

      if (frontImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'aadhar_front_path',
            frontImage.path,
          ),
        );
      }
      if (backImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('aadhar_back_path', backImage.path),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Aadhar saved',
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to save Aadhar',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse> uploadPan({
    required int userId,
    required int roleId,
    required String panNumber,
    File? frontImage,
    File? backImage,
    int? documentId,
  }) async {
    try {
      Uri url;
      if (documentId != null) {
        url = Uri.parse("${ApiConstants.panCard}/$documentId");
      } else {
        url = Uri.parse(ApiConstants.panCard);
      }

      final request = http.MultipartRequest('POST', url);
      final token = await SecureStorageService.getAccessToken();

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['user_id'] = userId.toString();
      request.fields['role_id'] = roleId.toString();
      request.fields['pan_number'] = panNumber;

      if (documentId != null) {
        request.fields['_method'] = 'PUT';
      }

      if (frontImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pan_card_front_path',
            frontImage.path,
          ),
        );
      }
      if (backImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pan_card_back_path',
            backImage.path,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'] ?? 'PAN saved',
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to save PAN',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ========================================
  // Company API
  // ========================================

  Future<ApiResponse<CompanyDetails>> getCompanyDetails({
    required int userId,
    required int roleId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.company).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<CompanyDetails>(
          success: true,
          message: 'Company details fetched',
          data: CompanyDetailsResponse.fromJson(jsonResponse).companyDetails,
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to fetch company details',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse> storeCompanyDetails({
    required int userId,
    required int roleId,
    required String companyName,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String gstNo,
    int? companyId,
  }) async {
    try {
      if (companyId != null) {
        // For Edit: PUT request with params in URL as per Postman screenshot
        final url = Uri.parse("${ApiConstants.company}/$companyId").replace(
          queryParameters: {
            'user_id': userId.toString(),
            'role_id': roleId.toString(),
            'company_name': companyName,
            'comp_address1': address1,
            'comp_address2': address2,
            'comp_city': city,
            'comp_state': state,
            'comp_country': country,
            'comp_pincode': pincode,
            'gst_no': gstNo,
          },
        );

        final response = await _performAuthenticatedPutRequest(url);
        final jsonResponse = _safeJsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return ApiResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Company details updated',
            data: jsonResponse['company_details'],
          );
        }
      } else {
        // For Store: POST request with body
        final url = Uri.parse(ApiConstants.company);
        final body = {
          'user_id': userId,
          'role_id': roleId,
          'company_name': companyName,
          'comp_address1': address1,
          'comp_address2': address2,
          'comp_city': city,
          'comp_state': state,
          'comp_country': country,
          'comp_pincode': pincode,
          'gst_no': gstNo,
        };

        final response = await _performAuthenticatedPost(url, body: body);
        final jsonResponse = _safeJsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return ApiResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Company details saved',
            data: jsonResponse['company_details'],
          );
        }
      }

      return ApiResponse(
        success: false,
        message: 'Failed to save company details',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ========================================
  // Banners API
  // ========================================

  Future<ApiResponse<List<BannerModel>>> getBanners({
    required int roleId,
  }) async {
    try {
      final url = Uri.parse(
        ApiConstants.banners,
      ).replace(queryParameters: {'role_id': roleId.toString()});

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> bannerList = jsonResponse['banners'] ?? [];
        return ApiResponse<List<BannerModel>>(
          success: true,
          message: 'Banners fetched successfully',
          data: bannerList.map((e) => BannerModel.fromJson(e)).toList(),
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to fetch banners',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ========================================
  // Quick Services API
  // ========================================

  Future<ApiResponse<List<QuickService>>> getQuickServices({
    required int roleId,
  }) async {
    try {
      final url = Uri.parse(
        ApiConstants.quickservices,
      ).replace(queryParameters: {'role_id': roleId.toString()});

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> serviceList = jsonResponse['quick_services'] ?? [];
        return ApiResponse<List<QuickService>>(
          success: true,
          message: 'Quick services fetched successfully',
          data: serviceList.map((e) => QuickService.fromJson(e)).toList(),
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to fetch quick services',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ========================================
  // AMC Plans API
  // ========================================

  Future<ApiResponse<List<AmcPlanItem>>> getAmcPlans({
    required int roleId,
  }) async {
    try {
      debugPrint(
        '🔵 API Request: GET ${ApiConstants.amcPlans}?role_id=$roleId',
      );

      final url = Uri.parse(
        ApiConstants.amcPlans,
      ).replace(queryParameters: {'role_id': roleId.toString()});

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final List<dynamic> planList = jsonResponse['amc_plans'] ?? [];
        return ApiResponse<List<AmcPlanItem>>(
          success: true,
          message: 'AMC plans fetched successfully',
          data: planList.map((e) => AmcPlanItem.fromJson(e)).toList(),
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch AMC plans'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } catch (e) {
      debugPrint('❌ Error fetching AMC plans: $e');
      return ApiResponse(success: false, message: 'An error occurred: $e');
    }
  }

  // Get AMC Plan Details by ID
  Future<ApiResponse<AmcPlanDetailResponse>> getAmcPlanDetails({
    required int planId,
    required int roleId,
  }) async {
    try {
      debugPrint(
        '🔵 API Request: GET ${ApiConstants.amcPlanDetails}/$planId?role_id=$roleId',
      );

      final url = Uri.parse(
        '${ApiConstants.amcPlanDetails}/$planId',
      ).replace(queryParameters: {'role_id': roleId.toString()});

      final response = await _performAuthenticatedGet(url);

      debugPrint('🟡 API Response Status: ${response.statusCode}');
      debugPrint('🟡 API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse<AmcPlanDetailResponse>(
          success: true,
          message: 'AMC plan details fetched successfully',
          data: AmcPlanDetailResponse.fromJson(jsonResponse),
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML'
                : 'Failed to fetch AMC plan details'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('🔴 Unexpected Error in getAmcPlanDetails: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Sales Dashboard API Methods
  // ========================================

  static const int _fallbackRoleIdForRefresh = 3; // Salesperson role id
  static const int _maxAuthRetries = 1;

  /// Heuristic check for HTML content (e.g. redirected login page).
  static bool _looksLikeHtml(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    return lower.startsWith('<!doctype html') || lower.startsWith('<html');
  }

  static bool _isUnauthorizedResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return true;
    }

    // Some backends redirect unauthorized requests to an HTML login page
    // while still returning 200. Detect that and treat as unauthorized so we
    // trigger refresh-token/logout instead of trying to parse HTML as JSON.
    if (_looksLikeHtml(response.body)) {
      debugPrint(
        '🔴 HTML login page detected from ${response.request?.url}. '
        'Treating as unauthorized.',
      );
      return true;
    }

    final bodyLower = response.body.toLowerCase();
    return bodyLower.contains('401') ||
        bodyLower.contains('unauthorized') ||
        bodyLower.contains('token not provided');
  }

  static Future<bool> _attemptTokenRefresh() async {
    final storedRoleId = await SecureStorageService.getRoleId();
    final storedUserId = await SecureStorageService.getUserId();
    if (storedUserId == null) {
      debugPrint('🔴 Cannot refresh token: missing stored user_id');
      return false;
    }

    final roleId = storedRoleId ?? _fallbackRoleIdForRefresh;
    final api = ApiService.instance;
    final response = await api.refreshToken(
      roleId: roleId,
      userId: storedUserId,
    );
    return response.success;
  }

  static Future<void> _handleAuthFailure() async {
    await SecureStorageService.clearTokens();
    await NavigationService.navigateToAuthRoot();
  }

  static Future<http.Response> _performAuthenticatedGet(Uri url) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      // Token refreshed successfully, loop will retry with new token.
    }
  }

  static Future<http.Response> _performAuthenticatedPut(
    Uri url, {
    required Map<String, dynamic> body,
  }) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      // Token refreshed successfully, loop will retry with new token.
    }
  }

  static Future<http.Response> _performAuthenticatedPutRequest(Uri url) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .put(url, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
    }
  }

  static Future<http.Response> _performAuthenticatedPost(
    Uri url, {
    required Map<String, dynamic> body,
  }) async {
    int retryCount = 0;
    while (true) {
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        await _handleAuthFailure();
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      // Token refreshed successfully, loop will retry with new token.
    }
  }
}
