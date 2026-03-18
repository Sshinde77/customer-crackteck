/// API endpoint constants
class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  // Base URL Configuration

  // Current Configuration: Android Emulator
  static const String baseUrl = 'https://crackteck.co.in/api/v1';

  // Authentication Endpoints
  static const String login = '$baseUrl/send-otp';
  static const String verifyOtp = '$baseUrl/verify-otp';
  static const String refreshToken = '$baseUrl/refresh-token';
  static const String signup = '$baseUrl/signup';
  static const String logout = '$baseUrl/logout';
  static const String productlist = '$baseUrl/product';
  static const String profile = '$baseUrl/profile';
  static const String addresses = '$baseUrl/addresses';
  static const String address = '$baseUrl/address';
  static const String aadharCard = '$baseUrl/aadhar-card';
  static const String panCard = '$baseUrl/customer-pan-card';
  static const String company = '$baseUrl/company-details';
  static const String banners = '$baseUrl/banners';
  static const String quickservices = '$baseUrl/quick-services';
  static const String submitQuickService =
      '$baseUrl/submit-quick-service-request';
  static const String servicesList = '$baseUrl/services-list';
  static const String services = '$baseUrl/services';
  static const String givefeedback = '$baseUrl/give-feedback';
  static const String getfeedback = '$baseUrl/get-feedback';
  static const String getallfeedback = '$baseUrl/get-all-feedback';
  static const String amcPlans = '$baseUrl/amc-plans';
  static const String amcPlanDetails = '$baseUrl/amc-plan-details';
  static const String product_category = '$baseUrl/product/categories';
  static const String productdetail = '$baseUrl/product';
  static const String product_buy = '$baseUrl/buy-product';
  static const String order_list = '$baseUrl/order';
  static const String service_request_list = '$baseUrl/all-service-requests';
  static const String service_request_details =
      '$baseUrl/service-request-details';
  static const String service_request_product_diagnostics =
      '$baseUrl/service-request-product-diagnostics';
  static const String service_request_approval =
      '$baseUrl/customer-approve-reject-part';
  static const String service_request_pickup_approval =
      '$baseUrl/customer-approve-reject-pickup';
  static const String quotation_list = '$baseUrl/service-request-quotations';
  static const String quotation_detail =
      '$baseUrl/service-request-quotation-details';
  static const String quotation_accept =
      '$baseUrl/service-request-quotations/{id}/accept';
  static const String quotation_reject =
      '$baseUrl/service-request-quotations{id}/reject';
  static const String invoice_list = '$baseUrl/service-request-invoices';
  static const String invoice_detail =
      '$baseUrl/service-request-invoice/{id}';
  static const String invoice_accept =
      '$baseUrl/service-request-invoice/{id}/accept';
  static const String invoice_reject =
      '$baseUrl/service-request-invoice/{id}/reject';
  static const String invoice_payment =
      '$baseUrl/invoice-payment/{id}';
  static const String cancelorder =
      '$baseUrl/cancel-order/{id}';
  static const String returnorder =
      '$baseUrl/return-order/{id}';

  static const String googlelogin =
      '$baseUrl/google-login';
  static const String couponapply =
      '$baseUrl/part-apply-coupon';

  // Request Timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Country Code
  static const String defaultCountryCode = '+91';
}
