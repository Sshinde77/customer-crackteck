import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Force account selection so the user can pick the intended Google account.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in cancelled by user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      return <String, dynamic>{
        'displayName': googleUser.displayName,
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
        'googleUserId': googleUser.id,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
      };
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Google sign-in platform error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } catch (error, stackTrace) {
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> sendGoogleLoginDataToBackend(
    Map<String, dynamic> googleUserData,
  ) async {
    // TODO: Replace with the actual API integration once the backend contract is ready.
    debugPrint('Sending Google login payload to backend: $googleUserData');
  }
}
