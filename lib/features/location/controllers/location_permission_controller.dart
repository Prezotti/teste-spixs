import 'package:get/get.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';

class LocationPermissionController extends GetxController {
  LocationPermissionController({
    required this._locationPermissionService,
  });

  final LocationPermissionService _locationPermissionService;
  final isRequesting = false.obs;

  Future<void> allow() async {
    if (isRequesting.value) return;
    isRequesting.value = true;

    try {
      final granted = await _locationPermissionService.request();
      if (granted) Get.offAllNamed(AppRoutes.home);
    } finally {
      isRequesting.value = false;
    }
  }

  void skip() {
    Get.offAllNamed(AppRoutes.home);
  }
}
