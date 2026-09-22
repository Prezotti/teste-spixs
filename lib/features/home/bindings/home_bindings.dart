import 'package:get/get.dart';
import 'package:teste_spixs/core/config/app_config.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/network/app_http_client.dart';
import 'package:teste_spixs/features/home/controllers/home_controller.dart';
import 'package:teste_spixs/features/home/data/repositories/places_repository_impl.dart';
import 'package:teste_spixs/features/home/data/services/places_api_service.dart';
import 'package:teste_spixs/features/home/domain/repositories/places_repository.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlacesApiService>(
      () => PlacesApiService(
        client: Get.find<AppHttpClient>(),
        apiKey: AppConfig.googleMapsApiKey,
      ),
    );
    Get.lazyPut<PlacesRepository>(
      () => PlacesRepositoryImpl(Get.find<PlacesApiService>()),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(
        placesRepository: Get.find<PlacesRepository>(),
        locationPermissionService: Get.find<LocationPermissionService>(),
      ),
    );
  }
}
