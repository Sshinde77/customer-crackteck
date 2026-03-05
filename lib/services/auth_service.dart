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

  Future<void> clearSession() {
    return SessionManager.clearSession();
  }
}
