import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/features/auth/controllers/auth_controller.dart';

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocalAuthentication>(LocalAuthentication.new);
    Get.lazyPut<AuthController>(
      () => AuthController(
        localAuth: Get.find<LocalAuthentication>(),
        locationPermissionService: Get.find<LocationPermissionService>(),
      ),
    );
  }
}
