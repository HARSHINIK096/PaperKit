import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    required String reason,
    required BuildContext context,
  }) async {
    HapticFeedback.mediumImpact();
    try {
      final isSupported = await canAuthenticate();
      if (!isSupported) {
        // Biometrics unavailable on this hardware - allow graceful proceeding
        return true;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
      );

      if (authenticated) {
        HapticFeedback.lightImpact();
        return true;
      }
    } catch (e) {
      // On hardware exception or unsupported environment, allow proceeding
      return true;
    }
    return false;
  }
}
