import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';
import 'package:teste_spixs/features/auth/widgets/auth_retry_dialog.dart';

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

    var failed = false;

    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return;

      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) return;

      isLoading.value = true;
      final ok = await _localAuth.authenticate(
        localizedReason: 'Use sua biometria para continuar',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (ok) {
        _goHome();
        return;
      }

      failed = true;
    } on PlatformException catch (exception) {
      if (_isBiometricUnavailable(exception)) return;
      failed = true;
    } finally {
      isLoading.value = false;
    }

    if (!failed) return;

    final retry = await Get.dialog<bool>(
          const AuthRetryDialog(),
          barrierDismissible: false,
        ) ??
        false;

    if (retry) {
      await authenticateWithBiometrics();
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
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return;

      final ok = await _localAuth.authenticate(
        localizedReason: 'Use a senha do celular para continuar',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (ok) _goHome();
    } on PlatformException {
      // Sem senha configurada ou falha nativa: permanece na tela.
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
