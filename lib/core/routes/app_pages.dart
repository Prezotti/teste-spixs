import 'package:get/get.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';
import 'package:teste_spixs/features/auth/bindings/auth_bindings.dart';
import 'package:teste_spixs/features/auth/pages/auth_page.dart';
import 'package:teste_spixs/features/home/bindings/home_bindings.dart';
import 'package:teste_spixs/features/home/pages/home_page.dart';
import 'package:teste_spixs/features/location/bindings/location_bindings.dart';
import 'package:teste_spixs/features/location/pages/location_permission_page.dart';
import 'package:teste_spixs/features/route/bindings/route_bindings.dart';
import 'package:teste_spixs/features/route/pages/route_page.dart';

abstract final class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthPage(),
      binding: AuthBindings(),
    ),
    GetPage(
      name: AppRoutes.locationPermission,
      page: () => const LocationPermissionPage(),
      binding: LocationBindings(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBindings(),
    ),
    GetPage(
      name: AppRoutes.route,
      page: () => const RoutePage(),
      binding: RouteBindings(),
    ),
  ];
}
