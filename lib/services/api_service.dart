import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../constants/core/navigation_service.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/amc_plan_model.dart';
import '../models/api_response.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/address_model.dart';
import '../models/aadhar_card_model.dart';
import '../models/pan_card_model.dart';
import '../models/company_model.dart';
import '../models/banner_model.dart';
import '../models/quick_service_model.dart';
import '../models/product_category_model.dart';
import '../models/order_model.dart';
import '../models/reward_coupon_model.dart';
import '../models/service_request_list_model.dart';

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
        'ðŸ”´ HTML response detected instead of JSON. Body preview: '
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

  Future<Map<String, String>> _authenticatedMultipartHeaders() async {
    final token = await SecureStorageService.getAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _resolvedAuthFields({
    int? userId,
    int? roleId,
  }) async {
    final storedUserId = await SecureStorageService.getUserId();
    final storedRoleId = await SecureStorageService.getRoleId();
    final resolvedUserId = userId ?? storedUserId;
    final resolvedRoleId = roleId ?? storedRoleId;

    final fields = <String, String>{};
    if (resolvedUserId != null && resolvedUserId > 0) {
      fields['user_id'] = resolvedUserId.toString();
    }
    if (resolvedRoleId != null && resolvedRoleId > 0) {
      fields['role_id'] = resolvedRoleId.toString();
    }
    return fields;
  }

  // ---------------------------
  // Helper: token persistence
  // ---------------------------
  Future<void> _persistTokensFromData(
    dynamic data, {
    required int roleId,
  }) async {
    String? accessToken;
    String? refreshToken;
    int? userId;

    if (data is Map<String, dynamic>) {
      final sources = _flattenCandidateMaps(data);

      accessToken = _extractStringFieldFromMaps(sources, const [
        'access_token',
        'token',
        'accessToken',
        'jwt',
        'jwt_token',
      ]);
      refreshToken = _extractStringFieldFromMaps(sources, const [
        'refresh_token',
        'refreshToken',
      ]);

      userId = _extractIntFieldFromMaps(sources, const ['user_id', 'id']);

      if (userId == null) {
        for (final source in sources) {
          if (source['user'] is Map<String, dynamic>) {
            final user = source['user'] as Map<String, dynamic>;
            userId = _tryParseInt(user['user_id'] ?? user['id']);
            if (userId != null) {
              break;
            }
          }
        }
      }
    } else if (data is String) {
      // Some APIs may return the token directly as a string.
      accessToken = data;
    }

    // Persist any available auth payload in one write flow.
    await SecureStorageService.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      roleId: roleId,
    );
  }

  List<Map<String, dynamic>> _flattenCandidateMaps(
    Map<String, dynamic> source,
  ) {
    final result = <Map<String, dynamic>>[source];
    final queue = <Map<String, dynamic>>[source];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final key in const ['data', 'result', 'payload']) {
        final nested = current[key];
        if (nested is Map<String, dynamic> && !result.contains(nested)) {
          result.add(nested);
          queue.add(nested);
        }
      }
    }
    return result;
  }

  String? _extractStringFieldFromMaps(
    Iterable<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      for (final key in keys) {
        final value = source[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  int? _extractIntFieldFromMaps(
    Iterable<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      for (final key in keys) {
        final parsed = _tryParseInt(source[key]);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static int? _tryParseInt(dynamic value) {
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
      debugPrint('ðŸ”µ API Request: POST ${ApiConstants.login}');
      debugPrint(
        'ðŸ”µ Request Body: {"role_id": $roleId, "phone_number": "$phoneNumber"}',
      );

      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: _headers,
            body: jsonEncode({'role_id': roleId, 'phone_number': phoneNumber}),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException catch (e) {
      debugPrint('ðŸ”´ No Internet / DNS Error: $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      debugPrint('ðŸ”´ ClientException: $e');
      return ApiResponse(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('ðŸ”´ Timeout: $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error: $e');
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
      debugPrint('ðŸ”µ API Request: POST ${ApiConstants.verifyOtp}');
      debugPrint(
        'ðŸ”µ Request Body: {"role_id": $roleId, "phone_number": "$phoneNumber", "otp": "$otp"}',
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

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Persist tokens and user context (if present) for this role.
        await _persistTokensFromData(jsonResponse, roleId: roleId);
        final responseData = jsonResponse['data'] ?? jsonResponse;
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'OTP verified',
          data: responseData,
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
      debugPrint('ðŸ”´ SSL Handshake Error: $e');
      return ApiResponse(success: false, message: 'SSL error: ${e.message}');
    } on SocketException catch (e) {
      debugPrint('ðŸ”´ No Internet / DNS Error: $e');
      return ApiResponse(
        success: false,
        message: 'No internet connection. Please check your network.',
      );
    } on http.ClientException catch (e) {
      debugPrint('ðŸ”´ ClientException: $e');
      return ApiResponse(
        success: false,
        message: 'Request failed: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('ðŸ”´ Timeout: $e');
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Refresh Token
  Future<ApiResponse> refreshToken({
    required int roleId,
    required int userId,
  }) async {
    try {
      debugPrint('ðŸ”µ API Request: POST ${ApiConstants.refreshToken}');
      debugPrint(
        'ðŸ”µ Request Query: {"user_id": $userId, "role_id": $roleId}',
      );

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

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ SSL Handshake Error: $e');
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
      debugPrint('ðŸ”´ Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Signup / Register
  Future<ApiResponse> signup({required Map<String, String> fields}) async {
    try {
      debugPrint('ðŸ”µ API Request: POST ${ApiConstants.signup}');
      debugPrint('ðŸ”µ Request Fields: $fields');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.signup),
      );
      request.headers.addAll({'Accept': 'application/json'});
      request.fields.addAll(fields);

      final streamedResponse = await request.send().timeout(
        ApiConstants.requestTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ Unexpected Error: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Logout
  Future<ApiResponse> logout({int? userId, int? roleId}) async {
    try {
      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }
      debugPrint('ðŸ”µ API Request: POST ${ApiConstants.logout}');
      debugPrint(
        'Request Query: user_id=${authFields['user_id']}&role_id=${authFields['role_id']}',
      );

      final uri = Uri.parse(ApiConstants.logout).replace(
        queryParameters: {
          'user_id': authFields['user_id']!,
          'role_id': authFields['role_id']!,
        },
      );

      final response = await _performAuthenticatedPost(uri, body: {});

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ Unexpected Error in logout: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Register or update the logged-in user's FCM device token.
  Future<ApiResponse> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
    int? userId,
    int? roleId,
  }) async {
    try {
      final trimmedToken = fcmToken.trim();
      final trimmedDeviceType = deviceType.trim();
      final trimmedDeviceId = deviceId.trim();
      if (trimmedToken.isEmpty ||
          trimmedDeviceType.isEmpty ||
          trimmedDeviceId.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Missing device token payload.',
        );
      }

      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      final uri = Uri.parse(ApiConstants.deviceToken).replace(
        queryParameters: {
          'user_id': authFields['user_id']!,
          'role_id': authFields['role_id']!,
          'fcm_token': trimmedToken,
          'device_type': trimmedDeviceType,
          'device_id': trimmedDeviceId,
        },
      );

      debugPrint('API Request: POST $uri');

      final response = await _performAuthenticatedPost(uri, body: {});

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Device token updated',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Device token update failed'),
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
      debugPrint('Unexpected Error in registerDeviceToken: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Product List API
  // ========================================

  Future<ApiResponse<ProductModel>> getProducts({int? roleId}) async {
    try {
      debugPrint(
        'ðŸ”µ API Request: GET ${ApiConstants.productlist}?role_id=$roleId',
      );

      final query = <String, String>{};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final url = query.isEmpty
          ? Uri.parse(ApiConstants.productlist)
          : Uri.parse(ApiConstants.productlist).replace(queryParameters: query);

      final response = await _performAuthenticatedGet(url);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final Map<String, dynamic> payload =
            jsonResponse['data'] is Map<String, dynamic>
            ? jsonResponse['data'] as Map<String, dynamic>
            : jsonResponse;
        return ApiResponse<ProductModel>(
          success: true,
          message: 'Products fetched successfully',
          data: ProductModel.fromJson(payload),
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
      debugPrint('ðŸ”´ Unexpected Error in getProducts: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Single Product API
  // ========================================

  Future<ApiResponse<ProductData>> getProductDetail({
    required int productId,
    int? roleId,
  }) async {
    try {
      final query = <String, String>{};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final url = query.isEmpty
          ? Uri.parse('${ApiConstants.productdetail}/$productId')
          : Uri.parse(
              '${ApiConstants.productdetail}/$productId',
            ).replace(queryParameters: query);

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final Map<String, dynamic> payload =
            jsonResponse['data'] is Map<String, dynamic>
            ? jsonResponse['data'] as Map<String, dynamic>
            : jsonResponse;

        // API can return {"product": {...}} (and sometimes wrapped in {"data": {...}}).
        final Map<String, dynamic> productJson =
            payload['product'] is Map<String, dynamic>
            ? payload['product'] as Map<String, dynamic>
            : payload;

        return ApiResponse<ProductData>(
          success: true,
          message: 'Product fetched successfully',
          data: ProductData.fromJson(productJson),
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch product'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error in getProductDetail: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Buy Product API
  // ========================================

  Future<ApiResponse> buyProduct({
    required int productId,
    required int roleId,
    required int quantity,
    required int customerId,
    required int shippingAddressId,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.product_buy}/$productId').replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'quantity': quantity.toString(),
          'user_id': customerId.toString(),
          'shipping_address_id': shippingAddressId.toString(),
        },
      );

      debugPrint('ðŸ”µ API Request: POST $url');

      final response = await _performAuthenticatedPost(
        url,
        body: {'shipping_address_id': shippingAddressId},
      );

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Product purchased successfully',
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to buy product'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error in buyProduct: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Service Request List API
  // ========================================

  Future<ApiResponse<List<ServiceRequestListItem>>> getAllServiceRequests({
    required int roleId,
    required int customerId,
  }) async {
    try {
      debugPrint(
        'Ã°Å¸â€Âµ API Request: GET ${ApiConstants.service_request_list}?role_id=$roleId&user_id=$customerId',
      );

      final url = Uri.parse(ApiConstants.service_request_list).replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': customerId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);

      debugPrint('Ã°Å¸Å¸Â¡ API Response Status: ${response.statusCode}');
      debugPrint('Ã°Å¸Å¸Â¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : jsonResponse;

        dynamic listNode =
            payload['service_requests'] ??
            payload['serviceRequests'] ??
            payload['requests'] ??
            payload['service_request'] ??
            payload['all_service_requests'] ??
            payload['allServiceRequests'];

        if (listNode == null && payload['data'] is List) {
          listNode = payload['data'];
        }
        if (listNode == null && dataRoot is List) {
          listNode = dataRoot;
        }

        final items = listNode is List
            ? listNode
                  .whereType<Map>()
                  .map(
                    (e) => ServiceRequestListItem.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
            : <ServiceRequestListItem>[];

        return ApiResponse<List<ServiceRequestListItem>>(
          success: jsonResponse['success'] ?? true,
          message:
              jsonResponse['message'] ??
              'Service requests fetched successfully',
          data: items,
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML'
                : 'Failed to fetch service requests'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Ã°Å¸â€Â´ Unexpected Error in getAllServiceRequests: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Quotation List API
  // ========================================

  Future<ApiResponse<List<Map<String, dynamic>>>> getQuotationList({
    required int roleId,
    required int customerId,
  }) async {
    try {
      debugPrint(
        'API Request: GET ${ApiConstants.quotation_list}?role_id=$roleId&user_id=$customerId',
      );

      final url = Uri.parse(ApiConstants.quotation_list).replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': customerId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : jsonResponse;

        dynamic listNode =
            payload['quotations'] ??
            payload['quotation_list'] ??
            payload['service_request_quotations'] ??
            payload['serviceRequestQuotations'] ??
            payload['quote_list'] ??
            payload['quotes'] ??
            payload['items'];

        if (listNode == null && payload['data'] is List) {
          listNode = payload['data'];
        }
        if (listNode == null && dataRoot is List) {
          listNode = dataRoot;
        }

        final items = listNode is List
            ? listNode
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : <Map<String, dynamic>>[];

        return ApiResponse<List<Map<String, dynamic>>>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Quotations fetched successfully',
          data: items,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch quotations'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getQuotationList: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getInvoiceList({
    required int roleId,
    required int userId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.invoice_list).replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': userId.toString(),
        },
      );

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : jsonResponse;

        dynamic listNode =
            payload['invoices'] ??
            payload['invoice_list'] ??
            payload['quotation_invoices'] ??
            payload['quotationInvoices'] ??
            payload['items'];

        if (listNode == null && payload['data'] is List) {
          listNode = payload['data'];
        }
        if (listNode == null && dataRoot is List) {
          listNode = dataRoot;
        }

        final items = listNode is List
            ? listNode
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : <Map<String, dynamic>>[];

        return ApiResponse<List<Map<String, dynamic>>>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Invoices fetched successfully',
          data: items,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch invoices'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getInvoiceList: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getInvoiceDetail({
    required int quoteId,
    required int roleId,
    required int userId,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveInvoiceEndpoint(ApiConstants.invoice_detail, quoteId),
          ).replace(
            queryParameters: {
              'role_id': roleId.toString(),
              'user_id': userId.toString(),
            },
          );

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (isHtml) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Server returned HTML',
          errors: jsonResponse['errors'],
        );
      }

      final dynamic dataRoot = jsonResponse['data'];
      final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
          ? dataRoot
          : dataRoot is Map
          ? Map<String, dynamic>.from(dataRoot)
          : jsonResponse;

      dynamic detailNode =
          payload['invoice'] ??
          payload['invoice_detail'] ??
          payload['invoice_details'] ??
          payload['quotation_invoice'] ??
          payload['quotationInvoice'] ??
          payload['service_request_invoice'] ??
          payload['serviceRequestInvoice'] ??
          payload['data'];

      Map<String, dynamic>? detail;

      if (detailNode is Map<String, dynamic>) {
        detail = Map<String, dynamic>.from(detailNode);
      } else if (detailNode is Map) {
        detail = Map<String, dynamic>.from(detailNode);
      } else if (detailNode is List &&
          detailNode.isNotEmpty &&
          detailNode.first is Map) {
        detail = Map<String, dynamic>.from(detailNode.first as Map);
      }

      final bool payloadLooksLikeInvoice =
          payload.containsKey('invoice_number') ||
          payload.containsKey('invoice_date') ||
          payload.containsKey('grand_total') ||
          payload.containsKey('quote_id');

      if (detail == null && payloadLooksLikeInvoice) {
        detail = payload;
      }

      if (detail != null) {
        if (!detail.containsKey('items')) {
          final dynamic itemsNode =
              payload['items'] ??
              payload['invoice_items'] ??
              payload['products'] ??
              payload['quotation_products'];
          if (itemsNode is List) {
            detail['items'] = itemsNode;
          }
        }

        if (!detail.containsKey('quote_details') &&
            payload['quote_details'] is Map) {
          detail['quote_details'] = payload['quote_details'];
        }

        if (!detail.containsKey('lead_details') &&
            payload['lead_details'] is Map) {
          final dynamic quoteDetails = detail['quote_details'];
          if (quoteDetails is Map) {
            quoteDetails['lead_details'] = payload['lead_details'];
            detail['quote_details'] = quoteDetails;
          } else {
            detail['quote_details'] = {'lead_details': payload['lead_details']};
          }
        }

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: jsonResponse['message']?.toString() ?? 'Invoice loaded',
          data: detail,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            jsonResponse['message']?.toString() ??
            'Failed to fetch invoice details',
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getInvoiceDetail: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> approveInvoice({
    required int invoiceId,
    required int roleId,
    required int userId,
  }) async {
    return _submitInvoiceAction(
      endpointTemplate: ApiConstants.invoice_accept,
      invoiceId: invoiceId,
      roleId: roleId,
      userId: userId,
      actionLabel: 'approve',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> rejectInvoice({
    required int invoiceId,
    required int roleId,
    required int userId,
  }) async {
    return _submitInvoiceAction(
      endpointTemplate: ApiConstants.invoice_reject,
      invoiceId: invoiceId,
      roleId: roleId,
      userId: userId,
      actionLabel: 'reject',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> payInvoice({
    required int invoiceId,
    required int roleId,
    required int userId,
    required double amount,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveInvoiceEndpoint(ApiConstants.invoice_payment, invoiceId),
          ).replace(
            queryParameters: {
              'user_id': userId.toString(),
              'role_id': roleId.toString(),
              'amount': _formatAmountForQuery(amount),
            },
          );

      debugPrint('API Request: POST $url');

      final response = await _performAuthenticatedPost(url, body: {});

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : dataRoot is Map
            ? Map<String, dynamic>.from(dataRoot)
            : <String, dynamic>{};

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message: _stringifyMessage(
            jsonResponse['message'],
            fallback: 'Invoice payment submitted successfully',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _stringifyMessage(
          jsonResponse['message'],
          fallback: isHtml
              ? 'Server returned HTML'
              : 'Failed to submit invoice payment',
        ),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in payInvoice: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> _submitInvoiceAction({
    required String endpointTemplate,
    required int invoiceId,
    required int roleId,
    required int userId,
    required String actionLabel,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveInvoiceEndpoint(endpointTemplate, invoiceId),
          ).replace(
            queryParameters: {
              'user_id': userId.toString(),
              'role_id': roleId.toString(),
            },
          );

      debugPrint('API Request: POST $url');

      final response = await _performAuthenticatedPost(url, body: {});

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : dataRoot is Map
            ? Map<String, dynamic>.from(dataRoot)
            : <String, dynamic>{};

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message: _stringifyMessage(
            jsonResponse['message'],
            fallback:
                'Invoice ${actionLabel == 'approve' ? 'approved' : 'rejected'} successfully',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _stringifyMessage(
          jsonResponse['message'],
          fallback: isHtml
              ? 'Server returned HTML'
              : 'Failed to $actionLabel invoice',
        ),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in ${actionLabel}Invoice: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getQuotationDetail({
    required int quotationId,
    required int roleId,
    required int userId,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.quotation_detail}/$quotationId')
          .replace(
            queryParameters: {
              'role_id': roleId.toString(),
              'user_id': userId.toString(),
            },
          );

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (isHtml) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Server returned HTML',
          errors: jsonResponse['errors'],
        );
      }

      final dynamic dataRoot = jsonResponse['data'];
      final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
          ? dataRoot
          : jsonResponse;

      dynamic detailNode =
          payload['quotation'] ??
          payload['quotation_detail'] ??
          payload['quotation_details'] ??
          payload['service_request_quotation'] ??
          payload['serviceRequestQuotation'] ??
          payload['quote'] ??
          payload['message'] ??
          payload['data'];

      Map<String, dynamic>? detail;

      if (detailNode is Map<String, dynamic>) {
        detail = Map<String, dynamic>.from(detailNode);
      } else if (detailNode is Map) {
        detail = Map<String, dynamic>.from(detailNode);
      } else if (detailNode is List &&
          detailNode.isNotEmpty &&
          detailNode.first is Map) {
        detail = Map<String, dynamic>.from(detailNode.first as Map);
      }

      final bool payloadLooksLikeDetail =
          payload.containsKey('quote_number') ||
          payload.containsKey('quote_date') ||
          payload.containsKey('expiry_date');

      if (detail == null && payloadLooksLikeDetail) {
        detail = payload;
      }

      if (detail != null) {
        if (!detail.containsKey('products') && payload['products'] is List) {
          detail['products'] = payload['products'];
        }
        if (!detail.containsKey('lead_details') &&
            payload['lead_details'] is Map) {
          detail['lead_details'] = payload['lead_details'];
        }
        if (!detail.containsKey('amc_data') && payload['amc_data'] is Map) {
          detail['amc_data'] = payload['amc_data'];
        }

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: jsonResponse['message']?.toString() ?? 'Quotation loaded',
          data: detail,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            jsonResponse['message']?.toString() ??
            'Failed to fetch quotation details',
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getQuotationDetail: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> acceptQuotation({
    required int quotationId,
    required int roleId,
    required int userId,
  }) async {
    return _submitQuotationAction(
      endpointTemplate: ApiConstants.quotation_accept,
      quotationId: quotationId,
      roleId: roleId,
      userId: userId,
      actionLabel: 'accept',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> rejectQuotation({
    required int quotationId,
    required int roleId,
    required int userId,
  }) async {
    return _submitQuotationAction(
      endpointTemplate: ApiConstants.quotation_reject,
      quotationId: quotationId,
      roleId: roleId,
      userId: userId,
      actionLabel: 'reject',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> _submitQuotationAction({
    required String endpointTemplate,
    required int quotationId,
    required int roleId,
    required int userId,
    required String actionLabel,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveQuotationActionEndpoint(endpointTemplate, quotationId),
          ).replace(
            queryParameters: {
              'user_id': userId.toString(),
              'role_id': roleId.toString(),
            },
          );

      debugPrint('API Request: POST $url');

      final response = await _performAuthenticatedPost(url, body: {});

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : dataRoot is Map
            ? Map<String, dynamic>.from(dataRoot)
            : <String, dynamic>{};

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message: _stringifyMessage(
            jsonResponse['message'],
            fallback:
                'Quotation ${actionLabel == 'accept' ? 'accepted' : 'rejected'} successfully',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _stringifyMessage(
          jsonResponse['message'],
          fallback: isHtml
              ? 'Server returned HTML'
              : 'Failed to $actionLabel quotation',
        ),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in ${actionLabel}Quotation: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  String _resolveQuotationActionEndpoint(String template, int quotationId) {
    if (template.contains('{id}')) {
      final bool hasSlashBeforePlaceholder = template.contains('/{id}');
      return template.replaceAll(
        '{id}',
        hasSlashBeforePlaceholder ? quotationId.toString() : '/$quotationId',
      );
    }
    return '$template/$quotationId';
  }

  String _resolveInvoiceEndpoint(String template, int id) {
    if (template.contains('{quote_id}')) {
      final bool hasSlashBeforePlaceholder = template.contains('/{quote_id}');
      return template.replaceAll(
        '{quote_id}',
        hasSlashBeforePlaceholder ? id.toString() : '/$id',
      );
    }
    if (template.contains('{id}')) {
      final bool hasSlashBeforePlaceholder = template.contains('/{id}');
      return template.replaceAll(
        '{id}',
        hasSlashBeforePlaceholder ? id.toString() : '/$id',
      );
    }
    return '$template/$id';
  }

  String _formatAmountForQuery(num amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _stringifyMessage(dynamic message, {required String fallback}) {
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    if (message is Map) {
      final dynamic nested = message['message'] ?? message['error'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
      return fallback;
    }
    return fallback;
  }

  // ========================================
  // Service Request Detail API
  // ========================================

  Future<ApiResponse<Map<String, dynamic>>> getServiceRequestDetails({
    required int requestId,
    required int roleId,
    required int customerId,
  }) async {
    try {
      final url =
          Uri.parse(
            '${ApiConstants.service_request_details}/$requestId',
          ).replace(
            queryParameters: {
              'role_id': roleId.toString(),
              'user_id': customerId.toString(),
            },
          );

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : jsonResponse;

        final dynamic detailNode =
            payload['service_request'] ??
            payload['serviceRequest'] ??
            payload['request'] ??
            payload['details'] ??
            payload['service_details'] ??
            payload['serviceDetail'] ??
            payload['service'];

        final Map<String, dynamic> details = detailNode is Map<String, dynamic>
            ? detailNode
            : detailNode is Map
            ? Map<String, dynamic>.from(detailNode)
            : payload;

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message:
              jsonResponse['message'] ??
              'Service request details fetched successfully',
          data: details,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML'
                : 'Failed to fetch service request details'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getServiceRequestDetails: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>>
  getServiceRequestProductDiagnostics({
    required int requestId,
    required int serviceProductId,
    required int roleId,
    required int customerId,
  }) async {
    try {
      final url =
          Uri.parse(
            '${ApiConstants.service_request_product_diagnostics}/$requestId/$serviceProductId',
          ).replace(
            queryParameters: {
              'role_id': roleId.toString(),
              'user_id': customerId.toString(),
            },
          );

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        Map<String, dynamic> payload;

        if (dataRoot is Map<String, dynamic>) {
          payload = Map<String, dynamic>.from(dataRoot);
        } else if (dataRoot is Map) {
          payload = Map<String, dynamic>.from(dataRoot);
        } else if (dataRoot is List) {
          payload = <String, dynamic>{'diagnoses': dataRoot};
        } else {
          payload = Map<String, dynamic>.from(jsonResponse);
        }

        final dynamic normalizedDiagnoses =
            payload['diagnoses'] ??
            payload['diagnosis_list'] ??
            payload['diagnostics'] ??
            payload['product_diagnostics'];

        payload['diagnoses'] = normalizedDiagnoses is List
            ? normalizedDiagnoses
            : <dynamic>[];

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message:
              jsonResponse['message'] ??
              'Product diagnostics fetched successfully',
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML'
                : 'Failed to fetch product diagnostics'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getServiceRequestProductDiagnostics: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> submitServiceRequestPartApproval({
    required int requestId,
    required int roleId,
    required int customerId,
    required String action,
    int? partId,
    required int productId,
  }) async {
    try {
      final queryParameters = <String, String>{
        'role_id': roleId.toString(),
        'user_id': customerId.toString(),
        'service_request_id': requestId.toString(),
        'product_id': productId.toString(),
        'action': action,
      };

      if (partId != null) {
        queryParameters['part_id'] = partId.toString();
      }

      final body = <String, dynamic>{
        'role_id': roleId,
        'user_id': customerId,
        'service_request_id': requestId,
        'product_id': productId,
        'action': action,
      };

      if (partId != null) {
        body['part_id'] = partId;
      }

      final url = Uri.parse(
        ApiConstants.service_request_approval,
      ).replace(queryParameters: queryParameters);

      debugPrint('API Request: POST $url');
      debugPrint('API Request Body: $body');

      final response = await _performAuthenticatedPost(url, body: body);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic data = jsonResponse['data'];
        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message:
              jsonResponse['message'] ?? 'Part status updated successfully',
          data: data is Map<String, dynamic>
              ? data
              : (data is Map
                    ? Map<String, dynamic>.from(data)
                    : <String, dynamic>{}),
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to update part status'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in submitServiceRequestPartApproval: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> applyPartCoupon({
    required int roleId,
    required int customerId,
    required String couponCode,
  }) async {
    try {
      final queryParameters = <String, String>{
        'role_id': roleId.toString(),
        'user_id': customerId.toString(),
        'coupon_code': couponCode,
      };

      final url = Uri.parse(
        ApiConstants.couponapply,
      ).replace(queryParameters: queryParameters);

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic data = jsonResponse['data'] ?? jsonResponse;
        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Coupon applied successfully',
          data: data is Map<String, dynamic>
              ? data
              : (data is Map
                    ? Map<String, dynamic>.from(data)
                    : <String, dynamic>{}),
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to apply coupon'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in applyPartCoupon: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> submitServiceRequestPickupApproval({
    required int requestId,
    required int roleId,
    required int customerId,
    required String action,
    required int productId,
  }) async {
    try {
      final queryParameters = <String, String>{
        'role_id': roleId.toString(),
        'user_id': customerId.toString(),
        'service_request_id': requestId.toString(),
        'product_id': productId.toString(),
        'action': action,
      };

      final body = <String, dynamic>{
        'role_id': roleId,
        'user_id': customerId,
        'service_request_id': requestId,
        'product_id': productId,
        'action': action,
      };

      final url = Uri.parse(
        ApiConstants.service_request_pickup_approval,
      ).replace(queryParameters: queryParameters);

      debugPrint('API Request: POST $url');
      debugPrint('API Request Body: $body');

      final response = await _performAuthenticatedPost(url, body: body);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic data = jsonResponse['data'];
        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message:
              jsonResponse['message'] ?? 'Pickup status updated successfully',
          data: data is Map<String, dynamic>
              ? data
              : (data is Map
                    ? Map<String, dynamic>.from(data)
                    : <String, dynamic>{}),
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml
                ? 'Server returned HTML'
                : 'Failed to update pickup status'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in submitServiceRequestPickupApproval: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Order List API
  // ========================================

  Future<ApiResponse<List<OrderModel>>> getOrderList({
    required int roleId,
    required int customerId,
  }) async {
    try {
      debugPrint(
        'Ã°Å¸â€Âµ API Request: GET ${ApiConstants.order_list}?role_id=$roleId&user_id=$customerId',
      );

      final url = Uri.parse(ApiConstants.order_list).replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': customerId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);

      debugPrint('Ã°Å¸Å¸Â¡ API Response Status: ${response.statusCode}');
      debugPrint('Ã°Å¸Å¸Â¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : jsonResponse;

        dynamic ordersNode = payload['orders'];
        if (ordersNode == null && payload['data'] is Map<String, dynamic>) {
          ordersNode = (payload['data'] as Map<String, dynamic>)['orders'];
        }
        if (ordersNode == null && dataRoot is List) {
          ordersNode = dataRoot;
        }

        final orders = ordersNode is List
            ? ordersNode
                  .whereType<Map>()
                  .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
            : <OrderModel>[];

        return ApiResponse<List<OrderModel>>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Orders fetched successfully',
          data: orders,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<List<OrderModel>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch orders'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Ã°Å¸â€Â´ Unexpected Error in getOrderList: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<OrderModel>> getOrderDetail({
    required int roleId,
    required int customerId,
    required int orderId,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveInvoiceEndpoint(ApiConstants.myorderdetail, orderId),
          ).replace(
            queryParameters: {
              'role_id': roleId.toString(),
              'user_id': customerId.toString(),
            },
          );

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? Map<String, dynamic>.from(dataRoot)
            : dataRoot is Map
            ? Map<String, dynamic>.from(dataRoot)
            : jsonResponse;

        dynamic detailNode =
            payload['order'] ??
            payload['order_detail'] ??
            payload['order_details'] ??
            payload['details'] ??
            payload['data'];

        Map<String, dynamic>? detail;

        if (detailNode is Map<String, dynamic>) {
          detail = Map<String, dynamic>.from(detailNode);
        } else if (detailNode is Map) {
          detail = Map<String, dynamic>.from(detailNode);
        }

        final bool payloadLooksLikeOrder =
            payload.containsKey('order_number') ||
            payload.containsKey('order_products') ||
            payload.containsKey('order_items') ||
            payload.containsKey('grand_total') ||
            payload.containsKey('payment_status');

        if (detail == null && payloadLooksLikeOrder) {
          detail = payload;
        }

        if (detail == null) {
          return ApiResponse<OrderModel>(
            success: false,
            message: jsonResponse['message'] ?? 'Order details not found',
            errors: jsonResponse['errors'],
          );
        }

        if (!detail.containsKey('order_products') &&
            !detail.containsKey('order_items') &&
            !detail.containsKey('items')) {
          final dynamic itemsNode =
              payload['order_products'] ??
              payload['order_items'] ??
              payload['items'] ??
              payload['products'];
          if (itemsNode is List) {
            detail['order_products'] = itemsNode;
          }
        }

        return ApiResponse<OrderModel>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Order details fetched successfully',
          data: OrderModel.fromJson(detail),
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<OrderModel>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch order details'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getOrderDetail: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> cancelOrder({
    required int orderId,
    required int roleId,
    required int userId,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveInvoiceEndpoint(ApiConstants.cancelorder, orderId),
          ).replace(
            queryParameters: {
              'user_id': userId.toString(),
              'role_id': roleId.toString(),
            },
          );

      debugPrint('API Request: POST $url');

      final response = await _performAuthenticatedPost(url, body: {});

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : dataRoot is Map
            ? Map<String, dynamic>.from(dataRoot)
            : <String, dynamic>{};

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? true,
          message: _stringifyMessage(
            jsonResponse['message'],
            fallback: 'Order cancelled successfully',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _stringifyMessage(
          jsonResponse['message'],
          fallback: isHtml ? 'Server returned HTML' : 'Failed to cancel order',
        ),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in cancelOrder: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> returnOrder({
    required int orderId,
    required int roleId,
    required int customerId,
    required String customerNotes,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveInvoiceEndpoint(ApiConstants.returnorder, orderId),
          ).replace(
            queryParameters: {
              'customer_id': customerId.toString(),
              'role_id': roleId.toString(),
              'customer_notes': customerNotes,
            },
          );

      debugPrint('API Request: POST $url');

      final response = await _performAuthenticatedPost(url, body: {});

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : dataRoot is Map
            ? Map<String, dynamic>.from(dataRoot)
            : <String, dynamic>{};

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? jsonResponse['status'] ?? true,
          message: _stringifyMessage(
            jsonResponse['message'],
            fallback: 'Order returned successfully',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _stringifyMessage(
          jsonResponse['message'],
          fallback: isHtml ? 'Server returned HTML' : 'Failed to return order',
        ),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in returnOrder: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> claimReward({
    required int orderId,
    required int roleId,
    required int userId,
  }) async {
    try {
      final url =
          Uri.parse(
            _resolveInvoiceEndpoint(ApiConstants.viewreward, orderId),
          ).replace(
            queryParameters: {
              'role_id': roleId.toString(),
              'user_id': userId.toString(),
            },
          );

      debugPrint('API Request: POST $url');

      final response = await _performAuthenticatedPost(url, body: {});

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final payload = jsonResponse['data'] is Map<String, dynamic>
            ? jsonResponse['data'] as Map<String, dynamic>
            : jsonResponse['data'] is Map
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : Map<String, dynamic>.from(jsonResponse);

        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'] ?? jsonResponse['status'] ?? true,
          message: _stringifyMessage(
            jsonResponse['message'],
            fallback: 'Reward claimed successfully',
          ),
          data: payload,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _stringifyMessage(
          jsonResponse['message'],
          fallback: isHtml ? 'Server returned HTML' : 'Failed to claim reward',
        ),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in claimReward: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<List<RewardCoupon>>> getRewardsList({
    int? userId,
    int? roleId,
  }) async {
    try {
      final query = await _resolvedAuthFields(userId: userId, roleId: roleId);
      final url = query.isEmpty
          ? Uri.parse(ApiConstants.rewardslist)
          : Uri.parse(ApiConstants.rewardslist).replace(queryParameters: query);

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? Map<String, dynamic>.from(dataRoot)
            : dataRoot is Map
            ? Map<String, dynamic>.from(dataRoot)
            : jsonResponse;

        dynamic rewardsNode =
            payload['rewards'] ??
            payload['reward_list'] ??
            payload['reward'] ??
            payload['items'] ??
            payload['data'];

        if (rewardsNode == null && dataRoot is List) {
          rewardsNode = dataRoot;
        }

        final rewards = rewardsNode is List
            ? rewardsNode
                  .whereType<Map>()
                  .map(
                    (item) => _mapRewardCouponFromApi(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList()
            : <RewardCoupon>[];

        return ApiResponse<List<RewardCoupon>>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Rewards fetched successfully',
          data: rewards,
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<List<RewardCoupon>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch rewards'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getRewardsList: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Product Categories API
  // ========================================

  Future<ApiResponse<List<ProductCategory>>> getProductCategories({
    int? roleId,
  }) async {
    try {
      debugPrint(
        'Ã°Å¸â€Âµ API Request: GET ${ApiConstants.product_category}?role_id=$roleId',
      );

      final query = <String, String>{};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final url = query.isEmpty
          ? Uri.parse(ApiConstants.product_category)
          : Uri.parse(
              ApiConstants.product_category,
            ).replace(queryParameters: query);

      final response = await _performAuthenticatedGet(url);

      debugPrint('Ã°Å¸Å¸Â¡ API Response Status: ${response.statusCode}');
      debugPrint('Ã°Å¸Å¸Â¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final Map<String, dynamic> payload =
            jsonResponse['data'] is Map<String, dynamic>
            ? jsonResponse['data'] as Map<String, dynamic>
            : jsonResponse;
        final categories = ProductCategoryResponse.fromJson(payload).categories;
        return ApiResponse<List<ProductCategory>>(
          success: true,
          message: 'Categories fetched successfully',
          data: categories,
        );
      }

      return ApiResponse(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch categories'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Ã°Å¸â€Â´ Unexpected Error in getProductCategories: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Profile API
  // ========================================

  Future<ApiResponse<UserModel>> getProfile({int? userId, int? roleId}) async {
    try {
      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      final resolvedUserId = authFields['user_id']!;
      final resolvedRoleId = authFields['role_id']!;

      debugPrint(
        'ðŸ”µ API Request: GET ${ApiConstants.profile}?user_id=$resolvedUserId&role_id=$resolvedRoleId',
      );

      final url = Uri.parse(ApiConstants.profile).replace(
        queryParameters: {'user_id': resolvedUserId, 'role_id': resolvedRoleId},
      );

      final response = await _performAuthenticatedGet(url);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ Unexpected Error in getProfile: $e');
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
      debugPrint('ðŸ”µ API Request: PUT ${ApiConstants.profile}');
      final body = {
        'user_id': userId,
        'role_id': roleId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'dob': dob,
        'gender': gender,
      };
      debugPrint('ðŸ”µ Request Body: $body');

      final response = await _performAuthenticatedPut(
        Uri.parse(ApiConstants.profile),
        body: body,
      );

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ Unexpected Error in updateProfile: $e');
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
        'ðŸ”µ API Request: GET ${ApiConstants.addresses}?user_id=$userId&role_id=$roleId',
      );

      final url = Uri.parse(ApiConstants.addresses).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'role_id': roleId.toString(),
        },
      );

      final response = await _performAuthenticatedGet(url);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ Unexpected Error in getAddresses: $e');
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
      debugPrint('ðŸ”µ API Request: POST ${ApiConstants.address}');

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

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ Unexpected Error in storeAddress: $e');
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
      debugPrint('ðŸ”µ API Request: PUT ${ApiConstants.address}/$addressId');

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

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

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
      debugPrint('ðŸ”´ Unexpected Error in updateAddress: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // Document API
  // ========================================

  Future<ApiResponse<AadharCard>> getAadharDetails({
    int? userId,
    int? roleId,
  }) async {
    try {
      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      final url = Uri.parse(
        ApiConstants.aadharCard,
      ).replace(queryParameters: authFields);

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

  Future<ApiResponse<PanCard>> getPanDetails({int? userId, int? roleId}) async {
    try {
      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      final url = Uri.parse(
        ApiConstants.panCard,
      ).replace(queryParameters: authFields);

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
    int? userId,
    int? roleId,
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
      request.headers.addAll(await _authenticatedMultipartHeaders());

      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      request.fields.addAll(authFields);
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
    int? userId,
    int? roleId,
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
      request.headers.addAll(await _authenticatedMultipartHeaders());

      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      request.fields.addAll(authFields);
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
    int? userId,
    int? roleId,
  }) async {
    try {
      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      final url = Uri.parse(
        ApiConstants.company,
      ).replace(queryParameters: authFields);

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
    int? userId,
    int? roleId,
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
      final authFields = await _resolvedAuthFields(
        userId: userId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      final resolvedUserId = authFields['user_id']!;
      final resolvedRoleId = authFields['role_id']!;

      if (companyId != null) {
        // For Edit: PUT request with params in URL as per Postman screenshot
        final url = Uri.parse("${ApiConstants.company}/$companyId").replace(
          queryParameters: {
            'user_id': resolvedUserId,
            'role_id': resolvedRoleId,
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
          'user_id': int.parse(resolvedUserId),
          'role_id': int.parse(resolvedRoleId),
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

  Future<ApiResponse<List<BannerModel>>> getBanners({int? roleId}) async {
    try {
      final query = <String, String>{};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final url = query.isEmpty
          ? Uri.parse(ApiConstants.banners)
          : Uri.parse(ApiConstants.banners).replace(queryParameters: query);

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
    int? roleId,
  }) async {
    try {
      final query = <String, String>{};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final url = query.isEmpty
          ? Uri.parse(ApiConstants.quickservices)
          : Uri.parse(
              ApiConstants.quickservices,
            ).replace(queryParameters: query);

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

  /// Submit Quick Service Request
  Future<ApiResponse> submitQuickServiceRequest({
    int? customerId,
    int? roleId,
    required String serviceType,
    required List<Map<String, dynamic>> products,
    int? amcPlanId,
    int? customerAddressId,
  }) async {
    try {
      debugPrint('ðŸ”µ API Request: POST ${ApiConstants.submitQuickService}');

      final url = Uri.parse(ApiConstants.submitQuickService);
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(await _authenticatedMultipartHeaders());

      final authFields = await _resolvedAuthFields(
        userId: customerId,
        roleId: roleId,
      );
      if (!authFields.containsKey('user_id') ||
          !authFields.containsKey('role_id')) {
        return ApiResponse(
          success: false,
          message: 'Missing user session. Please login again.',
        );
      }

      request.fields.addAll(authFields);
      request.fields['service_type'] = serviceType;
      if (customerAddressId != null) {
        request.fields['customer_address_id'] = customerAddressId.toString();
      }
      if (amcPlanId != null) {
        request.fields['amc_plan_id'] = amcPlanId.toString();
      }

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        request.fields['products[$i][name]'] = (product['name'] ?? '')
            .toString();
        request.fields['products[$i][type]'] = (product['type'] ?? '')
            .toString();
        request.fields['products[$i][model_no]'] = (product['model_no'] ?? '')
            .toString();
        request.fields['products[$i][sku]'] = (product['sku'] ?? '')
            .toString(); // Optional
        request.fields['products[$i][hsn]'] = (product['hsn'] ?? '')
            .toString(); // Optional
        request.fields['products[$i][purchase_date]'] =
            (product['purchase_date'] ?? '').toString();
        request.fields['products[$i][brand]'] = (product['brand'] ?? '')
            .toString();
        request.fields['products[$i][description]'] =
            (product['description'] ?? '').toString();
        if (product['service_type_id'] != null) {
          request.fields['products[$i][service_type_id]'] =
              product['service_type_id'].toString();
        }

        // Add images if any
        if (product['images'] != null && product['images'] is List<File>) {
          final List<File> images = product['images'];
          for (var img in images) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'products[$i][images][]',
                img.path,
              ),
            );
          }
        }
      }

      // Log the exact multipart keys/files being sent (to compare with Postman).
      debugPrint('Quick Service fields: ${request.fields}');
      debugPrint(
        'Quick Service files: ${request.files.map((f) => '${f.field}:${f.filename}').toList()}',
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic responseData =
            jsonResponse['data'] ?? jsonResponse['quick_service_request'];
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Request submitted successfully',
          data: responseData,
        );
      }

      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to submit request',
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error in submitQuickServiceRequest: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Get Services List (Filtered by role_id and service_type)
  Future<ApiResponse<List<QuickService>>> getServicesList({
    int? roleId,
    required String serviceType,
  }) async {
    try {
      final query = <String, String>{'service_type': serviceType};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final url = Uri.parse(
        ApiConstants.servicesList,
      ).replace(queryParameters: query);

      debugPrint('ðŸ”µ API Request: GET $url');

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> serviceList = jsonResponse['services'] ?? [];
        return ApiResponse<List<QuickService>>(
          success: true,
          message: 'Services fetched successfully',
          data: serviceList.map((e) => QuickService.fromJson(e)).toList(),
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to fetch services',
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error in getServicesList: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Give Feedback
  Future<ApiResponse> giveFeedback({
    required int roleId,
    required int customerId,
    required String serviceType,
    required String serviceId,
    required int rating,
    required String comments,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.givefeedback).replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': customerId.toString(),
          'service_type': serviceType,
          'service_id': serviceId,
          'rating': rating.toString(),
          'comments': comments,
        },
      );

      debugPrint('ðŸ”µ API Request: POST $url');

      // The Postman screenshot shows it as a POST but with query parameters.
      // We use _performAuthenticatedPost with an empty body if the backend expects POST method.
      final response = await _performAuthenticatedPost(url, body: {});
      final jsonResponse = _safeJsonDecode(response.body);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Feedback submitted successfully',
          data: jsonResponse['data'],
        );
      }

      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to submit feedback',
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error in giveFeedback: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Get Individual Feedback
  Future<ApiResponse> getFeedbackDetails({
    required int roleId,
    required int customerId,
    required String feedbackId,
  }) async {
    try {
      // Endpoint: https://crackteck.co.in/api/v1/get-feedback/2?role_id=4&user_id=3
      final url = Uri.parse("${ApiConstants.getfeedback}/$feedbackId").replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': customerId.toString(),
        },
      );

      debugPrint('ðŸ”µ API Request: GET $url');

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return ApiResponse(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Feedback fetched successfully',
          data: jsonResponse['feedback'],
        );
      }

      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Failed to fetch feedback details',
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('ðŸ”´ Unexpected Error in getFeedbackDetails: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Get All Feedback
  Future<ApiResponse<List<dynamic>>> getAllFeedback({
    required int roleId,
    required int customerId,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.getallfeedback).replace(
        queryParameters: {
          'role_id': roleId.toString(),
          'user_id': customerId.toString(),
        },
      );

      debugPrint('API Request: GET $url');

      final response = await _performAuthenticatedGet(url);
      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic dataRoot = jsonResponse['data'];
        final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
            ? dataRoot
            : jsonResponse;

        dynamic feedbackNode =
            payload['feedbacks'] ??
            payload['feedback_list'] ??
            payload['all_feedback'] ??
            payload['all_feedbacks'] ??
            payload['feedback'];

        if (feedbackNode == null && payload['data'] is List) {
          feedbackNode = payload['data'];
        }
        if (feedbackNode == null && dataRoot is List) {
          feedbackNode = dataRoot;
        }

        return ApiResponse<List<dynamic>>(
          success: jsonResponse['success'] ?? true,
          message: jsonResponse['message'] ?? 'Feedback fetched successfully',
          data: feedbackNode is List ? feedbackNode : <dynamic>[],
          errors: jsonResponse['errors'],
        );
      }

      return ApiResponse<List<dynamic>>(
        success: false,
        message:
            jsonResponse['message'] ??
            (isHtml ? 'Server returned HTML' : 'Failed to fetch feedback list'),
        errors: jsonResponse['errors'],
      );
    } on SocketException {
      return ApiResponse(success: false, message: 'No internet connection.');
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout.');
    } catch (e) {
      debugPrint('Unexpected Error in getAllFeedback: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ========================================
  // AMC Plans API
  // ========================================

  Future<ApiResponse<List<AmcPlanItem>>> getAmcPlans({
    int? roleId,
    String? supportType,
  }) async {
    try {
      debugPrint(
        'ðŸ”µ API Request: GET ${ApiConstants.amcPlans}?role_id=$roleId',
      );

      final query = <String, String>{};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final normalizedSupportType = supportType?.trim().toLowerCase();
      if (normalizedSupportType != null && normalizedSupportType.isNotEmpty) {
        query['support_type'] = normalizedSupportType;
      }
      final url = query.isEmpty
          ? Uri.parse(ApiConstants.amcPlans)
          : Uri.parse(ApiConstants.amcPlans).replace(queryParameters: query);

      final response = await _performAuthenticatedGet(url);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final parsed = AmcPlanResponse.fromJson(jsonResponse);
        return ApiResponse<List<AmcPlanItem>>(
          success: true,
          message: 'AMC plans fetched successfully',
          data: parsed.amcPlans ?? <AmcPlanItem>[],
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
      debugPrint('âŒ Error fetching AMC plans: $e');
      return ApiResponse(success: false, message: 'An error occurred: $e');
    }
  }

  // Get AMC Plan Details by ID
  Future<ApiResponse<AmcPlanDetailResponse>> getAmcPlanDetails({
    required int planId,
    int? roleId,
  }) async {
    try {
      debugPrint(
        'ðŸ”µ API Request: GET ${ApiConstants.amcPlanDetails}/$planId?role_id=$roleId',
      );

      final query = <String, String>{};
      if (roleId != null && roleId > 0) {
        query['role_id'] = roleId.toString();
      }
      final url = query.isEmpty
          ? Uri.parse('${ApiConstants.amcPlanDetails}/$planId')
          : Uri.parse(
              '${ApiConstants.amcPlanDetails}/$planId',
            ).replace(queryParameters: query);

      final response = await _performAuthenticatedGet(url);

      debugPrint('ðŸŸ¡ API Response Status: ${response.statusCode}');
      debugPrint('ðŸŸ¡ API Response Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);
      final bool isHtml = jsonResponse['isHtml'] == true;

      if (!isHtml &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final payload = jsonResponse['data'] is Map<String, dynamic>
            ? jsonResponse['data'] as Map<String, dynamic>
            : jsonResponse;
        final detailPayload = payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;

        return ApiResponse<AmcPlanDetailResponse>(
          success: true,
          message: 'AMC plan details fetched successfully',
          data: AmcPlanDetailResponse.fromJson({'data': detailPayload}),
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
      debugPrint('ðŸ”´ Unexpected Error in getAmcPlanDetails: $e');
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }
  // ========================================
  // Sales Dashboard API Methods
  // ========================================

  static const int _fallbackRoleIdForRefresh = 3; // Salesperson role id
  static const int _maxAuthRetries = 1;
  static const Duration _maxPostRefreshTokenWait = Duration(seconds: 45);
  static Future<bool>? _ongoingTokenRefresh;
  static Future<void>? _ongoingAuthFailureHandling;

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
        'ðŸ”´ HTML login page detected from ${response.request?.url}. '
        'Treating as unauthorized.',
      );
      return true;
    }

    final bodyLower = response.body.toLowerCase();
    return bodyLower.contains('401') ||
        bodyLower.contains('unauthorized') ||
        bodyLower.contains('token not provided');
  }

  static Future<Uri> _appendStoredAuthQuery(Uri url) async {
    final roleId = await SecureStorageService.getRoleId();
    final userId = await SecureStorageService.getUserId();
    final query = Map<String, String>.from(url.queryParameters);

    final existingRoleId = query['role_id'];
    final existingUserId = query['user_id'];

    if (_isInvalidAuthQueryValue(existingRoleId) &&
        roleId != null &&
        roleId > 0) {
      query['role_id'] = roleId.toString();
    }
    if (_isInvalidAuthQueryValue(existingUserId) &&
        userId != null &&
        userId > 0) {
      query['user_id'] = userId.toString();
    }

    if (mapEquals(query, url.queryParameters)) {
      return url;
    }
    return url.replace(queryParameters: query);
  }

  static bool _isInvalidAuthQueryValue(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized.isEmpty ||
        normalized == 'null' ||
        normalized == 'undefined' ||
        normalized == '0';
  }

  static Future<bool> _attemptTokenRefresh() async {
    final storedRoleId = await SecureStorageService.getRoleId();
    final storedUserId = await SecureStorageService.getUserId();
    if (storedUserId == null) {
      debugPrint('ðŸ”´ Cannot refresh token: missing stored user_id');
      return false;
    }

    final roleId = storedRoleId ?? _fallbackRoleIdForRefresh;
    final api = ApiService.instance;
    final response = await api.refreshToken(
      roleId: roleId,
      userId: storedUserId,
    );
    if (!response.success) {
      return false;
    }

    await _waitForRefreshedTokenReadiness();
    return true;
  }

  static Future<void> _waitForRefreshedTokenReadiness() async {
    final accessToken = await SecureStorageService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    final waitDuration = _computePostRefreshWait(accessToken);
    if (waitDuration == null || waitDuration <= Duration.zero) {
      return;
    }

    debugPrint(
      'Waiting ${waitDuration.inSeconds}s for refreshed token nbf before retrying request.',
    );
    await Future.delayed(waitDuration);
  }

  static Duration? _computePostRefreshWait(String token) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) {
      return null;
    }

    final nbfValue = _tryParseInt(payload['nbf']);
    if (nbfValue == null) {
      return null;
    }

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final deltaSeconds = nbfValue - nowSeconds;
    if (deltaSeconds <= 0) {
      return null;
    }

    final waitSeconds = deltaSeconds + 1;
    final candidate = Duration(seconds: waitSeconds);
    if (candidate > _maxPostRefreshTokenWait) {
      return _maxPostRefreshTokenWait;
    }
    return candidate;
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final parsed = jsonDecode(decoded);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<bool> _attemptTokenRefreshSingleFlight() {
    final inFlight = _ongoingTokenRefresh;
    if (inFlight != null) {
      return inFlight;
    }

    late Future<bool> refreshFuture;
    refreshFuture = _attemptTokenRefresh()
        .catchError((error, stackTrace) {
          debugPrint('Refresh token flow failed: $error');
          return false;
        })
        .whenComplete(() {
          if (identical(_ongoingTokenRefresh, refreshFuture)) {
            _ongoingTokenRefresh = null;
          }
        });

    _ongoingTokenRefresh = refreshFuture;
    return refreshFuture;
  }

  static Future<void> _handleAuthFailure() async {
    final inFlight = _ongoingAuthFailureHandling;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    late Future<void> authFailureFuture;
    authFailureFuture =
        () async {
          await SecureStorageService.clearTokens();
          await NavigationService.navigateToAuthRoot();
        }().whenComplete(() {
          if (identical(_ongoingAuthFailureHandling, authFailureFuture)) {
            _ongoingAuthFailureHandling = null;
          }
        });

    _ongoingAuthFailureHandling = authFailureFuture;
    await authFailureFuture;
  }

  static Future<http.Response> _performAuthenticatedGet(Uri url) async {
    int retryCount = 0;
    bool refreshedInThisRequest = false;
    while (true) {
      final authenticatedUrl = await _appendStoredAuthQuery(url);
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .get(authenticatedUrl, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        if (!refreshedInThisRequest) {
          await _handleAuthFailure();
        }
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefreshSingleFlight();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      refreshedInThisRequest = true;
      // Token refreshed successfully, loop will retry with new token.
    }
  }

  RewardCoupon _mapRewardCouponFromApi(Map<String, dynamic> json) {
    final rewardDetails = json['reward_details'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['reward_details'] as Map<String, dynamic>)
        : json['reward_details'] is Map
        ? Map<String, dynamic>.from(json['reward_details'] as Map)
        : const <String, dynamic>{};
    final couponDetails = json['coupon_details'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['coupon_details'] as Map<String, dynamic>)
        : json['coupon_details'] is Map
        ? Map<String, dynamic>.from(json['coupon_details'] as Map)
        : const <String, dynamic>{};

    final sourceType = _pickRewardText([
      json['source_type'],
      json['reward_source_type'],
      rewardDetails['source_type'],
      rewardDetails['reward_type'],
      json['type'],
    ], fallback: 'reward');
    final sourceId = _pickRewardText([
      json['source_id'],
      json['order_id'],
      json['service_request_id'],
      rewardDetails['source_id'],
      rewardDetails['order_id'],
      rewardDetails['service_request_id'],
      json['id'],
      rewardDetails['reward_id'],
      couponDetails['id'],
    ], fallback: '0');
    final rawRewardId = _pickRewardText([
      rewardDetails['reward_id'],
      json['reward_id'],
      json['id'],
      couponDetails['id'],
      sourceId,
    ], fallback: sourceId);
    final title = _pickRewardText([
      json['title'],
      json['reward_title'],
      couponDetails['coupon_name'],
      couponDetails['title'],
      couponDetails['offer_title'],
      rewardDetails['title'],
    ], fallback: 'Reward');
    final description = _pickRewardText([
      json['description'],
      json['reward_description'],
      couponDetails['description'],
      couponDetails['coupon_description'],
      rewardDetails['description'],
    ], fallback: 'Reward available for your account');
    final code = _pickRewardText([
      json['code'],
      json['coupon_code'],
      couponDetails['coupon_code'],
      couponDetails['code'],
    ], fallback: 'N/A');
    final validTill = _pickRewardText([
      json['valid_till'],
      json['validTill'],
      json['expiry_date'],
      json['expires_at'],
      rewardDetails['reward_end_date'],
      couponDetails['end_date'],
      couponDetails['valid_till'],
    ], fallback: 'Limited time');
    final createdAt = _pickRewardText([
      json['created_at'],
      json['createdAt'],
      rewardDetails['created_at'],
      couponDetails['created_at'],
    ], fallback: DateTime.now().toIso8601String());
    final scratched = _pickRewardBool([
      json['scratched'],
      json['is_scratched'],
      json['is_revealed'],
      json['claimed'],
      json['is_claimed'],
      json['status'],
    ]);
    final accentHex = _pickRewardColor([
      json['accent_hex'],
      json['accentHex'],
      json['color'],
      couponDetails['color'],
      rewardDetails['color'],
    ]);
    final iconName = _pickRewardText([
      json['icon_name'],
      json['iconName'],
      json['icon'],
      rewardDetails['icon_name'],
      couponDetails['icon_name'],
    ], fallback: _iconForRewardType(sourceType, title));
    final applicableCategories = _parseRewardRuleItems(
      couponDetails['applicable_categories'] ??
          rewardDetails['applicable_categories'] ??
          json['applicable_categories'],
      titleKeys: const ['name'],
      subtitleKeys: const ['type', 'slug'],
    );
    final applicableBrands = _parseRewardRuleItems(
      couponDetails['applicable_brands'] ??
          rewardDetails['applicable_brands'] ??
          json['applicable_brands'],
      titleKeys: const ['name'],
      subtitleKeys: const ['slug'],
    );
    final excludedProducts = _parseRewardRuleItems(
      couponDetails['excluded_products'] ??
          rewardDetails['excluded_products'] ??
          json['excluded_products'],
      titleKeys: const ['product_name', 'name'],
      subtitleKeys: const ['sku'],
    );

    return RewardCoupon(
      id: 'reward_${sourceType}_$rawRewardId',
      title: title,
      description: description,
      code: code,
      sourceType: sourceType,
      sourceId: sourceId,
      scratched: scratched,
      validTill: validTill,
      accentHex: accentHex,
      iconName: iconName,
      createdAt: createdAt,
      applicableCategories: applicableCategories,
      applicableBrands: applicableBrands,
      excludedProducts: excludedProducts,
    );
  }

  String _pickRewardText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
  }

  bool _pickRewardBool(List<dynamic> values, {bool fallback = false}) {
    for (final value in values) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized.isEmpty) {
          continue;
        }
        if (<String>{'true', '1', 'yes', 'claimed', 'scratched', 'revealed', 'unlocked'}
            .contains(normalized)) {
          return true;
        }
        if (<String>{'false', '0', 'no', 'pending', 'locked'}
            .contains(normalized)) {
          return false;
        }
      }
    }
    return fallback;
  }

  String _pickRewardColor(List<dynamic> values) {
    final picked = _pickRewardText(values);
    if (picked.isEmpty) {
      return '#1A73E8';
    }

    final normalized = picked.replaceAll('#', '').trim();
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized)) {
      return '#$normalized';
    }
    if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(normalized)) {
      return '#${normalized.substring(2)}';
    }
    return '#1A73E8';
  }

  String _iconForRewardType(String sourceType, String title) {
    final normalizedSource = sourceType.toLowerCase();
    final normalizedTitle = title.toLowerCase();

    if (normalizedSource.contains('service') ||
        normalizedTitle.contains('service')) {
      return 'build_circle';
    }
    if (normalizedTitle.contains('delivery') ||
        normalizedTitle.contains('shipping')) {
      return 'local_shipping';
    }
    if (normalizedTitle.contains('rs') ||
        normalizedTitle.contains('rupee') ||
        normalizedTitle.contains('cash') ||
        normalizedTitle.contains('save')) {
      return 'currency_rupee';
    }
    if (normalizedTitle.contains('reward')) {
      return 'redeem';
    }
    return 'local_offer';
  }

  List<RewardRuleItem> _parseRewardRuleItems(
    dynamic raw, {
    required List<String> titleKeys,
    List<String> subtitleKeys = const <String>[],
  }) {
    if (raw is! List) return const <RewardRuleItem>[];

    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      final title = _pickRewardText(
        titleKeys.map((key) => map[key]).toList(),
        fallback: 'Item',
      );
      final subtitle = _pickRewardText(
        subtitleKeys.map((key) => map[key]).toList(),
      );
      final id = _pickRewardText([
        map['id'],
        map['product_id'],
        map['brand_id'],
        map['parent_category_id'],
        title,
      ], fallback: title);

      return RewardRuleItem(
        id: id,
        title: title,
        subtitle: subtitle,
      );
    }).toList();
  }

  static Future<http.Response> _performAuthenticatedPut(
    Uri url, {
    required Map<String, dynamic> body,
  }) async {
    int retryCount = 0;
    bool refreshedInThisRequest = false;
    while (true) {
      final authenticatedUrl = await _appendStoredAuthQuery(url);
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .put(authenticatedUrl, headers: headers, body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        if (!refreshedInThisRequest) {
          await _handleAuthFailure();
        }
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefreshSingleFlight();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      refreshedInThisRequest = true;
      // Token refreshed successfully, loop will retry with new token.
    }
  }

  static Future<http.Response> _performAuthenticatedPutRequest(Uri url) async {
    int retryCount = 0;
    bool refreshedInThisRequest = false;
    while (true) {
      final authenticatedUrl = await _appendStoredAuthQuery(url);
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .put(authenticatedUrl, headers: headers)
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        if (!refreshedInThisRequest) {
          await _handleAuthFailure();
        }
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefreshSingleFlight();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      refreshedInThisRequest = true;
    }
  }

  static Future<http.Response> _performAuthenticatedPost(
    Uri url, {
    required Map<String, dynamic> body,
  }) async {
    int retryCount = 0;
    bool refreshedInThisRequest = false;
    while (true) {
      final authenticatedUrl = await _appendStoredAuthQuery(url);
      final accessToken = await SecureStorageService.getAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http
          .post(authenticatedUrl, headers: headers, body: jsonEncode(body))
          .timeout(ApiConstants.requestTimeout);

      if (!_isUnauthorizedResponse(response)) {
        return response;
      }

      // Unauthorized
      if (retryCount >= _maxAuthRetries) {
        if (!refreshedInThisRequest) {
          await _handleAuthFailure();
        }
        return response;
      }

      retryCount++;
      final refreshed = await _attemptTokenRefreshSingleFlight();
      if (!refreshed) {
        await _handleAuthFailure();
        return response;
      }
      refreshedInThisRequest = true;
      // Token refreshed successfully, loop will retry with new token.
    }
  }
}
