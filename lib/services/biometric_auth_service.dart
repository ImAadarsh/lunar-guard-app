import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Returns null on success, or an error/cancel message on failure.
  Future<String?> authenticateGate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported && !canCheck) {
        // No hardware / platform support: allow app access.
        return null;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Verify your identity to access Lunar Security',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      if (ok) return null;
      return 'Biometric verification was cancelled or failed.';
    } on PlatformException catch (e) {
      return e.message ?? 'Biometric verification failed.';
    } catch (_) {
      return 'Biometric verification failed.';
    }
  }
}
