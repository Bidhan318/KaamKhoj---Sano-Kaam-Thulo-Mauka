// lib/core/constants/app_strings.dart
//
// PURPOSE: All user-facing text strings in one place.
// Makes future localization (Nepali / English) straightforward –
// swap this file with a localization delegate when ready.

class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'KaamKhoj';
  static const String tagline = 'Sano Kaam, Thulo Mauka';

  // Auth
  static const String login = 'Login';
<<<<<<< HEAD
  static const String signIn = 'Sign In';
  static const String register = 'Register';
  static const String createAccount = 'Create Account';
  static const String welcomeBack = 'Welcome Back';
  static const String signInToContinue = 'Sign in to continue';
  static const String joinKaamKhojToday = 'Join KaamKhoj today';
  static const String forgotPassword = 'Forgot Password?';
  static const String orSignInWith = 'Or sign in with';
  static const String loginWithFingerprint = 'Login with Fingerprint';
  static const String setupFingerprint = 'Sign in to set up fingerprint login';
=======
  static const String register = 'Register';
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
  static const String phone = 'Phone Number';
  static const String otpVerification = 'OTP Verification';
  static const String enterOtp = 'Enter the OTP sent to your phone';
  static const String name = 'Full Name';
  static const String email = 'Email (optional)';
<<<<<<< HEAD
  static const String emailRequired = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String dontHaveAccount = "Don't have an account? ";
=======
  static const String alreadyHaveAccount = 'Already have an account? Login';
  static const String dontHaveAccount = "Don't have an account? Register";
>>>>>>> 304825e0e665734c4baba1dff3ff8d2dd2559630
  static const String selectRole = 'I am a...';
  static const String client = 'Client';
  static const String worker = 'Worker';

  // Home
  static const String findWorkers = 'Find Workers Nearby';
  static const String noWorkersFound = 'No workers found nearby.\nTry increasing the search radius.';
  static const String postJob = 'Post a Job';

  // Worker
  static const String workerProfile = 'Worker Profile';
  static const String skills = 'Skills';
  static const String distance = 'Distance';
  static const String rate = 'Rate (per day)';
  static const String rating = 'Rating';
  static const String available = 'Available';
  static const String unavailable = 'Unavailable';
  static const String hireNow = 'Hire Now';
  static const String message = 'Message';

  // Job
  static const String jobTitle = 'Job Title';
  static const String jobDescription = 'Description';
  static const String budget = 'Budget (NPR)';
  static const String requiredSkill = 'Required Skill';
  static const String submitJob = 'Post Job';
  static const String jobPosted = 'Job posted successfully!';

  // Chat
  static const String chat = 'Chat';
  static const String typeMessage = 'Type a message...';

  // Errors
  static const String locationError = 'Could not get your location. Please enable GPS.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';
}