import 'package:get/get.dart';
import 'package:teste_spixs/core/config/app_config.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/network/app_http_client.dart';
import 'package:teste_spixs/features/route/controllers/route_controller.dart';
import 'package:teste_spixs/features/route/data/repositories/directions_repository_impl.dart';
import 'package:teste_spixs/features/route/data/services/routes_api_service.dart';
import 'package:teste_spixs/features/route/domain/route_plan_args.dart';
import 'package:teste_spixs/features/route/domain/repositories/directions_repository.dart';

class RouteBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoutesApiService>(
      () => RoutesApiService(
        client: Get.find<AppHttpClient>(),
        apiKey: AppConfig.googleMapsApiKey,
      ),
    );
    Get.lazyPut<DirectionsRepository>(
      () => DirectionsRepositoryImpl(Get.find<RoutesApiService>()),
    );
    Get.lazyPut<RouteController>(
      () => RouteController(
        directionsRepository: Get.find<DirectionsRepository>(),
        locationPermissionService: Get.find<LocationPermissionService>(),
        args: Get.arguments as RoutePlanArgs,
      ),
    );
  }
}
