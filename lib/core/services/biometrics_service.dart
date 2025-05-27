import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricsService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      // Optionally log the error
      return false;
    }
  }

  Future<bool> authenticate(
      {String reason = 'Please authenticate to proceed'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      // Optionally log the error
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      // Optionally log the error
      return [];
    }
  }
}
