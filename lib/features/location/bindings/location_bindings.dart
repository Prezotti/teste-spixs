import 'package:get/get.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/features/location/controllers/location_permission_controller.dart';

class LocationBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationPermissionController>(
      () => LocationPermissionController(
        locationPermissionService: Get.find<LocationPermissionService>(),
      ),
    );
  }
}
