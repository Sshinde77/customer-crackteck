/// App-wide string constants
class AppStrings {
  AppStrings._(); // Private constructor to prevent instantiation

  // Role Selection Screen
  static const String roleSelectionTitle = 'Select your service role';
  static const String roleSelectionSubtitle = 'Choose your role to continue';

  static const int roleId= 4;
  // User Roles
  static const String fieldExecutive = 'Field Executive';
  static const String deliveryMan = 'Delivery Man';
  static const String salesPerson = 'Sales Person';

  // App Name
  static const String appName = 'CrackTech';

  // Login Screen
  static const String welcomeBack = 'Welcome Back!';
  static const String numberLabel = 'Phone Number :';
  static const String loginButton = 'Login';
  static const String dontHaveAccount = "Don't have account? ";
  static const String signUp = 'Sign Up';

  // Error Messages
  static const String phoneNotFound = 'Phone Number is Not found';
  static const String invalidPhoneFormat =
      'Please enter a valid 10-digit phone number';
  static const String networkError = 'Network error. Please try again.';
  static const String somethingWentWrong =
      'Something went wrong. Please try again.';

  // Dialog Buttons
  static const String cancel = 'Cancel';
  static const String signUpButton = 'Sign Up';

  // OTP Screen
  static const String otpVerification = 'OTP Verification';
  static const String enterOtp = 'Enter the OTP sent to your phone';
  static const String verifyButton = 'Verify';
  static const String resendOtp = 'Resend OTP';

  // Sign Up Screen
  static const String createAccount = 'Create Account';
  static const String nameLabel = 'Full Name';
  static const String emailLabel = 'Email';
  static const String registerButton = 'Register';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String login = 'Login';
}

/// Helper function to generate dynamic subtitle
String getLoginSubtitle() {
  return 'Customer, please continue to login';
}

/// Helper function to generate dynamic signup subtitle
String getSignUpSubtitle(String roleName) {
  return '$roleName, please fill the details to sign up';
}
