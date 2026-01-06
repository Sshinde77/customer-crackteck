import '../constants/app_strings.dart';

/// App-wide route name constants
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation


  //Initial Route Login Route (unified for all roles)
  static const String login = '/login';

  // OTP Verification Route
  static const String otpVerification = '/otp-verification';
  static const String hometab = '/hometab';

  // Sign Up Routes
  static const String signUp = '/signup';
  static const String salespersonDashboard = '/SalespersonDashboard';
  static const String salespersonLeads = '/salesperson-leads';
  static const String NewLeadScreen = '/new-lead-screen';
  static const String salespersonFollowUp = '/salesperson-followup';
  static const String salespersonMeeting = '/salesperson-meeting';
  static const String salespersonQuotation = '/salesperson-quotation';
  static const String salespersonProfile = '/salesperson-profile';
  static const String SalesPersonPersonalInfoScreen = '/salesperson-personal-info';
  static const String SalesPersonAttendanceScreen = '/salesperson-attendance';
  static const  String TaskViewAll = '/Task-Viewall';
  static const String salesoverview = '/sales-overview-screen';
  static const String newfollowupscreen = '/new-followup-screen';
  static const String salespersonNewQuotation = '/salesperson-new-quotation';
  static const String salespernewsonMeeting = '/salesperson-new-meeting';

  // 🔹 TEMP DASHBOARD ROUTES (ADD THESE)
  static const String adminDashboard = '/admin-dashboard';
  static const String residentDashboard = '/resident-dashboard';
  // static const String securityDashboard = '/security-dashboard';
}

/// Route arguments for passing data between screens
class LoginArguments {
  final int roleId;
  LoginArguments({ this.roleId =AppStrings.roleId});
}

