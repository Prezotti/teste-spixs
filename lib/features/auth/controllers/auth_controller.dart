import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';

class AuthController extends GetxController {
  AuthController({
    required this._localAuth,
    required this._locationPermissionService,
  });

  final LocalAuthentication _localAuth;
  final LocationPermissionService _locationPermissionService;

  final isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    authenticateWithBiometrics();
  }

  Future<void> authenticateWithBiometrics() async {
    if (isLoading.value) return;

    if (_isNativeAuthUnsupported) return;

    try {
      if (!await _localAuth.isDeviceSupported()) {
        _goHome();
        return;
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) return;

      isLoading.value = true;
      final ok = await _localAuth.authenticate(
        localizedReason: 'Use sua biometria para continuar',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (ok) _goHome();
    } on LocalAuthException catch (exception) {
      if (exception.code == LocalAuthExceptionCode.noCredentialsSet) {
        _goHome();
      }
    } on PlatformException catch (exception) {
      if (_isBiometricUnavailable(exception)) return;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> authenticateWithPassword() async {
    if (isLoading.value) return;

    if (_isNativeAuthUnsupported) {
      _goHome();
      return;
    }

    isLoading.value = true;

    try {
      if (!await _localAuth.isDeviceSupported()) {
        _goHome();
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Use a senha do celular para continuar',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (ok) _goHome();
    } on LocalAuthException catch (exception) {
      if (exception.code == LocalAuthExceptionCode.noCredentialsSet) _goHome();
    } on PlatformException catch (exception) {
      if (exception.code == 'PasscodeNotSet' || exception.code == 'NotAvailable') _goHome();
    } finally {
      isLoading.value = false;
    }
  }

  bool get _isNativeAuthUnsupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
  }

  bool _isBiometricUnavailable(PlatformException exception) {
    return switch (exception.code) {
      'NotAvailable' || 'NotEnrolled' || 'PasscodeNotSet' => true,
      _ => false,
    };
  }

  Future<void> _goHome() async {
    final granted = await _locationPermissionService.isGranted();
    Get.offAllNamed(
      granted ? AppRoutes.home : AppRoutes.locationPermission,
    );
  }
}
