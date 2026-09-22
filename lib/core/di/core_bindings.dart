import 'package:get/get.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/network/app_http_client.dart';

class CoreBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppHttpClient>(AppHttpClient.new, fenix: true);
    Get.lazyPut<LocationPermissionService>(
      LocationPermissionService.new,
      fenix: true,
    );
  }
}
